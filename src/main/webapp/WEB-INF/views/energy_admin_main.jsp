<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:if test="${empty sessionScope.user}">
    <c:redirect url="/login"/>
</c:if>
<c:if test="${sessionScope.role != 'ENERGY'}">
    <c:redirect url="/login"/>
</c:if>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>能源管理员工作台 - 智慧能源管理系统</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/energy-stats.css">
</head>
<body>
    <div class="header">
        <h1>能源管理员工作台</h1>
        <div class="header-info">
            <div class="user-info">
                <div class="user-avatar">${sessionScope.realName != null ? sessionScope.realName.substring(0, 1) : 'U'}</div>
                <span>${sessionScope.realName}</span>
            </div>
            <button class="logout-btn" onclick="logout()">退出登录</button>
        </div>
    </div>

    <div class="container">
        <div class="sidebar">
            <ul class="sidebar-menu">
                <li><a href="${pageContext.request.contextPath}/energy/dashboard" class="active"><span class="icon">📊</span>工作台</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/reports"><span class="icon">📈</span>能耗报表</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/peak-valley"><span class="icon">⏰</span>峰谷分析</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/data-audit"><span class="icon">✅</span>数据核实</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/optimization"><span class="icon">🎯</span>节能优化</a></li>
            </ul>
        </div>

        <div class="main-content">
            <div id="alertBox" class="alert-box" style="display: none;">
                <div class="icon">⚠️</div>
                <div class="content">
                    <h4>待处理异常数据</h4>
                    <p id="alertMessage">发现 <span id="alertCount">0</span> 条数据质量差的记录需要核实</p>
                </div>
                <button class="action" onclick="goToDataAudit()">立即处理</button>
            </div>

            <div class="dashboard-grid">
                <div class="stat-card">
                    <h3>今日总用电量</h3>
                    <div class="value" id="todayConsumption">--</div>
                    <div class="trend" id="consumptionTrend">--</div>
                </div>
                <div class="stat-card">
                    <h3>峰谷电费占比</h3>
                    <div class="value" id="peakValleyRatio">--</div>
                    <div class="trend">峰时段: <span id="peakRatio">--</span>%</div>
                </div>
                <div class="stat-card">
                    <h3>异常数据记录</h3>
                    <div class="value" id="abnormalDataCount">--</div>
                    <div class="trend down">待核实</div>
                </div>
                <div class="stat-card">
                    <h3>节能方案执行中</h3>
                    <div class="value" id="activeStrategies">--</div>
                    <div class="trend">个方案</div>
                </div>
            </div>

            <div class="quick-actions">
                <div class="action-card" onclick="goToReports()">
                    <h3>📊 查看能耗报表</h3>
                    <p>查看各区域、各能源类型的详细能耗数据</p>
                </div>
                <div class="action-card" onclick="goToPeakValley()">
                    <h3>⏰ 峰谷分析</h3>
                    <p>分析峰谷时段能耗与成本分布</p>
                </div>
                <div class="action-card" onclick="goToDataAudit()">
                    <h3>✅ 数据核实</h3>
                    <p>处理异常数据记录，提升数据质量</p>
                </div>
                <div class="action-card" onclick="goToOptimization()">
                    <h3>🎯 节能优化</h3>
                    <p>制定和跟踪节能优化方案</p>
                </div>
            </div>

            <div class="section">
                <div class="section-header">
                    <h2>最新能耗数据</h2>
                    <div class="actions">
                        <button class="btn btn-secondary" onclick="refreshData()">刷新</button>
                        <button class="btn btn-primary" onclick="goToReports()">查看全部</button>
                    </div>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>区域</th>
                            <th>能源类型</th>
                            <th>采集时间</th>
                            <th>能耗值</th>
                            <th>单位</th>
                            <th>数据质量</th>
                        </tr>
                    </thead>
                    <tbody id="energyDataTable">
                        <tr>
                            <td colspan="6" class="loading">加载中...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function logout() {
            window.location.href = '${pageContext.request.contextPath}/logout';
        }

        function goToReports() {
            window.location.href = '${pageContext.request.contextPath}/energy/reports';
        }

        function goToPeakValley() {
            window.location.href = '${pageContext.request.contextPath}/energy/peak-valley';
        }

        function goToDataAudit() {
            window.location.href = '${pageContext.request.contextPath}/energy/data-audit';
        }

        function goToOptimization() {
            window.location.href = '${pageContext.request.contextPath}/energy/optimization';
        }

        function refreshData() {
            loadDashboardData();
        }

        function loadDashboardData() {
            axios.get('${pageContext.request.contextPath}/api/energy/dashboard')
                .then(response => {
                    if (response.data.success) {
                        updateDashboard(response.data.data);
                    } else {
                        console.error('加载数据失败:', response.data.message);
                    }
                })
                .catch(error => {
                    console.error('请求失败:', error);
                });
        }

        function updateDashboard(data) {
            if (data.todayConsumption !== undefined) {
                document.getElementById('todayConsumption').textContent = formatNumber(data.todayConsumption);
            }

            if (data.consumptionTrend !== undefined) {
                const trendElement = document.getElementById('consumptionTrend');
                if (data.consumptionTrend > 0) {
                    trendElement.innerHTML = '↑ ' + data.consumptionTrend + '% <span class="up">较昨日</span>';
                    trendElement.classList.add('up');
                } else if (data.consumptionTrend < 0) {
                    trendElement.innerHTML = '↓ ' + Math.abs(data.consumptionTrend) + '% <span class="down">较昨日</span>';
                    trendElement.classList.add('down');
                } else {
                    trendElement.textContent = '与昨日持平';
                }
            }

            if (data.peakValleyRatio !== undefined) {
                document.getElementById('peakValleyRatio').textContent = data.peakValleyRatio + '%';
            }

            if (data.peakRatio !== undefined) {
                document.getElementById('peakRatio').textContent = data.peakRatio;
            }

            if (data.abnormalDataCount !== undefined) {
                document.getElementById('abnormalDataCount').textContent = data.abnormalDataCount;
                if (data.abnormalDataCount > 0) {
                    document.getElementById('alertBox').style.display = 'flex';
                    document.getElementById('alertCount').textContent = data.abnormalDataCount;
                } else {
                    document.getElementById('alertBox').style.display = 'none';
                }
            }

            if (data.activeStrategies !== undefined) {
                document.getElementById('activeStrategies').textContent = data.activeStrategies;
            }

            if (data.recentEnergyData && data.recentEnergyData.length > 0) {
                updateEnergyDataTable(data.recentEnergyData);
            }
        }

        function updateEnergyDataTable(dataList) {
            const tbody = document.getElementById('energyDataTable');
            tbody.innerHTML = '';

            dataList.forEach(function(item) {
                const row = document.createElement('tr');
                const qualityClass = getQualityClass(item.quality);
                const qualityText = getQualityText(item.quality);

                row.innerHTML = '<td>' + (item.factoryName || '--') + '</td>' +
                    '<td>' + (item.energyType || '--') + '</td>' +
                    '<td>' + formatDateTime(item.collectTime) + '</td>' +
                    '<td>' + formatNumber(item.value) + '</td>' +
                    '<td>' + (item.unit || '--') + '</td>' +
                    '<td><span class="status-badge ' + qualityClass + '">' + qualityText + '</span></td>';
                tbody.appendChild(row);
            });
        }

        function getQualityClass(quality) {
            switch (quality) {
                case 'good':
                    return 'normal';
                case 'warning':
                    return 'warning';
                case 'bad':
                    return 'error';
                default:
                    return 'normal';
            }
        }

        function getQualityText(quality) {
            switch (quality) {
                case 'good':
                    return '良好';
                case 'warning':
                    return '待核实';
                case 'bad':
                    return '数据质量差';
                default:
                    return '未知';
            }
        }

        function formatNumber(num) {
            if (num === undefined || num === null) return '0';
            return num.toLocaleString('zh-CN', { maximumFractionDigits: 2 });
        }

        function formatDateTime(dateStr) {
            if (!dateStr) return '--';
            const date = new Date(dateStr);
            return date.toLocaleString('zh-CN', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        document.addEventListener('DOMContentLoaded', function() {
            loadDashboardData();
            setInterval(loadDashboardData, 300000);
        });
    </script>
</body>
</html>
