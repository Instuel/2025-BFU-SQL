<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/dispatcher?action=workOrderList">← 返回工单列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>工单审核</h2>
      <p style="color:#64748b;margin-top:6px;">审核运维工单的处理结果。</p>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${workOrder == null}">
    <div class="warning-message">未找到对应工单。</div>
  </c:if>

  <c:if test="${workOrder != null}">
    <div class="rule-form">
      <div class="rule-form-header">
        <h2>工单信息</h2>
        <span class="order-priority <c:out value='${workOrder.alarmLevel == "高" ? "high" : (workOrder.alarmLevel == "中" ? "medium" : "low")}'/>">${workOrder.alarmLevel}级</span>
      </div>
      <div class="table-container">
        <table class="table">
          <tbody>
          <tr>
            <th>工单编号</th>
            <td>${workOrder.orderId}</td>
            <th>告警编号</th>
            <td>${workOrder.alarmId}</td>
          </tr>
          <tr>
            <th>运维人员</th>
            <td>${workOrder.oandmName}</td>
            <th>设备台账编号</th>
            <td>${workOrder.ledgerId}</td>
          </tr>
          <tr>
            <th>派单时间</th>
            <td>${workOrder.dispatchTime}</td>
            <th>响应时间</th>
            <td>${workOrder.responseTime}</td>
          </tr>
          <tr>
            <th>完成时间</th>
            <td>${workOrder.finishTime}</td>
            <th>当前审核状态</th>
            <td>
              <c:choose>
                <c:when test="${workOrder.reviewStatus == '通过'}">
                  <span class="order-review-tag pass">通过</span>
                </c:when>
                <c:when test="${workOrder.reviewStatus == '未通过'}">
                  <span class="order-review-tag fail">未通过</span>
                </c:when>
                <c:otherwise>
                  <span class="order-review-tag pending">待审核</span>
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
          <tr>
            <th>结果描述</th>
            <td colspan="3">${workOrder.resultDesc}</td>
          </tr>
          <c:if test="${not empty workOrder.reviewFeedback}">
            <tr>
              <th>审核反馈</th>
              <td colspan="3" style="color:#dc2626;">${workOrder.reviewFeedback}</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>

    <c:if test="${alarm != null}">
      <div class="order-list" style="margin-top:24px;">
        <div class="order-list-header">
          <h2>关联告警</h2>
        </div>
        <div class="order-item">
          <div class="order-item-header">
            <div class="order-id">告警 #${alarm.alarmId}</div>
            <span class="alarm-level <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">${alarm.alarmLevel}</span>
          </div>
          <div class="order-item-body">
            <div class="order-field">
              <span class="order-label">告警类型:</span>
              <span class="order-value">${alarm.alarmType}</span>
            </div>
            <div class="order-field">
              <span class="order-label">发生时间:</span>
              <span class="order-value">${alarm.occurTime}</span>
            </div>
            <div class="order-field">
              <span class="order-label">设备:</span>
              <span class="order-value">${alarm.deviceName} (${alarm.deviceType})</span>
            </div>
            <div class="order-field">
              <span class="order-label">告警内容:</span>
              <span class="order-value">${alarm.content}</span>
            </div>
            <div class="order-field">
              <span class="order-label">告警状态:</span>
              <span class="order-value">${alarm.processStatus}</span>
            </div>
          </div>
        </div>
      </div>
    </c:if>

    <c:if test="${workOrder.finishTime != null && (workOrder.reviewStatus == null || workOrder.reviewStatus == '')}">
      <div class="rule-form" style="margin-top:24px;">
        <div class="rule-form-header">
          <h2>工单审核</h2>
        </div>
        <form id="reviewForm" action="${ctx}/dispatcher" method="post" onsubmit="return validateReviewForm()">
          <input type="hidden" name="action" value="reviewWorkOrder">
          <input type="hidden" name="orderId" value="${workOrder.orderId}">
          <input type="hidden" name="alarmId" value="${workOrder.alarmId}">

          <div class="form-group">
            <label class="form-label">审核结果 <span class="required">*</span></label>
            <div class="radio-group">
              <label class="radio-label">
                <input type="radio" name="reviewStatus" value="通过" required>
                <span class="radio-custom"></span>
                <span>通过</span>
              </label>
              <label class="radio-label">
                <input type="radio" name="reviewStatus" value="未通过">
                <span class="radio-custom"></span>
                <span>未通过</span>
              </label>
            </div>
          </div>

          <div class="form-group" id="feedbackGroup" style="display:none;">
            <label class="form-label">审核反馈 <span class="required">*</span></label>
            <textarea class="form-control" name="reviewFeedback" rows="4" placeholder="请填写未通过的原因和改进建议"></textarea>
            <div class="form-hint">未通过时必须填写审核反馈</div>
          </div>

          <div class="form-actions">
            <button type="submit" class="btn btn-primary">提交审核</button>
            <a class="btn btn-secondary" href="${ctx}/dispatcher?action=workOrderList">取消</a>
          </div>
        </form>
      </div>
    </c:if>

    <c:if test="${workOrder.finishTime == null}">
      <div class="warning-message" style="margin-top:24px;">
        该工单尚未由运维人员提交（完成时间为空），暂不能审核。
      </div>
    </c:if>
  </c:if>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  const reviewRadios = document.querySelectorAll('input[name="reviewStatus"]');
  const feedbackGroup = document.getElementById('feedbackGroup');
  const feedbackInput = document.querySelector('textarea[name="reviewFeedback"]');

  reviewRadios.forEach(function(radio) {
    radio.addEventListener('change', function() {
      if (this.value === '未通过') {
        feedbackGroup.style.display = 'block';
        feedbackInput.setAttribute('required', 'required');
      } else {
        feedbackGroup.style.display = 'none';
        feedbackInput.removeAttribute('required');
      }
    });
  });
});

function validateReviewForm() {
  const reviewStatus = document.querySelector('input[name="reviewStatus"]:checked');
  if (!reviewStatus) {
    alert('请选择审核结果');
    return false;
  }

  if (reviewStatus.value === '未通过') {
    const feedback = document.querySelector('textarea[name="reviewFeedback"]').value.trim();
    if (!feedback) {
      alert('未通过时必须填写审核反馈');
      return false;
    }
  }

  return true;
}
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
