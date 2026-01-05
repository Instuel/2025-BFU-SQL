package com.bjfu.energy.controller;

import com.bjfu.energy.dao.DistMonitorDao;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.RoleOandM;
import com.bjfu.energy.dao.RoleOandMDao;
import com.bjfu.energy.dao.RoleOandMDaoImpl;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;

/**
 * 配电网监测路由控制器：
 *  /dist?action=room_list|room_detail|circuit_list|circuit_detail|
 *  transformer_list|transformer_detail|data_circuit_list|data_transformer_list
 */
public class DistServlet extends HttpServlet {

    private final DistMonitorDao distDao = new DistMonitorDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "room_list";
        }

        String jsp = "/WEB-INF/jsp/dist/room_list.jsp";
        Long userFactoryId = null;
        
        try {
            SysUser currentUser = (SysUser) req.getSession().getAttribute("currentUser");
            String roleType = (String) req.getSession().getAttribute("currentRoleType");
            
            if ("OM".equals(roleType) && currentUser != null) {
                RoleOandMDao roleOandMDao = new RoleOandMDaoImpl();
                RoleOandM oandm = roleOandMDao.findByUserId(currentUser.getUserId());
                if (oandm != null) {
                    userFactoryId = oandm.getFactoryId();
                }
            }
            
            switch (action) {
                case "room_list":
                    String roomSort = req.getParameter("roomSort");
                    int roomPage = parseInt(req.getParameter("page"), 1);
                    int roomPageSize = parseInt(req.getParameter("pageSize"), 20);
                    req.setAttribute("roomStats", distDao.getRoomStats(userFactoryId));
                    req.setAttribute("rooms", distDao.listRooms(userFactoryId, roomSort, roomPage, roomPageSize));
                    req.setAttribute("roomSort", roomSort);
                    req.setAttribute("roomPage", roomPage);
                    req.setAttribute("roomPageSize", roomPageSize);
                    req.setAttribute("roomTotalCount", distDao.countRooms(userFactoryId));
                    jsp = "/WEB-INF/jsp/dist/room_list.jsp";
                    break;
                case "room_detail":
                    Long roomId = parseLong(req.getParameter("id"));
                    if (roomId == null) {
                        List<Map<String, Object>> rooms = distDao.listRooms(userFactoryId);
                        if (!rooms.isEmpty()) {
                            roomId = ((Number) rooms.get(0).get("roomId")).longValue();
                        }
                    }
                    Map<String, Object> room = roomId == null ? null : distDao.findRoomById(roomId);
                    req.setAttribute("room", room);
                    req.setAttribute("circuits", roomId == null ? java.util.Collections.emptyList() : distDao.listCircuits(roomId, userFactoryId));
                    req.setAttribute("transformers", roomId == null ? java.util.Collections.emptyList() : distDao.listTransformers(roomId, userFactoryId));
                    jsp = "/WEB-INF/jsp/dist/room_detail.jsp";
                    break;
                case "circuit_list":
                    String circuitStatus = req.getParameter("circuitStatus");
                    int circuitPage = parseInt(req.getParameter("page"), 1);
                    int circuitPageSize = parseInt(req.getParameter("pageSize"), 20);
                    req.setAttribute("circuits", distDao.listCircuits(null, userFactoryId, circuitStatus, circuitPage, circuitPageSize));
                    req.setAttribute("circuitStatus", circuitStatus);
                    req.setAttribute("circuitPage", circuitPage);
                    req.setAttribute("circuitPageSize", circuitPageSize);
                    req.setAttribute("circuitTotalCount", distDao.countCircuits(null, userFactoryId, circuitStatus));
                    jsp = "/WEB-INF/jsp/dist/circuit_list.jsp";
                    break;
                case "circuit_detail":
                    Long circuitId = parseLong(req.getParameter("id"));
                    if (circuitId == null) {
                        List<Map<String, Object>> circuits = distDao.listCircuits(null, userFactoryId);
                        if (!circuits.isEmpty()) {
                            circuitId = ((Number) circuits.get(0).get("circuitId")).longValue();
                        }
                    }
                    Map<String, Object> circuit = circuitId == null ? null : distDao.findCircuitById(circuitId);
                    req.setAttribute("circuit", circuit);
                    req.setAttribute("circuitData", circuitId == null ? java.util.Collections.emptyList() : distDao.listCircuitData(circuitId));
                    if (circuit != null && circuit.get("ledgerId") instanceof Number) {
                        Long ledgerId = ((Number) circuit.get("ledgerId")).longValue();
                        req.setAttribute("workOrders", distDao.listWorkOrdersByLedger(ledgerId));
                    } else {
                        req.setAttribute("workOrders", java.util.Collections.emptyList());
                    }
                    jsp = "/WEB-INF/jsp/dist/circuit_detail.jsp";
                    break;
                case "transformer_list":
                    String transformerStatus = req.getParameter("transformerStatus");
                    int transformerPage = parseInt(req.getParameter("page"), 1);
                    int transformerPageSize = parseInt(req.getParameter("pageSize"), 20);
                    req.setAttribute("transformers", distDao.listTransformers(null, userFactoryId, transformerStatus, transformerPage, transformerPageSize));
                    req.setAttribute("transformerStatus", transformerStatus);
                    req.setAttribute("transformerPage", transformerPage);
                    req.setAttribute("transformerPageSize", transformerPageSize);
                    req.setAttribute("transformerTotalCount", distDao.countTransformers(null, userFactoryId, transformerStatus));
                    jsp = "/WEB-INF/jsp/dist/transformer_list.jsp";
                    break;
                case "transformer_detail":
                    Long transformerId = parseLong(req.getParameter("id"));
                    if (transformerId == null) {
                        List<Map<String, Object>> transformers = distDao.listTransformers(null, userFactoryId);
                        if (!transformers.isEmpty()) {
                            transformerId = ((Number) transformers.get(0).get("transformerId")).longValue();
                        }
                    }
                    Map<String, Object> transformer = transformerId == null ? null : distDao.findTransformerById(transformerId);
                    req.setAttribute("transformer", transformer);
                    req.setAttribute("transformerData", transformerId == null ? java.util.Collections.emptyList() : distDao.listTransformerData(transformerId));
                    if (transformer != null && transformer.get("ledgerId") instanceof Number) {
                        Long ledgerId = ((Number) transformer.get("ledgerId")).longValue();
                        req.setAttribute("alarmItems", distDao.listAlarmsByLedger(ledgerId));
                    } else {
                        req.setAttribute("alarmItems", java.util.Collections.emptyList());
                    }
                    jsp = "/WEB-INF/jsp/dist/transformer_detail.jsp";
                    break;
                case "data_circuit_list":
                    Long filterCircuitId = parseLong(req.getParameter("circuitId"));
                    req.setAttribute("circuitOptions", distDao.listCircuitOptions(userFactoryId));
                    req.setAttribute("selectedCircuitId", filterCircuitId);
                    req.setAttribute("circuitData", distDao.listCircuitData(filterCircuitId));
                    jsp = "/WEB-INF/jsp/dist/data_circuit_list.jsp";
                    break;
                case "data_transformer_list":
                    Long filterTransformerId = parseLong(req.getParameter("transformerId"));
                    req.setAttribute("transformerOptions", distDao.listTransformerOptions(userFactoryId));
                    req.setAttribute("selectedTransformerId", filterTransformerId);
                    req.setAttribute("transformerData", distDao.listTransformerData(filterTransformerId));
                    jsp = "/WEB-INF/jsp/dist/data_transformer_list.jsp";
                    break;
                default:
                    req.setAttribute("roomStats", distDao.getRoomStats(userFactoryId));
                    req.setAttribute("rooms", distDao.listRooms(userFactoryId));
                    jsp = "/WEB-INF/jsp/dist/room_list.jsp";
                    break;
            }
        } catch (Exception e) {
            throw new ServletException("配电网监测数据加载失败: " + e.getMessage(), e);
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

    private int parseInt(String value, int defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }
}
