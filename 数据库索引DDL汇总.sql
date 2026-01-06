/* ============================================================
   智慧能源管理系统 - 数据库索引DDL汇总
   Smart Energy Management System - Database Index DDL Summary
   
   整理日期: 2026-01-06
   数据库: SQL_BFU (SQL Server)
   
   说明：本文件按业务线整合了所有索引的DDL语句，
         包含主脚本和补丁中的所有索引定义。
   
   索引分类：
   1. 基础系统与人员权限索引
   2. 配电网监测业务线索引
   3. 综合能耗管理业务线索引
   4. 分布式光伏管理业务线索引
   5. 告警运维管理业务线索引
   6. 大屏数据展示业务线索引
   7. 数据分析师功能扩展索引
   ============================================================ */

USE SQL_BFU;
GO

/* ============================================================
   第一部分：基础系统与人员权限索引
   ============================================================ */

-- 1.1 系统人员表：登录账号唯一索引（加速登录验证）
-- 来源：main.sql 基础脚本
-- 用途：确保登录账号唯一性，同时加速登录时的账号查询
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_SysUser_Login' AND object_id = OBJECT_ID('dbo.Sys_User'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IDX_SysUser_Login 
    ON Sys_User (Login_Account);
    PRINT '已创建索引: IDX_SysUser_Login (系统人员登录加速)';
END
GO


/* ============================================================
   第二部分：配电网监测业务线索引
   负责人：张恺洋
   ============================================================ */

-- 2.1 变压器监测数据表：时间序列查询索引
-- 来源：main.sql 基础脚本
-- 用途：按变压器ID和采集时间快速查询历史监测数据
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Trans_Time' AND object_id = OBJECT_ID('dbo.Data_Transformer'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Trans_Time 
    ON Data_Transformer (Transformer_ID, Collect_Time);
    PRINT '已创建索引: IDX_Trans_Time (变压器时间序列查询)';
END
GO

-- 2.2 回路监测数据表：历史趋势查询索引
-- 来源：main.sql 基础脚本
-- 用途：按回路ID和采集时间查询历史趋势数据
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Circuit_History' AND object_id = OBJECT_ID('dbo.Data_Circuit'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Circuit_History 
    ON Data_Circuit (Circuit_ID, Collect_Time);
    PRINT '已创建索引: IDX_Circuit_History (回路历史趋势查询)';
END
GO

-- 2.3 回路监测数据表：厂区实时状态查询索引
-- 来源：main.sql 基础脚本
-- 用途：按厂区查询最新的回路监测状态，支持大屏实时展示
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Circuit_Factory_RT' AND object_id = OBJECT_ID('dbo.Data_Circuit'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Circuit_Factory_RT 
    ON Data_Circuit (Factory_ID, Collect_Time DESC);
    PRINT '已创建索引: IDX_Circuit_Factory_RT (厂区实时状态查询)';
END
GO


/* ============================================================
   第三部分：综合能耗管理业务线索引
   负责人：杨昊田
   ============================================================ */

-- 3.1 能耗计量设备表：厂区与能源类型复合索引
-- 来源：视图+触发器&存储过程+测试数据/综合能耗.sql
-- 用途：按厂区和能源类型查询设备，支持设备管理与统计分析
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Meter_Factory_Type' AND object_id = OBJECT_ID('dbo.Energy_Meter'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Meter_Factory_Type 
    ON Energy_Meter (Factory_ID, Energy_Type, Run_Status)
    INCLUDE (Install_Location, Calib_Cycle_Months);
    PRINT '已创建索引: IDX_Meter_Factory_Type (设备厂区类型查询)';
END
GO

-- 3.2 能耗监测数据表：设备时间序列索引
-- 来源：视图+触发器&存储过程+测试数据/综合能耗.sql
-- 用途：按设备ID和时间查询历史能耗数据
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Energy_Time' AND object_id = OBJECT_ID('dbo.Data_Energy'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Energy_Time 
    ON Data_Energy (Meter_ID, Collect_Time DESC)
    INCLUDE (Value, Quality);
    PRINT '已创建索引: IDX_Energy_Time (能耗时间序列查询)';
END
GO

-- 3.3 能耗监测数据表：数据质量筛选索引
-- 来源：视图+触发器&存储过程+测试数据/综合能耗.sql
-- 用途：按厂区和数据质量筛选异常数据，支持数据复核功能
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Energy_Quality' AND object_id = OBJECT_ID('dbo.Data_Energy'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Energy_Quality 
    ON Data_Energy (Factory_ID, Quality, Collect_Time DESC);
    PRINT '已创建索引: IDX_Energy_Quality (数据质量筛选)';
END
GO

-- 3.4 峰谷能耗数据表：报表统计核心索引
-- 来源：main.sql 基础脚本
-- 用途：峰谷能耗报表统计，按日期、能源类型、厂区快速聚合
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PeakValley_Rpt' AND object_id = OBJECT_ID('dbo.Data_PeakValley'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PeakValley_Rpt 
    ON Data_PeakValley (Stat_Date, Energy_Type, Factory_ID);
    PRINT '已创建索引: IDX_PeakValley_Rpt (峰谷报表统计)';
END
GO

-- 3.5 峰谷能耗数据表：报表详细统计索引（扩展版）
-- 来源：视图+触发器&存储过程+测试数据/综合能耗.sql
-- 用途：包含峰谷类型的完整报表统计，覆盖消耗量和成本
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PeakValley_Report' AND object_id = OBJECT_ID('dbo.Data_PeakValley'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PeakValley_Report 
    ON Data_PeakValley (Stat_Date, Energy_Type, Factory_ID, Peak_Type)
    INCLUDE (Total_Consumption, Cost_Amount);
    PRINT '已创建索引: IDX_PeakValley_Report (峰谷详细报表)';
END
GO

-- 3.6 峰谷能耗数据表：厂区统计索引
-- 来源：视图+触发器&存储过程+测试数据/综合能耗.sql
-- 用途：按厂区查询能耗趋势，支持厂区能耗对比分析
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PeakValley_Factory' AND object_id = OBJECT_ID('dbo.Data_PeakValley'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PeakValley_Factory 
    ON Data_PeakValley (Factory_ID, Stat_Date DESC);
    PRINT '已创建索引: IDX_PeakValley_Factory (厂区能耗趋势)';
END
GO


/* ============================================================
   第四部分：分布式光伏管理业务线索引
   负责人：段泓冰
   ============================================================ */

-- 4.1 光伏预测数据表：并网点-日期-时段精准匹配索引（覆盖常用对比字段）
-- 来源：main.sql 基础脚本
-- 用途：按 Point_ID + Forecast_Date + Time_Slot 快速定位单条预测记录；覆盖 Forecast_Val/Actual_Val 等字段，
--      支持“预测 vs 实际”对比、偏差计算、按模型版本/分析师维度统计等高频查询，减少回表
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Data_PV_Forecast_PointDateSlot'
      AND object_id = OBJECT_ID('dbo.Data_PV_Forecast')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Data_PV_Forecast_PointDateSlot
    ON dbo.Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot)
    INCLUDE (Forecast_Val, Actual_Val, Model_Version, Analyst_ID);

    PRINT '已创建索引: IX_Data_PV_Forecast_PointDateSlot (光伏预测精准匹配-覆盖字段)';
END
GO

-- 4.2 光伏发电采集数据表：设备-采集时间倒序查询索引（支持最新数据/时间窗分析）
-- 来源：main.sql 基础脚本
-- 用途：按 Device_ID + Collect_Time(倒序) 快速获取设备最新采集数据、近N分钟/近N天曲线与统计；
--      覆盖电量与效率字段，支撑设备运行分析、效率筛查、按并网点聚合等查询，提升“取最近一条/分页”性能
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Data_PV_Gen_DeviceTime'
      AND object_id = OBJECT_ID('dbo.Data_PV_Gen')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Data_PV_Gen_DeviceTime
    ON dbo.Data_PV_Gen (Device_ID, Collect_Time DESC)
    INCLUDE (Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Point_ID);

    PRINT '已创建索引: IX_Data_PV_Gen_DeviceTime (发电采集-设备最新数据倒序)';
END
GO

-- 4.3 光伏模型告警表：并网点-模型版本-触发时间倒序索引（告警检索与处理闭环）
-- 来源：main.sql 基础脚本
-- 用途：按 Point_ID + Model_Version + Trigger_Time(倒序) 快速查询最新/历史模型告警；
--      覆盖 Process_Status，支撑“未处理告警列表、按模型版本追溯、按时间段统计”等场景，减少回表与排序开销
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_PV_Model_Alert_PointModelTime'
      AND object_id = OBJECT_ID('dbo.PV_Model_Alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_PV_Model_Alert_PointModelTime
    ON dbo.PV_Model_Alert (Point_ID, Model_Version, Trigger_Time DESC)
    INCLUDE (Process_Status);

    PRINT '已创建索引: IX_PV_Model_Alert_PointModelTime (模型告警-最新告警检索)';
END
GO

-- 4.4 光伏设备表：设备类型-并网点筛选索引（设备清单与运行状态查询）
-- 来源：main.sql 基础脚本
-- 用途：按 Device_Type + Point_ID 快速筛选某并网点下的某类设备（如逆变器/电表等）；
--      覆盖 Device_ID、Run_Status、Ledger_ID、Capacity，支撑设备台账查询、运行状态统计、容量汇总等常用报表，降低回表成本
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_PV_Device_TypePoint'
      AND object_id = OBJECT_ID('dbo.PV_Device')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_PV_Device_TypePoint
    ON dbo.PV_Device (Device_Type, Point_ID)
    INCLUDE (Device_ID, Run_Status, Ledger_ID, Capacity);

    PRINT '已创建索引: IX_PV_Device_TypePoint (设备表-类型与并网点筛选覆盖)';
END
GO




/* ============================================================
   第五部分：告警运维管理业务线索引
   负责人：李振梁
   ============================================================ */

-- 5.1 告警信息表：大屏多维过滤索引
-- 来源：main.sql 基础脚本
-- 用途：大屏展示核心索引，支持按处理状态、告警等级、发生时间多维筛选
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Alarm_Dashboard' AND object_id = OBJECT_ID('dbo.Alarm_Info'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Alarm_Dashboard 
    ON Alarm_Info (Process_Status, Alarm_Level, Occur_Time)
    INCLUDE (Factory_ID);
    PRINT '已创建索引: IDX_Alarm_Dashboard (告警大屏多维过滤)';
END
GO

-- 5.2 运维工单表：告警关联唯一索引
-- 来源：main.sql 基础脚本
-- 用途：保证"一告警一工单"业务规则，同时加速告警关联查询
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Work_Order_Alarm_ID' AND object_id = OBJECT_ID('dbo.Work_Order'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Work_Order_Alarm_ID
    ON Work_Order(Alarm_ID);
    PRINT '已创建索引: UX_Work_Order_Alarm_ID (工单告警唯一关联)';
END
GO

-- 5.3 维护计划表：设备计划查询索引
-- 来源：patch.sql 补丁脚本
-- 用途：按设备台账ID和计划日期快速查询维护计划
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MaintPlan_Ledger_PlanDate' AND object_id = OBJECT_ID('dbo.Maintenance_Plan'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_MaintPlan_Ledger_PlanDate
    ON Maintenance_Plan(Ledger_ID, Plan_Date, Plan_ID);
    PRINT '已创建索引: IX_MaintPlan_Ledger_PlanDate (维护计划设备查询)';
END
GO


/* ============================================================
   第六部分：大屏数据展示业务线索引
   负责人：杨尧天
   ============================================================ */

-- 6.1 大屏展示配置表：配置编码唯一索引
-- 来源：main.sql + patch.sql
-- 用途：确保配置编码唯一，支持幂等插入数据
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dashboard_Config_Config_Code' AND object_id = OBJECT_ID('dbo.Dashboard_Config'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Dashboard_Config_Config_Code
    ON Dashboard_Config(Config_Code)
    WHERE Config_Code IS NOT NULL;
    PRINT '已创建索引: UX_Dashboard_Config_Config_Code (配置编码唯一)';
END
GO

-- 6.2 实时汇总数据表：统计时间索引
-- 来源：main.sql 大屏业务线扩展
-- 用途：按时间降序快速获取最新汇总数据，支持大屏实时刷新
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Stat_Realtime_Stat_Time' AND object_id = OBJECT_ID('dbo.Stat_Realtime'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Stat_Realtime_Stat_Time 
    ON Stat_Realtime(Stat_Time DESC);
    PRINT '已创建索引: IX_Stat_Realtime_Stat_Time (实时汇总时间查询)';
END
GO

-- 6.3 历史趋势数据表：日期与能源类型复合索引
-- 来源：main.sql 大屏业务线扩展
-- 用途：支持历史趋势分析，按日期和能源类型快速聚合
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trend_Date_Type' AND object_id = OBJECT_ID('dbo.Stat_History_Trend'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Trend_Date_Type 
    ON Stat_History_Trend(Stat_Date DESC, Energy_Type);
    PRINT '已创建索引: IX_Trend_Date_Type (历史趋势日期类型查询)';
END
GO

-- 6.4 管理层决策事项表：创建时间索引
-- 来源：patch.sql 补丁脚本
-- 用途：按创建时间降序排列决策事项，支持列表展示与分页
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ExecDecision_CreatedTime' AND object_id = OBJECT_ID('dbo.Exec_Decision_Item'))
BEGIN
    CREATE INDEX IX_ExecDecision_CreatedTime
    ON Exec_Decision_Item(Created_Time DESC, Decision_ID DESC);
    PRINT '已创建索引: IX_ExecDecision_CreatedTime (决策事项时间排序)';
END
GO

-- 6.5 科研项目表：申请日期索引
-- 来源：patch.sql 补丁脚本
-- 用途：按申请日期降序查询项目列表
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Research_Project_ApplyDate' AND object_id = OBJECT_ID('dbo.Research_Project'))
BEGIN
    CREATE INDEX IX_Research_Project_ApplyDate 
    ON Research_Project(Apply_Date DESC);
    PRINT '已创建索引: IX_Research_Project_ApplyDate (科研项目申请日期)';
END
GO


/* ============================================================
   第七部分：数据分析师功能扩展索引
   ============================================================ */

-- 7.1 光伏天气因子数据表：并网点日期索引
-- 来源：main.sql 数据分析师扩展
-- 用途：按并网点和日期查询天气数据，支持光伏发电预测分析
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PVWeather_PointDate' AND object_id = OBJECT_ID('dbo.PV_Weather_Daily'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PVWeather_PointDate
    ON PV_Weather_Daily (Point_ID, Weather_Date);
    PRINT '已创建索引: IDX_PVWeather_PointDate (光伏天气数据查询)';
END
GO

-- 7.2 产线产量数据表：产线日期索引
-- 来源：main.sql 数据分析师扩展
-- 用途：按产线和日期查询产量数据，支持产能与能耗关联分析
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Output_Date' AND object_id = OBJECT_ID('dbo.Data_Line_Output'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Output_Date
    ON Data_Line_Output (Line_ID, Stat_Date);
    PRINT '已创建索引: IDX_Line_Output_Date (产线产量日期查询)';
END
GO

-- 7.3 能耗-产线映射表：映射关系索引
-- 来源：main.sql 数据分析师扩展
-- 用途：快速查询产线与能耗计量设备的映射关系
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Map' AND object_id = OBJECT_ID('dbo.Energy_Line_Map'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Map
    ON Energy_Line_Map (Line_ID, Meter_ID);
    PRINT '已创建索引: IDX_Line_Map (能耗产线映射查询)';
END
GO


/* ============================================================
   索引汇总信息
   ============================================================
   
   本DDL汇总共包含 19 个索引，按业务线分布如下：
   
   1. 基础系统与人员权限：1个索引
      - IDX_SysUser_Login (UNIQUE) - 登录账号唯一索引
   
   2. 配电网监测业务线：3个索引
      - IDX_Trans_Time - 变压器时间序列查询
      - IDX_Circuit_History - 回路历史趋势查询
      - IDX_Circuit_Factory_RT - 厂区实时状态查询
   
   3. 综合能耗管理业务线：6个索引
      - IDX_Meter_Factory_Type - 设备厂区类型查询
      - IDX_Energy_Time - 能耗时间序列查询
      - IDX_Energy_Quality - 数据质量筛选
      - IDX_PeakValley_Rpt - 峰谷报表统计
      - IDX_PeakValley_Report - 峰谷详细报表（含INCLUDE列）
      - IDX_PeakValley_Factory - 厂区能耗趋势
   
   4. 分布式光伏管理业务线：1个索引
      - IDX_PV_Forecast_Match - 光伏预测精准匹配
   
   5. 告警运维管理业务线：3个索引
      - IDX_Alarm_Dashboard - 告警大屏多维过滤（含INCLUDE列）
      - UX_Work_Order_Alarm_ID (UNIQUE) - 工单告警唯一关联
      - IX_MaintPlan_Ledger_PlanDate - 维护计划设备查询
   
   6. 大屏数据展示业务线：5个索引
      - UX_Dashboard_Config_Config_Code (UNIQUE FILTERED) - 配置编码唯一
      - IX_Stat_Realtime_Stat_Time - 实时汇总时间查询
      - IX_Trend_Date_Type - 历史趋势日期类型查询
      - IX_ExecDecision_CreatedTime - 决策事项时间排序
      - IX_Research_Project_ApplyDate - 科研项目申请日期
   
   7. 数据分析师功能扩展：3个索引
      - IDX_PVWeather_PointDate - 光伏天气数据查询
      - IDX_Line_Output_Date - 产线产量日期查询
      - IDX_Line_Map - 能耗产线映射查询
   
   索引类型统计：
   - 唯一索引 (UNIQUE): 3个
   - 普通非聚集索引: 16个
   - 带INCLUDE列的覆盖索引: 4个
   - 筛选索引 (FILTERED): 1个
   
   ============================================================ */

PRINT N'============================================================';
PRINT N'智慧能源管理系统 数据库索引DDL汇总 执行完成';
PRINT N'共创建 19 个索引，涵盖7个业务模块';
PRINT N'============================================================';
GO
