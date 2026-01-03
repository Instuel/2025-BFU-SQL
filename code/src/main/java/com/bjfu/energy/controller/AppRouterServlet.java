package com.bjfu.energy.controller;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 简单路由控制器：
 *  /app?module=dashboard|dist|pv|energy|alarm|admin
 *  仅负责转发到对应的 JSP 占位页
 */
public class AppRouterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String module = req.getParameter("module");
        if (module == null || module.trim().isEmpty()) {
            module = "dashboard";
        }

        String jsp;
        switch (module) {
            case "dashboard":
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
            case "dist":
                jsp = "/WEB-INF/jsp/dist/room_list.jsp";
                break;
            case "pv":
                jsp = "/WEB-INF/jsp/pv/device_list.jsp";
                break;
            case "energy":
                jsp = "/WEB-INF/jsp/energy/meter_list.jsp";
                break;
            case "alarm":
                jsp = "/WEB-INF/jsp/alarm/alarm_list.jsp";
                break;
            case "admin":
                jsp = "/WEB-INF/jsp/admin/user_list.jsp";
                break;
            default:
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
        }

        req.getRequestDispatcher(jsp).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }
}
