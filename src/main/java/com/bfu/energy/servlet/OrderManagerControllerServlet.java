package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/order-manager/*")
public class OrderManagerControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/workspace")) {
            req.getRequestDispatcher("/WEB-INF/views/order_manager_workspace.jsp").forward(req, resp);
        } else if (pathInfo.equals("/alarm-review")) {
            req.getRequestDispatcher("/WEB-INF/views/alarm_review_dispatch.jsp").forward(req, resp);
        } else if (pathInfo.equals("/order-review")) {
            req.getRequestDispatcher("/WEB-INF/views/order_review_close.jsp").forward(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "页面不存在");
        }
    }
}
