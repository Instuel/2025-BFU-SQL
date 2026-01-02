package com.bfu.energy.servlet;

import com.bfu.energy.dao.AlarmInfoDAO;
import com.bfu.energy.dao.PVDeviceDAO;
import com.bfu.energy.dao.EnergyMeterDAO;
import com.bfu.energy.dao.DistTransformerDAO;
import com.bfu.energy.dao.WorkOrderDAO;
import com.bfu.energy.entity.AlarmInfo;
import com.bfu.energy.entity.PVDevice;
import com.bfu.energy.entity.EnergyMeter;
import com.bfu.energy.entity.DistTransformer;
import com.bfu.energy.entity.WorkOrder;
import com.bfu.energy.util.DAOFactory;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/api/maintenance/dashboard")
public class MaintenanceDashboardDataServlet extends HttpServlet {

    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            AlarmInfoDAO alarmInfoDAO = DAOFactory.getDAO(AlarmInfoDAO.class);
            PVDeviceDAO pvDeviceDAO = DAOFactory.getDAO(PVDeviceDAO.class);
            EnergyMeterDAO energyMeterDAO = DAOFactory.getDAO(EnergyMeterDAO.class);
            DistTransformerDAO distTransformerDAO = DAOFactory.getDAO(DistTransformerDAO.class);
            WorkOrderDAO workOrderDAO = DAOFactory.getDAO(WorkOrderDAO.class);
            
            Long userId = (Long) req.getSession().getAttribute("userId");
            
            int totalDevices = 0;
            int normalDevices = 0;
            
            List<PVDevice> pvDevices = pvDeviceDAO.findAll();
            for (PVDevice device : pvDevices) {
                totalDevices++;
                if ("正常".equals(device.getRunStatus())) {
                    normalDevices++;
                }
            }
            
            List<EnergyMeter> meters = energyMeterDAO.findAll();
            for (EnergyMeter meter : meters) {
                totalDevices++;
                if ("正常".equals(meter.getRunStatus())) {
                    normalDevices++;
                }
            }
            
            List<DistTransformer> transformers = distTransformerDAO.findAll();
            for (DistTransformer transformer : transformers) {
                totalDevices++;
            }
            
            List<WorkOrder> pendingOrders = workOrderDAO.findUnfinishedOrders();
            int pendingCount = pendingOrders.size();
            
            List<AlarmInfo> alarms = alarmInfoDAO.findByProcessStatus("未处理");
            int highLevelCount = 0;
            for (AlarmInfo alarm : alarms) {
                if ("高".equals(alarm.getAlarmLevel())) {
                    highLevelCount++;
                }
            }
            
            LocalDateTime monthStart = LocalDate.now().withDayOfMonth(1).atStartOfDay();
            LocalDateTime monthEnd = LocalDate.now().withDayOfMonth(LocalDate.now().lengthOfMonth()).atTime(23, 59, 59);
            List<WorkOrder> completedOrders = workOrderDAO.findByDateRange(monthStart, monthEnd);
            int completedCount = 0;
            for (WorkOrder order : completedOrders) {
                if (order.getFinishTime() != null) {
                    completedCount++;
                }
            }
            
            int totalMonthOrders = completedOrders.size();
            double completionRate = totalMonthOrders > 0 ? 
                (double) completedCount / totalMonthOrders * 100 : 0;
            
            List<Map<String, Object>> workOrderData = new ArrayList<>();
            for (WorkOrder order : pendingOrders.subList(0, Math.min(5, pendingOrders.size()))) {
                Map<String, Object> orderMap = new HashMap<>();
                orderMap.put("orderId", order.getOrderId());
                orderMap.put("status", order.getResponseTime() == null ? "pending" : "processing");
                orderMap.put("content", "处理告警工单");
                orderMap.put("dispatchTime", order.getDispatchTime());
                workOrderData.add(orderMap);
            }
            
            List<Map<String, Object>> alarmData = new ArrayList<>();
            for (AlarmInfo alarm : alarms.subList(0, Math.min(5, alarms.size()))) {
                Map<String, Object> alarmMap = new HashMap<>();
                alarmMap.put("alarmId", alarm.getAlarmId());
                alarmMap.put("level", getAlarmLevelClass(alarm.getAlarmLevel()));
                alarmMap.put("levelText", alarm.getAlarmLevel() + "等级");
                alarmMap.put("content", alarm.getContent());
                alarmMap.put("occurTime", alarm.getOccurTime());
                alarmData.add(alarmMap);
            }
            
            Map<String, Object> dashboardData = new HashMap<>();
            dashboardData.put("totalDevices", totalDevices);
            dashboardData.put("normalDevices", normalDevices);
            dashboardData.put("pendingOrders", pendingCount);
            dashboardData.put("highLevelAlarms", highLevelCount);
            dashboardData.put("completedOrders", completedCount);
            dashboardData.put("completionRate", String.format("%.1f", completionRate));
            dashboardData.put("workOrders", workOrderData);
            dashboardData.put("alarms", alarmData);
            
            result.put("success", true);
            result.put("data", dashboardData);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取dashboard数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private String getAlarmLevelClass(String level) {
        if ("高".equals(level)) return "high";
        if ("中".equals(level)) return "medium";
        return "low";
    }
}
