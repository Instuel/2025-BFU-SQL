package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataTransformer;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class DataTransformerDAO extends BaseDAO<DataTransformer, Long> {

    @Override
    protected String getTableName() {
        return "Data_Transformer";
    }

    @Override
    protected String getIdColumnName() {
        return "Data_ID";
    }

    @Override
    protected DataTransformer mapRow(ResultSet rs) throws SQLException {
        DataTransformer data = new DataTransformer();
        data.setDataId(rs.getLong("Data_ID"));
        data.setTransformerId(rs.getLong("Transformer_ID"));
        data.setCollectTime(rs.getTimestamp("Collect_Time"));
        data.setWindingTemp(rs.getObject("Winding_Temp", Double.class));
        data.setCoreTemp(rs.getObject("Core_Temp", Double.class));
        data.setLoadRate(rs.getObject("Load_Rate", Double.class));
        data.setFactoryId(rs.getObject("Factory_ID", Long.class));
        return data;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_Transformer (Transformer_ID, Collect_Time, Winding_Temp, Core_Temp, Load_Rate, Factory_ID) VALUES (?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataTransformer entity) throws SQLException {
        ps.setLong(1, entity.getTransformerId());
        ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        if (entity.getWindingTemp() != null) {
            ps.setDouble(3, entity.getWindingTemp());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getCoreTemp() != null) {
            ps.setDouble(4, entity.getCoreTemp());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getLoadRate() != null) {
            ps.setDouble(5, entity.getLoadRate());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(6, entity.getFactoryId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_Transformer SET Transformer_ID=?, Collect_Time=?, Winding_Temp=?, Core_Temp=?, Load_Rate=?, Factory_ID=? WHERE Data_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataTransformer entity) throws SQLException {
        ps.setLong(1, entity.getTransformerId());
        ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        if (entity.getWindingTemp() != null) {
            ps.setDouble(3, entity.getWindingTemp());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getCoreTemp() != null) {
            ps.setDouble(4, entity.getCoreTemp());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getLoadRate() != null) {
            ps.setDouble(5, entity.getLoadRate());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(6, entity.getFactoryId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        ps.setLong(7, entity.getDataId());
    }

    public List<DataTransformer> findByTransformerId(Long transformerId) throws SQLException {
        String sql = "SELECT * FROM Data_Transformer WHERE Transformer_ID = ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, transformerId);
            rs = ps.executeQuery();
            List<DataTransformer> list = new ArrayList<>();
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

    public List<DataTransformer> findByTimeRange(Long transformerId, java.util.Date startTime, java.util.Date endTime) throws SQLException {
        String sql = "SELECT * FROM Data_Transformer WHERE Transformer_ID = ? AND Collect_Time BETWEEN ? AND ? ORDER BY Collect_Time";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, transformerId);
            ps.setTimestamp(2, new java.sql.Timestamp(startTime.getTime()));
            ps.setTimestamp(3, new java.sql.Timestamp(endTime.getTime()));
            rs = ps.executeQuery();
            List<DataTransformer> list = new ArrayList<>();
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

    public DataTransformer findLatestByTransformerId(Long transformerId) throws SQLException {
        String sql = "SELECT TOP 1 * FROM Data_Transformer WHERE Transformer_ID = ? ORDER BY Collect_Time DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(sql);
            ps.setLong(1, transformerId);
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
}
