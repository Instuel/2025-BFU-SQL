<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 能耗数据质量审核</h1>
      <p>聚焦数据质量为“中/差”的能耗记录，完成复核并记录异常原因。</p>
    </div>

    <a class="back-btn" href="${ctx}/app?module=energy&view=meter_list" style="display:inline-block;margin-bottom:16px;color:#0ea5e9;text-decoration:none;font-size:14px;">← 返回综合能耗首页</a>

    <c:if test="${param.success == 'review'}">
      <div class="message success-message">复核记录已更新。</div>
    </c:if>
    <c:if test="${param.error == 'missing'}">
      <div class="message warning-message">请完善复核信息后再提交。</div>
    </c:if>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="data_review"/>
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
        <span class="energy-filter-label">质量等级</span>
        <select class="energy-filter-select" name="quality">
          <option value="">全部</option>
          <option value="中" <c:if test="${selectedQuality == '中'}">selected</c:if>>中</option>
          <option value="差" <c:if test="${selectedQuality == '差'}">selected</c:if>>差</option>
        </select>
        <button class="action-btn primary">筛选</button>
        <a class="action-btn" href="${ctx}/app?module=energy&view=energy_data_list">返回监测数据</a>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">待审核记录</div>
        <div class="energy-stat-value"><c:out value="${reviewStats.pendingCount}" default="0"/></div>
        <div class="energy-stat-sub">数据质量中/差待复核</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">已完成复核</div>
        <div class="energy-stat-value"><c:out value="${reviewStats.reviewedCount}" default="0"/></div>
        <div class="energy-stat-sub">已登记复核意见</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">审核记录总数</div>
        <div class="energy-stat-value"><c:out value="${reviewStats.totalCount}" default="0"/></div>
        <div class="energy-stat-sub">当前筛选范围内</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">当前筛选</div>
        <div class="energy-stat-value"><c:out value="${selectedFactoryId}" default="全部"/></div>
        <div class="energy-stat-sub">厂区筛选条件</div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">能耗数据复核清单</h3>
        <div class="action-buttons">
          <a class="action-btn secondary" href="${ctx}/exportCSV?type=data_review&factoryId=${selectedFactoryId}&energyType=${selectedEnergyType}&quality=${selectedQuality}">导出CSV</a>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>数据编号</th>
            <th>设备编号</th>
            <th>能源类型</th>
            <th>采集时间</th>
            <th>能耗值</th>
            <th>质量等级</th>
            <th>厂区</th>
            <th>复核状态</th>
            <th>复核操作</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${reviewRecords}" var="record">
            <tr>
              <td>${record.dataId}</td>
              <td>${record.meterCode}</td>
              <td>${record.energyType}</td>
              <td><c:out value="${record.collectTime}" default="-"/></td>
              <td><c:out value="${record.value}" default="-"/> <c:out value="${record.unit}" default=""/></td>
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
              <td>
                <c:choose>
                  <c:when test="${empty record.reviewStatus}">
                    <span class="status-badge warning">待复核</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge normal">${record.reviewStatus}</span>
                  </c:otherwise>
                </c:choose>
                <div style="font-size:12px;color:#94a3b8;margin-top:4px;">
                  <c:out value="${record.reviewTime}" default=""/>
                </div>
              </td>
              <td>
                <form class="inline-form" method="post" action="${ctx}/app">
                  <input type="hidden" name="module" value="energy"/>
                  <input type="hidden" name="action" value="review_data"/>
                  <input type="hidden" name="dataId" value="${record.dataId}"/>
                  <select class="energy-filter-select compact" name="reviewStatus">
                    <option value="已复核">已复核</option>
                    <option value="异常确认">异常确认</option>
                  </select>
                  <input class="energy-date-input compact" type="text" name="reviewRemark"
                         value="${record.reviewRemark}" placeholder="复核说明"/>
                  <button class="action-btn primary">提交</button>
                </form>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty reviewRecords}">
            <tr>
              <td colspan="9" style="text-align:center;color:#94a3b8;">暂无待审核能耗数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
