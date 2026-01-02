package com.bfu.energy.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;

/**
 * 静态资源Servlet
 * 强制设置正确的Content-Type，解决CSS/JS返回text/html的问题
 */
@WebServlet(urlPatterns = {"/css/*", "/js/*", "/images/*"})
public class StaticResourceServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        
        String path = req.getRequestURI().substring(req.getContextPath().length());
        
        // 设置正确的Content-Type
        String contentType = getContentType(path);
        resp.setContentType(contentType);
        
        // 获取实际文件路径
        String realPath = getServletContext().getRealPath(path);
        File file = new File(realPath);
        
        if (!file.exists() || !file.isFile()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        // 设置缓存头
        resp.setHeader("Cache-Control", "public, max-age=86400");
        resp.setContentLength((int) file.length());
        
        // 输出文件内容
        try (InputStream in = new FileInputStream(file);
             OutputStream out = resp.getOutputStream()) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }
    
    private String getContentType(String path) {
        String lowerPath = path.toLowerCase();
        if (lowerPath.endsWith(".css")) {
            return "text/css;charset=UTF-8";
        } else if (lowerPath.endsWith(".js")) {
            return "application/javascript;charset=UTF-8";
        } else if (lowerPath.endsWith(".png")) {
            return "image/png";
        } else if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg")) {
            return "image/jpeg";
        } else if (lowerPath.endsWith(".gif")) {
            return "image/gif";
        } else if (lowerPath.endsWith(".svg")) {
            return "image/svg+xml";
        } else if (lowerPath.endsWith(".ico")) {
            return "image/x-icon";
        } else if (lowerPath.endsWith(".woff") || lowerPath.endsWith(".woff2")) {
            return "font/woff2";
        } else if (lowerPath.endsWith(".ttf")) {
            return "font/ttf";
        }
        return "application/octet-stream";
    }
}
