package com.bjfu.energy.filter;

import com.bjfu.energy.entity.SysPermission;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.service.AuthService;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

    private final AuthService authService = new AuthService();

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

        if (session != null && session.getAttribute("currentPermUris") == null) {
            try {
                List<SysPermission> permissions = authService.getPermissions(loginUser.getUserId());
                Set<String> permCodes = new HashSet<>();
                Set<String> permModules = new HashSet<>();
                List<String> permUris = new ArrayList<>();
                for (SysPermission p : permissions) {
                    if (p.getPermCode() != null) {
                        permCodes.add(p.getPermCode());
                    }
                    if (p.getModule() != null) {
                        permModules.add(p.getModule());
                    }
                    if (p.getUriPattern() != null) {
                        permUris.add(p.getUriPattern());
                    }
                }
                session.setAttribute("currentPermCodes", permCodes);
                session.setAttribute("currentPermModules", permModules);
                session.setAttribute("currentPermUris", permUris);
            } catch (Exception e) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
        }

     // ...前面代码保持不变

        Set<String> permModules = (session == null) ? null : (Set<String>) session.getAttribute("currentPermModules");
        List<String> permUris = (session == null) ? null : (List<String>) session.getAttribute("currentPermUris");

        // ---------------------------
        // 模块级权限（RBAC）检查
        // ---------------------------
        // 说明：你的系统入口有两种：
        // 1) /app?module=xxx（工作台路由）
        // 2) /dist、/alarm、/admin（业务线 Servlet）
        // 之前仅对 /app 做了 module 权限校验，导致访问 /dist、/alarm 直接走 uriPattern 校验，
        // 但数据库里这些模块没有配置 Uri_Pattern，于是管理员也会 403。
        String module = null;
        if (uri.startsWith(ctx + "/app")) {
            module = request.getParameter("module");
            if (module == null || module.trim().isEmpty()) {
                module = "dashboard";
            }
        } else if (uri.startsWith(ctx + "/dist")) {
            module = "dist";
        } else if (uri.startsWith(ctx + "/alarm")) {
            module = "alarm";
        } else if (uri.startsWith(ctx + "/admin")) {
            module = "admin";
        } else if (uri.startsWith(ctx + "/execDashboard")) {
            // 企业管理层大屏 API：沿用 dashboard 模块权限
            module = "dashboard";
        }

        if (module != null) {
            if (permModules == null || !permModules.contains(module)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        // 其他非模块入口（比如你未来加的 /api/xxx）再走 Uri_Pattern
        if (!isUriPermitted(uri, ctx, permUris)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        chain.doFilter(req, resp);

    }

    private boolean isUriPermitted(String uri, String ctx, List<String> permUris) {
        if (permUris == null) {
            return false;
        }
        for (String pattern : permUris) {
            if (pattern == null || pattern.trim().isEmpty()) {
                continue;
            }
            String normalized = pattern.trim();
            String target = normalized.startsWith("/") ? ctx + normalized : ctx + "/" + normalized;
            if (normalized.endsWith("*")) {
                String prefix = target.substring(0, target.length() - 1);
                if (uri.startsWith(prefix)) {
                    return true;
                }
            } else if (uri.equals(target)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void destroy() {
    }
}
