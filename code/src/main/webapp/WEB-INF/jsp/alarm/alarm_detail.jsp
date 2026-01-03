<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <a class="back-btn" href="${ctx}/alarm?action=list&module=alarm">← 返回告警列表</a>

  <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
    <div>
      <h2>告警详情</h2>
      <p style="color:#64748b;margin-top:6px;">查看告警信息与派单处理状态。</p>
    </div>
  </div>

  <div class="alarm-nav">
    <a class="action-btn primary" href="${ctx}/alarm?action=list&module=alarm">告警列表</a>
    <a class="action-btn" href="${ctx}/alarm?action=workorderList&module=alarm">运维工单</a>
    <a class="action-btn" href="${ctx}/alarm?action=ledgerList&module=alarm">设备台账</a>
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
                <c:when test="${alarm.workOrderId != null}">
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

      <form action="${ctx}/alarm" method="post" style="margin-top:20px;">
        <input type="hidden" name="action" value="updateAlarmStatus"/>
        <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
        <div class="rule-form-grid">
          <div class="form-group">
            <label>更新处理状态</label>
            <select name="processStatus">
              <option value="未处理" <c:if test="${alarm.processStatus == '未处理'}">selected</c:if>>未处理</option>
              <option value="处理中" <c:if test="${alarm.processStatus == '处理中'}">selected</c:if>>处理中</option>
              <option value="已结案" <c:if test="${alarm.processStatus == '已结案'}">selected</c:if>>已结案</option>
            </select>
          </div>
          <div class="form-group" style="display:flex;align-items:flex-end;">
            <button class="btn btn-primary" type="submit">保存状态</button>
          </div>
        </div>
      </form>
    </div>

    <div class="order-list" style="margin-top:24px;">
      <div class="order-list-header">
        <h2>运维工单</h2>
        <c:if test="${workOrder != null}">
          <a class="btn btn-secondary" href="${ctx}/alarm?action=workorderDetail&id=${workOrder.orderId}&module=alarm">查看工单详情</a>
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
          <div class="order-details">
            <div class="order-detail"><strong>派单时间：</strong>${workOrder.dispatchTime}</div>
            <div class="order-detail"><strong>响应时间：</strong>${workOrder.responseTime}</div>
            <div class="order-detail"><strong>处理完成：</strong>${workOrder.finishTime}</div>
            <div class="order-detail"><strong>复查状态：</strong>${workOrder.reviewStatus}</div>
          </div>
        </div>
      </c:if>

      <c:if test="${workOrder == null}">
        <p style="color:#64748b;margin-bottom:16px;">当前告警尚未派单，管理员可直接生成运维工单。</p>
        <form action="${ctx}/alarm" method="post">
          <input type="hidden" name="action" value="createWorkOrder"/>
          <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
          <div class="rule-form-grid">
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
              <input name="attachmentPath" placeholder="例如：/upload/alarm/2024-01-01.png"/>
            </div>
            <div class="form-group" style="grid-column:1 / -1;">
              <label>备注</label>
              <textarea name="resultDesc" rows="3" placeholder="补充派单说明"></textarea>
            </div>
            <div class="form-group" style="display:flex;align-items:flex-end;">
              <button class="btn btn-primary" type="submit">生成运维工单</button>
            </div>
          </div>
        </form>
      </c:if>
    </div>
  </c:if>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
