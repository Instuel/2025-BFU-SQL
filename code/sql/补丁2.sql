/* ============================================================
   智慧能源管理系统 - 管理层大屏（ExecDashboardDao）缺表/缺列修复补丁
   目标数据库：SQL_BFU
   作用：
   1) 修复 Research_Project 缺表/缺列（用于统计待处理项目等）
   2) 修复 Exec_Decision_Item 缺表/列名不一致（Decision_ID 等）
   说明：脚本可重复执行（幂等），不会重复建表；会按需补列/改列名
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   1) Research_Project：按 ExecDashboardDao 需要的字段对齐
   备注：如果表已存在但列不全，会自动补齐缺列
   ============================================================ */
IF OBJECT_ID('dbo.Research_Project', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Research_Project (
        Project_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Research_Project PRIMARY KEY,
        Project_Title   NVARCHAR(200) NOT NULL,
        Project_Summary NVARCHAR(1000) NULL,
        Applicant       NVARCHAR(50)  NULL,
        Apply_Date      DATETIME2(0)  NOT NULL CONSTRAINT DF_Research_Project_ApplyDate DEFAULT SYSDATETIME(),
        Project_Status  NVARCHAR(20)  NOT NULL CONSTRAINT DF_Research_Project_Status DEFAULT N'申报中',
        Close_Report    NVARCHAR(2000) NULL,
        Close_Date      DATETIME2(0)  NULL
    );

    CREATE INDEX IX_Research_Project_ApplyDate ON dbo.Research_Project(Apply_Date DESC);
END
ELSE
BEGIN
    -- 补列（存在则跳过）
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

    -- 兜底默认值（只在默认约束不存在时添加；不覆盖现有约束）
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
        ADD CONSTRAINT DF_Research_Project_Status DEFAULT (N'申报中') FOR Project_Status;
    END

    -- 索引兜底
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

-- 可选：插入一些测试数据，避免大屏为空（只在表为空时插入）
IF NOT EXISTS (SELECT 1 FROM dbo.Research_Project)
BEGIN
    INSERT INTO dbo.Research_Project(Project_Title, Project_Summary, Applicant, Apply_Date, Project_Status)
    VALUES
    (N'能耗优化一期', N'峰谷电策略优化与用能诊断', N'系统管理员', DATEADD(DAY,-12,SYSDATETIME()), N'申报中'),
    (N'光伏并网收益评估', N'自发自用与上网收益测算', N'能源管理员', DATEADD(DAY,-35,SYSDATETIME()), N'结题中'),
    (N'告警联动改造', N'告警-工单-派单联动流程优化', N'调度员', DATEADD(DAY,-70,SYSDATETIME()), N'已结题');
END
GO


/* ============================================================
   2) Exec_Decision_Item：修复“Decision_ID 无效”等列名不一致问题
   - 你的代码在查：Decision_ID / Decision_Type / Title / Description / Status / Estimate_Cost / Expected_Saving / Created_Time / Alarm_ID
   - 如果你之前建的是 Item_* 列，会在这里自动改名
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
    -- 如果你旧表是 Item_* 命名，按需改名为代码期望的命名
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

    -- 补列（存在则跳过）
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

    -- 兜底默认约束（仅在不存在时添加）
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

-- 索引（提升列表/排序）
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

-- 可选：插入几条测试数据（只在表为空时插入）
IF NOT EXISTS (SELECT 1 FROM dbo.Exec_Decision_Item)
BEGIN
    INSERT INTO dbo.Exec_Decision_Item(Decision_Type, Title, Description, Status, Estimate_Cost, Expected_Saving, Created_Time, Alarm_ID)
    VALUES
    (N'能耗优化', N'本月能耗异常复盘', N'对峰值时段异常点进行复核并给出整改建议', N'待处理', NULL, NULL, DATEADD(DAY,-2,SYSDATETIME()), NULL),
    (N'运维改进', N'告警派单效率提升', N'优化告警→工单→派单流程与超时提醒', N'进行中', NULL, NULL, DATEADD(DAY,-10,SYSDATETIME()), NULL),
    (N'数据治理', N'管理层大屏指标校验', N'核对本月统计口径与数据源一致性', N'已完成', NULL, NULL, DATEADD(DAY,-25,SYSDATETIME()), NULL);
END
GO

/* ============================================================
   完成。若后续仍报“对象名/列名无效”，请把报错信息贴出来继续对齐。
   ============================================================ */
