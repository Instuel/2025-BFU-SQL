package com.bjfu.energy.dao;

import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AnalystDao {

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public Map<String, Object> getForecastOverview(int windowDays) throws Exception {
        Map<String, Object> overview = new HashMap<>();
        String deviationSql = "SELECT AVG(ABS((Forecast_Val - Actual_Val) / NULLIF(Actual_Val, 0))) * 100 AS avgDeviationRate, " +
                              "COUNT(*) AS sampleCount, MAX(Forecast_Date) AS latestDate " +
                              "FROM Data_PV_Forecast " +
                              "WHERE Actual_Val IS NOT NULL " +
                              "AND Forecast_Date >= DATEADD(DAY, -?, CAST(GETDATE() AS DATE))";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(deviationSql)) {
            ps.setInt(1, windowDays);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    overview.putAll(mapRow(rs));
                }
            }
        }

        String modelSql = "SELECT TOP 1 Model_Version AS modelVersion, Model_Name AS modelName, Update_Time AS updateTime " +
                          "FROM PV_Forecast_Model WHERE Status = 'Active' ORDER BY Update_Time DESC, Model_Version DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(modelSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                overview.putAll(mapRow(rs));
            }
        }
        return overview;
    }

    public Double getAvgDeviationRate(int startDaysBack, int endDaysBack) throws Exception {
        String sql = "SELECT AVG(ABS((Forecast_Val - Actual_Val) / NULLIF(Actual_Val, 0))) * 100 AS avgDeviationRate " +
                     "FROM Data_PV_Forecast " +
                     "WHERE Actual_Val IS NOT NULL " +
                     "AND Forecast_Date >= DATEADD(DAY, -?, CAST(GETDATE() AS DATE)) " +
                     "AND Forecast_Date < DATEADD(DAY, -?, CAST(GETDATE() AS DATE))";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, startDaysBack);
            ps.setInt(2, endDaysBack);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Object value = rs.getObject("avgDeviationRate");
                    return value == null ? null : ((Number) value).doubleValue();
                }
            }
        }
        return null;
    }

    public int countWeatherFactors(int windowDays) throws Exception {
        String sql = "SELECT COUNT(*) AS factorCount FROM PV_Weather_Daily " +
                     "WHERE Weather_Date >= DATEADD(DAY, -?, CAST(GETDATE() AS DATE))";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, windowDays);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("factorCount");
                }
            }
        }
        return 0;
    }

    public List<Map<String, Object>> listForecastDeviationInsights(int limit) throws Exception {
        String sql = "WITH ranked AS ( " +
                     "  SELECT f.Point_ID AS pointId, p.Point_Name AS pointName, " +
                     "         f.Forecast_Val AS forecastVal, f.Actual_Val AS actualVal, " +
                     "         CASE WHEN f.Actual_Val IS NULL OR f.Actual_Val = 0 THEN NULL " +
                     "              ELSE (f.Forecast_Val - f.Actual_Val) / f.Actual_Val * 100 END AS deviationRate, " +
                     "         f.Forecast_Date AS forecastDate, " +
                     "         w.Cloud_Cover AS cloudCover, w.Temperature AS temperature, w.Irradiance AS irradiance, " +
                     "         CASE WHEN w.Weather_ID IS NULL THEN N'未接入天气数据' " +
                     "              ELSE CONCAT(N'云量', w.Cloud_Cover, N'%, 温度', w.Temperature, N'℃, 辐照', w.Irradiance, N'W/㎡') END AS weatherFactor, " +
                     "         CASE WHEN w.Weather_ID IS NULL THEN N'补充天气因子采集' " +
                     "              WHEN w.Cloud_Cover >= 70 THEN N'引入云量实时修正' " +
                     "              WHEN w.Irradiance < 400 THEN N'辐照度校准' " +
                     "              WHEN w.Temperature >= 35 THEN N'加入温度灵敏度' " +
                     "              ELSE N'持续观察' END AS optimizationAdvice, " +
                     "         ROW_NUMBER() OVER (PARTITION BY f.Point_ID ORDER BY f.Forecast_Date DESC, f.Time_Slot DESC) AS rn " +
                     "  FROM Data_PV_Forecast f " +
                     "  JOIN PV_Grid_Point p ON f.Point_ID = p.Point_ID " +
                     "  LEFT JOIN PV_Weather_Daily w ON f.Point_ID = w.Point_ID AND f.Forecast_Date = w.Weather_Date " +
                     "  WHERE f.Actual_Val IS NOT NULL " +
                     ") " +
                     "SELECT TOP (?) * FROM ranked WHERE rn = 1 ORDER BY ABS(deviationRate) DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }

    public List<Map<String, Object>> listEnergyLineInsights(int limit) throws Exception {
        String sql = "WITH energy_daily AS ( " +
                     "  SELECT m.Line_ID AS lineId, CAST(d.Collect_Time AS DATE) AS statDate, " +
                     "         SUM(d.Value * ISNULL(m.Weight, 1)) AS totalEnergy " +
                     "  FROM Data_Energy d " +
                     "  JOIN Energy_Line_Map m ON d.Meter_ID = m.Meter_ID " +
                     "  GROUP BY m.Line_ID, CAST(d.Collect_Time AS DATE) " +
                     "), " +
                     "output_daily AS ( " +
                     "  SELECT Line_ID AS lineId, Stat_Date AS statDate, SUM(Output_Qty) AS totalOutput " +
                     "  FROM Data_Line_Output " +
                     "  GROUP BY Line_ID, Stat_Date " +
                     "), " +
                     "joined AS ( " +
                     "  SELECT e.lineId, e.statDate, e.totalEnergy, o.totalOutput " +
                     "  FROM energy_daily e " +
                     "  JOIN output_daily o ON e.lineId = o.lineId AND e.statDate = o.statDate " +
                     "), " +
                     "agg AS ( " +
                     "  SELECT lineId, COUNT(*) AS sampleCount, " +
                     "         SUM(totalEnergy) AS sumEnergy, SUM(totalOutput) AS sumOutput, " +
                     "         SUM(totalEnergy * totalOutput) AS sumEnergyOutput, " +
                     "         SUM(totalEnergy * totalEnergy) AS sumEnergy2, " +
                     "         SUM(totalOutput * totalOutput) AS sumOutput2 " +
                     "  FROM joined GROUP BY lineId " +
                     "), " +
                     "calc AS ( " +
                     "  SELECT lineId, " +
                     "         CASE WHEN (sampleCount * sumEnergy2 - sumEnergy * sumEnergy) = 0 " +
                     "                   OR (sampleCount * sumOutput2 - sumOutput * sumOutput) = 0 THEN NULL " +
                     "              ELSE (sampleCount * sumEnergyOutput - sumEnergy * sumOutput) / " +
                     "                   SQRT((sampleCount * sumEnergy2 - sumEnergy * sumEnergy) * " +
                     "                        (sampleCount * sumOutput2 - sumOutput * sumOutput)) END AS corrCoeff, " +
                     "         CASE WHEN sumOutput = 0 THEN NULL ELSE sumEnergy / sumOutput END AS energyPerOutput " +
                     "  FROM agg " +
                     ") " +
                     "SELECT TOP (?) l.Line_Name AS lineName, f.Factory_Name AS factoryName, " +
                     "       c.corrCoeff, c.energyPerOutput, " +
                     "       CASE WHEN c.energyPerOutput IS NULL THEN N'样本不足' " +
                     "            WHEN c.energyPerOutput > AVG(c.energyPerOutput) OVER() * 1.1 THEN N'存在节能潜力' " +
                     "            WHEN c.energyPerOutput < AVG(c.energyPerOutput) OVER() * 0.9 THEN N'运行效率良好' " +
                     "            ELSE N'需持续观察' END AS savingPotential " +
                     "FROM calc c " +
                     "JOIN Production_Line l ON c.lineId = l.Line_ID " +
                     "JOIN Base_Factory f ON l.Factory_ID = f.Factory_ID " +
                     "ORDER BY ABS(c.corrCoeff) DESC, c.energyPerOutput DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }

    public List<Map<String, Object>> listQuarterlyEnergyReports(int limit) throws Exception {
        String sql = "WITH latest AS (SELECT MAX(Stat_Date) AS latestDate FROM Data_PeakValley), " +
                     "quarter_base AS ( " +
                     "  SELECT p.Factory_ID AS factoryId, f.Factory_Name AS factoryName, p.Energy_Type AS energyType, " +
                     "         DATEPART(YEAR, p.Stat_Date) AS yearVal, DATEPART(QUARTER, p.Stat_Date) AS quarterVal, " +
                     "         SUM(p.Total_Consumption) AS totalConsumption, SUM(p.Cost_Amount) AS totalCost " +
                     "  FROM Data_PeakValley p " +
                     "  JOIN Base_Factory f ON p.Factory_ID = f.Factory_ID " +
                     "  CROSS JOIN latest " +
                     "  WHERE p.Stat_Date >= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, latest.latestDate), 0) " +
                     "    AND p.Stat_Date < DATEADD(QUARTER, DATEDIFF(QUARTER, 0, latest.latestDate) + 1, 0) " +
                     "  GROUP BY p.Factory_ID, f.Factory_Name, p.Energy_Type, " +
                     "           DATEPART(YEAR, p.Stat_Date), DATEPART(QUARTER, p.Stat_Date) " +
                     ") " +
                     "SELECT TOP (?) " +
                     "       CONCAT(yearVal, 'Q', quarterVal, N'季度能源成本分析报告') AS reportTitle, " +
                     "       factoryName, energyType, totalConsumption, totalCost, " +
                     "       CASE WHEN totalCost >= AVG(totalCost) OVER() * 1.1 THEN N'需关注' " +
                     "            WHEN totalCost <= AVG(totalCost) OVER() * 0.9 THEN N'表现良好' " +
                     "            ELSE N'待提交' END AS reportStatus " +
                     "FROM quarter_base " +
                     "ORDER BY totalCost DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }

    public List<Map<String, Object>> listModelAlerts(int limit) throws Exception {
        String sql = "SELECT TOP (?) a.Alert_ID AS alertId, p.Point_Name AS pointName, " +
                     "CONVERT(VARCHAR(16), a.Trigger_Time, 120) AS triggerTime, " +
                     "a.Remark AS remark, a.Process_Status AS processStatus, a.Model_Version AS modelVersion " +
                     "FROM PV_Model_Alert a " +
                     "JOIN PV_Grid_Point p ON a.Point_ID = p.Point_ID " +
                     "ORDER BY a.Trigger_Time DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }
}
