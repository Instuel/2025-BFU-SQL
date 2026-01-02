package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.AlarmRecord;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class AlarmRecordDAO extends BaseDAO<AlarmRecord, Long> {

    @Override
    protected String getTableName() {
        return "Alarm_Record";
    }

    @Override
    protected String getIdColumnName() {
        return "ID";
    }

    @Override
    protected AlarmRecord mapRow(ResultSet rs) throws SQLException {
        AlarmRecord alarm = new AlarmRecord();
        alarm.setId(rs.getLong("ID"));
        alarm.setAlarmCode(rs.getString("Alarm_Code"));
        Timestamp alarmTime = rs.getTimestamp("Alarm_Time");
        if (alarmTime != null) {
            alarm.setAlarmTime(new Date(alarmTime.getTime()));
        }
        alarm.setAlarmLevel(rs.getString("Alarm_Level"));
        alarm.setAlarmType(rs.getString("Alarm_Type"));
        alarm.setDeviceId(rs.getObject("Device_ID", Long.class));
        alarm.setAlarmContent(rs.getString("Alarm_Content"));
        alarm.setReviewStatus(rs.getString("Review_Status"));
        alarm.setReviewComment(rs.getString("Review_Comment"));
        Timestamp reviewTime = rs.getTimestamp("Review_Time");
        if (reviewTime != null) {
            alarm.setReviewTime(new Date(reviewTime.getTime()));
        }
        alarm.setWorkOrderId(rs.getObject("Work_Order_ID", Long.class));
        return alarm;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Alarm_Record (Alarm_Code, Alarm_Time, Alarm_Level, Alarm_Type, Device_ID, Alarm_Content, Review_Status, Review_Comment, Review_Time, Work_Order_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, AlarmRecord entity) throws SQLException {
        ps.setString(1, entity.getAlarmCode());
        if (entity.getAlarmTime() != null) {
            ps.setTimestamp(2, new Timestamp(entity.getAlarmTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getAlarmLevel());
        ps.setString(4, entity.getAlarmType());
        if (entity.getDeviceId() != null) {
            ps.setLong(5, entity.getDeviceId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
        ps.setString(6, entity.getAlarmContent());
        ps.setString(7, entity.getReviewStatus() != null ? entity.getReviewStatus() : "待审核");
        ps.setString(8, entity.getReviewComment());
        if (entity.getReviewTime() != null) {
            ps.setTimestamp(9, new Timestamp(entity.getReviewTime().getTime()));
        } else {
            ps.setNull(9, java.sql.Types.TIMESTAMP);
        }
        if (entity.getWorkOrderId() != null) {
            ps.setLong(10, entity.getWorkOrderId());
        } else {
            ps.setNull(10, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Alarm_Record SET Alarm_Code=?, Alarm_Time=?, Alarm_Level=?, Alarm_Type=?, Device_ID=?, Alarm_Content=?, Review_Status=?, Review_Comment=?, Review_Time=?, Work_Order_ID=? WHERE ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, AlarmRecord entity) throws SQLException {
        ps.setString(1, entity.getAlarmCode());
        if (entity.getAlarmTime() != null) {
            ps.setTimestamp(2, new Timestamp(entity.getAlarmTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getAlarmLevel());
        ps.setString(4, entity.getAlarmType());
        if (entity.getDeviceId() != null) {
            ps.setLong(5, entity.getDeviceId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
        ps.setString(6, entity.getAlarmContent());
        ps.setString(7, entity.getReviewStatus());
        ps.setString(8, entity.getReviewComment());
        if (entity.getReviewTime() != null) {
            ps.setTimestamp(9, new Timestamp(entity.getReviewTime().getTime()));
        } else {
            ps.setNull(9, java.sql.Types.TIMESTAMP);
        }
        if (entity.getWorkOrderId() != null) {
            ps.setLong(10, entity.getWorkOrderId());
        } else {
            ps.setNull(10, java.sql.Types.BIGINT);
        }
        ps.setLong(11, entity.getId());
    }

    public List<AlarmRecord> findByReviewStatus(String reviewStatus) {
        String sql = "SELECT * FROM Alarm_Record WHERE Review_Status = ? ORDER BY Alarm_Time DESC";
        List<AlarmRecord> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, reviewStatus);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmRecord> findByDeviceId(Long deviceId) {
        String sql = "SELECT * FROM Alarm_Record WHERE Device_ID = ? ORDER BY Alarm_Time DESC";
        List<AlarmRecord> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, deviceId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<AlarmRecord> findByDateRange(java.util.Date startDate, java.util.Date endDate) {
        String sql = "SELECT * FROM Alarm_Record WHERE Alarm_Time BETWEEN ? AND ? ORDER BY Alarm_Time DESC";
        List<AlarmRecord> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setTimestamp(1, new Timestamp(startDate.getTime()));
            ps.setTimestamp(2, new Timestamp(endDate.getTime()));
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
