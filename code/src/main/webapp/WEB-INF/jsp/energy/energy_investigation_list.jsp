<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 高耗能区域排查</h1>
      <p>基于峰谷统计与平均值对比，锁定高耗能区域并发起排查任务。</p>
    </div>

    <c:if test="${param.success == 'investigation'}">
      <div class="message success-message">高耗能排查任务已发起。</div>
    </c:if>
    <c:if test="${param.error == 'missing'}">
      <div class="message warning-message">请填写排查问题描述后提交。</div>
    </c:if>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">排查任务总数</div>
        <div class="energy-stat-value"><c:out value="${investigationStats.totalCount}" default="0"/></div>
        <div class="energy-stat-sub">累计发起排查</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">执行中排查</div>
        <div class="energy-stat-value"><c:out value="${investigationStats.activeCount}" default="0"/></div>
        <div class="energy-stat-sub">待确认整改</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">已完成排查</div>
        <div class="energy-stat-value"><c:out value="${investigationStats.completedCount}" default="0"/></div>
        <div class="energy-stat-sub">已归档</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">当前负责人</div>
        <div class="energy-stat-value"><c:out value="${sessionScope.currentUser.realName}" default="能源管理员"/></div>
        <div class="energy-stat-sub">排查牵头人</div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">高耗能区域预警</h3>
        <div class="action-buttons">
          <button class="action-btn secondary">刷新预警</button>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>统计日期</th>
            <th>厂区</th>
            <th>能源类型</th>
            <th>能耗总量</th>
            <th>平均值</th>
            <th>超出比例</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${highConsumptionAreas}" var="area">
            <tr>
              <td>${area.statDate}</td>
              <td>${area.factoryName}</td>
              <td>${area.energyType}</td>
              <td><c:out value="${area.totalConsumption}" default="-"/></td>
              <td><c:out value="${area.avgConsumption}" default="-"/></td>
              <td><c:out value="${area.overRate}" default="-"/>%</td>
            </tr>
          </c:forEach>
          <c:if test="${empty highConsumptionAreas}">
            <tr>
              <td colspan="6" style="text-align:center;color:#94a3b8;">暂无高耗能预警区域</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>

    <div class="energy-filter-section">
      <div class="section-header">
        <h3 class="section-title">发起排查任务</h3>
      </div>
      <form class="energy-form-grid" method="post" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="action" value="create_investigation"/>
        <div class="energy-form-item">
          <label>厂区</label>
          <select class="energy-filter-select" name="factoryId" required>
            <c:forEach items="${factories}" var="factory">
              <option value="${factory.factoryId}">${factory.factoryName}</option>
            </c:forEach>
          </select>
        </div>
        <div class="energy-form-item">
          <label>能源类型</label>
          <select class="energy-filter-select" name="energyType" required>
            <option value="电">电</option>
            <option value="水">水</option>
            <option value="蒸汽">蒸汽</option>
            <option value="天然气">天然气</option>
          </select>
        </div>
        <div class="energy-form-item">
          <label>排查等级</label>
          <select class="energy-filter-select" name="level">
            <option value="重点排查">重点排查</option>
            <option value="持续观察">持续观察</option>
          </select>
        </div>
        <div class="energy-form-item">
          <label>排查描述</label>
          <input class="energy-date-input" type="text" name="issueDesc" placeholder="如：天然气日能耗超平均值 30%" required/>
        </div>
        <div class="energy-form-actions">
          <button class="action-btn primary">提交排查</button>
        </div>
      </form>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">排查任务清单</h3>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>任务描述</th>
            <th>厂区</th>
            <th>能源类型</th>
            <th>等级</th>
            <th>状态</th>
            <th>负责人</th>
            <th>发起时间</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${investigations}" var="item">
            <tr>
              <td><c:out value="${item.issueDesc}" default="-"/></td>
              <td><c:out value="${item.factoryName}" default="-"/></td>
              <td><c:out value="${item.energyType}" default="-"/></td>
              <td><c:out value="${item.level}" default="-"/></td>
              <td>
                <c:choose>
                  <c:when test="${item.status == '已完成'}">
                    <span class="status-badge normal">已完成</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge warning">进行中</span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${item.owner}" default="-"/></td>
              <td><c:out value="${item.createTime}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty investigations}">
            <tr>
              <td colspan="7" style="text-align:center;color:#94a3b8;">暂无排查任务</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
