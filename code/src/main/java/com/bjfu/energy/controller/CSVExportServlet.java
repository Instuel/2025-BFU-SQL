package com.bjfu.energy.controller;

import com.bjfu.energy.dao.EnergyDao;
import com.bjfu.energy.util.CSVExportUtil;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.*;

/**
 * CSV导出控制器
 */
public class CSVExportServlet extends HttpServlet {

    private final EnergyDao energyDao = new EnergyDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        String type = req.getParameter("type");
        if (type == null || type.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "缺少导出类型参数");
            return;
        }

        try {
            switch (type) {
                case "energy_data":
                    exportEnergyData(req, resp);
                    break;
                case "peak_valley":
                    exportPeakValley(req, resp);
                    break;
                case "monthly_report":
                    exportMonthlyReport(req, resp);
                    break;
                case "data_review":
                    exportDataReview(req, resp);
                    break;
                case "optimization_plan":
                    exportOptimizationPlan(req, resp);
                    break;
                case "meter_list":
                    exportMeterList(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "不支持的导出类型");
            }
        } catch (Exception e) {
            throw new ServletException("导出CSV失败: " + e.getMessage(), e);
        }
    }

    /**
     * 导出能耗监测数据
     */
    private void exportEnergyData(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        List<Map<String, Object>> data = energyDao.listEnergyData(null, factoryId);

        List<String> headers = Arrays.asList(
            "数据编号", "设备编号", "采集时间", "能耗值", "单位", "数据质量", "厂区"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("数据编号", "dataId");
        fieldMapping.put("设备编号", "meterCode");
        fieldMapping.put("采集时间", "collectTime");
        fieldMapping.put("能耗值", "value");
        fieldMapping.put("单位", "unit");
        fieldMapping.put("数据质量", "quality");
        fieldMapping.put("厂区", "factoryName");

        String filename = "能耗监测数据_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    /**
     * 导出峰谷统计数据
     */
    private void exportPeakValley(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        List<Map<String, Object>> data = energyDao.listPeakValleySummary(factoryId, energyType);

        List<String> headers = Arrays.asList(
            "统计日期", "厂区", "能源类型", "尖峰能耗", "高峰能耗", 
            "平段能耗", "低谷能耗", "总能耗", "成本(元)"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("统计日期", "statDate");
        fieldMapping.put("厂区", "factoryName");
        fieldMapping.put("能源类型", "energyType");
        fieldMapping.put("尖峰能耗", "peakConsumption");
        fieldMapping.put("高峰能耗", "highConsumption");
        fieldMapping.put("平段能耗", "flatConsumption");
        fieldMapping.put("低谷能耗", "valleyConsumption");
        fieldMapping.put("总能耗", "totalConsumption");
        fieldMapping.put("成本(元)", "totalCost");

        String filename = "峰谷统计数据_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    /**
     * 导出月度能耗报表
     */
    private void exportMonthlyReport(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        List<Map<String, Object>> data = energyDao.listMonthlyEnergyReports(factoryId, energyType);

        List<String> headers = Arrays.asList(
            "月份", "厂区", "能源类型", "峰时能耗", "低谷能耗", 
            "峰谷差值", "总能耗", "成本(元)"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("月份", "reportMonth");
        fieldMapping.put("厂区", "factoryName");
        fieldMapping.put("能源类型", "energyType");
        fieldMapping.put("峰时能耗", "peakConsumption");
        fieldMapping.put("低谷能耗", "valleyConsumption");
        fieldMapping.put("峰谷差值", "peakValleyGap");
        fieldMapping.put("总能耗", "totalConsumption");
        fieldMapping.put("成本(元)", "totalCost");

        String filename = "月度能耗报表_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    /**
     * 导出数据审核记录
     */
    private void exportDataReview(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        String quality = req.getParameter("quality");
        List<Map<String, Object>> data = energyDao.listQualityIssueRecords(factoryId, energyType, quality);

        List<String> headers = Arrays.asList(
            "数据编号", "设备编号", "能源类型", "采集时间", "能耗值", 
            "单位", "质量等级", "厂区", "复核状态", "复核人", "复核时间", "复核说明"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("数据编号", "dataId");
        fieldMapping.put("设备编号", "meterCode");
        fieldMapping.put("能源类型", "energyType");
        fieldMapping.put("采集时间", "collectTime");
        fieldMapping.put("能耗值", "value");
        fieldMapping.put("单位", "unit");
        fieldMapping.put("质量等级", "quality");
        fieldMapping.put("厂区", "factoryName");
        fieldMapping.put("复核状态", "reviewStatus");
        fieldMapping.put("复核人", "reviewer");
        fieldMapping.put("复核时间", "reviewTime");
        fieldMapping.put("复核说明", "reviewRemark");

        String filename = "数据审核记录_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    /**
     * 导出优化方案
     */
    private void exportOptimizationPlan(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        List<Map<String, Object>> data = energyDao.listOptimizationPlans();

        List<String> headers = Arrays.asList(
            "方案名称", "厂区", "能源类型", "执行动作", 
            "目标降耗(%)", "实际降耗(%)", "状态", "启动日期"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("方案名称", "planTitle");
        fieldMapping.put("厂区", "factoryName");
        fieldMapping.put("能源类型", "energyType");
        fieldMapping.put("执行动作", "planAction");
        fieldMapping.put("目标降耗(%)", "targetReduction");
        fieldMapping.put("实际降耗(%)", "actualReduction");
        fieldMapping.put("状态", "status");
        fieldMapping.put("启动日期", "startDate");

        String filename = "能耗优化方案_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    /**
     * 导出计量设备清单
     */
    private void exportMeterList(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String runStatus = req.getParameter("runStatus");
        String keyword = req.getParameter("keyword");
        List<Map<String, Object>> data = energyDao.listMeters(energyType, factoryId, runStatus, keyword);

        List<String> headers = Arrays.asList(
            "设备编号", "能源类型", "安装位置", "管径规格", 
            "通讯协议", "运行状态", "校准周期(月)", "制造商", "厂区"
        );

        Map<String, String> fieldMapping = new LinkedHashMap<>();
        fieldMapping.put("设备编号", "meterCode");
        fieldMapping.put("能源类型", "energyType");
        fieldMapping.put("安装位置", "installLocation");
        fieldMapping.put("管径规格", "modelSpec");
        fieldMapping.put("通讯协议", "commProtocol");
        fieldMapping.put("运行状态", "runStatus");
        fieldMapping.put("校准周期(月)", "calibCycleMonths");
        fieldMapping.put("制造商", "manufacturer");
        fieldMapping.put("厂区", "factoryName");

        String filename = "计量设备清单_" + getCurrentDateString();
        CSVExportUtil.exportCSV(resp, filename, headers, data, fieldMapping);
    }

    private Long parseLong(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String getCurrentDateString() {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyyMMdd");
        return sdf.format(new java.util.Date());
    }
}