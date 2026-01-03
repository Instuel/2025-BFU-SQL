/* ============================================================
大屏数据展示业务线（企业管理层 exec_user）
负责人：杨尧天
   - 功能：
     A. 检查/补全业务线5相关表：Dashboard_Config / Stat_Realtime / Stat_History_Trend
     B. 每张表插入 23 条不同测试数据（幂等：重复执行不重复插入）
     C. 视图 >= 3：满足企业管理层大屏与统计查询
     D. 触发器 1：实时总用电量环比上升 >15% 自动生成告警（写入 Alarm_Info，若表存在）
   适用：SQL Server
   ============================================================ */
USE SQL_BFU;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    /* ------------------------------------------------------------
       0) 若核心表不存在：创建（尽量兼容基础脚本；外键/约束后续按存在性补）
       ------------------------------------------------------------ */

    IF OBJECT_ID('dbo.Dashboard_Config', 'U') IS NULL
    BEGIN
        EXEC(N'
            CREATE TABLE dbo.Dashboard_Config (
                Config_ID        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dashboard_Config PRIMARY KEY,
                Module_Name      NVARCHAR(20) NULL,       -- 能源总览/光伏总览等（基础脚本）
                Refresh_Rate     NVARCHAR(20) NULL,
                Sort_Rule        NVARCHAR(50) NULL,
                Display_Fields   NVARCHAR(500) NULL,      -- JSON or CSV（基础脚本）
                Auth_Level       NVARCHAR(20) NULL,       -- 管理员/运维人员（基础脚本）

                -- v4 扩展：用于幂等插数/更细刷新策略（业务线5）
                Config_Code      NVARCHAR(30) NULL,       -- 幂等键（唯一）
                Refresh_Interval INT NULL,
                Refresh_Unit     NVARCHAR(10) NULL
            );
        ');
    END;

    IF OBJECT_ID('dbo.Stat_Realtime', 'U') IS NULL
    BEGIN
        EXEC(N'
            CREATE TABLE dbo.Stat_Realtime (
                Summary_ID    NVARCHAR(20) NOT NULL CONSTRAINT PK_Stat_Realtime PRIMARY KEY,
                Stat_Time     DATETIME2(0) NOT NULL,

                -- 基础脚本字段
                Total_KWH     DECIMAL(12,3) NULL,
                Total_Alarm   INT NULL,
                PV_Gen_KWH    DECIMAL(12,3) NULL,
                Config_ID     BIGINT NULL,
                Manager_ID    BIGINT NULL,

                -- v4 扩展字段（业务线5：更丰富的大屏指标）
                Total_Water_m3     DECIMAL(12,3) NULL,
                Total_Steam_t      DECIMAL(12,3) NULL,
                Total_Gas_m3       DECIMAL(12,3) NULL,
                Alarm_High         INT NULL,
                Alarm_Mid          INT NULL,
                Alarm_Low          INT NULL,
                Alarm_Unprocessed  INT NULL
            );
        ');
    END;

    IF OBJECT_ID('dbo.Stat_History_Trend', 'U') IS NULL
    BEGIN
        EXEC(N'
            CREATE TABLE dbo.Stat_History_Trend (
                Trend_ID    NVARCHAR(20) NOT NULL CONSTRAINT PK_Stat_History_Trend PRIMARY KEY,

                -- 基础脚本字段
                Energy_Type NVARCHAR(10) NULL,
                Stat_Cycle  NVARCHAR(10) NULL, -- 日/周/月
                Stat_Date   DATE NULL,
                Value       DECIMAL(12,3) NULL,
                YOY_Rate    DECIMAL(5,2) NULL,  -- 同比
                MOM_Rate    DECIMAL(5,2) NULL,  -- 环比
                Config_ID   BIGINT NULL,
                Analyst_ID  BIGINT NULL,

                -- v4 扩展字段（业务线5）
                Industry_Avg DECIMAL(12,3) NULL,
                Trend_Tag    NVARCHAR(20) NULL  -- 同比上升/同比下降/平稳等
            );
        ');
    END;

    /* ------------------------------------------------------------
       1) Dashboard_Config：缺列补齐 + 约束/索引（全用动态 SQL 执行）
       ------------------------------------------------------------ */

    -- 1.1 缺列补齐（来自基础脚本 + v4 扩展）
    IF COL_LENGTH('dbo.Dashboard_Config','Module_Name') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Module_Name NVARCHAR(20) NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Rate') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Refresh_Rate NVARCHAR(20) NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Sort_Rule') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Sort_Rule NVARCHAR(50) NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Display_Fields') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Display_Fields NVARCHAR(500) NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Auth_Level') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Auth_Level NVARCHAR(20) NULL;');

    IF COL_LENGTH('dbo.Dashboard_Config','Config_Code') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Config_Code NVARCHAR(30) NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Interval') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Refresh_Interval INT NULL;');
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Unit') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Refresh_Unit NVARCHAR(10) NULL;');

    -- 1.2 兼容性：适当放宽字段长度（只做“变大”，不会破坏现有数据）
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.objects o ON c.object_id=o.object_id
        WHERE o.object_id=OBJECT_ID('dbo.Dashboard_Config')
          AND c.name='Display_Fields' AND c.max_length < 1000
    )
    BEGIN
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ALTER COLUMN Display_Fields NVARCHAR(1000) NULL;');
    END;

    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.objects o ON c.object_id=o.object_id
        WHERE o.object_id=OBJECT_ID('dbo.Dashboard_Config')
          AND c.name='Module_Name' AND c.max_length < 50
    )
    BEGIN
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ALTER COLUMN Module_Name NVARCHAR(50) NULL;');
    END;

    -- 1.3 唯一索引：Config_Code（幂等插数）
    IF COL_LENGTH('dbo.Dashboard_Config','Config_Code') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Dashboard_Config_Config_Code' AND object_id=OBJECT_ID('dbo.Dashboard_Config'))
    BEGIN
        EXEC(N'CREATE UNIQUE NONCLUSTERED INDEX UX_Dashboard_Config_Config_Code
              ON dbo.Dashboard_Config(Config_Code)
              WHERE Config_Code IS NOT NULL;');
    END;

    -- 1.4 CHECK：Refresh_Unit 取值
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Unit') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Dashboard_Config_Refresh_Unit' AND parent_object_id=OBJECT_ID('dbo.Dashboard_Config'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Dashboard_Config WITH NOCHECK
              ADD CONSTRAINT CK_Dashboard_Config_Refresh_Unit
              CHECK (Refresh_Unit IS NULL OR Refresh_Unit IN (''s'',''m'',''h''));');
    END;

    /* ------------------------------------------------------------
       2) Stat_Realtime：缺列补齐 + 索引 +（可选）外键
       ------------------------------------------------------------ */

    IF COL_LENGTH('dbo.Stat_Realtime','Summary_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Summary_ID NVARCHAR(20) NULL;'); -- 极端兜底
    IF COL_LENGTH('dbo.Stat_Realtime','Stat_Time') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Stat_Time DATETIME2(0) NULL;');

    -- 基础字段缺列补齐
    IF COL_LENGTH('dbo.Stat_Realtime','Total_KWH') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Total_KWH DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Total_Alarm') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Total_Alarm INT NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','PV_Gen_KWH') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD PV_Gen_KWH DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Config_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Config_ID BIGINT NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Manager_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Manager_ID BIGINT NULL;');

    -- v4 扩展字段
    IF COL_LENGTH('dbo.Stat_Realtime','Total_Water_m3') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Total_Water_m3 DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Total_Steam_t') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Total_Steam_t DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Total_Gas_m3') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Total_Gas_m3 DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Alarm_High') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Alarm_High INT NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Alarm_Mid') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Alarm_Mid INT NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Alarm_Low') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Alarm_Low INT NULL;');
    IF COL_LENGTH('dbo.Stat_Realtime','Alarm_Unprocessed') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_Realtime ADD Alarm_Unprocessed INT NULL;');

    -- 索引：Stat_Time
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Stat_Realtime_Stat_Time' AND object_id=OBJECT_ID('dbo.Stat_Realtime'))
    BEGIN
        EXEC(N'CREATE NONCLUSTERED INDEX IX_Stat_Realtime_Stat_Time ON dbo.Stat_Realtime(Stat_Time DESC);');
    END;

    -- 可选外键：若目标表存在且 FK 不存在，则补上
    IF OBJECT_ID('dbo.Dashboard_Config','U') IS NOT NULL
       AND COL_LENGTH('dbo.Stat_Realtime','Config_ID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Realtime_Config' AND parent_object_id=OBJECT_ID('dbo.Stat_Realtime'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_Realtime WITH NOCHECK
              ADD CONSTRAINT FK_Realtime_Config
              FOREIGN KEY (Config_ID) REFERENCES dbo.Dashboard_Config(Config_ID);');
    END;

    IF OBJECT_ID('dbo.Role_Manager','U') IS NOT NULL
       AND COL_LENGTH('dbo.Stat_Realtime','Manager_ID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Realtime_Manager' AND parent_object_id=OBJECT_ID('dbo.Stat_Realtime'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_Realtime WITH NOCHECK
              ADD CONSTRAINT FK_Realtime_Manager
              FOREIGN KEY (Manager_ID) REFERENCES dbo.Role_Manager(Manager_ID);');
    END;

    /* ------------------------------------------------------------
       3) Stat_History_Trend：缺列补齐 + CHECK + 索引 +（可选）外键
       ------------------------------------------------------------ */

    IF COL_LENGTH('dbo.Stat_History_Trend','Trend_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Trend_ID NVARCHAR(20) NULL;'); -- 极端兜底

    -- 基础字段缺列补齐
    IF COL_LENGTH('dbo.Stat_History_Trend','Energy_Type') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Energy_Type NVARCHAR(10) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Stat_Cycle') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Stat_Cycle NVARCHAR(10) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Stat_Date') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Stat_Date DATE NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Value') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Value DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','YOY_Rate') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD YOY_Rate DECIMAL(5,2) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','MOM_Rate') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD MOM_Rate DECIMAL(5,2) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Config_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Config_ID BIGINT NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Analyst_ID') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Analyst_ID BIGINT NULL;');

    -- v4 扩展
    IF COL_LENGTH('dbo.Stat_History_Trend','Industry_Avg') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Industry_Avg DECIMAL(12,3) NULL;');
    IF COL_LENGTH('dbo.Stat_History_Trend','Trend_Tag') IS NULL
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend ADD Trend_Tag NVARCHAR(20) NULL;');

    -- CHECK：Energy_Type/Stat_Cycle（只加一次）
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Trend_Energy_Type' AND parent_object_id=OBJECT_ID('dbo.Stat_History_Trend'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend WITH NOCHECK
              ADD CONSTRAINT CK_Trend_Energy_Type
              CHECK (Energy_Type IS NULL OR Energy_Type IN (N''电'',N''水'',N''蒸汽'',N''天然气'',N''光伏''));');
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Trend_Stat_Cycle' AND parent_object_id=OBJECT_ID('dbo.Stat_History_Trend'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend WITH NOCHECK
              ADD CONSTRAINT CK_Trend_Stat_Cycle
              CHECK (Stat_Cycle IS NULL OR Stat_Cycle IN (N''日'',N''周'',N''月''));');
    END;

    -- 索引：Stat_Date + Energy_Type
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Trend_Date_Type' AND object_id=OBJECT_ID('dbo.Stat_History_Trend'))
    BEGIN
        EXEC(N'CREATE NONCLUSTERED INDEX IX_Trend_Date_Type ON dbo.Stat_History_Trend(Stat_Date DESC, Energy_Type);');
    END;

    -- 可选外键
    IF OBJECT_ID('dbo.Dashboard_Config','U') IS NOT NULL
       AND COL_LENGTH('dbo.Stat_History_Trend','Config_ID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Trend_Config' AND parent_object_id=OBJECT_ID('dbo.Stat_History_Trend'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend WITH NOCHECK
              ADD CONSTRAINT FK_Trend_Config
              FOREIGN KEY (Config_ID) REFERENCES dbo.Dashboard_Config(Config_ID);');
    END;

    IF OBJECT_ID('dbo.Role_Analyst','U') IS NOT NULL
       AND COL_LENGTH('dbo.Stat_History_Trend','Analyst_ID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Trend_Analyst' AND parent_object_id=OBJECT_ID('dbo.Stat_History_Trend'))
    BEGIN
        EXEC(N'ALTER TABLE dbo.Stat_History_Trend WITH NOCHECK
              ADD CONSTRAINT FK_Trend_Analyst
              FOREIGN KEY (Analyst_ID) REFERENCES dbo.Role_Analyst(Analyst_ID);');
    END;

	-- 提交事务（结束第1部分的原子操作）
    COMMIT TRAN;
    PRINT '大屏数据业务线 表结构检查与创建成功';

END TRY
BEGIN CATCH
    -- 发生错误时回滚
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;
    
    -- 抛出错误信息
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO



/* ============================================================
综合能耗管理业务线补丁
负责人：杨昊田
   ============================================================ */

-- 1. 修改能耗计量设备表 - 增加"电"类型
IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Energy_Type' AND parent_object_id = OBJECT_ID('Energy_Meter'))
BEGIN
    ALTER TABLE Energy_Meter DROP CONSTRAINT CK_Energy_Type;
END
GO

-- 添加新的CHECK约束，包含4种能源类型：水、蒸汽、天然气、电
ALTER TABLE Energy_Meter 
ADD CONSTRAINT CK_Energy_Type CHECK (Energy_Type IN (N'水', N'蒸汽', N'天然气', N'电'));
GO

PRINT '综合能耗业务线 表结构检查与创建成功';
GO


/* ============================================================    
告警运维管理业务线补充
负责人：李振梁

修改内容：
   1) Alarm_Info   ：增加告警触发阈值字段 + 告警类型 CHECK 约束
   2) Work_Order   ：增加附件路径字段 + 复查状态 CHECK 约束
   3) Device_Ledger：增加质保期、校准时间、校准人员字段
   说明：均使用 ALTER，不破坏原有主外键结构
   ============================================================ */

USE SQL_BFU;
GO

-- 1.1 增加告警触发阈值字段
IF COL_LENGTH('Alarm_Info', 'Trigger_Threshold') IS NULL
BEGIN
    ALTER TABLE Alarm_Info
    ADD Trigger_Threshold DECIMAL(12,3) NULL;  -- 告警触发阈值，如温度/电压上限
END
GO

-- 1.2 为告警类型增加 CHECK 约束（任务书三种 + 实际扩展几种，其他归为“其他”）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_Alarm_Type'
      AND parent_object_id = OBJECT_ID('Alarm_Info')
)
BEGIN
    ALTER TABLE Alarm_Info
    ADD CONSTRAINT CK_Alarm_Type
        CHECK (Alarm_Type IN (
            N'越限告警',   -- 任务书原有
            N'通讯故障',   -- 任务书原有
            N'设备故障',   -- 任务书原有
            N'设备离线',   -- 实际常见：设备掉线
            N'环境告警',   -- 机房温湿度等
            N'安全告警',   -- 安全/权限相关
            N'其他'        -- 兜底类型
        ));
END
GO


-- 2.1 增加附件路径字段（存放故障现场照片路径或 URL）
IF COL_LENGTH('Work_Order', 'Attachment_Path') IS NULL
BEGIN
    ALTER TABLE Work_Order
    ADD Attachment_Path NVARCHAR(260) NULL;   -- 路径/URL
END
GO

-- 2.2 为复查状态增加 CHECK 约束（通过 / 未通过 / 未复查(NULL)）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_WorkOrder_Review_Status'
      AND parent_object_id = OBJECT_ID('Work_Order')
)
BEGIN
    ALTER TABLE Work_Order
    ADD CONSTRAINT CK_WorkOrder_Review_Status
        CHECK (Review_Status IN (N'通过', N'未通过') OR Review_Status IS NULL);
END
GO


-- 3.1 增加质保期（年）字段
IF COL_LENGTH('Device_Ledger', 'Warranty_Years') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Warranty_Years INT NULL;           -- 例如 1 / 2 / 3 年
END
GO

-- 3.2 增加校准时间字段
IF COL_LENGTH('Device_Ledger', 'Calibration_Time') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Calibration_Time DATETIME2(0) NULL;  -- 最近一次校准时间
END
GO

-- 3.3 增加校准人员字段
IF COL_LENGTH('Device_Ledger', 'Calibration_Person') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Calibration_Person NVARCHAR(50) NULL; -- 最近一次校准人员
END
GO

PRINT '告警运维业务线 表结构检查与创建成功';


/* ============================================================
配电网业务线表结构修改脚本
负责人：张恺洋

   目标数据库：SQL_BFU
   修改内容：
   1) Data_Transformer（变压器监测数据表）：新增“状态”字段 + CHECK 约束（正常/异常）
   2) Data_Circuit（回路监测数据表）：新增“状态”字段 + CHECK 约束（正常/异常）
   ============================================================ */
USE SQL_BFU;
GO


-- 检查并新增状态字段（若字段不存在）
IF COL_LENGTH('Data_Transformer', 'Device_Status') IS NULL
BEGIN
    ALTER TABLE Data_Transformer
    ADD Device_Status NVARCHAR(10) NULL; -- 状态：正常/异常
END
GO

-- 检查并新增状态字段 CHECK 约束（若约束不存在）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_DataTrans_Status'
      AND parent_object_id = OBJECT_ID('Data_Transformer')
)
BEGIN
    ALTER TABLE Data_Transformer
    ADD CONSTRAINT CK_DataTrans_Status
        CHECK (Device_Status IN (N'正常', N'异常') OR Device_Status IS NULL);
END
GO


-- 3.1 检查并新增状态字段（若字段不存在）
IF COL_LENGTH('Data_Circuit', 'Device_Status') IS NULL
BEGIN
    ALTER TABLE Data_Circuit
    ADD Device_Status NVARCHAR(10) NULL; -- 状态：正常/异常
END
GO

-- 3.2 检查并新增状态字段 CHECK 约束（若约束不存在）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_DataCircuit_Status'
      AND parent_object_id = OBJECT_ID('Data_Circuit')
)
BEGIN
    ALTER TABLE Data_Circuit
    ADD CONSTRAINT CK_DataCircuit_Status
        CHECK (Device_Status IN (N'正常', N'异常') OR Device_Status IS NULL);
END
GO


USE SQL_BFU;
GO

/* ============================================================
   一、完善变压器和线路数据的工厂外键关联
   说明：确保Data_Transformer和Data_Circuit的Factory_ID正确关联到Base_Factory
   ============================================================ */
-- 1.1 Data_Transformer表Factory_ID外键约束
IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys
    WHERE name = 'FK_DataTrans_Factory'
      AND parent_object_id = OBJECT_ID('Data_Transformer')
)
BEGIN
    ALTER TABLE Data_Transformer
    ADD CONSTRAINT FK_DataTrans_Factory
        FOREIGN KEY (Factory_ID)
        REFERENCES Base_Factory(Factory_ID);
END
GO

-- 1.2 Data_Circuit表Factory_ID外键约束
IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys
    WHERE name = 'FK_DataCircuit_Factory'
      AND parent_object_id = OBJECT_ID('Data_Circuit')
)
BEGIN
    ALTER TABLE Data_Circuit
    ADD CONSTRAINT FK_DataCircuit_Factory
        FOREIGN KEY (Factory_ID)
        REFERENCES Base_Factory(Factory_ID);
END
GO

/* ============================================================
   二、补充峰谷数据的类型约束
   说明：确保Data_PeakValley的Peak_Type与配置表Config_PeakValley的Time_Type取值一致
   ============================================================ */
IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints 
    WHERE name = 'CK_PeakValley_Type'
      AND parent_object_id = OBJECT_ID('Data_PeakValley')
)
BEGIN
    ALTER TABLE Data_PeakValley
    ADD CONSTRAINT CK_PeakValley_Type
        CHECK (Peak_Type IN ('尖峰', '高峰', '平段', '低谷') OR Peak_Type IS NULL);
END
GO

PRINT '配电网业务线 表结构检查与创建成功';
GO


/* ============================================================
   分布式光伏管理业务线 
   负责人：段泓冰
   ============================================================ */
-- 光伏预测模型表修改
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PV_Model_Status')
BEGIN
	ALTER TABLE PV_Forecast_Model
	ADD CONSTRAINT CK_PV_Model_Status 
	CHECK (Status IN ('Active', 'Inactive', 'Testing', 'Deprecated', 'Training'));
END
GO

-- 光伏设备表修改
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PV_Protocol')
BEGIN
    ALTER TABLE PV_Device
    ADD CONSTRAINT CK_PV_Protocol 
    CHECK (Protocol IN ('RS485', 'Lora'));
END
GO

-- 光伏发电数据表修改
-- 1. 添加字段
IF COL_LENGTH('Data_PV_Gen', 'Point_ID') IS NULL
BEGIN
    ALTER TABLE Data_PV_Gen
    ADD 
        Point_ID BIGINT NULL,                  -- 并网点编号
        Bus_Voltage DECIMAL(8,2) NULL,         -- 汇流箱组串电压（V）
        Bus_Current DECIMAL(8,2) NULL,         -- 汇流箱组串电流（A）
        String_Count INT NULL;                 -- 组串数量（可选）
END
GO

-- 2. 添加外键约束（并网点编号 PV_Grid_Point）
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PV_Grid_Point')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PVGen_Point')
BEGIN
    ALTER TABLE Data_PV_Gen
    ADD CONSTRAINT FK_PVGen_Point 
    FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID);
END
GO

-- 光伏预测数据表修改
-- 注意：先添加计算列
IF COL_LENGTH('Data_PV_Forecast', 'Deviation_Rate') IS NULL
BEGIN
    ALTER TABLE Data_PV_Forecast
    ADD Deviation_Rate AS (
        CASE 
            WHEN Actual_Val IS NOT NULL AND Forecast_Val IS NOT NULL 
            THEN ((Actual_Val - Forecast_Val) / NULLIF(Forecast_Val, 0)) * 100
            ELSE NULL 
        END
    ) PERSISTED;
END
GO

PRINT '分布式光伏管理业务线 表结构修改完成';
GO

/* ============================================================
   最后一步：生成数据库变更汇总报告
   功能：输出本次脚本涉及的所有业务线变更项摘要
   ============================================================ */

PRINT '正在生成变更汇总报告...';
GO

SELECT 
    '01-大屏数据展示' AS [业务线], 
    '杨尧天' AS [负责人], 
    'Dashboard_Config, Stat_Realtime, Stat_History_Trend' AS [涉及对象], 
    '创建/补全表结构; 增加v4扩展字段(Config_Code等); 增加索引' AS [变更摘要]
UNION ALL
SELECT 
    '02-综合能耗管理', 
    '杨昊田', 
    'Energy_Meter', 
    '修改 CK_Energy_Type 约束，增加“电”作为能源类型'
UNION ALL
SELECT 
    '03-告警运维管理', 
    '李振梁', 
    'Alarm_Info, Work_Order, Device_Ledger', 
    '增加阈值字段; 扩展告警类型约束; 增加附件路径; 增加质保/校准字段'
UNION ALL
SELECT 
    '04-配电网管理', 
    '张恺洋', 
    'Data_Transformer, Data_Circuit, Base_Factory', 
    '增加设备状态字段及约束; 修复工厂外键关联; 规范峰谷类型约束'
UNION ALL
SELECT 
    '05-分布式光伏', 
    '段泓冰', 
    'PV_Forecast_Model, PV_Device, Data_PV_Gen, Data_PV_Forecast', 
    '增加模型状态约束; 增加设备协议约束; 扩展并网点字段及外键; 增加偏差率计算列'
UNION ALL
SELECT 
    '== 执行状态 ==', 
    'SYSTEM', 
    'SQL_BFU Database', 
    '所有脚本逻辑执行完毕，当前时间: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
GO