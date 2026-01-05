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

public class PvDao {

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public Map<String, Object> getPvStats() throws Exception {
        String sql = "SELECT COUNT(*) AS totalCount, " +
                     "SUM(CASE WHEN Run_Status = '正常' THEN 1 ELSE 0 END) AS normalCount, " +
                     "SUM(CASE WHEN Run_Status = '故障' THEN 1 ELSE 0 END) AS faultCount, " +
                     "SUM(CASE WHEN Run_Status = '离线' THEN 1 ELSE 0 END) AS offlineCount, " +
                     "(SELECT SUM(Gen_KWH) FROM Data_PV_Gen " +
                     " WHERE CAST(Collect_Time AS DATE) = CAST(GETDATE() AS DATE)) AS todayGen " +
                     "FROM PV_Device";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return mapRow(rs);
            }
        }
        return new HashMap<>();
    }

    public List<Map<String, Object>> listGridPoints() throws Exception {
        String sql = "SELECT Point_ID AS pointId, Point_Name AS pointName FROM PV_Grid_Point ORDER BY Point_ID";
        List<Map<String, Object>> points = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                points.add(mapRow(rs));
            }
        }
        return points;
    }

    public List<Map<String, Object>> listDevices() throws Exception {
        String sql = "SELECT d.Device_ID AS deviceId, " +
                     "COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID)) AS deviceCode, " +
                     "d.Device_Type AS deviceType, d.Capacity AS capacity, d.Run_Status AS runStatus, " +
                     "d.Protocol AS protocol, p.Point_Name AS pointName, " +
                     "g.Gen_KWH AS genKwh, g.Grid_KWH AS gridKwh, g.Self_KWH AS selfKwh, " +
                     "g.Inverter_Eff AS inverterEff, " +
                     "CONVERT(VARCHAR(16), g.Collect_Time, 120) AS collectTime " +
                     "FROM PV_Device d " +
                     "JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID " +
                     "LEFT JOIN Device_Ledger l ON d.Ledger_ID = l.Ledger_ID " +
                     "OUTER APPLY ( " +
                     "  SELECT TOP 1 Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Collect_Time " +
                     "  FROM Data_PV_Gen g WHERE g.Device_ID = d.Device_ID " +
                     "  ORDER BY Collect_Time DESC " +
                     ") g " +
                     "ORDER BY d.Device_ID DESC";
        List<Map<String, Object>> devices = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                devices.add(mapRow(rs));
            }
        }
        return devices;
    }

    public Long findFirstDeviceId() throws Exception {
        String sql = "SELECT TOP 1 Device_ID AS deviceId FROM PV_Device ORDER BY Device_ID";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getLong("deviceId");
            }
        }
        return null;
    }

    public Map<String, Object> findDeviceById(long deviceId) throws Exception {
        String sql = "SELECT TOP 1 d.Device_ID AS deviceId, " +
                     "COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID)) AS deviceCode, " +
                     "d.Device_Type AS deviceType, d.Capacity AS capacity, d.Run_Status AS runStatus, " +
                     "d.Protocol AS protocol, d.Install_Date AS installDate, " +
                     "p.Point_Name AS pointName, l.Model_Spec AS modelSpec " +
                     "FROM PV_Device d " +
                     "JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID " +
                     "LEFT JOIN Device_Ledger l ON d.Ledger_ID = l.Ledger_ID " +
                     "WHERE d.Device_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, deviceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listGenData(Long deviceId, Long pointId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT g.Data_ID AS dataId, g.Device_ID AS deviceId, ")
           .append("COALESCE(l.Device_Name, CONCAT('PV-', g.Device_ID)) AS deviceCode, ")
           .append("p.Point_Name AS pointName, ")
           .append("CONVERT(VARCHAR(19), g.Collect_Time, 120) AS collectTime, ")
           .append("g.Gen_KWH AS genKwh, g.Grid_KWH AS gridKwh, g.Self_KWH AS selfKwh, ")
           .append("g.Inverter_Eff AS inverterEff ")
           .append("FROM Data_PV_Gen g ")
           .append("JOIN PV_Device d ON g.Device_ID = d.Device_ID ")
           .append("LEFT JOIN Device_Ledger l ON d.Ledger_ID = l.Ledger_ID ")
           .append("JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (deviceId != null) {
            sql.append("AND g.Device_ID = ? ");
            params.add(deviceId);
        }
        if (pointId != null) {
            sql.append("AND d.Point_ID = ? ");
            params.add(pointId);
        }
        sql.append("ORDER BY g.Collect_Time DESC");
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

    public List<Map<String, Object>> listForecasts(Long pointId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT f.Forecast_ID AS forecastId, p.Point_Name AS pointName, ")
           .append("f.Forecast_Date AS forecastDate, f.Time_Slot AS timeSlot, ")
           .append("f.Forecast_Val AS forecastVal, f.Actual_Val AS actualVal, ")
           .append("CASE WHEN f.Actual_Val IS NULL OR f.Actual_Val = 0 THEN NULL ")
           .append("ELSE (f.Forecast_Val - f.Actual_Val) / f.Actual_Val END AS deviationRate, ")
           .append("m.Model_Name AS modelName, f.Model_Version AS modelVersion ")
           .append("FROM Data_PV_Forecast f ")
           .append("JOIN PV_Grid_Point p ON f.Point_ID = p.Point_ID ")
           .append("LEFT JOIN PV_Forecast_Model m ON f.Model_Version = m.Model_Version ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (pointId != null) {
            sql.append("AND f.Point_ID = ? ");
            params.add(pointId);
        }
        sql.append("ORDER BY f.Forecast_Date DESC, f.Time_Slot");
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

    public Map<String, Object> findForecastById(long forecastId) throws Exception {
        String sql = "SELECT TOP 1 f.Forecast_ID AS forecastId, p.Point_Name AS pointName, " +
                     "f.Forecast_Date AS forecastDate, f.Time_Slot AS timeSlot, " +
                     "f.Forecast_Val AS forecastVal, f.Actual_Val AS actualVal, " +
                     "CASE WHEN f.Actual_Val IS NULL OR f.Actual_Val = 0 THEN NULL " +
                     "ELSE (f.Forecast_Val - f.Actual_Val) / f.Actual_Val END AS deviationRate, " +
                     "m.Model_Name AS modelName, f.Model_Version AS modelVersion " +
                     "FROM Data_PV_Forecast f " +
                     "JOIN PV_Grid_Point p ON f.Point_ID = p.Point_ID " +
                     "LEFT JOIN PV_Forecast_Model m ON f.Model_Version = m.Model_Version " +
                     "WHERE f.Forecast_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, forecastId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listModelAlerts() throws Exception {
        String sql = "SELECT a.Alert_ID AS alertId, p.Point_Name AS pointName, " +
                     "CONVERT(VARCHAR(19), a.Trigger_Time, 120) AS triggerTime, " +
                     "a.Remark AS remark, a.Process_Status AS processStatus, a.Model_Version AS modelVersion " +
                     "FROM PV_Model_Alert a " +
                     "JOIN PV_Grid_Point p ON a.Point_ID = p.Point_ID " +
                     "ORDER BY a.Trigger_Time DESC";
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
}
