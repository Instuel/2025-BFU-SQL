package com.bjfu.energy.dao;

import com.bjfu.energy.entity.WorkOrder;

import java.util.List;

public interface WorkOrderDao {
    List<WorkOrder> findAll(String reviewStatus) throws Exception;
    WorkOrder findById(Long orderId) throws Exception;
    WorkOrder findByAlarmId(Long alarmId) throws Exception;
    List<WorkOrder> findByLedgerId(Long ledgerId) throws Exception;
    List<WorkOrder> findByOandmId(Long oandmId, String reviewStatus) throws Exception;
    Long insert(WorkOrder order) throws Exception;
    void update(WorkOrder order) throws Exception;
}
