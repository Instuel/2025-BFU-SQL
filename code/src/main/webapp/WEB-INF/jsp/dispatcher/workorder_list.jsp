<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>运维工单追踪</h2>
      <p style="color:#64748b;margin-top:6px;">实时查看工单状态，审核运维结果。</p>
    </div>
    <div style="display:flex;gap:12px;align-items:center;">
      <label style="font-size:14px;color:#475569;">告警类型筛选：</label>
      <select id="alarmTypeFilter" onchange="filterWorkOrders()" style="padding:8px 12px;border:1px solid #e2e8f0;border-radius:6px;font-size:14px;min-width:150px;">
        <option value="">全部类型</option>
        <option value="越限告警">越限告警</option>
        <option value="设备故障">设备故障</option>
        <option value="通讯故障">通讯故障</option>
        <option value="设备离线">设备离线</option>
        <option value="环境告警">环境告警</option>
        <option value="安全告警">安全告警</option>
        <option value="其他">其他</option>
      </select>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-label">总工单数</div>
      <div class="stat-value">${totalCount}</div>
      <div class="stat-change">全部工单</div>
    </div>
    <div class="stat-card" style="background:#fef3c7;border:1px solid #fcd34d;">
      <div class="stat-label" style="color:#d97706;">待审核</div>
      <div class="stat-value" style="color:#d97706;">${pendingReviewCount}</div>
      <div class="stat-change" style="color:#b45309;">需要审核</div>
    </div>
    <div class="stat-card" style="background:#dcfce7;border:1px solid #86efac;">
      <div class="stat-label" style="color:#16a34a;">已通过</div>
      <div class="stat-value" style="color:#16a34a;">${passedCount}</div>
      <div class="stat-change" style="color:#15803d;">审核通过</div>
    </div>
    <div class="stat-card" style="background:#fee2e2;border:1px solid #fca5a5;">
      <div class="stat-label" style="color:#dc2626;">未通过</div>
      <div class="stat-value" style="color:#dc2626;">${failedCount}</div>
      <div class="stat-change" style="color:#b91c1c;">需要返工</div>
    </div>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>工单编号</th>
        <th>告警类型</th>
        <th>等级</th>
        <th>设备名称</th>
        <th>运维人员</th>
        <th>派单时间</th>
        <th>响应时间</th>
        <th>完成时间</th>
        <th>审核状态</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${workOrders}" var="wo">
        <tr class="<c:if test='${wo.reviewStatus == null || wo.reviewStatus == ""}'>highlight-row</c:if>" data-alarm-type="${wo.alarmType}">
          <td>${wo.orderId}</td>
          <td>${wo.alarmType}</td>
          <td>
            <span class="alarm-level <c:out value='${wo.alarmLevel == "高" ? "high" : (wo.alarmLevel == "中" ? "medium" : "low")}'/>">
              ${wo.alarmLevel}
            </span>
          </td>
          <td>
            <div>${wo.deviceName}</div>
            <div style="font-size:12px;color:#94a3b8;">${wo.deviceType}</div>
          </td>
          <td>${wo.oandmName}</td>
          <td>${wo.dispatchTime}</td>
          <td>${wo.responseTime}</td>
          <td>${wo.finishTime}</td>
          <td>
            <c:choose>
              <c:when test="${wo.reviewStatus == '通过'}">
                <span class="order-review-tag pass">通过</span>
              </c:when>
              <c:when test="${wo.reviewStatus == '未通过'}">
                <span class="order-review-tag fail">未通过</span>
              </c:when>
              <c:otherwise>
                <span class="order-review-tag pending">待审核</span>
              </c:otherwise>
            </c:choose>
          </td>
          <td>
            <a class="btn btn-link" href="${ctx}/dispatcher?action=reviewWorkOrder&id=${wo.orderId}">审核</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty workOrders}">
        <tr>
          <td colspan="10" style="text-align:center;color:#94a3b8;">暂无工单</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<script>
function filterWorkOrders() {
  const selectedType = document.getElementById('alarmTypeFilter').value;
  const rows = document.querySelectorAll('tbody tr');
  
  rows.forEach(row => {
    if (row.querySelector('td[colspan]')) {
      row.style.display = '';
      return;
    }
    
    const alarmType = row.getAttribute('data-alarm-type');
    if (selectedType === '' || alarmType === selectedType) {
      row.style.display = '';
    } else {
      row.style.display = 'none';
    }
  });
}
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
