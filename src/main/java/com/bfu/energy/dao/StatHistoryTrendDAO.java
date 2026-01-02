package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.StatHistoryTrend;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class StatHistoryTrendDAO extends BaseDAO<StatHistoryTrend, String> {

    @Override
    protected String getTableName() {
        return "Stat_History_Trend";
    }

    @Override
    protected String getIdColumnName() {
        return "Trend_ID";
    }

    @Override
    protected StatHistoryTrend mapRow(ResultSet rs) throws SQLException {
        StatHistoryTrend trend = new StatHistoryTrend();
        trend.setTrendId(rs.getString("Trend_ID"));
        trend.setEnergyType(rs.getString("Energy_Type"));
        trend.setStatCycle(rs.getString("Stat_Cycle"));
        trend.setStatDate(rs.getDate("Stat_Date"));
        trend.setValue(rs.getBigDecimal("Value"));
        trend.setYoyRate(rs.getBigDecimal("YOY_Rate"));
        trend.setMomRate(rs.getBigDecimal("MOM_Rate"));
        trend.setConfigId(rs.getObject("Config_ID", Long.class));
        trend.setAnalystId(rs.getObject("Analyst_ID", Long.class));
        return trend;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Stat_History_Trend (Trend_ID, Energy_Type, Stat_Cycle, Stat_Date, Value, YOY_Rate, MOM_Rate, Config_ID, Analyst_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, StatHistoryTrend entity) throws SQLException {
        ps.setString(1, entity.getTrendId());
        ps.setString(2, entity.getEnergyType());
        ps.setString(3, entity.getStatCycle());
        if (entity.getStatDate() != null) {
            ps.setDate(4, entity.getStatDate());
        } else {
            ps.setNull(4, java.sql.Types.DATE);
        }
        ps.setBigDecimal(5, entity.getValue());
        ps.setBigDecimal(6, entity.getYoyRate());
        ps.setBigDecimal(7, entity.getMomRate());
        if (entity.getConfigId() != null) {
            ps.setLong(8, entity.getConfigId());
        } else {
            ps.setNull(8, java.sql.Types.BIGINT);
        }
        if (entity.getAnalystId() != null) {
            ps.setLong(9, entity.getAnalystId());
        } else {
            ps.setNull(9, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Stat_History_Trend SET Energy_Type=?, Stat_Cycle=?, Stat_Date=?, Value=?, YOY_Rate=?, MOM_Rate=?, Config_ID=?, Analyst_ID=? WHERE Trend_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, StatHistoryTrend entity) throws SQLException {
        ps.setString(1, entity.getEnergyType());
        ps.setString(2, entity.getStatCycle());
        if (entity.getStatDate() != null) {
            ps.setDate(3, entity.getStatDate());
        } else {
            ps.setNull(3, java.sql.Types.DATE);
        }
        ps.setBigDecimal(4, entity.getValue());
        ps.setBigDecimal(5, entity.getYoyRate());
        ps.setBigDecimal(6, entity.getMomRate());
        if (entity.getConfigId() != null) {
            ps.setLong(7, entity.getConfigId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        if (entity.getAnalystId() != null) {
            ps.setLong(8, entity.getAnalystId());
        } else {
            ps.setNull(8, java.sql.Types.BIGINT);
        }
        ps.setString(9, entity.getTrendId());
    }

    public List<StatHistoryTrend> findByEnergyType(String energyType) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Energy_Type = ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
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

    public List<StatHistoryTrend> findByStatCycle(String statCycle) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Stat_Cycle = ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, statCycle);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<StatHistoryTrend> findByDateRange(Date startDate, Date endDate) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Stat_Date BETWEEN ? AND ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
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

    public List<StatHistoryTrend> findByEnergyTypeAndCycle(String energyType, String statCycle) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Energy_Type = ? AND Stat_Cycle = ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, energyType);
            ps.setString(2, statCycle);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<StatHistoryTrend> findByConfigId(Long configId) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Config_ID = ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, configId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<StatHistoryTrend> findByAnalystId(Long analystId) {
        String sql = "SELECT * FROM Stat_History_Trend WHERE Analyst_ID = ? ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, analystId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public StatHistoryTrend findLatestByEnergyType(String energyType) {
        String sql = "SELECT TOP 1 * FROM Stat_History_Trend WHERE Energy_Type = ? ORDER BY Stat_Date DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, energyType);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public BigDecimal getAverageValueByDateRange(Date startDate, Date endDate) {
        String sql = "SELECT AVG(Value) as AvgValue FROM Stat_History_Trend WHERE Stat_Date BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDate(1, startDate);
            ps.setDate(2, endDate);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("AvgValue");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getAverageValueByEnergyTypeAndDateRange(String energyType, Date startDate, Date endDate) {
        String sql = "SELECT AVG(Value) as AvgValue FROM Stat_History_Trend WHERE Energy_Type = ? AND Stat_Date BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, energyType);
            ps.setDate(2, startDate);
            ps.setDate(3, endDate);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("AvgValue");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public List<StatHistoryTrend> findAll() {
        String sql = "SELECT * FROM Stat_History_Trend ORDER BY Stat_Date DESC";
        List<StatHistoryTrend> list = new ArrayList<>();
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
