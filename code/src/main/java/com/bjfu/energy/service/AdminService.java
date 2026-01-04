package com.bjfu.energy.service;

import com.bjfu.energy.dao.AdminDao;
import com.bjfu.energy.entity.AdminAuditLog;
import com.bjfu.energy.entity.AlarmRule;
import com.bjfu.energy.entity.BackupLog;
import com.bjfu.energy.entity.PeakValleyConfig;
import com.bjfu.energy.entity.PermissionSummary;
import com.bjfu.energy.entity.RoleAssignmentView;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

public class AdminService {

    private final AdminDao adminDao = new AdminDao();

    public List<RoleAssignmentView> listRoleAssignments() throws Exception {
        return adminDao.listRoleAssignments();
    }

    public void updateRoleAssignment(Long userId, String roleType, Long operatorId) throws Exception {
        if (userId == null) {
            throw new IllegalArgumentException("请选择需要分配角色的用户");
        }
        if (roleType == null || roleType.trim().isEmpty()) {
            throw new IllegalArgumentException("角色类型不能为空");
        }
        adminDao.replaceRoleAssignment(userId, roleType.trim(), operatorId);
        writeAuditLog("角色分配", "用户ID " + userId + " 设置角色为 " + roleType, operatorId);
    }

    public List<PermissionSummary> listPermissions() throws Exception {
        return adminDao.listPermissions();
    }

    public List<AlarmRule> listAlarmRules() throws Exception {
        return adminDao.listAlarmRules();
    }

    public void saveAlarmRule(Long ruleId,
                              String alarmType,
                              String alarmLevel,
                              String thresholdValue,
                              String thresholdUnit,
                              String notifyChannel,
                              String enabled,
                              Long operatorId) throws Exception {
        if (alarmType == null || alarmType.trim().isEmpty()) {
            throw new IllegalArgumentException("告警类型不能为空");
        }
        if (alarmLevel == null || alarmLevel.trim().isEmpty()) {
            throw new IllegalArgumentException("告警等级不能为空");
        }
        AlarmRule rule = new AlarmRule();
        rule.setRuleId(ruleId);
        rule.setAlarmType(alarmType.trim());
        rule.setAlarmLevel(alarmLevel.trim());
        if (thresholdValue != null && !thresholdValue.trim().isEmpty()) {
            rule.setThresholdValue(new BigDecimal(thresholdValue.trim()));
        }
        rule.setThresholdUnit(thresholdUnit == null ? null : thresholdUnit.trim());
        rule.setNotifyChannel(notifyChannel == null ? null : notifyChannel.trim());
        rule.setEnabled("1".equals(enabled) ? 1 : 0);
        adminDao.saveAlarmRule(rule);
        String action = ruleId == null ? "新增" : "更新";
        writeAuditLog("告警规则" + action, "告警类型: " + alarmType + " 等级: " + alarmLevel, operatorId);
    }

    public void toggleAlarmRule(Long ruleId, int enabled, Long operatorId) throws Exception {
        adminDao.updateAlarmRuleStatus(ruleId, enabled);
        writeAuditLog("告警规则状态", "规则ID " + ruleId + " 状态=" + (enabled == 1 ? "启用" : "停用"), operatorId);
    }

    public List<PeakValleyConfig> listPeakValleyConfigs() throws Exception {
        return adminDao.listPeakValleyConfigs();
    }

    public void addPeakValleyConfig(String timeType, String startTime, String endTime, String priceRate, Long operatorId)
            throws Exception {
        if (timeType == null || timeType.trim().isEmpty()) {
            throw new IllegalArgumentException("峰谷类型不能为空");
        }
        if (startTime == null || startTime.trim().isEmpty()) {
            throw new IllegalArgumentException("开始时间不能为空");
        }
        if (endTime == null || endTime.trim().isEmpty()) {
            throw new IllegalArgumentException("结束时间不能为空");
        }
        PeakValleyConfig config = new PeakValleyConfig();
        config.setTimeType(timeType.trim());
        config.setStartTime(LocalTime.parse(startTime));
        config.setEndTime(LocalTime.parse(endTime));
        if (priceRate != null && !priceRate.trim().isEmpty()) {
            config.setPriceRate(new BigDecimal(priceRate.trim()));
        }
        adminDao.savePeakValleyConfig(config);
        writeAuditLog("峰谷时段配置", "新增 " + timeType + " " + startTime + "-" + endTime, operatorId);
    }

    public List<BackupLog> listBackupLogs() throws Exception {
        return adminDao.listBackupLogs();
    }

    public void createBackupLog(String backupType,
                                String backupPath,
                                String status,
                                String remark,
                                Long operatorId) throws Exception {
        if (backupType == null || backupType.trim().isEmpty()) {
            throw new IllegalArgumentException("备份类型不能为空");
        }

        BackupLog log = new BackupLog();
        log.setBackupType(backupType.trim());
        log.setBackupPath(backupPath == null ? null : backupPath.trim());
        log.setOperatorId(operatorId);
        log.setStartTime(LocalDateTime.now());

        boolean success = false;
        String finalStatus = (status == null || status.trim().isEmpty()) ? null : status.trim();
        String finalRemark = remark == null ? null : remark.trim();

        try {
            // 真正执行备份/恢复动作
            if ("全量备份".equals(backupType)) {
                adminDao.executeFullBackup(log.getBackupPath());
            } else if ("增量备份".equals(backupType)) {
                adminDao.executeDiffBackup(log.getBackupPath());
            } else if ("恢复演练".equals(backupType)) {
                adminDao.executeRestoreVerify(log.getBackupPath());
            }
            success = true;
        } catch (Exception e) {
            // 失败时在备注中追加错误信息
            StringBuilder sb = new StringBuilder();
            if (finalRemark != null && !finalRemark.isEmpty()) {
                sb.append(finalRemark).append("；");
            }
            sb.append("执行失败: ").append(e.getMessage());
            finalRemark = sb.toString();
            finalStatus = "失败";
            throw e;
        } finally {
            log.setEndTime(LocalDateTime.now());
            if (finalStatus == null || finalStatus.isEmpty()) {
                finalStatus = success ? "成功" : "失败";
            }
            log.setStatus(finalStatus);
            log.setRemark(finalRemark);
            adminDao.insertBackupLog(log);
            writeAuditLog("备份/恢复", "执行 " + backupType + " 任务", operatorId);
        }
    }

    public List<AdminAuditLog> listAuditLogs() throws Exception {
        return adminDao.listAuditLogs();
    }

    public Map<String, Integer> loadSystemCounters() throws Exception {
        return adminDao.loadSystemCounters();
    }

    public String getLatestBackupTime() throws Exception {
        return adminDao.findLatestBackupTime();
    }

    public long getDbLatencyMs() throws Exception {
        return adminDao.measureDbLatencyMs();
    }

    private void writeAuditLog(String actionType, String detail, Long operatorId) throws Exception {
        AdminAuditLog log = new AdminAuditLog();
        log.setActionType(actionType);
        log.setActionDetail(detail);
        log.setOperatorId(operatorId);
        adminDao.insertAuditLog(log);
    }
}
