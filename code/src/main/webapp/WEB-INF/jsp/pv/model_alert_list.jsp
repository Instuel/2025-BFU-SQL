<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'model_alert_list' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>模型优化提醒</h1>
    <p>当预测偏差率连续 3 天超过 15% 时触发提醒，指引模型优化。</p>
    <div class="pv-subnav">
      <a class="<c:out value='${pvView == \"device_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_list">设备列表</a>
      <a class="<c:out value='${pvView == \"device_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_detail">设备详情</a>
      <a class="<c:out value='${pvView == \"gen_data_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=gen_data_list">发电数据</a>
      <a class="<c:out value='${pvView == \"forecast_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测信息</a>
      <a class="<c:out value='${pvView == \"forecast_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_detail">预测详情</a>
      <a class="<c:out value='${pvView == \"model_alert_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=model_alert_list">模型告警</a>
    </div>
  </div>

  <div class="pv-stats-cards">
    <div class="pv-stat-card">
      <div class="pv-stat-label">待处理提醒</div>
      <div class="pv-stat-value">${fn:length(modelAlerts)}</div>
      <div class="pv-stat-trend down">当前告警数量</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">模型优化完成</div>
      <div class="pv-stat-value"><c:out value="${modelAlerts[0].modelVersion}" default="--"/></div>
      <div class="pv-stat-trend">最新模型版本</div>
    </div>
  </div>

  <div class="pv-section" style="margin-top: var(--spacing-xl);">
    <div class="pv-table-header">
      <div class="pv-table-title">模型告警列表</div>
      <div style="display: flex; align-items: center; gap: var(--spacing-md);">
        <form method="get" action="${ctx}/app" style="display: flex; align-items: center; gap: var(--spacing-sm);">
          <input type="hidden" name="module" value="pv"/>
          <input type="hidden" name="view" value="model_alert_list"/>
          <label class="pv-filter-label" style="margin-bottom: 0;">状态筛选：</label>
          <select name="statusFilter" class="pv-sort-select" onchange="this.form.submit()">
            <option value="">全部</option>
            <option value="未处理" <c:if test="${selectedStatusFilter == '未处理'}">selected</c:if>>未处理</option>
            <option value="待处理" <c:if test="${selectedStatusFilter == '待处理'}">selected</c:if>>紧急处理</option>
          </select>
        </form>
        <span class="pv-text-badge danger">偏差率超 15%</span>
      </div>
    </div>
    <div class="table-container">
      <table class="data-table">
        <thead>
        <tr>
          <th>告警编号</th>
          <th>并网点编号</th>
          <th>触发日期</th>
          <th>备注</th>
          <th>模型版本</th>
          <th>状态</th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${modelAlerts}" var="alert">
          <tr>
            <td>${alert.alertId}</td>
            <td>${alert.pointName}</td>
            <td><c:out value="${alert.triggerTime}" default="-"/></td>
            <td><c:out value="${alert.remark}" default="-"/></td>
            <td><c:out value="${alert.modelVersion}" default="-"/></td>
            <td><span class="pv-text-badge <c:if test='${alert.processStatus == "待处理"}'>warn</c:if>"><c:out value="${alert.processStatus}" default="-"/></span></td>
          </tr>
        </c:forEach>
        <c:if test="${empty modelAlerts}">
          <tr>
            <td colspan="6" style="text-align:center;color:#94a3b8;">暂无模型告警</td>
          </tr>
        </c:if>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
