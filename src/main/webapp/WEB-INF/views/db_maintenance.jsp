<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>数据库运维 - 系统管理员</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="db-container">
        <div class="db-header">
            <h1>数据库运维</h1>
            <p>执行增量/全量数据备份与恢复，监控磁盘占用率及查询响应时间</p>
        </div>

        <div class="db-overview">
            <div class="overview-card">
                <div class="overview-title">数据库大小</div>
                <div class="overview-value" id="dbSize">--</div>
                <div class="overview-change" id="dbSizeChange">--</div>
            </div>
            <div class="overview-card">
                <div class="overview-title">磁盘占用率</div>
                <div class="overview-value" id="diskUsage">--</div>
                <div class="overview-change" id="diskUsageChange">--</div>
            </div>
            <div class="overview-card">
                <div class="overview-title">平均查询响应时间</div>
                <div class="overview-value" id="queryTime">--</div>
                <div class="overview-change" id="queryTimeChange">--</div>
            </div>
            <div class="overview-card">
                <div class="overview-title">最近备份时间</div>
                <div class="overview-value" id="lastBackup">--</div>
                <div class="overview-change">自动备份</div>
            </div>
        </div>

        <div class="db-content">
            <div class="content-card">
                <div class="card-title">数据备份</div>
                
                <div class="backup-options">
                    <div class="backup-option selected" onclick="selectBackupOption('incremental', this)">
                        <div class="backup-option-title">增量备份</div>
                        <div class="backup-option-desc">仅备份自上次备份以来发生变化的数据，速度快，节省空间</div>
                    </div>
                    <div class="backup-option" onclick="selectBackupOption('full', this)">
                        <div class="backup-option-title">全量备份</div>
                        <div class="backup-option-desc">备份整个数据库，数据完整，但耗时较长</div>
                    </div>
                </div>

                <button class="btn btn-primary" onclick="startBackup()" id="backupBtn">开始备份</button>

                <div class="restore-section">
                    <div class="restore-title">数据恢复</div>
                    <div class="restore-warning">
                        ⚠️ 警告：恢复操作将覆盖当前数据库数据，请谨慎操作！建议在恢复前先进行完整备份。
                    </div>
                    <button class="btn btn-warning" onclick="showRestoreModal()">选择备份文件恢复</button>
                </div>

                <div class="backup-history">
                    <div class="card-title" style="font-size: 16px; border-bottom: none; padding-bottom: 10px;">备份历史</div>
                    <table class="history-table">
                        <thead>
                            <tr>
                                <th>备份时间</th>
                                <th>类型</th>
                                <th>大小</th>
                                <th>状态</th>
                            </tr>
                        </thead>
                        <tbody id="backupHistoryBody">
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="content-card">
                <div class="card-title">数据库监控</div>
                
                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>磁盘占用率</span>
                        <span id="diskUsageValue">--</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" id="diskUsageProgress" style="width: 0%"></div>
                    </div>
                </div>

                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>数据库连接数</span>
                        <span id="connectionCount">--</span>
                    </div>
                    <div class="monitor-value" id="connectionValue">--</div>
                </div>

                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>活跃查询数</span>
                        <span id="activeQueryCount">--</span>
                    </div>
                    <div class="monitor-value" id="activeQueryValue">--</div>
                </div>

                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>查询响应时间 (ms)</span>
                        <span id="queryResponseTime">--</span>
                    </div>
                    <div class="monitor-value" id="queryResponseValue">--</div>
                </div>

                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>缓存命中率</span>
                        <span id="cacheHitRate">--</span>
                    </div>
                    <div class="monitor-value" id="cacheHitValue">--</div>
                </div>

                <div class="monitor-item">
                    <div class="monitor-label">
                        <span>事务成功率</span>
                        <span id="transactionSuccessRate">--</span>
                    </div>
                    <div class="monitor-value" id="transactionSuccessValue">--</div>
                </div>

                <button class="btn btn-success" onclick="refreshMonitor()">刷新监控数据</button>
            </div>
        </div>
    </div>

    <div class="modal" id="restoreModal">
        <div class="modal-content">
            <div class="modal-title">确认数据恢复</div>
            <div class="modal-body">
                您确定要从选定的备份文件恢复数据吗？<br><br>
                此操作将：<br>
                • 覆盖当前数据库的所有数据<br>
                • 停止所有正在进行的数据库操作<br>
                • 可能需要较长时间完成<br><br>
                <strong>请确保您已了解此操作的后果！</strong>
            </div>
            <div class="modal-actions">
                <button class="btn btn-secondary" onclick="closeRestoreModal()">取消</button>
                <button class="btn btn-danger" onclick="confirmRestore()">确认恢复</button>
            </div>
        </div>
    </div>

    <script>
        let selectedBackupType = 'incremental';

        function selectBackupOption(type, element) {
            selectedBackupType = type;
            document.querySelectorAll('.backup-option').forEach(option => {
                option.classList.remove('selected');
            });
            element.classList.add('selected');
        }

        function startBackup() {
            const backupBtn = document.getElementById('backupBtn');
            backupBtn.disabled = true;
            backupBtn.textContent = '备份中...';

            fetch('${pageContext.request.contextPath}/api/admin/backup', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: selectedBackupType
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showNotification('备份成功！', 'success');
                    loadBackupHistory();
                    loadMonitorData();
                } else {
                    showNotification('备份失败：' + data.message, 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showNotification('备份失败：网络错误', 'error');
            })
            .finally(() => {
                backupBtn.disabled = false;
                backupBtn.textContent = '开始备份';
            });
        }

        function showRestoreModal() {
            document.getElementById('restoreModal').classList.add('active');
        }

        function closeRestoreModal() {
            document.getElementById('restoreModal').classList.remove('active');
        }

        function confirmRestore() {
            closeRestoreModal();
            showNotification('正在恢复数据，请稍候...', 'info');

            fetch('${pageContext.request.contextPath}/api/admin/restore', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showNotification('数据恢复成功！', 'success');
                    loadMonitorData();
                } else {
                    showNotification('数据恢复失败：' + data.message, 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showNotification('数据恢复失败：网络错误', 'error');
            });
        }

        function loadBackupHistory() {
            fetch('${pageContext.request.contextPath}/api/admin/backup-history')
            .then(response => response.json())
            .then(data => {
                if (data.success && data.history) {
                    const tbody = document.getElementById('backupHistoryBody');
                    tbody.innerHTML = '';
                    
                    data.history.forEach(backup => {
                        const row = document.createElement('tr');
                        row.innerHTML = `
                            <td>${backup.backupTime}</td>
                            <td>${backup.type === 'full' ? '全量' : '增量'}</td>
                            <td>${backup.size}</td>
                            <td><span class="status-badge ${backup.status === 'success' ? 'success' : 'danger'}">${backup.status === 'success' ? '成功' : '失败'}</span></td>
                        `;
                        tbody.appendChild(row);
                    });
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }

        function loadMonitorData() {
            fetch('${pageContext.request.contextPath}/api/admin/db-monitor')
            .then(response => response.json())
            .then(data => {
                if (data.success && data.monitor) {
                    const monitor = data.monitor;
                    
                    document.getElementById('dbSize').textContent = monitor.dbSize;
                    document.getElementById('dbSizeChange').textContent = monitor.dbSizeChange;
                    
                    document.getElementById('diskUsage').textContent = monitor.diskUsage;
                    document.getElementById('diskUsageChange').textContent = monitor.diskUsageChange;
                    document.getElementById('diskUsageValue').textContent = monitor.diskUsage;
                    document.getElementById('diskUsageProgress').style.width = monitor.diskUsagePercent;
                    document.getElementById('diskUsageProgress').className = 'progress-fill ' + monitor.diskUsageStatus;
                    
                    document.getElementById('queryTime').textContent = monitor.queryTime;
                    document.getElementById('queryTimeChange').textContent = monitor.queryTimeChange;
                    document.getElementById('queryResponseTime').textContent = monitor.queryTime;
                    document.getElementById('queryResponseValue').textContent = monitor.queryTime + ' ms';
                    
                    document.getElementById('connectionCount').textContent = monitor.connectionCount;
                    document.getElementById('connectionValue').textContent = monitor.connectionCount + ' / ' + monitor.maxConnections;
                    
                    document.getElementById('activeQueryCount').textContent = monitor.activeQueryCount;
                    document.getElementById('activeQueryValue').textContent = monitor.activeQueryCount;
                    
                    document.getElementById('cacheHitRate').textContent = monitor.cacheHitRate;
                    document.getElementById('cacheHitValue').textContent = monitor.cacheHitRate;
                    
                    document.getElementById('transactionSuccessRate').textContent = monitor.transactionSuccessRate;
                    document.getElementById('transactionSuccessValue').textContent = monitor.transactionSuccessRate;
                    
                    document.getElementById('lastBackup').textContent = monitor.lastBackup;
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }

        function refreshMonitor() {
            loadMonitorData();
            showNotification('监控数据已刷新', 'success');
        }

        function showNotification(message, type) {
            const notification = document.createElement('div');
            notification.className = 'notification ' + type;
            notification.textContent = message;
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.remove();
            }, 3000);
        }

        window.onload = function() {
            loadBackupHistory();
            loadMonitorData();
            
            setInterval(loadMonitorData, 30000);
        };
    </script>
</body>
</html>
