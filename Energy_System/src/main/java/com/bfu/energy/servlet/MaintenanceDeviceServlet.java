package com.bfu.energy.servlet;

import com.bfu.energy.dao.PVDeviceDAO;
import com.bfu.energy.dao.EnergyMeterDAO;
import com.bfu.energy.dao.DistTransformerDAO;
import com.bfu.energy.entity.PVDevice;
import com.bfu.energy.entity.EnergyMeter;
import com.bfu.energy.entity.DistTransformer;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;

@WebServlet("/api/maintenance/devices")
public class MaintenanceDeviceServlet extends HttpServlet {

    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            PVDeviceDAO pvDeviceDAO = (PVDeviceDAO) com.bfu.energy.dao.DAOFactory.getDAO(PVDeviceDAO.class);
            EnergyMeterDAO energyMeterDAO = (EnergyMeterDAO) com.bfu.energy.dao.DAOFactory.getDAO(EnergyMeterDAO.class);
            DistTransformerDAO distTransformerDAO = (DistTransformerDAO) com.bfu.energy.dao.DAOFactory.getDAO(DistTransformerDAO.class);
            
            String deviceType = req.getParameter("deviceType");
            String status = req.getParameter("status");
            String factoryId = req.getParameter("factoryId");
            String name = req.getParameter("name");
            int page = Integer.parseInt(req.getParameter("page") != null ? req.getParameter("page") : "1");
            int pageSize = Integer.parseInt(req.getParameter("pageSize") != null ? req.getParameter("pageSize") : "12");
            
            List<Map<String, Object>> allDevices = new ArrayList<>();
            
            List<PVDevice> pvDevices = pvDeviceDAO.findAll();
            for (PVDevice device : pvDevices) {
                Map<String, Object> deviceMap = new HashMap<>();
                deviceMap.put("id", device.getDeviceId());
                deviceMap.put("type", "inverter");
                deviceMap.put("name", "逆变器 #" + device.getDeviceId());
                deviceMap.put("status", getDeviceStatus(device.getRunStatus()));
                deviceMap.put("factoryId", device.getLedgerId());
                deviceMap.put("factoryName", device.getLedgerId() != null ? 
                    (device.getLedgerId() == 1 ? "真旺厂" : "豆果厂") : "--");
                deviceMap.put("location", "光伏区域");
                deviceMap.put("manufacturer", "未知");
                deviceMap.put("installDate", device.getInstallDate());
                deviceMap.put("calibCycle", "--");
                allDevices.add(deviceMap);
            }
            
            List<EnergyMeter> meters = energyMeterDAO.findAll();
            for (EnergyMeter meter : meters) {
                Map<String, Object> deviceMap = new HashMap<>();
                deviceMap.put("id", meter.getMeterId());
                deviceMap.put("type", "meter");
                deviceMap.put("name", meter.getEnergyType() + "表 #" + meter.getMeterId());
                deviceMap.put("status", getDeviceStatus(meter.getRunStatus()));
                deviceMap.put("factoryId", meter.getFactoryId());
                deviceMap.put("factoryName", meter.getFactoryId() != null ? 
                    (meter.getFactoryId() == 1 ? "真旺厂" : "豆果厂") : "--");
                deviceMap.put("location", meter.getInstallLocation());
                deviceMap.put("manufacturer", meter.getManufacturer());
                deviceMap.put("installDate", null);
                deviceMap.put("calibCycle", meter.getCalibCycleMonths());
                allDevices.add(deviceMap);
            }
            
            List<DistTransformer> transformers = distTransformerDAO.findAll();
            for (DistTransformer transformer : transformers) {
                Map<String, Object> deviceMap = new HashMap<>();
                deviceMap.put("id", transformer.getTransformerId());
                deviceMap.put("type", "transformer");
                deviceMap.put("name", transformer.getTransformerName());
                deviceMap.put("status", "normal");
                deviceMap.put("factoryId", transformer.getLedgerId());
                deviceMap.put("factoryName", transformer.getLedgerId() != null ? 
                    (transformer.getLedgerId() == 1 ? "真旺厂" : "豆果厂") : "--");
                deviceMap.put("location", "配电室");
                deviceMap.put("manufacturer", "未知");
                deviceMap.put("installDate", null);
                deviceMap.put("calibCycle", "--");
                allDevices.add(deviceMap);
            }
            
            if (deviceType != null && !deviceType.isEmpty()) {
                allDevices.removeIf(d -> !deviceType.equals(d.get("type")));
            }
            
            if (status != null && !status.isEmpty()) {
                allDevices.removeIf(d -> !status.equals(d.get("status")));
            }
            
            if (factoryId != null && !factoryId.isEmpty()) {
                Long fid = Long.parseLong(factoryId);
                allDevices.removeIf(d -> d.get("factoryId") == null || !fid.equals(d.get("factoryId")));
            }
            
            if (name != null && !name.isEmpty()) {
                allDevices.removeIf(d -> !d.get("name").toString().contains(name));
            }
            
            int total = allDevices.size();
            int startIndex = (page - 1) * pageSize;
            int endIndex = Math.min(startIndex + pageSize, total);
            
            List<Map<String, Object>> pagedDevices = allDevices.subList(startIndex, endIndex);
            
            Map<String, Object> data = new HashMap<>();
            data.put("devices", pagedDevices);
            data.put("total", total);
            data.put("page", page);
            data.put("pageSize", pageSize);
            
            result.put("success", true);
            result.put("data", data);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "获取设备列表失败: " + e.getMessage());
        }
        
        PrintWriter out = resp.getWriter();
        out.print(gson.toJson(result));
        out.flush();
    }
    
    private String getDeviceStatus(String runStatus) {
        if ("正常".equals(runStatus)) return "normal";
        if ("预警".equals(runStatus)) return "warning";
        if ("故障".equals(runStatus)) return "error";
        return "normal";
    }
}
