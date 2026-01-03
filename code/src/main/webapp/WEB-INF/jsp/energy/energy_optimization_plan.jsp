<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 能耗优化方案</h1>
      <p>制定峰谷负荷优化策略，跟踪方案执行后的能耗下降效果。</p>
    </div>

    <c:if test="${param.success == 'plan'}">
      <div class="message success-message">节能方案已新增并进入执行中。</div>
    </c:if>
    <c:if test="${param.error == 'missing'}">
      <div class="message warning-message">请补全方案信息后提交。</div>
    </c:if>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">执行中方案</div>
        <div class="energy-stat-value"><c:out value="${planStats.activeCount}" default="0"/></div>
        <div class="energy-stat-sub">正在跟踪成效</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">已完成方案</div>
        <div class="energy-stat-value"><c:out value="${planStats.completedCount}" default="0"/></div>
        <div class="energy-stat-sub">已归档</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">方案总量</div>
        <div class="energy-stat-value"><c:out value="${planStats.totalCount}" default="0"/></div>
        <div class="energy-stat-sub">覆盖各厂区</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">负责人</div>
        <div class="energy-stat-value"><c:out value="${sessionScope.currentUser.realName}" default="能源管理员"/></div>
        <div class="energy-stat-sub">方案牵头人</div>
      </div>
    </div>

    <div class="energy-filter-section">
      <div class="section-header">
        <h3 class="section-title">新增优化方案</h3>
      </div>
      <form class="energy-form-grid" method="post" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="action" value="create_plan"/>
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
          <label>方案标题</label>
          <input class="energy-date-input" type="text" name="planTitle" placeholder="如：峰谷用电时段调整" required/>
        </div>
        <div class="energy-form-item">
          <label>执行动作</label>
          <input class="energy-date-input" type="text" name="planAction" placeholder="如：将高负荷生产移至 22:00 后" required/>
        </div>
        <div class="energy-form-item">
          <label>启动日期</label>
          <input class="energy-date-input" type="date" name="startDate" required/>
        </div>
        <div class="energy-form-item">
          <label>目标降耗 (%)</label>
          <input class="energy-date-input" type="number" step="0.1" name="targetReduction" placeholder="6.5"/>
        </div>
        <div class="energy-form-actions">
          <button class="action-btn primary">提交方案</button>
        </div>
      </form>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">方案执行清单</h3>
        <div class="action-buttons">
          <button class="action-btn secondary">导出清单</button>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>方案名称</th>
            <th>厂区</th>
            <th>能源类型</th>
            <th>执行动作</th>
            <th>目标降耗</th>
            <th>实际降耗</th>
            <th>状态</th>
            <th>启动日期</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${plans}" var="plan">
            <tr>
              <td>${plan.planTitle}</td>
              <td><c:out value="${plan.factoryName}" default="-"/></td>
              <td>${plan.energyType}</td>
              <td><c:out value="${plan.planAction}" default="-"/></td>
              <td><c:out value="${plan.targetReduction}" default="0"/>%</td>
              <td><c:out value="${plan.actualReduction}" default="0"/>%</td>
              <td>
                <c:choose>
                  <c:when test="${plan.status == '已完成'}">
                    <span class="status-badge normal">已完成</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge warning">执行中</span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${plan.startDate}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty plans}">
            <tr>
              <td colspan="8" style="text-align:center;color:#94a3b8;">暂无节能优化方案</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
