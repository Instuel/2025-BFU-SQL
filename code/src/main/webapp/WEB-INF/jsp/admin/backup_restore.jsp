<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 备份与恢复</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <c:if test="${not empty message}">
    <div class="success-message message">${message}</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="error-message message">${error}</div>
  </c:if>

  <div class="content-grid" style="margin-top:16px;">
    <div class="card">
      <h3 style="margin-bottom:16px;">执行备份/恢复</h3>
      <form action="${pageContext.request.contextPath}/admin" method="post" class="form">
        <input type="hidden" name="action" value="saveBackupLog">
        <div class="form-group">
          <label class="form-label">任务类型</label>
          <select name="backupType" class="input">
            <option value="全量备份">全量备份</option>
            <option value="增量备份">增量备份</option>
            <option value="恢复演练">恢复演练</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">备份文件路径</label>
          <input class="input" type="text" name="backupPath" placeholder="/data/backup/energy_20250318.bak">
        </div>
        <div class="form-group">
          <label class="form-label">执行结果</label>
          <select name="status" class="input">
            <option value="成功">成功</option>
            <option value="失败">失败</option>
            <option value="进行中">进行中</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">备注</label>
          <textarea class="input" name="remark" rows="3" placeholder="说明备份范围或恢复步骤"></textarea>
        </div>
        <button class="btn btn-primary" type="submit">保存记录</button>
      </form>
    </div>

    <div class="card">
      <h3 style="margin-bottom:16px;">备份记录</h3>
      <table class="table" style="width:100%;">
        <thead>
        <tr>
          <th>ID</th>
          <th>类型</th>
          <th>状态</th>
          <th>路径</th>
          <th>开始时间</th>
          <th>结束时间</th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${backupLogs}" var="log">
          <tr>
            <td>${log.backupId}</td>
            <td>${log.backupType}</td>
            <td>
              <c:choose>
                <c:when test="${log.status == '成功'}"><span class="status-badge normal">成功</span></c:when>
                <c:when test="${log.status == '进行中'}"><span class="status-badge warning">进行中</span></c:when>
                <c:otherwise><span class="status-badge error">失败</span></c:otherwise>
              </c:choose>
            </td>
            <td>${log.backupPath}</td>
            <td>${log.startTime}</td>
            <td>${log.endTime}</td>
          </tr>
        </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
