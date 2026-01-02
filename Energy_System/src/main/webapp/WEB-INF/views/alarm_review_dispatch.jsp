<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>告警审核与派单 - 运维工单管理员</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="container">
        <a href="${pageContext.request.contextPath}/order-manager/workspace" class="back-link">返回工作台</a>

        <div class="page-header">
            <h1>告警审核与派单</h1>
            <p>审核告警真实性，生成运维工单并分配给就近运维人员</p>
        </div>

        <div class="stats-cards">
            <div class="stat-card">
                <div class="stat-value" id="pendingCount">0</div>
                <div class="stat-label">待审核告警</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="verifiedCount">0</div>
                <div class="stat-label">今日已审核</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="dispatchedCount">0</div>
                <div class="stat-label">今日派单</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="falseAlarmCount">0</div>
                <div class="stat-label">误报数量</div>
            </div>
        </div>

        <div class="filter-section">
            <div class="filter-title">筛选条件</div>
            <form class="filter-form" id="filterForm">
                <div class="form-group">
                    <label>告警级别</label>
                    <select name="alarmLevel" id="alarmLevel">
                        <option value="">全部</option>
                        <option value="高">高</option>
                        <option value="中">中</option>
                        <option value="低">低</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>告警类型</label>
                    <select name="alarmType" id="alarmType">
                        <option value="">全部</option>
                        <option value="设备故障">设备故障</option>
                        <option value="能耗异常">能耗异常</option>
                        <option value="温度异常">温度异常</option>
                        <option value="电压异常">电压异常</option>
                        <option value="其他">其他</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>审核状态</label>
                    <select name="reviewStatus" id="reviewStatus">
                        <option value="">全部</option>
                        <option value="待审核">待审核</option>
                        <option value="已通过">已通过</option>
                        <option value="误报">误报</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>开始日期</label>
                    <input type="date" name="startDate" id="startDate">
                </div>
                <div class="form-group">
                    <label>结束日期</label>
                    <input type="date" name="endDate" id="endDate">
                </div>
                <div class="form-group">
                    <button type="button" class="btn btn-primary" onclick="applyFilter()">查询</button>
                </div>
                <div class="form-group">
                    <button type="button" class="btn btn-secondary" onclick="resetFilter()">重置</button>
                </div>
            </form>
        </div>

        <div class="table-container">
            <div class="table-header">
                <div class="table-title">告警列表</div>
            </div>
            <table id="alarmTable">
                <thead>
                    <tr>
                        <th>告警编号</th>
                        <th>告警时间</th>
                        <th>告警级别</th>
                        <th>告警类型</th>
                        <th>设备名称</th>
                        <th>告警内容</th>
                        <th>审核状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="alarmTableBody">
                </tbody>
            </table>
            <div class="pagination" id="pagination">
            </div>
        </div>
    </div>

    <div class="modal" id="reviewModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>告警审核</h2>
                <button class="modal-close" onclick="closeReviewModal()">&times;</button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="reviewAlarmId">
                <div class="detail-row">
                    <div class="detail-label">告警编号:</div>
                    <div class="detail-value" id="reviewAlarmCode"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">告警时间:</div>
                    <div class="detail-value" id="reviewAlarmTime"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">告警级别:</div>
                    <div class="detail-value" id="reviewAlarmLevel"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">告警类型:</div>
                    <div class="detail-value" id="reviewAlarmType"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">设备名称:</div>
                    <div class="detail-value" id="reviewDeviceName"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">告警内容:</div>
                    <div class="detail-value" id="reviewAlarmContent"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">审核意见:</div>
                    <div class="detail-value">
                        <textarea id="reviewComment" placeholder="请输入审核意见"></textarea>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-danger" onclick="submitReview('误报')">标记为误报</button>
                <button class="btn btn-success" onclick="submitReview('已通过')">通过审核并派单</button>
            </div>
        </div>
    </div>

    <div class="modal" id="dispatchModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>工单派发</h2>
                <button class="modal-close" onclick="closeDispatchModal()">&times;</button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="dispatchAlarmId">
                <div class="detail-row">
                    <div class="detail-label">告警编号:</div>
                    <div class="detail-value" id="dispatchAlarmCode"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">设备名称:</div>
                    <div class="detail-value" id="dispatchDeviceName"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">告警内容:</div>
                    <div class="detail-value" id="dispatchAlarmContent"></div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">工单标题:</div>
                    <div class="detail-value">
                        <input type="text" id="orderTitle" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px;">
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">工单描述:</div>
                    <div class="detail-value">
                        <textarea id="orderDescription" placeholder="请输入工单描述"></textarea>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">优先级:</div>
                    <div class="detail-value">
                        <select id="orderPriority" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px;">
                            <option value="高">高</option>
                            <option value="中" selected>中</option>
                            <option value="低">低</option>
                        </select>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">指派给:</div>
                    <div class="detail-value">
                        <select id="assignTo" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px;">
                            <option value="">请选择运维人员</option>
                        </select>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">期望完成时间:</div>
                    <div class="detail-value">
                        <input type="datetime-local" id="expectedCompletionTime" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px;">
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeDispatchModal()">取消</button>
                <button class="btn btn-primary" onclick="submitDispatch()">确认派单</button>
            </div>
        </div>
    </div>

    <script src="${pageContext.request.contextPath}/js/chart.js"></script>
    <script>
        let currentPage = 1;
        let pageSize = 10;
        let totalPages = 1;

        document.addEventListener('DOMContentLoaded', function() {
            loadStats();
            loadAlarms();
            loadMaintenancePersonnel();
        });

        function loadStats() {
            fetch('${pageContext.request.contextPath}/api/order-manager/alarm-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('pendingCount').textContent = data.data.pendingCount || 0;
                        document.getElementById('verifiedCount').textContent = data.data.verifiedCount || 0;
                        document.getElementById('dispatchedCount').textContent = data.data.dispatchedCount || 0;
                        document.getElementById('falseAlarmCount').textContent = data.data.falseAlarmCount || 0;
                    }
                })
                .catch(error => console.error('加载统计数据失败:', error));
        }

        function loadAlarms() {
            const params = new URLSearchParams();
            params.append('page', currentPage);
            params.append('pageSize', pageSize);
            
            const alarmLevel = document.getElementById('alarmLevel').value;
            const alarmType = document.getElementById('alarmType').value;
            const reviewStatus = document.getElementById('reviewStatus').value;
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;

            if (alarmLevel) params.append('alarmLevel', alarmLevel);
            if (alarmType) params.append('alarmType', alarmType);
            if (reviewStatus) params.append('reviewStatus', reviewStatus);
            if (startDate) params.append('startDate', startDate);
            if (endDate) params.append('endDate', endDate);

            fetch('${pageContext.request.contextPath}/api/order-manager/alarms?' + params.toString())
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderAlarms(data.data.list);
                        totalPages = data.data.totalPages;
                        renderPagination();
                    }
                })
                .catch(error => console.error('加载告警数据失败:', error));
        }

        function renderAlarms(alarms) {
            const tbody = document.getElementById('alarmTableBody');
            tbody.innerHTML = '';

            if (alarms.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 40px;">暂无数据</td></tr>';
                return;
            }

            alarms.forEach(alarm => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${alarm.alarmCode || ''}</td>
                    <td>${alarm.alarmTime || ''}</td>
                    <td><span class="priority-badge priority-${alarm.alarmLevel === '高' ? 'high' : alarm.alarmLevel === '中' ? 'medium' : 'low'}">${alarm.alarmLevel || ''}</span></td>
                    <td>${alarm.alarmType || ''}</td>
                    <td>${alarm.deviceName || ''}</td>
                    <td>${alarm.alarmContent || ''}</td>
                    <td><span class="status-badge status-${alarm.reviewStatus === '待审核' ? 'pending' : alarm.reviewStatus === '已通过' ? 'verified' : 'false'}">${alarm.reviewStatus || ''}</span></td>
                    <td>
                        <div class="action-buttons">
                            ${alarm.reviewStatus === '待审核' ? `
                                <button class="btn btn-sm btn-primary" onclick="openReviewModal('${alarm.id}')">审核</button>
                            ` : ''}
                            ${alarm.reviewStatus === '已通过' && !alarm.workOrderId ? `
                                <button class="btn btn-sm btn-success" onclick="openDispatchModal('${alarm.id}')">派单</button>
                            ` : ''}
                            ${alarm.workOrderId ? `
                                <button class="btn btn-sm btn-secondary" onclick="viewWorkOrder('${alarm.workOrderId}')">查看工单</button>
                            ` : ''}
                        </div>
                    </td>
                `;
                tbody.appendChild(row);
            });
        }

        function renderPagination() {
            const pagination = document.getElementById('pagination');
            pagination.innerHTML = '';

            const prevBtn = document.createElement('button');
            prevBtn.textContent = '上一页';
            prevBtn.disabled = currentPage === 1;
            prevBtn.onclick = () => {
                if (currentPage > 1) {
                    currentPage--;
                    loadAlarms();
                }
            };
            pagination.appendChild(prevBtn);

            for (let i = 1; i <= totalPages; i++) {
                const btn = document.createElement('button');
                btn.textContent = i;
                btn.className = i === currentPage ? 'active' : '';
                btn.onclick = () => {
                    currentPage = i;
                    loadAlarms();
                };
                pagination.appendChild(btn);
            }

            const nextBtn = document.createElement('button');
            nextBtn.textContent = '下一页';
            nextBtn.disabled = currentPage === totalPages;
            nextBtn.onclick = () => {
                if (currentPage < totalPages) {
                    currentPage++;
                    loadAlarms();
                }
            };
            pagination.appendChild(nextBtn);
        }

        function applyFilter() {
            currentPage = 1;
            loadAlarms();
        }

        function resetFilter() {
            document.getElementById('filterForm').reset();
            currentPage = 1;
            loadAlarms();
        }

        function openReviewModal(alarmId) {
            fetch('${pageContext.request.contextPath}/api/order-manager/alarm/' + alarmId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const alarm = data.data;
                        document.getElementById('reviewAlarmId').value = alarm.id;
                        document.getElementById('reviewAlarmCode').textContent = alarm.alarmCode;
                        document.getElementById('reviewAlarmTime').textContent = alarm.alarmTime;
                        document.getElementById('reviewAlarmLevel').textContent = alarm.alarmLevel;
                        document.getElementById('reviewAlarmType').textContent = alarm.alarmType;
                        document.getElementById('reviewDeviceName').textContent = alarm.deviceName;
                        document.getElementById('reviewAlarmContent').textContent = alarm.alarmContent;
                        document.getElementById('reviewComment').value = '';
                        document.getElementById('reviewModal').classList.add('active');
                    }
                })
                .catch(error => console.error('加载告警详情失败:', error));
        }

        function closeReviewModal() {
            document.getElementById('reviewModal').classList.remove('active');
        }

        function submitReview(status) {
            const alarmId = document.getElementById('reviewAlarmId').value;
            const comment = document.getElementById('reviewComment').value;

            fetch('${pageContext.request.contextPath}/api/order-manager/alarm/review', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    alarmId: alarmId,
                    status: status,
                    comment: comment
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('审核成功');
                    closeReviewModal();
                    loadStats();
                    loadAlarms();
                    
                    if (status === '已通过') {
                        openDispatchModal(alarmId);
                    }
                } else {
                    alert('审核失败: ' + data.message);
                }
            })
            .catch(error => {
                console.error('审核失败:', error);
                alert('审核失败');
            });
        }

        function openDispatchModal(alarmId) {
            fetch('${pageContext.request.contextPath}/api/order-manager/alarm/' + alarmId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const alarm = data.data;
                        document.getElementById('dispatchAlarmId').value = alarm.id;
                        document.getElementById('dispatchAlarmCode').textContent = alarm.alarmCode;
                        document.getElementById('dispatchDeviceName').textContent = alarm.deviceName;
                        document.getElementById('dispatchAlarmContent').textContent = alarm.alarmContent;
                        document.getElementById('orderTitle').value = '处理告警: ' + alarm.alarmCode;
                        document.getElementById('orderDescription').value = '告警内容: ' + alarm.alarmContent;
                        document.getElementById('orderPriority').value = alarm.alarmLevel === '高' ? '高' : '中';
                        
                        const now = new Date();
                        now.setHours(now.getHours() + 24);
                        document.getElementById('expectedCompletionTime').value = now.toISOString().slice(0, 16);
                        
                        document.getElementById('dispatchModal').classList.add('active');
                    }
                })
                .catch(error => console.error('加载告警详情失败:', error));
        }

        function closeDispatchModal() {
            document.getElementById('dispatchModal').classList.remove('active');
        }

        function loadMaintenancePersonnel() {
            fetch('${pageContext.request.contextPath}/api/order-manager/maintenance-personnel')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const select = document.getElementById('assignTo');
                        select.innerHTML = '<option value="">请选择运维人员</option>';
                        data.data.forEach(person => {
                            const option = document.createElement('option');
                            option.value = person.id;
                            option.textContent = person.name + ' (' + person.area + ')';
                            select.appendChild(option);
                        });
                    }
                })
                .catch(error => console.error('加载运维人员失败:', error));
        }

        function submitDispatch() {
            const alarmId = document.getElementById('dispatchAlarmId').value;
            const orderTitle = document.getElementById('orderTitle').value;
            const orderDescription = document.getElementById('orderDescription').value;
            const orderPriority = document.getElementById('orderPriority').value;
            const assignTo = document.getElementById('assignTo').value;
            const expectedCompletionTime = document.getElementById('expectedCompletionTime').value;

            if (!assignTo) {
                alert('请选择运维人员');
                return;
            }

            fetch('${pageContext.request.contextPath}/api/order-manager/dispatch', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    alarmId: alarmId,
                    orderTitle: orderTitle,
                    orderDescription: orderDescription,
                    orderPriority: orderPriority,
                    assignTo: assignTo,
                    expectedCompletionTime: expectedCompletionTime
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('派单成功');
                    closeDispatchModal();
                    loadStats();
                    loadAlarms();
                } else {
                    alert('派单失败: ' + data.message);
                }
            })
            .catch(error => {
                console.error('派单失败:', error);
                alert('派单失败');
            });
        }

        function viewWorkOrder(workOrderId) {
            window.location.href = '${pageContext.request.contextPath}/order-manager/order-review?orderId=' + workOrderId;
        }
    </script>
</body>
</html>
