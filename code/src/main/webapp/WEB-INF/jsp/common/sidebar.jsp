<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="m" value="${empty param.module ? requestScope.module : param.module}" />
<c:set var="permModules" value="${sessionScope.currentPermModules}" />

<div class="sidebar">
  <div style="padding:0 28px 14px 28px;">
    <div class="section-title" style="margin:0;">导航</div>
    <div style="color:#94a3b8;font-size:12px;margin-top:6px;">按模块进入（入口最终应受 RBAC 控制）</div>
  </div>

  <ul class="sidebar-menu">
    <c:if test="${permModules != null && permModules.contains('dashboard')}">
      <li>
        <a class="<c:out value='${m==\"dashboard\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=dashboard">
          <span class="icon">📊</span> <span>大屏/总览</span>
        </a>
      </li>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('dist')}">
      <li>
        <a class="<c:out value='${m==\"dist\" ? \"active\" : \"\"}'/>" href="${ctx}/dist?module=dist&action=room_list">
          <span class="icon">🔌</span> <span>配电网监测</span>
        </a>
        <ul style="padding-left:48px;margin-top:4px;">
          <li style="margin:4px 0;">
            <a href="${ctx}/dist?module=dist&action=room_list" style="font-size:13px;color:#64748b;">
              <span>配电房监测</span>
            </a>
          </li>
          <li style="margin:4px 0;">
            <a href="${ctx}/dist?module=dist&action=circuit_list" style="font-size:13px;color:#64748b;">
              <span>回路监测</span>
            </a>
          </li>
          <li style="margin:4px 0;">
            <a href="${ctx}/dist?module=dist&action=transformer_list" style="font-size:13px;color:#64748b;">
              <span>变压器监测</span>
            </a>
          </li>
          <li style="margin:4px 0;">
            <a href="${ctx}/view" style="font-size:13px;color:#64748b;">
              <span>业务视图查看</span>
            </a>
          </li>
        </ul>
      </li>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('pv')}">
      <li>
        <a class="<c:out value='${m==\"pv\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv">
          <span class="icon">☀️</span> <span>分布式光伏</span>
        </a>
      </li>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('energy')}">
      <li>
        <a class="<c:out value='${m==\"energy\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=energy">
          <span class="icon">⚡</span> <span>综合能耗</span>
        </a>
      </li>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('alarm')}">
      <c:set var="roleType" value="${sessionScope.currentRoleType}" />
      <c:choose>
        <c:when test="${roleType == 'OM'}">
          <li>
            <a class="<c:out value='${m==\"alarm\" ? \"active\" : \"\"}'/>" href="${ctx}/alarm?action=workorderList&module=alarm">
              <span class="icon">🚨</span> <span>我的工单</span>
            </a>
          </li>
        </c:when>
        <c:otherwise>
          <li>
            <a class="<c:out value='${m==\"alarm\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=alarm">
              <span class="icon">🚨</span> <span>告警运维</span>
            </a>
          </li>
        </c:otherwise>
      </c:choose>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('dispatcher')}">
      <li>
        <a class="<c:out value='${m==\"dispatcher\" ? \"active\" : \"\"}'/>" href="${ctx}/dispatcher?action=list&module=dispatcher">
          <span class="icon">🚨</span> <span>运维工单管理</span>
        </a>
      </li>
    </c:if>
    <c:if test="${permModules != null && permModules.contains('admin')}">
      <li>
        <a class="<c:out value='${m==\"admin\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=admin">
          <span class="icon">🛠️</span> <span>系统管理</span>
        </a>
      </li>
    </c:if>
  </ul>
</div>
