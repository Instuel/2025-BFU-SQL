package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysUser;

import java.util.List;

public interface UserDao {
    List<SysUser> findAll() throws Exception;
    SysUser findById(Long userId) throws Exception;
    SysUser findByLoginAccount(String loginAccount) throws Exception;
    Long insert(SysUser user) throws Exception;
    void update(SysUser user) throws Exception;
    void updateStatus(Long userId, int status, Long updatedBy) throws Exception;
    void updatePassword(Long userId, String passwordHash, String salt, Long updatedBy) throws Exception;
    void delete(Long userId) throws Exception;
}
