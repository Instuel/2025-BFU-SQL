package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.EnergyMeter;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class EnergyMeterDAO extends BaseDAO<EnergyMeter, Long> {

    @Override
    protected String getTableName() {
        return "Energy_Meter";
    }

    @Override
    protected String getIdColumnName() {
        return "Meter_ID";
    }

    @Override
    protected EnergyMeter mapRow(ResultSet rs) throws SQLException {
        EnergyMeter meter = new EnergyMeter();
        meter.setMeterId(rs.getLong("Meter_ID"));
        meter.setEnergyType(rs.getString("Energy_Type"));
        meter.setCommProtocol(rs.getString("Comm_Protocol"));
        meter.setRunStatus(rs.getString("Run_Status"));
        meter.setInstallLocation(rs.getString("Install_Location"));
        meter.setCalibCycleMonths(rs.getObject("Calib_Cycle_Months", Integer.class));
        meter.setManufacturer(rs.getString("Manufacturer"));
        meter.setFactoryId(rs.getLong("Factory_ID"));
        meter.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        return meter;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Energy_Meter (Energy_Type, Comm_Protocol, Run_Status, Install_Location, Calib_Cycle_Months, Manufacturer, Factory_ID, Ledger_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, EnergyMeter entity) throws SQLException {
        ps.setString(1, entity.getEnergyType());
        ps.setString(2, entity.getCommProtocol());
        ps.setString(3, entity.getRunStatus());
        ps.setString(4, entity.getInstallLocation());
        if (entity.getCalibCycleMonths() != null) {
            ps.setInt(5, entity.getCalibCycleMonths());
        } else {
            ps.setNull(5, java.sql.Types.INTEGER);
        }
        ps.setString(6, entity.getManufacturer());
        ps.setLong(7, entity.getFactoryId());
        if (entity.getLedgerId() != null) {
            ps.setLong(8, entity.getLedgerId());
        } else {
            ps.setNull(8, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Energy_Meter SET Energy_Type=?, Comm_Protocol=?, Run_Status=?, Install_Location=?, Calib_Cycle_Months=?, Manufacturer=?, Factory_ID=?, Ledger_ID=? WHERE Meter_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, EnergyMeter entity) throws SQLException {
        ps.setString(1, entity.getEnergyType());
        ps.setString(2, entity.getCommProtocol());
        ps.setString(3, entity.getRunStatus());
        ps.setString(4, entity.getInstallLocation());
        if (entity.getCalibCycleMonths() != null) {
            ps.setInt(5, entity.getCalibCycleMonths());
        } else {
            ps.setNull(5, java.sql.Types.INTEGER);
        }
        ps.setString(6, entity.getManufacturer());
        ps.setLong(7, entity.getFactoryId());
        if (entity.getLedgerId() != null) {
            ps.setLong(8, entity.getLedgerId());
        } else {
            ps.setNull(8, java.sql.Types.BIGINT);
        }
        ps.setLong(9, entity.getMeterId());
    }

    public List<EnergyMeter> findByFactoryId(Long factoryId) {
        String sql = "SELECT * FROM Energy_Meter WHERE Factory_ID = ?";
        List<EnergyMeter> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, factoryId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<EnergyMeter> findByEnergyType(String energyType) {
        String sql = "SELECT * FROM Energy_Meter WHERE Energy_Type = ?";
        List<EnergyMeter> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, energyType);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<EnergyMeter> findByRunStatus(String runStatus) {
        String sql = "SELECT * FROM Energy_Meter WHERE Run_Status = ?";
        List<EnergyMeter> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, runStatus);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<EnergyMeter> findAll() {
        String sql = "SELECT * FROM Energy_Meter ORDER BY Meter_ID";
        List<EnergyMeter> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
}
