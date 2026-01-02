<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>决策总览</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="overview-container">
        <div class="overview-header">
            <button class="back-btn" onclick="window.location.href='${pageContext.request.contextPath}/executive/dashboard'">
                ← 返回工作台
            </button>
            <h1>决策总览</h1>
            <p>查看能源总览、光伏收益及高等级告警</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card energy">
                <div class="stat-label">总能耗</div>
                <div class="stat-value" id="totalEnergy">--</div>
                <div class="stat-change" id="energyChange">
                    <span>--</span>
                </div>
            </div>

            <div class="stat-card pv">
                <div class="stat-label">光伏收益</div>
                <div class="stat-value" id="pvRevenue">--</div>
                <div class="stat-change" id="revenueChange">
                    <span>--</span>
                </div>
            </div>

            <div class="stat-card alarm">
                <div class="stat-label">高等级告警</div>
                <div class="stat-value" id="highAlarms">--</div>
                <div class="stat-change" id="alarmChange">
                    <span>--</span>
                </div>
            </div>
        </div>

        <div class="content-grid">
            <div class="main-content">
                <div class="chart-section">
                    <div class="section-title">
                        <span>能耗趋势分析</span>
                        <div class="filter-bar">
                            <select class="filter-select" id="timeRange" onchange="loadEnergyTrend()">
                                <option value="week" selected>本周</option>
                                <option value="month">本月</option>
                                <option value="quarter">本季度</option>
                            </select>
                        </div>
                    </div>
                    <div class="chart-container" id="energyTrendChart">
                        能耗趋势图表
                    </div>
                </div>

                <div class="chart-section">
                    <div class="section-title">
                        <span>光伏发电与收益</span>
                    </div>
                    <div class="chart-container" id="pvChart">
                        光伏发电与收益图表
                    </div>
                </div>

                <div class="chart-section">
                    <div class="section-title">
                        <span>能耗溯源分析（按设备）</span>
                    </div>
                    <div class="table-container">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>设备名称</th>
                                    <th>能耗 (kWh)</th>
                                    <th>占比</th>
                                    <th>趋势</th>
                                </tr>
                            </thead>
                            <tbody id="sourceAnalysisTable">
                                <tr>
                                    <td colspan="4" style="text-align: center; color: #999;">加载中...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="side-content">
                <div class="chart-section">
                    <div class="section-title">
                        <span>高等级告警</span>
                        <button class="btn btn-secondary" onclick="loadAlarms()">刷新</button>
                    </div>
                    <div class="filter-bar">
                        <select class="filter-select" id="alarmLevel" onchange="loadAlarms()">
                            <option value="all">全部等级</option>
                            <option value="high" selected>高</option>
                            <option value="medium">中</option>
                            <option value="low">低</option>
                        </select>
                    </div>
                    <div class="alarm-list" id="alarmList">
                        <div style="text-align: center; color: #999; padding: 20px;">加载中...</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function loadOverviewStats() {
            fetch('${pageContext.request.contextPath}/api/executive/overview-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('totalEnergy').textContent = data.data.totalEnergy || '--';
                        document.getElementById('pvRevenue').textContent = data.data.pvRevenue || '--';
                        document.getElementById('highAlarms').textContent = data.data.highAlarms || '--';
                        
                        updateStatChange('energyChange', data.data.energyChange);
                        updateStatChange('revenueChange', data.data.revenueChange);
                        updateStatChange('alarmChange', data.data.alarmChange);
                    }
                })
                .catch(error => {
                    console.error('加载统计数据失败:', error);
                });
        }

        function updateStatChange(elementId, change) {
            const element = document.getElementById(elementId);
            if (change) {
                const isPositive = change >= 0;
                element.className = 'stat-change ' + (isPositive ? 'positive' : 'negative');
                element.innerHTML = (isPositive ? '↑' : '↓') + ' ' + Math.abs(change) + '%';
            }
        }

        function loadEnergyTrend() {
            const timeRange = document.getElementById('timeRange').value;
            fetch(`${pageContext.request.contextPath}/api/executive/energy-trend?timeRange=${timeRange}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('energyTrendChart').innerHTML = 
                            '能耗趋势数据已加载<br>' + JSON.stringify(data.data, null, 2);
                    }
                })
                .catch(error => {
                    console.error('加载能源趋势失败:', error);
                });
        }

        function loadPVData() {
            fetch('${pageContext.request.contextPath}/api/executive/pv-data')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('pvChart').innerHTML = 
                            '光伏发电与收益数据已加载<br>' + JSON.stringify(data.data, null, 2);
                    }
                })
                .catch(error => {
                    console.error('加载光伏数据失败:', error);
                });
        }

        function loadSourceAnalysis() {
            fetch(`${pageContext.request.contextPath}/api/executive/source-analysis`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const tbody = document.getElementById('sourceAnalysisTable');
                        tbody.innerHTML = data.data.map(item => `
                            <tr>
                                <td>${item.name}</td>
                                <td>${item.energy}</td>
                                <td>${item.percentage}</td>
                                <td>${item.trend}</td>
                            </tr>
                        `).join('');
                    }
                })
                .catch(error => {
                    console.error('加载溯源分析失败:', error);
                });
        }

        function loadAlarms() {
            const alarmLevel = document.getElementById('alarmLevel').value;
            fetch(`${pageContext.request.contextPath}/api/executive/alarms?level=${alarmLevel}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const alarmList = document.getElementById('alarmList');
                        if (data.data.length === 0) {
                            alarmList.innerHTML = '<div style="text-align: center; color: #999; padding: 20px;">暂无告警</div>';
                        } else {
                            alarmList.innerHTML = data.data.map(alarm => `
                                <div class="alarm-item">
                                    <span class="alarm-level ${alarm.level}">${alarm.levelText}</span>
                                    <div class="alarm-time">${alarm.time}</div>
                                    <div class="alarm-content">${alarm.content}</div>
                                    <div class="alarm-device">设备: ${alarm.device}</div>
                                </div>
                            `).join('');
                        }
                    }
                })
                .catch(error => {
                    console.error('加载告警列表失败:', error);
                });
        }

        window.onload = function() {
            loadOverviewStats();
            loadEnergyTrend();
            loadPVData();
            loadSourceAnalysis();
            loadAlarms();
        };
    </script>
</body>
</html>