/* ============================================================
   SQL_BFU 测试数据填充脚本（保证关联表有交集）
   适用：你已执行完“数据库初始化脚本.sql”
        如也执行了“权限与账号管理扩展.sql”，本脚本会自动识别权限表并做幂等插入
   数据特点：
     - Sys_User -> Role_* -> Sys_Role_Assignment 全链路
     - Factory -> Room -> Transformer/Circuit -> Data_* 全链路
     - Factory -> Energy_Meter -> Data_Energy + Data_PeakValley 全链路
     - PV_Grid_Point -> PV_Device -> Data_PV_Gen + Forecast + Alert 全链路
     - Alarm_Info -> Work_Order -> Alarm_Handling_Log 全链路
     - Dashboard_Config -> Stat_Realtime/Stat_History_Trend 全链路
   ============================================================ */

USE SQL_BFU;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
BEGIN TRAN;

------------------------------------------------------------
-- 1) 基础用户（幂等插入）
--    密码统一：123456（沿用你“测试用户初始化脚本.sql”的 hash + salt）
------------------------------------------------------------
DECLARE @Salt NVARCHAR(32) = N'VGVzdFNhbHQxMjM0NTY3OA==';
DECLARE @PwdHash NVARCHAR(64) = N'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11';

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'admin')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('admin', @PwdHash, @Salt, N'系统管理员', N'信息中心', '13800000001', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'om_user1')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('om_user1', @PwdHash, @Salt, N'运维人员-张运维', N'运维部', '13800000002', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'om_user2')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('om_user2', @PwdHash, @Salt, N'运维人员-李运维', N'运维部', '13800000006', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'energy_user')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('energy_user', @PwdHash, @Salt, N'能源管理员-王能管', N'能源管理部', '13800000003', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'analyst_user')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('analyst_user', @PwdHash, @Salt, N'数据分析师-赵分析', N'数据中心', '13800000004', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'exec_user')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('exec_user', @PwdHash, @Salt, N'管理层-刘经理', N'管理层', '13800000005', 1);

IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'dispatcher_user')
INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
VALUES ('dispatcher_user', @PwdHash, @Salt, N'工单调度员-周调度', N'运维调度', '13800000007', 1);

DECLARE
  @uid_admin BIGINT,
  @uid_om1 BIGINT,
  @uid_om2 BIGINT,
  @uid_energy BIGINT,
  @uid_analyst BIGINT,
  @uid_exec BIGINT,
  @uid_dispatcher BIGINT;

SELECT @uid_admin = User_ID FROM Sys_User WHERE Login_Account='admin';
SELECT @uid_om1 = User_ID FROM Sys_User WHERE Login_Account='om_user1';
SELECT @uid_om2 = User_ID FROM Sys_User WHERE Login_Account='om_user2';
SELECT @uid_energy = User_ID FROM Sys_User WHERE Login_Account='energy_user';
SELECT @uid_analyst = User_ID FROM Sys_User WHERE Login_Account='analyst_user';
SELECT @uid_exec = User_ID FROM Sys_User WHERE Login_Account='exec_user';
SELECT @uid_dispatcher = User_ID FROM Sys_User WHERE Login_Account='dispatcher_user';

-- 若你执行了“权限与账号管理扩展.sql”，Sys_User 会多出审计字段；这里做一次安全更新（无字段则跳过）
IF COL_LENGTH('Sys_User', 'Created_By') IS NOT NULL
BEGIN
  UPDATE Sys_User
     SET Created_By = ISNULL(Created_By, @uid_admin),
         Updated_By = ISNULL(Updated_By, @uid_admin),
         Updated_Time = ISNULL(Updated_Time, SYSDATETIME())
   WHERE Login_Account IN ('admin','om_user1','om_user2','energy_user','analyst_user','exec_user','dispatcher_user');
END

------------------------------------------------------------
-- 2) 角色实体表 Role_*（幂等插入）
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Role_SysAdmin WHERE User_ID=@uid_admin)
  INSERT INTO Role_SysAdmin(User_ID) VALUES (@uid_admin);

IF NOT EXISTS (SELECT 1 FROM Role_OandM WHERE User_ID=@uid_om1)
  INSERT INTO Role_OandM(User_ID) VALUES (@uid_om1);

IF NOT EXISTS (SELECT 1 FROM Role_OandM WHERE User_ID=@uid_om2)
  INSERT INTO Role_OandM(User_ID) VALUES (@uid_om2);

IF NOT EXISTS (SELECT 1 FROM Role_EnergyMgr WHERE User_ID=@uid_energy)
  INSERT INTO Role_EnergyMgr(User_ID) VALUES (@uid_energy);

IF NOT EXISTS (SELECT 1 FROM Role_Analyst WHERE User_ID=@uid_analyst)
  INSERT INTO Role_Analyst(User_ID) VALUES (@uid_analyst);

IF NOT EXISTS (SELECT 1 FROM Role_Manager WHERE User_ID=@uid_exec)
  INSERT INTO Role_Manager(User_ID) VALUES (@uid_exec);

IF NOT EXISTS (SELECT 1 FROM Role_Dispatcher WHERE User_ID=@uid_dispatcher)
  INSERT INTO Role_Dispatcher(User_ID) VALUES (@uid_dispatcher);

DECLARE
  @admin_id BIGINT,
  @om1_id BIGINT,
  @om2_id BIGINT,
  @energy_mgr_id BIGINT,
  @analyst_id BIGINT,
  @manager_id BIGINT,
  @dispatcher_id BIGINT;

SELECT @admin_id = Admin_ID FROM Role_SysAdmin WHERE User_ID=@uid_admin;
SELECT @om1_id = OandM_ID FROM Role_OandM WHERE User_ID=@uid_om1;
SELECT @om2_id = OandM_ID FROM Role_OandM WHERE User_ID=@uid_om2;
SELECT @energy_mgr_id = EnergyMgr_ID FROM Role_EnergyMgr WHERE User_ID=@uid_energy;
SELECT @analyst_id = Analyst_ID FROM Role_Analyst WHERE User_ID=@uid_analyst;
SELECT @manager_id = Manager_ID FROM Role_Manager WHERE User_ID=@uid_exec;
SELECT @dispatcher_id = Dispatcher_ID FROM Role_Dispatcher WHERE User_ID=@uid_dispatcher;

------------------------------------------------------------
-- 3) Sys_Role_Assignment（注意：你初始化脚本里 Role_Type 的 CHECK 有个拼写 'DEISPATCHER'）
--    为了不报错，这里给 dispatcher 用 'DEISPATCHER'。如果你已修复约束为 'DISPATCHER'，把下面改掉即可。
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_admin)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_admin, 'ADMIN', NULL);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_om1)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_om1, 'OM', @admin_id);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_om2)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_om2, 'OM', @admin_id);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_energy)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_energy, 'ENERGY', @admin_id);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_analyst)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_analyst, 'ANALYST', @admin_id);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_exec)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_exec, 'EXEC', @admin_id);

IF NOT EXISTS (SELECT 1 FROM Sys_Role_Assignment WHERE User_ID=@uid_dispatcher)
INSERT INTO Sys_Role_Assignment(User_ID, Role_Type, Assigned_By)
VALUES(@uid_dispatcher, 'DISPATCHER', @admin_id);

------------------------------------------------------------
-- 4) 厂区 Base_Factory（与用户交集：Manager_User_ID）
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Base_Factory WHERE Factory_Name = N'北林校园厂区')
INSERT INTO Base_Factory(Factory_Name, Area_Desc, Manager_User_ID)
VALUES(N'北林校园厂区', N'主校区负荷中心区域', @uid_exec);

IF NOT EXISTS (SELECT 1 FROM Base_Factory WHERE Factory_Name = N'西区实验厂区')
INSERT INTO Base_Factory(Factory_Name, Area_Desc, Manager_User_ID)
VALUES(N'西区实验厂区', N'实验楼与机房负荷区域', @uid_admin);

DECLARE @fid1 BIGINT, @fid2 BIGINT;
SELECT @fid1 = Factory_ID FROM Base_Factory WHERE Factory_Name=N'北林校园厂区';
SELECT @fid2 = Factory_ID FROM Base_Factory WHERE Factory_Name=N'西区实验厂区';

------------------------------------------------------------
-- 5) 设备台账 Device_Ledger（被多条业务线引用：配电/能耗/光伏/告警/工单）
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'变压器1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'变压器1号', N'变压器', N'S11-1000kVA', '2024-01-01', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'变压器2号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'变压器2号', N'变压器', N'S11-800kVA', '2024-03-01', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'配电电表A1')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'配电电表A1', N'电表', N'DTSD-341', '2024-02-10', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'配电电表B1')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'配电电表B1', N'电表', N'DTSD-341', '2024-04-10', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'水表1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'水表1号', N'水表', N'LXSG-50', '2024-02-15', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'气表1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'气表1号', N'气表', N'G4', '2024-02-20', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'蒸汽计量表1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'蒸汽计量表1号', N'其他', N'STEAM-MTR', '2024-05-01', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'逆变器1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'逆变器1号', N'逆变器', N'INV-50kW', '2024-02-15', N'正常使用');

IF NOT EXISTS (SELECT 1 FROM Device_Ledger WHERE Device_Name=N'汇流箱1号')
INSERT INTO Device_Ledger(Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status)
VALUES(N'汇流箱1号', N'汇流箱', N'CB-16', '2024-02-18', N'正常使用');

DECLARE
  @lid_t1 BIGINT, @lid_t2 BIGINT,
  @lid_ca1 BIGINT, @lid_cb1 BIGINT,
  @lid_w1 BIGINT, @lid_g1 BIGINT, @lid_s1 BIGINT,
  @lid_inv1 BIGINT, @lid_cbbox1 BIGINT;

SELECT @lid_t1 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'变压器1号';
SELECT @lid_t2 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'变压器2号';
SELECT @lid_ca1 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'配电电表A1';
SELECT @lid_cb1 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'配电电表B1';
SELECT @lid_w1  = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'水表1号';
SELECT @lid_g1  = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'气表1号';
SELECT @lid_s1  = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'蒸汽计量表1号';
SELECT @lid_inv1 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'逆变器1号';
SELECT @lid_cbbox1 = Ledger_ID FROM Device_Ledger WHERE Device_Name=N'汇流箱1号';

------------------------------------------------------------
-- 6) 配电：Dist_Room -> Dist_Transformer/Dist_Circuit -> Data_*
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Dist_Room WHERE Room_Name=N'A区配电室' AND Factory_ID=@fid1)
INSERT INTO Dist_Room(Room_Name, Location, Voltage_Level, Manager_User_ID, Factory_ID)
VALUES(N'A区配电室', N'北林校园厂区-A楼', N'10kV', @uid_om1, @fid1);

IF NOT EXISTS (SELECT 1 FROM Dist_Room WHERE Room_Name=N'B区配电室' AND Factory_ID=@fid2)
INSERT INTO Dist_Room(Room_Name, Location, Voltage_Level, Manager_User_ID, Factory_ID)
VALUES(N'B区配电室', N'西区实验厂区-实验楼', N'10kV', @uid_om2, @fid2);

DECLARE @roomA BIGINT, @roomB BIGINT;
SELECT @roomA = Room_ID FROM Dist_Room WHERE Room_Name=N'A区配电室' AND Factory_ID=@fid1;
SELECT @roomB = Room_ID FROM Dist_Room WHERE Room_Name=N'B区配电室' AND Factory_ID=@fid2;

IF NOT EXISTS (SELECT 1 FROM Dist_Transformer WHERE Transformer_Name=N'A区主变1' AND Room_ID=@roomA)
INSERT INTO Dist_Transformer(Transformer_Name, Room_ID, Ledger_ID)
VALUES(N'A区主变1', @roomA, @lid_t1);

IF NOT EXISTS (SELECT 1 FROM Dist_Transformer WHERE Transformer_Name=N'B区主变1' AND Room_ID=@roomB)
INSERT INTO Dist_Transformer(Transformer_Name, Room_ID, Ledger_ID)
VALUES(N'B区主变1', @roomB, @lid_t2);

DECLARE @trA BIGINT, @trB BIGINT;
SELECT @trA = Transformer_ID FROM Dist_Transformer WHERE Transformer_Name=N'A区主变1' AND Room_ID=@roomA;
SELECT @trB = Transformer_ID FROM Dist_Transformer WHERE Transformer_Name=N'B区主变1' AND Room_ID=@roomB;

IF NOT EXISTS (SELECT 1 FROM Dist_Circuit WHERE Circuit_Name=N'A区回路-教学楼' AND Room_ID=@roomA)
INSERT INTO Dist_Circuit(Circuit_Name, Room_ID, Ledger_ID)
VALUES(N'A区回路-教学楼', @roomA, @lid_ca1);

IF NOT EXISTS (SELECT 1 FROM Dist_Circuit WHERE Circuit_Name=N'B区回路-实验楼' AND Room_ID=@roomB)
INSERT INTO Dist_Circuit(Circuit_Name, Room_ID, Ledger_ID)
VALUES(N'B区回路-实验楼', @roomB, @lid_cb1);

DECLARE @cA BIGINT, @cB BIGINT;
SELECT @cA = Circuit_ID FROM Dist_Circuit WHERE Circuit_Name=N'A区回路-教学楼' AND Room_ID=@roomA;
SELECT @cB = Circuit_ID FROM Dist_Circuit WHERE Circuit_Name=N'B区回路-实验楼' AND Room_ID=@roomB;

-- 采集数据（避免重复：同设备同时间点不重复）
IF NOT EXISTS (SELECT 1 FROM Data_Transformer WHERE Transformer_ID=@trA AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Transformer(Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, Load_Rate, Factory_ID)
VALUES
(@trA,'2026-01-03 08:00:00', 72.5, 61.2, 55.3, @fid1),
(@trA,'2026-01-03 12:00:00', 78.1, 66.0, 62.8, @fid1),
(@trA,'2026-01-03 18:00:00', 81.6, 69.4, 70.2, @fid1);

IF NOT EXISTS (SELECT 1 FROM Data_Transformer WHERE Transformer_ID=@trB AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Transformer(Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, Load_Rate, Factory_ID)
VALUES
(@trB,'2026-01-03 08:00:00', 68.9, 58.0, 48.6, @fid2),
(@trB,'2026-01-03 12:00:00', 73.2, 62.1, 57.9, @fid2),
(@trB,'2026-01-03 18:00:00', 76.8, 64.8, 64.4, @fid2);

IF NOT EXISTS (SELECT 1 FROM Data_Circuit WHERE Circuit_ID=@cA AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Circuit(Circuit_ID, Collect_Time, Voltage, Current_Val, Active_Power, Reactive_Power, Power_Factor, Switch_Status, Factory_ID)
VALUES
(@cA,'2026-01-03 08:00:00', 380.0, 120.5, 65.200, 12.300, 0.982, N'合闸', @fid1),
(@cA,'2026-01-03 12:00:00', 380.0, 140.2, 78.900, 15.100, 0.975, N'合闸', @fid1),
(@cA,'2026-01-03 18:00:00', 380.0, 160.8, 88.600, 18.200, 0.968, N'合闸', @fid1);

IF NOT EXISTS (SELECT 1 FROM Data_Circuit WHERE Circuit_ID=@cB AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Circuit(Circuit_ID, Collect_Time, Voltage, Current_Val, Active_Power, Reactive_Power, Power_Factor, Switch_Status, Factory_ID)
VALUES
(@cB,'2026-01-03 08:00:00', 380.0, 98.7,  52.400, 10.800, 0.981, N'合闸', @fid2),
(@cB,'2026-01-03 12:00:00', 380.0, 112.9, 61.700, 12.900, 0.972, N'合闸', @fid2),
(@cB,'2026-01-03 18:00:00', 380.0, 0.0,   0.000,  0.000,  0.000, N'分闸', @fid2);

------------------------------------------------------------
-- 7) 能耗：Energy_Meter -> Data_PeakValley / Data_Energy
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Energy_Meter WHERE Energy_Type=N'水' AND Factory_ID=@fid1 AND Ledger_ID=@lid_w1)
INSERT INTO Energy_Meter(Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID)
VALUES(N'水', N'RS485', N'正常', N'北林校园-水泵房', 12, N'某水务厂商', @fid1, @lid_w1);

IF NOT EXISTS (SELECT 1 FROM Energy_Meter WHERE Energy_Type=N'天然气' AND Factory_ID=@fid1 AND Ledger_ID=@lid_g1)
INSERT INTO Energy_Meter(Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID)
VALUES(N'天然气', N'RS485', N'正常', N'北林校园-锅炉房', 12, N'某燃气厂商', @fid1, @lid_g1);

IF NOT EXISTS (SELECT 1 FROM Energy_Meter WHERE Energy_Type=N'蒸汽' AND Factory_ID=@fid1 AND Ledger_ID=@lid_s1)
INSERT INTO Energy_Meter(Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID)
VALUES(N'蒸汽', N'RS485', N'正常', N'北林校园-换热站', 6, N'某计量厂商', @fid1, @lid_s1);

-- 西区也给两块表
IF NOT EXISTS (SELECT 1 FROM Energy_Meter WHERE Energy_Type=N'水' AND Factory_ID=@fid2 AND Ledger_ID=@lid_w1)
INSERT INTO Energy_Meter(Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID)
VALUES(N'水', N'LoRa', N'正常', N'西区实验-水泵房', 12, N'某水务厂商', @fid2, @lid_w1);

IF NOT EXISTS (SELECT 1 FROM Energy_Meter WHERE Energy_Type=N'天然气' AND Factory_ID=@fid2 AND Ledger_ID=@lid_g1)
INSERT INTO Energy_Meter(Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID)
VALUES(N'天然气', N'LoRa', N'正常', N'西区实验-锅炉房', 12, N'某燃气厂商', @fid2, @lid_g1);

DECLARE
  @m_w_f1 BIGINT, @m_g_f1 BIGINT, @m_s_f1 BIGINT,
  @m_w_f2 BIGINT, @m_g_f2 BIGINT;

SELECT @m_w_f1 = Meter_ID FROM Energy_Meter WHERE Energy_Type=N'水' AND Factory_ID=@fid1 AND Ledger_ID=@lid_w1;
SELECT @m_g_f1 = Meter_ID FROM Energy_Meter WHERE Energy_Type=N'天然气' AND Factory_ID=@fid1 AND Ledger_ID=@lid_g1;
SELECT @m_s_f1 = Meter_ID FROM Energy_Meter WHERE Energy_Type=N'蒸汽' AND Factory_ID=@fid1 AND Ledger_ID=@lid_s1;
SELECT @m_w_f2 = Meter_ID FROM Energy_Meter WHERE Energy_Type=N'水' AND Factory_ID=@fid2 AND Ledger_ID=@lid_w1;
SELECT @m_g_f2 = Meter_ID FROM Energy_Meter WHERE Energy_Type=N'天然气' AND Factory_ID=@fid2 AND Ledger_ID=@lid_g1;

-- 峰谷时段配置（4条）
IF NOT EXISTS (SELECT 1 FROM Config_PeakValley WHERE Time_Type=N'尖峰')
INSERT INTO Config_PeakValley(Time_Type, Start_Time, End_Time, Price_Rate)
VALUES (N'尖峰','09:00','11:00', 1.2000);

IF NOT EXISTS (SELECT 1 FROM Config_PeakValley WHERE Time_Type=N'高峰')
INSERT INTO Config_PeakValley(Time_Type, Start_Time, End_Time, Price_Rate)
VALUES (N'高峰','11:00','18:00', 1.0000);

IF NOT EXISTS (SELECT 1 FROM Config_PeakValley WHERE Time_Type=N'平段')
INSERT INTO Config_PeakValley(Time_Type, Start_Time, End_Time, Price_Rate)
VALUES (N'平段','18:00','22:00', 0.8000);

IF NOT EXISTS (SELECT 1 FROM Config_PeakValley WHERE Time_Type=N'低谷')
INSERT INTO Config_PeakValley(Time_Type, Start_Time, End_Time, Price_Rate)
VALUES (N'低谷','22:00','06:00', 0.5000);

-- 峰谷统计（与 EnergyMgr 关联）
IF NOT EXISTS (SELECT 1 FROM Data_PeakValley WHERE Stat_Date='2026-01-03' AND Factory_ID=@fid1 AND Energy_Type=N'水' AND Peak_Type=N'高峰')
INSERT INTO Data_PeakValley(Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount, EnergyMgr_ID)
VALUES('2026-01-03', N'水', @fid1, N'高峰', 120.500, 120.50, @energy_mgr_id);

IF NOT EXISTS (SELECT 1 FROM Data_PeakValley WHERE Stat_Date='2026-01-03' AND Factory_ID=@fid1 AND Energy_Type=N'天然气' AND Peak_Type=N'高峰')
INSERT INTO Data_PeakValley(Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount, EnergyMgr_ID)
VALUES('2026-01-03', N'天然气', @fid1, N'高峰', 80.250, 96.30, @energy_mgr_id);

IF NOT EXISTS (SELECT 1 FROM Data_PeakValley WHERE Stat_Date='2026-01-03' AND Factory_ID=@fid2 AND Energy_Type=N'水' AND Peak_Type=N'平段')
INSERT INTO Data_PeakValley(Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount, EnergyMgr_ID)
VALUES('2026-01-03', N'水', @fid2, N'平段', 66.700, 53.36, @energy_mgr_id);

DECLARE @pvrec_f1_w BIGINT;
SELECT TOP 1 @pvrec_f1_w = Record_ID
  FROM Data_PeakValley
 WHERE Stat_Date='2026-01-03' AND Factory_ID=@fid1 AND Energy_Type=N'水'
 ORDER BY Record_ID DESC;

-- 能耗明细数据（与 Meter + PV_Record 有交集）
IF NOT EXISTS (SELECT 1 FROM Data_Energy WHERE Meter_ID=@m_w_f1 AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Energy(Meter_ID, Collect_Time, Value, Unit, Quality, Factory_ID, PV_Record_ID)
VALUES
(@m_w_f1,'2026-01-03 08:00:00', 10.250, N'm³', N'优', @fid1, @pvrec_f1_w),
(@m_w_f1,'2026-01-03 12:00:00', 12.600, N'm³', N'良', @fid1, @pvrec_f1_w),
(@m_w_f1,'2026-01-03 18:00:00', 14.100, N'm³', N'优', @fid1, @pvrec_f1_w);

IF NOT EXISTS (SELECT 1 FROM Data_Energy WHERE Meter_ID=@m_g_f1 AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Energy(Meter_ID, Collect_Time, Value, Unit, Quality, Factory_ID, PV_Record_ID)
VALUES
(@m_g_f1,'2026-01-03 08:00:00', 6.200, N'm³', N'优', @fid1, NULL),
(@m_g_f1,'2026-01-03 12:00:00', 7.050, N'm³', N'良', @fid1, NULL),
(@m_g_f1,'2026-01-03 18:00:00', 8.300, N'm³', N'优', @fid1, NULL);

IF NOT EXISTS (SELECT 1 FROM Data_Energy WHERE Meter_ID=@m_w_f2 AND Collect_Time='2026-01-03 08:00:00')
INSERT INTO Data_Energy(Meter_ID, Collect_Time, Value, Unit, Quality, Factory_ID, PV_Record_ID)
VALUES
(@m_w_f2,'2026-01-03 08:00:00', 5.800, N'm³', N'优', @fid2, NULL),
(@m_w_f2,'2026-01-03 12:00:00', 6.900, N'm³', N'中', @fid2, NULL);

------------------------------------------------------------
-- 8) 光伏：PV_Grid_Point -> PV_Device -> Data_PV_Gen
--         Forecast(Model/Analyst) + Alert
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM PV_Grid_Point WHERE Point_Name=N'北林-光伏并网点')
INSERT INTO PV_Grid_Point(Point_Name, Location)
VALUES(N'北林-光伏并网点', N'北林校园厂区-屋顶光伏');

IF NOT EXISTS (SELECT 1 FROM PV_Grid_Point WHERE Point_Name=N'西区-光伏并网点')
INSERT INTO PV_Grid_Point(Point_Name, Location)
VALUES(N'西区-光伏并网点', N'西区实验厂区-屋顶光伏');

DECLARE @p1 BIGINT, @p2 BIGINT;
SELECT @p1 = Point_ID FROM PV_Grid_Point WHERE Point_Name=N'北林-光伏并网点';
SELECT @p2 = Point_ID FROM PV_Grid_Point WHERE Point_Name=N'西区-光伏并网点';

-- PV_Device：逆变器/汇流箱（外键到 PV_Grid_Point，且可挂接 Device_Ledger）
IF NOT EXISTS (SELECT 1 FROM PV_Device WHERE Device_Type=N'逆变器' AND Point_ID=@p1)
INSERT INTO PV_Device(Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID, Ledger_ID)
VALUES(N'逆变器', 50.00, N'正常', '2024-02-15', N'RS485', @p1, @lid_inv1);

IF NOT EXISTS (SELECT 1 FROM PV_Device WHERE Device_Type=N'汇流箱' AND Point_ID=@p1)
INSERT INTO PV_Device(Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID, Ledger_ID)
VALUES(N'汇流箱', 55.00, N'正常', '2024-02-18',N'Lora' , @p1, @lid_cbbox1);

DECLARE @pv_inv1 BIGINT, @pv_cb1 BIGINT;
SELECT TOP 1 @pv_inv1 = Device_ID FROM PV_Device WHERE Device_Type=N'逆变器' AND Point_ID=@p1 ORDER BY Device_ID;
SELECT TOP 1 @pv_cb1  = Device_ID FROM PV_Device WHERE Device_Type=N'汇流箱' AND Point_ID=@p1 ORDER BY Device_ID;

IF NOT EXISTS (SELECT 1 FROM Data_PV_Gen WHERE Device_ID=@pv_inv1 AND Collect_Time='2026-01-03 10:00:00')
INSERT INTO Data_PV_Gen(Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Factory_ID)
VALUES
(@pv_inv1,'2026-01-03 10:00:00', 120.500, 90.300, 30.200, 98.20, @fid1),
(@pv_inv1,'2026-01-03 12:00:00', 150.700, 110.400, 40.300, 98.60, @fid1),
(@pv_inv1,'2026-01-03 14:00:00', 140.200, 100.000, 40.200, 98.10, @fid1);

-- 预测模型
IF NOT EXISTS (SELECT 1 FROM PV_Forecast_Model WHERE Model_Version='v1.0')
INSERT INTO PV_Forecast_Model(Model_Version, Model_Name, Status, Update_Time)
VALUES('v1.0', N'基础光伏预测模型', 'Active', '2025-12-20 00:00:00');

IF NOT EXISTS (SELECT 1 FROM PV_Forecast_Model WHERE Model_Version='v1.1')
INSERT INTO PV_Forecast_Model(Model_Version, Model_Name, Status, Update_Time)
VALUES('v1.1', N'改进光伏预测模型', 'Active', '2026-01-01 00:00:00');

-- 预测数据（与 Point + Model + Analyst 关联）
IF NOT EXISTS (SELECT 1 FROM Data_PV_Forecast WHERE Point_ID=@p1 AND Forecast_Date='2026-01-03' AND Time_Slot='10:00-11:00')
INSERT INTO Data_PV_Forecast(Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES
(@p1,'2026-01-03','10:00-11:00', 125.0, 120.5, 'v1.1', @analyst_id),
(@p1,'2026-01-03','11:00-12:00', 155.0, 150.7, 'v1.1', @analyst_id),
(@p1,'2026-01-03','12:00-13:00', 145.0, 140.2, 'v1.1', @analyst_id);

-- 模型提醒
IF NOT EXISTS (SELECT 1 FROM PV_Model_Alert WHERE Point_ID=@p1 AND Trigger_Time='2026-01-03 20:00:00')
INSERT INTO PV_Model_Alert(Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
VALUES(@p1, '2026-01-03 20:00:00', N'预测偏差增大，建议复核模型输入数据或更新版本', N'未处理', 'v1.1');

------------------------------------------------------------
-- 9) 告警：Alarm_Info -> Work_Order -> Alarm_Handling_Log
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Alarm_Info WHERE Occur_Time='2026-01-03 12:05:00' AND Alarm_Level=N'高')
INSERT INTO Alarm_Info(Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Verify_Status, Ledger_ID, Factory_ID)
VALUES(N'越限告警', N'高', N'A区主变1 绕组温度超过阈值', '2026-01-03 12:05:00', N'处理中', N'待审核', @lid_t1, @fid1);

IF NOT EXISTS (SELECT 1 FROM Alarm_Info WHERE Occur_Time='2026-01-03 18:10:00' AND Alarm_Level=N'中')
INSERT INTO Alarm_Info(Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Verify_Status, Ledger_ID, Factory_ID)
VALUES(N'通讯故障', N'中', N'B区回路-实验楼 电表通讯中断', '2026-01-03 18:10:00', N'未处理', N'待审核', @lid_cb1, @fid2);

IF NOT EXISTS (SELECT 1 FROM Alarm_Info WHERE Occur_Time='2026-01-02 09:00:00' AND Alarm_Level=N'低')
INSERT INTO Alarm_Info(Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Verify_Status, Ledger_ID, Factory_ID)
VALUES(N'设备故障', N'低', N'逆变器1号 运行状态抖动', '2026-01-02 09:00:00', N'已结案', N'有效', @lid_inv1, @fid1);


DECLARE @alarm_high BIGINT, @alarm_mid BIGINT, @alarm_low BIGINT;
SELECT @alarm_high = Alarm_ID FROM Alarm_Info WHERE Occur_Time='2026-01-03 12:05:00';
SELECT @alarm_mid  = Alarm_ID FROM Alarm_Info WHERE Occur_Time='2026-01-03 18:10:00';
SELECT @alarm_low  = Alarm_ID FROM Alarm_Info WHERE Occur_Time='2026-01-02 09:00:00';

-- 工单（与 Alarm + OandM + Dispatcher + Ledger 有交集；注意 Work_Order 对 Dispatcher_ID 没建 FK，但我们仍填真实 dispatcher_id）
IF NOT EXISTS (SELECT 1 FROM Work_Order WHERE Alarm_ID=@alarm_high)
INSERT INTO Work_Order(Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status)
VALUES
(@alarm_high, @om1_id, @dispatcher_id, @lid_t1,
 '2026-01-03 12:10:00', '2026-01-03 12:25:00', NULL, N'已到场检查，暂未更换部件', NULL);

IF NOT EXISTS (SELECT 1 FROM Work_Order WHERE Alarm_ID=@alarm_mid)
INSERT INTO Work_Order(Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status)
VALUES
(@alarm_mid, @om2_id, @dispatcher_id, @lid_cb1,
 '2026-01-03 18:20:00', NULL, NULL, N'待响应：请先核查网络与采集器供电', NULL);

IF NOT EXISTS (SELECT 1 FROM Work_Order WHERE Alarm_ID=@alarm_low)
INSERT INTO Work_Order(Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status)
VALUES
(@alarm_low, @om1_id, @dispatcher_id, @lid_inv1,
 '2026-01-02 09:10:00', '2026-01-02 09:30:00', '2026-01-02 11:00:00', N'重新上电并校验参数，恢复正常', N'通过');

-- 处理日志（与 Alarm + OandM + Dispatcher 有 FK 交集）
IF NOT EXISTS (SELECT 1 FROM Alarm_Handling_Log WHERE Alarm_ID=@alarm_high AND Handle_Time='2026-01-03 12:12:00')
INSERT INTO Alarm_Handling_Log(Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
VALUES
(@alarm_high, '2026-01-03 12:12:00', N'处理中', @om1_id, @dispatcher_id);

IF NOT EXISTS (SELECT 1 FROM Alarm_Handling_Log WHERE Alarm_ID=@alarm_mid AND Handle_Time='2026-01-03 18:22:00')
INSERT INTO Alarm_Handling_Log(Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
VALUES
(@alarm_mid, '2026-01-03 18:22:00', N'未处理', NULL, @dispatcher_id);

IF NOT EXISTS (SELECT 1 FROM Alarm_Handling_Log WHERE Alarm_ID=@alarm_low AND Handle_Time='2026-01-02 11:05:00')
INSERT INTO Alarm_Handling_Log(Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
VALUES
(@alarm_low, '2026-01-02 11:05:00', N'已结案', @om1_id, @dispatcher_id);

------------------------------------------------------------
-- 10) 大屏：Dashboard_Config -> Stat_Realtime / Stat_History_Trend
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Dashboard_Config WHERE Module_Name=N'能源总览' AND Auth_Level=N'管理层')
INSERT INTO Dashboard_Config(Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES(N'能源总览', N'15s', N'按厂区', N'{"kpi":["Total_KWH","YOY","MOM"]}', N'管理层');

IF NOT EXISTS (SELECT 1 FROM Dashboard_Config WHERE Module_Name=N'光伏总览' AND Auth_Level=N'管理层')
INSERT INTO Dashboard_Config(Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES(N'光伏总览', N'30s', N'按并网点', N'{"kpi":["PV_Gen_KWH","Inverter_Eff"]}', N'管理层');

IF NOT EXISTS (SELECT 1 FROM Dashboard_Config WHERE Module_Name=N'告警总览' AND Auth_Level=N'运维人员')
INSERT INTO Dashboard_Config(Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES(N'告警总览', N'10s', N'按等级', N'{"kpi":["Total_Alarm","High_Alarm"]}', N'运维人员');

DECLARE @cfg_energy BIGINT, @cfg_pv BIGINT, @cfg_alarm BIGINT;
SELECT TOP 1 @cfg_energy = Config_ID FROM Dashboard_Config WHERE Module_Name=N'能源总览' AND Auth_Level=N'管理层' ORDER BY Config_ID;
SELECT TOP 1 @cfg_pv     = Config_ID FROM Dashboard_Config WHERE Module_Name=N'光伏总览' AND Auth_Level=N'管理层' ORDER BY Config_ID;
SELECT TOP 1 @cfg_alarm  = Config_ID FROM Dashboard_Config WHERE Module_Name=N'告警总览' AND Auth_Level=N'运维人员' ORDER BY Config_ID;

-- 实时汇总（PK 是字符串，固定写可重复跑）
IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID='RT2601030800')
INSERT INTO Stat_Realtime(Summary_ID, Stat_Time, Total_KWH, Total_Alarm, PV_Gen_KWH, Config_ID, Manager_ID)
VALUES('RT2601030800', '2026-01-03 08:00:00', 1800.500, 2, 0.000, @cfg_energy, @manager_id);

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID='RT2601031200')
INSERT INTO Stat_Realtime(Summary_ID, Stat_Time, Total_KWH, Total_Alarm, PV_Gen_KWH, Config_ID, Manager_ID)
VALUES('RT2601031200', '2026-01-03 12:00:00', 2200.800, 3, 150.700, @cfg_energy, @manager_id);

-- 历史趋势（与 Config + Analyst 有 FK 交集）
IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID='TR260103D01')
INSERT INTO Stat_History_Trend(Trend_ID, Energy_Type, Stat_Cycle, Stat_Date, Value, YOY_Rate, MOM_Rate, Config_ID, Analyst_ID)
VALUES
('TR260103D01', N'电', N'日', '2026-01-03', 2200.800, 8.50, 2.10, @cfg_energy, @analyst_id);

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID='TR260103PV1')
INSERT INTO Stat_History_Trend(Trend_ID, Energy_Type, Stat_Cycle, Stat_Date, Value, YOY_Rate, MOM_Rate, Config_ID, Analyst_ID)
VALUES
('TR260103PV1', N'光伏', N'日', '2026-01-03', 411.400, 12.30, 3.40, @cfg_pv, @analyst_id);

------------------------------------------------------------
-- 11) 权限表（如果你已跑“权限与账号管理扩展.sql”，这里做幂等补全；没跑则自动跳过）
------------------------------------------------------------
IF OBJECT_ID('Sys_Permission','U') IS NOT NULL
BEGIN
  -- 只做“存在则不插入”，避免 PK 冲突
  IF NOT EXISTS (SELECT 1 FROM Sys_Permission WHERE Perm_Code='ALARM_WORKORDER_VIEW')
    INSERT INTO Sys_Permission(Perm_Code, Perm_Name, Module, Uri_Pattern)
    VALUES('ALARM_WORKORDER_VIEW', N'工单查看', 'alarm', '/alarm/workorder');

  IF OBJECT_ID('Sys_Role_Permission','U') IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sys_Role_Permission WHERE Role_Type='OM' AND Perm_Code='ALARM_WORKORDER_VIEW')
      INSERT INTO Sys_Role_Permission(Role_Type, Perm_Code) VALUES('OM','ALARM_WORKORDER_VIEW');

    IF NOT EXISTS (SELECT 1 FROM Sys_Role_Permission WHERE Role_Type='ADMIN' AND Perm_Code='ALARM_WORKORDER_VIEW')
      INSERT INTO Sys_Role_Permission(Role_Type, Perm_Code) VALUES('ADMIN','ALARM_WORKORDER_VIEW');
  END
END

COMMIT TRAN;
PRINT N'✅ 测试数据填充完成：已生成 用户/角色/厂区/配电/能耗/光伏/告警/工单/大屏 关联数据。';

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;

  SELECT
    ERROR_NUMBER()    AS ErrNo,
    ERROR_SEVERITY()  AS ErrSeverity,
    ERROR_STATE()     AS ErrState,
    ERROR_PROCEDURE() AS ErrProc,
    ERROR_LINE()      AS ErrLine,
    ERROR_MESSAGE()   AS ErrMsg;

  THROW;  -- 直接抛出原始异常（保留真实行号/对象信息）
END CATCH

GO
