package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.PVDevice;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class PVDeviceDAO extends BaseDAO<PVDevice, Long> {

    @Override
    protected String getTableName() {
        return "PV_Device";
    }

    @Override
    protected String getIdColumnName() {
        return "Device_ID";
    }

    @Override
    protected PVDevice mapRow(ResultSet rs) throws SQLException {
        PVDevice device = new PVDevice();
        device.setDeviceId(rs.getLong("Device_ID"));
        device.setDeviceType(rs.getString("Device_Type"));
        device.setCapacity(rs.getObject("Capacity", Double.class));
        device.setRunStatus(rs.getString("Run_Status"));
        device.setInstallDate(rs.getObject("Install_Date", java.util.Date.class));
        device.setProtocol(rs.getString("Protocol"));
        device.setPointId(rs.getLong("Point_ID"));
        device.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        return device;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO PV_Device (Device_Type, Capacity, Run_Status, Install_Date, Protocol, Point_ID, Ledger_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, PVDevice entity) throws SQLException {
        ps.setString(1, entity.getDeviceType());
        if (entity.getCapacity() != null) {
            ps.setDouble(2, entity.getCapacity());
        } else {
            ps.setNull(2, java.sql.Types.DECIMAL);
        }
        ps.setString(3, entity.getRunStatus());
        if (entity.getInstallDate() != null) {
            ps.setDate(4, new java.sql.Date(entity.getInstallDate().getTime()));
        } else {
            ps.setNull(4, java.sql.Types.DATE);
        }
        ps.setString(5, entity.getProtocol());
        ps.setLong(6, entity.getPointId());
        if (entity.getLedgerId() != null) {
            ps.setLong(7, entity.getLedgerId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE PV_Device SET Device_Type=?, Capacity=?, Run_Status=?, Install_Date=?, Protocol=?, Point_ID=?, Ledger_ID=? WHERE Device_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, PVDevice entity) throws SQLException {
        ps.setString(1, entity.getDeviceType());
        if (entity.getCapacity() != null) {
            ps.setDouble(2, entity.getCapacity());
        } else {
            ps.setNull(2, java.sql.Types.DECIMAL);
        }
        ps.setString(3, entity.getRunStatus());
        if (entity.getInstallDate() != null) {
            ps.setDate(4, new java.sql.Date(entity.getInstallDate().getTime()));
        } else {
            ps.setNull(4, java.sql.Types.DATE);
        }
        ps.setString(5, entity.getProtocol());
        ps.setLong(6, entity.getPointId());
        if (entity.getLedgerId() != null) {
            ps.setLong(7, entity.getLedgerId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        ps.setLong(8, entity.getDeviceId());
    }
}
