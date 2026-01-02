package com.bfu.energy.servlet;

import com.bfu.energy.dao.UserDAO;
import com.bfu.energy.dao.RoleDAO;
import com.bfu.energy.dao.AlarmRuleDAO;
import com.bfu.energy.entity.User;
import com.bfu.energy.entity.Role;
import com.bfu.energy.entity.AlarmRule;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;

// TODO: 暂时禁用，缺少 UserDAO, RoleDAO, AlarmRuleDAO 类
// @WebServlet("/api/admin/*")
public class SystemAdminDataServlet extends HttpServlet {
    private Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create();
    private UserDAO userDAO = new UserDAO();
    private RoleDAO roleDAO = new RoleDAO();
    private AlarmRuleDAO alarmRuleDAO = new AlarmRuleDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            if ("/users".equals(pathInfo)) {
                handleGetUsers(request, response);
            } else if ("/roles".equals(pathInfo)) {
                handleGetRoles(request, response);
            } else if ("/alarm-rules".equals(pathInfo)) {
                handleGetAlarmRules(request, response);
            } else if ("/params".equals(pathInfo)) {
                handleGetParams(request, response);
            } else if ("/backup-history".equals(pathInfo)) {
                handleGetBackupHistory(request, response);
            } else if ("/db-monitor".equals(pathInfo)) {
                handleGetDBMonitor(request, response);
            } else if ("/stats".equals(pathInfo)) {
                handleGetStats(request, response);
            } else {
                sendErrorResponse(response, "Invalid endpoint", HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendErrorResponse(response, "Server error: " + e.getMessage(), HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            if ("/users".equals(pathInfo)) {
                handleCreateUser(request, response);
            } else if ("/roles".equals(pathInfo)) {
                handleCreateRole(request, response);
            } else if ("/alarm-rules".equals(pathInfo)) {
                handleCreateAlarmRule(request, response);
            } else if ("/params".equals(pathInfo)) {
                handleSaveParams(request, response);
            } else if ("/backup".equals(pathInfo)) {
                handleBackup(request, response);
            } else if ("/restore".equals(pathInfo)) {
                handleRestore(request, response);
            } else {
                sendErrorResponse(response, "Invalid endpoint", HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendErrorResponse(response, "Server error: " + e.getMessage(), HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            if (pathInfo != null && pathInfo.startsWith("/users/")) {
                handleUpdateUser(request, response);
            } else if (pathInfo != null && pathInfo.startsWith("/roles/")) {
                handleUpdateRole(request, response);
            } else if (pathInfo != null && pathInfo.startsWith("/alarm-rules/")) {
                handleUpdateAlarmRule(request, response);
            } else {
                sendErrorResponse(response, "Invalid endpoint", HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendErrorResponse(response, "Server error: " + e.getMessage(), HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            if (pathInfo != null && pathInfo.startsWith("/users/")) {
                handleDeleteUser(request, response);
            } else if (pathInfo != null && pathInfo.startsWith("/roles/")) {
                handleDeleteRole(request, response);
            } else if (pathInfo != null && pathInfo.startsWith("/alarm-rules/")) {
                handleDeleteAlarmRule(request, response);
            } else {
                sendErrorResponse(response, "Invalid endpoint", HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendErrorResponse(response, "Server error: " + e.getMessage(), HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private void handleGetUsers(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String search = request.getParameter("search");
        String role = request.getParameter("role");
        String status = request.getParameter("status");
        int page = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
        int pageSize = Integer.parseInt(request.getParameter("pageSize") != null ? request.getParameter("pageSize") : "10");

        List<User> users = userDAO.getUsers(search, role, status, page, pageSize);
        int total = userDAO.getTotalUsers(search, role, status);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("users", users);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);

        sendSuccessResponse(response, result);
    }

    private void handleCreateUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        User user = new User();
        user.setEmployeeId((String) data.get("employeeId"));
        user.setUsername((String) data.get("username"));
        user.setPassword((String) data.get("password"));
        user.setName((String) data.get("name"));
        user.setRole((String) data.get("role"));
        user.setResponsibleArea((String) data.get("responsibleArea"));
        user.setEmail((String) data.get("email"));
        user.setPhone((String) data.get("phone"));
        user.setStatus((String) data.getOrDefault("status", "active"));

        boolean success = userDAO.createUser(user);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "用户创建成功" : "用户创建失败");

        sendSuccessResponse(response, result);
    }

    private void handleUpdateUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String userId = request.getPathInfo().substring("/users/".length());

        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        User user = userDAO.getUserById(userId);
        if (user != null) {
            user.setName((String) data.get("name"));
            user.setRole((String) data.get("role"));
            user.setResponsibleArea((String) data.get("responsibleArea"));
            user.setEmail((String) data.get("email"));
            user.setPhone((String) data.get("phone"));
            user.setStatus((String) data.get("status"));

            boolean success = userDAO.updateUser(user);

            Map<String, Object> result = new HashMap<>();
            result.put("success", success);
            result.put("message", success ? "用户更新成功" : "用户更新失败");

            sendSuccessResponse(response, result);
        } else {
            sendErrorResponse(response, "用户不存在", HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleDeleteUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String userId = request.getPathInfo().substring("/users/".length());

        boolean success = userDAO.deleteUser(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "用户删除成功" : "用户删除失败");

        sendSuccessResponse(response, result);
    }

    private void handleGetRoles(HttpServletRequest request, HttpServletResponse response) throws IOException {
        List<Role> roles = roleDAO.getAllRoles();

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("roles", roles);

        sendSuccessResponse(response, result);
    }

    private void handleCreateRole(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        Role role = new Role();
        role.setRoleCode((String) data.get("roleCode"));
        role.setRoleName((String) data.get("roleName"));
        role.setPermissionLevel((Integer) data.get("permissionLevel"));
        role.setDescription((String) data.get("description"));
        role.setPermissions((List<String>) data.get("permissions"));

        boolean success = roleDAO.createRole(role);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "角色创建成功" : "角色创建失败");

        sendSuccessResponse(response, result);
    }

    private void handleUpdateRole(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String roleId = request.getPathInfo().substring("/roles/".length());

        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        Role role = roleDAO.getRoleById(roleId);
        if (role != null) {
            role.setRoleName((String) data.get("roleName"));
            role.setPermissionLevel((Integer) data.get("permissionLevel"));
            role.setDescription((String) data.get("description"));
            role.setPermissions((List<String>) data.get("permissions"));

            boolean success = roleDAO.updateRole(role);

            Map<String, Object> result = new HashMap<>();
            result.put("success", success);
            result.put("message", success ? "角色更新成功" : "角色更新失败");

            sendSuccessResponse(response, result);
        } else {
            sendErrorResponse(response, "角色不存在", HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleDeleteRole(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String roleId = request.getPathInfo().substring("/roles/".length());

        boolean success = roleDAO.deleteRole(roleId);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "角色删除成功" : "角色删除失败");

        sendSuccessResponse(response, result);
    }

    private void handleGetAlarmRules(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String search = request.getParameter("search");
        String level = request.getParameter("level");
        String status = request.getParameter("status");
        int page = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
        int pageSize = Integer.parseInt(request.getParameter("pageSize") != null ? request.getParameter("pageSize") : "10");

        List<AlarmRule> rules = alarmRuleDAO.getAlarmRules(search, level, status, page, pageSize);
        int total = alarmRuleDAO.getTotalAlarmRules(search, level, status);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("rules", rules);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);

        sendSuccessResponse(response, result);
    }

    private void handleCreateAlarmRule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        AlarmRule rule = new AlarmRule();
        rule.setRuleName((String) data.get("ruleName"));
        rule.setDeviceType((String) data.get("deviceType"));
        rule.setMetric((String) data.get("metric"));
        rule.setCondition((String) data.get("condition"));
        rule.setThreshold((Double) data.get("threshold"));
        rule.setUnit((String) data.get("unit"));
        rule.setLevel((String) data.get("level"));
        rule.setNotifications((List<String>) data.get("notifications"));
        rule.setStatus((String) data.getOrDefault("status", "active"));
        rule.setDescription((String) data.get("description"));

        boolean success = alarmRuleDAO.createAlarmRule(rule);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "告警规则创建成功" : "告警规则创建失败");

        sendSuccessResponse(response, result);
    }

    private void handleUpdateAlarmRule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String ruleId = request.getPathInfo().substring("/alarm-rules/".length());

        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        AlarmRule rule = alarmRuleDAO.getAlarmRuleById(ruleId);
        if (rule != null) {
            rule.setRuleName((String) data.get("ruleName"));
            rule.setDeviceType((String) data.get("deviceType"));
            rule.setMetric((String) data.get("metric"));
            rule.setCondition((String) data.get("condition"));
            rule.setThreshold((Double) data.get("threshold"));
            rule.setUnit((String) data.get("unit"));
            rule.setLevel((String) data.get("level"));
            rule.setNotifications((List<String>) data.get("notifications"));
            rule.setStatus((String) data.get("status"));
            rule.setDescription((String) data.get("description"));

            boolean success = alarmRuleDAO.updateAlarmRule(rule);

            Map<String, Object> result = new HashMap<>();
            result.put("success", success);
            result.put("message", success ? "告警规则更新成功" : "告警规则更新失败");

            sendSuccessResponse(response, result);
        } else {
            sendErrorResponse(response, "告警规则不存在", HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleDeleteAlarmRule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String ruleId = request.getPathInfo().substring("/alarm-rules/".length());

        boolean success = alarmRuleDAO.deleteAlarmRule(ruleId);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "告警规则删除成功" : "告警规则删除失败");

        sendSuccessResponse(response, result);
    }

    private void handleGetParams(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String category = request.getParameter("category");
        Map<String, Object> params = getParamsByCategory(category);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("params", params);

        sendSuccessResponse(response, result);
    }

    private void handleSaveParams(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);

        boolean success = saveParams(data);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "参数保存成功" : "参数保存失败");

        sendSuccessResponse(response, result);
    }

    private void handleGetBackupHistory(HttpServletRequest request, HttpServletResponse response) throws IOException {
        List<Map<String, Object>> history = getBackupHistory();

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("history", history);

        sendSuccessResponse(response, result);
    }

    private void handleGetDBMonitor(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Map<String, Object> monitor = getDBMonitorData();

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("monitor", monitor);

        sendSuccessResponse(response, result);
    }

    private void handleBackup(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BufferedReader reader = request.getReader();
        Map<String, Object> data = gson.fromJson(reader, Map.class);
        String type = (String) data.get("type");

        boolean success = performBackup(type);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "备份成功" : "备份失败");

        sendSuccessResponse(response, result);
    }

    private void handleRestore(HttpServletRequest request, HttpServletResponse response) throws IOException {
        boolean success = performRestore();

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", success ? "数据恢复成功" : "数据恢复失败");

        sendSuccessResponse(response, result);
    }

    private void handleGetStats(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Map<String, Object> stats = new HashMap<>();
        stats.put("userCount", userDAO.getTotalUsers(null, null, null));
        stats.put("roleCount", roleDAO.getAllRoles().size());
        stats.put("alarmRuleCount", alarmRuleDAO.getTotalAlarmRules(null, null, null));
        stats.put("activeAlarmRuleCount", alarmRuleDAO.getTotalAlarmRules(null, null, "active"));

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("stats", stats);

        sendSuccessResponse(response, result);
    }

    private Map<String, Object> getParamsByCategory(String category) {
        Map<String, Object> params = new HashMap<>();
        
        if ("time".equals(category)) {
            params.put("peak1Start", "08:00");
            params.put("peak1End", "12:00");
            params.put("peak2Start", "14:00");
            params.put("peak2End", "17:00");
            params.put("peak3Start", "19:00");
            params.put("peak3End", "21:00");
            params.put("valley1Start", "23:00");
            params.put("valley1End", "07:00");
            params.put("valley2Start", "12:00");
            params.put("valley2End", "14:00");
        } else if ("display".equals(category)) {
            params.put("dataRefreshRate", 5);
            params.put("alarmRefreshRate", 10);
            params.put("chartRefreshRate", 30);
            params.put("historyDays", 7);
            params.put("realtimeRetention", 24);
            params.put("alarmDisplayCount", 10);
            params.put("autoRefresh", true);
            params.put("animationEffect", true);
        } else if ("alarm".equals(category)) {
            params.put("highAlarmThreshold", 90);
            params.put("mediumAlarmThreshold", 75);
            params.put("lowAlarmThreshold", 60);
            params.put("alarmEscalationTime", 30);
            params.put("alarmNotifyInterval", 15);
            params.put("alarmHistoryDays", 90);
            params.put("emailNotify", true);
            params.put("smsNotify", false);
            params.put("systemNotify", true);
        } else if ("system".equals(category)) {
            params.put("dataCollectionRate", 1);
            params.put("batchSize", 1000);
            params.put("compressThreshold", 30);
            params.put("queryTimeout", 30);
            params.put("maxConnections", 50);
            params.put("cacheExpireTime", 300);
            params.put("minPasswordLength", 8);
            params.put("maxLoginAttempts", 5);
            params.put("lockoutDuration", 30);
        }
        
        return params;
    }

    private boolean saveParams(Map<String, Object> params) {
        return true;
    }

    private List<Map<String, Object>> getBackupHistory() {
        List<Map<String, Object>> history = new ArrayList<>();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        
        Map<String, Object> backup1 = new HashMap<>();
        backup1.put("backupTime", sdf.format(new Date(System.currentTimeMillis() - 3600000)));
        backup1.put("type", "incremental");
        backup1.put("size", "125.6 MB");
        backup1.put("status", "success");
        history.add(backup1);
        
        Map<String, Object> backup2 = new HashMap<>();
        backup2.put("backupTime", sdf.format(new Date(System.currentTimeMillis() - 86400000)));
        backup2.put("type", "full");
        backup2.put("size", "2.4 GB");
        backup2.put("status", "success");
        history.add(backup2);
        
        Map<String, Object> backup3 = new HashMap<>();
        backup3.put("backupTime", sdf.format(new Date(System.currentTimeMillis() - 172800000)));
        backup3.put("type", "incremental");
        backup3.put("size", "118.3 MB");
        backup3.put("status", "success");
        history.add(backup3);
        
        Map<String, Object> backup4 = new HashMap<>();
        backup4.put("backupTime", sdf.format(new Date(System.currentTimeMillis() - 259200000)));
        backup4.put("type", "full");
        backup4.put("size", "2.3 GB");
        backup4.put("status", "success");
        history.add(backup4);
        
        return history;
    }

    private Map<String, Object> getDBMonitorData() {
        Map<String, Object> monitor = new HashMap<>();
        Random random = new Random();
        
        monitor.put("dbSize", "2.5 GB");
        monitor.put("dbSizeChange", "+0.1 GB");
        
        int diskUsagePercent = 65 + random.nextInt(15);
        monitor.put("diskUsage", diskUsagePercent + "%");
        monitor.put("diskUsageChange", "+2.3%");
        monitor.put("diskUsagePercent", diskUsagePercent + "%");
        monitor.put("diskUsageStatus", diskUsagePercent > 80 ? "danger" : (diskUsagePercent > 70 ? "warning" : ""));
        
        int queryTime = 20 + random.nextInt(30);
        monitor.put("queryTime", queryTime + " ms");
        monitor.put("queryTimeChange", queryTime > 40 ? "+5 ms" : "-3 ms");
        
        monitor.put("connectionCount", "32");
        monitor.put("maxConnections", "50");
        
        monitor.put("activeQueryCount", "8");
        
        int cacheHitRate = 85 + random.nextInt(10);
        monitor.put("cacheHitRate", cacheHitRate + "%");
        
        monitor.put("transactionSuccessRate", "99.8%");
        
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        monitor.put("lastBackup", sdf.format(new Date(System.currentTimeMillis() - 3600000)));
        
        return monitor;
    }

    private boolean performBackup(String type) {
        return true;
    }

    private boolean performRestore() {
        return true;
    }

    private void sendSuccessResponse(HttpServletResponse response, Object data) throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        PrintWriter out = response.getWriter();
        out.print(gson.toJson(data));
        out.flush();
    }

    private void sendErrorResponse(HttpServletResponse response, String message, int statusCode) throws IOException {
        response.setStatus(statusCode);
        PrintWriter out = response.getWriter();
        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("message", message);
        out.print(gson.toJson(error));
        out.flush();
    }
}
