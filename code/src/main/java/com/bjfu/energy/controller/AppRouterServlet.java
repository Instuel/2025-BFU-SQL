package com.bjfu.energy.controller;

import com.bjfu.energy.dao.EnergyDao;
import com.bjfu.energy.dao.PvDao;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String module = req.getParameter("module");
        if (module == null || module.trim().isEmpty()) {
            module = "dashboard";
        }

        String jsp;
        switch (module) {
            case "dashboard":
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
            case "dist":
                resp.sendRedirect(req.getContextPath() + "/dist?action=room_list");
                return;
            case "pv":
                String view = req.getParameter("view");
                if (view == null || view.trim().isEmpty()) {
                    view = "device_list";
                }
                try {
                    switch (view) {
                        case "device_detail":
                            Long deviceId = parseLong(req.getParameter("id"));
                            if (deviceId == null) {
                                deviceId = pvDao.findFirstDeviceId();
                            }
                            req.setAttribute("device", deviceId == null ? null : pvDao.findDeviceById(deviceId));
                            List<Map<String, Object>> genRecords = deviceId == null ? java.util.Collections.emptyList() : pvDao.listGenData(deviceId, null);
                            req.setAttribute("genRecords", genRecords);
                            req.setAttribute("latestGenRecord", genRecords.isEmpty() ? null : genRecords.get(0));
                            jsp = "/WEB-INF/jsp/pv/device_detail.jsp";
                            break;
                        case "gen_data_list":
                            Long pointId = parseLong(req.getParameter("pointId"));
                            req.setAttribute("gridPoints", pvDao.listGridPoints());
                            req.setAttribute("selectedPointId", pointId);
                            List<Map<String, Object>> genDataRecords = pvDao.listGenData(null, pointId);
                            req.setAttribute("genRecords", genDataRecords);
                            req.setAttribute("latestGenRecord", genDataRecords.isEmpty() ? null : genDataRecords.get(0));
                            jsp = "/WEB-INF/jsp/pv/gen_data_list.jsp";
                            break;
                        case "forecast_list":
                            Long forecastPointId = parseLong(req.getParameter("pointId"));
                            req.setAttribute("gridPoints", pvDao.listGridPoints());
                            req.setAttribute("selectedPointId", forecastPointId);
                            List<Map<String, Object>> forecastRecords = pvDao.listForecasts(forecastPointId);
                            req.setAttribute("forecasts", forecastRecords);
                            req.setAttribute("latestForecast", forecastRecords.isEmpty() ? null : forecastRecords.get(0));
                            jsp = "/WEB-INF/jsp/pv/forecast_list.jsp";
                            break;
                        case "forecast_detail":
                            Long forecastId = parseLong(req.getParameter("id"));
                            if (forecastId == null) {
                                List<Map<String, Object>> forecasts = pvDao.listForecasts(null);
                                if (!forecasts.isEmpty()) {
                                    forecastId = ((Number) forecasts.get(0).get("forecastId")).longValue();
                                }
                            }
                            req.setAttribute("forecast", forecastId == null ? null : pvDao.findForecastById(forecastId));
                            jsp = "/WEB-INF/jsp/pv/forecast_detail.jsp";
                            break;
                        case "model_alert_list":
                            req.setAttribute("modelAlerts", pvDao.listModelAlerts());
                            jsp = "/WEB-INF/jsp/pv/model_alert_list.jsp";
                            break;
                        case "device_list":
                        default:
                            req.setAttribute("pvStats", pvDao.getPvStats());
                            req.setAttribute("devices", pvDao.listDevices());
                            jsp = "/WEB-INF/jsp/pv/device_list.jsp";
                            break;
                    }
                } catch (Exception e) {
                    throw new ServletException("光伏模块数据加载失败: " + e.getMessage(), e);
                }
                break;
            case "energy":
                view = req.getParameter("view");
                if (view == null || view.trim().isEmpty()) {
                    view = "meter_list";
                }
                try {
                    switch (view) {
                        case "meter_detail":
                            Long meterId = parseLong(req.getParameter("id"));
                            if (meterId == null) {
                                meterId = energyDao.findFirstMeterId();
                            }
                            req.setAttribute("meter", meterId == null ? null : energyDao.findMeterById(meterId));
                            List<Map<String, Object>> energyRecords = meterId == null ? java.util.Collections.emptyList() : energyDao.listEnergyData(meterId, null);
                            req.setAttribute("energyRecords", energyRecords);
                            req.setAttribute("latestEnergyRecord", energyRecords.isEmpty() ? null : energyRecords.get(0));
                            jsp = "/WEB-INF/jsp/energy/meter_detail.jsp";
                            break;
                        case "energy_data_list":
                            Long factoryId = parseLong(req.getParameter("factoryId"));
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", factoryId);
                            List<Map<String, Object>> energyRecordsList = energyDao.listEnergyData(null, factoryId);
                            req.setAttribute("energyRecords", energyRecordsList);
                            req.setAttribute("latestEnergyRecord", energyRecordsList.isEmpty() ? null : energyRecordsList.get(0));
                            jsp = "/WEB-INF/jsp/energy/energy_data_list.jsp";
                            break;
                        case "peak_valley_list":
                            Long pvFactoryId = parseLong(req.getParameter("factoryId"));
                            String pvEnergyType = req.getParameter("energyType");
                            req.setAttribute("factories", energyDao.listFactories());
                            req.setAttribute("selectedFactoryId", pvFactoryId);
                            req.setAttribute("selectedEnergyType", pvEnergyType);
                            req.setAttribute("peakValleySummaries", energyDao.listPeakValleySummary(pvFactoryId, pvEnergyType));
                            req.setAttribute("reportStats", energyDao.getLatestPeakValleyReportStats());
                            jsp = "/WEB-INF/jsp/energy/peak_valley_list.jsp";
                            break;
                        case "peak_valley_report":
                            req.setAttribute("reportStats", energyDao.getLatestPeakValleyReportStats());
                            req.setAttribute("reportItems", energyDao.listPeakValleySummary(null, null));
                            jsp = "/WEB-INF/jsp/energy/peak_valley_report.jsp";
                            break;
                        case "meter_list":
                        default:
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
                } catch (Exception e) {
                    throw new ServletException("综合能耗模块数据加载失败: " + e.getMessage(), e);
                }
                break;
            case "alarm":
                resp.sendRedirect(req.getContextPath() + "/alarm?action=list&module=alarm");
                return;
            case "admin":
                resp.sendRedirect(req.getContextPath() + "/admin?action=list");
                return;
            default:
                jsp = "/WEB-INF/jsp/dashboard/dashboard.jsp";
                break;
        }

        req.getRequestDispatcher(jsp).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
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
}
