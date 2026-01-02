package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.AlarmHandlingLog;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class AlarmHandlingLogDAO extends BaseDAO<AlarmHandlingLog, Long> {

    @Override
    protected String getTableName() {
        return "Alarm_Handling_Log";
    }

    @Override
    protected String getIdColumnName() {
        return "Log_ID";
    }

    @Override
    protected AlarmHandlingLog mapRow(ResultSet rs) throws SQLException {
        AlarmHandlingLog log = new AlarmHandlingLog();
        log.setLogId(rs.getLong("Log_ID"));
        log.setAlarmId(rs.getLong("Alarm_ID"));
        Timestamp handleTime = rs.getTimestamp("Handle_Time");
        if (handleTime != null) {
            log.setHandleTime(handleTime.toLocalDateTime());
        }
        log.setStatusAfter(rs.getString("Status_After"));
        log.setOandMId(rs.getObject("OandM_ID", Long.class));
        log.setDispatcherId(rs.getObject("Dispatcher_ID", Long.class));
        return log;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Alarm_Handling_Log (Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID) VALUES (?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, AlarmHandlingLog entity) throws SQLException {
        ps.setLong(1, entity.getAlarmId());
        if (entity.getHandleTime() != null) {
            ps.setTimestamp(2, Timestamp.valueOf(entity.getHandleTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getStatusAfter());
        if (entity.getOandMId() != null) {
            ps.setLong(4, entity.getOandMId());
        } else {
            ps.setNull(4, java.sql.Types.BIGINT);
        }
        if (entity.getDispatcherId() != null) {
            ps.setLong(5, entity.getDispatcherId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Alarm_Handling_Log SET Alarm_ID=?, Handle_Time=?, Status_After=?, OandM_ID=?, Dispatcher_ID=? WHERE Log_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, AlarmHandlingLog entity) throws SQLException {
        ps.setLong(1, entity.getAlarmId());
        if (entity.getHandleTime() != null) {
            ps.setTimestamp(2, Timestamp.valueOf(entity.getHandleTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getStatusAfter());
        if (entity.getOandMId() != null) {
            ps.setLong(4, entity.getOandMId());
        } else {
            ps.setNull(4, java.sql.Types.BIGINT);
        }
        if (entity.getDispatcherId() != null) {
            ps.setLong(5, entity.getDispatcherId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
        ps.setLong(6, entity.getLogId());
    }

    public List<AlarmHandlingLog> findByAlarmId(Long alarmId) {
        String sql = "SELECT * FROM Alarm_Handling_Log WHERE Alarm_ID = ? ORDER BY Handle_Time DESC";
        List<AlarmHandlingLog> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, alarmId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmHandlingLog> findByOandMId(Long oandMId) {
        String sql = "SELECT * FROM Alarm_Handling_Log WHERE OandM_ID = ? ORDER BY Handle_Time DESC";
        List<AlarmHandlingLog> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, oandMId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmHandlingLog> findByDispatcherId(Long dispatcherId) {
        String sql = "SELECT * FROM Alarm_Handling_Log WHERE Dispatcher_ID = ? ORDER BY Handle_Time DESC";
        List<AlarmHandlingLog> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, dispatcherId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmHandlingLog> findByStatusAfter(String statusAfter) {
        String sql = "SELECT * FROM Alarm_Handling_Log WHERE Status_After = ? ORDER BY Handle_Time DESC";
        List<AlarmHandlingLog> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, statusAfter);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmHandlingLog> findByDateRange(java.time.LocalDateTime startTime, java.time.LocalDateTime endTime) {
        String sql = "SELECT * FROM Alarm_Handling_Log WHERE Handle_Time BETWEEN ? AND ? ORDER BY Handle_Time DESC";
        List<AlarmHandlingLog> list = new ArrayList<>();
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

    public AlarmHandlingLog findLatestByAlarmId(Long alarmId) {
        String sql = "SELECT TOP 1 * FROM Alarm_Handling_Log WHERE Alarm_ID = ? ORDER BY Handle_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, alarmId);
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
