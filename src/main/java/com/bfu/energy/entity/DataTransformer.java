package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class DataTransformer implements Serializable {
    private Long dataId;
    private Long transformerId;
    private Date collectTime;
    private Double windingTemp;
    private Double coreTemp;
    private Double loadRate;
    private Long factoryId;

    public DataTransformer() {
    }

    public Long getDataId() {
        return dataId;
    }

    public void setDataId(Long dataId) {
        this.dataId = dataId;
    }

    public Long getTransformerId() {
        return transformerId;
    }

    public void setTransformerId(Long transformerId) {
        this.transformerId = transformerId;
    }

    public Date getCollectTime() {
        return collectTime;
    }

    public void setCollectTime(Date collectTime) {
        this.collectTime = collectTime;
    }

    public Double getWindingTemp() {
        return windingTemp;
    }

    public void setWindingTemp(Double windingTemp) {
        this.windingTemp = windingTemp;
    }

    public Double getCoreTemp() {
        return coreTemp;
    }

    public void setCoreTemp(Double coreTemp) {
        this.coreTemp = coreTemp;
    }

    public Double getLoadRate() {
        return loadRate;
    }

    public void setLoadRate(Double loadRate) {
        this.loadRate = loadRate;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    @Override
    public String toString() {
        return "DataTransformer{" +
                "dataId=" + dataId +
                ", transformerId=" + transformerId +
                ", collectTime=" + collectTime +
                ", windingTemp=" + windingTemp +
                ", coreTemp=" + coreTemp +
                ", loadRate=" + loadRate +
                ", factoryId=" + factoryId +
                '}';
    }
}
