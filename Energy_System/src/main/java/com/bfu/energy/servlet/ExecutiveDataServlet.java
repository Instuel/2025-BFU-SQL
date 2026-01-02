package com.bfu.energy.servlet;

import com.bfu.energy.dao.*;
import com.bfu.energy.entity.*;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;

@WebServlet("/api/executive/*")
public class ExecutiveDataServlet extends HttpServlet {

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

        if (pathInfo.equals("/dashboard-stats")) {
            getDashboardStats(req, resp);
        } else if (pathInfo.equals("/overview-stats")) {
            getOverviewStats(req, resp);
        } else if (pathInfo.equals("/energy-trend")) {
            getEnergyTrend(req, resp);
        } else if (pathInfo.equals("/pv-data")) {
            getPVData(req, resp);
        } else if (pathInfo.equals("/source-analysis")) {
            getSourceAnalysis(req, resp);
        } else if (pathInfo.equals("/alarms")) {
            getAlarms(req, resp);
        } else if (pathInfo.equals("/report-data")) {
            getReportData(req, resp);
        } else if (pathInfo.equals("/reports")) {
            getReports(req, resp);
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

        sendError(resp, "无效的请求路径");
    }

    private void getDashboardStats(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalEnergy", "125,680");
            stats.put("pvRevenue", "45,230");
            stats.put("activeAlarms", "12");
            stats.put("efficiency", "92.5%");
            stats.put("monthlyCost", "8.5");
            stats.put("savings", "3.2");
            stats.put("targetProgress", "87%");
            stats.put("reportCount", "24");
            
            result.put("success", true);
            result.put("data", stats);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取仪表板统计数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getOverviewStats(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalEnergy", "125,680");
            stats.put("pvRevenue", "45,230");
            stats.put("activeAlarms", "12");
            stats.put("efficiency", "92.5%");
            stats.put("energyChange", -5.2);
            stats.put("revenueChange", 8.3);
            stats.put("alarmChange", -15.0);
            stats.put("efficiencyChange", 3.1);
            stats.put("selfUseRate", "78.5%");
            stats.put("gridPurchase", "2,450");
            stats.put("gridFeed", "1,230");
            stats.put("carbonReduction", "12.5吨");
            
            result.put("success", true);
            result.put("data", stats);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取总览统计数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getEnergyTrend(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            String timeRange = req.getParameter("timeRange");
            
            List<Map<String, Object>> trendData = new ArrayList<>();
            
            if ("day".equals(timeRange)) {
                for (int i = 0; i < 24; i++) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", i + ":00");
                    point.put("energy", 500 + (int)(Math.random() * 200));
                    trendData.add(point);
                }
            } else if ("week".equals(timeRange)) {
                String[] days = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};
                for (String day : days) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", day);
                    point.put("energy", 12000 + (int)(Math.random() * 3000));
                    trendData.add(point);
                }
            } else if ("month".equals(timeRange)) {
                for (int i = 1; i <= 30; i++) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", i + "日");
                    point.put("energy", 4000 + (int)(Math.random() * 1000));
                    trendData.add(point);
                }
            } else {
                String[] quarters = {"Q1", "Q2", "Q3", "Q4"};
                for (String quarter : quarters) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", quarter);
                    point.put("energy", 350000 + (int)(Math.random() * 50000));
                    trendData.add(point);
                }
            }
            
            result.put("success", true);
            result.put("data", trendData);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取能源趋势数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getPVData(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            String timeRange = req.getParameter("timeRange");
            
            List<Map<String, Object>> pvData = new ArrayList<>();
            
            if ("day".equals(timeRange)) {
                for (int i = 6; i <= 18; i++) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", i + ":00");
                    point.put("generation", 100 + (int)(Math.random() * 200));
                    point.put("revenue", 50 + (int)(Math.random() * 100));
                    pvData.add(point);
                }
            } else if ("week".equals(timeRange)) {
                String[] days = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};
                for (String day : days) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", day);
                    point.put("generation", 2500 + (int)(Math.random() * 500));
                    point.put("revenue", 1250 + (int)(Math.random() * 250));
                    pvData.add(point);
                }
            } else {
                for (int i = 1; i <= 30; i++) {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", i + "日");
                    point.put("generation", 800 + (int)(Math.random() * 200));
                    point.put("revenue", 400 + (int)(Math.random() * 100));
                    pvData.add(point);
                }
            }
            
            result.put("success", true);
            result.put("data", pvData);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取光伏数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private void getSourceAnalysis(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            List<Map<String, Object>> sourceData = new ArrayList<>();
            
            sourceData.add(createSourceItem("生产设备A", "45,230", "36%", "↓ 2.1%"));
            sourceData.add(createSourceItem("生产设备B", "38,450", "31%", "↑ 1.5%"));
            sourceData.add(createSourceItem("生产设备C", "25,670", "20%", "↓ 0.8%"));
            sourceData.add(createSourceItem("辅助设备", "16,330", "13%", "↑ 3.2%"));
            
            result.put("success", true);
            result.put("data", sourceData);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取溯源分析数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private Map<String, Object> createSourceItem(String name, String energy, String percentage, String trend) {
        Map<String, Object> item = new HashMap<>();
        item.put("name", name);
        item.put("energy", energy);
        item.put("percentage", percentage);
        item.put("trend", trend);
        return item;
    }

    private void getAlarms(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            String level = req.getParameter("level");
            
            List<Map<String, Object>> alarms = new ArrayList<>();
            
            alarms.add(createAlarm("high", "高", "2024-01-15 10:30:00", "35KV变压器温度过高", "变压器#1"));
            alarms.add(createAlarm("medium", "中", "2024-01-15 09:45:00", "光伏逆变器效率下降", "逆变器#3"));
            alarms.add(createAlarm("medium", "中", "2024-01-15 08:20:00", "生产设备能耗异常", "生产设备A"));
            alarms.add(createAlarm("low", "低", "2024-01-15 07:10:00", "辅助设备运行时间过长", "辅助设备#2"));
            alarms.add(createAlarm("high", "高", "2024-01-14 16:50:00", "配电室电压波动", "配电柜#5"));
            
            if (!"all".equals(level)) {
                alarms = new ArrayList<>();
                if ("high".equals(level)) {
                    alarms.add(createAlarm("high", "高", "2024-01-15 10:30:00", "35KV变压器温度过高", "变压器#1"));
                    alarms.add(createAlarm("high", "高", "2024-01-14 16:50:00", "配电室电压波动", "配电柜#5"));
                } else if ("medium".equals(level)) {
                    alarms.add(createAlarm("medium", "中", "2024-01-15 09:45:00", "光伏逆变器效率下降", "逆变器#3"));
                    alarms.add(createAlarm("medium", "中", "2024-01-15 08:20:00", "生产设备能耗异常", "生产设备A"));
                } else {
                    alarms.add(createAlarm("low", "低", "2024-01-15 07:10:00", "辅助设备运行时间过长", "辅助设备#2"));
                }
            }
            
            result.put("success", true);
            result.put("data", alarms);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取告警列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private Map<String, Object> createAlarm(String level, String levelText, String time, String content, String device) {
        Map<String, Object> alarm = new HashMap<>();
        alarm.put("level", level);
        alarm.put("levelText", levelText);
        alarm.put("time", time);
        alarm.put("content", content);
        alarm.put("device", device);
        return alarm;
    }

    private void getReportData(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            Map<String, Object> reportData = new HashMap<>();
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalCost", "85.2万元");
            stats.put("savings", "32.5万元");
            stats.put("efficiency", "92.5%");
            stats.put("costChange", "-5.2%");
            stats.put("savingsChange", "+8.3%");
            stats.put("efficiencyChange", "+3.1%");
            reportData.put("stats", stats);
            
            Map<String, Object> comparison = new HashMap<>();
            comparison.put("electricityCost", createComparisonData("45.6万元", "-5.2%"));
            comparison.put("pvRevenue", createComparisonData("32.5万元", "+8.3%"));
            reportData.put("comparison", comparison);
            
            result.put("success", true);
            result.put("data", reportData);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取报告数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private Map<String, Object> createComparisonData(String value, String change) {
        Map<String, Object> comparison = new HashMap<>();
        comparison.put("value", value);
        comparison.put("change", change);
        return comparison;
    }

    private void getReports(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            List<Map<String, Object>> reports = new ArrayList<>();
            
            reports.add(createReport("RPT-2024-001", "2024年1月能耗总结报告", "completed", "已完成", "月度报告", "2024-01-15", "本月总能耗125,680kWh，节能收益32.5万元，目标完成率87%"));
            reports.add(createReport("RPT-2024-002", "2024年Q1能耗总结报告", "in-progress", "进行中", "季度报告", "2024-01-10", "Q1能耗分析报告正在编制中"));
            reports.add(createReport("RPT-2023-012", "2023年12月能耗总结报告", "completed", "已完成", "月度报告", "2023-12-31", "12月总能耗118,520kWh，节能收益28.3万元"));
            reports.add(createReport("RPT-2023-011", "2023年Q4能耗总结报告", "completed", "已完成", "季度报告", "2023-12-31", "Q4总能耗356,800kWh，节能收益95.2万元"));
            reports.add(createReport("RPT-2024-003", "2024年2月能耗预测报告", "pending", "待生成", "月度报告", "2024-01-20", "预计2月能耗120,000kWh"));
            
            result.put("success", true);
            result.put("data", reports);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取报告列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private Map<String, Object> createReport(String id, String title, String statusClass, String statusText, String period, String createTime, String summary) {
        Map<String, Object> report = new HashMap<>();
        report.put("id", id);
        report.put("title", title);
        report.put("statusClass", statusClass);
        report.put("statusText", statusText);
        report.put("period", period);
        report.put("createTime", createTime);
        report.put("summary", summary);
        return report;
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