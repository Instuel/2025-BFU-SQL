<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 峰谷统计</h1>
      <p>按电网峰谷时段自动统计每日能耗及成本，定位高耗能区域。</p>
    </div>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="peak_valley_list"/>
        <span class="energy-filter-label">能源类型</span>
        <select class="energy-filter-select" name="energyType">
          <option value="">全部</option>
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
        <a class="action-btn" href="${ctx}/app?module=energy&view=peak_valley_report">查看成本报告</a>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">最新统计总能耗</div>
        <div class="energy-stat-value"><c:out value="${reportStats.totalConsumption}" default="--"/></div>
        <div class="energy-stat-sub">最近统计日汇总</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">最新统计成本</div>
        <div class="energy-stat-value">¥ <c:out value="${reportStats.totalCost}" default="--"/></div>
        <div class="energy-stat-sub">最近统计日成本</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">低谷能耗</div>
        <div class="energy-stat-value"><c:out value="${reportStats.valleyConsumption}" default="--"/></div>
        <div class="energy-stat-sub">低谷时段累计</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">统计日期</div>
        <div class="energy-stat-value"><c:out value="${reportStats.reportDate}" default="--"/></div>
        <div class="energy-stat-sub">最近统计日期</div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">峰谷统计明细</h3>
        <div class="action-buttons">
          <button class="action-btn secondary">生成日报</button>
          <button class="action-btn">导出 Excel</button>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>统计日期</th>
            <th>厂区</th>
            <th>能源类型</th>
            <th>尖峰能耗</th>
            <th>高峰能耗</th>
            <th>平段能耗</th>
            <th>低谷能耗</th>
            <th>总能耗</th>
            <th>成本 (元)</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${peakValleySummaries}" var="summary">
            <tr>
              <td>${summary.statDate}</td>
              <td>${summary.factoryName}</td>
              <td>${summary.energyType}</td>
              <td><c:out value="${summary.peakConsumption}" default="-"/></td>
              <td><c:out value="${summary.highConsumption}" default="-"/></td>
              <td><c:out value="${summary.flatConsumption}" default="-"/></td>
              <td><c:out value="${summary.valleyConsumption}" default="-"/></td>
              <td><c:out value="${summary.totalConsumption}" default="-"/></td>
              <td><c:out value="${summary.totalCost}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty peakValleySummaries}">
            <tr>
              <td colspan="9" style="text-align:center;color:#94a3b8;">暂无峰谷统计数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
