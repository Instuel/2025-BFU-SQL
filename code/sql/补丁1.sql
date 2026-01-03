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

-- 4) 默认值：新告警默认“待审核”
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

-- 5) CHECK 约束（可选，但建议加，避免乱写）
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

-- 6) 旧数据兜底：空值统一置为“待审核”（匹配你页面统计逻辑）
UPDATE dbo.Alarm_Info
SET Verify_Status = N'待审核'
WHERE Verify_Status IS NULL OR LTRIM(RTRIM(Verify_Status)) = N'';
GO
