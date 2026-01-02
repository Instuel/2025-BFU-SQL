<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:if test="${empty sessionScope.user}">
    <c:redirect url="/login"/>
</c:if>
<c:if test="${sessionScope.role != 'ENERGY'}">
    <c:redirect url="/dashboard"/>
</c:if>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>能耗报表 - 能源管理员工作台</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/energy-stats.css">
</head>
<body>
    <div class="header">
        <h1>能耗报表</h1>
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
                <li><a href="${pageContext.request.contextPath}/energy/dashboard"><span class="icon">📊</span>工作台</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/reports" class="active"><span class="icon">📈</span>能耗报表</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/peak-valley"><span class="icon">⏰</span>峰谷分析</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/data-audit"><span class="icon">✅</span>数据核实</a></li>
                <li><a href="${pageContext.request.contextPath}/energy/optimization"><span class="icon">🎯</span>节能优化</a></li>
            </ul>
        </div>

        <div class="main-content">
            <div class="filter-section">
                <div class="filter-grid">
                    <div class="filter-item">
                        <label>区域</label>
                        <select id="factoryFilter">
                            <option value="">全部区域</option>
                            <option value="1">真旺厂</option>
                            <option value="2">豆果厂</option>
                        </select>
                    </div>
                    <div class="filter-item">
                        <label>能源类型</label>
                        <select id="energyTypeFilter">
                            <option value="">全部类型</option>
                            <option value="electricity">电</option>
                            <option value="water">水</option>
                            <option value="steam">蒸汽</option>
                            <option value="gas">天然气</option>
                        </select>
                    </div>
                    <div class="filter-item">
                        <label>时间维度</label>
                        <select id="timeDimensionFilter">
                            <option value="daily">日度</option>
                            <option value="monthly">月度</option>
                        </select>
                    </div>
                    <div class="filter-item">
                        <label>开始日期</label>
                        <input type="date" id="startDate">
                    </div>
                    <div class="filter-item">
                        <label>结束日期</label>
                        <input type="date" id="endDate">
                    </div>
                </div>
                <div class="filter-actions">
                    <button class="btn btn-secondary" onclick="resetFilters()">重置</button>
                    <button class="btn btn-primary" onclick="applyFilters()">查询</button>
                    <button class="btn btn-export" onclick="exportData()">导出</button>
                </div>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <h3>总能耗</h3>
                    <div class="value" id="totalConsumption">--</div>
                    <span class="unit">kWh</span>
                </div>
                <div class="stat-card">
                    <h3>平均日能耗</h3>
                    <div class="value" id="avgDailyConsumption">--</div>
                    <span class="unit">kWh/日</span>
                </div>
                <div class="stat-card">
                    <h3>最高单日能耗</h3>
                    <div class="value" id="maxDailyConsumption">--</div>
                    <span class="unit">kWh</span>
                </div>
                <div class="stat-card">
                    <h3>最低单日能耗</h3>
                    <div class="value" id="minDailyConsumption">--</div>
                    <span class="unit">kWh</span>
                </div>
            </div>

            <div class="table-section">
                <div class="table-header">
                    <h2>能耗明细</h2>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>日期</th>
                            <th>区域</th>
                            <th>能源类型</th>
                            <th>能耗值</th>
                            <th>单位</th>
                            <th>环比变化</th>
                        </tr>
                    </thead>
                    <tbody id="reportTableBody">
                        <tr>
                            <td colspan="6" class="loading">加载中...</td>
                        </tr>
                    </tbody>
                </table>
                <div class="pagination" id="pagination">
                    <button id="prevPage" onclick="changePage(-1)" disabled>上一页</button>
                    <span class="page-info">第 <span id="currentPage">1</span> 页，共 <span id="totalPages">1</span> 页</span>
                    <button id="nextPage" onclick="changePage(1)" disabled>下一页</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let totalPages = 1;
        let currentFilters = {};

        function logout() {
            window.location.href = '${pageContext.request.contextPath}/logout';
        }

        function initDates() {
            const today = new Date();
            const thirtyDaysAgo = new Date(today);
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

            document.getElementById('endDate').value = formatDate(today);
            document.getElementById('startDate').value = formatDate(thirtyDaysAgo);
        }

        function formatDate(date) {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;
        }

        function resetFilters() {
            document.getElementById('factoryFilter').value = '';
            document.getElementById('energyTypeFilter').value = '';
            document.getElementById('timeDimensionFilter').value = 'daily';
            initDates();
            currentPage = 1;
            loadReportData();
        }

        function applyFilters() {
            currentPage = 1;
            currentFilters = {
                factoryId: document.getElementById('factoryFilter').value,
                energyType: document.getElementById('energyTypeFilter').value,
                timeDimension: document.getElementById('timeDimensionFilter').value,
                startDate: document.getElementById('startDate').value,
                endDate: document.getElementById('endDate').value
            };
            loadReportData();
        }

        function loadReportData() {
            const params = new URLSearchParams({
                factoryId: currentFilters.factoryId || '',
                energyType: currentFilters.energyType || '',
                timeDimension: currentFilters.timeDimension || 'daily',
                startDate: currentFilters.startDate || '',
                endDate: currentFilters.endDate || '',
                page: currentPage,
                pageSize: 10
            });

            axios.get(`${pageContext.request.contextPath}/api/energy/reports?${params}`)
                .then(response => {
                    if (response.data.success) {
                        updateReportData(response.data.data);
                    } else {
                        console.error('加载数据失败:', response.data.message);
                    }
                })
                .catch(error => {
                    console.error('请求失败:', error);
                });
        }

        function updateReportData(data) {
            if (data.stats) {
                document.getElementById('totalConsumption').textContent = formatNumber(data.stats.totalConsumption);
                document.getElementById('avgDailyConsumption').textContent = formatNumber(data.stats.avgDailyConsumption);
                document.getElementById('maxDailyConsumption').textContent = formatNumber(data.stats.maxDailyConsumption);
                document.getElementById('minDailyConsumption').textContent = formatNumber(data.stats.minDailyConsumption);
            }

            if (data.records && data.records.length > 0) {
                updateTable(data.records);
            } else {
                showEmptyState();
            }

            if (data.pagination) {
                currentPage = data.pagination.currentPage;
                totalPages = data.pagination.totalPages;
                updatePagination();
            }
        }

        function updateTable(records) {
            const tbody = document.getElementById('reportTableBody');
            tbody.innerHTML = '';

            records.forEach(record => {
                const row = document.createElement('tr');
                const momChange = record.momChange !== null ? record.momChange : 0;
                const momChangeClass = momChange > 0 ? 'up' : (momChange < 0 ? 'down' : '');
                const momChangeIcon = momChange > 0 ? '↑' : (momChange < 0 ? '↓' : '-');

                row.innerHTML = `
                    <td>${formatDateDisplay(record.statDate)}</td>
                    <td>${record.factoryName || '--'}</td>
                    <td>${record.energyType || '--'}</td>
                    <td>${formatNumber(record.consumption)}</td>
                    <td>${record.unit || '--'}</td>
                    <td class="${momChangeClass}">${momChangeIcon} ${Math.abs(momChange).toFixed(2)}%</td>
                `;
                tbody.appendChild(row);
            });
        }

        function showEmptyState() {
            const tbody = document.getElementById('reportTableBody');
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="empty-state">
                        <div class="icon">📊</div>
                        <p>暂无数据</p>
                    </td>
                </tr>
            `;
        }

        function updatePagination() {
            document.getElementById('currentPage').textContent = currentPage;
            document.getElementById('totalPages').textContent = totalPages;
            document.getElementById('prevPage').disabled = currentPage <= 1;
            document.getElementById('nextPage').disabled = currentPage >= totalPages;
        }

        function changePage(delta) {
            currentPage += delta;
            loadReportData();
        }

        function exportData() {
            alert('导出功能开发中...');
        }

        function formatNumber(num) {
            if (num === undefined || num === null) return '0';
            return num.toLocaleString('zh-CN', { maximumFractionDigits: 2 });
        }

        function formatDateDisplay(dateStr) {
            if (!dateStr) return '--';
            const date = new Date(dateStr);
            return date.toLocaleDateString('zh-CN');
        }

        document.addEventListener('DOMContentLoaded', function() {
            initDates();
            loadReportData();
        });
    </script>
</body>
</html>
