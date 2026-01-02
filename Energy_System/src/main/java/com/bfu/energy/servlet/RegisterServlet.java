package com.bfu.energy.servlet;

import com.bfu.energy.dao.SysUserDAO;
import com.bfu.energy.entity.SysUser;
import com.bfu.energy.util.DAOFactory;
import com.bfu.energy.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String loginAccount = req.getParameter("loginAccount");
        String password = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");
        String realName = req.getParameter("realName");
        String department = req.getParameter("department");
        String contactPhone = req.getParameter("contactPhone");

        try {
            if (!password.equals(confirmPassword)) {
                throw new Exception("两次密码输入不一致");
            }

            SysUserDAO userDAO = DAOFactory.getDAO(SysUserDAO.class);
            SysUser existingUser = userDAO.findByLoginAccount(loginAccount);
            if (existingUser != null) {
                throw new Exception("登录账号已存在");
            }

            String salt = PasswordUtil.generateSalt();
            String encryptedPassword = PasswordUtil.encryptPassword(password, salt);

            SysUser user = new SysUser();
            user.setLoginAccount(loginAccount);
            user.setLoginPassword(encryptedPassword);
            user.setSalt(salt);
            user.setRealName(realName);
            user.setDepartment(department);
            user.setContactPhone(contactPhone);
            user.setAccountStatus(1);

            userDAO.insert(user);

            resp.sendRedirect(req.getContextPath() + "/login?success=注册成功，请登录");

        } catch (Exception e) {
            req.setAttribute("error", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/views/register.jsp").forward(req, resp);
        }
    }
}
