package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysUser;

/** Sys_User 表的 DAO（骨架） */
public interface SysUserDao {
    SysUser findByLoginAccount(String loginAccount) throws Exception;
    Long insert(SysUser user) throws Exception;
    void updateLastLogin(Long userId) throws Exception;

    void increaseFailedLogin(Long userId) throws Exception;
    void resetFailedLogin(Long userId) throws Exception;
    void lockAccount(Long userId, int minutes) throws Exception;

    String getRoleTypeByUserId(Long userId) throws Exception; // 取 Sys_Role_Assignment.Role_Type
}
