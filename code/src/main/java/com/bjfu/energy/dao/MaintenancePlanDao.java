package com.bjfu.energy.dao;

import com.bjfu.energy.entity.MaintenancePlan;

import java.util.List;

public interface MaintenancePlanDao {
    List<MaintenancePlan> findAll(String deviceType, String status) throws Exception;

    List<MaintenancePlan> findByLedgerId(Long ledgerId) throws Exception;

    Long insert(MaintenancePlan plan) throws Exception;
}
