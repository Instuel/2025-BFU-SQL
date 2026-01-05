<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/alarm?action=workorderList&module=alarm">← 返回工单列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>运维工单详情</h2>
      <p style="color:#64748b;margin-top:6px;">填写处理过程、上传附件并完成复查。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn primary" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
    <a class="action-btn" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${createMode}">
    <div class="rule-form">
      <div class="rule-form-header">
        <h2>创建运维工单</h2>
      </div>
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
          </div>
        </div>
      </c:if>

      <form action="${ctx}/alarm" method="post" enctype="multipart/form-data" class="rule-form-grid">
        <input type="hidden" name="action" value="createWorkOrder"/>
        <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
        <div class="form-group">
          <label>运维人员 ID</label>
          <input name="oandmId" placeholder="填写运维人员 ID"/>
        </div>
        <div class="form-group">
          <label>设备台账编号</label>
          <input name="ledgerId" value="${alarm.ledgerId}" placeholder="关联设备台账编号"/>
        </div>
        <div class="form-group">
          <label>派单时间</label>
          <input type="datetime-local" name="dispatchTime"/>
        </div>
        <div class="form-group">
          <label>附件路径</label>
          <input name="attachmentPath" placeholder="例如：/upload/workorder/2024-01-01.png"/>
        </div>
        <div class="form-group">
          <label>上传附件</label>
          <input type="file" name="attachmentFile" accept=".png,.jpg,.jpeg,.pdf,.doc,.docx"/>
        </div>
        <div class="form-group" style="grid-column:1 / -1;">
          <label>派单说明</label>
          <textarea name="resultDesc" rows="3" placeholder="补充派单说明"></textarea>
        </div>
        <div class="form-group" style="display:flex;align-items:flex-end;">
          <button class="btn btn-primary" type="submit">创建工单</button>
        </div>
      </form>
    </div>
  </c:if>

  <c:if test="${!createMode}">
    <c:if test="${workOrder == null}">
      <div class="warning-message">未找到对应工单。</div>
    </c:if>
    <c:if test="${workOrder != null}">
      <div class="rule-form">
        <div class="rule-form-header">
          <h2>工单信息</h2>
          <span class="order-priority <c:out value='${workOrder.alarmLevel == "高" ? "high" : (workOrder.alarmLevel == "中" ? "medium" : "low")}'/>">${workOrder.alarmLevel}级</span>
        </div>
        <form action="${ctx}/alarm" method="post" enctype="multipart/form-data" class="rule-form-grid">
          <input type="hidden" name="action" value="updateWorkOrder"/>
          <input type="hidden" name="orderId" value="${workOrder.orderId}"/>
          <input type="hidden" name="alarmId" value="${workOrder.alarmId}"/>
          <div class="form-group">
            <label>工单编号</label>
            <input value="${workOrder.orderId}" readonly/>
          </div>
          <div class="form-group">
            <label>告警编号</label>
            <input value="${workOrder.alarmId}" readonly/>
          </div>
          <div class="form-group">
            <label>运维人员 ID</label>
            <input name="oandmId" value="${workOrder.oandmId}"/>
          </div>
          <div class="form-group">
            <label>设备台账编号</label>
            <input name="ledgerId" value="${workOrder.ledgerId}"/>
          </div>
          <div class="form-group">
            <label>派单时间</label>
            <input type="datetime-local" name="dispatchTime" value="${workOrder.dispatchTime}"/>
          </div>
          <div class="form-group">
            <label>响应时间</label>
            <input type="datetime-local" name="responseTime" value="${workOrder.responseTime}"/>
          </div>
          <div class="form-group">
            <label>完成时间</label>
            <input type="datetime-local" name="finishTime" value="${workOrder.finishTime}"/>
          </div>
          <div class="form-group">
            <label>响应提醒</label>
            <c:choose>
              <c:when test="${workOrder.responseOverdue}">
                <span class="order-reminder-tag overdue">超时提醒</span>
              </c:when>
              <c:otherwise>
                <span class="order-reminder-tag">正常</span>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="form-group">
            <label>复查状态</label>
            <select name="reviewStatus">
              <option value="" <c:if test="${empty workOrder.reviewStatus}">selected</c:if>>未复查</option>
              <option value="通过" <c:if test="${workOrder.reviewStatus == '通过'}">selected</c:if>>通过</option>
              <option value="未通过" <c:if test="${workOrder.reviewStatus == '未通过'}">selected</c:if>>未通过</option>
            </select>
          </div>
          <div class="form-group">
            <label>附件路径</label>
            <input name="attachmentPath" value="${workOrder.attachmentPath}"/>
          </div>
          <div class="form-group">
            <label>上传附件</label>
            <input type="file" name="attachmentFile" accept=".png,.jpg,.jpeg,.pdf,.doc,.docx"/>
            <c:if test="${not empty workOrder.attachmentPath}">
              <div style="margin-top:6px;font-size:12px;">
                当前附件：
                <a class="btn btn-link" href="${ctx}${workOrder.attachmentPath}" target="_blank">查看附件</a>
              </div>
            </c:if>
          </div>
          <div class="form-group" style="grid-column:1 / -1;">
            <label>处理结果</label>
            <textarea name="resultDesc" rows="4">${workOrder.resultDesc}</textarea>
          </div>
          <div class="form-group" style="display:flex;align-items:flex-end;">
            <button class="btn btn-primary" type="submit">保存工单</button>
          </div>
        </form>
      </div>

      <c:if test="${workOrder.reviewStatus == '未通过'}">
        <div class="rule-form" style="margin-top:24px;">
          <div class="rule-form-header">
            <h2>复查未通过 - 重新派单</h2>
          </div>
          <form action="${ctx}/alarm" method="post" class="rule-form-grid">
            <input type="hidden" name="action" value="redispatchWorkOrder"/>
            <input type="hidden" name="orderId" value="${workOrder.orderId}"/>
            <div class="form-group">
              <label>重新指派运维人员 ID</label>
              <input name="oandmId" value="${workOrder.oandmId}" placeholder="填写新的运维人员 ID"/>
            </div>
            <div class="form-group">
              <label>重新派单时间</label>
              <input type="datetime-local" name="dispatchTime"/>
            </div>
            <div class="form-group" style="grid-column:1 / -1;">
              <label>重新派单原因</label>
              <textarea name="redispatchReason" rows="3" placeholder="补充复查未通过的原因与新的处理要求"></textarea>
            </div>
            <div class="form-group" style="display:flex;align-items:flex-end;">
              <button class="btn btn-primary" type="submit">确认重新派单</button>
            </div>
          </form>
        </div>
      </c:if>
    </c:if>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
