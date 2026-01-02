<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:if test="${empty sessionScope.user}">
    <c:redirect url="/login"/>
</c:if>
<c:if test="${sessionScope.role != 'OM'}">
    <c:redirect url="/dashboard"/>
</c:if>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>设备台账查看 - 智慧能源管理系统</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="header">
        <div style="display: flex; align-items: center; gap: 20px;">
            <a href="/maintenance/dashboard" class="back-btn">&larr; 返回</a>
            <h1>设备台账查看</h1>
        </div>
        <div class="header-info">
            <div class="user-info">
                <div class="user-avatar">${sessionScope.user.realName.substring(0,1)}</div>
                <span>${sessionScope.user.realName}</span>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="filter-section">
            <div class="filter-grid">
                <div class="filter-item">
                    <label>设备类型</label>
                    <select id="deviceTypeFilter">
                        <option value="">全部类型</option>
                        <option value="transformer">变压器</option>
                        <option value="meter">电表/水表</option>
                        <option value="inverter">逆变器</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label>运行状态</label>
                    <select id="statusFilter">
                        <option value="">全部状态</option>
                        <option value="normal">正常运行</option>
                        <option value="warning">预警</option>
                        <option value="error">故障</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label>区域</label>
                    <select id="factoryFilter">
                        <option value="">全部区域</option>
                        <option value="1">真旺厂</option>
                        <option value="2">豆果厂</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label>设备名称</label>
                    <input type="text" id="nameFilter" placeholder="输入设备名称">
                </div>
            </div>
            <div class="filter-actions">
                <button class="btn btn-secondary" onclick="resetFilters()">重置</button>
                <button class="btn btn-primary" onclick="applyFilters()">查询</button>
            </div>
        </div>

        <div class="device-grid" id="deviceGrid">
            <div class="loading">加载中</div>
        </div>

        <div class="pagination" id="pagination" style="display: none;">
            <button onclick="prevPage()" id="prevBtn">上一页</button>
            <span id="pageInfo">第 1 页</span>
            <button onclick="nextPage()" id="nextBtn">下一页</button>
        </div>
    </div>

    <div class="modal" id="deviceModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 id="modalTitle">设备详情</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div class="detail-grid" id="deviceDetails">
            </div>
            <div class="maintenance-history">
                <h3>维护记录</h3>
                <ul class="history-list" id="maintenanceHistory">
                    <li class="history-item">
                        <div class="history-date">2024-12-15 10:30</div>
                        <div class="history-content">定期巡检，设备运行正常</div>
                    </li>
                    <li class="history-item">
                        <div class="history-date">2024-11-20 14:00</div>
                        <div class="history-content">更换滤芯，清洁设备</div>
                    </li>
                </ul>
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '/api/maintenance';
        let currentPage = 1;
        let pageSize = 12;
        let totalDevices = 0;

        async function loadDevices() {
            try {
                const filters = {
                    deviceType: document.getElementById('deviceTypeFilter').value,
                    status: document.getElementById('statusFilter').value,
                    factoryId: document.getElementById('factoryFilter').value,
                    name: document.getElementById('nameFilter').value,
                    page: currentPage,
                    pageSize: pageSize
                };

                const response = await axios.get(`${API_BASE}/devices`, { params: filters });
                const data = response.data.data;

                totalDevices = data.total || 0;
                renderDevices(data.devices || []);
                updatePagination();
            } catch (error) {
                console.error('加载设备列表失败:', error);
                document.getElementById('deviceGrid').innerHTML = '<div class="empty-state">加载失败，请刷新重试</div>';
            }
        }

        function renderDevices(devices) {
            const container = document.getElementById('deviceGrid');
            
            if (devices.length === 0) {
                container.innerHTML = '<div class="empty-state"><i>📋</i><p>暂无设备数据</p></div>';
                return;
            }

            container.innerHTML = devices.map(device => `
                <div class="device-card" onclick="showDeviceDetail(${device.id}, '${device.type}')">
                    <div class="device-header">
                        <div class="device-type">
                            <div class="device-icon ${device.type}">
                                ${getDeviceIcon(device.type)}
                            </div>
                            <div class="device-name">${device.name}</div>
                        </div>
                        <span class="device-status ${device.status}">${getStatusText(device.status)}</span>
                    </div>
                    <div class="device-info">
                        <div class="info-item">
                            <span class="info-label">设备类型</span>
                            <span class="info-value">${getDeviceTypeText(device.type)}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">所在区域</span>
                            <span class="info-value">${device.factoryName || '--'}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">安装位置</span>
                            <span class="info-value">${device.location || '--'}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">制造商</span>
                            <span class="info-value">${device.manufacturer || '--'}</span>
                        </div>
                    </div>
                    <div class="device-actions">
                        <a href="/maintenance/devices/${device.id}/history" class="action-link">维护记录</a>
                        <a href="/maintenance/devices/${device.id}/alarms" class="action-link">告警历史</a>
                    </div>
                </div>
            `).join('');
        }

        function getDeviceIcon(type) {
            const icons = {
                'transformer': '⚡',
                'meter': '📊',
                'inverter': '🔋'
            };
            return icons[type] || '📦';
        }

        function getDeviceTypeText(type) {
            const types = {
                'transformer': '变压器',
                'meter': '电表/水表',
                'inverter': '逆变器'
            };
            return types[type] || type;
        }

        function getStatusText(status) {
            const statuses = {
                'normal': '正常运行',
                'warning': '预警',
                'error': '故障'
            };
            return statuses[status] || status;
        }

        function updatePagination() {
            const totalPages = Math.ceil(totalDevices / pageSize);
            const pagination = document.getElementById('pagination');
            
            if (totalPages <= 1) {
                pagination.style.display = 'none';
                return;
            }

            pagination.style.display = 'flex';
            document.getElementById('pageInfo').textContent = `第 ${currentPage} / ${totalPages} 页`;
            document.getElementById('prevBtn').disabled = currentPage === 1;
            document.getElementById('nextBtn').disabled = currentPage === totalPages;
        }

        function prevPage() {
            if (currentPage > 1) {
                currentPage--;
                loadDevices();
            }
        }

        function nextPage() {
            const totalPages = Math.ceil(totalDevices / pageSize);
            if (currentPage < totalPages) {
                currentPage++;
                loadDevices();
            }
        }

        function applyFilters() {
            currentPage = 1;
            loadDevices();
        }

        function resetFilters() {
            document.getElementById('deviceTypeFilter').value = '';
            document.getElementById('statusFilter').value = '';
            document.getElementById('factoryFilter').value = '';
            document.getElementById('nameFilter').value = '';
            currentPage = 1;
            loadDevices();
        }

        async function showDeviceDetail(deviceId, deviceType) {
            try {
                const response = await axios.get(`${API_BASE}/devices/${deviceId}`);
                const device = response.data.data;

                document.getElementById('modalTitle').textContent = device.name;
                document.getElementById('deviceDetails').innerHTML = `
                    <div class="detail-item">
                        <span class="detail-label">设备ID</span>
                        <span class="detail-value">${device.id}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">设备类型</span>
                        <span class="detail-value">${getDeviceTypeText(device.type)}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">运行状态</span>
                        <span class="detail-value">${getStatusText(device.status)}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">所在区域</span>
                        <span class="detail-value">${device.factoryName || '--'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">安装位置</span>
                        <span class="detail-value">${device.location || '--'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">制造商</span>
                        <span class="detail-value">${device.manufacturer || '--'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">安装日期</span>
                        <span class="detail-value">${device.installDate || '--'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">校准周期</span>
                        <span class="detail-value">${device.calibCycle || '--'} 个月</span>
                    </div>
                `;

                document.getElementById('deviceModal').classList.add('active');
            } catch (error) {
                console.error('加载设备详情失败:', error);
                alert('加载设备详情失败');
            }
        }

        function closeModal() {
            document.getElementById('deviceModal').classList.remove('active');
        }

        document.addEventListener('DOMContentLoaded', loadDevices);
    </script>
</body>
</html>
