/* ============================================================
   Patch v4: 业务线5 大屏数据展示（企业管理层 exec_user）
   - 修复点：
     1) 彻底避免 SQL Server “同一 batch 内 DDL 后引用列” 的编译期错误
        => 所有涉及新列/新约束/新索引/视图/触发器的 DDL/DML 均用 EXEC('...') 动态执行
     2) 不再包含任何 “...” 省略符，保证脚本可直接执行
   - 功能：
     A. 检查/补全业务线5相关表：Dashboard_Config / Stat_Realtime / Stat_History_Trend
     B. 每张表插入 23 条不同测试数据（幂等：重复执行不重复插入）
     C. 视图 >= 3：满足企业管理层大屏与统计查询
     D. 触发器 1：实时总用电量环比上升 >15% 自动生成告警（写入 Alarm_Info，若表存在）
   适用：SQL Server
   ============================================================ */

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

    /* ------------------------------------------------------------
       4) 插入 23 条测试数据（每张表 23 条；幂等）
       ------------------------------------------------------------ */

    -- 4.1 Dashboard_Config：23 条模块配置（用 Config_Code 幂等）
    IF COL_LENGTH('dbo.Dashboard_Config','Config_Code') IS NOT NULL
    BEGIN
        EXEC(N'
            ;WITH src AS (
                SELECT * FROM (VALUES
                    (N''EXEC_MOD_01'', N''能源总览'',  N''10s'', N''kwh_desc'', N''total_kwh,total_alarm,pv_gen_kwh'',        N''企业管理层'', 10, N''s''),
                    (N''EXEC_MOD_02'', N''电力总览'',  N''30s'', N''kwh_desc'', N''total_kwh,water,steam,gas'',              N''企业管理层'', 30, N''s''),
                    (N''EXEC_MOD_03'', N''用电分析'',  N''1m'',  N''kwh_desc'', N''total_kwh,yoy,mom,industry_avg'',         N''企业管理层'', 1,  N''m''),
                    (N''EXEC_MOD_04'', N''用水分析'',  N''1m'',  N''m3_desc'',  N''total_water_m3,yoy,mom,industry_avg'',    N''企业管理层'', 1,  N''m''),
                    (N''EXEC_MOD_05'', N''蒸汽分析'',  N''5m'',  N''t_desc'',   N''total_steam_t,yoy,mom,industry_avg'',     N''企业管理层'', 5,  N''m''),
                    (N''EXEC_MOD_06'', N''天然气分析'',N''5m'',  N''m3_desc'',  N''total_gas_m3,yoy,mom,industry_avg'',       N''企业管理层'', 5,  N''m''),
                    (N''EXEC_MOD_07'', N''光伏总览'',  N''30s'', N''pv_desc'',  N''pv_gen_kwh,yoy,mom,industry_avg'',         N''企业管理层'', 30, N''s''),
                    (N''EXEC_MOD_08'', N''告警总览'',  N''10s'', N''alarm_desc'',N''total_alarm,high,mid,low,unprocessed'',   N''企业管理层'', 10, N''s''),
                    (N''EXEC_MOD_09'', N''趋势面板'',  N''5m'',  N''trend_desc'',N''trend_7d,trend_30d,trend_tag'',           N''企业管理层'', 5,  N''m''),
                    (N''EXEC_MOD_10'', N''部门能耗'',  N''10m'', N''dept_desc'', N''dept_top5,dept_bottom5'',                N''企业管理层'', 10, N''m''),
                    (N''EXEC_MOD_11'', N''厂区对比'',  N''10m'', N''site_desc'', N''site_kwh,site_alarm'',                   N''企业管理层'', 10, N''m''),
                    (N''EXEC_MOD_12'', N''碳排估算'',  N''30m'', N''co2_desc'',  N''co2_total,co2_intensity'',              N''企业管理层'', 30, N''m''),
                    (N''EXEC_MOD_13'', N''成本估算'',  N''30m'', N''cost_desc'', N''cost_total,cost_trend'',                N''企业管理层'', 30, N''m''),
                    (N''EXEC_MOD_14'', N''峰谷分析'',  N''15m'', N''pv_valley'', N''peak_kwh,valley_kwh,ratio'',            N''企业管理层'', 15, N''m''),
                    (N''EXEC_MOD_15'', N''用能异常'',  N''10s'', N''anomaly'',  N''spike,drop,alerts'',                      N''企业管理层'', 10, N''s''),
                    (N''EXEC_MOD_16'', N''设备健康'',  N''30m'', N''health'',   N''online_rate,fault_rate'',                N''企业管理层'', 30, N''m''),
                    (N''EXEC_MOD_17'', N''KPI看板'',   N''5m'',  N''kpi'',      N''kwh_per_output,alarm_rate'',             N''企业管理层'', 5,  N''m''),
                    (N''EXEC_MOD_18'', N''月度总结'',  N''6h'',  N''monthly'',  N''month_kwh,month_yoy,month_cost'',         N''企业管理层'', 6,  N''h''),
                    (N''EXEC_MOD_19'', N''年度总结'',  N''24h'', N''yearly'',   N''year_kwh,year_yoy,year_cost'',            N''企业管理层'', 24, N''h''),
                    (N''EXEC_MOD_20'', N''能效对标'',  N''1h'',  N''benchmark'',N''industry_avg,rank,trend_tag'',           N''企业管理层'', 1,  N''h''),
                    (N''EXEC_MOD_21'', N''预警中心'',  N''10s'', N''warn'',     N''unprocessed,high,mid,low'',              N''企业管理层'', 10, N''s''),
                    (N''EXEC_MOD_22'', N''预测概览'',  N''30m'', N''forecast'', N''forecast_next,forecast_bias'',           N''企业管理层'', 30, N''m''),
                    (N''EXEC_MOD_23'', N''报表导出'',  N''24h'', N''export'',   N''export_link,last_export_time'',          N''企业管理层'', 24, N''h'')
                ) AS v(Config_Code, Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level, Refresh_Interval, Refresh_Unit)
            )
            INSERT INTO dbo.Dashboard_Config (Config_Code, Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level, Refresh_Interval, Refresh_Unit)
            SELECT s.Config_Code, s.Module_Name, s.Refresh_Rate, s.Sort_Rule, s.Display_Fields, s.Auth_Level, s.Refresh_Interval, s.Refresh_Unit
            FROM src s
            WHERE NOT EXISTS (
                SELECT 1 FROM dbo.Dashboard_Config t WHERE t.Config_Code = s.Config_Code
            );
        ');
    END
    ELSE
    BEGIN
        -- 若确实无法增加 Config_Code（极端情况），仍插入 23 条（按 Module_Name 幂等）
        EXEC(N'
            ;WITH src AS (
                SELECT * FROM (VALUES
                    (N''能源总览'',N''10s'',N''kwh_desc'',N''total_kwh,total_alarm,pv_gen_kwh'',N''企业管理层''),
                    (N''电力总览'',N''30s'',N''kwh_desc'',N''total_kwh,water,steam,gas'',N''企业管理层''),
                    (N''用电分析'',N''1m'', N''kwh_desc'',N''total_kwh,yoy,mom,industry_avg'',N''企业管理层''),
                    (N''用水分析'',N''1m'', N''m3_desc'', N''total_water_m3,yoy,mom,industry_avg'',N''企业管理层''),
                    (N''蒸汽分析'',N''5m'', N''t_desc'',  N''total_steam_t,yoy,mom,industry_avg'',N''企业管理层''),
                    (N''天然气分析'',N''5m'',N''m3_desc'', N''total_gas_m3,yoy,mom,industry_avg'',N''企业管理层''),
                    (N''光伏总览'',N''30s'',N''pv_desc'', N''pv_gen_kwh,yoy,mom,industry_avg'',N''企业管理层''),
                    (N''告警总览'',N''10s'',N''alarm_desc'',N''total_alarm,high,mid,low,unprocessed'',N''企业管理层''),
                    (N''趋势面板'',N''5m'', N''trend_desc'',N''trend_7d,trend_30d,trend_tag'',N''企业管理层''),
                    (N''部门能耗'',N''10m'',N''dept_desc'',N''dept_top5,dept_bottom5'',N''企业管理层''),
                    (N''厂区对比'',N''10m'',N''site_desc'',N''site_kwh,site_alarm'',N''企业管理层''),
                    (N''碳排估算'',N''30m'',N''co2_desc'', N''co2_total,co2_intensity'',N''企业管理层''),
                    (N''成本估算'',N''30m'',N''cost_desc'',N''cost_total,cost_trend'',N''企业管理层''),
                    (N''峰谷分析'',N''15m'',N''pv_valley'',N''peak_kwh,valley_kwh,ratio'',N''企业管理层''),
                    (N''用能异常'',N''10s'',N''anomaly'', N''spike,drop,alerts'',N''企业管理层''),
                    (N''设备健康'',N''30m'',N''health'',  N''online_rate,fault_rate'',N''企业管理层''),
                    (N''KPI看板'', N''5m'', N''kpi'',     N''kwh_per_output,alarm_rate'',N''企业管理层''),
                    (N''月度总结'',N''6h'', N''monthly'', N''month_kwh,month_yoy,month_cost'',N''企业管理层''),
                    (N''年度总结'',N''24h'',N''yearly'',  N''year_kwh,year_yoy,year_cost'',N''企业管理层''),
                    (N''能效对标'',N''1h'', N''benchmark'',N''industry_avg,rank,trend_tag'',N''企业管理层''),
                    (N''预警中心'',N''10s'',N''warn'',    N''unprocessed,high,mid,low'',N''企业管理层''),
                    (N''预测概览'',N''30m'',N''forecast'',N''forecast_next,forecast_bias'',N''企业管理层''),
                    (N''报表导出'',N''24h'',N''export'',  N''export_link,last_export_time'',N''企业管理层'')
                ) AS v(Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
            )
            INSERT INTO dbo.Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
            SELECT s.Module_Name, s.Refresh_Rate, s.Sort_Rule, s.Display_Fields, s.Auth_Level
            FROM src s
            WHERE NOT EXISTS (
                SELECT 1 FROM dbo.Dashboard_Config t WHERE t.Module_Name = s.Module_Name
            );
        ');
    END;

    -- 4.2 Stat_Realtime：23 条实时汇总（Summary_ID 幂等）
    EXEC(N'
        ;WITH cfg AS (
            SELECT TOP 23 Config_ID, 
                   COALESCE(Config_Code, CONCAT(N''CFG_'', RIGHT(''000''+CAST(Config_ID AS NVARCHAR(10)),3))) AS ConfigKey
            FROM dbo.Dashboard_Config
            ORDER BY Config_ID
        ),
        seq AS (
            SELECT ROW_NUMBER() OVER (ORDER BY Config_ID) AS rn, Config_ID
            FROM cfg
        ),
        src AS (
            SELECT
                CONCAT(N''RT_'', RIGHT(''000''+CAST(rn AS NVARCHAR(10)),3)) AS Summary_ID,
                DATEADD(MINUTE, -1 * (rn-1), SYSUTCDATETIME()) AS Stat_Time,
                CAST( 1200 + rn*37 AS DECIMAL(12,3)) AS Total_KWH,
                CAST( (rn % 9) + 3 AS INT) AS Total_Alarm,
                CAST( 180 + rn*5 AS DECIMAL(12,3)) AS PV_Gen_KWH,
                Config_ID,
                NULL AS Manager_ID,
                CAST( 300 + rn*9  AS DECIMAL(12,3)) AS Total_Water_m3,
                CAST( 50  + rn*2  AS DECIMAL(12,3)) AS Total_Steam_t,
                CAST( 90  + rn*3  AS DECIMAL(12,3)) AS Total_Gas_m3,
                CAST( rn % 3 AS INT) AS Alarm_High,
                CAST( rn % 4 AS INT) AS Alarm_Mid,
                CAST( rn % 5 AS INT) AS Alarm_Low,
                CAST( rn % 6 AS INT) AS Alarm_Unprocessed
            FROM seq
        )
        INSERT INTO dbo.Stat_Realtime
            (Summary_ID, Stat_Time, Total_KWH, Total_Alarm, PV_Gen_KWH, Config_ID, Manager_ID,
             Total_Water_m3, Total_Steam_t, Total_Gas_m3, Alarm_High, Alarm_Mid, Alarm_Low, Alarm_Unprocessed)
        SELECT
            s.Summary_ID, s.Stat_Time, s.Total_KWH, s.Total_Alarm, s.PV_Gen_KWH, s.Config_ID, s.Manager_ID,
            s.Total_Water_m3, s.Total_Steam_t, s.Total_Gas_m3, s.Alarm_High, s.Alarm_Mid, s.Alarm_Low, s.Alarm_Unprocessed
        FROM src s
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Stat_Realtime t WHERE t.Summary_ID = s.Summary_ID);
    ');

    -- 4.3 Stat_History_Trend：23 条趋势（Trend_ID 幂等）
    EXEC(N'
        ;WITH cfg AS (
            SELECT TOP 23 Config_ID
            FROM dbo.Dashboard_Config
            ORDER BY Config_ID
        ),
        seq AS (
            SELECT ROW_NUMBER() OVER (ORDER BY Config_ID) AS rn, Config_ID
            FROM cfg
        ),
        src AS (
            SELECT
                CONCAT(N''TR_'', RIGHT(''000''+CAST(rn AS NVARCHAR(10)),3)) AS Trend_ID,
                CASE (rn-1) % 5
                    WHEN 0 THEN N''电''
                    WHEN 1 THEN N''水''
                    WHEN 2 THEN N''蒸汽''
                    WHEN 3 THEN N''天然气''
                    ELSE N''光伏''
                END AS Energy_Type,
                CASE (rn-1) % 3
                    WHEN 0 THEN N''日''
                    WHEN 1 THEN N''周''
                    ELSE N''月''
                END AS Stat_Cycle,
                DATEADD(DAY, -1*(rn-1), CONVERT(date, GETDATE())) AS Stat_Date,
                CAST( 800 + rn*11 AS DECIMAL(12,3)) AS Value,
                CAST( -5 + (rn%11) AS DECIMAL(5,2)) AS YOY_Rate,
                CAST( -3 + (rn%9)  AS DECIMAL(5,2)) AS MOM_Rate,
                Config_ID,
                NULL AS Analyst_ID,
                CAST( 780 + rn*10 AS DECIMAL(12,3)) AS Industry_Avg,
                CASE WHEN (-5 + (rn%11)) < 0 THEN N''同比下降''
                     WHEN (-5 + (rn%11)) > 0 THEN N''同比上升''
                     ELSE N''同比持平'' END AS Trend_Tag
            FROM seq
        )
        INSERT INTO dbo.Stat_History_Trend
            (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date, Value, YOY_Rate, MOM_Rate, Config_ID, Analyst_ID, Industry_Avg, Trend_Tag)
        SELECT
            s.Trend_ID, s.Energy_Type, s.Stat_Cycle, s.Stat_Date, s.Value, s.YOY_Rate, s.MOM_Rate, s.Config_ID, s.Analyst_ID, s.Industry_Avg, s.Trend_Tag
        FROM src s
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Stat_History_Trend t WHERE t.Trend_ID = s.Trend_ID);
    ');

    /* ------------------------------------------------------------
       5) 视图 >= 3（动态创建，重复执行先 DROP 再 CREATE）
       ------------------------------------------------------------ */

    -- 5.1 企业管理层：各模块最新一条实时数据（用于大屏刷新）
    IF OBJECT_ID('dbo.View_Exec_Latest_Dashboard', 'V') IS NOT NULL
        EXEC(N'DROP VIEW dbo.View_Exec_Latest_Dashboard;');

    EXEC(N'
        CREATE VIEW dbo.View_Exec_Latest_Dashboard AS
        SELECT
            c.Config_ID,
            c.Module_Name,
            c.Auth_Level,
            r.Stat_Time,
            r.Total_KWH,
            r.Total_Alarm,
            r.PV_Gen_KWH,
            r.Total_Water_m3,
            r.Total_Steam_t,
            r.Total_Gas_m3,
            r.Alarm_High,
            r.Alarm_Mid,
            r.Alarm_Low,
            r.Alarm_Unprocessed
        FROM dbo.Dashboard_Config c
        OUTER APPLY (
            SELECT TOP 1 *
            FROM dbo.Stat_Realtime rr
            WHERE rr.Config_ID = c.Config_ID
            ORDER BY rr.Stat_Time DESC
        ) r
        WHERE c.Auth_Level IN (N''企业管理层'', N''管理员'') OR c.Auth_Level IS NULL;
    ');

    -- 5.2 企业管理层：近 370 天趋势（同比/环比/行业均值/趋势标签）
    IF OBJECT_ID('dbo.View_Exec_Trend_Recent', 'V') IS NOT NULL
        EXEC(N'DROP VIEW dbo.View_Exec_Trend_Recent;');

    EXEC(N'
        CREATE VIEW dbo.View_Exec_Trend_Recent AS
        SELECT
            t.Energy_Type,
            t.Stat_Cycle,
            t.Stat_Date,
            t.Value,
            t.Industry_Avg,
            t.YOY_Rate,
            t.MOM_Rate,
            t.Trend_Tag,
            c.Module_Name
        FROM dbo.Stat_History_Trend t
        LEFT JOIN dbo.Dashboard_Config c ON c.Config_ID = t.Config_ID
        WHERE t.Stat_Date >= DATEADD(DAY, -370, CONVERT(date, GETDATE()));
    ');

    -- 5.3 企业管理层：近 24 小时告警统计（若 Alarm_Info 存在）
    IF OBJECT_ID('dbo.View_Exec_Alarm_Stats_24h', 'V') IS NOT NULL
        EXEC(N'DROP VIEW dbo.View_Exec_Alarm_Stats_24h;');

    IF OBJECT_ID('dbo.Alarm_Info','U') IS NOT NULL
    BEGIN
        EXEC(N'
            CREATE VIEW dbo.View_Exec_Alarm_Stats_24h AS
            SELECT
                CONVERT(date, a.Occur_Time) AS [Date],
                COUNT(*) AS Total_Alarm,
                SUM(CASE WHEN a.Alarm_Level = N''高'' THEN 1 ELSE 0 END) AS High_Alarm,
                SUM(CASE WHEN a.Alarm_Level = N''中'' THEN 1 ELSE 0 END) AS Mid_Alarm,
                SUM(CASE WHEN a.Alarm_Level = N''低'' THEN 1 ELSE 0 END) AS Low_Alarm,
                SUM(CASE WHEN a.Process_Status = N''未处理'' THEN 1 ELSE 0 END) AS Unprocessed_Alarm
            FROM dbo.Alarm_Info a
            WHERE a.Occur_Time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
            GROUP BY CONVERT(date, a.Occur_Time);
        ');
    END
    ELSE
    BEGIN
        -- 若无告警表，则创建一个空壳视图，避免整体失败
        EXEC(N'
            CREATE VIEW dbo.View_Exec_Alarm_Stats_24h AS
            SELECT
                CONVERT(date, GETDATE()) AS [Date],
                CAST(0 AS INT) AS Total_Alarm,
                CAST(0 AS INT) AS High_Alarm,
                CAST(0 AS INT) AS Mid_Alarm,
                CAST(0 AS INT) AS Low_Alarm,
                CAST(0 AS INT) AS Unprocessed_Alarm
            WHERE 1=0;
        ');
    END;

    /* ------------------------------------------------------------
       6) 触发器 1：实时总用电量环比上升 > 15% => 写入 Alarm_Info（若表存在）
       ------------------------------------------------------------ */

IF OBJECT_ID('dbo.Alarm_Info','U') IS NOT NULL
BEGIN
    IF OBJECT_ID('dbo.TRG_StatRealtime_ConsumptionSpike','TR') IS NOT NULL
        EXEC(N'DROP TRIGGER dbo.TRG_StatRealtime_ConsumptionSpike;');

    EXEC(N'
        CREATE TRIGGER dbo.TRG_StatRealtime_ConsumptionSpike
        ON dbo.Stat_Realtime
        AFTER INSERT
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH ins AS (
                SELECT
                    i.Summary_ID,
                    i.Stat_Time,
                    i.Total_KWH,
                    i.Config_ID
                FROM inserted i
                WHERE i.Total_KWH IS NOT NULL
                  AND i.Stat_Time IS NOT NULL
            ),
            prev AS (
                SELECT
                    ins.Summary_ID,
                    ins.Stat_Time,
                    ins.Total_KWH AS Cur_KWH,
                    p.Prev_KWH
                FROM ins
                OUTER APPLY (
                    SELECT TOP 1 r.Total_KWH AS Prev_KWH
                    FROM dbo.Stat_Realtime r
                    WHERE
                        (
                            (r.Config_ID = ins.Config_ID)
                            OR (r.Config_ID IS NULL AND ins.Config_ID IS NULL)
                        )
                        AND r.Stat_Time < ins.Stat_Time
                        AND r.Total_KWH IS NOT NULL
                    ORDER BY r.Stat_Time DESC
                ) p
            ),
            spike AS (
                SELECT
                    Summary_ID,
                    Stat_Time,
                    Cur_KWH,
                    Prev_KWH,
                    CASE
                        WHEN Prev_KWH IS NULL OR Prev_KWH = 0 THEN NULL
                        ELSE (Cur_KWH - Prev_KWH) / NULLIF(Prev_KWH, 0)
                    END AS RiseRate
                FROM prev
            )
            INSERT INTO dbo.Alarm_Info
                (Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Ledger_ID, Factory_ID)
            SELECT
                N''其他'' AS Alarm_Type, -- 兼容 CK_Alarm_Type
                CASE WHEN s.RiseRate > 0.30 THEN N''高'' ELSE N''中'' END AS Alarm_Level,
                CONCAT(
                    N''总用电量突增：当前 '', CONVERT(NVARCHAR(30), s.Cur_KWH), N'' kWh；上一周期 '',
                    CONVERT(NVARCHAR(30), s.Prev_KWH), N'' kWh；上升 '',
                    CONVERT(NVARCHAR(10), CAST(s.RiseRate*100 AS DECIMAL(6,2))), N''%（Summary_ID='',
                    s.Summary_ID, N''）''
                ) AS Content,
                s.Stat_Time AS Occur_Time,         -- ✅ 用本次插入的统计时间
                N''未处理'' AS Process_Status,
                NULL AS Ledger_ID,
                NULL AS Factory_ID
            FROM spike s
            WHERE s.RiseRate IS NOT NULL AND s.RiseRate > 0.15;
        END
    ');
END;

    COMMIT TRAN;
    PRINT N'Patch v4 applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    DECLARE @ErrMsg NVARCHAR(4000)=ERROR_MESSAGE(),
            @ErrLine INT=ERROR_LINE(),
            @ErrNum  INT=ERROR_NUMBER(),
            @ErrSev  INT=ERROR_SEVERITY(),
            @ErrSta  INT=ERROR_STATE();

    RAISERROR(N'Patch v4 failed. Error %d, Severity %d, State %d, Line %d: %s',
              16, 1, @ErrNum, @ErrSev, @ErrSta, @ErrLine, @ErrMsg);
END CATCH;
