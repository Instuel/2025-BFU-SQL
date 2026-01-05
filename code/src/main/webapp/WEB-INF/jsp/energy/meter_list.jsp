<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="energy-stats-container">
    <div class="energy-stats-header">
      <h1>综合能耗管理 / 计量设备台账</h1>
      <p>覆盖电/水/蒸汽/天然气计量设备的运行状态、校准周期与厂区分布。</p>
    </div>

    <%-- 操作提示信息 --%>
    <c:if test="${param.success == 'meter'}">
      <div class="alert alert-success" style="background:#d1fae5;border:1px solid #10b981;color:#065f46;padding:12px 16px;border-radius:8px;margin-bottom:16px;">
        ✓ 新增设备成功！
      </div>
    </c:if>
    <c:if test="${param.error == 'missing'}">
      <div class="alert alert-error" style="background:#fee2e2;border:1px solid #ef4444;color:#991b1b;padding:12px 16px;border-radius:8px;margin-bottom:16px;">
        ✗ 请填写必填字段（能源类型、厂区、安装位置）
      </div>
    </c:if>

    <div class="energy-filter-section">
      <form class="energy-filter-bar" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="energy"/>
        <input type="hidden" name="view" value="meter_list"/>
        <span class="energy-filter-label">能源类型</span>
        <select class="energy-filter-select" name="energyType">
          <option value="">全部</option>
          <option value="电" <c:if test="${selectedEnergyType == '电'}">selected</c:if>>电</option>
          <option value="水" <c:if test="${selectedEnergyType == '水'}">selected</c:if>>水</option>
          <option value="蒸汽" <c:if test="${selectedEnergyType == '蒸汽'}">selected</c:if>>蒸汽</option>
          <option value="天然气" <c:if test="${selectedEnergyType == '天然气'}">selected</c:if>>天然气</option>
        </select>
        <span class="energy-filter-label">厂区</span>
        <select class="energy-filter-select" name="factoryId">
          <option value="">全部厂区</option>
          <c:forEach items="${factories}" var="factory">
            <option value="${factory.factoryId}" <c:if test="${selectedFactoryId == factory.factoryId}">selected</c:if>>
              ${factory.factoryName}
            </option>
          </c:forEach>
        </select>
        <span class="energy-filter-label">状态</span>
        <select class="energy-filter-select" name="runStatus">
          <option value="">全部</option>
          <option value="正常" <c:if test="${selectedRunStatus == '正常'}">selected</c:if>>正常</option>
          <option value="故障" <c:if test="${selectedRunStatus == '故障'}">selected</c:if>>故障</option>
        </select>
        <input class="energy-date-input" type="text" name="keyword" value="${keyword}" placeholder="设备编号/位置搜索"/>
        <button class="action-btn primary">查询</button>
      </form>
    </div>

    <div class="energy-stats-grid">
      <div class="energy-stat-card consumption">
        <div class="energy-stat-label">设备总数</div>
        <div class="energy-stat-value">${meterStats.totalCount}</div>
        <div class="energy-stat-sub">覆盖 ${meterStats.factoryCount} 个厂区</div>
      </div>
      <div class="energy-stat-card efficiency">
        <div class="energy-stat-label">正常运行</div>
        <div class="energy-stat-value">${meterStats.normalCount}</div>
        <div class="energy-stat-sub">状态为正常的设备数量</div>
      </div>
      <div class="energy-stat-card cost">
        <div class="energy-stat-label">故障设备</div>
        <div class="energy-stat-value">${meterStats.abnormalCount}</div>
        <div class="energy-stat-sub">运行状态异常</div>
      </div>
      <div class="energy-stat-card savings">
        <div class="energy-stat-label">厂区覆盖</div>
        <div class="energy-stat-value">${meterStats.factoryCount}</div>
        <div class="energy-stat-sub">关联厂区数量</div>
      </div>
    </div>

    <div class="section" style="margin-bottom:24px;">
      <div class="section-header">
        <h3 class="section-title">综合能耗快捷入口</h3>
        <div class="action-buttons">
          <a class="action-btn primary" href="${ctx}/app?module=energy&view=energy_data_list">监测数据</a>
          <a class="action-btn secondary" href="${ctx}/app?module=energy&view=peak_valley_list">峰谷统计</a>
          <a class="action-btn" href="${ctx}/app?module=energy&view=peak_valley_report">能耗报告</a>
          <a class="action-btn" href="${ctx}/app?module=energy&view=report_overview">月度报表</a>
          <a class="action-btn" href="${ctx}/app?module=energy&view=data_review">数据审核</a>
          <a class="action-btn" href="${ctx}/app?module=energy&view=optimization_plan">优化方案</a>
        </div>
      </div>
      <p style="color:#64748b;margin:0;">提示：设备信息用于关联能耗监测数据与峰谷统计报表。</p>
    </div>

    <div class="section">
      <div class="section-header">
        <h3 class="section-title">计量设备清单</h3>
        <div class="action-buttons">
          <button class="action-btn primary" type="button" onclick="openAddMeterModal()">新增设备</button>
          <a class="action-btn secondary" href="${ctx}/exportCSV?type=meter_list&energyType=${selectedEnergyType}&factoryId=${selectedFactoryId}&runStatus=${selectedRunStatus}&keyword=${keyword}">导出CSV</a>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>设备编号</th>
            <th>能源类型</th>
            <th>安装位置</th>
            <th>管径规格</th>
            <th>通讯协议</th>
            <th>运行状态</th>
            <th>校准周期</th>
            <th>操作</th>
          </tr>
          </thead>
          <tbody>
          <c:forEach items="${meters}" var="meter">
            <tr>
              <td>${meter.meterCode}</td>
              <td>${meter.energyType}</td>
              <td><c:out value="${meter.installLocation}" default="-"/></td>
              <td><c:out value="${meter.modelSpec}" default="-"/></td>
              <td><c:out value="${meter.commProtocol}" default="-"/></td>
              <td>
                <c:choose>
                  <c:when test="${meter.runStatus == '正常'}">
                    <span class="status-badge normal">正常</span>
                  </c:when>
                  <c:otherwise>
                    <span class="status-badge warning">故障</span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${meter.calibCycleMonths}" default="-"/> 个月</td>
              <td>
                <a class="action-btn secondary" href="${ctx}/app?module=energy&view=meter_detail&id=${meter.meterId}">详情</a>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty meters}">
            <tr>
              <td colspan="8" style="text-align:center;color:#94a3b8;">暂无计量设备数据</td>
            </tr>
          </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<%-- 新增设备弹窗 --%>
<div id="addMeterModal" class="modal-overlay" style="display:none;">
  <div class="modal-content">
    <div class="modal-header">
      <h3>新增计量设备</h3>
      <button type="button" class="modal-close" onclick="closeAddMeterModal()">&times;</button>
    </div>
    <form method="post" action="${ctx}/app" id="addMeterForm">
      <input type="hidden" name="module" value="energy"/>
      <input type="hidden" name="action" value="create_meter"/>
      
      <div class="modal-body">
        <div class="form-group">
          <label class="form-label required">能源类型</label>
          <select name="energyType" class="form-select" required>
            <option value="">请选择能源类型</option>
            <option value="电">电</option>
            <option value="水">水</option>
            <option value="蒸汽">蒸汽</option>
            <option value="天然气">天然气</option>
          </select>
        </div>
        
        <div class="form-group">
          <label class="form-label required">所属厂区</label>
          <select name="factoryId" class="form-select" required>
            <option value="">请选择厂区</option>
            <c:forEach items="${factories}" var="factory">
              <option value="${factory.factoryId}">${factory.factoryName}</option>
            </c:forEach>
          </select>
        </div>
        
        <div class="form-group">
          <label class="form-label required">安装位置</label>
          <input type="text" name="installLocation" class="form-input" placeholder="请输入安装位置" required/>
        </div>
        
        <div class="form-group">
          <label class="form-label">通讯协议</label>
          <select name="commProtocol" class="form-select">
            <option value="">请选择通讯协议</option>
            <option value="RS485">RS485</option>
            <option value="Lora">Lora</option>
            <option value="Modbus">Modbus</option>
            <option value="TCP/IP">TCP/IP</option>
          </select>
        </div>
        
        <div class="form-group">
          <label class="form-label">校准周期（月）</label>
          <input type="number" name="calibCycleMonths" class="form-input" placeholder="如：12" min="1" max="120"/>
        </div>
        
        <div class="form-group">
          <label class="form-label">生产厂家</label>
          <input type="text" name="manufacturer" class="form-input" placeholder="请输入生产厂家"/>
        </div>
      </div>
      
      <div class="modal-footer">
        <button type="button" class="action-btn" onclick="closeAddMeterModal()">取消</button>
        <button type="submit" class="action-btn primary">确认新增</button>
      </div>
    </form>
  </div>
</div>

<style>
/* 弹窗样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #fff;
  border-radius: 12px;
  width: 500px;
  max-width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
  color: #1e293b;
}

.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: #64748b;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.modal-close:hover {
  color: #1e293b;
}

.modal-body {
  padding: 24px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px;
  border-top: 1px solid #e2e8f0;
  background: #f8fafc;
  border-radius: 0 0 12px 12px;
}

/* 表单样式 */
.form-group {
  margin-bottom: 16px;
}

.form-label {
  display: block;
  margin-bottom: 6px;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
}

.form-label.required::after {
  content: " *";
  color: #ef4444;
}

.form-input,
.form-select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  color: #1f2937;
  background: #fff;
  transition: border-color 0.2s, box-shadow 0.2s;
  box-sizing: border-box;
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-input::placeholder {
  color: #9ca3af;
}
</style>

<script>
// 1. 专门用于测试的打印，按F12看控制台有没有这句话，证明脚本加载了
console.log("Meter List Script Loaded!");

function openAddMeterModal() {
  console.log("点击了新增按钮"); // 测试点击是否有反应
  var modal = document.getElementById('addMeterModal');
  if (modal) {
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
  } else {
    alert("错误：找不到弹窗元素，请检查 ID 是否为 addMeterModal");
  }
}

function closeAddMeterModal() {
  var modal = document.getElementById('addMeterModal');
  if (modal) {
    modal.style.display = 'none';
    document.body.style.overflow = '';
    // 重置表单
    document.getElementById('addMeterForm').reset();
  }
}

// 确保 DOM 加载完毕后再绑定事件
document.addEventListener("DOMContentLoaded", function() {
    
    // 点击弹窗外部区域关闭弹窗
    var modal = document.getElementById('addMeterModal');
    if(modal) {
        modal.addEventListener('click', function(e) {
          if (e.target === this) {
            closeAddMeterModal();
          }
        });
    }

    // ESC键关闭弹窗
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        closeAddMeterModal();
      }
    });

    // 表单验证
    var form = document.getElementById('addMeterForm');
    if(form) {
        form.addEventListener('submit', function(e) {
          var energyType = this.querySelector('select[name="energyType"]').value;
          var factoryId = this.querySelector('select[name="factoryId"]').value;
          var installLocation = this.querySelector('input[name="installLocation"]').value.trim();
          
          if (!energyType || !factoryId || !installLocation) {
            e.preventDefault();
            alert('请填写所有必填字段（能源类型、厂区、安装位置）');
            return false;
          }
          return true;
        });
    }
});
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>