package com.bfu.energy.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class WorkOrder implements Serializable {
    private Long orderId;
    private Long alarmId;
    private Long oandMId;
    private Long ledgerId;
    private LocalDateTime dispatchTime;
    private LocalDateTime responseTime;
    private LocalDateTime finishTime;
    private String resultDesc;
    private String reviewStatus;

    public WorkOrder() {
    }

    public Long getOrderId() {
        return orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public Long getAlarmId() {
        return alarmId;
    }

    public void setAlarmId(Long alarmId) {
        this.alarmId = alarmId;
    }

    public Long getOandMId() {
        return oandMId;
    }

    public void setOandMId(Long oandMId) {
        this.oandMId = oandMId;
    }

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    public LocalDateTime getDispatchTime() {
        return dispatchTime;
    }

    public void setDispatchTime(LocalDateTime dispatchTime) {
        this.dispatchTime = dispatchTime;
    }

    public LocalDateTime getResponseTime() {
        return responseTime;
    }

    public void setResponseTime(LocalDateTime responseTime) {
        this.responseTime = responseTime;
    }

    public LocalDateTime getFinishTime() {
        return finishTime;
    }

    public void setFinishTime(LocalDateTime finishTime) {
        this.finishTime = finishTime;
    }

    public String getResultDesc() {
        return resultDesc;
    }

    public void setResultDesc(String resultDesc) {
        this.resultDesc = resultDesc;
    }

    public String getReviewStatus() {
        return reviewStatus;
    }

    public void setReviewStatus(String reviewStatus) {
        this.reviewStatus = reviewStatus;
    }

    @Override
    public String toString() {
        return "WorkOrder{" +
                "orderId=" + orderId +
                ", alarmId=" + alarmId +
                ", oandMId=" + oandMId +
                ", ledgerId=" + ledgerId +
                ", dispatchTime=" + dispatchTime +
                ", responseTime=" + responseTime +
                ", finishTime=" + finishTime +
                ", resultDesc='" + resultDesc + '\'' +
                ", reviewStatus='" + reviewStatus + '\'' +
                '}';
    }
}
