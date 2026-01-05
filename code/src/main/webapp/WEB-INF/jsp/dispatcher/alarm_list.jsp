<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>运维工单管理</h2>
      <p style="color:#64748b;margin-top:6px;">审核告警真实性，生成并派发运维工单。</p>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="stats-grid">
    <div class="stat-card alarm">
      <div class="stat-label">待审核告警</div>
      <div class="stat-value">${totalCount}</div>
      <div class="stat-change">需确认真实性</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">高等级告警</div>
      <div class="stat-value">${highCount}</div>
      <div class="stat-change">需要 15 分钟内派单</div>
    </div>
    <div class="stat-card" style="background:#fef2f2;border:1px solid #fecaca;">
      <div class="stat-label" style="color:#dc2626;">紧急告警</div>
      <div class="stat-value" style="color:#dc2626;">${urgentCount}</div>
      <div class="stat-change" style="color:#b91c1c;">高等级待审核/未处理</div>
    </div>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>告警编号</th>
        <th>告警类型</th>
        <th>等级</th>
        <th>告警内容</th>
        <th>发生时间</th>
        <th>关联设备</th>
        <th>派单时效</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${alarms}" var="a">
        <tr class="<c:if test='${a.alarmLevel == "高" && (a.processStatus == "待审核" || a.processStatus == "未处理")}'>highlight-row</c:if>">
          <td>${a.alarmId}</td>
          <td>${a.alarmType}</td>
          <td>
            <span class="alarm-level <c:out value='${a.alarmLevel == "高" ? "high" : (a.alarmLevel == "中" ? "medium" : "low")}'/>">
              ${a.alarmLevel}
            </span>
          </td>
          <td>${a.content}</td>
          <td>${a.occurTime}</td>
          <td>
            <div>${a.deviceName}</div>
            <div style="font-size:12px;color:#94a3b8;">${a.deviceType}</div>
          </td>
          <td>
            <c:choose>
              <c:when test="${a.dispatchOverdue}">
                <span class="alarm-sla-tag overdue">已超时</span>
              </c:when>
              <c:otherwise>
                <span class="alarm-sla-tag">待派单</span>
              </c:otherwise>
            </c:choose>
          </td>
          <td>
            <a class="btn btn-link" href="${ctx}/dispatcher?action=detail&id=${a.alarmId}">审核</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty alarms}">
        <tr>
          <td colspan="8" style="text-align:center;color:#94a3b8;">暂无待审核告警</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
