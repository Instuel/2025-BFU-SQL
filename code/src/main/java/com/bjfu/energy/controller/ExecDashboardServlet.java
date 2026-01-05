package com.bjfu.energy.controller;

import com.bjfu.energy.dao.ExecDashboardConfigDao;
import com.bjfu.energy.dao.ExecDashboardDao;
import com.bjfu.energy.entity.SysUser;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

/**
 * 业务线5：企业管理层大屏 API
 *
 * GET  /execDashboard?action=realtime  -> 分钟级实时汇总 JSON
 * GET  /execDashboard?action=config    -> 当前用户 widgetsCsv
 * POST /execDashboard?action=saveConfig (widgets=csv) -> 保存自定义展示配置
 */
public class ExecDashboardServlet extends HttpServlet {

    private final ExecDashboardDao execDashboardDao = new ExecDashboardDao();
    private final ExecDashboardConfigDao configDao = new ExecDashboardConfigDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "realtime";
        }

        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        HttpSession session = req.getSession(false);
        SysUser user = session == null ? null : (SysUser) session.getAttribute("currentUser");

        try (PrintWriter out = resp.getWriter()) {
            switch (action) {
                case "config": {
                    String csv = null;
                    // 1) 优先 DB
                    try {
                        csv = (user == null) ? configDao.defaultWidgetsCsv() : configDao.getWidgetsCsv(user.getUserId());
                    } catch (Exception e) {
                        // 2) DB 不可用：兜底 session
                        if (session != null) {
                            Object v = session.getAttribute("execWidgetsCsv");
                            csv = v == null ? configDao.defaultWidgetsCsv() : String.valueOf(v);
                        } else {
                            csv = configDao.defaultWidgetsCsv();
                        }
                    }
                    out.write("{\"ok\":true,\"widgetsCsv\":" + jsonString(csv) + "}");
                    return;
                }
                case "realtime":
                default: {
                    Map<String, Object> m = execDashboardDao.getRealtimeSummary();
                    out.write(mapToJson(m));
                    return;
                }
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":false,\"error\":" + jsonString(e.getMessage()) + "}");
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "saveConfig";
        }

        if (!"saveConfig".equals(action)) {
            doGet(req, resp);
            return;
        }

        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        HttpSession session = req.getSession(false);
        SysUser user = session == null ? null : (SysUser) session.getAttribute("currentUser");
        if (user == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":false,\"error\":\"未登录\"}");
            }
            return;
        }

        String widgets = req.getParameter("widgets");

        try (PrintWriter out = resp.getWriter()) {
            String cleaned = configDao.cleanCsv(widgets);
            if (cleaned == null || cleaned.trim().isEmpty()) {
                cleaned = configDao.defaultWidgetsCsv();
            }

            boolean savedToDb = true;
            try {
                configDao.saveWidgetsCsv(user.getUserId(), cleaned);
            } catch (Exception e) {
                savedToDb = false;
                // DB 不可用：兜底 session，保证演示可用
                if (session != null) {
                    session.setAttribute("execWidgetsCsv", cleaned);
                }
            }

            out.write("{\"ok\":true,\"widgetsCsv\":" + jsonString(cleaned) + ",\"savedToDb\":" + (savedToDb ? "true" : "false") + "}");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            try (PrintWriter out = resp.getWriter()) {
                out.write("{\"ok\":false,\"error\":" + jsonString(e.getMessage()) + "}");
            }
        }
    }

    // -------------------------
    // JSON helpers（不依赖第三方库）
    // -------------------------

    private static String jsonString(String s) {
        if (s == null) {
            return "null";
        }
        StringBuilder sb = new StringBuilder();
        sb.append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        sb.append('"');
        return sb.toString();
    }

    private static String mapToJson(Map<String, Object> m) {
        if (m == null) {
            return "{\"ok\":true}";
        }
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        sb.append("\"ok\":true");
        for (Map.Entry<String, Object> e : m.entrySet()) {
            sb.append(',');
            sb.append(jsonString(e.getKey()));
            sb.append(':');
            sb.append(valueToJson(e.getValue()));
        }
        sb.append('}');
        return sb.toString();
    }

    private static String valueToJson(Object v) {
        if (v == null) {
            return "null";
        }
        if (v instanceof Number || v instanceof Boolean) {
            return String.valueOf(v);
        }
        return jsonString(String.valueOf(v));
    }
}