package com.bjfu.energy.controller;

import com.bjfu.energy.entity.SysUser;
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
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8);
        return req.getContextPath() + "/admin?action=list&message=" + encoded;
    }
}
