<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 设备详情</h1>
      <p>展示单台计量设备运行信息、校准记录与关联能耗趋势。</p>
    </div>

    <div class="section" style="margin-bottom:24px;">
      <div class="section-header">
        <h3 class="section-title"><c:out value="${meter.meterCode}" default="--"/> 计量设备</h3>
        <div class="action-buttons">
          <a class="action-btn secondary" href="${ctx}/app?module=energy&view=meter_list">返回列表</a>
          <a class="action-btn primary" href="${ctx}/app?module=energy&view=energy_data_list">查看监测数据</a>
        </div>
      </div>
      <div class="status-tags" style="display:flex;gap:12px;flex-wrap:wrap;">
        <c:choose>
          <c:when test="${meter.runStatus == '正常'}">
            <span class="status-badge normal">运行正常</span>
          </c:when>
          <c:otherwise>
            <span class="status-badge warning">运行异常</span>
          </c:otherwise>
        </c:choose>
        <span class="status-badge active">校准周期 ${meter.calibCycleMonths} 个月</span>
        <span class="status-badge warning">厂区：<c:out value="${meter.factoryName}" default="-"/></span>
      </div>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">最新能耗值</div>
        <div class="energy-stat-value"><c:out value="${latestEnergyRecord.value}" default="--"/> <c:out value="${latestEnergyRecord.unit}" default=""/></div>
        <div class="energy-stat-sub"><c:out value="${latestEnergyRecord.collectTime}" default="暂无采集时间"/></div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">数据质量</div>
        <div class="energy-stat-value"><c:out value="${latestEnergyRecord.quality}" default="--"/></div>
        <div class="energy-stat-sub">最新监测质量</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">累计记录数</div>
        <div class="energy-stat-value">${fn:length(energyRecords)}</div>
        <div class="energy-stat-sub">最近采集数据条数</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">通讯协议</div>
        <div class="energy-stat-value"><c:out value="${meter.commProtocol}" default="--"/></div>
        <div class="energy-stat-sub">设备通讯方式</div>
      </div>
    </div>

    <div class="section" style="margin-bottom:24px;">
      <h3 class="section-title">设备信息</h3>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;">
        <div class="stat-card">
          <div class="stat-label">能源类型</div>
          <div class="stat-value" style="font-size:20px;"><c:out value="${meter.energyType}" default="--"/></div>
          <div class="stat-sub">规格型号：<c:out value="${meter.modelSpec}" default="--"/></div>
        </div>
        <div class="stat-card">
          <div class="stat-label">安装位置</div>
          <div class="stat-value" style="font-size:20px;"><c:out value="${meter.installLocation}" default="--"/></div>
          <div class="stat-sub">所属厂区：<c:out value="${meter.factoryName}" default="--"/></div>
        </div>
        <div class="stat-card">
          <div class="stat-label">通讯协议</div>
          <div class="stat-value" style="font-size:20px;"><c:out value="${meter.commProtocol}" default="--"/></div>
          <div class="stat-sub">运行状态：<c:out value="${meter.runStatus}" default="--"/></div>
        </div>
        <div class="stat-card">
          <div class="stat-label">生产厂家</div>
          <div class="stat-value" style="font-size:20px;"><c:out value="${meter.manufacturer}" default="--"/></div>
          <div class="stat-sub">校准周期：<c:out value="${meter.calibCycleMonths}" default="-"/> 个月</div>
        </div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">最近 24 小时能耗快照</h3>
        <button class="action-btn">导出记录</button>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>采集时间</th>
            <th>能耗值</th>
            <th>数据质量</th>
            <th>所属厂区</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${energyRecords}" var="record">
            <tr>
              <td><c:out value="${record.collectTime}" default="-"/></td>
              <td><c:out value="${record.value}" default="-"/> <c:out value="${record.unit}" default=""/></td>
              <td><span class="status-badge normal"><c:out value="${record.quality}" default="-"/></span></td>
              <td><c:out value="${record.factoryName}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty energyRecords}">
            <tr>
              <td colspan="4" style="text-align:center;color:#94a3b8;">暂无能耗监测记录</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
