<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;">
    <h2>系统管理 - 账号管理</h2>
    <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin?action=create">新增账号</a>
  </div>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-top:12px;">${message}</div>
  </c:if>

  <table class="table" style="margin-top:16px;width:100%;">
    <thead>
    <tr>
      <th>ID</th>
      <th>账号</th>
      <th>姓名</th>
      <th>部门</th>
      <th>电话</th>
      <th>状态</th>
      <th>创建时间</th>
      <th>最近登录</th>
      <th>操作</th>
    </tr>
    </thead>
    <tbody>
    <c:forEach items="${users}" var="u">
      <tr>
        <td>${u.userId}</td>
        <td>${u.loginAccount}</td>
        <td>${u.realName}</td>
        <td>${u.department}</td>
        <td>${u.contactPhone}</td>
        <td>
          <c:choose>
            <c:when test="${u.accountStatus == 1}">启用</c:when>
            <c:otherwise>禁用</c:otherwise>
          </c:choose>
        </td>
        <td>${u.createdTime}</td>
        <td>${u.lastLoginTime}</td>
        <td>
          <a class="btn btn-link" href="${pageContext.request.contextPath}/admin?action=detail&id=${u.userId}">编辑</a>
          <form action="${pageContext.request.contextPath}/admin" method="post" style="display:inline;">
            <input type="hidden" name="action" value="toggleStatus">
            <input type="hidden" name="userId" value="${u.userId}">
            <c:choose>
              <c:when test="${u.accountStatus == 1}">
                <input type="hidden" name="status" value="0">
                <button class="btn btn-warning" type="submit">禁用</button>
              </c:when>
              <c:otherwise>
                <input type="hidden" name="status" value="1">
                <button class="btn btn-success" type="submit">启用</button>
              </c:otherwise>
            </c:choose>
          </form>
          <form action="${pageContext.request.contextPath}/admin" method="post" style="display:inline;">
            <input type="hidden" name="action" value="resetPassword">
            <input type="hidden" name="userId" value="${u.userId}">
            <button class="btn btn-secondary" type="submit">重置密码</button>
          </form>
          <form action="${pageContext.request.contextPath}/admin" method="post" style="display:inline;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="userId" value="${u.userId}">
            <button class="btn btn-danger" type="submit">删除</button>
          </form>
        </td>
      </tr>
    </c:forEach>
    </tbody>
  </table>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
