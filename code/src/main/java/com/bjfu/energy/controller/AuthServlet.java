package com.bjfu.energy.controller;

import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.service.AuthService;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * 处理登录 / 登出 / 注册：
 *  /auth?action=loginPage
 *  /auth?action=login
 *  /auth?action=logout
 *  /auth?action=registerPage
 *  /auth?action=register
 */
public class AuthServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "loginPage";
        }

        switch (action) {
            case "loginPage":
                req.getRequestDispatcher("/WEB-INF/jsp/auth/login.jsp").forward(req, resp);
                break;
            case "registerPage":
                req.getRequestDispatcher("/WEB-INF/jsp/auth/register.jsp").forward(req, resp);
                break;
            case "logout":
                HttpSession session = req.getSession(false);
                if (session != null) {
                    session.invalidate();
                }
                resp.sendRedirect(req.getContextPath() + "/auth?action=loginPage");
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if ("login".equals(action)) {
            handleLogin(req, resp);
        } else if ("register".equals(action)) {
            handleRegister(req, resp);
        } else {
            doGet(req, resp);
        }
    }

    private void handleLogin(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String loginAccount = req.getParameter("loginAccount");
        String loginPassword = req.getParameter("loginPassword");

        try {
            SysUser user = authService.login(loginAccount, loginPassword);
            if (user == null) {
                req.setAttribute("error", "账号或密码错误，或账号已被禁用。");
                req.getRequestDispatcher("/WEB-INF/jsp/auth/login.jsp").forward(req, resp);
                return;
            }

            HttpSession session = req.getSession();
            session.setAttribute("currentUser", user);

            String roleType = authService.getRoleType(user.getUserId());
            if (roleType == null) {
                roleType = "GUEST";
            }
            session.setAttribute("currentRoleType", roleType);

            resp.sendRedirect(req.getContextPath() + "/app?module=dashboard");
        } catch (Exception e) {
            throw new ServletException("登录失败: " + e.getMessage(), e);
        }
    }

    private void handleRegister(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            SysUser u = new SysUser();
            u.setLoginAccount(req.getParameter("loginAccount"));
            u.setRealName(req.getParameter("realName"));
            u.setDepartment(req.getParameter("department"));
            u.setContactPhone(req.getParameter("contactPhone"));
            String rawPassword = req.getParameter("loginPassword");

            authService.register(u, rawPassword);
            resp.sendRedirect(req.getContextPath() + "/auth?action=loginPage");
        } catch (Exception e) {
            throw new ServletException("注册失败: " + e.getMessage(), e);
        }
    }
}
