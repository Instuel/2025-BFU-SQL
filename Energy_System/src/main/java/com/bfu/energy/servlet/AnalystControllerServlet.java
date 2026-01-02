package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/analysis/*")
public class AnalystControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/dashboard")) {
            req.getRequestDispatcher("/WEB-INF/views/analysis_workspace.jsp").forward(req, resp);
        } else if (pathInfo.equals("/pv-prediction")) {
            req.getRequestDispatcher("/WEB-INF/views/pv_prediction_optimization.jsp").forward(req, resp);
        } else if (pathInfo.equals("/energy-pattern")) {
            req.getRequestDispatcher("/WEB-INF/views/energy_consumption_pattern.jsp").forward(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "页面不存在");
        }
    }
}
