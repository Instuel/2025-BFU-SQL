package com.bfu.energy.entity;

import java.io.Serializable;

public class PVGridPoint implements Serializable {
    private Long pointId;
    private String pointName;
    private String location;

    public PVGridPoint() {
    }

    public Long getPointId() {
        return pointId;
    }

    public void setPointId(Long pointId) {
        this.pointId = pointId;
    }

    public String getPointName() {
        return pointName;
    }

    public void setPointName(String pointName) {
        this.pointName = pointName;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    @Override
    public String toString() {
        return "PVGridPoint{" +
                "pointId=" + pointId +
                ", pointName='" + pointName + '\'' +
                ", location='" + location + '\'' +
                '}';
    }
}
