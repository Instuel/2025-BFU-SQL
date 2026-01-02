package com.bfu.energy.filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletResponseWrapper;
import java.io.IOException;

/**
 * 静态资源过滤器
 * 强制设置CSS/JS等静态资源的正确Content-Type
 * 解决IDE（如MyEclipse CodeLive）错误设置Content-Type的问题
 */
@WebFilter(urlPatterns = {"/css/*", "/js/*", "/images/*"})
public class StaticResourceFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                        FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        
        String uri = req.getRequestURI().toLowerCase();
        
        // 根据文件扩展名设置正确的Content-Type
        if (uri.endsWith(".css")) {
            resp.setContentType("text/css;charset=UTF-8");
        } else if (uri.endsWith(".js")) {
            resp.setContentType("application/javascript;charset=UTF-8");
        } else if (uri.endsWith(".png")) {
            resp.setContentType("image/png");
        } else if (uri.endsWith(".jpg") || uri.endsWith(".jpeg")) {
            resp.setContentType("image/jpeg");
        } else if (uri.endsWith(".gif")) {
            resp.setContentType("image/gif");
        } else if (uri.endsWith(".svg")) {
            resp.setContentType("image/svg+xml");
        } else if (uri.endsWith(".ico")) {
            resp.setContentType("image/x-icon");
        }
        
        // 使用包装器防止后续代码覆盖Content-Type
        ContentTypeLockedResponse wrappedResponse = new ContentTypeLockedResponse(resp);
        chain.doFilter(request, wrappedResponse);
    }

    @Override
    public void destroy() {
    }
    
    /**
     * 响应包装器，锁定Content-Type不被覆盖
     */
    private static class ContentTypeLockedResponse extends HttpServletResponseWrapper {
        private boolean contentTypeSet = false;
        
        public ContentTypeLockedResponse(HttpServletResponse response) {
            super(response);
            // 检查是否已经设置了Content-Type
            String contentType = response.getContentType();
            if (contentType != null && !contentType.contains("text/html")) {
                contentTypeSet = true;
            }
        }
        
        @Override
        public void setContentType(String type) {
            if (!contentTypeSet) {
                super.setContentType(type);
                contentTypeSet = true;
            }
            // 如果已经设置过，忽略后续的setContentType调用
        }
        
        @Override
        public void setHeader(String name, String value) {
            if ("Content-Type".equalsIgnoreCase(name) && contentTypeSet) {
                return; // 忽略对Content-Type的覆盖
            }
            super.setHeader(name, value);
        }
        
        @Override
        public void addHeader(String name, String value) {
            if ("Content-Type".equalsIgnoreCase(name) && contentTypeSet) {
                return;
            }
            super.addHeader(name, value);
        }
    }
}
