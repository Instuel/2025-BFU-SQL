package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.AlarmInfo;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

public class AlarmInfoDAO extends BaseDAO<AlarmInfo, Long> {

    @Override
    protected String getTableName() {
        return "Alarm_Info";
    }

    @Override
    protected String getIdColumnName() {
        return "Alarm_ID";
    }

    @Override
    protected AlarmInfo mapRow(ResultSet rs) throws SQLException {
        AlarmInfo alarm = new AlarmInfo();
        alarm.setAlarmId(rs.getLong("Alarm_ID"));
        alarm.setAlarmType(rs.getString("Alarm_Type"));
        alarm.setAlarmLevel(rs.getString("Alarm_Level"));
        alarm.setContent(rs.getString("Content"));
        Timestamp occurTime = rs.getTimestamp("Occur_Time");
        if (occurTime != null) {
            alarm.setOccurTime(occurTime.toLocalDateTime());
        }
        alarm.setProcessStatus(rs.getString("Process_Status"));
        alarm.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        alarm.setFactoryId(rs.getObject("Factory_ID", Long.class));
        return alarm;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Alarm_Info (Alarm_Type, Alarm_Level, Content, Occur_Time, Process_Status, Ledger_ID, Factory_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, AlarmInfo entity) throws SQLException {
        ps.setString(1, entity.getAlarmType());
        ps.setString(2, entity.getAlarmLevel());
        ps.setString(3, entity.getContent());
        if (entity.getOccurTime() != null) {
            ps.setTimestamp(4, Timestamp.valueOf(entity.getOccurTime()));
        } else {
            ps.setNull(4, java.sql.Types.TIMESTAMP);
        }
        ps.setString(5, entity.getProcessStatus() != null ? entity.getProcessStatus() : "未处理");
        if (entity.getLedgerId() != null) {
            ps.setLong(6, entity.getLedgerId());
        } else {
            ps.setNull(6, java.sql.Types.BIGINT);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(7, entity.getFactoryId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Alarm_Info SET Alarm_Type=?, Alarm_Level=?, Content=?, Process_Status=? WHERE Alarm_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, AlarmInfo entity) throws SQLException {
        ps.setString(1, entity.getAlarmType());
        ps.setString(2, entity.getAlarmLevel());
        ps.setString(3, entity.getContent());
        ps.setString(4, entity.getProcessStatus());
        ps.setLong(5, entity.getAlarmId());
    }

    public Integer countActiveAlarms() {
        String sql = "SELECT COUNT(*) FROM Alarm_Info WHERE Process_Status = '未处理' OR Process_Status = '处理中'";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public java.util.List<AlarmInfo> findByProcessStatus(String processStatus) {
        String sql = "SELECT * FROM Alarm_Info WHERE Process_Status = ? ORDER BY Occur_Time DESC";
        java.util.List<AlarmInfo> list = new java.util.ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, processStatus);
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
