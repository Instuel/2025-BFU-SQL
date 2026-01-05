package com.bjfu.energy.service;

import com.bjfu.energy.dao.DispatcherDao;
import com.bjfu.energy.dao.DispatcherDaoImpl;
import com.bjfu.energy.dao.WorkOrderDao;
import com.bjfu.energy.dao.WorkOrderDaoImpl;
import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.WorkOrder;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class DispatcherService {

    private static final long RESPONSE_LIMIT_MINUTES = 30;

    private final DispatcherDao dispatcherDao = new DispatcherDaoImpl();
    private final WorkOrderDao workOrderDao = new WorkOrderDaoImpl();

    public List<AlarmInfo> findPendingVerificationAlarms() throws Exception {
        List<AlarmInfo> alarms = dispatcherDao.findPendingVerificationAlarms();
        LocalDateTime now = LocalDateTime.now();
        for (AlarmInfo alarm : alarms) {
            applyDispatchOverdue(alarm, now);
        }
        return alarms;
    }

    public AlarmInfo findAlarmById(Long alarmId) throws Exception {
        AlarmInfo alarm = dispatcherDao.findAlarmById(alarmId);
        if (alarm != null) {
            applyDispatchOverdue(alarm, LocalDateTime.now());
        }
        return alarm;
    }

    public List<SysUser> findOandMUsers() throws Exception {
        return dispatcherDao.findOandMUsers();
    }

    public void updateAlarmVerification(Long alarmId, String verifyStatus, String verifyRemark) throws Exception {
        if (alarmId == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        if (verifyStatus == null || verifyStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("真实性审核状态不能为空");
        }
        dispatcherDao.updateAlarmVerification(alarmId, verifyStatus.trim(), verifyRemark);
    }

    public void updateAlarmProcessStatus(Long alarmId, String processStatus) throws Exception {
        if (alarmId == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        if (processStatus == null || processStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("处理状态不能为空");
        }
        dispatcherDao.updateAlarmProcessStatus(alarmId, processStatus.trim());
    }

    public WorkOrder getWorkOrder(Long orderId) throws Exception {
        WorkOrder order = workOrderDao.findById(orderId);
        if (order != null) {
            applyResponseOverdue(order, LocalDateTime.now());
        }
        return order;
    }

    public WorkOrder getWorkOrderByAlarm(Long alarmId) throws Exception {
        return workOrderDao.findByAlarmId(alarmId);
    }

    public Long createWorkOrder(WorkOrder order) throws Exception {
        if (order == null || order.getAlarmId() == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        
        // 检查是否已存在工单
        WorkOrder existingOrder = workOrderDao.findByAlarmId(order.getAlarmId());
        if (existingOrder != null) {
            // 如果已存在工单，更新现有工单而不是创建新工单
            existingOrder.setOandmId(order.getOandmId());
            existingOrder.setDispatcherId(order.getDispatcherId());
            existingOrder.setLedgerId(order.getLedgerId());
            existingOrder.setDispatchTime(order.getDispatchTime() != null ? order.getDispatchTime() : LocalDateTime.now());
            existingOrder.setResultDesc(order.getResultDesc());
            existingOrder.setAttachmentPath(order.getAttachmentPath());
            // 重置工单状态，重新开始流程
            existingOrder.setResponseTime(null);
            existingOrder.setFinishTime(null);
            existingOrder.setReviewStatus(null);
            
            workOrderDao.update(existingOrder);
            return existingOrder.getOrderId();
        }
        
        AlarmInfo alarm = dispatcherDao.findAlarmById(order.getAlarmId());
        if (alarm == null) {
            throw new IllegalArgumentException("告警不存在");
        }
        if (!"有效".equals(alarm.getVerifyStatus())) {
            throw new IllegalStateException("告警尚未通过真实性审核");
        }
        if (order.getLedgerId() == null && alarm.getLedgerId() != null) {
            order.setLedgerId(alarm.getLedgerId());
        }
        if (order.getDispatchTime() == null) {
            order.setDispatchTime(LocalDateTime.now());
        }
        if (order.getReviewStatus() == null || order.getReviewStatus().trim().isEmpty()) {
            order.setReviewStatus(null);
        }
        return dispatcherDao.createWorkOrder(order);
    }

    public List<WorkOrder> findAllWorkOrders() throws Exception {
        List<WorkOrder> orders = dispatcherDao.findAllWorkOrders();
        LocalDateTime now = LocalDateTime.now();
        for (WorkOrder order : orders) {
            applyResponseOverdue(order, now);
        }
        return orders;
    }

    public WorkOrder findWorkOrderById(Long orderId) throws Exception {
        WorkOrder order = dispatcherDao.findWorkOrderById(orderId);
        if (order != null) {
            applyResponseOverdue(order, LocalDateTime.now());
        }
        return order;
    }

    public void reviewWorkOrder(Long orderId, String reviewStatus, String reviewFeedback, Long dispatcherId) throws Exception {
        if (orderId == null) {
            throw new IllegalArgumentException("工单编号不能为空");
        }
        if (reviewStatus == null || reviewStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("审核状态不能为空");
        }
        if (!"通过".equals(reviewStatus) && !"未通过".equals(reviewStatus)) {
            throw new IllegalArgumentException("审核状态必须为'通过'或'未通过'");
        }
        if ("未通过".equals(reviewStatus) && (reviewFeedback == null || reviewFeedback.trim().isEmpty())) {
            throw new IllegalArgumentException("未通过时必须填写审核反馈");
        }
        
        WorkOrder order = dispatcherDao.findWorkOrderById(orderId);
        if (order == null) {
            throw new IllegalArgumentException("工单不存在");
        }

        // 只有运维完成并提交（完成时间不为空）的工单才能审核
        if (order.getFinishTime() == null) {
            throw new IllegalStateException("工单尚未提交，不能审核");
        }
        
        dispatcherDao.updateWorkOrderReview(orderId, reviewStatus.trim(), reviewFeedback);
        
        String handlingDesc = "工单审核结果：" + reviewStatus;
        if (reviewFeedback != null && !reviewFeedback.trim().isEmpty()) {
            handlingDesc += "，反馈：" + reviewFeedback.trim();
        }
        
        dispatcherDao.addAlarmHandlingLog(order.getAlarmId(), orderId, "工单审核", handlingDesc, dispatcherId);
        
        if ("通过".equals(reviewStatus)) {
            dispatcherDao.updateAlarmProcessStatus(order.getAlarmId(), "已结案");
        }
    }

    private void applyDispatchOverdue(AlarmInfo alarm, LocalDateTime now) {
        if (alarm.getOccurTime() == null) {
            return;
        }
        if (!"高".equals(alarm.getAlarmLevel())) {
            alarm.setDispatchOverdue(false);
            return;
        }
        LocalDateTime base = alarm.getDispatchTime();
        long minutes;
        if (base == null) {
            minutes = ChronoUnit.MINUTES.between(alarm.getOccurTime(), now);
        } else {
            minutes = ChronoUnit.MINUTES.between(alarm.getOccurTime(), base);
        }
        alarm.setDispatchOverdue(minutes > 15);
    }

    private void applyResponseOverdue(WorkOrder order, LocalDateTime now) {
        if (order.getDispatchTime() == null || order.getResponseTime() != null) {
            order.setResponseOverdue(false);
            return;
        }
        long minutes = ChronoUnit.MINUTES.between(order.getDispatchTime(), now);
        order.setResponseOverdue(minutes > RESPONSE_LIMIT_MINUTES);
    }
}
