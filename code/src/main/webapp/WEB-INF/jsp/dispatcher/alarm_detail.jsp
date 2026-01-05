<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/dispatcher/dispatcher_nav.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/dispatcher?action=list">← 返回告警列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>告警审核</h2>
      <p style="color:#64748b;margin-top:6px;">审核告警真实性，决定是否生成运维工单。</p>
    </div>
  </div>

  <c:if test="${not empty message}">
    <div class="success-message" style="margin-bottom:16px;">${message}</div>
  </c:if>

  <c:if test="${alarm == null}">
    <div class="warning-message">未找到对应告警数据。</div>
  </c:if>

  <c:if test="${alarm != null}">
    <div class="rule-form">
      <div class="rule-form-header">
        <h2>告警信息</h2>
        <span class="alarm-level <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">${alarm.alarmLevel}</span>
      </div>
      <div class="table-container">
        <table class="table">
          <tbody>
          <tr>
            <th>告警编号</th>
            <td>${alarm.alarmId}</td>
            <th>告警类型</th>
            <td>${alarm.alarmType}</td>
          </tr>
          <tr>
            <th>发生时间</th>
            <td>${alarm.occurTime}</td>
            <th>处理状态</th>
            <td>${alarm.processStatus}</td>
          </tr>
          <tr>
            <th>真实性审核</th>
            <td>
              <c:choose>
                <c:when test="${alarm.verifyStatus == '有效'}"><span class="alarm-verify-tag valid">有效</span></c:when>
                <c:when test="${alarm.verifyStatus == '误报'}"><span class="alarm-verify-tag invalid">误报</span></c:when>
                <c:otherwise><span class="alarm-verify-tag pending">待审核</span></c:otherwise>
              </c:choose>
            </td>
            <th>审核备注</th>
            <td>${alarm.verifyRemark}</td>
          </tr>
          <tr>
            <th>关联设备</th>
            <td>${alarm.deviceName} (${alarm.deviceType})</td>
            <th>设备台账编号</th>
            <td>${alarm.ledgerId}</td>
          </tr>
          <tr>
            <th>触发阈值</th>
            <td>${alarm.triggerThreshold}</td>
            <th>派单时效</th>
            <td>
              <c:choose>
                <c:when test="${alarm.dispatchOverdue}">
                  <span class="alarm-sla-tag overdue">高等级派单超时</span>
                </c:when>
                <c:when test="${workOrder != null}">
                  <span class="alarm-sla-tag">已派单</span>
                </c:when>
                <c:otherwise>
                  <span class="alarm-sla-tag">待派单</span>
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
          <tr>
            <th>告警内容</th>
            <td colspan="3">${alarm.content}</td>
          </tr>
          </tbody>
        </table>
      </div>

      <c:if test="${alarm.verifyStatus == null || alarm.verifyStatus == '待审核'}">
        <form action="${ctx}/dispatcher" method="post" style="margin-top:20px;">
          <input type="hidden" name="action" value="verifyAlarm"/>
          <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
          <div class="rule-form-grid">
            <div class="form-group">
              <label>真实性审核</label>
              <select name="verifyStatus" required>
                <option value="">请选择</option>
                <option value="有效">有效</option>
                <option value="误报">误报</option>
              </select>
            </div>
            <div class="form-group" style="grid-column:1 / -1;">
              <label>审核说明</label>
              <textarea name="verifyRemark" rows="3" placeholder="填写误报原因或核实说明"></textarea>
            </div>
            <div class="form-group" style="display:flex;align-items:flex-end;">
              <button class="btn btn-primary" type="submit">提交审核</button>
            </div>
          </div>
        </form>
      </c:if>

      <c:if test="${alarm.verifyStatus == '有效'}">
        <div style="margin-top:20px;">
          <a class="btn btn-primary" href="${ctx}/dispatcher?action=createWorkOrder&alarmId=${alarm.alarmId}">创建运维工单</a>
        </div>
      </c:if>
    </div>

    <div class="order-list" style="margin-top:24px;">
      <div class="order-list-header">
        <h2>运维工单</h2>
        <c:if test="${workOrder != null}">
          <a class="btn btn-secondary" href="${ctx}/dispatcher?action=workOrderDetail&id=${workOrder.orderId}">查看工单详情</a>
        </c:if>
      </div>

      <c:if test="${workOrder != null}">
        <div class="order-item">
          <div class="order-item-header">
            <div class="order-id">工单 #${workOrder.orderId}</div>
            <span class="order-priority <c:out value='${alarm.alarmLevel == "高" ? "high" : (alarm.alarmLevel == "中" ? "medium" : "low")}'/>">
              ${alarm.alarmLevel}级
            </span>
          </div>
          <div class="order-item-body">
            <div class="order-field">
              <span class="order-label">派发时间:</span>
              <span class="order-value">${workOrder.dispatchTime}</span>
            </div>
            <div class="order-field">
              <span class="order-label">处理状态:</span>
              <span class="order-value">
                <c:choose>
                  <c:when test="${workOrder.responseTime == null}">待响应</c:when>
                  <c:when test="${workOrder.finishTime == null}">处理中</c:when>
                  <c:otherwise>已完成</c:otherwise>
                </c:choose>
              </span>
            </div>
            <div class="order-field">
              <span class="order-label">结果描述:</span>
              <span class="order-value">${workOrder.resultDesc}</span>
            </div>
          </div>
        </div>
      </c:if>

      <c:if test="${workOrder == null}">
        <div class="order-item" style="text-align:center;color:#94a3b8;">
          暂无运维工单
        </div>
      </c:if>
    </div>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
