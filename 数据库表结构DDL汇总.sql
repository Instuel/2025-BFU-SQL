/* ============================================================
   智慧能源管理系统 - 数据库表结构DDL汇总
   Smart Energy Management System - Database Schema DDL Summary
   
   整理日期: 2026-01-06
   数据库: SQL_BFU (SQL Server)
   
   说明：本文件按业务线整合了所有数据表的DDL语句，
         包含主脚本和补丁中的所有表结构定义。
   
   业务线划分：
   1. 基础系统与人员权限
   2. 公共基础信息与设备台账
   3. 配电网监测业务线
   4. 综合能耗管理业务线
   5. 分布式光伏管理业务线
   6. 告警运维管理业务线
   7. 大屏数据展示与统计业务线
   8. 系统管理员功能扩展
   9. 能源管理员功能扩展
   10. 数据分析师功能扩展
   ============================================================ */

-- 创建数据库
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
CREATE TABLE Sys_User (
    User_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Login_Account NVARCHAR(50) NOT NULL,
    Login_Password NVARCHAR(64) NOT NULL,            -- SHA-256加密
    Salt NVARCHAR(32) NOT NULL,
    Real_Name NVARCHAR(50) NOT NULL,
    Department NVARCHAR(100),
    Contact_Phone NVARCHAR(20),
    Account_Status TINYINT DEFAULT 1,                -- 1-正常, 0-冻结
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME(),
    Last_Login_Time DATETIME2(0) NULL,               -- 补丁扩展：最后登录时间
    Updated_Time DATETIME2(0) NULL,                  -- 补丁扩展：更新时间
    Created_By BIGINT NULL,                          -- 补丁扩展：创建人
    Updated_By BIGINT NULL,                          -- 补丁扩展：更新人
    
    CONSTRAINT UQ_Sys_User_Login UNIQUE (Login_Account),
    CONSTRAINT FK_SysUser_CreatedBy FOREIGN KEY (Created_By) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_SysUser_UpdatedBy FOREIGN KEY (Updated_By) REFERENCES Sys_User(User_ID)
);
GO

-- 2.1 系统管理员角色表
CREATE TABLE Role_SysAdmin (
    Admin_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_SysAdmin_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 2.2 运维人员角色表
CREATE TABLE Role_OandM (
    OandM_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    Factory_ID BIGINT NULL,                          -- 补丁扩展：所属厂区
    CONSTRAINT FK_OandM_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
    -- FK_OandM_Factory 外键在 Base_Factory 创建后添加
);
GO

-- 2.3 能源管理员角色表
CREATE TABLE Role_EnergyMgr (
    EnergyMgr_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_EnergyMgr_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 2.4 数据分析师角色表
CREATE TABLE Role_Analyst (
    Analyst_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Analyst_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 2.5 企业管理层角色表
CREATE TABLE Role_Manager (
    Manager_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Manager_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 2.6 运维工单管理员角色表
CREATE TABLE Role_Dispatcher (
    Dispatcher_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    CONSTRAINT FK_Dispatcher_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 3. 人员角色分配表 (Role Assignment)
CREATE TABLE Sys_Role_Assignment (
    Assignment_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    User_ID BIGINT NOT NULL,
    Role_Type NVARCHAR(20) NOT NULL,                 -- ADMIN, OM, ENERGY, ANALYST, EXEC, DISPATCHER
    Assigned_By BIGINT NULL,                         -- 系统管理员ID
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Assignment_User FOREIGN KEY (User_ID) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_Assignment_Admin FOREIGN KEY (Assigned_By) REFERENCES Role_SysAdmin(Admin_ID),
    CONSTRAINT CK_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'))
);
GO

-- 4. 权限表 (补丁扩展)
CREATE TABLE Sys_Permission (
    Perm_Code NVARCHAR(64) PRIMARY KEY,
    Perm_Name NVARCHAR(100) NOT NULL,
    Module NVARCHAR(50) NULL,
    Uri_Pattern NVARCHAR(200) NULL,
    Is_Enabled TINYINT DEFAULT 1,
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME()
);
GO

-- 5. 角色权限关联表 (补丁扩展)
CREATE TABLE Sys_Role_Permission (
    Role_Type NVARCHAR(20) NOT NULL,
    Perm_Code NVARCHAR(64) NOT NULL,
    Assigned_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_RolePerm_Perm FOREIGN KEY (Perm_Code) REFERENCES Sys_Permission(Perm_Code),
    CONSTRAINT CK_RolePerm_Role_Type CHECK (Role_Type IN ('ADMIN','OM','ENERGY','ANALYST','EXEC','DISPATCHER'))
);
GO


/* ============================================================
   第二部分：公共基础信息与设备台账
   ============================================================ */

-- 6. 厂区信息表 (Factory Info)
CREATE TABLE Base_Factory (
    Factory_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Factory_Name NVARCHAR(64) NOT NULL,
    Area_Desc NVARCHAR(200),
    Manager_User_ID BIGINT NULL,                     -- 负责人ID (系统人员)

    CONSTRAINT FK_Factory_Manager FOREIGN KEY (Manager_User_ID) REFERENCES Sys_User(User_ID)
);
GO

-- 添加 Role_OandM 的厂区外键约束
ALTER TABLE Role_OandM
ADD CONSTRAINT FK_OandM_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID);
GO

-- 7. 设备台账表 (Device Ledger) - 核心资产表
CREATE TABLE Device_Ledger (
    Ledger_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_Name NVARCHAR(50) NOT NULL,
    Device_Type NVARCHAR(20) NOT NULL,               -- 变压器, 水表, 逆变器等
    Model_Spec NVARCHAR(50),
    Install_Time DATE,
    Scrap_Status NVARCHAR(20) DEFAULT '正常使用',
    Factory_ID BIGINT NULL,                          -- 补丁扩展：所属厂区
    Warranty_Years INT NULL,                         -- 补丁扩展：质保期（年）
    Calibration_Time DATETIME2(0) NULL,              -- 补丁扩展：最近校准时间
    Calibration_Person NVARCHAR(50) NULL,            -- 补丁扩展：校准人员

    CONSTRAINT CK_Device_Type CHECK (Device_Type IN ('变压器','水表','逆变器','汇流箱','电表','气表','其他')),
    CONSTRAINT CK_Scrap_Status CHECK (Scrap_Status IN ('正常使用','已报废')),
    CONSTRAINT FK_DeviceLedger_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID)
);
GO


/* ============================================================
   第三部分：配电网监测业务线
   负责人：张恺洋
   ============================================================ */

-- 8. 配电房表 (Distribution Room)
CREATE TABLE Dist_Room (
    Room_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Room_Name NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100),
    Voltage_Level NVARCHAR(10),                      -- 如 35KV, 0.4KV
    Manager_User_ID BIGINT,
    Factory_ID BIGINT,                               -- 厂区外键

    CONSTRAINT FK_Room_Manager FOREIGN KEY (Manager_User_ID) REFERENCES Sys_User(User_ID),
    CONSTRAINT FK_Room_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID)
);
GO

-- 9. 变压器表 (Transformer)
CREATE TABLE Dist_Transformer (
    Transformer_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Transformer_Name NVARCHAR(100),
    Room_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,                           -- 关联台账
    Device_Status NVARCHAR(10) NULL,                 -- 补丁扩展：设备状态
    
    CONSTRAINT FK_Trans_Room FOREIGN KEY (Room_ID) REFERENCES Dist_Room(Room_ID),
    CONSTRAINT FK_Trans_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_DistTrans_Status CHECK (Device_Status IN (N'正常', N'异常') OR Device_Status IS NULL)
);
GO

-- 10. 回路表 (Circuit)
CREATE TABLE Dist_Circuit (
    Circuit_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Circuit_Name NVARCHAR(100),
    Room_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,                           -- 关联台账
    Device_Status NVARCHAR(10) NULL,                 -- 补丁扩展：设备状态

    CONSTRAINT FK_Circuit_Room FOREIGN KEY (Room_ID) REFERENCES Dist_Room(Room_ID),
    CONSTRAINT FK_Circuit_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_DistCircuit_Status CHECK (Device_Status IN (N'正常', N'异常') OR Device_Status IS NULL)
);
GO

-- 11. 变压器监测数据表 (Transformer Data)
CREATE TABLE Data_Transformer (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Transformer_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Winding_Temp DECIMAL(6,2),                       -- 绕组温度
    Core_Temp DECIMAL(6,2),                          -- 铁芯温度
    Load_Rate DECIMAL(5,2),                          -- 负载率
    Factory_ID BIGINT,                               -- 冗余字段优化查询

    CONSTRAINT FK_DataTrans_Device FOREIGN KEY (Transformer_ID) REFERENCES Dist_Transformer(Transformer_ID),
    CONSTRAINT FK_DataTrans_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID)
);
GO

-- 12. 回路监测数据表 (Circuit Data)
CREATE TABLE Data_Circuit (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Circuit_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Voltage DECIMAL(10,3),                           -- 电压(kV)
    Current_Val DECIMAL(10,3),                       -- 电流(A)
    Active_Power DECIMAL(12,3),                      -- 有功功率(kW)
    Reactive_Power DECIMAL(12,3),                    -- 无功功率(kVar)
    Power_Factor DECIMAL(5,3),                       -- 功率因数
    Switch_Status NVARCHAR(10),                      -- 合闸/分闸
    Factory_ID BIGINT,                               -- 冗余字段优化查询

    CONSTRAINT FK_DataCircuit_Device FOREIGN KEY (Circuit_ID) REFERENCES Dist_Circuit(Circuit_ID),
    CONSTRAINT FK_DataCircuit_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT CK_Switch_Status CHECK (Switch_Status IN ('合闸','分闸'))
);
GO


/* ============================================================
   第四部分：综合能耗管理业务线
   负责人：杨昊田
   ============================================================ */

-- 13. 能耗计量设备表 (Energy Meter)
CREATE TABLE Energy_Meter (
    Meter_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Energy_Type NVARCHAR(10) NOT NULL,               -- 水/蒸汽/天然气/电
    Comm_Protocol NVARCHAR(20),                      -- RS485/Lora
    Run_Status NVARCHAR(10) DEFAULT '正常',
    Install_Location NVARCHAR(100),
    Calib_Cycle_Months INT,                          -- 校准周期（月）
    Manufacturer NVARCHAR(50),
    Factory_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,

    CONSTRAINT FK_Meter_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT FK_Meter_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_Energy_Type CHECK (Energy_Type IN (N'水', N'蒸汽', N'天然气', N'电')),
    CONSTRAINT CK_Meter_Status CHECK (Run_Status IN ('正常','故障'))
);
GO

-- 14. 峰谷时段配置表 (Peak Valley Config)
CREATE TABLE Config_PeakValley (
    Config_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Time_Type NVARCHAR(10) NOT NULL,                 -- 尖峰/高峰/平段/低谷
    Start_Time TIME(0) NOT NULL,
    End_Time TIME(0) NOT NULL,
    Price_Rate DECIMAL(8,4) NOT NULL,                -- 单价
    
    CONSTRAINT CK_Time_Type CHECK (Time_Type IN ('尖峰','高峰','平段','低谷'))
);
GO

-- 15. 峰谷能耗数据表 (Peak Valley Data) - 按日统计结果
CREATE TABLE Data_PeakValley (
    Record_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Stat_Date DATE NOT NULL,
    Energy_Type NVARCHAR(10) NOT NULL,
    Factory_ID BIGINT NOT NULL,
    Peak_Type NVARCHAR(10),                          -- 尖峰/高峰/平段/低谷
    Total_Consumption DECIMAL(12,3),
    Cost_Amount DECIMAL(12,2),
    EnergyMgr_ID BIGINT,

    CONSTRAINT FK_PVData_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT FK_PVData_Mgr FOREIGN KEY (EnergyMgr_ID) REFERENCES Role_EnergyMgr(EnergyMgr_ID),
    CONSTRAINT CK_PeakValley_Type CHECK (Peak_Type IN ('尖峰', '高峰', '平段', '低谷') OR Peak_Type IS NULL)
);
GO

-- 16. 能耗监测数据表 (Energy Data)
CREATE TABLE Data_Energy (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Meter_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Value DECIMAL(12,3) NOT NULL,
    Unit NVARCHAR(10),                               -- m³, t, kWh等
    Quality NVARCHAR(10) DEFAULT '优',               -- 优/良/中/差
    Factory_ID BIGINT,                               -- 冗余优化
    PV_Record_ID BIGINT,                             -- 关联峰谷记录

    CONSTRAINT FK_DataEnergy_Meter FOREIGN KEY (Meter_ID) REFERENCES Energy_Meter(Meter_ID),
    CONSTRAINT FK_DataEnergy_PV FOREIGN KEY (PV_Record_ID) REFERENCES Data_PeakValley(Record_ID),
    CONSTRAINT CK_Data_Quality CHECK (Quality IN ('优','良','中','差'))
);
GO


/* ============================================================
   第五部分：分布式光伏管理业务线
   负责人：段泓冰
   ============================================================ */

-- 17. 并网点表 (Grid Point)
CREATE TABLE PV_Grid_Point (
    Point_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_Name NVARCHAR(50),
    Location NVARCHAR(100)
);
GO

-- 18. 光伏设备表 (PV Device)
CREATE TABLE PV_Device (
    Device_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_Type NVARCHAR(20) NOT NULL,               -- 逆变器/汇流箱
    Capacity DECIMAL(10,2),                          -- 装机容量(kWP)
    Run_Status NVARCHAR(10) DEFAULT '正常',
    Install_Date DATE,
    Protocol NVARCHAR(20),                           -- 通讯协议
    Point_ID BIGINT NOT NULL,
    Ledger_ID BIGINT NULL,
    Last_Update_Time DATETIME NULL DEFAULT GETDATE(), -- 补丁扩展

    CONSTRAINT FK_PV_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID),
    CONSTRAINT FK_PV_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_PV_Type CHECK (Device_Type IN ('逆变器','汇流箱')),
    CONSTRAINT CK_PV_Device_Run_Status CHECK (Run_Status IN ('正常', '故障', '离线', '异常')),
    CONSTRAINT CK_PV_Protocol CHECK (Protocol IN ('RS485', 'Lora'))
);
GO

-- 19. 光伏发电数据表 (PV Generation)
CREATE TABLE Data_PV_Gen (
    Data_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Device_ID BIGINT NOT NULL,
    Collect_Time DATETIME2(0) NOT NULL,
    Gen_KWH DECIMAL(12,3),                           -- 发电量
    Grid_KWH DECIMAL(12,3),                          -- 上网电量
    Self_KWH DECIMAL(12,3),                          -- 自用电量
    Inverter_Eff DECIMAL(5,2),                       -- 逆变器效率(%)
    Factory_ID BIGINT,                               -- 冗余优化
    Point_ID BIGINT NULL,                            -- 补丁扩展：并网点编号
    Bus_Voltage DECIMAL(8,2) NULL,                   -- 补丁扩展：汇流箱组串电压(V)
    Bus_Current DECIMAL(8,2) NULL,                   -- 补丁扩展：汇流箱组串电流(A)
    String_Count INT NULL,                           -- 补丁扩展：组串数量

    CONSTRAINT FK_PVGen_Device FOREIGN KEY (Device_ID) REFERENCES PV_Device(Device_ID),
    CONSTRAINT FK_PVGen_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID)
);
GO

-- 20. 光伏预测模型表 (Forecast Model)
CREATE TABLE PV_Forecast_Model (
    Model_Version NVARCHAR(20) PRIMARY KEY,
    Model_Name NVARCHAR(50),
    Status NVARCHAR(10) DEFAULT 'Active',
    Update_Time DATETIME2(0),
    
    CONSTRAINT CK_PV_Model_Status CHECK (Status IN ('Active', 'Inactive', 'Testing', 'Deprecated', 'Training'))
);
GO

-- 21. 光伏预测数据表 (Forecast)
CREATE TABLE Data_PV_Forecast (
    Forecast_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_ID BIGINT NOT NULL,
    Forecast_Date DATE NOT NULL,
    Time_Slot NVARCHAR(20),                          -- 如 '08:00-09:00'
    Forecast_Val DECIMAL(12,3),
    Actual_Val DECIMAL(12,3),
    Model_Version NVARCHAR(20),
    Analyst_ID BIGINT,
    Deviation_Rate AS (                              -- 补丁扩展：偏差率计算列
        CASE 
            WHEN Actual_Val IS NOT NULL AND Forecast_Val IS NOT NULL 
            THEN ((Actual_Val - Forecast_Val) / NULLIF(Forecast_Val, 0)) * 100
            ELSE NULL 
        END
    ) PERSISTED,

    CONSTRAINT FK_Forecast_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID),
    CONSTRAINT FK_Forecast_Model FOREIGN KEY (Model_Version) REFERENCES PV_Forecast_Model(Model_Version),
    CONSTRAINT FK_Forecast_Analyst FOREIGN KEY (Analyst_ID) REFERENCES Role_Analyst(Analyst_ID)
);
GO

-- 22. 模型优化提醒表 (Optimization Alert)
CREATE TABLE PV_Model_Alert (
    Alert_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_ID BIGINT NOT NULL,
    Trigger_Time DATETIME2(0),
    Remark NVARCHAR(200),
    Process_Status NVARCHAR(10) DEFAULT '未处理',
    Model_Version NVARCHAR(20),

    CONSTRAINT FK_Alert_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID)
);
GO


/* ============================================================
   第六部分：告警运维管理业务线
   负责人：李振梁
   ============================================================ */

-- 23. 告警基本信息表 (Alarm Info)
CREATE TABLE Alarm_Info (
    Alarm_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_Type NVARCHAR(20) NOT NULL,                -- 越限告警/通讯故障/设备故障等
    Alarm_Level NVARCHAR(10) NOT NULL,               -- 高/中/低
    Content NVARCHAR(200),
    Occur_Time DATETIME2(0) NOT NULL,
    Process_Status NVARCHAR(10) DEFAULT '未处理',
    Ledger_ID BIGINT NULL,                           -- 关联设备台账
    Factory_ID BIGINT,                               -- 冗余优化，便于大屏查询
    Trigger_Threshold DECIMAL(12,3) NULL,            -- 补丁扩展：告警触发阈值
    Verify_Status NVARCHAR(10) NULL                  -- 补丁扩展：复核状态
        CONSTRAINT DF_Alarm_Info_Verify_Status DEFAULT (N'待审核'),
    Verify_Remark NVARCHAR(200) NULL,                -- 补丁扩展：复核备注

    CONSTRAINT FK_Alarm_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_Alarm_Level CHECK (Alarm_Level IN ('高','中','低')),
    CONSTRAINT CK_Alarm_Status CHECK (Process_Status IN ('未处理','处理中','已结案')),
    CONSTRAINT CK_Alarm_Type CHECK (Alarm_Type IN (
        N'越限告警', N'通讯故障', N'设备故障', N'设备离线', N'环境告警', N'安全告警', N'其他'
    )),
    CONSTRAINT CK_Alarm_Verify_Status CHECK (Verify_Status IN (N'待审核', N'有效', N'误报') OR Verify_Status IS NULL)
);
GO

-- 24. 运维工单数据表 (Work Order)
CREATE TABLE Work_Order (
    Order_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_ID BIGINT NOT NULL,
    OandM_ID BIGINT NOT NULL,                        -- 运维人员
    Dispatcher_ID BIGINT NOT NULL,                   -- 运维工单管理员
    Ledger_ID BIGINT,                                -- 维修设备
    Dispatch_Time DATETIME2(0),
    Response_Time DATETIME2(0),
    Finish_Time DATETIME2(0),
    Result_Desc NVARCHAR(200),
    Review_Status NVARCHAR(10),                      -- 通过/未通过
    Attachment_Path NVARCHAR(260) NULL,              -- 补丁扩展：附件路径
    Review_Feedback NVARCHAR(500) NULL,              -- 补丁扩展：复查反馈

    CONSTRAINT FK_Order_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID),
    CONSTRAINT FK_Order_OandM FOREIGN KEY (OandM_ID) REFERENCES Role_OandM(OandM_ID),
    CONSTRAINT FK_Order_Dispatcher FOREIGN KEY (Dispatcher_ID) REFERENCES Role_Dispatcher(Dispatcher_ID),
    CONSTRAINT FK_Order_Ledger FOREIGN KEY (Ledger_ID) REFERENCES Device_Ledger(Ledger_ID),
    CONSTRAINT CK_WorkOrder_Review_Status CHECK (Review_Status IN (N'通过', N'未通过') OR Review_Status IS NULL)
);
GO

-- 添加工单唯一约束（一告警一工单）
CREATE UNIQUE NONCLUSTERED INDEX UX_Work_Order_Alarm_ID
ON Work_Order(Alarm_ID);
GO

-- 25. 告警处理日志表 (Alarm Handling Log)
CREATE TABLE Alarm_Handling_Log (
    Log_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Alarm_ID BIGINT NOT NULL,
    Handle_Time DATETIME2(0) DEFAULT SYSDATETIME(),
    Status_After NVARCHAR(10),
    OandM_ID BIGINT,                                 -- 处理人
    Dispatcher_ID BIGINT,                            -- 调度人
    
    CONSTRAINT FK_Log_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID),
    CONSTRAINT FK_Log_OandM FOREIGN KEY (OandM_ID) REFERENCES Role_OandM(OandM_ID),
    CONSTRAINT FK_Log_Dispatch FOREIGN KEY (Dispatcher_ID) REFERENCES Role_Dispatcher(Dispatcher_ID)
);
GO

-- 26. 维护计划表 (Maintenance Plan) - 补丁新增
CREATE TABLE Maintenance_Plan (
    Plan_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Ledger_ID BIGINT NULL,                           -- 关联设备台账
    Plan_Type NVARCHAR(50) NULL,
    Plan_Content NVARCHAR(500) NULL,
    Plan_Date DATE NULL,
    Owner_Name NVARCHAR(50) NULL,
    Status NVARCHAR(20) NULL,
    Created_At DATETIME2(0) NULL,

    CONSTRAINT FK_MaintPlan_Ledger FOREIGN KEY (Ledger_ID) 
        REFERENCES Device_Ledger(Ledger_ID) ON DELETE SET NULL
);
GO

CREATE NONCLUSTERED INDEX IX_MaintPlan_Ledger_PlanDate
ON Maintenance_Plan(Ledger_ID, Plan_Date, Plan_ID);
GO


/* ============================================================
   第七部分：大屏数据展示与统计业务线
   负责人：杨尧天
   ============================================================ */

-- 27. 大屏展示配置表 (Dashboard Config)
CREATE TABLE Dashboard_Config (
    Config_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Module_Name NVARCHAR(50),                        -- 能源总览/光伏总览等
    Refresh_Rate NVARCHAR(20),
    Sort_Rule NVARCHAR(50),
    Display_Fields NVARCHAR(1000),                   -- JSON or CSV
    Auth_Level NVARCHAR(20),                         -- 管理员/运维人员
    Config_Code NVARCHAR(30) NULL,                   -- 补丁扩展：幂等键
    Refresh_Interval INT NULL,                       -- 补丁扩展：刷新间隔
    Refresh_Unit NVARCHAR(10) NULL,                  -- 补丁扩展：刷新单位

    CONSTRAINT CK_Dashboard_Config_Refresh_Unit CHECK (Refresh_Unit IS NULL OR Refresh_Unit IN ('s','m','h'))
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_Dashboard_Config_Config_Code
ON Dashboard_Config(Config_Code) WHERE Config_Code IS NOT NULL;
GO

-- 28. 实时汇总数据表 (Realtime Summary)
CREATE TABLE Stat_Realtime (
    Summary_ID NVARCHAR(20) PRIMARY KEY,             -- 时间戳字符串或GUID
    Stat_Time DATETIME2(0) NOT NULL,
    Total_KWH DECIMAL(12,3),
    Total_Alarm INT,
    PV_Gen_KWH DECIMAL(12,3),
    Config_ID BIGINT,
    Manager_ID BIGINT,
    Total_Water_m3 DECIMAL(12,3) NULL,               -- 补丁扩展
    Total_Steam_t DECIMAL(12,3) NULL,                -- 补丁扩展
    Total_Gas_m3 DECIMAL(12,3) NULL,                 -- 补丁扩展
    Alarm_High INT NULL,                             -- 补丁扩展
    Alarm_Mid INT NULL,                              -- 补丁扩展
    Alarm_Low INT NULL,                              -- 补丁扩展
    Alarm_Unprocessed INT NULL,                      -- 补丁扩展

    CONSTRAINT FK_Realtime_Config FOREIGN KEY (Config_ID) REFERENCES Dashboard_Config(Config_ID),
    CONSTRAINT FK_Realtime_Manager FOREIGN KEY (Manager_ID) REFERENCES Role_Manager(Manager_ID)
);
GO

CREATE NONCLUSTERED INDEX IX_Stat_Realtime_Stat_Time 
ON Stat_Realtime(Stat_Time DESC);
GO

-- 29. 历史趋势数据表 (History Trend)
CREATE TABLE Stat_History_Trend (
    Trend_ID NVARCHAR(20) PRIMARY KEY,
    Energy_Type NVARCHAR(10),                        -- 电/水/蒸汽/天然气/光伏
    Stat_Cycle NVARCHAR(10),                         -- 日/周/月
    Stat_Date DATE,
    Value DECIMAL(12,3),
    YOY_Rate DECIMAL(5,2),                           -- 同比
    MOM_Rate DECIMAL(5,2),                           -- 环比
    Config_ID BIGINT,
    Analyst_ID BIGINT,
    Industry_Avg DECIMAL(12,3) NULL,                 -- 补丁扩展：行业均值
    Trend_Tag NVARCHAR(20) NULL,                     -- 补丁扩展：趋势标签

    CONSTRAINT FK_Trend_Config FOREIGN KEY (Config_ID) REFERENCES Dashboard_Config(Config_ID),
    CONSTRAINT FK_Trend_Analyst FOREIGN KEY (Analyst_ID) REFERENCES Role_Analyst(Analyst_ID),
    CONSTRAINT CK_Trend_Energy_Type CHECK (Energy_Type IS NULL OR Energy_Type IN (N'电',N'水',N'蒸汽',N'天然气',N'光伏')),
    CONSTRAINT CK_Trend_Stat_Cycle CHECK (Stat_Cycle IS NULL OR Stat_Cycle IN (N'日',N'周',N'月'))
);
GO

CREATE NONCLUSTERED INDEX IX_Trend_Date_Type 
ON Stat_History_Trend(Stat_Date DESC, Energy_Type);
GO

-- 30. 管理层重大事项决策表 (Executive Decision Items)
CREATE TABLE Exec_Decision_Item (
    Decision_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Decision_Type NVARCHAR(50) NULL,                 -- 维修/改造/能耗优化等
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(2000) NULL,
    Status NVARCHAR(20) DEFAULT N'待处理',
    Alarm_ID BIGINT NULL,
    Estimate_Cost DECIMAL(18,2),
    Expected_Saving DECIMAL(18,2),
    Created_Time DATETIME2(0) DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Decision_Alarm FOREIGN KEY (Alarm_ID) REFERENCES Alarm_Info(Alarm_ID)
);
GO

CREATE INDEX IX_ExecDecision_CreatedTime
ON Exec_Decision_Item(Created_Time DESC, Decision_ID DESC);
GO

-- 31. 科研项目表 (Research Project)
CREATE TABLE Research_Project (
    Project_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Project_Title NVARCHAR(200) NOT NULL,
    Project_Summary NVARCHAR(1000) NULL,
    Applicant NVARCHAR(50) NULL,
    Apply_Date DATETIME2(0) DEFAULT SYSDATETIME(),
    Project_Status NVARCHAR(20) DEFAULT N'申报中',
    Close_Report NVARCHAR(2000) NULL,
    Close_Date DATETIME2(0) NULL
);
GO

CREATE INDEX IX_Research_Project_ApplyDate 
ON Research_Project(Apply_Date DESC);
GO


/* ============================================================
   第八部分：系统管理员功能扩展
   ============================================================ */

-- 32. 告警规则配置表 (Alarm Rule)
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
GO

-- 33. 数据备份日志表 (Backup Log)
CREATE TABLE Sys_Backup_Log (
    Backup_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Backup_Type NVARCHAR(20) NOT NULL,               -- 增量备份/全量备份
    Backup_Path NVARCHAR(200) NULL,
    Status NVARCHAR(20) NOT NULL,
    Operator_ID BIGINT NULL,
    Start_Time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    End_Time DATETIME2(0) NULL,
    Remark NVARCHAR(200) NULL
);
GO

-- 34. 管理员操作审计日志表 (Admin Audit Log)
CREATE TABLE Sys_Admin_Audit_Log (
    Log_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Action_Type NVARCHAR(30) NOT NULL,
    Action_Detail NVARCHAR(200) NULL,
    Operator_ID BIGINT NULL,
    Action_Time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
GO


/* ============================================================
   第九部分：能源管理员功能扩展
   ============================================================ */

-- 35. 能耗数据复核表 (Energy Data Review)
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
GO

-- 36. 高耗能区域排查任务表 (Energy Investigation)
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
GO

-- 37. 能耗优化方案表 (Energy Optimization Plan)
CREATE TABLE Energy_Optimization_Plan (
    Plan_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Factory_ID BIGINT NOT NULL,
    Energy_Type NVARCHAR(10) NOT NULL,
    Plan_Title NVARCHAR(100) NOT NULL,
    Plan_Action NVARCHAR(200) NOT NULL,
    Start_Date DATE NOT NULL,
    Target_Reduction DECIMAL(5,2),                   -- 目标降幅(%)
    Actual_Reduction DECIMAL(5,2),                   -- 实际降幅(%)
    Status NVARCHAR(10) DEFAULT '执行中',
    Owner NVARCHAR(50),

    CONSTRAINT FK_EnergyPlan_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
    CONSTRAINT CK_EnergyPlan_Status CHECK (Status IN ('执行中','已完成','待启动'))
);
GO


/* ============================================================
   第十部分：数据分析师功能扩展
   ============================================================ */

-- 38. 光伏天气因子数据表 (PV Weather Daily)
CREATE TABLE PV_Weather_Daily (
    Weather_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Point_ID BIGINT NOT NULL,
    Weather_Date DATE NOT NULL,
    Cloud_Cover INT NULL,                            -- 云量(%)
    Temperature DECIMAL(5,2) NULL,                   -- 温度(°C)
    Irradiance DECIMAL(8,2) NULL,                    -- 辐照度(W/m²)
    Weather_Desc NVARCHAR(100) NULL,

    CONSTRAINT FK_PVWeather_Point FOREIGN KEY (Point_ID) REFERENCES PV_Grid_Point(Point_ID)
);
GO

CREATE NONCLUSTERED INDEX IDX_PVWeather_PointDate
ON PV_Weather_Daily(Point_ID, Weather_Date);
GO

-- 39. 生产线信息表 (Production Line)
CREATE TABLE Production_Line (
    Line_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Line_Name NVARCHAR(50) NOT NULL,
    Factory_ID BIGINT NOT NULL,
    Product_Type NVARCHAR(50) NULL,
    Design_Capacity DECIMAL(12,2) NULL,              -- 设计产能
    Run_Status NVARCHAR(10) DEFAULT '运行',

    CONSTRAINT FK_Line_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID)
);
GO

-- 40. 产线产量数据表 (Line Output)
CREATE TABLE Data_Line_Output (
    Output_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Line_ID BIGINT NOT NULL,
    Stat_Date DATE NOT NULL,
    Output_Qty DECIMAL(12,3) NULL,
    Unit NVARCHAR(10) NULL,

    CONSTRAINT FK_Output_Line FOREIGN KEY (Line_ID) REFERENCES Production_Line(Line_ID)
);
GO

CREATE NONCLUSTERED INDEX IDX_Line_Output_Date
ON Data_Line_Output(Line_ID, Stat_Date);
GO

-- 41. 能耗-产线映射表 (Energy Line Map)
CREATE TABLE Energy_Line_Map (
    Map_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Line_ID BIGINT NOT NULL,
    Meter_ID BIGINT NOT NULL,
    Weight DECIMAL(6,3) DEFAULT 1.000,               -- 分摊权重

    CONSTRAINT FK_LineMap_Line FOREIGN KEY (Line_ID) REFERENCES Production_Line(Line_ID),
    CONSTRAINT FK_LineMap_Meter FOREIGN KEY (Meter_ID) REFERENCES Energy_Meter(Meter_ID)
);
GO

CREATE NONCLUSTERED INDEX IDX_Line_Map
ON Energy_Line_Map(Line_ID, Meter_ID);
GO


/* ============================================================
   第十一部分：高性能索引优化
   ============================================================ */

-- 1. 回路监测数据：历史趋势查询优化
CREATE NONCLUSTERED INDEX IDX_Circuit_History 
ON Data_Circuit (Circuit_ID, Collect_Time);
GO

-- 2. 回路监测数据：厂区实时状态查询优化
CREATE NONCLUSTERED INDEX IDX_Circuit_Factory_RT 
ON Data_Circuit (Factory_ID, Collect_Time DESC);
GO

-- 3. 告警信息：多维过滤 (大屏展示核心)
CREATE NONCLUSTERED INDEX IDX_Alarm_Dashboard 
ON Alarm_Info (Process_Status, Alarm_Level, Occur_Time)
INCLUDE (Factory_ID);
GO

-- 4. 峰谷能耗：报表统计优化
CREATE NONCLUSTERED INDEX IDX_PeakValley_Rpt 
ON Data_PeakValley (Stat_Date, Energy_Type, Factory_ID);
GO

-- 5. 光伏预测：精准匹配
CREATE NONCLUSTERED INDEX IDX_PV_Forecast_Match 
ON Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot);
GO

-- 6. 系统人员：登录加速
CREATE UNIQUE NONCLUSTERED INDEX IDX_SysUser_Login 
ON Sys_User (Login_Account);
GO

-- 7. 变压器数据：时间序列查询
CREATE NONCLUSTERED INDEX IDX_Trans_Time 
ON Data_Transformer (Transformer_ID, Collect_Time);
GO


/* ============================================================
   汇总信息
   ============================================================
   
   本DDL汇总共包含 41 张数据表，按业务线分布如下：
   
   1. 基础系统与人员权限：7张表
      - Sys_User, Role_SysAdmin, Role_OandM, Role_EnergyMgr, 
        Role_Analyst, Role_Manager, Role_Dispatcher,
        Sys_Role_Assignment, Sys_Permission, Sys_Role_Permission
   
   2. 公共基础信息：2张表
      - Base_Factory, Device_Ledger
   
   3. 配电网监测业务线：4张表
      - Dist_Room, Dist_Transformer, Dist_Circuit, 
        Data_Transformer, Data_Circuit
   
   4. 综合能耗管理业务线：4张表
      - Energy_Meter, Config_PeakValley, Data_PeakValley, Data_Energy
   
   5. 分布式光伏管理业务线：5张表
      - PV_Grid_Point, PV_Device, Data_PV_Gen, 
        PV_Forecast_Model, Data_PV_Forecast, PV_Model_Alert
   
   6. 告警运维管理业务线：4张表
      - Alarm_Info, Work_Order, Alarm_Handling_Log, Maintenance_Plan
   
   7. 大屏数据展示业务线：5张表
      - Dashboard_Config, Stat_Realtime, Stat_History_Trend,
        Exec_Decision_Item, Research_Project
   
   8. 系统管理员功能扩展：3张表
      - Sys_Alarm_Rule, Sys_Backup_Log, Sys_Admin_Audit_Log
   
   9. 能源管理员功能扩展：3张表
      - Energy_Data_Review, Energy_Investigation, Energy_Optimization_Plan
   
   10. 数据分析师功能扩展：4张表
       - PV_Weather_Daily, Production_Line, Data_Line_Output, Energy_Line_Map
   
   ============================================================ */

PRINT N'============================================================';
PRINT N'智慧能源管理系统 数据库表结构DDL汇总 执行完成';
PRINT N'共创建 41 张数据表，涵盖10个业务模块';
PRINT N'============================================================';
GO
