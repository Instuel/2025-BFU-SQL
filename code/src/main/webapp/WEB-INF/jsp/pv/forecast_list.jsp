<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="pvView" value="${empty param.view ? 'forecast_list' : param.view}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>光伏预测信息</h1>
    <p>基于历史发电与天气数据生成次日预测，并对偏差率进行持续优化。</p>
    <div class="pv-subnav">
      <a class="<c:out value='${pvView == \"device_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_list">设备列表</a>
      <a class="<c:out value='${pvView == \"device_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=device_detail">设备详情</a>
      <a class="<c:out value='${pvView == \"gen_data_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=gen_data_list">发电数据</a>
<<<<<<< HEAD
      <a class="<c:out value='${pvView == \"forecast_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测优化</a>
=======
      <a class="<c:out value='${pvView == \"forecast_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测信息</a>
>>>>>>> origin/main
      <a class="<c:out value='${pvView == \"forecast_detail\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=forecast_detail">预测详情</a>
      <a class="<c:out value='${pvView == \"model_alert_list\" ? \"active\" : \"\"}'/>" href="${ctx}/app?module=pv&view=model_alert_list">模型告警</a>
    </div>
  </div>

  <div class="pv-content-container">
    <div class="pv-sidebar">
      <form method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="pv"/>
        <input type="hidden" name="view" value="forecast_list"/>
        <div class="pv-sidebar-title">预测筛选</div>
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
        <button class="pv-filter-btn">查询预测</button>
      </form>
    </div>

    <div class="pv-main-content">
      <div class="pv-stats-cards">
        <div class="pv-stat-card">
          <div class="pv-stat-label">预测总发电量</div>
<<<<<<< HEAD
          <div class="pv-stat-value"><c:out value="${latestForecast.forecastVal}" default="--"/> kWh</div>
          <div class="pv-stat-trend">最新预测记录</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">平均偏差率</div>
          <div class="pv-stat-value"><c:out value="${latestForecast.deviationRate}" default="--"/>%</div>
          <div class="pv-stat-trend">最新偏差率</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">触发优化提醒</div>
          <div class="pv-stat-value">${fn:length(forecasts)}</div>
          <div class="pv-stat-trend down">当前筛选预测条数</div>
=======
          <div class="pv-stat-value"><c:out value="${totalForecastVal}" default="--"/> kWh</div>
          <div class="pv-stat-trend">所有预测记录累计</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">平均偏差率</div>
          <div class="pv-stat-value"><c:out value="${avgDeviationRate}" default="--"/>%</div>
          <div class="pv-stat-trend">所有记录平均值</div>
        </div>
        <div class="pv-stat-card">
          <div class="pv-stat-label">触发优化提醒</div>
          <div class="pv-stat-value">${deviationOverCount}</div>
          <div class="pv-stat-trend down">偏差率超15%记录数</div>
>>>>>>> origin/main
        </div>
      </div>

      <div class="pv-deviation-table">
        <div class="pv-table-header">
          <div class="pv-table-title">预测偏差明细</div>
          <span class="pv-text-badge warn">偏差率超 15% 触发优化提醒</span>
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
<<<<<<< HEAD
=======
              <th>操作</th>
>>>>>>> origin/main
            </tr>
            </thead>
            <tbody>
            <c:forEach items="${forecasts}" var="forecast">
              <tr>
                <td>${forecast.timeSlot}</td>
                <td><c:out value="${forecast.forecastVal}" default="-"/></td>
                <td><c:out value="${forecast.actualVal}" default="-"/></td>
                <td><c:out value="${forecast.deviationRate}" default="-"/>%</td>
<<<<<<< HEAD
                <td><span class="pv-deviation-badge low">已生成</span></td>
=======
                <td>
                  <c:choose>
                    <c:when test="${forecast.deviationRate != null && (forecast.deviationRate > 15 || forecast.deviationRate < -15)}">
                      <span class="pv-deviation-badge warning">偏差率超标</span>
                    </c:when>
                    <c:otherwise>
                      <span class="pv-deviation-badge low">正常</span>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <a href="${ctx}/app?module=pv&view=forecast_detail&id=${forecast.forecastId}" class="pv-detail-link">查看详情</a>
                </td>
>>>>>>> origin/main
              </tr>
            </c:forEach>
            <c:if test="${empty forecasts}">
              <tr>
<<<<<<< HEAD
                <td colspan="5" style="text-align:center;color:#94a3b8;">暂无预测记录</td>
=======
                <td colspan="6" style="text-align:center;color:#94a3b8;">暂无预测记录</td>
>>>>>>> origin/main
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
