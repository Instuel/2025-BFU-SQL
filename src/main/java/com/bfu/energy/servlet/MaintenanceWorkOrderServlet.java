package com.bfu.energy.servlet;

import com.bfu.energy.dao.WorkOrderDAO;
import com.bfu.energy.dao.AlarmInfoDAO;
import com.bfu.energy.entity.WorkOrder;
import com.bfu.energy.entity.AlarmInfo;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.util.*;

@WebServlet("/api/maintenance/work-orders")
public class MaintenanceWorkOrderServlet extends HttpServlet {

    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) com.bfu.energy.dao.DAOFactory.getDAO(WorkOrderDAO.class);
            AlarmInfoDAO alarmInfoDAO = (AlarmInfoDAO) com.bfu.energy.dao.DAOFactory.getDAO(AlarmInfoDAO.class);
            
            String status = req.getParameter("status");
            String alarmLevel = req.getParameter("alarmLevel");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");
            int page = Integer.parseInt(req.getParameter("page") != null ? req.getParameter("page") : "1");
            int pageSize = Integer.parseInt(req.getParameter("pageSize") != null ? req.getParameter("pageSize") : "10");
            
            List<WorkOrder> allOrders = workOrderDAO.findAll();
            
            if (status != null && !status.isEmpty()) {
                allOrders.removeIf(order -> !status.equals(getOrderStatus(order)));
            }
            
            if (startDateStr != null && !startDateStr.isEmpty()) {
                LocalDateTime startDate = LocalDateTime.parse(startDateStr);
                allOrders.removeIf(order -> order.getDispatchTime() == null || 
                    order.getDispatchTime().isBefore(startDate));
            }
            
            if (endDateStr != null && !endDateStr.isEmpty()) {
                LocalDateTime endDate = LocalDateTime.parse(endDateStr);
                allOrders.removeIf(order -> order.getDispatchTime() == null || 
                    order.getDispatchTime().isAfter(endDate));
            }
            
            if (alarmLevel != null && !alarmLevel.isEmpty()) {
                List<WorkOrder> filteredOrders = new ArrayList<>();
                for (WorkOrder order : allOrders) {
                    if (order.getAlarmId() != null) {
                        AlarmInfo alarm = alarmInfoDAO.findById(order.getAlarmId());
                        if (alarm != null && alarmLevel.equals(alarm.getAlarmLevel())) {
                            filteredOrders.add(order);
                        }
                    }
                }
                allOrders = filteredOrders;
            }
            
            int total = allOrders.size();
            int startIndex = (page - 1) * pageSize;
            int endIndex = Math.min(startIndex + pageSize, total);
            
            List<Map<String, Object>> orderData = new ArrayList<>();
            for (WorkOrder order : allOrders.subList(startIndex, endIndex)) {
                Map<String, Object> orderMap = new HashMap<>();
                orderMap.put("orderId", order.getOrderId());
                orderMap.put("status", getOrderStatus(order));
                orderMap.put("statusText", getOrderStatusText(order));
                orderMap.put("dispatchTime", order.getDispatchTime());
                orderMap.put("responseTime", order.getResponseTime());
                orderMap.put("finishTime", order.getFinishTime());
                
                if (order.getAlarmId() != null) {
                    AlarmInfo alarm = alarmInfoDAO.findById(order.getAlarmId());
                    if (alarm != null) {
                        orderMap.put("alarmId", alarm.getAlarmId());
                        orderMap.put("alarmLevel", alarm.getAlarmLevel());
                        orderMap.put("alarmLevelClass", getAlarmLevelClass(alarm.getAlarmLevel()));
                        orderMap.put("alarmContent", alarm.getContent());
                        orderMap.put("alarmOccurTime", alarm.getOccurTime());
                    }
                }
                
                orderData.add(orderMap);
            }
            
            Map<String, Object> data = new HashMap<>();
            data.put("workOrders", orderData);
            data.put("total", total);
            data.put("page", page);
            data.put("pageSize", pageSize);
            
            result.put("success", true);
            result.put("data", data);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取工单列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private String getOrderStatus(WorkOrder order) {
        if (order.getFinishTime() != null) return "completed";
        if (order.getResponseTime() != null) return "processing";
        return "pending";
    }
    
    private String getOrderStatusText(WorkOrder order) {
        if (order.getFinishTime() != null) return "已完成";
        if (order.getResponseTime() != null) return "处理中";
        return "待处理";
    }
    
    private String getAlarmLevelClass(String level) {
        if ("高".equals(level)) return "high";
        if ("中".equals(level)) return "medium";
        return "low";
    }
}
