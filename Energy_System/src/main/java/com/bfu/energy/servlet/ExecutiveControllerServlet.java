package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/executive/*")
public class ExecutiveControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/dashboard")) {
            req.getRequestDispatcher("/WEB-INF/views/management_dashboard.jsp").forward(req, resp);
        } else if (pathInfo.equals("/overview")) {
            req.getRequestDispatcher("/WEB-INF/views/executive_overview.jsp").forward(req, resp);
        } else if (pathInfo.equals("/report")) {
            req.getRequestDispatcher("/WEB-INF/views/energy_consumption_report.jsp").forward(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "页面不存在");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "无效的请求");
            return;
        }
        
        resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "不支持的请求方法");
    }
}