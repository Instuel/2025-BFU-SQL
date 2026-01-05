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
        return listDevices(null, null);
    }

    public List<Map<String, Object>> listDevices(String sortBy, String sortOrder) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT d.Device_ID AS deviceId, ")
           .append("COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID)) AS deviceCode, ")
           .append("d.Device_Type AS deviceType, d.Capacity AS capacity, d.Run_Status AS runStatus, ")
           .append("d.Protocol AS protocol, p.Point_Name AS pointName, ")
           .append("g.Gen_KWH AS genKwh, g.Grid_KWH AS gridKwh, g.Self_KWH AS selfKwh, ")
           .append("g.Inverter_Eff AS inverterEff, ")
           .append("g.Collect_Time AS collectTimeRaw, ")
           .append("CONVERT(VARCHAR(16), g.Collect_Time, 120) AS collectTime ")
           .append("FROM PV_Device d ")
           .append("JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID ")
           .append("LEFT JOIN Device_Ledger l ON d.Ledger_ID = l.Ledger_ID ")
           .append("OUTER APPLY ( ")
           .append("  SELECT TOP 1 Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Collect_Time ")
           .append("  FROM Data_PV_Gen g WHERE g.Device_ID = d.Device_ID ")
           .append("  ORDER BY Collect_Time DESC ")
           .append(") g ");

        // 排序字段映射
        String orderColumn = "d.Device_ID";
        if ("deviceCode".equals(sortBy)) {
            // 提取设备编号中-后面的数字进行数值排序
            orderColumn = "CAST(SUBSTRING(COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID)), CHARINDEX('-', COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID))) + 1, LEN(COALESCE(l.Device_Name, CONCAT('PV-', d.Device_ID)))) AS INT)";
        } else if ("collectTime".equals(sortBy)) {
            orderColumn = "g.Collect_Time";
        } else if ("capacity".equals(sortBy)) {
            orderColumn = "d.Capacity";
        } else if ("deviceType".equals(sortBy)) {
            orderColumn = "d.Device_Type";
        }

        String order = "DESC".equalsIgnoreCase(sortOrder) ? "DESC" : "ASC";
        sql.append("ORDER BY ").append(orderColumn).append(" ").append(order);

        List<Map<String, Object>> devices = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString());
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
           .append("f.Deviation_Rate AS deviationRate, ")
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
                     "f.Deviation_Rate AS deviationRate, " +
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
        return listModelAlerts(null);
    }

    public List<Map<String, Object>> listModelAlerts(String statusFilter) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT a.Alert_ID AS alertId, p.Point_Name AS pointName, ")
           .append("CONVERT(VARCHAR(19), a.Trigger_Time, 120) AS triggerTime, ")
           .append("a.Remark AS remark, a.Process_Status AS processStatus, a.Model_Version AS modelVersion ")
           .append("FROM PV_Model_Alert a ")
           .append("JOIN PV_Grid_Point p ON a.Point_ID = p.Point_ID ");
        
        List<Object> params = new ArrayList<>();
        if (statusFilter != null && !statusFilter.trim().isEmpty()) {
            sql.append("WHERE a.Process_Status LIKE ? ");
            params.add("%" + statusFilter.trim() + "%");
        }
        sql.append("ORDER BY a.Trigger_Time DESC");
        
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

    // ==================== 光伏设备 CRUD 操作 ====================

    /**
     * 新增光伏设备
     * @param deviceType 设备类型（逆变器/汇流箱）
     * @param capacity 装机容量（kWp）
     * @param runStatus 运行状态
     * @param installDate 安装日期
     * @param protocol 通信协议
     * @param pointId 并网点ID
     * @return 新增设备的ID，失败返回-1
     */
    public long insertDevice(String deviceType, Double capacity, String runStatus, 
                             String installDate, String protocol, Long pointId) throws Exception {
        String sql = "INSERT INTO PV_Device (Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID) " +
                     "VALUES (?, ?, ?, ?, ?, ?); SELECT SCOPE_IDENTITY() AS newId;";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, deviceType);
            if (capacity != null) {
                ps.setDouble(2, capacity);
            } else {
                ps.setNull(2, java.sql.Types.DECIMAL);
            }
            ps.setString(3, runStatus != null ? runStatus : "正常");
            if (installDate != null && !installDate.isEmpty()) {
                ps.setString(4, installDate);
            } else {
                ps.setNull(4, java.sql.Types.DATE);
            }
            ps.setString(5, protocol);
            ps.setLong(6, pointId);
            
            boolean hasResult = ps.execute();
            // 跳过INSERT结果，获取SELECT结果
            if (!hasResult) {
                hasResult = ps.getMoreResults();
            }
            if (hasResult) {
                try (ResultSet rs = ps.getResultSet()) {
                    if (rs.next()) {
                        return rs.getLong("newId");
                    }
                }
            }
        }
        return -1;
    }

    /**
     * 更新光伏设备信息
     * @param deviceId 设备ID
     * @param deviceType 设备类型
     * @param capacity 装机容量
     * @param runStatus 运行状态
     * @param installDate 安装日期
     * @param protocol 通信协议
     * @param pointId 并网点ID
     * @return 更新是否成功
     */
    public boolean updateDevice(long deviceId, String deviceType, Double capacity, 
                                String runStatus, String installDate, String protocol, Long pointId) throws Exception {
        String sql = "UPDATE PV_Device SET Device_Type = ?, Capacity = ?, Run_Status = ?, " +
                     "Install_Date = ?, Protocol = ?, Point_ID = ? WHERE Device_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, deviceType);
            if (capacity != null) {
                ps.setDouble(2, capacity);
            } else {
                ps.setNull(2, java.sql.Types.DECIMAL);
            }
            ps.setString(3, runStatus);
            if (installDate != null && !installDate.isEmpty()) {
                ps.setString(4, installDate);
            } else {
                ps.setNull(4, java.sql.Types.DATE);
            }
            ps.setString(5, protocol);
            ps.setLong(6, pointId);
            ps.setLong(7, deviceId);
            
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * 删除光伏设备
     * @param deviceId 设备ID
     * @return 删除是否成功
     */
    public boolean deleteDevice(long deviceId) throws Exception {
        // 先删除关联的发电数据
        String deleteGenSql = "DELETE FROM Data_PV_Gen WHERE Device_ID = ?";
        String deleteDeviceSql = "DELETE FROM PV_Device WHERE Device_ID = ?";
        
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // 删除发电数据
                try (PreparedStatement ps = conn.prepareStatement(deleteGenSql)) {
                    ps.setLong(1, deviceId);
                    ps.executeUpdate();
                }
                // 删除设备
                try (PreparedStatement ps = conn.prepareStatement(deleteDeviceSql)) {
                    ps.setLong(1, deviceId);
                    int rows = ps.executeUpdate();
                    conn.commit();
                    return rows > 0;
                }
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /**
     * 根据ID查询设备详细信息（用于编辑）
     */
    public Map<String, Object> findDeviceForEdit(long deviceId) throws Exception {
        String sql = "SELECT d.Device_ID AS deviceId, d.Device_Type AS deviceType, " +
                     "d.Capacity AS capacity, d.Run_Status AS runStatus, " +
                     "CONVERT(VARCHAR(10), d.Install_Date, 23) AS installDate, " +
                     "d.Protocol AS protocol, d.Point_ID AS pointId, " +
                     "p.Point_Name AS pointName " +
                     "FROM PV_Device d " +
                     "JOIN PV_Grid_Point p ON d.Point_ID = p.Point_ID " +
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
}
