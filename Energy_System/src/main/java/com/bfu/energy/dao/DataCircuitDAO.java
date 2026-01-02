package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataCircuit;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class DataCircuitDAO extends BaseDAO<DataCircuit, Long> {

    @Override
    protected String getTableName() {
        return "Data_Circuit";
    }

    @Override
    protected String getIdColumnName() {
        return "Data_ID";
    }

    @Override
    protected DataCircuit mapRow(ResultSet rs) throws SQLException {
        DataCircuit data = new DataCircuit();
        data.setDataId(rs.getLong("Data_ID"));
        data.setCircuitId(rs.getLong("Circuit_ID"));
        data.setCollectTime(rs.getTimestamp("Collect_Time"));
        data.setVoltage(rs.getObject("Voltage", Double.class));
        data.setCurrentVal(rs.getObject("Current_Val", Double.class));
        data.setActivePower(rs.getObject("Active_Power", Double.class));
        data.setReactivePower(rs.getObject("Reactive_Power", Double.class));
        data.setPowerFactor(rs.getObject("Power_Factor", Double.class));
        data.setSwitchStatus(rs.getString("Switch_Status"));
        data.setFactoryId(rs.getObject("Factory_ID", Long.class));
        return data;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_Circuit (Circuit_ID, Collect_Time, Voltage, Current_Val, Active_Power, Reactive_Power, Power_Factor, Switch_Status, Factory_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataCircuit entity) throws SQLException {
        ps.setLong(1, entity.getCircuitId());
        ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        if (entity.getVoltage() != null) {
            ps.setDouble(3, entity.getVoltage());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getCurrentVal() != null) {
            ps.setDouble(4, entity.getCurrentVal());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getActivePower() != null) {
            ps.setDouble(5, entity.getActivePower());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getReactivePower() != null) {
            ps.setDouble(6, entity.getReactivePower());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getPowerFactor() != null) {
            ps.setDouble(7, entity.getPowerFactor());
        } else {
            ps.setNull(7, java.sql.Types.DECIMAL);
        }
        ps.setString(8, entity.getSwitchStatus());
        if (entity.getFactoryId() != null) {
            ps.setLong(9, entity.getFactoryId());
        } else {
            ps.setNull(9, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_Circuit SET Circuit_ID=?, Collect_Time=?, Voltage=?, Current_Val=?, Active_Power=?, Reactive_Power=?, Power_Factor=?, Switch_Status=?, Factory_ID=? WHERE Data_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataCircuit entity) throws SQLException {
        ps.setLong(1, entity.getCircuitId());
        ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        if (entity.getVoltage() != null) {
            ps.setDouble(3, entity.getVoltage());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getCurrentVal() != null) {
            ps.setDouble(4, entity.getCurrentVal());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getActivePower() != null) {
            ps.setDouble(5, entity.getActivePower());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getReactivePower() != null) {
            ps.setDouble(6, entity.getReactivePower());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getPowerFactor() != null) {
            ps.setDouble(7, entity.getPowerFactor());
        } else {
            ps.setNull(7, java.sql.Types.DECIMAL);
        }
        ps.setString(8, entity.getSwitchStatus());
        if (entity.getFactoryId() != null) {
            ps.setLong(9, entity.getFactoryId());
        } else {
            ps.setNull(9, java.sql.Types.BIGINT);
        }
        ps.setLong(10, entity.getDataId());
    }

    public List<DataCircuit> findByCircuitId(Long circuitId) throws SQLException {
        String sql = "SELECT * FROM Data_Circuit WHERE Circuit_ID = ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, circuitId);
            rs = ps.executeQuery();
            List<DataCircuit> list = new ArrayList<>();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
            return list;
        } catch (SQLException e) {
            throw e;
        } finally {
            close(conn, ps, rs);
        }
    }

    public List<DataCircuit> findByTimeRange(Long circuitId, java.util.Date startTime, java.util.Date endTime) throws SQLException {
        String sql = "SELECT * FROM Data_Circuit WHERE Circuit_ID = ? AND Collect_Time BETWEEN ? AND ? ORDER BY Collect_Time";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, circuitId);
            ps.setTimestamp(2, new java.sql.Timestamp(startTime.getTime()));
            ps.setTimestamp(3, new java.sql.Timestamp(endTime.getTime()));
            rs = ps.executeQuery();
            List<DataCircuit> list = new ArrayList<>();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
            return list;
        } catch (SQLException e) {
            throw e;
        } finally {
            close(conn, ps, rs);
        }
    }

    public DataCircuit findLatestByCircuitId(Long circuitId) throws SQLException {
        String sql = "SELECT TOP 1 * FROM Data_Circuit WHERE Circuit_ID = ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, circuitId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
            return null;
        } catch (SQLException e) {
            throw e;
        } finally {
            close(conn, ps, rs);
        }
    }

    public List<DataCircuit> findBySwitchStatus(String switchStatus) throws SQLException {
        String sql = "SELECT * FROM Data_Circuit WHERE Switch_Status = ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, switchStatus);
            rs = ps.executeQuery();
            List<DataCircuit> list = new ArrayList<>();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
            return list;
        } catch (SQLException e) {
            throw e;
        } finally {
            close(conn, ps, rs);
        }
    }

    public List<DataCircuit> findAbnormalVoltage(Double minVoltage, Double maxVoltage) throws SQLException {
        String sql = "SELECT * FROM Data_Circuit WHERE Voltage < ? OR Voltage > ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setDouble(1, minVoltage);
            ps.setDouble(2, maxVoltage);
            rs = ps.executeQuery();
            List<DataCircuit> list = new ArrayList<>();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
            return list;
        } catch (SQLException e) {
            throw e;
        } finally {
            close(conn, ps, rs);
        }
    }
}
