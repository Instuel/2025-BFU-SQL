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
   第一部分：基础系统与人员权限表
   ============================================================ */

-- 1. 系统人员表 (System Users)
IF OBJECT_ID('Sys_User', 'U') IS NOT NULL DROP TABLE Sys_User;
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
    Role_Type NVARCHAR(20) NOT NULL, -- ADMIN, OM, ENERGY, ANALYST, EXEC, DEISPATCHER
    Assigned_By BIGINT NULL, -- 系统管理员ID
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Assignment_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_Assignment_Admin FOREIGN KEY (Assigned_By) REFERENCES Role_SysAdmin(Admin_ID),
    CONSTRAINT CK_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC', 'DEISPATCHER'))
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