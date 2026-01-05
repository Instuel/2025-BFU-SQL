package com.bjfu.energy.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class DeviceLedger {

    private Long ledgerId;
    private String deviceName;
    private String deviceType;
    private String modelSpec;
    private LocalDate installTime;
    private String scrapStatus;
    private Integer warrantyYears;
    private LocalDateTime calibrationTime;
    private String calibrationPerson;
    private Long factoryId;

    private LocalDate warrantyExpireDate;
    private Integer warrantyDaysLeft;
    private String warrantyStatus;

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    public String getDeviceName() {
        return deviceName;
    }

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getModelSpec() {
        return modelSpec;
    }

    public void setModelSpec(String modelSpec) {
        this.modelSpec = modelSpec;
    }

    public LocalDate getInstallTime() {
        return installTime;
    }

    public void setInstallTime(LocalDate installTime) {
        this.installTime = installTime;
    }

    public String getScrapStatus() {
        return scrapStatus;
    }

    public void setScrapStatus(String scrapStatus) {
        this.scrapStatus = scrapStatus;
    }

    public Integer getWarrantyYears() {
        return warrantyYears;
    }

    public void setWarrantyYears(Integer warrantyYears) {
        this.warrantyYears = warrantyYears;
    }

    public LocalDateTime getCalibrationTime() {
        return calibrationTime;
    }

    public void setCalibrationTime(LocalDateTime calibrationTime) {
        this.calibrationTime = calibrationTime;
    }

    public String getCalibrationPerson() {
        return calibrationPerson;
    }

    public void setCalibrationPerson(String calibrationPerson) {
        this.calibrationPerson = calibrationPerson;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public LocalDate getWarrantyExpireDate() {
        return warrantyExpireDate;
    }

    public void setWarrantyExpireDate(LocalDate warrantyExpireDate) {
        this.warrantyExpireDate = warrantyExpireDate;
    }

    public Integer getWarrantyDaysLeft() {
        return warrantyDaysLeft;
    }

    public void setWarrantyDaysLeft(Integer warrantyDaysLeft) {
        this.warrantyDaysLeft = warrantyDaysLeft;
    }

    public String getWarrantyStatus() {
        return warrantyStatus;
    }

    public void setWarrantyStatus(String warrantyStatus) {
        this.warrantyStatus = warrantyStatus;
    }
}
