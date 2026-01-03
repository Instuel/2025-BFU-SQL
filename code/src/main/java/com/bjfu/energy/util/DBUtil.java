package com.bjfu.energy.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

/**
 * 极简 JDBC 工具类：
 * - 从 classpath 下加载 db.properties
 * - 根据配置加载 JDBC Driver 并提供 Connection
 */
public final class DBUtil {

    private static final Properties PROPS = new Properties();

    static {
        try (InputStream in = DBUtil.class.getClassLoader().getResourceAsStream("db.properties")) {
            if (in == null) {
                throw new RuntimeException("找不到数据库配置文件 db.properties，请确认其已放在 src/main/resources 下。");
            }
            PROPS.load(in);

            String driver = PROPS.getProperty("db.driver");
            if (driver != null && driver.trim().length() > 0) {
                Class.forName(driver.trim());
            }
        } catch (Exception e) {
            throw new RuntimeException("DBUtil 初始化失败: " + e.getMessage(), e);
        }
    }

    private DBUtil() {
    }

    public static Connection getConnection() throws Exception {
        String url = PROPS.getProperty("db.url");
        String user = PROPS.getProperty("db.user");
        String password = PROPS.getProperty("db.password");

        if (url == null || url.trim().isEmpty()) {
            throw new IllegalStateException("db.url 未在 db.properties 中配置");
        }

        return DriverManager.getConnection(url, user, password);
    }
}
