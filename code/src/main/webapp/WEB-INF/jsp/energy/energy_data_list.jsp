<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 能耗监测数据</h1>
      <p>分钟级采集数据，支持数据质量核查与厂区对比分析。</p>
    </div>

    <a class="back-btn" href="${ctx}/app?module=energy&view=meter_list" style="display:inline-block;margin-bottom:16px;color:#0ea5e9;text-decoration:none;font-size:14px;">← 返回综合能耗首页</a>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="energy_data_list"/>
        <span class="energy-filter-label">厂区</span>
        <select class="energy-filter-select" name="factoryId">
          <option value="">全部厂区</option>
          <c:forEach items="${factories}" var="factory">
            <option value="${factory.factoryId}" <c:if test="${selectedFactoryId == factory.factoryId}">selected</c:if>>
              ${factory.factoryName}
            </option>
          </c:forEach>
        </select>
        <button class="action-btn primary">筛选</button>
        <a class="action-btn secondary" href="${ctx}/app?module=energy&view=data_review">数据质量审核</a>
        <a class="action-btn" href="${ctx}/app?module=energy&view=meter_list">返回设备台账</a>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">监测记录数</div>
        <div class="energy-stat-value">${fn:length(energyRecords)}</div>
        <div class="energy-stat-sub">当前筛选范围内记录</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">最新采集时间</div>
        <div class="energy-stat-value"><c:out value="${latestEnergyRecord.collectTime}" default="--"/></div>
        <div class="energy-stat-sub">按最新记录更新</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">最新数据质量</div>
        <div class="energy-stat-value"><c:out value="${latestEnergyRecord.quality}" default="--"/></div>
        <div class="energy-stat-sub">监测质量等级</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">厂区筛选</div>
        <div class="energy-stat-value"><c:out value="${selectedFactoryId}" default="全部"/></div>
        <div class="energy-stat-sub">当前筛选厂区</div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">能耗监测记录</h3>
        <div class="action-buttons">
          <button class="action-btn secondary">批量标记待核实</button>
          <a class="action-btn" href="${ctx}/exportCSV?type=energy_data&factoryId=${selectedFactoryId}">导出CSV</a>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>数据编号</th>
            <th>设备编号</th>
            <th>采集时间</th>
            <th>能耗值</th>
            <th>单位</th>
            <th>数据质量</th>
            <th>厂区</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${energyRecords}" var="record">
            <tr>
              <td>${record.dataId}</td>
              <td>${record.meterCode}</td>
              <td><c:out value="${record.collectTime}" default="-"/></td>
              <td><c:out value="${record.value}" default="-"/></td>
              <td><c:out value="${record.unit}" default="-"/></td>
              <td>
                <c:choose>
                  <c:when test="${record.quality == '差'}">
                    <span class="status-badge error">差</span>
                  </c:when>
                  <c:when test="${record.quality == '中'}">
                    <span class="status-badge warning">中</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge normal"><c:out value="${record.quality}" default="-"/></span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${record.factoryName}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty energyRecords}">
            <tr>
              <td colspan="7" style="text-align:center;color:#94a3b8;">暂无能耗监测数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
