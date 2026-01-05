<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>
<c:set var="isEdit" value="${not empty device}" />
<c:set var="pvView" value="${isEdit ? 'device_edit' : 'device_add'}" />

<div class="main-content">
  <div class="pv-page-header">
    <h1>${isEdit ? '编辑光伏设备' : '新增光伏设备'}</h1>
    <p>${isEdit ? '修改设备的基本信息和运行参数。' : '添加新的光伏设备到系统中。'}</p>
    <div class="pv-subnav">
      <a class="<c:out value='${pvView == "device_list" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=device_list">设备列表</a>
      <a class="<c:out value='${pvView == "device_detail" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=device_detail">设备详情</a>
      <a class="<c:out value='${pvView == "gen_data_list" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=gen_data_list">发电数据</a>
      <a class="<c:out value='${pvView == "forecast_list" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=forecast_list">预测信息</a>
      <a class="<c:out value='${pvView == "forecast_detail" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=forecast_detail">预测详情</a>
      <a class="<c:out value='${pvView == "model_alert_list" ? "active" : ""}'/>" href="${ctx}/app?module=pv&view=model_alert_list">模型告警</a>
    </div>
  </div>

  <div class="pv-form-container" style="max-width: 600px; margin: var(--spacing-xl) auto;">
    <div class="pv-section">
      <div class="pv-table-header">
        <div class="pv-table-title">${isEdit ? '编辑设备信息' : '填写设备信息'}</div>
      </div>
      
      <c:if test="${not empty param.error}">
        <div class="pv-alert pv-alert-danger" style="margin: var(--spacing-md) 0; padding: var(--spacing-md); background: #fff1f0; border: 1px solid #ffa39e; border-radius: var(--radius-md); color: #cf1322;">
          <c:choose>
            <c:when test="${param.error == 'missing'}">请填写必填字段！</c:when>
            <c:when test="${param.error == 'failed'}">操作失败，请重试！</c:when>
            <c:otherwise>发生错误，请重试！</c:otherwise>
          </c:choose>
        </div>
      </c:if>

      <form method="post" action="${ctx}/app" style="padding: var(--spacing-lg);">
        <input type="hidden" name="module" value="pv"/>
        <input type="hidden" name="action" value="${isEdit ? 'device_edit' : 'device_add'}"/>
        <c:if test="${isEdit}">
          <input type="hidden" name="deviceId" value="${device.deviceId}"/>
        </c:if>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            设备类型 <span style="color: #ff4d4f;">*</span>
          </label>
          <select name="deviceType" class="pv-filter-select" style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);" required>
            <option value="">请选择设备类型</option>
            <option value="逆变器" <c:if test="${device.deviceType == '逆变器'}">selected</c:if>>逆变器</option>
            <option value="汇流箱" <c:if test="${device.deviceType == '汇流箱'}">selected</c:if>>汇流箱</option>
          </select>
        </div>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            并网点 <span style="color: #ff4d4f;">*</span>
          </label>
          <select name="pointId" class="pv-filter-select" style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);" required>
            <option value="">请选择并网点</option>
            <c:forEach items="${gridPoints}" var="point">
              <option value="${point.pointId}" <c:if test="${device.pointId == point.pointId}">selected</c:if>>
                ${point.pointName}
              </option>
            </c:forEach>
          </select>
        </div>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            装机容量 (kWp)
          </label>
          <input type="number" name="capacity" step="0.01" min="0" 
                 value="${device.capacity}" 
                 class="pv-filter-select" 
                 style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);"
                 placeholder="请输入装机容量，汇流箱可留空"/>
        </div>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            运行状态
          </label>
          <select name="runStatus" class="pv-filter-select" style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);">
            <option value="正常" <c:if test="${empty device.runStatus || device.runStatus == '正常'}">selected</c:if>>正常</option>
            <option value="异常" <c:if test="${device.runStatus == '异常'}">selected</c:if>>异常</option>
            <option value="故障" <c:if test="${device.runStatus == '故障'}">selected</c:if>>故障</option>
            <option value="离线" <c:if test="${device.runStatus == '离线'}">selected</c:if>>离线</option>
          </select>
        </div>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            安装日期
          </label>
          <input type="date" name="installDate" 
                 value="${device.installDate}" 
                 class="pv-filter-select" 
                 style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);"/>
        </div>

        <div class="pv-form-group" style="margin-bottom: var(--spacing-lg);">
          <label class="pv-filter-label" style="display: block; margin-bottom: var(--spacing-sm); font-weight: 500;">
            通信协议
          </label>
          <select name="protocol" class="pv-filter-select" style="width: 100%; padding: var(--spacing-sm) var(--spacing-md);">
            <option value="RS485" <c:if test="${empty device.protocol || device.protocol == 'RS485'}">selected</c:if>>RS485</option>
            <option value="Lora" <c:if test="${device.protocol == 'Lora'}">selected</c:if>>Lora</option>
            <option value="TCP/IP" <c:if test="${device.protocol == 'TCP/IP'}">selected</c:if>>TCP/IP</option>
            <option value="Modbus" <c:if test="${device.protocol == 'Modbus'}">selected</c:if>>Modbus</option>
          </select>
        </div>

        <div class="pv-form-actions" style="display: flex; gap: var(--spacing-sm); justify-content: flex-end; padding-top: var(--spacing-lg); border-top: 1px solid var(--border-color);">
          <a href="${ctx}/app?module=pv&view=device_list" class="pv-sort-btn" style="text-decoration: none; background: #f5f5f5; color: #666;">
            取消
          </a>
          <button type="submit" class="pv-sort-btn">
            ${isEdit ? '保存' : '添加'}
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
