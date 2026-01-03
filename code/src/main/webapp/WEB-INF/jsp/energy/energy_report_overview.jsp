<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 区域能耗报表</h1>
      <p>按月汇总不同厂区与能源类型能耗数据，并对比峰谷差值。</p>
    </div>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="report_overview"/>
        <span class="energy-filter-label">能源类型</span>
        <select class="energy-filter-select" name="energyType">
          <option value="">全部</option>
          <option value="电" <c:if test="${selectedEnergyType == '电'}">selected</c:if>>电</option>
          <option value="水" <c:if test="${selectedEnergyType == '水'}">selected</c:if>>水</option>
          <option value="蒸汽" <c:if test="${selectedEnergyType == '蒸汽'}">selected</c:if>>蒸汽</option>
          <option value="天然气" <c:if test="${selectedEnergyType == '天然气'}">selected</c:if>>天然气</option>
        </select>
        <span class="energy-filter-label">厂区</span>
        <select class="energy-filter-select" name="factoryId">
          <option value="">全部厂区</option>
          <c:forEach items="${factories}" var="factory">
            <option value="${factory.factoryId}" <c:if test="${selectedFactoryId == factory.factoryId}">selected</c:if>>
              ${factory.factoryName}
            </option>
          </c:forEach>
        </select>
        <button class="action-btn primary">查询</button>
        <a class="action-btn secondary" href="${ctx}/app?module=energy&view=peak_valley_list">峰谷统计</a>
        <a class="action-btn" href="${ctx}/app?module=energy&view=peak_valley_report">日成本报告</a>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">最新月份总能耗</div>
        <div class="energy-stat-value"><c:out value="${monthlyStats.totalConsumption}" default="--"/></div>
        <div class="energy-stat-sub">统计月份：<c:out value="${monthlyStats.reportMonth}" default="--"/></div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">最新月份成本</div>
        <div class="energy-stat-value">¥ <c:out value="${monthlyStats.totalCost}" default="--"/></div>
        <div class="energy-stat-sub">峰谷成本汇总</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">峰时能耗</div>
        <div class="energy-stat-value"><c:out value="${monthlyStats.peakConsumption}" default="--"/></div>
        <div class="energy-stat-sub">尖峰/高峰能耗</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">低谷能耗</div>
        <div class="energy-stat-value"><c:out value="${monthlyStats.valleyConsumption}" default="--"/></div>
        <div class="energy-stat-sub">低谷时段累计</div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">月度能耗报表</h3>
        <div class="action-buttons">
          <button class="action-btn secondary">生成月报</button>
          <button class="action-btn">导出 Excel</button>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>月份</th>
            <th>厂区</th>
            <th>能源类型</th>
            <th>峰时能耗</th>
            <th>低谷能耗</th>
            <th>峰谷差值</th>
            <th>总能耗</th>
            <th>成本 (元)</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${monthlyReports}" var="report">
            <tr>
              <td>${report.reportMonth}</td>
              <td>${report.factoryName}</td>
              <td>${report.energyType}</td>
              <td><c:out value="${report.peakConsumption}" default="-"/></td>
              <td><c:out value="${report.valleyConsumption}" default="-"/></td>
              <td><c:out value="${report.peakValleyGap}" default="-"/></td>
              <td><c:out value="${report.totalConsumption}" default="-"/></td>
              <td><c:out value="${report.totalCost}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty monthlyReports}">
            <tr>
              <td colspan="8" style="text-align:center;color:#94a3b8;">暂无月度能耗报表数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
