<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 操作日志</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <div class="card" style="margin-top:16px;">
    <div style="margin-bottom:16px;color:#64748b;">记录系统管理员的关键配置行为，便于审计追踪。</div>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>日志ID</th>
        <th>操作类型</th>
        <th>操作内容</th>
        <th>操作人</th>
        <th>操作时间</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${auditLogs}" var="log">
        <tr>
          <td>${log.logId}</td>
          <td>${log.actionType}</td>
          <td>${log.actionDetail}</td>
          <td>
            <c:choose>
              <c:when test="${log.operatorId != null}">${log.operatorId}</c:when>
              <c:otherwise>系统</c:otherwise>
            </c:choose>
          </td>
          <td>${log.actionTime}</td>
        </tr>
      </c:forEach>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
