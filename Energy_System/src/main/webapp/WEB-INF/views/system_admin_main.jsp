<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统管理员工作台</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
</head>
<body>
    <div class="workspace-container">
        <div class="workspace-header">
            <h1>系统管理员工作台</h1>
            <p>系统最高权限！负责底层配置与安全运维</p>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/admin/rbac'">
            <div class="module-icon rbac">👥</div>
            <div class="module-title">用户与角色管理</div>
            <div class="module-desc">维护账号信息，分配角色权限（RBAC），如设置运维人员的负责区域</div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="userCount">--</div>
                    <div class="stat-label">用户总数</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="roleCount">--</div>
                    <div class="stat-label">角色数量</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/admin/alarm-rules'">
            <div class="module-icon alarm">🔔</div>
            <div class="module-title">告警规则配置</div>
            <div class="module-desc">调整告警触发阈值（如变压器绕组温度上限），配置告警规则</div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="ruleCount">--</div>
                    <div class="stat-label">规则数量</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="activeRuleCount">--</div>
                    <div class="stat-label">启用规则</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/admin/business-params'">
            <div class="module-icon param">⚙️</div>
            <div class="module-title">业务参数配置</div>
            <div class="module-desc">配置峰谷时段划分标准、大屏展示刷新频率等关键参数</div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="paramCount">--</div>
                    <div class="stat-label">参数数量</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="modifiedCount">--</div>
                    <div class="stat-label">近期修改</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/admin/db-maintenance'">
            <div class="module-icon db">💾</div>
            <div class="module-title">数据库运维</div>
            <div class="module-desc">执行增量/全量数据备份与恢复，监控磁盘占用率及查询响应时间</div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="dbSize">--</div>
                    <div class="stat-label">数据库大小</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="backupCount">--</div>
                    <div class="stat-label">备份文件</div>
                </div>
            </div>
        </div>

        <div class="system-status">
            <div class="section-title">系统状态监控</div>
            <div class="status-grid">
                <div class="status-item normal">
                    <div class="status-label">系统运行状态</div>
                    <div class="status-value" id="systemStatus">--</div>
                </div>
                <div class="status-item normal">
                    <div class="status-label">CPU使用率</div>
                    <div class="status-value" id="cpuUsage">--</div>
                </div>
                <div class="status-item normal">
                    <div class="status-label">内存使用率</div>
                    <div class="status-value" id="memoryUsage">--</div>
                </div>
                <div class="status-item normal">
                    <div class="status-label">磁盘使用率</div>
                    <div class="status-value" id="diskUsage">--</div>
                </div>
                <div class="status-item normal">
                    <div class="status-label">数据库连接数</div>
                    <div class="status-value" id="dbConnections">--</div>
                </div>
                <div class="status-item normal">
                    <div class="status-label">在线用户数</div>
                    <div class="status-value" id="onlineUsers">--</div>
                </div>
            </div>
        </div>

        <div class="quick-actions">
            <div class="section-title">快捷操作</div>
            <div class="action-buttons">
                <button class="action-btn primary" onclick="quickBackup()">📦 快速备份</button>
                <button class="action-btn success" onclick="checkSystemHealth()">✅ 系统健康检查</button>
                <button class="action-btn warning" onclick="viewLogs()">📋 查看日志</button>
                <button class="action-btn danger" onclick="clearCache()">🗑️ 清理缓存</button>
            </div>
        </div>
    </div>

    <script>
        function loadDashboardStats() {
            fetch('${pageContext.request.contextPath}/api/admin/dashboard-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('userCount').textContent = data.data.userCount || '--';
                        document.getElementById('roleCount').textContent = data.data.roleCount || '--';
                        document.getElementById('ruleCount').textContent = data.data.ruleCount || '--';
                        document.getElementById('activeRuleCount').textContent = data.data.activeRuleCount || '--';
                        document.getElementById('paramCount').textContent = data.data.paramCount || '--';
                        document.getElementById('modifiedCount').textContent = data.data.modifiedCount || '--';
                        document.getElementById('dbSize').textContent = data.data.dbSize || '--';
                        document.getElementById('backupCount').textContent = data.data.backupCount || '--';
                    }
                })
                .catch(error => {
                    console.error('加载统计数据失败:', error);
                });
        }

        function loadSystemStatus() {
            fetch('${pageContext.request.contextPath}/api/admin/system-status')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('systemStatus').textContent = data.data.systemStatus || '--';
                        document.getElementById('cpuUsage').textContent = data.data.cpuUsage || '--';
                        document.getElementById('memoryUsage').textContent = data.data.memoryUsage || '--';
                        document.getElementById('diskUsage').textContent = data.data.diskUsage || '--';
                        document.getElementById('dbConnections').textContent = data.data.dbConnections || '--';
                        document.getElementById('onlineUsers').textContent = data.data.onlineUsers || '--';
                    }
                })
                .catch(error => {
                    console.error('加载系统状态失败:', error);
                });
        }

        function quickBackup() {
            if (confirm('确定要执行快速备份吗？')) {
                fetch('${pageContext.request.contextPath}/api/admin/quick-backup', {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('备份成功！');
                    } else {
                        alert('备份失败：' + data.message);
                    }
                })
                .catch(error => {
                    console.error('备份失败:', error);
                    alert('备份失败：' + error.message);
                });
            }
        }

        function checkSystemHealth() {
            fetch('${pageContext.request.contextPath}/api/admin/health-check')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('系统健康检查通过！');
                    } else {
                        alert('系统健康检查发现问题：' + data.message);
                    }
                })
                .catch(error => {
                    console.error('健康检查失败:', error);
                    alert('健康检查失败：' + error.message);
                });
        }

        function viewLogs() {
            window.open('${pageContext.request.contextPath}/admin/logs', '_blank');
        }

        function clearCache() {
            if (confirm('确定要清理系统缓存吗？')) {
                fetch('${pageContext.request.contextPath}/api/admin/clear-cache', {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('缓存清理成功！');
                    } else {
                        alert('缓存清理失败：' + data.message);
                    }
                })
                .catch(error => {
                    console.error('清理缓存失败:', error);
                    alert('清理缓存失败：' + error.message);
                });
            }
        }

        window.onload = function() {
            loadDashboardStats();
            loadSystemStatus();
            
            setInterval(function() {
                loadSystemStatus();
            }, 30000);
        };
    </script>
</body>
</html>
