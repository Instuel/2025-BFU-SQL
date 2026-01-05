package com.bjfu.energy.controller;

import com.bjfu.energy.entity.AlarmInfo;
import com.bjfu.energy.entity.DeviceLedger;
import com.bjfu.energy.entity.MaintenancePlan;
import com.bjfu.energy.entity.WorkOrder;
import com.bjfu.energy.service.AlarmService;

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
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * 运维人员(OM)工单管理模块
 * 专门为OM角色设计的工单管理功能，只包含OM需要的操作
 */
@MultipartConfig
public class OMWorkOrderServlet extends HttpServlet {

    private final AlarmService alarmService = new AlarmService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "workorderList";
        }

        req.setAttribute("module", "om_workorder");

        try {
            switch (action) {
                case "workorderList":
                    handleWorkOrderList(req, resp);
                    break;
                case "workorderDetail":
                    handleWorkOrderDetail(req, resp);
                    break;
                case "alarmList":
                    handleAlarmList(req, resp);
                    break;
                case "alarmDetail":
                    handleAlarmDetail(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("运维工单请求处理失败: " + e.getMessage(), e);
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
                case "updateWorkOrder":
                    handleUpdateWorkOrder(req, resp);
                    break;
                case "submitWorkOrder":
                    handleSubmitWorkOrder(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("运维工单操作失败: " + e.getMessage(), e);
        }
    }

    private void handleWorkOrderList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String status = req.getParameter("status");
        String reviewStatus = req.getParameter("reviewStatus");
        
        // 获取当前登录的运维人员信息
        com.bjfu.energy.entity.SysUser currentUser = (com.bjfu.energy.entity.SysUser) req.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        
        // 获取运维人员ID
        String omId = String.valueOf(currentUser.getUserId());
        
        // 查询分配给当前运维人员的工单
        List<WorkOrder> workOrders = alarmService.listWorkOrdersByOM(omId, status, reviewStatus);
        
        req.setAttribute("workOrders", workOrders);
        req.setAttribute("status", status);
        req.setAttribute("reviewStatus", reviewStatus);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("workorderTab", "workorder");
        req.getRequestDispatcher("/WEB-INF/jsp/om/workorder_list.jsp").forward(req, resp);
    }

    private void handleWorkOrderDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String orderId = req.getParameter("id");
        if (orderId == null || orderId.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "工单ID不能为空");
            return;
        }

        WorkOrder workOrder = alarmService.findWorkOrderById(orderId);
        if (workOrder == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "工单不存在");
            return;
        }

        // 获取关联的告警信息
        AlarmInfo alarm = alarmService.getAlarm(workOrder.getAlarmId());
        
        req.setAttribute("workOrder", workOrder);
        req.setAttribute("alarm", alarm);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/om/workorder_detail.jsp").forward(req, resp);
    }

    private void handleAlarmList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String alarmType = req.getParameter("alarmType");
        String alarmLevel = req.getParameter("alarmLevel");
        String processStatus = req.getParameter("processStatus");
        String verifyStatus = req.getParameter("verifyStatus");
        
        // 获取当前登录的运维人员信息
        com.bjfu.energy.entity.SysUser currentUser = (com.bjfu.energy.entity.SysUser) req.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        
        // 获取运维人员所属厂区ID
        Long userFactoryId = null;
        com.bjfu.energy.dao.RoleOandMDao roleOandMDao = new com.bjfu.energy.dao.RoleOandMDaoImpl();
        com.bjfu.energy.entity.RoleOandM oandm = roleOandMDao.findByUserId(currentUser.getUserId());
        if (oandm != null) {
            userFactoryId = oandm.getFactoryId();
        }
        
        // 查询当前厂区的告警
        List<AlarmInfo> alarms = alarmService.listAlarmsByFactory(userFactoryId, alarmType, alarmLevel, processStatus, verifyStatus);

        req.setAttribute("alarms", alarms);
        req.setAttribute("alarmType", alarmType);
        req.setAttribute("alarmLevel", alarmLevel);
        req.setAttribute("processStatus", processStatus);
        req.setAttribute("verifyStatus", verifyStatus);
        req.setAttribute("message", req.getParameter("message"));
        req.setAttribute("alarmTab", "alarm");
        req.getRequestDispatcher("/WEB-INF/jsp/om/alarm_list.jsp").forward(req, resp);
    }

    private void handleAlarmDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException, ServletException {
        String alarmId = req.getParameter("id");
        if (alarmId == null || alarmId.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "告警ID不能为空");
            return;
        }

        AlarmInfo alarm = alarmService.getAlarm(Long.valueOf(alarmId));
        if (alarm == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "告警不存在");
            return;
        }

        // 查询关联的工单信息（仅查询分配给当前运维人员的工单）
        com.bjfu.energy.entity.SysUser currentUser = (com.bjfu.energy.entity.SysUser) req.getSession().getAttribute("currentUser");
        String omId = currentUser != null ? String.valueOf(currentUser.getUserId()) : null;
        WorkOrder workOrder = alarmService.findWorkOrderByAlarmIdAndOM(alarmId, omId);
        
        req.setAttribute("alarm", alarm);
        req.setAttribute("workOrder", workOrder);
        req.setAttribute("message", req.getParameter("message"));
        req.getRequestDispatcher("/WEB-INF/jsp/om/alarm_detail.jsp").forward(req, resp);
    }

    private void handleUpdateWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        String orderId = req.getParameter("orderId");
        String alarmId = req.getParameter("alarmId");
        String responseTime = req.getParameter("responseTime");
        String completionTime = req.getParameter("completionTime");
        String processResult = req.getParameter("processResult");
        
        // 处理附件上传
        String attachmentPath = null;
        Part filePart = req.getPart("attachment");
        if (filePart != null && filePart.getSize() > 0) {
            String fileName = filePart.getSubmittedFileName();
            if (fileName != null && !fileName.trim().isEmpty()) {
                // 创建上传目录
                String uploadDir = getServletContext().getRealPath("/uploads");
                Path uploadPath = Paths.get(uploadDir);
                if (!Files.exists(uploadPath)) {
                    Files.createDirectories(uploadPath);
                }
                
                // 生成唯一文件名
                String fileExt = fileName.substring(fileName.lastIndexOf("."));
                String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
                Path filePath = uploadPath.resolve(uniqueFileName);
                
                // 保存文件
                filePart.write(filePath.toString());
                attachmentPath = "/uploads/" + uniqueFileName;
            }
        }
        
        // 更新工单信息
        boolean success = alarmService.updateWorkOrder(
            orderId, 
            responseTime, 
            completionTime, 
            attachmentPath, 
            processResult
        );
        
        if (success) {
            resp.sendRedirect(req.getContextPath() + "/om-workorder?action=workorderDetail&id=" + orderId + "&message=工单保存成功");
        } else {
            resp.sendRedirect(req.getContextPath() + "/om-workorder?action=workorderDetail&id=" + orderId + "&message=工单保存失败");
        }
    }

    private void handleSubmitWorkOrder(HttpServletRequest req, HttpServletResponse resp)
            throws Exception, IOException {
        String orderId = req.getParameter("orderId");
        String alarmId = req.getParameter("alarmId");
        String responseTime = req.getParameter("responseTime");
        String completionTime = req.getParameter("completionTime");
        String processResult = req.getParameter("processResult");
        
        // 处理附件上传
        String attachmentPath = null;
        Part filePart = req.getPart("attachment");
        if (filePart != null && filePart.getSize() > 0) {
            String fileName = filePart.getSubmittedFileName();
            if (fileName != null && !fileName.trim().isEmpty()) {
                // 创建上传目录
                String uploadDir = getServletContext().getRealPath("/uploads");
                Path uploadPath = Paths.get(uploadDir);
                if (!Files.exists(uploadPath)) {
                    Files.createDirectories(uploadPath);
                }
                
                // 生成唯一文件名
                String fileExt = fileName.substring(fileName.lastIndexOf("."));
                String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
                Path filePath = uploadPath.resolve(uniqueFileName);
                
                // 保存文件
                filePart.write(filePath.toString());
                attachmentPath = "/uploads/" + uniqueFileName;
            }
        }
        
        // 提交工单（更新工单信息并设置复查状态为待审核）
        boolean success = alarmService.submitWorkOrder(
            orderId, 
            responseTime, 
            completionTime, 
            attachmentPath, 
            processResult
        );
        
        if (success) {
            resp.sendRedirect(req.getContextPath() + "/om-workorder?action=workorderDetail&id=" + orderId + "&message=工单提交成功，等待管理员审核");
        } else {
            resp.sendRedirect(req.getContextPath() + "/om-workorder?action=workorderDetail&id=" + orderId + "&message=工单提交失败");
        }
    }
}