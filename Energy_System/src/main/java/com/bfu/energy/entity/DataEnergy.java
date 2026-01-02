package com.bfu.energy.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Timestamp;

public class DataEnergy implements Serializable {
    private Long dataId;
    private Long meterId;
    private Timestamp collectTime;
    private BigDecimal value;
    private String unit;
    private String quality;
    private Long factoryId;
    private Long pvRecordId;

    public DataEnergy() {
    }

    public Long getDataId() {
        return dataId;
    }

    public void setDataId(Long dataId) {
        this.dataId = dataId;
    }

    public Long getMeterId() {
        return meterId;
    }

    public void setMeterId(Long meterId) {
        this.meterId = meterId;
    }

    public Timestamp getCollectTime() {
        return collectTime;
    }

    public void setCollectTime(Timestamp collectTime) {
        this.collectTime = collectTime;
    }

    public BigDecimal getValue() {
        return value;
    }

    public void setValue(BigDecimal value) {
        this.value = value;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public String getQuality() {
        return quality;
    }

    public void setQuality(String quality) {
        this.quality = quality;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public Long getPvRecordId() {
        return pvRecordId;
    }

    public void setPvRecordId(Long pvRecordId) {
        this.pvRecordId = pvRecordId;
    }

    @Override
    public String toString() {
        return "DataEnergy{" +
                "dataId=" + dataId +
                ", meterId=" + meterId +
                ", collectTime=" + collectTime +
                ", value=" + value +
                ", unit='" + unit + '\'' +
                ", quality='" + quality + '\'' +
                ", factoryId=" + factoryId +
                ", pvRecordId=" + pvRecordId +
                '}';
    }
}
