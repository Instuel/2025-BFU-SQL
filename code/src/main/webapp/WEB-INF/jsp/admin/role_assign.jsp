<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 角色分配</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty message}">
    <div class="success-message message">${message}</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="error-message message">${error}</div>
  </c:if>

  <div class="card" style="margin-top:16px;">
    <div style="margin-bottom:16px;color:#64748b;">为用户分配角色，系统将按角色权限开放对应模块。</div>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>用户ID</th>
        <th>账号</th>
        <th>姓名</th>
        <th>部门</th>
        <th>账号状态</th>
        <th>当前角色</th>
        <th>分配时间</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${roleAssignments}" var="item">
        <tr>
          <td>${item.userId}</td>
          <td>${item.loginAccount}</td>
          <td>${item.realName}</td>
          <td>${item.department}</td>
          <td>
            <c:choose>
              <c:when test="${item.accountStatus == 1}">启用</c:when>
              <c:otherwise>禁用</c:otherwise>
            </c:choose>
          </td>
          <td>${item.roleType}</td>
          <td>${item.assignedTime}</td>
          <td>
            <form action="${pageContext.request.contextPath}/admin" method="post" style="display:flex;gap:8px;align-items:center;">
              <input type="hidden" name="action" value="saveRoleAssignment">
              <input type="hidden" name="userId" value="${item.userId}">
              <select name="roleType" class="input" style="min-width:140px;">
                <c:forEach items="${roleOptions}" var="role">
                  <option value="${role}" <c:if test="${role == item.roleType}">selected</c:if>>${role}</option>
                </c:forEach>
              </select>
              <button class="btn btn-primary" type="submit">保存</button>
            </form>
          </td>
        </tr>
      </c:forEach>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
