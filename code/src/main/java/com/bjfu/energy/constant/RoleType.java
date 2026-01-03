package com.bjfu.energy.constant;

/** 角色类型（与数据库 Sys_Role_Assignment.Role_Type 对齐） */
public final class RoleType {
    private RoleType() {}

    public static final String ADMIN = "ADMIN";        // 系统管理员
    public static final String OM = "OM";              // 运维人员
    public static final String ENERGY = "ENERGY";      // 能源管理员
    public static final String ANALYST = "ANALYST";    // 数据分析师
    public static final String EXEC = "EXEC";          // 企业管理层
    public static final String DISPATCHER = "DISPATCHER"; // 运维工单管理员
}
