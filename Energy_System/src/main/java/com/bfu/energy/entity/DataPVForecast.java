package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class DataPVForecast implements Serializable {
    private Long forecastId;
    private Long pointId;
    private Date forecastDate;
    private String timeSlot;
    private Double forecastVal;
    private Double actualVal;
    private String modelVersion;
    private Long analystId;

    public DataPVForecast() {
    }

    public Long getForecastId() {
        return forecastId;
    }

    public void setForecastId(Long forecastId) {
        this.forecastId = forecastId;
    }

    public Long getPointId() {
        return pointId;
    }

    public void setPointId(Long pointId) {
        this.pointId = pointId;
    }

    public Date getForecastDate() {
        return forecastDate;
    }

    public void setForecastDate(Date forecastDate) {
        this.forecastDate = forecastDate;
    }

    public String getTimeSlot() {
        return timeSlot;
    }

    public void setTimeSlot(String timeSlot) {
        this.timeSlot = timeSlot;
    }

    public Double getForecastVal() {
        return forecastVal;
    }

    public void setForecastVal(Double forecastVal) {
        this.forecastVal = forecastVal;
    }

    public Double getActualVal() {
        return actualVal;
    }

    public void setActualVal(Double actualVal) {
        this.actualVal = actualVal;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public Long getAnalystId() {
        return analystId;
    }

    public void setAnalystId(Long analystId) {
        this.analystId = analystId;
    }

    @Override
    public String toString() {
        return "DataPVForecast{" +
                "forecastId=" + forecastId +
                ", pointId=" + pointId +
                ", forecastDate=" + forecastDate +
                ", timeSlot='" + timeSlot + '\'' +
                ", forecastVal=" + forecastVal +
                ", actualVal=" + actualVal +
                ", modelVersion='" + modelVersion + '\'' +
                ", analystId=" + analystId +
                '}';
    }
}
