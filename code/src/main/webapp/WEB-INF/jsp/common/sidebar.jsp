<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="m" value="${empty param.module ? requestScope.module : param.module}" />
<c:set var="v" value="${empty param.view ? requestScope.view : param.view}" />
<c:set var="permModules" value="${sessionScope.currentPermModules}" />
<c:set var="roleType" value="${sessionScope.currentRoleType}" />

<div class="sidebar">
  <div style="padding:0 28px 14px 28px;">
    <div class="section-title" style="margin:0;">导航</div>
    <div style="color:#94a3b8;font-size:12px;margin-top:6px;">按模块进入（入口最终应受 RBAC 控制）</div>
  </div>

  <ul class="sidebar-menu">
    <!-- 企业管理层（EXEC） -->
    <c:if test="${roleType == 'EXEC'}">
      <li>
        <a class="<c:out value='${m=="dashboard" && v=="execDesk" ? "active" : ""}'/>"
           href="${ctx}/app?module=dashboard&view=execDesk">
          <span class="icon">🏠</span> <span>工作台</span>
        </a>
      </li>
      <li>
        <a class="<c:out value='${m=="dashboard" && v=="execScreen" ? "active" : ""}'/>"
           href="${ctx}/app?module=dashboard&view=execScreen">
          <span class="icon">📺</span> <span>大屏</span>
        </a>
      </li>
      <li>
        <a class="<c:out value='${m=="energy" && v=="report_overview" ? "active" : ""}'/>"
           href="${ctx}/app?module=energy&view=report_overview">
          <span class="icon">📈</span> <span>月度/季度能耗报告</span>
        </a>
      </li>
      <li>
        <a class="<c:out value='${m=="dashboard" && v=="execProject" ? "active" : ""}'/>"
           href="${ctx}/app?module=dashboard&view=execProject">
          <span class="icon">🧾</span> <span>科研项目申报/结题</span>
        </a>
      </li>
    </c:if>

    <!-- 非 EXEC：按模块 + 角色展示 -->
    <c:if test="${roleType != 'EXEC'}">

      <c:if test="${permModules != null && permModules.contains('dashboard')}">
        <c:choose>
          <c:when test="${roleType == 'ENERGY'}">
            <li>
              <a class="<c:out value='${m=="dashboard" && empty v ? "active" : ""}'/>"
                 href="${ctx}/app?module=dashboard">
                <span class="icon">📊</span> <span>综合能耗总览</span>
              </a>
            </li>
            <li>
              <a class="<c:out value='${m=="dashboard" && v=="execScreen" ? "active" : ""}'/>"
                 href="${ctx}/app?module=dashboard&view=execScreen">
                <span class="icon">📺</span> <span>综合能耗大屏</span>
              </a>
            </li>
          </c:when>

          <c:otherwise>
            <li>
              <a class="<c:out value='${m=="dashboard" ? "active" : ""}'/>"
                 href="${ctx}/app?module=dashboard">
                <span class="icon">📊</span> <span>大屏/总览</span>
              </a>
            </li>
          </c:otherwise>
        </c:choose>
      </c:if>

      <c:if test="${permModules != null && permModules.contains('dist')}">
        <li>
          <a class="<c:out value='${m=="dist" ? "active" : ""}'/>"
             href="${ctx}/dist?module=dist&action=room_list">
            <span class="icon">🔌</span> <span>配电网监测</span>
          </a>
        </li>
      </c:if>

      <c:if test="${permModules != null && permModules.contains('pv')}">
        <li>
          <a class="<c:out value='${m=="pv" ? "active" : ""}'/>"
             href="${ctx}/app?module=pv">
            <span class="icon">☀️</span> <span>分布式光伏</span>
          </a>
        </li>
      </c:if>

      <c:if test="${permModules != null && permModules.contains('energy')}">
        <li>
          <a class="<c:out value='${m=="energy" ? "active" : ""}'/>"
             href="${ctx}/app?module=energy">
            <span class="icon">⚡</span> <span>综合能耗</span>
          </a>
        </li>
      </c:if>

      <c:if test="${permModules != null && permModules.contains('alarm')}">
        <li>
          <a class="<c:out value='${m=="alarm" ? "active" : ""}'/>"
             href="${ctx}/app?module=alarm">
            <span class="icon">🚨</span> <span>告警运维</span>
          </a>
        </li>
      </c:if>

      <c:if test="${permModules != null && permModules.contains('admin')}">
        <li>
          <a class="<c:out value='${m=="admin" ? "active" : ""}'/>"
             href="${ctx}/app?module=admin">
            <span class="icon">🛠️</span> <span>系统管理</span>
          </a>
        </li>
      </c:if>
    </c:if>
  </ul>
</div>
