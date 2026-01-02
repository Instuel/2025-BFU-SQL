package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/admin/*")
public class SystemAdminControllerServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/dashboard")) {
            request.getRequestDispatcher("/WEB-INF/views/system_admin_main.jsp").forward(request, response);
        } else if (pathInfo.equals("/rbac")) {
            request.getRequestDispatcher("/WEB-INF/views/rbac_management.jsp").forward(request, response);
        } else if (pathInfo.equals("/alarm-rules")) {
            request.getRequestDispatcher("/WEB-INF/views/alarm_rule_config.jsp").forward(request, response);
        } else if (pathInfo.equals("/params")) {
            request.getRequestDispatcher("/WEB-INF/views/business_param_config.jsp").forward(request, response);
        } else if (pathInfo.equals("/db-maintenance")) {
            request.getRequestDispatcher("/WEB-INF/views/db_maintenance.jsp").forward(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }
}
