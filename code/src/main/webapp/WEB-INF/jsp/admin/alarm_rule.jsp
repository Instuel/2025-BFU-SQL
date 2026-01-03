<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 告警规则配置</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty message}">
    <div class="success-message message">${message}</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="error-message message">${error}</div>
  </c:if>

  <div class="content-grid" style="margin-top:16px;">
    <div class="card">
      <h3 style="margin-bottom:16px;">新增/更新规则</h3>
      <form action="${pageContext.request.contextPath}/admin" method="post" class="form">
        <input type="hidden" name="action" value="saveAlarmRule">
        <div class="form-group">
          <label class="form-label">告警类型</label>
          <input class="input" type="text" name="alarmType" placeholder="如：变压器温度告警">
        </div>
        <div class="form-group">
          <label class="form-label">告警等级</label>
          <select class="input" name="alarmLevel">
            <option value="高">高</option>
            <option value="中">中</option>
            <option value="低">低</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">触发阈值</label>
          <div style="display:flex;gap:8px;">
            <input class="input" type="number" step="0.01" name="thresholdValue" placeholder="如：85">
            <input class="input" type="text" name="thresholdUnit" placeholder="℃ / kWh / %">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">通知渠道</label>
          <input class="input" type="text" name="notifyChannel" placeholder="短信 / APP 推送 / 邮件">
        </div>
        <div class="form-group">
          <label class="form-label">是否启用</label>
          <select class="input" name="enabled">
            <option value="1">启用</option>
            <option value="0">停用</option>
          </select>
        </div>
        <button class="btn btn-primary" type="submit">保存规则</button>
      </form>
    </div>

    <div class="card">
      <h3 style="margin-bottom:16px;">规则清单</h3>
      <table class="table" style="width:100%;">
        <thead>
        <tr>
          <th>ID</th>
          <th>告警类型</th>
          <th>等级</th>
          <th>阈值</th>
          <th>通知渠道</th>
          <th>状态</th>
          <th>更新时间</th>
          <th>操作</th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${alarmRules}" var="rule">
          <tr>
            <td>${rule.ruleId}</td>
            <td>${rule.alarmType}</td>
            <td>${rule.alarmLevel}</td>
            <td>
              <c:choose>
                <c:when test="${rule.thresholdValue != null}">${rule.thresholdValue} ${rule.thresholdUnit}</c:when>
                <c:otherwise>-</c:otherwise>
              </c:choose>
            </td>
            <td>${rule.notifyChannel}</td>
            <td>
              <c:choose>
                <c:when test="${rule.enabled == 1}"><span class="status-badge active">启用</span></c:when>
                <c:otherwise><span class="status-badge inactive">停用</span></c:otherwise>
              </c:choose>
            </td>
            <td>${rule.updatedTime}</td>
            <td>
              <form action="${pageContext.request.contextPath}/admin" method="post" style="display:inline;">
                <input type="hidden" name="action" value="toggleAlarmRule">
                <input type="hidden" name="ruleId" value="${rule.ruleId}">
                <c:choose>
                  <c:when test="${rule.enabled == 1}">
                    <input type="hidden" name="enabled" value="0">
                    <button class="btn btn-warning" type="submit">停用</button>
                  </c:when>
                  <c:otherwise>
                    <input type="hidden" name="enabled" value="1">
                    <button class="btn btn-success" type="submit">启用</button>
                  </c:otherwise>
                </c:choose>
              </form>
            </td>
          </tr>
        </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
