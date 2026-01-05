package com.bjfu.energy.controller;

import com.bjfu.energy.dao.ViewDao;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.RoleOandM;
import com.bjfu.energy.dao.RoleOandMDao;
import com.bjfu.energy.dao.RoleOandMDaoImpl;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class ViewServlet extends HttpServlet {

    private final ViewDao viewDao = new ViewDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        String jsp = "/WEB-INF/jsp/view/view_list.jsp";
        Long userFactoryId = null;
        String errorMessage = null;
        
        try {
            SysUser currentUser = (SysUser) req.getSession().getAttribute("currentUser");
            String roleType = (String) req.getSession().getAttribute("currentRoleType");
            
            if ("OM".equals(roleType) && currentUser != null) {
                RoleOandMDao roleOandMDao = new RoleOandMDaoImpl();
                RoleOandM oandm = roleOandMDao.findByUserId(currentUser.getUserId());
                if (oandm != null) {
                    userFactoryId = oandm.getFactoryId();
                }
            }
            
            req.setAttribute("userFactoryId", userFactoryId);
            
            switch (action) {
                case "list":
                    jsp = "/WEB-INF/jsp/view/view_list.jsp";
                    break;
                case "circuit_abnormal":
                    List<Map<String, Object>> circuitAbnormalList = viewDao.getCircuitAbnormalData(userFactoryId);
                    req.setAttribute("circuitAbnormalList", circuitAbnormalList);
                    req.setAttribute("viewTitle", "回路异常监测视图");
                    req.setAttribute("viewDescription", "筛选电压越界的回路异常记录，支持按厂区追溯");
                    req.setAttribute("debugInfo", "查询到 " + circuitAbnormalList.size() + " 条记录");
                    jsp = "/WEB-INF/jsp/view/circuit_abnormal.jsp";
                    break;
                case "data_integrity":
                    List<Map<String, Object>> dataIntegrityList = viewDao.getDataIntegrityData(userFactoryId);
                    req.setAttribute("dataIntegrityList", dataIntegrityList);
                    req.setAttribute("viewTitle", "配电网业务数据完整性校验视图");
                    req.setAttribute("viewDescription", "校验回路和变压器关键数据的完整性");
                    req.setAttribute("debugInfo", "查询到 " + dataIntegrityList.size() + " 条记录");
                    jsp = "/WEB-INF/jsp/view/data_integrity.jsp";
                    break;
                case "peakvalley_stats":
                    String statDate = req.getParameter("statDate");
                    List<Map<String, Object>> peakValleyList = viewDao.getPeakValleyStatsData(userFactoryId, statDate);
                    req.setAttribute("peakValleyList", peakValleyList);
                    req.setAttribute("statDate", statDate);
                    req.setAttribute("viewTitle", "每日分时电价统计视图");
                    req.setAttribute("viewDescription", "按厂区+配电房+峰谷时段统计用电量");
                    req.setAttribute("debugInfo", "查询到 " + peakValleyList.size() + " 条记录");
                    jsp = "/WEB-INF/jsp/view/peakvalley_stats.jsp";
                    break;
                case "realtime_data":
                    List<Map<String, Object>> realtimeDataList = viewDao.getRealtimeDeviceData(userFactoryId);
                    req.setAttribute("realtimeDataList", realtimeDataList);
                    req.setAttribute("viewTitle", "实时回路和变压器数据采集视图");
                    req.setAttribute("viewDescription", "获取变压器和回路的最新一条数据");
                    req.setAttribute("debugInfo", "查询到 " + realtimeDataList.size() + " 条记录");
                    jsp = "/WEB-INF/jsp/view/realtime_data.jsp";
                    break;
                case "equipment_status":
                    List<Map<String, Object>> equipmentStatusList = viewDao.getEquipmentStatusData(userFactoryId);
                    req.setAttribute("equipmentStatusList", equipmentStatusList);
                    req.setAttribute("viewTitle", "配电房设备健康状态概览视图");
                    req.setAttribute("viewDescription", "从配电房维度，汇总设备运行状态全貌");
                    req.setAttribute("debugInfo", "查询到 " + equipmentStatusList.size() + " 条记录");
                    jsp = "/WEB-INF/jsp/view/equipment_status.jsp";
                    break;
                default:
                    jsp = "/WEB-INF/jsp/view/view_list.jsp";
                    break;
            }
        } catch (Exception e) {
            errorMessage = "业务视图数据加载失败: " + e.getMessage();
            req.setAttribute("error", errorMessage);
            req.setAttribute("errorDetail", e.toString());
            e.printStackTrace();
        }
        
        req.getRequestDispatcher(jsp).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }
}
