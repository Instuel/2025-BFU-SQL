<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">← 返回台账列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>设备台账详情</h2>
      <p style="color:#64748b;margin-top:6px;">查看设备生命周期与维修记录。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn primary" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${ledger == null}">
    <div class="warning-message">未找到设备台账。</div>
  </c:if>

  <c:if test="${ledger != null}">
    <div class="rule-form">
      <div class="rule-form-header">
        <h2>设备信息</h2>
        <c:choose>
          <c:when test="${ledger.warrantyStatus == '即将到期'}">
            <span class="warranty-tag warning">即将到期</span>
          </c:when>
          <c:when test="${ledger.warrantyStatus == '已过期'}">
            <span class="warranty-tag expired">已过期</span>
          </c:when>
          <c:otherwise>
            <span class="warranty-tag">${ledger.warrantyStatus}</span>
          </c:otherwise>
        </c:choose>
      </div>
      <div class="table-container">
        <table class="table">
          <tbody>
          <tr>
            <th>台账编号</th>
            <td>${ledger.ledgerId}</td>
            <th>设备名称</th>
            <td>${ledger.deviceName}</td>
          </tr>
          <tr>
            <th>设备类型</th>
            <td>${ledger.deviceType}</td>
            <th>型号规格</th>
            <td>${ledger.modelSpec}</td>
          </tr>
          <tr>
            <th>安装时间</th>
            <td>${ledger.installTime}</td>
            <th>质保年限</th>
            <td>${ledger.warrantyYears}</td>
          </tr>
          <tr>
            <th>质保到期</th>
            <td>${ledger.warrantyExpireDate}</td>
            <th>剩余天数</th>
            <td>${ledger.warrantyDaysLeft}</td>
          </tr>
          <tr>
            <th>校准时间</th>
            <td>${ledger.calibrationTime}</td>
            <th>校准人员</th>
            <td>${ledger.calibrationPerson}</td>
          </tr>
          <tr>
            <th>报废状态</th>
            <td colspan="3">${ledger.scrapStatus}</td>
          </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="order-list" style="margin-top:24px;">
      <div class="order-list-header">
        <h2>维修记录（关联工单）</h2>
      </div>
      <c:forEach items="${orders}" var="o">
        <div class="order-item">
          <div class="order-item-header">
            <div class="order-id">工单 #${o.orderId}</div>
            <span class="order-priority <c:out value='${o.alarmLevel == "高" ? "high" : (o.alarmLevel == "中" ? "medium" : "low")}'/>">${o.alarmLevel}级</span>
          </div>
          <div class="order-details">
            <div class="order-detail"><strong>告警编号：</strong>${o.alarmId}</div>
            <div class="order-detail"><strong>派单时间：</strong>${o.dispatchTime}</div>
            <div class="order-detail"><strong>完成时间：</strong>${o.finishTime}</div>
            <div class="order-detail"><strong>复查状态：</strong>${o.reviewStatus}</div>
          </div>
          <div style="margin-top:12px;">
            <a class="btn btn-link" href="${ctx}/alarm?action=workorderDetail&id=${o.orderId}&module=alarm">查看工单</a>
          </div>
        </div>
      </c:forEach>
      <c:if test="${empty orders}">
        <div style="color:#94a3b8;">暂无维修记录。</div>
      </c:if>
    </div>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
