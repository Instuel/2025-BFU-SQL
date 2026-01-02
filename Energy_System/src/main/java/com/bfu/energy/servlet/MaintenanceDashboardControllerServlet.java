package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/maintenance/*")
public class MaintenanceDashboardControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/dashboard")) {
            req.getRequestDispatcher("/WEB-INF/views/maintenance_personnel_main.jsp").forward(req, resp);
        } else if (pathInfo.equals("/devices")) {
            req.getRequestDispatcher("/WEB-INF/views/device_ledger_view.jsp").forward(req, resp);
        } else if (pathInfo.equals("/work-orders")) {
            req.getRequestDispatcher("/WEB-INF/views/work_order_handle.jsp").forward(req, resp);
        } else if (pathInfo.equals("/plans")) {
            req.getRequestDispatcher("/WEB-INF/views/maintenance_plan.jsp").forward(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "页面不存在");
        }
    }
}
