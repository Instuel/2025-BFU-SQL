<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 账号详情</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty error}">
    <div class="error-message" style="margin-top:12px;">${error}</div>
  </c:if>

  <form action="${pageContext.request.contextPath}/admin" method="post" style="max-width:680px;">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="userId" value="${user.userId}">

    <div class="form-group">
      <label for="loginAccount">账号</label>
      <input type="text" id="loginAccount" name="loginAccount" required
             value="${user.loginAccount}" placeholder="请输入账号">
    </div>

    <div class="form-group">
      <label for="realName">姓名</label>
      <input type="text" id="realName" name="realName" required
             value="${user.realName}" placeholder="请输入姓名">
    </div>

    <div class="form-group">
      <label for="department">部门</label>
      <input type="text" id="department" name="department"
             value="${user.department}" placeholder="请输入部门">
    </div>

    <div class="form-group">
      <label for="contactPhone">电话</label>
      <input type="text" id="contactPhone" name="contactPhone"
             value="${user.contactPhone}" placeholder="请输入电话">
    </div>

    <div class="form-group">
      <label for="accountStatus">状态</label>
      <select id="accountStatus" name="accountStatus">
        <option value="1" <c:if test="${user.accountStatus == 1 || empty user}">selected</c:if>>启用</option>
        <option value="0" <c:if test="${user.accountStatus == 0}">selected</c:if>>禁用</option>
      </select>
    </div>

    <div class="form-group">
      <label for="newPassword">
        <c:choose>
          <c:when test="${empty user}">初始密码</c:when>
          <c:otherwise>更新密码（可选）</c:otherwise>
        </c:choose>
      </label>
      <input type="password" id="newPassword" name="newPassword"
             <c:if test="${empty user}">required</c:if>
             placeholder="请输入密码">
    </div>

    <div style="display:flex;gap:12px;">
      <button type="submit" class="btn btn-primary">保存</button>
      <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin?action=list">返回列表</a>
    </div>
  </form>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
