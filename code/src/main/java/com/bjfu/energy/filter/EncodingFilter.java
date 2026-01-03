package com.bjfu.energy.filter;

import javax.servlet.*;
import java.io.IOException;

/**
 * 全站编码过滤器：统一设置为 UTF-8
 */
public class EncodingFilter implements Filter {

    private String encoding = "UTF-8";

    @Override
    public void init(FilterConfig filterConfig) {
        if (filterConfig != null) {
            String enc = filterConfig.getInitParameter("encoding");
            if (enc != null && enc.trim().length() > 0) {
                encoding = enc.trim();
            }
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        if (encoding != null) {
            request.setCharacterEncoding(encoding);
            response.setCharacterEncoding(encoding);
        }
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
