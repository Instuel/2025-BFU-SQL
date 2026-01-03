<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="m" value="${param.module}" />

<div class="sidebar">
  <div style="padding:0 28px 14px 28px;">
    <div class="section-title" style="margin:0;">导航</div>
    <div style="color:#94a3b8;font-size:12px;margin-top:6px;">按模块进入（入口最终应受 RBAC 控制）</div>
  </div>

  <ul class="sidebar-menu">
    <li>
      <a class="<c:out value='${m=="dashboard" ? "active" : ""}'/>" href="${ctx}/app?module=dashboard">
        <span class="icon">📊</span> <span>大屏/总览</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${m=="dist" ? "active" : ""}'/>" href="${ctx}/app?module=dist">
        <span class="icon">🔌</span> <span>配电网监测</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${m=="pv" ? "active" : ""}'/>" href="${ctx}/app?module=pv">
        <span class="icon">☀️</span> <span>分布式光伏</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${m=="energy" ? "active" : ""}'/>" href="${ctx}/app?module=energy">
        <span class="icon">⚡</span> <span>综合能耗</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${m=="alarm" ? "active" : ""}'/>" href="${ctx}/app?module=alarm">
        <span class="icon">🚨</span> <span>告警运维</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${m=="admin" ? "active" : ""}'/>" href="${ctx}/app?module=admin">
        <span class="icon">🛠️</span> <span>系统管理</span>
      </a>
    </li>
  </ul>
</div>
