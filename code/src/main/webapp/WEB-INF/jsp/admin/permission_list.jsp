<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 权限清单</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <div class="card" style="margin-top:16px;">
    <div style="margin-bottom:16px;color:#64748b;">展示系统权限与授权角色，便于核对 RBAC 配置。</div>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>权限编码</th>
        <th>权限名称</th>
        <th>模块</th>
        <th>URI 规则</th>
        <th>状态</th>
        <th>授权角色</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${permissions}" var="perm">
        <tr>
          <td>${perm.permCode}</td>
          <td>${perm.permName}</td>
          <td>${perm.module}</td>
          <td>${perm.uriPattern}</td>
          <td>
            <c:choose>
              <c:when test="${perm.enabled == 1}"><span class="status-badge active">启用</span></c:when>
              <c:otherwise><span class="status-badge inactive">停用</span></c:otherwise>
            </c:choose>
          </td>
          <td>${perm.roleTypes}</td>
        </tr>
      </c:forEach>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
