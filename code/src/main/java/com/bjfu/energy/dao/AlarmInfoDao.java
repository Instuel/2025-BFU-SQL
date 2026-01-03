package com.bjfu.energy.dao;

import com.bjfu.energy.entity.AlarmInfo;

import java.util.List;

public interface AlarmInfoDao {
    List<AlarmInfo> findAll(String alarmType, String alarmLevel, String processStatus, String verifyStatus) throws Exception;
    AlarmInfo findById(Long alarmId) throws Exception;
    void updateStatus(Long alarmId, String processStatus) throws Exception;
    void updateVerification(Long alarmId, String verifyStatus, String verifyRemark) throws Exception;
}
