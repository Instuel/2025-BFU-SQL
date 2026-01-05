<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/alarm?action=workorderList&module=alarm">← 返回工单列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>运维工单详情</h2>
      <p style="color:#64748b;margin-top:6px;">收到工单后填写处理过程并提交审核。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <c:if test="${sessionScope.currentRoleType == 'OM' || sessionScope.currentRoleType == '运维人员'}">
      <a class="action-btn primary" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    </c:if>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
    <a class="action-btn" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${createMode}">
    <div class="warning-message" style="margin-bottom:16px;">当前页面处于创建模式：建议由调度员在“告警审核/派单”流程中创建工单。</div>
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
          <label class="form-label">运维人员 OandM_ID</label>
          <input class="form-control" name="oandmId" placeholder="填写 Role_OandM.OandM_ID"/>
        </div>
        <div class="form-group">
          <label class="form-label">设备台账编号</label>
          <input class="form-control" name="ledgerId" value="${alarm.ledgerId}"/>
        </div>
        <div class="form-group" style="grid-column:1/-1;">
          <label class="form-label">派单说明</label>
          <textarea class="form-control" name="resultDesc" rows="4" placeholder="可填写派单备注"></textarea>
        </div>
        <div class="form-group" style="grid-column:1/-1;">
          <label class="form-label">附件（可选）</label>
          <input class="form-control" type="file" name="attachmentFile"/>
        </div>
        <div class="form-actions" style="grid-column:1/-1;">
          <button type="submit" class="btn btn-primary">创建工单</button>
          <a class="btn btn-secondary" href="${ctx}/alarm?action=list&module=alarm">返回</a>
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
          <div>
            <c:choose>
              <c:when test="${workOrder.reviewStatus == '通过'}">
                <span class="order-review-tag pass">通过</span>
              </c:when>
              <c:when test="${workOrder.reviewStatus == '未通过'}">
                <span class="order-review-tag fail">未通过</span>
              </c:when>
              <c:when test="${workOrder.finishTime != null}">
                <span class="order-review-tag pending">待审核</span>
              </c:when>
              <c:when test="${workOrder.responseTime == null}">
                <span class="order-review-tag pending">待响应</span>
              </c:when>
              <c:otherwise>
                <span class="order-review-tag pending">处理中</span>
              </c:otherwise>
            </c:choose>
          </div>
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
              <th>台账编号</th>
              <td>${workOrder.ledgerId}</td>
              <th>派单时间</th>
              <td>${workOrder.dispatchTime}</td>
            </tr>
            <tr>
              <th>响应时间</th>
              <td>${workOrder.responseTime}</td>
              <th>完成时间</th>
              <td>${workOrder.finishTime}</td>
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

      <c:if test="${sessionScope.currentRoleType == 'OM'}">
        <div style="margin-top:16px;">
          <c:if test="${workOrder.responseTime == null}">
            <form action="${ctx}/alarm" method="post" style="display:inline-block;margin-right:8px;">
              <input type="hidden" name="action" value="receiveWorkOrder"/>
              <input type="hidden" name="orderId" value="${workOrder.orderId}"/>
              <button type="submit" class="btn btn-secondary">收到工单</button>
            </form>
          </c:if>
        </div>
      </c:if>

      <div class="rule-form" style="margin-top:16px;">
        <div class="rule-form-header">
          <h2>填写处理信息</h2>
        </div>

        <form id="workOrderForm" action="${ctx}/alarm" method="post" enctype="multipart/form-data" class="rule-form-grid">
          <input type="hidden" id="formAction" name="action" value="updateWorkOrder"/>
          <input type="hidden" name="orderId" value="${workOrder.orderId}"/>
          <input type="hidden" name="alarmId" value="${workOrder.alarmId}"/>
          <input type="hidden" name="ledgerId" value="${workOrder.ledgerId}"/>
          <input type="hidden" name="oandmId" value="${workOrder.oandmId}"/>
          <input type="hidden" name="dispatchTime" value="${workOrder.dispatchTime}"/>
          <input type="hidden" name="attachmentPath" value="${workOrder.attachmentPath}"/>

          <div class="form-group">
            <label class="form-label">响应时间</label>
            <input class="form-control" type="datetime-local" name="responseTime" value="${workOrder.responseTime}"/>
            <div class="form-hint">点击“收到工单”会自动填写该时间，也可手动调整。</div>
          </div>
          <div class="form-group">
            <label class="form-label">完成时间</label>
            <input class="form-control" type="datetime-local" name="finishTime" value="${workOrder.finishTime}"/>
            <div class="form-hint">提交审核时若为空，系统会自动补当前时间。</div>
          </div>

          <div class="form-group" style="grid-column:1/-1;">
            <label class="form-label">处理结果描述 <span class="required">*</span></label>
            <textarea class="form-control" name="resultDesc" rows="6" placeholder="请填写处理过程、原因分析、处理措施等" required>${workOrder.resultDesc}</textarea>
          </div>

          <div class="form-group" style="grid-column:1/-1;">
            <label class="form-label">附件（可选）</label>
            <input class="form-control" type="file" name="attachmentFile"/>
            <c:if test="${not empty workOrder.attachmentPath}">
              <div class="form-hint">
                已有附件：<a href="${ctx}${workOrder.attachmentPath}" target="_blank">点击查看</a>
              </div>
            </c:if>
          </div>

          <div class="form-actions" style="grid-column:1/-1;">
            <c:if test="${sessionScope.currentRoleType == 'OM'}">
              <button type="submit" class="btn btn-primary" onclick="document.getElementById('formAction').value='updateWorkOrder'">保存工单</button>
              <button type="submit" class="btn btn-success" onclick="document.getElementById('formAction').value='submitWorkOrder'">提交审核</button>
            </c:if>
            <a class="btn btn-secondary" href="${ctx}/alarm?action=workorderList&module=alarm">返回列表</a>
          </div>
        </form>
      </div>
    </c:if>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
