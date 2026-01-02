package com.bfu.energy.entity;

import java.io.Serializable;

public class DistRoom implements Serializable {
    private Long roomId;
    private String roomName;
    private String location;
    private String voltageLevel;
    private Long managerUserId;
    private Long factoryId;

    public DistRoom() {
    }

    public Long getRoomId() {
        return roomId;
    }

    public void setRoomId(Long roomId) {
        this.roomId = roomId;
    }

    public String getRoomName() {
        return roomName;
    }

    public void setRoomName(String roomName) {
        this.roomName = roomName;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getVoltageLevel() {
        return voltageLevel;
    }

    public void setVoltageLevel(String voltageLevel) {
        this.voltageLevel = voltageLevel;
    }

    public Long getManagerUserId() {
        return managerUserId;
    }

    public void setManagerUserId(Long managerUserId) {
        this.managerUserId = managerUserId;
    }

    public Long getFactoryId() {
        return factoryId;
    }

    public void setFactoryId(Long factoryId) {
        this.factoryId = factoryId;
    }

    @Override
    public String toString() {
        return "DistRoom{" +
                "roomId=" + roomId +
                ", roomName='" + roomName + '\'' +
                ", location='" + location + '\'' +
                ", voltageLevel='" + voltageLevel + '\'' +
                ", factoryId=" + factoryId +
                '}';
    }
}
