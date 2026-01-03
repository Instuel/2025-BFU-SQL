package com.bjfu.energy.filter;

import com.bjfu.energy.entity.SysUser;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * 登录鉴权过滤器（简化版 RBAC）：
 * - 放行静态资源、错误页、首页、登录/注册相关请求
 * - 其他请求要求 session 中存在 currentUser
 *
 * 说明：
 * 你的前端样式依赖 /css 下的 common.css/components.css 等资源。
 * 如果这里不放行 /css，则浏览器请求 CSS 会被重定向到登录页，导致页面“像没样式”。
 */
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
            throws IOException, ServletException {

        if (!(req instanceof HttpServletRequest) || !(resp instanceof HttpServletResponse)) {
            chain.doFilter(req, resp);
            return;
        }

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) resp;

        String ctx = request.getContextPath();
        String uri = request.getRequestURI();

        // 静态资源、错误页、首页、认证接口直接放行
        if (uri.startsWith(ctx + "/static/")
                || uri.startsWith(ctx + "/css/")
                || uri.startsWith(ctx + "/error/")
                || uri.equals(ctx + "/favicon.ico")
                || uri.equals(ctx + "/")
                || uri.equals(ctx + "/index.jsp")
                || uri.startsWith(ctx + "/auth")) {
            chain.doFilter(req, resp);
            return;
        }

        HttpSession session = request.getSession(false);
        SysUser loginUser = (session == null) ? null : (SysUser) session.getAttribute("currentUser");
        if (loginUser == null) {
            response.sendRedirect(ctx + "/auth?action=loginPage");
            return;
        }

        // 如需细粒度权限控制，可在此处根据 session 中的 currentRoleType + URI 做判断
        chain.doFilter(req, resp);
    }

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void destroy() {
    }
}
