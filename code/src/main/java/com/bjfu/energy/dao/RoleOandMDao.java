package com.bjfu.energy.dao;

import com.bjfu.energy.entity.RoleOandM;
import com.bjfu.energy.entity.SysUser;

import java.util.List;

public interface RoleOandMDao {
    List<SysUser> findAll() throws Exception;
    List<SysUser> findByFactory(Long factoryId) throws Exception;
    RoleOandM findByUserId(Long userId) throws Exception;
    RoleOandM findById(Long oandmId) throws Exception;
    Long insert(RoleOandM roleOandM) throws Exception;
    void update(RoleOandM roleOandM) throws Exception;
    void delete(Long oandmId) throws Exception;
}
