package com.bfu.energy.servlet;

import com.bfu.energy.dao.AlarmInfoDAO;
import com.bfu.energy.dao.BaseFactoryDAO;
import com.bfu.energy.dao.StatRealtimeDAO;
import com.bfu.energy.entity.AlarmInfo;
import com.bfu.energy.entity.BaseFactory;
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
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/public/stats")
public class PublicStatsServlet extends HttpServlet {

    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            StatRealtimeDAO statRealtimeDAO = DAOFactory.getDAO(StatRealtimeDAO.class);
            AlarmInfoDAO alarmInfoDAO = DAOFactory.getDAO(AlarmInfoDAO.class);
            BaseFactoryDAO baseFactoryDAO = DAOFactory.getDAO(BaseFactoryDAO.class);
            
            StatRealtime latestStat = statRealtimeDAO.findLatest();
            
            Integer activeAlarmCount = alarmInfoDAO.countActiveAlarms();
            
            int factoryCount = baseFactoryDAO.countAll();
            
            result.put("success", true);
            result.put("data", buildStatsData(latestStat, activeAlarmCount, factoryCount));
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取统计数据失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private Map<String, Object> buildStatsData(StatRealtime stat, Integer activeAlarmCount, int factoryCount) {
        Map<String, Object> data = new HashMap<>();
        
        if (stat != null) {
            data.put("totalKwh", stat.getTotalKwh() != null ? stat.getTotalKwh().doubleValue() : 0);
            data.put("pvGenKwh", stat.getPvGenKwh() != null ? stat.getPvGenKwh().doubleValue() : 0);
            data.put("statTime", stat.getStatTime() != null ? stat.getStatTime().toString() : "");
        } else {
            data.put("totalKwh", 0);
            data.put("pvGenKwh", 0);
            data.put("statTime", "");
        }
        
        data.put("totalAlarm", activeAlarmCount != null ? activeAlarmCount : 0);
        data.put("factoryCount", factoryCount);
        
        return data;
    }
}
