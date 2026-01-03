<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>预防性维护计划</h2>
      <p style="color:#64748b;margin-top:6px;">覆盖设备台账的校准与巡检计划。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
    <a class="action-btn primary" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="rule-form" style="margin-top:16px;">
    <div class="rule-form-header">
      <h2>计划筛选</h2>
    </div>
    <form method="get" action="${ctx}/alarm" class="rule-form-grid">
      <input type="hidden" name="action" value="maintenancePlanList"/>
      <input type="hidden" name="module" value="alarm"/>
      <div class="form-group">
        <label>设备类型</label>
        <select name="deviceType">
          <option value="">全部</option>
          <option value="变压器" <c:if test="${deviceType == '变压器'}">selected</c:if>>变压器</option>
          <option value="水表" <c:if test="${deviceType == '水表'}">selected</c:if>>水表</option>
          <option value="逆变器" <c:if test="${deviceType == '逆变器'}">selected</c:if>>逆变器</option>
        </select>
      </div>
      <div class="form-group">
        <label>计划状态</label>
        <select name="status">
          <option value="">全部</option>
          <option value="待执行" <c:if test="${status == '待执行'}">selected</c:if>>待执行</option>
          <option value="执行中" <c:if test="${status == '执行中'}">selected</c:if>>执行中</option>
          <option value="已完成" <c:if test="${status == '已完成'}">selected</c:if>>已完成</option>
        </select>
      </div>
      <div class="form-group" style="display:flex;align-items:flex-end;gap:12px;">
        <button class="btn btn-primary" type="submit">应用筛选</button>
        <a class="btn btn-secondary" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">重置</a>
      </div>
    </form>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>计划编号</th>
        <th>设备</th>
        <th>计划类型</th>
        <th>计划内容</th>
        <th>计划日期</th>
        <th>负责人</th>
        <th>状态</th>
        <th>创建时间</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${plans}" var="p">
        <tr>
          <td>${p.planId}</td>
          <td>
            <div>${p.deviceName}</div>
            <div style="font-size:12px;color:#94a3b8;">${p.deviceType}</div>
          </td>
          <td>${p.planType}</td>
          <td>${p.planContent}</td>
          <td>${p.planDate}</td>
          <td>${p.ownerName}</td>
          <td>${p.status}</td>
          <td>${p.createdAt}</td>
          <td>
            <a class="btn btn-link" href="${ctx}/alarm?action=ledgerDetail&id=${p.ledgerId}&module=alarm">设备台账</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty plans}">
        <tr>
          <td colspan="9" style="text-align:center;color:#94a3b8;">暂无维护计划数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
