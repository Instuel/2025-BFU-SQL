package com.bjfu.energy.controller;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.DeviceLedger;
import com.bjfu.energy.entity.WorkOrder;
import com.bjfu.energy.service.AlarmService;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * 告警运维模块入口：告警列表 / 工单管理 / 设备台账
 *  /alarm?action=list
 *  /alarm?action=detail&id=1
 *  /alarm?action=workorderList
 *  /alarm?action=workorderDetail&id=1
 *  /alarm?action=ledgerList
 *  /alarm?action=ledgerDetail&id=1
 */
public class AlarmServlet extends HttpServlet {

    private final AlarmService alarmService = new AlarmService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        req.setAttribute("module", "alarm");

        try {
            switch (action) {
                case "list":
                    handleAlarmList(req, resp);
                    break;
                case "detail":
                    handleAlarmDetail(req, resp);
                    break;
                case "workorderList":
                    handleWorkOrderList(req, resp);
                    break;
                case "workorderDetail":
                    handleWorkOrderDetail(req, resp);
                    break;
                case "ledgerList":
                    handleLedgerList(req, resp);
                    break;
                case "ledgerDetail":
                    handleLedgerDetail(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("告警运维请求处理失败: " + e.getMessage(), e);
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
                case "updateAlarmStatus":
                    handleUpdateAlarmStatus(req, resp);
                    break;
                case "createWorkOrder":
                    handleCreateWorkOrder(req, resp);
                    break;
                case "updateWorkOrder":
                    handleUpdateWorkOrder(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("告警运维操作失败: " + e.getMessage(), e);
        }
    }

    private void handleAlarmList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String alarmType = req.getParameter("alarmType");
        String alarmLevel = req.getParameter("alarmLevel");
        String processStatus = req.getParameter("processStatus");
        List<AlarmInfo> alarms = alarmService.listAlarms(alarmType, alarmLevel, processStatus);

        int total = alarms.size();
        int highCount = 0;
        int pendingCount = 0;
        int processingCount = 0;
        int closedCount = 0;
        int overdueCount = 0;
        for (AlarmInfo alarm : alarms) {
            if ("高".equals(alarm.getAlarmLevel())) {
                highCount++;
            }
            if ("未处理".equals(alarm.getProcessStatus())) {
                pendingCount++;
            } else if ("处理中".equals(alarm.getProcessStatus())) {
                processingCount++;
            } else if ("已结案".equals(alarm.getProcessStatus())) {
                closedCount++;
            }
            if (alarm.isDispatchOverdue()) {
                overdueCount++;
            }
        }

        req.setAttribute("alarms", alarms);
        req.setAttribute("alarmType", alarmType);
        req.setAttribute("alarmLevel", alarmLevel);
        req.setAttribute("processStatus", processStatus);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "alarm");
        req.setAttribute("totalCount", total);
        req.setAttribute("highCount", highCount);
        req.setAttribute("pendingCount", pendingCount);
        req.setAttribute("processingCount", processingCount);
        req.setAttribute("closedCount", closedCount);
        req.setAttribute("overdueCount", overdueCount);
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/alarm_list.jsp").forward(req, resp);
    }

    private void handleAlarmDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/alarm?action=list&module=alarm");
            return;
        }
        AlarmInfo alarm = alarmService.getAlarm(Long.valueOf(idStr));
        WorkOrder order = alarmService.getWorkOrderByAlarm(Long.valueOf(idStr));
        req.setAttribute("alarm", alarm);
        req.setAttribute("workOrder", order);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "alarm");
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/alarm_detail.jsp").forward(req, resp);
    }

    private void handleWorkOrderList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String reviewStatus = req.getParameter("reviewStatus");
        List<WorkOrder> orders = alarmService.listWorkOrders(reviewStatus);

        int total = orders.size();
        int pending = 0;
        int processing = 0;
        int completed = 0;
        for (WorkOrder order : orders) {
            if (order.getResponseTime() == null) {
                pending++;
            } else if (order.getFinishTime() == null) {
                processing++;
            } else {
                completed++;
            }
        }

        req.setAttribute("orders", orders);
        req.setAttribute("reviewStatus", reviewStatus);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "workorder");
        req.setAttribute("orderTotal", total);
        req.setAttribute("orderPending", pending);
        req.setAttribute("orderProcessing", processing);
        req.setAttribute("orderCompleted", completed);
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/workorder_list.jsp").forward(req, resp);
    }

    private void handleWorkOrderDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        String alarmIdStr = req.getParameter("alarmId");
        WorkOrder order = null;
        AlarmInfo alarm = null;
        boolean createMode = false;
        if (idStr != null && !idStr.trim().isEmpty()) {
            order = alarmService.getWorkOrder(Long.valueOf(idStr));
        } else if (alarmIdStr != null && !alarmIdStr.trim().isEmpty()) {
            Long alarmId = Long.valueOf(alarmIdStr);
            order = alarmService.getWorkOrderByAlarm(alarmId);
            if (order == null) {
                createMode = true;
                alarm = alarmService.getAlarm(alarmId);
            }
        }

        req.setAttribute("workOrder", order);
        req.setAttribute("alarm", alarm);
        req.setAttribute("createMode", createMode);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "workorder");
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/workorder_detail.jsp").forward(req, resp);
    }

    private void handleLedgerList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String deviceType = req.getParameter("deviceType");
        String scrapStatus = req.getParameter("scrapStatus");
        List<DeviceLedger> ledgers = alarmService.listLedgers(deviceType, scrapStatus);

        req.setAttribute("ledgers", ledgers);
        req.setAttribute("deviceType", deviceType);
        req.setAttribute("scrapStatus", scrapStatus);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "ledger");
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/ledger_list.jsp").forward(req, resp);
    }

    private void handleLedgerDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/alarm?action=ledgerList&module=alarm");
            return;
        }
        Long ledgerId = Long.valueOf(idStr);
        DeviceLedger ledger = alarmService.getLedger(ledgerId);
        List<WorkOrder> orders = alarmService.listWorkOrdersForLedger(ledgerId);

        req.setAttribute("ledger", ledger);
        req.setAttribute("orders", orders);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "ledger");
        req.getRequestDispatcher("/WEB-INF/jsp/alarm/ledger_detail.jsp").forward(req, resp);
    }

    private void handleUpdateAlarmStatus(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        Long alarmId = Long.valueOf(req.getParameter("alarmId"));
        String processStatus = req.getParameter("processStatus");
        alarmService.updateAlarmStatus(alarmId, processStatus);
        String target = req.getContextPath() + "/alarm?action=detail&id=" + alarmId + "&module=alarm";
        resp.sendRedirect(buildRedirect(target, "处理状态已更新"));
    }

    private void handleCreateWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        WorkOrder order = new WorkOrder();
        order.setAlarmId(Long.valueOf(req.getParameter("alarmId")));
        order.setLedgerId(parseLong(req.getParameter("ledgerId")));
        order.setOandmId(parseLong(req.getParameter("oandmId")));
        order.setDispatchTime(parseDateTime(req.getParameter("dispatchTime")));
        order.setResultDesc(req.getParameter("resultDesc"));
        order.setReviewStatus(req.getParameter("reviewStatus"));
        order.setAttachmentPath(req.getParameter("attachmentPath"));

        Long id = alarmService.createWorkOrder(order);
        String target = req.getContextPath() + "/alarm?action=workorderDetail&id=" + id + "&module=alarm";
        resp.sendRedirect(buildRedirect(target, "运维工单已创建"));
    }

    private void handleUpdateWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        WorkOrder order = new WorkOrder();
        order.setOrderId(Long.valueOf(req.getParameter("orderId")));
        order.setAlarmId(parseLong(req.getParameter("alarmId")));
        order.setLedgerId(parseLong(req.getParameter("ledgerId")));
        order.setOandmId(parseLong(req.getParameter("oandmId")));
        order.setDispatchTime(parseDateTime(req.getParameter("dispatchTime")));
        order.setResponseTime(parseDateTime(req.getParameter("responseTime")));
        order.setFinishTime(parseDateTime(req.getParameter("finishTime")));
        order.setResultDesc(req.getParameter("resultDesc"));
        order.setReviewStatus(req.getParameter("reviewStatus"));
        order.setAttachmentPath(req.getParameter("attachmentPath"));

        alarmService.updateWorkOrder(order);
        String target = req.getContextPath() + "/alarm?action=workorderDetail&id=" + order.getOrderId() + "&module=alarm";
        resp.sendRedirect(buildRedirect(target, "工单信息已更新"));
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

    private String buildRedirect(String target, String message) {
    	String encoded;
    	try {
    	    encoded = URLEncoder.encode(message == null ? "" : message, StandardCharsets.UTF_8.name());
    	} catch (Exception e) {
    	    // 理论上不会发生，因为 UTF-8 必定存在
    	    encoded = "";
    	}
        return target + "&message=" + encoded;
    }
}
