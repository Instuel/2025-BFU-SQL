package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class PVDevice implements Serializable {
    private Long deviceId;
    private String deviceType;
    private Double capacity;
    private String runStatus;
    private Date installDate;
    private String protocol;
    private Long pointId;
    private Long ledgerId;

    public PVDevice() {
    }

    public Long getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(Long deviceId) {
        this.deviceId = deviceId;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public Double getCapacity() {
        return capacity;
    }

    public void setCapacity(Double capacity) {
        this.capacity = capacity;
    }

    public String getRunStatus() {
        return runStatus;
    }

    public void setRunStatus(String runStatus) {
        this.runStatus = runStatus;
    }

    public Date getInstallDate() {
        return installDate;
    }

    public void setInstallDate(Date installDate) {
        this.installDate = installDate;
    }

    public String getProtocol() {
        return protocol;
    }

    public void setProtocol(String protocol) {
        this.protocol = protocol;
    }

    public Long getPointId() {
        return pointId;
    }

    public void setPointId(Long pointId) {
        this.pointId = pointId;
    }

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    @Override
    public String toString() {
        return "PVDevice{" +
                "deviceId=" + deviceId +
                ", deviceType='" + deviceType + '\'' +
                ", capacity=" + capacity +
                ", runStatus='" + runStatus + '\'' +
                ", installDate=" + installDate +
                ", protocol='" + protocol + '\'' +
                ", pointId=" + pointId +
                ", ledgerId=" + ledgerId +
                '}';
    }
}
