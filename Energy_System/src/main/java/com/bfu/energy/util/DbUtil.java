package com.bfu.energy.util;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

public final class DbUtil {

    private static String url;
    private static String username;
    private static String password;
    private static String driverClass;

    static {
        loadConfig();
    }

    private static void loadConfig() {
        Properties props = new Properties();
        try (InputStream in = DbUtil.class.getClassLoader()
                .getResourceAsStream("db.properties")) {
            props.load(in);
            driverClass = props.getProperty("jdbc.driver");
            url = props.getProperty("jdbc.url");
            username = props.getProperty("jdbc.username");
            password = props.getProperty("jdbc.password");
            Class.forName(driverClass);
        } catch (Exception e) {
            throw new RuntimeException("加载数据库配置失败", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, username, password);
    }

    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { }
        }
        if (stmt != null) {
            try { stmt.close(); } catch (SQLException e) { }
        }
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { }
        }
    }

    public static void close(Connection conn, Statement stmt) {
        close(conn, stmt, null);
    }

    public static void close(Connection conn) {
        close(conn, null, null);
    }
}
