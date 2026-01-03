<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'device_detail' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>设备详情：<c:out value="${device.deviceCode}" default="--"/></h1>
    <p>查看单台设备的基础信息、运行指标与最近一次采集数据。</p>
    <div class="pv-subnav">
      <a class="<c:out value='${pvView == \"device_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_list">设备列表</a>
      <a class="<c:out value='${pvView == \"device_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_detail">设备详情</a>
      <a class="<c:out value='${pvView == \"gen_data_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=gen_data_list">发电数据</a>
      <a class="<c:out value='${pvView == \"forecast_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测优化</a>
      <a class="<c:out value='${pvView == \"forecast_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_detail">预测详情</a>
      <a class="<c:out value='${pvView == \"model_alert_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=model_alert_list">模型告警</a>
    </div>
  </div>

  <div class="pv-stats-cards">
    <div class="pv-stat-card">
      <div class="pv-stat-label">运行状态</div>
      <div class="pv-stat-value"><c:out value="${device.runStatus}" default="--"/></div>
      <div class="pv-stat-trend">设备运行状态</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">逆变效率</div>
      <div class="pv-stat-value"><c:out value="${latestGenRecord.inverterEff}" default="--"/>%</div>
      <div class="pv-stat-trend">最新采集效率</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">今日发电</div>
      <div class="pv-stat-value"><c:out value="${latestGenRecord.genKwh}" default="--"/> kWh</div>
      <div class="pv-stat-trend">自用电 <c:out value="${latestGenRecord.selfKwh}" default="--"/> kWh</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">装机容量</div>
      <div class="pv-stat-value"><c:out value="${device.capacity}" default="--"/> kWp</div>
      <div class="pv-stat-trend down">设备规格</div>
    </div>
  </div>

  <div class="pv-section" style="margin-top: var(--spacing-xl);">
    <div class="pv-table-header">
      <div class="pv-table-title">设备基础信息</div>
      <span class="pv-text-badge"><c:out value="${device.runStatus}" default="未知"/></span>
    </div>
    <div class="table-container">
      <table class="data-table">
        <tbody>
        <tr>
          <th>设备编号</th>
          <td><c:out value="${device.deviceCode}" default="-"/></td>
          <th>设备类型</th>
          <td><c:out value="${device.deviceType}" default="-"/></td>
        </tr>
        <tr>
          <th>安装位置</th>
          <td><c:out value="${device.pointName}" default="-"/></td>
          <th>装机容量</th>
          <td><c:out value="${device.capacity}" default="-"/> kWp</td>
        </tr>
        <tr>
          <th>投运时间</th>
          <td><c:out value="${device.installDate}" default="-"/></td>
          <th>通信协议</th>
          <td><c:out value="${device.protocol}" default="-"/></td>
        </tr>
        <tr>
          <th>并网点编号</th>
          <td><c:out value="${device.pointName}" default="-"/></td>
          <th>校准周期</th>
          <td><c:out value="${device.modelSpec}" default="-"/></td>
        </tr>
        </tbody>
      </table>
    </div>
  </div>

  <div class="pv-section" style="margin-top: var(--spacing-xl);">
    <div class="pv-table-header">
      <div class="pv-table-title">最近 5 条采集数据</div>
      <span class="pv-text-badge warn">5 分钟/次采集</span>
    </div>
    <div class="table-container">
      <table class="data-table">
        <thead>
        <tr>
          <th>采集时间</th>
          <th>发电量(kWh)</th>
          <th>上网电量(kWh)</th>
          <th>自用电量(kWh)</th>
          <th>逆变效率</th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${genRecords}" var="record" varStatus="status">
          <c:if test="${status.index < 5}">
            <tr>
              <td><c:out value="${record.collectTime}" default="-"/></td>
              <td><c:out value="${record.genKwh}" default="-"/></td>
              <td><c:out value="${record.gridKwh}" default="-"/></td>
              <td><c:out value="${record.selfKwh}" default="-"/></td>
              <td><c:out value="${record.inverterEff}" default="-"/>%</td>
            </tr>
          </c:if>
        </c:forEach>
        <c:if test="${empty genRecords}">
          <tr>
            <td colspan="5" style="text-align:center;color:#94a3b8;">暂无采集数据</td>
          </tr>
        </c:if>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
