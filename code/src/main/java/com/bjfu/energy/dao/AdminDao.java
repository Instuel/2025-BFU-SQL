package com.bjfu.energy.dao;

import com.bjfu.energy.entity.AdminAuditLog;
import com.bjfu.energy.entity.AlarmRule;
import com.bjfu.energy.entity.BackupLog;
import com.bjfu.energy.entity.PeakValleyConfig;
import com.bjfu.energy.entity.PermissionSummary;
import com.bjfu.energy.entity.RoleAssignmentView;
import com.bjfu.energy.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Time;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AdminDao {

    public List<RoleAssignmentView> listRoleAssignments() throws Exception {
        String sql = "SELECT u.User_ID, u.Login_Account, u.Real_Name, u.Department, u.Account_Status, " +
                "       a.Role_Type, a.Assigned_Time " +
                "FROM Sys_User u " +
                "OUTER APPLY ( " +
                "    SELECT TOP 1 Role_Type, Assigned_Time " +
                "    FROM Sys_Role_Assignment a " +
                "    WHERE a.User_ID = u.User_ID " +
                "    ORDER BY a.Assigned_Time DESC, a.Assignment_ID DESC " +
                ") a " +
                "ORDER BY u.User_ID";
        List<RoleAssignmentView> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                RoleAssignmentView view = new RoleAssignmentView();
                view.setUserId(rs.getLong("User_ID"));
                view.setLoginAccount(rs.getString("Login_Account"));
                view.setRealName(rs.getString("Real_Name"));
                view.setDepartment(rs.getString("Department"));
                int status = rs.getInt("Account_Status");
                if (rs.wasNull()) {
                    view.setAccountStatus(null);
                } else {
                    view.setAccountStatus(status);
                }
                view.setRoleType(rs.getString("Role_Type"));
                java.sql.Timestamp assignedTime = rs.getTimestamp("Assigned_Time");
                view.setAssignedTime(assignedTime == null ? null : assignedTime.toLocalDateTime());
                result.add(view);
            }
        }
        return result;
    }

    public void replaceRoleAssignment(Long userId, String roleType, Long operatorId) throws Exception {
        String deleteSql = "DELETE FROM Sys_Role_Assignment WHERE User_ID = ?";
        String insertSql = "INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By) VALUES (?, ?, ?)";
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement deletePs = conn.prepareStatement(deleteSql)) {
                deletePs.setLong(1, userId);
                deletePs.executeUpdate();
            }
            try (PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
                insertPs.setLong(1, userId);
                insertPs.setString(2, roleType);
                if (operatorId == null) {
                    insertPs.setNull(3, java.sql.Types.BIGINT);
                } else {
                    insertPs.setLong(3, operatorId);
                }
                insertPs.executeUpdate();
            }
            conn.commit();
        }
    }

    public List<PermissionSummary> listPermissions() throws Exception {
        String permSql = "SELECT Perm_Code, Perm_Name, Module, Uri_Pattern, Is_Enabled " +
                "FROM Sys_Permission ORDER BY Module, Perm_Code";
        String roleSql = "SELECT Perm_Code, Role_Type FROM Sys_Role_Permission";

        Map<String, PermissionSummary> map = new LinkedHashMap<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement permPs = conn.prepareStatement(permSql);
             ResultSet permRs = permPs.executeQuery()) {
            while (permRs.next()) {
                PermissionSummary summary = new PermissionSummary();
                String permCode = permRs.getString("Perm_Code");
                summary.setPermCode(permCode);
                summary.setPermName(permRs.getString("Perm_Name"));
                summary.setModule(permRs.getString("Module"));
                summary.setUriPattern(permRs.getString("Uri_Pattern"));
                int enabled = permRs.getInt("Is_Enabled");
                if (permRs.wasNull()) {
                    summary.setEnabled(null);
                } else {
                    summary.setEnabled(enabled);
                }
                map.put(permCode, summary);
            }
        }

        Map<String, List<String>> roleMap = new LinkedHashMap<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement rolePs = conn.prepareStatement(roleSql);
             ResultSet roleRs = rolePs.executeQuery()) {
            while (roleRs.next()) {
                String permCode = roleRs.getString("Perm_Code");
                String roleType = roleRs.getString("Role_Type");
                roleMap.computeIfAbsent(permCode, key -> new ArrayList<>()).add(roleType);
            }
        }

        for (Map.Entry<String, PermissionSummary> entry : map.entrySet()) {
            List<String> roles = roleMap.get(entry.getKey());
            if (roles == null || roles.isEmpty()) {
                entry.getValue().setRoleTypes("-");
            } else {
                entry.getValue().setRoleTypes(String.join(", ", roles));
            }
        }

        return new ArrayList<>(map.values());
    }

    public List<AlarmRule> listAlarmRules() throws Exception {
        String sql = "SELECT Rule_ID, Alarm_Type, Alarm_Level, Threshold_Value, Threshold_Unit, " +
                "Notify_Channel, Is_Enabled, Updated_Time " +
                "FROM Sys_Alarm_Rule ORDER BY Rule_ID DESC";
        List<AlarmRule> rules = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                AlarmRule rule = new AlarmRule();
                rule.setRuleId(rs.getLong("Rule_ID"));
                rule.setAlarmType(rs.getString("Alarm_Type"));
                rule.setAlarmLevel(rs.getString("Alarm_Level"));
                BigDecimal threshold = rs.getBigDecimal("Threshold_Value");
                rule.setThresholdValue(threshold);
                rule.setThresholdUnit(rs.getString("Threshold_Unit"));
                rule.setNotifyChannel(rs.getString("Notify_Channel"));
                int enabled = rs.getInt("Is_Enabled");
                if (rs.wasNull()) {
                    rule.setEnabled(null);
                } else {
                    rule.setEnabled(enabled);
                }
                java.sql.Timestamp updated = rs.getTimestamp("Updated_Time");
                rule.setUpdatedTime(updated == null ? null : updated.toLocalDateTime());
                rules.add(rule);
            }
        }
        return rules;
    }

    public void saveAlarmRule(AlarmRule rule) throws Exception {
        if (rule.getRuleId() == null) {
            String sql = "INSERT INTO Sys_Alarm_Rule (Alarm_Type, Alarm_Level, Threshold_Value, Threshold_Unit, " +
                    "Notify_Channel, Is_Enabled) VALUES (?, ?, ?, ?, ?, ?)";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, rule.getAlarmType());
                ps.setString(2, rule.getAlarmLevel());
                if (rule.getThresholdValue() == null) {
                    ps.setNull(3, java.sql.Types.DECIMAL);
                } else {
                    ps.setBigDecimal(3, rule.getThresholdValue());
                }
                ps.setString(4, rule.getThresholdUnit());
                ps.setString(5, rule.getNotifyChannel());
                ps.setInt(6, rule.getEnabled() == null ? 1 : rule.getEnabled());
                ps.executeUpdate();
            }
        } else {
            String sql = "UPDATE Sys_Alarm_Rule SET Alarm_Type = ?, Alarm_Level = ?, Threshold_Value = ?, " +
                    "Threshold_Unit = ?, Notify_Channel = ?, Is_Enabled = ?, Updated_Time = SYSDATETIME() " +
                    "WHERE Rule_ID = ?";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, rule.getAlarmType());
                ps.setString(2, rule.getAlarmLevel());
                if (rule.getThresholdValue() == null) {
                    ps.setNull(3, java.sql.Types.DECIMAL);
                } else {
                    ps.setBigDecimal(3, rule.getThresholdValue());
                }
                ps.setString(4, rule.getThresholdUnit());
                ps.setString(5, rule.getNotifyChannel());
                ps.setInt(6, rule.getEnabled() == null ? 1 : rule.getEnabled());
                ps.setLong(7, rule.getRuleId());
                ps.executeUpdate();
            }
        }
    }

    public void updateAlarmRuleStatus(Long ruleId, int enabled) throws Exception {
        String sql = "UPDATE Sys_Alarm_Rule SET Is_Enabled = ?, Updated_Time = SYSDATETIME() WHERE Rule_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, enabled);
            ps.setLong(2, ruleId);
            ps.executeUpdate();
        }
    }

    public List<PeakValleyConfig> listPeakValleyConfigs() throws Exception {
        String sql = "SELECT Config_ID, Time_Type, Start_Time, End_Time, Price_Rate " +
                "FROM Config_PeakValley ORDER BY Start_Time";
        List<PeakValleyConfig> configs = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                PeakValleyConfig config = new PeakValleyConfig();
                config.setConfigId(rs.getLong("Config_ID"));
                config.setTimeType(rs.getString("Time_Type"));
                Time start = rs.getTime("Start_Time");
                Time end = rs.getTime("End_Time");
                config.setStartTime(start == null ? null : start.toLocalTime());
                config.setEndTime(end == null ? null : end.toLocalTime());
                config.setPriceRate(rs.getBigDecimal("Price_Rate"));
                configs.add(config);
            }
        }
        return configs;
    }

    public void savePeakValleyConfig(PeakValleyConfig config) throws Exception {
        String sql = "INSERT INTO Config_PeakValley (Time_Type, Start_Time, End_Time, Price_Rate) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, config.getTimeType());
            ps.setTime(2, config.getStartTime() == null ? null : Time.valueOf(config.getStartTime()));
            ps.setTime(3, config.getEndTime() == null ? null : Time.valueOf(config.getEndTime()));
            if (config.getPriceRate() == null) {
                ps.setNull(4, java.sql.Types.DECIMAL);
            } else {
                ps.setBigDecimal(4, config.getPriceRate());
            }
            ps.executeUpdate();
        }
    }

    public List<BackupLog> listBackupLogs() throws Exception {
        String sql = "SELECT Backup_ID, Backup_Type, Backup_Path, Status, Operator_ID, Start_Time, End_Time, Remark " +
                "FROM Sys_Backup_Log ORDER BY Start_Time DESC";
        List<BackupLog> logs = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BackupLog log = new BackupLog();
                log.setBackupId(rs.getLong("Backup_ID"));
                log.setBackupType(rs.getString("Backup_Type"));
                log.setBackupPath(rs.getString("Backup_Path"));
                log.setStatus(rs.getString("Status"));
                long operatorId = rs.getLong("Operator_ID");
                if (rs.wasNull()) {
                    log.setOperatorId(null);
                } else {
                    log.setOperatorId(operatorId);
                }
                java.sql.Timestamp start = rs.getTimestamp("Start_Time");
                java.sql.Timestamp end = rs.getTimestamp("End_Time");
                log.setStartTime(start == null ? null : start.toLocalDateTime());
                log.setEndTime(end == null ? null : end.toLocalDateTime());
                log.setRemark(rs.getString("Remark"));
                logs.add(log);
            }
        }
        return logs;
    }

    public void insertBackupLog(BackupLog log) throws Exception {
        String sql = "INSERT INTO Sys_Backup_Log (Backup_Type, Backup_Path, Status, Operator_ID, Start_Time, End_Time, Remark) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, log.getBackupType());
            ps.setString(2, log.getBackupPath());
            ps.setString(3, log.getStatus());
            if (log.getOperatorId() == null) {
                ps.setNull(4, java.sql.Types.BIGINT);
            } else {
                ps.setLong(4, log.getOperatorId());
            }
            if (log.getStartTime() == null) {
                ps.setNull(5, java.sql.Types.TIMESTAMP);
            } else {
                ps.setTimestamp(5, java.sql.Timestamp.valueOf(log.getStartTime()));
            }
            if (log.getEndTime() == null) {
                ps.setNull(6, java.sql.Types.TIMESTAMP);
            } else {
                ps.setTimestamp(6, java.sql.Timestamp.valueOf(log.getEndTime()));
            }
            ps.setString(7, log.getRemark());
            ps.executeUpdate();
        }
    }

    /**
     * 执行全量备份。仅用于演示，不处理复杂权限与路径校验。
     */
    public void executeFullBackup(String backupPath) throws Exception {
        if (backupPath == null || backupPath.trim().isEmpty()) {
            throw new IllegalArgumentException("备份文件路径不能为空");
        }
        String sql = "BACKUP DATABASE SQL_BFU TO DISK = ? WITH INIT";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, backupPath.trim());
            ps.executeUpdate();
        }
    }

    /**
     * 执行增量（差异）备份。
     */
    public void executeDiffBackup(String backupPath) throws Exception {
        if (backupPath == null || backupPath.trim().isEmpty()) {
            throw new IllegalArgumentException("备份文件路径不能为空");
        }
        String sql = "BACKUP DATABASE SQL_BFU TO DISK = ? WITH DIFFERENTIAL, INIT";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, backupPath.trim());
            ps.executeUpdate();
        }
    }

    /**
     * 对备份文件做恢复校验（不真正恢复数据库）。
     */
    public void executeRestoreVerify(String backupPath) throws Exception {
        if (backupPath == null || backupPath.trim().isEmpty()) {
            throw new IllegalArgumentException("备份文件路径不能为空");
        }
        String sql = "RESTORE VERIFYONLY FROM DISK = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, backupPath.trim());
            ps.execute();
        }
    }

    public List<AdminAuditLog> listAuditLogs() throws Exception {
        String sql = "SELECT Log_ID, Action_Type, Action_Detail, Operator_ID, Action_Time " +
                "FROM Sys_Admin_Audit_Log ORDER BY Action_Time DESC";
        List<AdminAuditLog> logs = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                AdminAuditLog log = new AdminAuditLog();
                log.setLogId(rs.getLong("Log_ID"));
                log.setActionType(rs.getString("Action_Type"));
                log.setActionDetail(rs.getString("Action_Detail"));
                long operatorId = rs.getLong("Operator_ID");
                if (rs.wasNull()) {
                    log.setOperatorId(null);
                } else {
                    log.setOperatorId(operatorId);
                }
                java.sql.Timestamp actionTime = rs.getTimestamp("Action_Time");
                log.setActionTime(actionTime == null ? null : actionTime.toLocalDateTime());
                logs.add(log);
            }
        }
        return logs;
    }

    public void insertAuditLog(AdminAuditLog log) throws Exception {
        String sql = "INSERT INTO Sys_Admin_Audit_Log (Action_Type, Action_Detail, Operator_ID, Action_Time) " +
                "VALUES (?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, log.getActionType());
            ps.setString(2, log.getActionDetail());
            if (log.getOperatorId() == null) {
                ps.setNull(3, java.sql.Types.BIGINT);
            } else {
                ps.setLong(3, log.getOperatorId());
            }
            LocalDateTime actionTime = log.getActionTime() == null ? LocalDateTime.now() : log.getActionTime();
            ps.setTimestamp(4, java.sql.Timestamp.valueOf(actionTime));
            ps.executeUpdate();
        }
    }

    public Map<String, Integer> loadSystemCounters() throws Exception {
        Map<String, Integer> result = new LinkedHashMap<>();
        result.put("userCount", queryCount("SELECT COUNT(1) FROM Sys_User"));
        result.put("roleCount", queryCount("SELECT COUNT(DISTINCT Role_Type) FROM Sys_Role_Assignment"));
        result.put("permissionCount", queryCount("SELECT COUNT(1) FROM Sys_Permission"));
        result.put("alarmRuleCount", queryCount("SELECT COUNT(1) FROM Sys_Alarm_Rule"));
        result.put("backupCount", queryCount("SELECT COUNT(1) FROM Sys_Backup_Log"));
        return result;
    }

    public String findLatestBackupTime() throws Exception {
        String sql = "SELECT TOP 1 Start_Time FROM Sys_Backup_Log ORDER BY Start_Time DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                java.sql.Timestamp ts = rs.getTimestamp("Start_Time");
                return ts == null ? "-" : ts.toLocalDateTime().toString().replace('T', ' ');
            }
        }
        return "-";
    }

    public long measureDbLatencyMs() throws Exception {
        long start = System.nanoTime();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT 1");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rs.getInt(1);
            }
        }
        return Math.max(1, (System.nanoTime() - start) / 1_000_000);
    }

    /**
     * 简单估算接口可用率：当前应用能够正常访问数据库则认为 99.90%，否则为 0。
     * 在课程设计场景下用于给管理台提供一个“真实来源”的监控指标。
     */
    public double loadApiAvailability() {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT 1");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return 99.90d;
            }
        } catch (Exception e) {
            return 0.0d;
        }
        return 0.0d;
    }

    /**
     * 查询当前数据库占用的空间，并按一个预设总容量（1 TB）估算磁盘占用率。
     * 实际项目中可以改为接入运维监控系统或读取真实磁盘容量。
     */
    public Map<String, Double> queryDiskUsage() throws Exception {
        double usedMb = 0.0d;
        String sql = "SELECT SUM(size) * 8.0 / 1024.0 AS DbSizeMB FROM sys.database_files";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                usedMb = rs.getDouble("DbSizeMB");
            }
        }
        if (usedMb < 0) {
            usedMb = 0.0d;
        }
        // 这里假设总容量为 1 TB（1024 * 1024 MB），仅用于展示
        double totalMb = 1024.0d * 1024.0d;
        double usedGb = usedMb / 1024.0d;
        double totalGb = totalMb / 1024.0d;
        double percent = totalMb > 0 ? Math.min(100.0d, (usedMb / totalMb) * 100.0d) : 0.0d;

        Map<String, Double> result = new LinkedHashMap<>();
        result.put("usedGb", usedGb);
        result.put("totalGb", totalGb);
        result.put("percent", percent);
        return result;
    }

    private int queryCount(String sql) throws Exception {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        }
        return 0;
    }
}
