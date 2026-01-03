package com.bjfu.energy.entity;

import java.io.Serializable;

public class PermissionSummary implements Serializable {

    private String permCode;
    private String permName;
    private String module;
    private String uriPattern;
    private Integer enabled;
    private String roleTypes;

    public String getPermCode() {
        return permCode;
    }

    public void setPermCode(String permCode) {
        this.permCode = permCode;
    }

    public String getPermName() {
        return permName;
    }

    public void setPermName(String permName) {
        this.permName = permName;
    }

    public String getModule() {
        return module;
    }

    public void setModule(String module) {
        this.module = module;
    }

    public String getUriPattern() {
        return uriPattern;
    }

    public void setUriPattern(String uriPattern) {
        this.uriPattern = uriPattern;
    }

    public Integer getEnabled() {
        return enabled;
    }

    public void setEnabled(Integer enabled) {
        this.enabled = enabled;
    }

    public String getRoleTypes() {
        return roleTypes;
    }

    public void setRoleTypes(String roleTypes) {
        this.roleTypes = roleTypes;
    }
}
