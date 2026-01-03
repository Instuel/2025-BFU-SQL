package com.bjfu.energy.dao;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class AlarmInfoDaoImpl implements AlarmInfoDao {

    private AlarmInfo mapRow(ResultSet rs) throws Exception {
        AlarmInfo alarm = new AlarmInfo();
        alarm.setAlarmId(rs.getLong("Alarm_ID"));
        alarm.setAlarmType(rs.getString("Alarm_Type"));
        alarm.setAlarmLevel(rs.getString("Alarm_Level"));
        alarm.setContent(rs.getString("Content"));
        Timestamp occur = rs.getTimestamp("Occur_Time");
        if (occur != null) {
            alarm.setOccurTime(occur.toLocalDateTime());
        }
        alarm.setProcessStatus(rs.getString("Process_Status"));
        long ledgerId = rs.getLong("Ledger_ID");
        if (rs.wasNull()) {
            alarm.setLedgerId(null);
        } else {
            alarm.setLedgerId(ledgerId);
        }
        long factoryId = rs.getLong("Factory_ID");
        if (rs.wasNull()) {
            alarm.setFactoryId(null);
        } else {
            alarm.setFactoryId(factoryId);
        }
        BigDecimal threshold = rs.getBigDecimal("Trigger_Threshold");
        alarm.setTriggerThreshold(threshold);
        alarm.setDeviceName(rs.getString("Device_Name"));
        alarm.setDeviceType(rs.getString("Device_Type"));
        long orderId = rs.getLong("Order_ID");
        if (rs.wasNull()) {
            alarm.setWorkOrderId(null);
        } else {
            alarm.setWorkOrderId(orderId);
        }
        Timestamp dispatch = rs.getTimestamp("Dispatch_Time");
        if (dispatch != null) {
            alarm.setDispatchTime(dispatch.toLocalDateTime());
        }
        return alarm;
    }

    @Override
    public List<AlarmInfo> findAll(String alarmType, String alarmLevel, String processStatus) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, ")
           .append("a.Process_Status, a.Ledger_ID, a.Factory_ID, a.Trigger_Threshold, ")
           .append("l.Device_Name, l.Device_Type, w.Order_ID, w.Dispatch_Time ")
           .append("FROM Alarm_Info a ")
           .append("LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID ")
           .append("LEFT JOIN Work_Order w ON a.Alarm_ID = w.Alarm_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (alarmType != null && !alarmType.trim().isEmpty()) {
            sql.append("AND a.Alarm_Type = ? ");
            params.add(alarmType.trim());
        }
        if (alarmLevel != null && !alarmLevel.trim().isEmpty()) {
            sql.append("AND a.Alarm_Level = ? ");
            params.add(alarmLevel.trim());
        }
        if (processStatus != null && !processStatus.trim().isEmpty()) {
            sql.append("AND a.Process_Status = ? ");
            params.add(processStatus.trim());
        }
        sql.append("ORDER BY a.Occur_Time DESC, a.Alarm_ID DESC");

        List<AlarmInfo> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public AlarmInfo findById(Long alarmId) throws Exception {
        String sql = "SELECT TOP 1 a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, " +
                     "a.Process_Status, a.Ledger_ID, a.Factory_ID, a.Trigger_Threshold, " +
                     "l.Device_Name, l.Device_Type, w.Order_ID, w.Dispatch_Time " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID " +
                     "LEFT JOIN Work_Order w ON a.Alarm_ID = w.Alarm_ID " +
                     "WHERE a.Alarm_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, alarmId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public void updateStatus(Long alarmId, String processStatus) throws Exception {
        String sql = "UPDATE Alarm_Info SET Process_Status = ? WHERE Alarm_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, processStatus);
            ps.setLong(2, alarmId);
            ps.executeUpdate();
        }
    }
}
