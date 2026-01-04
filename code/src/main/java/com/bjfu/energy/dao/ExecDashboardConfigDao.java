package com.bjfu.energy.dao;

import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * 业务线5（企业管理层大屏）：自定义展示配置
 * <p>
 * 说明：
 * - 默认按“全显示”渲染；
 * - 如数据库存在表 Exec_Dashboard_Config，则按用户持久化配置；
 * - 若该表未创建/不可用，调用方可选择用 Session 兜底。
 * </p>
 *
 * 建议建表（SQLServer）：
 * <pre>
 * CREATE TABLE Exec_Dashboard_Config(
 *   Config_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
 *   User_ID BIGINT NOT NULL UNIQUE,
 *   Widgets_Csv NVARCHAR(500) NOT NULL,
 *   Updated_At DATETIME NOT NULL DEFAULT(GETDATE())
 * );
 * </pre>
 */
public class ExecDashboardConfigDao {

    /**
     * 白名单：允许展示/隐藏的大屏模块。
     * 你可以按需增减，但请同步修改 dashboard.jsp 的 checkbox。
     */
    private static final Set<String> ALLOWED = new LinkedHashSet<>(Arrays.asList(
            "kpi",          // 月度 KPI（3 张卡片）
            "realtime",     // 实时汇总卡片
            "summaries",    // 能耗总结与降本评估
            "trends",       // 历史趋势 + Top 厂区
            "decisions",    // 重大事项决策
            "alarms",       // 高等级告警推送
            "projects"      // 科研项目管理
    ));

    public String getWidgetsCsv(Long userId) throws Exception {
        if (userId == null) {
            return defaultWidgetsCsv();
        }
        String sql = "SELECT Widgets_Csv FROM Exec_Dashboard_Config WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String csv = rs.getString(1);
                    String cleaned = cleanCsv(csv);
                    return cleaned == null || cleaned.isEmpty() ? defaultWidgetsCsv() : cleaned;
                }
            }
        }
        return defaultWidgetsCsv();
    }

    public void saveWidgetsCsv(Long userId, String widgetsCsv) throws Exception {
        if (userId == null) {
            throw new IllegalArgumentException("userId 不能为空");
        }
        String cleaned = cleanCsv(widgetsCsv);
        if (cleaned == null || cleaned.isEmpty()) {
            cleaned = defaultWidgetsCsv();
        }

        String update = "UPDATE Exec_Dashboard_Config SET Widgets_Csv = ?, Updated_At = GETDATE() WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(update)) {
            ps.setString(1, cleaned);
            ps.setLong(2, userId);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                return;
            }
        }

        String insert = "INSERT INTO Exec_Dashboard_Config(User_ID, Widgets_Csv, Updated_At) VALUES(?, ?, GETDATE())";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(insert)) {
            ps.setLong(1, userId);
            ps.setString(2, cleaned);
            ps.executeUpdate();
        }
    }

    public String defaultWidgetsCsv() {
        return String.join(",", ALLOWED);
    }

    /**
     * 清洗并按白名单过滤：去空格、去重、保持白名单顺序。
     */
    public String cleanCsv(String csv) {
        if (csv == null) {
            return null;
        }
        String[] parts = csv.split(",");
        Set<String> picked = new LinkedHashSet<>();
        for (String p : parts) {
            if (p == null) {
                continue;
            }
            String key = p.trim();
            if (!key.isEmpty()) {
                picked.add(key);
            }
        }
        // 只保留允许的模块，并按 ALLOWED 顺序输出
        Set<String> ordered = new LinkedHashSet<>();
        for (String allow : ALLOWED) {
            if (picked.contains(allow)) {
                ordered.add(allow);
            }
        }
        return String.join(",", ordered);
    }
}
