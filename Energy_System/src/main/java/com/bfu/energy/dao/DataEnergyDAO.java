package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataEnergy;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class DataEnergyDAO extends BaseDAO<DataEnergy, Long> {

    @Override
    protected String getTableName() {
        return "Data_Energy";
    }

    @Override
    protected String getIdColumnName() {
        return "Data_ID";
    }

    @Override
    protected DataEnergy mapRow(ResultSet rs) throws SQLException {
        DataEnergy data = new DataEnergy();
        data.setDataId(rs.getLong("Data_ID"));
        data.setMeterId(rs.getLong("Meter_ID"));
        data.setCollectTime(rs.getTimestamp("Collect_Time"));
        data.setValue(rs.getBigDecimal("Value"));
        data.setUnit(rs.getString("Unit"));
        data.setQuality(rs.getString("Quality"));
        data.setFactoryId(rs.getObject("Factory_ID", Long.class));
        data.setPvRecordId(rs.getObject("PV_Record_ID", Long.class));
        return data;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_Energy (Meter_ID, Collect_Time, Value, Unit, Quality, Factory_ID, PV_Record_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataEnergy entity) throws SQLException {
        ps.setLong(1, entity.getMeterId());
        ps.setTimestamp(2, entity.getCollectTime());
        ps.setBigDecimal(3, entity.getValue());
        ps.setString(4, entity.getUnit());
        ps.setString(5, entity.getQuality());
        if (entity.getFactoryId() != null) {
            ps.setLong(6, entity.getFactoryId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        if (entity.getPvRecordId() != null) {
            ps.setLong(7, entity.getPvRecordId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_Energy SET Meter_ID=?, Collect_Time=?, Value=?, Unit=?, Quality=?, Factory_ID=?, PV_Record_ID=? WHERE Data_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataEnergy entity) throws SQLException {
        ps.setLong(1, entity.getMeterId());
        ps.setTimestamp(2, entity.getCollectTime());
        ps.setBigDecimal(3, entity.getValue());
        ps.setString(4, entity.getUnit());
        ps.setString(5, entity.getQuality());
        if (entity.getFactoryId() != null) {
            ps.setLong(6, entity.getFactoryId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        if (entity.getPvRecordId() != null) {
            ps.setLong(7, entity.getPvRecordId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        ps.setLong(8, entity.getDataId());
    }

    public List<DataEnergy> findByMeterId(Long meterId) {
        String sql = "SELECT * FROM Data_Energy WHERE Meter_ID = ? ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, meterId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataEnergy> findByFactoryId(Long factoryId) {
        String sql = "SELECT * FROM Data_Energy WHERE Factory_ID = ? ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
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

    public List<DataEnergy> findByMeterIdAndTimeRange(Long meterId, Timestamp startTime, Timestamp endTime) {
        String sql = "SELECT * FROM Data_Energy WHERE Meter_ID = ? AND Collect_Time BETWEEN ? AND ? ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, meterId);
            ps.setTimestamp(2, startTime);
            ps.setTimestamp(3, endTime);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataEnergy> findByFactoryIdAndTimeRange(Long factoryId, Timestamp startTime, Timestamp endTime) {
        String sql = "SELECT * FROM Data_Energy WHERE Factory_ID = ? AND Collect_Time BETWEEN ? AND ? ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, factoryId);
            ps.setTimestamp(2, startTime);
            ps.setTimestamp(3, endTime);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public BigDecimal getLatestValueByMeterId(Long meterId) {
        String sql = "SELECT TOP 1 Value FROM Data_Energy WHERE Meter_ID = ? ORDER BY Collect_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, meterId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("Value");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal getSumValueByMeterIdAndTimeRange(Long meterId, Timestamp startTime, Timestamp endTime) {
        String sql = "SELECT SUM(Value) as total FROM Data_Energy WHERE Meter_ID = ? AND Collect_Time BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, meterId);
            ps.setTimestamp(2, startTime);
            ps.setTimestamp(3, endTime);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public List<DataEnergy> findByQuality(String quality) {
        String sql = "SELECT * FROM Data_Energy WHERE Quality = ? ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, quality);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<DataEnergy> findRecent(int limit) {
        String sql = "SELECT TOP " + limit + " * FROM Data_Energy ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
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

    public List<DataEnergy> findAll() {
        String sql = "SELECT * FROM Data_Energy ORDER BY Collect_Time DESC";
        List<DataEnergy> list = new ArrayList<>();
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
