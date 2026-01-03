package com.bjfu.energy.controller;

import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.service.AdminService;
import com.bjfu.energy.service.UserService;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 系统管理员入口：账号管理（增删改查、禁用/启用、重置密码）
 *  /admin?action=list
 *  /admin?action=detail&id=1
 *  /admin?action=create
 */
public class AdminServlet extends HttpServlet {

    private final UserService userService = new UserService();
    private final AdminService adminService = new AdminService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        try {
            switch (action) {
                case "list":
                    handleList(req, resp);
                    break;
                case "detail":
                    handleDetail(req, resp, false);
                    break;
                case "create":
                    handleDetail(req, resp, true);
                    break;
                case "role_assign":
                    handleRoleAssign(req, resp);
                    break;
                case "permission_list":
                    handlePermissionList(req, resp);
                    break;
                case "alarm_rule":
                    handleAlarmRule(req, resp);
                    break;
                case "peak_valley":
                    handlePeakValley(req, resp);
                    break;
                case "backup_restore":
                    handleBackupRestore(req, resp);
                    break;
                case "system_status":
                    handleSystemStatus(req, resp);
                    break;
                case "audit_log":
                    handleAuditLog(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("管理员请求处理失败: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) {
            doGet(req, resp);
            return;
        }

        try {
            switch (action) {
                case "save":
                    handleSave(req, resp);
                    break;
                case "toggleStatus":
                    handleToggleStatus(req, resp);
                    break;
                case "resetPassword":
                    handleResetPassword(req, resp);
                    break;
                case "delete":
                    handleDelete(req, resp);
                    break;
                case "saveRoleAssignment":
                    handleSaveRoleAssignment(req, resp);
                    break;
                case "saveAlarmRule":
                    handleSaveAlarmRule(req, resp);
                    break;
                case "toggleAlarmRule":
                    handleToggleAlarmRule(req, resp);
                    break;
                case "savePeakValley":
                    handleSavePeakValley(req, resp);
                    break;
                case "saveBackupLog":
                    handleSaveBackupLog(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("管理员操作失败: " + e.getMessage(), e);
        }
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp) throws Exception, IOException, ServletException {
        List<SysUser> users = userService.listUsers();
        req.setAttribute("users", users);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/admin/user_list.jsp").forward(req, resp);
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, boolean create)
            throws Exception, IOException, ServletException {
        SysUser user = null;
        if (!create) {
            String idStr = req.getParameter("id");
            if (idStr != null && !idStr.trim().isEmpty()) {
                user = userService.getUser(Long.valueOf(idStr));
            }
        }
        req.setAttribute("user", user);
        req.setAttribute("createMode", create);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/user_detail.jsp").forward(req, resp);
    }

    private void handleRoleAssign(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("roleAssignments", adminService.listRoleAssignments());
        req.setAttribute("roleOptions", java.util.Arrays.asList(
                "ADMIN", "ENERGY", "OM", "ANALYST", "EXEC", "DISPATCHER"
        ));
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("error", req.getParameter("error"));
        req.getRequestDispatcher("/WEB-INF/jsp/admin/role_assign.jsp").forward(req, resp);
    }

    private void handlePermissionList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("permissions", adminService.listPermissions());
        req.getRequestDispatcher("/WEB-INF/jsp/admin/permission_list.jsp").forward(req, resp);
    }

    private void handleAlarmRule(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("alarmRules", adminService.listAlarmRules());
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("error", req.getParameter("error"));
        req.getRequestDispatcher("/WEB-INF/jsp/admin/alarm_rule.jsp").forward(req, resp);
    }

    private void handlePeakValley(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("peakValleyConfigs", adminService.listPeakValleyConfigs());
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("error", req.getParameter("error"));
        req.getRequestDispatcher("/WEB-INF/jsp/admin/peak_valley.jsp").forward(req, resp);
    }

    private void handleBackupRestore(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("backupLogs", adminService.listBackupLogs());
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("error", req.getParameter("error"));
        req.getRequestDispatcher("/WEB-INF/jsp/admin/backup_restore.jsp").forward(req, resp);
    }

    private void handleSystemStatus(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("systemCounters", adminService.loadSystemCounters());
        req.setAttribute("latestBackupTime", adminService.getLatestBackupTime());
        req.setAttribute("dbLatencyMs", adminService.getDbLatencyMs());
        req.getRequestDispatcher("/WEB-INF/jsp/admin/system_status.jsp").forward(req, resp);
    }

    private void handleAuditLog(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        req.setAttribute("auditLogs", adminService.listAuditLogs());
        req.getRequestDispatcher("/WEB-INF/jsp/admin/audit_log.jsp").forward(req, resp);
    }

    private void handleSave(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            String userId = req.getParameter("userId");
            String loginAccount = req.getParameter("loginAccount");
            String realName = req.getParameter("realName");
            String department = req.getParameter("department");
            String contactPhone = req.getParameter("contactPhone");
            String status = req.getParameter("accountStatus");
            String password = req.getParameter("newPassword");

            SysUser user = new SysUser();
            user.setLoginAccount(loginAccount);
            user.setRealName(realName);
            user.setDepartment(department);
            user.setContactPhone(contactPhone);
            if (status != null && !status.trim().isEmpty()) {
                user.setAccountStatus(Integer.parseInt(status));
            }

            if (userId == null || userId.trim().isEmpty()) {
                userService.createUser(user, password, operatorId);
                resp.sendRedirect(buildRedirect(req, "用户已创建"));
            } else {
                user.setUserId(Long.valueOf(userId));
                userService.updateUser(user, password, operatorId);
                resp.sendRedirect(buildRedirect(req, "用户已更新"));
            }
        } catch (Exception e) {
            req.setAttribute("error", e.getMessage());
            req.setAttribute("user", buildUserFromRequest(req));
            req.getRequestDispatcher("/WEB-INF/jsp/admin/user_detail.jsp").forward(req, resp);
        }
    }

    private SysUser buildUserFromRequest(HttpServletRequest req) {
        SysUser user = new SysUser();
        String userId = req.getParameter("userId");
        if (userId != null && !userId.trim().isEmpty()) {
            user.setUserId(Long.valueOf(userId));
        }
        user.setLoginAccount(req.getParameter("loginAccount"));
        user.setRealName(req.getParameter("realName"));
        user.setDepartment(req.getParameter("department"));
        user.setContactPhone(req.getParameter("contactPhone"));
        String status = req.getParameter("accountStatus");
        if (status != null && !status.trim().isEmpty()) {
            user.setAccountStatus(Integer.parseInt(status));
        }
        return user;
    }

    private void handleToggleStatus(HttpServletRequest req, HttpServletResponse resp) throws Exception, IOException {
        Long operatorId = getOperatorId(req.getSession(false));
        Long userId = Long.valueOf(req.getParameter("userId"));
        int status = Integer.parseInt(req.getParameter("status"));
        userService.updateStatus(userId, status, operatorId);
        resp.sendRedirect(buildRedirect(req, status == 1 ? "账号已启用" : "账号已禁用"));
    }

    private void handleResetPassword(HttpServletRequest req, HttpServletResponse resp) throws Exception, IOException {
        Long operatorId = getOperatorId(req.getSession(false));
        Long userId = Long.valueOf(req.getParameter("userId"));
        userService.resetPassword(userId, operatorId);
        resp.sendRedirect(buildRedirect(req, "密码已重置为 123456"));
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws Exception, IOException {
        Long userId = Long.valueOf(req.getParameter("userId"));
        userService.deleteUser(userId);
        resp.sendRedirect(buildRedirect(req, "用户已删除"));
    }

    private void handleSaveRoleAssignment(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            Long userId = Long.valueOf(req.getParameter("userId"));
            String roleType = req.getParameter("roleType");
            adminService.updateRoleAssignment(userId, roleType, operatorId);
            resp.sendRedirect(buildRedirect(req, "role_assign", "角色已更新"));
        } catch (Exception e) {
            resp.sendRedirect(buildRedirect(req, "role_assign", "更新失败: " + e.getMessage(), true));
        }
    }

    private void handleSaveAlarmRule(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            String ruleIdStr = req.getParameter("ruleId");
            Long ruleId = (ruleIdStr == null || ruleIdStr.trim().isEmpty()) ? null : Long.valueOf(ruleIdStr);
            adminService.saveAlarmRule(
                    ruleId,
                    req.getParameter("alarmType"),
                    req.getParameter("alarmLevel"),
                    req.getParameter("thresholdValue"),
                    req.getParameter("thresholdUnit"),
                    req.getParameter("notifyChannel"),
                    req.getParameter("enabled"),
                    operatorId
            );
            resp.sendRedirect(buildRedirect(req, "alarm_rule", "告警规则已保存"));
        } catch (Exception e) {
            resp.sendRedirect(buildRedirect(req, "alarm_rule", "保存失败: " + e.getMessage(), true));
        }
    }

    private void handleToggleAlarmRule(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            Long ruleId = Long.valueOf(req.getParameter("ruleId"));
            int enabled = Integer.parseInt(req.getParameter("enabled"));
            adminService.toggleAlarmRule(ruleId, enabled, operatorId);
            resp.sendRedirect(buildRedirect(req, "alarm_rule", "规则状态已更新"));
        } catch (Exception e) {
            resp.sendRedirect(buildRedirect(req, "alarm_rule", "更新失败: " + e.getMessage(), true));
        }
    }

    private void handleSavePeakValley(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            adminService.addPeakValleyConfig(
                    req.getParameter("timeType"),
                    req.getParameter("startTime"),
                    req.getParameter("endTime"),
                    req.getParameter("priceRate"),
                    operatorId
            );
            resp.sendRedirect(buildRedirect(req, "peak_valley", "峰谷配置已新增"));
        } catch (Exception e) {
            resp.sendRedirect(buildRedirect(req, "peak_valley", "保存失败: " + e.getMessage(), true));
        }
    }

    private void handleSaveBackupLog(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        try {
            Long operatorId = getOperatorId(req.getSession(false));
            adminService.createBackupLog(
                    req.getParameter("backupType"),
                    req.getParameter("backupPath"),
                    req.getParameter("status"),
                    req.getParameter("remark"),
                    operatorId
            );
            resp.sendRedirect(buildRedirect(req, "backup_restore", "备份记录已生成"));
        } catch (Exception e) {
            resp.sendRedirect(buildRedirect(req, "backup_restore", "保存失败: " + e.getMessage(), true));
        }
    }

    private Long getOperatorId(HttpSession session) {
        if (session == null) {
            return null;
        }
        Object userObj = session.getAttribute("currentUser");
        if (userObj instanceof SysUser) {
            return ((SysUser) userObj).getUserId();
        }
        return null;
    }

    private String buildRedirect(HttpServletRequest req, String message) {
    	String encoded;
    	try {
    	    encoded = URLEncoder.encode(message == null ? "" : message, StandardCharsets.UTF_8.name());
    	} catch (Exception e) {
    	    // 理论上不会发生，因为 UTF-8 必定存在
    	    encoded = "";
    	}
        return req.getContextPath() + "/admin?action=list&message=" + encoded;
    }

    private String buildRedirect(HttpServletRequest req, String action, String message) {
        return buildRedirect(req, action, message, false);
    }

    private String buildRedirect(HttpServletRequest req, String action, String message, boolean error) {
        String encoded;
        try {
            encoded = URLEncoder.encode(message == null ? "" : message, StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            encoded = "";
        }
        String key = error ? "error" : "message";
        return req.getContextPath() + "/admin?action=" + action + "&" + key + "=" + encoded;
    }
}
