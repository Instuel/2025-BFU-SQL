/* ============================================================
   智慧能源管理系统 - 数据库结构增量修改脚本
   目标数据库：SQL_BFU
   修改内容：
   1) Alarm_Info   ：增加告警触发阈值字段 + 告警类型 CHECK 约束
   2) Work_Order   ：增加附件路径字段 + 复查状态 CHECK 约束
   3) Device_Ledger：增加质保期、校准时间、校准人员字段
   说明：均使用 ALTER，不破坏原有主外键结构
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   一、Alarm_Info 表修改
   1) 增加告警触发阈值字段 Trigger_Threshold
   2) 为告警类型 Alarm_Type 增加 CHECK 约束 CK_Alarm_Type
   ============================================================ */

-- 1.1 增加告警触发阈值字段
IF COL_LENGTH('Alarm_Info', 'Trigger_Threshold') IS NULL
BEGIN
    ALTER TABLE Alarm_Info
    ADD Trigger_Threshold DECIMAL(12,3) NULL;  -- 告警触发阈值，如温度/电压上限
END
GO

-- 1.2 为告警类型增加 CHECK 约束（任务书三种 + 实际扩展几种，其他归为“其他”）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_Alarm_Type'
      AND parent_object_id = OBJECT_ID('Alarm_Info')
)
BEGIN
    ALTER TABLE Alarm_Info
    ADD CONSTRAINT CK_Alarm_Type
        CHECK (Alarm_Type IN (
            N'越限告警',   -- 任务书原有
            N'通讯故障',   -- 任务书原有
            N'设备故障',   -- 任务书原有
            N'设备离线',   -- 实际常见：设备掉线
            N'环境告警',   -- 机房温湿度等
            N'安全告警',   -- 安全/权限相关
            N'其他'        -- 兜底类型
        ));
END
GO


/* ============================================================
   二、Work_Order 表修改
   1) 增加附件路径字段 Attachment_Path
   2) 为复查状态 Review_Status 增加 CHECK 约束 CK_WorkOrder_Review_Status
   说明：保留原有 Ledger_ID 外键，实现
         “一个工单只对应一个设备，一个设备可以对应多个工单”
   ============================================================ */

-- 2.1 增加附件路径字段（存放故障现场照片路径或 URL）
IF COL_LENGTH('Work_Order', 'Attachment_Path') IS NULL
BEGIN
    ALTER TABLE Work_Order
    ADD Attachment_Path NVARCHAR(260) NULL;   -- 路径/URL
END
GO

-- 2.2 为复查状态增加 CHECK 约束（通过 / 未通过 / 未复查(NULL)）
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_WorkOrder_Review_Status'
      AND parent_object_id = OBJECT_ID('Work_Order')
)
BEGIN
    ALTER TABLE Work_Order
    ADD CONSTRAINT CK_WorkOrder_Review_Status
        CHECK (Review_Status IN (N'通过', N'未通过') OR Review_Status IS NULL);
END
GO


/* ============================================================
   三、Device_Ledger 表修改
   1) 增加质保期（年）字段 Warranty_Years
   2) 增加校准时间字段 Calibration_Time
   3) 增加校准人员字段 Calibration_Person
   说明：维修记录（关联工单编号）通过
         Work_Order.Ledger_ID 一对多关系实现
         某设备的所有维修记录 = 所有关联工单
   ============================================================ */

-- 3.1 增加质保期（年）字段
IF COL_LENGTH('Device_Ledger', 'Warranty_Years') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Warranty_Years INT NULL;           -- 例如 1 / 2 / 3 年
END
GO

-- 3.2 增加校准时间字段
IF COL_LENGTH('Device_Ledger', 'Calibration_Time') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Calibration_Time DATETIME2(0) NULL;  -- 最近一次校准时间
END
GO

-- 3.3 增加校准人员字段
IF COL_LENGTH('Device_Ledger', 'Calibration_Person') IS NULL
BEGIN
    ALTER TABLE Device_Ledger
    ADD Calibration_Person NVARCHAR(50) NULL; -- 最近一次校准人员
END
GO

PRINT '增量结构修改完成：Alarm_Info / Work_Order / Device_Ledger 已按任务书要求更新。';
