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
    <title>运维人员工作台 - 智慧能源管理系统</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="header">
        <h1>运维人员工作台</h1>
        <div class="header-info">
            <div class="user-info">
                <div class="user-avatar">${sessionScope.user.realName.substring(0,1)}</div>
                <span>${sessionScope.user.realName}</span>
                <span style="font-size: 12px; opacity: 0.8;">运维人员</span>
            </div>
            <button class="logout-btn" onclick="logout()">退出登录</button>
        </div>
    </div>

    <div class="container">
        <div class="dashboard-grid">
            <div class="stat-card">
                <h3>负责设备总数</h3>
                <div class="value" id="totalDevices">--</div>
                <div class="trend">正常运行: <span id="normalDevices">--</span></div>
            </div>
            <div class="stat-card">
                <h3>待处理工单</h3>
                <div class="value" id="pendingOrders">--</div>
                <div class="trend urgent">需尽快处理</div>
            </div>
            <div class="stat-card">
                <h3>高等级告警</h3>
                <div class="value" id="highLevelAlarms">--</div>
                <div class="trend warning">需立即关注</div>
            </div>
            <div class="stat-card">
                <h3>本月完成工单</h3>
                <div class="value" id="completedOrders">--</div>
                <div class="trend normal">完成率: <span id="completionRate">--</span>%</div>
            </div>
        </div>

        <div class="content-grid">
            <div class="card">
                <div class="card-header">
                    <h2>待处理工单</h2>
                    <a href="${pageContext.request.contextPath}/maintenance/work-orders" class="more">查看全部 &rarr;</a>
                </div>
                <ul class="work-order-list" id="workOrderList">
                    <li class="loading">加载中</li>
                </ul>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>最新告警</h2>
                    <a href="${pageContext.request.contextPath}/maintenance/alarms" class="more">查看全部 &rarr;</a>
                </div>
                <ul class="alarm-list" id="alarmList">
                    <li class="loading">加载中</li>
                </ul>
            </div>
        </div>

        <div class="card" style="margin-top: 20px;">
            <div class="card-header">
                <h2>快速操作</h2>
            </div>
            <div class="quick-actions">
                <button class="action-btn" onclick="location.href='${pageContext.request.contextPath}/maintenance/devices'">
                    📋 查看设备台账
                </button>
                <button class="action-btn secondary" onclick="location.href='${pageContext.request.contextPath}/maintenance/work-orders'">
                    📝 处理工单
                </button>
                <button class="action-btn tertiary" onclick="location.href='${pageContext.request.contextPath}/maintenance/plans'">
                    📅 维护计划
                </button>
                <button class="action-btn quaternary" onclick="location.href='${pageContext.request.contextPath}/maintenance/reports'">
                    📊 工作报表
                </button>
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '${pageContext.request.contextPath}/api/maintenance';

        function logout() {
            if (confirm('确定要退出登录吗？')) {
                window.location.href = '${pageContext.request.contextPath}/logout';
            }
        }

        async function loadDashboardData() {
            try {
                const response = await axios.get(API_BASE + '/dashboard');
                const data = response.data.data;

                document.getElementById('totalDevices').textContent = data.totalDevices || 0;
                document.getElementById('normalDevices').textContent = data.normalDevices || 0;
                document.getElementById('pendingOrders').textContent = data.pendingOrders || 0;
                document.getElementById('highLevelAlarms').textContent = data.highLevelAlarms || 0;
                document.getElementById('completedOrders').textContent = data.completedOrders || 0;
                document.getElementById('completionRate').textContent = data.completionRate || 0;

                renderWorkOrders(data.workOrders || []);
                renderAlarms(data.alarms || []);
            } catch (error) {
                console.error('加载仪表板数据失败:', error);
                document.getElementById('workOrderList').innerHTML = '<li class="empty-state">加载失败，请刷新重试</li>';
                document.getElementById('alarmList').innerHTML = '<li class="empty-state">加载失败，请刷新重试</li>';
            }
        }

        function renderWorkOrders(orders) {
            const container = document.getElementById('workOrderList');
            
            if (orders.length === 0) {
                container.innerHTML = '<li class="empty-state">暂无待处理工单</li>';
                return;
            }

            var html = '';
            for (var i = 0; i < orders.length; i++) {
                var order = orders[i];
                html += '<li class="work-order-item">' +
                    '<div class="order-header">' +
                    '<span class="order-id">工单 #' + order.orderId + '</span>' +
                    '<span class="order-status ' + order.status + '">' + getStatusText(order.status) + '</span>' +
                    '</div>' +
                    '<div class="order-content">' + (order.content || '暂无描述') + '</div>' +
                    '<div class="order-time">派发时间: ' + formatTime(order.dispatchTime) + '</div>' +
                    '</li>';
            }
            container.innerHTML = html;
        }

        function renderAlarms(alarms) {
            const container = document.getElementById('alarmList');
            
            if (alarms.length === 0) {
                container.innerHTML = '<li class="empty-state">暂无告警信息</li>';
                return;
            }

            var html = '';
            for (var i = 0; i < alarms.length; i++) {
                var alarm = alarms[i];
                html += '<li class="alarm-item ' + alarm.level + '">' +
                    '<div class="alarm-header">' +
                    '<span class="alarm-level ' + alarm.level + '">' + alarm.levelText + '</span>' +
                    '<span class="alarm-time">' + formatTime(alarm.occurTime) + '</span>' +
                    '</div>' +
                    '<div class="alarm-content">' + alarm.content + '</div>' +
                    '</li>';
            }
            container.innerHTML = html;
        }

        function getStatusText(status) {
            var statusMap = {
                'pending': '待处理',
                'processing': '处理中',
                'completed': '已完成'
            };
            return statusMap[status] || status;
        }

        function formatTime(time) {
            if (!time) return '--';
            var date = new Date(time);
            return date.toLocaleString('zh-CN', {
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        document.addEventListener('DOMContentLoaded', loadDashboardData);

        setInterval(loadDashboardData, 30000);
    </script>
</body>
</html>
