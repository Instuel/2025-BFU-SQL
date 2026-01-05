<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 峰谷时段配置</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty message}">
    <div class="success-message message">${message}</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="error-message message">${error}</div>
  </c:if>

  <div class="content-grid" style="margin-top:16px;">
    <div class="card">
      <h3 style="margin-bottom:16px;">新增峰谷时段</h3>
      <form action="${pageContext.request.contextPath}/admin" method="post" class="form">
        <input type="hidden" name="action" value="savePeakValley">
        <div class="form-group">
          <label class="form-label">时段类型</label>
          <select class="input" name="timeType">
            <option value="尖">尖</option>
            <option value="峰">峰</option>
            <option value="平">平</option>
            <option value="谷">谷</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">开始时间</label>
          <input class="input" type="time" name="startTime" required>
        </div>
        <div class="form-group">
          <label class="form-label">结束时间</label>
          <input class="input" type="time" name="endTime" required>
        </div>
        <div class="form-group">
          <label class="form-label">电价系数</label>
          <input class="input" type="number" step="0.0001" name="priceRate" placeholder="如：1.2000">
        </div>
        <button class="btn btn-primary" type="submit">保存配置</button>
      </form>
    </div>

    <div class="card">
      <h3 style="margin-bottom:16px;">当前配置</h3>
      <table class="table" style="width:100%;">
        <thead>
        <tr>
          <th>ID</th>
          <th>类型</th>
          <th>开始</th>
          <th>结束</th>
          <th>电价系数</th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${peakValleyConfigs}" var="cfg">
          <tr>
            <td>${cfg.configId}</td>
            <td>${cfg.timeType}</td>
            <td>${cfg.startTime}</td>
            <td>${cfg.endTime}</td>
            <td>${cfg.priceRate}</td>
          </tr>
        </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
