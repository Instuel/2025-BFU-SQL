package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class DataCircuit implements Serializable {
    private Long dataId;
    private Long circuitId;
    private Date collectTime;
    private Double voltage;
    private Double currentVal;
    private Double activePower;
    private Double reactivePower;
    private Double powerFactor;
    private String switchStatus;
    private Long factoryId;

    public DataCircuit() {
    }

    public Long getDataId() {
        return dataId;
    }

    public void setDataId(Long dataId) {
        this.dataId = dataId;
    }

    public Long getCircuitId() {
        return circuitId;
    }

    public void setCircuitId(Long circuitId) {
        this.circuitId = circuitId;
    }

    public Date getCollectTime() {
        return collectTime;
    }

    public void setCollectTime(Date collectTime) {
        this.collectTime = collectTime;
    }

    public Double getVoltage() {
        return voltage;
    }

    public void setVoltage(Double voltage) {
        this.voltage = voltage;
    }

    public Double getCurrentVal() {
        return currentVal;
    }

    public void setCurrentVal(Double currentVal) {
        this.currentVal = currentVal;
    }

    public Double getActivePower() {
        return activePower;
    }

    public void setActivePower(Double activePower) {
        this.activePower = activePower;
    }

    public Double getReactivePower() {
        return reactivePower;
    }

    public void setReactivePower(Double reactivePower) {
        this.reactivePower = reactivePower;
    }

    public Double getPowerFactor() {
        return powerFactor;
    }

    public void setPowerFactor(Double powerFactor) {
        this.powerFactor = powerFactor;
    }

    public String getSwitchStatus() {
        return switchStatus;
    }

    public void setSwitchStatus(String switchStatus) {
        this.switchStatus = switchStatus;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    @Override
    public String toString() {
        return "DataCircuit{" +
                "dataId=" + dataId +
                ", circuitId=" + circuitId +
                ", collectTime=" + collectTime +
                ", voltage=" + voltage +
                ", currentVal=" + currentVal +
                ", activePower=" + activePower +
                ", reactivePower=" + reactivePower +
                ", powerFactor=" + powerFactor +
                ", switchStatus='" + switchStatus + '\'' +
                ", factoryId=" + factoryId +
                '}';
    }
}
