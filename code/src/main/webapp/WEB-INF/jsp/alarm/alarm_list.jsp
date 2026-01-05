<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>告警与运维管理</h2>
      <p style="color:#64748b;margin-top:6px;">聚合实时告警信息，跟踪派单与处理状态。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn primary" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <c:if test="${sessionScope.currentRoleType == 'OM' || sessionScope.currentRoleType == '运维人员'}">
      <a class="action-btn" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    </c:if>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
    <a class="action-btn" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="stats-grid">
    <div class="stat-card alarm">
      <div class="stat-label">告警总数</div>
      <div class="stat-value">${totalCount}</div>
      <div class="stat-change">全量告警汇总</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">待审核告警</div>
      <div class="stat-value">${verifyPendingCount}</div>
      <div class="stat-change">需确认真实性</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">高等级告警</div>
      <div class="stat-value">${highCount}</div>
      <div class="stat-change">需要 15 分钟内派单</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">处理中</div>
      <div class="stat-value">${processingCount}</div>
      <div class="stat-change">正在处理的告警</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">误报剔除</div>
      <div class="stat-value">${falseAlarmCount}</div>
      <div class="stat-change">已确认误报</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">超时派单</div>
      <div class="stat-value">${overdueCount}</div>
      <div class="stat-change">高等级超时告警</div>
    </div>
  </div>

  <div class="rule-form" style="margin-top:16px;">
    <div class="rule-form-header">
      <h2>告警筛选</h2>
    </div>
    <form method="get" action="${ctx}/alarm" class="rule-form-grid">
      <input type="hidden" name="action" value="list"/>
      <input type="hidden" name="module" value="alarm"/>
      <div class="form-group">
        <label>告警类型</label>
        <select name="alarmType">
          <option value="">全部</option>
          <option value="越限告警" <c:if test="${alarmType == '越限告警'}">selected</c:if>>越限告警</option>
          <option value="通讯故障" <c:if test="${alarmType == '通讯故障'}">selected</c:if>>通讯故障</option>
          <option value="设备故障" <c:if test="${alarmType == '设备故障'}">selected</c:if>>设备故障</option>
        </select>
      </div>
      <div class="form-group">
        <label>告警等级</label>
        <select name="alarmLevel">
          <option value="">全部</option>
          <option value="高" <c:if test="${alarmLevel == '高'}">selected</c:if>>高</option>
          <option value="中" <c:if test="${alarmLevel == '中'}">selected</c:if>>中</option>
          <option value="低" <c:if test="${alarmLevel == '低'}">selected</c:if>>低</option>
        </select>
      </div>
      <div class="form-group">
        <label>处理状态</label>
        <select name="processStatus">
          <option value="">全部</option>
          <option value="未处理" <c:if test="${processStatus == '未处理'}">selected</c:if>>未处理</option>
          <option value="处理中" <c:if test="${processStatus == '处理中'}">selected</c:if>>处理中</option>
          <option value="已结案" <c:if test="${processStatus == '已结案'}">selected</c:if>>已结案</option>
        </select>
      </div>
      <div class="form-group">
        <label>真实性</label>
        <select name="verifyStatus">
          <option value="">全部</option>
          <option value="待审核" <c:if test="${verifyStatus == '待审核'}">selected</c:if>>待审核</option>
          <option value="有效" <c:if test="${verifyStatus == '有效'}">selected</c:if>>有效</option>
          <option value="误报" <c:if test="${verifyStatus == '误报'}">selected</c:if>>误报</option>
        </select>
      </div>
      <div class="form-group" style="display:flex;align-items:flex-end;gap:12px;">
        <button class="btn btn-primary" type="submit">应用筛选</button>
        <a class="btn btn-secondary" href="${ctx}/alarm?action=list&module=alarm">重置</a>
      </div>
    </form>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>告警编号</th>
        <th>告警类型</th>
        <th>等级</th>
        <th>告警内容</th>
        <th>发生时间</th>
        <th>处理状态</th>
        <th>真实性</th>
        <th>关联设备</th>
        <th>派单时效</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${alarms}" var="a">
        <tr>
          <td>${a.alarmId}</td>
          <td>${a.alarmType}</td>
          <td>
            <span class="alarm-level <c:out value='${a.alarmLevel == "高" ? "high" : (a.alarmLevel == "中" ? "medium" : "low")}'/>">
              ${a.alarmLevel}
            </span>
          </td>
          <td>${a.content}</td>
          <td>${a.occurTime}</td>
          <td>
            <c:choose>
              <c:when test="${a.processStatus == '未处理'}"><span class="alarm-status-tag pending">未处理</span></c:when>
              <c:when test="${a.processStatus == '处理中'}"><span class="alarm-status-tag processing">处理中</span></c:when>
              <c:otherwise><span class="alarm-status-tag closed">已结案</span></c:otherwise>
            </c:choose>
          </td>
          <td>
            <c:choose>
              <c:when test="${a.verifyStatus == '有效'}"><span class="alarm-verify-tag valid">有效</span></c:when>
              <c:when test="${a.verifyStatus == '误报'}"><span class="alarm-verify-tag invalid">误报</span></c:when>
              <c:otherwise><span class="alarm-verify-tag pending">待审核</span></c:otherwise>
            </c:choose>
          </td>
          <td>
            <div>${a.deviceName}</div>
            <div style="font-size:12px;color:#94a3b8;">${a.deviceType}</div>
          </td>
          <td>
            <c:choose>
              <c:when test="${a.dispatchOverdue}">
                <span class="alarm-sla-tag overdue">已超时</span>
              </c:when>
              <c:when test="${a.workOrderId != null}">
                <span class="alarm-sla-tag">已派单</span>
              </c:when>
              <c:otherwise>
                <span class="alarm-sla-tag">待派单</span>
              </c:otherwise>
            </c:choose>
          </td>
          <td>
            <a class="btn btn-link" href="${ctx}/alarm?action=detail&id=${a.alarmId}&module=alarm">查看</a>
            <c:if test="${a.workOrderId != null && currentRoleType != 'OM'}">
              <a class="btn btn-link" href="${ctx}/alarm?action=workorderDetail&id=${a.workOrderId}&module=alarm">工单</a>
            </c:if>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty alarms}">
        <tr>
          <td colspan="10" style="text-align:center;color:#94a3b8;">暂无告警数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
