package com.bfu.energy.entity;

import java.io.Serializable;

public class EnergyMeter implements Serializable {
    private Long meterId;
    private String energyType;
    private String commProtocol;
    private String runStatus;
    private String installLocation;
    private Integer calibCycleMonths;
    private String manufacturer;
    private Long factoryId;
    private Long ledgerId;

    public EnergyMeter() {
    }

    public Long getMeterId() {
        return meterId;
    }

    public void setMeterId(Long meterId) {
        this.meterId = meterId;
    }

    public String getEnergyType() {
        return energyType;
    }

    public void setEnergyType(String energyType) {
        this.energyType = energyType;
    }

    public String getCommProtocol() {
        return commProtocol;
    }

    public void setCommProtocol(String commProtocol) {
        this.commProtocol = commProtocol;
    }

    public String getRunStatus() {
        return runStatus;
    }

    public void setRunStatus(String runStatus) {
        this.runStatus = runStatus;
    }

    public String getInstallLocation() {
        return installLocation;
    }

    public void setInstallLocation(String installLocation) {
        this.installLocation = installLocation;
    }

    public Integer getCalibCycleMonths() {
        return calibCycleMonths;
    }

    public void setCalibCycleMonths(Integer calibCycleMonths) {
        this.calibCycleMonths = calibCycleMonths;
    }

    public String getManufacturer() {
        return manufacturer;
    }

    public void setManufacturer(String manufacturer) {
        this.manufacturer = manufacturer;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    @Override
    public String toString() {
        return "EnergyMeter{" +
                "meterId=" + meterId +
                ", energyType='" + energyType + '\'' +
                ", commProtocol='" + commProtocol + '\'' +
                ", runStatus='" + runStatus + '\'' +
                ", installLocation='" + installLocation + '\'' +
                ", calibCycleMonths=" + calibCycleMonths +
                ", manufacturer='" + manufacturer + '\'' +
                ", factoryId=" + factoryId +
                ", ledgerId=" + ledgerId +
                '}';
    }
}
