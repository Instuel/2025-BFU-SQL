<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>运维工单管理员工作台</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="workspace-container">
        <div class="workspace-header">
            <h1>运维工单管理员工作台</h1>
            <p>告警审核派单与工单复查结案管理平台</p>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/alarm-review'">
            <div class="module-icon alarm">
                🔔
            </div>
            <div class="module-title">告警审核与派单</div>
            <div class="module-desc">
                审核告警真实性，生成运维工单并分配给就近运维人员
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-label">待审核告警</div>
                    <div class="stat-value" id="pendingAlarms">0</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">今日派单</div>
                    <div class="stat-value" id="todayOrders">0</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/order-review'">
            <div class="module-icon order">
                ✅
            </div>
            <div class="module-title">工单复查结案</div>
            <div class="module-desc">
                复查处理结果，审核通过后关闭工单并更新设备台账
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-label">待复查工单</div>
                    <div class="stat-value" id="pendingReviews">0</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">本周结案</div>
                    <div class="stat-value" id="weekClosed">0</div>
                </div>
            </div>
        </div>

        <div class="quick-actions">
            <div class="section-title">快速操作</div>
            <div class="action-grid">
                <div class="action-item" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/alarm-review'">
                    <div class="action-icon">🔔</div>
                    <div class="action-title">审核告警</div>
                </div>
                <div class="action-item" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/alarm-review?status=high'">
                    <div class="action-icon">⚠️</div>
                    <div class="action-title">高优先级告警</div>
                </div>
                <div class="action-item" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/order-review'">
                    <div class="action-icon">📋</div>
                    <div class="action-title">复查工单</div>
                </div>
                <div class="action-item" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/order-review?status=completed'">
                    <div class="action-icon">✅</div>
                    <div class="action-title">待结案工单</div>
                </div>
            </div>
        </div>

        <div class="recent-tasks">
            <div class="section-title">最近任务</div>
            <ul class="task-list" id="taskList">
                <li class="task-item">
                    <div class="task-status pending"></div>
                    <div class="task-info">
                        <div class="task-title">告警审核 - 35KV变压器温度异常</div>
                        <div class="task-time">10分钟前</div>
                    </div>
                    <button class="task-action" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/alarm-review'">处理</button>
                </li>
                <li class="task-item">
                    <div class="task-status processing"></div>
                    <div class="task-info">
                        <div class="task-title">工单复查 - OM-2024-0012</div>
                        <div class="task-time">30分钟前</div>
                    </div>
                    <button class="task-action" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/order-review'">复查</button>
                </li>
                <li class="task-item">
                    <div class="task-status completed"></div>
                    <div class="task-info">
                        <div class="task-title">工单结案 - OM-2024-0011</div>
                        <div class="task-time">1小时前</div>
                    </div>
                    <button class="task-action" onclick="window.location.href='${pageContext.request.contextPath}/order-manager/order-review'">查看</button>
                </li>
            </ul>
        </div>
    </div>

    <script>
        function loadDashboardData() {
            fetch('${pageContext.request.contextPath}/api/order-manager/dashboard')
                .then(response => response.json())
                .then(result => {
                    if (result.success) {
                        const data = result.data;
                        document.getElementById('pendingAlarms').textContent = data.pendingAlarms || 0;
                        document.getElementById('todayOrders').textContent = data.todayOrders || 0;
                        document.getElementById('pendingReviews').textContent = data.pendingReviews || 0;
                        document.getElementById('weekClosed').textContent = data.weekClosed || 0;
                        
                        if (data.recentTasks && data.recentTasks.length > 0) {
                            updateTaskList(data.recentTasks);
                        }
                    }
                })
                .catch(error => {
                    console.error('加载数据失败:', error);
                });
        }

        function updateTaskList(tasks) {
            const taskList = document.getElementById('taskList');
            taskList.innerHTML = '';
            
            tasks.forEach(task => {
                const li = document.createElement('li');
                li.className = 'task-item';
                
                const statusClass = task.status === 'pending' ? 'pending' : 
                                     task.status === 'processing' ? 'processing' : 'completed';
                
                li.innerHTML = `
                    <div class="task-status ${statusClass}"></div>
                    <div class="task-info">
                        <div class="task-title">${task.title}</div>
                        <div class="task-time">${task.time}</div>
                    </div>
                    <button class="task-action" onclick="handleTask('${task.type}', '${task.id}')">${task.action}</button>
                `;
                
                taskList.appendChild(li);
            });
        }

        function handleTask(type, id) {
            if (type === 'alarm') {
                window.location.href = '${pageContext.request.contextPath}/order-manager/alarm-review?id=' + id;
            } else if (type === 'order') {
                window.location.href = '${pageContext.request.contextPath}/order-manager/order-review?id=' + id;
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            loadDashboardData();
            
            setInterval(loadDashboardData, 30000);
        });
    </script>
</body>
</html>
