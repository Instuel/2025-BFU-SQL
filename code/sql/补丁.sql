/* ============================================================
   智慧能源管理系统 - 修复缺失的ExecDashboardDao相关缺失/缺陷修改补丁
   目标数据库：SQL_BFU
   用途：
   1) 修改 Research_Project 缺失/缺陷，便于统计大屏相关项目等；
   2) 修改 Exec_Decision_Item 缺失/重命名一致，Decision_ID 等；
   说明：脚本可重复执行，幂等，避免重复插入数据会按主键更新/跳过。
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   1) Research_Project补充 ExecDashboardDao 需要的字段定义
   备注：如果表已存在则不全量重建，自动补充缺失
   ============================================================ */
IF OBJECT_ID('dbo.Research_Project', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Research_Project (
        Project_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Research_Project PRIMARY KEY,
        Project_Title   NVARCHAR(200) NOT NULL,
        Project_Summary NVARCHAR(1000) NULL,
        Applicant       NVARCHAR(50)  NULL,
        Apply_Date      DATETIME2(0)  NOT NULL CONSTRAINT DF_Research_Project_ApplyDate DEFAULT SYSDATETIME(),
        Project_Status  NVARCHAR(20)  NOT NULL CONSTRAINT DF_Research_Project_Status DEFAULT N'待规划',
        Close_Report    NVARCHAR(2000) NULL,
        Close_Date      DATETIME2(0)  NULL
    );

    CREATE INDEX IX_Research_Project_ApplyDate ON dbo.Research_Project(Apply_Date DESC);
END
ELSE
BEGIN
    -- 检查，补充缺失字段
    IF COL_LENGTH('dbo.Research_Project','Project_Title') IS NULL
        ALTER TABLE dbo.Research_Project ADD Project_Title NVARCHAR(200) NULL;
    IF COL_LENGTH('dbo.Research_Project','Project_Summary') IS NULL
        ALTER TABLE dbo.Research_Project ADD Project_Summary NVARCHAR(1000) NULL;
    IF COL_LENGTH('dbo.Research_Project','Applicant') IS NULL
        ALTER TABLE dbo.Research_Project ADD Applicant NVARCHAR(50) NULL;
    IF COL_LENGTH('dbo.Research_Project','Apply_Date') IS NULL
        ALTER TABLE dbo.Research_Project ADD Apply_Date DATETIME2(0) NULL;
    IF COL_LENGTH('dbo.Research_Project','Project_Status') IS NULL
        ALTER TABLE dbo.Research_Project ADD Project_Status NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.Research_Project','Close_Report') IS NULL
        ALTER TABLE dbo.Research_Project ADD Close_Report NVARCHAR(2000) NULL;
    IF COL_LENGTH('dbo.Research_Project','Close_Date') IS NULL
        ALTER TABLE dbo.Research_Project ADD Close_Date DATETIME2(0) NULL;

    -- 添加默认值，只在默认约束不存在时添加，避免重复约束错误
    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.default_object_id = dc.object_id
        WHERE dc.parent_object_id = OBJECT_ID('dbo.Research_Project')
          AND c.name = 'Apply_Date'
    )
    BEGIN
        ALTER TABLE dbo.Research_Project
        ADD CONSTRAINT DF_Research_Project_ApplyDate DEFAULT SYSDATETIME() FOR Apply_Date;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.default_object_id = dc.object_id
        WHERE dc.parent_object_id = OBJECT_ID('dbo.Research_Project')
          AND c.name = 'Project_Status'
    )
    BEGIN
        ALTER TABLE dbo.Research_Project
        ADD CONSTRAINT DF_Research_Project_Status DEFAULT (N'待规划') FOR Project_Status;
    END

    -- 添加索引
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID('dbo.Research_Project')
          AND name = 'IX_Research_Project_ApplyDate'
    )
    BEGIN
        CREATE INDEX IX_Research_Project_ApplyDate ON dbo.Research_Project(Apply_Date DESC);
    END
END
GO

-- 可选：插入一些测试数据，如果表为空，只在表为空时插入）
IF NOT EXISTS (SELECT 1 FROM dbo.Research_Project)
BEGIN
    INSERT INTO dbo.Research_Project(Project_Title, Project_Summary, Applicant, Apply_Date, Project_Status)
    VALUES
    (N'能耗优化一期', N'针对电力能耗优化相关研究', N'系统管理员', DATEADD(DAY,-12,SYSDATETIME()), N'待规划'),
    (N'光伏发电效率研究', N'对光伏发电效率提升的研究', N'能源管理员', DATEADD(DAY,-35,SYSDATETIME()), N'进行中'),
    (N'储能系统研究', N'储能-电网-负载联合优化研究', N'研究员', DATEADD(DAY,-70,SYSDATETIME()), N'已结束');
END
GO


/* ============================================================
   2) Exec_Decision_Item表修改：Decision_ID 有效性，重命名一致性等
   - 期待存在的列：Decision_ID / Decision_Type / Title / Description / Status / Estimate_Cost / Expected_Saving / Created_Time / Alarm_ID
   - 如果之前建表用 Item_* 列，则自动重命名
   ============================================================ */
IF OBJECT_ID('dbo.Exec_Decision_Item', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Exec_Decision_Item (
        Decision_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Exec_Decision_Item PRIMARY KEY,
        Decision_Type    NVARCHAR(50)  NULL,
        Title            NVARCHAR(200) NOT NULL,
        Description      NVARCHAR(2000) NULL,
        Status           NVARCHAR(20)  NOT NULL CONSTRAINT DF_ExecDecision_Status DEFAULT(N'待处理'),
        Estimate_Cost    DECIMAL(18,2) NULL,
        Expected_Saving  DECIMAL(18,2) NULL,
        Created_Time     DATETIME2(0)  NOT NULL CONSTRAINT DF_ExecDecision_Created DEFAULT SYSDATETIME(),
        Alarm_ID         BIGINT NULL
    );
END
ELSE
BEGIN
    -- 如果可能表用 Item_* 列名，则重命名为期待的列名
    IF COL_LENGTH('dbo.Exec_Decision_Item','Decision_ID') IS NULL
       AND COL_LENGTH('dbo.Exec_Decision_Item','Item_ID') IS NOT NULL
        EXEC sp_rename 'dbo.Exec_Decision_Item.Item_ID', 'Decision_ID', 'COLUMN';

    IF COL_LENGTH('dbo.Exec_Decision_Item','Title') IS NULL
       AND COL_LENGTH('dbo.Exec_Decision_Item','Item_Title') IS NOT NULL
        EXEC sp_rename 'dbo.Exec_Decision_Item.Item_Title', 'Title', 'COLUMN';

    IF COL_LENGTH('dbo.Exec_Decision_Item','Description') IS NULL
       AND COL_LENGTH('dbo.Exec_Decision_Item','Item_Content') IS NOT NULL
        EXEC sp_rename 'dbo.Exec_Decision_Item.Item_Content', 'Description', 'COLUMN';

    IF COL_LENGTH('dbo.Exec_Decision_Item','Status') IS NULL
       AND COL_LENGTH('dbo.Exec_Decision_Item','Item_Status') IS NOT NULL
        EXEC sp_rename 'dbo.Exec_Decision_Item.Item_Status', 'Status', 'COLUMN';

    -- 检查，补充缺失字段
    IF COL_LENGTH('dbo.Exec_Decision_Item','Decision_Type') IS NULL
        ALTER TABLE dbo.Exec_Decision_Item ADD Decision_Type NVARCHAR(50) NULL;

    IF COL_LENGTH('dbo.Exec_Decision_Item','Estimate_Cost') IS NULL
        ALTER TABLE dbo.Exec_Decision_Item ADD Estimate_Cost DECIMAL(18,2) NULL;

    IF COL_LENGTH('dbo.Exec_Decision_Item','Expected_Saving') IS NULL
        ALTER TABLE dbo.Exec_Decision_Item ADD Expected_Saving DECIMAL(18,2) NULL;

    IF COL_LENGTH('dbo.Exec_Decision_Item','Created_Time') IS NULL
        ALTER TABLE dbo.Exec_Decision_Item ADD Created_Time DATETIME2(0) NULL;

    IF COL_LENGTH('dbo.Exec_Decision_Item','Alarm_ID') IS NULL
        ALTER TABLE dbo.Exec_Decision_Item ADD Alarm_ID BIGINT NULL;

    -- 添加默认约束（仅在不存在时添加）
    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.default_object_id = dc.object_id
        WHERE dc.parent_object_id = OBJECT_ID('dbo.Exec_Decision_Item')
          AND c.name = 'Status'
    )
    BEGIN
        ALTER TABLE dbo.Exec_Decision_Item
        ADD CONSTRAINT DF_ExecDecision_Status DEFAULT (N'待处理') FOR Status;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.default_object_id = dc.object_id
        WHERE dc.parent_object_id = OBJECT_ID('dbo.Exec_Decision_Item')
          AND c.name = 'Created_Time'
    )
    BEGIN
        ALTER TABLE dbo.Exec_Decision_Item
        ADD CONSTRAINT DF_ExecDecision_Created DEFAULT (SYSDATETIME()) FOR Created_Time;
    END
END
GO

-- 添加索引（列表/排序）
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Exec_Decision_Item')
      AND name = 'IX_ExecDecision_CreatedTime'
)
BEGIN
    CREATE INDEX IX_ExecDecision_CreatedTime
    ON dbo.Exec_Decision_Item(Created_Time DESC, Decision_ID DESC);
END
GO

-- 可选：插入几条测试数据，只在表为空时插入）
IF NOT EXISTS (SELECT 1 FROM dbo.Exec_Decision_Item)
BEGIN
    INSERT INTO dbo.Exec_Decision_Item(Decision_Type, Title, Description, Status, Estimate_Cost, Expected_Saving, Created_Time, Alarm_ID)
    VALUES
    (N'能耗优化', N'处理能耗异常告警', N'对发电时段异常进行深入分析并制定解决方案', N'待处理', NULL, NULL, DATEADD(DAY,-2,SYSDATETIME()), NULL),
    (N'运维改进', N'储能发电效率提升', N'优化储能系统发电效率，减少超时问题', N'待处理', NULL, NULL, DATEADD(DAY,-10,SYSDATETIME()), NULL),
    (N'设备更新', N'配电网设备指标校准', N'针对配电网统计口径进行能源一体化', N'已完成', NULL, NULL, DATEADD(DAY,-25,SYSDATETIME()), NULL);
END
GO

PRINT N'执行决策业务线补丁完成。'
GO

/* ============================================================
   告警管理业务线补丁
   ============================================================ */
USE SQL_BFU;
GO


-- 0) 确认表存在
IF OBJECT_ID('dbo.Alarm_Info', 'U') IS NULL
BEGIN
    THROW 50001, 'dbo.Alarm_Info 表不存在，请先执行数据库初始化脚本.sql', 1;
END
GO

-- 1) 增加 Verify_Status（告警真实性：待审核/有效/误报）
IF COL_LENGTH('dbo.Alarm_Info', 'Verify_Status') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Verify_Status NVARCHAR(10) NULL;
END
GO

-- 2) 增加 Verify_Remark（审核说明）
IF COL_LENGTH('dbo.Alarm_Info', 'Verify_Remark') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Verify_Remark NVARCHAR(200) NULL;
END
GO

-- 3) 增加 Trigger_Threshold（告警触发阈值，便于也在不分析）
IF COL_LENGTH('dbo.Alarm_Info', 'Trigger_Threshold') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Trigger_Threshold DECIMAL(12,3) NULL;
END
GO

-- 4) 默认值：新告警默认"待审核"
IF NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints dc
    JOIN sys.columns c ON c.default_object_id = dc.object_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.Alarm_Info')
      AND c.name = 'Verify_Status'
)
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD CONSTRAINT DF_Alarm_Info_Verify_Status DEFAULT (N'待审核') FOR Verify_Status;
END
GO

-- 5) CHECK 约束（可选，增加数据完整性检查）
IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Alarm_Verify_Status'
      AND parent_object_id = OBJECT_ID('dbo.Alarm_Info')
)
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD CONSTRAINT CK_Alarm_Verify_Status
    CHECK (Verify_Status IN (N'待审核', N'有效', N'误报') OR Verify_Status IS NULL);
END
GO

-- 6) 历史数据修正：空值统一设为"待审核"（匹配页面统计逻辑）
UPDATE dbo.Alarm_Info
SET Verify_Status = N'待审核'
WHERE Verify_Status IS NULL OR LTRIM(RTRIM(Verify_Status)) = N'';
GO

PRINT N'告警管理业务线补丁完成。'
GO

/* ============================================================
   运维工单管理补丁 - 添加 Review_Feedback 字段
   ============================================================ */

-- 添加 Review_Feedback 字段到 Work_Order 表
IF COL_LENGTH('dbo.Work_Order', 'Review_Feedback') IS NULL
BEGIN
    ALTER TABLE dbo.Work_Order
    ADD Review_Feedback NVARCHAR(500) NULL;
    
    PRINT N'已添加 Work_Order.Review_Feedback 字段';
END
ELSE
BEGIN
    PRINT N'Work_Order.Review_Feedback 字段已存在，跳过添加';
END
GO

PRINT N'运维工单管理补丁完成。'
GO
/* ============================================================
   告警处理日志补丁 - 扩展 Status_After 字段长度
   ============================================================ */
IF COL_LENGTH('dbo.Alarm_Handling_Log', 'Status_After') = 20  -- NVARCHAR(10) = 20 bytes
BEGIN
    ALTER TABLE dbo.Alarm_Handling_Log
    ALTER COLUMN Status_After NVARCHAR(200) NULL;
    
    PRINT N'已扩展 Alarm_Handling_Log.Status_After 字段长度至 NVARCHAR(200)';
END
ELSE
BEGIN
    PRINT N'Alarm_Handling_Log.Status_After 字段长度已足够，跳过修改';
END
GO

PRINT N'告警处理日志补丁完成。'
GO