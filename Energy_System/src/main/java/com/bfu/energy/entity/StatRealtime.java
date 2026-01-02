package com.bfu.energy.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public class StatRealtime implements Serializable {
    private String summaryId;
    private LocalDateTime statTime;
    private BigDecimal totalKwh;
    private Integer totalAlarm;
    private BigDecimal pvGenKwh;
    private Long configId;
    private Long managerId;

    public StatRealtime() {
    }

    public String getSummaryId() {
        return summaryId;
    }

    public void setSummaryId(String summaryId) {
        this.summaryId = summaryId;
    }

    public LocalDateTime getStatTime() {
        return statTime;
    }

    public void setStatTime(LocalDateTime statTime) {
        this.statTime = statTime;
    }

    public BigDecimal getTotalKwh() {
        return totalKwh;
    }

    public void setTotalKwh(BigDecimal totalKwh) {
        this.totalKwh = totalKwh;
    }

    public Integer getTotalAlarm() {
        return totalAlarm;
    }

    public void setTotalAlarm(Integer totalAlarm) {
        this.totalAlarm = totalAlarm;
    }

    public BigDecimal getPvGenKwh() {
        return pvGenKwh;
    }

    public void setPvGenKwh(BigDecimal pvGenKwh) {
        this.pvGenKwh = pvGenKwh;
    }

    public Long getConfigId() {
        return configId;
    }

    public void setConfigId(Long configId) {
        this.configId = configId;
    }

    public Long getManagerId() {
        return managerId;
    }

    public void setManagerId(Long managerId) {
        this.managerId = managerId;
    }

    @Override
    public String toString() {
        return "StatRealtime{" +
                "summaryId='" + summaryId + '\'' +
                ", statTime=" + statTime +
                ", totalKwh=" + totalKwh +
                ", totalAlarm=" + totalAlarm +
                ", pvGenKwh=" + pvGenKwh +
                ", configId=" + configId +
                ", managerId=" + managerId +
                '}';
    }
}
