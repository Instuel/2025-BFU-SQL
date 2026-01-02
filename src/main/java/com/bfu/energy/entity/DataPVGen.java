package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class DataPVGen implements Serializable {
    private Long dataId;
    private Long deviceId;
    private Date collectTime;
    private Double genKwh;
    private Double gridKwh;
    private Double selfKwh;
    private Double inverterEff;
    private Long factoryId;

    public DataPVGen() {
    }

    public Long getDataId() {
        return dataId;
    }

    public void setDataId(Long dataId) {
        this.dataId = dataId;
    }

    public Long getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(Long deviceId) {
        this.deviceId = deviceId;
    }

    public Date getCollectTime() {
        return collectTime;
    }

    public void setCollectTime(Date collectTime) {
        this.collectTime = collectTime;
    }

    public Double getGenKwh() {
        return genKwh;
    }

    public void setGenKwh(Double genKwh) {
        this.genKwh = genKwh;
    }

    public Double getGridKwh() {
        return gridKwh;
    }

    public void setGridKwh(Double gridKwh) {
        this.gridKwh = gridKwh;
    }

    public Double getSelfKwh() {
        return selfKwh;
    }

    public void setSelfKwh(Double selfKwh) {
        this.selfKwh = selfKwh;
    }

    public Double getInverterEff() {
        return inverterEff;
    }

    public void setInverterEff(Double inverterEff) {
        this.inverterEff = inverterEff;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    @Override
    public String toString() {
        return "DataPVGen{" +
                "dataId=" + dataId +
                ", deviceId=" + deviceId +
                ", collectTime=" + collectTime +
                ", genKwh=" + genKwh +
                ", gridKwh=" + gridKwh +
                ", selfKwh=" + selfKwh +
                ", inverterEff=" + inverterEff +
                ", factoryId=" + factoryId +
                '}';
    }
}
