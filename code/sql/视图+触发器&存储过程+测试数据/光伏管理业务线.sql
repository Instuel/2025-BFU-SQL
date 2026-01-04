/* ============================================================
   Part 2: 构建视图
   ============================================================ */

-- 光伏日发电量视图 (Daily PV Generation View)
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

-- 光伏预测偏差视图 (PV Forecast Deviation View)
IF OBJECT_ID('PV_Forecast_Deviation', 'V') IS NOT NULL
    DROP VIEW PV_Forecast_Deviation;
GO

CREATE VIEW PV_Forecast_Deviation AS
SELECT
    p.Point_Name,
    f.Forecast_Date,
    f.Time_Slot,
    f.Forecast_Val,
    f.Actual_Val,
    ((f.Actual_Val - f.Forecast_Val) / NULLIF(f.Forecast_Val, 0)) * 100 AS Deviation_Percentage
FROM Data_PV_Forecast f
JOIN PV_Grid_Point p ON f.Point_ID = p.Point_ID
WHERE ABS((f.Actual_Val - f.Forecast_Val) / NULLIF(f.Forecast_Val, 0)) > 0.15;
GO

-- 设备效率低于 85% 的设备视图 (Devices with Efficiency Below 85%)
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
WHERE d.Device_Type = '逆变器'
GROUP BY dl.Device_Name, d.Device_Type, p.Point_Name
HAVING AVG(g.Inverter_Eff) < 85;
GO

PRINT 'Part 2: 视图创建完成';
GO

/* ============================================================
   Part 3: 构建触发器
   ============================================================ */

-- 触发器1：当发电数据插入时，自动更新预测表的实际值并计算偏差率
IF OBJECT_ID('TR_Update_Forecast_Actual', 'TR') IS NOT NULL
    DROP TRIGGER TR_Update_Forecast_Actual;
GO

CREATE TRIGGER TR_Update_Forecast_Actual
ON Data_PV_Gen
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 只处理逆变器的发电数据（汇流箱没有发电量）
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN PV_Device pd ON i.Device_ID = pd.Device_ID
        WHERE pd.Device_Type = '逆变器'
          AND i.Gen_KWH IS NOT NULL
          AND i.Point_ID IS NOT NULL
    )
    BEGIN
        PRINT '开始同步发电数据到预测表...';
        
        -- 临时表存储汇总的发电量（按并网点、日期、小时）
        CREATE TABLE #HourlyGeneration (
            Point_ID BIGINT,
            Forecast_Date DATE,
            Time_Slot NVARCHAR(20),
            Total_Gen_KWH DECIMAL(12,3),
            PRIMARY KEY (Point_ID, Forecast_Date, Time_Slot)
        );
        
        -- 汇总5分钟数据到小时段
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
        WHERE pd.Device_Type = '逆变器'
          AND i.Gen_KWH IS NOT NULL
          AND i.Point_ID IS NOT NULL
        GROUP BY 
            i.Point_ID, 
            CONVERT(DATE, i.Collect_Time),
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) AS NVARCHAR(2)), 2) + ':00-' + 
            RIGHT('0' + CAST(DATEPART(HOUR, i.Collect_Time) + 1 AS NVARCHAR(2)), 2) + ':00';
        
        -- 统计信息
        DECLARE @RecordCount INT = (SELECT COUNT(*) FROM #HourlyGeneration);
        PRINT '汇总了 ' + CAST(@RecordCount AS NVARCHAR(10)) + ' 个时段的发电数据';
        
        IF @RecordCount > 0
        BEGIN
            -- 更新预测表的Actual_Val
            UPDATE f
            SET 
                Actual_Val = ISNULL(f.Actual_Val, 0) + hg.Total_Gen_KWH
            FROM Data_PV_Forecast f
            INNER JOIN #HourlyGeneration hg ON f.Point_ID = hg.Point_ID
                                           AND f.Forecast_Date = hg.Forecast_Date
                                           AND f.Time_Slot = hg.Time_Slot;
            
            DECLARE @UpdatedCount INT = @@ROWCOUNT;
            PRINT '成功更新了 ' + CAST(@UpdatedCount AS NVARCHAR(10)) + ' 条预测记录的实际值';
        END
        
        DROP TABLE #HourlyGeneration;
    END
    ELSE
    BEGIN
        PRINT '没有需要同步的逆变器发电数据';
    END
END;
GO

-- 存储过程：检查连续3天偏差率超15%（先创建，因为触发器依赖它）
IF OBJECT_ID('Check_Continuous_Deviation', 'P') IS NOT NULL
    DROP PROCEDURE Check_Continuous_Deviation;
GO

CREATE PROCEDURE Check_Continuous_Deviation
AS
BEGIN
    SET NOCOUNT ON;

    -- 如果不存在 PV_Model_Alert 表，直接返回
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PV_Model_Alert')
        RETURN;

    WITH DailyAgg AS (
        SELECT
            d.Point_ID,
            CAST(d.Forecast_Date AS date) AS Forecast_Day,
            d.Model_Version,
            SUM(CASE WHEN d.Actual_Val   IS NOT NULL THEN d.Actual_Val   ELSE 0 END) AS Actual_Day,
            SUM(CASE WHEN d.Forecast_Val IS NOT NULL THEN d.Forecast_Val ELSE 0 END) AS Forecast_Day_Val,
            SUM(CASE WHEN d.Actual_Val   IS NOT NULL THEN 1 ELSE 0 END) AS Actual_Cnt,
            SUM(CASE WHEN d.Forecast_Val IS NOT NULL THEN 1 ELSE 0 END) AS Forecast_Cnt
        FROM Data_PV_Forecast d
        WHERE d.Model_Version IS NOT NULL
          AND d.Forecast_Date IS NOT NULL
          AND d.Actual_Val IS NOT NULL
          AND d.Forecast_Val IS NOT NULL
        GROUP BY
            d.Point_ID,
            CAST(d.Forecast_Date AS date),
            d.Model_Version
    ),
    DeviationDays AS (
        SELECT
            Point_ID,
            Forecast_Day,
            Model_Version,
            CASE
                WHEN Forecast_Day_Val IS NOT NULL
                THEN ((Actual_Day - Forecast_Day_Val) / NULLIF(Forecast_Day_Val, 0.0)) * 100.0
                ELSE NULL
            END AS Deviation_Rate,
            ROW_NUMBER() OVER (PARTITION BY Point_ID, Model_Version ORDER BY Forecast_Day) AS RowNum
        FROM DailyAgg
        WHERE Forecast_Day_Val IS NOT NULL
          AND Forecast_Day_Val <> 0
          AND ABS(((Actual_Day - Forecast_Day_Val) / NULLIF(Forecast_Day_Val, 0.0)) * 100.0) > 15.0
    ),
    ContinuousGroups AS (
        SELECT
            Point_ID,
            Model_Version,
            Forecast_Day,
            RowNum,
            DATEADD(DAY, -RowNum, Forecast_Day) AS GroupDate
        FROM DeviationDays
    ),
    ContinuousAlerts AS (
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
    INSERT INTO PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
    SELECT
        ca.Point_ID,
        GETDATE() AS Trigger_Time,
        N'紧急：并网点 ' + p.Point_Name +
        N' 连续 ' + CAST(ca.Consecutive_Days AS NVARCHAR(10)) +
        N' 天（' + CONVERT(NVARCHAR(10), ca.Start_Date, 23) + N' 至 ' +
        CONVERT(NVARCHAR(10), ca.End_Date, 23) + N'）日汇总预测偏差率超过15%' +
        CHAR(10) + N'模型版本: ' + ca.Model_Version +
        CHAR(10) + N'建议立即优化预测模型！',
        N'紧急处理' AS Process_Status,
        ca.Model_Version
    FROM ContinuousAlerts ca
    INNER JOIN PV_Grid_Point p ON ca.Point_ID = p.Point_ID
    WHERE NOT EXISTS (
        SELECT 1
        FROM PV_Model_Alert a
        WHERE a.Point_ID = ca.Point_ID
          AND a.Model_Version = ca.Model_Version
          AND a.Remark LIKE N'%连续%天%预测偏差率%15%%'
          AND DATEDIFF(DAY, a.Trigger_Time, GETDATE()) < 3
    );

    DECLARE @ContinuousCount INT = @@ROWCOUNT;

    IF @ContinuousCount > 0
    BEGIN
        PRINT N'发现 ' + CAST(@ContinuousCount AS NVARCHAR(10)) + N' 个并网点连续3天以上偏差率超15%';
    END
END;
GO

PRINT 'Check_Continuous_Deviation 创建完成';
GO

-- 触发器2：当预测数据更新且偏差率超15%时，触发模型优化提醒
IF OBJECT_ID('TR_Model_Optimization_Alert', 'TR') IS NOT NULL
    DROP TRIGGER TR_Model_Optimization_Alert;
GO

CREATE TRIGGER TR_Model_Optimization_Alert
ON Data_PV_Forecast
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 只处理Actual_Val被更新的记录（从NULL变为有值）
    IF UPDATE(Actual_Val)
    BEGIN
        PRINT '开始检查预测偏差率...';
        
        -- 如果不存在 PV_Model_Alert 表，直接返回
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PV_Model_Alert')
            RETURN;
            
        -- 查找偏差率超过15%的新记录
        INSERT INTO PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
        SELECT 
            i.Point_ID,
            GETDATE() AS Trigger_Time,
            '并网点 ' + p.Point_Name + ' 在 ' + CONVERT(NVARCHAR(10), i.Forecast_Date) + 
            ' ' + i.Time_Slot + ' 时段的预测偏差率超过15%' + 
            CHAR(10) + '预测值: ' + CAST(i.Forecast_Val AS NVARCHAR(20)) + ' kWh' +
            CHAR(10) + '实际值: ' + CAST(i.Actual_Val AS NVARCHAR(20)) + ' kWh' +
            CHAR(10) + '偏差率: ' + 
            CAST(ROUND(
                CASE 
                    WHEN i.Actual_Val IS NOT NULL AND i.Forecast_Val IS NOT NULL 
                    THEN ((i.Actual_Val - i.Forecast_Val) / NULLIF(i.Forecast_Val, 0)) * 100
                    ELSE NULL 
                END, 2) AS NVARCHAR(20)) + '%',
            '未处理' AS Process_Status,
            i.Model_Version
        FROM inserted i
        INNER JOIN PV_Grid_Point p ON i.Point_ID = p.Point_ID
        WHERE i.Actual_Val IS NOT NULL
          AND i.Forecast_Val IS NOT NULL
          AND ABS(
                CASE 
                    WHEN i.Actual_Val IS NOT NULL AND i.Forecast_Val IS NOT NULL 
                    THEN ((i.Actual_Val - i.Forecast_Val) / NULLIF(i.Forecast_Val, 0)) * 100
                    ELSE NULL 
                END
              ) > 15
          -- 避免重复告警
          AND NOT EXISTS (
              SELECT 1 FROM PV_Model_Alert a
              WHERE a.Point_ID = i.Point_ID
                AND a.Model_Version = i.Model_Version
                AND CONVERT(DATE, a.Trigger_Time) = i.Forecast_Date
                AND a.Remark LIKE '%' + i.Time_Slot + '%'
                AND a.Process_Status IN ('未处理', '处理中')
          );
        
        DECLARE @AlertCount INT = @@ROWCOUNT;
        
        IF @AlertCount > 0
        BEGIN
            PRINT '已生成 ' + CAST(@AlertCount AS NVARCHAR(10)) + ' 条模型优化提醒';
            
            -- 检查连续3天偏差率超15%的情况
            EXEC Check_Continuous_Deviation;
        END
        ELSE
        BEGIN
            PRINT '没有发现偏差率超过15%的记录';
        END
    END
END;
GO

-- 触发器3：在插入或更新发电数据时实时检查逆变器效率
/* ============================================================
   修复：先确保 PV_Device 表有 Last_Update_Time 字段
   ============================================================ */
IF COL_LENGTH('PV_Device', 'Last_Update_Time') IS NULL
BEGIN
    ALTER TABLE PV_Device
    ADD Last_Update_Time DATETIME NULL DEFAULT GETDATE();
    PRINT '已自动为 PV_Device 表补全 Last_Update_Time 字段';
END
GO

/* ============================================================
   触发器3：在插入或更新发电数据时实时检查逆变器效率
   ============================================================ */
IF OBJECT_ID('TR_Check_Inverter_Efficiency', 'TR') IS NOT NULL
    DROP TRIGGER TR_Check_Inverter_Efficiency;
GO

CREATE TRIGGER TR_Check_Inverter_Efficiency
ON Data_PV_Gen
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UpdatedCount INT = 0;
    
    -- 1. 基础检查：是否有数据插入
    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;
    
    -- 2. 核心逻辑：检查效率 < 85% 且状态正常的逆变器
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN PV_Device d ON i.Device_ID = d.Device_ID
        WHERE d.Device_Type = '逆变器'
          AND i.Inverter_Eff < 85.00
          AND d.Run_Status = '正常'
    )
    BEGIN
        -- 3. 执行更新：标记为异常，并更新时间
        -- 注意：此处不再需要 CASE 判断，因为上方已确保列存在
        UPDATE PV_Device
        SET Run_Status = '异常',
            Last_Update_Time = GETDATE() 
        FROM PV_Device d
        INNER JOIN inserted i ON d.Device_ID = i.Device_ID
        WHERE d.Device_Type = '逆变器'
          AND i.Inverter_Eff < 85.00
          AND d.Run_Status = '正常';
        
        SET @UpdatedCount = @@ROWCOUNT;
        
        -- 4. 输出提示信息
        IF @UpdatedCount > 0
        BEGIN
            PRINT '发现 ' + CAST(@UpdatedCount AS NVARCHAR(10)) + ' 个逆变器效率低于85%，已标记为异常状态';
            
            -- 显示前10条异常详情
            IF @UpdatedCount <= 10 
            BEGIN
                SELECT 
                    '异常设备告警' AS Alert_Type,
                    d.Device_ID,
                    d.Capacity,
                    i.Inverter_Eff AS Current_Efficiency,
                    i.Collect_Time,
                    '逆变器效率低于85%，当前效率：' + CAST(i.Inverter_Eff AS NVARCHAR(10)) + '%' AS Alert_Message
                FROM inserted i
                INNER JOIN PV_Device d ON i.Device_ID = d.Device_ID
                WHERE d.Device_Type = '逆变器'
                  AND i.Inverter_Eff < 85.00
                  AND d.Run_Status = '异常'; 
            END
        END
    END
END;
GO

PRINT '触发器 TR_Check_Inverter_Efficiency 创建完成';
GO

PRINT 'Part 3: 触发器创建完成';
GO

PRINT '========== 所有脚本执行完成 ==========';
GO

/* ============================================================
   Part 5: 插入测试数据
   ============================================================ */

-- 插入数据分析师数据（20条）
-- 先删除之前的数据分析师数据
DELETE FROM Data_PV_Forecast
WHERE Analyst_ID IN (
    SELECT Analyst_ID 
    FROM Role_Analyst 
    WHERE User_ID IN (
        SELECT User_ID FROM Sys_User WHERE Login_Account LIKE 'analyst%'
    )
);
DELETE FROM Sys_Role_Assignment
WHERE User_ID IN (
    SELECT User_ID 
    FROM Sys_User 
    WHERE Login_Account LIKE 'analyst%'
);
DELETE FROM Role_Analyst
WHERE User_ID IN (
    SELECT User_ID 
    FROM Sys_User 
    WHERE Login_Account LIKE 'analyst%'
);
DELETE FROM Sys_User 
WHERE Login_Account LIKE 'analyst%';

GO

-- 插入Sys_User的部分数据
DECLARE @FirstUserID INT;

INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status, Created_Time)
VALUES 
('analyst01', 'hash1', 'salt1', '张三', '数据分析部', '13800000001', 1, '2023-01-01 08:00:00'),
('analyst02', 'hash2', 'salt2', '李四', '数据分析部', '13800000002', 1, '2023-02-01 08:00:00'),
('analyst03', 'hash3', 'salt3', '王五', '数据分析部', '13800000003', 1, '2023-03-01 08:00:00'),
('analyst04', 'hash4', 'salt4', '赵六', '数据分析部', '13800000004', 1, '2023-04-01 08:00:00'),
('analyst05', 'hash5', 'salt5', '孙七', '数据分析部', '13800000005', 1, '2023-05-01 08:00:00'),
('analyst06', 'hash6', 'salt6', '周八', '数据分析部', '13800000006', 1, '2023-06-01 08:00:00'),
('analyst07', 'hash7', 'salt7', '吴九', '数据分析部', '13800000007', 1, '2023-07-01 08:00:00'),
('analyst08', 'hash8', 'salt8', '郑十', '数据分析部', '13800000008', 1, '2023-08-01 08:00:00'),
('analyst09', 'hash9', 'salt9', '钱一', '数据分析部', '13800000009', 1, '2023-09-01 08:00:00'),
('analyst10', 'hash10', 'salt10', '钱二', '数据分析部', '13800000010', 1, '2023-10-01 08:00:00'),
('analyst11', 'hash11', 'salt11', '孙三', '数据分析部', '13800000011', 1, '2023-11-01 08:00:00'),
('analyst12', 'hash12', 'salt12', '李四', '数据分析部', '13800000012', 1, '2023-12-01 08:00:00'),
('analyst13', 'hash13', 'salt13', '周五', '数据分析部', '13800000013', 1, '2024-01-01 08:00:00'),
('analyst14', 'hash14', 'salt14', '吴六', '数据分析部', '13800000014', 1, '2024-02-01 08:00:00'),
('analyst15', 'hash15', 'salt15', '郑七', '数据分析部', '13800000015', 1, '2024-03-01 08:00:00'),
('analyst16', 'hash16', 'salt16', '王八', '数据分析部', '13800000016', 1, '2024-04-01 08:00:00'),
('analyst17', 'hash17', 'salt17', '赵九', '数据分析部', '13800000017', 1, '2024-05-01 08:00:00'),
('analyst18', 'hash18', 'salt18', '孙十', '数据分析部', '13800000018', 1, '2024-06-01 08:00:00'),
('analyst19', 'hash19', 'salt19', '周一', '数据分析部', '13800000019', 1, '2024-07-01 08:00:00'),
('analyst20', 'hash20', 'salt20', '吴二', '数据分析部', '13800000020', 1, '2024-08-01 08:00:00');

-- 获取第一个插入的User_ID
SELECT @FirstUserID = MIN(User_ID) FROM Sys_User WHERE Login_Account LIKE 'analyst%';
PRINT '第一个分析师User_ID: ' + CAST(@FirstUserID AS NVARCHAR(10));
GO

-- 插入数据分析师角色表（使用实际的User_ID）
INSERT INTO Role_Analyst (User_ID)
SELECT User_ID 
FROM Sys_User 
WHERE Login_Account LIKE 'analyst%'
ORDER BY User_ID;
GO

PRINT '已插入 ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' 个分析师角色';
GO

-- 1. 并网点表 (PV_Grid_Point)
-- 适合数据库初始化的时候直接运行。

-- 并网点编号插入时自动生成
INSERT INTO PV_Grid_Point (Point_Name, Location) VALUES
('并网点01', '厂区A-屋顶光伏区'),
('并网点02', '厂区A-停车场光伏'),
('并网点03', '厂区B-1号厂房'),
('并网点04', '厂区B-2号厂房'),
('并网点05', '厂区C-办公楼'),
('并网点06', '厂区C-仓库屋顶'),
('并网点07', '厂区D-南侧光伏区'),
('并网点08', '厂区D-北侧光伏区'),
('并网点09', '厂区E-综合楼'),
('并网点10', '厂区E-实验楼'),
('并网点11', '厂区F-主厂房'),
('并网点12', '厂区F-辅厂房'),
('并网点13', '厂区G-1期项目'),
('并网点14', '厂区G-2期项目'),
('并网点15', '厂区H-东区光伏'),
('并网点16', '厂区H-西区光伏'),
('并网点17', '厂区I-分布式光伏1'),
('并网点18', '厂区I-分布式光伏2'),
('并网点19', '厂区J-集中式光伏'),
('并网点20', '厂区J-分布式光伏');
GO


-- 2. 光伏设备表 (PV_Device) 时间从2023年秋季到2025年冬季
-- Ledger_ID 暂时全部为 NULL
INSERT INTO PV_Device (Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID, Ledger_ID) VALUES
('逆变器', 50.00, '正常', '2023-09-15', 'RS485', 1, NULL),
('逆变器', 100.00, '正常', '2023-10-10', 'Lora', 2, NULL),
('汇流箱', NULL, '正常', '2023-11-20', 'RS485', 1, NULL),
('逆变器', 80.00, '正常', '2023-12-05', 'RS485', 3, NULL),
('逆变器', 60.00, '正常', '2024-03-22', 'Lora', 4, NULL),
('汇流箱', NULL, '正常', '2024-05-28', 'RS485', 2, NULL),
('逆变器', 120.00, '正常', '2024-06-08', 'Lora', 5, NULL),
('逆变器', 75.00, '正常', '2024-08-15', 'RS485', 6, NULL),
('逆变器', 90.00, '正常', '2024-10-10', 'Lora', 7, NULL),
('汇流箱', NULL, '正常', '2024-11-18', 'RS485', 3, NULL),
('逆变器', 55.00, '正常', '2025-01-25', 'RS485', 8, NULL),
('逆变器', 110.00, '正常', '2025-02-28', 'Lora', 9, NULL),
('汇流箱', NULL, '正常', '2025-04-20', 'RS485', 4, NULL),
('逆变器', 70.00, '正常', '2025-06-05', 'RS485', 10, NULL),
('逆变器', 85.00, '正常', '2025-07-15', 'Lora', 11, NULL),
('逆变器', 95.00, '正常', '2025-09-12', 'RS485', 12, NULL),
('汇流箱', NULL, '正常', '2025-10-02', 'RS485', 5, NULL),
('逆变器', 65.00, '正常', '2025-11-28', 'Lora', 13, NULL),
('逆变器', 105.00, '正常', '2025-12-08', 'RS485', 14, NULL),
('逆变器', 40.00, '正常', '2025-12-30', 'Lora', 15, NULL);
GO

-- 3. 光伏预测模型表 (PV_Forecast_Model) - 相同模型名，不同版本
DELETE FROM PV_Model_Alert;    -- 删除模型产生的报警
DELETE FROM Data_PV_Forecast;  -- 删除模型产生的预测数据

-- 2. 【核心】删除模型表本身
DELETE FROM PV_Forecast_Model;

INSERT INTO PV_Forecast_Model (Model_Version, Model_Name, Status, Update_Time) VALUES
-- SUN系列模型
('SUN-V1.0.0', 'SUN光伏预测模型', 'Deprecated', '2023-08-01 10:00:00'),
('SUN-V1.1.0', 'SUN光伏预测模型', 'Deprecated', '2023-10-15 14:30:00'),
('SUN-V1.2.0', 'SUN光伏预测模型', 'Deprecated', '2023-12-20 09:15:00'),
('SUN-V2.0.0', 'SUN光伏预测模型', 'Active', '2024-03-10 16:45:00'),
('SUN-V2.1.0', 'SUN光伏预测模型', 'Active', '2024-06-05 11:20:00'),
('SUN-V2.1.1', 'SUN光伏预测模型', 'Active', '2024-08-12 16:30:00'),
('SUN-V2.2.0', 'SUN光伏预测模型', 'Testing', '2024-10-25 15:30:00'),
('SUN-V2.2.1', 'SUN光伏预测模型', 'Testing', '2024-12-30 13:45:00'),
('SUN-V2.3.0', 'SUN光伏预测模型', 'Training', '2025-02-10 09:00:00'),
('SUN-V2.3.1', 'SUN光伏预测模型', 'Training', '2025-04-10 09:25:00'),

-- WIND系列模型
('WIND-V1.0.0', 'WIND智能预测模型', 'Deprecated', '2023-09-01 10:00:00'),
('WIND-V1.1.0', 'WIND智能预测模型', 'Active', '2024-01-15 14:30:00'),
('WIND-V1.2.0', 'WIND智能预测模型', 'Active', '2024-05-20 09:15:00'),
('WIND-V2.0.0', 'WIND智能预测模型', 'Testing', '2024-09-10 16:45:00'),

-- RAIN系列模型
('RAIN-V1.0.0', 'RAIN深度学习模型', 'Deprecated', '2023-11-01 10:00:00'),
('RAIN-V1.1.0', 'RAIN深度学习模型', 'Active', '2024-03-15 14:30:00'),
('RAIN-V1.2.0', 'RAIN深度学习模型', 'Testing', '2024-07-20 09:15:00'),
('RAIN-V2.0.0', 'RAIN深度学习模型', 'Training', '2024-11-10 16:45:00'),

-- CLOUD系列模型
('CLOUD-V1.0.0', 'CLOUD集成学习模型', 'Active', '2024-02-01 10:00:00'),
('CLOUD-V1.1.0', 'CLOUD集成学习模型', 'Testing', '2024-06-15 14:30:00'),
('CLOUD-V1.2.0', 'CLOUD集成学习模型', 'Training', '2024-10-20 09:15:00');
GO


-- 情景设定：2025年6月连续三周（6月1日-6月21日）
-- 重点关注：并网点1（逆变器1，设备ID=1）

-- 4. 插入预测数据（Data_PV_Forecast）Actual_Val 应该为 NULL
-- 在插入预测数据之前，先获取正确的Analyst_ID
DECLARE @FirstAnalystID BIGINT;

-- 获取第一个分析师的Analyst_ID（不是User_ID）
SELECT @FirstAnalystID = MIN(Analyst_ID) FROM Role_Analyst;

PRINT '第一个分析师Analyst_ID: ' + CAST(@FirstAnalystID AS NVARCHAR(10));

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID) VALUES
-- 第1周预测（初始时Actual_Val为NULL）
(1, '2025-06-01', '12:00-13:00', 26.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-02', '12:00-13:00', 25.200, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-03', '12:00-13:00', 24.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-04', '12:00-13:00', 23.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-05', '12:00-13:00', 22.800, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-06', '12:00-13:00', 21.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-07', '12:00-13:00', 20.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),

-- 第2周预测
(1, '2025-06-08', '12:00-13:00', 19.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-09', '12:00-13:00', 19.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-10', '12:00-13:00', 18.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-11', '12:00-13:00', 18.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-12', '12:00-13:00', 17.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-13', '12:00-13:00', 17.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-14', '12:00-13:00', 16.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),

-- 第3周预测
(1, '2025-06-15', '12:00-13:00', 16.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-16', '12:00-13:00', 16.500, NULL, 'SUN-V2.1.0', @FirstAnalystID),
(1, '2025-06-17', '12:00-13:00', 17.000, NULL, 'SUN-V2.1.0', @FirstAnalystID),
-- 6月18日分析师更新模型版本
(1, '2025-06-18', '12:00-13:00', 26.800, NULL, 'SUN-V2.2.0', @FirstAnalystID),
(1, '2025-06-19', '12:00-13:00', 27.500, NULL, 'SUN-V2.2.0', @FirstAnalystID),
(1, '2025-06-20', '12:00-13:00', 28.200, NULL, 'SUN-V2.2.0', @FirstAnalystID),
(1, '2025-06-21', '12:00-13:00', 29.500, NULL, 'SUN-V2.2.0', @FirstAnalystID);
GO


-- 5. 插入发电数据（Data_PV_Gen）2025年6月连续21天
-- 这会触发 TR_Update_Forecast_Actual 触发器，自动更新预测表的Actual_Val
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Factory_ID, Point_ID, Bus_Voltage, Bus_Current, String_Count) VALUES
-- 第1周：正常情况
(1, '2025-06-01 12:00:00', 25.500, 18.500, 7.000, 98.00, 1, 1, NULL, NULL, NULL),
(1, '2025-06-02 12:00:00', 24.800, 17.800, 7.000, 97.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-03 12:00:00', 23.200, 16.200, 7.000, 96.80, 1, 1, NULL, NULL, NULL),
(1, '2025-06-04 12:00:00', 22.500, 15.500, 7.000, 96.20, 1, 1, NULL, NULL, NULL),
(1, '2025-06-05 12:00:00', 21.800, 14.800, 7.000, 95.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-06 12:00:00', 20.500, 13.500, 7.000, 94.80, 1, 1, NULL, NULL, NULL),
(1, '2025-06-07 12:00:00', 19.200, 12.200, 7.000, 94.00, 1, 1, NULL, NULL, NULL),

-- 第2周：开始出现设备异常
(1, '2025-06-08 12:00:00', 18.500, 11.500, 7.000, 84.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-09 12:00:00', 17.800, 10.800, 7.000, 83.20, 1, 1, NULL, NULL, NULL),
(1, '2025-06-10 12:00:00', 16.500, 9.500, 7.000, 82.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-11 12:00:00', 15.200, 8.200, 7.000, 81.80, 1, 1, NULL, NULL, NULL),
(1, '2025-06-12 12:00:00', 14.500, 7.500, 7.000, 80.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-13 12:00:00', 13.800, 6.800, 7.000, 79.20, 1, 1, NULL, NULL, NULL),
(1, '2025-06-14 12:00:00', 12.500, 5.500, 7.000, 78.50, 1, 1, NULL, NULL, NULL),

-- 第3周：设备维修后恢复
(1, '2025-06-15 12:00:00', 24.500, 17.500, 7.000, 97.80, 1, 1, NULL, NULL, NULL),
(1, '2025-06-16 12:00:00', 25.200, 18.200, 7.000, 98.20, 1, 1, NULL, NULL, NULL),
(1, '2025-06-17 12:00:00', 26.500, 19.500, 7.000, 98.50, 1, 1, NULL, NULL, NULL),
(1, '2025-06-18 12:00:00', 27.200, 20.200, 7.000, 98.80, 1, 1, NULL, NULL, NULL),
(1, '2025-06-19 12:00:00', 28.500, 21.500, 7.000, 99.00, 1, 1, NULL, NULL, NULL),
(1, '2025-06-20 12:00:00', 29.200, 22.200, 7.000, 99.20, 1, 1, NULL, NULL, NULL),
(1, '2025-06-21 12:00:00', 30.500, 23.500, 7.000, 99.50, 1, 1, NULL, NULL, NULL);
GO

PRINT '测试数据插入完毕。';
GO

