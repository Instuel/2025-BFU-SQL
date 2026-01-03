USE SQL_BFU;
GO

IF OBJECT_ID('dbo.Research_Project', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Research_Project (
        Project_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Research_Project PRIMARY KEY,
        Project_Title   NVARCHAR(100) NOT NULL,
        Project_Summary NVARCHAR(500) NULL,
        Applicant       NVARCHAR(50)  NULL,
        Apply_Date      DATETIME2(0)  NOT NULL CONSTRAINT DF_Research_Project_ApplyDate DEFAULT SYSDATETIME(),
        Project_Status  NVARCHAR(20)  NOT NULL CONSTRAINT DF_Research_Project_Status DEFAULT N'申报中',
        Close_Report    NVARCHAR(500) NULL,
        Close_Date      DATETIME2(0)  NULL
    );

    CREATE INDEX IX_Research_Project_ApplyDate ON dbo.Research_Project(Apply_Date DESC);
END
GO

-- 可选：插入一些测试数据，避免大屏为空
IF NOT EXISTS (SELECT 1 FROM dbo.Research_Project)
BEGIN
    INSERT INTO dbo.Research_Project(Project_Title, Project_Summary, Applicant, Apply_Date, Project_Status)
    VALUES
    (N'能耗优化一期', N'峰谷电策略优化与用能诊断', N'系统管理员', DATEADD(DAY,-12,SYSDATETIME()), N'申报中'),
    (N'光伏并网收益评估', N'自发自用与上网收益测算', N'能源管理员', DATEADD(DAY,-35,SYSDATETIME()), N'结题中'),
    (N'告警联动改造', N'告警-工单-派单联动流程优化', N'调度员', DATEADD(DAY,-70,SYSDATETIME()), N'已结题');
END
GO
