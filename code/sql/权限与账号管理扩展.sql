/* ============================================================
   账号管理与权限扩展脚本 (修正版)
   修正点：调整了 DROP TABLE 的顺序，先删子表 Sys_Role_Permission，再删父表 Sys_Permission，防止重复执行脚本报错
   ============================================================ */

USE SQL_BFU;
GO

/* === 1. Sys_User 扩展字段 === */
IF COL_LENGTH('Sys_User', 'Last_Login_Time') IS NULL
BEGIN
    ALTER TABLE Sys_User ADD Last_Login_Time DATETIME2(0) NULL;
END
GO

IF COL_LENGTH('Sys_User', 'Updated_Time') IS NULL
BEGIN
    ALTER TABLE Sys_User ADD Updated_Time DATETIME2(0) NULL;
END
GO

IF COL_LENGTH('Sys_User', 'Created_By') IS NULL
BEGIN
    ALTER TABLE Sys_User ADD Created_By BIGINT NULL;
END
GO

IF COL_LENGTH('Sys_User', 'Updated_By') IS NULL
BEGIN
    ALTER TABLE Sys_User ADD Updated_By BIGINT NULL;
END
GO

/* 可选：审计人字段引用 Sys_User */
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SysUser_CreatedBy'
)
BEGIN
    ALTER TABLE Sys_User ADD CONSTRAINT FK_SysUser_CreatedBy
    FOREIGN KEY (Created_By) REFERENCES Sys_User(User_ID);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SysUser_UpdatedBy'
)
BEGIN
    ALTER TABLE Sys_User ADD CONSTRAINT FK_SysUser_UpdatedBy
    FOREIGN KEY (Updated_By) REFERENCES Sys_User(User_ID);
END
GO

/* === 2. 权限表 (核心修改部分) === */

-- 【重要修改】必须先删除子表 (Sys_Role_Permission)，因为它有外键指向 Sys_Permission
IF OBJECT_ID('Sys_Role_Permission', 'U') IS NOT NULL 
    DROP TABLE Sys_Role_Permission;
GO

-- 【重要修改】子表删除后，现在可以安全删除父表 (Sys_Permission) 了
IF OBJECT_ID('Sys_Permission', 'U') IS NOT NULL 
    DROP TABLE Sys_Permission;
GO

-- 重新创建父表
CREATE TABLE Sys_Permission (
    Perm_Code NVARCHAR(64) PRIMARY KEY,
    Perm_Name NVARCHAR(100) NOT NULL,
    Module NVARCHAR(50) NULL,
    Uri_Pattern NVARCHAR(200) NULL,
    Is_Enabled TINYINT DEFAULT 1,
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME()
);
GO

-- 重新创建子表
CREATE TABLE Sys_Role_Permission (
    Role_Type NVARCHAR(20) NOT NULL,
    Perm_Code NVARCHAR(64) NOT NULL,
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_RolePerm_Perm FOREIGN KEY (Perm_Code) REFERENCES Sys_Permission(Perm_Code),
    CONSTRAINT CK_RolePerm_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'))
);
GO

/* === 3. 初始化权限 === */
INSERT INTO Sys_Permission (Perm_Code, Perm_Name, Module, Uri_Pattern) VALUES
('MODULE_DASHBOARD', N'总览模块', 'dashboard', NULL),
('MODULE_DIST', N'配电网监测模块', 'dist', NULL),
('MODULE_PV', N'分布式光伏模块', 'pv', NULL),
('MODULE_ENERGY', N'综合能耗模块', 'energy', NULL),
('MODULE_ALARM', N'告警运维模块', 'alarm', NULL),
('MODULE_ADMIN', N'系统管理模块', 'admin', NULL),
('MODULE_DISPATCHER', N'运维工单管理模块', 'dispatcher', NULL),
('ADMIN_USER_MANAGE', N'账号管理', NULL, '/admin');
GO

/* === 4. 初始化角色权限 === */
-- 系统管理员：全部模块 + 账号管理
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('ADMIN','MODULE_DASHBOARD'),
('ADMIN','MODULE_DIST'),
('ADMIN','MODULE_PV'),
('ADMIN','MODULE_ENERGY'),
('ADMIN','MODULE_ALARM'),
('ADMIN','MODULE_ADMIN'),
('ADMIN','MODULE_DISPATCHER'),
('ADMIN','ADMIN_USER_MANAGE');

-- 运维人员
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('OM','MODULE_DASHBOARD'),
('OM','MODULE_DIST'),
('OM','MODULE_ALARM');

-- 能源管理员
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('ENERGY','MODULE_DASHBOARD'),
('ENERGY','MODULE_ENERGY');

-- 分析师
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('ANALYST','MODULE_DASHBOARD'),
('ANALYST','MODULE_PV'),
('ANALYST','MODULE_ENERGY');

-- 管理层
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('EXEC','MODULE_DASHBOARD'),
('EXEC','MODULE_ENERGY');

-- 运维工单管理员
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('DISPATCHER','MODULE_DASHBOARD'),
('DISPATCHER','MODULE_DISPATCHER');
GO

PRINT '账号扩展与权限表重建完成。';