<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="adminAction" value="${empty param.action ? 'list' : param.action}" />

<div class="admin-nav">
  <a class="<c:out value='${adminAction==\"list\" || adminAction==\"detail\" || adminAction==\"create\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=list">账号管理</a>
  <a class="<c:out value='${adminAction==\"role_assign\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=role_assign">角色分配</a>
  <a class="<c:out value='${adminAction==\"permission_list\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=permission_list">权限清单</a>
  <a class="<c:out value='${adminAction==\"alarm_rule\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=alarm_rule">告警规则</a>
  <a class="<c:out value='${adminAction==\"peak_valley\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=peak_valley">峰谷时段</a>
  <a class="<c:out value='${adminAction==\"backup_restore\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=backup_restore">备份恢复</a>
  <a class="<c:out value='${adminAction==\"system_status\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=system_status">系统状态</a>
  <a class="<c:out value='${adminAction==\"audit_log\" ? \"active\" : \"\"}'/>"
     href="${pageContext.request.contextPath}/admin?action=audit_log">操作日志</a>
</div>
