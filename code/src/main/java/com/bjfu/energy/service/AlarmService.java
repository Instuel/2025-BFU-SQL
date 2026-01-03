package com.bjfu.energy.service;

import com.bjfu.energy.dao.AlarmInfoDao;
import com.bjfu.energy.dao.AlarmInfoDaoImpl;
import com.bjfu.energy.dao.DeviceLedgerDao;
import com.bjfu.energy.dao.DeviceLedgerDaoImpl;
import com.bjfu.energy.dao.MaintenancePlanDao;
import com.bjfu.energy.dao.MaintenancePlanDaoImpl;
import com.bjfu.energy.dao.WorkOrderDao;
import com.bjfu.energy.dao.WorkOrderDaoImpl;
import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.DeviceLedger;
import com.bjfu.energy.entity.MaintenancePlan;
import com.bjfu.energy.entity.WorkOrder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class AlarmService {

    private static final long DISPATCH_LIMIT_MINUTES = 15;
    private static final long RESPONSE_LIMIT_MINUTES = 30;

    private final AlarmInfoDao alarmInfoDao = new AlarmInfoDaoImpl();
    private final WorkOrderDao workOrderDao = new WorkOrderDaoImpl();
    private final DeviceLedgerDao deviceLedgerDao = new DeviceLedgerDaoImpl();
    private final MaintenancePlanDao maintenancePlanDao = new MaintenancePlanDaoImpl();

    public List<AlarmInfo> listAlarms(String alarmType, String alarmLevel, String processStatus, String verifyStatus) throws Exception {
        List<AlarmInfo> alarms = alarmInfoDao.findAll(alarmType, alarmLevel, processStatus, verifyStatus);
        LocalDateTime now = LocalDateTime.now();
        for (AlarmInfo alarm : alarms) {
            applyDispatchOverdue(alarm, now);
        }
        return alarms;
    }

    public AlarmInfo getAlarm(Long alarmId) throws Exception {
        AlarmInfo alarm = alarmInfoDao.findById(alarmId);
        if (alarm != null) {
            applyDispatchOverdue(alarm, LocalDateTime.now());
        }
        return alarm;
    }

    public void updateAlarmStatus(Long alarmId, String processStatus) throws Exception {
        if (alarmId == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        if (processStatus == null || processStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("处理状态不能为空");
        }
        alarmInfoDao.updateStatus(alarmId, processStatus.trim());
    }

    public void updateAlarmVerification(Long alarmId, String verifyStatus, String verifyRemark) throws Exception {
        if (alarmId == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        if (verifyStatus == null || verifyStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("真实性审核状态不能为空");
        }
        alarmInfoDao.updateVerification(alarmId, verifyStatus.trim(), verifyRemark);
        if ("误报".equals(verifyStatus.trim())) {
            alarmInfoDao.updateStatus(alarmId, "已结案");
        }
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

    public List<WorkOrder> listWorkOrders(String reviewStatus) throws Exception {
        List<WorkOrder> orders = workOrderDao.findAll(reviewStatus);
        LocalDateTime now = LocalDateTime.now();
        for (WorkOrder order : orders) {
            applyResponseOverdue(order, now);
        }
        return orders;
    }

    public List<WorkOrder> listWorkOrdersForLedger(Long ledgerId) throws Exception {
        List<WorkOrder> orders = workOrderDao.findByLedgerId(ledgerId);
        LocalDateTime now = LocalDateTime.now();
        for (WorkOrder order : orders) {
            applyResponseOverdue(order, now);
        }
        return orders;
    }

    public Long createWorkOrder(WorkOrder order) throws Exception {
        if (order == null || order.getAlarmId() == null) {
            throw new IllegalArgumentException("告警编号不能为空");
        }
        if (workOrderDao.findByAlarmId(order.getAlarmId()) != null) {
            throw new IllegalStateException("该告警已存在运维工单");
        }
        AlarmInfo alarm = alarmInfoDao.findById(order.getAlarmId());
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
        Long id = workOrderDao.insert(order);
        alarmInfoDao.updateStatus(order.getAlarmId(), "处理中");
        return id;
    }

    public void updateWorkOrder(WorkOrder order) throws Exception {
        if (order == null || order.getOrderId() == null) {
            throw new IllegalArgumentException("工单编号不能为空");
        }
        workOrderDao.update(order);
        if (order.getAlarmId() == null) {
            WorkOrder updated = workOrderDao.findById(order.getOrderId());
            if (updated != null) {
                order.setAlarmId(updated.getAlarmId());
            }
        }
        if (order.getAlarmId() != null) {
            if (order.getFinishTime() != null && "通过".equals(order.getReviewStatus())) {
                alarmInfoDao.updateStatus(order.getAlarmId(), "已结案");
            } else if (order.getFinishTime() != null && "未通过".equals(order.getReviewStatus())) {
                alarmInfoDao.updateStatus(order.getAlarmId(), "处理中");
            } else if (order.getResponseTime() != null) {
                alarmInfoDao.updateStatus(order.getAlarmId(), "处理中");
            }
        }
    }

    public void redispatchWorkOrder(Long orderId, Long oandmId, LocalDateTime dispatchTime, String reason) throws Exception {
        if (orderId == null) {
            throw new IllegalArgumentException("工单编号不能为空");
        }
        WorkOrder existing = workOrderDao.findById(orderId);
        if (existing == null) {
            throw new IllegalArgumentException("工单不存在");
        }
        if (!"未通过".equals(existing.getReviewStatus())) {
            throw new IllegalStateException("仅未通过复查的工单可重新派单");
        }
        existing.setOandmId(oandmId != null ? oandmId : existing.getOandmId());
        existing.setDispatchTime(dispatchTime == null ? LocalDateTime.now() : dispatchTime);
        existing.setResponseTime(null);
        existing.setFinishTime(null);
        existing.setReviewStatus(null);
        if (reason != null && !reason.trim().isEmpty()) {
            String prefix = "[重新派单] ";
            String current = existing.getResultDesc();
            String merged = (current == null || current.trim().isEmpty())
                    ? prefix + reason.trim()
                    : current.trim() + "\n" + prefix + reason.trim();
            existing.setResultDesc(merged);
        }
        workOrderDao.update(existing);
        if (existing.getAlarmId() != null) {
            alarmInfoDao.updateStatus(existing.getAlarmId(), "处理中");
        }
    }

    public List<DeviceLedger> listLedgers(String deviceType, String scrapStatus) throws Exception {
        List<DeviceLedger> ledgers = deviceLedgerDao.findAll(deviceType, scrapStatus);
        LocalDate today = LocalDate.now();
        for (DeviceLedger ledger : ledgers) {
            applyWarrantyStatus(ledger, today);
        }
        return ledgers;
    }

    public DeviceLedger getLedger(Long ledgerId) throws Exception {
        DeviceLedger ledger = deviceLedgerDao.findById(ledgerId);
        if (ledger != null) {
            applyWarrantyStatus(ledger, LocalDate.now());
        }
        return ledger;
    }

    public List<MaintenancePlan> listMaintenancePlans(String deviceType, String status) throws Exception {
        return maintenancePlanDao.findAll(deviceType, status);
    }

    public List<MaintenancePlan> listMaintenancePlansForLedger(Long ledgerId) throws Exception {
        return maintenancePlanDao.findByLedgerId(ledgerId);
    }

    public Long createMaintenancePlan(MaintenancePlan plan) throws Exception {
        if (plan == null || plan.getLedgerId() == null) {
            throw new IllegalArgumentException("设备台账编号不能为空");
        }
        if (plan.getPlanDate() == null) {
            throw new IllegalArgumentException("计划日期不能为空");
        }
        if (plan.getStatus() == null || plan.getStatus().trim().isEmpty()) {
            plan.setStatus("待执行");
        }
        return maintenancePlanDao.insert(plan);
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
        alarm.setDispatchOverdue(minutes > DISPATCH_LIMIT_MINUTES);
    }

    private void applyResponseOverdue(WorkOrder order, LocalDateTime now) {
        if (order.getDispatchTime() == null || order.getResponseTime() != null) {
            order.setResponseOverdue(false);
            return;
        }
        long minutes = ChronoUnit.MINUTES.between(order.getDispatchTime(), now);
        order.setResponseOverdue(minutes > RESPONSE_LIMIT_MINUTES);
    }

    private void applyWarrantyStatus(DeviceLedger ledger, LocalDate today) {
        if (ledger.getInstallTime() == null || ledger.getWarrantyYears() == null) {
            ledger.setWarrantyStatus("未知");
            ledger.setWarrantyDaysLeft(null);
            ledger.setWarrantyExpireDate(null);
            return;
        }
        LocalDate expire = ledger.getInstallTime().plusYears(ledger.getWarrantyYears());
        long daysLeft = ChronoUnit.DAYS.between(today, expire);
        ledger.setWarrantyExpireDate(expire);
        ledger.setWarrantyDaysLeft((int) daysLeft);
        if (daysLeft < 0) {
            ledger.setWarrantyStatus("已过期");
        } else if (daysLeft <= 30) {
            ledger.setWarrantyStatus("即将到期");
        } else {
            ledger.setWarrantyStatus("正常");
        }
    }
}
