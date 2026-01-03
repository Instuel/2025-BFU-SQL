/* ============================================================
   智慧能源管理系统 - 业务线5（大屏数据展示）综合补丁脚本
   负责人：杨尧天（企业管理层 exec_user）
   说明：
     1) 严格对照《智慧能源管理课程设计2025年任务书》2.1.5 大屏数据展示业务线，
        补齐 Dashboard_Config / Stat_Realtime / Stat_History_Trend 的字段与约束；
     2) 在上述结构基础上，为业务线5相关表各插入 25 条示例数据，便于联调大屏与报表；
     3) 请先确保已经执行了《数据库创建脚本.sql》和《测试用户初始化脚本.sql》。
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   一、结构补丁：对照任务书 2.1.5 补齐字段与约束
   ============================================================ */

-- 1.1 Dashboard_Config：补充展示模块与权限等级的枚举约束
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Dashboard_Config_Module_Name')
BEGIN
    ALTER TABLE Dashboard_Config
    ADD CONSTRAINT CK_Dashboard_Config_Module_Name
    CHECK (Module_Name IN (N'能源总览', N'光伏总览', N'配电网运行状态', N'告警统计'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Dashboard_Config_Auth_Level')
BEGIN
    ALTER TABLE Dashboard_Config
    ADD CONSTRAINT CK_Dashboard_Config_Auth_Level
    CHECK (Auth_Level IN (N'管理员', N'能源管理员', N'运维人员'));
END
GO

-- 1.2 Stat_Realtime：补齐任务书要求的实时综合能耗与告警分级字段
IF COL_LENGTH('Stat_Realtime', 'Total_Water') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Total_Water DECIMAL(12,3) NULL;          -- 总用水量
END
GO

IF COL_LENGTH('Stat_Realtime', 'Total_Steam') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Total_Steam DECIMAL(12,3) NULL;          -- 总蒸汽消耗量
END
GO

IF COL_LENGTH('Stat_Realtime', 'Total_Gas') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Total_Gas DECIMAL(12,3) NULL;            -- 总天然气消耗量
END
GO

IF COL_LENGTH('Stat_Realtime', 'PV_SelfUse_KWH') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD PV_SelfUse_KWH DECIMAL(12,3) NULL;       -- 光伏自用电量
END
GO

IF COL_LENGTH('Stat_Realtime', 'Alarm_High_Count') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Alarm_High_Count INT NULL;               -- 高等级告警数
END
GO

IF COL_LENGTH('Stat_Realtime', 'Alarm_Medium_Count') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Alarm_Medium_Count INT NULL;             -- 中等级告警数
END
GO

IF COL_LENGTH('Stat_Realtime', 'Alarm_Low_Count') IS NULL
BEGIN
    ALTER TABLE Stat_Realtime
    ADD Alarm_Low_Count INT NULL;                -- 低等级告警数
END
GO

-- 1.3 Stat_History_Trend：补齐行业均值字段（可选）
IF COL_LENGTH('Stat_History_Trend', 'Industry_Avg_Value') IS NULL
BEGIN
    ALTER TABLE Stat_History_Trend
    ADD Industry_Avg_Value DECIMAL(12,3) NULL;   -- 行业均值（可选）
END
GO

-- 1.4 Stat_History_Trend：补充能源类型与统计周期的枚举约束
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Trend_Energy_Type')
BEGIN
    ALTER TABLE Stat_History_Trend
    ADD CONSTRAINT CK_Trend_Energy_Type
    CHECK (Energy_Type IN (N'电', N'水', N'蒸汽', N'天然气', N'光伏'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Trend_Stat_Cycle')
BEGIN
    ALTER TABLE Stat_History_Trend
    ADD CONSTRAINT CK_Trend_Stat_Cycle
    CHECK (Stat_Cycle IN (N'日', N'周', N'月'));
END
GO

/* ============================================================
   二、示例数据补丁：为业务线5相关表各插入 25 条数据
   ============================================================ */

-- 2.1 获取 exec_user 对应的企业管理层角色 ID 以及 analyst_user 对应的数据分析师角色 ID
DECLARE @ExecManagerID BIGINT;
DECLARE @AnalystID BIGINT;

SELECT @ExecManagerID = m.Manager_ID
FROM Role_Manager m
JOIN Sys_User u ON u.User_ID = m.User_ID
WHERE u.Login_Account = 'exec_user';

IF @ExecManagerID IS NULL
BEGIN
    RAISERROR(N'未找到 exec_user 对应的企业管理层角色，请先执行《测试用户初始化脚本.sql》。', 16, 1);
    RETURN;
END

SELECT @AnalystID = a.Analyst_ID
FROM Role_Analyst a
JOIN Sys_User u ON u.User_ID = a.User_ID
WHERE u.Login_Account = 'analyst_user';

IF @AnalystID IS NULL
BEGIN
    RAISERROR(N'未找到 analyst_user 对应的数据分析师角色，请先执行《测试用户初始化脚本.sql》。', 16, 1);
    RETURN;
END

/* ------------------------------------------------------------
   2.2 大屏展示配置：Dashboard_Config 插入 25 条示例配置
   ------------------------------------------------------------ */

-- 示例配置 01：能源总览 / 30s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按时间降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'管理员');

-- 示例配置 02：光伏总览 / 60s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按能耗降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'能源管理员');

-- 示例配置 03：配电网运行状态 / 90s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按告警数量降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'运维人员');

-- 示例配置 04：告警统计 / 120s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按时间降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'管理员');

-- 示例配置 05：能源总览 / 30s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按能耗降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'能源管理员');

-- 示例配置 06：光伏总览 / 60s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按告警数量降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'运维人员');

-- 示例配置 07：配电网运行状态 / 90s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按时间降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'管理员');

-- 示例配置 08：告警统计 / 120s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按能耗降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'能源管理员');

-- 示例配置 09：能源总览 / 30s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按告警数量降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'运维人员');

-- 示例配置 10：光伏总览 / 60s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按时间降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'管理员');

-- 示例配置 11：配电网运行状态 / 90s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按能耗降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'能源管理员');

-- 示例配置 12：告警统计 / 120s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按告警数量降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'运维人员');

-- 示例配置 13：能源总览 / 30s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按时间降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'管理员');

-- 示例配置 14：光伏总览 / 60s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按能耗降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'能源管理员');

-- 示例配置 15：配电网运行状态 / 90s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按告警数量降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'运维人员');

-- 示例配置 16：告警统计 / 120s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按时间降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'管理员');

-- 示例配置 17：能源总览 / 30s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按能耗降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'能源管理员');

-- 示例配置 18：光伏总览 / 60s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按告警数量降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'运维人员');

-- 示例配置 19：配电网运行状态 / 90s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按时间降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'管理员');

-- 示例配置 20：告警统计 / 120s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按能耗降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'能源管理员');

-- 示例配置 21：能源总览 / 30s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按告警数量降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'运维人员');

-- 示例配置 22：光伏总览 / 60s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'光伏总览', N'60s', N'按时间降序', N'{ "光伏总发电量", "光伏自用电量", "上网电量" }', N'管理员');

-- 示例配置 23：配电网运行状态 / 90s / 能源管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'配电网运行状态', N'90s', N'按能耗降序', N'{ "关键变压器负载率", "重要回路电流", "电压越限次数" }', N'能源管理员');

-- 示例配置 24：告警统计 / 120s / 运维人员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'告警统计', N'120s', N'按告警数量降序', N'{ "总告警次数", "高等级告警数", "中等级告警数", "低等级告警数" }', N'运维人员');

-- 示例配置 25：能源总览 / 30s / 管理员
INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level)
VALUES (N'能源总览', N'30s', N'按时间降序', N'{ "总用电量", "总用水量", "总蒸汽量", "总天然气量" }', N'管理员');

-- 为后续汇总 / 趋势数据选择一条“能源总览”配置作为绑定对象
DECLARE @MainConfigID BIGINT;
SELECT TOP 1 @MainConfigID = Config_ID
FROM Dashboard_Config
WHERE Module_Name = N'能源总览'
ORDER BY Config_ID;

IF @MainConfigID IS NULL
BEGIN
    RAISERROR(N'未能找到任何能源总览的大屏配置，请检查 Dashboard_Config 插入是否成功。', 16, 1);
    RETURN;
END

/* ------------------------------------------------------------
   2.3 实时汇总数据：Stat_Realtime 插入 25 条示例数据
   说明：
     - Summary_ID 采用 RTB5_0001 ~ RTB5_0025，避免与其他业务线冲突；
     - Stat_Time 模拟 2025-01-01 08:00 起每分钟一条数据；
     - 总用电量 / 水 / 蒸汽 / 天然气 / 光伏自用 / 光伏总发电量 采用递增数列；
     - 总告警次数及高 / 中 / 低等级告警数采用可解释的分解关系。
   ------------------------------------------------------------ */
IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0001')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0001', '2025-01-01 08:00:00',
     1000.000, 200.000, 150.000, 300.000,
     250.000, 180.000, 3, 0, 1, 2,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0002')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0002', '2025-01-01 08:01:00',
     1015.000, 202.500, 151.800, 303.200,
     254.000, 183.000, 6, 1, 2, 3,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0003')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0003', '2025-01-01 08:02:00',
     1030.000, 205.000, 153.600, 306.400,
     258.000, 186.000, 9, 2, 3, 4,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0004')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0004', '2025-01-01 08:03:00',
     1045.000, 207.500, 155.400, 309.600,
     262.000, 189.000, 0, 0, 0, 0,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0005')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0005', '2025-01-01 08:04:00',
     1060.000, 210.000, 157.200, 312.800,
     266.000, 192.000, 3, 1, 1, 1,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0006')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0006', '2025-01-01 08:05:00',
     1075.000, 212.500, 159.000, 316.000,
     270.000, 195.000, 6, 2, 2, 2,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0007')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0007', '2025-01-01 08:06:00',
     1090.000, 215.000, 160.800, 319.200,
     274.000, 198.000, 6, 0, 3, 3,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0008')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0008', '2025-01-01 08:07:00',
     1105.000, 217.500, 162.600, 322.400,
     278.000, 201.000, 5, 1, 0, 4,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0009')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0009', '2025-01-01 08:08:00',
     1120.000, 220.000, 164.400, 325.600,
     282.000, 204.000, 3, 2, 1, 0,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0010')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0010', '2025-01-01 08:09:00',
     1135.000, 222.500, 166.200, 328.800,
     286.000, 207.000, 3, 0, 2, 1,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0011')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0011', '2025-01-01 08:10:00',
     1150.000, 225.000, 168.000, 332.000,
     290.000, 210.000, 6, 1, 3, 2,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0012')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0012', '2025-01-01 08:11:00',
     1165.000, 227.500, 169.800, 335.200,
     294.000, 213.000, 5, 2, 0, 3,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0013')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0013', '2025-01-01 08:12:00',
     1180.000, 230.000, 171.600, 338.400,
     298.000, 216.000, 5, 0, 1, 4,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0014')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0014', '2025-01-01 08:13:00',
     1195.000, 232.500, 173.400, 341.600,
     302.000, 219.000, 3, 1, 2, 0,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0015')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0015', '2025-01-01 08:14:00',
     1210.000, 235.000, 175.200, 344.800,
     306.000, 222.000, 6, 2, 3, 1,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0016')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0016', '2025-01-01 08:15:00',
     1225.000, 237.500, 177.000, 348.000,
     310.000, 225.000, 2, 0, 0, 2,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0017')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0017', '2025-01-01 08:16:00',
     1240.000, 240.000, 178.800, 351.200,
     314.000, 228.000, 5, 1, 1, 3,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0018')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0018', '2025-01-01 08:17:00',
     1255.000, 242.500, 180.600, 354.400,
     318.000, 231.000, 8, 2, 2, 4,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0019')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0019', '2025-01-01 08:18:00',
     1270.000, 245.000, 182.400, 357.600,
     322.000, 234.000, 3, 0, 3, 0,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0020')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0020', '2025-01-01 08:19:00',
     1285.000, 247.500, 184.200, 360.800,
     326.000, 237.000, 2, 1, 0, 1,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0021')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0021', '2025-01-01 08:20:00',
     1300.000, 250.000, 186.000, 364.000,
     330.000, 240.000, 5, 2, 1, 2,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0022')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0022', '2025-01-01 08:21:00',
     1315.000, 252.500, 187.800, 367.200,
     334.000, 243.000, 5, 0, 2, 3,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0023')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0023', '2025-01-01 08:22:00',
     1330.000, 255.000, 189.600, 370.400,
     338.000, 246.000, 8, 1, 3, 4,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0024')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0024', '2025-01-01 08:23:00',
     1345.000, 257.500, 191.400, 373.600,
     342.000, 249.000, 2, 2, 0, 0,
     @MainConfigID, @ExecManagerID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_Realtime WHERE Summary_ID = N'RTB5_0025')
BEGIN
    INSERT INTO Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Water, Total_Steam, Total_Gas,
     PV_Gen_KWH, PV_SelfUse_KWH, Total_Alarm, Alarm_High_Count, Alarm_Medium_Count, Alarm_Low_Count,
     Config_ID, Manager_ID)
    VALUES
    (N'RTB5_0025', '2025-01-01 08:24:00',
     1360.000, 260.000, 193.200, 376.800,
     346.000, 252.000, 2, 0, 1, 1,
     @MainConfigID, @ExecManagerID);
END
GO

/* ------------------------------------------------------------
   2.4 历史趋势数据：Stat_History_Trend 插入 25 条示例数据
   说明：
     - Trend_ID 采用 HTB5_0001 ~ HTB5_0025；
     - Energy_Type 在【电 / 水 / 蒸汽 / 天然气 / 光伏】之间循环；
     - Stat_Cycle 在【日 / 周 / 月】之间循环；
     - Stat_Date 从 2024-12-01 起每天一条；
     - Value 模拟实际能耗 / 发电量数值；
     - YOY_Rate / MOM_Rate 模拟同比 / 环比（单位：百分比）；
     - Industry_Avg_Value 模拟行业平均水平，略高于本厂数据。
   ------------------------------------------------------------ */
IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0001')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0001', N'电', N'日', '2024-12-01',
     400.000, -5.00, -3.00, 420.000,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0002')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0002', N'水', N'周', '2024-12-02',
     412.500, -4.70, -2.75, 433.125,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0003')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0003', N'蒸汽', N'月', '2024-12-03',
     425.000, -4.40, -2.50, 446.250,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0004')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0004', N'天然气', N'日', '2024-12-04',
     437.500, -4.10, -2.25, 459.375,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0005')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0005', N'光伏', N'周', '2024-12-05',
     450.000, -3.80, -2.00, 472.500,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0006')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0006', N'电', N'月', '2024-12-06',
     462.500, -3.50, -1.75, 485.625,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0007')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0007', N'水', N'日', '2024-12-07',
     475.000, -3.20, -1.50, 498.750,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0008')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0008', N'蒸汽', N'周', '2024-12-08',
     487.500, -2.90, -1.25, 511.875,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0009')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0009', N'天然气', N'月', '2024-12-09',
     500.000, -2.60, -1.00, 525.000,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0010')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0010', N'光伏', N'日', '2024-12-10',
     512.500, -2.30, -0.75, 538.125,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0011')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0011', N'电', N'周', '2024-12-11',
     525.000, -2.00, -0.50, 551.250,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0012')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0012', N'水', N'月', '2024-12-12',
     537.500, -1.70, -0.25, 564.375,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0013')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0013', N'蒸汽', N'日', '2024-12-13',
     550.000, -1.40, 0.00, 577.500,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0014')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0014', N'天然气', N'周', '2024-12-14',
     562.500, -1.10, 0.25, 590.625,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0015')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0015', N'光伏', N'月', '2024-12-15',
     575.000, -0.80, 0.50, 603.750,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0016')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0016', N'电', N'日', '2024-12-16',
     587.500, -0.50, 0.75, 616.875,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0017')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0017', N'水', N'周', '2024-12-17',
     600.000, -0.20, 1.00, 630.000,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0018')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0018', N'蒸汽', N'月', '2024-12-18',
     612.500, 0.10, 1.25, 643.125,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0019')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0019', N'天然气', N'日', '2024-12-19',
     625.000, 0.40, 1.50, 656.250,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0020')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0020', N'光伏', N'周', '2024-12-20',
     637.500, 0.70, 1.75, 669.375,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0021')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0021', N'电', N'月', '2024-12-21',
     650.000, 1.00, 2.00, 682.500,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0022')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0022', N'水', N'日', '2024-12-22',
     662.500, 1.30, 2.25, 695.625,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0023')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0023', N'蒸汽', N'周', '2024-12-23',
     675.000, 1.60, 2.50, 708.750,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0024')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0024', N'天然气', N'月', '2024-12-24',
     687.500, 1.90, 2.75, 721.875,
     @MainConfigID, @AnalystID);
END
GO

IF NOT EXISTS (SELECT 1 FROM Stat_History_Trend WHERE Trend_ID = N'HTB5_0025')
BEGIN
    INSERT INTO Stat_History_Trend
    (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date,
     Value, YOY_Rate, MOM_Rate, Industry_Avg_Value,
     Config_ID, Analyst_ID)
    VALUES
    (N'HTB5_0025', N'光伏', N'日', '2024-12-25',
     700.000, 2.20, 3.00, 735.000,
     @MainConfigID, @AnalystID);
END
GO

PRINT N'✓ 业务线5（大屏数据展示）结构与示例数据补丁执行完成：Dashboard_Config / Stat_Realtime / Stat_History_Trend 已更新。';
