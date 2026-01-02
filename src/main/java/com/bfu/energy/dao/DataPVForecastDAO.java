package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataPVForecast;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class DataPVForecastDAO extends BaseDAO<DataPVForecast, Long> {

    @Override
    protected String getTableName() {
        return "Data_PV_Forecast";
    }

    @Override
    protected String getIdColumnName() {
        return "Forecast_ID";
    }

    @Override
    protected DataPVForecast mapRow(ResultSet rs) throws SQLException {
        DataPVForecast forecast = new DataPVForecast();
        forecast.setForecastId(rs.getLong("Forecast_ID"));
        forecast.setPointId(rs.getLong("Point_ID"));
        forecast.setForecastDate(rs.getObject("Forecast_Date", java.util.Date.class));
        forecast.setTimeSlot(rs.getString("Time_Slot"));
        forecast.setForecastVal(rs.getObject("Forecast_Val", Double.class));
        forecast.setActualVal(rs.getObject("Actual_Val", Double.class));
        forecast.setModelVersion(rs.getString("Model_Version"));
        forecast.setAnalystId(rs.getObject("Analyst_ID", Long.class));
        return forecast;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_PV_Forecast (Point_ID, Forecast_Date, Time_Slot, Forecast_Val, Actual_Val, Model_Version, Analyst_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataPVForecast entity) throws SQLException {
        ps.setLong(1, entity.getPointId());
        if (entity.getForecastDate() != null) {
            ps.setDate(2, new java.sql.Date(entity.getForecastDate().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.DATE);
        }
        ps.setString(3, entity.getTimeSlot());
        if (entity.getForecastVal() != null) {
            ps.setDouble(4, entity.getForecastVal());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getActualVal() != null) {
            ps.setDouble(5, entity.getActualVal());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        ps.setString(6, entity.getModelVersion());
        if (entity.getAnalystId() != null) {
            ps.setLong(7, entity.getAnalystId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_PV_Forecast SET Point_ID=?, Forecast_Date=?, Time_Slot=?, Forecast_Val=?, Actual_Val=?, Model_Version=?, Analyst_ID=? WHERE Forecast_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataPVForecast entity) throws SQLException {
        ps.setLong(1, entity.getPointId());
        if (entity.getForecastDate() != null) {
            ps.setDate(2, new java.sql.Date(entity.getForecastDate().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.DATE);
        }
        ps.setString(3, entity.getTimeSlot());
        if (entity.getForecastVal() != null) {
            ps.setDouble(4, entity.getForecastVal());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getActualVal() != null) {
            ps.setDouble(5, entity.getActualVal());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        ps.setString(6, entity.getModelVersion());
        if (entity.getAnalystId() != null) {
            ps.setLong(7, entity.getAnalystId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        ps.setLong(8, entity.getForecastId());
    }

    public List<DataPVForecast> findAll() {
        String sql = "SELECT * FROM Data_PV_Forecast ORDER BY Forecast_Date DESC, Time_Slot";
        List<DataPVForecast> list = new ArrayList<>();
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

    public List<DataPVForecast> findByPointId(Long pointId) {
        String sql = "SELECT * FROM Data_PV_Forecast WHERE Point_ID = ? ORDER BY Forecast_Date DESC, Time_Slot";
        List<DataPVForecast> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, pointId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataPVForecast> findByModelVersion(String modelVersion) {
        String sql = "SELECT * FROM Data_PV_Forecast WHERE Model_Version = ? ORDER BY Forecast_Date DESC, Time_Slot";
        List<DataPVForecast> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, modelVersion);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataPVForecast> findByDateRange(java.util.Date startDate, java.util.Date endDate) {
        String sql = "SELECT * FROM Data_PV_Forecast WHERE Forecast_Date BETWEEN ? AND ? ORDER BY Forecast_Date DESC, Time_Slot";
        List<DataPVForecast> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDate(1, new java.sql.Date(startDate.getTime()));
            ps.setDate(2, new java.sql.Date(endDate.getTime()));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataPVForecast> findByTimeSlot(String timeSlot) {
        String sql = "SELECT * FROM Data_PV_Forecast WHERE Time_Slot = ? ORDER BY Forecast_Date DESC";
        List<DataPVForecast> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, timeSlot);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataPVForecast> findByPointIdAndDateRange(Long pointId, java.util.Date startDate, java.util.Date endDate) {
        String sql = "SELECT * FROM Data_PV_Forecast WHERE Point_ID = ? AND Forecast_Date BETWEEN ? AND ? ORDER BY Forecast_Date DESC, Time_Slot";
        List<DataPVForecast> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, pointId);
            ps.setDate(2, new java.sql.Date(startDate.getTime()));
            ps.setDate(3, new java.sql.Date(endDate.getTime()));
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
