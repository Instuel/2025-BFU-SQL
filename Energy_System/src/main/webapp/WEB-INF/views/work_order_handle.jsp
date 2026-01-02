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
    <title>运维工单执行 - 智慧能源管理系统</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Microsoft YaHei', Arial, sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 20px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 {
            font-size: 24px;
            font-weight: 600;
        }
        .header-info {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(255,255,255,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }
        .back-btn {
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
        }
        .back-btn:hover {
            background: rgba(255,255,255,0.3);
        }
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .filter-section {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }
        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .filter-item {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .filter-item label {
            font-size: 14px;
            color: #666;
            font-weight: 500;
        }
        .filter-item select,
        .filter-item input {
            padding: 10px 15px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .filter-item select:focus,
        .filter-item input:focus {
            outline: none;
            border-color: #f5576c;
        }
        .filter-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        .btn {
            padding: 10px 25px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
        }
        .btn-primary {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(245, 87, 108, 0.4);
        }
        .btn-secondary {
            background: #f0f0f0;
            color: #666;
        }
        .btn-secondary:hover {
            background: #e0e0e0;
        }
        .btn-success {
            background: #2ed573;
            color: white;
        }
        .btn-success:hover {
            background: #26af61;
        }
        .work-order-grid {
            display: grid;
            gap: 20px;
        }
        .work-order-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: all 0.3s;
        }
        .work-order-card:hover {
            box-shadow: 0 4px 16px rgba(0,0,0,0.12);
        }
        .order-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #f0f0f0;
        }
        .order-id {
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }
        .order-status {
            padding: 6px 16px;
            border-radius: 16px;
            font-size: 13px;
            font-weight: 600;
        }
        .order-status.pending {
            background: #ffeaa7;
            color: #d35400;
        }
        .order-status.processing {
            background: #74b9ff;
            color: #0984e3;
        }
        .order-status.completed {
            background: #55efc4;
            color: #00b894;
        }
        .order-status.urgent {
            background: #ff7675;
            color: white;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }
        .order-content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        .content-section {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .section-title {
            font-size: 14px;
            color: #999;
            font-weight: 500;
            margin-bottom: 5px;
        }
        .section-value {
            font-size: 15px;
            color: #333;
            line-height: 1.6;
        }
        .alarm-info {
            background: #fff5f5;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #f5576c;
        }
        .alarm-info.warning {
            background: #fff8e1;
            border-left-color: #ffa502;
        }
        .alarm-info.normal {
            background: #f0fff4;
            border-left-color: #2ed573;
        }
        .alarm-level {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .alarm-level.high {
            background: #f5576c;
            color: white;
        }
        .alarm-level.medium {
            background: #ffa502;
            color: white;
        }
        .alarm-level.low {
            background: #2ed573;
            color: white;
        }
        .order-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
        }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        .empty-state i {
            font-size: 64px;
            margin-bottom: 20px;
            display: block;
        }
        .loading {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        .loading::after {
            content: '...';
            animation: dots 1.5s steps(4, end) infinite;
        }
        @keyframes dots {
            0%, 20% { content: '.'; }
            40% { content: '..'; }
            60%, 100% { content: '...'; }
        }
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }
        .modal.active {
            display: flex;
        }
        .modal-content {
            background: white;
            border-radius: 12px;
            padding: 30px;
            max-width: 700px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
        }
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }
        .modal-header h2 {
            font-size: 20px;
            color: #333;
        }
        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            color: #999;
            cursor: pointer;
        }
        .close-btn:hover {
            color: #333;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            color: #666;
            font-weight: 500;
        }
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            resize: vertical;
            min-height: 120px;
            transition: border-color 0.3s;
        }
        .form-group textarea:focus {
            outline: none;
            border-color: #f5576c;
        }
        .form-group select {
            width: 100%;
            padding: 12px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group select:focus {
            outline: none;
            border-color: #f5576c;
        }
        .file-upload {
            border: 2px dashed #e0e0e0;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        .file-upload:hover {
            border-color: #f5576c;
            background: #fff5f5;
        }
        .file-upload input {
            display: none;
        }
        .file-upload-text {
            color: #999;
            font-size: 14px;
        }
        .file-upload-icon {
            font-size: 48px;
            margin-bottom: 10px;
            display: block;
        }
        .file-list {
            margin-top: 15px;
            display: grid;
            gap: 10px;
        }
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            background: #f9f9f9;
            border-radius: 6px;
        }
        .file-name {
            font-size: 14px;
            color: #333;
        }
        .file-remove {
            color: #f5576c;
            cursor: pointer;
            font-size: 18px;
        }
        .modal-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 25px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
        }
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            margin-top: 30px;
        }
        .pagination button {
            padding: 8px 16px;
            border: 1px solid #e0e0e0;
            background: white;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s;
        }
        .pagination button:hover:not(:disabled) {
            border-color: #f5576c;
            color: #f5576c;
        }
        .pagination button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .pagination span {
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div style="display: flex; align-items: center; gap: 20px;">
            <a href="/maintenance/dashboard" class="back-btn">&larr; 返回</a>
            <h1>运维工单执行</h1>
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
                    <label>工单状态</label>
                    <select id="statusFilter">
                        <option value="">全部状态</option>
                        <option value="pending">待处理</option>
                        <option value="processing">处理中</option>
                        <option value="completed">已完成</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label>告警等级</label>
                    <select id="alarmLevelFilter">
                        <option value="">全部等级</option>
                        <option value="high">高等级</option>
                        <option value="medium">中等级</option>
                        <option value="low">低等级</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label>派发时间</label>
                    <input type="date" id="startDate">
                </div>
                <div class="filter-item">
                    <label>至</label>
                    <input type="date" id="endDate">
                </div>
            </div>
            <div class="filter-actions">
                <button class="btn btn-secondary" onclick="resetFilters()">重置</button>
                <button class="btn btn-primary" onclick="applyFilters()">查询</button>
            </div>
        </div>

        <div class="work-order-grid" id="workOrderGrid">
            <div class="loading">加载中</div>
        </div>

        <div class="pagination" id="pagination" style="display: none;">
            <button onclick="prevPage()" id="prevBtn">上一页</button>
            <span id="pageInfo">第 1 页</span>
            <button onclick="nextPage()" id="nextBtn">下一页</button>
        </div>
    </div>

    <div class="modal" id="handleModal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 id="modalTitle">处理工单</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <form id="handleForm">
                <input type="hidden" id="orderId">
                <div class="form-group">
                    <label>处理结果 *</label>
                    <textarea id="resultDesc" placeholder="请详细描述处理过程和结果" required></textarea>
                </div>
                <div class="form-group">
                    <label>处理状态 *</label>
                    <select id="handleStatus" required>
                        <option value="">请选择</option>
                        <option value="processing">处理中</option>
                        <option value="completed">已完成</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>现场照片</label>
                    <div class="file-upload" onclick="document.getElementById('fileInput').click()">
                        <input type="file" id="fileInput" multiple accept="image/*" onchange="handleFileSelect(event)">
                        <span class="file-upload-icon">📷</span>
                        <span class="file-upload-text">点击或拖拽上传现场照片</span>
                    </div>
                    <div class="file-list" id="fileList"></div>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">取消</button>
                    <button type="submit" class="btn btn-success">提交处理结果</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const API_BASE = '/api/maintenance';
        let currentPage = 1;
        let pageSize = 10;
        let totalOrders = 0;
        let uploadedFiles = [];

        async function loadWorkOrders() {
            try {
                const filters = {
                    status: document.getElementById('statusFilter').value,
                    alarmLevel: document.getElementById('alarmLevelFilter').value,
                    startDate: document.getElementById('startDate').value,
                    endDate: document.getElementById('endDate').value,
                    page: currentPage,
                    pageSize: pageSize
                };

                const response = await axios.get(`${API_BASE}/work-orders`, { params: filters });
                const data = response.data.data;

                totalOrders = data.total || 0;
                renderWorkOrders(data.orders || []);
                updatePagination();
            } catch (error) {
                console.error('加载工单列表失败:', error);
                document.getElementById('workOrderGrid').innerHTML = '<div class="empty-state">加载失败，请刷新重试</div>';
            }
        }

        function renderWorkOrders(orders) {
            var container = document.getElementById('workOrderGrid');
            
            if (orders.length === 0) {
                container.innerHTML = '<div class="empty-state"><i>📝</i><p>暂无工单数据</p></div>';
                return;
            }

            var html = '';
            for (var i = 0; i < orders.length; i++) {
                var order = orders[i];
                var statusClass = order.status + (order.urgent ? ' urgent' : '');
                var resultSection = '';
                if (order.resultDesc) {
                    resultSection = '<div class="content-section" style="margin-bottom: 20px;">' +
                        '<div class="section-title">处理结果</div>' +
                        '<div class="section-value">' + order.resultDesc + '</div>' +
                        '</div>';
                }
                var actionButtons = '';
                if (order.status === 'pending' || order.status === 'processing') {
                    actionButtons = '<button class="btn btn-primary" onclick="openHandleModal(' + order.orderId + ')">处理工单</button>';
                }
                
                html += '<div class="work-order-card">' +
                    '<div class="order-header">' +
                    '<span class="order-id">工单 #' + order.orderId + '</span>' +
                    '<span class="order-status ' + statusClass + '">' + getStatusText(order.status) + '</span>' +
                    '</div>' +
                    '<div class="order-content">' +
                    '<div class="content-section">' +
                    '<div class="section-title">告警信息</div>' +
                    '<div class="alarm-info ' + order.alarmLevel + '">' +
                    '<span class="alarm-level ' + order.alarmLevel + '">' + getAlarmLevelText(order.alarmLevel) + '</span>' +
                    '<div class="section-value">' + (order.alarmContent || '暂无告警内容') + '</div>' +
                    '</div></div>' +
                    '<div class="content-section">' +
                    '<div class="section-title">工单详情</div>' +
                    '<div class="section-value">派发时间: ' + formatTime(order.dispatchTime) + '</div>' +
                    '<div class="section-value">响应时间: ' + (formatTime(order.responseTime) || '--') + '</div>' +
                    '<div class="section-value">完成时间: ' + (formatTime(order.finishTime) || '--') + '</div>' +
                    '</div></div>' +
                    resultSection +
                    '<div class="order-actions">' +
                    actionButtons +
                    '<button class="btn btn-secondary" onclick="viewOrderDetail(' + order.orderId + ')">查看详情</button>' +
                    '</div></div>';
            }
            container.innerHTML = html;
        }

        function getStatusText(status) {
            const statuses = {
                'pending': '待处理',
                'processing': '处理中',
                'completed': '已完成'
            };
            return statuses[status] || status;
        }

        function getAlarmLevelText(level) {
            const levels = {
                'high': '高等级',
                'medium': '中等级',
                'low': '低等级'
            };
            return levels[level] || level;
        }

        function formatTime(time) {
            if (!time) return null;
            const date = new Date(time);
            return date.toLocaleString('zh-CN', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        function updatePagination() {
            const totalPages = Math.ceil(totalOrders / pageSize);
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
                loadWorkOrders();
            }
        }

        function nextPage() {
            const totalPages = Math.ceil(totalOrders / pageSize);
            if (currentPage < totalPages) {
                currentPage++;
                loadWorkOrders();
            }
        }

        function applyFilters() {
            currentPage = 1;
            loadWorkOrders();
        }

        function resetFilters() {
            document.getElementById('statusFilter').value = '';
            document.getElementById('alarmLevelFilter').value = '';
            document.getElementById('startDate').value = '';
            document.getElementById('endDate').value = '';
            currentPage = 1;
            loadWorkOrders();
        }

        function openHandleModal(orderId) {
            document.getElementById('orderId').value = orderId;
            document.getElementById('modalTitle').textContent = '处理工单 #' + orderId;
            document.getElementById('resultDesc').value = '';
            document.getElementById('handleStatus').value = '';
            uploadedFiles = [];
            document.getElementById('fileList').innerHTML = '';
            document.getElementById('handleModal').classList.add('active');
        }

        function closeModal() {
            document.getElementById('handleModal').classList.remove('active');
        }

        function handleFileSelect(event) {
            var files = event.target.files;
            var fileList = document.getElementById('fileList');
            
            for (var i = 0; i < files.length; i++) {
                uploadedFiles.push(files[i]);
                var fileItem = document.createElement('div');
                fileItem.className = 'file-item';
                fileItem.innerHTML = '<span class="file-name">' + files[i].name + '</span>' +
                    '<span class="file-remove" onclick="removeFile(' + (uploadedFiles.length - 1) + ')">&times;</span>';
                fileList.appendChild(fileItem);
            }
        }

        function removeFile(index) {
            uploadedFiles.splice(index, 1);
            renderFileList();
        }

        function renderFileList() {
            var fileList = document.getElementById('fileList');
            var html = '';
            for (var i = 0; i < uploadedFiles.length; i++) {
                html += '<div class="file-item">' +
                    '<span class="file-name">' + uploadedFiles[i].name + '</span>' +
                    '<span class="file-remove" onclick="removeFile(' + i + ')">&times;</span>' +
                    '</div>';
            }
            fileList.innerHTML = html;
        }

        document.getElementById('handleForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const orderId = document.getElementById('orderId').value;
            const resultDesc = document.getElementById('resultDesc').value;
            const handleStatus = document.getElementById('handleStatus').value;

            try {
                const formData = new FormData();
                formData.append('orderId', orderId);
                formData.append('resultDesc', resultDesc);
                formData.append('status', handleStatus);
                
                uploadedFiles.forEach(file => {
                    formData.append('files', file);
                });

                const response = await axios.post(`${API_BASE}/work-orders/${orderId}/handle`, formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                });

                if (response.data.success) {
                    alert('工单处理成功');
                    closeModal();
                    loadWorkOrders();
                } else {
                    alert('工单处理失败: ' + response.data.message);
                }
            } catch (error) {
                console.error('处理工单失败:', error);
                alert('处理工单失败，请重试');
            }
        });

        function viewOrderDetail(orderId) {
            alert('查看工单详情功能开发中...');
        }

        document.addEventListener('DOMContentLoaded', loadWorkOrders);
    </script>
</body>
</html>
