<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>工单复查结案 - 运维工单管理员</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="container">
        <a href="${pageContext.request.contextPath}/order-manager/workspace" class="back-link">返回工作台</a>

        <div class="page-header">
            <h1>工单复查结案</h1>
            <p>复查处理结果，审核通过后关闭工单并更新设备台账</p>
        </div>

        <div class="stats-cards">
            <div class="stat-card">
                <div class="stat-value" id="pendingReviewCount">0</div>
                <div class="stat-label">待复查工单</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="reviewedCount">0</div>
                <div class="stat-label">今日已复查</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="closedCount">0</div>
                <div class="stat-label">本周结案</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="rejectedCount">0</div>
                <div class="stat-label">驳回数量</div>
            </div>
        </div>

        <div class="filter-section">
            <div class="filter-title">筛选条件</div>
            <form class="filter-form" id="filterForm">
                <div class="form-group">
                    <label>工单状态</label>
                    <select name="orderStatus" id="orderStatus">
                        <option value="">全部</option>
                        <option value="待复查">待复查</option>
                        <option value="已完成">已完成</option>
                        <option value="已结案">已结案</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>优先级</label>
                    <select name="priority" id="priority">
                        <option value="">全部</option>
                        <option value="高">高</option>
                        <option value="中">中</option>
                        <option value="低">低</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>处理人</label>
                    <select name="assignee" id="assignee">
                        <option value="">全部</option>
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
                <div class="table-title">工单列表</div>
            </div>
            <table id="orderTable">
                <thead>
                    <tr>
                        <th>工单编号</th>
                        <th>工单标题</th>
                        <th>设备名称</th>
                        <th>优先级</th>
                        <th>处理人</th>
                        <th>创建时间</th>
                        <th>完成时间</th>
                        <th>工单状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="orderTableBody">
                </tbody>
            </table>
            <div class="pagination" id="pagination">
            </div>
        </div>
    </div>

    <div class="modal" id="reviewModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>工单复查</h2>
                <button class="modal-close" onclick="closeReviewModal()">&times;</button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="reviewOrderId">
                
                <div class="detail-section">
                    <h3>工单信息</h3>
                    <div class="detail-row">
                        <div class="detail-label">工单编号:</div>
                        <div class="detail-value" id="reviewOrderCode"></div>
                    </div>
                    <div class="detail-row">
                        <div class="detail-label">工单标题:</div>
                        <div class="detail-value" id="reviewOrderTitle"></div>
                    </div>
                    <div class="detail-row">
                        <div class="detail-label">设备名称:</div>
                        <div class="detail-value" id="reviewDeviceName"></div>
                    </div>
                    <div class="detail-row">
                        <div class="detail-label">优先级:</div>
                        <div class="detail-value" id="reviewPriority"></div>
                    </div>
                    <div class="detail-row">
                        <div class="detail-label">创建时间:</div>
                        <div class="detail-value" id="reviewCreateTime"></div>
                    </div>
                    <div class="detail-row">
                        <div class="detail-label">期望完成时间:</div>
                        <div class="detail-value" id="reviewExpectedTime"></div>
                    </div>
                </div>

                <div class="detail-section">
                    <h3>工单描述</h3>
                    <div class="detail-value" id="reviewOrderDescription"></div>
                </div>

                <div class="detail-section">
                    <h3>处理记录</h3>
                    <div class="timeline" id="reviewTimeline">
                    </div>
                </div>

                <div class="detail-section">
                    <h3>复查意见</h3>
                    <div class="detail-value">
                        <textarea id="reviewComment" placeholder="请输入复查意见"></textarea>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-danger" onclick="submitReview('驳回')">驳回</button>
                <button class="btn btn-success" onclick="submitReview('通过')">通过并结案</button>
            </div>
        </div>
    </div>

    <div class="modal" id="detailModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>工单详情</h2>
                <button class="modal-close" onclick="closeDetailModal()">&times;</button>
            </div>
            <div class="modal-body" id="detailContent">
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeDetailModal()">关闭</button>
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
            loadOrders();
            loadMaintenancePersonnel();
        });

        function loadStats() {
            fetch('${pageContext.request.contextPath}/api/order-manager/order-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('pendingReviewCount').textContent = data.data.pendingReviewCount || 0;
                        document.getElementById('reviewedCount').textContent = data.data.reviewedCount || 0;
                        document.getElementById('closedCount').textContent = data.data.closedCount || 0;
                        document.getElementById('rejectedCount').textContent = data.data.rejectedCount || 0;
                    }
                })
                .catch(error => console.error('加载统计数据失败:', error));
        }

        function loadOrders() {
            const params = new URLSearchParams();
            params.append('page', currentPage);
            params.append('pageSize', pageSize);
            
            const orderStatus = document.getElementById('orderStatus').value;
            const priority = document.getElementById('priority').value;
            const assignee = document.getElementById('assignee').value;
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;

            if (orderStatus) params.append('orderStatus', orderStatus);
            if (priority) params.append('priority', priority);
            if (assignee) params.append('assignee', assignee);
            if (startDate) params.append('startDate', startDate);
            if (endDate) params.append('endDate', endDate);

            fetch('${pageContext.request.contextPath}/api/order-manager/orders?' + params.toString())
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderOrders(data.data.list);
                        totalPages = data.data.totalPages;
                        renderPagination();
                    }
                })
                .catch(error => console.error('加载工单数据失败:', error));
        }

        function renderOrders(orders) {
            const tbody = document.getElementById('orderTableBody');
            tbody.innerHTML = '';

            if (orders.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align: center; padding: 40px;">暂无数据</td></tr>';
                return;
            }

            orders.forEach(order => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${order.orderCode || ''}</td>
                    <td>${order.orderTitle || ''}</td>
                    <td>${order.deviceName || ''}</td>
                    <td><span class="priority-badge priority-${order.priority === '高' ? 'high' : order.priority === '中' ? 'medium' : 'low'}">${order.priority || ''}</span></td>
                    <td>${order.assigneeName || ''}</td>
                    <td>${order.createTime || ''}</td>
                    <td>${order.completeTime || ''}</td>
                    <td><span class="status-badge status-${order.orderStatus === '待复查' ? 'pending' : order.orderStatus === '已完成' ? 'processing' : order.orderStatus === '已结案' ? 'closed' : 'rejected'}">${order.orderStatus || ''}</span></td>
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-sm btn-primary" onclick="openDetailModal('${order.id}')">查看详情</button>
                            ${order.orderStatus === '待复查' ? `
                                <button class="btn btn-sm btn-success" onclick="openReviewModal('${order.id}')">复查</button>
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
                    loadOrders();
                }
            };
            pagination.appendChild(prevBtn);

            for (let i = 1; i <= totalPages; i++) {
                const btn = document.createElement('button');
                btn.textContent = i;
                btn.className = i === currentPage ? 'active' : '';
                btn.onclick = () => {
                    currentPage = i;
                    loadOrders();
                };
                pagination.appendChild(btn);
            }

            const nextBtn = document.createElement('button');
            nextBtn.textContent = '下一页';
            nextBtn.disabled = currentPage === totalPages;
            nextBtn.onclick = () => {
                if (currentPage < totalPages) {
                    currentPage++;
                    loadOrders();
                }
            };
            pagination.appendChild(nextBtn);
        }

        function applyFilter() {
            currentPage = 1;
            loadOrders();
        }

        function resetFilter() {
            document.getElementById('filterForm').reset();
            currentPage = 1;
            loadOrders();
        }

        function openDetailModal(orderId) {
            fetch('${pageContext.request.contextPath}/api/order-manager/order/' + orderId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const order = data.data;
                        const content = document.getElementById('detailContent');
                        content.innerHTML = `
                            <div class="detail-section">
                                <h3>工单信息</h3>
                                <div class="detail-row">
                                    <div class="detail-label">工单编号:</div>
                                    <div class="detail-value">${order.orderCode || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">工单标题:</div>
                                    <div class="detail-value">${order.orderTitle || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">设备名称:</div>
                                    <div class="detail-value">${order.deviceName || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">优先级:</div>
                                    <div class="detail-value">${order.priority || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">处理人:</div>
                                    <div class="detail-value">${order.assigneeName || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">创建时间:</div>
                                    <div class="detail-value">${order.createTime || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">期望完成时间:</div>
                                    <div class="detail-value">${order.expectedCompletionTime || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">完成时间:</div>
                                    <div class="detail-value">${order.completeTime || ''}</div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">工单状态:</div>
                                    <div class="detail-value">${order.orderStatus || ''}</div>
                                </div>
                            </div>

                            <div class="detail-section">
                                <h3>工单描述</h3>
                                <div class="detail-value">${order.orderDescription || ''}</div>
                            </div>

                            <div class="detail-section">
                                <h3>处理记录</h3>
                                <div class="timeline">
                                    ${order.timeline ? order.timeline.map(item => `
                                        <div class="timeline-item">
                                            <div class="timeline-time">${item.time}</div>
                                            <div class="timeline-content">${item.content}</div>
                                        </div>
                                    `).join('') : '<div class="timeline-content">暂无处理记录</div>'}
                                </div>
                            </div>

                            ${order.reviewComment ? `
                                <div class="detail-section">
                                    <h3>复查意见</h3>
                                    <div class="detail-value">${order.reviewComment}</div>
                                </div>
                            ` : ''}
                        `;
                        document.getElementById('detailModal').classList.add('active');
                    }
                })
                .catch(error => console.error('加载工单详情失败:', error));
        }

        function closeDetailModal() {
            document.getElementById('detailModal').classList.remove('active');
        }

        function openReviewModal(orderId) {
            fetch('${pageContext.request.contextPath}/api/order-manager/order/' + orderId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const order = data.data;
                        document.getElementById('reviewOrderId').value = order.id;
                        document.getElementById('reviewOrderCode').textContent = order.orderCode;
                        document.getElementById('reviewOrderTitle').textContent = order.orderTitle;
                        document.getElementById('reviewDeviceName').textContent = order.deviceName;
                        document.getElementById('reviewPriority').textContent = order.priority;
                        document.getElementById('reviewCreateTime').textContent = order.createTime;
                        document.getElementById('reviewExpectedTime').textContent = order.expectedCompletionTime;
                        document.getElementById('reviewOrderDescription').textContent = order.orderDescription;
                        document.getElementById('reviewComment').value = '';
                        
                        const timeline = document.getElementById('reviewTimeline');
                        if (order.timeline && order.timeline.length > 0) {
                            timeline.innerHTML = order.timeline.map(item => `
                                <div class="timeline-item">
                                    <div class="timeline-time">${item.time}</div>
                                    <div class="timeline-content">${item.content}</div>
                                </div>
                            `).join('');
                        } else {
                            timeline.innerHTML = '<div class="timeline-content">暂无处理记录</div>';
                        }
                        
                        document.getElementById('reviewModal').classList.add('active');
                    }
                })
                .catch(error => console.error('加载工单详情失败:', error));
        }

        function closeReviewModal() {
            document.getElementById('reviewModal').classList.remove('active');
        }

        function submitReview(status) {
            const orderId = document.getElementById('reviewOrderId').value;
            const comment = document.getElementById('reviewComment').value;

            if (!comment.trim()) {
                alert('请输入复查意见');
                return;
            }

            fetch('${pageContext.request.contextPath}/api/order-manager/order/review', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    orderId: orderId,
                    status: status,
                    comment: comment
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('复查成功');
                    closeReviewModal();
                    loadStats();
                    loadOrders();
                } else {
                    alert('复查失败: ' + data.message);
                }
            })
            .catch(error => {
                console.error('复查失败:', error);
                alert('复查失败');
            });
        }

        function loadMaintenancePersonnel() {
            fetch('${pageContext.request.contextPath}/api/order-manager/maintenance-personnel')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const select = document.getElementById('assignee');
                        select.innerHTML = '<option value="">全部</option>';
                        data.data.forEach(person => {
                            const option = document.createElement('option');
                            option.value = person.id;
                            option.textContent = person.name;
                            select.appendChild(option);
                        });
                    }
                })
                .catch(error => console.error('加载运维人员失败:', error));
        }
    </script>
</body>
</html>
