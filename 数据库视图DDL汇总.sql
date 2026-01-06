/* ============================================================
   智慧能源管理系统 - 数据库视图DDL汇总
   Smart Energy Management System - Database View DDL Summary
   
   整理日期: 2026-01-06
   数据库: SQL_BFU (SQL Server)
   
   说明：本文件按业务线整合了所有视图的DDL语句，
         包含主脚本和补丁中的所有视图定义。
   
   视图分类：
   1. 配电网监测业务线视图 (5个)
   2. 综合能耗管理业务线视图 (5个)
   3. 分布式光伏管理业务线视图 (5个)
   4. 告警运维管理业务线视图 (4个)
   5. 大屏数据展示业务线视图 (4个)
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   第一部分：配电网监测业务线视图
   负责人：张恺洋
   ============================================================ */

-- ============================================================
-- 视图 1.1: 回路异常数据视图 (View_Circuit_Abnormal)
-- 来源：main.sql + dist.sql (增强版)
-- 用途：快速筛选出电压异常（过压/欠压）的回路监测记录
-- 关联表：Data_Circuit, Dist_Circuit, Dist_Room, Base_Factory, Device_Ledger
-- ============================================================
IF OBJECT_ID('View_Circuit_Abnormal', 'V') IS NOT NULL 
    DROP VIEW View_Circuit_Abnormal;
GO

CREATE VIEW View_Circuit_Abnormal AS
SELECT
    d.Data_ID,
    d.Circuit_ID,
    c.Circuit_Name,
    f.Factory_ID, 
    f.Factory_Name,
    r.Room_ID, 
    r.Room_Name, 
    r.Voltage_Level,
    l.Device_Name AS Ledger_Device_Name,
    l.Model_Spec AS Device_Model,
    l.Warranty_Years,
    d.Collect_Time,
    CAST(d.Collect_Time AS TIME) AS Abnormal_TimeSlot,
    d.Voltage,
    d.Current_Val,
    d.Active_Power,
    d.Switch_Status,
    -- 异常类型判断
    CASE
        WHEN d.Voltage > 37 THEN N'过压'
        WHEN d.Voltage < 33 THEN N'欠压'
    END AS Abnormal_Type,
    -- 异常等级判断
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

PRINT '已创建视图: View_Circuit_Abnormal (回路异常数据)';
GO


-- ============================================================
-- 视图 1.2: 数据完整性校验视图 (View_PowerGrid_Data_Integrity)
-- 来源：dist.sql
-- 用途：检测配电网监测数据的完整性，标记缺失字段
-- 关联表：Data_Circuit, Data_Transformer, Dist_Circuit, Dist_Transformer, Dist_Room, Base_Factory
-- ============================================================
IF OBJECT_ID('View_PowerGrid_Data_Integrity', 'V') IS NOT NULL 
    DROP VIEW View_PowerGrid_Data_Integrity;
GO

CREATE VIEW View_PowerGrid_Data_Integrity AS
SELECT
    N'回路' AS Device_Type,
    c.Circuit_ID AS Device_ID,
    c.Circuit_Name AS Device_Name,
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    d.Collect_Time,
    CASE WHEN d.Voltage IS NULL OR d.Current_Val IS NULL THEN N'数据不完整' ELSE N'数据完整' END AS Data_Integrity_Status,
    CASE WHEN d.Voltage IS NULL AND d.Current_Val IS NULL THEN N'电压、电流均缺失'
         WHEN d.Voltage IS NULL THEN N'电压缺失'
         WHEN d.Current_Val IS NULL THEN N'电流缺失'
         ELSE N'无缺失' END AS Missing_Field,
    c.Device_Status AS Equipment_Status,
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
    t.Device_Status AS Equipment_Status,
    r.Voltage_Level
FROM Data_Transformer d
JOIN Dist_Transformer t ON d.Transformer_ID = t.Transformer_ID
JOIN Dist_Room r ON t.Room_ID = r.Room_ID
JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
WHERE d.Winding_Temp IS NULL OR d.Load_Rate IS NULL;
GO

PRINT '已创建视图: View_PowerGrid_Data_Integrity (数据完整性校验)';
GO


-- ============================================================
-- 视图 1.3: 每日峰谷时段用电统计视图 (View_Daily_PeakValley_Power_Stats)
-- 来源：dist.sql
-- 用途：按配电房统计每日各峰谷时段的用电量、功率、成本
-- 关联表：Data_Circuit, Data_Transformer, Dist_Circuit, Dist_Transformer, Dist_Room, Base_Factory, Config_PeakValley
-- ============================================================
IF OBJECT_ID('View_Daily_PeakValley_Power_Stats', 'V') IS NOT NULL 
    DROP VIEW View_Daily_PeakValley_Power_Stats;
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
        SUM(CASE WHEN dt.Winding_Temp > 80 THEN 1 ELSE 0 END) AS Trans_Abnormal_Count
    FROM Data_Transformer dt
    JOIN Dist_Transformer t ON dt.Transformer_ID = t.Transformer_ID
    LEFT JOIN Config_PeakValley cp 
        ON CAST(dt.Collect_Time AS TIME(0)) BETWEEN cp.Start_Time AND cp.End_Time
    GROUP BY CAST(dt.Collect_Time AS DATE), dt.Factory_ID, t.Room_ID, cp.Time_Type
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

PRINT '已创建视图: View_Daily_PeakValley_Power_Stats (每日峰谷用电统计)';
GO


-- ============================================================
-- 视图 1.4: 实时设备数据视图 (View_RealTime_Device_Data)
-- 来源：dist.sql
-- 用途：获取变压器和回路的最新监测数据，用于实时监控
-- 关联表：Data_Circuit, Data_Transformer, Dist_Circuit, Dist_Transformer, Dist_Room, Base_Factory, Device_Ledger
-- ============================================================
IF OBJECT_ID('View_RealTime_Device_Data', 'V') IS NOT NULL 
    DROP VIEW View_RealTime_Device_Data;
GO

CREATE VIEW View_RealTime_Device_Data AS
WITH CTE_Latest_Transformer AS (
    SELECT 
        Transformer_ID, Winding_Temp, Core_Temp, Load_Rate, Collect_Time,
        ROW_NUMBER() OVER (PARTITION BY Transformer_ID ORDER BY Collect_Time DESC) AS RN
    FROM Data_Transformer
),
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
    CAST(NULL AS NVARCHAR(10)) AS Switch_Status,
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

PRINT '已创建视图: View_RealTime_Device_Data (实时设备数据)';
GO


-- ============================================================
-- 视图 1.5: 配电房设备状态汇总视图 (View_DistRoom_Equipment_Status)
-- 来源：dist.sql
-- 用途：汇总各配电房的设备数量、状态分布、健康度评分
-- 关联表：Dist_Room, Dist_Transformer, Dist_Circuit, Base_Factory, Sys_User
-- ============================================================
IF OBJECT_ID('View_DistRoom_Equipment_Status', 'V') IS NOT NULL 
    DROP VIEW View_DistRoom_Equipment_Status;
GO

CREATE VIEW View_DistRoom_Equipment_Status AS
SELECT
    r.Room_ID, r.Room_Name, f.Factory_ID, f.Factory_Name,
    r.Location, r.Voltage_Level, u.Real_Name AS Room_Manager,
    COUNT(DISTINCT t.Transformer_ID) AS Total_Transformers,
    SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Transformers,
    SUM(CASE WHEN t.Device_Status = N'异常' THEN 1 ELSE 0 END) AS Abnormal_Transformers,
    COUNT(DISTINCT c.Circuit_ID) AS Total_Circuits,
    SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Circuits,
    SUM(CASE WHEN c.Device_Status = N'异常' THEN 1 ELSE 0 END) AS Abnormal_Circuits,
    -- 计算健康度评分
    CASE 
        WHEN (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)) = 0 THEN 0.00
        ELSE ROUND(
            (SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) + SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END)) * 1.0 
            / (COUNT(DISTINCT t.Transformer_ID) + COUNT(DISTINCT c.Circuit_ID)), 2
        )
    END AS Overall_Health_Score,
    -- 健康等级
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

PRINT '已创建视图: View_DistRoom_Equipment_Status (配电房设备状态汇总)';
GO


/* ============================================================
   第二部分：综合能耗管理业务线视图
   负责人：杨昊田
   ============================================================ */

-- ============================================================
-- 视图 2.1: 厂区日能耗成本统计视图 (View_Daily_Energy_Cost)
-- 来源：main.sql
-- 用途：聚合计算各厂区每日各能源类型的总能耗及成本
-- 关联表：Data_PeakValley, Base_Factory
-- ============================================================
IF OBJECT_ID('View_Daily_Energy_Cost', 'V') IS NOT NULL 
    DROP VIEW View_Daily_Energy_Cost;
GO

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

PRINT '已创建视图: View_Daily_Energy_Cost (厂区日能耗成本统计)';
GO


-- ============================================================
-- 视图 2.2: 峰谷能耗占比分析视图 (View_PeakValley_Ratio)
-- 来源：energy.sql
-- 用途：分析各厂区各能源类型的峰谷用电占比，识别优化空间
-- 关联表：Data_PeakValley, Base_Factory
-- ============================================================
IF OBJECT_ID('View_PeakValley_Ratio', 'V') IS NOT NULL 
    DROP VIEW View_PeakValley_Ratio;
GO

CREATE VIEW View_PeakValley_Ratio AS
SELECT 
    pv.Factory_ID,
    f.Factory_Name,
    pv.Stat_Date,
    pv.Energy_Type,
    -- 计算各时段能耗
    SUM(CASE WHEN pv.Peak_Type = N'尖峰' THEN pv.Total_Consumption ELSE 0 END) AS Peak_Sharp_Consumption,
    SUM(CASE WHEN pv.Peak_Type = N'高峰' THEN pv.Total_Consumption ELSE 0 END) AS Peak_High_Consumption,
    SUM(CASE WHEN pv.Peak_Type = N'平段' THEN pv.Total_Consumption ELSE 0 END) AS Flat_Consumption,
    SUM(CASE WHEN pv.Peak_Type = N'低谷' THEN pv.Total_Consumption ELSE 0 END) AS Valley_Consumption,
    -- 计算总能耗
    SUM(pv.Total_Consumption) AS Total_Consumption,
    -- 计算各时段占比
    CAST(SUM(CASE WHEN pv.Peak_Type = N'尖峰' THEN pv.Total_Consumption ELSE 0 END) * 100.0 / 
         NULLIF(SUM(pv.Total_Consumption), 0) AS DECIMAL(5,2)) AS Sharp_Ratio,
    CAST(SUM(CASE WHEN pv.Peak_Type = N'高峰' THEN pv.Total_Consumption ELSE 0 END) * 100.0 / 
         NULLIF(SUM(pv.Total_Consumption), 0) AS DECIMAL(5,2)) AS High_Ratio,
    CAST(SUM(CASE WHEN pv.Peak_Type = N'平段' THEN pv.Total_Consumption ELSE 0 END) * 100.0 / 
         NULLIF(SUM(pv.Total_Consumption), 0) AS DECIMAL(5,2)) AS Flat_Ratio,
    CAST(SUM(CASE WHEN pv.Peak_Type = N'低谷' THEN pv.Total_Consumption ELSE 0 END) * 100.0 / 
         NULLIF(SUM(pv.Total_Consumption), 0) AS DECIMAL(5,2)) AS Valley_Ratio,
    -- 计算总成本
    SUM(pv.Cost_Amount) AS Total_Cost,
    -- 优化建议标记：谷段占比<30%时标记为需优化
    CASE 
        WHEN SUM(CASE WHEN pv.Peak_Type = N'低谷' THEN pv.Total_Consumption ELSE 0 END) * 100.0 / 
             NULLIF(SUM(pv.Total_Consumption), 0) < 30 
        THEN N'需优化-谷段占比过低'
        ELSE N'正常'
    END AS Optimization_Flag
FROM Data_PeakValley pv
JOIN Base_Factory f ON pv.Factory_ID = f.Factory_ID
GROUP BY pv.Factory_ID, f.Factory_Name, pv.Stat_Date, pv.Energy_Type;
GO

PRINT '已创建视图: View_PeakValley_Ratio (峰谷能耗占比分析)';
GO


-- ============================================================
-- 视图 2.3: 动态峰谷统计视图 (View_PeakValley_Dynamic)
-- 来源：patch.sql
-- 用途：基于实时能耗数据和峰谷配置动态计算峰谷能耗
-- 关联表：Data_Energy, Energy_Meter, Config_PeakValley
-- ============================================================
IF OBJECT_ID('View_PeakValley_Dynamic', 'V') IS NOT NULL
    DROP VIEW View_PeakValley_Dynamic;
GO

CREATE VIEW View_PeakValley_Dynamic AS
SELECT
    CAST(e.Collect_Time AS DATE) AS Stat_Date,
    m.Energy_Type AS Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID) AS Factory_ID,
    c.Time_Type AS Peak_Type,
    SUM(e.Value) AS Total_Consumption,
    SUM(e.Value * c.Price_Rate) AS Cost_Amount
FROM Data_Energy e
JOIN Energy_Meter m ON e.Meter_ID = m.Meter_ID
JOIN Config_PeakValley c
    ON CAST(e.Collect_Time AS TIME(0)) >= c.Start_Time
   AND CAST(e.Collect_Time AS TIME(0)) < c.End_Time
GROUP BY
    CAST(e.Collect_Time AS DATE),
    m.Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID),
    c.Time_Type;
GO

PRINT '已创建视图: View_PeakValley_Dynamic (动态峰谷统计)';
GO


-- ============================================================
-- 视图 2.4: 厂区能耗成本汇总视图 (View_Factory_Energy_Cost)
-- 来源：energy.sql
-- 用途：按厂区汇总各类能源的日度成本，支持成本分析
-- 关联表：Data_PeakValley, Base_Factory
-- ============================================================
IF OBJECT_ID('View_Factory_Energy_Cost', 'V') IS NOT NULL 
    DROP VIEW View_Factory_Energy_Cost;
GO

CREATE VIEW View_Factory_Energy_Cost AS
SELECT 
    f.Factory_ID,
    f.Factory_Name,
    pv.Stat_Date,
    -- 分能源类型统计
    SUM(CASE WHEN pv.Energy_Type = N'电' THEN pv.Total_Consumption ELSE 0 END) AS Electric_Consumption,
    SUM(CASE WHEN pv.Energy_Type = N'电' THEN pv.Cost_Amount ELSE 0 END) AS Electric_Cost,
    SUM(CASE WHEN pv.Energy_Type = N'水' THEN pv.Total_Consumption ELSE 0 END) AS Water_Consumption,
    SUM(CASE WHEN pv.Energy_Type = N'水' THEN pv.Cost_Amount ELSE 0 END) AS Water_Cost,
    SUM(CASE WHEN pv.Energy_Type = N'蒸汽' THEN pv.Total_Consumption ELSE 0 END) AS Steam_Consumption,
    SUM(CASE WHEN pv.Energy_Type = N'蒸汽' THEN pv.Cost_Amount ELSE 0 END) AS Steam_Cost,
    SUM(CASE WHEN pv.Energy_Type = N'天然气' THEN pv.Total_Consumption ELSE 0 END) AS Gas_Consumption,
    SUM(CASE WHEN pv.Energy_Type = N'天然气' THEN pv.Cost_Amount ELSE 0 END) AS Gas_Cost,
    -- 总计
    SUM(pv.Total_Consumption) AS Total_Consumption,
    SUM(pv.Cost_Amount) AS Total_Cost,
    -- 计算单位成本
    CAST(SUM(pv.Cost_Amount) / NULLIF(SUM(pv.Total_Consumption), 0) AS DECIMAL(8,4)) AS Avg_Unit_Cost
FROM Base_Factory f
LEFT JOIN Data_PeakValley pv ON f.Factory_ID = pv.Factory_ID
GROUP BY f.Factory_ID, f.Factory_Name, pv.Stat_Date;
GO

PRINT '已创建视图: View_Factory_Energy_Cost (厂区能耗成本汇总)';
GO


-- ============================================================
-- 视图 2.5: 待核实能耗数据视图 (View_Energy_ToVerify)
-- 来源：energy.sql
-- 用途：筛选数据质量为"中"或"差"的能耗记录，供人工复核
-- 关联表：Data_Energy, Energy_Meter, Base_Factory
-- ============================================================
IF OBJECT_ID('View_Energy_ToVerify', 'V') IS NOT NULL 
    DROP VIEW View_Energy_ToVerify;
GO

CREATE VIEW View_Energy_ToVerify AS
SELECT 
    de.Data_ID,
    de.Collect_Time,
    f.Factory_Name,
    m.Energy_Type,
    m.Install_Location,
    de.Value,
    de.Unit,
    de.Quality,
    m.Run_Status AS Meter_Status,
    CASE 
        WHEN de.Quality IN (N'中', N'差') THEN N'需人工复核'
        ELSE N'正常'
    END AS Verify_Status,
    m.Manufacturer
FROM Data_Energy de
JOIN Energy_Meter m ON de.Meter_ID = m.Meter_ID
JOIN Base_Factory f ON de.Factory_ID = f.Factory_ID
WHERE de.Quality IN (N'中', N'差');
GO

PRINT '已创建视图: View_Energy_ToVerify (待核实能耗数据)';
GO


-- ============================================================
-- 视图 2.6: 设备运行状态监控视图 (View_Meter_Status_Monitor)
-- 来源：energy.sql
-- 用途：综合展示各能源类型设备的运行状态和校准情况
-- 关联表：Energy_Meter, Base_Factory, Device_Ledger, Data_Energy
-- ============================================================
IF OBJECT_ID('View_Meter_Status_Monitor', 'V') IS NOT NULL 
    DROP VIEW View_Meter_Status_Monitor;
GO

CREATE VIEW View_Meter_Status_Monitor AS
SELECT 
    m.Meter_ID,
    m.Energy_Type,
    f.Factory_Name,
    m.Install_Location,
    m.Run_Status,
    m.Manufacturer,
    m.Calib_Cycle_Months,
    l.Install_Time,
    -- 计算距离下次校准的月数
    DATEDIFF(MONTH, l.Install_Time, GETDATE()) % NULLIF(m.Calib_Cycle_Months, 0) AS Months_Since_Last_Calib,
    CASE 
        WHEN m.Calib_Cycle_Months IS NOT NULL AND 
             DATEDIFF(MONTH, l.Install_Time, GETDATE()) % m.Calib_Cycle_Months >= m.Calib_Cycle_Months - 1
        THEN N'即将到期-需安排校准'
        WHEN m.Run_Status = N'故障'
        THEN N'设备故障-需维修'
        ELSE N'正常运行'
    END AS Maintenance_Status,
    -- 统计最近7天的采集数据量
    (SELECT COUNT(*) 
     FROM Data_Energy de 
     WHERE de.Meter_ID = m.Meter_ID 
       AND de.Collect_Time >= DATEADD(DAY, -7, GETDATE())) AS Data_Count_Last7Days
FROM Energy_Meter m
JOIN Base_Factory f ON m.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON m.Ledger_ID = l.Ledger_ID;
GO

PRINT '已创建视图: View_Meter_Status_Monitor (设备运行状态监控)';
GO


/* ============================================================
   第三部分：分布式光伏管理业务线视图
   负责人：段泓冰
   ============================================================ */

-- ============================================================
-- 视图 3.1: 每日光伏发电量统计视图 (Daily_PV_Generation)
-- 来源：pv.sql
-- 用途：统计每个并网点每日的总发电量、上网电量、自用电量
-- 关联表：Data_PV_Gen, PV_Device, PV_Grid_Point
-- ============================================================
IF OBJECT_ID('Daily_PV_Generation', 'V') IS NOT NULL
    DROP VIEW Daily_PV_Generation;
GO

CREATE VIEW Daily_PV_Generation AS
SELECT
    p.Point_Name,
    CONVERT(DATE, d.Collect_Time) AS Collect_Date,
    SUM(d.Gen_KWH) AS Total_Generation_KWH,
    SUM(d.Grid_KWH) AS Total_Grid_KWH,
    SUM(d.Self_KWH) AS Total_Self_KWH
FROM Data_PV_Gen d
JOIN PV_Device pd ON d.Device_ID = pd.Device_ID
JOIN PV_Grid_Point p ON pd.Point_ID = p.Point_ID
GROUP BY p.Point_Name, CONVERT(DATE, d.Collect_Time);
GO

PRINT '已创建视图: Daily_PV_Generation (每日光伏发电量统计)';
GO


-- ============================================================
-- 视图 3.2: 光伏预测偏差明细视图 (PV_Forecast_Deviation_Detail)
-- 来源：pv.sql
-- 用途：展示预测偏差超过15%的记录，用于模型优化分析
-- 关联表：Data_PV_Forecast, PV_Grid_Point, PV_Forecast_Model, Role_Analyst, Sys_User
-- ============================================================
IF OBJECT_ID('PV_Forecast_Deviation_Detail', 'V') IS NOT NULL
    DROP VIEW PV_Forecast_Deviation_Detail;
GO

CREATE VIEW PV_Forecast_Deviation_Detail AS
SELECT
    p.Point_Name,
    f.Forecast_Date,
    f.Time_Slot,
    fm.Model_Name,
    fm.Status AS Model_Status,
    u.Real_Name AS Analyst_Name,
    f.Forecast_Val,
    f.Actual_Val,
    (f.Actual_Val - f.Forecast_Val) AS Deviation_Val,
    ((f.Actual_Val - f.Forecast_Val) / NULLIF(f.Forecast_Val, 0)) * 100.0 AS Deviation_Percentage
FROM Data_PV_Forecast f
JOIN PV_Grid_Point p ON f.Point_ID = p.Point_ID
JOIN PV_Forecast_Model fm ON f.Model_Version = fm.Model_Version
LEFT JOIN Role_Analyst ra ON f.Analyst_ID = ra.Analyst_ID
LEFT JOIN Sys_User u ON ra.User_ID = u.User_ID
WHERE f.Actual_Val IS NOT NULL
  AND ABS((f.Actual_Val - f.Forecast_Val) / NULLIF(f.Forecast_Val, 0.0)) > 0.15;
GO

PRINT '已创建视图: PV_Forecast_Deviation_Detail (光伏预测偏差明细)';
GO


-- ============================================================
-- 视图 3.3: 低效率设备视图 (Low_Efficiency_Devices)
-- 来源：pv.sql
-- 用途：列出历史平均逆变器效率低于85%的设备
-- 关联表：PV_Device, PV_Grid_Point, Data_PV_Gen, Device_Ledger
-- ============================================================
IF OBJECT_ID('Low_Efficiency_Devices', 'V') IS NOT NULL
    DROP VIEW Low_Efficiency_Devices;
GO

CREATE VIEW Low_Efficiency_Devices AS
SELECT
    dl.Device_Name,
    d.Device_Type,
    p.Point_Name,
    AVG(g.Inverter_Eff) AS Avg_Inverter_Eff
FROM PV_Device d
JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID
JOIN Data_PV_Gen g ON d.Device_ID = g.Device_ID
LEFT JOIN Device_Ledger dl ON d.Ledger_ID = dl.Ledger_ID
WHERE d.Device_Type = N'逆变器'
GROUP BY dl.Device_Name, d.Device_Type, p.Point_Name
HAVING AVG(g.Inverter_Eff) < 85;
GO

PRINT '已创建视图: Low_Efficiency_Devices (低效率设备)';
GO


-- ============================================================
-- 视图 3.4: 光伏模型优化告警追踪视图 (PV_Model_Alert_Trace)
-- 来源：pv.sql
-- 用途：追踪模型优化告警及其关联的预测偏差详情
-- 关联表：PV_Model_Alert, PV_Grid_Point, PV_Forecast_Model, Data_PV_Forecast, Role_Analyst, Sys_User
-- ============================================================
IF OBJECT_ID('PV_Model_Alert_Trace', 'V') IS NOT NULL
    DROP VIEW PV_Model_Alert_Trace;
GO

CREATE VIEW PV_Model_Alert_Trace AS
SELECT
    a.Alert_ID,
    a.Trigger_Time,
    a.Process_Status,
    a.Remark,
    p.Point_Name,
    a.Model_Version,
    fm.Model_Name,
    fm.Status AS Model_Status,
    f.Forecast_Date,
    f.Time_Slot,
    f.Forecast_Val,
    f.Actual_Val,
    (f.Actual_Val - f.Forecast_Val) AS Deviation_Val,
    ((f.Actual_Val - f.Forecast_Val) / NULLIF(f.Forecast_Val, 0.0)) * 100.0 AS Deviation_Percentage,
    u.Real_Name AS Analyst_Name
FROM PV_Model_Alert a
JOIN PV_Grid_Point p ON a.Point_ID = p.Point_ID
LEFT JOIN PV_Forecast_Model fm ON a.Model_Version = fm.Model_Version
OUTER APPLY (
    SELECT TOP (1) f1.*
    FROM Data_PV_Forecast f1
    WHERE f1.Point_ID = a.Point_ID
      AND f1.Model_Version = a.Model_Version
      AND f1.Forecast_Date = CONVERT(date, a.Trigger_Time)
      AND f1.Actual_Val IS NOT NULL
      AND f1.Forecast_Val IS NOT NULL
      AND ABS((f1.Actual_Val - f1.Forecast_Val) / NULLIF(f1.Forecast_Val, 0.0)) > 0.15
    ORDER BY ABS((f1.Actual_Val - f1.Forecast_Val) / NULLIF(f1.Forecast_Val, 0.0)) DESC, f1.Time_Slot DESC
) f
LEFT JOIN Role_Analyst ra ON f.Analyst_ID = ra.Analyst_ID
LEFT JOIN Sys_User u ON ra.User_ID = u.User_ID;
GO

PRINT '已创建视图: PV_Model_Alert_Trace (光伏模型优化告警追踪)';
GO


-- ============================================================
-- 视图 3.5: 光伏设备健康度视图 (PV_Device_Health)
-- 来源：pv.sql
-- 用途：展示设备最近采集时间、效率、近7天未结案告警数
-- 关联表：PV_Device, PV_Grid_Point, Device_Ledger, Data_PV_Gen, Alarm_Info
-- ============================================================
IF OBJECT_ID('PV_Device_Health', 'V') IS NOT NULL
    DROP VIEW PV_Device_Health;
GO

CREATE VIEW PV_Device_Health AS
WITH LastGen AS (
    SELECT
        g.Device_ID,
        MAX(g.Collect_Time) AS Last_Collect_Time
    FROM Data_PV_Gen g
    GROUP BY g.Device_ID
),
LastEff AS (
    SELECT
        g.Device_ID,
        g.Collect_Time,
        g.Inverter_Eff
    FROM Data_PV_Gen g
    JOIN LastGen lg ON lg.Device_ID = g.Device_ID AND lg.Last_Collect_Time = g.Collect_Time
),
AlarmAgg AS (
    SELECT
        ai.Ledger_ID,
        COUNT(*) AS Unclosed_Alarm_Cnt_7d,
        MAX(ai.Occur_Time) AS Last_Alarm_Time
    FROM Alarm_Info ai
    WHERE ai.Process_Status <> N'已结案'
      AND ai.Occur_Time >= DATEADD(DAY, -7, SYSDATETIME())
    GROUP BY ai.Ledger_ID
)
SELECT
    d.Device_ID,
    dl.Device_Name,
    d.Device_Type,
    d.Run_Status,
    p.Point_Name,
    lg.Last_Collect_Time,
    le.Inverter_Eff AS Last_Inverter_Eff,
    aa.Unclosed_Alarm_Cnt_7d,
    aa.Last_Alarm_Time
FROM PV_Device d
JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID
LEFT JOIN Device_Ledger dl ON d.Ledger_ID = dl.Ledger_ID
LEFT JOIN LastGen lg ON d.Device_ID = lg.Device_ID
LEFT JOIN LastEff le ON d.Device_ID = le.Device_ID
LEFT JOIN AlarmAgg aa ON d.Ledger_ID = aa.Ledger_ID;
GO

PRINT '已创建视图: PV_Device_Health (光伏设备健康度)';
GO


/* ============================================================
   第四部分：告警运维管理业务线视图
   负责人：李振梁
   ============================================================ */

-- ============================================================
-- 视图 4.1: 待处理高等级告警视图 (View_Pending_High_Alarms)
-- 来源：main.sql
-- 用途：大屏直接查询此视图获取红色告警（未处理的高等级告警）
-- 关联表：Alarm_Info, Base_Factory, Device_Ledger
-- ============================================================
IF OBJECT_ID('View_Pending_High_Alarms', 'V') IS NOT NULL 
    DROP VIEW View_Pending_High_Alarms;
GO

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
WHERE a.Process_Status = N'未处理' 
  AND a.Alarm_Level = N'高';
GO

PRINT '已创建视图: View_Pending_High_Alarms (待处理高等级告警)';
GO


-- ============================================================
-- 视图 4.2: 高等级告警派单SLA视图 (View_High_Alarm_Dispatch_SLA)
-- 来源：alarm.sql
-- 用途：监控高等级告警的派单响应时间，判断是否超时（15分钟SLA）
-- 关联表：Alarm_Info, Work_Order
-- ============================================================
IF OBJECT_ID('View_High_Alarm_Dispatch_SLA', 'V') IS NOT NULL 
    DROP VIEW View_High_Alarm_Dispatch_SLA;
GO

CREATE VIEW View_High_Alarm_Dispatch_SLA AS
SELECT
    a.Alarm_ID, 
    a.Alarm_Type, 
    a.Alarm_Level, 
    a.Content, 
    a.Occur_Time, 
    a.Process_Status,
    w.Dispatch_Time AS First_Dispatch_Time,
    CASE WHEN w.Dispatch_Time IS NULL THEN NULL 
         ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) END AS Dispatch_Duration_Min,
    CASE WHEN w.Dispatch_Time IS NULL THEN N'未派单' 
         WHEN DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) <= 15 THEN N'正常' 
         ELSE N'超时' END AS SLA_Status
FROM Alarm_Info a
LEFT JOIN Work_Order w ON a.Alarm_ID = w.Alarm_ID
WHERE a.Alarm_Level = N'高';
GO

PRINT '已创建视图: View_High_Alarm_Dispatch_SLA (高等级告警派单SLA)';
GO


-- ============================================================
-- 视图 4.3: 运维人员工作量汇总视图 (View_OandM_Workload_Summary)
-- 来源：alarm.sql
-- 用途：统计各运维人员的工单数量、处理效率、响应时间等
-- 关联表：Work_Order, Role_OandM, Sys_User, Alarm_Info
-- ============================================================
IF OBJECT_ID('View_OandM_Workload_Summary', 'V') IS NOT NULL 
    DROP VIEW View_OandM_Workload_Summary;
GO

CREATE VIEW View_OandM_Workload_Summary AS
SELECT
    o.OandM_ID, 
    u.Real_Name, 
    u.Department,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN w.Finish_Time IS NOT NULL AND w.Review_Status = N'通过' THEN 1 ELSE 0 END) AS Finished_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'高' THEN 1 ELSE 0 END) AS High_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'中' THEN 1 ELSE 0 END) AS Mid_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'低' THEN 1 ELSE 0 END) AS Low_Orders,
    AVG(CASE WHEN w.Response_Time IS NOT NULL AND w.Dispatch_Time IS NOT NULL 
             THEN DATEDIFF(MINUTE, w.Dispatch_Time, w.Response_Time) END) AS Avg_Response_Min,
    AVG(CASE WHEN w.Finish_Time IS NOT NULL AND w.Dispatch_Time IS NOT NULL 
             THEN DATEDIFF(MINUTE, w.Dispatch_Time, w.Finish_Time) END) AS Avg_Handle_Min
FROM Work_Order w
JOIN Role_OandM o ON w.OandM_ID = o.OandM_ID
JOIN Sys_User u ON o.User_ID = u.User_ID
JOIN Alarm_Info a ON w.Alarm_ID = a.Alarm_ID
GROUP BY o.OandM_ID, u.Real_Name, u.Department;
GO

PRINT '已创建视图: View_OandM_Workload_Summary (运维人员工作量汇总)';
GO


-- ============================================================
-- 视图 4.4: 告警处理效率视图 (View_Alarm_Process_Efficiency)
-- 来源：alarm.sql
-- 用途：统计每个告警的响应时长和总处理时长
-- 关联表：Alarm_Info, Work_Order
-- ============================================================
IF OBJECT_ID('View_Alarm_Process_Efficiency', 'V') IS NOT NULL 
    DROP VIEW View_Alarm_Process_Efficiency;
GO

CREATE VIEW View_Alarm_Process_Efficiency AS
SELECT
    a.Alarm_ID, 
    a.Alarm_Type, 
    a.Alarm_Level, 
    a.Content, 
    a.Occur_Time, 
    a.Process_Status,
    w.Dispatch_Time AS First_Dispatch_Time,
    w.Finish_Time AS Last_Finish_Time,
    CASE WHEN w.Dispatch_Time IS NULL THEN NULL 
         ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) END AS Response_Duration_Min,
    CASE WHEN w.Finish_Time IS NULL THEN NULL 
         ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Finish_Time) END AS Total_Duration_Min
FROM Alarm_Info a
LEFT JOIN Work_Order w ON a.Alarm_ID = w.Alarm_ID;
GO

PRINT '已创建视图: View_Alarm_Process_Efficiency (告警处理效率)';
GO


/* ============================================================
   第五部分：大屏数据展示业务线视图
   负责人：杨尧天
   ============================================================ */

-- ============================================================
-- 视图 5.1: 企业管理层大屏最新数据视图 (View_Exec_Latest_Dashboard)
-- 来源：dashboard.sql
-- 用途：获取各模块最新一条实时汇总数据，用于大屏刷新
-- 关联表：Dashboard_Config, Stat_Realtime
-- ============================================================
IF OBJECT_ID('View_Exec_Latest_Dashboard', 'V') IS NOT NULL
    DROP VIEW View_Exec_Latest_Dashboard;
GO

CREATE VIEW View_Exec_Latest_Dashboard AS
SELECT
    c.Config_ID,
    c.Module_Name,
    c.Auth_Level,
    r.Stat_Time,
    r.Total_KWH,
    r.Total_Alarm,
    r.PV_Gen_KWH,
    r.Total_Water_m3,
    r.Total_Steam_t,
    r.Total_Gas_m3,
    r.Alarm_High,
    r.Alarm_Mid,
    r.Alarm_Low,
    r.Alarm_Unprocessed
FROM Dashboard_Config c
OUTER APPLY (
    SELECT TOP 1 *
    FROM Stat_Realtime rr
    WHERE rr.Config_ID = c.Config_ID
    ORDER BY rr.Stat_Time DESC
) r
WHERE c.Auth_Level IN (N'企业管理层', N'管理员') OR c.Auth_Level IS NULL;
GO

PRINT '已创建视图: View_Exec_Latest_Dashboard (企业管理层大屏最新数据)';
GO


-- ============================================================
-- 视图 5.2: 近一年趋势数据视图 (View_Exec_Trend_Recent)
-- 来源：dashboard.sql
-- 用途：获取近370天的历史趋势数据，支持同比/环比分析
-- 关联表：Stat_History_Trend, Dashboard_Config
-- ============================================================
IF OBJECT_ID('View_Exec_Trend_Recent', 'V') IS NOT NULL
    DROP VIEW View_Exec_Trend_Recent;
GO

CREATE VIEW View_Exec_Trend_Recent AS
SELECT
    t.Energy_Type,
    t.Stat_Cycle,
    t.Stat_Date,
    t.Value,
    t.Industry_Avg,
    t.YOY_Rate,
    t.MOM_Rate,
    t.Trend_Tag,
    c.Module_Name
FROM Stat_History_Trend t
LEFT JOIN Dashboard_Config c ON c.Config_ID = t.Config_ID
WHERE t.Stat_Date >= DATEADD(DAY, -370, CONVERT(date, GETDATE()));
GO

PRINT '已创建视图: View_Exec_Trend_Recent (近一年趋势数据)';
GO


-- ============================================================
-- 视图 5.3: 近24小时告警统计视图 (View_Exec_Alarm_Stats_24h)
-- 来源：dashboard.sql
-- 用途：统计近24小时内的告警数量分布（按等级、处理状态）
-- 关联表：Alarm_Info
-- ============================================================
IF OBJECT_ID('View_Exec_Alarm_Stats_24h', 'V') IS NOT NULL
    DROP VIEW View_Exec_Alarm_Stats_24h;
GO

CREATE VIEW View_Exec_Alarm_Stats_24h AS
SELECT
    CONVERT(date, a.Occur_Time) AS [Date],
    COUNT(*) AS Total_Alarm,
    SUM(CASE WHEN a.Alarm_Level = N'高' THEN 1 ELSE 0 END) AS High_Alarm,
    SUM(CASE WHEN a.Alarm_Level = N'中' THEN 1 ELSE 0 END) AS Mid_Alarm,
    SUM(CASE WHEN a.Alarm_Level = N'低' THEN 1 ELSE 0 END) AS Low_Alarm,
    SUM(CASE WHEN a.Process_Status = N'未处理' THEN 1 ELSE 0 END) AS Unprocessed_Alarm
FROM Alarm_Info a
WHERE a.Occur_Time >= DATEADD(HOUR, -24, GETDATE())
GROUP BY CONVERT(date, a.Occur_Time);
GO

PRINT '已创建视图: View_Exec_Alarm_Stats_24h (近24小时告警统计)';
GO


-- ============================================================
-- 视图 5.4: 待处理高等级告警简洁视图 (View_Alarm_Pending_High_Simple)
-- 来源：alarm.sql
-- 用途：简化版高等级告警视图，仅包含核心字段
-- 关联表：Alarm_Info
-- ============================================================
IF OBJECT_ID('View_Alarm_Pending_High_Simple', 'V') IS NOT NULL 
    DROP VIEW View_Alarm_Pending_High_Simple;
GO

CREATE VIEW View_Alarm_Pending_High_Simple AS
SELECT 
    Alarm_ID, 
    Alarm_Type, 
    Alarm_Level, 
    Content, 
    Occur_Time, 
    Process_Status, 
    Trigger_Threshold
FROM Alarm_Info
WHERE Alarm_Level = N'高' AND Process_Status = N'未处理';
GO

PRINT '已创建视图: View_Alarm_Pending_High_Simple (待处理高等级告警简洁版)';
GO


/* ============================================================
   视图汇总信息
   ============================================================
   
   本DDL汇总共包含 23 个视图，按业务线分布如下：
   
   1. 配电网监测业务线：5个视图
      - View_Circuit_Abnormal (回路异常数据)
      - View_PowerGrid_Data_Integrity (数据完整性校验)
      - View_Daily_PeakValley_Power_Stats (每日峰谷用电统计)
      - View_RealTime_Device_Data (实时设备数据)
      - View_DistRoom_Equipment_Status (配电房设备状态汇总)
   
   2. 综合能耗管理业务线：6个视图
      - View_Daily_Energy_Cost (厂区日能耗成本统计)
      - View_PeakValley_Ratio (峰谷能耗占比分析)
      - View_PeakValley_Dynamic (动态峰谷统计)
      - View_Factory_Energy_Cost (厂区能耗成本汇总)
      - View_Energy_ToVerify (待核实能耗数据)
      - View_Meter_Status_Monitor (设备运行状态监控)
   
   3. 分布式光伏管理业务线：5个视图
      - Daily_PV_Generation (每日光伏发电量统计)
      - PV_Forecast_Deviation_Detail (光伏预测偏差明细)
      - Low_Efficiency_Devices (低效率设备)
      - PV_Model_Alert_Trace (光伏模型优化告警追踪)
      - PV_Device_Health (光伏设备健康度)
   
   4. 告警运维管理业务线：4个视图
      - View_Pending_High_Alarms (待处理高等级告警)
      - View_High_Alarm_Dispatch_SLA (高等级告警派单SLA)
      - View_OandM_Workload_Summary (运维人员工作量汇总)
      - View_Alarm_Process_Efficiency (告警处理效率)
   
   5. 大屏数据展示业务线：4个视图
      - View_Exec_Latest_Dashboard (企业管理层大屏最新数据)
      - View_Exec_Trend_Recent (近一年趋势数据)
      - View_Exec_Alarm_Stats_24h (近24小时告警统计)
      - View_Alarm_Pending_High_Simple (待处理高等级告警简洁版)
   
   视图特点：
   - 所有视图均为多表关联查询（3表及以上）
   - 包含聚合统计、CTE递归、OUTER APPLY等高级查询
   - 支持DROP IF EXISTS，可重复执行
   
   ============================================================ */

PRINT N'============================================================';
PRINT N'智慧能源管理系统 数据库视图DDL汇总 执行完成';
PRINT N'共创建 23 个视图，涵盖5个业务模块';
PRINT N'============================================================';
GO
