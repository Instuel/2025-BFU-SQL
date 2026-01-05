package com.bjfu.energy.controller;

import com.bjfu.energy.dao.EnergyDao;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

/**
 * 能源计量设备管理Servlet
 * 处理设备的新增、修改、删除等操作
 */
public class EnergyMeterServlet extends HttpServlet {

    private final EnergyDao energyDao = new EnergyDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        String action = req.getParameter("action");
        
        if (action == null || action.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "缺少action参数");
            return;
        }

        try {
            switch (action) {
                case "create":
                    createMeter(req, resp);
                    break;
                case "update":
                    updateMeter(req, resp);
                    break;
                case "delete":
                    deleteMeter(req, resp);
                    break;
                case "getMeterInfo":
                    getMeterInfo(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "不支持的操作");
            }
        } catch (Exception e) {
            throw new ServletException("处理计量设备请求失败: " + e.getMessage(), e);
        }
    }

    /**
     * 新增计量设备
     */
    private void createMeter(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        
        // 获取参数
        String energyType = req.getParameter("energyType");
        String commProtocol = req.getParameter("commProtocol");
        String runStatus = req.getParameter("runStatus");
        String installLocation = req.getParameter("installLocation");
        String calibCycleMonths = req.getParameter("calibCycleMonths");
        String manufacturer = req.getParameter("manufacturer");
        Long factoryId = parseLong(req.getParameter("factoryId"));
        Long ledgerId = parseLong(req.getParameter("ledgerId"));

        // 验证必填参数
        if (energyType == null || energyType.trim().isEmpty()) {
            returnJson(resp, false, "能源类型不能为空");
            return;
        }
        if (factoryId == null) {
            returnJson(resp, false, "厂区不能为空");
            return;
        }

        // 设置默认值
        if (runStatus == null || runStatus.trim().isEmpty()) {
            runStatus = "正常";
        }

        // 调用DAO新增
        energyDao.createMeter(
            energyType.trim(),
            commProtocol != null ? commProtocol.trim() : null,
            runStatus.trim(),
            installLocation != null ? installLocation.trim() : null,
            calibCycleMonths != null && !calibCycleMonths.trim().isEmpty() 
                ? Integer.parseInt(calibCycleMonths.trim()) : null,
            manufacturer != null ? manufacturer.trim() : null,
            factoryId,
            ledgerId
        );

        returnJson(resp, true, "设备新增成功");
    }

    /**
     * 更新计量设备
     */
    private void updateMeter(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        
        Long meterId = parseLong(req.getParameter("meterId"));
        if (meterId == null) {
            returnJson(resp, false, "设备ID不能为空");
            return;
        }

        String energyType = req.getParameter("energyType");
        String commProtocol = req.getParameter("commProtocol");
        String runStatus = req.getParameter("runStatus");
        String installLocation = req.getParameter("installLocation");
        String calibCycleMonths = req.getParameter("calibCycleMonths");
        String manufacturer = req.getParameter("manufacturer");
        Long factoryId = parseLong(req.getParameter("factoryId"));

        energyDao.updateMeter(
            meterId,
            energyType != null ? energyType.trim() : null,
            commProtocol != null ? commProtocol.trim() : null,
            runStatus != null ? runStatus.trim() : null,
            installLocation != null ? installLocation.trim() : null,
            calibCycleMonths != null && !calibCycleMonths.trim().isEmpty() 
                ? Integer.parseInt(calibCycleMonths.trim()) : null,
            manufacturer != null ? manufacturer.trim() : null,
            factoryId
        );

        returnJson(resp, true, "设备更新成功");
    }

    /**
     * 删除计量设备
     */
    private void deleteMeter(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        
        Long meterId = parseLong(req.getParameter("meterId"));
        if (meterId == null) {
            returnJson(resp, false, "设备ID不能为空");
            return;
        }

        energyDao.deleteMeter(meterId);
        returnJson(resp, true, "设备删除成功");
    }

    /**
     * 获取设备信息（用于编辑）
     */
    private void getMeterInfo(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        
        Long meterId = parseLong(req.getParameter("meterId"));
        if (meterId == null) {
            returnJson(resp, false, "设备ID不能为空");
            return;
        }

        Map<String, Object> meter = energyDao.findMeterById(meterId);
        if (meter == null) {
            returnJson(resp, false, "设备不存在");
            return;
        }

        // 返回设备信息
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("data", meter);
        
        out.print(gson.toJson(result));
        out.flush();
    }

    /**
     * 返回JSON响应
     */
    private void returnJson(HttpServletResponse resp, boolean success, String message) 
            throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", message);
        
        out.print(gson.toJson(result));
        out.flush();
    }

    /**
     * 解析Long参数
     */
    private Long parseLong(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
