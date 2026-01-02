package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.StatRealtime;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class StatRealtimeDAO extends BaseDAO<StatRealtime, String> {

    @Override
    protected String getTableName() {
        return "Stat_Realtime";
    }

    @Override
    protected String getIdColumnName() {
        return "Summary_ID";
    }

    @Override
    protected StatRealtime mapRow(ResultSet rs) throws SQLException {
        StatRealtime stat = new StatRealtime();
        stat.setSummaryId(rs.getString("Summary_ID"));
        Timestamp statTime = rs.getTimestamp("Stat_Time");
        if (statTime != null) {
            stat.setStatTime(statTime.toLocalDateTime());
        }
        stat.setTotalKwh(rs.getBigDecimal("Total_KWH"));
        stat.setTotalAlarm(rs.getInt("Total_Alarm"));
        stat.setPvGenKwh(rs.getBigDecimal("PV_Gen_KWH"));
        stat.setConfigId(rs.getObject("Config_ID", Long.class));
        stat.setManagerId(rs.getObject("Manager_ID", Long.class));
        return stat;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Stat_Realtime (Summary_ID, Stat_Time, Total_KWH, Total_Alarm, PV_Gen_KWH, Config_ID, Manager_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, StatRealtime entity) throws SQLException {
        ps.setString(1, entity.getSummaryId());
        if (entity.getStatTime() != null) {
            ps.setTimestamp(2, Timestamp.valueOf(entity.getStatTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setBigDecimal(3, entity.getTotalKwh());
        ps.setInt(4, entity.getTotalAlarm());
        ps.setBigDecimal(5, entity.getPvGenKwh());
        if (entity.getConfigId() != null) {
            ps.setLong(6, entity.getConfigId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        if (entity.getManagerId() != null) {
            ps.setLong(7, entity.getManagerId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Stat_Realtime SET Stat_Time=?, Total_KWH=?, Total_Alarm=?, PV_Gen_KWH=?, Config_ID=?, Manager_ID=? WHERE Summary_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, StatRealtime entity) throws SQLException {
        if (entity.getStatTime() != null) {
            ps.setTimestamp(1, Timestamp.valueOf(entity.getStatTime()));
        } else {
            ps.setNull(1, java.sql.Types.TIMESTAMP);
        }
        ps.setBigDecimal(2, entity.getTotalKwh());
        ps.setInt(3, entity.getTotalAlarm());
        ps.setBigDecimal(4, entity.getPvGenKwh());
        if (entity.getConfigId() != null) {
            ps.setLong(5, entity.getConfigId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
        if (entity.getManagerId() != null) {
            ps.setLong(6, entity.getManagerId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        ps.setString(7, entity.getSummaryId());
    }

    public StatRealtime findLatest() {
        String sql = "SELECT TOP 1 * FROM Stat_Realtime ORDER BY Stat_Time DESC";
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

    public List<StatRealtime> findByConfigId(Long configId) {
        String sql = "SELECT * FROM Stat_Realtime WHERE Config_ID = ? ORDER BY Stat_Time DESC";
        List<StatRealtime> list = new ArrayList<>();
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

    public List<StatRealtime> findByManagerId(Long managerId) {
        String sql = "SELECT * FROM Stat_Realtime WHERE Manager_ID = ? ORDER BY Stat_Time DESC";
        List<StatRealtime> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, managerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<StatRealtime> findByDateRange(LocalDateTime startTime, LocalDateTime endTime) {
        String sql = "SELECT * FROM Stat_Realtime WHERE Stat_Time BETWEEN ? AND ? ORDER BY Stat_Time DESC";
        List<StatRealtime> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public BigDecimal getTotalKwhByDateRange(LocalDateTime startTime, LocalDateTime endTime) {
        String sql = "SELECT SUM(Total_KWH) as Total FROM Stat_Realtime WHERE Stat_Time BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("Total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public Integer getTotalAlarmByDateRange(LocalDateTime startTime, LocalDateTime endTime) {
        String sql = "SELECT SUM(Total_Alarm) as Total FROM Stat_Realtime WHERE Stat_Time BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("Total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public BigDecimal getPvGenKwhByDateRange(LocalDateTime startTime, LocalDateTime endTime) {
        String sql = "SELECT SUM(PV_Gen_KWH) as Total FROM Stat_Realtime WHERE Stat_Time BETWEEN ? AND ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTimestamp(1, Timestamp.valueOf(startTime));
            ps.setTimestamp(2, Timestamp.valueOf(endTime));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("Total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }

    public StatRealtime findByStatDate(Date statDate) {
        String sql = "SELECT TOP 1 * FROM Stat_Realtime WHERE CAST(Stat_Time AS DATE) = ? ORDER BY Stat_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setDate(1, statDate);
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
