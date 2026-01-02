package com.bfu.energy.servlet;

import com.bfu.energy.dao.SysRoleAssignmentDAO;
import com.bfu.energy.dao.SysUserDAO;
import com.bfu.energy.entity.SysRoleAssignment;
import com.bfu.energy.entity.SysUser;
import com.bfu.energy.exception.BusinessException;
import com.bfu.energy.util.DAOFactory;
import com.bfu.energy.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String loginAccount = req.getParameter("loginAccount");
        String password = req.getParameter("password");

        try {
            SysUserDAO userDAO = DAOFactory.getDAO(SysUserDAO.class);
            SysUser user = userDAO.findByLoginAccount(loginAccount);

            if (user == null) {
                throw new BusinessException("LOGIN_ERROR", "用户不存在");
            }

            if (user.getAccountStatus() == 0) {
                throw new BusinessException("LOGIN_ERROR", "账号已被禁用");
            }

            if (!PasswordUtil.verifyPassword(password, user.getSalt(), user.getLoginPassword())) {
                throw new BusinessException("LOGIN_ERROR", "密码错误");
            }

            HttpSession session = req.getSession();
            session.setAttribute("user", user);
            session.setAttribute("userId", user.getUserId());
            session.setAttribute("realName", user.getRealName());

            SysRoleAssignmentDAO roleAssignmentDAO = DAOFactory.getDAO(SysRoleAssignmentDAO.class);
            List<SysRoleAssignment> roles = roleAssignmentDAO.findByUserId(user.getUserId());

            if (roles.isEmpty()) {
                session.setAttribute("role", "USER");
                resp.sendRedirect(req.getContextPath() + "/dashboard");
            } else {
                String primaryRole = roles.get(0).getRoleType();
                session.setAttribute("role", primaryRole);
                session.setAttribute("roles", roles);

                String redirectUrl = getRedirectUrlByRole(primaryRole);
                resp.sendRedirect(req.getContextPath() + redirectUrl);
            }

        } catch (BusinessException e) {
            req.setAttribute("error", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
        }
    }

    private String getRedirectUrlByRole(String roleType) {
        switch (roleType) {
            case "ADMIN":
                return "/admin/dashboard";
            case "OM":
                return "/maintenance/dashboard";  // 运维人员 -> 维护工作台
            case "ENERGY":
                return "/energy/dashboard";
            case "ANALYST":
                return "/analysis/dashboard";  // 数据分析师 -> 分析师工作台
            case "EXEC":
                return "/executive/dashboard";  // 企业管理层
            default:
                return "/";
        }
    }
}
