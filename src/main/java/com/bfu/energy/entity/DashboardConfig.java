package com.bfu.energy.entity;

import java.io.Serializable;

public class DashboardConfig implements Serializable {
    private Long configId;
    private String moduleName;
    private String refreshRate;
    private String sortRule;
    private String displayFields;
    private String authLevel;

    public DashboardConfig() {
    }

    public Long getConfigId() {
        return configId;
    }

    public void setConfigId(Long configId) {
        this.configId = configId;
    }

    public String getModuleName() {
        return moduleName;
    }

    public void setModuleName(String moduleName) {
        this.moduleName = moduleName;
    }

    public String getRefreshRate() {
        return refreshRate;
    }

    public void setRefreshRate(String refreshRate) {
        this.refreshRate = refreshRate;
    }

    public String getSortRule() {
        return sortRule;
    }

    public void setSortRule(String sortRule) {
        this.sortRule = sortRule;
    }

    public String getDisplayFields() {
        return displayFields;
    }

    public void setDisplayFields(String displayFields) {
        this.displayFields = displayFields;
    }

    public String getAuthLevel() {
        return authLevel;
    }

    public void setAuthLevel(String authLevel) {
        this.authLevel = authLevel;
    }

    @Override
    public String toString() {
        return "DashboardConfig{" +
                "configId=" + configId +
                ", moduleName='" + moduleName + '\'' +
                ", refreshRate='" + refreshRate + '\'' +
                ", sortRule='" + sortRule + '\'' +
                ", displayFields='" + displayFields + '\'' +
                ", authLevel='" + authLevel + '\'' +
                '}';
    }
}
