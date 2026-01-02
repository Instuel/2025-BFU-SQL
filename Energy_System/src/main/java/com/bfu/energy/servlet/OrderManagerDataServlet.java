package com.bfu.energy.servlet;

import com.bfu.energy.dao.*;
import com.bfu.energy.entity.*;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Type;
import java.text.SimpleDateFormat;
import java.util.*;

@WebServlet("/api/order-manager/*")
public class OrderManagerDataServlet extends HttpServlet {

    private Gson gson = new Gson();
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    private SimpleDateFormat dateOnlyFormat = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null) {
            sendError(resp, "无效的请求路径");
            return;
        }

        if (pathInfo.equals("/alarm-stats")) {
            getAlarmStats(req, resp);
        } else if (pathInfo.equals("/alarms")) {
            getAlarms(req, resp);
        } else if (pathInfo.startsWith("/alarm/")) {
            String alarmId = pathInfo.substring("/alarm/".length());
            getAlarmDetail(req, resp, alarmId);
        } else if (pathInfo.equals("/order-stats")) {
            getOrderStats(req, resp);
        } else if (pathInfo.equals("/orders")) {
            getOrders(req, resp);
        } else if (pathInfo.startsWith("/order/")) {
            String orderId = pathInfo.substring("/order/".length());
            getOrderDetail(req, resp, orderId);
        } else if (pathInfo.equals("/maintenance-personnel")) {
            getMaintenancePersonnel(req, resp);
        } else {
            sendError(resp, "无效的请求路径");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        String pathInfo = req.getPathInfo();
        
        if (pathInfo == null) {
            sendError(resp, "无效的请求路径");
            return;
        }

        if (pathInfo.equals("/alarm/review")) {
            reviewAlarm(req, resp);
        } else if (pathInfo.equals("/dispatch")) {
            dispatchWorkOrder(req, resp);
        } else if (pathInfo.equals("/order/review")) {
            reviewOrder(req, resp);
        } else {
            sendError(resp, "无效的请求路径");
        }
    }

    private void getAlarmStats(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            AlarmRecordDAO alarmDAO = (AlarmRecordDAO) DAOFactory.getDAO(AlarmRecordDAO.class);
            
            List<AlarmRecord> allAlarms = alarmDAO.findAll();
            
            int pendingCount = 0;
            int verifiedCount = 0;
            int dispatchedCount = 0;
            int falseAlarmCount = 0;
            
            String today = dateOnlyFormat.format(new Date());
            
            for (AlarmRecord alarm : allAlarms) {
                String alarmDate = dateOnlyFormat.format(alarm.getAlarmTime());
                
                if ("待审核".equals(alarm.getReviewStatus())) {
                    pendingCount++;
                } else if ("已通过".equals(alarm.getReviewStatus())) {
                    if (today.equals(alarmDate)) {
                        verifiedCount++;
                    }
                    if (alarm.getWorkOrderId() != null) {
                        if (today.equals(alarmDate)) {
                            dispatchedCount++;
                        }
                    }
                } else if ("误报".equals(alarm.getReviewStatus())) {
                    falseAlarmCount++;
                }
            }
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("pendingCount", pendingCount);
            stats.put("verifiedCount", verifiedCount);
            stats.put("dispatchedCount", dispatchedCount);
            stats.put("falseAlarmCount", falseAlarmCount);
            
            result.put("success", true);
            result.put("data", stats);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取告警统计数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getAlarms(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            AlarmRecordDAO alarmDAO = (AlarmRecordDAO) DAOFactory.getDAO(AlarmRecordDAO.class);
            BaseDeviceDAO deviceDAO = (BaseDeviceDAO) DAOFactory.getDAO(BaseDeviceDAO.class);
            
            int page = Integer.parseInt(req.getParameter("page"));
            int pageSize = Integer.parseInt(req.getParameter("pageSize"));
            
            String alarmLevel = req.getParameter("alarmLevel");
            String alarmType = req.getParameter("alarmType");
            String reviewStatus = req.getParameter("reviewStatus");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");
            
            List<AlarmRecord> allAlarms = alarmDAO.findAll();
            List<BaseDevice> devices = deviceDAO.findAll();
            
            Map<Long, String> deviceNameMap = new HashMap<>();
            for (BaseDevice device : devices) {
                deviceNameMap.put(device.getId(), device.getDeviceName());
            }
            
            List<AlarmRecord> filteredAlarms = new ArrayList<>();
            for (AlarmRecord alarm : allAlarms) {
                if (alarmLevel != null && !alarmLevel.isEmpty() && !alarmLevel.equals(alarm.getAlarmLevel())) {
                    continue;
                }
                if (alarmType != null && !alarmType.isEmpty() && !alarmType.equals(alarm.getAlarmType())) {
                    continue;
                }
                if (reviewStatus != null && !reviewStatus.isEmpty() && !reviewStatus.equals(alarm.getReviewStatus())) {
                    continue;
                }
                if (startDateStr != null && !startDateStr.isEmpty()) {
                    Date startDate = dateOnlyFormat.parse(startDateStr);
                    if (alarm.getAlarmTime().before(startDate)) {
                        continue;
                    }
                }
                if (endDateStr != null && !endDateStr.isEmpty()) {
                    Date endDate = dateOnlyFormat.parse(endDateStr);
                    endDate.setHours(23, 59, 59);
                    if (alarm.getAlarmTime().after(endDate)) {
                        continue;
                    }
                }
                filteredAlarms.add(alarm);
            }
            
            int total = filteredAlarms.size();
            int totalPages = (int) Math.ceil((double) total / pageSize);
            
            int startIndex = (page - 1) * pageSize;
            int endIndex = Math.min(startIndex + pageSize, total);
            
            List<AlarmRecord> pagedAlarms = filteredAlarms.subList(startIndex, endIndex);
            
            List<Map<String, Object>> alarmList = new ArrayList<>();
            for (AlarmRecord alarm : pagedAlarms) {
                Map<String, Object> alarmData = new HashMap<>();
                alarmData.put("id", alarm.getId());
                alarmData.put("alarmCode", alarm.getAlarmCode());
                alarmData.put("alarmTime", dateFormat.format(alarm.getAlarmTime()));
                alarmData.put("alarmLevel", alarm.getAlarmLevel());
                alarmData.put("alarmType", alarm.getAlarmType());
                alarmData.put("deviceId", alarm.getDeviceId());
                alarmData.put("deviceName", deviceNameMap.get(alarm.getDeviceId()));
                alarmData.put("alarmContent", alarm.getAlarmContent());
                alarmData.put("reviewStatus", alarm.getReviewStatus());
                alarmData.put("workOrderId", alarm.getWorkOrderId());
                alarmList.add(alarmData);
            }
            
            Map<String, Object> data = new HashMap<>();
            data.put("list", alarmList);
            data.put("total", total);
            data.put("totalPages", totalPages);
            data.put("currentPage", page);
            data.put("pageSize", pageSize);
            
            result.put("success", true);
            result.put("data", data);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取告警列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getAlarmDetail(HttpServletRequest req, HttpServletResponse resp, String alarmId) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            AlarmRecordDAO alarmDAO = (AlarmRecordDAO) DAOFactory.getDAO(AlarmRecordDAO.class);
            BaseDeviceDAO deviceDAO = (BaseDeviceDAO) DAOFactory.getDAO(BaseDeviceDAO.class);
            
            AlarmRecord alarm = alarmDAO.findById(Long.parseLong(alarmId));
            
            if (alarm != null) {
                BaseDevice device = deviceDAO.findById(alarm.getDeviceId());
                
                Map<String, Object> alarmData = new HashMap<>();
                alarmData.put("id", alarm.getId());
                alarmData.put("alarmCode", alarm.getAlarmCode());
                alarmData.put("alarmTime", dateFormat.format(alarm.getAlarmTime()));
                alarmData.put("alarmLevel", alarm.getAlarmLevel());
                alarmData.put("alarmType", alarm.getAlarmType());
                alarmData.put("deviceId", alarm.getDeviceId());
                alarmData.put("deviceName", device != null ? device.getDeviceName() : "");
                alarmData.put("alarmContent", alarm.getAlarmContent());
                alarmData.put("reviewStatus", alarm.getReviewStatus());
                alarmData.put("reviewComment", alarm.getReviewComment());
                alarmData.put("reviewTime", alarm.getReviewTime() != null ? dateFormat.format(alarm.getReviewTime()) : "");
                alarmData.put("workOrderId", alarm.getWorkOrderId());
                
                result.put("success", true);
                result.put("data", alarmData);
            } else {
                result.put("success", false);
                result.put("message", "告警不存在");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取告警详情失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void reviewAlarm(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = req.getReader().readLine()) != null) {
                sb.append(line);
            }
            
            Type type = new TypeToken<Map<String, String>>(){}.getType();
            Map<String, String> params = gson.fromJson(sb.toString(), type);
            
            String alarmIdStr = params.get("alarmId");
            String status = params.get("status");
            String comment = params.get("comment");
            
            AlarmRecordDAO alarmDAO = (AlarmRecordDAO) DAOFactory.getDAO(AlarmRecordDAO.class);
            
            AlarmRecord alarm = alarmDAO.findById(Long.parseLong(alarmIdStr));
            
            if (alarm != null) {
                alarm.setReviewStatus(status);
                alarm.setReviewComment(comment);
                alarm.setReviewTime(new Date());
                
                alarmDAO.update(alarm);
                
                result.put("success", true);
                result.put("message", "审核成功");
            } else {
                result.put("success", false);
                result.put("message", "告警不存在");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "审核失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void dispatchWorkOrder(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = req.getReader().readLine()) != null) {
                sb.append(line);
            }
            
            Type type = new TypeToken<Map<String, String>>(){}.getType();
            Map<String, String> params = gson.fromJson(sb.toString(), type);
            
            String alarmIdStr = params.get("alarmId");
            String orderTitle = params.get("orderTitle");
            String orderDescription = params.get("orderDescription");
            String orderPriority = params.get("orderPriority");
            String assignTo = params.get("assignTo");
            String expectedCompletionTimeStr = params.get("expectedCompletionTime");
            
            AlarmRecordDAO alarmDAO = (AlarmRecordDAO) DAOFactory.getDAO(AlarmRecordDAO.class);
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) DAOFactory.getDAO(WorkOrderDAO.class);
            
            AlarmRecord alarm = alarmDAO.findById(Long.parseLong(alarmIdStr));
            
            if (alarm != null) {
                WorkOrder workOrder = new WorkOrder();
                workOrder.setOrderCode(generateOrderCode());
                workOrder.setOrderTitle(orderTitle);
                workOrder.setOrderDescription(orderDescription);
                workOrder.setPriority(orderPriority);
                workOrder.setDeviceId(alarm.getDeviceId());
                workOrder.setAssigneeId(Long.parseLong(assignTo));
                workOrder.setCreateTime(new Date());
                workOrder.setOrderStatus("待处理");
                workOrder.setExpectedCompletionTime(dateFormat.parse(expectedCompletionTimeStr));
                
                workOrderDAO.save(workOrder);
                
                alarm.setWorkOrderId(workOrder.getId());
                alarmDAO.update(alarm);
                
                result.put("success", true);
                result.put("message", "派单成功");
                result.put("workOrderId", workOrder.getId());
            } else {
                result.put("success", false);
                result.put("message", "告警不存在");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "派单失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getOrderStats(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) DAOFactory.getDAO(WorkOrderDAO.class);
            
            List<WorkOrder> allOrders = workOrderDAO.findAll();
            
            int pendingReviewCount = 0;
            int reviewedCount = 0;
            int closedCount = 0;
            int rejectedCount = 0;
            
            String today = dateOnlyFormat.format(new Date());
            Calendar cal = Calendar.getInstance();
            cal.add(Calendar.DAY_OF_MONTH, -7);
            String weekAgo = dateOnlyFormat.format(cal.getTime());
            
            for (WorkOrder order : allOrders) {
                String completeDate = order.getCompleteTime() != null ? dateOnlyFormat.format(order.getCompleteTime()) : "";
                
                if ("待复查".equals(order.getOrderStatus())) {
                    pendingReviewCount++;
                } else if ("已完成".equals(order.getOrderStatus()) || "已结案".equals(order.getOrderStatus())) {
                    if (today.equals(completeDate)) {
                        reviewedCount++;
                    }
                    if ("已结案".equals(order.getOrderStatus())) {
                        if (completeDate.compareTo(weekAgo) >= 0) {
                            closedCount++;
                        }
                    }
                } else if ("已驳回".equals(order.getOrderStatus())) {
                    rejectedCount++;
                }
            }
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("pendingReviewCount", pendingReviewCount);
            stats.put("reviewedCount", reviewedCount);
            stats.put("closedCount", closedCount);
            stats.put("rejectedCount", rejectedCount);
            
            result.put("success", true);
            result.put("data", stats);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取工单统计数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getOrders(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) DAOFactory.getDAO(WorkOrderDAO.class);
            BaseDeviceDAO deviceDAO = (BaseDeviceDAO) DAOFactory.getDAO(BaseDeviceDAO.class);
            SysUserDAO userDAO = (SysUserDAO) DAOFactory.getDAO(SysUserDAO.class);
            
            int page = Integer.parseInt(req.getParameter("page"));
            int pageSize = Integer.parseInt(req.getParameter("pageSize"));
            
            String orderStatus = req.getParameter("orderStatus");
            String priority = req.getParameter("priority");
            String assignee = req.getParameter("assignee");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");
            
            List<WorkOrder> allOrders = workOrderDAO.findAll();
            List<BaseDevice> devices = deviceDAO.findAll();
            List<SysUser> users = userDAO.findAll();
            
            Map<Long, String> deviceNameMap = new HashMap<>();
            for (BaseDevice device : devices) {
                deviceNameMap.put(device.getId(), device.getDeviceName());
            }
            
            Map<Long, String> userNameMap = new HashMap<>();
            for (SysUser user : users) {
                userNameMap.put(user.getId(), user.getUsername());
            }
            
            List<WorkOrder> filteredOrders = new ArrayList<>();
            for (WorkOrder order : allOrders) {
                if (orderStatus != null && !orderStatus.isEmpty() && !orderStatus.equals(order.getOrderStatus())) {
                    continue;
                }
                if (priority != null && !priority.isEmpty() && !priority.equals(order.getPriority())) {
                    continue;
                }
                if (assignee != null && !assignee.isEmpty() && !assignee.equals(String.valueOf(order.getAssigneeId()))) {
                    continue;
                }
                if (startDateStr != null && !startDateStr.isEmpty()) {
                    Date startDate = dateOnlyFormat.parse(startDateStr);
                    if (order.getCreateTime().before(startDate)) {
                        continue;
                    }
                }
                if (endDateStr != null && !endDateStr.isEmpty()) {
                    Date endDate = dateOnlyFormat.parse(endDateStr);
                    endDate.setHours(23, 59, 59);
                    if (order.getCreateTime().after(endDate)) {
                        continue;
                    }
                }
                filteredOrders.add(order);
            }
            
            int total = filteredOrders.size();
            int totalPages = (int) Math.ceil((double) total / pageSize);
            
            int startIndex = (page - 1) * pageSize;
            int endIndex = Math.min(startIndex + pageSize, total);
            
            List<WorkOrder> pagedOrders = filteredOrders.subList(startIndex, endIndex);
            
            List<Map<String, Object>> orderList = new ArrayList<>();
            for (WorkOrder order : pagedOrders) {
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("id", order.getId());
                orderData.put("orderCode", order.getOrderCode());
                orderData.put("orderTitle", order.getOrderTitle());
                orderData.put("deviceId", order.getDeviceId());
                orderData.put("deviceName", deviceNameMap.get(order.getDeviceId()));
                orderData.put("priority", order.getPriority());
                orderData.put("assigneeId", order.getAssigneeId());
                orderData.put("assigneeName", userNameMap.get(order.getAssigneeId()));
                orderData.put("createTime", dateFormat.format(order.getCreateTime()));
                orderData.put("expectedCompletionTime", order.getExpectedCompletionTime() != null ? dateFormat.format(order.getExpectedCompletionTime()) : "");
                orderData.put("completeTime", order.getCompleteTime() != null ? dateFormat.format(order.getCompleteTime()) : "");
                orderData.put("orderStatus", order.getOrderStatus());
                orderList.add(orderData);
            }
            
            Map<String, Object> data = new HashMap<>();
            data.put("list", orderList);
            data.put("total", total);
            data.put("totalPages", totalPages);
            data.put("currentPage", page);
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

    private void getOrderDetail(HttpServletRequest req, HttpServletResponse resp, String orderId) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) DAOFactory.getDAO(WorkOrderDAO.class);
            BaseDeviceDAO deviceDAO = (BaseDeviceDAO) DAOFactory.getDAO(BaseDeviceDAO.class);
            SysUserDAO userDAO = (SysUserDAO) DAOFactory.getDAO(SysUserDAO.class);
            
            WorkOrder order = workOrderDAO.findById(Long.parseLong(orderId));
            
            if (order != null) {
                BaseDevice device = deviceDAO.findById(order.getDeviceId());
                SysUser assignee = userDAO.findById(order.getAssigneeId());
                
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("id", order.getId());
                orderData.put("orderCode", order.getOrderCode());
                orderData.put("orderTitle", order.getOrderTitle());
                orderData.put("orderDescription", order.getOrderDescription());
                orderData.put("priority", order.getPriority());
                orderData.put("deviceId", order.getDeviceId());
                orderData.put("deviceName", device != null ? device.getDeviceName() : "");
                orderData.put("assigneeId", order.getAssigneeId());
                orderData.put("assigneeName", assignee != null ? assignee.getUsername() : "");
                orderData.put("createTime", dateFormat.format(order.getCreateTime()));
                orderData.put("expectedCompletionTime", order.getExpectedCompletionTime() != null ? dateFormat.format(order.getExpectedCompletionTime()) : "");
                orderData.put("completeTime", order.getCompleteTime() != null ? dateFormat.format(order.getCompleteTime()) : "");
                orderData.put("orderStatus", order.getOrderStatus());
                orderData.put("reviewComment", order.getReviewComment());
                
                List<Map<String, Object>> timeline = new ArrayList<>();
                timeline.add(new HashMap<String, Object>() {{
                    put("time", dateFormat.format(order.getCreateTime()));
                    put("content", "工单创建");
                }});
                if (order.getCompleteTime() != null) {
                    timeline.add(new HashMap<String, Object>() {{
                        put("time", dateFormat.format(order.getCompleteTime()));
                        put("content", "工单完成");
                    }});
                }
                orderData.put("timeline", timeline);
                
                result.put("success", true);
                result.put("data", orderData);
            } else {
                result.put("success", false);
                result.put("message", "工单不存在");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取工单详情失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void reviewOrder(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = req.getReader().readLine()) != null) {
                sb.append(line);
            }
            
            Type type = new TypeToken<Map<String, String>>(){}.getType();
            Map<String, String> params = gson.fromJson(sb.toString(), type);
            
            String orderIdStr = params.get("orderId");
            String status = params.get("status");
            String comment = params.get("comment");
            
            WorkOrderDAO workOrderDAO = (WorkOrderDAO) DAOFactory.getDAO(WorkOrderDAO.class);
            BaseDeviceDAO deviceDAO = (BaseDeviceDAO) DAOFactory.getDAO(BaseDeviceDAO.class);
            
            WorkOrder order = workOrderDAO.findById(Long.parseLong(orderIdStr));
            
            if (order != null) {
                if ("通过".equals(status)) {
                    order.setOrderStatus("已结案");
                } else {
                    order.setOrderStatus("已驳回");
                }
                order.setReviewComment(comment);
                
                workOrderDAO.update(order);
                
                if ("通过".equals(status)) {
                    BaseDevice device = deviceDAO.findById(order.getDeviceId());
                    if (device != null) {
                        device.setLastMaintenanceTime(new Date());
                        deviceDAO.update(device);
                    }
                }
                
                result.put("success", true);
                result.put("message", "复查成功");
            } else {
                result.put("success", false);
                result.put("message", "工单不存在");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "复查失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getMaintenancePersonnel(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            SysUserDAO userDAO = (SysUserDAO) DAOFactory.getDAO(SysUserDAO.class);
            SysRoleAssignmentDAO roleAssignmentDAO = (SysRoleAssignmentDAO) DAOFactory.getDAO(SysRoleAssignmentDAO.class);
            
            List<SysUser> allUsers = userDAO.findAll();
            List<SysRoleAssignment> roleAssignments = roleAssignmentDAO.findAll();
            
            List<Map<String, Object>> personnel = new ArrayList<>();
            
            for (SysUser user : allUsers) {
                for (SysRoleAssignment assignment : roleAssignments) {
                    if (assignment.getUserId().equals(user.getId()) && "OM".equals(assignment.getRoleCode())) {
                        Map<String, Object> person = new HashMap<>();
                        person.put("id", user.getId());
                        person.put("name", user.getUsername());
                        person.put("area", assignment.getAreaCode() != null ? assignment.getAreaCode() : "");
                        personnel.add(person);
                        break;
                    }
                }
            }
            
            result.put("success", true);
            result.put("data", personnel);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取运维人员列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private String generateOrderCode() {
        return "WO" + System.currentTimeMillis();
    }

    private void sendError(HttpServletResponse resp, String message) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        result.put("success", false);
        result.put("message", message);
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
}
