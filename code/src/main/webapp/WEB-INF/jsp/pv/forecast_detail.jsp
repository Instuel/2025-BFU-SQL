<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'forecast_detail' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>预测详情：<c:out value="${forecast.forecastDate}" default="--"/>（<c:out value="${forecast.pointName}" default="--"/>）</h1>
    <p>逐时段预测与实际发电量对比，关注偏差率超标的时段。</p>
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
      <div class="pv-stat-label">预测总发电量</div>
      <div class="pv-stat-value"><c:out value="${forecast.forecastVal}" default="--"/> kWh</div>
      <div class="pv-stat-trend">模型版本 <c:out value="${forecast.modelVersion}" default="--"/></div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">实际总发电量</div>
      <div class="pv-stat-value"><c:out value="${forecast.actualVal}" default="--"/> kWh</div>
      <div class="pv-stat-trend">并网点 <c:out value="${forecast.pointName}" default="--"/></div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">平均偏差率</div>
      <div class="pv-stat-value"><c:out value="${forecast.deviationRate}" default="--"/>%</div>
      <div class="pv-stat-trend">当前预测偏差</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">异常时段</div>
      <div class="pv-stat-value">1</div>
      <div class="pv-stat-trend down">详情查看下方表格</div>
    </div>
  </div>

  <div class="pv-section" style="margin-top: var(--spacing-xl);">
    <div class="pv-table-header">
      <div class="pv-table-title">小时级预测对比</div>
      <span class="pv-text-badge warn">偏差率超 15% 触发提醒</span>
    </div>
    <div class="table-container">
      <table class="data-table">
        <thead>
        <tr>
          <th>预测时段</th>
          <th>预测发电量(kWh)</th>
          <th>实际发电量(kWh)</th>
          <th>偏差率</th>
          <th>状态</th>
        </tr>
        </thead>
        <tbody>
        <c:if test="${forecast != null}">
          <tr>
            <td><c:out value="${forecast.timeSlot}" default="-"/></td>
            <td><c:out value="${forecast.forecastVal}" default="-"/></td>
            <td><c:out value="${forecast.actualVal}" default="-"/></td>
            <td><c:out value="${forecast.deviationRate}" default="-"/>%</td>
            <td><span class="pv-deviation-badge low">已生成</span></td>
          </tr>
        </c:if>
        <c:if test="${forecast == null}">
          <tr>
            <td colspan="5" style="text-align:center;color:#94a3b8;">暂无预测详情</td>
          </tr>
        </c:if>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
