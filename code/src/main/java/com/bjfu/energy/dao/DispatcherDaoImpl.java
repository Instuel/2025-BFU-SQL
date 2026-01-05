package com.bjfu.energy.dao;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.WorkOrder;
import com.bjfu.energy.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class DispatcherDaoImpl implements DispatcherDao {

    @Override
    public List<AlarmInfo> findPendingVerificationAlarms() throws Exception {
        String sql = "SELECT a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, " +
                     "a.Process_Status, a.Verify_Status, a.Verify_Remark, a.Ledger_ID, a.Factory_ID, a.Trigger_Threshold, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID " +
                     "WHERE (a.Verify_Status = '待审核' OR a.Verify_Status IS NULL) " +
                     "ORDER BY a.Occur_Time DESC, a.Alarm_ID DESC";
        
        List<AlarmInfo> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapAlarmRow(rs));
            }
        }
        return list;
    }

    @Override
    public AlarmInfo findAlarmById(Long alarmId) throws Exception {
        String sql = "SELECT TOP 1 a.Alarm_ID, a.Alarm_Type, a.Alarm_Level, a.Content, a.Occur_Time, " +
                     "a.Process_Status, a.Verify_Status, a.Verify_Remark, a.Ledger_ID, a.Factory_ID, a.Trigger_Threshold, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Alarm_Info a " +
                     "LEFT JOIN Device_Ledger l ON a.Ledger_ID = l.Ledger_ID " +
                     "WHERE a.Alarm_ID = ?";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, alarmId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapAlarmRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public List<SysUser> findOandMUsers() throws Exception {
        String sql = "SELECT u.User_ID, u.Login_Account, u.Real_Name, u.Department, u.Contact_Phone " +
                     "FROM Sys_User u " +
                     "INNER JOIN Role_OandM r ON u.User_ID = r.User_ID " +
                     "WHERE u.Account_Status = 1 " +
                     "ORDER BY u.Real_Name";
        
        List<SysUser> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                SysUser user = new SysUser();
                user.setUserId(rs.getLong("User_ID"));
                user.setLoginAccount(rs.getString("Login_Account"));
                user.setRealName(rs.getString("Real_Name"));
                user.setDepartment(rs.getString("Department"));
                user.setContactPhone(rs.getString("Contact_Phone"));
                list.add(user);
            }
        }
        return list;
    }

    @Override
    public Long createWorkOrder(WorkOrder order) throws Exception {
        String sql = "INSERT INTO Work_Order (Alarm_ID, OandM_ID, Dispatcher_ID, Ledger_ID, Dispatch_Time, " +
                     "Response_Time, Finish_Time, Result_Desc, Review_Status) VALUES (?,?,?,?,?,?,?,?,?)";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, order.getAlarmId());
            
            if (order.getOandmId() == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, order.getOandmId());
            }
            
            if (order.getDispatcherId() == null) {
                ps.setNull(3, Types.BIGINT);
            } else {
                ps.setLong(3, order.getDispatcherId());
            }
            
            if (order.getLedgerId() == null) {
                ps.setNull(4, Types.BIGINT);
            } else {
                ps.setLong(4, order.getLedgerId());
            }
            
            if (order.getDispatchTime() == null) {
                ps.setNull(5, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, Timestamp.valueOf(order.getDispatchTime()));
            }
            
            if (order.getResponseTime() == null) {
                ps.setNull(6, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(6, Timestamp.valueOf(order.getResponseTime()));
            }
            
            if (order.getFinishTime() == null) {
                ps.setNull(7, Types.TIMESTAMP);
            } else {
                ps.setTimestamp(7, Timestamp.valueOf(order.getFinishTime()));
            }
            
            ps.setString(8, order.getResultDesc());
            ps.setString(9, order.getReviewStatus());
            
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
    public void updateAlarmVerification(Long alarmId, String verifyStatus, String verifyRemark) throws Exception {
        String sql = "UPDATE Alarm_Info SET Verify_Status = ?, Verify_Remark = ? WHERE Alarm_ID = ?";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, verifyStatus);
            ps.setString(2, verifyRemark);
            ps.setLong(3, alarmId);
            ps.executeUpdate();
        }
    }

    @Override
    public void updateAlarmProcessStatus(Long alarmId, String processStatus) throws Exception {
        String sql = "UPDATE Alarm_Info SET Process_Status = ? WHERE Alarm_ID = ?";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, processStatus);
            ps.setLong(2, alarmId);
            ps.executeUpdate();
        }
    }

    @Override
    public List<WorkOrder> findAllWorkOrders() throws Exception {
        String sql = "SELECT o.Order_ID, o.Alarm_ID, o.OandM_ID, o.Dispatcher_ID, o.Ledger_ID, " +
                     "o.Dispatch_Time, o.Response_Time, o.Finish_Time, o.Result_Desc, o.Review_Status, o.Review_Feedback, " +
                     "a.Alarm_Type, a.Alarm_Level, a.Content, a.Process_Status, a.Verify_Status, " +
                     "l.Device_Name, l.Device_Type, " +
                     "u.Real_Name as OandM_Name " +
                     "FROM Work_Order o " +
                     "LEFT JOIN Alarm_Info a ON o.Alarm_ID = a.Alarm_ID " +
                     "LEFT JOIN Device_Ledger l ON o.Ledger_ID = l.Ledger_ID " +
                     "LEFT JOIN Role_OandM r ON o.OandM_ID = r.OandM_ID " +
                     "LEFT JOIN Sys_User u ON r.User_ID = u.User_ID " +
                     "ORDER BY o.Dispatch_Time DESC, o.Order_ID DESC";
        
        List<WorkOrder> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapWorkOrderRow(rs));
            }
        }
        return list;
    }

    @Override
    public WorkOrder findWorkOrderById(Long orderId) throws Exception {
        String sql = "SELECT TOP 1 o.Order_ID, o.Alarm_ID, o.OandM_ID, o.Dispatcher_ID, o.Ledger_ID, " +
                     "o.Dispatch_Time, o.Response_Time, o.Finish_Time, o.Result_Desc, o.Review_Status, o.Review_Feedback, " +
                     "a.Alarm_Type, a.Alarm_Level, a.Content, a.Process_Status, a.Verify_Status, " +
                     "l.Device_Name, l.Device_Type, " +
                     "u.Real_Name as OandM_Name " +
                     "FROM Work_Order o " +
                     "LEFT JOIN Alarm_Info a ON o.Alarm_ID = a.Alarm_ID " +
                     "LEFT JOIN Device_Ledger l ON o.Ledger_ID = l.Ledger_ID " +
                     "LEFT JOIN Role_OandM r ON o.OandM_ID = r.OandM_ID " +
                     "LEFT JOIN Sys_User u ON r.User_ID = u.User_ID " +
                     "WHERE o.Order_ID = ?";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapWorkOrderRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public void updateWorkOrderReview(Long orderId, String reviewStatus, String reviewFeedback) throws Exception {
        String sql = "UPDATE Work_Order SET Review_Status = ?, Review_Feedback = ? WHERE Order_ID = ?";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, reviewStatus);
            ps.setString(2, reviewFeedback);
            ps.setLong(3, orderId);
            ps.executeUpdate();
        }
    }

    @Override
    public void addAlarmHandlingLog(Long alarmId, Long orderId, String handlingType, String handlingDesc, Long handlerId) throws Exception {
        // Map the parameters to the actual database schema
        // Use handlingDesc directly if it's meaningful, otherwise use handlingType
        String statusAfter;
        if (handlingDesc != null && !handlingDesc.trim().isEmpty()) {
            // Use the detailed description directly, avoid redundant concatenation
            statusAfter = handlingDesc.trim();
        } else {
            statusAfter = handlingType;
        }
        
        // Truncate if still too long (safety measure)
        if (statusAfter.length() > 200) {
            statusAfter = statusAfter.substring(0, 197) + "...";
        }
        
        String sql = "INSERT INTO Alarm_Handling_Log (Alarm_ID, Handle_Time, Status_After, OandM_ID, Dispatcher_ID) " +
                     "VALUES (?,GETDATE(),?,?,?)";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, alarmId);
            ps.setString(2, statusAfter);
            
            // For now, assume handlerId is a dispatcher ID since this is called from DispatcherService
            // In a more sophisticated system, we'd need to determine the role type
            ps.setNull(3, Types.BIGINT); // OandM_ID
            
            if (handlerId == null) {
                ps.setNull(4, Types.BIGINT); // Dispatcher_ID
            } else {
                ps.setLong(4, handlerId); // Dispatcher_ID
            }
            
            ps.executeUpdate();
        }
    }

    private AlarmInfo mapAlarmRow(ResultSet rs) throws Exception {
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
        alarm.setVerifyStatus(rs.getString("Verify_Status"));
        alarm.setVerifyRemark(rs.getString("Verify_Remark"));
        
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
        
        return alarm;
    }

    private WorkOrder mapWorkOrderRow(ResultSet rs) throws Exception {
        WorkOrder order = new WorkOrder();
        order.setOrderId(rs.getLong("Order_ID"));
        
        long alarmId = rs.getLong("Alarm_ID");
        if (rs.wasNull()) {
            order.setAlarmId(null);
        } else {
            order.setAlarmId(alarmId);
        }
        
        long oandmId = rs.getLong("OandM_ID");
        if (rs.wasNull()) {
            order.setOandmId(null);
        } else {
            order.setOandmId(oandmId);
        }
        
        long dispatcherId = rs.getLong("Dispatcher_ID");
        if (rs.wasNull()) {
            order.setDispatcherId(null);
        } else {
            order.setDispatcherId(dispatcherId);
        }
        
        long ledgerId = rs.getLong("Ledger_ID");
        if (rs.wasNull()) {
            order.setLedgerId(null);
        } else {
            order.setLedgerId(ledgerId);
        }
        
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
        order.setReviewFeedback(rs.getString("Review_Feedback"));
        
        order.setAlarmType(rs.getString("Alarm_Type"));
        order.setAlarmLevel(rs.getString("Alarm_Level"));
        order.setAlarmContent(rs.getString("Content"));
        order.setAlarmStatus(rs.getString("Process_Status"));
        order.setDeviceName(rs.getString("Device_Name"));
        order.setDeviceType(rs.getString("Device_Type"));
        order.setOandmName(rs.getString("OandM_Name"));
        
        return order;
    }
}
