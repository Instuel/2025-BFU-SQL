<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>能耗总结报告</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/energy-stats.css">
</head>
<body>
    <div class="report-container">
        <div class="report-header">
            <button class="back-btn" onclick="window.location.href='${pageContext.request.contextPath}/executive/dashboard'">
                ← 返回工作台
            </button>
            <h1>能耗总结报告</h1>
            <p>查看月度/季度总结报告，评估"降本增效"目标完成情况</p>
        </div>

        <div class="filter-section">
            <div class="filter-bar">
                <span class="filter-label">报告类型:</span>
                <select class="filter-select" id="reportType" onchange="loadReportData()">
                    <option value="monthly">月度报告</option>
                    <option value="quarterly">季度报告</option>
                </select>

                <span class="filter-label">时间范围:</span>
                <select class="filter-select" id="timePeriod" onchange="loadReportData()">
                    <option value="current">当前</option>
                    <option value="last">上一期</option>
                </select>

                <span class="filter-label">年份:</span>
                <select class="filter-select" id="year" onchange="loadReportData()">
                    <option value="2024">2024</option>
                    <option value="2023">2023</option>
                </select>

                <button class="btn btn-primary" onclick="loadReportData()">查询</button>
                <button class="btn btn-secondary" onclick="resetFilters()">重置</button>
                <button class="btn btn-success" onclick="exportReport()">导出报告</button>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card cost">
                <div class="stat-label">总成本</div>
                <div class="stat-value" id="totalCost">--</div>
                <div class="stat-sub" id="costChange">较上期: --</div>
            </div>

            <div class="stat-card savings">
                <div class="stat-label">节能收益</div>
                <div class="stat-value" id="savings">--</div>
                <div class="stat-sub" id="savingsChange">较上期: --</div>
            </div>

            <div class="stat-card efficiency">
                <div class="stat-label">能效提升</div>
                <div class="stat-value" id="efficiency">--</div>
                <div class="stat-sub" id="efficiencyChange">较上期: --</div>
            </div>
        </div>

        <div class="content-grid">
            <div class="main-content">
                <div class="report-section">
                    <div class="section-title">
                        <span>能耗趋势分析</span>
                    </div>
                    <div class="chart-container" id="energyTrendChart">
                        能耗趋势图表
                    </div>
                </div>

                <div class="report-section">
                    <div class="section-title">
                        <span>成本对比分析</span>
                    </div>
                    <div class="comparison-table">
                        <div class="comparison-row">
                            <div class="comparison-label">电费成本</div>
                            <div class="comparison-value" id="electricityCost">--</div>
                            <div class="comparison-change" id="electricityCostChange">--</div>
                        </div>
                        <div class="comparison-row">
                            <div class="comparison-label">光伏收益</div>
                            <div class="comparison-value" id="pvRevenue">--</div>
                            <div class="comparison-change" id="pvRevenueChange">--</div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="side-content">
                <div class="report-section">
                    <div class="section-title">
                        <span>报告列表</span>
                        <button class="btn btn-secondary" onclick="loadReports()">刷新</button>
                    </div>
                    <div class="report-list" id="reportList">
                        <div style="text-align: center; color: #999; padding: 20px;">加载中...</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function loadReportData() {
            const reportType = document.getElementById('reportType').value;
            const timePeriod = document.getElementById('timePeriod').value;
            const year = document.getElementById('year').value;

            fetch(`${pageContext.request.contextPath}/api/executive/report-data?reportType=${reportType}&timePeriod=${timePeriod}&year=${year}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updateReportStats(data.data);
                        updateComparisonData(data.data.comparison);
                    }
                })
                .catch(error => {
                    console.error('加载报告数据失败:', error);
                });
        }

        function updateReportStats(data) {
            document.getElementById('totalCost').textContent = data.totalCost || '--';
            document.getElementById('savings').textContent = data.savings || '--';
            document.getElementById('efficiency').textContent = data.efficiency || '--';

            document.getElementById('costChange').textContent = `较上期: ${data.costChange || '--'}`;
            document.getElementById('savingsChange').textContent = `较上期: ${data.savingsChange || '--'}`;
            document.getElementById('efficiencyChange').textContent = `较上期: ${data.efficiencyChange || '--'}`;
        }

        function updateComparisonData(comparison) {
            if (comparison) {
                updateComparisonItem('electricityCost', comparison.electricityCost);
                updateComparisonItem('pvRevenue', comparison.pvRevenue);
            }
        }

        function updateComparisonItem(id, data) {
            document.getElementById(`${id}`).textContent = data.value || '--';
            const changeElement = document.getElementById(`${id}Change`);
            if (data.change) {
                const isPositive = data.change >= 0;
                changeElement.className = 'comparison-change ' + (isPositive ? 'positive' : 'negative');
                changeElement.textContent = (isPositive ? '+' : '') + data.change + '%';
            }
        }

        function loadReports() {
            fetch('${pageContext.request.contextPath}/api/executive/reports')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const reportList = document.getElementById('reportList');
                        if (data.data.length === 0) {
                            reportList.innerHTML = '<div style="text-align: center; color: #999; padding: 20px;">暂无报告</div>';
                        } else {
                            reportList.innerHTML = data.data.map(report => `
                                <div class="report-item" onclick="viewReport('${report.id}')">
                                    <div class="report-title">${report.title}</div>
                                    <div class="report-meta">
                                        <span class="report-status ${report.statusClass}">${report.statusText}</span>
                                        <span> | ${report.period}</span>
                                        <span> | ${report.createTime}</span>
                                    </div>
                                    <div class="report-summary">${report.summary}</div>
                                </div>
                            `).join('');
                        }
                    }
                })
                .catch(error => {
                    console.error('加载报告列表失败:', error);
                });
        }

        function viewReport(reportId) {
            alert(`查看报告详情: ${reportId}`);
        }

        function resetFilters() {
            document.getElementById('reportType').value = 'monthly';
            document.getElementById('timePeriod').value = 'current';
            document.getElementById('year').value = '2024';
            loadReportData();
        }

        function exportReport() {
            alert('报告导出功能正在开发中...');
        }

        window.onload = function() {
            loadReportData();
            loadReports();
        };
    </script>
</body>
</html>