package com.bjfu.energy.entity;

public class RoleOandM {
    private Long oandmId;
    private Long userId;
    private Long factoryId;

    public RoleOandM() {
    }

    public RoleOandM(Long oandmId, Long userId, Long factoryId) {
        this.oandmId = oandmId;
        this.userId = userId;
        this.factoryId = factoryId;
    }

    public Long getOandmId() {
        return oandmId;
    }

    public void setOandmId(Long oandmId) {
        this.oandmId = oandmId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }
}
