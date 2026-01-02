package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.WorkOrder;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class WorkOrderDAO extends BaseDAO<WorkOrder, Long> {

    @Override
    protected String getTableName() {
        return "Work_Order";
    }

    @Override
    protected String getIdColumnName() {
        return "Order_ID";
    }

    @Override
    protected WorkOrder mapRow(ResultSet rs) throws SQLException {
        WorkOrder order = new WorkOrder();
        order.setOrderId(rs.getLong("Order_ID"));
        order.setAlarmId(rs.getLong("Alarm_ID"));
        order.setOandMId(rs.getLong("OandM_ID"));
        order.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        Timestamp dispatchTime = rs.getTimestamp("Dispatch_Time");
        if (dispatchTime != null) {
            order.setDispatchTime(dispatchTime.toLocalDateTime());
        }
        Timestamp responseTime = rs.getTimestamp("Response_Time");
        if (responseTime != null) {
            order.setResponseTime(responseTime.toLocalDateTime());
        }
        Timestamp finishTime = rs.getTimestamp("Finish_Time");
        if (finishTime != null) {
            order.setFinishTime(finishTime.toLocalDateTime());
        }
        order.setResultDesc(rs.getString("Result_Desc"));
        order.setReviewStatus(rs.getString("Review_Status"));
        return order;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Work_Order (Alarm_ID, OandM_ID, Ledger_ID, Dispatch_Time, Response_Time, Finish_Time, Result_Desc, Review_Status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, WorkOrder entity) throws SQLException {
        ps.setLong(1, entity.getAlarmId());
        ps.setLong(2, entity.getOandMId());
        if (entity.getLedgerId() != null) {
            ps.setLong(3, entity.getLedgerId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
        if (entity.getDispatchTime() != null) {
            ps.setTimestamp(4, Timestamp.valueOf(entity.getDispatchTime()));
        } else {
            ps.setNull(4, java.sql.Types.TIMESTAMP);
        }
        if (entity.getResponseTime() != null) {
            ps.setTimestamp(5, Timestamp.valueOf(entity.getResponseTime()));
        } else {
            ps.setNull(5, java.sql.Types.TIMESTAMP);
        }
        if (entity.getFinishTime() != null) {
            ps.setTimestamp(6, Timestamp.valueOf(entity.getFinishTime()));
        } else {
            ps.setNull(6, java.sql.Types.TIMESTAMP);
        }
        ps.setString(7, entity.getResultDesc());
        ps.setString(8, entity.getReviewStatus());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Work_Order SET Alarm_ID=?, OandM_ID=?, Ledger_ID=?, Dispatch_Time=?, Response_Time=?, Finish_Time=?, Result_Desc=?, Review_Status=? WHERE Order_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, WorkOrder entity) throws SQLException {
        ps.setLong(1, entity.getAlarmId());
        ps.setLong(2, entity.getOandMId());
        if (entity.getLedgerId() != null) {
            ps.setLong(3, entity.getLedgerId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
        if (entity.getDispatchTime() != null) {
            ps.setTimestamp(4, Timestamp.valueOf(entity.getDispatchTime()));
        } else {
            ps.setNull(4, java.sql.Types.TIMESTAMP);
        }
        if (entity.getResponseTime() != null) {
            ps.setTimestamp(5, Timestamp.valueOf(entity.getResponseTime()));
        } else {
            ps.setNull(5, java.sql.Types.TIMESTAMP);
        }
        if (entity.getFinishTime() != null) {
            ps.setTimestamp(6, Timestamp.valueOf(entity.getFinishTime()));
        } else {
            ps.setNull(6, java.sql.Types.TIMESTAMP);
        }
        ps.setString(7, entity.getResultDesc());
        ps.setString(8, entity.getReviewStatus());
        ps.setLong(9, entity.getOrderId());
    }

    public WorkOrder findByAlarmId(Long alarmId) {
        String sql = "SELECT * FROM Work_Order WHERE Alarm_ID = ?";
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

    public List<WorkOrder> findByOandMId(Long oandMId) {
        String sql = "SELECT * FROM Work_Order WHERE OandM_ID = ? ORDER BY Dispatch_Time DESC";
        List<WorkOrder> list = new ArrayList<>();
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

    public List<WorkOrder> findByReviewStatus(String reviewStatus) {
        String sql = "SELECT * FROM Work_Order WHERE Review_Status = ? ORDER BY Dispatch_Time DESC";
        List<WorkOrder> list = new ArrayList<>();
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

    public List<WorkOrder> findUnfinishedOrders() {
        String sql = "SELECT * FROM Work_Order WHERE Finish_Time IS NULL ORDER BY Dispatch_Time DESC";
        List<WorkOrder> list = new ArrayList<>();
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

    public List<WorkOrder> findByDateRange(java.time.LocalDateTime startTime, java.time.LocalDateTime endTime) {
        String sql = "SELECT * FROM Work_Order WHERE Dispatch_Time BETWEEN ? AND ? ORDER BY Dispatch_Time DESC";
        List<WorkOrder> list = new ArrayList<>();
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
}
