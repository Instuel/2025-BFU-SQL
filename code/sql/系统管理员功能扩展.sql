-- 系统管理员功能扩展：告警规则/备份日志/操作审计

IF OBJECT_ID('Sys_Alarm_Rule', 'U') IS NULL
BEGIN
    CREATE TABLE Sys_Alarm_Rule (
        Rule_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Alarm_Type NVARCHAR(30) NOT NULL,
        Alarm_Level NVARCHAR(10) NOT NULL,
        Threshold_Value DECIMAL(10,2) NULL,
        Threshold_Unit NVARCHAR(20) NULL,
        Notify_Channel NVARCHAR(50) NULL,
        Is_Enabled BIT NOT NULL DEFAULT 1,
        Updated_Time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT CK_AlarmRule_Level CHECK (Alarm_Level IN ('高', '中', '低'))
    );
END

IF OBJECT_ID('Sys_Backup_Log', 'U') IS NULL
BEGIN
    CREATE TABLE Sys_Backup_Log (
        Backup_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Backup_Type NVARCHAR(20) NOT NULL,
        Backup_Path NVARCHAR(200) NULL,
        Status NVARCHAR(20) NOT NULL,
        Operator_ID BIGINT NULL,
        Start_Time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        End_Time DATETIME2(0) NULL,
        Remark NVARCHAR(200) NULL
    );
END

IF OBJECT_ID('Sys_Admin_Audit_Log', 'U') IS NULL
BEGIN
    CREATE TABLE Sys_Admin_Audit_Log (
        Log_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Action_Type NVARCHAR(30) NOT NULL,
        Action_Detail NVARCHAR(200) NULL,
        Operator_ID BIGINT NULL,
        Action_Time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
    );
END

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Role_Type'
      AND parent_object_id = OBJECT_ID('Sys_Role_Assignment')
)
BEGIN
    ALTER TABLE Sys_Role_Assignment DROP CONSTRAINT CK_Role_Type;
END

ALTER TABLE Sys_Role_Assignment
ADD CONSTRAINT CK_Role_Type
    CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER','DEISPATCHER'));
