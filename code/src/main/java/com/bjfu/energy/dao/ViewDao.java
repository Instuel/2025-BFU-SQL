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

public class ViewDao {

    private Map<String, Object> mapRow(ResultSet rs) throws Exception {
        Map<String, Object> row = new HashMap<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            String key = meta.getColumnLabel(i);
            row.put(key, rs.getObject(i));
        }
        return row;
    }

    public List<Map<String, Object>> getCircuitAbnormalData(Long factoryId) throws Exception {
        String sql = "SELECT * FROM View_Circuit_Abnormal";
        if (factoryId != null) {
            sql += " WHERE Factory_ID = ?";
        }
        sql += " ORDER BY Collect_Time DESC";
        
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (factoryId != null) {
                ps.setLong(1, factoryId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public List<Map<String, Object>> getDataIntegrityData(Long factoryId) throws Exception {
        String sql = "SELECT * FROM View_PowerGrid_Data_Integrity";
        if (factoryId != null) {
            sql += " WHERE Factory_ID = ?";
        }
        sql += " ORDER BY Collect_Time DESC";
        
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (factoryId != null) {
                ps.setLong(1, factoryId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public List<Map<String, Object>> getPeakValleyStatsData(Long factoryId, String statDate) throws Exception {
        String sql = "SELECT * FROM View_Daily_PeakValley_Power_Stats WHERE 1=1";
        if (factoryId != null) {
            sql += " AND Factory_ID = ?";
        }
        if (statDate != null && !statDate.isEmpty()) {
            sql += " AND Stat_Date = ?";
        }
        sql += " ORDER BY Stat_Date DESC, Peak_Type";
        
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int paramIndex = 1;
            if (factoryId != null) {
                ps.setLong(paramIndex++, factoryId);
            }
            if (statDate != null && !statDate.isEmpty()) {
                ps.setString(paramIndex, statDate);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public List<Map<String, Object>> getRealtimeDeviceData(Long factoryId) throws Exception {
        String sql = "SELECT * FROM View_RealTime_Device_Data";
        if (factoryId != null) {
            sql += " WHERE Factory_Name IN (SELECT Factory_Name FROM Base_Factory WHERE Factory_ID = ?)";
        }
        sql += " ORDER BY Device_Type, Latest_Collect_Time DESC";
        
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (factoryId != null) {
                ps.setLong(1, factoryId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public List<Map<String, Object>> getEquipmentStatusData(Long factoryId) throws Exception {
        String sql = "SELECT * FROM View_DistRoom_Equipment_Status";
        if (factoryId != null) {
            sql += " WHERE Factory_ID = ?";
        }
        sql += " ORDER BY Overall_Health_Score DESC";
        
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (factoryId != null) {
                ps.setLong(1, factoryId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }
}
