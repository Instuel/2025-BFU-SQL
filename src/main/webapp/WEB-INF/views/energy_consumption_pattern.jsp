<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>能耗规律挖掘</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/energy-stats.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <jsp:include page="/WEB-INF/views/common/header.jsp" />
    
    <div class="page-header">
        <h1>能耗规律挖掘</h1>
        <p>分析产线能耗与产量的关联关系，生成季度能源成本分析报告</p>
    </div>

    <div class="content-container">
        <div class="sidebar">
            <div class="sidebar-title">筛选条件</div>
            
            <div class="filter-group">
                <label class="filter-label">厂区</label>
                <select class="filter-select" id="factorySelect">
                    <option value="">全部厂区</option>
                </select>
            </div>

            <div class="filter-group">
                <label class="filter-label">能源类型</label>
                <select class="filter-select" id="energyTypeSelect">
                    <option value="">全部类型</option>
                    <option value="电">电</option>
                    <option value="水">水</option>
                    <option value="气">气</option>
                </select>
            </div>

            <div class="filter-group">
                <label class="filter-label">统计周期</label>
                <select class="filter-select" id="statCycleSelect">
                    <option value="日">日</option>
                    <option value="周">周</option>
                    <option value="月">月</option>
                    <option value="季">季</option>
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

            <button class="filter-btn" onclick="applyFilters()">应用筛选</button>
            <button class="filter-btn" style="background: #fff; color: #333; border: 1px solid #d9d9d9;" onclick="resetFilters()">重置</button>
        </div>

        <div class="main-content">
            <div class="stats-cards">
                <div class="stat-card">
                    <div class="stat-label">能耗产量关联度</div>
                    <div class="stat-value" id="correlation">0.85</div>
                    <div class="stat-trend">↑ 0.03 较上季度</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">单位产量能耗</div>
                    <div class="stat-value" id="unitEnergy">2.45</div>
                    <div class="stat-trend down">↓ 0.12 较上季度</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">总能耗</div>
                    <div class="stat-value" id="totalEnergy">12.5万</div>
                    <div class="stat-trend">↑ 5.2% 较上季度</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">总产量</div>
                    <div class="stat-value" id="totalProduction">5.1万</div>
                    <div class="stat-trend">↑ 8.7% 较上季度</div>
                </div>
            </div>

            <div class="chart-grid">
                <div class="chart-section">
                    <div class="chart-header">
                        <div class="chart-title">能耗趋势</div>
                        <div class="chart-actions">
                            <button class="chart-action-btn" onclick="exportChart('energy')">导出</button>
                        </div>
                    </div>
                    <div class="chart-container">
                        <canvas id="energyChart"></canvas>
                    </div>
                </div>

                <div class="chart-section">
                    <div class="chart-header">
                        <div class="chart-title">产量趋势</div>
                        <div class="chart-actions">
                            <button class="chart-action-btn" onclick="exportChart('production')">导出</button>
                        </div>
                    </div>
                    <div class="chart-container">
                        <canvas id="productionChart"></canvas>
                    </div>
                </div>
            </div>

            <div class="chart-section">
                <div class="chart-header">
                    <div class="chart-title">能耗与产量关联分析</div>
                    <div class="chart-actions">
                        <button class="chart-action-btn" onclick="exportChart('correlation')">导出</button>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="correlationChart"></canvas>
                </div>
            </div>

            <div class="analysis-table">
                <div class="table-header">
                    <div class="table-title">能耗产量关联度分析</div>
                    <div class="chart-actions">
                        <button class="chart-action-btn" onclick="exportTable()">导出表格</button>
                    </div>
                </div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>厂区</th>
                            <th>能源类型</th>
                            <th>关联度</th>
                            <th>单位产量能耗</th>
                            <th>能耗增长率</th>
                            <th>产量增长率</th>
                            <th>分析结论</th>
                        </tr>
                    </thead>
                    <tbody id="analysisTableBody">
                    </tbody>
                </table>
            </div>

            <div class="report-section">
                <div class="report-header">
                    <div class="report-title">季度能源成本分析报告</div>
                    <button class="generate-btn" onclick="generateReport()">生成报告</button>
                </div>
                <div class="report-content" id="reportContent">
                </div>
            </div>
        </div>
    </div>

    <script>
        let energyChart, productionChart, correlationChart;

        function initCharts() {
            const energyCtx = document.getElementById('energyChart').getContext('2d');
            energyChart = new Chart(energyCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: '能耗 (kWh)',
                        data: [],
                        borderColor: '#f093fb',
                        backgroundColor: 'rgba(240, 147, 251, 0.1)',
                        fill: true,
                        tension: 0.4
                    }]
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
                                text: '能耗 (kWh)'
                            }
                        }
                    }
                }
            });

            const productionCtx = document.getElementById('productionChart').getContext('2d');
            productionChart = new Chart(productionCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: '产量 (件)',
                        data: [],
                        borderColor: '#f5576c',
                        backgroundColor: 'rgba(245, 87, 108, 0.1)',
                        fill: true,
                        tension: 0.4
                    }]
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
                                text: '产量 (件)'
                            }
                        }
                    }
                }
            });

            const correlationCtx = document.getElementById('correlationChart').getContext('2d');
            correlationChart = new Chart(correlationCtx, {
                type: 'scatter',
                data: {
                    datasets: [{
                        label: '能耗 vs 产量',
                        data: [],
                        backgroundColor: 'rgba(240, 147, 251, 0.6)',
                        borderColor: '#f093fb',
                        pointRadius: 6,
                        pointHoverRadius: 8
                    }]
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
                        x: {
                            title: {
                                display: true,
                                text: '产量 (件)'
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: '能耗 (kWh)'
                            }
                        }
                    }
                }
            });
        }

        function loadAnalysisData() {
            const params = new URLSearchParams();
            const factoryId = document.getElementById('factorySelect').value;
            const energyType = document.getElementById('energyTypeSelect').value;
            const statCycle = document.getElementById('statCycleSelect').value;
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;

            if (factoryId) params.append('factoryId', factoryId);
            if (energyType) params.append('energyType', energyType);
            if (statCycle) params.append('statCycle', statCycle);
            if (startDate) params.append('startDate', startDate);
            if (endDate) params.append('endDate', endDate);

            fetch(`${pageContext.request.contextPath}/api/analysis/energy-pattern?${params}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updateStats(data.data.stats);
                        updateCharts(data.data.chartData);
                        updateTable(data.data.tableData);
                        updateReports(data.data.reports);
                    }
                })
                .catch(error => {
                    console.error('加载分析数据失败:', error);
                });
        }

        function updateStats(stats) {
            document.getElementById('correlation').textContent = stats.correlation;
            document.getElementById('unitEnergy').textContent = stats.unitEnergy;
            document.getElementById('totalEnergy').textContent = stats.totalEnergy;
            document.getElementById('totalProduction').textContent = stats.totalProduction;
        }

        function updateCharts(chartData) {
            energyChart.data.labels = chartData.labels;
            energyChart.data.datasets[0].data = chartData.energyData;
            energyChart.update();

            productionChart.data.labels = chartData.labels;
            productionChart.data.datasets[0].data = chartData.productionData;
            productionChart.update();

            correlationChart.data.datasets[0].data = chartData.correlationData;
            correlationChart.update();
        }

        function updateTable(tableData) {
            const tbody = document.getElementById('analysisTableBody');
            tbody.innerHTML = '';

            tableData.forEach(row => {
                const correlation = row.correlation;
                let badgeClass = 'high';
                if (correlation < 0.6) badgeClass = 'low';
                else if (correlation < 0.8) badgeClass = 'medium';

                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${row.factoryName}</td>
                    <td>${row.energyType}</td>
                    <td><span class="correlation-badge ${badgeClass}">${correlation.toFixed(2)}</span></td>
                    <td>${row.unitEnergy.toFixed(2)}</td>
                    <td>${row.energyGrowthRate > 0 ? '+' : ''}${row.energyGrowthRate.toFixed(1)}%</td>
                    <td>${row.productionGrowthRate > 0 ? '+' : ''}${row.productionGrowthRate.toFixed(1)}%</td>
                    <td>${row.conclusion}</td>
                `;
                tbody.appendChild(tr);
            });
        }

        function updateReports(reports) {
            const container = document.getElementById('reportContent');
            container.innerHTML = '';

            reports.forEach(report => {
                const statusClass = report.status === 'completed' ? 'completed' : 'generating';
                const div = document.createElement('div');
                div.className = 'report-item';
                div.innerHTML = `
                    <div class="report-quarter">${report.quarter}</div>
                    <div class="report-date">${report.date}</div>
                    <span class="report-status ${statusClass}">${report.statusText}</span>
                `;
                container.appendChild(div);
            });
        }

        function loadFilterOptions() {
            fetch(`${pageContext.request.contextPath}/api/analysis/energy-pattern/filters`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        populateFactorySelect(data.data.factories);
                    }
                })
                .catch(error => {
                    console.error('加载筛选选项失败:', error);
                });
        }

        function populateFactorySelect(factories) {
            const select = document.getElementById('factorySelect');
            factories.forEach(factory => {
                const option = document.createElement('option');
                option.value = factory.factoryId;
                option.textContent = factory.factoryName;
                select.appendChild(option);
            });
        }

        function applyFilters() {
            loadAnalysisData();
        }

        function resetFilters() {
            document.getElementById('factorySelect').value = '';
            document.getElementById('energyTypeSelect').value = '';
            document.getElementById('statCycleSelect').value = '日';
            document.getElementById('startDate').value = '';
            document.getElementById('endDate').value = '';
            loadAnalysisData();
        }

        function exportChart(type) {
            alert(`导出${type}图表功能开发中...`);
        }

        function exportTable() {
            alert('导出表格功能开发中...');
        }

        function generateReport() {
            if (confirm('确定要生成季度能源成本分析报告吗？')) {
                fetch(`${pageContext.request.contextPath}/api/analysis/energy-pattern/generate-report`, {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('报告生成任务已启动，请稍后在报告列表中查看。');
                        loadAnalysisData();
                    } else {
                        alert('报告生成失败: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('报告生成失败:', error);
                    alert('报告生成失败，请稍后重试。');
                });
            }
        }

        window.onload = function() {
            initCharts();
            loadFilterOptions();
            loadAnalysisData();
        };
    </script>
</body>
</html>