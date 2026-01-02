package com.bfu.energy.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Date;

public class StatHistoryTrend implements Serializable {
    private String trendId;
    private String energyType;
    private String statCycle;
    private Date statDate;
    private BigDecimal value;
    private BigDecimal yoyRate;
    private BigDecimal momRate;
    private Long configId;
    private Long analystId;

    public StatHistoryTrend() {
    }

    public String getTrendId() {
        return trendId;
    }

    public void setTrendId(String trendId) {
        this.trendId = trendId;
    }

    public String getEnergyType() {
        return energyType;
    }

    public void setEnergyType(String energyType) {
        this.energyType = energyType;
    }

    public String getStatCycle() {
        return statCycle;
    }

    public void setStatCycle(String statCycle) {
        this.statCycle = statCycle;
    }

    public Date getStatDate() {
        return statDate;
    }

    public void setStatDate(Date statDate) {
        this.statDate = statDate;
    }

    public BigDecimal getValue() {
        return value;
    }

    public void setValue(BigDecimal value) {
        this.value = value;
    }

    public BigDecimal getYoyRate() {
        return yoyRate;
    }

    public void setYoyRate(BigDecimal yoyRate) {
        this.yoyRate = yoyRate;
    }

    public BigDecimal getMomRate() {
        return momRate;
    }

    public void setMomRate(BigDecimal momRate) {
        this.momRate = momRate;
    }

    public Long getConfigId() {
        return configId;
    }

    public void setConfigId(Long configId) {
        this.configId = configId;
    }

    public Long getAnalystId() {
        return analystId;
    }

    public void setAnalystId(Long analystId) {
        this.analystId = analystId;
    }

    @Override
    public String toString() {
        return "StatHistoryTrend{" +
                "trendId='" + trendId + '\'' +
                ", energyType='" + energyType + '\'' +
                ", statCycle='" + statCycle + '\'' +
                ", statDate=" + statDate +
                ", value=" + value +
                ", yoyRate=" + yoyRate +
                ", momRate=" + momRate +
                ", configId=" + configId +
                ", analystId=" + analystId +
                '}';
    }
}
