USE SQL_BFU;
GO

/* ============================================================
   0. 清理旧的触发器
   ============================================================ */
IF OBJECT_ID('dbo.TR_Transformer_Analyze', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Transformer_Analyze;
GO

IF OBJECT_ID('dbo.TR_Circuit_Analyze', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Circuit_Analyze;
GO

/* ============================================================
   触发器 1：变压器数据分析 (修正版)
   修正内容：
   1. Data表插入时不包含 Device_Status。
   2. 根据数据判断结果，UPDATE Dist_Transformer 表的 Device_Status。
   ============================================================ */
CREATE TRIGGER TR_Transformer_Analyze
ON Data_Transformer
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 获取阈值
    DECLARE @Threshold DECIMAL(12,3);
    SELECT TOP 1 @Threshold = Trigger_Threshold
    FROM Alarm_Info
    WHERE Alarm_Type = N'越限告警' AND Trigger_Threshold IS NOT NULL
    ORDER BY Occur_Time DESC;

    SET @Threshold = ISNULL(@Threshold, 80.0); 

    -- 2. 执行数据插入 (从列列表中移除 Device_Status)
    INSERT INTO Data_Transformer (
        Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, 
        Load_Rate, Factory_ID
    )
    SELECT 
        i.Transformer_ID, i.Collect_Time, i.Winding_Temp, i.Core_Temp, 
        i.Load_Rate, i.Factory_ID
    FROM inserted i;

    -- 3. 【新增】更新台账表的设备状态 (Dist_Transformer)
    -- 逻辑：如果有任意一条新插入的数据异常，则更新对应设备为'异常'，否则保持原样或更新为正常
    -- 注意：这里简化处理，直接根据最新一条数据的状态更新设备
    UPDATE t
    SET Device_Status = CASE 
            WHEN (
                (i.Winding_Temp > @Threshold AND i.Winding_Temp <> 999 AND i.Winding_Temp > 0) OR
                (i.Core_Temp > @Threshold    AND i.Core_Temp <> 999    AND i.Core_Temp > 0)
            ) THEN N'异常'
            ELSE N'正常' -- 如果数据正常，恢复设备状态为正常
        END
    FROM Dist_Transformer t
    JOIN inserted i ON t.Transformer_ID = i.Transformer_ID;

    -- 4. 生成告警
    INSERT INTO Alarm_Info (
        Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, 
        Ledger_ID, Factory_ID, Trigger_Threshold, Verify_Status, Verify_Remark
    )
    SELECT 
        N'越限告警',
        N'高',
        N'变压器温度越限! 绕组:' + CAST(i.Winding_Temp AS NVARCHAR(20)) + N'℃, 铁芯:' + CAST(i.Core_Temp AS NVARCHAR(20)) + N'℃ (阈值:' + CAST(@Threshold AS NVARCHAR(20)) + N')',
        i.Collect_Time,
        N'未处理',
        t.Ledger_ID,
        i.Factory_ID,
        @Threshold,
        N'待审核',
        NULL
    FROM inserted i
    JOIN Dist_Transformer t ON i.Transformer_ID = t.Transformer_ID
    WHERE (
        (i.Winding_Temp > @Threshold AND i.Winding_Temp <> 999 AND i.Winding_Temp > 0) OR
        (i.Core_Temp > @Threshold    AND i.Core_Temp <> 999    AND i.Core_Temp > 0)
    );
END;
GO
PRINT '触发器 1 (修复版) 创建成功';
GO

/* ============================================================
   触发器 2：回路数据综合分析 (修正版)
   修正内容：同步更新 Dist_Circuit 的 Device_Status
   ============================================================ */
CREATE TRIGGER TR_Circuit_Analyze
ON Data_Circuit
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Threshold_V DECIMAL(12,3); 
    SELECT TOP 1 @Threshold_V = Trigger_Threshold
    FROM Alarm_Info
    WHERE Alarm_Type = N'越限告警' AND Trigger_Threshold IS NOT NULL
    ORDER BY Occur_Time DESC;
    SET @Threshold_V = ISNULL(@Threshold_V, 37.0); 

    -- 1. 执行插入 (移除 Device_Status)
    INSERT INTO Data_Circuit (
        Circuit_ID, Collect_Time, Voltage, Current_Val, 
        Active_Power, Reactive_Power, Power_Factor, 
        Switch_Status, Factory_ID
    )
    SELECT 
        i.Circuit_ID, i.Collect_Time, i.Voltage, i.Current_Val, 
        i.Active_Power, i.Reactive_Power, i.Power_Factor, 
        i.Switch_Status, i.Factory_ID
    FROM inserted i;

    -- 2. 【新增】更新台账表的设备状态 (Dist_Circuit)
    UPDATE c
    SET Device_Status = CASE 
            WHEN (i.Voltage > @Threshold_V AND i.Voltage <> 999 AND i.Voltage > 0) THEN N'异常'
            WHEN (i.Voltage >= 999 OR i.Voltage <= 0 OR i.Current_Val >= 999 OR i.Current_Val <= 0) THEN N'异常' -- 离线/故障也算异常
            ELSE N'正常'
        END
    FROM Dist_Circuit c
    JOIN inserted i ON c.Circuit_ID = i.Circuit_ID;

    -- 3. 生成越限告警
    INSERT INTO Alarm_Info (
        Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, 
        Ledger_ID, Factory_ID, Trigger_Threshold, Verify_Status, Verify_Remark
    )
    SELECT 
        N'越限告警', N'高',
        N'回路参数越限! 电压:' + CAST(i.Voltage AS NVARCHAR(20)) + N'kV (阈值:' + CAST(@Threshold_V AS NVARCHAR(20)) + N')',
        i.Collect_Time, N'未处理', c.Ledger_ID, i.Factory_ID, @Threshold_V, N'待审核', NULL
    FROM inserted i
    JOIN Dist_Circuit c ON i.Circuit_ID = c.Circuit_ID
    WHERE (i.Voltage > @Threshold_V AND i.Voltage <> 999 AND i.Voltage > 0); 

    -- 4. 生成离线告警
    INSERT INTO Alarm_Info (
        Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, 
        Ledger_ID, Factory_ID, Trigger_Threshold, Verify_Status, Verify_Remark
    )
    SELECT 
        N'设备离线', N'高',
        N'监测数值异常(999/0)，判定为设备离线或传感器断网。',
        i.Collect_Time, N'未处理', c.Ledger_ID, i.Factory_ID, NULL, N'待审核', NULL
    FROM inserted i
    JOIN Dist_Circuit c ON i.Circuit_ID = c.Circuit_ID
    WHERE (
        i.Voltage >= 999 OR i.Voltage <= 0 OR 
        i.Current_Val >= 999 OR i.Current_Val <= 0
    );
END;
GO
PRINT '触发器 2 (修复版) 创建成功';
GO

/* ============================================================
   视图 1: 厂区回路异常数据视图 (修正)
   修正点：此视图原本基于数值筛选，受影响较小，主要是 Status 引用需修正
============================================================ */
IF OBJECT_ID ('View_Circuit_Abnormal', 'V') IS NOT NULL DROP VIEW View_Circuit_Abnormal;
GO
CREATE VIEW View_Circuit_Abnormal AS
SELECT
    d.Data_ID,
    d.Circuit_ID,
    c.Circuit_Name,
    f.Factory_ID, f.Factory_Name,
    r.Room_ID, r.Room_Name, r.Voltage_Level,
    l.Device_Name AS Ledger_Device_Name,
    l.Model_Spec AS Device_Model,
    l.Warranty_Years,
    d.Collect_Time,
    CAST(d.Collect_Time AS TIME) AS Abnormal_TimeSlot,
    d.Voltage,
    d.Current_Val,
    d.Active_Power,
    d.Switch_Status,
    CASE
        WHEN d.Voltage > 37 THEN N'过压'
        WHEN d.Voltage < 33 THEN N'欠压'
    END AS Abnormal_Type,
    CASE
        WHEN d.Voltage > 38 OR d.Voltage < 32 THEN N'严重'
        WHEN d.Voltage > 37 OR d.Voltage < 33 THEN N'一般'
    END AS Abnormal_Level,
    N'33kV≤正常电压≤37kV' AS Threshold_Desc
FROM Data_Circuit d
JOIN Dist_Circuit c ON d.Circuit_ID = c.Circuit_ID
JOIN Dist_Room r ON c.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON c.Ledger_ID = l.Ledger_ID
WHERE (d.Voltage > 37 OR d.Voltage < 33) AND d.Voltage IS NOT NULL;
GO

/* ============================================================
   视图 2: 数据完整性校验视图 (修正)
   修正点：d.Device_Status -> c.Device_Status / t.Device_Status
============================================================ */
IF OBJECT_ID('View_PowerGrid_Data_Integrity', 'V') IS NOT NULL DROP VIEW View_PowerGrid_Data_Integrity;
GO
CREATE VIEW View_PowerGrid_Data_Integrity AS
SELECT
    N'线路' AS Device_Type,
    c.Circuit_ID AS Device_ID,
    c.Circuit_Name AS Device_Name,
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    d.Collect_Time,
    CASE WHEN d.Voltage IS NULL OR d.Current_Val IS NULL THEN N'数据不完整' ELSE N'数据完整' END AS Data_Integrity_Status,
    CASE WHEN d.Voltage IS NULL AND d.Current_Val IS NULL THEN N'电压、电流均缺失'
         WHEN d.Voltage IS NULL THEN N'电压缺失'
         WHEN d.Current_Val IS NULL THEN N'电流缺失'
         ELSE N'无缺失' END AS Missing_Field,
    c.Device_Status AS Equipment_Status, -- 【修正】取台账状态
    r.Voltage_Level
FROM Data_Circuit d
JOIN Dist_Circuit c ON d.Circuit_ID = c.Circuit_ID
JOIN Dist_Room r ON c.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
WHERE d.Voltage IS NULL OR d.Current_Val IS NULL
UNION ALL
SELECT
    N'变压器' AS Device_Type,
    t.Transformer_ID AS Device_ID,
    t.Transformer_Name AS Device_Name,
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    d.Collect_Time,
    CASE WHEN d.Winding_Temp IS NULL OR d.Load_Rate IS NULL THEN N'数据不完整' ELSE N'数据完整' END AS Data_Integrity_Status,
    CASE WHEN d.Winding_Temp IS NULL AND d.Load_Rate IS NULL THEN N'绕组温度、负载率均缺失'
         WHEN d.Winding_Temp IS NULL THEN N'绕组温度缺失'
         WHEN d.Load_Rate IS NULL THEN N'负载率缺失'
         ELSE N'无缺失' END AS Missing_Field,
    t.Device_Status AS Equipment_Status, -- 【修正】取台账状态
    r.Voltage_Level
FROM Data_Transformer d
JOIN Dist_Transformer t ON d.Transformer_ID = t.Transformer_ID
JOIN Dist_Room r ON t.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
WHERE d.Winding_Temp IS NULL OR d.Load_Rate IS NULL;
GO

/* ============================================================
   视图 3：每日峰谷时段用电统计 (修正)
   修正点：Data表无Status，统计异常数改用数值阈值判断
============================================================ */
IF OBJECT_ID('View_Daily_PeakValley_Power_Stats', 'V') IS NOT NULL DROP VIEW View_Daily_PeakValley_Power_Stats;
GO
CREATE VIEW View_Daily_PeakValley_Power_Stats AS
WITH Circuit_PeakValley_Match AS (
    SELECT
        dc.Data_ID,
        CAST(dc.Collect_Time AS DATE) AS Stat_Date,
        dc.Factory_ID,
        dc.Circuit_ID,
        c.Room_ID,
        dc.Active_Power,
        dc.Voltage,
        -- 【修正】使用数值判断是否异常 (电压>37) 代替 Device_Status 字段
        CASE WHEN dc.Voltage > 37 OR dc.Voltage < 33 THEN 1 ELSE 0 END AS Is_Abnormal,
        DATEDIFF(SECOND, LAG(dc.Collect_Time) OVER (PARTITION BY dc.Circuit_ID ORDER BY dc.Collect_Time), dc.Collect_Time) / 3600.0 AS Collect_Interval_H,
        cp.Time_Type AS Peak_Type,
        cp.Price_Rate
    FROM Data_Circuit dc
    JOIN Dist_Circuit c ON dc.Circuit_ID = c.Circuit_ID
    LEFT JOIN Config_PeakValley cp 
        ON CAST(dc.Collect_Time AS TIME(0)) BETWEEN cp.Start_Time AND cp.End_Time
    WHERE dc.Active_Power IS NOT NULL
),
Transformer_Daily_Peak AS (
    SELECT
        CAST(dt.Collect_Time AS DATE) AS Stat_Date,
        dt.Factory_ID,
        t.Room_ID,
        cp.Time_Type AS Peak_Type,
        AVG(dt.Winding_Temp) AS Avg_Trans_Winding_Temp,
        AVG(dt.Load_Rate) AS Avg_Trans_Load_Rate,
        -- 【修正】使用数值判断是否异常 (温度>80)
        SUM(CASE WHEN dt.Winding_Temp > 80 THEN 1 ELSE 0 END) AS Trans_Abnormal_Count
    FROM Data_Transformer dt
    JOIN Dist_Transformer t ON dt.Transformer_ID = t.Transformer_ID
    LEFT JOIN Config_PeakValley cp 
        ON CAST(dt.Collect_Time AS TIME(0)) BETWEEN cp.Start_Time AND cp.End_Time
    GROUP BY
        CAST(dt.Collect_Time AS DATE), dt.Factory_ID, t.Room_ID, cp.Time_Type
)
SELECT
    f.Factory_ID, f.Factory_Name,
    r.Room_ID, r.Room_Name, r.Voltage_Level,
    cpm.Stat_Date, cpm.Peak_Type, cpm.Price_Rate,
    COUNT(DISTINCT cpm.Circuit_ID) AS Circuit_Count,
    SUM(CASE WHEN cpm.Collect_Interval_H > 0 THEN cpm.Active_Power * cpm.Collect_Interval_H ELSE 0 END) AS Total_Power_KWH,
    AVG(cpm.Active_Power) AS Avg_Active_Power_KW,
    MAX(cpm.Active_Power) AS Max_Active_Power_KW,
    SUM(cpm.Is_Abnormal) AS Circuit_Abnormal_Count,
    td.Avg_Trans_Winding_Temp,
    td.Avg_Trans_Load_Rate,
    td.Trans_Abnormal_Count,
    ROUND(SUM(CASE WHEN cpm.Collect_Interval_H > 0 THEN cpm.Active_Power * cpm.Collect_Interval_H ELSE 0 END) * cpm.Price_Rate, 2) AS Estimated_Cost
FROM Circuit_PeakValley_Match cpm
JOIN Base_Factory f ON cpm.Factory_ID = f.Factory_ID
JOIN Dist_Room r ON cpm.Room_ID = r.Room_ID
LEFT JOIN Transformer_Daily_Peak td 
    ON cpm.Stat_Date = td.Stat_Date AND cpm.Room_ID = td.Room_ID AND cpm.Peak_Type = td.Peak_Type
GROUP BY
    f.Factory_ID, f.Factory_Name, r.Room_ID, r.Room_Name, r.Voltage_Level,
    cpm.Stat_Date, cpm.Peak_Type, cpm.Price_Rate,
    td.Avg_Trans_Winding_Temp, td.Avg_Trans_Load_Rate, td.Trans_Abnormal_Count
HAVING SUM(CASE WHEN cpm.Collect_Interval_H > 0 THEN cpm.Active_Power * cpm.Collect_Interval_H ELSE 0 END) > 0;
GO

/* ============================================================
   视图 4：实时数据视图 (修正)
   修正点：CTE中移除Device_Status，主查询改为引用 Dist_ 表
============================================================ */
IF OBJECT_ID('View_RealTime_Device_Data', 'V') IS NOT NULL DROP VIEW View_RealTime_Device_Data;
GO
CREATE VIEW View_RealTime_Device_Data AS
-- CTE 1：获取变压器最新数据（不含状态）
WITH CTE_Latest_Transformer AS (
    SELECT 
        Transformer_ID, Winding_Temp, Core_Temp, Load_Rate, Collect_Time,
        ROW_NUMBER() OVER (PARTITION BY Transformer_ID ORDER BY Collect_Time DESC) AS RN
    FROM Data_Transformer
),
-- CTE 2：获取回路最新数据（不含状态）
CTE_Latest_Circuit AS (
    SELECT 
        Circuit_ID, Voltage, Current_Val, Switch_Status, Collect_Time,
        ROW_NUMBER() OVER (PARTITION BY Circuit_ID ORDER BY Collect_Time DESC) AS RN
    FROM Data_Circuit
)
SELECT
    N'变压器' AS Device_Type,
    t.Transformer_ID AS Device_ID,
    t.Transformer_Name AS Device_Name,
    ISNULL(l.Model_Spec, N'未知型号') AS Model_Spec,
    f.Factory_Name, r.Room_Name, r.Voltage_Level,
    dt.Collect_Time AS Latest_Collect_Time,
    dt.Winding_Temp, dt.Core_Temp, dt.Load_Rate,
    CAST(NULL AS DECIMAL(10,3)) AS Voltage,
    CAST(NULL AS DECIMAL(10,3)) AS Current_Val,
    CAST(NULL AS NVARCHAR(10))  AS Switch_Status,
    -- 【修正】状态取自 Dist_Transformer
    ISNULL(t.Device_Status, N'离线') AS Device_Status, 
    CASE 
        WHEN t.Device_Status = N'异常' THEN N'红色' 
        WHEN t.Device_Status = N'正常' THEN N'绿色'
        ELSE N'灰色'
    END AS Status_Color
FROM Dist_Transformer t
JOIN Dist_Room r ON t.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON t.Ledger_ID = l.Ledger_ID
LEFT JOIN CTE_Latest_Transformer dt ON t.Transformer_ID = dt.Transformer_ID AND dt.RN = 1
UNION ALL
SELECT
    N'回路' AS Device_Type,
    c.Circuit_ID AS Device_ID,
    c.Circuit_Name AS Device_Name,
    ISNULL(l.Model_Spec, N'未知型号') AS Model_Spec,
    f.Factory_Name, r.Room_Name, r.Voltage_Level,
    dc.Collect_Time AS Latest_Collect_Time,
    CAST(NULL AS DECIMAL(6,2)) AS Winding_Temp,
    CAST(NULL AS DECIMAL(6,2)) AS Core_Temp,
    CAST(NULL AS DECIMAL(5,2)) AS Load_Rate,
    dc.Voltage, dc.Current_Val, dc.Switch_Status,
    -- 【修正】状态取自 Dist_Circuit
    ISNULL(c.Device_Status, N'离线') AS Device_Status,
    CASE 
        WHEN c.Device_Status = N'异常' THEN N'红色' 
        WHEN c.Device_Status = N'正常' THEN N'绿色'
        ELSE N'灰色' 
    END AS Status_Color
FROM Dist_Circuit c
JOIN Dist_Room r ON c.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON c.Ledger_ID = l.Ledger_ID
LEFT JOIN CTE_Latest_Circuit dc ON c.Circuit_ID = dc.Circuit_ID AND dc.RN = 1;
GO

/* ============================================================
   视图 5：配电房汇总 (修正)
   修正点：Device_Status 来源变更为 t.Device_Status 和 c.Device_Status
============================================================ */
IF OBJECT_ID('View_DistRoom_Equipment_Status', 'V') IS NOT NULL DROP VIEW View_DistRoom_Equipment_Status;
GO
CREATE VIEW View_DistRoom_Equipment_Status AS
SELECT
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    r.Location, r.Voltage_Level, u.Real_Name AS Room_Manager,
    COUNT(DISTINCT t.Transformer_ID) AS Total_Transformers,
    -- 【修正】直接统计 Dist 表状态
    SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Transformers,
    SUM(CASE WHEN t.Device_Status = N'异常' THEN 1 ELSE 0 END) AS Abnormal_Transformers,
    COUNT(DISTINCT c.Circuit_ID) AS Total_Circuits,
    SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Circuits,
    SUM(CASE WHEN c.Device_Status = N'异常' THEN 1 ELSE 0 END) AS Abnormal_Circuits,
    -- 计算健康度
    CASE 
        WHEN (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)) = 0 THEN 0.00
        ELSE ROUND(
            (SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) + SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END)) * 1.0 
            / (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)), 2
        )
    END AS Overall_Health_Score,
    CASE 
        WHEN (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)) = 0 THEN N'无设备'
        WHEN ROUND(
            (SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) + SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END)) * 1.0 
            / (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)), 2
        ) >= 0.9 THEN N'优秀'
        WHEN ROUND(
            (SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) + SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END)) * 1.0 
            / (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)), 2
        ) >= 0.7 THEN N'良好'
        ELSE N'较差'
    END AS Health_Level
FROM Dist_Room r
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
LEFT JOIN Sys_User u ON r.Manager_User_ID = u.User_ID
LEFT JOIN Dist_Transformer t ON r.Room_ID = t.Room_ID
LEFT JOIN Dist_Circuit c ON r.Room_ID = c.Room_ID
GROUP BY
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    r.Location, r.Voltage_Level, u.Real_Name;
GO


/* ============================================================
   智慧能源管理系统 - 自动化测试数据生成脚本 (精简版)
   目标数据库：SQL_BFU
   生成内容：8张核心表，每表 20 条数据
   说明：已调整外键关联，确保前20条数据内部逻辑自洽
   ============================================================ */

USE SQL_BFU;
GO

SET NOCOUNT ON;

-- 1. 预设：插入必要系统用户 (参考 Sys_User示例.txt)
IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'admin')
BEGIN
    INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status)
    VALUES 
    ('admin', 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11', 'VGVzdFNhbHQxMjM0NTY3OA==', N'张管理', N'信息技术部', '13800000001', 1);
END
DECLARE @MgrID BIGINT = (SELECT TOP 1 User_ID FROM Sys_User WHERE Login_Account = 'admin');

-- ============================================================
-- 1. Base_Factory (厂区信息) - 20条
-- ============================================================
PRINT '正在生成 Base_Factory 数据...';
INSERT INTO Base_Factory (Factory_Name, Area_Desc, Manager_User_ID)
VALUES 
(N'总厂区', N'北京市海淀区清华东路35号', @MgrID),
(N'一分厂-模具车间', N'东区A座', @MgrID),
(N'一分厂-组装车间', N'东区B座', @MgrID),
(N'二分厂-涂装车间', N'西区C座', NULL), 
(N'二分厂-冲压车间', N'西区D座', @MgrID),
(N'三分厂-注塑车间', N'北区E座', @MgrID),
(N'三分厂-包装车间', N'北区F座', NULL),
(N'研发中心实验室', N'科技园1号楼', @MgrID),
(N'员工宿舍区', N'生活区', NULL),
(N'仓储物流中心', N'物流园', @MgrID),
(N'污水处理站', N'环保区', @MgrID),
(N'光伏发电示范区', N'厂区屋顶', NULL),
(N'高压配电总站', N'动力区', @MgrID),
(N'备用厂区A', N'预留用地', NULL),
(N'备用厂区B', N'预留用地', NULL),
(N'四分厂-精加工', N'南区G座', @MgrID),
(N'四分厂-热处理', N'南区H座', @MgrID),
(N'五分厂-电子产线', N'高新园区', @MgrID),
(N'测试车间01', N'临时区域', NULL),
(N'测试车间02', N'临时区域', NULL); 
-- 20条截止
GO

-- ============================================================
-- 2. Config_PeakValley (峰谷配置) - 20条
-- ============================================================
PRINT '正在生成 Config_PeakValley 数据...';
INSERT INTO Config_PeakValley (Time_Type, Start_Time, End_Time, Price_Rate)
VALUES
-- 策略A
(N'低谷', '00:00:00', '06:00:00', 0.3500),
(N'平段', '06:00:00', '08:00:00', 0.6500),
(N'高峰', '08:00:00', '10:00:00', 1.1000),
(N'尖峰', '10:00:00', '12:00:00', 1.3500),
(N'高峰', '12:00:00', '14:00:00', 1.1000),
(N'平段', '14:00:00', '16:00:00', 0.6500),
(N'尖峰', '16:00:00', '18:00:00', 1.3500),
(N'高峰', '18:00:00', '22:00:00', 1.1000),
(N'平段', '22:00:00', '23:59:59', 0.6500),
-- 策略B
(N'低谷', '00:00:00', '05:00:00', 0.4000),
(N'平段', '05:00:00', '09:00:00', 0.7000),
(N'高峰', '09:00:00', '11:00:00', 1.2000),
(N'尖峰', '11:00:00', '13:00:00', 1.5000),
(N'高峰', '13:00:00', '15:00:00', 1.2000),
(N'平段', '15:00:00', '17:00:00', 0.7000),
(N'尖峰', '17:00:00', '19:00:00', 1.5000),
(N'高峰', '19:00:00', '22:00:00', 1.2000),
(N'低谷', '22:00:00', '23:59:59', 0.4000),
-- 策略C测试
(N'平段', '08:00:00', '18:00:00', 0.6000),
(N'尖峰', '10:00:00', '11:00:00', 1.8000); 
-- 20条截止
GO

-- ============================================================
-- 3. Device_Ledger (设备台账) - 20条
-- ============================================================
PRINT '正在生成 Device_Ledger 数据...';
INSERT INTO Device_Ledger (Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status, Warranty_Years, Calibration_Time, Calibration_Person)
VALUES
(N'1#主变压器', N'变压器', N'S11-2500KVA', '2020-01-01', N'正常使用', 5, '2025-01-01', N'张三'),
(N'2#备用变压器', N'变压器', N'S13-M-1000', '2021-06-15', N'正常使用', 3, '2024-12-01', N'李四'),
(N'1号车间总水表', N'水表', N'DN100', '2019-03-10', N'正常使用', 2, NULL, NULL),
(N'屋顶光伏逆变器A', N'逆变器', N'SUN2000', '2023-01-01', N'正常使用', 5, '2025-06-01', N'厂家人员'),
(N'屋顶光伏逆变器B', N'逆变器', N'SUN2000', '2023-01-01', N'正常使用', 5, NULL, NULL),
(N'东区汇流箱01', N'汇流箱', N'PV-16', '2023-02-01', N'正常使用', 3, NULL, NULL),
(N'配电室智能电表1', N'电表', N'DTSD1352', '2022-05-20', N'正常使用', 1, '2025-01-10', N'王五'),
(N'配电室智能电表2', N'电表', N'DTSD1352', '2022-05-20', N'正常使用', 1, NULL, NULL),
(N'食堂天然气表', N'气表', N'G65', '2020-11-11', N'正常使用', 2, '2024-11-11', N'燃气公司'),
(N'3#老旧变压器', N'变压器', N'S9-800', '2010-01-01', N'已报废', 0, NULL, NULL),
(N'空压机房电表', N'电表', N'DTSF', '2021-08-08', N'正常使用', 1, NULL, NULL),
(N'西区汇流箱02', N'汇流箱', N'PV-16', '2023-02-01', N'正常使用', 3, NULL, NULL),
(N'生活区水表', N'水表', N'DN50', '2019-04-01', N'正常使用', 2, NULL, NULL),
(N'4#干式变压器', N'变压器', N'SCB10', '2022-09-09', N'正常使用', 5, '2025-09-09', N'赵六'),
(N'环境监测仪', N'其他', N'ENV-200', '2024-01-01', N'正常使用', 1, NULL, NULL),
(N'锅炉房气表', N'气表', N'G100', '2018-05-05', N'正常使用', 2, NULL, NULL),
(N'5#变压器', N'变压器', N'S11-630', '2021-01-01', N'正常使用', 3, NULL, NULL),
(N'6#变压器', N'变压器', N'S11-630', '2021-01-01', N'正常使用', 3, NULL, NULL),
(N'测试电表A', N'电表', N'TEST-01', '2025-01-01', N'正常使用', 1, NULL, NULL),
(N'测试电表B', N'电表', N'TEST-02', '2025-01-01', N'正常使用', 1, NULL, NULL);
-- 20条截止
GO

-- ============================================================
-- 4. Dist_Room (配电房) - 20条 [修正版]
-- 修正点：子查询增加 TOP 1，防止因 Base_Factory 有重复数据导致报错
-- ============================================================
PRINT '正在生成 Dist_Room 数据...';

-- 重新获取变量，同样加 TOP 1 确保安全
DECLARE @F1 BIGINT = (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name = N'总厂区');
DECLARE @F2 BIGINT = (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name = N'一分厂-模具车间');
-- 重新获取管理员ID（防止变量作用域丢失）
DECLARE @MgrID_Room BIGINT = (SELECT TOP 1 User_ID FROM Sys_User WHERE Login_Account = 'admin');

INSERT INTO Dist_Room (Room_Name, Location, Voltage_Level, Manager_User_ID, Factory_ID)
VALUES
(N'总配电房', N'总厂区东南角', N'35KV', @MgrID_Room, @F1),
(N'一分厂配电室', N'一分厂A座1F', N'0.4KV', @MgrID_Room, @F2),
-- 下面这些行就是报错源头，已全部加上 TOP 1
(N'二分厂配电室', N'二分厂C座1F', N'0.4KV', NULL, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'%二分厂%冲压%')),
(N'三分厂配电室', N'三分厂E座', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'%三分厂%注塑%')),
(N'研发楼配电间', N'科技园1F', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'研发%')),
(N'生活区配电室', N'宿舍楼下', N'0.4KV', NULL, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'员工宿舍%')),
(N'仓储配电箱', N'物流园入口', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'仓储%')),
(N'污水站动力柜', N'污水站旁', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'污水%')),
(N'光伏并网柜', N'屋顶接入点', N'0.4KV', NULL, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'光伏%')),
(N'35KV变电站', N'厂区北门', N'35KV', @MgrID_Room, @F1),
(N'备用配电房', N'预留区', N'0.4KV', NULL, NULL), 
(N'四分厂配电室A', N'南区G座', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'%四分厂%精加工%')),
(N'四分厂配电室B', N'南区H座', N'0.4KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'%四分厂%热处理%')),
(N'五分厂配电中心', N'高新园', N'35KV', @MgrID_Room, (SELECT TOP 1 Factory_ID FROM Base_Factory WHERE Factory_Name LIKE N'五分厂%')),
(N'测试配电室1', N'临时区', N'0.4KV', NULL, NULL),
(N'测试配电室2', N'临时区', N'0.4KV', NULL, NULL),
(N'行政楼配电间', N'办公楼B1', N'0.4KV', @MgrID_Room, @F1), 
(N'食堂动力柜', N'食堂后厨', N'0.4KV', NULL, @F1),     
(N'废料站配电箱', N'回收站', N'0.4KV', @MgrID_Room, @F2),    
(N'充电桩配电柜', N'地库', N'0.4KV', NULL, @F1);        
GO

-- ============================================================
-- 5. Dist_Transformer (变压器台账) - 20条
-- 修改：新增 Device_Status 字段，默认设为 '正常'
-- ============================================================
PRINT '正在生成 Dist_Transformer 数据...';
DECLARE @R1 BIGINT = (SELECT MIN(Room_ID) FROM Dist_Room);
DECLARE @L1 BIGINT = (SELECT TOP 1 Ledger_ID FROM Device_Ledger WHERE Device_Type = '变压器' ORDER BY Ledger_ID);

INSERT INTO Dist_Transformer (Transformer_Name, Room_ID, Ledger_ID, Device_Status)
VALUES
(N'1#主变', @R1, @L1, N'正常'),
(N'2#主变', @R1, (SELECT TOP 1 Ledger_ID FROM Device_Ledger WHERE Device_Name = N'2#备用变压器'), N'正常'),
(N'一分厂变压器', @R1+1, (SELECT TOP 1 Ledger_ID FROM Device_Ledger WHERE Device_Name = N'5#变压器'), N'正常'),
(N'二分厂变压器', @R1+2, (SELECT TOP 1 Ledger_ID FROM Device_Ledger WHERE Device_Name = N'6#变压器'), N'正常'),
(N'三分厂变压器', @R1+3, NULL, N'正常'), 
(N'研发楼变压器', @R1+4, (SELECT TOP 1 Ledger_ID FROM Device_Ledger WHERE Device_Name = N'4#干式变压器'), N'正常'),
(N'生活区变压器', @R1+5, NULL, N'正常'),
(N'仓储变压器', @R1+6, NULL, N'正常'),
(N'污水站变压器', @R1+7, NULL, N'正常'),
(N'光伏升压变', @R1+8, NULL, N'正常'),
(N'35KV总变A', @R1+9, NULL, N'正常'),
(N'35KV总变B', @R1+9, NULL, N'正常'),
(N'四分厂变压器1', @R1+11, NULL, N'正常'),
(N'四分厂变压器2', @R1+12, NULL, N'正常'),
(N'五分厂主变', @R1+13, NULL, N'正常'),
(N'测试变压器1', @R1+14, NULL, N'正常'),
(N'测试变压器2', @R1+14, NULL, N'正常'),
(N'行政楼变压器', @R1+16, NULL, N'正常'),
(N'食堂变压器', @R1+17, NULL, N'正常'),
(N'动力变压器', @R1, NULL, N'正常');
-- 20条截止
GO

-- ============================================================
-- 6. Dist_Circuit (回路台账) - 20条
-- 修改：新增 Device_Status 字段，默认设为 '正常'
-- ============================================================
PRINT '正在生成 Dist_Circuit 数据...';
DECLARE @R_Start BIGINT = (SELECT MIN(Room_ID) FROM Dist_Room);

INSERT INTO Dist_Circuit (Circuit_Name, Room_ID, Ledger_ID, Device_Status)
VALUES
(N'总进线回路A', @R_Start, NULL, N'正常'),
(N'总进线回路B', @R_Start, NULL, N'正常'),
(N'一分厂照明回路', @R_Start+1, NULL, N'正常'),
(N'一分厂动力回路', @R_Start+1, NULL, N'正常'),
(N'二分厂涂装线回路', @R_Start+2, NULL, N'正常'),
(N'二分厂冲压机回路', @R_Start+2, NULL, N'正常'),
(N'注塑机专线1', @R_Start+3, NULL, N'正常'),
(N'注塑机专线2', @R_Start+3, NULL, N'正常'),
(N'研发服务器回路', @R_Start+4, NULL, N'正常'),
(N'实验室插座回路', @R_Start+4, NULL, N'正常'),
(N'宿舍楼照明', @R_Start+5, NULL, N'正常'),
(N'宿舍楼空调', @R_Start+5, NULL, N'正常'),
(N'仓库货梯回路', @R_Start+6, NULL, N'正常'),
(N'污水泵回路', @R_Start+7, NULL, N'正常'),
(N'光伏并网回路', @R_Start+8, NULL, N'正常'),
(N'35KV出线1', @R_Start+9, NULL, N'正常'),
(N'35KV出线2', @R_Start+9, NULL, N'正常'),
(N'精加工数控机床', @R_Start+11, NULL, N'正常'),
(N'热处理炉回路', @R_Start+12, NULL, N'正常'),
(N'电子产线UPS', @R_Start+13, NULL, N'正常');
-- 20条截止
GO

--PRINT '正在禁用触发器以进行数据初始化...';
-- 这里的触发器名如果存在请确保正确，如果没有创建过可以注释掉
--DISABLE TRIGGER TR_Transformer_Analyze ON Data_Transformer;
--DISABLE TRIGGER TR_Circuit_Analyze ON Data_Circuit;
--GO

-- ===========================================================
-- 7. Data_Transformer (变压器监测数据) - 20条
-- 修改：删除了最后一列 Device_Status
-- ============================================================
DECLARE @T1 BIGINT = (SELECT TOP 1 Transformer_ID FROM Dist_Transformer ORDER BY Transformer_ID);
DECLARE @T2 BIGINT = (SELECT TOP 1 Transformer_ID FROM Dist_Transformer ORDER BY Transformer_ID DESC);
DECLARE @FacID BIGINT = (SELECT TOP 1 Factory_ID FROM Base_Factory);

INSERT INTO Data_Transformer (Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, Load_Rate, Factory_ID)
VALUES
-- 正常数据 (1-10)
(@T1, '2025-01-01 08:00:00', 65.5, 60.2, 45.5, @FacID),
(@T1, '2025-01-01 08:15:00', 66.0, 61.0, 46.0, @FacID),
(@T1, '2025-01-01 08:30:00', 68.2, 62.5, 50.1, @FacID),
(@T2, '2025-01-01 09:00:00', 55.0, 50.0, 30.0, @FacID),
(@T2, '2025-01-01 09:15:00', 56.5, 51.2, 32.5, @FacID),
(@T1, '2025-01-01 09:00:00', 70.1, 65.4, 60.0, @FacID),
(@T1, '2025-01-01 09:15:00', 72.3, 67.0, 62.5, @FacID),
(@T2, '2025-01-01 10:00:00', 58.0, 53.0, 35.0, @FacID),
(@T1, '2025-01-01 10:00:00', 75.0, 70.0, 70.0, @FacID),
(@T1, '2025-01-01 10:15:00', 76.5, 71.5, 72.0, @FacID),
-- 异常数据 (11-15) - 即使数据异常，这里只负责存数据，状态由触发器或Dist表维护
(@T1, '2025-01-01 12:00:00', 105.5, 98.0, 95.0, @FacID), 
(@T1, '2025-01-01 12:15:00', 110.0, 102.0, 98.0, @FacID),
(@T1, '2025-01-01 12:30:00', 125.0, 115.0, 105.0, @FacID),
(@T2, '2025-01-01 12:00:00', 101.0, 95.0, 88.0, @FacID),
(@T2, '2025-01-01 12:15:00', 102.5, 96.0, 89.0, @FacID),
-- 缺值/边界数据 (16-20)
(@T1, '2025-01-01 14:00:00', NULL, 60.0, 45.0, @FacID),
(@T1, '2025-01-01 14:15:00', 65.0, NULL, 45.0, @FacID),
(@T2, '2025-01-01 14:00:00', 55.0, 50.0, NULL, @FacID),
(@T2, '2025-01-01 14:15:00', NULL, NULL, NULL, @FacID),
(@T1, '2025-01-01 14:30:00', 60.0, 55.0, 40.0, NULL);
-- 20条截止
GO

-- ============================================================
-- 8. Data_Circuit (回路监测数据) - 20条
-- 修改：删除了最后一列 Device_Status
-- ============================================================
PRINT '正在生成 Data_Circuit 数据...';
DECLARE @C1 BIGINT = (SELECT TOP 1 Circuit_ID FROM Dist_Circuit ORDER BY Circuit_ID);
DECLARE @C2 BIGINT = (SELECT TOP 1 Circuit_ID FROM Dist_Circuit ORDER BY Circuit_ID DESC);
DECLARE @FacID2 BIGINT = (SELECT TOP 1 Factory_ID FROM Base_Factory);

INSERT INTO Data_Circuit (Circuit_ID, Collect_Time, Voltage, Current_Val, Active_Power, Reactive_Power, Power_Factor, Switch_Status, Factory_ID)
VALUES
-- 正常数据 (1-10)
(@C1, '2025-01-01 08:00:00', 35.100, 100.000, 3000.000, 500.000, 0.980, N'合闸', @FacID2),
(@C1, '2025-01-01 08:15:00', 34.900, 102.000, 3050.000, 510.000, 0.980, N'合闸', @FacID2),
(@C1, '2025-01-01 08:30:00', 35.200, 105.000, 3100.000, 520.000, 0.975, N'合闸', @FacID2),
(@C1, '2025-01-01 08:45:00', 35.050, 98.000, 2900.000, 480.000, 0.985, N'合闸', @FacID2),
(@C1, '2025-01-01 09:00:00', 35.000, 110.000, 3300.000, 600.000, 0.960, N'合闸', @FacID2),
(@C2, '2025-01-01 08:00:00', 0.380, 50.000, 15.000, 2.000, 0.950, N'合闸', @FacID2),
(@C2, '2025-01-01 08:15:00', 0.385, 52.000, 16.000, 2.100, 0.950, N'合闸', @FacID2),
(@C2, '2025-01-01 08:30:00', 0.378, 55.000, 17.000, 2.500, 0.940, N'合闸', @FacID2),
(@C2, '2025-01-01 08:45:00', 0.382, 48.000, 14.000, 1.800, 0.960, N'合闸', @FacID2),
(@C2, '2025-01-01 09:00:00', 0.390, 60.000, 20.000, 5.000, 0.900, N'合闸', @FacID2),
-- 异常数据：电压越限 (11-15)
(@C1, '2025-01-01 10:00:00', 38.500, 100.000, 3200.000, 600.000, 0.950, N'合闸', @FacID2),
(@C1, '2025-01-01 10:15:00', 31.000, 100.000, 2800.000, 400.000, 0.950, N'合闸', @FacID2),
(@C2, '2025-01-01 10:00:00', 0.450, 50.000, 18.000, 3.000, 0.950, N'合闸', @FacID2),
(@C2, '2025-01-01 10:15:00', 0.300, 50.000, 12.000, 2.000, 0.950, N'合闸', @FacID2),
(@C1, '2025-01-01 10:30:00', 40.000, 0.000, 0.000, 0.000, 0.000, N'合闸', @FacID2),
-- 异常：跳闸/分闸 (16-19)
(@C1, '2025-01-01 11:00:00', 0.000, 0.000, 0.000, 0.000, 0.000, N'分闸', @FacID2),
(@C1, '2025-01-01 11:15:00', 35.000, 0.000, 0.000, 0.000, 0.000, N'分闸', @FacID2),
(@C2, '2025-01-01 11:00:00', 0.000, 0.000, 0.000, 0.000, 0.000, N'分闸', @FacID2),
(@C2, '2025-01-01 11:15:00', 0.380, 0.000, 0.000, 0.000, 0.000, N'分闸', @FacID2),
-- 缺值数据 (20)
(@C1, '2025-01-01 12:00:00', NULL, 100.000, 3000.000, NULL, 0.950, N'合闸', @FacID2);
-- 20条截止
GO

--PRINT '数据初始化完成，正在重新启用触发器...';
--ENABLE TRIGGER TR_Transformer_Analyze ON Data_Transformer;
--ENABLE TRIGGER TR_Circuit_Analyze ON Data_Circuit;
--GO

PRINT '所有测试数据生成完成。';
GO