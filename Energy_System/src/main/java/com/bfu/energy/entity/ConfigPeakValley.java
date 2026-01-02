package com.bfu.energy.entity;

import java.io.Serializable;
import java.sql.Time;

public class ConfigPeakValley implements Serializable {
    private Long configId;
    private String timeType;
    private Time startTime;
    private Time endTime;
    private Double priceRate;

    public ConfigPeakValley() {
    }

    public Long getConfigId() {
        return configId;
    }

    public void setConfigId(Long configId) {
        this.configId = configId;
    }

    public String getTimeType() {
        return timeType;
    }

    public void setTimeType(String timeType) {
        this.timeType = timeType;
    }

    public Time getStartTime() {
        return startTime;
    }

    public void setStartTime(Time startTime) {
        this.startTime = startTime;
    }

    public Time getEndTime() {
        return endTime;
    }

    public void setEndTime(Time endTime) {
        this.endTime = endTime;
    }

    public Double getPriceRate() {
        return priceRate;
    }

    public void setPriceRate(Double priceRate) {
        this.priceRate = priceRate;
    }

    @Override
    public String toString() {
        return "ConfigPeakValley{" +
                "configId=" + configId +
                ", timeType='" + timeType + '\'' +
                ", startTime=" + startTime +
                ", endTime=" + endTime +
                ", priceRate=" + priceRate +
                '}';
    }
}
