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

    public List<Map<String, Object>> listHighAlarms(int limit) throws Exception {
        String sql = "SELECT TOP " + limit + " a.Alarm_ID AS alarmId, a.Content AS content, " +
                     "CONVERT(VARCHAR(16), a.Occur_Time, 120) AS occurTime, " +
                     "l.Device_Name AS deviceName, l.Device_Type AS deviceType, " +
                     "f.Factory_Name AS factoryName " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID " +
                     "LEFT JOIN Base_Factory f ON a.Factory_ID = f.Factory_ID " +
                     "LEFT JOIN Sys_Alarm_Rule r ON a.Alarm_Type = r.Alarm_Type " +
                     "WHERE a.Alarm_Level = '高' " +
                     "  AND (r.Is_Enabled IS NULL OR r.Is_Enabled = 1) " +
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
                  "SUM(Total_Consumption) AS totalConsumption, " +
                  "SUM(Cost_Amount) AS totalCost " +
                  "FROM View_PeakValley_Dynamic " +
                  "GROUP BY YEAR(Stat_Date), DATEPART(QUARTER, Stat_Date) " +
                  "ORDER BY statYear DESC, statQuarter DESC";
        } else {
            sql = "SELECT TOP 6 YEAR(Stat_Date) AS statYear, MONTH(Stat_Date) AS statMonth, " +
                  "SUM(Total_Consumption) AS totalConsumption, " +
                  "SUM(Cost_Amount) AS totalCost " +
                  "FROM View_PeakValley_Dynamic " +
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
                row.put("statYear", year);
                if ("quarter".equalsIgnoreCase(cycle)) {
                    int quarter = rs.getInt("statQuarter");
                    row.put("statQuarter", quarter);
                    row.put("periodLabel", String.format("%d-Q%d", year, quarter));
                } else {
                    int month = rs.getInt("statMonth");
                    row.put("statMonth", month);
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
        String sql = "SELECT TOP 6 Project_ID AS projectId, Project_Title AS projectTitle, " +
                     "Applicant AS applicant, Project_Status AS projectStatus, " +
                     "CONVERT(VARCHAR(10), Apply_Date, 120) AS applyDate, " +
                     "CONVERT(VARCHAR(10), Close_Date, 120) AS closeDate " +
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
        String sql = "SELECT Project_ID AS projectId, Project_Title AS projectTitle " +
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
                     "SUM(CASE WHEN a.Alarm_Level = '高' THEN 1 ELSE 0 END) AS highCount, " +
                     "SUM(CASE WHEN a.Alarm_Level = '高' AND a.Occur_Time >= DATEADD(DAY, -7, SYSDATETIME()) " +
                     "THEN 1 ELSE 0 END) AS recentHighCount " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Sys_Alarm_Rule r ON a.Alarm_Type = r.Alarm_Type " +
                     "WHERE a.Occur_Time >= ? AND a.Occur_Time < ? " +
                     "AND (r.Is_Enabled IS NULL OR r.Is_Enabled = 1)";
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
