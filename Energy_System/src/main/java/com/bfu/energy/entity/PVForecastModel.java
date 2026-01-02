package com.bfu.energy.entity;

import java.io.Serializable;
import java.util.Date;

public class PVForecastModel implements Serializable {
    private String modelVersion;
    private String modelName;
    private String status;
    private Date updateTime;

    public PVForecastModel() {
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public String getModelName() {
        return modelName;
    }

    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Date getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(Date updateTime) {
        this.updateTime = updateTime;
    }

    @Override
    public String toString() {
        return "PVForecastModel{" +
                "modelVersion='" + modelVersion + '\'' +
                ", modelName='" + modelName + '\'' +
                ", status='" + status + '\'' +
                ", updateTime=" + updateTime +
                '}';
    }
}
