<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="report-container">
    <div class="report-header">
      <h1>综合能耗管理 / 日能耗成本报告</h1>
      <p>自动汇总峰谷能耗、成本与节能建议，支持按厂区与能源类型对比。</p>
    </div>

    <a class="back-btn" href="${ctx}/app?module=energy&view=peak_valley_list">← 返回峰谷统计</a>

    <div class="filter-section">
      <div class="filter-bar">
        <span class="filter-label">统计周期</span>
        <select class="filter-select">
          <option>日</option>
          <option>周</option>
          <option>月</option>
        </select>
        <span class="filter-label">能源类型</span>
        <select class="filter-select">
          <option>电</option>
          <option>水</option>
          <option>蒸汽</option>
          <option>天然气</option>
        </select>
        <span class="filter-label">厂区</span>
        <select class="filter-select">
          <option>全部厂区</option>
          <option>真旺厂</option>
          <option>豆果厂</option>
          <option>A3 厂区</option>
        </select>
        <input class="date-input" type="date"/>
        <button class="action-btn primary">生成报告</button>
        <button class="action-btn">导出 PDF</button>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card cost">
        <div class="stat-label">当日能耗成本</div>
        <div class="stat-value">¥ <c:out value="${reportStats.totalCost}" default="--"/></div>
        <div class="stat-sub">最近统计日汇总</div>
      </div>
      <div class="stat-card savings">
        <div class="stat-label">低谷能耗</div>
        <div class="stat-value"><c:out value="${reportStats.valleyConsumption}" default="--"/></div>
        <div class="stat-sub">低谷时段累计</div>
      </div>
      <div class="stat-card efficiency">
        <div class="stat-label">总能耗</div>
        <div class="stat-value"><c:out value="${reportStats.totalConsumption}" default="--"/></div>
        <div class="stat-sub">统计周期总量</div>
      </div>
    </div>

    <div class="content-grid">
      <div>
        <div class="report-section">
          <div class="section-title">厂区能耗成本对比</div>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>厂区</th>
                <th>能源类型</th>
                <th>统计日期</th>
                <th>总能耗</th>
                <th>总成本 (元)</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach items="${reportItems}" var="item">
                <tr>
                  <td>${item.factoryName}</td>
                  <td>${item.energyType}</td>
                  <td>${item.statDate}</td>
                  <td><c:out value="${item.totalConsumption}" default="-"/></td>
                  <td><c:out value="${item.totalCost}" default="-"/></td>
                </tr>
              </c:forEach>
              <c:if test="${empty reportItems}">
                <tr>
                  <td colspan="5" style="text-align:center;color:#94a3b8;">暂无峰谷成本数据</td>
                </tr>
              </c:if>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div>
        <div class="report-section">
          <div class="section-title">报告摘要</div>
          <div class="report-list">
            <c:forEach items="${reportItems}" var="item" varStatus="status">
              <c:if test="${status.index < 3}">
                <div class="report-item">
                  <div class="report-title">峰谷统计摘要</div>
                  <div class="report-meta">${item.factoryName} · ${item.statDate}</div>
                  <div class="report-summary">总能耗 ${item.totalConsumption}，成本 ${item.totalCost} 元。</div>
                  <span class="report-status completed">已生成</span>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${empty reportItems}">
              <div class="report-item">
                <div class="report-title">暂无报告摘要</div>
                <div class="report-meta">请先生成峰谷统计数据</div>
                <div class="report-summary">当前没有可用的数据摘要。</div>
                <span class="report-status pending">待生成</span>
              </div>
            </c:if>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
