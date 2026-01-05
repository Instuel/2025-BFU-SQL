package com.bjfu.energy.controller;

import com.bjfu.energy.dao.AnalystDao;
import com.bjfu.energy.dao.DistMonitorDao;
import com.bjfu.energy.dao.EnergyDao;
import com.bjfu.energy.dao.ExecDashboardDao;
import com.bjfu.energy.dao.AdminDao;
import com.bjfu.energy.dao.PvDao;
import com.bjfu.energy.entity.SysUser;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * 简单路由控制器：
 *  /app?module=dashboard|dist|pv|energy|alarm|admin
 *  仅负责转发到对应的 JSP 占位页
 */
public class AppRouterServlet extends HttpServlet {

    private final EnergyDao energyDao = new EnergyDao();
    private final PvDao pvDao = new PvDao();
    private final ExecDashboardDao execDashboardDao = new ExecDashboardDao();
    private final DistMonitorDao distMonitorDao = new DistMonitorDao();
    private final AnalystDao analystDao = new AnalystDao();
    private final AdminDao adminDao = new AdminDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String module = req.getParameter("module");
        if (module == null || module.trim().isEmpty()) {
            module = "dashboard";
        }
        String roleType = null;
        if (req.getSession(false) != null) {
            roleType = (String) req.getSession(false).getAttribute("currentRoleType");
        }

        String jsp;

        switch (module) {

            case "dashboard": {
                roleType = getRoleType(req);
                String viewParam = req.getParameter("view");

                // ===== 企业管理层（EXEC）+ 能源管理员（ENERGY）的大屏入口 =====
                // EXEC：默认 execDesk
                // ENERGY：只有带 view 参数（例如 execScreen / execHighAlarm）才走这里；
                //         不带 view 仍然走后面的“能源管理员工作台 dashboard.jsp”
                if ("EXEC".equals(roleType)
                        || ("ENERGY".equals(roleType) && viewParam != null && !viewParam.trim().isEmpty())) {

                    String execView = (viewParam == null || viewParam.trim().isEmpty())
                            ? "execDesk"
                            : viewParam.trim();

                    // 能源管理员只允许访问 execScreen / execHighAlarm
                    if ("ENERGY".equals(roleType)
                            && !"execScreen".equals(execView)
                            && !"execHighAlarm".equals(execView)) {
                        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "仅企业管理层可访问该功能");
                        return;
                    }

                    try {
                        switch (execView) {
                            case "execDesk":
                                // 仅展示入口卡片，无需加载重数据
                                jsp = "/WEB-INF/jsp/exec/exec_desk.jsp";
                                break;

                            case "execScreen": {
                                // 大屏：实时汇总 + 月度概览 + 光伏/配电统计 + 高等级告警 + 历史趋势
                                req.setAttribute("monthlyOverview", execDashboardDao.getMonthlyOverview());
                                req.setAttribute("screenRealtime", execDashboardDao.getRealtimeSummary());
                                req.setAttribute("pvStats", pvDao.getPvStats());
                                req.setAttribute("highAlarms", execDashboardDao.listHighAlarms(6));
                                req.setAttribute("screenConfigs", execDashboardDao.listDashboardConfigs());

                                String trendEnergyType = req.getParameter("trendEnergyType");
                                String trendCycle = req.getParameter("trendCycle");
                                if (trendEnergyType == null || trendEnergyType.trim().isEmpty()) {
                                    trendEnergyType = "电";
                                }
                                if (trendCycle == null || trendCycle.trim().isEmpty()) {
                                    trendCycle = "月";
                                }

                                req.setAttribute("trendEnergyType", trendEnergyType);
                                req.setAttribute("trendCycle", trendCycle);
                                req.setAttribute("screenTrends",
                                        execDashboardDao.listHistoryTrends(trendEnergyType, trendCycle, 12));

                                applyFlashMessage(req);
                                jsp = "/WEB-INF/jsp/exec/exec_screen.jsp";
                                break;
                            }

                            case "execProject": {
                                // 科研项目：申报/结题 + 列表
                                req.setAttribute("openProjects", execDashboardDao.listOpenProjects());
                                req.setAttribute("recentProjects", execDashboardDao.listResearchProjects());
                                applyFlashMessage(req);
                                jsp = "/WEB-INF/jsp/exec/exec_project.jsp";
                                break;
                            }

                            case "execHighAlarm": {
                                // 高等级告警推送：从大屏进入，仅列表展示
                                req.setAttribute("highAlarms", execDashboardDao.listHighAlarms(100));
                                applyFlashMessage(req);
                                jsp = "/WEB-INF/jsp/exec/exec_high_alarm.jsp";
                                break;
                            }

                            default:
                                jsp = "/WEB-INF/jsp/exec/exec_desk.jsp";
                                break;
                        }
                    } catch (Exception e) {
                        throw new ServletException("企业管理层/大屏数据加载失败: " + e.getMessage(), e);
                    }

                    // 直接 forward，避免继续走 dashboard.jsp 的加载逻辑
                    req.getRequestDispatcher(jsp).forward(req, resp);
                    return;
                }

                // ===== 其他角色进入 dashboard.jsp =====
                if ("ADMIN".equals(roleType)) {
                    try {
                        req.setAttribute("systemCounters", adminDao.loadSystemCounters());
                        req.setAttribute("latestBackupTime", adminDao.findLatestBackupTime());
                        req.setAttribute("dbLatencyMs", adminDao.measureDbLatencyMs());
                        req.setAttribute("apiAvailability", adminDao.loadApiAvailability());
                        Map<String, Double> diskUsage = adminDao.queryDiskUsage();
                        if (diskUsage != null) {
                            req.setAttribute("diskUsedGb", diskUsage.get("usedGb"));
                            req.setAttribute("diskTotalGb", diskUsage.get("totalGb"));
                            req.setAttribute("diskUsagePercent", diskUsage.get("percent"));
                        }
                    } catch (Exception e) {
                        throw new ServletException("系统管理员工作台数据加载失败: " + e.getMessage(), e);
                    }
                }

                if ("ENERGY".equals(roleType)) {
                    try {
                        req.setAttribute("pendingReviewCount", energyDao.getPendingReviewCount());
                        req.setAttribute("activePlanCount", energyDao.getActivePlanCount());
                        req.setAttribute("highConsumptionCount", energyDao.listHighConsumptionAreas().size());
                    } catch (Exception e) {
                        throw new ServletException("能源管理员工作台数据加载失败: " + e.getMessage(), e);
                    }
                }

                loadAnalystDashboard(req);
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
            }

            case "dist": {
                resp.sendRedirect(req.getContextPath() + "/dist?action=room_list");
                return;
            }

            case "pv": {
                String pvView = req.getParameter("view");
                if (pvView == null || pvView.trim().isEmpty()) {
                    pvView = "device_list";
                }

                try {
                    switch (pvView) {
                        case "device_detail": {
                            Long deviceId = parseLong(req.getParameter("id"));
                            if (deviceId == null) {
                                deviceId = pvDao.findFirstDeviceId();
                            }
                            req.setAttribute("device", deviceId == null ? null : pvDao.findDeviceById(deviceId));
                            List<Map<String, Object>> genRecords =
                                    deviceId == null ? java.util.Collections.emptyList() : pvDao.listGenData(deviceId, null);
                            req.setAttribute("genRecords", genRecords);
                            req.setAttribute("latestGenRecord", genRecords.isEmpty() ? null : genRecords.get(0));
                            jsp = "/WEB-INF/jsp/pv/device_detail.jsp";
                            break;
                        }

                        case "gen_data_list": {
                            Long pointId = parseLong(req.getParameter("pointId"));
                            req.setAttribute("gridPoints", pvDao.listGridPoints());
                            req.setAttribute("selectedPointId", pointId);
                            List<Map<String, Object>> genDataRecords = pvDao.listGenData(null, pointId);
                            req.setAttribute("genRecords", genDataRecords);
                            req.setAttribute("latestGenRecord", genDataRecords.isEmpty() ? null : genDataRecords.get(0));
                            jsp = "/WEB-INF/jsp/pv/gen_data_list.jsp";
                            break;
                        }

                        case "forecast_list": {
                            Long forecastPointId = parseLong(req.getParameter("pointId"));
                            req.setAttribute("gridPoints", pvDao.listGridPoints());
                            req.setAttribute("selectedPointId", forecastPointId);
                            List<Map<String, Object>> forecastRecords = pvDao.listForecasts(forecastPointId);
                            req.setAttribute("forecasts", forecastRecords);
                            req.setAttribute("latestForecast", forecastRecords.isEmpty() ? null : forecastRecords.get(0));

                            // 计算统计数据
                            int deviationOverCount = 0;
                            double totalForecastVal = 0;
                            double totalDeviationRate = 0;
                            int deviationCount = 0;
                            for (Map<String, Object> forecast : forecastRecords) {
                                Object forecastVal = forecast.get("forecastVal");
                                if (forecastVal != null) {
                                    totalForecastVal += ((Number) forecastVal).doubleValue();
                                }
                                Object rate = forecast.get("deviationRate");
                                if (rate != null) {
                                    double deviationRate = ((Number) rate).doubleValue();
                                    totalDeviationRate += deviationRate;
                                    deviationCount++;
                                    if (Math.abs(deviationRate) > 15) {
                                        deviationOverCount++;
                                    }
                                }
                            }
                            req.setAttribute("deviationOverCount", deviationOverCount);
                            req.setAttribute("totalForecastVal", String.format("%.2f", totalForecastVal));
                            req.setAttribute("avgDeviationRate", deviationCount > 0
                                    ? String.format("%.2f", totalDeviationRate / deviationCount)
                                    : "--");

                            jsp = "/WEB-INF/jsp/pv/forecast_list.jsp";
                            break;
                        }

                        case "forecast_detail": {
                            Long forecastId = parseLong(req.getParameter("id"));
                            if (forecastId == null) {
                                List<Map<String, Object>> forecasts = pvDao.listForecasts(null);
                                if (!forecasts.isEmpty()) {
                                    Object fid = forecasts.get(0).get("forecastId");
                                    if (fid instanceof Number) {
                                        forecastId = ((Number) fid).longValue();
                                    }
                                }
                            }
                            req.setAttribute("forecast", forecastId == null ? null : pvDao.findForecastById(forecastId));
                            jsp = "/WEB-INF/jsp/pv/forecast_detail.jsp";
                            break;
                        }

                        case "model_alert_list": {
                            String statusFilter = req.getParameter("statusFilter");
                            req.setAttribute("selectedStatusFilter", statusFilter);
                            req.setAttribute("modelAlerts", pvDao.listModelAlerts(statusFilter));
                            jsp = "/WEB-INF/jsp/pv/model_alert_list.jsp";
                            break;
                        }

                        case "device_list":
                        default: {
                            String sortBy = req.getParameter("sortBy");
                            String sortOrder = req.getParameter("sortOrder");
                            req.setAttribute("pvStats", pvDao.getPvStats());
                            req.setAttribute("devices", pvDao.listDevices(sortBy, sortOrder));
                            req.setAttribute("selectedSortBy", sortBy);
                            req.setAttribute("selectedSortOrder", sortOrder);
                            jsp = "/WEB-INF/jsp/pv/device_list.jsp";
                            break;
                        }
                    }
                } catch (Exception e) {
                    throw new ServletException("光伏模块数据加载失败: " + e.getMessage(), e);
                }
                break;
            }

            case "energy": {
                String energyView = req.getParameter("view");
                if (energyView == null || energyView.trim().isEmpty()) {
                    energyView = "meter_list";
                }

                try {
                    switch (energyView) {
                        case "meter_detail": {
                            Long meterId = parseLong(req.getParameter("id"));
                            if (meterId == null) {
                                meterId = energyDao.findFirstMeterId();
                            }
                            req.setAttribute("meter", meterId == null ? null : energyDao.findMeterById(meterId));
                            List<Map<String, Object>> energyRecords =
                                    meterId == null ? java.util.Collections.emptyList() : energyDao.listEnergyData(meterId, null);
                            req.setAttribute("energyRecords", energyRecords);
                            req.setAttribute("latestEnergyRecord", energyRecords.isEmpty() ? null : energyRecords.get(0));
                            jsp = "/WEB-INF/jsp/energy/meter_detail.jsp";
                            break;
                        }

                        case "energy_data_list": {
                            Long factoryId = parseLong(req.getParameter("factoryId"));
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", factoryId);
                            List<Map<String, Object>> energyRecordsList = energyDao.listEnergyData(null, factoryId);
                            req.setAttribute("energyRecords", energyRecordsList);
                            req.setAttribute("latestEnergyRecord", energyRecordsList.isEmpty() ? null : energyRecordsList.get(0));
                            jsp = "/WEB-INF/jsp/energy/energy_data_list.jsp";
                            break;
                        }

                        case "peak_valley_list": {
                            Long pvFactoryId = parseLong(req.getParameter("factoryId"));
                            String pvEnergyType = req.getParameter("energyType");
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", pvFactoryId);
                            req.setAttribute("selectedEnergyType", pvEnergyType);
                            req.setAttribute("peakValleySummaries", energyDao.listPeakValleySummary(pvFactoryId, pvEnergyType));
                            req.setAttribute("reportStats", energyDao.getLatestPeakValleyReportStats());
                            jsp = "/WEB-INF/jsp/energy/peak_valley_list.jsp";
                            break;
                        }

                        case "peak_valley_report": {
                            req.setAttribute("reportStats", energyDao.getLatestPeakValleyReportStats());
                            req.setAttribute("reportItems", energyDao.listPeakValleySummary(null, null));
                            jsp = "/WEB-INF/jsp/energy/peak_valley_report.jsp";
                            break;
                        }

                        case "report_overview": {
                            Long reportFactoryId = parseLong(req.getParameter("factoryId"));
                            String reportEnergyType = req.getParameter("energyType");
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", reportFactoryId);
                            req.setAttribute("selectedEnergyType", reportEnergyType);
                            req.setAttribute("monthlyStats", energyDao.getLatestMonthlyReportStats());
                            req.setAttribute("monthlyReports", energyDao.listMonthlyEnergyReports(reportFactoryId, reportEnergyType));
                            jsp = "/WEB-INF/jsp/energy/energy_report_overview.jsp";
                            break;
                        }

                        case "data_review": {
                            Long reviewFactoryId = parseLong(req.getParameter("factoryId"));
                            String reviewEnergyType = req.getParameter("energyType");
                            String quality = req.getParameter("quality");
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", reviewFactoryId);
                            req.setAttribute("selectedEnergyType", reviewEnergyType);
                            req.setAttribute("selectedQuality", quality);
                            req.setAttribute("reviewStats", energyDao.getQualityReviewStats(reviewFactoryId, reviewEnergyType, quality));
                            req.setAttribute("reviewRecords", energyDao.listQualityIssueRecords(reviewFactoryId, reviewEnergyType, quality));
                            jsp = "/WEB-INF/jsp/energy/energy_data_review.jsp";
                            break;
                        }

                        case "optimization_plan": {
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("planStats", energyDao.getOptimizationStats());
                            req.setAttribute("plans", energyDao.listOptimizationPlans());

                            // 复用峰谷动态统计结果，作为制定优化方案的参考数据
                            req.setAttribute("reportStats", energyDao.getLatestPeakValleyReportStats());
                            req.setAttribute("peakValleySummaries", energyDao.listPeakValleySummary(null, null));

                            jsp = "/WEB-INF/jsp/energy/energy_optimization_plan.jsp";
                            break;
                        }

                        case "investigation_list": {
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("investigationStats", energyDao.getInvestigationStats());
                            req.setAttribute("highConsumptionAreas", energyDao.listHighConsumptionAreas());
                            req.setAttribute("investigations", energyDao.listInvestigations());
                            jsp = "/WEB-INF/jsp/energy/energy_investigation_list.jsp";
                            break;
                        }

                        case "meter_list":
                        default: {
                            String energyType = req.getParameter("energyType");
                            Long listFactoryId = parseLong(req.getParameter("factoryId"));
                            String runStatus = req.getParameter("runStatus");
                            String keyword = req.getParameter("keyword");
                            req.setAttribute("meterStats", energyDao.getMeterStats());
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedEnergyType", energyType);
                            req.setAttribute("selectedFactoryId", listFactoryId);
                            req.setAttribute("selectedRunStatus", runStatus);
                            req.setAttribute("keyword", keyword);
                            req.setAttribute("meters", energyDao.listMeters(energyType, listFactoryId, runStatus, keyword));

                            jsp = "/WEB-INF/jsp/energy/meter_list.jsp";
                            break;
                        }
                    }
                } catch (Exception e) {
                    throw new ServletException("综合能耗模块数据加载失败: " + e.getMessage(), e);
                }
                break;
            }

            case "alarm": {
                resp.sendRedirect(req.getContextPath() + "/alarm?action=list&module=alarm");
                return;
            }

            case "admin": {
                resp.sendRedirect(req.getContextPath() + "/admin?action=list");
                return;
            }

            default: {
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
            }
        }

        req.getRequestDispatcher(jsp).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String module = req.getParameter("module");

        // EXEC 的 POST 操作（决策/项目申报/结题）
        if ("dashboard".equals(module) && "EXEC".equals(getRoleType(req))) {
            String action = req.getParameter("action");
            try {
                if ("decisionUpdate".equals(action)) {
                    Long decisionId = parseLong(req.getParameter("decisionId"));
                    String status = req.getParameter("status");
                    if (decisionId != null && status != null && !status.trim().isEmpty()) {
                        execDashboardDao.updateDecisionStatus(decisionId, status.trim());
                        setFlashMessage(req, "success", "决策状态已更新");
                    } else {
                        setFlashMessage(req, "warning", "请选择有效的决策项与状态");
                    }
                } else if ("projectApply".equals(action)) {
                    String title = req.getParameter("projectTitle");
                    String summary = req.getParameter("projectSummary");
                    String applicant = getCurrentUserName(req);
                    if (title != null && !title.trim().isEmpty()) {
                        execDashboardDao.createResearchProject(title.trim(), summary, applicant);
                        setFlashMessage(req, "success", "科研项目申请已提交");
                    } else {
                        setFlashMessage(req, "warning", "请填写科研项目名称");
                    }
                } else if ("projectClose".equals(action)) {
                    Long projectId = parseLong(req.getParameter("projectId"));
                    String closeReport = req.getParameter("closeReport");
                    if (projectId != null && closeReport != null && !closeReport.trim().isEmpty()) {
                        execDashboardDao.submitResearchClosure(projectId, closeReport.trim());
                        setFlashMessage(req, "success", "科研项目结题报告已提交");
                    } else {
                        setFlashMessage(req, "warning", "请选择项目并填写结题报告");
                    }
                }

                // 允许页面指定提交后返回的 view；默认回到管理层工作台
                String returnView = req.getParameter("returnView");
                if (returnView == null || returnView.trim().isEmpty()) {
                    returnView = "execDesk";
                }
                resp.sendRedirect(req.getContextPath() + "/app?module=dashboard&view=" + returnView);
                return;

            } catch (Exception e) {
                throw new ServletException("管理层操作处理失败: " + e.getMessage(), e);
            }
        }

        // 非 energy 的 POST，直接交给 doGet 继续处理
        if (!"energy".equals(module)) {
            doGet(req, resp);
            return;
        }
        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            doGet(req, resp);
            return;
        }
        try {
            switch (action) {
                case "review_data":
                    handleReviewData(req, resp);
                    return;
                case "create_plan":
                    handleCreatePlan(req, resp);
                    return;
                case "create_investigation":
                    handleCreateInvestigation(req, resp);
                    return;
                case "create_meter":
                    handleCreateMeter(req, resp);
                    return;
                default:
                    doGet(req, resp);
            }
        } catch (Exception e) {
            throw new ServletException("能源管理员操作失败: " + e.getMessage(), e);
        }
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

    private String getRoleType(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return null;
        }
        Object roleType = session.getAttribute("currentRoleType");
        return roleType == null ? null : roleType.toString();
    }

    private String getCurrentUserName(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return "管理层";
        }
        SysUser user = (SysUser) session.getAttribute("currentUser");
        if (user == null || user.getRealName() == null || user.getRealName().trim().isEmpty()) {
            return "管理层";
        }
        return user.getRealName().trim();
    }

    private void setFlashMessage(HttpServletRequest req, String type, String message) {
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.setAttribute("execFlashType", type);
            session.setAttribute("execFlashMessage", message);
        }
    }

    private void applyFlashMessage(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return;
        }
        Object message = session.getAttribute("execFlashMessage");
        Object type = session.getAttribute("execFlashType");
        if (message != null) {
            req.setAttribute("execFlashMessage", message);
            req.setAttribute("execFlashType", type == null ? "info" : type);
            session.removeAttribute("execFlashMessage");
            session.removeAttribute("execFlashType");
        }
    }

    private void handleReviewData(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long dataId = parseLong(req.getParameter("dataId"));
        String reviewStatus = req.getParameter("reviewStatus");
        String reviewRemark = req.getParameter("reviewRemark");

        String reviewer = "系统";
        if (req.getSession(false) != null && req.getSession(false).getAttribute("currentUser") != null) {
            SysUser user = (SysUser) req.getSession(false).getAttribute("currentUser");
            reviewer = user.getRealName() != null ? user.getRealName() : user.getLoginAccount();
        }

        if (dataId == null || reviewStatus == null || reviewStatus.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=data_review&error=missing");
            return;
        }
        energyDao.upsertEnergyDataReview(dataId, reviewStatus.trim(), reviewer, reviewRemark);
        resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=data_review&success=review");
    }

    private void handleCreatePlan(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        String planTitle = req.getParameter("planTitle");
        String planAction = req.getParameter("planAction");
        String startDate = req.getParameter("startDate");
        String targetReduction = req.getParameter("targetReduction");

        String owner = "能源管理员";
        if (req.getSession(false) != null && req.getSession(false).getAttribute("currentUser") != null) {
            SysUser user = (SysUser) req.getSession(false).getAttribute("currentUser");
            owner = user.getRealName() != null ? user.getRealName() : user.getLoginAccount();
        }

        if (factoryId == null || energyType == null || energyType.trim().isEmpty()
                || planTitle == null || planTitle.trim().isEmpty()
                || planAction == null || planAction.trim().isEmpty()
                || startDate == null || startDate.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=optimization_plan&error=missing");
            return;
        }

        java.sql.Date date = java.sql.Date.valueOf(startDate);
        java.math.BigDecimal target = (targetReduction == null || targetReduction.trim().isEmpty())
                ? java.math.BigDecimal.ZERO
                : new java.math.BigDecimal(targetReduction.trim());

        energyDao.createOptimizationPlan(factoryId, energyType, planTitle.trim(), planAction.trim(), date, target, owner);
        resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=optimization_plan&success=plan");
    }

    private void handleCreateInvestigation(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String energyType = req.getParameter("energyType");
        String level = req.getParameter("level");
        String issueDesc = req.getParameter("issueDesc");

        String owner = "能源管理员";
        if (req.getSession(false) != null && req.getSession(false).getAttribute("currentUser") != null) {
            SysUser user = (SysUser) req.getSession(false).getAttribute("currentUser");
            owner = user.getRealName() != null ? user.getRealName() : user.getLoginAccount();
        }

        if (factoryId == null || energyType == null || energyType.trim().isEmpty()
                || issueDesc == null || issueDesc.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=investigation_list&error=missing");
            return;
        }

        String levelValue = (level == null || level.trim().isEmpty()) ? "重点排查" : level.trim();
        energyDao.createInvestigation(factoryId, energyType, levelValue, issueDesc.trim(), owner);
        resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=investigation_list&success=investigation");
    }

    private void handleCreateMeter(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String energyType = req.getParameter("energyType");
        Long factoryId = parseLong(req.getParameter("factoryId"));
        String installLocation = req.getParameter("installLocation");
        String commProtocol = req.getParameter("commProtocol");
        String calibCycleMonthsStr = req.getParameter("calibCycleMonths");
        String manufacturer = req.getParameter("manufacturer");

        // 验证必填字段
        if (energyType == null || energyType.trim().isEmpty()
                || factoryId == null
                || installLocation == null || installLocation.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=meter_list&error=missing");
            return;
        }

        // 解析校准周期
        Integer calibCycleMonths = null;
        if (calibCycleMonthsStr != null && !calibCycleMonthsStr.trim().isEmpty()) {
            try {
                calibCycleMonths = Integer.parseInt(calibCycleMonthsStr.trim());
            } catch (NumberFormatException e) {
                // 忽略无效数值
            }
        }

        // 调用DAO新增计量设备
        energyDao.createMeter(
            energyType.trim(),
            factoryId,
            installLocation.trim(),
            commProtocol != null ? commProtocol.trim() : null,
            calibCycleMonths,
            manufacturer != null ? manufacturer.trim() : null
        );

        resp.sendRedirect(req.getContextPath() + "/app?module=energy&view=meter_list&success=meter");
    }

    private void loadAnalystDashboard(HttpServletRequest req) throws ServletException {
        HttpSession session = req.getSession(false);
        String roleType = session == null ? null : (String) session.getAttribute("currentRoleType");
        if (!"ANALYST".equals(roleType)) {
            return;
        }
        try {
            int windowDays = 90;
            Map<String, Object> overview = analystDao.getForecastOverview(windowDays);
            Double lastWeekDeviation = analystDao.getAvgDeviationRate(7, 0);
            Double prevWeekDeviation = analystDao.getAvgDeviationRate(14, 7);
            String deviationTrend = buildDeviationTrend(lastWeekDeviation, prevWeekDeviation);
            int weatherCount = analystDao.countWeatherFactors(30);

            List<Map<String, Object>> forecastInsights = analystDao.listForecastDeviationInsights(6);
            List<Map<String, Object>> energyInsights = analystDao.listEnergyLineInsights(4);
            List<Map<String, Object>> reportItems = analystDao.listQuarterlyEnergyReports(4);
            List<Map<String, Object>> modelAlerts = analystDao.listModelAlerts(2);

            overview.put("dataWindowLabel", "近" + windowDays + "天");
            overview.put("deviationTrend", deviationTrend);
            overview.put("weatherHint", weatherCount > 0 ? "引入天气因子" : "待接入天气因子");
            overview.put("correlationTaskCount", energyInsights.size());
            overview.put("reportCount", reportItems.size());
            overview.put("pendingReportCount", countPendingReports(reportItems));

            req.setAttribute("analystOverview", overview);
            req.setAttribute("forecastInsights", forecastInsights);
            req.setAttribute("energyInsights", energyInsights);
            req.setAttribute("reportItems", reportItems);
            req.setAttribute("modelOptimizations", buildModelOptimizations(weatherCount, modelAlerts));
        } catch (Exception e) {
            throw new ServletException("数据分析师工作台数据加载失败: " + e.getMessage(), e);
        }
    }

    private String buildDeviationTrend(Double lastWeekDeviation, Double prevWeekDeviation) {
        if (lastWeekDeviation == null || prevWeekDeviation == null) {
            return "暂无对比数据";
        }
        double delta = lastWeekDeviation - prevWeekDeviation;
        String arrow = delta <= 0 ? "▼" : "▲";
        String state = delta <= 0 ? "优化后" : "需关注";
        return String.format("%s %.2f%% %s", arrow, Math.abs(delta), state);
    }

    private int countPendingReports(List<Map<String, Object>> reportItems) {
        int count = 0;
        for (Map<String, Object> item : reportItems) {
            Object status = item.get("reportStatus");
            if (status != null && !"表现良好".equals(status.toString())) {
                count++;
            }
        }
        return count;
    }

    private List<Map<String, Object>> buildModelOptimizations(int weatherCount, List<Map<String, Object>> alerts) {
        List<Map<String, Object>> items = new java.util.ArrayList<>();
        Map<String, Object> weather = new java.util.HashMap<>();
        weather.put("title", "天气因子融合");
        weather.put("desc", weatherCount > 0 ? "已完成特征工程" : "等待天气数据接入");
        weather.put("status", weatherCount > 0 ? "已上线" : "待接入");
        items.add(weather);

        for (Map<String, Object> alert : alerts) {
            Map<String, Object> item = new java.util.HashMap<>();
            item.put("title", "模型告警 - " + alert.get("pointName"));
            item.put("desc", alert.get("remark") == null ? "偏差超阈值，需复盘模型" : alert.get("remark"));
            item.put("status", alert.get("processStatus") == null ? "待处理" : alert.get("processStatus"));
            items.add(item);
        }

        if (alerts.isEmpty()) {
            Map<String, Object> fallback = new java.util.HashMap<>();
            fallback.put("title", "辐照度校准");
            fallback.put("desc", "等待外部数据比对");
            fallback.put("status", "排队中");
            items.add(fallback);
        }
        return items;
    }
}