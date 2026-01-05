<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div class="report-container">
    <div class="report-header">
      <h1>综合能耗管理 / 日能耗成本报告</h1>
      <p>自动汇总峰谷能耗、成本与节能建议,支持按厂区与能源类型对比。</p>
    </div>

    <a class="back-btn" href="${ctx}/app?module=energy&view=meter_list">← 返回综合能耗首页</a>

    <div class="filter-section">
      <div class="filter-bar">
        <span class="filter-label">统计周期</span>
        <select class="filter-select" id="period">
          <option value="日" selected>日</option>
          <option value="周">周</option>
          <option value="月">月</option>
        </select>
        <span class="filter-label">能源类型</span>
        <select class="filter-select" id="energyType">
          <option value="">全部</option>
          <option value="电">电</option>
          <option value="水">水</option>
          <option value="蒸汽">蒸汽</option>
          <option value="天然气">天然气</option>
        </select>
        <span class="filter-label">厂区</span>
        <select class="filter-select" id="factoryId">
          <option value="">全部厂区</option>
          <c:forEach items="${factories}" var="factory">
            <option value="${factory.factoryId}">${factory.factoryName}</option>
          </c:forEach>
        </select>
        <input class="date-input" type="date" id="reportDate"/>
        <button class="action-btn primary" onclick="generateReport()">生成报告</button>
        <button class="action-btn" onclick="exportPDF()">导出 PDF</button>
      </div>
    </div>

    <!-- 报告生成状态提示 -->
    <div id="statusMessage" style="display:none; padding:12px; margin:16px 0; border-radius:8px; font-size:14px;"></div>

    <div class="stats-grid">
      <div class="stat-card cost">
        <div class="stat-label">当日能耗成本</div>
        <div class="stat-value" id="totalCostDisplay">¥ <c:out value="${reportStats.totalCost}" default="--"/></div>
        <div class="stat-sub">最近统计日汇总</div>
      </div>
      <div class="stat-card savings">
        <div class="stat-label">低谷能耗</div>
        <div class="stat-value" id="valleyConsumptionDisplay"><c:out value="${reportStats.valleyConsumption}" default="--"/></div>
        <div class="stat-sub">低谷时段累计</div>
      </div>
      <div class="stat-card efficiency">
        <div class="stat-label">总能耗</div>
        <div class="stat-value" id="totalConsumptionDisplay"><c:out value="${reportStats.totalConsumption}" default="--"/></div>
        <div class="stat-sub">统计周期总量</div>
      </div>
    </div>

    <div class="content-grid">
      <div>
        <div class="report-section">
          <div class="section-title">厂区能耗成本对比</div>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>厂区</th>
                <th>能源类型</th>
                <th>统计日期</th>
                <th>总能耗</th>
                <th>总成本 (元)</th>
              </tr>
              </thead>
              <tbody id="reportTableBody">
              <c:forEach items="${reportItems}" var="item">
                <tr>
                  <td>${item.factoryName}</td>
                  <td>${item.energyType}</td>
                  <td>${item.statDate}</td>
                  <td><c:out value="${item.totalConsumption}" default="-"/></td>
                  <td><c:out value="${item.totalCost}" default="-"/></td>
                </tr>
              </c:forEach>
              <c:if test="${empty reportItems}">
                <tr>
                  <td colspan="5" style="text-align:center;color:#94a3b8;">暂无峰谷成本数据</td>
                </tr>
              </c:if>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div>
        <div class="report-section">
          <div class="section-title">报告摘要</div>
          <div class="report-list" id="reportSummaryList">
            <c:forEach items="${reportItems}" var="item" varStatus="status">
              <c:if test="${status.index < 3}">
                <div class="report-item">
                  <div class="report-title">峰谷统计摘要</div>
                  <div class="report-meta">${item.factoryName} · ${item.statDate}</div>
                  <div class="report-summary">总能耗 ${item.totalConsumption},成本 ${item.totalCost} 元。</div>
                  <span class="report-status completed">已生成</span>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${empty reportItems}">
              <div class="report-item">
                <div class="report-title">暂无报告摘要</div>
                <div class="report-meta">请先生成峰谷统计数据</div>
                <div class="report-summary">当前没有可用的数据摘要。</div>
                <span class="report-status pending">待生成</span>
              </div>
            </c:if>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
// 设置默认日期为今天
document.getElementById('reportDate').valueAsDate = new Date();

// 生成报告函数
function generateReport() {
    const period = document.getElementById('period').value;
    const energyType = document.getElementById('energyType').value;
    const factoryId = document.getElementById('factoryId').value;
    const date = document.getElementById('reportDate').value;
    
    // 显示加载状态
    showStatus('正在生成报告...', 'info');
    
    // 构建请求URL
    const params = new URLSearchParams({
        action: 'generateReport',
        period: period,
        energyType: energyType,
        factoryId: factoryId,
        date: date
    });
    
    // 发送AJAX请求
    fetch('${ctx}/energyReport?' + params.toString())
        .then(response => {
            if (!response.ok) {
                throw new Error('请求失败: ' + response.status);
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                // 更新统计卡片
                document.getElementById('totalCostDisplay').textContent = '¥ ' + data.totalCost;
                document.getElementById('valleyConsumptionDisplay').textContent = data.valleyConsumption;
                document.getElementById('totalConsumptionDisplay').textContent = data.totalConsumption;
                
                // 显示成功消息
                showStatus('报告生成成功! ' + data.suggestion, 'success');
                
                // 刷新数据表格
                loadReportData(energyType, factoryId);
            } else {
                showStatus('报告生成失败', 'error');
            }
        })
        .catch(error => {
            console.error('生成报告出错:', error);
            showStatus('生成报告失败: ' + error.message, 'error');
        });
}

// 导出PDF函数
function exportPDF() {
    const period = document.getElementById('period').value;
    const energyType = document.getElementById('energyType').value;
    const factoryId = document.getElementById('factoryId').value;
    const date = document.getElementById('reportDate').value;
    
    // 显示导出状态
    showStatus('正在生成PDF文件...', 'info');
    
    // 构建下载URL
    const params = new URLSearchParams({
        action: 'exportPDF',
        period: period,
        energyType: energyType,
        factoryId: factoryId,
        date: date
    });
    
    // 使用隐藏的iframe下载PDF
    const downloadUrl = '${ctx}/energyReport?' + params.toString();
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = downloadUrl;
    document.body.appendChild(iframe);
    
    // 显示成功消息
    setTimeout(() => {
        showStatus('PDF文件已开始下载', 'success');
        // 2秒后移除iframe
        setTimeout(() => {
            document.body.removeChild(iframe);
        }, 2000);
    }, 500);
}

// 加载报告数据
function loadReportData(energyType, factoryId) {
    const params = new URLSearchParams({
        action: 'getReportData',
        energyType: energyType || '',
        factoryId: factoryId || ''
    });
    
    fetch('${ctx}/energyReport?' + params.toString())
        .then(response => response.json())
        .then(data => {
            updateReportTable(data);
        })
        .catch(error => {
            console.error('加载数据出错:', error);
        });
}

// 更新报告表格
function updateReportTable(data) {
    const tbody = document.getElementById('reportTableBody');
    
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:#94a3b8;">暂无峰谷成本数据</td></tr>';
        return;
    }
    
    let html = '';
    data.forEach(item => {
        html += '<tr>';
        html += '<td>' + (item.factoryName || '-') + '</td>';
        html += '<td>' + (item.energyType || '-') + '</td>';
        html += '<td>' + (item.statDate || '-') + '</td>';
        html += '<td>' + (item.totalConsumption || '-') + '</td>';
        html += '<td>' + (item.totalCost || '-') + '</td>';
        html += '</tr>';
    });
    tbody.innerHTML = html;
}

// 显示状态消息
function showStatus(message, type) {
    const statusDiv = document.getElementById('statusMessage');
    statusDiv.style.display = 'block';
    statusDiv.textContent = message;
    
    // 根据类型设置样式
    if (type === 'success') {
        statusDiv.style.backgroundColor = '#d1fae5';
        statusDiv.style.color = '#065f46';
        statusDiv.style.border = '1px solid #10b981';
    } else if (type === 'error') {
        statusDiv.style.backgroundColor = '#fee2e2';
        statusDiv.style.color = '#991b1b';
        statusDiv.style.border = '1px solid #ef4444';
    } else { // info
        statusDiv.style.backgroundColor = '#dbeafe';
        statusDiv.style.color = '#1e40af';
        statusDiv.style.border = '1px solid #3b82f6';
    }
    
    // 3秒后自动隐藏
    setTimeout(() => {
        statusDiv.style.display = 'none';
    }, 3000);
}
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
