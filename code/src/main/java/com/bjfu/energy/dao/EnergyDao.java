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

public class EnergyDao {

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public Map<String, Object> getMeterStats() throws Exception {
        String sql = "SELECT COUNT(*) AS totalCount, " +
                     "SUM(CASE WHEN Run_Status = '正常' THEN 1 ELSE 0 END) AS normalCount, " +
                     "SUM(CASE WHEN Run_Status <> '正常' THEN 1 ELSE 0 END) AS abnormalCount, " +
                     "COUNT(DISTINCT Factory_ID) AS factoryCount " +
                     "FROM Energy_Meter";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return mapRow(rs);
            }
        }
        return new HashMap<>();
    }

    public List<Map<String, Object>> listFactories() throws Exception {
        String sql = "SELECT Factory_ID AS factoryId, Factory_Name AS factoryName " +
                     "FROM Base_Factory ORDER BY Factory_ID";
        List<Map<String, Object>> factories = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                factories.add(mapRow(rs));
            }
        }
        return factories;
    }

    public List<Map<String, Object>> listMeters(String energyType, Long factoryId, String runStatus, String keyword)
            throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT m.Meter_ID AS meterId, ")
           .append("COALESCE(l.Device_Name, CONCAT('EM-', m.Meter_ID)) AS meterCode, ")
           .append("m.Energy_Type AS energyType, m.Install_Location AS installLocation, ")
           .append("m.Comm_Protocol AS commProtocol, m.Run_Status AS runStatus, ")
           .append("m.Calib_Cycle_Months AS calibCycleMonths, m.Manufacturer AS manufacturer, ")
           .append("l.Model_Spec AS modelSpec, f.Factory_Name AS factoryName ")
           .append("FROM Energy_Meter m ")
           .append("LEFT JOIN Device_Ledger l ON m.Ledger_ID = l.Ledger_ID ")
           .append("JOIN Base_Factory f ON m.Factory_ID = f.Factory_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (energyType != null && !energyType.isEmpty() && !"全部".equals(energyType)) {
            sql.append("AND m.Energy_Type = ? ");
            params.add(energyType);
        }
        if (factoryId != null) {
            sql.append("AND m.Factory_ID = ? ");
            params.add(factoryId);
        }
        if (runStatus != null && !runStatus.isEmpty() && !"全部".equals(runStatus)) {
            sql.append("AND m.Run_Status = ? ");
            params.add(runStatus);
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (m.Install_Location LIKE ? OR l.Device_Name LIKE ?) ");
            String like = "%" + keyword.trim() + "%";
            params.add(like);
            params.add(like);
        }
        sql.append("ORDER BY m.Meter_ID DESC");
        List<Map<String, Object>> meters = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    meters.add(mapRow(rs));
                }
            }
        }
        return meters;
    }

    public Long findFirstMeterId() throws Exception {
        String sql = "SELECT TOP 1 Meter_ID AS meterId FROM Energy_Meter ORDER BY Meter_ID";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getLong("meterId");
            }
        }
        return null;
    }

    public Map<String, Object> findMeterById(long meterId) throws Exception {
        String sql = "SELECT TOP 1 m.Meter_ID AS meterId, " +
                     "COALESCE(l.Device_Name, CONCAT('EM-', m.Meter_ID)) AS meterCode, " +
                     "m.Energy_Type AS energyType, m.Install_Location AS installLocation, " +
                     "m.Comm_Protocol AS commProtocol, m.Run_Status AS runStatus, " +
                     "m.Calib_Cycle_Months AS calibCycleMonths, m.Manufacturer AS manufacturer, " +
                     "l.Model_Spec AS modelSpec, f.Factory_Name AS factoryName " +
                     "FROM Energy_Meter m " +
                     "LEFT JOIN Device_Ledger l ON m.Ledger_ID = l.Ledger_ID " +
                     "JOIN Base_Factory f ON m.Factory_ID = f.Factory_ID " +
                     "WHERE m.Meter_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, meterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listEnergyData(Long meterId, Long factoryId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT d.Data_ID AS dataId, d.Meter_ID AS meterId, ")
           .append("COALESCE(l.Device_Name, CONCAT('EM-', d.Meter_ID)) AS meterCode, ")
           .append("CONVERT(VARCHAR(19), d.Collect_Time, 120) AS collectTime, ")
           .append("d.Value AS value, d.Unit AS unit, d.Quality AS quality, ")
           .append("f.Factory_Name AS factoryName ")
           .append("FROM Data_Energy d ")
           .append("JOIN Energy_Meter m ON d.Meter_ID = m.Meter_ID ")
           .append("LEFT JOIN Device_Ledger l ON m.Ledger_ID = l.Ledger_ID ")
           .append("JOIN Base_Factory f ON d.Factory_ID = f.Factory_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (meterId != null) {
            sql.append("AND d.Meter_ID = ? ");
            params.add(meterId);
        }
        if (factoryId != null) {
            sql.append("AND d.Factory_ID = ? ");
            params.add(factoryId);
        }
        sql.append("ORDER BY d.Collect_Time DESC");
        List<Map<String, Object>> records = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    records.add(mapRow(rs));
                }
            }
        }
        return records;
    }

    public List<Map<String, Object>> listPeakValleySummary(Long factoryId, String energyType) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.Stat_Date AS statDate, p.Energy_Type AS energyType, ")
           .append("f.Factory_Name AS factoryName, ")
           .append("SUM(CASE WHEN p.Peak_Type = '尖峰' THEN p.Total_Consumption ELSE 0 END) AS peakConsumption, ")
           .append("SUM(CASE WHEN p.Peak_Type = '高峰' THEN p.Total_Consumption ELSE 0 END) AS highConsumption, ")
           .append("SUM(CASE WHEN p.Peak_Type = '平段' THEN p.Total_Consumption ELSE 0 END) AS flatConsumption, ")
           .append("SUM(CASE WHEN p.Peak_Type = '低谷' THEN p.Total_Consumption ELSE 0 END) AS valleyConsumption, ")
           .append("SUM(p.Total_Consumption) AS totalConsumption, ")
           .append("SUM(p.Cost_Amount) AS totalCost ")
           .append("FROM Data_PeakValley p ")
           .append("JOIN Base_Factory f ON p.Factory_ID = f.Factory_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (factoryId != null) {
            sql.append("AND p.Factory_ID = ? ");
            params.add(factoryId);
        }
        if (energyType != null && !energyType.isEmpty() && !"全部".equals(energyType)) {
            sql.append("AND p.Energy_Type = ? ");
            params.add(energyType);
        }
        sql.append("GROUP BY p.Stat_Date, p.Energy_Type, f.Factory_Name ")
           .append("ORDER BY p.Stat_Date DESC, f.Factory_Name");
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }

    public Map<String, Object> getLatestPeakValleyReportStats() throws Exception {
        String dateSql = "SELECT TOP 1 Stat_Date AS statDate FROM Data_PeakValley ORDER BY Stat_Date DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(dateSql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                return new HashMap<>();
            }
            Object statDate = rs.getObject("statDate");
            String sql = "SELECT ? AS reportDate, " +
                         "SUM(CASE WHEN Peak_Type = '低谷' THEN Total_Consumption ELSE 0 END) AS valleyConsumption, " +
                         "SUM(Total_Consumption) AS totalConsumption, " +
                         "SUM(Cost_Amount) AS totalCost " +
                         "FROM Data_PeakValley WHERE Stat_Date = ?";
            try (PreparedStatement detailPs = conn.prepareStatement(sql)) {
                detailPs.setObject(1, statDate);
                detailPs.setObject(2, statDate);
                try (ResultSet detailRs = detailPs.executeQuery()) {
                    if (detailRs.next()) {
                        return mapRow(detailRs);
                    }
                }
            }
        }
        return new HashMap<>();
    }
}
