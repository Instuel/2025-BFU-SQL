package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.ConfigPeakValley;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.util.ArrayList;
import java.util.List;

public class ConfigPeakValleyDAO extends BaseDAO<ConfigPeakValley, Long> {

    @Override
    protected String getTableName() {
        return "Config_PeakValley";
    }

    @Override
    protected String getIdColumnName() {
        return "Config_ID";
    }

    @Override
    protected ConfigPeakValley mapRow(ResultSet rs) throws SQLException {
        ConfigPeakValley config = new ConfigPeakValley();
        config.setConfigId(rs.getLong("Config_ID"));
        config.setTimeType(rs.getString("Time_Type"));
        config.setStartTime(rs.getTime("Start_Time"));
        config.setEndTime(rs.getTime("End_Time"));
        config.setPriceRate(rs.getDouble("Price_Rate"));
        return config;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Config_PeakValley (Time_Type, Start_Time, End_Time, Price_Rate) VALUES (?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, ConfigPeakValley entity) throws SQLException {
        ps.setString(1, entity.getTimeType());
        ps.setTime(2, entity.getStartTime());
        ps.setTime(3, entity.getEndTime());
        ps.setDouble(4, entity.getPriceRate());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Config_PeakValley SET Time_Type=?, Start_Time=?, End_Time=?, Price_Rate=? WHERE Config_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, ConfigPeakValley entity) throws SQLException {
        ps.setString(1, entity.getTimeType());
        ps.setTime(2, entity.getStartTime());
        ps.setTime(3, entity.getEndTime());
        ps.setDouble(4, entity.getPriceRate());
        ps.setLong(5, entity.getConfigId());
    }

    public ConfigPeakValley findByTimeType(String timeType) {
        String sql = "SELECT * FROM Config_PeakValley WHERE Time_Type = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, timeType);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<ConfigPeakValley> findAllOrderedByTime() {
        String sql = "SELECT * FROM Config_PeakValley ORDER BY Start_Time";
        List<ConfigPeakValley> list = new ArrayList<>();
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

    public ConfigPeakValley findByTime(Time time) {
        String sql = "SELECT * FROM Config_PeakValley WHERE Start_Time <= ? AND End_Time > ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTime(1, time);
            ps.setTime(2, time);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}
