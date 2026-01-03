package com.bjfu.energy.service;

import com.bjfu.energy.dao.AlarmInfoDao;
import com.bjfu.energy.dao.AlarmInfoDaoImpl;
import com.bjfu.energy.dao.DeviceLedgerDao;
import com.bjfu.energy.dao.DeviceLedgerDaoImpl;
import com.bjfu.energy.dao.WorkOrderDao;
import com.bjfu.energy.dao.WorkOrderDaoImpl;
import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.DeviceLedger;
import com.bjfu.energy.entity.WorkOrder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class AlarmService {

    private static final long DISPATCH_LIMIT_MINUTES = 15;

    private final AlarmInfoDao alarmInfoDao = new AlarmInfoDaoImpl();
    private final WorkOrderDao workOrderDao = new WorkOrderDaoImpl();
    private final DeviceLedgerDao deviceLedgerDao = new DeviceLedgerDaoImpl();

    public List<AlarmInfo> listAlarms(String alarmType, String alarmLevel, String processStatus) throws Exception {
        List<AlarmInfo> alarms = alarmInfoDao.findAll(alarmType, alarmLevel, processStatus);
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

    public WorkOrder getWorkOrder(Long orderId) throws Exception {
        return workOrderDao.findById(orderId);
    }

    public WorkOrder getWorkOrderByAlarm(Long alarmId) throws Exception {
        return workOrderDao.findByAlarmId(alarmId);
    }

    public List<WorkOrder> listWorkOrders(String reviewStatus) throws Exception {
        return workOrderDao.findAll(reviewStatus);
    }

    public List<WorkOrder> listWorkOrdersForLedger(Long ledgerId) throws Exception {
        return workOrderDao.findByLedgerId(ledgerId);
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
            } else if (order.getResponseTime() != null) {
                alarmInfoDao.updateStatus(order.getAlarmId(), "处理中");
            }
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
