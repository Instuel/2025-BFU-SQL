<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 计量设备台账</h1>
      <p>覆盖水/蒸汽/天然气计量设备的运行状态、校准周期与厂区分布。</p>
    </div>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="meter_list"/>
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
        <span class="energy-filter-label">状态</span>
        <select class="energy-filter-select" name="runStatus">
          <option value="">全部</option>
          <option value="正常" <c:if test="${selectedRunStatus == '正常'}">selected</c:if>>正常</option>
          <option value="故障" <c:if test="${selectedRunStatus == '故障'}">selected</c:if>>故障</option>
        </select>
        <input class="energy-date-input" type="text" name="keyword" value="${keyword}" placeholder="设备编号/位置搜索"/>
        <button class="action-btn primary">查询</button>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">设备总数</div>
        <div class="energy-stat-value">${meterStats.totalCount}</div>
        <div class="energy-stat-sub">覆盖 ${meterStats.factoryCount} 个厂区</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">正常运行</div>
        <div class="energy-stat-value">${meterStats.normalCount}</div>
        <div class="energy-stat-sub">状态为正常的设备数量</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">故障设备</div>
        <div class="energy-stat-value">${meterStats.abnormalCount}</div>
        <div class="energy-stat-sub">运行状态异常</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">厂区覆盖</div>
        <div class="energy-stat-value">${meterStats.factoryCount}</div>
        <div class="energy-stat-sub">关联厂区数量</div>
      </div>
    </div>

    <div class="section" style="margin-bottom:24px;">
      <div class="section-header">
        <h3 class="section-title">综合能耗快捷入口</h3>
        <div class="action-buttons">
          <a class="action-btn primary" href="${ctx}/app?module=energy&view=energy_data_list">监测数据</a>
          <a class="action-btn secondary" href="${ctx}/app?module=energy&view=peak_valley_list">峰谷统计</a>
          <a class="action-btn" href="${ctx}/app?module=energy&view=peak_valley_report">能耗报告</a>
        </div>
      </div>
      <p style="color:#64748b;margin:0;">提示：设备信息用于关联能耗监测数据与峰谷统计报表。</p>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">计量设备清单</h3>
        <button class="action-btn primary">新增设备</button>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>设备编号</th>
            <th>能源类型</th>
            <th>安装位置</th>
            <th>管径规格</th>
            <th>通讯协议</th>
            <th>运行状态</th>
            <th>校准周期</th>
            <th>操作</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${meters}" var="meter">
            <tr>
              <td>${meter.meterCode}</td>
              <td>${meter.energyType}</td>
              <td><c:out value="${meter.installLocation}" default="-"/></td>
              <td><c:out value="${meter.modelSpec}" default="-"/></td>
              <td><c:out value="${meter.commProtocol}" default="-"/></td>
              <td>
                <c:choose>
                  <c:when test="${meter.runStatus == '正常'}">
                    <span class="status-badge normal">正常</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge warning">故障</span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${meter.calibCycleMonths}" default="-"/> 个月</td>
              <td>
                <a class="action-btn secondary" href="${ctx}/app?module=energy&view=meter_detail&id=${meter.meterId}">详情</a>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty meters}">
            <tr>
              <td colspan="8" style="text-align:center;color:#94a3b8;">暂无计量设备数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
