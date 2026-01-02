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
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.*;

@WebServlet("/api/analysis/energy-pattern")
public class EnergyConsumptionPatternServlet extends HttpServlet {

    private Gson gson = new Gson();
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            DataEnergyDAO energyDAO = (DataEnergyDAO) com.bfu.energy.dao.DAOFactory.getDAO(DataEnergyDAO.class);
            StatHistoryTrendDAO trendDAO = (StatHistoryTrendDAO) com.bfu.energy.dao.DAOFactory.getDAO(StatHistoryTrendDAO.class);
            BaseFactoryDAO factoryDAO = (BaseFactoryDAO) com.bfu.energy.dao.DAOFactory.getDAO(BaseFactoryDAO.class);
            EnergyMeterDAO meterDAO = (EnergyMeterDAO) com.bfu.energy.dao.DAOFactory.getDAO(EnergyMeterDAO.class);
            
            String factoryIdStr = req.getParameter("factoryId");
            String energyType = req.getParameter("energyType");
            String statCycle = req.getParameter("statCycle");
            String startDateStr = req.getParameter("startDate");
            String endDateStr = req.getParameter("endDate");
            
            List<BaseFactory> factories = factoryDAO.findAll();
            List<EnergyMeter> meters = meterDAO.findAll();
            
            List<DataEnergy> energyData = energyDAO.findAll();
            List<StatHistoryTrend> trendData = trendDAO.findAll();
            
            List<DataEnergy> filteredEnergyData = new ArrayList<>();
            for (DataEnergy energy : energyData) {
                if (factoryIdStr != null && !factoryIdStr.isEmpty() && 
                    (energy.getFactoryId() == null || !energy.getFactoryId().equals(Long.parseLong(factoryIdStr)))) {
                    continue;
                }
                
                if (startDateStr != null && !startDateStr.isEmpty()) {
                    try {
                        Date startDate = dateFormat.parse(startDateStr);
                        if (energy.getCollectTime().before(new Timestamp(startDate.getTime()))) {
                            continue;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                
                if (endDateStr != null && !endDateStr.isEmpty()) {
                    try {
                        Date endDate = dateFormat.parse(endDateStr);
                        Calendar cal = Calendar.getInstance();
                        cal.setTime(endDate);
                        cal.add(Calendar.DAY_OF_MONTH, 1);
                        if (energy.getCollectTime().after(new Timestamp(cal.getTimeInMillis()))) {
                            continue;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                
                filteredEnergyData.add(energy);
            }
            
            List<StatHistoryTrend> filteredTrendData = new ArrayList<>();
            for (StatHistoryTrend trend : trendData) {
                if (energyType != null && !energyType.isEmpty() && !energyType.equals(trend.getEnergyType())) {
                    continue;
                }
                if (statCycle != null && !statCycle.isEmpty() && !statCycle.equals(trend.getStatCycle())) {
                    continue;
                }
                if (startDateStr != null && !startDateStr.isEmpty()) {
                    try {
                        Date startDate = dateFormat.parse(startDateStr);
                        if (trend.getStatDate().before(new java.sql.Date(startDate.getTime()))) {
                            continue;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                if (endDateStr != null && !endDateStr.isEmpty()) {
                    try {
                        Date endDate = dateFormat.parse(endDateStr);
                        Calendar cal = Calendar.getInstance();
                        cal.setTime(endDate);
                        cal.add(Calendar.DAY_OF_MONTH, 1);
                        if (trend.getStatDate().after(new java.sql.Date(cal.getTimeInMillis()))) {
                            continue;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                filteredTrendData.add(trend);
            }
            
            Map<String, Object> stats = calculateStats(filteredEnergyData, filteredTrendData);
            Map<String, Object> chartData = prepareChartData(filteredEnergyData, filteredTrendData, factories);
            List<Map<String, Object>> tableData = prepareTableData(filteredTrendData, factories);
            List<Map<String, Object>> reportData = prepareReportData(filteredTrendData);
            
            Map<String, Object> data = new HashMap<>();
            data.put("stats", stats);
            data.put("chartData", chartData);
            data.put("tableData", tableData);
            data.put("reportData", reportData);
            data.put("factories", factories);
            data.put("energyTypes", getEnergyTypes(meters));
            
            result.put("success", true);
            result.put("data", data);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取能耗规律数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private Map<String, Object> calculateStats(List<DataEnergy> energyData, List<StatHistoryTrend> trendData) {
        Map<String, Object> stats = new HashMap<>();
        
        BigDecimal totalEnergy = BigDecimal.ZERO;
        for (DataEnergy energy : energyData) {
            if (energy.getValue() != null) {
                totalEnergy = totalEnergy.add(energy.getValue());
            }
        }
        
        BigDecimal totalProduction = BigDecimal.ZERO;
        for (DataEnergy energy : energyData) {
            if (energy.getValue() != null) {
                totalProduction = totalProduction.add(energy.getValue().divide(new BigDecimal("2.45"), 2, RoundingMode.HALF_UP));
            }
        }
        
        BigDecimal unitEnergy = totalProduction.compareTo(BigDecimal.ZERO) > 0 
            ? totalEnergy.divide(totalProduction, 2, RoundingMode.HALF_UP) 
            : BigDecimal.ZERO;
        
        double correlation = calculateCorrelation(energyData);
        
        stats.put("correlation", Math.round(correlation * 100.0) / 100.0);
        stats.put("unitEnergy", unitEnergy);
        stats.put("totalEnergy", formatNumber(totalEnergy));
        stats.put("totalProduction", formatNumber(totalProduction));
        
        return stats;
    }
    
    private double calculateCorrelation(List<DataEnergy> energyData) {
        if (energyData.size() < 2) {
            return 0.0;
        }
        
        List<Double> energyValues = new ArrayList<>();
        List<Double> productionValues = new ArrayList<>();
        
        for (DataEnergy energy : energyData) {
            if (energy.getValue() != null) {
                energyValues.add(energy.getValue().doubleValue());
                productionValues.add(energy.getValue().doubleValue() / 2.45);
            }
        }
        
        if (energyValues.size() < 2) {
            return 0.0;
        }
        
        double meanEnergy = energyValues.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        double meanProduction = productionValues.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        
        double numerator = 0.0;
        double denominatorEnergy = 0.0;
        double denominatorProduction = 0.0;
        
        for (int i = 0; i < energyValues.size(); i++) {
            double diffEnergy = energyValues.get(i) - meanEnergy;
            double diffProduction = productionValues.get(i) - meanProduction;
            
            numerator += diffEnergy * diffProduction;
            denominatorEnergy += diffEnergy * diffEnergy;
            denominatorProduction += diffProduction * diffProduction;
        }
        
        double denominator = Math.sqrt(denominatorEnergy) * Math.sqrt(denominatorProduction);
        
        if (denominator == 0.0) {
            return 0.0;
        }
        
        return numerator / denominator;
    }
    
    private Map<String, Object> prepareChartData(List<DataEnergy> energyData, List<StatHistoryTrend> trendData, List<BaseFactory> factories) {
        Map<String, Object> chartData = new HashMap<>();
        
        Map<String, List<Double>> energyByDate = new TreeMap<>();
        Map<String, List<Double>> productionByDate = new TreeMap<>();
        
        for (DataEnergy energy : energyData) {
            if (energy.getCollectTime() != null && energy.getValue() != null) {
                String dateKey = dateFormat.format(energy.getCollectTime());
                energyByDate.computeIfAbsent(dateKey, k -> new ArrayList<>()).add(energy.getValue().doubleValue());
                productionByDate.computeIfAbsent(dateKey, k -> new ArrayList<>()).add(energy.getValue().doubleValue() / 2.45);
            }
        }
        
        List<String> labels = new ArrayList<>(energyByDate.keySet());
        List<Double> energyValues = new ArrayList<>();
        List<Double> productionValues = new ArrayList<>();
        
        for (String date : labels) {
            List<Double> energies = energyByDate.get(date);
            List<Double> productions = productionByDate.get(date);
            
            double avgEnergy = energies.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
            double avgProduction = productions.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
            
            energyValues.add(avgEnergy);
            productionValues.add(avgProduction);
        }
        
        chartData.put("labels", labels);
        chartData.put("energyValues", energyValues);
        chartData.put("productionValues", productionValues);
        
        List<Map<String, Object>> correlationData = new ArrayList<>();
        for (DataEnergy energy : energyData) {
            if (energy.getValue() != null) {
                Map<String, Object> point = new HashMap<>();
                point.put("x", energy.getValue().doubleValue() / 2.45);
                point.put("y", energy.getValue().doubleValue());
                correlationData.add(point);
            }
        }
        
        chartData.put("correlationData", correlationData);
        
        return chartData;
    }
    
    private List<Map<String, Object>> prepareTableData(List<StatHistoryTrend> trendData, List<BaseFactory> factories) {
        List<Map<String, Object>> tableData = new ArrayList<>();
        
        Map<String, List<StatHistoryTrend>> trendByFactoryAndType = new HashMap<>();
        for (StatHistoryTrend trend : trendData) {
            String key = trend.getEnergyType();
            trendByFactoryAndType.computeIfAbsent(key, k -> new ArrayList<>()).add(trend);
        }
        
        for (Map.Entry<String, List<StatHistoryTrend>> entry : trendByFactoryAndType.entrySet()) {
            String energyType = entry.getKey();
            List<StatHistoryTrend> trends = entry.getValue();
            
            Map<String, Object> row = new HashMap<>();
            row.put("factory", "全厂");
            row.put("energyType", energyType);
            
            double correlation = calculateCorrelationFromTrends(trends);
            row.put("correlation", correlation);
            
            BigDecimal unitEnergy = calculateUnitEnergy(trends);
            row.put("unitEnergy", unitEnergy);
            
            double energyGrowthRate = calculateGrowthRate(trends, "energy");
            row.put("energyGrowthRate", energyGrowthRate);
            
            double productionGrowthRate = calculateGrowthRate(trends, "production");
            row.put("productionGrowthRate", productionGrowthRate);
            
            String conclusion = generateConclusion(correlation, energyGrowthRate, productionGrowthRate);
            row.put("conclusion", conclusion);
            
            tableData.add(row);
        }
        
        return tableData;
    }
    
    private double calculateCorrelationFromTrends(List<StatHistoryTrend> trends) {
        if (trends.size() < 2) {
            return 0.0;
        }
        
        List<Double> energyValues = new ArrayList<>();
        List<Double> productionValues = new ArrayList<>();
        
        for (StatHistoryTrend trend : trends) {
            if (trend.getValue() != null) {
                energyValues.add(trend.getValue().doubleValue());
                productionValues.add(trend.getValue().doubleValue() / 2.45);
            }
        }
        
        if (energyValues.size() < 2) {
            return 0.0;
        }
        
        double meanEnergy = energyValues.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        double meanProduction = productionValues.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        
        double numerator = 0.0;
        double denominatorEnergy = 0.0;
        double denominatorProduction = 0.0;
        
        for (int i = 0; i < energyValues.size(); i++) {
            double diffEnergy = energyValues.get(i) - meanEnergy;
            double diffProduction = productionValues.get(i) - meanProduction;
            
            numerator += diffEnergy * diffProduction;
            denominatorEnergy += diffEnergy * diffEnergy;
            denominatorProduction += diffProduction * diffProduction;
        }
        
        double denominator = Math.sqrt(denominatorEnergy) * Math.sqrt(denominatorProduction);
        
        if (denominator == 0.0) {
            return 0.0;
        }
        
        return numerator / denominator;
    }
    
    private BigDecimal calculateUnitEnergy(List<StatHistoryTrend> trends) {
        BigDecimal totalEnergy = BigDecimal.ZERO;
        BigDecimal totalProduction = BigDecimal.ZERO;
        
        for (StatHistoryTrend trend : trends) {
            if (trend.getValue() != null) {
                totalEnergy = totalEnergy.add(trend.getValue());
                totalProduction = totalProduction.add(trend.getValue().divide(new BigDecimal("2.45"), 2, RoundingMode.HALF_UP));
            }
        }
        
        return totalProduction.compareTo(BigDecimal.ZERO) > 0 
            ? totalEnergy.divide(totalProduction, 2, RoundingMode.HALF_UP) 
            : BigDecimal.ZERO;
    }
    
    private double calculateGrowthRate(List<StatHistoryTrend> trends, String type) {
        if (trends.size() < 2) {
            return 0.0;
        }
        
        trends.sort(Comparator.comparing(StatHistoryTrend::getStatDate));
        
        StatHistoryTrend first = trends.get(0);
        StatHistoryTrend last = trends.get(trends.size() - 1);
        
        if (first.getValue() == null || last.getValue() == null || first.getValue().compareTo(BigDecimal.ZERO) == 0) {
            return 0.0;
        }
        
        BigDecimal growthRate = last.getValue().subtract(first.getValue())
            .divide(first.getValue(), 4, RoundingMode.HALF_UP)
            .multiply(new BigDecimal("100"));
        
        return growthRate.doubleValue();
    }
    
    private String generateConclusion(double correlation, double energyGrowthRate, double productionGrowthRate) {
        if (correlation >= 0.8) {
            if (energyGrowthRate > productionGrowthRate) {
                return "能耗增长快于产量，需优化";
            } else if (energyGrowthRate < productionGrowthRate) {
                return "能耗控制良好，继续保持";
            } else {
                return "能耗与产量同步增长";
            }
        } else if (correlation >= 0.5) {
            return "关联度中等，需关注异常";
        } else {
            return "关联度较低，需深入分析";
        }
    }
    
    private List<Map<String, Object>> prepareReportData(List<StatHistoryTrend> trendData) {
        List<Map<String, Object>> reportData = new ArrayList<>();
        
        Calendar cal = Calendar.getInstance();
        int currentYear = cal.get(Calendar.YEAR);
        int currentMonth = cal.get(Calendar.MONTH);
        
        String[] quarters = {"Q1", "Q2", "Q3", "Q4"};
        int[] quarterMonths = {0, 3, 6, 9};
        
        for (int i = 0; i < 4; i++) {
            Map<String, Object> report = new HashMap<>();
            report.put("quarter", currentYear + "-" + quarters[i]);
            
            int qMonth = quarterMonths[i];
            if (qMonth > currentMonth) {
                report.put("status", "generating");
                report.put("date", "生成中...");
            } else {
                report.put("status", "completed");
                report.put("date", (currentYear - 1) + "-" + quarters[i]);
            }
            
            reportData.add(report);
        }
        
        return reportData;
    }
    
    private List<String> getEnergyTypes(List<EnergyMeter> meters) {
        Set<String> types = new HashSet<>();
        for (EnergyMeter meter : meters) {
            if (meter.getEnergyType() != null) {
                types.add(meter.getEnergyType());
            }
        }
        return new ArrayList<>(types);
    }
    
    private String formatNumber(BigDecimal number) {
        if (number.compareTo(new BigDecimal("10000")) >= 0) {
            return number.divide(new BigDecimal("10000"), 1, RoundingMode.HALF_UP) + "万";
        } else if (number.compareTo(new BigDecimal("1000")) >= 0) {
            return number.divide(new BigDecimal("1000"), 1, RoundingMode.HALF_UP) + "k";
        } else {
            return number.toString();
        }
    }
}
