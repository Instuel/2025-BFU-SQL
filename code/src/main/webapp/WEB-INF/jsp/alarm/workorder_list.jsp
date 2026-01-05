<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>运维工单管理</h2>
      <p style="color:#64748b;margin-top:6px;">跟踪派单、响应与复查流程。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn primary" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
    <a class="action-btn" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="order-stats">
    <div class="order-stat-card pending">
      <div class="order-stat-label">待响应</div>
      <div class="order-stat-value">${orderPending}</div>
    </div>
    <div class="order-stat-card processing">
      <div class="order-stat-label">处理中</div>
      <div class="order-stat-value">${orderProcessing}</div>
    </div>
    <div class="order-stat-card completed">
      <div class="order-stat-label">已完成</div>
      <div class="order-stat-value">${orderCompleted}</div>
    </div>
    <div class="order-stat-card">
      <div class="order-stat-label">超时未响应</div>
      <div class="order-stat-value">${orderOverdue}</div>
    </div>
    <div class="order-stat-card">
      <div class="order-stat-label">工单总数</div>
      <div class="order-stat-value">${orderTotal}</div>
    </div>
  </div>

  <div class="rule-form" style="margin-top:16px;">
    <div class="rule-form-header">
      <h2>工单筛选</h2>
    </div>
    <form method="get" action="${ctx}/alarm" class="rule-form-grid">
      <input type="hidden" name="action" value="workorderList"/>
      <input type="hidden" name="module" value="alarm"/>
      <div class="form-group">
        <label>复查状态</label>
        <select name="reviewStatus">
          <option value="">全部</option>
          <option value="通过" <c:if test="${reviewStatus == '通过'}">selected</c:if>>通过</option>
          <option value="未通过" <c:if test="${reviewStatus == '未通过'}">selected</c:if>>未通过</option>
        </select>
      </div>
      <div class="form-group" style="display:flex;align-items:flex-end;gap:12px;">
        <button class="btn btn-primary" type="submit">应用筛选</button>
        <a class="btn btn-secondary" href="${ctx}/alarm?action=workorderList&module=alarm">重置</a>
      </div>
    </form>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>工单编号</th>
        <th>告警编号</th>
        <th>设备</th>
        <th>告警等级</th>
        <th>派单时间</th>
        <th>响应时间</th>
        <th>完成时间</th>
        <th>提醒状态</th>
        <th>复查状态</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${orders}" var="o">
        <tr>
          <td>${o.orderId}</td>
          <td>${o.alarmId}</td>
          <td>
            <div>${o.deviceName}</div>
            <div style="font-size:12px;color:#94a3b8;">${o.deviceType}</div>
          </td>
          <td>
            <span class="order-priority <c:out value='${o.alarmLevel == "高" ? "high" : (o.alarmLevel == "中" ? "medium" : "low")}'/>">
              ${o.alarmLevel}
            </span>
          </td>
          <td>${o.dispatchTime}</td>
          <td>${o.responseTime}</td>
          <td>${o.finishTime}</td>
          <td>
            <c:choose>
              <c:when test="${o.responseOverdue}">
                <span class="order-reminder-tag overdue">超时提醒</span>
              </c:when>
              <c:otherwise>
                <span class="order-reminder-tag">正常</span>
              </c:otherwise>
            </c:choose>
          </td>
          <td>${o.reviewStatus}</td>
          <td>
            <a class="btn btn-link" href="${ctx}/alarm?action=workorderDetail&id=${o.orderId}&module=alarm">查看</a>
            <c:if test="${currentRoleType != 'OM'}">
              <a class="btn btn-link" href="${ctx}/alarm?action=detail&id=${o.alarmId}&module=alarm">告警</a>
            </c:if>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty orders}">
        <tr>
          <td colspan="10" style="text-align:center;color:#94a3b8;">暂无工单数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
