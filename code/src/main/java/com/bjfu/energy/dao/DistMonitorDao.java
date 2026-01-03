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

public class DistMonitorDao {

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public Map<String, Object> getRoomStats() throws Exception {
        String sql = "SELECT " +
                     "(SELECT COUNT(*) FROM Dist_Room) AS roomCount, " +
                     "(SELECT COUNT(*) FROM Dist_Circuit) AS circuitCount, " +
                     "(SELECT COUNT(*) FROM Dist_Transformer) AS transformerCount, " +
                     "(SELECT CONVERT(VARCHAR(16), MAX(Collect_Time), 120) FROM Data_Circuit) AS latestCircuitTime";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return mapRow(rs);
            }
        }
        return new HashMap<>();
    }

    public List<Map<String, Object>> listRooms() throws Exception {
        String sql = "SELECT r.Room_ID AS roomId, r.Room_Name AS roomName, r.Location AS location, " +
                     "r.Voltage_Level AS voltageLevel, u.Real_Name AS managerName, " +
                     "u.Contact_Phone AS managerPhone, " +
                     "(SELECT COUNT(*) FROM Dist_Transformer t WHERE t.Room_ID = r.Room_ID) AS transformerCount, " +
                     "(SELECT COUNT(*) FROM Dist_Circuit c WHERE c.Room_ID = r.Room_ID) AS circuitCount " +
                     "FROM Dist_Room r " +
                     "LEFT JOIN Sys_User u ON r.Manager_User_ID = u.User_ID " +
                     "ORDER BY r.Room_ID DESC";
        List<Map<String, Object>> rooms = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rooms.add(mapRow(rs));
            }
        }
        return rooms;
    }

    public Map<String, Object> findRoomById(long roomId) throws Exception {
        String sql = "SELECT TOP 1 r.Room_ID AS roomId, r.Room_Name AS roomName, r.Location AS location, " +
                     "r.Voltage_Level AS voltageLevel, r.Factory_ID AS factoryId, f.Factory_Name AS factoryName, " +
                     "u.Real_Name AS managerName, u.Contact_Phone AS managerPhone " +
                     "FROM Dist_Room r " +
                     "LEFT JOIN Base_Factory f ON r.Factory_ID = f.Factory_ID " +
                     "LEFT JOIN Sys_User u ON r.Manager_User_ID = u.User_ID " +
                     "WHERE r.Room_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listCircuits(Long roomId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT c.Circuit_ID AS circuitId, c.Circuit_Name AS circuitName, ")
           .append("r.Room_Name AS roomName, ")
           .append("d.Voltage AS voltage, d.Current_Val AS currentVal, ")
           .append("d.Active_Power AS activePower, d.Power_Factor AS powerFactor, ")
           .append("d.Switch_Status AS switchStatus, ")
           .append("CONVERT(VARCHAR(16), d.Collect_Time, 120) AS collectTime ")
           .append("FROM Dist_Circuit c ")
           .append("JOIN Dist_Room r ON c.Room_ID = r.Room_ID ")
           .append("OUTER APPLY ( ")
           .append("  SELECT TOP 1 Voltage, Current_Val, Active_Power, Power_Factor, Switch_Status, Collect_Time ")
           .append("  FROM Data_Circuit dc WHERE dc.Circuit_ID = c.Circuit_ID ")
           .append("  ORDER BY Collect_Time DESC ")
           .append(") d ");
        List<Object> params = new ArrayList<>();
        if (roomId != null) {
            sql.append("WHERE c.Room_ID = ? ");
            params.add(roomId);
        }
        sql.append("ORDER BY c.Circuit_ID DESC");
        List<Map<String, Object>> circuits = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    circuits.add(mapRow(rs));
                }
            }
        }
        return circuits;
    }

    public Map<String, Object> findCircuitById(long circuitId) throws Exception {
        String sql = "SELECT TOP 1 c.Circuit_ID AS circuitId, c.Circuit_Name AS circuitName, " +
                     "r.Room_ID AS roomId, r.Room_Name AS roomName, r.Voltage_Level AS voltageLevel, " +
                     "c.Ledger_ID AS ledgerId, l.Device_Name AS ledgerName, l.Model_Spec AS modelSpec " +
                     "FROM Dist_Circuit c " +
                     "JOIN Dist_Room r ON c.Room_ID = r.Room_ID " +
                     "LEFT JOIN Device_Ledger l ON c.Ledger_ID = l.Ledger_ID " +
                     "WHERE c.Circuit_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, circuitId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listCircuitData(Long circuitId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT dc.Data_ID AS dataId, dc.Circuit_ID AS circuitId, c.Circuit_Name AS circuitName, ")
           .append("r.Room_Name AS roomName, ")
           .append("CONVERT(VARCHAR(19), dc.Collect_Time, 120) AS collectTime, ")
           .append("dc.Voltage AS voltage, dc.Current_Val AS currentVal, ")
           .append("dc.Active_Power AS activePower, dc.Reactive_Power AS reactivePower, ")
           .append("dc.Power_Factor AS powerFactor, dc.Switch_Status AS switchStatus ")
           .append("FROM Data_Circuit dc ")
           .append("JOIN Dist_Circuit c ON dc.Circuit_ID = c.Circuit_ID ")
           .append("JOIN Dist_Room r ON c.Room_ID = r.Room_ID ");
        List<Object> params = new ArrayList<>();
        if (circuitId != null) {
            sql.append("WHERE dc.Circuit_ID = ? ");
            params.add(circuitId);
        }
        sql.append("ORDER BY dc.Collect_Time DESC");
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

    public List<Map<String, Object>> listTransformers(Long roomId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT t.Transformer_ID AS transformerId, t.Transformer_Name AS transformerName, ")
           .append("r.Room_Name AS roomName, ")
           .append("d.Load_Rate AS loadRate, d.Winding_Temp AS windingTemp, ")
           .append("d.Core_Temp AS coreTemp, ")
           .append("CONVERT(VARCHAR(16), d.Collect_Time, 120) AS collectTime ")
           .append("FROM Dist_Transformer t ")
           .append("JOIN Dist_Room r ON t.Room_ID = r.Room_ID ")
           .append("OUTER APPLY ( ")
           .append("  SELECT TOP 1 Load_Rate, Winding_Temp, Core_Temp, Collect_Time ")
           .append("  FROM Data_Transformer dt WHERE dt.Transformer_ID = t.Transformer_ID ")
           .append("  ORDER BY Collect_Time DESC ")
           .append(") d ");
        List<Object> params = new ArrayList<>();
        if (roomId != null) {
            sql.append("WHERE t.Room_ID = ? ");
            params.add(roomId);
        }
        sql.append("ORDER BY t.Transformer_ID DESC");
        List<Map<String, Object>> transformers = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    transformers.add(mapRow(rs));
                }
            }
        }
        return transformers;
    }

    public Map<String, Object> findTransformerById(long transformerId) throws Exception {
        String sql = "SELECT TOP 1 t.Transformer_ID AS transformerId, t.Transformer_Name AS transformerName, " +
                     "r.Room_ID AS roomId, r.Room_Name AS roomName, " +
                     "t.Ledger_ID AS ledgerId, l.Device_Name AS ledgerName, l.Model_Spec AS modelSpec " +
                     "FROM Dist_Transformer t " +
                     "JOIN Dist_Room r ON t.Room_ID = r.Room_ID " +
                     "LEFT JOIN Device_Ledger l ON t.Ledger_ID = l.Ledger_ID " +
                     "WHERE t.Transformer_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, transformerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> listTransformerData(Long transformerId) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT dt.Data_ID AS dataId, dt.Transformer_ID AS transformerId, ")
           .append("t.Transformer_Name AS transformerName, ")
           .append("CONVERT(VARCHAR(19), dt.Collect_Time, 120) AS collectTime, ")
           .append("dt.Load_Rate AS loadRate, dt.Winding_Temp AS windingTemp, ")
           .append("dt.Core_Temp AS coreTemp ")
           .append("FROM Data_Transformer dt ")
           .append("JOIN Dist_Transformer t ON dt.Transformer_ID = t.Transformer_ID ");
        List<Object> params = new ArrayList<>();
        if (transformerId != null) {
            sql.append("WHERE dt.Transformer_ID = ? ");
            params.add(transformerId);
        }
        sql.append("ORDER BY dt.Collect_Time DESC");
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

    public List<Map<String, Object>> listCircuitOptions() throws Exception {
        String sql = "SELECT c.Circuit_ID AS circuitId, c.Circuit_Name AS circuitName " +
                     "FROM Dist_Circuit c ORDER BY c.Circuit_ID";
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

    public List<Map<String, Object>> listTransformerOptions() throws Exception {
        String sql = "SELECT t.Transformer_ID AS transformerId, t.Transformer_Name AS transformerName " +
                     "FROM Dist_Transformer t ORDER BY t.Transformer_ID";
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

    public List<Map<String, Object>> listWorkOrdersByLedger(Long ledgerId) throws Exception {
        if (ledgerId == null) {
            return new ArrayList<>();
        }
        String sql = "SELECT o.Order_ID AS orderId, " +
                     "CONVERT(VARCHAR(19), o.Dispatch_Time, 120) AS dispatchTime, " +
                     "CONVERT(VARCHAR(19), o.Finish_Time, 120) AS finishTime, " +
                     "o.Result_Desc AS resultDesc, o.Review_Status AS reviewStatus " +
                     "FROM Work_Order o WHERE o.Ledger_ID = ? " +
                     "ORDER BY o.Dispatch_Time DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, ledgerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }

    public List<Map<String, Object>> listAlarmsByLedger(Long ledgerId) throws Exception {
        if (ledgerId == null) {
            return new ArrayList<>();
        }
        String sql = "SELECT a.Alarm_ID AS alarmId, a.Alarm_Type AS alarmType, " +
                     "CONVERT(VARCHAR(19), a.Occur_Time, 120) AS occurTime, " +
                     "a.Content AS content, a.Alarm_Level AS alarmLevel, a.Process_Status AS processStatus " +
                     "FROM Alarm_Info a WHERE a.Ledger_ID = ? " +
                     "ORDER BY a.Occur_Time DESC";
        List<Map<String, Object>> items = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, ledgerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapRow(rs));
                }
            }
        }
        return items;
    }
}
