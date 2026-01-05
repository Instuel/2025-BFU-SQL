/* ============================================================
   综合能耗

   插入测试数据（每表至少20条）
   ============================================================ */

-- 2.1 插入厂区基础数据（如果还没有的话）
-- 首先检查是否已有厂区数据
IF NOT EXISTS (SELECT 1 FROM Base_Factory WHERE Factory_Name = N'真旺厂')
BEGIN
    INSERT INTO Base_Factory (Factory_Name, Area_Desc) VALUES
    (N'真旺厂', N'主生产区域，包含多条生产线'),
    (N'豆果厂', N'豆制品加工区域'),
    (N'A3厂区', N'A3综合生产区'),
    (N'糕饼一厂', N'糕饼生产专区'),
    (N'VOCS处理区', N'废气处理设施区域');
END
GO

-- 2.2 插入能耗计量设备数据（25条，覆盖4种能源类型）
SET IDENTITY_INSERT Energy_Meter OFF;

INSERT INTO Energy_Meter (Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID)
VALUES
-- 水表设备（6条）
(N'水', N'RS485', N'正常', N'真旺厂东北角水表间', 12, N'宁波水表有限公司', 1),
(N'水', N'Lora', N'正常', N'豆果厂主管道入口', 12, N'三川智慧科技', 2),
(N'水', N'RS485', N'正常', N'A3厂区西侧水表房', 12, N'宁波水表有限公司', 3),
(N'水', N'Lora', N'故障', N'糕饼一厂冷却水管', 6, N'三川智慧科技', 4),
(N'水', N'RS485', N'正常', N'VOCS处理区循环水', 12, N'威胜集团', 5),
(N'水', N'Lora', N'正常', N'真旺厂消防水管', 12, N'三川智慧科技', 1),

-- 蒸汽表设备（6条）
(N'蒸汽', N'RS485', N'正常', N'真旺厂锅炉房出口', 6, N'浙江威星智能仪表', 1),
(N'蒸汽', N'RS485', N'正常', N'豆果厂蒸煮车间', 6, N'杭州美控自动化', 2),
(N'蒸汽', N'Lora', N'正常', N'A3厂区供热管道', 12, N'浙江威星智能仪表', 3),
(N'蒸汽', N'RS485', N'故障', N'糕饼一厂烘焙区', 6, N'杭州美控自动化', 4),
(N'蒸汽', N'RS485', N'正常', N'真旺厂二号锅炉', 6, N'浙江威星智能仪表', 1),
(N'蒸汽', N'Lora', N'正常', N'豆果厂干燥区', 12, N'杭州美控自动化', 2),

-- 天然气表设备（6条）
(N'天然气', N'RS485', N'正常', N'真旺厂燃气锅炉', 12, N'金卡智能集团', 1),
(N'天然气', N'Lora', N'正常', N'豆果厂燃气灶区', 12, N'成都秦川物联网', 2),
(N'天然气', N'RS485', N'正常', N'A3厂区热风炉', 12, N'金卡智能集团', 3),
(N'天然气', N'Lora', N'故障', N'糕饼一厂烤箱区', 6, N'成都秦川物联网', 4),
(N'天然气', N'RS485', N'正常', N'VOCS处理区燃烧炉', 12, N'金卡智能集团', 5),
(N'天然气', N'Lora', N'正常', N'真旺厂食堂', 12, N'成都秦川物联网', 1),

-- 电表设备（7条）- 新增能源类型
(N'电', N'RS485', N'正常', N'真旺厂总配电房', 12, N'国电南瑞科技', 1),
(N'电', N'Lora', N'正常', N'豆果厂分配电房1', 12, N'威胜集团', 2),
(N'电', N'RS485', N'正常', N'A3厂区配电房', 12, N'国电南瑞科技', 3),
(N'电', N'Lora', N'正常', N'糕饼一厂动力车间', 6, N'威胜集团', 4),
(N'电', N'RS485', N'正常', N'VOCS下面配电间', 12, N'国电南瑞科技', 5),
(N'电', N'Lora', N'故障', N'真旺厂办公楼', 12, N'威胜集团', 1),
(N'电', N'RS485', N'正常', N'豆果厂冷库', 12, N'国电南瑞科技', 2);

PRINT '已成功插入25条能耗计量设备数据（包含4种能源类型）';
GO

-- 2.3 插入峰谷时段配置数据（已有配置则跳过）
IF NOT EXISTS (SELECT 1 FROM Config_PeakValley)
BEGIN
    INSERT INTO Config_PeakValley (Time_Type, Start_Time, End_Time, Price_Rate) VALUES
    -- 尖峰时段
    (N'尖峰', '10:00:00', '12:00:00', 1.2500),
    (N'尖峰', '16:00:00', '18:00:00', 1.2500),
    -- 高峰时段
    (N'高峰', '08:00:00', '10:00:00', 1.0000),
    (N'高峰', '12:00:00', '16:00:00', 1.0000),
    (N'高峰', '18:00:00', '22:00:00', 1.0000),
    -- 平段
    (N'平段', '06:00:00', '08:00:00', 0.6500),
    (N'平段', '22:00:00', '23:59:59', 0.6500),
    -- 低谷
    (N'低谷', '00:00:00', '06:00:00', 0.3500);
    
    PRINT '已成功插入峰谷时段配置数据';
END
GO

-- 2.4 插入能耗监测数据（30条，重点造"波动超阈值"数据）
INSERT INTO Data_Energy (Meter_ID, Collect_Time, Value, Unit, Quality, Factory_ID) VALUES
-- 水表监测数据（正常+异常质量）
(1, '2025-12-25 08:00:00', 125.5, N'm³', N'优', 1),
(1, '2025-12-25 09:00:00', 132.8, N'm³', N'优', 1),
(1, '2025-12-25 10:00:00', 168.2, N'm³', N'中', 1), -- 波动>20%，应标记待核实
(2, '2025-12-25 08:00:00', 89.3, N'm³', N'优', 2),
(2, '2025-12-25 09:00:00', 115.6, N'm³', N'差', 2), -- 波动>20%
(3, '2025-12-25 10:00:00', 156.7, N'm³', N'良', 3),

-- 蒸汽监测数据
(7, '2025-12-25 08:00:00', 8.5, N't', N'优', 1),
(7, '2025-12-25 09:00:00', 9.2, N't', N'优', 1),
(7, '2025-12-25 10:00:00', 11.8, N't', N'中', 1), -- 波动较大
(8, '2025-12-25 08:00:00', 6.3, N't', N'优', 2),
(8, '2025-12-25 09:00:00', 8.1, N't', N'差', 2), -- 波动>20%
(9, '2025-12-25 10:00:00', 7.9, N't', N'良', 3),

-- 天然气监测数据
(13, '2025-12-25 08:00:00', 234.5, N'm³', N'优', 1),
(13, '2025-12-25 09:00:00', 256.8, N'm³', N'优', 1),
(13, '2025-12-25 10:00:00', 312.5, N'm³', N'差', 1), -- 波动>20%
(14, '2025-12-25 08:00:00', 178.3, N'm³', N'优', 2),
(14, '2025-12-25 09:00:00', 225.6, N'm³', N'中', 2), -- 波动较大
(15, '2025-12-25 10:00:00', 189.4, N'm³', N'良', 3),

-- 电表监测数据（新增）
(19, '2025-12-25 08:00:00', 1234.5, N'kWh', N'优', 1),
(19, '2025-12-25 09:00:00', 1456.8, N'kWh', N'优', 1),
(19, '2025-12-25 10:00:00', 1823.4, N'kWh', N'中', 1), -- 波动>20%
(20, '2025-12-25 08:00:00', 876.3, N'kWh', N'优', 2),
(20, '2025-12-25 09:00:00', 1125.9, N'kWh', N'差', 2), -- 波动>20%
(21, '2025-12-25 10:00:00', 967.2, N'kWh', N'良', 3),
(22, '2025-12-25 08:00:00', 543.8, N'kWh', N'优', 4),
(22, '2025-12-25 09:00:00', 589.5, N'kWh', N'优', 4),
(23, '2025-12-25 10:00:00', 712.3, N'kWh', N'良', 5),
(24, '2025-12-25 08:00:00', 234.6, N'kWh', N'差', 1), -- 异常数据
(25, '2025-12-25 09:00:00', 456.9, N'kWh', N'优', 2);

PRINT '已成功插入30条能耗监测数据（包含波动异常数据）';
GO

-- 2.5 插入峰谷能耗数据（25条，重点造"峰谷占比差异明显"的数据）
INSERT INTO Data_PeakValley (Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount) VALUES
-- 真旺厂电力数据 - 谷段占比较低（<30%）
('2025-12-20', N'电', 1, N'尖峰', 1250.5, 1563.13),
('2025-12-20', N'电', 1, N'高峰', 3560.8, 3560.80),
('2025-12-20', N'电', 1, N'平段', 1890.3, 1228.70),
('2025-12-20', N'电', 1, N'低谷', 850.2, 297.57), -- 谷段占比仅11.5%

-- 豆果厂电力数据 - 峰谷分布较合理
('2025-12-20', N'电', 2, N'尖峰', 890.5, 1113.13),
('2025-12-20', N'电', 2, N'高峰', 2340.6, 2340.60),
('2025-12-20', N'电', 2, N'平段', 1560.8, 1014.52),
('2025-12-20', N'电', 2, N'低谷', 1850.3, 647.61), -- 谷段占比27.5%

-- A3厂区天然气数据
('2025-12-20', N'天然气', 3, N'尖峰', 450.5, 563.13),
('2025-12-20', N'天然气', 3, N'高峰', 1280.3, 1280.30),
('2025-12-20', N'天然气', 3, N'平段', 890.6, 578.89),
('2025-12-20', N'天然气', 3, N'低谷', 320.8, 112.28),

-- 糕饼一厂水数据
('2025-12-20', N'水', 4, N'尖峰', 125.5, 156.88),
('2025-12-20', N'水', 4, N'高峰', 345.8, 345.80),
('2025-12-20', N'水', 4, N'平段', 234.6, 152.49),
('2025-12-20', N'水', 4, N'低谷', 89.3, 31.26),

-- VOCS处理区蒸汽数据
('2025-12-20', N'蒸汽', 5, N'尖峰', 12.5, 15.63),
('2025-12-20', N'蒸汽', 5, N'高峰', 34.8, 34.80),
('2025-12-20', N'蒸汽', 5, N'平段', 23.6, 15.34),
('2025-12-20', N'蒸汽', 5, N'低谷', 8.2, 2.87),

-- 次日数据（真旺厂）- 谷段占比依然很低
('2025-12-21', N'电', 1, N'尖峰', 1320.6, 1650.75),
('2025-12-21', N'电', 1, N'高峰', 3780.4, 3780.40),
('2025-12-21', N'电', 1, N'平段', 1920.5, 1248.33),
('2025-12-21', N'电', 1, N'低谷', 780.3, 273.11); -- 谷段占比仅10.1%

PRINT '已成功插入25条峰谷能耗数据（包含峰谷占比异常数据）';
GO

/* ============================================================
   Part 3: 创建索引（优化查询性能）
   ============================================================ */

-- 3.1 能耗计量设备表索引
-- 按厂区和能源类型查询优化
CREATE NONCLUSTERED INDEX IDX_Meter_Factory_Type 
ON Energy_Meter (Factory_ID, Energy_Type, Run_Status)
INCLUDE (Install_Location, Calib_Cycle_Months);

PRINT '已创建索引: IDX_Meter_Factory_Type';
GO

-- 3.2 能耗监测数据表索引
-- 按设备和时间查询优化（历史数据查询）
CREATE NONCLUSTERED INDEX IDX_Energy_Time 
ON Data_Energy (Meter_ID, Collect_Time DESC)
INCLUDE (Value, Quality);

-- 按厂区和数据质量查询优化（异常数据筛选）
CREATE NONCLUSTERED INDEX IDX_Energy_Quality 
ON Data_Energy (Factory_ID, Quality, Collect_Time DESC);

PRINT '已创建索引: IDX_Energy_Time, IDX_Energy_Quality';
GO

-- 3.3 峰谷能耗数据表索引
-- 按日期、能源类型和厂区查询优化（报表统计核心）
CREATE NONCLUSTERED INDEX IDX_PeakValley_Report 
ON Data_PeakValley (Stat_Date, Energy_Type, Factory_ID, Peak_Type)
INCLUDE (Total_Consumption, Cost_Amount);

-- 按厂区和统计日期查询优化
CREATE NONCLUSTERED INDEX IDX_PeakValley_Factory 
ON Data_PeakValley (Factory_ID, Stat_Date DESC);

PRINT '已创建索引: IDX_PeakValley_Report, IDX_PeakValley_Factory';
GO

/* ============================================================
   Part 4: 创建视图（至少3个实用视图）
   ============================================================ */

-- 4.1 视图1：峰谷能耗占比分析视图
-- 用途：分析各厂区各能源类型的峰谷用电占比，快速识别优化空间
CREATE OR ALTER VIEW View_PeakValley_Ratio AS
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

PRINT '已创建视图: View_PeakValley_Ratio（峰谷能耗占比分析）';
GO

-- 4.2 视图2：厂区能耗成本汇总视图
-- 用途：按厂区汇总各类能源的日度成本，支持成本分析
CREATE OR ALTER VIEW View_Factory_Energy_Cost AS
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

PRINT '已创建视图: View_Factory_Energy_Cost（厂区能耗成本汇总）';
GO

-- 4.3 视图3：待核实能耗数据视图
GO
CREATE OR ALTER VIEW View_Energy_ToVerify AS
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

PRINT '已创建视图: View_Energy_ToVerify';
GO

-- 4.4 视图4：设备运行状态监控视图（附加视图）
-- 用途：综合展示各能源类型设备的运行状态和校准情况
CREATE OR ALTER VIEW View_Meter_Status_Monitor AS
SELECT 
    m.Meter_ID,
    m.Energy_Type,
    f.Factory_Name,
    m.Install_Location,
    m.Run_Status,
    m.Manufacturer,
    m.Calib_Cycle_Months,
    l.Install_Time,
    -- 计算距离下次校准的月数（假设基于安装时间）
    DATEDIFF(MONTH, l.Install_Time, GETDATE()) % m.Calib_Cycle_Months AS Months_Since_Last_Calib,
    CASE 
        WHEN DATEDIFF(MONTH, l.Install_Time, GETDATE()) % m.Calib_Cycle_Months >= m.Calib_Cycle_Months - 1
        THEN N'即将到期-需安排校准'
        WHEN m.Run_Status = N'故障'
        THEN N'设备故障-需维修'
        ELSE N'正常运行'
    END AS Maintenance_Status,
    -- 统计最近的采集数据量
    (SELECT COUNT(*) 
     FROM Data_Energy de 
     WHERE de.Meter_ID = m.Meter_ID 
       AND de.Collect_Time >= DATEADD(DAY, -7, GETDATE())) AS Data_Count_Last7Days
FROM Energy_Meter m
JOIN Base_Factory f ON m.Factory_ID = f.Factory_ID
LEFT JOIN Device_Ledger l ON m.Ledger_ID = l.Ledger_ID;
GO

PRINT '已创建视图: View_Meter_Status_Monitor（设备运行状态监控）';
GO

/* ============================================================
   Part 5: 创建触发器（自动标记异常数据）
   ============================================================ */

-- 5.1 触发器：当能耗数据波动超过阈值时，自动标记数据质量为"待核实"
-- 业务逻辑：当单日能耗数据波动超过20%时，自动将数据质量状态标记为"中"或"差"
CREATE OR ALTER TRIGGER dbo.TRG_Energy_Quality_Check
ON dbo.Data_Energy
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) 选择一个“必定满足 CK_Alarm_Type”的 Alarm_Type */
    DECLARE @AlarmType NVARCHAR(50);
    SELECT TOP 1 @AlarmType = Alarm_Type
    FROM dbo.Alarm_Info
    WHERE Alarm_Type IS NOT NULL
    ORDER BY Occur_Time DESC;

    SET @AlarmType = ISNULL(@AlarmType, N'越限告警');

    /* 2) 计算 inserted 的上一条数据和波动率，并落到临时表 #F（供后续多条语句复用） */
    IF OBJECT_ID('tempdb..#F') IS NOT NULL DROP TABLE #F;

    ;WITH I AS (
        SELECT
            i.Data_ID,
            i.Meter_ID,
            i.Factory_ID,
            i.Collect_Time,
            i.Value AS Current_Value
        FROM inserted i
    ),
    P AS (
        SELECT
            I.*,
            Prev.Value AS Previous_Value,
            CASE
                WHEN Prev.Value IS NULL OR Prev.Value <= 0 THEN NULL
                ELSE ABS(I.Current_Value - Prev.Value) * 100.0 / Prev.Value
            END AS Fluctuation_Rate
        FROM I
        OUTER APPLY (
            SELECT TOP 1 de.Value
            FROM dbo.Data_Energy de
            WHERE de.Meter_ID = I.Meter_ID
              AND de.Collect_Time < I.Collect_Time
            ORDER BY de.Collect_Time DESC, de.Data_ID DESC
        ) Prev
    )
    SELECT
        P.Data_ID,
        P.Meter_ID,
        P.Factory_ID,
        P.Collect_Time,
        P.Current_Value,
        P.Previous_Value,
        P.Fluctuation_Rate,
        CASE
            WHEN P.Fluctuation_Rate > 30 THEN N'差'
            WHEN P.Fluctuation_Rate > 20 THEN N'中'
            ELSE NULL
        END AS New_Quality,
        CASE
            WHEN P.Fluctuation_Rate > 30 THEN 30
            WHEN P.Fluctuation_Rate > 20 THEN 20
            ELSE NULL
        END AS ThresholdUsed
    INTO #F
    FROM P
    WHERE P.Fluctuation_Rate IS NOT NULL
      AND P.Fluctuation_Rate > 20;

    /* 如果本次没有任何波动超阈值的数据，直接退出 */
    IF NOT EXISTS (SELECT 1 FROM #F) RETURN;

    /* 3) 更新 Data_Energy.Quality（NULL-safe，避免漏更新） */
    UPDATE de
    SET de.Quality = f.New_Quality
    FROM dbo.Data_Energy de
    INNER JOIN #F f ON f.Data_ID = de.Data_ID
    WHERE ISNULL(de.Quality, N'') <> ISNULL(f.New_Quality, N'');

    /* 4) 写入 Alarm_Info 告警（避免重复） */
    INSERT INTO dbo.Alarm_Info (
        Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status,
        Ledger_ID, Factory_ID, Trigger_Threshold, Verify_Status, Verify_Remark
    )
    SELECT
        @AlarmType AS Alarm_Type,
        CASE WHEN f.New_Quality = N'差' THEN N'高' ELSE N'中' END AS Alarm_Level,
        N'能耗数据波动异常：设备(Meter_ID=' + CAST(f.Meter_ID AS NVARCHAR(20)) + N') '
        + N'本次=' + CAST(f.Current_Value AS NVARCHAR(30))
        + N'，上次=' + CAST(f.Previous_Value AS NVARCHAR(30))
        + N'，波动率=' + CAST(CAST(f.Fluctuation_Rate AS DECIMAL(10,2)) AS NVARCHAR(30)) + N'%'
        + N'（阈值>' + CAST(f.ThresholdUsed AS NVARCHAR(10)) + N'%），已标记数据质量为“' + f.New_Quality + N'”。'
        AS Content,
        f.Collect_Time AS Occur_Time,
        N'未处理' AS Process_Status,
        m.Ledger_ID,
        f.Factory_ID,
        CAST(f.ThresholdUsed AS DECIMAL(12,3)) AS Trigger_Threshold,
        N'待审核' AS Verify_Status,
        NULL AS Verify_Remark
    FROM #F f
    LEFT JOIN dbo.Energy_Meter m ON m.Meter_ID = f.Meter_ID
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Alarm_Info a
        WHERE a.Occur_Time = f.Collect_Time
          AND a.Factory_ID = f.Factory_ID
          AND a.Content LIKE N'%Meter_ID=' + CAST(f.Meter_ID AS NVARCHAR(20)) + N'%'
          AND a.Content LIKE N'%能耗数据波动异常%'
    );
END;
GO


PRINT '已创建触发器: TRG_Energy_Quality_Check（自动检测能耗波动并标记质量）';
GO

/* ============================================================
   Part 6: 创建存储过程（日度峰谷能耗统计）
   ============================================================ */

-- 6.1 存储过程：日度峰谷能耗统计
-- 修正：改用标准 DROP/CREATE 模式，确保创建成功
GO

-- 如果存在则先删除
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_Calculate_Daily_PeakValley')
    DROP PROCEDURE SP_Calculate_Daily_PeakValley;
GO

-- 重新创建
CREATE PROCEDURE SP_Calculate_Daily_PeakValley
    @Stat_Date DATE,
    @Factory_ID BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. 删除旧数据
        IF @Factory_ID IS NULL
        BEGIN
            DELETE FROM Data_PeakValley WHERE Stat_Date = @Stat_Date;
            PRINT '已删除 ' + CONVERT(NVARCHAR(20), @Stat_Date, 120) + ' 的所有旧数据';
        END
        ELSE
        BEGIN
            DELETE FROM Data_PeakValley 
            WHERE Stat_Date = @Stat_Date AND Factory_ID = @Factory_ID;
        END
        
        -- 2. 计算并插入新数据
        INSERT INTO Data_PeakValley (Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount)
        SELECT 
            CAST(de.Collect_Time AS DATE),
            m.Energy_Type,
            de.Factory_ID,
            -- 简单的峰谷判断逻辑 (示例)
            CASE 
                WHEN CAST(de.Collect_Time AS TIME) BETWEEN '08:00' AND '22:00' THEN N'高峰'
                ELSE N'低谷'
            END,
            SUM(de.Value),
            SUM(de.Value * 1.0) -- 简化计算，实际根据你的逻辑来
        FROM Data_Energy de
        JOIN Energy_Meter m ON de.Meter_ID = m.Meter_ID
        WHERE CAST(de.Collect_Time AS DATE) = @Stat_Date
          AND (@Factory_ID IS NULL OR de.Factory_ID = @Factory_ID)
        GROUP BY 
            CAST(de.Collect_Time AS DATE),
            m.Energy_Type,
            de.Factory_ID,
            CASE 
                WHEN CAST(de.Collect_Time AS TIME) BETWEEN '08:00' AND '22:00' THEN N'高峰'
                ELSE N'低谷'
            END;
            
        COMMIT TRANSACTION;
        PRINT '统计完成。';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT '已创建存储过程: SP_Calculate_Daily_PeakValley（日度峰谷能耗统计）';
GO

/* ============================================================
   Part 7: 测试SQL语句示例
   ============================================================ */

PRINT '========================================';
PRINT '第三业务线数据库脚本执行完成！';
PRINT '========================================';
PRINT '';
PRINT '已完成内容：';
PRINT '1. 修改表结构 - 增加"电"作为第4种能源类型';
PRINT '2. 插入测试数据 - 能耗计量设备（25条）、能耗监测数据（30条）、峰谷能耗数据（25条）';
PRINT '3. 创建索引 - 5个高性能索引';
PRINT '4. 创建视图 - 4个实用视图';
PRINT '5. 创建触发器 - 自动检测能耗波动并标记质量';
PRINT '6. 创建存储过程 - 日度峰谷能耗统计';
PRINT '';
PRINT '测试视图查询示例：';
PRINT '-- 查看峰谷占比分析';
PRINT 'SELECT * FROM View_PeakValley_Ratio WHERE Valley_Ratio < 30;';
PRINT '';
PRINT '-- 查看厂区能耗成本';
PRINT 'SELECT * FROM View_Factory_Energy_Cost ORDER BY Total_Cost DESC;';
PRINT '';
PRINT '-- 查看待核实数据';
PRINT 'SELECT * FROM View_Energy_ToVerify;';
PRINT '';
PRINT '测试存储过程示例：';
PRINT '-- 统计指定日期的峰谷能耗';
PRINT 'EXEC SP_Calculate_Daily_PeakValley @Stat_Date = ''2025-12-25'';';
PRINT '';
PRINT '========================================';
GO
