package com.bfu.energy.servlet;

import com.bfu.energy.dao.DataEnergyDAO;
import com.bfu.energy.dao.DataPeakValleyDAO;
import com.bfu.energy.dao.StatRealtimeDAO;
import com.bfu.energy.entity.DataEnergy;
import com.bfu.energy.entity.DataPeakValley;
import com.bfu.energy.entity.StatRealtime;
import com.bfu.energy.util.DAOFactory;
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
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/energy/dashboard")
public class EnergyDashboardDataServlet extends HttpServlet {

    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            DataEnergyDAO dataEnergyDAO = DAOFactory.getDAO(DataEnergyDAO.class);
            DataPeakValleyDAO dataPeakValleyDAO = DAOFactory.getDAO(DataPeakValleyDAO.class);
            StatRealtimeDAO statRealtimeDAO = DAOFactory.getDAO(StatRealtimeDAO.class);
            
            StatRealtime todayStat = statRealtimeDAO.findByStatDate(Date.valueOf(LocalDate.now()));
            StatRealtime yesterdayStat = statRealtimeDAO.findByStatDate(Date.valueOf(LocalDate.now().minusDays(1)));
            
            BigDecimal todayConsumption = todayStat != null ? todayStat.getTotalKwh() : BigDecimal.ZERO;
            BigDecimal yesterdayConsumption = yesterdayStat != null ? yesterdayStat.getTotalKwh() : BigDecimal.ZERO;
            
            BigDecimal consumptionTrend = BigDecimal.ZERO;
            if (yesterdayConsumption.compareTo(BigDecimal.ZERO) > 0) {
                consumptionTrend = todayConsumption.subtract(yesterdayConsumption)
                    .divide(yesterdayConsumption, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            }
            
            List<DataPeakValley> todayPeakValleyData = dataPeakValleyDAO.findByDateRange(
                Date.valueOf(LocalDate.now()), 
                Date.valueOf(LocalDate.now())
            );
            
            Map<String, Object> peakValleyStats = calculatePeakValleyStats(todayPeakValleyData);
            
            List<DataEnergy> abnormalData = dataEnergyDAO.findByQuality("bad");
            List<DataEnergy> warningData = dataEnergyDAO.findByQuality("warning");
            int abnormalDataCount = abnormalData.size() + warningData.size();
            
            List<Map<String, Object>> recentEnergyData = getRecentEnergyData(dataEnergyDAO);
            
            result.put("success", true);
            result.put("data", buildDashboardData(
                todayConsumption, 
                consumptionTrend, 
                peakValleyStats, 
                abnormalDataCount, 
                recentEnergyData
            ));
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取dashboard数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private Map<String, Object> calculatePeakValleyStats(List<DataPeakValley> peakValleyData) {
        Map<String, Object> stats = new HashMap<>();
        
        BigDecimal totalConsumption = BigDecimal.ZERO;
        BigDecimal peakConsumption = BigDecimal.ZERO;
        BigDecimal valleyConsumption = BigDecimal.ZERO;
        BigDecimal flatConsumption = BigDecimal.ZERO;
        BigDecimal sharpConsumption = BigDecimal.ZERO;
        
        for (DataPeakValley data : peakValleyData) {
            if (data.getTotalConsumption() != null) {
                totalConsumption = totalConsumption.add(data.getTotalConsumption());
                
                switch (data.getPeakType()) {
                    case "peak":
                        peakConsumption = peakConsumption.add(data.getTotalConsumption());
                        break;
                    case "valley":
                        valleyConsumption = valleyConsumption.add(data.getTotalConsumption());
                        break;
                    case "flat":
                        flatConsumption = flatConsumption.add(data.getTotalConsumption());
                        break;
                    case "sharp":
                        sharpConsumption = sharpConsumption.add(data.getTotalConsumption());
                        break;
                }
            }
        }
        
        BigDecimal peakValleyRatio = BigDecimal.ZERO;
        BigDecimal peakRatio = BigDecimal.ZERO;
        
        if (totalConsumption.compareTo(BigDecimal.ZERO) > 0) {
            peakValleyRatio = peakConsumption.divide(totalConsumption, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));
            peakRatio = peakConsumption.divide(totalConsumption, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));
        }
        
        stats.put("peakValleyRatio", peakValleyRatio);
        stats.put("peakRatio", peakRatio);
        stats.put("peakConsumption", peakConsumption);
        stats.put("valleyConsumption", valleyConsumption);
        stats.put("flatConsumption", flatConsumption);
        stats.put("sharpConsumption", sharpConsumption);
        
        return stats;
    }
    
    private List<Map<String, Object>> getRecentEnergyData(DataEnergyDAO dataEnergyDAO) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        List<DataEnergy> recentData = dataEnergyDAO.findRecent(10);
        
        for (DataEnergy data : recentData) {
            Map<String, Object> item = new HashMap<>();
            item.put("dataId", data.getDataId());
            item.put("factoryId", data.getFactoryId());
            item.put("energyType", getEnergyTypeByMeterId(data.getMeterId()));
            item.put("collectTime", data.getCollectTime());
            item.put("value", data.getValue());
            item.put("unit", data.getUnit());
            item.put("quality", data.getQuality());
            item.put("factoryName", getFactoryNameById(data.getFactoryId()));
            result.add(item);
        }
        
        return result;
    }
    
    private String getEnergyTypeByMeterId(Long meterId) {
        return "电";
    }
    
    private String getFactoryNameById(Long factoryId) {
        if (factoryId == null) return "--";
        return factoryId == 1 ? "真旺厂" : (factoryId == 2 ? "豆果厂" : "--");
    }
    
    private Map<String, Object> buildDashboardData(
            BigDecimal todayConsumption,
            BigDecimal consumptionTrend,
            Map<String, Object> peakValleyStats,
            int abnormalDataCount,
            List<Map<String, Object>> recentEnergyData) {
        Map<String, Object> data = new HashMap<>();
        
        data.put("todayConsumption", todayConsumption);
        data.put("consumptionTrend", consumptionTrend);
        data.put("peakValleyRatio", peakValleyStats.get("peakValleyRatio"));
        data.put("peakRatio", peakValleyStats.get("peakRatio"));
        data.put("abnormalDataCount", abnormalDataCount);
        data.put("activeStrategies", 3);
        data.put("recentEnergyData", recentEnergyData);
        
        return data;
    }
}
