package com.bfu.energy.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class AlarmHandlingLog implements Serializable {
    private Long logId;
    private Long alarmId;
    private LocalDateTime handleTime;
    private String statusAfter;
    private Long oandMId;
    private Long dispatcherId;

    public AlarmHandlingLog() {
    }

    public Long getLogId() {
        return logId;
    }

    public void setLogId(Long logId) {
        this.logId = logId;
    }

    public Long getAlarmId() {
        return alarmId;
    }

    public void setAlarmId(Long alarmId) {
        this.alarmId = alarmId;
    }

    public LocalDateTime getHandleTime() {
        return handleTime;
    }

    public void setHandleTime(LocalDateTime handleTime) {
        this.handleTime = handleTime;
    }

    public String getStatusAfter() {
        return statusAfter;
    }

    public void setStatusAfter(String statusAfter) {
        this.statusAfter = statusAfter;
    }

    public Long getOandMId() {
        return oandMId;
    }

    public void setOandMId(Long oandMId) {
        this.oandMId = oandMId;
    }

    public Long getDispatcherId() {
        return dispatcherId;
    }

    public void setDispatcherId(Long dispatcherId) {
        this.dispatcherId = dispatcherId;
    }

    @Override
    public String toString() {
        return "AlarmHandlingLog{" +
                "logId=" + logId +
                ", alarmId=" + alarmId +
                ", handleTime=" + handleTime +
                ", statusAfter='" + statusAfter + '\'' +
                ", oandMId=" + oandMId +
                ", dispatcherId=" + dispatcherId +
                '}';
    }
}
