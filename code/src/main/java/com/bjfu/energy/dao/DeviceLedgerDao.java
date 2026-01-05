package com.bjfu.energy.dao;

import com.bjfu.energy.entity.DeviceLedger;

import java.util.List;

public interface DeviceLedgerDao {
    List<DeviceLedger> findAll(String deviceType, String scrapStatus) throws Exception;
    List<DeviceLedger> findByFactory(Long factoryId, String deviceType, String scrapStatus) throws Exception;
    DeviceLedger findById(Long ledgerId) throws Exception;
}
