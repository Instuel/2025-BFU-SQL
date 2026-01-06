package com.bjfu.energy.dao;

public interface RoleDispatcherDao {
    Long findDispatcherIdByUserId(Long userId) throws Exception;
}
