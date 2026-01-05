<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'device_list' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>分布式光伏设备监控</h1>
    <p>覆盖逆变器与汇流箱的运行状态、装机容量与实时发电指标。</p>
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
      <div class="pv-stat-label">接入设备数</div>
      <div class="pv-stat-value">${pvStats.totalCount}</div>
      <div class="pv-stat-trend">设备总数</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">在线设备</div>
      <div class="pv-stat-value">${pvStats.normalCount}</div>
      <div class="pv-stat-trend">运行正常</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">今日累计发电</div>
      <div class="pv-stat-value"><c:out value="${pvStats.todayGen}" default="0"/> kWh</div>
      <div class="pv-stat-trend">当日累计发电</div>
    </div>
    <div class="pv-stat-card">
      <div class="pv-stat-label">异常设备</div>
      <div class="pv-stat-value">${pvStats.faultCount}</div>
      <div class="pv-stat-trend down">故障设备数量</div>
    </div>
  </div>

  <c:if test="${not empty successMsg}">
    <div class="pv-alert pv-alert-success" style="margin: var(--spacing-md) 0; padding: var(--spacing-md); background: #f6ffed; border: 1px solid #b7eb8f; border-radius: var(--radius-md); color: #52c41a;">
      ${successMsg}
    </div>
  </c:if>

  <div class="pv-device-container">
    <div class="pv-device-header">
      <h1>设备运行概览</h1>
      <p>按照设备类型与运行状态快速定位故障与离线设备。</p>
    </div>

    <div class="pv-device-filter">
      <form method="get" action="${ctx}/app" class="pv-sort-form">
        <input type="hidden" name="module" value="pv"/>
        <input type="hidden" name="view" value="device_list"/>
        <label class="pv-sort-label">排序方式：</label>
        <select name="sortBy" class="pv-sort-select">
          <option value="deviceCode" <c:if test="${selectedSortBy == 'deviceCode'}">selected</c:if>>设备编号</option>
          <option value="collectTime" <c:if test="${selectedSortBy == 'collectTime'}">selected</c:if>>采集时间</option>
          <option value="capacity" <c:if test="${selectedSortBy == 'capacity'}">selected</c:if>>装机容量</option>
          <option value="deviceType" <c:if test="${selectedSortBy == 'deviceType'}">selected</c:if>>设备类型</option>
        </select>
        <select name="sortOrder" class="pv-sort-select">
          <option value="ASC" <c:if test="${selectedSortOrder == 'ASC'}">selected</c:if>>升序</option>
          <option value="DESC" <c:if test="${selectedSortOrder == 'DESC' || empty selectedSortOrder}">selected</c:if>>降序</option>
        </select>
        <button type="submit" class="pv-sort-btn">排序</button>
        <a href="${ctx}/app?module=pv&view=device_add" class="pv-sort-btn" style="text-decoration: none; margin-left: 8px;">+ 新增</a>
      </form>
    </div>

    <div class="pv-device-grid">
      <c:forEach items="${devices}" var="device">
        <div class="pv-device-card">
          <div class="pv-device-card-header">
            <div class="pv-device-name">${device.deviceCode}（${device.deviceType}）</div>
            <c:choose>
              <c:when test="${device.runStatus == '故障' || device.runStatus == '异常' || device.runStatus == '离线'}">
                <span class="pv-device-status maintenance"><c:out value="${device.runStatus}" default="未知"/></span>
              </c:when>
              <c:otherwise>
                <span class="pv-device-status online"><c:out value="${device.runStatus}" default="未知"/></span>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="pv-device-metrics">
            <div class="pv-device-metric">
              <div class="pv-device-metric-label">装机容量</div>
              <div class="pv-device-metric-value"><c:out value="${device.capacity}" default="-"/> kWp</div>
            </div>
            <div class="pv-device-metric">
              <div class="pv-device-metric-label">发电量</div>
              <div class="pv-device-metric-value"><c:out value="${device.genKwh}" default="-"/> kWh</div>
            </div>
            <div class="pv-device-metric">
              <div class="pv-device-metric-label">并网电量</div>
              <div class="pv-device-metric-value"><c:out value="${device.gridKwh}" default="-"/> kWh</div>
            </div>
            <div class="pv-device-metric">
              <div class="pv-device-metric-label">采集时间</div>
              <div class="pv-device-metric-value"><c:out value="${device.collectTime}" default="-"/></div>
            </div>
          </div>
          <div class="pv-device-card-footer">
            <a href="${ctx}/app?module=pv&view=device_detail&id=${device.deviceId}" class="pv-device-detail-btn">查看详情 →</a>
            <div class="pv-device-actions" style="display: flex; gap: var(--spacing-sm); margin-top: var(--spacing-sm);">
              <a href="${ctx}/app?module=pv&view=device_edit&id=${device.deviceId}" 
                 class="pv-btn-edit" style="padding: 4px 12px; background: #e6f7ff; color: #1890ff; border-radius: var(--radius-sm); text-decoration: none; font-size: 12px;">
                编辑
              </a>
              <form method="post" action="${ctx}/app" style="display: inline;" 
                    onsubmit="return confirm('确定要删除该设备吗？删除后相关发电数据也会被清除！');">
                <input type="hidden" name="module" value="pv"/>
                <input type="hidden" name="action" value="device_delete"/>
                <input type="hidden" name="deviceId" value="${device.deviceId}"/>
                <button type="submit" class="pv-btn-delete" 
                        style="padding: 4px 12px; background: #fff1f0; color: #ff4d4f; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 12px;">
                  删除
                </button>
              </form>
            </div>
          </div>
        </div>
      </c:forEach>
      <c:if test="${empty devices}">
        <div class="pv-device-card">
          <div class="pv-device-name">暂无光伏设备数据</div>
        </div>
      </c:if>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
