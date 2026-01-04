/* ============================================================
   告警业务线整合脚本 (修复版)
   负责人：李振梁
   修复内容：
   1. 脚本头部增加 IDENTITY_INSERT 强制关闭逻辑，防止会话状态残留。
   2. 增加 Verify_Status 字段及约束的标准化重建，解决约束冲突。
   3. 修正 MERGE 语句，确保字段映射完全正确。
   ============================================================ */

USE SQL_BFU;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- 遇到错误自动回滚事务

/* ============================================================
   0. 【关键修复】防御性清理：强制关闭可能残留的 IDENTITY_INSERT
   ============================================================ */
BEGIN TRY SET IDENTITY_INSERT dbo.Device_Ledger OFF; END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT dbo.Alarm_Info OFF;    END TRY BEGIN CATCH END CATCH;
BEGIN TRY SET IDENTITY_INSERT dbo.Work_Order OFF;    END TRY BEGIN CATCH END CATCH;
GO

/* ============================================================
   1. 【关键修复】标准化表结构与约束
      确保 Alarm_Info 表拥有 Verify_Status 字段且约束与数据一致
   ============================================================ */
-- 1.1 确保字段存在
IF COL_LENGTH('dbo.Alarm_Info', 'Verify_Status') IS NULL
BEGIN
    ALTER TABLE dbo.Alarm_Info ADD Verify_Status NVARCHAR(20) NULL;
END
GO

-- 1.2 重建约束 (防止因约束定义不同（如'待核实' vs '待审核'）导致的报错)
IF OBJECT_ID('CK_Alarm_Verify', 'C') IS NOT NULL 
    ALTER TABLE dbo.Alarm_Info DROP CONSTRAINT CK_Alarm_Verify;
IF OBJECT_ID('CK_Alarm_Verify_Status', 'C') IS NOT NULL 
    ALTER TABLE dbo.Alarm_Info DROP CONSTRAINT CK_Alarm_Verify_Status;
GO

ALTER TABLE dbo.Alarm_Info ADD CONSTRAINT CK_Alarm_Verify 
    CHECK (Verify_Status IN (N'待审核', N'有效', N'误报') OR Verify_Status IS NULL);
GO

/* ============================================================
   2. 触发器：同步告警状态 + 写处理日志
   ============================================================ */
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

    -- 将 inserted 和 deleted 的对比结果写入表变量
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

    -- 2.1 同步 Alarm_Info.Process_Status
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

    -- 2.2 派单日志
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

    -- 2.3 结案日志
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

/* ============================================================
   3. 视图（4 个）
   ============================================================ */
-- 视图 1
IF OBJECT_ID('dbo.View_Alarm_Pending_High_Simple', 'V') IS NOT NULL DROP VIEW dbo.View_Alarm_Pending_High_Simple;
GO
CREATE VIEW dbo.View_Alarm_Pending_High_Simple AS
SELECT Alarm_ID, Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Trigger_Threshold
FROM dbo.Alarm_Info
WHERE Alarm_Level = N'高' AND Process_Status = N'未处理';
GO

-- 视图 2
IF OBJECT_ID('dbo.View_High_Alarm_Dispatch_SLA', 'V') IS NOT NULL DROP VIEW dbo.View_High_Alarm_Dispatch_SLA;
GO
CREATE VIEW dbo.View_High_Alarm_Dispatch_SLA AS
SELECT
    a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, a.Process_Status,
    w.Dispatch_Time AS First_Dispatch_Time,
    CASE WHEN w.Dispatch_Time IS NULL THEN NULL ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) END AS Dispatch_Duration_Min,
    CASE WHEN w.Dispatch_Time IS NULL THEN N'未派单' WHEN DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) <= 15 THEN N'正常' ELSE N'超时' END AS SLA_Status
FROM dbo.Alarm_Info a
LEFT JOIN dbo.Work_Order w ON a.Alarm_ID = w.Alarm_ID
WHERE a.Alarm_Level = N'高';
GO

-- 视图 3
IF OBJECT_ID('dbo.View_OandM_Workload_Summary', 'V') IS NOT NULL DROP VIEW dbo.View_OandM_Workload_Summary;
GO
CREATE VIEW dbo.View_OandM_Workload_Summary AS
SELECT
    o.OandM_ID, u.Real_Name, u.Department,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN w.Finish_Time IS NOT NULL AND w.Review_Status = N'通过' THEN 1 ELSE 0 END) AS Finished_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'高' THEN 1 ELSE 0 END) AS High_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'中' THEN 1 ELSE 0 END) AS Mid_Orders,
    SUM(CASE WHEN a.Alarm_Level = N'低' THEN 1 ELSE 0 END) AS Low_Orders,
    AVG(CASE WHEN w.Response_Time IS NOT NULL AND w.Dispatch_Time IS NOT NULL THEN DATEDIFF(MINUTE, w.Dispatch_Time, w.Response_Time) END) AS Avg_Response_Min,
    AVG(CASE WHEN w.Finish_Time IS NOT NULL AND w.Dispatch_Time IS NOT NULL THEN DATEDIFF(MINUTE, w.Dispatch_Time, w.Finish_Time) END) AS Avg_Handle_Min
FROM dbo.Work_Order w
JOIN dbo.Role_OandM o ON w.OandM_ID = o.OandM_ID
JOIN dbo.Sys_User u ON o.User_ID = u.User_ID
JOIN dbo.Alarm_Info a ON w.Alarm_ID = a.Alarm_ID
GROUP BY o.OandM_ID, u.Real_Name, u.Department;
GO

-- 视图 4
IF OBJECT_ID('dbo.View_Alarm_Process_Efficiency', 'V') IS NOT NULL DROP VIEW dbo.View_Alarm_Process_Efficiency;
GO
CREATE VIEW dbo.View_Alarm_Process_Efficiency AS
SELECT
    a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, a.Process_Status,
    w.Dispatch_Time AS First_Dispatch_Time,
    w.Finish_Time   AS Last_Finish_Time,
    CASE WHEN w.Dispatch_Time IS NULL THEN NULL ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Dispatch_Time) END AS Response_Duration_Min,
    CASE WHEN w.Finish_Time IS NULL THEN NULL ELSE DATEDIFF(MINUTE, a.Occur_Time, w.Finish_Time) END AS Total_Duration_Min
FROM dbo.Alarm_Info a
LEFT JOIN dbo.Work_Order w ON a.Alarm_ID = w.Alarm_ID;
GO

/* ============================================================
   4. 测试数据插入 (幂等 Upsert)
   ============================================================ */
BEGIN TRY
    BEGIN TRAN;

    -- 4.1 确保人员存在
    IF NOT EXISTS (SELECT 1 FROM dbo.Sys_User WHERE Login_Account = N'om_user')
        INSERT INTO dbo.Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Account_Status) VALUES (N'om_user', REPLICATE(N'0',64), REPLICATE(N'0',32), N'张运维', N'运维部', 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.Sys_User WHERE Login_Account = N'dispatcher')
        INSERT INTO dbo.Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Account_Status) VALUES (N'dispatcher', REPLICATE(N'1',64), REPLICATE(N'1',32), N'李调度', N'运维调度', 1);

    DECLARE @OmUserId BIGINT = (SELECT User_ID FROM dbo.Sys_User WHERE Login_Account = N'om_user');
    DECLARE @DispUserId BIGINT = (SELECT User_ID FROM dbo.Sys_User WHERE Login_Account = N'dispatcher');

    -- 4.2 确保角色存在
    IF NOT EXISTS (SELECT 1 FROM dbo.Role_OandM WHERE User_ID = @OmUserId) INSERT INTO dbo.Role_OandM(User_ID) VALUES (@OmUserId);
    IF NOT EXISTS (SELECT 1 FROM dbo.Role_Dispatcher WHERE User_ID = @DispUserId) INSERT INTO dbo.Role_Dispatcher(User_ID) VALUES (@DispUserId);

    DECLARE @OandM_ID BIGINT = (SELECT MIN(OandM_ID) FROM dbo.Role_OandM WHERE User_ID = @OmUserId);
    DECLARE @Dispatcher_ID BIGINT = (SELECT MIN(Dispatcher_ID) FROM dbo.Role_Dispatcher WHERE User_ID = @DispUserId);

    -- 4.3 Upsert：Device_Ledger
    SET IDENTITY_INSERT dbo.Device_Ledger ON;
    MERGE dbo.Device_Ledger AS T
    USING (VALUES
        (1, N'变压器1号', N'变压器', N'S11-1000kVA', CONVERT(date,'2024-01-01'), 2, CONVERT(datetime2(0),'2025-06-01 10:00:00'), N'张运维', N'正常使用'),
        (2, N'电表1号', N'电表', N'DTSD-341', CONVERT(date,'2024-03-01'), 1, CONVERT(datetime2(0),'2025-05-15 09:30:00'), N'李运维', N'正常使用'),
        (3, N'逆变器1号', N'逆变器', N'INV-50kW', CONVERT(date,'2024-02-15'), 3, NULL, NULL, N'正常使用'),
        (4, N'环境传感器1', N'其他', N'TH-01', CONVERT(date,'2024-04-01'), 1, CONVERT(datetime2(0),'2025-04-10 14:00:00'), N'王运维', N'正常使用')
    ) AS S(Ledger_ID, Device_Name, Device_Type, Model_Spec, Install_Time, Warranty_Years, Calibration_Time, Calibration_Person, Scrap_Status)
    ON T.Ledger_ID = S.Ledger_ID
    WHEN MATCHED THEN UPDATE SET
        T.Device_Name = S.Device_Name, T.Device_Type = S.Device_Type, T.Model_Spec = S.Model_Spec, T.Install_Time = S.Install_Time,
        T.Warranty_Years = S.Warranty_Years, T.Calibration_Time = S.Calibration_Time, T.Calibration_Person = S.Calibration_Person, T.Scrap_Status = S.Scrap_Status
    WHEN NOT MATCHED THEN
        INSERT (Ledger_ID, Device_Name, Device_Type, Model_Spec, Install_Time, Warranty_Years, Calibration_Time, Calibration_Person, Scrap_Status)
        VALUES (S.Ledger_ID, S.Device_Name, S.Device_Type, S.Model_Spec, S.Install_Time, S.Warranty_Years, S.Calibration_Time, S.Calibration_Person, S.Scrap_Status);
    SET IDENTITY_INSERT dbo.Device_Ledger OFF;

    -- 4.4 Upsert：Alarm_Info (包含 Verify_Status，解决约束冲突)
    SET IDENTITY_INSERT dbo.Alarm_Info ON;
    MERGE dbo.Alarm_Info AS T
    USING (VALUES
        -- 新产生的告警->待审核->只能是未处理，误报的告警->已结案, 有效->未处理/处理中/已结案。
        (1,  N'越限告警', N'高', N'变压器1绕组温度超限',        CONVERT(datetime2(0),'2025-12-30 09:00:00'), N'未处理',  80.0, 1, NULL, N'待审核'),
        (2,  N'设备故障', N'高', N'变压器1油位异常',            CONVERT(datetime2(0),'2025-12-30 09:10:00'), N'未处理',  NULL, 1, NULL, N'待审核'),
        (3,  N'通讯故障', N'高', N'电表1通讯中断',              CONVERT(datetime2(0),'2025-12-30 09:20:00'), N'未处理',  NULL, 2, NULL, N'待审核'),
        (4,  N'越限告警', N'高', N'回路1电流过载',              CONVERT(datetime2(0),'2025-12-30 09:30:00'), N'已结案', 100.0, 2, NULL, N'误报'),
        (5,  N'设备故障', N'高', N'逆变器1故障停机',            CONVERT(datetime2(0),'2025-12-30 09:40:00'), N'已结案',  NULL, 3, NULL, N'有效'),
        (6,  N'设备离线', N'高', N'逆变器1短暂离线',            CONVERT(datetime2(0),'2025-12-30 09:50:00'), N'处理中',  NULL, 3, NULL, N'有效'),
        (7,  N'环境告警', N'高', N'配电室A温度过高',            CONVERT(datetime2(0),'2025-12-30 10:00:00'), N'已结案',  35.0, 4, NULL, N'有效'),
        (8,  N'安全告警', N'高', N'配电室A门禁异常',            CONVERT(datetime2(0),'2025-12-30 10:10:00'), N'已结案',  NULL, 4, NULL, N'有效'),
        (9,  N'通讯故障', N'中', N'水表1通讯波动',              CONVERT(datetime2(0),'2025-12-30 11:00:00'), N'未处理',  NULL, 2, NULL, N'待审核'),
        (10, N'设备故障', N'中', N'电表2精度异常',              CONVERT(datetime2(0),'2025-12-30 11:10:00'), N'处理中',  NULL, 2, NULL, N'有效'),
        (11, N'越限告警', N'中', N'回路2功率因数偏低',          CONVERT(datetime2(0),'2025-12-30 11:20:00'), N'已结案',  95.0, 2, NULL, N'有效'),
        (12, N'设备离线', N'中', N'环境传感器1网络掉线',        CONVERT(datetime2(0),'2025-12-30 11:30:00'), N'已结案',  NULL, 4, NULL, N'有效'),
        (13, N'环境告警', N'中', N'配电室B湿度过高',            CONVERT(datetime2(0),'2025-12-30 11:40:00'), N'未处理',  70.0, 4, NULL, N'待审核'),
        (14, N'安全告警', N'中', N'非法刷卡失败多次',            CONVERT(datetime2(0),'2025-12-30 11:50:00'), N'已结案',  NULL, 4, NULL, N'有效'),
        (15, N'通讯故障', N'低', N'临时测试点通讯丢包',         CONVERT(datetime2(0),'2025-12-30 12:00:00'), N'未处理',  NULL, 2, NULL, N'待审核'),
        (16, N'越限告警', N'低', N'支路电流轻微超限',           CONVERT(datetime2(0),'2025-12-30 12:10:00'), N'已结案', 110.0, 2, NULL, N'有效'),
        (17, N'设备故障', N'低', N'指示灯损坏',                 CONVERT(datetime2(0),'2025-12-30 12:20:00'), N'处理中',  NULL, 3, NULL, N'有效'),
        (18, N'环境告警', N'低', N'仓库温度略有波动',           CONVERT(datetime2(0),'2025-12-30 12:30:00'), N'已结案',  NULL, 4, NULL, N'误报'),
        (19, N'安全告警', N'低', N'异常登录告警',               CONVERT(datetime2(0),'2025-12-30 12:40:00'), N'已结案',  NULL, 4, NULL, N'有效'),
        (20, N'其他',     N'低', N'测试用告警',                 CONVERT(datetime2(0),'2025-12-30 12:50:00'), N'未处理',  NULL, 1, NULL, N'待审核')
    ) AS S(Alarm_ID, Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Trigger_Threshold, Ledger_ID, Factory_ID, Verify_Status)
    ON T.Alarm_ID = S.Alarm_ID
    WHEN MATCHED THEN UPDATE SET
        T.Alarm_Type = S.Alarm_Type, T.Alarm_Level = S.Alarm_Level, T.Content = S.Content,
        T.Occur_Time = S.Occur_Time, T.Process_Status = S.Process_Status, T.Trigger_Threshold = S.Trigger_Threshold,
        T.Ledger_ID = S.Ledger_ID, T.Factory_ID = S.Factory_ID,
        T.Verify_Status = S.Verify_Status -- 【修正】更新时同步 Verify_Status
    WHEN NOT MATCHED THEN
        INSERT (Alarm_ID, Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Trigger_Threshold, Ledger_ID, Factory_ID, Verify_Status)
        VALUES (S.Alarm_ID, S.Alarm_Type, S.Alarm_Level, S.Content, S.Occur_Time, S.Process_Status, S.Trigger_Threshold, S.Ledger_ID, S.Factory_ID, S.Verify_Status); -- 【修正】插入时写入 Verify_Status

    SET IDENTITY_INSERT dbo.Alarm_Info OFF;

    -- 4.5 Upsert：Work_Order
    SET IDENTITY_INSERT dbo.Work_Order ON;
    MERGE dbo.Work_Order AS T
    USING (VALUES
        (1, 1, @OandM_ID, @Dispatcher_ID, 1, NULL, NULL, NULL, N'变压器1高温告警，尚未派单', NULL, NULL),
        (2, 2, @OandM_ID, @Dispatcher_ID, 1, CONVERT(datetime2(0),'2025-12-30 09:20:00'), CONVERT(datetime2(0),'2025-12-30 09:30:00'), CONVERT(datetime2(0),'2025-12-30 10:00:00'), N'检查油位，排气阀调整，告警消除', N'通过', N'/files/wo_2_pic1.jpg'),
        (3, 3, @OandM_ID, @Dispatcher_ID, 2, CONVERT(datetime2(0),'2025-12-30 09:45:00'), CONVERT(datetime2(0),'2025-12-30 10:00:00'), NULL, N'通讯模块复位后仍不稳定，待更换', N'未通过', N'/files/wo_3_log.txt'),
        (4, 4, @OandM_ID, @Dispatcher_ID, 2, NULL, NULL, NULL, N'回路1电流过载，调度已锁定待确认', NULL, NULL),
        (5, 5, @OandM_ID, @Dispatcher_ID, 3, CONVERT(datetime2(0),'2025-12-30 09:45:00'), CONVERT(datetime2(0),'2025-12-30 09:55:00'), CONVERT(datetime2(0),'2025-12-30 11:00:00'), N'逆变器1更换风扇模块，恢复正常', N'通过', N'/files/wo_5_report.pdf'),
        (6, 6, @OandM_ID, @Dispatcher_ID, 3, CONVERT(datetime2(0),'2025-12-30 10:20:00'), CONVERT(datetime2(0),'2025-12-30 10:40:00'), NULL, N'逆变器1短暂离线，现场检查未发现明显问题', N'未通过', NULL),
        (7, 7, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 10:05:00'), CONVERT(datetime2(0),'2025-12-30 10:20:00'), CONVERT(datetime2(0),'2025-12-30 11:30:00'), N'增加通风，空调检修，温度恢复正常', N'通过', N'/files/wo_7_pic.png'),
        (8, 8, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 10:25:00'), CONVERT(datetime2(0),'2025-12-30 10:40:00'), CONVERT(datetime2(0),'2025-12-30 11:10:00'), N'门禁系统日志排查，无异常入侵，调整告警阈值', N'通过', NULL),
        (9, 9, @OandM_ID, @Dispatcher_ID, 2, NULL, NULL, NULL, N'水表1通讯波动，尚未安排现场处理', NULL, NULL),
        (10, 10, @OandM_ID, @Dispatcher_ID, 2, CONVERT(datetime2(0),'2025-12-30 11:30:00'), CONVERT(datetime2(0),'2025-12-30 11:50:00'), NULL, N'电表2精度异常，已远程校准，待复测', N'未通过', N'/files/wo_10_tmp.txt'),
        (11, 11, @OandM_ID, @Dispatcher_ID, 2, CONVERT(datetime2(0),'2025-12-30 11:30:00'), CONVERT(datetime2(0),'2025-12-30 11:40:00'), CONVERT(datetime2(0),'2025-12-30 12:10:00'), N'调整无功补偿装置，功率因数恢复', N'通过', N'/files/wo_11_report.docx'),
        (12, 12, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 11:40:00'), CONVERT(datetime2(0),'2025-12-30 11:55:00'), CONVERT(datetime2(0),'2025-12-30 12:30:00'), N'更换环境传感器1网络模块', N'通过', NULL),
        (13, 13, @OandM_ID, @Dispatcher_ID, 4, NULL, NULL, NULL, N'配电室B湿度过高，待现场确认', NULL, NULL),
        (14, 14, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 12:00:00'), CONVERT(datetime2(0),'2025-12-30 12:10:00'), CONVERT(datetime2(0),'2025-12-30 12:40:00'), N'门禁策略优化，增加告警阈值及白名单', N'通过', N'/files/wo_14_pic.jpg'),
        (15, 15, @OandM_ID, @Dispatcher_ID, 2, NULL, NULL, NULL, N'临时测试点通讯丢包，暂不处理', NULL, NULL),
        (16, 16, @OandM_ID, @Dispatcher_ID, 2, CONVERT(datetime2(0),'2025-12-30 12:20:00'), CONVERT(datetime2(0),'2025-12-30 12:30:00'), CONVERT(datetime2(0),'2025-12-30 13:00:00'), N'支路电流轻微超限，优化负载分配', N'通过', NULL),
        (17, 17, @OandM_ID, @Dispatcher_ID, 3, CONVERT(datetime2(0),'2025-12-30 12:30:00'), CONVERT(datetime2(0),'2025-12-30 12:50:00'), NULL, N'更换指示灯，待复查', N'未通过', NULL),
        (18, 18, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 12:40:00'), CONVERT(datetime2(0),'2025-12-30 13:00:00'), CONVERT(datetime2(0),'2025-12-30 13:30:00'), N'仓库空调调节，温度恢复正常', N'通过', N'/files/wo_18_pic.png'),
        (19, 19, @OandM_ID, @Dispatcher_ID, 4, CONVERT(datetime2(0),'2025-12-30 12:50:00'), CONVERT(datetime2(0),'2025-12-30 13:05:00'), CONVERT(datetime2(0),'2025-12-30 13:40:00'), N'安全日志核查，确认为误报，调整策略', N'通过', NULL),
        (20, 20, @OandM_ID, @Dispatcher_ID, 1, NULL, NULL, NULL, N'测试用告警，对应虚拟工单，不处理', NULL, NULL)
    ) AS S(Order_ID, Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status, Attachment_Path)
    ON T.Order_ID = S.Order_ID
    WHEN MATCHED THEN UPDATE SET
        T.Alarm_ID = S.Alarm_ID, T.OandM_ID = S.OandM_ID, T.Dispatcher_ID = S.Dispatcher_ID, T.Ledger_ID = S.Ledger_ID,
        T.Dispatch_Time = S.Dispatch_Time, T.Response_Time = S.Response_Time, T.Finish_Time = S.Finish_Time,
        T.Result_Desc = S.Result_Desc, T.Review_Status = S.Review_Status, T.Attachment_Path = S.Attachment_Path
    WHEN NOT MATCHED THEN
        INSERT (Order_ID, Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status, Attachment_Path)
        VALUES (S.Order_ID, S.Alarm_ID, S.OandM_ID, S.Dispatcher_ID, S.Ledger_ID, S.Dispatch_Time, S.Response_Time, S.Finish_Time, S.Result_Desc, S.Review_Status, S.Attachment_Path);
    SET IDENTITY_INSERT dbo.Work_Order OFF;

    COMMIT TRAN;
    PRINT N'告警业务线整合脚本执行完成：约束/视图/触发器/测试数据已就绪。';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    -- 打印详细错误以方便调试
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'Error occurred: ' + @msg;
    THROW 53000, @msg, 1;
END CATCH;
GO