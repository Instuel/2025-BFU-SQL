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
    <a class="action-btn" href="${ctx}/alarm?action=maintenancePlanList&module=alarm">维护计划</a>
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

      <c:if test="${currentRoleType != '运维人员'}">
        <form action="${ctx}/alarm" method="post" style="margin-top:20px;">
          <input type="hidden" name="action" value="updateAlarmVerify"/>
          <input type="hidden" name="alarmId" value="${alarm.alarmId}"/>
          <div class="rule-form-grid">
            <div class="form-group">
              <label>真实性审核</label>
              <select name="verifyStatus">
                <option value="待审核" <c:if test="${alarm.verifyStatus == '待审核' || empty alarm.verifyStatus}">selected</c:if>>待审核</option>
                <option value="有效" <c:if test="${alarm.verifyStatus == '有效'}">selected</c:if>>有效</option>
                <option value="误报" <c:if test="${alarm.verifyStatus == '误报'}">selected</c:if>>误报</option>
              </select>
            </div>
            <div class="form-group" style="grid-column:1 / -1;">
              <label>审核说明</label>
              <textarea name="verifyRemark" rows="3" placeholder="填写误报原因或核实说明">${alarm.verifyRemark}</textarea>
            </div>
            <div class="form-group" style="display:flex;align-items:flex-end;">
              <button class="btn btn-primary" type="submit">保存审核</button>
            </div>
          </div>
        </form>
      </c:if>

      <c:if test="${currentRoleType != '运维人员'}">
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
      </c:if>
    </div>

    <c:if test="${currentRoleType != 'OM'}">
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
        <c:choose>
          <c:when test="${alarm.verifyStatus != '有效'}">
            <div class="warning-message">当前告警尚未通过真实性审核，请先完成审核后再派单。</div>
          </c:when>
          <c:otherwise>
            <p style="color:#64748b;margin-bottom:16px;">当前告警尚未派单，管理员可直接生成运维工单。</p>
          </c:otherwise>
        </c:choose>
        <c:if test="${currentRoleType != 'OM'}">
          <form action="${ctx}/alarm" method="post" enctype="multipart/form-data">
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
                <label>备注</label>
                <textarea name="resultDesc" rows="3" placeholder="补充派单说明"></textarea>
              </div>
              <div class="form-group" style="display:flex;align-items:flex-end;">
                <button class="btn btn-primary" type="submit" <c:if test="${alarm.verifyStatus != '有效'}">disabled</c:if>>生成运维工单</button>
              </div>
            </div>
          </form>
        </c:if>
      </c:if>
    </div>
    </c:if>
  </c:if>
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
