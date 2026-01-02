package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.PVForecastModel;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PVForecastModelDAO extends BaseDAO<PVForecastModel, String> {

    @Override
    protected String getTableName() {
        return "PV_Forecast_Model";
    }

    @Override
    protected String getIdColumnName() {
        return "Model_Version";
    }

    @Override
    protected PVForecastModel mapRow(ResultSet rs) throws SQLException {
        PVForecastModel model = new PVForecastModel();
        model.setModelVersion(rs.getString("Model_Version"));
        model.setModelName(rs.getString("Model_Name"));
        model.setStatus(rs.getString("Status"));
        model.setUpdateTime(rs.getObject("Update_Time", java.util.Date.class));
        return model;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO PV_Forecast_Model (Model_Version, Model_Name, Status, Update_Time) VALUES (?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, PVForecastModel entity) throws SQLException {
        ps.setString(1, entity.getModelVersion());
        ps.setString(2, entity.getModelName());
        ps.setString(3, entity.getStatus());
        if (entity.getUpdateTime() != null) {
            ps.setTimestamp(4, new java.sql.Timestamp(entity.getUpdateTime().getTime()));
        } else {
            ps.setNull(4, java.sql.Types.TIMESTAMP);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE PV_Forecast_Model SET Model_Name=?, Status=?, Update_Time=? WHERE Model_Version=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, PVForecastModel entity) throws SQLException {
        ps.setString(1, entity.getModelName());
        ps.setString(2, entity.getStatus());
        if (entity.getUpdateTime() != null) {
            ps.setTimestamp(3, new java.sql.Timestamp(entity.getUpdateTime().getTime()));
        } else {
            ps.setNull(3, java.sql.Types.TIMESTAMP);
        }
        ps.setString(4, entity.getModelVersion());
    }

    public List<PVForecastModel> findAll() {
        String sql = "SELECT * FROM PV_Forecast_Model ORDER BY Update_Time DESC";
        List<PVForecastModel> list = new ArrayList<>();
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

    public PVForecastModel findLatest() {
        String sql = "SELECT TOP 1 * FROM PV_Forecast_Model ORDER BY Update_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public PVForecastModel findByStatus(String status) {
        String sql = "SELECT TOP 1 * FROM PV_Forecast_Model WHERE Status = ? ORDER BY Update_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, status);
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
