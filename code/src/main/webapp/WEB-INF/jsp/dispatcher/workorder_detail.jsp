<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/dispatcher?action=list">← 返回告警列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>工单详情</h2>
      <p style="color:#64748b;margin-top:6px;">查看运维工单的详细信息。</p>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${workOrder == null}">
    <div class="warning-message">未找到对应工单。</div>
  </c:if>

  <c:if test="${workOrder != null}">
    <div class="rule-form">
      <div class="rule-form-header">
        <h2>工单信息</h2>
        <span class="order-priority <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">${alarm.alarmLevel}级</span>
      </div>
      <div class="table-container">
        <table class="table">
          <tbody>
          <tr>
            <th>工单编号</th>
            <td>${workOrder.orderId}</td>
            <th>告警编号</th>
            <td>${workOrder.alarmId}</td>
          </tr>
          <tr>
            <th>运维人员 ID</th>
            <td>${workOrder.oandmId}</td>
            <th>设备台账编号</th>
            <td>${workOrder.ledgerId}</td>
          </tr>
          <tr>
            <th>派单时间</th>
            <td>${workOrder.dispatchTime}</td>
            <th>响应时间</th>
            <td>${workOrder.responseTime}</td>
          </tr>
          <tr>
            <th>完成时间</th>
            <td>${workOrder.finishTime}</td>
            <th>响应提醒</th>
            <td>
              <c:choose>
                <c:when test="${workOrder.responseOverdue}">
                  <span class="order-reminder-tag overdue">超时提醒</span>
                </c:when>
                <c:otherwise>
                  <span class="order-reminder-tag">正常</span>
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
          <tr>
            <th>复查状态</th>
            <td>
              <c:choose>
                <c:when test="${workOrder.reviewStatus == '通过'}"><span class="order-review-tag pass">通过</span></c:when>
                <c:when test="${workOrder.reviewStatus == '未通过'}"><span class="order-review-tag fail">未通过</span></c:when>
                <c:otherwise><span class="order-review-tag pending">待复查</span></c:otherwise>
              </c:choose>
            </td>
            <th>附件路径</th>
            <td>${workOrder.attachmentPath}</td>
          </tr>
          <tr>
            <th>结果描述</th>
            <td colspan="3">${workOrder.resultDesc}</td>
          </tr>
          </tbody>
        </table>
      </div>
    </div>

    <c:if test="${alarm != null}">
      <div class="order-list" style="margin-top:24px;">
        <div class="order-list-header">
          <h2>关联告警</h2>
        </div>
        <div class="order-item">
          <div class="order-item-header">
            <div class="order-id">告警 #${alarm.alarmId}</div>
            <span class="alarm-level <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">${alarm.alarmLevel}</span>
          </div>
          <div class="order-item-body">
            <div class="order-field">
              <span class="order-label">告警类型:</span>
              <span class="order-value">${alarm.alarmType}</span>
            </div>
            <div class="order-field">
              <span class="order-label">发生时间:</span>
              <span class="order-value">${alarm.occurTime}</span>
            </div>
            <div class="order-field">
              <span class="order-label">设备:</span>
              <span class="order-value">${alarm.deviceName} (${alarm.deviceType})</span>
            </div>
            <div class="order-field">
              <span class="order-label">告警内容:</span>
              <span class="order-value">${alarm.content}</span>
            </div>
          </div>
        </div>
      </div>
    </c:if>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
