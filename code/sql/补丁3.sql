USE SQL_BFU;
GO

-- 1) 如已存在同名视图，先删掉
IF OBJECT_ID('View_PeakValley_Dynamic', 'V') IS NOT NULL
    DROP VIEW View_PeakValley_Dynamic;
GO

-- 2) 创建动态峰谷视图：按当前 Config_PeakValley 重新分段统计
CREATE VIEW View_PeakValley_Dynamic AS
SELECT
    CAST(e.Collect_Time AS DATE)                   AS Stat_Date,
    m.Energy_Type                                  AS Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID)            AS Factory_ID,
    c.Time_Type                                    AS Peak_Type,       -- 尖峰/高峰/平段/低谷
    SUM(e.Value)                                   AS Total_Consumption,
    SUM(e.Value * c.Price_Rate)                    AS Cost_Amount
FROM Data_Energy e
JOIN Energy_Meter m
    ON e.Meter_ID = m.Meter_ID
JOIN Config_PeakValley c
    ON CAST(e.Collect_Time AS TIME(0)) >= c.Start_Time
   AND CAST(e.Collect_Time AS TIME(0)) <  c.End_Time
GROUP BY
    CAST(e.Collect_Time AS DATE),
    m.Energy_Type,
    ISNULL(e.Factory_ID, m.Factory_ID),
    c.Time_Type;
GO
