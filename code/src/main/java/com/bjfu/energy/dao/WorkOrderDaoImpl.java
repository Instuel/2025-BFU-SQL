package com.bjfu.energy.dao;

import com.bjfu.energy.entity.WorkOrder;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class WorkOrderDaoImpl implements WorkOrderDao {

    private WorkOrder mapRow(ResultSet rs) throws Exception {
        WorkOrder order = new WorkOrder();
        order.setOrderId(rs.getLong("Order_ID"));
        order.setAlarmId(rs.getLong("Alarm_ID"));
        long oandmId = rs.getLong("OandM_ID");
        order.setOandmId(rs.wasNull() ? null : oandmId);
        long ledgerId = rs.getLong("Ledger_ID");
        order.setLedgerId(rs.wasNull() ? null : ledgerId);
        Timestamp dispatch = rs.getTimestamp("Dispatch_Time");
        if (dispatch != null) {
            order.setDispatchTime(dispatch.toLocalDateTime());
        }
        Timestamp response = rs.getTimestamp("Response_Time");
        if (response != null) {
            order.setResponseTime(response.toLocalDateTime());
        }
        Timestamp finish = rs.getTimestamp("Finish_Time");
        if (finish != null) {
            order.setFinishTime(finish.toLocalDateTime());
        }
        order.setResultDesc(rs.getString("Result_Desc"));
        order.setReviewStatus(rs.getString("Review_Status"));
        order.setAttachmentPath(rs.getString("Attachment_Path"));

        order.setAlarmLevel(rs.getString("Alarm_Level"));
        order.setAlarmType(rs.getString("Alarm_Type"));
        order.setAlarmContent(rs.getString("Content"));
        order.setAlarmStatus(rs.getString("Process_Status"));
        order.setDeviceName(rs.getString("Device_Name"));
        order.setDeviceType(rs.getString("Device_Type"));
        return order;
    }

    @Override
    public List<WorkOrder> findAll(String reviewStatus) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT w.Order_ID, w.Alarm_ID, w.OandM_ID, w.Ledger_ID, w.Dispatch_Time, w.Response_Time, ")
           .append("w.Finish_Time, w.Result_Desc, w.Review_Status, w.Attachment_Path, ")
           .append("a.Alarm_Level, a.Alarm_Type, a.Content, a.Process_Status, ")
           .append("l.Device_Name, l.Device_Type ")
           .append("FROM Work_Order w ")
           .append("LEFT JOIN Alarm_Info a ON w.Alarm_ID = a.Alarm_ID ")
           .append("LEFT JOIN Device_Ledger l ON w.Ledger_ID = l.Ledger_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (reviewStatus != null && !reviewStatus.trim().isEmpty()) {
            sql.append("AND w.Review_Status = ? ");
            params.add(reviewStatus.trim());
        }
        sql.append("ORDER BY w.Dispatch_Time DESC, w.Order_ID DESC");

        List<WorkOrder> list = new ArrayList<>();
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
    public WorkOrder findById(Long orderId) throws Exception {
        String sql = "SELECT TOP 1 w.Order_ID, w.Alarm_ID, w.OandM_ID, w.Ledger_ID, w.Dispatch_Time, " +
                     "w.Response_Time, w.Finish_Time, w.Result_Desc, w.Review_Status, w.Attachment_Path, " +
                     "a.Alarm_Level, a.Alarm_Type, a.Content, a.Process_Status, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Work_Order w " +
                     "LEFT JOIN Alarm_Info a ON w.Alarm_ID = a.Alarm_ID " +
                     "LEFT JOIN Device_Ledger l ON w.Ledger_ID = l.Ledger_ID " +
                     "WHERE w.Order_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public WorkOrder findByAlarmId(Long alarmId) throws Exception {
        String sql = "SELECT TOP 1 w.Order_ID, w.Alarm_ID, w.OandM_ID, w.Ledger_ID, w.Dispatch_Time, " +
                     "w.Response_Time, w.Finish_Time, w.Result_Desc, w.Review_Status, w.Attachment_Path, " +
                     "a.Alarm_Level, a.Alarm_Type, a.Content, a.Process_Status, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Work_Order w " +
                     "LEFT JOIN Alarm_Info a ON w.Alarm_ID = a.Alarm_ID " +
                     "LEFT JOIN Device_Ledger l ON w.Ledger_ID = l.Ledger_ID " +
                     "WHERE w.Alarm_ID = ?";
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
    public List<WorkOrder> findByLedgerId(Long ledgerId) throws Exception {
        String sql = "SELECT w.Order_ID, w.Alarm_ID, w.OandM_ID, w.Ledger_ID, w.Dispatch_Time, " +
                     "w.Response_Time, w.Finish_Time, w.Result_Desc, w.Review_Status, w.Attachment_Path, " +
                     "a.Alarm_Level, a.Alarm_Type, a.Content, a.Process_Status, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Work_Order w " +
                     "LEFT JOIN Alarm_Info a ON w.Alarm_ID = a.Alarm_ID " +
                     "LEFT JOIN Device_Ledger l ON w.Ledger_ID = l.Ledger_ID " +
                     "WHERE w.Ledger_ID = ? " +
                     "ORDER BY w.Dispatch_Time DESC, w.Order_ID DESC";
        List<WorkOrder> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, ledgerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public Long insert(WorkOrder order) throws Exception {
        String sql = "INSERT INTO Work_Order (Alarm_ID, OandM_ID, Ledger_ID, Dispatch_Time, Response_Time, " +
                     "Finish_Time, Result_Desc, Review_Status, Attachment_Path) VALUES (?,?,?,?,?,?,?,?,?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, order.getAlarmId());
            if (order.getOandmId() == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, order.getOandmId());
            }
            if (order.getLedgerId() == null) {
                ps.setNull(3, Types.BIGINT);
            } else {
                ps.setLong(3, order.getLedgerId());
            }
            if (order.getDispatchTime() == null) {
                ps.setNull(4, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(4, Timestamp.valueOf(order.getDispatchTime()));
            }
            if (order.getResponseTime() == null) {
                ps.setNull(5, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, Timestamp.valueOf(order.getResponseTime()));
            }
            if (order.getFinishTime() == null) {
                ps.setNull(6, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(6, Timestamp.valueOf(order.getFinishTime()));
            }
            ps.setString(7, order.getResultDesc());
            ps.setString(8, order.getReviewStatus());
            ps.setString(9, order.getAttachmentPath());

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long id = rs.getLong(1);
                    order.setOrderId(id);
                    return id;
                }
            }
        }
        return null;
    }

    @Override
    public void update(WorkOrder order) throws Exception {
        String sql = "UPDATE Work_Order SET OandM_ID = ?, Ledger_ID = ?, Dispatch_Time = ?, Response_Time = ?, " +
                     "Finish_Time = ?, Result_Desc = ?, Review_Status = ?, Attachment_Path = ? WHERE Order_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (order.getOandmId() == null) {
                ps.setNull(1, Types.BIGINT);
            } else {
                ps.setLong(1, order.getOandmId());
            }
            if (order.getLedgerId() == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, order.getLedgerId());
            }
            if (order.getDispatchTime() == null) {
                ps.setNull(3, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(3, Timestamp.valueOf(order.getDispatchTime()));
            }
            if (order.getResponseTime() == null) {
                ps.setNull(4, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(4, Timestamp.valueOf(order.getResponseTime()));
            }
            if (order.getFinishTime() == null) {
                ps.setNull(5, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, Timestamp.valueOf(order.getFinishTime()));
            }
            ps.setString(6, order.getResultDesc());
            ps.setString(7, order.getReviewStatus());
            ps.setString(8, order.getAttachmentPath());
            ps.setLong(9, order.getOrderId());
            ps.executeUpdate();
        }
    }
}
