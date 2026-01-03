/* ============================================================
   智慧能源管理系统（Smart Energy Management System）
   ✅ 一键初始化 + 扩展 + 更新补丁 + 测试用户（合并版）
   生成日期：2026-01-04

   本脚本已整合以下文件并做了必要修复：
   1) 数据库初始化脚本.sql
   2) 权限与账号管理扩展.sql
   3) 系统管理员功能扩展.sql
   4) 能源管理员功能扩展.sql
   5) 数据分析师功能扩展.sql
   6) 数据库更新脚本.sql
   7) 测试用户初始化脚本.sql

   ⚠️ 重要说明：
   - 默认会在 USE SQL_BFU 后执行“清理旧对象”（@DoClean=1），会删除 SQL_BFU 中所有用户对象与数据，
     适合测试环境一键重建；如需保留数据，请把 @DoClean 改为 0。
   ============================================================ */



/* ======================= 1) 数据库初始化脚本（已修复） ======================= */

/* ============================================================
   智慧能源管理系统 (Smart Energy Management System)
   数据库初始化脚本
   版本: 1.0
   生成日期: 2026-01-01
   ============================================================ */

-- 1. 创建数据库
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SQL_BFU')
BEGIN
    CREATE DATABASE SQL_BFU;
END
GO

USE SQL_BFU;
GO


/* ============================================================
   0) 可选：清理旧对象（测试环境推荐）
   说明：@DoClean=1 时会删除当前库内的用户视图/外键/表/存储过程/函数
         如果你只想在已有数据上做“增量更新”，请把 @DoClean 改为 0
   ⚠️ 注意：会清空 SQL_BFU 库内所有用户对象与数据
   ============================================================ */
DECLARE @DoClean BIT = 1;

IF @DoClean = 1
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    /* 0.1 删除视图 */
    SET @sql = N'';
    SELECT @sql += N'DROP VIEW ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + CHAR(10)
    FROM sys.views;
    IF LEN(@sql) > 0 EXEC sp_executesql @sql;

    /* 0.2 删除外键 */
    SET @sql = N'';
    SELECT @sql += N'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
                 + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(10)
    FROM sys.foreign_keys fk
    JOIN sys.tables t ON fk.parent_object_id = t.object_id;
    IF LEN(@sql) > 0 EXEC sp_executesql @sql;

    /* 0.3 删除表 */
    SET @sql = N'';
    SELECT @sql += N'DROP TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + CHAR(10)
    FROM sys.tables;
    IF LEN(@sql) > 0 EXEC sp_executesql @sql;

    /* 0.4 删除存储过程（保底） */
    SET @sql = N'';
    SELECT @sql += N'DROP PROCEDURE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + CHAR(10)
    FROM sys.procedures;
    IF LEN(@sql) > 0 EXEC sp_executesql @sql;

    /* 0.5 删除函数（保底） */
    SET @sql = N'';
    SELECT @sql += N'DROP FUNCTION ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + CHAR(10)
    FROM sys.objects
    WHERE type IN ('FN','IF','TF');
    IF LEN(@sql) > 0 EXEC sp_executesql @sql;

    PRINT N'已清理 SQL_BFU 库内旧对象（@DoClean=1）';
END
GO

/* ============================================================
   第一部分：基础系统与人员权限表
   ============================================================ */

-- 1. 系统人员表 (System Users)
CREATE TABLE Sys_User (
    User_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Login_Account NVARCHAR(50) NOT NULL,
    Login_Password NVARCHAR(64) NOT NULL, -- SHA-256
    Salt NVARCHAR(32) NOT NULL,
    Real_Name NVARCHAR(50) NOT NULL,
    Department NVARCHAR(100),
    Contact_Phone NVARCHAR(20),
    Account_Status TINYINT DEFAULT 1, -- 1-正常, 0-冻结
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME(),
    
    -- 索引：登录账号唯一
    CONSTRAINT UQ_Sys_User_Login UNIQUE (Login_Account)
);

-- 2. 角色表定义 (补充定义，用于支持业务表外键)
-- 2.1 系统管理员
CREATE TABLE Role_SysAdmin (
    Admin_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_SysAdmin_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 2.2 运维人员
CREATE TABLE Role_OandM (
    OandM_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_OandM_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 2.3 能源管理员
CREATE TABLE Role_EnergyMgr (
    EnergyMgr_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_EnergyMgr_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 2.4 数据分析师
CREATE TABLE Role_Analyst (
    Analyst_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Analyst_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 2.5 企业管理层
CREATE TABLE Role_Manager (
    Manager_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Manager_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 2.6 运维工单人员
CREATE TABLE Role_Dispatcher (
    Dispatcher_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Dispatcher_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);

-- 3. 人员角色分配表 (Role Assignment)
CREATE TABLE Sys_Role_Assignment (
    Assignment_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    Role_Type NVARCHAR(20) NOT NULL, -- ADMIN, OM, ENERGY, ANALYST, EXEC, DISPATCHER
    Assigned_By BIGINT NULL, -- 系统管理员ID
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Assignment_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_Assignment_Admin FOREIGN KEY (Assigned_By) REFERENCES Role_SysAdmin(Admin_ID),
    CONSTRAINT CK_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'))
);


/* ============================================================
   第二部分：公共基础信息与设备台账
   ============================================================ */

-- 4. 厂区信息表 (Factory Info)
CREATE TABLE Base_Factory (
    Factory_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Factory_Name NVARCHAR(64) NOT NULL,
    Area_Desc NVARCHAR(200),
    Manager_User_ID BIGINT NULL, -- 负责人ID (系统人员)

    CONSTRAINT FK_Factory_Manager FOREIGN KEY (Manager_User_ID) REFERENCES Sys_User(User_ID)
);

-- 5. 设备台账表 (Device Ledger) - 核心资产表
CREATE TABLE Device_Ledger (
    Ledger_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_Name NVARCHAR(50) NOT NULL,
    Device_Type NVARCHAR(20) NOT NULL, -- 变压器, 水表, 逆变器等
    Model_Spec NVARCHAR(50),
    Install_Time DATE,
    Scrap_Status NVARCHAR(20) DEFAULT '正常使用',

    CONSTRAINT CK_Device_Type CHECK (Device_Type IN ('变压器','水表','逆变器','汇流箱','电表','气表','其他')),
    CONSTRAINT CK_Scrap_Status CHECK (Scrap_Status IN ('正常使用','已报废'))
);


/* ============================================================
   第三部分：配电网监测业务线
   ============================================================ */

-- 6. 配电房表 (Distribution Room)
CREATE TABLE Dist_Room (
    Room_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Room_Name NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100),
    Voltage_Level NVARCHAR(10),
    Manager_User_ID BIGINT,
    Factory_ID BIGINT, -- 厂区外键以支持查询优化

    CONSTRAINT FK_Room_Manager FOREIGN KEY (Manager_User_ID) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_Room_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID)
);

-- 7. 变压器表 (Transformer)
CREATE TABLE Dist_Transformer (
    Transformer_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Transformer_Name NVARCHAR(100),
    Room_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL, -- 关联台账
    
    CONSTRAINT FK_Trans_Room FOREIGN KEY (Room_ID) REFERENCES Dist_Room(Room_ID),
    CONSTRAINT FK_Trans_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID)
);

-- 8. 回路表 (Circuit)
CREATE TABLE Dist_Circuit (
    Circuit_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Circuit_Name NVARCHAR(100),
    Room_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL, -- 关联台账

    CONSTRAINT FK_Circuit_Room FOREIGN KEY (Room_ID) REFERENCES Dist_Room(Room_ID),
    CONSTRAINT FK_Circuit_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID)
);

-- 9. 变压器监测数据表 (Transformer Data)
CREATE TABLE Data_Transformer (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Transformer_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Winding_Temp DECIMAL(6,2), -- 绕组温度
    Core_Temp DECIMAL(6,2),    -- 铁芯温度
    Load_Rate DECIMAL(5,2),    -- 负载率
    Factory_ID BIGINT,         -- 冗余字段优化查询

    CONSTRAINT FK_DataTrans_Device FOREIGN KEY (Transformer_ID) REFERENCES Dist_Transformer(Transformer_ID)
);

-- 10. 回路监测数据表 (Circuit Data)
CREATE TABLE Data_Circuit (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Circuit_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Voltage DECIMAL(10,3),
    Current_Val DECIMAL(10,3),
    Active_Power DECIMAL(12,3),
    Reactive_Power DECIMAL(12,3),
    Power_Factor DECIMAL(5,3),
    Switch_Status NVARCHAR(10), -- 合闸/分闸
    Factory_ID BIGINT,         -- 冗余字段优化查询

    CONSTRAINT FK_DataCircuit_Device FOREIGN KEY (Circuit_ID) REFERENCES Dist_Circuit(Circuit_ID),
    CONSTRAINT CK_Switch_Status CHECK (Switch_Status IN ('合闸','分闸'))
);


/* ============================================================
   第四部分：综合能耗管理业务线
   ============================================================ */

-- 11. 能耗计量设备表 (Energy Meter)
CREATE TABLE Energy_Meter (
    Meter_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Energy_Type NVARCHAR(10) NOT NULL, -- 水/蒸汽/天然气
    Comm_Protocol NVARCHAR(20),        -- RS485/Lora
    Run_Status NVARCHAR(10) DEFAULT '正常',
    Install_Location NVARCHAR(100),
    Calib_Cycle_Months INT,
    Manufacturer NVARCHAR(50),
    Factory_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,

    CONSTRAINT FK_Meter_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT FK_Meter_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_Energy_Type CHECK (Energy_Type IN ('水','蒸汽','天然气')),
    CONSTRAINT CK_Meter_Status CHECK (Run_Status IN ('正常','故障'))
);

-- 12. 峰谷时段配置表 (补充表，用于支撑计算)
CREATE TABLE Config_PeakValley (
    Config_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Time_Type NVARCHAR(10) NOT NULL, -- 尖峰/高峰/平段/低谷
    Start_Time TIME(0) NOT NULL,
    End_Time TIME(0) NOT NULL,
    Price_Rate DECIMAL(8,4) NOT NULL, -- 单价
    
    CONSTRAINT CK_Time_Type CHECK (Time_Type IN ('尖峰','高峰','平段','低谷'))
);

-- 13. 峰谷能耗数据表 (Peak Valley Data) - 按日统计结果
CREATE TABLE Data_PeakValley (
    Record_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Stat_Date DATE NOT NULL,
    Energy_Type NVARCHAR(10) NOT NULL,
    Factory_ID BIGINT NOT NULL,
    Peak_Type NVARCHAR(10), -- 尖峰/高峰/平段/低谷
    Total_Consumption DECIMAL(12,3),
    Cost_Amount DECIMAL(12,2),
    EnergyMgr_ID BIGINT,

    CONSTRAINT FK_PVData_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT FK_PVData_Mgr FOREIGN KEY (EnergyMgr_ID) REFERENCES Role_EnergyMgr(EnergyMgr_ID)
);

-- 14. 能耗监测数据表 (Energy Data)
CREATE TABLE Data_Energy (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Meter_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Value DECIMAL(12,3) NOT NULL,
    Unit NVARCHAR(10),
    Quality NVARCHAR(10) DEFAULT '优', -- 优/良/中/差
    Factory_ID BIGINT, -- 冗余优化
    PV_Record_ID BIGINT, -- 关联峰谷记录

    CONSTRAINT FK_DataEnergy_Meter FOREIGN KEY (Meter_ID) REFERENCES Energy_Meter(Meter_ID),
    CONSTRAINT FK_DataEnergy_PV FOREIGN KEY (PV_Record_ID) REFERENCES Data_PeakValley(Record_ID),
    CONSTRAINT CK_Data_Quality CHECK (Quality IN ('优','良','中','差'))
);


/* ============================================================
   第五部分：分布式光伏管理业务线
   ============================================================ */

-- 15. 并网点表 (Grid Point)
CREATE TABLE PV_Grid_Point (
    Point_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_Name NVARCHAR(50),
    Location NVARCHAR(100)
);

-- 16. 光伏设备表 (PV Device)
CREATE TABLE PV_Device (
    Device_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_Type NVARCHAR(20) NOT NULL, -- 逆变器/汇流箱
    Capacity DECIMAL(10,2), -- kWP
    Run_Status NVARCHAR(10) DEFAULT '正常',
    Install_Date DATE,
    Protocol NVARCHAR(20),
    Point_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,

    CONSTRAINT FK_PV_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID),
    CONSTRAINT FK_PV_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_PV_Type CHECK (Device_Type IN ('逆变器','汇流箱')),
    CONSTRAINT CK_PV_Status CHECK (Run_Status IN ('正常','故障','离线'))
);

-- 17. 光伏发电数据表 (PV Generation)
CREATE TABLE Data_PV_Gen (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Gen_KWH DECIMAL(12,3), -- 发电量
    Grid_KWH DECIMAL(12,3), -- 上网电量
    Self_KWH DECIMAL(12,3), -- 自用电量
    Inverter_Eff DECIMAL(5,2), -- 逆变器效率
    Factory_ID BIGINT, -- 冗余优化

    CONSTRAINT FK_PVGen_Device FOREIGN KEY (Device_ID) REFERENCES PV_Device(Device_ID)
);

-- 18. 光伏预测模型表
CREATE TABLE PV_Forecast_Model (
    Model_Version NVARCHAR(20) PRIMARY KEY,
    Model_Name NVARCHAR(50),
    Status NVARCHAR(10) DEFAULT 'Active',
    Update_Time DATETIME2(0)
);

-- 19. 光伏预测数据表 (Forecast)
CREATE TABLE Data_PV_Forecast (
    Forecast_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_ID BIGINT NOT NULL,
    Forecast_Date DATE NOT NULL,
    Time_Slot NVARCHAR(20), -- 如 '08:00-09:00'
    Forecast_Val DECIMAL(12,3),
    Actual_Val DECIMAL(12,3),
    Model_Version NVARCHAR(20),
    Analyst_ID BIGINT,

    CONSTRAINT FK_Forecast_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID),
    CONSTRAINT FK_Forecast_Model FOREIGN KEY (Model_Version) REFERENCES PV_Forecast_Model(Model_Version),
    CONSTRAINT FK_Forecast_Analyst FOREIGN KEY (Analyst_ID) REFERENCES Role_Analyst(Analyst_ID)
);

-- 20. 模型优化提醒表 (Optimization Alert)
CREATE TABLE PV_Model_Alert (
    Alert_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_ID BIGINT NOT NULL,
    Trigger_Time DATETIME2(0),
    Remark NVARCHAR(200),
    Process_Status NVARCHAR(10) DEFAULT '未处理',
    Model_Version NVARCHAR(20),

    CONSTRAINT FK_Alert_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID)
);


/* ============================================================
   第六部分：告警运维管理业务线
   ============================================================ */

-- 21. 告警基本信息表 (Alarm Info)
CREATE TABLE Alarm_Info (
    Alarm_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_Type NVARCHAR(20) NOT NULL, -- 越限告警/通讯故障/设备故障
    Alarm_Level NVARCHAR(10) NOT NULL, -- 高/中/低
    Content NVARCHAR(200),
    Occur_Time DATETIME2(0) NOT NULL,
    Process_Status NVARCHAR(10) DEFAULT '未处理',
    Ledger_ID BIGINT NULL, -- 关联设备台账
    Factory_ID BIGINT,     -- 冗余优化，便于大屏查询

    CONSTRAINT FK_Alarm_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_Alarm_Level CHECK (Alarm_Level IN ('高','中','低')),
    CONSTRAINT CK_Alarm_Status CHECK (Process_Status IN ('未处理','处理中','已结案'))
);

-- 22. 运维工单数据表 (Work Order)
CREATE TABLE Work_Order (
    Order_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_ID BIGINT NOT NULL,
    OandM_ID BIGINT NOT NULL, -- 运维人员
    Dispatcher_ID BIGINT NOT NULL, --运维工单管理员
    Ledger_ID BIGINT,         -- 维修设备
    Dispatch_Time DATETIME2(0),
    Response_Time DATETIME2(0),
    Finish_Time DATETIME2(0),
    Result_Desc NVARCHAR(200),
    Review_Status NVARCHAR(10), -- 通过/未通过

    CONSTRAINT FK_Order_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID),
    CONSTRAINT FK_Order_OandM FOREIGN KEY (OandM_ID) REFERENCES Role_OandM(OandM_ID),
    CONSTRAINT FK_Order_Dispatcher FOREIGN KEY (Dispatcher_ID) REFERENCES Role_Dispatcher(Dispatcher_ID),
    CONSTRAINT FK_Order_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID)
);

-- 23. 告警处理信息 (Alarm Handling Log - 过程记录)
CREATE TABLE Alarm_Handling_Log (
    Log_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_ID BIGINT NOT NULL,
    Handle_Time DATETIME2(0) DEFAULT SYSDATETIME(),
    Status_After NVARCHAR(10),
    OandM_ID BIGINT,      -- 处理人
    Dispatcher_ID BIGINT, -- 调度人
    
    CONSTRAINT FK_Log_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID),
    CONSTRAINT FK_Log_OandM FOREIGN KEY (OandM_ID) REFERENCES Role_OandM(OandM_ID),
    CONSTRAINT FK_Log_Dispatch FOREIGN KEY (Dispatcher_ID) REFERENCES Role_Dispatcher(Dispatcher_ID)
);


/* ============================================================
   第七部分：大屏数据展示与统计
   ============================================================ */

-- 24. 大屏展示配置表 (Dashboard Config)
CREATE TABLE Dashboard_Config (
    Config_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Module_Name NVARCHAR(20), -- 能源总览/光伏总览等
    Refresh_Rate NVARCHAR(20),
    Sort_Rule NVARCHAR(50),
    Display_Fields NVARCHAR(500), -- JSON or CSV
    Auth_Level NVARCHAR(20) -- 管理员/运维人员
);

-- 25. 实时汇总数据表 (Realtime Summary)
CREATE TABLE Stat_Realtime (
    Summary_ID NVARCHAR(20) PRIMARY KEY, -- 建议使用时间戳字符串或GUID
    Stat_Time DATETIME2(0) NOT NULL,
    Total_KWH DECIMAL(12,3),
    Total_Alarm INT,
    PV_Gen_KWH DECIMAL(12,3),
    Config_ID BIGINT,
    Manager_ID BIGINT,

    CONSTRAINT FK_Realtime_Config FOREIGN KEY (Config_ID) REFERENCES Dashboard_Config(Config_ID),
    CONSTRAINT FK_Realtime_Manager FOREIGN KEY (Manager_ID) REFERENCES Role_Manager(Manager_ID)
);

-- 26. 历史趋势数据表 (History Trend)
CREATE TABLE Stat_History_Trend (
    Trend_ID NVARCHAR(20) PRIMARY KEY,
    Energy_Type NVARCHAR(10),
    Stat_Cycle NVARCHAR(10), -- 日/周/月
    Stat_Date DATE,
    Value DECIMAL(12,3),
    YOY_Rate DECIMAL(5,2), -- 同比
    MOM_Rate DECIMAL(5,2), -- 环比
    Config_ID BIGINT,
    Analyst_ID BIGINT,

    CONSTRAINT FK_Trend_Config FOREIGN KEY (Config_ID) REFERENCES Dashboard_Config(Config_ID),
    CONSTRAINT FK_Trend_Analyst FOREIGN KEY (Analyst_ID) REFERENCES Role_Analyst(Analyst_ID)
);

/* ============================================================
   第八部分：高性能索引优化 (Index Creation)
   ============================================================ */
GO

-- 1. 回路监测数据：历史趋势查询优化
CREATE NONCLUSTERED INDEX IDX_Circuit_History 
ON Data_Circuit (Circuit_ID, Collect_Time);

-- 2. 回路监测数据：厂区实时状态查询优化 (利用冗余厂区ID)
CREATE NONCLUSTERED INDEX IDX_Circuit_Factory_RT 
ON Data_Circuit (Factory_ID, Collect_Time DESC);

-- 3. 告警信息：多维过滤 (大屏展示核心)
CREATE NONCLUSTERED INDEX IDX_Alarm_Dashboard 
ON Alarm_Info (Process_Status, Alarm_Level, Occur_Time)
INCLUDE (Factory_ID); -- 包含列优化查询

-- 4. 峰谷能耗：报表统计优化
CREATE NONCLUSTERED INDEX IDX_PeakValley_Rpt 
ON Data_PeakValley (Stat_Date, Energy_Type, Factory_ID);

-- 5. 光伏预测：精准匹配
CREATE NONCLUSTERED INDEX IDX_PV_Forecast_Match 
ON Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot);

-- 6. 系统人员：登录加速
CREATE UNIQUE NONCLUSTERED INDEX IDX_SysUser_Login 
ON Sys_User (Login_Account);

-- 7. 变压器数据：时间序列查询
CREATE NONCLUSTERED INDEX IDX_Trans_Time 
ON Data_Transformer (Transformer_ID, Collect_Time);

GO

/* ============================================================
   第九部分：核心业务视图 (View Definitions)
   ============================================================ */
GO

-- 视图 1: 厂区回路异常数据视图 (辅助配电网监测)
-- 作用：快速筛选出电压或电流异常的记录
CREATE VIEW View_Circuit_Abnormal AS
SELECT 
    d.Data_ID,
    d.Collect_Time,
    f.Factory_Name,
    r.Room_Name,
    c.Circuit_Name,
    d.Voltage,
    d.Current_Val,
    d.Switch_Status
FROM Data_Circuit d
JOIN Dist_Circuit c ON d.Circuit_ID = c.Circuit_ID
JOIN Dist_Room r ON c.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
WHERE d.Voltage > 37 -- 假设35kV超限 (示例阈值)
   OR d.Voltage < 33;
GO

-- 视图 2: 厂区日能耗成本统计视图 (辅助综合能耗)
-- 作用：聚合计算各厂区每日的总能耗成本
CREATE VIEW View_Daily_Energy_Cost AS
SELECT 
    p.Stat_Date,
    f.Factory_Name,
    p.Energy_Type,
    SUM(p.Total_Consumption) AS Total_Usage,
    SUM(p.Cost_Amount) AS Total_Cost
FROM Data_PeakValley p
JOIN Base_Factory f ON p.Factory_ID = f.Factory_ID
GROUP BY p.Stat_Date, f.Factory_Name, p.Energy_Type;
GO

PRINT 'Database SQL_BFU initialized successfully with all tables, constraints, indexes and views.';

/* ============================================================
   企业管理层：重大决策与科研项目
   ============================================================ */

-- 27. 管理层重大事项决策表 (Executive Decision Items)
CREATE TABLE Exec_Decision_Item (
    Decision_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Decision_Type NVARCHAR(20) NOT NULL, -- 维修/改造
    Title NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200),
    Status NVARCHAR(20) DEFAULT '待决策',
    Alarm_ID BIGINT NULL,
    Estimate_Cost DECIMAL(12,2),
    Expected_Saving DECIMAL(12,2),
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Decision_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID)
);
GO

-- 28. 科研项目表 (Research Project)
CREATE TABLE Research_Project (
    Project_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Project_Title NVARCHAR(100) NOT NULL,
    Project_Summary NVARCHAR(500),
    Applicant NVARCHAR(50),
    Apply_Date DATETIME2(0) DEFAULT SYSDATETIME(),
    Project_Status NVARCHAR(20) DEFAULT '申报中',
    Close_Report NVARCHAR(500),
    Close_Date DATETIME2(0)
);
GO
-- 视图 3: 待处理高等级告警视图 (辅助大屏展示)
-- 作用：大屏直接查询此视图获取红色告警
CREATE VIEW View_Pending_High_Alarms AS
SELECT 
    a.Alarm_ID,
    a.Occur_Time,
    a.Alarm_Type,
    a.Content,
    f.Factory_Name,
    l.Device_Name
FROM Alarm_Info a
LEFT JOIN Base_Factory f ON a.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID
WHERE a.Process_Status = '未处理' 
  AND a.Alarm_Level = '高';
GO

PRINT 'Database SQL_BFU initialized successfully with all tables, constraints, indexes and views.';

/* ============================================================
   额外约束：保证“一告警一工单”（可按需删除）
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_Work_Order_Alarm_ID' AND object_id = OBJECT_ID('dbo.Work_Order')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Work_Order_Alarm_ID
    ON dbo.Work_Order(Alarm_ID);
END
GO



/* ======================= 2) 权限与账号管理扩展（已修复 DROP 顺序） ======================= */

/* ============================================================
   账号管理与权限扩展脚本
   说明：为 Sys_User 增加审计字段，并新增权限相关表
   ============================================================ */

USE SQL_BFU;
GO

IF OBJECT_ID('Sys_Role_Permission', 'U') IS NOT NULL DROP TABLE Sys_Role_Permission;
GO
IF OBJECT_ID('Sys_Permission', 'U') IS NOT NULL DROP TABLE Sys_Permission;
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

/* === 2. 权限表 === */
CREATE TABLE Sys_Permission (
    Perm_Code NVARCHAR(64) PRIMARY KEY,
    Perm_Name NVARCHAR(100) NOT NULL,
    Module NVARCHAR(50) NULL,
    Uri_Pattern NVARCHAR(200) NULL,
    Is_Enabled TINYINT DEFAULT 1,
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME()
);

CREATE TABLE Sys_Role_Permission (
    Role_Type NVARCHAR(20) NOT NULL,
    Perm_Code NVARCHAR(64) NOT NULL,
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_RolePerm_Perm FOREIGN KEY (Perm_Code) REFERENCES Sys_Permission(Perm_Code),
    CONSTRAINT CK_RolePerm_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'))
);

/* === 3. 初始化权限 === */
INSERT INTO Sys_Permission (Perm_Code, Perm_Name, Module, Uri_Pattern) VALUES
('MODULE_DASHBOARD', N'总览模块', 'dashboard', NULL),
('MODULE_DIST', N'配电网监测模块', 'dist', NULL),
('MODULE_PV', N'分布式光伏模块', 'pv', NULL),
('MODULE_ENERGY', N'综合能耗模块', 'energy', NULL),
('MODULE_ALARM', N'告警运维模块', 'alarm', NULL),
('MODULE_ADMIN', N'系统管理模块', 'admin', NULL),
('ADMIN_USER_MANAGE', N'账号管理', NULL, '/admin');

/* === 4. 初始化角色权限 === */
-- 系统管理员：全部模块 + 账号管理
INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('ADMIN','MODULE_DASHBOARD'),
('ADMIN','MODULE_DIST'),
('ADMIN','MODULE_PV'),
('ADMIN','MODULE_ENERGY'),
('ADMIN','MODULE_ALARM'),
('ADMIN','MODULE_ADMIN'),
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

INSERT INTO Sys_Role_Permission (Role_Type, Perm_Code) VALUES
('DISPATCHER','MODULE_DASHBOARD'),
('DISPATCHER','MODULE_ENERGY');


/* ======================= 3) 系统管理员功能扩展（已修复角色类型约束） ======================= */

USE SQL_BFU;
GO

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
    CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'));


/* ======================= 4) 能源管理员功能扩展 ======================= */

USE SQL_BFU;
GO

-- 能源管理员功能扩展：数据复核、排查任务、优化方案

IF OBJECT_ID('Energy_Data_Review', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Data_Review (
        Review_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Data_ID BIGINT NOT NULL,
        Review_Status NVARCHAR(10) DEFAULT '待复核',
        Reviewer NVARCHAR(50),
        Review_Remark NVARCHAR(200),
        Review_Time DATETIME2(0),

        CONSTRAINT FK_EnergyReview_Data FOREIGN KEY (Data_ID) REFERENCES Data_Energy(Data_ID),
        CONSTRAINT CK_EnergyReview_Status CHECK (Review_Status IN ('待复核','已复核','异常确认'))
    );
END
GO

IF OBJECT_ID('Energy_Investigation', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Investigation (
        Investigation_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Factory_ID BIGINT NOT NULL,
        Energy_Type NVARCHAR(10) NOT NULL,
        Level NVARCHAR(10) DEFAULT '重点排查',
        Issue_Desc NVARCHAR(200) NOT NULL,
        Status NVARCHAR(10) DEFAULT '进行中',
        Owner NVARCHAR(50),
        Create_Time DATETIME2(0),

        CONSTRAINT FK_EnergyInvestigation_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
        CONSTRAINT CK_EnergyInvestigation_Level CHECK (Level IN ('重点排查','持续观察')),
        CONSTRAINT CK_EnergyInvestigation_Status CHECK (Status IN ('进行中','已完成'))
    );
END
GO

IF OBJECT_ID('Energy_Optimization_Plan', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Optimization_Plan (
        Plan_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Factory_ID BIGINT NOT NULL,
        Energy_Type NVARCHAR(10) NOT NULL,
        Plan_Title NVARCHAR(100) NOT NULL,
        Plan_Action NVARCHAR(200) NOT NULL,
        Start_Date DATE NOT NULL,
        Target_Reduction DECIMAL(5,2),
        Actual_Reduction DECIMAL(5,2),
        Status NVARCHAR(10) DEFAULT '执行中',
        Owner NVARCHAR(50),

        CONSTRAINT FK_EnergyPlan_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
        CONSTRAINT CK_EnergyPlan_Status CHECK (Status IN ('执行中','已完成','待启动'))
    );
END
GO


/* ======================= 5) 数据分析师功能扩展 ======================= */

/* ============================================================
   数据分析师业务扩展脚本
   - 光伏天气因子数据
   - 产线产量数据与能耗映射
   适用数据库：SQL Server
   ============================================================ */
USE SQL_BFU;
GO

SET NOCOUNT ON;

IF OBJECT_ID('dbo.PV_Weather_Daily', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PV_Weather_Daily (
        Weather_ID    BIGINT IDENTITY(1,1) PRIMARY KEY,
        Point_ID      BIGINT NOT NULL,
        Weather_Date  DATE NOT NULL,
        Cloud_Cover   INT NULL,
        Temperature  DECIMAL(5,2) NULL,
        Irradiance   DECIMAL(8,2) NULL,
        Weather_Desc NVARCHAR(100) NULL,

        CONSTRAINT FK_PVWeather_Point FOREIGN KEY (Point_ID) REFERENCES dbo.PV_Grid_Point(Point_ID)
    );
END;

IF OBJECT_ID('dbo.Production_Line', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Production_Line (
        Line_ID         BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_Name       NVARCHAR(50) NOT NULL,
        Factory_ID      BIGINT NOT NULL,
        Product_Type    NVARCHAR(50) NULL,
        Design_Capacity DECIMAL(12,2) NULL,
        Run_Status      NVARCHAR(10) DEFAULT '运行',

        CONSTRAINT FK_Line_Factory FOREIGN KEY (Factory_ID) REFERENCES dbo.Base_Factory(Factory_ID)
    );
END;

IF OBJECT_ID('dbo.Data_Line_Output', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Data_Line_Output (
        Output_ID  BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_ID    BIGINT NOT NULL,
        Stat_Date  DATE NOT NULL,
        Output_Qty DECIMAL(12,3) NULL,
        Unit       NVARCHAR(10) NULL,

        CONSTRAINT FK_Output_Line FOREIGN KEY (Line_ID) REFERENCES dbo.Production_Line(Line_ID)
    );
END;

IF OBJECT_ID('dbo.Energy_Line_Map', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Energy_Line_Map (
        Map_ID  BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_ID BIGINT NOT NULL,
        Meter_ID BIGINT NOT NULL,
        Weight DECIMAL(6,3) DEFAULT 1.000,

        CONSTRAINT FK_LineMap_Line FOREIGN KEY (Line_ID) REFERENCES dbo.Production_Line(Line_ID),
        CONSTRAINT FK_LineMap_Meter FOREIGN KEY (Meter_ID) REFERENCES dbo.Energy_Meter(Meter_ID)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PVWeather_PointDate' AND object_id = OBJECT_ID('dbo.PV_Weather_Daily'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PVWeather_PointDate
    ON dbo.PV_Weather_Daily (Point_ID, Weather_Date);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Output_Date' AND object_id = OBJECT_ID('dbo.Data_Line_Output'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Output_Date
    ON dbo.Data_Line_Output (Line_ID, Stat_Date);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Map' AND object_id = OBJECT_ID('dbo.Energy_Line_Map'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Map
    ON dbo.Energy_Line_Map (Line_ID, Meter_ID);
END;


/* ======================= 6) 数据库更新脚本（已修复乱码段） ======================= */

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
   告警运维管理业务线：Alarm_Info 复核字段补充（修复乱码段）
   说明：
     - Verify_Status：用于“复核/退回/通过”等状态标记
     - Verify_Remark：复核备注/退回原因
     - 兼容性：允许 NULL（老数据）并提供默认值
   ============================================================ */
IF COL_LENGTH('Alarm_Info', 'Verify_Status') IS NULL
BEGIN
    ALTER TABLE Alarm_Info
    ADD Verify_Status NVARCHAR(10) NULL
        CONSTRAINT DF_Alarm_Verify_Status DEFAULT (N'待复核');
END
GO

IF COL_LENGTH('Alarm_Info', 'Verify_Remark') IS NULL
BEGIN
    ALTER TABLE Alarm_Info
    ADD Verify_Remark NVARCHAR(200) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Alarm_Verify'
      AND parent_object_id = OBJECT_ID('Alarm_Info')
)
BEGIN
    ALTER TABLE Alarm_Info
    ADD CONSTRAINT CK_Alarm_Verify
        CHECK (Verify_Status IN (N'待复核', N'通过', N'未通过') OR Verify_Status IS NULL);
END
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

USE SQL_BFU;
GO

/* ============================================================
   第一部分：执行 DDL/DML 操作 (建表、插数、加约束)
   注意：这部分必须在生成报告之前执行完毕
   ============================================================ */

-- 1. 创建 Exec_Decision_Item 表
IF OBJECT_ID('dbo.Exec_Decision_Item', 'U') IS NULL
BEGIN
    EXEC(N'
        CREATE TABLE dbo.Exec_Decision_Item (
            Decision_ID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Exec_Decision PRIMARY KEY,
            Decision_Type NVARCHAR(20) NOT NULL,
            Title NVARCHAR(100) NOT NULL,
            Description NVARCHAR(200) NULL,
            Status NVARCHAR(20) NULL,
            Alarm_ID BIGINT NULL,
            Estimate_Cost DECIMAL(12,2) NULL,
            Expected_Saving DECIMAL(12,2) NULL,
            Created_Time DATETIME2(0) NULL,

            CONSTRAINT FK_Decision_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID)
        );
    ');
END
GO

-- 2. 创建 Maintenance_Plan 表
IF OBJECT_ID('dbo.Maintenance_Plan', 'U') IS NULL
BEGIN
    EXEC(N'
        CREATE TABLE dbo.Maintenance_Plan (
            Plan_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Maintenance_Plan PRIMARY KEY,
            Ledger_ID    BIGINT NULL,
            Plan_Type    NVARCHAR(50) NULL,
            Plan_Content NVARCHAR(500) NULL,
            Plan_Date    DATE NULL,
            Owner_Name   NVARCHAR(50) NULL,
            Status       NVARCHAR(20) NULL,
            Created_At   DATETIME2(0) NULL
        );
    ');
END;
GO

-- 3. 创建 Research_Project 表
IF OBJECT_ID('dbo.Research_Project', 'U') IS NULL
BEGIN
    EXEC(N'
        CREATE TABLE dbo.Research_Project (
            Project_ID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Research_Project PRIMARY KEY,
            Project_Title NVARCHAR(100) NOT NULL,
            Project_Summary NVARCHAR(500) NULL,
            Applicant NVARCHAR(50) NULL,
            Apply_Date DATETIME2(0) NULL,
            Project_Status NVARCHAR(20) NULL,
            Close_Report NVARCHAR(500) NULL,
            Close_Date DATETIME2(0) NULL
        );
    ');
END;
GO

-- 4. 插入测试数据
IF NOT EXISTS (SELECT 1 FROM dbo.Exec_Decision_Item)
BEGIN
    INSERT INTO dbo.Exec_Decision_Item (Decision_Type, Title, Description, Status, Estimate_Cost, Expected_Saving, Created_Time)
    VALUES
    (N'维修', N'35KV 配电房故障', N'主变温度异常，建议紧急检修并制定预算。', N'待决策', 480000, NULL, SYSDATETIME()),
    (N'改造', N'空压系统节能改造', N'预估节能 12%，建议纳入年度节能计划。', N'待决策', 320000, 120000, SYSDATETIME());
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Research_Project)
BEGIN
    INSERT INTO dbo.Research_Project (Project_Title, Project_Summary, Applicant, Apply_Date, Project_Status)
    VALUES
    (N'光伏智能预测项目', N'提升光伏预测精度，支撑自用电收益提升。', N'管理层', SYSDATETIME(), N'申报中'),
    (N'能耗优化示范项目', N'围绕高耗能设备开展节能改造示范。', N'管理层', SYSDATETIME(), N'结题中');
END;
GO

-- 5. 补全外键约束
IF COL_LENGTH('dbo.Maintenance_Plan','Ledger_ID') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Maintenance_Plan_Ledger' AND parent_object_id=OBJECT_ID('dbo.Maintenance_Plan'))
BEGIN
    EXEC(N'ALTER TABLE dbo.Maintenance_Plan WITH NOCHECK
           ADD CONSTRAINT FK_Maintenance_Plan_Ledger FOREIGN KEY (Ledger_ID) REFERENCES dbo.Device_Ledger(Ledger_ID);');
END;
GO


/* ============================================================
   第二部分：生成变更汇总报告 (纯查询)
   注意：这里是纯粹的 SELECT ... UNION ALL ... SELECT 结构
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


/* ======================= 7) 测试用户初始化脚本 ======================= */

USE SQL_BFU;
GO

-- ============================================================
-- 智慧能源管理系统 - 测试用户初始化脚本
-- 可直接在SQL Server中运行，支持跨环境迁移
-- 所有用户密码: 123456
-- ============================================================

-- 密码加密说明：
-- 原始密码: 123456
-- Salt: VGVzdFNhbHQxMjM0NTY3OA== (固定值)
-- 加密方式: SHA256(password + salt)
-- 哈希结果: c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11

-- ============================================================
-- 第一步：插入用户到 Sys_User 表
-- ============================================================

USE SQL_BFU
GO
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES 
('admin', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '张管理', '信息技术部', '13800000001', 1),
('om_user', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '李运维', '运维部', '13800000002', 1),
('energy_user', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '王能源', '能源管理部', '13800000003', 1),
('analyst_user', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '赵分析', '数据分析部', '13800000004', 1),
('exec_user', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '钱总监', '管理层', '13800000005', 1),
('dispatcher', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', '胡调度', '运维工单调度部', '13800000006', 1); 

-- ============================================================
-- 第二步：插入角色表记录
-- ============================================================
INSERT INTO Role_SysAdmin (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'admin';
INSERT INTO Role_OandM (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'om_user';
INSERT INTO Role_EnergyMgr (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'energy_user';
INSERT INTO Role_Analyst (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'analyst_user';
INSERT INTO Role_Manager (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'exec_user';
INSERT INTO Role_Dispatcher (User_ID) SELECT User_ID FROM Sys_User WHERE Login_Account = 'dispatcher'; 
-- ============================================================
-- 第三步：分配角色到 Sys_Role_Assignment 表
-- ============================================================
INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By)
SELECT User_ID, 'ADMIN', NULL FROM Sys_User WHERE Login_Account = 'admin';

INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By)
SELECT User_ID, 'OM', NULL FROM Sys_User WHERE Login_Account = 'om_user';

INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By)
SELECT User_ID, 'ENERGY', NULL FROM Sys_User WHERE Login_Account = 'energy_user';

INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By)
SELECT User_ID, 'ANALYST', NULL FROM Sys_User WHERE Login_Account = 'analyst_user';

INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By)
SELECT User_ID, 'EXEC', NULL FROM Sys_User WHERE Login_Account = 'exec_user';

INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By) 
SELECT User_ID, 'DISPATCHER', NULL FROM Sys_User WHERE Login_Account = 'dispatcher'; 

-- ============================================================
-- 验证插入结果
-- ============================================================
SELECT 
    u.User_ID, 
    u.Login_Account AS N'账号', 
    u.Real_Name AS N'姓名', 
    u.Department AS N'部门', 
    r.Role_Type AS N'角色', 
    CASE r.Role_Type 
        WHEN 'ADMIN' THEN '/admin/dashboard' 
        WHEN 'OM' THEN '/om/dashboard' 
        WHEN 'ENERGY' THEN '/energy/dashboard' 
        WHEN 'ANALYST' THEN '/analyst/dashboard' 
        WHEN 'EXEC' THEN '/exec/dashboard' 
        WHEN 'DISPATCHER' THEN '/dispatcher/dashboard' 
    END AS N'登录跳转页面' 
FROM Sys_User u 
LEFT JOIN Sys_Role_Assignment r ON u.User_ID = r.User_ID 
WHERE u.Login_Account IN ('admin','om_user','energy_user','analyst_user','exec_user', 'dispatcher') 
ORDER BY u.User_ID; 

PRINT N'✓ 测试用户创建完成！所有用户密码: 123456';

