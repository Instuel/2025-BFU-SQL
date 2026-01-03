package com.bjfu.energy.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AlarmInfo {

    private Long alarmId;
    private String alarmType;
    private String alarmLevel;
    private String content;
    private LocalDateTime occurTime;
    private String processStatus;
    private Long ledgerId;
    private Long factoryId;
    private BigDecimal triggerThreshold;

    private String deviceName;
    private String deviceType;

    private Long workOrderId;
    private LocalDateTime dispatchTime;
    private boolean dispatchOverdue;

    public Long getAlarmId() {
        return alarmId;
    }

    public void setAlarmId(Long alarmId) {
        this.alarmId = alarmId;
    }

    public String getAlarmType() {
        return alarmType;
    }

    public void setAlarmType(String alarmType) {
        this.alarmType = alarmType;
    }

    public String getAlarmLevel() {
        return alarmLevel;
    }

    public void setAlarmLevel(String alarmLevel) {
        this.alarmLevel = alarmLevel;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public LocalDateTime getOccurTime() {
        return occurTime;
    }

    public void setOccurTime(LocalDateTime occurTime) {
        this.occurTime = occurTime;
    }

    public String getProcessStatus() {
        return processStatus;
    }

    public void setProcessStatus(String processStatus) {
        this.processStatus = processStatus;
    }

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public BigDecimal getTriggerThreshold() {
        return triggerThreshold;
    }

    public void setTriggerThreshold(BigDecimal triggerThreshold) {
        this.triggerThreshold = triggerThreshold;
    }

    public String getDeviceName() {
        return deviceName;
    }

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public Long getWorkOrderId() {
        return workOrderId;
    }

    public void setWorkOrderId(Long workOrderId) {
        this.workOrderId = workOrderId;
    }

    public LocalDateTime getDispatchTime() {
        return dispatchTime;
    }

    public void setDispatchTime(LocalDateTime dispatchTime) {
        this.dispatchTime = dispatchTime;
    }

    public boolean isDispatchOverdue() {
        return dispatchOverdue;
    }

    public void setDispatchOverdue(boolean dispatchOverdue) {
        this.dispatchOverdue = dispatchOverdue;
    }
}
