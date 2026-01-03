package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysPermission;

import java.util.List;

public interface PermissionDao {
    List<SysPermission> findByUserId(Long userId) throws Exception;
}
