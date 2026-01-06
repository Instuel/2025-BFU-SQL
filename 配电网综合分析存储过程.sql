USE SQL_BFU;
GO

/* ============================================================
   配电网综合分析存储过程
   基于配电网.sql脚本编写的综合分析存储过程
   
   功能说明：
   1. 设备健康状态分析
   2. 异常数据统计和报警
   3. 能耗分析和成本计算
   4. 数据完整性检查
   5. 生成综合分析报告
   
   参数说明：
   @AnalysisType: 分析类型 (1=设备状态, 2=异常统计, 3=能耗分析, 4=数据完整性, 5=综合报告)
   @StartDate: 开始日期
   @EndDate: 结束日期  
   @FactoryID: 工厂ID (可选，为NULL时分析所有工厂)
   @RoomID: 配电房ID (可选，为NULL时分析所有配电房)
   ============================================================ */

IF OBJECT_ID('dbo.SP_PowerGrid_Analysis', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_PowerGrid_Analysis;
GO

CREATE PROCEDURE SP_PowerGrid_Analysis
    @AnalysisType INT = 5,              -- 分析类型：1=设备状态, 2=异常统计, 3=能耗分析, 4=数据完整性, 5=综合报告
    @StartDate DATETIME = NULL,         -- 开始日期
    @EndDate DATETIME = NULL,           -- 结束日期
    @FactoryID BIGINT = NULL,           -- 工厂ID (可选)
    @RoomID BIGINT = NULL               -- 配电房ID (可选)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 参数验证和默认值设置
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(DAY, -7, GETDATE()); -- 默认最近7天
    
    IF @EndDate IS NULL
        SET @EndDate = GETDATE();
    
    -- 临时表用于存储分析结果
    CREATE TABLE #AnalysisResults (
        ResultType NVARCHAR(50),
        Category NVARCHAR(100),
        ItemName NVARCHAR(200),
        Value1 DECIMAL(18,3),
        Value2 DECIMAL(18,3),
        Status NVARCHAR(50),
        Description NVARCHAR(500),
        CreateTime DATETIME DEFAULT GETDATE()
    );
    
    -- 1. 设备健康状态分析
    IF @AnalysisType IN (1, 5)
    BEGIN
        PRINT '正在执行设备健康状态分析...';
        
        -- 变压器状态统计
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'设备状态',
            N'变压器',
            f.Factory_Name + N' - ' + r.Room_Name,
            COUNT(*) AS Total_Count,
            SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Count,
            CASE 
                WHEN SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.9 THEN N'优秀'
                WHEN SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.7 THEN N'良好'
                ELSE N'较差'
            END,
            N'变压器健康率: ' + 
            CAST(ROUND(SUM(CASE WHEN t.Device_Status = N'正常' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS NVARCHAR(10)) + N'%'
        FROM Dist_Transformer t
        JOIN Dist_Room r ON t.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
        GROUP BY f.Factory_Name, r.Room_Name, f.Factory_ID, r.Room_ID;
        
        -- 电路状态统计
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'设备状态',
            N'电路',
            f.Factory_Name + N' - ' + r.Room_Name,
            COUNT(*) AS Total_Count,
            SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Count,
            CASE 
                WHEN SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.9 THEN N'优秀'
                WHEN SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.7 THEN N'良好'
                ELSE N'较差'
            END,
            N'电路健康率: ' + 
            CAST(ROUND(SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS NVARCHAR(10)) + N'%'
        FROM Dist_Circuit c
        JOIN Dist_Room r ON c.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
        GROUP BY f.Factory_Name, r.Room_Name, f.Factory_ID, r.Room_ID;
    END
    
    -- 2. 异常数据统计和报警
    IF @AnalysisType IN (2, 5)
    BEGIN
        PRINT '正在执行异常数据统计...';
        
        -- 变压器温度异常统计
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'异常统计',
            N'变压器温度异常',
            t.Transformer_Name,
            AVG(dt.Winding_Temp) AS Avg_Winding_Temp,
            AVG(dt.Core_Temp) AS Avg_Core_Temp,
            CASE 
                WHEN AVG(dt.Winding_Temp) > 80 OR AVG(dt.Core_Temp) > 80 THEN N'异常'
                WHEN AVG(dt.Winding_Temp) > 70 OR AVG(dt.Core_Temp) > 70 THEN N'警告'
                ELSE N'正常'
            END,
            N'平均绕组温度: ' + CAST(ROUND(AVG(dt.Winding_Temp), 2) AS NVARCHAR(10)) + N'℃, ' +
            N'平均铁芯温度: ' + CAST(ROUND(AVG(dt.Core_Temp), 2) AS NVARCHAR(10)) + N'℃'
        FROM Data_Transformer dt
        JOIN Dist_Transformer t ON dt.Transformer_ID = t.Transformer_ID
        JOIN Dist_Room r ON t.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE dt.Collect_Time BETWEEN @StartDate AND @EndDate
          AND (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
          AND dt.Winding_Temp IS NOT NULL 
          AND dt.Core_Temp IS NOT NULL
        GROUP BY t.Transformer_ID, t.Transformer_Name
        HAVING AVG(dt.Winding_Temp) > 60 OR AVG(dt.Core_Temp) > 60; -- 只显示有温度风险的设备
        
        -- 电路电压异常统计
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'异常统计',
            N'电路电压异常',
            c.Circuit_Name,
            AVG(dc.Voltage) AS Avg_Voltage,
            COUNT(*) AS Abnormal_Count,
            CASE 
                WHEN AVG(dc.Voltage) > 37 OR AVG(dc.Voltage) < 33 THEN N'异常'
                WHEN AVG(dc.Voltage) > 36 OR AVG(dc.Voltage) < 34 THEN N'警告'
                ELSE N'正常'
            END,
            N'平均电压: ' + CAST(ROUND(AVG(dc.Voltage), 3) AS NVARCHAR(10)) + N'kV, ' +
            N'异常次数: ' + CAST(COUNT(*) AS NVARCHAR(10))
        FROM Data_Circuit dc
        JOIN Dist_Circuit c ON dc.Circuit_ID = c.Circuit_ID
        JOIN Dist_Room r ON c.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE dc.Collect_Time BETWEEN @StartDate AND @EndDate
          AND (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
          AND dc.Voltage IS NOT NULL
          AND (dc.Voltage > 37 OR dc.Voltage < 33) -- 只统计异常数据
        GROUP BY c.Circuit_ID, c.Circuit_Name;
    END
    
    -- 3. 能耗分析和成本计算
    IF @AnalysisType IN (3, 5)
    BEGIN
        PRINT '正在执行能耗分析...';
        
        -- 按工厂统计日用电量和成本
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'能耗分析',
            N'日用电统计',
            f.Factory_Name + N' - ' + CAST(CAST(dc.Collect_Time AS DATE) AS NVARCHAR(20)),
            SUM(dc.Active_Power) / 1000.0 AS Total_Power_MWH, -- 转换为MWh
            SUM(dc.Active_Power * ISNULL(cp.Price_Rate, 0.65)) / 1000.0 AS Estimated_Cost, -- 估算成本
            CASE 
                WHEN SUM(dc.Active_Power) / 1000.0 > 100 THEN N'高耗能'
                WHEN SUM(dc.Active_Power) / 1000.0 > 50 THEN N'中等'
                ELSE N'正常'
            END,
            N'日用电量: ' + CAST(ROUND(SUM(dc.Active_Power) / 1000.0, 3) AS NVARCHAR(20)) + N'MWh, ' +
            N'估算成本: ' + CAST(ROUND(SUM(dc.Active_Power * ISNULL(cp.Price_Rate, 0.65)) / 1000.0, 2) AS NVARCHAR(20)) + N'元'
        FROM Data_Circuit dc
        JOIN Dist_Circuit c ON dc.Circuit_ID = c.Circuit_ID
        JOIN Dist_Room r ON c.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        LEFT JOIN Config_PeakValley cp ON CAST(dc.Collect_Time AS TIME(0)) BETWEEN cp.Start_Time AND cp.End_Time
        WHERE dc.Collect_Time BETWEEN @StartDate AND @EndDate
          AND (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
          AND dc.Active_Power IS NOT NULL
          AND dc.Active_Power > 0
        GROUP BY f.Factory_ID, f.Factory_Name, CAST(dc.Collect_Time AS DATE)
        HAVING SUM(dc.Active_Power) > 0;
    END
    
    -- 4. 数据完整性检查
    IF @AnalysisType IN (4, 5)
    BEGIN
        PRINT '正在执行数据完整性检查...';
        
        -- 变压器数据完整性
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'数据完整性',
            N'变压器数据',
            t.Transformer_Name,
            COUNT(*) AS Total_Records,
            SUM(CASE WHEN dt.Winding_Temp IS NULL OR dt.Core_Temp IS NULL OR dt.Load_Rate IS NULL THEN 1 ELSE 0 END) AS Missing_Records,
            CASE 
                WHEN SUM(CASE WHEN dt.Winding_Temp IS NULL OR dt.Core_Temp IS NULL OR dt.Load_Rate IS NULL THEN 1 ELSE 0 END) = 0 THEN N'完整'
                WHEN SUM(CASE WHEN dt.Winding_Temp IS NULL OR dt.Core_Temp IS NULL OR dt.Load_Rate IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) < 0.1 THEN N'良好'
                ELSE N'缺失严重'
            END,
            N'总记录数: ' + CAST(COUNT(*) AS NVARCHAR(10)) + N', ' +
            N'缺失记录: ' + CAST(SUM(CASE WHEN dt.Winding_Temp IS NULL OR dt.Core_Temp IS NULL OR dt.Load_Rate IS NULL THEN 1 ELSE 0 END) AS NVARCHAR(10)) + N', ' +
            N'完整率: ' + CAST(ROUND((COUNT(*) - SUM(CASE WHEN dt.Winding_Temp IS NULL OR dt.Core_Temp IS NULL OR dt.Load_Rate IS NULL THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2) AS NVARCHAR(10)) + N'%'
        FROM Data_Transformer dt
        JOIN Dist_Transformer t ON dt.Transformer_ID = t.Transformer_ID
        JOIN Dist_Room r ON t.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE dt.Collect_Time BETWEEN @StartDate AND @EndDate
          AND (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
        GROUP BY t.Transformer_ID, t.Transformer_Name;
        
        -- 电路数据完整性
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'数据完整性',
            N'电路数据',
            c.Circuit_Name,
            COUNT(*) AS Total_Records,
            SUM(CASE WHEN dc.Voltage IS NULL OR dc.Current_Val IS NULL OR dc.Active_Power IS NULL THEN 1 ELSE 0 END) AS Missing_Records,
            CASE 
                WHEN SUM(CASE WHEN dc.Voltage IS NULL OR dc.Current_Val IS NULL OR dc.Active_Power IS NULL THEN 1 ELSE 0 END) = 0 THEN N'完整'
                WHEN SUM(CASE WHEN dc.Voltage IS NULL OR dc.Current_Val IS NULL OR dc.Active_Power IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) < 0.1 THEN N'良好'
                ELSE N'缺失严重'
            END,
            N'总记录数: ' + CAST(COUNT(*) AS NVARCHAR(10)) + N', ' +
            N'缺失记录: ' + CAST(SUM(CASE WHEN dc.Voltage IS NULL OR dc.Current_Val IS NULL OR dc.Active_Power IS NULL THEN 1 ELSE 0 END) AS NVARCHAR(10)) + N', ' +
            N'完整率: ' + CAST(ROUND((COUNT(*) - SUM(CASE WHEN dc.Voltage IS NULL OR dc.Current_Val IS NULL OR dc.Active_Power IS NULL THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2) AS NVARCHAR(10)) + N'%'
        FROM Data_Circuit dc
        JOIN Dist_Circuit c ON dc.Circuit_ID = c.Circuit_ID
        JOIN Dist_Room r ON c.Room_ID = r.Room_ID
        JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID
        WHERE dc.Collect_Time BETWEEN @StartDate AND @EndDate
          AND (@FactoryID IS NULL OR f.Factory_ID = @FactoryID)
          AND (@RoomID IS NULL OR r.Room_ID = @RoomID)
        GROUP BY c.Circuit_ID, c.Circuit_Name;
    END
    
    -- 5. 生成综合分析报告
    IF @AnalysisType = 5
    BEGIN
        PRINT '正在生成综合分析报告...';
        
        -- 添加报告摘要
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'综合报告',
            N'分析摘要',
            N'报告生成时间',
            DATEDIFF(DAY, @StartDate, @EndDate) AS Analysis_Days,
            COUNT(DISTINCT CASE WHEN ResultType = N'异常统计' AND Status = N'异常' THEN ItemName END) AS Critical_Issues,
            N'已完成',
            N'分析时间段: ' + CAST(@StartDate AS NVARCHAR(20)) + N' 至 ' + CAST(@EndDate AS NVARCHAR(20)) + N', ' +
            N'发现 ' + CAST(COUNT(DISTINCT CASE WHEN ResultType = N'异常统计' AND Status = N'异常' THEN ItemName END) AS NVARCHAR(10)) + N' 个严重异常'
        FROM #AnalysisResults;
    END
    
    -- 返回分析结果
    SELECT 
        ResultType AS 结果类型,
        Category AS 分析类别,
        ItemName AS 项目名称,
        Value1 AS 数值1,
        Value2 AS 数值2,
        Status AS 状态,
        Description AS 详细描述,
        CreateTime AS 分析时间
    FROM #AnalysisResults
    ORDER BY ResultType, Category, Status DESC, Value1 DESC;
    
    -- 清理临时表
    DROP TABLE #AnalysisResults;
    
    PRINT '配电网综合分析完成！';
END;
GO

PRINT '存储过程 SP_PowerGrid_Analysis 创建成功！';
GO

/* ============================================================
   使用示例和说明
   ============================================================ */

-- 示例1: 执行设备状态分析
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 1, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例2: 执行异常统计分析
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 2, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例3: 执行能耗分析
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 3, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例4: 执行数据完整性检查
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 4, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例5: 执行综合分析报告（推荐）
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 5, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例6: 分析特定工厂的数据
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 5, @FactoryID = 1, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

-- 示例7: 分析特定配电房的数据
-- EXEC SP_PowerGrid_Analysis @AnalysisType = 5, @RoomID = 1, @StartDate = '2025-01-01', @EndDate = '2025-01-07';

PRINT '使用示例已添加