package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DashboardConfig;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class DashboardConfigDAO extends BaseDAO<DashboardConfig, Long> {

    @Override
    protected String getTableName() {
        return "Dashboard_Config";
    }

    @Override
    protected String getIdColumnName() {
        return "Config_ID";
    }

    @Override
    protected DashboardConfig mapRow(ResultSet rs) throws SQLException {
        DashboardConfig config = new DashboardConfig();
        config.setConfigId(rs.getLong("Config_ID"));
        config.setModuleName(rs.getString("Module_Name"));
        config.setRefreshRate(rs.getString("Refresh_Rate"));
        config.setSortRule(rs.getString("Sort_Rule"));
        config.setDisplayFields(rs.getString("Display_Fields"));
        config.setAuthLevel(rs.getString("Auth_Level"));
        return config;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Dashboard_Config (Module_Name, Refresh_Rate, Sort_Rule, Display_Fields, Auth_Level) VALUES (?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DashboardConfig entity) throws SQLException {
        ps.setString(1, entity.getModuleName());
        ps.setString(2, entity.getRefreshRate());
        ps.setString(3, entity.getSortRule());
        ps.setString(4, entity.getDisplayFields());
        ps.setString(5, entity.getAuthLevel());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Dashboard_Config SET Module_Name=?, Refresh_Rate=?, Sort_Rule=?, Display_Fields=?, Auth_Level=? WHERE Config_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DashboardConfig entity) throws SQLException {
        ps.setString(1, entity.getModuleName());
        ps.setString(2, entity.getRefreshRate());
        ps.setString(3, entity.getSortRule());
        ps.setString(4, entity.getDisplayFields());
        ps.setString(5, entity.getAuthLevel());
        ps.setLong(6, entity.getConfigId());
    }

    public DashboardConfig findByModuleName(String moduleName) {
        String sql = "SELECT * FROM Dashboard_Config WHERE Module_Name = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, moduleName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<DashboardConfig> findByAuthLevel(String authLevel) {
        String sql = "SELECT * FROM Dashboard_Config WHERE Auth_Level = ? ORDER BY Config_ID";
        List<DashboardConfig> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, authLevel);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DashboardConfig> findAll() {
        String sql = "SELECT * FROM Dashboard_Config ORDER BY Config_ID";
        List<DashboardConfig> list = new ArrayList<>();
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
