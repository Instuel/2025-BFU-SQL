package com.bjfu.energy.controller;

import com.bjfu.energy.dao.EnergyDao;
import com.bjfu.energy.util.PDFReportUtil;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 能源报告Servlet - 处理报告生成和PDF导出
 */
public class EnergyReportServlet extends HttpServlet {

    private final EnergyDao energyDao = new EnergyDao();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        
        if (action == null || action.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "缺少action参数");
            return;
        }

        try {
            switch (action) {
                case "generateReport":
                    generateReport(req, resp);
                    break;
                case "exportPDF":
                    exportPDF(req, resp);
                    break;
                case "getReportData":
                    getReportData(req, resp);
                    break;
                case "generateMonthlyReport":
                    generateMonthlyReport(req, resp);
                    break;
                case "exportMonthlyPDF":
                    exportMonthlyPDF(req, resp);
                    break;
                case "getMonthlyReportData":
                    getMonthlyReportData(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "不支持的操作");
            }
        } catch (Exception e) {
            throw new ServletException("处理报告请求失败: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }

    /**
     * 生成报告 - 返回JSON数据
     */
    private void generateReport(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        String period = req.getParameter("period"); // 日/周/月
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String dateStr = req.getParameter("date");

        // 查询峰谷统计数据
        List<Map<String, Object>> data = energyDao.listPeakValleySummary(factoryId, energyType);
        
        // 生成报告摘要
        Map<String, Object> reportSummary = generateReportSummary(data, period, dateStr);
        
        // 返回JSON响应
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(reportSummary));
        out.flush();
    }

    /**
     * 导出PDF报告
     */
    private void exportPDF(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        String period = req.getParameter("period"); // 日/周/月
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String dateStr = req.getParameter("date");

        // 查询数据
        List<Map<String, Object>> data = energyDao.listPeakValleySummary(factoryId, energyType);
        
        // 生成报告摘要
        Map<String, Object> reportSummary = generateReportSummary(data, period, dateStr);
        
        // 生成PDF文件名
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
        String filename = "日能耗成本报告_" + sdf.format(new Date());
        
        // 使用PDF工具类生成PDF
        PDFReportUtil.exportPDF(resp, filename, reportSummary, data);
    }

    /**
     * 获取报告数据(Ajax调用)
     */
    private void getReportData(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        
        List<Map<String, Object>> data = energyDao.listPeakValleySummary(factoryId, energyType);
        
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(data));
        out.flush();
    }

    /**
     * 生成报告摘要
     */
    private Map<String, Object> generateReportSummary(List<Map<String, Object>> data, 
                                                       String period, String dateStr) {
        Map<String, Object> summary = new HashMap<>();
        
        // 统计总计
        double totalConsumption = 0;
        double totalCost = 0;
        double peakConsumption = 0;
        double valleyConsumption = 0;
        
        for (Map<String, Object> row : data) {
            totalConsumption += getDoubleValue(row, "totalConsumption");
            totalCost += getDoubleValue(row, "totalCost");
            peakConsumption += getDoubleValue(row, "peakConsumption");
            valleyConsumption += getDoubleValue(row, "valleyConsumption");
        }
        
        summary.put("totalConsumption", String.format("%.2f", totalConsumption));
        summary.put("totalCost", String.format("%.2f", totalCost));
        summary.put("peakConsumption", String.format("%.2f", peakConsumption));
        summary.put("valleyConsumption", String.format("%.2f", valleyConsumption));
        summary.put("period", period != null ? period : "日");
        summary.put("date", dateStr != null ? dateStr : new SimpleDateFormat("yyyy-MM-dd").format(new Date()));
        summary.put("itemCount", data.size());
        summary.put("generateTime", new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        
        // 计算节能建议
        double peakRatio = totalConsumption > 0 ? (peakConsumption / totalConsumption) * 100 : 0;
        String suggestion = "";
        if (peakRatio > 60) {
            suggestion = "峰时能耗占比较高(" + String.format("%.1f", peakRatio) + "%)，建议优化生产时段安排，将部分负荷转移至低谷时段。";
        } else if (peakRatio > 40) {
            suggestion = "峰时能耗占比适中(" + String.format("%.1f", peakRatio) + "%)，可考虑进一步优化用能结构以降低成本。";
        } else {
            suggestion = "峰时能耗占比较低(" + String.format("%.1f", peakRatio) + "%)，用能结构良好，请继续保持。";
        }
        summary.put("suggestion", suggestion);
        summary.put("success", true);
        
        return summary;
    }

    /**
     * 从Map中获取double值
     */
    private double getDoubleValue(Map<String, Object> map, String key) {
        Object value = map.get(key);
        if (value == null) {
            return 0.0;
        }
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        try {
            return Double.parseDouble(value.toString());
        } catch (NumberFormatException e) {
            return 0.0;
        }
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
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    /**
     * 生成月度报告 - 返回JSON数据
     */
    private void generateMonthlyReport(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));

        // 查询月度报表数据
        List<Map<String, Object>> data = energyDao.listMonthlyEnergyReports(factoryId, energyType);
        
        // 生成月报摘要
        Map<String, Object> reportSummary = generateMonthlyReportSummary(data);
        
        // 返回JSON响应
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(reportSummary));
        out.flush();
    }

    /**
     * 导出月度报告PDF
     */
    private void exportMonthlyPDF(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));

        // 查询月度报表数据
        List<Map<String, Object>> data = energyDao.listMonthlyEnergyReports(factoryId, energyType);
        
        // 生成月报摘要
        Map<String, Object> reportSummary = generateMonthlyReportSummary(data);
        
        // 生成PDF文件名
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
        String filename = "月度能耗报告_" + sdf.format(new Date());
        
        // 使用PDF工具类生成PDF（月报版本）
        PDFReportUtil.exportMonthlyReportPDF(resp, filename, reportSummary, data);
    }

    /**
     * 获取月度报告数据(Ajax调用)
     */
    private void getMonthlyReportData(HttpServletRequest req, HttpServletResponse resp) 
            throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        
        List<Map<String, Object>> data = energyDao.listMonthlyEnergyReports(factoryId, energyType);
        
        resp.setContentType("application/json; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(data));
        out.flush();
    }

    /**
     * 生成月报摘要
     */
    private Map<String, Object> generateMonthlyReportSummary(List<Map<String, Object>> data) {
        Map<String, Object> summary = new HashMap<>();
        
        // 统计总计
        double totalConsumption = 0;
        double totalCost = 0;
        double peakConsumption = 0;
        double valleyConsumption = 0;
        String latestMonth = "";
        
        for (Map<String, Object> row : data) {
            totalConsumption += getDoubleValue(row, "totalConsumption");
            totalCost += getDoubleValue(row, "totalCost");
            peakConsumption += getDoubleValue(row, "peakConsumption");
            valleyConsumption += getDoubleValue(row, "valleyConsumption");
            
            // 获取最新月份
            String month = (String) row.get("reportMonth");
            if (month != null && (latestMonth.isEmpty() || month.compareTo(latestMonth) > 0)) {
                latestMonth = month;
            }
        }
        
        summary.put("totalConsumption", String.format("%.2f", totalConsumption));
        summary.put("totalCost", String.format("%.2f", totalCost));
        summary.put("peakConsumption", String.format("%.2f", peakConsumption));
        summary.put("valleyConsumption", String.format("%.2f", valleyConsumption));
        summary.put("latestMonth", latestMonth);
        summary.put("itemCount", data.size());
        summary.put("generateTime", new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        
        // 计算峰谷差值分析
        double peakValleyGap = peakConsumption - valleyConsumption;
        summary.put("peakValleyGap", String.format("%.2f", peakValleyGap));
        
        // 计算峰谷比
        double peakValleyRatio = valleyConsumption > 0 ? (peakConsumption / valleyConsumption) : 0;
        summary.put("peakValleyRatio", String.format("%.2f", peakValleyRatio));
        
        // 生成分析建议
        String analysis = "";
        if (peakValleyRatio > 2.0) {
            analysis = "峰谷能耗差异较大(峰谷比" + String.format("%.2f", peakValleyRatio) + ")，建议重点关注高峰时段的能耗控制，可通过调整生产计划降低峰时负荷。";
        } else if (peakValleyRatio > 1.5) {
            analysis = "峰谷能耗差异适中(峰谷比" + String.format("%.2f", peakValleyRatio) + ")，能源使用结构相对合理，可继续优化以进一步降低成本。";
        } else {
            analysis = "峰谷能耗分布均衡(峰谷比" + String.format("%.2f", peakValleyRatio) + ")，能源管理表现良好。";
        }
        summary.put("analysis", analysis);
        summary.put("success", true);
        
        return summary;
    }
}
