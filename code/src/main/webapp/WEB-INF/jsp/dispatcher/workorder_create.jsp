<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/dispatcher?action=detail&id=${alarm.alarmId}">← 返回告警详情</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>创建运维工单</h2>
      <p style="color:#64748b;margin-top:6px;">为有效告警创建运维工单并派发给运维人员。</p>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${alarm != null}">
    <div class="order-item" style="margin-bottom:16px;">
      <div class="order-item-header">
        <div class="order-id">告警 #${alarm.alarmId}</div>
        <span class="order-priority <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">${alarm.alarmLevel}级</span>
      </div>
      <div class="order-details">
        <div class="order-detail"><strong>告警类型：</strong>${alarm.alarmType}</div>
        <div class="order-detail"><strong>发生时间：</strong>${alarm.occurTime}</div>
        <div class="order-detail"><strong>设备：</strong>${alarm.deviceName}</div>
        <div class="order-detail"><strong>台账编号：</strong>${alarm.ledgerId}</div>
        <div class="order-detail"><strong>告警内容：</strong>${alarm.content}</div>
      </div>
    </div>
  </c:if>

  <div class="rule-form">
    <div class="rule-form-header">
      <h2>工单信息</h2>
    </div>
    <form action="${ctx}/dispatcher" method="post" enctype="multipart/form-data" class="rule-form-grid">
      <input type="hidden" name="action" value="createWorkOrder"/>
      <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
      <input type="hidden" name="ledgerId" value="${alarm.ledgerId}"/>
      <input type="hidden" name="dispatcherId" value="${dispatcherId}"/>
      <div class="form-group">
        <label>运维人员</label>
        <select name="oandmId" required>
          <option value="">请选择运维人员</option>
          <c:forEach items="${oandmUsers}" var="user">
            <option value="${user.userId}">${user.realName} (${user.loginAccount})</option>
          </c:forEach>
        </select>
      </div>
      <div class="form-group">
        <label>设备台账编号</label>
        <input value="${alarm.ledgerId}" readonly/>
      </div>
      <div class="form-group">
        <label>派单时间</label>
        <input type="datetime-local" name="dispatchTime" value="${now}"/>
      </div>
      <div class="form-group">
        <label>上传附件</label>
        <input type="file" name="attachmentFile" id="attachmentFile" accept=".png,.jpg,.jpeg,.pdf,.doc,.docx" style="display:none;" onchange="handleFileSelect(this)"/>
        <div style="display:flex;gap:8px;align-items:center;">
          <button type="button" class="btn btn-secondary" onclick="document.getElementById('attachmentFile').click()">
            选择文件
          </button>
          <span id="selectedFileName" style="color:#64748b;font-size:14px;">未选择文件</span>
        </div>
        <div class="form-hint">支持格式：PNG, JPG, PDF, DOC, DOCX（最大10MB）</div>
      </div>
      <div class="form-group" style="grid-column:1 / -1;">
        <label>派单说明</label>
        <textarea name="resultDesc" rows="3" placeholder="补充派单说明"></textarea>
      </div>
      <div class="form-group" style="display:flex;align-items:flex-end;">
        <button class="btn btn-primary" type="submit">创建并派发工单</button>
      </div>
    </form>
  </div>
</div>

<script>
function handleFileSelect(input) {
  const fileNameSpan = document.getElementById('selectedFileName');
  if (input.files && input.files.length > 0) {
    const file = input.files[0];
    const fileSize = (file.size / 1024 / 1024).toFixed(2);
    fileNameSpan.textContent = file.name + ' (' + fileSize + ' MB)';
    
    if (file.size > 10 * 1024 * 1024) {
      alert('文件大小超过10MB限制，请选择更小的文件');
      input.value = '';
      fileNameSpan.textContent = '未选择文件';
    }
  } else {
    fileNameSpan.textContent = '未选择文件';
  }
}
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
