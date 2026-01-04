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

PRINT N'大屏数据业务线补丁完成。'
GO

/* ============================================================
   告警管理业务补丁
   ============================================================ */
USE SQL_BFU;
GO


-- 0) 确认表存在
IF OBJECT_ID('dbo.Alarm_Info', 'U') IS NULL
BEGIN
    THROW 50001, 'dbo.Alarm_Info 表不存在，请先执行数据库初始化脚本.sql', 1;
END
GO

-- 1) 补 Verify_Status（告警真实性：待审核/有效/误报）
IF COL_LENGTH('dbo.Alarm_Info', 'Verify_Status') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Verify_Status NVARCHAR(10) NULL;
END
GO

-- 2) 补 Verify_Remark（复核说明）
IF COL_LENGTH('dbo.Alarm_Info', 'Verify_Remark') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Verify_Remark NVARCHAR(200) NULL;
END
GO

-- 3) 补 Trigger_Threshold（告警触发阈值，代码也在查这个）
IF COL_LENGTH('dbo.Alarm_Info', 'Trigger_Threshold') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info
    ADD Trigger_Threshold DECIMAL(12,3) NULL;
END
GO

USE SQL_BFU;
GO

SET NOCOUNT ON;

PRINT '正在执行：告警管理业务线约束与数据修正...';

/* ============================================================
   Step 1: 暴力清理旧约束 (防止改名或重复导致的报错)
   我们先查出所有绑定在 Verify_Status 上的约束并删除
   ============================================================ */
DECLARE @ConstraintName NVARCHAR(200);
DECLARE @TableName NVARCHAR(50) = 'dbo.Alarm_Info';
DECLARE @ColName NVARCHAR(50) = 'Verify_Status';

-- 1.1 清理默认值约束 (不管它叫什么名字)
SELECT @ConstraintName = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_column_id = c.column_id AND dc.parent_object_id = c.object_id
WHERE dc.parent_object_id = OBJECT_ID(@TableName) 
  AND c.name = @ColName;

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName);
    PRINT '  - 已删除旧默认值约束: ' + @ConstraintName;
END

-- 1.2 清理 CHECK 约束 (清理所有可能的旧名字)
-- 我们循环删除，直到删干净为止（防止表上同时挂了新旧两个约束）
WHILE EXISTS (
    SELECT 1 FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID(@TableName) 
      AND (name = 'CK_Alarm_Verify' OR name = 'CK_Alarm_Verify_Status') -- 覆盖新旧两个名字
)
BEGIN
    SELECT TOP 1 @ConstraintName = name 
    FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID(@TableName) 
      AND (name = 'CK_Alarm_Verify' OR name = 'CK_Alarm_Verify_Status');
      
    EXEC('ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @ConstraintName);
    PRINT '  - 已删除旧 CHECK 约束: ' + @ConstraintName;
END
GO

/* ============================================================
   Step 2: 旧数据兜底 (防止脏数据导致新约束创建失败)
   必须在创建 CHECK 约束之前执行！
   ============================================================ */
-- 临时禁用触发器，防止批量更新时触发工单同步逻辑
DISABLE TRIGGER ALL ON dbo.Alarm_Info;

UPDATE dbo.Alarm_Info
SET Verify_Status = N'待审核'
WHERE Verify_Status IS NULL 
   OR Verify_Status NOT IN (N'待审核', N'有效', N'误报'); -- 顺便修复不合规的值

PRINT '  - 已修正历史数据的 Verify_Status 为 [待审核] (' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' 行受影响)';

ENABLE TRIGGER ALL ON dbo.Alarm_Info;
GO

/* ============================================================
   Step 3: 重建标准约束
   ============================================================ */
-- 3.1 添加默认值：新告警默认“待审核”
ALTER TABLE dbo.Alarm_Info
ADD CONSTRAINT DF_Alarm_Info_Verify_Status DEFAULT (N'待审核') FOR Verify_Status;
PRINT '  - 已创建新默认值约束: DF_Alarm_Info_Verify_Status';

-- 3.2 添加 CHECK 约束：限制取值范围
ALTER TABLE dbo.Alarm_Info WITH CHECK
ADD CONSTRAINT CK_Alarm_Verify_Status
CHECK (Verify_Status IN (N'待审核', N'有效', N'误报') OR Verify_Status IS NULL);
PRINT '  - 已创建新 CHECK 约束: CK_Alarm_Verify_Status';
GO

PRINT '告警管理业务线补丁执行完成。';

GO


/* ============================================================
   综合能耗业务补丁
   ============================================================ */

USE SQL_BFU;
GO

-- 1) 如已存在同名视图，先删掉
IF OBJECT_ID('View_PeakValley_Dynamic', 'V') IS NOT NULL
    DROP VIEW View_PeakValley_Dynamic;
GO

-- 2) 创建动态峰谷视图：按当前 Config_PeakValley 重新分段统计
CREATE VIEW View_PeakValley_Dynamic AS
SELECT
    CAST(e.Collect_Time AS DATE)                   AS Stat_Date,
    m.Energy_Type                                  AS Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID)            AS Factory_ID,
    c.Time_Type                                    AS Peak_Type,       -- 尖峰/高峰/平段/低谷
    SUM(e.Value)                                   AS Total_Consumption,
    SUM(e.Value * c.Price_Rate)                    AS Cost_Amount
FROM Data_Energy e
JOIN Energy_Meter m
    ON e.Meter_ID = m.Meter_ID
JOIN Config_PeakValley c
    ON CAST(e.Collect_Time AS TIME(0)) >= c.Start_Time
   AND CAST(e.Collect_Time AS TIME(0)) <  c.End_Time
GROUP BY
    CAST(e.Collect_Time AS DATE),
    m.Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID),
    c.Time_Type;
GO

PRINT N'综合能耗业务线补丁完成。'
GO


USE SQL_BFU;
GO

/* ============================================================
   配电网补丁
   第一部分：修改表结构
   功能：为 Role_OandM（运维人员表）增加 Factory_ID（所属厂区）
   ============================================================ */

-- 1. 添加 Factory_ID 字段 (允许为空，以兼容现有数据)
IF COL_LENGTH('dbo.Role_OandM', 'Factory_ID') IS NULL
BEGIN
    ALTER TABLE dbo.Role_OandM
    ADD Factory_ID BIGINT NULL;
    
    PRINT '已成功向 Role_OandM 表添加 Factory_ID 字段。';
END
GO

-- 2. 添加外键约束 (关联到 Base_Factory 表)
IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys 
    WHERE name = 'FK_OandM_Factory' AND parent_object_id = OBJECT_ID('dbo.Role_OandM')
)
BEGIN
    ALTER TABLE dbo.Role_OandM
    ADD CONSTRAINT FK_OandM_Factory
    FOREIGN KEY (Factory_ID) REFERENCES dbo.Base_Factory(Factory_ID);

    PRINT '已成功添加外键约束 FK_OandM_Factory。';
END
GO


/* ============================================================
   第二部分：插入 5 条运维人员测试数据
   说明：
   1. 自动确保 Base_Factory 有数据
   2. 创建 Sys_User 账号 (密码统一为 123456)
   3. 创建 Role_OandM 记录并分配厂区
   4. 创建 Sys_Role_Assignment 赋予 OM 角色权限
   ============================================================ */

-- 0. [前置准备] 确保至少有几个厂区用于测试
IF NOT EXISTS (SELECT 1 FROM dbo.Base_Factory)
BEGIN
    INSERT INTO dbo.Base_Factory (Factory_Name, Area_Desc) VALUES 
    (N'一号厂区', N'东部生产基地'),
    (N'二号厂区', N'西部物流中心'),
    (N'三号厂区', N'南部研发中心');
END
GO

-- 1. [创建用户] 插入5个测试账号 (om_test_01 ~ 05)
-- 密码哈希对应明文: 123456
INSERT INTO dbo.Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
SELECT * FROM (VALUES
    ('om_test_01', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '张巡检', '运维一部', '13900000001', 1),
    ('om_test_02', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '王维修', '运维一部', '13900000002', 1),
    ('om_test_03', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '李电工', '运维二部', '13900000003', 1),
    ('om_test_04', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '赵技师', '运维二部', '13900000004', 1),
    ('om_test_05', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '刘值班', '设施部',   '13900000005', 1)
) AS S(Acct, Pwd, Salt, Name, Dept, Phone, Stat)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Sys_User WHERE Login_Account = S.Acct);
GO

-- 2. [分配角色与厂区] 将用户关联到 Role_OandM 并指定 Factory_ID
-- 逻辑：前2人分配到第1个厂区，中间2人分配到第2个厂区，最后1人分配到第3个厂区
DECLARE @F1 BIGINT = (SELECT TOP 1 Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID ASC);
DECLARE @F2 BIGINT = (SELECT TOP 1 Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID DESC); -- 偷懒取最后一个，假设只有2-3个厂区
DECLARE @F3 BIGINT = ISNULL((SELECT Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY), @F1);

INSERT INTO dbo.Role_OandM (User_ID, Factory_ID)
SELECT 
    u.User_ID,
    CASE 
        WHEN u.Login_Account IN ('om_test_01', 'om_test_02') THEN @F1
        WHEN u.Login_Account IN ('om_test_03', 'om_test_04') THEN @F3
        ELSE @F2 
    END
FROM dbo.Sys_User u
WHERE u.Login_Account IN ('om_test_01', 'om_test_02', 'om_test_03', 'om_test_04', 'om_test_05')
  AND NOT EXISTS (SELECT 1 FROM dbo.Role_OandM WHERE User_ID = u.User_ID);
GO

-- 3. [赋予权限] 在 Sys_Role_Assignment 中注册角色类型
INSERT INTO dbo.Sys_Role_Assignment (User_ID, Role_Type)
SELECT u.User_ID, 'OM'
FROM dbo.Sys_User u
WHERE u.Login_Account IN ('om_test_01', 'om_test_02', 'om_test_03', 'om_test_04', 'om_test_05')
  AND NOT EXISTS (SELECT 1 FROM dbo.Sys_Role_Assignment WHERE User_ID = u.User_ID AND Role_Type = 'OM');
GO

PRINT '✓ 已完成表结构修改与 5 条运维人员测试数据插入。';

/* ============================================================
   设备台账表 (Device_Ledger) 结构扩展
   功能：增加所属厂区 (Factory_ID) 并建立外键关联
   ============================================================ */

-- 1. 添加 Factory_ID 字段
-- 说明：先允许为 NULL，方便处理旧数据；等数据补全后可视情况改为 NOT NULL
IF COL_LENGTH('dbo.Device_Ledger', 'Factory_ID') IS NULL
BEGIN
    ALTER TABLE dbo.Device_Ledger
    ADD Factory_ID BIGINT NULL;
    
    PRINT N'已成功向 Device_Ledger 表添加 Factory_ID 字段。';
END
GO

-- 2. 【关键步骤】初始化旧数据的 Factory_ID
-- 说明：在建立外键之前，必须确保现有数据有合法的 Factory_ID，否则 NULL 或非法值可能导致业务逻辑问题（虽外键允许NULL，但建议初始化）
-- 逻辑：
--   变压器1号 (Ledger_ID=1) -> 分配给第1个厂区
--   电表1号 (Ledger_ID=2)   -> 分配给第1个厂区
--   逆变器1号 (Ledger_ID=3) -> 分配给第2个厂区
--   环境传感器1 (Ledger_ID=4) -> 分配给第3个厂区 (若无则分配给第1个)

IF EXISTS (SELECT 1 FROM dbo.Device_Ledger WHERE Factory_ID IS NULL) AND EXISTS (SELECT 1 FROM dbo.Base_Factory)
BEGIN
    DECLARE @F1 BIGINT = (SELECT TOP 1 Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID ASC);
    DECLARE @F2 BIGINT = (SELECT TOP 1 Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID DESC);
    DECLARE @F3 BIGINT = ISNULL((SELECT Factory_ID FROM dbo.Base_Factory ORDER BY Factory_ID OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY), @F1);

    -- 更新 Ledger_ID = 1, 2 (变压器, 电表)
    UPDATE dbo.Device_Ledger 
    SET Factory_ID = @F1 
    WHERE Ledger_ID IN (1, 2) AND Factory_ID IS NULL;

    -- 更新 Ledger_ID = 3 (逆变器)
    UPDATE dbo.Device_Ledger 
    SET Factory_ID = @F2 
    WHERE Ledger_ID = 3 AND Factory_ID IS NULL;

    -- 更新 Ledger_ID = 4 (环境传感器)
    UPDATE dbo.Device_Ledger 
    SET Factory_ID = @F3 
    WHERE Ledger_ID = 4 AND Factory_ID IS NULL;
    
    -- 兜底：如果还有其他的 NULL，统一给第一个厂区
    UPDATE dbo.Device_Ledger
    SET Factory_ID = @F1
    WHERE Factory_ID IS NULL;

    PRINT '已完成现有设备台账的厂区归属初始化。';
END
GO

-- 3. 添加外键约束
IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys 
    WHERE name = 'FK_DeviceLedger_Factory' AND parent_object_id = OBJECT_ID('dbo.Device_Ledger')
)
BEGIN
    ALTER TABLE dbo.Device_Ledger
    ADD CONSTRAINT FK_DeviceLedger_Factory
    FOREIGN KEY (Factory_ID) REFERENCES dbo.Base_Factory(Factory_ID);

    PRINT '已成功添加外键约束 FK_DeviceLedger_Factory。';
END
GO

PRINT N'配电网业务线补丁完成。'
GO

SELECT 
    name AS [约束名],
    definition AS [约束定义/公式],
    parent_object_id,
    OBJECT_NAME(parent_object_id) AS [所属表名]
FROM 
    sys.check_constraints
WHERE 
    name = 'CK_Alarm_Verify_Status'; -- 这里换成你要查的约束名
