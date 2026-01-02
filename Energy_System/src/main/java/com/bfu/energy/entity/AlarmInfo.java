package com.bfu.energy.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class AlarmInfo implements Serializable {
    private Long alarmId;
    private String alarmType;
    private String alarmLevel;
    private String content;
    private LocalDateTime occurTime;
    private String processStatus;
    private Long ledgerId;
    private Long factoryId;

    public AlarmInfo() {
    }

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

    @Override
    public String toString() {
        return "AlarmInfo{" +
                "alarmId=" + alarmId +
                ", alarmType='" + alarmType + '\'' +
                ", alarmLevel='" + alarmLevel + '\'' +
                ", content='" + content + '\'' +
                ", occurTime=" + occurTime +
                ", processStatus='" + processStatus + '\'' +
                '}';
    }
}
