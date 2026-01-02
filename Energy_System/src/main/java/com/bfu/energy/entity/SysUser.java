package com.bfu.energy.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class SysUser implements Serializable {
    private Long userId;
    private String loginAccount;
    private String loginPassword;
    private String salt;
    private String realName;
    private String department;
    private String contactPhone;
    private Integer accountStatus;
    private LocalDateTime createdTime;

    public SysUser() {
    }

    public SysUser(Long userId, String loginAccount, String loginPassword, String salt, String realName, 
                   String department, String contactPhone, Integer accountStatus, LocalDateTime createdTime) {
        this.userId = userId;
        this.loginAccount = loginAccount;
        this.loginPassword = loginPassword;
        this.salt = salt;
        this.realName = realName;
        this.department = department;
        this.contactPhone = contactPhone;
        this.accountStatus = accountStatus;
        this.createdTime = createdTime;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getLoginAccount() {
        return loginAccount;
    }

    public void setLoginAccount(String loginAccount) {
        this.loginAccount = loginAccount;
    }

    public String getLoginPassword() {
        return loginPassword;
    }

    public void setLoginPassword(String loginPassword) {
        this.loginPassword = loginPassword;
    }

    public String getSalt() {
        return salt;
    }

    public void setSalt(String salt) {
        this.salt = salt;
    }

    public String getRealName() {
        return realName;
    }

    public void setRealName(String realName) {
        this.realName = realName;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public String getContactPhone() {
        return contactPhone;
    }

    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }

    public Integer getAccountStatus() {
        return accountStatus;
    }

    public void setAccountStatus(Integer accountStatus) {
        this.accountStatus = accountStatus;
    }

    public LocalDateTime getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(LocalDateTime createdTime) {
        this.createdTime = createdTime;
    }

    @Override
    public String toString() {
        return "SysUser{" +
                "userId=" + userId +
                ", loginAccount='" + loginAccount + '\'' +
                ", loginPassword='" + loginPassword + '\'' +
                ", salt='" + salt + '\'' +
                ", realName='" + realName + '\'' +
                ", department='" + department + '\'' +
                ", contactPhone='" + contactPhone + '\'' +
                ", accountStatus=" + accountStatus +
                ", createdTime=" + createdTime +
                '}';
    }
}
