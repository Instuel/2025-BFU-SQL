package com.bjfu.energy.dao;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.WorkOrder;

import java.util.List;

public interface DispatcherDao {
    List<AlarmInfo> findPendingVerificationAlarms() throws Exception;
    AlarmInfo findAlarmById(Long alarmId) throws Exception;
    List<SysUser> findOandMUsers() throws Exception;
    Long createWorkOrder(WorkOrder order) throws Exception;
    void updateAlarmVerification(Long alarmId, String verifyStatus, String verifyRemark) throws Exception;
    void updateAlarmProcessStatus(Long alarmId, String processStatus) throws Exception;
    List<WorkOrder> findAllWorkOrders() throws Exception;
    WorkOrder findWorkOrderById(Long orderId) throws Exception;
    void updateWorkOrderReview(Long orderId, String reviewStatus, String reviewFeedback) throws Exception;
    void addAlarmHandlingLog(Long alarmId, Long orderId, String handlingType, String handlingDesc, Long handlerId) throws Exception;
}
