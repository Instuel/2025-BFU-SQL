/* ============================================================
   智慧能源管理系统 - 数据库存储过程和触发器DDL汇总
   Smart Energy Management System - Stored Procedures & Triggers DDL Summary
   
   整理日期: 2026-01-06
   数据库: SQL_BFU (SQL Server)
   
   说明：本文件按业务线整合了所有存储过程和触发器的DDL语句，
         包含主脚本和补丁中的所有定义，并详细介绍每个对象的
         业务用途和适用范围。
   
   内容分类：
   1. 配电网监测业务线 (2个触发器 + 1个存储过程)
   2. 综合能耗管理业务线 (1个触发器 + 1个存储过程)
   3. 分布式光伏管理业务线 (3个触发器 + 1个存储过程)
   4. 告警运维管理业务线 (1个触发器)
   5. 大屏数据展示业务线 (1个触发器)
   ============================================================ */

USE SQL_BFU;
GO

SET NOCOUNT ON;
GO

/* ############################################################
   ##                                                        ##
   ##          第一部分：配电网监测业务线                      ##
   ##          负责人：张恺洋                                  ##
   ##                                                        ##
   ############################################################
   
   【业务背景】
   配电网监测业务线负责监控配电房中的变压器和回路设备运行状态，
   实时采集电压、电流、温度等参数，及时发现异常并生成告警。
   
   【触发器设计】
   - TR_Transformer_Analyze: 变压器数据分析触发器
   - TR_Circuit_Analyze: 回路数据分析触发器
   
   【存储过程设计】
   - SP_PowerGrid_Analysis: 配电网综合分析存储过程
   ============================================================ */

-- ============================================================
-- 触发器 1.1: 变压器数据分析触发器 (TR_Transformer_Analyze)
-- ============================================================
/*
【功能描述】
当变压器监测数据(Data_Transformer)插入时，自动执行以下操作：
1. 将监测数据正确插入数据表（INSTEAD OF触发器模式）
2. 根据温度阈值判断设备状态，更新台账表(Dist_Transformer)的Device_Status
3. 当温度超过阈值时，自动生成高等级告警写入Alarm_Info表

【适用范围】
- 实时监控变压器运行温度
- 自动标记设备异常状态
- 无需人工干预的告警生成

【业务规则】
- 默认温度阈值：80℃（可从Alarm_Info历史记录获取动态阈值）
- 绕组温度或铁芯温度超过阈值即判定为异常
- 排除无效数据（999或<=0的异常采集值）

【触发条件】
- INSERT操作触发（INSTEAD OF模式）
*/
-- ============================================================
IF OBJECT_ID('dbo.TR_Transformer_Analyze', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Transformer_Analyze;
GO

CREATE TRIGGER TR_Transformer_Analyze
ON Data_Transformer
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 获取温度阈值（从历史告警记录或使用默认值80℃）
    DECLARE @Threshold DECIMAL(12,3);
    SELECT TOP 1 @Threshold = Trigger_Threshold
    FROM Alarm_Info
    WHERE Alarm_Type = N'越限告警' AND Trigger_Threshold IS NOT NULL
    ORDER BY Occur_Time DESC;

    SET @Threshold = ISNULL(@Threshold, 80.0); 

    -- 2. 执行数据插入（不包含Device_Status字段，因为Data表不存储状态）
    INSERT INTO Data_Transformer (
        Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, 
        Load_Rate, Factory_ID
    )
    SELECT 
        i.Transformer_ID, i.Collect_Time, i.Winding_Temp, i.Core_Temp, 
        i.Load_Rate, i.Factory_ID
    FROM inserted i;

    -- 3. 更新台账表的设备状态（Dist_Transformer）
    -- 逻辑：如果有任意一条新插入的数据异常，则更新对应设备为'异常'，否则恢复为'正常'
    UPDATE t
    SET Device_Status = CASE 
            WHEN (
                (i.Winding_Temp > @Threshold AND i.Winding_Temp <> 999 AND i.Winding_Temp > 0) OR
                (i.Core_Temp > @Threshold AND i.Core_Temp <> 999 AND i.Core_Temp > 0)
            ) THEN N'异常'
            ELSE N'正常'
        END
    FROM Dist_Transformer t
    JOIN inserted i ON t.Transformer_ID = i.Transformer_ID;

    -- 4. 生成越限告警
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
        (i.Core_Temp > @Threshold AND i.Core_Temp <> 999 AND i.Core_Temp > 0)
    );
END;
GO

PRINT '已创建触发器: TR_Transformer_Analyze (变压器数据分析)';
GO


-- ============================================================
-- 触发器 1.2: 回路数据分析触发器 (TR_Circuit_Analyze)
-- ============================================================
/*
【功能描述】
当回路监测数据(Data_Circuit)插入时，自动执行以下操作：
1. 将监测数据正确插入数据表
2. 根据电压阈值判断设备状态，更新台账表(Dist_Circuit)的Device_Status
3. 当电压越限时，生成越限告警
4. 当监测数值异常（999或0）时，生成设备离线告警

【适用范围】
- 实时监控回路电压、电流状态
- 自动检测设备离线或传感器故障
- 电压越限预警

【业务规则】
- 默认电压阈值：37kV（正常范围33-37kV）
- 电压超过阈值生成越限告警
- 电压或电流为999或<=0时判定为设备离线

【触发条件】
- INSERT操作触发（INSTEAD OF模式）
*/
-- ============================================================
IF OBJECT_ID('dbo.TR_Circuit_Analyze', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Circuit_Analyze;
GO

CREATE TRIGGER TR_Circuit_Analyze
ON Data_Circuit
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 获取电压阈值
    DECLARE @Threshold_V DECIMAL(12,3); 
    SELECT TOP 1 @Threshold_V = Trigger_Threshold
    FROM Alarm_Info
    WHERE Alarm_Type = N'越限告警' AND Trigger_Threshold IS NOT NULL
    ORDER BY Occur_Time DESC;
    SET @Threshold_V = ISNULL(@Threshold_V, 37.0); 

    -- 1. 执行数据插入
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

    -- 2. 更新台账表的设备状态
    UPDATE c
    SET Device_Status = CASE 
            WHEN (i.Voltage > @Threshold_V AND i.Voltage <> 999 AND i.Voltage > 0) THEN N'异常'
            WHEN (i.Voltage >= 999 OR i.Voltage <= 0 OR i.Current_Val >= 999 OR i.Current_Val <= 0) THEN N'异常'
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

    -- 4. 生成设备离线告警
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

PRINT '已创建触发器: TR_Circuit_Analyze (回路数据分析)';
GO


-- ============================================================
-- 存储过程 1.1: 配电网综合分析 (SP_PowerGrid_Analysis)
-- ============================================================
/*
【功能描述】
提供配电网多维度综合分析能力，支持以下分析类型：
1. 设备健康状态分析 - 统计各配电房设备正常/异常比例
2. 异常数据统计 - 汇总温度/电压异常记录
3. 能耗分析 - 按工厂统计日用电量和成本
4. 数据完整性检查 - 检测缺失数据比例
5. 综合报告 - 一次性输出所有分析结果

【适用范围】
- 定期生成配电网运行分析报告
- 设备健康度评估
- 能耗成本分析
- 数据质量监控

【参数说明】
- @AnalysisType: 分析类型（1=设备状态, 2=异常统计, 3=能耗分析, 4=数据完整性, 5=综合报告）
- @StartDate: 分析开始日期（默认7天前）
- @EndDate: 分析结束日期（默认当前）
- @FactoryID: 指定工厂ID（NULL表示所有工厂）
- @RoomID: 指定配电房ID（NULL表示所有配电房）

【调用示例】
EXEC SP_PowerGrid_Analysis @AnalysisType = 5;  -- 综合报告
EXEC SP_PowerGrid_Analysis @AnalysisType = 1, @FactoryID = 1;  -- 指定工厂的设备状态
EXEC SP_PowerGrid_Analysis @AnalysisType = 3, @StartDate = '2025-01-01', @EndDate = '2025-01-31';
*/
-- ============================================================
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
        SET @StartDate = DATEADD(DAY, -7, GETDATE());
    
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
            N'回路',
            f.Factory_Name + N' - ' + r.Room_Name,
            COUNT(*) AS Total_Count,
            SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) AS Normal_Count,
            CASE 
                WHEN SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.9 THEN N'优秀'
                WHEN SUM(CASE WHEN c.Device_Status = N'正常' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >= 0.7 THEN N'良好'
                ELSE N'较差'
            END,
            N'回路健康率: ' + 
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
          AND dt.Winding_Temp IS NOT NULL AND dt.Core_Temp IS NOT NULL
        GROUP BY t.Transformer_ID, t.Transformer_Name
        HAVING AVG(dt.Winding_Temp) > 60 OR AVG(dt.Core_Temp) > 60;
        
        -- 回路电压异常统计
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'异常统计',
            N'回路电压异常',
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
          AND (dc.Voltage > 37 OR dc.Voltage < 33)
        GROUP BY c.Circuit_ID, c.Circuit_Name;
    END
    
    -- 3. 能耗分析和成本计算
    IF @AnalysisType IN (3, 5)
    BEGIN
        PRINT '正在执行能耗分析...';
        
        INSERT INTO #AnalysisResults (ResultType, Category, ItemName, Value1, Value2, Status, Description)
        SELECT 
            N'能耗分析',
            N'日用电统计',
            f.Factory_Name + N' - ' + CAST(CAST(dc.Collect_Time AS DATE) AS NVARCHAR(20)),
            SUM(dc.Active_Power) / 1000.0 AS Total_Power_MWH,
            SUM(dc.Active_Power * ISNULL(cp.Price_Rate, 0.65)) / 1000.0 AS Estimated_Cost,
            CASE 
                WHEN SUM(dc.Active_Power) / 1000.0 > 100 THEN N'高能耗'
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
          AND dc.Active_Power IS NOT NULL AND dc.Active_Power > 0
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
    END
    
    -- 5. 生成综合报告摘要
    IF @AnalysisType = 5
    BEGIN
        PRINT '正在生成综合分析报告...';
        
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

PRINT '已创建存储过程: SP_PowerGrid_Analysis (配电网综合分析)';
GO


/* ############################################################
   ##                                                        ##
   ##          第二部分：综合能耗管理业务线                    ##
   ##          负责人：杨昊田                                  ##
   ##                                                        ##
   ############################################################
   
   【业务背景】
   综合能耗管理业务线负责采集和分析各类能源（电、水、蒸汽、天然气）
   的消耗数据，支持峰谷电价计算和能耗成本分析。
   
   【触发器设计】
   - TRG_Energy_Quality_Check: 能耗数据质量自动检测触发器
   
   【存储过程设计】
   - SP_Calculate_Daily_PeakValley: 日度峰谷能耗统计存储过程
   ============================================================ */

-- ============================================================
-- 触发器 2.1: 能耗数据质量检测触发器 (TRG_Energy_Quality_Check)
-- ============================================================
/*
【功能描述】
当能耗数据(Data_Energy)插入或更新时，自动执行以下操作：
1. 计算与前一条记录的波动率
2. 波动率>20%标记为"中"质量，>30%标记为"差"质量
3. 自动生成告警记录

【适用范围】
- 能耗数据采集质量监控
- 异常用能行为检测
- 数据波动预警

【业务规则】
- 波动率 = |当前值 - 上次值| / 上次值 × 100%
- 波动率 > 30%: 质量标记为"差"，生成高等级告警
- 波动率 > 20%: 质量标记为"中"，生成中等级告警

【触发条件】
- INSERT, UPDATE操作触发（AFTER模式）
*/
-- ============================================================
IF OBJECT_ID('dbo.TRG_Energy_Quality_Check', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_Energy_Quality_Check;
GO

CREATE TRIGGER dbo.TRG_Energy_Quality_Check
ON dbo.Data_Energy
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 获取一个有效的告警类型
    DECLARE @AlarmType NVARCHAR(50);
    SELECT TOP 1 @AlarmType = Alarm_Type
    FROM dbo.Alarm_Info
    WHERE Alarm_Type IS NOT NULL
    ORDER BY Occur_Time DESC;
    SET @AlarmType = ISNULL(@AlarmType, N'越限告警');

    -- 2. 计算波动率并存入临时表
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

    -- 如果没有波动超阈值的数据，直接退出
    IF NOT EXISTS (SELECT 1 FROM #F) RETURN;

    -- 3. 更新数据质量标记
    UPDATE de
    SET de.Quality = f.New_Quality
    FROM dbo.Data_Energy de
    INNER JOIN #F f ON f.Data_ID = de.Data_ID
    WHERE ISNULL(de.Quality, N'') <> ISNULL(f.New_Quality, N'');

    -- 4. 写入告警记录（避免重复）
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
        + N'（阈值>' + CAST(f.ThresholdUsed AS NVARCHAR(10)) + N'%），已标记数据质量为"' + f.New_Quality + N'"。'
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

PRINT '已创建触发器: TRG_Energy_Quality_Check (能耗数据质量检测)';
GO


-- ============================================================
-- 存储过程 2.1: 日度峰谷能耗统计 (SP_Calculate_Daily_PeakValley)
-- ============================================================
/*
【功能描述】
按日期统计各厂区的峰谷时段能耗，计算能耗量和成本，
结果写入Data_PeakValley汇总表。

【适用范围】
- 日终批量统计峰谷能耗
- 电费成本分析
- 峰谷电价优化决策支持

【参数说明】
- @Stat_Date: 统计日期
- @Factory_ID: 指定工厂ID（NULL表示所有工厂）

【调用示例】
-- 统计所有工厂的某天数据
EXEC SP_Calculate_Daily_PeakValley @Stat_Date = '2025-12-25';

-- 统计指定工厂
EXEC SP_Calculate_Daily_PeakValley @Stat_Date = '2025-12-25', @Factory_ID = 1;
*/
-- ============================================================
IF OBJECT_ID('dbo.SP_Calculate_Daily_PeakValley', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_Calculate_Daily_PeakValley;
GO

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
            -- 峰谷时段判断（简化版本，实际应关联Config_PeakValley表）
            CASE 
                WHEN CAST(de.Collect_Time AS TIME) BETWEEN '08:00' AND '22:00' THEN N'高峰'
                ELSE N'低谷'
            END,
            SUM(de.Value),
            SUM(de.Value * 1.0) -- 成本计算（实际应乘以对应时段电价）
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
        PRINT '日度峰谷能耗统计完成。日期: ' + CONVERT(NVARCHAR(20), @Stat_Date, 120);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT '已创建存储过程: SP_Calculate_Daily_PeakValley (日度峰谷能耗统计)';
GO


/* ############################################################
   ##                                                        ##
   ##          第三部分：分布式光伏管理业务线                  ##
   ##          负责人：段泓冰                                  ##
   ##                                                        ##
   ############################################################
   
   【业务背景】
   分布式光伏管理业务线负责光伏发电设备监控、发电量预测、
   预测偏差分析和模型优化告警。
   
   【触发器设计】
   - TR_Update_Forecast_Actual: 发电数据同步预测实际值触发器
   - TR_Model_Optimization_Alert: 预测偏差告警触发器
   - TR_Check_Inverter_Efficiency: 逆变器效率检测触发器
   
   【存储过程设计】
   - Check_Continuous_Deviation: 连续偏差检测存储过程
   ============================================================ */

-- ============================================================
-- 触发器 3.1: 发电数据同步预测实际值 (TR_Update_Forecast_Actual)
-- ============================================================
/*
【功能描述】
当光伏发电数据(Data_PV_Gen)插入时，自动将实际发电量
同步到预测表(Data_PV_Forecast)的Actual_Val字段。

【适用范围】
- 自动更新预测表的实际值
- 为预测偏差分析提供数据支持
- 减少人工数据同步工作

【业务规则】
- 只处理逆变器的发电数据（汇流箱不发电）
- 按并网点、日期、小时时段汇总
- 累加到预测表的实际值字段

【触发条件】
- INSERT操作触发（AFTER模式）
*/
-- ============================================================
IF OBJECT_ID('TR_Update_Forecast_Actual', 'TR') IS NOT NULL
    DROP TRIGGER TR_Update_Forecast_Actual;
GO

CREATE TRIGGER TR_Update_Forecast_Actual
ON Data_PV_Gen
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 只处理逆变器的发电数据
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN PV_Device pd ON i.Device_ID = pd.Device_ID
        WHERE pd.Device_Type = N'逆变器'
          AND i.Gen_KWH IS NOT NULL
          AND i.Point_ID IS NOT NULL
    )
    BEGIN
        PRINT N'开始同步发电数据到预测表...';
        
        -- 临时表存储汇总的发电量（按并网点、日期、小时）
        CREATE TABLE #HourlyGeneration (
            Point_ID BIGINT,
            Forecast_Date DATE,
            Time_Slot NVARCHAR(20),
            Total_Gen_KWH DECIMAL(12,3),
            PRIMARY KEY (Point_ID, Forecast_Date, Time_Slot)
        );
        
        -- 汇总5分钟数据到小时级
        INSERT INTO #HourlyGeneration (Point_ID, Forecast_Date, Time_Slot, Total_Gen_KWH)
        SELECT 
            i.Point_ID,
            CONVERT(DATE, i.Collect_Time) AS Forecast_Date,
            -- 将时间转换为小时段格式，如'08:00-09:00'
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) AS NVARCHAR(2)), 2) + ':00-' + 
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) + 1 AS NVARCHAR(2)), 2) + ':00' AS Time_Slot,
            SUM(i.Gen_KWH) AS Total_Gen_KWH
        FROM inserted i
        JOIN PV_Device pd ON i.Device_ID = pd.Device_ID
        WHERE pd.Device_Type = N'逆变器'
          AND i.Gen_KWH IS NOT NULL
          AND i.Point_ID IS NOT NULL
        GROUP BY 
            i.Point_ID, 
            CONVERT(DATE, i.Collect_Time),
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) AS NVARCHAR(2)), 2) + ':00-' + 
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) + 1 AS NVARCHAR(2)), 2) + ':00';
        
        DECLARE @RecordCount INT = (SELECT COUNT(*) FROM #HourlyGeneration);
        PRINT N'汇总了 ' + CAST(@RecordCount AS NVARCHAR(10)) + N' 个时段的发电数据';
        
        IF @RecordCount > 0
        BEGIN
            -- 更新预测表的Actual_Val
            UPDATE f
            SET Actual_Val = ISNULL(f.Actual_Val, 0) + hg.Total_Gen_KWH
            FROM Data_PV_Forecast f
            INNER JOIN #HourlyGeneration hg ON f.Point_ID = hg.Point_ID
                                           AND f.Forecast_Date = hg.Forecast_Date
                                           AND f.Time_Slot = hg.Time_Slot;
            
            DECLARE @UpdatedCount INT = @@ROWCOUNT;
            PRINT N'成功更新了 ' + CAST(@UpdatedCount AS NVARCHAR(10)) + N' 条预测记录的实际值';
        END
        
        DROP TABLE #HourlyGeneration;
    END
END;
GO

PRINT '已创建触发器: TR_Update_Forecast_Actual (发电数据同步预测实际值)';
GO


-- ============================================================
-- 存储过程 3.1: 连续偏差检测 (Check_Continuous_Deviation)
-- ============================================================
/*
【功能描述】
检测连续3天及以上预测偏差率超过15%的情况，
自动生成模型优化告警。

【适用范围】
- 定期检测预测模型准确性
- 识别需要优化的预测模型
- 触发模型重训练流程

【业务规则】
- 按日汇总预测值和实际值
- 计算日偏差率 = (实际值 - 预测值) / 预测值 × 100%
- 连续3天偏差率>15%则生成告警

【调用方式】
- 可由触发器自动调用
- 也可作为定时任务单独调用
*/
-- ============================================================
IF OBJECT_ID('dbo.Check_Continuous_Deviation', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Check_Continuous_Deviation;
GO

CREATE PROCEDURE dbo.Check_Continuous_Deviation
AS
BEGIN
    SET NOCOUNT ON;

    -- 检查PV_Model_Alert表是否存在
    IF OBJECT_ID('dbo.PV_Model_Alert','U') IS NULL
        RETURN;

    ;WITH DailyAgg AS (
        -- 按日汇总预测值和实际值
        SELECT
            d.Point_ID,
            CAST(d.Forecast_Date AS date) AS Forecast_Day,
            d.Model_Version,
            SUM(d.Actual_Val) AS Actual_Day,
            SUM(d.Forecast_Val) AS Forecast_Day_Val
        FROM dbo.Data_PV_Forecast d
        WHERE d.Model_Version IS NOT NULL
          AND d.Forecast_Date IS NOT NULL
          AND d.Actual_Val IS NOT NULL
          AND d.Forecast_Val IS NOT NULL
        GROUP BY d.Point_ID, CAST(d.Forecast_Date AS date), d.Model_Version
    ),
    DeviationDays AS (
        -- 计算每日偏差率，筛选偏差>15%的日期
        SELECT
            Point_ID,
            Forecast_Day,
            Model_Version,
            ((Actual_Day - Forecast_Day_Val) / NULLIF(Forecast_Day_Val, 0.0)) * 100.0 AS Deviation_Rate,
            ROW_NUMBER() OVER (PARTITION BY Point_ID, Model_Version ORDER BY Forecast_Day) AS RowNum
        FROM DailyAgg
        WHERE Forecast_Day_Val <> 0
          AND ABS(((Actual_Day - Forecast_Day_Val) / NULLIF(Forecast_Day_Val, 0.0)) * 100.0) > 15.0
    ),
    ContinuousGroups AS (
        -- 识别连续日期组
        SELECT
            Point_ID,
            Model_Version,
            Forecast_Day,
            DATEADD(DAY, -RowNum, Forecast_Day) AS GroupDate
        FROM DeviationDays
    ),
    ContinuousAlerts AS (
        -- 筛选连续3天及以上的组
        SELECT
            Point_ID,
            Model_Version,
            MIN(Forecast_Day) AS Start_Date,
            MAX(Forecast_Day) AS End_Date,
            COUNT(*) AS Consecutive_Days
        FROM ContinuousGroups
        GROUP BY Point_ID, Model_Version, GroupDate
        HAVING COUNT(*) >= 3
    )
    -- 插入告警记录
    INSERT INTO dbo.PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
    SELECT
        ca.Point_ID,
        CAST(ca.End_Date AS datetime2(0)) AS Trigger_Time,
        CONCAT(
            N'光伏并网点 ', p.Point_Name,
            N' 连续 ', ca.Consecutive_Days, N' 天（',
            CONVERT(nvarchar(10), ca.Start_Date, 23), N' 至 ', CONVERT(nvarchar(10), ca.End_Date, 23),
            N'）日发电与预测偏差率超过15%',
            CHAR(10), N'模型版本: ', ca.Model_Version,
            CHAR(10), N'建议检查并优化预测模型！'
        ),
        N'待处理告警',
        ca.Model_Version
    FROM ContinuousAlerts ca
    JOIN dbo.PV_Grid_Point p ON ca.Point_ID = p.Point_ID
    WHERE NOT EXISTS (
        -- 避免重复告警
        SELECT 1
        FROM dbo.PV_Model_Alert a
        WHERE a.Point_ID = ca.Point_ID
          AND a.Model_Version = ca.Model_Version
          AND a.Remark LIKE N'%连续%天%偏差率超过15%'
          AND DATEDIFF(DAY, a.Trigger_Time, CAST(ca.End_Date AS datetime2(0))) < 3
    );
END;
GO

PRINT '已创建存储过程: Check_Continuous_Deviation (连续偏差检测)';
GO


-- ============================================================
-- 触发器 3.2: 预测偏差告警 (TR_Model_Optimization_Alert)
-- ============================================================
/*
【功能描述】
当预测表(Data_PV_Forecast)的Actual_Val被更新时，
检测偏差率是否超过15%，如超过则生成模型优化告警。

【适用范围】
- 实时监控预测准确性
- 单时段偏差预警
- 触发连续偏差检测

【业务规则】
- 偏差率 = |实际值 - 预测值| / 预测值 × 100%
- 偏差率 > 15% 时生成告警
- 同时触发连续偏差检测存储过程

【触发条件】
- UPDATE Actual_Val字段时触发
*/
-- ============================================================
IF OBJECT_ID('dbo.TR_Model_Optimization_Alert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Model_Optimization_Alert;
GO

CREATE TRIGGER dbo.TR_Model_Optimization_Alert
ON dbo.Data_PV_Forecast
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 只在Actual_Val被更新时触发
    IF NOT UPDATE(Actual_Val)
        RETURN;

    -- 检查PV_Model_Alert表是否存在
    IF OBJECT_ID('dbo.PV_Model_Alert','U') IS NULL
        RETURN;

    -- 插入偏差超过15%的告警
    INSERT INTO dbo.PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
    SELECT
        i.Point_ID,
        CAST(i.Forecast_Date AS datetime2(0)),
        CONCAT(
            N'并网点 ', p.Point_Name, N' 在 ',
            CONVERT(nvarchar(10), i.Forecast_Date, 23), N' ', CONVERT(nvarchar(50), i.Time_Slot),
            N' 时段的预测偏差率超过15%',
            CHAR(10), N'预测值: ', CONVERT(nvarchar(50), i.Forecast_Val), N' kWh',
            CHAR(10), N'实际值: ', CONVERT(nvarchar(50), i.Actual_Val), N' kWh',
            CHAR(10), N'偏差率: ', CONVERT(nvarchar(50),
                ROUND(((i.Actual_Val - i.Forecast_Val) / NULLIF(i.Forecast_Val, 0.0)) * 100.0, 2)
            ), N'%'
        ),
        N'未处理',
        i.Model_Version
    FROM inserted i
    JOIN dbo.PV_Grid_Point p ON i.Point_ID = p.Point_ID
    WHERE i.Actual_Val IS NOT NULL
      AND i.Forecast_Val IS NOT NULL
      AND i.Forecast_Val <> 0
      AND ABS(((i.Actual_Val - i.Forecast_Val) / i.Forecast_Val) * 100.0) > 15.0
      AND NOT EXISTS (
          -- 避免重复告警
          SELECT 1
          FROM dbo.PV_Model_Alert a
          WHERE a.Point_ID = i.Point_ID
            AND a.Model_Version = i.Model_Version
            AND CONVERT(date, a.Trigger_Time) = i.Forecast_Date
            AND a.Remark LIKE '%' + CONVERT(nvarchar(50), i.Time_Slot) + '%'
            AND a.Process_Status IN (N'未处理', N'处理中', N'待处理告警')
      );

    -- 触发连续偏差检测
    IF @@ROWCOUNT > 0
        EXEC dbo.Check_Continuous_Deviation;
END;
GO

PRINT '已创建触发器: TR_Model_Optimization_Alert (预测偏差告警)';
GO


-- ============================================================
-- 触发器 3.3: 逆变器效率检测 (TR_Check_Inverter_Efficiency)
-- ============================================================
/*
【功能描述】
当光伏发电数据插入或更新时，检测逆变器效率是否低于85%，
如低于则：
1. 将设备状态更新为"异常"
2. 生成设备告警记录

【适用范围】
- 逆变器性能监控
- 设备故障预警
- 维护计划触发

【业务规则】
- 效率阈值：85%
- 只检测当前状态为"正常"的逆变器设备
- 同一设备同一天只生成一条告警

【触发条件】
- INSERT, UPDATE操作触发
*/
-- ============================================================
IF OBJECT_ID('dbo.TR_Check_Inverter_Efficiency', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Check_Inverter_Efficiency;
GO

CREATE TRIGGER dbo.TR_Check_Inverter_Efficiency
ON dbo.Data_PV_Gen
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 没有inserted数据直接退出
    IF NOT EXISTS (SELECT 1 FROM inserted) 
        RETURN;

    -- 检查是否存在效率<85%且设备当前为正常的记录
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.PV_Device d ON d.Device_ID = i.Device_ID
        WHERE d.Device_Type = N'逆变器'
          AND i.Inverter_Eff IS NOT NULL
          AND i.Inverter_Eff < 85.0
          AND d.Run_Status = N'正常'
    )
        RETURN;

    -- 收集命中的低效率数据
    IF OBJECT_ID('tempdb..#bad') IS NOT NULL DROP TABLE #bad;

    SELECT DISTINCT
        i.Device_ID,
        i.Collect_Time,
        i.Inverter_Eff,
        d.Ledger_ID,
        d.Point_ID
    INTO #bad
    FROM inserted i
    INNER JOIN dbo.PV_Device d ON d.Device_ID = i.Device_ID
    WHERE d.Device_Type = N'逆变器'
      AND i.Inverter_Eff IS NOT NULL
      AND i.Inverter_Eff < 85.0
      AND d.Run_Status = N'正常';

    IF NOT EXISTS (SELECT 1 FROM #bad)
        RETURN;

    -- 更新设备状态：正常 -> 异常
    UPDATE d
    SET d.Run_Status = N'异常'
    FROM dbo.PV_Device d
    INNER JOIN #bad b ON b.Device_ID = d.Device_ID
    WHERE d.Run_Status = N'正常';

    -- 写入告警记录（同一设备同一天不重复）
    INSERT INTO dbo.Alarm_Info
    (
        Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status,
        Ledger_ID, Factory_ID, Verify_Status, Trigger_Threshold
    )
    SELECT
        N'越限告警' AS Alarm_Type,
        N'中' AS Alarm_Level,
        N'逆变器效率低于85%：Device_ID=' + CAST(b.Device_ID AS NVARCHAR(20)) +
        N'，效率=' + CAST(b.Inverter_Eff AS NVARCHAR(20)) +
        N'% ，采集时间=' + CONVERT(NVARCHAR(19), b.Collect_Time, 120) AS Content,
        ISNULL(b.Collect_Time, SYSDATETIME()) AS Occur_Time,
        N'未处理' AS Process_Status,
        b.Ledger_ID,
        NULL AS Factory_ID,
        N'待审核' AS Verify_Status,
        CAST(85.0 AS DECIMAL(12,3)) AS Trigger_Threshold
    FROM #bad b
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Alarm_Info a
        WHERE a.Ledger_ID = b.Ledger_ID
          AND a.Alarm_Type = N'越限告警'
          AND a.Content LIKE N'%逆变器效率低于85%%'
          AND CONVERT(date, a.Occur_Time) = CONVERT(date, ISNULL(b.Collect_Time, SYSDATETIME()))
    );
END;
GO

PRINT '已创建触发器: TR_Check_Inverter_Efficiency (逆变器效率检测)';
GO


/* ############################################################
   ##                                                        ##
   ##          第四部分：告警运维管理业务线                    ##
   ##          负责人：李振梁                                  ##
   ##                                                        ##
   ############################################################
   
   【业务背景】
   告警运维管理业务线负责告警派单、工单管理、运维人员调度，
   实现告警从产生到结案的全流程闭环管理。
   
   【存储过程设计】
   - SP_Alarm_Dispatch_WorkOrder: 告警派单（生成/更新工单 + 写日志 + 更新告警状态）
   
   【触发器设计】
   - TR_WorkOrder_SyncAlarmAndLog: 工单状态同步触发器
   
   【特点说明】
   该业务线既支持“手动派单”（存储过程），也支持“工单表变更自动联动”（触发器），
   两者共同保证告警从产生到结案的流程闭环与审计留痕。
   ============================================================ */


-- ============================================================
-- 存储过程 4.0: 告警派单存储过程 (SP_Alarm_Dispatch_WorkOrder)
-- ============================================================
/*
【功能描述】
对指定告警(Alarm_ID)进行派单操作，自动完成：
1. 若已存在工单：更新工单(Work_Order)的派单信息（调度员/运维员/台账/派单时间）
2. 若不存在工单：创建新工单
3. 同步更新告警表(Alarm_Info)状态为"处理中"
4. 写入处理日志(Alarm_Handling_Log)用于审计与追溯

【适用范围】
- 调度员手动派单入口
- 工单重派/改派
- 需要在写入工单前做业务校验的场景

【业务规则】
- 若告警已结案：禁止派单
- 派单成功后：告警状态置为"处理中"
- 每次派单均写入一条"处理中"日志

【输入参数】
- @Alarm_ID      : 告警ID（必填）
- @Dispatcher_ID : 调度员角色ID（必填）
- @OandM_ID      : 运维人员角色ID（必填）
- @Ledger_ID     : 设备台账ID（可选）
- @Dispatch_Time : 派单时间（可选，默认当前系统时间）

【输出】
- 返回该告警对应的最新工单记录（TOP 1）
*/
-- ============================================================
IF OBJECT_ID('dbo.SP_Alarm_Dispatch_WorkOrder', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_Alarm_Dispatch_WorkOrder;
GO

CREATE PROCEDURE dbo.SP_Alarm_Dispatch_WorkOrder
    @Alarm_ID       BIGINT,
    @Dispatcher_ID  BIGINT,
    @OandM_ID       BIGINT,
    @Ledger_ID      BIGINT       = NULL,
    @Dispatch_Time  DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Dispatch_Time = COALESCE(@Dispatch_Time, SYSDATETIME());

    -- 1) 告警存在性校验
    IF NOT EXISTS (SELECT 1 FROM dbo.Alarm_Info WHERE Alarm_ID = @Alarm_ID)
    BEGIN
        RAISERROR(N'告警不存在：Alarm_ID=%d', 16, 1, @Alarm_ID);
        RETURN;
    END

    -- 2) 告警状态校验：已结案禁止派单
    IF EXISTS (SELECT 1 FROM dbo.Alarm_Info WHERE Alarm_ID = @Alarm_ID AND Process_Status = N'已结案')
    BEGIN
        RAISERROR(N'告警已结案，不能派单：Alarm_ID=%d', 16, 1, @Alarm_ID);
        RETURN;
    END

    BEGIN TRAN;

        -- 3) 工单存在则更新，不存在则新增
        IF EXISTS (SELECT 1 FROM dbo.Work_Order WHERE Alarm_ID = @Alarm_ID)
        BEGIN
            UPDATE dbo.Work_Order
            SET
                Dispatcher_ID = @Dispatcher_ID,
                OandM_ID      = @OandM_ID,
                Ledger_ID     = COALESCE(@Ledger_ID, Ledger_ID),
                Dispatch_Time = COALESCE(Dispatch_Time, @Dispatch_Time)
            WHERE Alarm_ID = @Alarm_ID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Work_Order
            (Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Review_Status)
            VALUES
            (@Alarm_ID, @OandM_ID, @Dispatcher_ID, @Ledger_ID, @Dispatch_Time, NULL);
        END

        -- 4) 告警状态置为"处理中"
        UPDATE dbo.Alarm_Info
        SET Process_Status = N'处理中'
        WHERE Alarm_ID = @Alarm_ID
          AND Process_Status <> N'已结案';

        -- 5) 写处理日志（派单日志）
        INSERT INTO dbo.Alarm_Handling_Log
        (Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
        VALUES
        (@Alarm_ID, @Dispatch_Time, N'处理中', @OandM_ID, @Dispatcher_ID);

    COMMIT;

    -- 6) 返回该告警对应的最新工单信息
    SELECT TOP (1)
        w.Order_ID, w.Alarm_ID, w.OandM_ID, w.Dispatcher_ID, w.Ledger_ID,
        w.Dispatch_Time, w.Response_Time, w.Finish_Time, w.Review_Status
    FROM dbo.Work_Order w
    WHERE w.Alarm_ID = @Alarm_ID
    ORDER BY w.Order_ID DESC;
END;
GO

PRINT '已创建存储过程: SP_Alarm_Dispatch_WorkOrder (告警派单)';
GO


-- ============================================================
-- 触发器 4.1: 工单状态同步触发器 (TR_WorkOrder_SyncAlarmAndLog)
-- ============================================================
/*
【功能描述】
当工单表(Work_Order)发生变更时，自动执行以下操作：
1. 同步更新告警表(Alarm_Info)的处理状态
2. 记录派单日志到处理日志表(Alarm_Handling_Log)
3. 记录结案日志

【适用范围】
- 告警处理流程自动化
- 状态变更追踪
- 审计日志记录

【业务规则】
- 派单后：告警状态从"未处理"变为"处理中"
- 完成并审核通过后：告警状态变为"已结案"
- 每次状态变更都记录日志

【触发条件】
- INSERT, UPDATE操作触发
*/
-- ============================================================
IF OBJECT_ID('dbo.TR_WorkOrder_SyncAlarmAndLog', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_WorkOrder_SyncAlarmAndLog;
GO

CREATE TRIGGER dbo.TR_WorkOrder_SyncAlarmAndLog
ON dbo.Work_Order
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 定义表变量，暂存变更数据
    DECLARE @Changes TABLE (
        Order_ID BIGINT,
        Alarm_ID BIGINT,
        OandM_ID BIGINT,
        Dispatcher_ID BIGINT,
        Dispatch_Time DATETIME2(0),
        Finish_Time DATETIME2(0),
        Review_Status NVARCHAR(10),
        Old_Dispatch_Time DATETIME2(0),
        Old_Finish_Time DATETIME2(0),
        Old_Review_Status NVARCHAR(10)
    );

    -- 将inserted和deleted的对比结果写入表变量
    INSERT INTO @Changes
    SELECT
        i.Order_ID,
        i.Alarm_ID,
        i.OandM_ID,
        i.Dispatcher_ID,
        i.Dispatch_Time,
        i.Finish_Time,
        i.Review_Status,
        d.Dispatch_Time,
        d.Finish_Time,
        d.Review_Status
    FROM inserted i
    LEFT JOIN deleted d ON i.Order_ID = d.Order_ID
    WHERE i.Alarm_ID IS NOT NULL;

    -- 1. 同步Alarm_Info.Process_Status
    UPDATE a
    SET a.Process_Status =
        CASE
            WHEN c.Finish_Time IS NOT NULL AND c.Review_Status = N'通过' THEN N'已结案'
            WHEN c.Dispatch_Time IS NOT NULL AND a.Process_Status = N'未处理' THEN N'处理中'
            ELSE a.Process_Status
        END
    FROM dbo.Alarm_Info a
    JOIN @Changes c ON a.Alarm_ID = c.Alarm_ID
    WHERE
        (c.Finish_Time IS NOT NULL AND c.Review_Status = N'通过' AND a.Process_Status <> N'已结案')
        OR
        (c.Dispatch_Time IS NOT NULL AND a.Process_Status = N'未处理');

    -- 2. 记录派单日志
    INSERT INTO dbo.Alarm_Handling_Log (Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
    SELECT
        c.Alarm_ID,
        c.Dispatch_Time,
        N'处理中',
        c.OandM_ID,
        CASE WHEN EXISTS (SELECT 1 FROM dbo.Role_Dispatcher rd WHERE rd.Dispatcher_ID = c.Dispatcher_ID)
             THEN c.Dispatcher_ID ELSE NULL END
    FROM @Changes c
    WHERE c.Dispatch_Time IS NOT NULL
      AND (c.Old_Dispatch_Time IS NULL)
      AND NOT EXISTS (
            SELECT 1 FROM dbo.Alarm_Handling_Log l
            WHERE l.Alarm_ID = c.Alarm_ID AND l.Status_After = N'处理中'
      );

    -- 3. 记录结案日志
    INSERT INTO dbo.Alarm_Handling_Log (Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID)
    SELECT
        c.Alarm_ID,
        ISNULL(c.Finish_Time, SYSDATETIME()),
        N'已结案',
        c.OandM_ID,
        CASE WHEN EXISTS (SELECT 1 FROM dbo.Role_Dispatcher rd WHERE rd.Dispatcher_ID = c.Dispatcher_ID)
             THEN c.Dispatcher_ID ELSE NULL END
    FROM @Changes c
    WHERE c.Finish_Time IS NOT NULL
      AND c.Review_Status = N'通过'
      AND (
            c.Old_Finish_Time IS NULL
         OR ISNULL(c.Old_Review_Status, N'') <> N'通过'
      )
      AND NOT EXISTS (
            SELECT 1 FROM dbo.Alarm_Handling_Log l
            WHERE l.Alarm_ID = c.Alarm_ID AND l.Status_After = N'已结案'
      );
END;
GO

PRINT '已创建触发器: TR_WorkOrder_SyncAlarmAndLog (工单状态同步)';
GO



/* ############################################################
   ##                                                        ##
   ##          第五部分：大屏数据展示业务线                    ##
   ##          负责人：杨尧天                                  ##
   ##                                                        ##
   ############################################################
   
   【业务背景】
   大屏数据展示业务线负责实时汇总各业务数据，
   为管理层大屏提供统一的数据源。
   
   【存储过程设计】
   - SP_Exec_Refresh_Realtime_Stat: 刷新并写入实时汇总（Stat_Realtime）
   
   【触发器设计】
   - TRG_StatRealtime_ConsumptionSpike: 用电量突增告警触发器
   
   【特点说明】
   该业务线通过存储过程生成“实时汇总快照”，并通过触发器监控异常波动，
   形成“汇总-监控-告警”的闭环。
   ============================================================ */


-- ============================================================
-- 存储过程 5.0: 刷新并写入实时汇总 (SP_Exec_Refresh_Realtime_Stat)
-- ============================================================
/*
【功能描述】
汇总当日多源业务数据，写入实时统计表(Stat_Realtime)，并返回本次写入结果：
1. 用电量汇总：来自日峰谷统计(Data_PeakValley，Energy_Type='电')
2. 光伏发电量：来自光伏发电采集(Data_PV_Gen)
3. 水/蒸汽/天然气：来自综合能耗采集(Data_Energy + Energy_Meter)
4. 告警统计：来自告警表(Alarm_Info)，统计当日告警数量及等级/未处理数量

【适用范围】
- 大屏实时数据刷新
- 统一汇总口径输出
- 支持按工厂/配置维度筛选（可选）

【业务规则】
- @Stat_Time 默认取当前系统时间
- Summary_ID = yyyyMMddHHmmss（由@Stat_Time生成）
- 若未传@Config_ID，则默认取Dashboard_Config中的第一条配置

【输入参数】
- @Config_ID  : 大屏配置ID（可选）
- @Factory_ID : 工厂ID（可选）
- @Stat_Time  : 统计时间（可选，默认当前系统时间）

【输出】
- 返回本次写入的Stat_Realtime记录
*/
-- ============================================================
IF OBJECT_ID('dbo.SP_Exec_Refresh_Realtime_Stat', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_Exec_Refresh_Realtime_Stat;
GO

CREATE PROCEDURE dbo.SP_Exec_Refresh_Realtime_Stat
    @Config_ID  BIGINT       = NULL,
    @Factory_ID BIGINT       = NULL,
    @Stat_Time  DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Stat_Time = COALESCE(@Stat_Time, SYSDATETIME());

    DECLARE @DayStart DATETIME2(0) = DATEADD(DAY, DATEDIFF(DAY, 0, @Stat_Time), 0);
    DECLARE @DayEnd   DATETIME2(0) = DATEADD(DAY, 1, @DayStart);

    -- 若未指定配置，则默认取第一条大屏配置
    IF @Config_ID IS NULL
        SELECT TOP (1) @Config_ID = c.Config_ID
        FROM dbo.Dashboard_Config c
        ORDER BY c.Config_ID;

    -- Summary_ID = yyyyMMddHHmmss
    DECLARE @Summary_ID NVARCHAR(20) =
        CONVERT(CHAR(8), @Stat_Time, 112) + REPLACE(CONVERT(CHAR(8), @Stat_Time, 108), ':', '');

    DECLARE
        @Total_KWH           DECIMAL(12,3) = NULL,
        @PV_Gen_KWH          DECIMAL(12,3) = NULL,
        @Total_Water_m3      DECIMAL(12,3) = NULL,
        @Total_Steam_t       DECIMAL(12,3) = NULL,
        @Total_Gas_m3        DECIMAL(12,3) = NULL,
        @Total_Alarm         INT           = 0,
        @Alarm_High          INT           = 0,
        @Alarm_Mid           INT           = 0,
        @Alarm_Low           INT           = 0,
        @Alarm_Unprocessed   INT           = 0;

    /* 1) 总用电量：优先取峰谷统计（Energy_Type='电'） */
    SELECT
        @Total_KWH = SUM(pv.Total_Consumption)
    FROM dbo.Data_PeakValley pv
    WHERE pv.Stat_Date = CONVERT(date, @Stat_Time)
      AND ( @Factory_ID IS NULL OR pv.Factory_ID = @Factory_ID )
      AND pv.Energy_Type = N'电';

    /* 2) 光伏发电量：取当天累计（若光伏表存在） */
    IF OBJECT_ID('dbo.Data_PV_Gen','U') IS NOT NULL
    BEGIN
        SELECT
            @PV_Gen_KWH = SUM(g.Gen_KWH)
        FROM dbo.Data_PV_Gen g
        WHERE g.Collect_Time >= @DayStart
          AND g.Collect_Time <  @DayEnd
          AND ( @Factory_ID IS NULL OR g.Factory_ID = @Factory_ID );
    END

    /* 3) 水/蒸汽/天然气：取当天累计（Data_Energy + Energy_Meter） */
    SELECT
        @Total_Water_m3 = SUM(CASE WHEN m.Energy_Type = N'水'     THEN e.Value ELSE 0 END),
        @Total_Steam_t  = SUM(CASE WHEN m.Energy_Type = N'蒸汽'   THEN e.Value ELSE 0 END),
        @Total_Gas_m3   = SUM(CASE WHEN m.Energy_Type = N'天然气' THEN e.Value ELSE 0 END)
    FROM dbo.Data_Energy e
    JOIN dbo.Energy_Meter m ON e.Meter_ID = m.Meter_ID
    WHERE e.Collect_Time >= @DayStart
      AND e.Collect_Time <  @DayEnd
      AND ( @Factory_ID IS NULL OR e.Factory_ID = @Factory_ID );

    /* 4) 告警统计：当天累计（若存在告警表） */
    IF OBJECT_ID('dbo.Alarm_Info','U') IS NOT NULL
    BEGIN
        SELECT
            @Total_Alarm       = COUNT(*),
            @Alarm_High        = SUM(CASE WHEN a.Alarm_Level = N'高' THEN 1 ELSE 0 END),
            @Alarm_Mid         = SUM(CASE WHEN a.Alarm_Level = N'中' THEN 1 ELSE 0 END),
            @Alarm_Low         = SUM(CASE WHEN a.Alarm_Level = N'低' THEN 1 ELSE 0 END),
            @Alarm_Unprocessed = SUM(CASE WHEN a.Process_Status = N'未处理' THEN 1 ELSE 0 END)
        FROM dbo.Alarm_Info a
        WHERE a.Occur_Time >= @DayStart
          AND a.Occur_Time <  @DayEnd
          AND ( @Factory_ID IS NULL OR a.Factory_ID = @Factory_ID );
    END

    /* 5) 写入实时统计表并返回本次结果 */
    INSERT INTO dbo.Stat_Realtime
    (Summary_ID, Stat_Time, Total_KWH, Total_Alarm, PV_Gen_KWH, Config_ID,
     Total_Water_m3, Total_Steam_t, Total_Gas_m3,
     Alarm_High, Alarm_Mid, Alarm_Low, Alarm_Unprocessed)
    VALUES
    (@Summary_ID, @Stat_Time, @Total_KWH, @Total_Alarm, @PV_Gen_KWH, @Config_ID,
     @Total_Water_m3, @Total_Steam_t, @Total_Gas_m3,
     @Alarm_High, @Alarm_Mid, @Alarm_Low, @Alarm_Unprocessed);

    SELECT *
    FROM dbo.Stat_Realtime
    WHERE Summary_ID = @Summary_ID;
END;
GO

PRINT '已创建存储过程: SP_Exec_Refresh_Realtime_Stat (实时汇总刷新)';
GO


-- ============================================================
-- 触发器 5.1: 用电量突增告警 (TRG_StatRealtime_ConsumptionSpike)
-- ============================================================
/*
【功能描述】
当实时统计表(Stat_Realtime)插入新数据时，检测总用电量
是否比上一周期环比上升超过15%，如超过则生成告警。

【适用范围】
- 异常用电监控
- 用能突增预警
- 节能管理支持

【业务规则】
- 环比上升率 = (当前值 - 上一周期值) / 上一周期值 × 100%
- 上升率 > 15% 时生成中等级告警
- 上升率 > 30% 时生成高等级告警

【触发条件】
- INSERT操作触发
*/
-- ============================================================
IF OBJECT_ID('dbo.TRG_StatRealtime_ConsumptionSpike', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_StatRealtime_ConsumptionSpike;
GO

-- 检查Alarm_Info表是否存在
IF OBJECT_ID('dbo.Alarm_Info','U') IS NOT NULL
BEGIN
    EXEC(N'
        CREATE TRIGGER dbo.TRG_StatRealtime_ConsumptionSpike
        ON dbo.Stat_Realtime
        AFTER INSERT
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH ins AS (
                SELECT
                    i.Summary_ID,
                    i.Stat_Time,
                    i.Total_KWH,
                    i.Config_ID
                FROM inserted i
                WHERE i.Total_KWH IS NOT NULL
                  AND i.Stat_Time IS NOT NULL
            ),
            prev AS (
                SELECT
                    ins.Summary_ID,
                    ins.Stat_Time,
                    ins.Total_KWH AS Cur_KWH,
                    p.Prev_KWH
                FROM ins
                OUTER APPLY (
                    SELECT TOP 1 r.Total_KWH AS Prev_KWH
                    FROM dbo.Stat_Realtime r
                    WHERE
                        (
                            (r.Config_ID = ins.Config_ID)
                            OR (r.Config_ID IS NULL AND ins.Config_ID IS NULL)
                        )
                        AND r.Stat_Time < ins.Stat_Time
                        AND r.Total_KWH IS NOT NULL
                    ORDER BY r.Stat_Time DESC
                ) p
            ),
            spike AS (
                SELECT
                    Summary_ID,
                    Stat_Time,
                    Cur_KWH,
                    Prev_KWH,
                    CASE
                        WHEN Prev_KWH IS NULL OR Prev_KWH = 0 THEN NULL
                        ELSE (Cur_KWH - Prev_KWH) / NULLIF(Prev_KWH, 0)
                    END AS RiseRate
                FROM prev
            )
            INSERT INTO dbo.Alarm_Info
                (Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Ledger_ID, Factory_ID)
            SELECT
                N''其他'' AS Alarm_Type,
                CASE WHEN s.RiseRate > 0.30 THEN N''高'' ELSE N''中'' END AS Alarm_Level,
                CONCAT(
                    N''总用电量突增：当前 '', CONVERT(NVARCHAR(30), s.Cur_KWH), N'' kWh；上一周期 '',
                    CONVERT(NVARCHAR(30), s.Prev_KWH), N'' kWh；上升 '',
                    CONVERT(NVARCHAR(10), CAST(s.RiseRate*100 AS DECIMAL(6,2))), N''%（Summary_ID='',
                    s.Summary_ID, N''）''
                ) AS Content,
                s.Stat_Time AS Occur_Time,
                N''未处理'' AS Process_Status,
                NULL AS Ledger_ID,
                NULL AS Factory_ID
            FROM spike s
            WHERE s.RiseRate IS NOT NULL AND s.RiseRate > 0.15;
        END
    ');
    PRINT '已创建触发器: TRG_StatRealtime_ConsumptionSpike (用电量突增告警)';
END
ELSE
BEGIN
    PRINT '跳过触发器创建: TRG_StatRealtime_ConsumptionSpike (Alarm_Info表不存在)';
END
GO


/* ============================================================
   存储过程和触发器汇总信息
   ============================================================
   
   本DDL汇总共包含 8个触发器 和 3个存储过程，按业务线分布如下：
   
   1. 配电网监测业务线：2个触发器 + 1个存储过程
      - TR_Transformer_Analyze (变压器数据分析触发器)
        适用：变压器温度实时监控和异常告警
      - TR_Circuit_Analyze (回路数据分析触发器)
        适用：回路电压监控、设备离线检测
      - SP_PowerGrid_Analysis (配电网综合分析存储过程)
        适用：设备健康分析、异常统计、能耗分析、数据完整性检查
   
   2. 综合能耗管理业务线：1个触发器 + 1个存储过程
      - TRG_Energy_Quality_Check (能耗数据质量检测触发器)
        适用：能耗数据波动监控、数据质量自动标记
      - SP_Calculate_Daily_PeakValley (日度峰谷能耗统计存储过程)
        适用：日终峰谷能耗汇总、成本计算
   
   3. 分布式光伏管理业务线：3个触发器 + 1个存储过程
      - TR_Update_Forecast_Actual (发电数据同步预测实际值触发器)
        适用：自动更新预测表实际值
      - TR_Model_Optimization_Alert (预测偏差告警触发器)
        适用：单时段预测偏差监控
      - TR_Check_Inverter_Efficiency (逆变器效率检测触发器)
        适用：逆变器性能监控、故障预警
      - Check_Continuous_Deviation (连续偏差检测存储过程)
        适用：连续多天预测偏差检测、模型优化告警
   
   4. 告警运维管理业务线：1个触发器
      - TR_WorkOrder_SyncAlarmAndLog (工单状态同步触发器)
        适用：告警处理流程自动化、状态追踪、审计日志
   
   5. 大屏数据展示业务线：1个触发器
      - TRG_StatRealtime_ConsumptionSpike (用电量突增告警触发器)
        适用：异常用电监控、用能突增预警
   
   触发器类型统计：
   - INSTEAD OF INSERT: 2个（配电网数据插入控制）
   - AFTER INSERT: 3个（数据同步和告警生成）
   - AFTER INSERT, UPDATE: 2个（状态变更监控）
   - AFTER UPDATE: 1个（预测偏差检测）
   
   ============================================================ */


PRINT N'============================================================';
PRINT N'智慧能源管理系统 数据库存储过程和触发器DDL汇总 执行完成';
PRINT N'共创建 8 个触发器 + 3 个存储过程，涵盖5个业务模块';
PRINT N'============================================================';
GO
