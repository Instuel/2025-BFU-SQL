<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'gen_data_list' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>光伏发电数据管理</h1>
    <p>实时采集 5 分钟一条的发电数据，展示并网点与设备的发电表现。</p>
    <div class="pv-subnav">
      <a class="<c:out value='${pvView == \"device_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_list">设备列表</a>
      <a class="<c:out value='${pvView == \"device_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_detail">设备详情</a>
      <a class="<c:out value='${pvView == \"gen_data_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=gen_data_list">发电数据</a>
      <a class="<c:out value='${pvView == \"forecast_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测优化</a>
      <a class="<c:out value='${pvView == \"forecast_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_detail">预测详情</a>
      <a class="<c:out value='${pvView == \"model_alert_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=model_alert_list">模型告警</a>
    </div>
  </div>

  <div class="pv-content-container">
    <div class="pv-sidebar">
      <form method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="pv"/>
        <input type="hidden" name="view" value="gen_data_list"/>
        <div class="pv-sidebar-title">筛选条件</div>
        <div class="pv-filter-group">
          <label class="pv-filter-label">并网点编号</label>
          <select class="pv-filter-select" name="pointId">
            <option value="">全部</option>
            <c:forEach items="${gridPoints}" var="point">
              <option value="${point.pointId}" <c:if test="${selectedPointId == point.pointId}">selected</c:if>>
                ${point.pointName}
              </option>
            </c:forEach>
          </select>
        </div>
        <button class="pv-filter-btn">查询数据</button>
      </form>
    </div>

    <div class="pv-main-content">
      <div class="pv-stats-cards">
        <div class="pv-stat-card">
          <div class="pv-stat-label">今日总发电量</div>
          <div class="pv-stat-value"><c:out value="${latestGenRecord.genKwh}" default="--"/> kWh</div>
          <div class="pv-stat-trend">上网 <c:out value="${latestGenRecord.gridKwh}" default="--"/> kWh</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">逆变效率均值</div>
          <div class="pv-stat-value"><c:out value="${latestGenRecord.inverterEff}" default="--"/>%</div>
          <div class="pv-stat-trend down">最新采集效率</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">数据完整率</div>
          <div class="pv-stat-value">${fn:length(genRecords)}</div>
          <div class="pv-stat-trend">当前筛选记录数</div>
        </div>
      </div>

      <div class="pv-section">
        <div class="pv-table-header">
          <div class="pv-table-title">发电数据明细</div>
          <span class="pv-text-badge warn">实时采集 5 分钟/次</span>
        </div>
        <div class="table-container">
          <table class="data-table">
            <thead>
            <tr>
              <th>数据编号</th>
              <th>设备编号</th>
              <th>并网点编号</th>
              <th>采集时间</th>
              <th>发电量(kWh)</th>
              <th>上网电量(kWh)</th>
              <th>自用电量(kWh)</th>
              <th>逆变效率</th>
              <th>状态</th>
            </tr>
            </thead>
            <tbody>
            <c:forEach items="${genRecords}" var="record">
              <tr>
                <td>${record.dataId}</td>
                <td>${record.deviceCode}</td>
                <td>${record.pointName}</td>
                <td><c:out value="${record.collectTime}" default="-"/></td>
                <td><c:out value="${record.genKwh}" default="-"/></td>
                <td><c:out value="${record.gridKwh}" default="-"/></td>
                <td><c:out value="${record.selfKwh}" default="-"/></td>
                <td><c:out value="${record.inverterEff}" default="-"/>%</td>
                <td><span class="pv-text-badge">已采集</span></td>
              </tr>
            </c:forEach>
            <c:if test="${empty genRecords}">
              <tr>
                <td colspan="9" style="text-align:center;color:#94a3b8;">暂无发电数据</td>
              </tr>
            </c:if>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
