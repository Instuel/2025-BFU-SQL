package com.bfu.energy.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class SysRoleAssignment implements Serializable {
    private Long assignmentId;
    private Long userId;
    private String roleType;
    private Long assignedBy;
    private LocalDateTime assignedTime;

    public SysRoleAssignment() {
    }

    public Long getAssignmentId() {
        return assignmentId;
    }

    public void setAssignmentId(Long assignmentId) {
        this.assignmentId = assignmentId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getRoleType() {
        return roleType;
    }

    public void setRoleType(String roleType) {
        this.roleType = roleType;
    }

    public Long getAssignedBy() {
        return assignedBy;
    }

    public void setAssignedBy(Long assignedBy) {
        this.assignedBy = assignedBy;
    }

    public LocalDateTime getAssignedTime() {
        return assignedTime;
    }

    public void setAssignedTime(LocalDateTime assignedTime) {
        this.assignedTime = assignedTime;
    }

    @Override
    public String toString() {
        return "SysRoleAssignment{" +
                "assignmentId=" + assignmentId +
                ", userId=" + userId +
                ", roleType='" + roleType + '\'' +
                ", assignedBy=" + assignedBy +
                ", assignedTime=" + assignedTime +
                '}';
    }
}
