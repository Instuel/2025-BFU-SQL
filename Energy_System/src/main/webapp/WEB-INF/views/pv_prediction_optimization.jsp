<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>光伏预测优化</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/pv-manage.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <jsp:include page="/WEB-INF/views/common/header.jsp" />
    
    <div class="page-header">
        <h1>光伏预测优化</h1>
        <p>对比光伏预测数据与实际数据，计算偏差率，优化预测模型版本</p>
    </div>

    <div class="content-container">
        <div class="sidebar">
            <div class="sidebar-title">筛选条件</div>
            
            <div class="filter-group">
                <label class="filter-label">并网点</label>
                <select class="filter-select" id="pointSelect">
                    <option value="">全部并网点</option>
                </select>
            </div>

            <div class="filter-group">
                <label class="filter-label">模型版本</label>
                <select class="filter-select" id="modelVersionSelect">
                    <option value="">全部版本</option>
                </select>
            </div>

            <div class="filter-group">
                <label class="filter-label">开始日期</label>
                <input type="date" class="filter-date" id="startDate">
            </div>

            <div class="filter-group">
                <label class="filter-label">结束日期</label>
                <input type="date" class="filter-date" id="endDate">
            </div>

            <div class="filter-group">
                <label class="filter-label">时间段</label>
                <select class="filter-select" id="timeSlotSelect">
                    <option value="">全部时间段</option>
                    <option value="00:00-04:00">00:00-04:00</option>
                    <option value="04:00-08:00">04:00-08:00</option>
                    <option value="08:00-12:00">08:00-12:00</option>
                    <option value="12:00-16:00">12:00-16:00</option>
                    <option value="16:00-20:00">16:00-20:00</option>
                    <option value="20:00-24:00">20:00-24:00</option>
                </select>
            </div>

            <button class="filter-btn" onclick="applyFilters()">应用筛选</button>
            <button class="filter-btn" style="background: #fff; color: #333; border: 1px solid #d9d9d9;" onclick="resetFilters()">重置</button>
        </div>

        <div class="main-content">
            <div class="stats-cards">
                <div class="stat-card">
                    <div class="stat-label">预测准确率</div>
                    <div class="stat-value" id="accuracy">91.5%</div>
                    <div class="stat-trend">↑ 2.3% 较上周</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">平均偏差率</div>
                    <div class="stat-value" id="avgDeviation">8.5%</div>
                    <div class="stat-trend down">↓ 1.2% 较上周</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">最大偏差</div>
                    <div class="stat-value" id="maxDeviation">15.2%</div>
                    <div class="stat-trend down">↓ 3.5% 较上周</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">预测样本数</div>
                    <div class="stat-value" id="sampleCount">1,248</div>
                    <div class="stat-trend">↑ 156 较上周</div>
                </div>
            </div>

            <div class="chart-section">
                <div class="chart-header">
                    <div class="chart-title">预测值 vs 实际值对比</div>
                    <div class="chart-actions">
                        <button class="chart-action-btn" onclick="exportChart()">导出图表</button>
                        <button class="chart-action-btn" onclick="refreshChart()">刷新</button>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="comparisonChart"></canvas>
                </div>
            </div>

            <div class="deviation-table">
                <div class="table-header">
                    <div class="table-title">偏差率明细</div>
                    <div class="chart-actions">
                        <button class="chart-action-btn" onclick="exportTable()">导出表格</button>
                    </div>
                </div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>日期</th>
                            <th>时间段</th>
                            <th>并网点</th>
                            <th>预测值 (kWh)</th>
                            <th>实际值 (kWh)</th>
                            <th>偏差率</th>
                            <th>模型版本</th>
                        </tr>
                    </thead>
                    <tbody id="deviationTableBody">
                    </tbody>
                </table>
            </div>

            <div class="model-info">
                <div class="model-header">
                    <div class="model-title">当前模型信息</div>
                    <button class="optimize-btn" onclick="optimizeModel()">优化模型</button>
                </div>
                <div class="model-details">
                    <div class="model-detail-item">
                        <div class="detail-label">模型版本</div>
                        <div class="detail-value" id="currentModelVersion">v2.1</div>
                    </div>
                    <div class="model-detail-item">
                        <div class="detail-label">模型名称</div>
                        <div class="detail-value" id="modelName">LSTM-Enhanced</div>
                    </div>
                    <div class="model-detail-item">
                        <div class="detail-label">状态</div>
                        <div class="detail-value" id="modelStatus">运行中</div>
                    </div>
                    <div class="model-detail-item">
                        <div class="detail-label">最后更新</div>
                        <div class="detail-value" id="lastUpdate">2024-01-15</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let comparisonChart;

        function initChart() {
            const ctx = document.getElementById('comparisonChart').getContext('2d');
            comparisonChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [
                        {
                            label: '预测值',
                            data: [],
                            borderColor: '#667eea',
                            backgroundColor: 'rgba(102, 126, 234, 0.1)',
                            fill: true,
                            tension: 0.4
                        },
                        {
                            label: '实际值',
                            data: [],
                            borderColor: '#52c41a',
                            backgroundColor: 'rgba(82, 196, 26, 0.1)',
                            fill: true,
                            tension: 0.4
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'top',
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: '发电量 (kWh)'
                            }
                        }
                    }
                }
            });
        }

        function loadPredictionData() {
            const params = new URLSearchParams();
            const pointId = document.getElementById('pointSelect').value;
            const modelVersion = document.getElementById('modelVersionSelect').value;
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;
            const timeSlot = document.getElementById('timeSlotSelect').value;

            if (pointId) params.append('pointId', pointId);
            if (modelVersion) params.append('modelVersion', modelVersion);
            if (startDate) params.append('startDate', startDate);
            if (endDate) params.append('endDate', endDate);
            if (timeSlot) params.append('timeSlot', timeSlot);

            fetch(`${pageContext.request.contextPath}/api/analysis/pv-prediction?${params}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updateStats(data.data.stats);
                        updateChart(data.data.chartData);
                        updateTable(data.data.tableData);
                        updateModelInfo(data.data.modelInfo);
                    }
                })
                .catch(error => {
                    console.error('加载预测数据失败:', error);
                });
        }

        function updateStats(stats) {
            document.getElementById('accuracy').textContent = stats.accuracy + '%';
            document.getElementById('avgDeviation').textContent = stats.avgDeviation + '%';
            document.getElementById('maxDeviation').textContent = stats.maxDeviation + '%';
            document.getElementById('sampleCount').textContent = stats.sampleCount.toLocaleString();
        }

        function updateChart(chartData) {
            comparisonChart.data.labels = chartData.labels;
            comparisonChart.data.datasets[0].data = chartData.forecastValues;
            comparisonChart.data.datasets[1].data = chartData.actualValues;
            comparisonChart.update();
        }

        function updateTable(tableData) {
            const tbody = document.getElementById('deviationTableBody');
            tbody.innerHTML = '';

            tableData.forEach(row => {
                const deviation = row.deviation;
                let badgeClass = 'low';
                if (deviation > 5) badgeClass = 'medium';
                if (deviation > 10) badgeClass = 'high';

                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${row.date}</td>
                    <td>${row.timeSlot}</td>
                    <td>${row.pointName}</td>
                    <td>${row.forecastVal.toFixed(2)}</td>
                    <td>${row.actualVal.toFixed(2)}</td>
                    <td><span class="deviation-badge ${badgeClass}">${deviation.toFixed(1)}%</span></td>
                    <td>${row.modelVersion}</td>
                `;
                tbody.appendChild(tr);
            });
        }

        function updateModelInfo(modelInfo) {
            document.getElementById('currentModelVersion').textContent = modelInfo.modelVersion;
            document.getElementById('modelName').textContent = modelInfo.modelName;
            document.getElementById('modelStatus').textContent = modelInfo.status;
            document.getElementById('lastUpdate').textContent = modelInfo.updateTime;
        }

        function loadFilterOptions() {
            fetch(`${pageContext.request.contextPath}/api/analysis/pv-prediction/filters`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        populatePointSelect(data.data.points);
                        populateModelVersionSelect(data.data.modelVersions);
                    }
                })
                .catch(error => {
                    console.error('加载筛选选项失败:', error);
                });
        }

        function populatePointSelect(points) {
            const select = document.getElementById('pointSelect');
            points.forEach(point => {
                const option = document.createElement('option');
                option.value = point.pointId;
                option.textContent = point.pointName;
                select.appendChild(option);
            });
        }

        function populateModelVersionSelect(versions) {
            const select = document.getElementById('modelVersionSelect');
            versions.forEach(version => {
                const option = document.createElement('option');
                option.value = version;
                option.textContent = version;
                select.appendChild(option);
            });
        }

        function applyFilters() {
            loadPredictionData();
        }

        function resetFilters() {
            document.getElementById('pointSelect').value = '';
            document.getElementById('modelVersionSelect').value = '';
            document.getElementById('startDate').value = '';
            document.getElementById('endDate').value = '';
            document.getElementById('timeSlotSelect').value = '';
            loadPredictionData();
        }

        function refreshChart() {
            loadPredictionData();
        }

        function exportChart() {
            alert('导出图表功能开发中...');
        }

        function exportTable() {
            alert('导出表格功能开发中...');
        }

        function optimizeModel() {
            if (confirm('确定要优化预测模型吗？此操作可能需要较长时间。')) {
                fetch(`${pageContext.request.contextPath}/api/analysis/pv-prediction/optimize`, {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('模型优化任务已启动，请稍后查看结果。');
                    } else {
                        alert('模型优化失败: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('模型优化失败:', error);
                    alert('模型优化失败，请稍后重试。');
                });
            }
        }

        window.onload = function() {
            initChart();
            loadFilterOptions();
            loadPredictionData();
        };
    </script>
</body>
</html>