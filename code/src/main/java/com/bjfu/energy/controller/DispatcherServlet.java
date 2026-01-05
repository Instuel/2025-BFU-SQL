package com.bjfu.energy.controller;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.WorkOrder;
import com.bjfu.energy.service.DispatcherService;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@MultipartConfig
public class DispatcherServlet extends HttpServlet {

    private final DispatcherService dispatcherService = new DispatcherService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        req.setAttribute("module", "dispatcher");

        try {
            switch (action) {
                case "list":
                    handleAlarmList(req, resp);
                    break;
                case "detail":
                    handleAlarmDetail(req, resp);
                    break;
                case "createWorkOrder":
                    handleCreateWorkOrderPage(req, resp);
                    break;
                case "workOrderDetail":
                    handleWorkOrderDetail(req, resp);
                    break;
                case "workOrderList":
                    handleWorkOrderList(req, resp);
                    break;
                case "reviewWorkOrder":
                    handleReviewWorkOrderPage(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("运维工单管理员请求处理失败: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            doGet(req, resp);
            return;
        }

        try {
            switch (action) {
                case "verifyAlarm":
                    handleVerifyAlarm(req, resp);
                    break;
                case "createWorkOrder":
                    handleCreateWorkOrder(req, resp);
                    break;
                case "reviewWorkOrder":
                    handleReviewWorkOrder(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("运维工单管理员操作失败: " + e.getMessage(), e);
        }
    }

    private void handleAlarmList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        List<AlarmInfo> alarms = dispatcherService.findPendingVerificationAlarms();

        int total = alarms.size();
        int highCount = 0;
        int urgentCount = 0;
        for (AlarmInfo alarm : alarms) {
            if ("高".equals(alarm.getAlarmLevel())) {
                highCount++;
            }
            if ("高".equals(alarm.getAlarmLevel()) && 
                ("待审核".equals(alarm.getProcessStatus()) || "未处理".equals(alarm.getProcessStatus()))) {
                urgentCount++;
            }
        }

        req.setAttribute("alarms", alarms);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("totalCount", total);
        req.setAttribute("highCount", highCount);
        req.setAttribute("urgentCount", urgentCount);
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/alarm_list.jsp").forward(req, resp);
    }

    private void handleAlarmDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/dispatcher?action=list");
            return;
        }
        AlarmInfo alarm = dispatcherService.findAlarmById(Long.valueOf(idStr));
        WorkOrder order = dispatcherService.getWorkOrderByAlarm(Long.valueOf(idStr));
        req.setAttribute("alarm", alarm);
        req.setAttribute("workOrder", order);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/alarm_detail.jsp").forward(req, resp);
    }

    private void handleCreateWorkOrderPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String alarmIdStr = req.getParameter("alarmId");
        if (alarmIdStr == null || alarmIdStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/dispatcher?action=list");
            return;
        }
        Long alarmId = Long.valueOf(alarmIdStr);
        AlarmInfo alarm = dispatcherService.findAlarmById(alarmId);
        if (alarm == null) {
            resp.sendRedirect(buildRedirect(req.getContextPath() + "/dispatcher?action=list", "未找到对应告警"));
            return;
        }
        
        // 获取当前用户的dispatcher ID
        com.bjfu.energy.entity.SysUser currentUser = (com.bjfu.energy.entity.SysUser) req.getSession().getAttribute("currentUser");
        Long dispatcherId = null;
        if (currentUser != null) {
            // 查找当前用户的dispatcher角色ID
            com.bjfu.energy.dao.RoleOandMDao roleDao = new com.bjfu.energy.dao.RoleOandMDaoImpl();
            // 这里需要一个查找dispatcher角色的方法，暂时使用用户ID
            dispatcherId = currentUser.getUserId();
        }
        
        List<SysUser> oandmUsers = dispatcherService.findOandMUsers();
        req.setAttribute("alarm", alarm);
        req.setAttribute("oandmUsers", oandmUsers);
        req.setAttribute("dispatcherId", dispatcherId);
        req.setAttribute("now", java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")));
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/workorder_create.jsp").forward(req, resp);
    }

    private void handleWorkOrderDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/dispatcher?action=list");
            return;
        }
        WorkOrder order = dispatcherService.getWorkOrder(Long.valueOf(idStr));
        AlarmInfo alarm = null;
        if (order != null && order.getAlarmId() != null) {
            alarm = dispatcherService.findAlarmById(order.getAlarmId());
        }
        req.setAttribute("workOrder", order);
        req.setAttribute("alarm", alarm);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/workorder_detail.jsp").forward(req, resp);
    }

    private void handleWorkOrderList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        List<WorkOrder> workOrders = dispatcherService.findAllWorkOrders();

        int totalCount = workOrders.size();
        int pendingReviewCount = 0;
        int passedCount = 0;
        int failedCount = 0;

        for (WorkOrder order : workOrders) {
            if (order.getReviewStatus() == null || order.getReviewStatus().trim().isEmpty()) {
                pendingReviewCount++;
            } else if ("通过".equals(order.getReviewStatus())) {
                passedCount++;
            } else if ("未通过".equals(order.getReviewStatus())) {
                failedCount++;
            }
        }

        req.setAttribute("workOrders", workOrders);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("totalCount", totalCount);
        req.setAttribute("pendingReviewCount", pendingReviewCount);
        req.setAttribute("passedCount", passedCount);
        req.setAttribute("failedCount", failedCount);
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/workorder_list.jsp").forward(req, resp);
    }

    private void handleReviewWorkOrderPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/dispatcher?action=workOrderList");
            return;
        }
        WorkOrder order = dispatcherService.findWorkOrderById(Long.valueOf(idStr));
        AlarmInfo alarm = null;
        if (order != null && order.getAlarmId() != null) {
            alarm = dispatcherService.findAlarmById(order.getAlarmId());
        }
        req.setAttribute("workOrder", order);
        req.setAttribute("alarm", alarm);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/dispatcher/workorder_review.jsp").forward(req, resp);
    }

    private void handleVerifyAlarm(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        Long alarmId = Long.valueOf(req.getParameter("alarmId"));
        String verifyStatus = req.getParameter("verifyStatus");
        String verifyRemark = req.getParameter("verifyRemark");

        dispatcherService.updateAlarmVerification(alarmId, verifyStatus, verifyRemark);

        if ("误报".equals(verifyStatus)) {
            dispatcherService.updateAlarmProcessStatus(alarmId, "已结案");
            String target = req.getContextPath() + "/dispatcher?action=list";
            resp.sendRedirect(buildRedirect(target, "告警已标记为误报并结案"));
        } else {
            String target = req.getContextPath() + "/dispatcher?action=createWorkOrder&alarmId=" + alarmId;
            resp.sendRedirect(buildRedirect(target, "告警已确认为有效，请创建工单"));
        }
    }

    private void handleCreateWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        Long alarmId = Long.valueOf(req.getParameter("alarmId"));
        AlarmInfo alarm = dispatcherService.findAlarmById(alarmId);
        if (alarm == null) {
            String target = req.getContextPath() + "/dispatcher?action=list";
            resp.sendRedirect(buildRedirect(target, "未找到对应告警"));
            return;
        }
        if (!"有效".equals(alarm.getVerifyStatus())) {
            String target = req.getContextPath() + "/dispatcher?action=detail&id=" + alarmId;
            resp.sendRedirect(buildRedirect(target, "请先完成告警真实性审核"));
            return;
        }

        // 检查是否已存在工单
        WorkOrder existingOrder = dispatcherService.getWorkOrderByAlarm(alarmId);
        boolean isUpdate = (existingOrder != null);

        WorkOrder order = new WorkOrder();
        order.setAlarmId(alarmId);
        order.setLedgerId(parseLong(req.getParameter("ledgerId")));
        order.setOandmId(parseLong(req.getParameter("oandmId")));
        order.setDispatcherId(parseLong(req.getParameter("dispatcherId")));
        order.setDispatchTime(parseDateTime(req.getParameter("dispatchTime")));
        order.setResultDesc(req.getParameter("resultDesc"));
        order.setReviewStatus(null);
        String attachmentPath = handleAttachmentUpload(req, null);
        order.setAttachmentPath(attachmentPath);

        Long id = dispatcherService.createWorkOrder(order);
        dispatcherService.updateAlarmProcessStatus(alarmId, "处理中");
        
        String target = req.getContextPath() + "/dispatcher?action=workOrderDetail&id=" + id;
        String message = isUpdate ? "运维工单已更新并重新派发" : "运维工单已创建并派发";
        resp.sendRedirect(buildRedirect(target, message));
    }

    private void handleReviewWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        Long orderId = Long.valueOf(req.getParameter("orderId"));
        Long alarmId = Long.valueOf(req.getParameter("alarmId"));
        String reviewStatus = req.getParameter("reviewStatus");
        String reviewFeedback = req.getParameter("reviewFeedback");
        Long dispatcherId = parseLong(req.getParameter("dispatcherId"));

        dispatcherService.reviewWorkOrder(orderId, reviewStatus, reviewFeedback, dispatcherId);

        String target = req.getContextPath() + "/dispatcher?action=reviewWorkOrder&id=" + orderId;
        if ("通过".equals(reviewStatus)) {
            resp.sendRedirect(buildRedirect(target, "工单审核通过，告警已结案"));
        } else {
            resp.sendRedirect(buildRedirect(target, "工单审核未通过，已返回运维人员"));
        }
    }

    private LocalDateTime parseDateTime(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        String input = value.trim();
        try {
            return LocalDateTime.parse(input, DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));
        } catch (DateTimeParseException e) {
            return LocalDateTime.parse(input);
        }
    }

    private Long parseLong(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return Long.valueOf(value.trim());
    }

    private String handleAttachmentUpload(HttpServletRequest req, String fallbackPath)
            throws IOException, ServletException {
        Part part = req.getPart("attachmentFile");
        if (part == null || part.getSize() == 0) {
            return fallbackPath;
        }
        String submittedFileName = part.getSubmittedFileName();
        if (submittedFileName == null || submittedFileName.trim().isEmpty()) {
            return fallbackPath;
        }
        String safeName = Paths.get(submittedFileName).getFileName().toString();
        String fileName = "workorder_" + System.currentTimeMillis() + "_" + safeName;
        String basePath = req.getServletContext().getRealPath("/uploads/workorder");
        Path uploadDir = basePath == null
                ? Paths.get(System.getProperty("java.io.tmpdir"), "energy_uploads", "workorder")
                : Paths.get(basePath);
        Files.createDirectories(uploadDir);
        Path target = uploadDir.resolve(fileName);
        try {
            Files.copy(part.getInputStream(), target);
        } catch (IOException ex) {
            return fallbackPath;
        }
        return "/uploads/workorder/" + fileName;
    }

    private String buildRedirect(String target, String message) {
        String encoded;
        try {
            encoded = URLEncoder.encode(message == null ? "" : message, StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            encoded = "";
        }
        return target + "&message=" + encoded;
    }
}
