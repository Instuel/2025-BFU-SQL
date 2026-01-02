package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class PVModelAlert implements Serializable {
    private Long alertId;
    private Long pointId;
    private Date triggerTime;
    private String remark;
    private String processStatus;
    private String modelVersion;

    public PVModelAlert() {
    }

    public Long getAlertId() {
        return alertId;
    }

    public void setAlertId(Long alertId) {
        this.alertId = alertId;
    }

    public Long getPointId() {
        return pointId;
    }

    public void setPointId(Long pointId) {
        this.pointId = pointId;
    }

    public Date getTriggerTime() {
        return triggerTime;
    }

    public void setTriggerTime(Date triggerTime) {
        this.triggerTime = triggerTime;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }

    public String getProcessStatus() {
        return processStatus;
    }

    public void setProcessStatus(String processStatus) {
        this.processStatus = processStatus;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    @Override
    public String toString() {
        return "PVModelAlert{" +
                "alertId=" + alertId +
                ", pointId=" + pointId +
                ", triggerTime=" + triggerTime +
                ", remark='" + remark + '\'' +
                ", processStatus='" + processStatus + '\'' +
                ", modelVersion='" + modelVersion + '\'' +
                '}';
    }
}
