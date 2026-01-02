package com.bfu.energy.entity;

import java.io.Serializable;

public class BaseFactory implements Serializable {
    private Long factoryId;
    private String factoryName;
    private String areaDesc;
    private Long managerUserId;

    public BaseFactory() {
    }

    public BaseFactory(Long factoryId, String factoryName, String areaDesc, Long managerUserId) {
        this.factoryId = factoryId;
        this.factoryName = factoryName;
        this.areaDesc = areaDesc;
        this.managerUserId = managerUserId;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    public String getFactoryName() {
        return factoryName;
    }

    public void setFactoryName(String factoryName) {
        this.factoryName = factoryName;
    }

    public String getAreaDesc() {
        return areaDesc;
    }

    public void setAreaDesc(String areaDesc) {
        this.areaDesc = areaDesc;
    }

    public Long getManagerUserId() {
        return managerUserId;
    }

    public void setManagerUserId(Long managerUserId) {
        this.managerUserId = managerUserId;
    }

    @Override
    public String toString() {
        return "BaseFactory{" +
                "factoryId=" + factoryId +
                ", factoryName='" + factoryName + '\'' +
                ", areaDesc='" + areaDesc + '\'' +
                ", managerUserId=" + managerUserId +
                '}';
    }
}
