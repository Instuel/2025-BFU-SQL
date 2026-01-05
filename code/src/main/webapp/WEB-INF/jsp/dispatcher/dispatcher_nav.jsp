<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="act" value="${empty param.action ? requestScope.action : param.action}" />

<div class="sidebar">
  <div style="padding:0 28px 14px 28px;">
    <div class="section-title" style="margin:0;">运维工单管理</div>
    <div style="color:#94a3b8;font-size:12px;margin-top:6px;">告警审核与工单派发</div>
  </div>

  <ul class="sidebar-menu">
    <li>
      <a href="${ctx}/app?module=dashboard">
        <span class="icon">⬅️</span> <span>返回大屏/总览</span>
      </a>
    </li>

    <li>
      <a class="<c:out value='${act=="list" ? "active" : ""}'/>"
         href="${ctx}/dispatcher?action=list&module=dispatcher">
        <span class="icon">📋</span> <span>告警审核列表</span>
      </a>
    </li>
    <li>
      <a class="<c:out value='${act=="workOrderList" ? "active" : ""}'/>"
         href="${ctx}/dispatcher?action=workOrderList&module=dispatcher">
        <span class="icon">🔍</span> <span>工单追踪</span>
      </a>
    </li>
  </ul>
</div>
