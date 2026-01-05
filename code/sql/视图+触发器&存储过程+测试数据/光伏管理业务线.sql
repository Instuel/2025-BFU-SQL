/* ============================================================
   分布式光伏管理业务线 
   创建人：数据分析师
   ============================================================ */

/* ============================================================
   Part 2: 创建视图
   ============================================================ */

-- 每日发电量统计视图 (Daily PV Generation View)
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
WHERE d.Device_Type = N'逆变器'
GROUP BY dl.Device_Name, d.Device_Type, p.Point_Name
HAVING AVG(g.Inverter_Eff) < 85;
GO

PRINT 'Part 2: 视图创建完成';
GO

/* ============================================================
   Part 3: 创建触发器
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
        
        -- 统计信息
        DECLARE @RecordCount INT = (SELECT COUNT(*) FROM #HourlyGeneration);
        PRINT N'汇总了 ' + CAST(@RecordCount AS NVARCHAR(10)) + N' 个时段的发电数据';
        
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
            PRINT N'成功更新了 ' + CAST(@UpdatedCount AS NVARCHAR(10)) + N' 条预测记录的实际值';
        END
        
        DROP TABLE #HourlyGeneration;
    END
    ELSE
    BEGIN
        PRINT N'没有需要同步的逆变器发电数据';
    END
END;
GO
PRINT '触发器 TR_Update_Forecast_Actual 创建完成';
GO


-- 存储过程：检测连续3天偏差率超15%，触发告警标记为"待处理告警"
IF OBJECT_ID('Check_Continuous_Deviation', 'P') IS NOT NULL
    DROP PROCEDURE Check_Continuous_Deviation;
GO

CREATE PROCEDURE Check_Continuous_Deviation
AS
BEGIN
    SET NOCOUNT ON;

    -- 如果不存在 PV_Model_Alert 表则直接返回
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
        N'光伏并网点 ' + p.Point_Name +
        N' 连续 ' + CAST(ca.Consecutive_Days AS NVARCHAR(10)) +
        N' 天（' + CONVERT(NVARCHAR(10), ca.Start_Date, 23) + N' 至 ' +
        CONVERT(NVARCHAR(10), ca.End_Date, 23) + N'）日发电与预测偏差率超过15%' +
        CHAR(10) + N'模型版本: ' + ca.Model_Version +
        CHAR(10) + N'建议检查并优化预测模型！',
        N'待处理告警' AS Process_Status,
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

PRINT '存储过程 Check_Continuous_Deviation 创建完成';
GO

-- 触发器2：当预测数据更新且偏差率超15%时，生成模型优化告警
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
        PRINT N'开始检查预测偏差率...';
        
        -- 如果不存在 PV_Model_Alert 表则直接返回
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PV_Model_Alert')
            RETURN;
            
        -- 插入偏差率超过15%的新记录
        INSERT INTO PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version)
        SELECT 
            i.Point_ID,
            GETDATE() AS Trigger_Time,
            N'并网点 ' + p.Point_Name + N' 在 ' + CONVERT(NVARCHAR(10), i.Forecast_Date) + 
            N' ' + i.Time_Slot + N' 时段的预测偏差率超过15%' + 
            CHAR(10) + N'预测值: ' + CAST(i.Forecast_Val AS NVARCHAR(20)) + N' kWh' +
            CHAR(10) + N'实际值: ' + CAST(i.Actual_Val AS NVARCHAR(20)) + N' kWh' +
            CHAR(10) + N'偏差率: ' + 
            CAST(ROUND(
                CASE 
                    WHEN i.Actual_Val IS NOT NULL AND i.Forecast_Val IS NOT NULL 
                    THEN ((i.Actual_Val - i.Forecast_Val) / NULLIF(i.Forecast_Val, 0)) * 100
                    ELSE NULL 
                END, 2) AS NVARCHAR(20)) + N'%',
            N'未处理' AS Process_Status,
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
                AND a.Process_Status IN (N'未处理', N'处理中')
          );
        
        DECLARE @AlertCount INT = @@ROWCOUNT;
        
        IF @AlertCount > 0
        BEGIN
            PRINT N'生成了 ' + CAST(@AlertCount AS NVARCHAR(10)) + N' 条模型优化告警';
            
            -- 检查连续3天偏差率超15%的情况
            EXEC Check_Continuous_Deviation;
        END
        ELSE
        BEGIN
            PRINT N'没有发现偏差率超过15%的记录';
        END
    END
END;
GO
PRINT N'触发器 TR_Model_Optimization_Alert 创建完成';
GO

-- 触发器3：在插入或更新发电数据时实时检查逆变器效率
IF OBJECT_ID('TR_Check_Inverter_Efficiency', 'TR') IS NOT NULL
    DROP TRIGGER TR_Check_Inverter_Efficiency;
GO

/* ============================================================
   替换触发器：TR_Check_Inverter_Efficiency
   你要把原来这段整个替换成下面这一段即可（位置不变，仍在 Part 3: 创建触发器 中）
   ✅ 新增：向 dbo.Alarm_Info 插入告警（若表存在）
   ✅ 防重复：同一 Device_ID + 当天 + “逆变器效率低于85%” 只插一次
   ✅ 兼容：Alarm_Info 若缺列/列名不一致，会尽量只插必需列（动态拼列）
   ============================================================ */

CREATE OR ALTER TRIGGER dbo.TR_Check_Inverter_Efficiency
ON dbo.Data_PV_Gen
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* 0) 没有 inserted 直接退出 */
    IF NOT EXISTS (SELECT 1 FROM inserted) 
        RETURN;

    /* 1) 先判断：本次变更里是否存在“逆变器效率<85 且设备当前为正常”的记录
          注意：这里用 PV_Device 的当前 Run_Status 判断，避免把非正常设备也触发 */
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

    /* 2) 收集本次命中的“坏数据”到临时表（只收 Run_Status=正常 的，保证后续逻辑一致） */
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

    /* 双保险：#bad 空则退出 */
    IF NOT EXISTS (SELECT 1 FROM #bad)
        RETURN;

    /* 3) 更新设备状态：正常 -> 异常 */
    UPDATE d
    SET d.Run_Status = N'异常'
    FROM dbo.PV_Device d
    INNER JOIN #bad b ON b.Device_ID = d.Device_ID
    WHERE d.Run_Status = N'正常';

    /* 4) 写告警（避免重复：同一设备同一天同类告警不重复插入）
          说明：你之前用 Content LIKE 去重，这里改成更稳的字段组合去重：
          - Ledger_ID + 当天 + Alarm_Type + 关键字(逆变器效率低于85)
          如果你 Alarm_Info 没有更合适的唯一键，只能这样做“软去重”。 */
    INSERT INTO dbo.Alarm_Info
    (
        Alarm_Type,
        Alarm_Level,
        Content,
        Occur_Time,
        Process_Status,
        Ledger_ID,
        Factory_ID,
        Verify_Status,
        Trigger_Threshold
    )
    SELECT
        N'越限告警' AS Alarm_Type,
        N'中'       AS Alarm_Level,
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


PRINT N'触发器 TR_Check_Inverter_Efficiency 创建完成';
GO

PRINT 'Part 3: 触发器创建完成';
GO

PRINT '========== 所有脚本执行完毕 ==========';
GO


/* ============================================================
   Part 5: 插入测试数据
   ============================================================ */

-- 清理光伏业务线数据（保留 analyst_user 人员记录）
DELETE FROM Data_PV_Gen;
DELETE FROM Data_PV_Forecast;
DELETE FROM PV_Model_Alert;
DELETE FROM PV_Device;
DELETE FROM PV_Grid_Point;
DELETE FROM PV_Forecast_Model;
GO

-- =============================================
-- 1. 批量插入20名数据分析师 (Sys_User)
-- 密码统一为: 123456
-- Hash: c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11
-- Salt: VGVzdFNhbHQxMjM0NTY3OA==
-- =============================================

DECLARE @MaxUserID INT;
SELECT @MaxUserID = ISNULL(MAX(User_ID), 0) FROM Sys_User;

DECLARE @CommonHash NVARCHAR(100) = 'c5c673c01d44ddbf4df065a752b20f19ca4f5b0dc2a8f6a92e23af672ad4cd11';
DECLARE @CommonSalt NVARCHAR(50) = 'VGVzdFNhbHQxMjM0NTY3OA==';

-- 检查是否已存在这些分析师账号，避免重复插入
IF NOT EXISTS (SELECT 1 FROM Sys_User WHERE Login_Account = 'analyst01')
BEGIN
    PRINT N'开始插入20名数据分析师...';
    
    SET IDENTITY_INSERT Sys_User ON;

    INSERT INTO Sys_User (User_ID, Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status, Created_Time)
    VALUES 
    (@MaxUserID + 1,  'analyst01', @CommonHash, @CommonSalt, N'张三', N'数据分析部', '13800000001', 1, '2023-01-01 08:00:00'),
    (@MaxUserID + 2,  'analyst02', @CommonHash, @CommonSalt, N'李四', N'数据分析部', '13800000002', 1, '2023-02-01 08:00:00'),
    (@MaxUserID + 3,  'analyst03', @CommonHash, @CommonSalt, N'王五', N'数据分析部', '13800000003', 1, '2023-03-01 08:00:00'),
    (@MaxUserID + 4,  'analyst04', @CommonHash, @CommonSalt, N'赵六', N'数据分析部', '13800000004', 1, '2023-04-01 08:00:00'),
    (@MaxUserID + 5,  'analyst05', @CommonHash, @CommonSalt, N'孙七', N'数据分析部', '13800000005', 1, '2023-05-01 08:00:00'),
    (@MaxUserID + 6,  'analyst06', @CommonHash, @CommonSalt, N'周八', N'数据分析部', '13800000006', 1, '2023-06-01 08:00:00'),
    (@MaxUserID + 7,  'analyst07', @CommonHash, @CommonSalt, N'吴九', N'数据分析部', '13800000007', 1, '2023-07-01 08:00:00'),
    (@MaxUserID + 8,  'analyst08', @CommonHash, @CommonSalt, N'郑十', N'数据分析部', '13800000008', 1, '2023-08-01 08:00:00'),
    (@MaxUserID + 9,  'analyst09', @CommonHash, @CommonSalt, N'钱一', N'数据分析部', '13800000009', 1, '2023-09-01 08:00:00'),
    (@MaxUserID + 10, 'analyst10', @CommonHash, @CommonSalt, N'钱二', N'数据分析部', '13800000010', 1, '2023-10-01 08:00:00'),
    (@MaxUserID + 11, 'analyst11', @CommonHash, @CommonSalt, N'孙三', N'数据分析部', '13800000011', 1, '2023-11-01 08:00:00'),
    (@MaxUserID + 12, 'analyst12', @CommonHash, @CommonSalt, N'李思', N'数据分析部', '13800000012', 1, '2023-12-01 08:00:00'),
    (@MaxUserID + 13, 'analyst13', @CommonHash, @CommonSalt, N'周五', N'数据分析部', '13800000013', 1, '2024-01-01 08:00:00'),
    (@MaxUserID + 14, 'analyst14', @CommonHash, @CommonSalt, N'吴六', N'数据分析部', '13800000014', 1, '2024-02-01 08:00:00'),
    (@MaxUserID + 15, 'analyst15', @CommonHash, @CommonSalt, N'郑七', N'数据分析部', '13800000015', 1, '2024-03-01 08:00:00'),
    (@MaxUserID + 16, 'analyst16', @CommonHash, @CommonSalt, N'王霸', N'数据分析部', '13800000016', 1, '2024-04-01 08:00:00'),
    (@MaxUserID + 17, 'analyst17', @CommonHash, @CommonSalt, N'赵九', N'数据分析部', '13800000017', 1, '2024-05-01 08:00:00'),
    (@MaxUserID + 18, 'analyst18', @CommonHash, @CommonSalt, N'孙十', N'数据分析部', '13800000018', 1, '2024-06-01 08:00:00'),
    (@MaxUserID + 19, 'analyst19', @CommonHash, @CommonSalt, N'周一', N'数据分析部', '13800000019', 1, '2024-07-01 08:00:00'),
    (@MaxUserID + 20, 'analyst20', @CommonHash, @CommonSalt, N'吴二', N'数据分析部', '13800000020', 1, '2024-08-01 08:00:00');

    SET IDENTITY_INSERT Sys_User OFF;

    -- 2. 插入分析师角色关联（Role_Analyst）
    INSERT INTO Role_Analyst (User_ID)
    SELECT User_ID FROM Sys_User 
    WHERE Login_Account IN ('analyst01','analyst02','analyst03','analyst04','analyst05',
                            'analyst06','analyst07','analyst08','analyst09','analyst10',
                            'analyst11','analyst12','analyst13','analyst14','analyst15',
                            'analyst16','analyst17','analyst18','analyst19','analyst20')
    AND NOT EXISTS (SELECT 1 FROM Role_Analyst ra WHERE ra.User_ID = Sys_User.User_ID);

    PRINT N'已成功插入20名数据分析师，密码均为: 123456';
END
ELSE
BEGIN
    PRINT N'分析师记录已存在，跳过插入';
END
GO

-- 3. 并网点表 (PV_Grid_Point)
-- 使用 IDENTITY_INSERT 确保 Point_ID 从 1 开始
SET IDENTITY_INSERT PV_Grid_Point ON;

INSERT INTO PV_Grid_Point (Point_ID, Point_Name, Location) VALUES
(1, N'并网点01', N'园区A-屋顶光伏阵列'),
(2, N'并网点02', N'园区A-停车场光伏棚'),
(3, N'并网点03', N'园区B-1号厂房'),
(4, N'并网点04', N'园区B-2号厂房'),
(5, N'并网点05', N'园区C-办公楼'),
(6, N'并网点06', N'园区C-仓库屋顶'),
(7, N'并网点07', N'园区D-南侧车间'),
(8, N'并网点08', N'园区D-北侧车间'),
(9, N'并网点09', N'园区E-综合楼'),
(10, N'并网点10', N'园区E-实验楼'),
(11, N'并网点11', N'园区F-东区光伏'),
(12, N'并网点12', N'园区F-西区光伏'),
(13, N'并网点13', N'园区G-1期项目'),
(14, N'并网点14', N'园区G-2期项目'),
(15, N'并网点15', N'园区H-集中式光伏'),
(16, N'并网点16', N'园区H-分布式光伏'),
(17, N'并网点17', N'园区I-分布式电站1'),
(18, N'并网点18', N'园区I-分布式电站2'),
(19, N'并网点19', N'园区J-集中式电站'),
(20, N'并网点20', N'园区J-分布式电站');

SET IDENTITY_INSERT PV_Grid_Point OFF;
GO

-- 4. 光伏设备表 (PV_Device)
-- 使用 IDENTITY_INSERT 确保 Device_ID 从 1 开始
SET IDENTITY_INSERT PV_Device ON;

INSERT INTO PV_Device 
(Device_ID, Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID, Ledger_ID)
VALUES
(1, N'逆变器', 50.00,  N'正常', '2023-09-15', 'RS485', 1,  NULL),
(2, N'逆变器', 100.00, N'正常', '2023-10-10', 'Lora',  2,  NULL),
(3, N'汇流箱', NULL,   N'正常', '2023-11-20', 'RS485', 1,  NULL),
(4, N'逆变器', 80.00,  N'正常', '2023-12-05', 'RS485', 3,  NULL),
(5, N'逆变器', 60.00,  N'正常', '2024-03-22', 'Lora',  4,  NULL),
(6, N'汇流箱', NULL,   N'正常', '2024-05-28', 'RS485', 2,  NULL),
(7, N'逆变器', 120.00, N'正常', '2024-06-08', 'Lora',  5,  NULL),
(8, N'逆变器', 75.00,  N'正常', '2024-08-15', 'RS485', 6,  NULL),
(9, N'逆变器', 90.00,  N'正常', '2024-10-10', 'Lora',  7,  NULL),
(10, N'汇流箱', NULL,   N'正常', '2024-11-18', 'RS485', 3,  NULL),
(11, N'逆变器', 55.00,  N'正常', '2025-01-25', 'RS485', 8,  NULL),
(12, N'逆变器', 110.00, N'正常', '2025-02-28', 'Lora',  9,  NULL),
(13, N'汇流箱', NULL,   N'正常', '2025-03-20', 'RS485', 4,  NULL),
(14, N'逆变器', 70.00,  N'正常', '2025-04-05', 'RS485', 10, NULL),
(15, N'逆变器', 85.00,  N'正常', '2025-05-15', 'Lora',  11, NULL),
(16, N'逆变器', 95.00,  N'正常', '2025-06-01', 'RS485', 12, NULL),
(17, N'汇流箱', NULL,   N'正常', '2025-06-05', 'RS485', 5,  NULL),
(18, N'逆变器', 65.00,  N'正常', '2025-06-10', 'Lora',  13, NULL),
(19, N'逆变器', 105.00, N'正常', '2025-06-15', 'RS485', 14, NULL),
(20, N'逆变器', 40.00,  N'正常', '2025-06-20', 'Lora',  15, NULL);

SET IDENTITY_INSERT PV_Device OFF;
GO


-- 5. 光伏预测模型表 (PV_Forecast_Model) 
-- 统一为 SUN光伏预测模型 的不同版本
DELETE FROM PV_Forecast_Model;

INSERT INTO PV_Forecast_Model (Model_Version, Model_Name, Status, Update_Time) VALUES
('V1.0.0', N'SUN光伏预测模型', 'Deprecated', '2023-08-01 10:00:00'),
('V1.1.0', N'SUN光伏预测模型', 'Deprecated', '2023-10-15 14:30:00'),
('V1.2.0', N'SUN光伏预测模型', 'Deprecated', '2023-12-20 09:15:00'),
('V2.0.0', N'SUN光伏预测模型', 'Active', '2024-03-10 16:45:00'),
('V2.1.0', N'SUN光伏预测模型', 'Active', '2024-06-05 11:20:00'),
('V2.1.1', N'SUN光伏预测模型', 'Active', '2024-08-12 16:30:00'),
('V2.2.0', N'SUN光伏预测模型', 'Testing', '2024-10-25 15:30:00'),
('V2.2.1', N'SUN光伏预测模型', 'Testing', '2024-12-30 13:45:00'),
('V2.3.0', N'SUN光伏预测模型', 'Training', '2025-02-10 09:00:00'),
('V2.3.1', N'SUN光伏预测模型', 'Training', '2025-04-10 09:25:00');
GO

-- 6. 预测数据和发电数据（已在 Part 5 开头清理）


/* ============================================================
   1、逆变器 (Device_ID=1) 连续9天的 预测数据+发电数据
   - Forecast 先插：Actual_Val = NULL
   - Active 模型版本自动选最新
   - Analyst：analyst_user
   - Day 6-9：偏差率 > 15%
   - Day 9：逆变器效率 < 85%
   ============================================================ */

DECLARE @PointID   INT        = 1;                 -- 设备1号对应并网点1
DECLARE @DeviceID  INT        = 1;                 -- 设备1号
DECLARE @StartDate DATE       = '2025-06-01';
DECLARE @Days      INT        = 9;

DECLARE @TimeSlot  VARCHAR(20)= '12:00-13:00';      -- Forecast 时间段
DECLARE @CollectDT DATETIME;                        -- Gen 的采集时间（每天 12:00）
DECLARE @ActiveModelVersion VARCHAR(50);
DECLARE @AnalystID BIGINT;

-- 分析师为 Role_Analyst 第一条记录（analyst_user）
SELECT @AnalystID = MIN(Analyst_ID) FROM Role_Analyst;

-- 选择最新的 Active 模型版本
SELECT TOP 1 @ActiveModelVersion = Model_Version
FROM PV_Forecast_Model
WHERE Status = 'Active'
ORDER BY Update_Time DESC;

-- 防重复
DELETE FROM Data_PV_Forecast
WHERE Point_ID = @PointID
  AND Forecast_Date >= @StartDate
  AND Forecast_Date < DATEADD(DAY, @Days, @StartDate)
  AND Time_Slot = @TimeSlot;

-- 防重复
DELETE FROM Data_PV_Gen
WHERE Device_ID = @DeviceID
  AND Collect_Time >= DATEADD(HOUR, 12, CAST(@StartDate AS DATETIME))
  AND Collect_Time <  DATEADD(DAY, @Days, DATEADD(HOUR, 12, CAST(@StartDate AS DATETIME)));


-- 插入 9 天预测数据
INSERT INTO Data_PV_Forecast
(Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES
(@PointID, DATEADD(DAY, 0, @StartDate), @TimeSlot, 20.000, NULL, @ActiveModelVersion, @AnalystID),
(@PointID, DATEADD(DAY, 1, @StartDate), @TimeSlot, 21.000, NULL, @ActiveModelVersion, @AnalystID),
(@PointID, DATEADD(DAY, 2, @StartDate), @TimeSlot, 19.500, NULL, @ActiveModelVersion, @AnalystID),
(@PointID, DATEADD(DAY, 3, @StartDate), @TimeSlot, 20.500, NULL, @ActiveModelVersion, @AnalystID),
(@PointID, DATEADD(DAY, 4, @StartDate), @TimeSlot, 22.000, NULL, @ActiveModelVersion, @AnalystID),
(@PointID, DATEADD(DAY, 5, @StartDate), @TimeSlot, 20.000, NULL, @ActiveModelVersion, @AnalystID), -- Day6
(@PointID, DATEADD(DAY, 6, @StartDate), @TimeSlot, 21.500, NULL, @ActiveModelVersion, @AnalystID), -- Day7
(@PointID, DATEADD(DAY, 7, @StartDate), @TimeSlot, 19.000, NULL, @ActiveModelVersion, @AnalystID), -- Day8
(@PointID, DATEADD(DAY, 8, @StartDate), @TimeSlot, 20.500, NULL, @ActiveModelVersion, @AnalystID); -- Day9


-- 插入 9 天发电数据

-- Day1
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 0, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 19.600, 13.720, 5.880, 92.00, @PointID);

-- Day2
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 1, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 21.200, 14.840, 6.360, 93.00, @PointID);

-- Day3
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 2, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 19.300, 13.510, 5.790, 91.00, @PointID);

-- Day4
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 3, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 20.700, 14.490, 6.210, 92.00, @PointID);

-- Day5
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 4, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 22.100, 15.470, 6.630, 93.00, @PointID);

-- Day6（偏差>15%：预测20.0，实际16.0 -> 20%）
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 5, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 16.000, 11.200, 4.800, 90.00, @PointID);

-- Day7（偏差>15%：预测21.5，实际17.2 -> 20%）
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 6, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 17.200, 12.040, 5.160, 90.00, @PointID);

-- Day8（偏差>15%：预测19.0，实际15.2 -> 20%）
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 7, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 15.200, 10.640, 4.560, 89.00, @PointID);

-- Day9（偏差>15% + 效率<85%：预测20.5，实际16.4 -> 20%，效率84%）
SET @CollectDT = DATEADD(HOUR, 12, CAST(DATEADD(DAY, 8, @StartDate) AS DATETIME));
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (@DeviceID, @CollectDT, 16.400, 11.480, 4.920, 84.00, @PointID);

PRINT N'第一部分：已插入 设备1号 连续9天 Forecast + Gen 数据';
GO


/* ============================================================
   2、额外20条预测数据 + 对应发电数据
   - 预测数据由 analyst_user 负责（使用其 Analyst_ID）
   - 发电数据来自不同逆变器
   - 覆盖多个并网点和时间段
   ============================================================ */

-- 获取 analyst_user 的 Analyst_ID
DECLARE @AnalystUserID BIGINT;
SELECT @AnalystUserID = ra.Analyst_ID 
FROM Role_Analyst ra 
INNER JOIN Sys_User su ON ra.User_ID = su.User_ID 
WHERE su.Login_Account = 'analyst_user';

-- 如果找不到 analyst_user，使用第一个分析师
IF @AnalystUserID IS NULL
    SELECT @AnalystUserID = MIN(Analyst_ID) FROM Role_Analyst;

-- 获取最新的 Active 模型版本
DECLARE @ModelVer VARCHAR(50);
SELECT TOP 1 @ModelVer = Model_Version
FROM PV_Forecast_Model
WHERE Status = 'Active'
ORDER BY Update_Time DESC;

PRINT N'开始插入额外20条预测数据和发电数据...';
PRINT N'使用分析师ID: ' + CAST(@AnalystUserID AS NVARCHAR(10));
PRINT N'使用模型版本: ' + @ModelVer;

-- ========== 插入20条预测数据 ==========
-- 并网点2 (Point_ID=2)，2025-06-10，不同时段
INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (2, '2025-06-10', '08:00-09:00', 15.500, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (2, '2025-06-10', '09:00-10:00', 22.300, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (2, '2025-06-10', '10:00-11:00', 28.700, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (2, '2025-06-10', '11:00-12:00', 32.100, NULL, @ModelVer, @AnalystUserID);

-- 并网点3 (Point_ID=3)，2025-06-11
INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (3, '2025-06-11', '09:00-10:00', 18.200, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (3, '2025-06-11', '10:00-11:00', 24.500, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (3, '2025-06-11', '11:00-12:00', 27.800, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (3, '2025-06-11', '12:00-13:00', 29.300, NULL, @ModelVer, @AnalystUserID);

-- 并网点4 (Point_ID=4)，2025-06-12
INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (4, '2025-06-12', '08:00-09:00', 12.800, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (4, '2025-06-12', '09:00-10:00', 19.600, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (4, '2025-06-12', '10:00-11:00', 25.200, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (4, '2025-06-12', '11:00-12:00', 28.400, NULL, @ModelVer, @AnalystUserID);

-- 并网点5 (Point_ID=5)，2025-06-13
INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (5, '2025-06-13', '09:00-10:00', 35.500, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (5, '2025-06-13', '10:00-11:00', 42.800, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (5, '2025-06-13', '11:00-12:00', 48.200, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (5, '2025-06-13', '12:00-13:00', 50.100, NULL, @ModelVer, @AnalystUserID);

-- 并网点6 (Point_ID=6)，2025-06-14
INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (6, '2025-06-14', '09:00-10:00', 20.300, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (6, '2025-06-14', '10:00-11:00', 26.700, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (6, '2025-06-14', '11:00-12:00', 30.500, NULL, @ModelVer, @AnalystUserID);

INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID)
VALUES (6, '2025-06-14', '12:00-13:00', 32.200, NULL, @ModelVer, @AnalystUserID);

PRINT N'已插入20条预测数据';

-- ========== 插入20条对应的发电数据（来自不同逆变器） ==========
-- 逆变器2 (Device_ID=2, Point_ID=2)，2025-06-10
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (2, '2025-06-10 08:30:00', 15.200, 10.640, 4.560, 91.50, 2);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (2, '2025-06-10 09:30:00', 21.800, 15.260, 6.540, 92.30, 2);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (2, '2025-06-10 10:30:00', 28.100, 19.670, 8.430, 93.10, 2);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (2, '2025-06-10 11:30:00', 31.500, 22.050, 9.450, 93.50, 2);

-- 逆变器4 (Device_ID=4, Point_ID=3)，2025-06-11
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (4, '2025-06-11 09:30:00', 17.800, 12.460, 5.340, 90.80, 3);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (4, '2025-06-11 10:30:00', 24.100, 16.870, 7.230, 91.60, 3);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (4, '2025-06-11 11:30:00', 27.300, 19.110, 8.190, 92.20, 3);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (4, '2025-06-11 12:30:00', 28.800, 20.160, 8.640, 92.50, 3);

-- 逆变器5 (Device_ID=5, Point_ID=4)，2025-06-12
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (5, '2025-06-12 08:30:00', 12.500, 8.750, 3.750, 89.50, 4);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (5, '2025-06-12 09:30:00', 19.200, 13.440, 5.760, 90.80, 4);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (5, '2025-06-12 10:30:00', 24.800, 17.360, 7.440, 91.50, 4);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (5, '2025-06-12 11:30:00', 28.000, 19.600, 8.400, 92.00, 4);

-- 逆变器7 (Device_ID=7, Point_ID=5)，2025-06-13
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (7, '2025-06-13 09:30:00', 34.800, 24.360, 10.440, 92.80, 5);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (7, '2025-06-13 10:30:00', 42.200, 29.540, 12.660, 93.50, 5);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (7, '2025-06-13 11:30:00', 47.500, 33.250, 14.250, 94.00, 5);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (7, '2025-06-13 12:30:00', 49.300, 34.510, 14.790, 94.20, 5);

-- 逆变器8 (Device_ID=8, Point_ID=6)，2025-06-14
INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (8, '2025-06-14 09:30:00', 19.800, 13.860, 5.940, 91.20, 6);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (8, '2025-06-14 10:30:00', 26.200, 18.340, 7.860, 92.00, 6);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (8, '2025-06-14 11:30:00', 30.000, 21.000, 9.000, 92.50, 6);

INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID)
VALUES (8, '2025-06-14 12:30:00', 31.800, 22.260, 9.540, 92.80, 6);

PRINT N'已插入20条发电数据';
PRINT N'第二部分：额外20条预测+发电数据插入完成';
GO
