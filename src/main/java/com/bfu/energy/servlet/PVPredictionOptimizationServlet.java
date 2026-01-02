package com.bfu.energy.servlet;

import com.bfu.energy.dao.DataPVForecastDAO;
import com.bfu.energy.dao.PVForecastModelDAO;
import com.bfu.energy.dao.PVGridPointDAO;
import com.bfu.energy.entity.DataPVForecast;
import com.bfu.energy.entity.PVForecastModel;
import com.bfu.energy.entity.PVGridPoint;
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

@WebServlet("/api/analysis/pv-prediction")
public class PVPredictionOptimizationServlet extends HttpServlet {

    private Gson gson = new Gson();
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            DataPVForecastDAO forecastDAO = (DataPVForecastDAO) com.bfu.energy.dao.DAOFactory.getDAO(DataPVForecastDAO.class);
            PVForecastModelDAO modelDAO = (PVForecastModelDAO) com.bfu.energy.dao.DAOFactory.getDAO(PVForecastModelDAO.class);
            PVGridPointDAO pointDAO = (PVGridPointDAO) com.bfu.energy.dao.DAOFactory.getDAO(PVGridPointDAO.class);
            
            String pointIdStr = req.getParameter("pointId");
            String modelVersion = req.getParameter("modelVersion");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");
            String timeSlot = req.getParameter("timeSlot");
            
            List<DataPVForecast> forecasts = forecastDAO.findAll();
            
            List<DataPVForecast> filteredForecasts = new ArrayList<>();
            for (DataPVForecast forecast : forecasts) {
                if (pointIdStr != null && !pointIdStr.isEmpty() && !forecast.getPointId().equals(Long.parseLong(pointIdStr))) {
                    continue;
                }
                if (modelVersion != null && !modelVersion.isEmpty() && !modelVersion.equals(forecast.getModelVersion())) {
                    continue;
                }
                if (timeSlot != null && !timeSlot.isEmpty() && !timeSlot.equals(forecast.getTimeSlot())) {
                    continue;
                }
                if (startDateStr != null && !startDateStr.isEmpty()) {
                    Date forecastDate = forecast.getForecastDate();
                    Date startDate = dateFormat.parse(startDateStr);
                    if (forecastDate.before(startDate)) {
                        continue;
                    }
                }
                if (endDateStr != null && !endDateStr.isEmpty()) {
                    Date forecastDate = forecast.getForecastDate();
                    Date endDate = dateFormat.parse(endDateStr);
                    if (forecastDate.after(endDate)) {
                        continue;
                    }
                }
                filteredForecasts.add(forecast);
            }
            
            Map<String, Object> stats = calculateStats(filteredForecasts);
            Map<String, Object> chartData = prepareChartData(filteredForecasts, pointDAO);
            List<Map<String, Object>> tableData = prepareTableData(filteredForecasts, pointDAO);
            Map<String, Object> modelInfo = getModelInfo(modelDAO);
            
            Map<String, Object> data = new HashMap<>();
            data.put("stats", stats);
            data.put("chartData", chartData);
            data.put("tableData", tableData);
            data.put("modelInfo", modelInfo);
            
            result.put("success", true);
            result.put("data", data);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取光伏预测数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }

    private Map<String, Object> calculateStats(List<DataPVForecast> forecasts) {
        Map<String, Object> stats = new HashMap<>();
        
        double totalDeviation = 0;
        double maxDeviation = 0;
        int validCount = 0;
        
        for (DataPVForecast forecast : forecasts) {
            if (forecast.getForecastVal() != null && forecast.getActualVal() != null && forecast.getActualVal() > 0) {
                double deviation = Math.abs(forecast.getForecastVal() - forecast.getActualVal()) / forecast.getActualVal() * 100;
                totalDeviation += deviation;
                if (deviation > maxDeviation) {
                    maxDeviation = deviation;
                }
                validCount++;
            }
        }
        
        double avgDeviation = validCount > 0 ? totalDeviation / validCount : 0;
        double accuracy = 100 - avgDeviation;
        
        stats.put("accuracy", Math.round(accuracy * 10.0) / 10.0);
        stats.put("avgDeviation", Math.round(avgDeviation * 10.0) / 10.0);
        stats.put("maxDeviation", Math.round(maxDeviation * 10.0) / 10.0);
        stats.put("sampleCount", forecasts.size());
        
        return stats;
    }

    private Map<String, Object> prepareChartData(List<DataPVForecast> forecasts, PVGridPointDAO pointDAO) {
        Map<String, Object> chartData = new HashMap<>();
        
        List<String> labels = new ArrayList<>();
        List<Double> forecastValues = new ArrayList<>();
        List<Double> actualValues = new ArrayList<>();
        
        Map<String, PVGridPoint> pointMap = new HashMap<>();
        for (PVGridPoint point : pointDAO.findAll()) {
            pointMap.put(String.valueOf(point.getPointId()), point);
        }
        
        forecasts.sort(Comparator.comparing(DataPVForecast::getForecastDate)
                .thenComparing(DataPVForecast::getTimeSlot));
        
        for (DataPVForecast forecast : forecasts) {
            String dateStr = dateFormat.format(forecast.getForecastDate());
            String timeSlot = forecast.getTimeSlot();
            String pointName = pointMap.containsKey(String.valueOf(forecast.getPointId())) 
                    ? pointMap.get(String.valueOf(forecast.getPointId())).getPointName() 
                    : "未知";
            labels.add(dateStr + " " + timeSlot + " " + pointName);
            forecastValues.add(forecast.getForecastVal() != null ? forecast.getForecastVal() : 0);
            actualValues.add(forecast.getActualVal() != null ? forecast.getActualVal() : 0);
        }
        
        chartData.put("labels", labels);
        chartData.put("forecastValues", forecastValues);
        chartData.put("actualValues", actualValues);
        
        return chartData;
    }

    private List<Map<String, Object>> prepareTableData(List<DataPVForecast> forecasts, PVGridPointDAO pointDAO) {
        List<Map<String, Object>> tableData = new ArrayList<>();
        
        Map<String, PVGridPoint> pointMap = new HashMap<>();
        for (PVGridPoint point : pointDAO.findAll()) {
            pointMap.put(String.valueOf(point.getPointId()), point);
        }
        
        for (DataPVForecast forecast : forecasts) {
            Map<String, Object> row = new HashMap<>();
            row.put("date", dateFormat.format(forecast.getForecastDate()));
            row.put("timeSlot", forecast.getTimeSlot());
            
            String pointName = pointMap.containsKey(String.valueOf(forecast.getPointId())) 
                    ? pointMap.get(String.valueOf(forecast.getPointId())).getPointName() 
                    : "未知";
            row.put("pointName", pointName);
            row.put("forecastVal", forecast.getForecastVal() != null ? forecast.getForecastVal() : 0);
            row.put("actualVal", forecast.getActualVal() != null ? forecast.getActualVal() : 0);
            
            double deviation = 0;
            if (forecast.getForecastVal() != null && forecast.getActualVal() != null && forecast.getActualVal() > 0) {
                deviation = Math.abs(forecast.getForecastVal() - forecast.getActualVal()) / forecast.getActualVal() * 100;
            }
            row.put("deviation", Math.round(deviation * 10.0) / 10.0);
            row.put("modelVersion", forecast.getModelVersion());
            
            tableData.add(row);
        }
        
        return tableData;
    }

    private Map<String, Object> getModelInfo(PVForecastModelDAO modelDAO) {
        Map<String, Object> modelInfo = new HashMap<>();
        
        List<PVForecastModel> models = modelDAO.findAll();
        if (!models.isEmpty()) {
            PVForecastModel latestModel = models.get(0);
            modelInfo.put("modelVersion", latestModel.getModelVersion());
            modelInfo.put("modelName", latestModel.getModelName());
            modelInfo.put("status", latestModel.getStatus());
            modelInfo.put("updateTime", latestModel.getUpdateTime() != null 
                    ? dateFormat.format(latestModel.getUpdateTime()) 
                    : "未知");
        } else {
            modelInfo.put("modelVersion", "v1.0");
            modelInfo.put("modelName", "Basic Model");
            modelInfo.put("status", "运行中");
            modelInfo.put("updateTime", "2024-01-01");
        }
        
        return modelInfo;
    }
}