<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<div class="main-content dashboard-page">
  <div class="dashboard-container exec-screen">
    <div class="dashboard-header">
      <div class="exec-screen-topbar">
        <div>
          <h1>高等级告警</h1>
          <p>仅以列表方式展示高等级告警推送，便于管理层快速浏览。</p>
        </div>
        <div class="exec-screen-actions">
          <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execScreen">← 返回大屏</a>
          <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execDesk">返回工作台</a>
        </div>
      </div>
    </div>

    <section class="dashboard-chart-section" style="margin-top:0;">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">高等级告警推送列表</div>
          <div class="dashboard-section-hint">数据来源：Alarm_Info（Alarm_Level = '高'），按发生时间倒序。</div>
        </div>
        <div class="dashboard-meta">
          <div class="dashboard-meta-item">共 <b><c:out value="${empty highAlarms ? 0 : highAlarms.size()}"/></b> 条</div>
        </div>
      </div>

      <c:choose>
        <c:when test="${empty highAlarms}">
          <div class="dashboard-empty">暂无高等级告警。</div>
        </c:when>
        <c:otherwise>
          <ul class="exec-alarm-list" style="padding:0; margin:0;">
            <c:forEach items="${highAlarms}" var="a">
              <li style="padding:12px 14px;">
                <span class="workbench-tag danger">高</span>
                <span class="exec-alarm-time" style="min-width:120px;"><c:out value="${a.occurTime}"/></span>
                <span class="exec-alarm-content"><c:out value="${a.content}"/></span>
                <c:if test="${not empty a.factoryName}">
                  <span class="dashboard-section-hint" style="margin-left:10px;">厂区：<c:out value="${a.factoryName}"/></span>
                </c:if>
                <c:if test="${not empty a.deviceName}">
                  <span class="dashboard-section-hint" style="margin-left:10px;">设备：<c:out value="${a.deviceName}"/></span>
                </c:if>
              </li>
            </c:forEach>
          </ul>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
