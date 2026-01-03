<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>设备台账管理</h2>
      <p style="color:#64748b;margin-top:6px;">维护设备全生命周期信息与维修记录。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn primary" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <div class="rule-form" style="margin-top:16px;">
    <div class="rule-form-header">
      <h2>台账筛选</h2>
    </div>
    <form method="get" action="${ctx}/alarm" class="rule-form-grid">
      <input type="hidden" name="action" value="ledgerList"/>
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
        <label>报废状态</label>
        <select name="scrapStatus">
          <option value="">全部</option>
          <option value="正常使用" <c:if test="${scrapStatus == '正常使用'}">selected</c:if>>正常使用</option>
          <option value="已报废" <c:if test="${scrapStatus == '已报废'}">selected</c:if>>已报废</option>
        </select>
      </div>
      <div class="form-group" style="display:flex;align-items:flex-end;gap:12px;">
        <button class="btn btn-primary" type="submit">应用筛选</button>
        <a class="btn btn-secondary" href="${ctx}/alarm?action=ledgerList&module=alarm">重置</a>
      </div>
    </form>
  </div>

  <div class="table-container" style="margin-top:16px;">
    <table class="table">
      <thead>
      <tr>
        <th>台账编号</th>
        <th>设备名称</th>
        <th>设备类型</th>
        <th>型号规格</th>
        <th>安装时间</th>
        <th>质保状态</th>
        <th>校准记录</th>
        <th>报废状态</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${ledgers}" var="l">
        <tr>
          <td>${l.ledgerId}</td>
          <td>${l.deviceName}</td>
          <td>${l.deviceType}</td>
          <td>${l.modelSpec}</td>
          <td>${l.installTime}</td>
          <td>
            <c:choose>
              <c:when test="${l.warrantyStatus == '即将到期'}">
                <span class="warranty-tag warning">即将到期 (${l.warrantyDaysLeft} 天)</span>
              </c:when>
              <c:when test="${l.warrantyStatus == '已过期'}">
                <span class="warranty-tag expired">已过期</span>
              </c:when>
              <c:otherwise>
                <span class="warranty-tag">${l.warrantyStatus}</span>
              </c:otherwise>
            </c:choose>
          </td>
          <td>
            <div>${l.calibrationTime}</div>
            <div style="font-size:12px;color:#94a3b8;">${l.calibrationPerson}</div>
          </td>
          <td>${l.scrapStatus}</td>
          <td>
            <a class="btn btn-link" href="${ctx}/alarm?action=ledgerDetail&id=${l.ledgerId}&module=alarm">查看</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty ledgers}">
        <tr>
          <td colspan="9" style="text-align:center;color:#94a3b8;">暂无台账数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
