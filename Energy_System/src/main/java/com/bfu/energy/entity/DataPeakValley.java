package com.bfu.energy.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Date;

public class DataPeakValley implements Serializable {
    private Long recordId;
    private Date statDate;
    private String energyType;
    private Long factoryId;
    private String peakType;
    private BigDecimal totalConsumption;
    private BigDecimal costAmount;
    private Long energyMgrId;

    public DataPeakValley() {
    }

    public Long getRecordId() {
        return recordId;
    }

    public void setRecordId(Long recordId) {
        this.recordId = recordId;
    }

    public Date getStatDate() {
        return statDate;
    }

    public void setStatDate(Date statDate) {
        this.statDate = statDate;
    }

    public String getEnergyType() {
        return energyType;
    }

    public void setEnergyType(String energyType) {
        this.energyType = energyType;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public String getPeakType() {
        return peakType;
    }

    public void setPeakType(String peakType) {
        this.peakType = peakType;
    }

    public BigDecimal getTotalConsumption() {
        return totalConsumption;
    }

    public void setTotalConsumption(BigDecimal totalConsumption) {
        this.totalConsumption = totalConsumption;
    }

    public BigDecimal getCostAmount() {
        return costAmount;
    }

    public void setCostAmount(BigDecimal costAmount) {
        this.costAmount = costAmount;
    }

    public Long getEnergyMgrId() {
        return energyMgrId;
    }

    public void setEnergyMgrId(Long energyMgrId) {
        this.energyMgrId = energyMgrId;
    }

    @Override
    public String toString() {
        return "DataPeakValley{" +
                "recordId=" + recordId +
                ", statDate=" + statDate +
                ", energyType='" + energyType + '\'' +
                ", factoryId=" + factoryId +
                ", peakType='" + peakType + '\'' +
                ", totalConsumption=" + totalConsumption +
                ", costAmount=" + costAmount +
                ", energyMgrId=" + energyMgrId +
                '}';
    }
}
