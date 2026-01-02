<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>告警规则配置</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/maintenance.css">
</head>
<body>
    <div class="alarm-config-container">
        <div class="page-header">
            <h1 class="page-title">告警规则配置</h1>
            <p class="page-subtitle">调整告警触发阈值（如变压器绕组温度上限），配置告警规则</p>
        </div>

        <div class="content-card">
            <div class="rule-stats">
                <div class="stat-card">
                    <div class="stat-value" id="totalRules">--</div>
                    <div class="stat-label">规则总数</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="activeRules">--</div>
                    <div class="stat-label">启用规则</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="highLevelRules">--</div>
                    <div class="stat-label">高等级规则</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="todayTriggers">--</div>
                    <div class="stat-label">今日触发</div>
                </div>
            </div>

            <div class="toolbar">
                <div class="search-box">
                    <input type="text" class="search-input" id="ruleSearch" placeholder="搜索规则名称、设备类型...">
                    <select class="filter-select" id="levelFilter">
                        <option value="">全部等级</option>
                        <option value="high">高等级</option>
                        <option value="medium">中等级</option>
                        <option value="low">低等级</option>
                    </select>
                    <select class="filter-select" id="statusFilter">
                        <option value="">全部状态</option>
                        <option value="active">启用</option>
                        <option value="inactive">禁用</option>
                    </select>
                    <button class="btn btn-primary" onclick="searchRules()">搜索</button>
                </div>
                <button class="btn btn-success" onclick="openRuleModal()">+ 新增规则</button>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>规则名称</th>
                        <th>设备类型</th>
                        <th>监测指标</th>
                        <th>阈值条件</th>
                        <th>告警等级</th>
                        <th>触发次数</th>
                        <th>状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="ruleTableBody">
                </tbody>
            </table>

            <div class="pagination" id="rulePagination">
            </div>
        </div>
    </div>

    <div class="modal-overlay" id="ruleModal">
        <div class="modal">
            <div class="modal-header">
                <h3 class="modal-title" id="ruleModalTitle">新增告警规则</h3>
                <button class="modal-close" onclick="closeRuleModal()">&times;</button>
            </div>
            <form id="ruleForm">
                <input type="hidden" id="ruleId">
                <div class="form-group">
                    <label class="form-label">规则名称 *</label>
                    <input type="text" class="form-input" id="ruleName" required>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">设备类型 *</label>
                        <select class="form-select" id="deviceType" required>
                            <option value="">请选择设备类型</option>
                            <option value="变压器">变压器</option>
                            <option value="逆变器">逆变器</option>
                            <option value="汇流箱">汇流箱</option>
                            <option value="配电柜">配电柜</option>
                            <option value="其他">其他</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">监测指标 *</label>
                        <select class="form-select" id="metric" required>
                            <option value="">请选择监测指标</option>
                            <option value="温度">温度</option>
                            <option value="电压">电压</option>
                            <option value="电流">电流</option>
                            <option value="功率">功率</option>
                            <option value="频率">频率</option>
                            <option value="其他">其他</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">阈值条件 *</label>
                        <select class="form-select" id="condition" required>
                            <option value="">请选择条件</option>
                            <option value=">">大于 (>)</option>
                            <option value="<">小于 (<)</option>
                            <option value=">=">大于等于 (>=)</option>
                            <option value="<=">小于等于 (<=)</option>
                            <option value="=">等于 (=)</option>
                            <option value="!=">不等于 (!=)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">阈值数值 *</label>
                        <input type="number" class="form-input" id="threshold" step="0.01" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">单位</label>
                        <input type="text" class="form-input" id="unit" placeholder="如：℃、V、A">
                    </div>
                    <div class="form-group">
                        <label class="form-label">告警等级 *</label>
                        <select class="form-select" id="level" required>
                            <option value="">请选择告警等级</option>
                            <option value="high">高等级</option>
                            <option value="medium">中等级</option>
                            <option value="low">低等级</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">通知方式</label>
                        <div class="checkbox-group">
                            <label><input type="checkbox" name="notification" value="sms"> 短信</label>
                            <label><input type="checkbox" name="notification" value="email"> 邮件</label>
                            <label><input type="checkbox" name="notification" value="system"> 系统消息</label>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">状态</label>
                        <select class="form-select" id="ruleStatus">
                            <option value="active">启用</option>
                            <option value="inactive">禁用</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">描述</label>
                    <textarea class="form-textarea" id="description" placeholder="请输入规则描述..."></textarea>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeRuleModal()">取消</button>
                    <button type="submit" class="btn btn-primary">保存</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let pageSize = 10;

        function loadRuleStats() {
            fetch(`${pageContext.request.contextPath}/api/admin/alarm-rules/stats`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('totalRules').textContent = data.data.totalRules || '--';
                        document.getElementById('activeRules').textContent = data.data.activeRules || '--';
                        document.getElementById('highLevelRules').textContent = data.data.highLevelRules || '--';
                        document.getElementById('todayTriggers').textContent = data.data.todayTriggers || '--';
                    }
                })
                .catch(error => console.error('加载规则统计失败:', error));
        }

        function loadRules() {
            const search = document.getElementById('ruleSearch').value;
            const level = document.getElementById('levelFilter').value;
            const status = document.getElementById('statusFilter').value;

            let url = `${pageContext.request.contextPath}/api/admin/alarm-rules?page=${currentPage}&size=${pageSize}`;
            if (search) url += `&search=${encodeURIComponent(search)}`;
            if (level) url += `&level=${level}`;
            if (status) url += `&status=${status}`;

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderRules(data.data.list);
                        renderPagination('rulePagination', data.data.total, data.data.page, data.data.size);
                    }
                })
                .catch(error => console.error('加载规则列表失败:', error));
        }

        function renderRules(rules) {
            const tbody = document.getElementById('ruleTableBody');
            tbody.innerHTML = rules.map(rule => `
                <tr>
                    <td>${rule.name}</td>
                    <td>${rule.deviceType}</td>
                    <td>${rule.metric}</td>
                    <td>${rule.condition} ${rule.threshold} ${rule.unit || ''}</td>
                    <td><span class="level-badge ${rule.level}">${getLevelText(rule.level)}</span></td>
                    <td>${rule.triggerCount || 0}</td>
                    <td><span class="status-badge ${rule.status}">${rule.status === 'active' ? '启用' : '禁用'}</span></td>
                    <td>
                        <div class="action-buttons">
                            <button class="action-btn edit" onclick="editRule(${rule.id})">编辑</button>
                            <button class="action-btn delete" onclick="deleteRule(${rule.id})">删除</button>
                        </div>
                    </td>
                </tr>
            `).join('');
        }

        function getLevelText(level) {
            const levelMap = {
                'high': '高',
                'medium': '中',
                'low': '低'
            };
            return levelMap[level] || level;
        }

        function openRuleModal(ruleId = null) {
            document.getElementById('ruleModal').classList.add('active');
            document.getElementById('ruleForm').reset();
            document.getElementById('ruleId').value = '';
            document.getElementById('ruleModalTitle').textContent = ruleId ? '编辑告警规则' : '新增告警规则';
        }

        function closeRuleModal() {
            document.getElementById('ruleModal').classList.remove('active');
        }

        function editRule(ruleId) {
            fetch(`${pageContext.request.contextPath}/api/admin/alarm-rules/${ruleId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const rule = data.data;
                        document.getElementById('ruleId').value = rule.id;
                        document.getElementById('ruleName').value = rule.name;
                        document.getElementById('deviceType').value = rule.deviceType;
                        document.getElementById('metric').value = rule.metric;
                        document.getElementById('condition').value = rule.condition;
                        document.getElementById('threshold').value = rule.threshold;
                        document.getElementById('unit').value = rule.unit || '';
                        document.getElementById('level').value = rule.level;
                        document.getElementById('ruleStatus').value = rule.status;
                        document.getElementById('description').value = rule.description || '';

                        if (rule.notifications) {
                            rule.notifications.forEach(notif => {
                                const checkbox = document.querySelector(`input[name="notification"][value="${notif}"]`);
                                if (checkbox) checkbox.checked = true;
                            });
                        }

                        openRuleModal(ruleId);
                    }
                })
                .catch(error => console.error('加载规则信息失败:', error));
        }

        function deleteRule(ruleId) {
            if (confirm('确定要删除该告警规则吗？')) {
                fetch(`${pageContext.request.contextPath}/api/admin/alarm-rules/${ruleId}`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('删除成功！');
                        loadRules();
                        loadRuleStats();
                    } else {
                        alert('删除失败：' + data.message);
                    }
                })
                .catch(error => {
                    console.error('删除规则失败:', error);
                    alert('删除失败：' + error.message);
                });
            }
        }

        function searchRules() {
            currentPage = 1;
            loadRules();
        }

        function renderPagination(containerId, total, page, size) {
            const totalPages = Math.ceil(total / size);
            const container = document.getElementById(containerId);
            
            let html = '';
            
            html += `<button class="page-btn" onclick="changePage(${page - 1})" ${page === 1 ? 'disabled' : ''}>上一页</button>`;
            
            for (let i = 1; i <= totalPages; i++) {
                html += `<button class="page-btn ${i === page ? 'active' : ''}" onclick="changePage(${i})">${i}</button>`;
            }
            
            html += `<button class="page-btn" onclick="changePage(${page + 1})" ${page === totalPages ? 'disabled' : ''}>下一页</button>`;
            
            container.innerHTML = html;
        }

        function changePage(page) {
            currentPage = page;
            loadRules();
        }

        document.getElementById('ruleForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const ruleId = document.getElementById('ruleId').value;
            const selectedNotifications = [];
            document.querySelectorAll('input[name="notification"]:checked').forEach(checkbox => {
                selectedNotifications.push(checkbox.value);
            });

            const ruleData = {
                name: document.getElementById('ruleName').value,
                deviceType: document.getElementById('deviceType').value,
                metric: document.getElementById('metric').value,
                condition: document.getElementById('condition').value,
                threshold: parseFloat(document.getElementById('threshold').value),
                unit: document.getElementById('unit').value,
                level: document.getElementById('level').value,
                notifications: selectedNotifications,
                status: document.getElementById('ruleStatus').value,
                description: document.getElementById('description').value
            };

            const url = ruleId ? `${pageContext.request.contextPath}/api/admin/alarm-rules/${ruleId}` : `${pageContext.request.contextPath}/api/admin/alarm-rules`;
            const method = ruleId ? 'PUT' : 'POST';

            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(ruleData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('保存成功！');
                    closeRuleModal();
                    loadRules();
                    loadRuleStats();
                } else {
                    alert('保存失败：' + data.message);
                }
            })
            .catch(error => {
                console.error('保存规则失败:', error);
                alert('保存失败：' + error.message);
            });
        });

        document.getElementById('levelFilter').addEventListener('change', searchRules);
        document.getElementById('statusFilter').addEventListener('change', searchRules);

        window.onload = function() {
            loadRuleStats();
            loadRules();
        };
    </script>
</body>
</html>
