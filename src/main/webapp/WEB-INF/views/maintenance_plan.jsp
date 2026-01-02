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
    <title>预防性维护计划 - 智慧能源管理系统</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="header">
        <div style="display: flex; align-items: center; gap: 20px;">
            <a href="/maintenance/dashboard" class="back-btn">&larr; 返回</a>
            <h1>预防性维护计划</h1>
        </div>
        <div class="header-info">
            <div class="user-info">
                <div class="user-avatar">${sessionScope.user.realName.substring(0,1)}</div>
                <span>${sessionScope.user.realName}</span>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="dashboard-grid">
            <div class="stat-card">
                <h3>即将到期校准</h3>
                <div class="value" id="calibrationDue">--</div>
                <div class="trend urgent">30天内</div>
            </div>
            <div class="stat-card">
                <h3>质保即将到期</h3>
                <div class="value" id="warrantyDue">--</div>
                <div class="trend warning">90天内</div>
            </div>
            <div class="stat-card">
                <h3>待执行维护</h3>
                <div class="value" id="pendingTasks">--</div>
                <div class="trend normal">个任务</div>
            </div>
            <div class="stat-card">
                <h3>本月已完成</h3>
                <div class="value" id="completedTasks">--</div>
                <div class="trend">个任务</div>
            </div>
        </div>

        <div class="content-grid">
            <div class="card">
                <div class="card-header">
                    <h2>维护任务列表</h2>
                    <button class="btn btn-primary btn-sm" onclick="openCreateTaskModal()">+ 新建任务</button>
                </div>
                <ul class="task-list" id="taskList">
                    <li class="loading">加载中</li>
                </ul>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>到期提醒</h2>
                </div>
                <ul class="reminder-list" id="reminderList">
                    <li class="loading">加载中</li>
                </ul>
            </div>
        </div>
    </div>

    <div class="modal" id="createTaskModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>新建维护任务</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <form id="createTaskForm">
                <div class="form-group">
                    <label>任务名称 *</label>
                    <input type="text" id="taskName" placeholder="输入任务名称" required>
                </div>
                <div class="form-group">
                    <label>设备类型 *</label>
                    <select id="taskDeviceType" required>
                        <option value="">请选择</option>
                        <option value="transformer">变压器</option>
                        <option value="meter">电表/水表</option>
                        <option value="inverter">逆变器</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>计划执行日期 *</label>
                    <input type="date" id="taskDate" required>
                </div>
                <div class="form-group">
                    <label>维护类型 *</label>
                    <select id="taskType" required>
                        <option value="">请选择</option>
                        <option value="calibration">校准</option>
                        <option value="inspection">巡检</option>
                        <option value="maintenance">维护</option>
                        <option value="replacement">更换</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>任务描述</label>
                    <textarea id="taskDesc" placeholder="输入任务详细描述"></textarea>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">取消</button>
                    <button type="submit" class="btn btn-primary">创建任务</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const API_BASE = '/api/maintenance';

        async function loadDashboardData() {
            try {
                const response = await axios.get(`${API_BASE}/maintenance/dashboard`);
                const data = response.data.data;

                document.getElementById('calibrationDue').textContent = data.calibrationDue || 0;
                document.getElementById('warrantyDue').textContent = data.warrantyDue || 0;
                document.getElementById('pendingTasks').textContent = data.pendingTasks || 0;
                document.getElementById('completedTasks').textContent = data.completedTasks || 0;

                renderTasks(data.tasks || []);
                renderReminders(data.reminders || []);
            } catch (error) {
                console.error('加载仪表板数据失败:', error);
                document.getElementById('taskList').innerHTML = '<li class="empty-state">加载失败，请刷新重试</li>';
                document.getElementById('reminderList').innerHTML = '<li class="empty-state">加载失败，请刷新重试</li>';
            }
        }

        function renderTasks(tasks) {
            const container = document.getElementById('taskList');
            
            if (tasks.length === 0) {
                container.innerHTML = '<li class="empty-state"><i>📋</i><p>暂无维护任务</p></li>';
                return;
            }

            container.innerHTML = tasks.map(task => `
                <li class="task-item">
                    <div class="task-header">
                        <span class="task-name">${task.name}</span>
                        <span class="task-status ${task.status}">${getTaskStatusText(task.status)}</span>
                    </div>
                    <div class="task-content">${task.description || '暂无描述'}</div>
                    <div class="task-time">计划时间: ${formatDate(task.planDate)}</div>
                    ${task.status === 'pending' ? `
                        <div class="task-actions">
                            <button class="btn btn-primary btn-sm" onclick="startTask(${task.id})">开始执行</button>
                            <button class="btn btn-secondary btn-sm" onclick="completeTask(${task.id})">完成</button>
                        </div>
                    ` : ''}
                </li>
            `).join('');
        }

        function renderReminders(reminders) {
            const container = document.getElementById('reminderList');
            
            if (reminders.length === 0) {
                container.innerHTML = '<li class="empty-state"><i>🔔</i><p>暂无到期提醒</p></li>';
                return;
            }

            container.innerHTML = reminders.map(reminder => `
                <li class="reminder-item ${reminder.level}">
                    <div class="reminder-header">
                        <span class="reminder-type">${reminder.type}</span>
                        <span class="reminder-days ${reminder.level}">${reminder.daysLeft}天后到期</span>
                    </div>
                    <div class="reminder-content">${reminder.content}</div>
                    <div class="reminder-time">${reminder.deviceName} - ${reminder.location}</div>
                </li>
            `).join('');
        }

        function getTaskStatusText(status) {
            const statuses = {
                'pending': '待执行',
                'inprogress': '进行中',
                'completed': '已完成'
            };
            return statuses[status] || status;
        }

        function formatDate(date) {
            if (!date) return '--';
            const d = new Date(date);
            return d.toLocaleDateString('zh-CN');
        }

        function openCreateTaskModal() {
            document.getElementById('createTaskModal').classList.add('active');
        }

        function closeModal() {
            document.getElementById('createTaskModal').classList.remove('active');
        }

        document.getElementById('createTaskForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const taskData = {
                name: document.getElementById('taskName').value,
                deviceType: document.getElementById('taskDeviceType').value,
                planDate: document.getElementById('taskDate').value,
                type: document.getElementById('taskType').value,
                description: document.getElementById('taskDesc').value
            };

            try {
                const response = await axios.post(`${API_BASE}/maintenance/tasks`, taskData);
                
                if (response.data.success) {
                    alert('任务创建成功');
                    closeModal();
                    loadDashboardData();
                } else {
                    alert('任务创建失败: ' + response.data.message);
                }
            } catch (error) {
                console.error('创建任务失败:', error);
                alert('创建任务失败，请重试');
            }
        });

        async function startTask(taskId) {
            if (!confirm('确定要开始执行此任务吗？')) return;

            try {
                const response = await axios.put(`${API_BASE}/maintenance/tasks/${taskId}/start`);
                
                if (response.data.success) {
                    loadDashboardData();
                } else {
                    alert('操作失败: ' + response.data.message);
                }
            } catch (error) {
                console.error('操作失败:', error);
                alert('操作失败，请重试');
            }
        }

        async function completeTask(taskId) {
            if (!confirm('确定要完成此任务吗？')) return;

            try {
                const response = await axios.put(`${API_BASE}/maintenance/tasks/${taskId}/complete`);
                
                if (response.data.success) {
                    loadDashboardData();
                } else {
                    alert('操作失败: ' + response.data.message);
                }
            } catch (error) {
                console.error('操作失败:', error);
                alert('操作失败，请重试');
            }
        }

        document.addEventListener('DOMContentLoaded', loadDashboardData);

        setInterval(loadDashboardData, 60000);
    </script>
</body>
</html>
