package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataPeakValley;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

public class DataPeakValleyDAO extends BaseDAO<DataPeakValley, Long> {

    @Override
    protected String getTableName() {
        return "Data_PeakValley";
    }

    @Override
    protected String getIdColumnName() {
        return "Record_ID";
    }

    @Override
    protected DataPeakValley mapRow(ResultSet rs) throws SQLException {
        DataPeakValley data = new DataPeakValley();
        data.setRecordId(rs.getLong("Record_ID"));
        data.setStatDate(rs.getDate("Stat_Date"));
        data.setEnergyType(rs.getString("Energy_Type"));
        data.setFactoryId(rs.getLong("Factory_ID"));
        data.setPeakType(rs.getString("Peak_Type"));
        data.setTotalConsumption(rs.getBigDecimal("Total_Consumption"));
        data.setCostAmount(rs.getBigDecimal("Cost_Amount"));
        data.setEnergyMgrId(rs.getObject("EnergyMgr_ID", Long.class));
        return data;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_PeakValley (Stat_Date, Energy_Type, Factory_ID, Peak_Type, Total_Consumption, Cost_Amount, EnergyMgr_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataPeakValley entity) throws SQLException {
        ps.setDate(1, entity.getStatDate());
        ps.setString(2, entity.getEnergyType());
        ps.setLong(3, entity.getFactoryId());
        ps.setString(4, entity.getPeakType());
        if (entity.getTotalConsumption() != null) {
            ps.setBigDecimal(5, entity.getTotalConsumption());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getCostAmount() != null) {
            ps.setBigDecimal(6, entity.getCostAmount());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getEnergyMgrId() != null) {
            ps.setLong(7, entity.getEnergyMgrId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_PeakValley SET Stat_Date=?, Energy_Type=?, Factory_ID=?, Peak_Type=?, Total_Consumption=?, Cost_Amount=?, EnergyMgr_ID=? WHERE Record_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataPeakValley entity) throws SQLException {
        ps.setDate(1, entity.getStatDate());
        ps.setString(2, entity.getEnergyType());
        ps.setLong(3, entity.getFactoryId());
        ps.setString(4, entity.getPeakType());
        if (entity.getTotalConsumption() != null) {
            ps.setBigDecimal(5, entity.getTotalConsumption());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getCostAmount() != null) {
            ps.setBigDecimal(6, entity.getCostAmount());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getEnergyMgrId() != null) {
            ps.setLong(7, entity.getEnergyMgrId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        ps.setLong(8, entity.getRecordId());
    }

    public List<DataPeakValley> findByFactoryId(Long factoryId) {
        String sql = "SELECT * FROM Data_PeakValley WHERE Factory_ID = ? ORDER BY Stat_Date DESC";
        List<DataPeakValley> list = new ArrayList<>();
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

    public List<DataPeakValley> findByStatDate(Date statDate) {
        String sql = "SELECT * FROM Data_PeakValley WHERE Stat_Date = ?";
        List<DataPeakValley> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDate(1, statDate);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataPeakValley> findByFactoryIdAndDateRange(Long factoryId, Date startDate, Date endDate) {
        String sql = "SELECT * FROM Data_PeakValley WHERE Factory_ID = ? AND Stat_Date BETWEEN ? AND ? ORDER BY Stat_Date DESC";
        List<DataPeakValley> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, factoryId);
            ps.setDate(2, startDate);
            ps.setDate(3, endDate);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public BigDecimal getTotalConsumptionByFactoryAndDate(Long factoryId, Date statDate) {
        String sql = "SELECT SUM(Total_Consumption) as total FROM Data_PeakValley WHERE Factory_ID = ? AND Stat_Date = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, factoryId);
            ps.setDate(2, statDate);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getTotalCostByFactoryAndDateRange(Long factoryId, Date startDate, Date endDate) {
        String sql = "SELECT SUM(Cost_Amount) as total FROM Data_PeakValley WHERE Factory_ID = ? AND Stat_Date BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, factoryId);
            ps.setDate(2, startDate);
            ps.setDate(3, endDate);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public List<DataPeakValley> findByDateRange(Date startDate, Date endDate) {
        String sql = "SELECT * FROM Data_PeakValley WHERE Stat_Date BETWEEN ? AND ? ORDER BY Stat_Date DESC";
        List<DataPeakValley> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDate(1, startDate);
            ps.setDate(2, endDate);
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
