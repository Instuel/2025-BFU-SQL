package com.bjfu.energy.dao;

import com.bjfu.energy.util.DBUtil;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ExecDashboardDao {

    private static final BigDecimal SELF_USE_RATE = new BigDecimal("0.85");
    private static final BigDecimal GRID_SALE_RATE = new BigDecimal("0.45");
    private static final BigDecimal TARGET_REDUCTION_RATE = new BigDecimal("0.08");

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public Map<String, Object> getMonthlyOverview() throws Exception {
        LocalDate today = LocalDate.now();
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);
        LocalDate prevMonthStart = monthStart.minusMonths(1);

        EnergySummary current = queryEnergySummary(monthStart, nextMonthStart);
        EnergySummary previous = queryEnergySummary(prevMonthStart, monthStart);
        PvSummary pvSummary = queryPvSummary(monthStart, nextMonthStart);
        AlarmSummary alarmSummary = queryAlarmSummary(monthStart, nextMonthStart);
        int pendingProjects = countPendingProjects();

        BigDecimal energyChangeRate = calcRate(current.totalConsumption, previous.totalConsumption);
        BigDecimal costChangeRate = calcRate(current.totalCost, previous.totalCost);
        BigDecimal targetCompletion = calcTargetCompletion(previous.totalCost, current.totalCost);

        BigDecimal selfSaving = pvSummary.selfKwh.multiply(SELF_USE_RATE);
        BigDecimal gridRevenue = pvSummary.gridKwh.multiply(GRID_SALE_RATE);

        Map<String, Object> overview = new HashMap<>();
        overview.put("monthLabel", monthStart.toString().substring(0, 7));
        overview.put("monthlyConsumption", current.totalConsumption);
        overview.put("monthlyCost", current.totalCost);
        overview.put("monthlyChangeRate", energyChangeRate);
        overview.put("monthlyCostChangeRate", costChangeRate);
        overview.put("targetCompletion", targetCompletion);
        overview.put("pvGenKwh", pvSummary.genKwh);
        overview.put("pvSelfKwh", pvSummary.selfKwh);
        overview.put("pvGridKwh", pvSummary.gridKwh);
        overview.put("pvSelfSaving", selfSaving);
        overview.put("pvGridRevenue", gridRevenue);
        overview.put("pvTotalRevenue", selfSaving.add(gridRevenue));
        overview.put("alarmTotalCount", alarmSummary.totalCount);
        overview.put("alarmHighCount", alarmSummary.highCount);
        overview.put("alarmRecentHighCount", alarmSummary.recentHighCount);
        overview.put("pendingProjectCount", pendingProjects);
        return overview;
    }

    /**
     * 业务线5：大屏实时汇总
     * <p>
     * 规则：优先读取 Stat_Realtime（由调度/触发器/ETL 等写入），按 Stat_Time 倒序取最新一条。
     * 若 Stat_Realtime 为空，则从业务表做兜底汇总：
     * - 能耗（电/水/蒸汽/天然气）：取 Data_PeakValley 最新 Stat_Date 的按能源类型汇总值；
     * - 光伏发电：取 Data_PV_Gen 最新一天汇总；
     * - 告警：取 Alarm_Info 近 24 小时的总数 + 按等级/处理状态的拆分。
     * </p>
     */
    public Map<String, Object> getRealtimeSummary() throws Exception {
        try {
            Map<String, Object> fromTable = queryRealtimeFromStatTable();
            if (fromTable != null) {
                return fromTable;
            }
        } catch (Exception ignore) {
            // 可能表不存在或列不完整：走兜底计算
        }
        return computeRealtimeFallback();
    }

    /**
     * 业务线5：历史趋势查询（支持日/周/月等周期）。
     * 直接读取 Stat_History_Trend；若该表为空，返回空列表（页面会给出“暂无数据”）。
     */
    public List<Map<String, Object>> listHistoryTrends(String energyType, String statCycle, int limit) throws Exception {
        if (energyType == null || energyType.trim().isEmpty()) {
            energyType = "电";
        }
        if (statCycle == null || statCycle.trim().isEmpty()) {
            statCycle = "月";
        }
        if (limit <= 0) {
            limit = 12;
        }

        String sql = "SELECT TOP " + limit + " Trend_ID AS trendId, Energy_Type AS energyType, Stat_Cycle AS statCycle, " +
                "CONVERT(VARCHAR(10), Stat_Date, 120) AS statDate, Value AS value, YOY_Rate AS yoyRate, MOM_Rate AS momRate, " +
                "Industry_Avg AS industryAvg, Trend_Tag AS trendTag " +
                "FROM Stat_History_Trend WHERE Energy_Type = ? AND Stat_Cycle = ? ORDER BY Stat_Date DESC";

        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, energyType.trim());
            ps.setString(2, statCycle.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = mapRow(rs);
                    if (row.get("trendTag") == null) {
                        row.put("trendTag", buildTrendTag(row.get("yoyRate"), row.get("momRate")));
                    }
                    list.add(row);
                }
            }
        } catch (Exception e) {
            // 兼容基础脚本：没有扩展列时，退化到基础字段
            String sql2 = "SELECT TOP " + limit + " Trend_ID AS trendId, Energy_Type AS energyType, Stat_Cycle AS statCycle, " +
                    "CONVERT(VARCHAR(10), Stat_Date, 120) AS statDate, Value AS value, YOY_Rate AS yoyRate, MOM_Rate AS momRate " +
                    "FROM Stat_History_Trend WHERE Energy_Type = ? AND Stat_Cycle = ? ORDER BY Stat_Date DESC";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql2)) {
                ps.setString(1, energyType.trim());
                ps.setString(2, statCycle.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = mapRow(rs);
                        row.put("trendTag", buildTrendTag(row.get("yoyRate"), row.get("momRate")));
                        list.add(row);
                    }
                }
            }
        }
        return list;
    }

    /**
     * 业务线5：能耗溯源（Top-N 厂区能耗占比）。
     * period 可选：month（本月）/quarter（本季度）。
     */
    public List<Map<String, Object>> listTopFactories(String energyType, String period, int limit) throws Exception {
        if (energyType == null || energyType.trim().isEmpty()) {
            energyType = "电";
        }
        if (period == null || period.trim().isEmpty()) {
            period = "month";
        }
        if (limit <= 0) {
            limit = 5;
        }

        LocalDate today = LocalDate.now();
        LocalDate start;
        LocalDate end;
        if ("quarter".equalsIgnoreCase(period)) {
            int quarter = (today.getMonthValue() - 1) / 3;
            int startMonth = quarter * 3 + 1;
            start = LocalDate.of(today.getYear(), startMonth, 1);
            end = start.plusMonths(3);
        } else {
            start = today.withDayOfMonth(1);
            end = start.plusMonths(1);
        }

        String sql = "SELECT TOP " + limit + " f.Factory_Name AS factoryName, " +
                "SUM(ISNULL(p.Total_Consumption,0)) AS totalConsumption, " +
                "SUM(ISNULL(p.Cost_Amount,0)) AS totalCost " +
                "FROM Data_PeakValley p " +
                "JOIN Base_Factory f ON p.Factory_ID = f.Factory_ID " +
                "WHERE p.Stat_Date >= ? AND p.Stat_Date < ? AND p.Energy_Type = ? " +
                "GROUP BY f.Factory_Name " +
                "ORDER BY SUM(ISNULL(p.Total_Consumption,0)) DESC";

        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(start));
            ps.setDate(2, java.sql.Date.valueOf(end));
            ps.setString(3, energyType.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    private Map<String, Object> queryRealtimeFromStatTable() throws Exception {
        // 先尝试扩展字段（业务线5增强版）
        String sql = "SELECT TOP 1 Stat_Time AS statTime, Total_KWH AS totalKwh, " +
                "Total_Water_m3 AS totalWaterM3, Total_Steam_t AS totalSteamT, Total_Gas_m3 AS totalGasM3, " +
                "PV_Gen_KWH AS pvGenKwh, Total_Alarm AS totalAlarm, Alarm_High AS alarmHigh, Alarm_Mid AS alarmMid, " +
                "Alarm_Low AS alarmLow, Alarm_Unprocessed AS alarmUnprocessed " +
                "FROM Stat_Realtime ORDER BY Stat_Time DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return null;
            }
            Map<String, Object> row = mapRow(rs);
            normalizeRealtimeRow(row);
            return row;
        } catch (Exception e) {
            // 基础脚本字段
            String sql2 = "SELECT TOP 1 Stat_Time AS statTime, Total_KWH AS totalKwh, PV_Gen_KWH AS pvGenKwh, Total_Alarm AS totalAlarm " +
                    "FROM Stat_Realtime ORDER BY Stat_Time DESC";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql2);
                 ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> row = mapRow(rs);
                normalizeRealtimeRow(row);
                // 缺失字段置 0
                row.putIfAbsent("totalWaterM3", BigDecimal.ZERO);
                row.putIfAbsent("totalSteamT", BigDecimal.ZERO);
                row.putIfAbsent("totalGasM3", BigDecimal.ZERO);
                row.putIfAbsent("alarmHigh", 0);
                row.putIfAbsent("alarmMid", 0);
                row.putIfAbsent("alarmLow", 0);
                row.putIfAbsent("alarmUnprocessed", 0);
                return row;
            }
        }
    }

    private void normalizeRealtimeRow(Map<String, Object> row) {
        // JSP 里统一使用这些 Key；这里把可能的不同命名/类型统一一下
        if (row.containsKey("statTime") && row.get("statTime") instanceof Timestamp) {
            row.put("statTime", ((Timestamp) row.get("statTime")).toLocalDateTime().toString().replace('T', ' '));
        }
        // 某些 JDBC 返回 BigDecimal/Double，JSP fmt 都能处理，这里不强转
        row.putIfAbsent("totalKwh", BigDecimal.ZERO);
        row.putIfAbsent("pvGenKwh", BigDecimal.ZERO);
        row.putIfAbsent("totalAlarm", 0);
    }

    private Map<String, Object> computeRealtimeFallback() throws Exception {
        Map<String, Object> row = new HashMap<>();
        row.put("statTime", LocalDateTime.now().toString().replace('T', ' '));

        LocalDate latestDay = null;
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT MAX(Stat_Date) AS maxDay FROM Data_PeakValley");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getDate(1) != null) {
                latestDay = rs.getDate(1).toLocalDate();
            }
        }
        if (latestDay == null) {
            // 没有统计数据
            row.put("totalKwh", BigDecimal.ZERO);
            row.put("totalWaterM3", BigDecimal.ZERO);
            row.put("totalSteamT", BigDecimal.ZERO);
            row.put("totalGasM3", BigDecimal.ZERO);
        } else {
            String sql = "SELECT Energy_Type AS energyType, SUM(ISNULL(Total_Consumption,0)) AS totalConsumption " +
                    "FROM Data_PeakValley WHERE Stat_Date = ? GROUP BY Energy_Type";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setDate(1, java.sql.Date.valueOf(latestDay));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String et = rs.getString("energyType");
                        BigDecimal val = rs.getBigDecimal("totalConsumption");
                        if (val == null) val = BigDecimal.ZERO;
                        if ("电".equals(et)) {
                            row.put("totalKwh", val);
                        } else if ("水".equals(et)) {
                            row.put("totalWaterM3", val);
                        } else if ("蒸汽".equals(et)) {
                            row.put("totalSteamT", val);
                        } else if ("天然气".equals(et)) {
                            row.put("totalGasM3", val);
                        }
                    }
                }
            }
        }

        // PV（取最新一天）
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT SUM(ISNULL(Gen_KWH,0)) AS pvGen FROM Data_PV_Gen WHERE CONVERT(DATE, Collect_Time) = (SELECT MAX(CONVERT(DATE, Collect_Time)) FROM Data_PV_Gen)");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                BigDecimal pvGen = rs.getBigDecimal("pvGen");
                row.put("pvGenKwh", pvGen == null ? BigDecimal.ZERO : pvGen);
            }
        } catch (Exception e) {
            row.put("pvGenKwh", BigDecimal.ZERO);
        }

        // 告警（近24小时）
        try (Connection conn = DBUtil.getConnection()) {
            String totalSql = "SELECT COUNT(1) AS totalCnt FROM Alarm_Info WHERE Occur_Time >= DATEADD(HOUR, -24, SYSDATETIME())";
            try (PreparedStatement ps = conn.prepareStatement(totalSql);
                 ResultSet rs = ps.executeQuery()) {
                row.put("totalAlarm", rs.next() ? rs.getInt("totalCnt") : 0);
            }
            String levelSql = "SELECT Alarm_Level AS level, COUNT(1) AS cnt FROM Alarm_Info WHERE Occur_Time >= DATEADD(HOUR, -24, SYSDATETIME()) GROUP BY Alarm_Level";
            int high = 0, mid = 0, low = 0;
            try (PreparedStatement ps = conn.prepareStatement(levelSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String level = rs.getString("level");
                    int cnt = rs.getInt("cnt");
                    if (level == null) continue;
                    if (level.contains("高")) high += cnt;
                    else if (level.contains("中")) mid += cnt;
                    else if (level.contains("低")) low += cnt;
                }
            }
            row.put("alarmHigh", high);
            row.put("alarmMid", mid);
            row.put("alarmLow", low);

            String unprocessedSql = "SELECT COUNT(1) AS cnt FROM Alarm_Info WHERE Process_Status = '未处理'";
            try (PreparedStatement ps = conn.prepareStatement(unprocessedSql);
                 ResultSet rs = ps.executeQuery()) {
                row.put("alarmUnprocessed", rs.next() ? rs.getInt("cnt") : 0);
            }
        } catch (Exception e) {
            row.put("totalAlarm", 0);
            row.put("alarmHigh", 0);
            row.put("alarmMid", 0);
            row.put("alarmLow", 0);
            row.put("alarmUnprocessed", 0);
        }

        // 缺省兜底
        row.putIfAbsent("totalKwh", BigDecimal.ZERO);
        row.putIfAbsent("totalWaterM3", BigDecimal.ZERO);
        row.putIfAbsent("totalSteamT", BigDecimal.ZERO);
        row.putIfAbsent("totalGasM3", BigDecimal.ZERO);
        row.putIfAbsent("pvGenKwh", BigDecimal.ZERO);
        row.putIfAbsent("totalAlarm", 0);
        return row;
    }

    private String buildTrendTag(Object yoyRate, Object momRate) {
        // 任务书要求：同比/环比为负标“下降”，为正标“上升”。这里优先同比，其次环比。
        Double yoy = toDouble(yoyRate);
        Double mom = toDouble(momRate);
        Double base = yoy != null ? yoy : mom;
        if (base == null) {
            return "暂无";
        }
        if (base < 0) {
            return "能耗下降";
        }
        if (base > 0) {
            return "能耗上升";
        }
        return "平稳";
    }

    private Double toDouble(Object val) {
        if (val == null) return null;
        if (val instanceof Number) {
            return ((Number) val).doubleValue();
        }
        try {
            return Double.parseDouble(val.toString());
        } catch (Exception e) {
            return null;
        }
    }

    public List<Map<String, Object>> listHighAlarms(int limit) throws Exception {
        String sql = "SELECT TOP " + limit + " a.Alarm_ID AS alarmId, a.Content AS content, " +
                     "CONVERT(VARCHAR(16), a.Occur_Time, 120) AS occurTime, " +
                     "l.Device_Name AS deviceName, l.Device_Type AS deviceType, " +
                     "f.Factory_Name AS factoryName " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID " +
                     "LEFT JOIN Base_Factory f ON a.Factory_ID = f.Factory_ID " +
                     "WHERE a.Alarm_Level = '高' " +
                     "ORDER BY a.Occur_Time DESC, a.Alarm_ID DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                items.add(mapRow(rs));
            }
        }
        return items;
    }

    public List<Map<String, Object>> listDecisionItems() throws Exception {
        String sql = "SELECT d.Decision_ID AS decisionId, d.Decision_Type AS decisionType, " +
                     "d.Title AS title, d.Description AS description, d.Status AS status, " +
                     "d.Estimate_Cost AS estimateCost, d.Expected_Saving AS expectedSaving, " +
                     "CONVERT(VARCHAR(16), d.Created_Time, 120) AS createdTime, " +
                     "a.Content AS alarmContent " +
                     "FROM Exec_Decision_Item d " +
                     "LEFT JOIN Alarm_Info a ON d.Alarm_ID = a.Alarm_ID " +
                     "ORDER BY d.Created_Time DESC, d.Decision_ID DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                items.add(mapRow(rs));
            }
        }
        return items;
    }

    public void updateDecisionStatus(long decisionId, String status) throws Exception {
        String sql = "UPDATE Exec_Decision_Item SET Status = ? WHERE Decision_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setLong(2, decisionId);
            ps.executeUpdate();
        }
    }

    public List<Map<String, Object>> listEnergySummaries(String cycle) throws Exception {
        String sql;
        if ("quarter".equalsIgnoreCase(cycle)) {
            sql = "SELECT TOP 6 YEAR(Stat_Date) AS statYear, DATEPART(QUARTER, Stat_Date) AS statQuarter, " +
                  "SUM(Total_Consumption) AS totalConsumption, SUM(Cost_Amount) AS totalCost " +
                  "FROM Data_PeakValley " +
                  "GROUP BY YEAR(Stat_Date), DATEPART(QUARTER, Stat_Date) " +
                  "ORDER BY statYear DESC, statQuarter DESC";
        } else {
            sql = "SELECT TOP 6 YEAR(Stat_Date) AS statYear, MONTH(Stat_Date) AS statMonth, " +
                  "SUM(Total_Consumption) AS totalConsumption, SUM(Cost_Amount) AS totalCost " +
                  "FROM Data_PeakValley " +
                  "GROUP BY YEAR(Stat_Date), MONTH(Stat_Date) " +
                  "ORDER BY statYear DESC, statMonth DESC";
        }
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                int year = rs.getInt("statYear");
                if ("quarter".equalsIgnoreCase(cycle)) {
                    int quarter = rs.getInt("statQuarter");
                    row.put("periodLabel", String.format("%d-Q%d", year, quarter));
                } else {
                    int month = rs.getInt("statMonth");
                    row.put("periodLabel", String.format("%d-%02d", year, month));
                }
                row.put("totalConsumption", rs.getBigDecimal("totalConsumption"));
                row.put("totalCost", rs.getBigDecimal("totalCost"));
                items.add(row);
            }
        }
        enrichChangeRate(items);
        return items;
    }

    public List<Map<String, Object>> listResearchProjects() throws Exception {
        // 兼容不同页面的展示字段：列表需要标题/状态/时间；详情行可展示摘要与结题报告
        String sql = "SELECT TOP 6 Project_ID AS projectId, Project_Title AS projectTitle, " +
                     "Project_Summary AS projectSummary, Close_Report AS closeReport, " +
                     "Applicant AS applicant, Project_Status AS projectStatus, " +
                     "CONVERT(VARCHAR(19), Apply_Date, 120) AS applyDate, " +
                     "CONVERT(VARCHAR(19), Close_Date, 120) AS closeDate " +
                     "FROM Research_Project " +
                     "ORDER BY Apply_Date DESC, Project_ID DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                items.add(mapRow(rs));
            }
        }
        return items;
    }

    public List<Map<String, Object>> listOpenProjects() throws Exception {
        String sql = "SELECT Project_ID AS projectId, Project_Title AS projectTitle, Project_Status AS projectStatus " +
                     "FROM Research_Project " +
                     "WHERE Project_Status IN ('申报中', '结题中') " +
                     "ORDER BY Apply_Date DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                items.add(mapRow(rs));
            }
        }
        return items;
    }

    public void createResearchProject(String title, String summary, String applicant) throws Exception {
        String sql = "INSERT INTO Research_Project (Project_Title, Project_Summary, Applicant, Project_Status, Apply_Date) " +
                     "VALUES (?, ?, ?, '申报中', SYSDATETIME())";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setString(2, summary);
            ps.setString(3, applicant);
            ps.executeUpdate();
        }
    }

    public void submitResearchClosure(long projectId, String closeReport) throws Exception {
        String sql = "UPDATE Research_Project " +
                     "SET Close_Report = ?, Close_Date = SYSDATETIME(), Project_Status = '结题中' " +
                     "WHERE Project_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, closeReport);
            ps.setLong(2, projectId);
            ps.executeUpdate();
        }
    }

    private EnergySummary queryEnergySummary(LocalDate start, LocalDate end) throws Exception {
        String sql = "SELECT COALESCE(SUM(Total_Consumption), 0) AS totalConsumption, " +
                     "COALESCE(SUM(Cost_Amount), 0) AS totalCost " +
                     "FROM Data_PeakValley WHERE Stat_Date >= ? AND Stat_Date < ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(start));
            ps.setDate(2, java.sql.Date.valueOf(end));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new EnergySummary(rs.getBigDecimal("totalConsumption"), rs.getBigDecimal("totalCost"));
                }
            }
        }
        return new EnergySummary(BigDecimal.ZERO, BigDecimal.ZERO);
    }

    private PvSummary queryPvSummary(LocalDate start, LocalDate end) throws Exception {
        String sql = "SELECT COALESCE(SUM(Gen_KWH), 0) AS genKwh, " +
                     "COALESCE(SUM(Self_KWH), 0) AS selfKwh, " +
                     "COALESCE(SUM(Grid_KWH), 0) AS gridKwh " +
                     "FROM Data_PV_Gen WHERE Collect_Time >= ? AND Collect_Time < ?";
        LocalDateTime startTime = start.atStartOfDay();
        LocalDateTime endTime = end.atStartOfDay();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new PvSummary(rs.getBigDecimal("genKwh"), rs.getBigDecimal("selfKwh"),
                            rs.getBigDecimal("gridKwh"));
                }
            }
        }
        return new PvSummary(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
    }

    private AlarmSummary queryAlarmSummary(LocalDate start, LocalDate end) throws Exception {
        String sql = "SELECT COUNT(*) AS totalCount, " +
                     "SUM(CASE WHEN Alarm_Level = '高' THEN 1 ELSE 0 END) AS highCount, " +
                     "SUM(CASE WHEN Alarm_Level = '高' AND Occur_Time >= DATEADD(DAY, -7, SYSDATETIME()) " +
                     "THEN 1 ELSE 0 END) AS recentHighCount " +
                     "FROM Alarm_Info WHERE Occur_Time >= ? AND Occur_Time < ?";
        LocalDateTime startTime = start.atStartOfDay();
        LocalDateTime endTime = end.atStartOfDay();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new AlarmSummary(rs.getInt("totalCount"), rs.getInt("highCount"),
                            rs.getInt("recentHighCount"));
                }
            }
        }
        return new AlarmSummary(0, 0, 0);
    }

    private int countPendingProjects() throws Exception {
        String sql = "SELECT COUNT(*) AS pendingCount " +
                     "FROM Research_Project WHERE Project_Status IN ('申报中', '结题中')";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("pendingCount");
            }
        }
        return 0;
    }

    private void enrichChangeRate(List<Map<String, Object>> items) {
        for (int i = 0; i < items.size(); i++) {
            Map<String, Object> current = items.get(i);
            BigDecimal currentValue = toBigDecimal(current.get("totalConsumption"));
            BigDecimal rate = null;
            if (i + 1 < items.size()) {
                Map<String, Object> previous = items.get(i + 1);
                BigDecimal prevValue = toBigDecimal(previous.get("totalConsumption"));
                rate = calcRate(currentValue, prevValue);
            }
            current.put("changeRate", rate);
            String trendTag = "暂无对比";
            String goalStatus = "待评估";
            if (rate != null) {
                if (rate.compareTo(BigDecimal.ZERO) < 0) {
                    trendTag = rate.compareTo(new BigDecimal("-0.05")) <= 0 ? "降本显著" : "小幅下降";
                } else if (rate.compareTo(BigDecimal.ZERO) > 0) {
                    trendTag = "能耗上升";
                } else {
                    trendTag = "持平";
                }
                goalStatus = rate.compareTo(new BigDecimal("-0.05")) <= 0 ? "达标" : "未达标";
            }
            current.put("trendTag", trendTag);
            current.put("goalStatus", goalStatus);
        }
    }

    private BigDecimal calcRate(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.compareTo(BigDecimal.ZERO) == 0) {
            return null;
        }
        BigDecimal diff = current.subtract(previous);
        return diff.divide(previous, 4, RoundingMode.HALF_UP);
    }

    private BigDecimal calcTargetCompletion(BigDecimal previousCost, BigDecimal currentCost) {
        if (previousCost == null || previousCost.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal reduction = previousCost.subtract(currentCost);
        BigDecimal reductionRate = reduction.divide(previousCost, 4, RoundingMode.HALF_UP);
        if (reductionRate.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal completion = reductionRate.divide(TARGET_REDUCTION_RATE, 4, RoundingMode.HALF_UP);
        if (completion.compareTo(BigDecimal.ONE) > 0) {
            return BigDecimal.ONE;
        }
        return completion;
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        }
        if (value instanceof Number) {
            return BigDecimal.valueOf(((Number) value).doubleValue());
        }
        return BigDecimal.ZERO;
    }

    private static class EnergySummary {
        private final BigDecimal totalConsumption;
        private final BigDecimal totalCost;

        private EnergySummary(BigDecimal totalConsumption, BigDecimal totalCost) {
            this.totalConsumption = totalConsumption == null ? BigDecimal.ZERO : totalConsumption;
            this.totalCost = totalCost == null ? BigDecimal.ZERO : totalCost;
        }
    }

    private static class PvSummary {
        private final BigDecimal genKwh;
        private final BigDecimal selfKwh;
        private final BigDecimal gridKwh;

        private PvSummary(BigDecimal genKwh, BigDecimal selfKwh, BigDecimal gridKwh) {
            this.genKwh = genKwh == null ? BigDecimal.ZERO : genKwh;
            this.selfKwh = selfKwh == null ? BigDecimal.ZERO : selfKwh;
            this.gridKwh = gridKwh == null ? BigDecimal.ZERO : gridKwh;
        }
    }

    private static class AlarmSummary {
        private final int totalCount;
        private final int highCount;
        private final int recentHighCount;

        private AlarmSummary(int totalCount, int highCount, int recentHighCount) {
            this.totalCount = totalCount;
            this.highCount = highCount;
            this.recentHighCount = recentHighCount;
        }
    }
}
