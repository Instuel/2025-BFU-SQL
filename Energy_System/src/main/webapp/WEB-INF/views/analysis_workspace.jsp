<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:if test="${empty sessionScope.user}">
    <c:redirect url="/login"/>
</c:if>
<c:if test="${sessionScope.role != 'ANALYST'}">
    <c:redirect url="/login"/>
</c:if>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>数据分析师工作台</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    
    <div class="workspace-container">
        <div class="workspace-header">
            <h1>数据分析师工作台</h1>
            <p>光伏预测优化与能耗规律挖掘分析平台</p>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/analysis/pv-prediction'">
            <div class="module-icon pv">
                ☀️
            </div>
            <div class="module-title">光伏预测优化</div>
            <div class="module-desc">
                对比光伏预测数据与实际数据，计算偏差率，优化预测模型版本
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-label">模型版本</div>
                    <div class="stat-value" id="modelVersion">v2.1</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">平均偏差</div>
                    <div class="stat-value" id="avgDeviation">8.5%</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/analysis/energy-pattern'">
            <div class="module-icon energy">
                ⚡
            </div>
            <div class="module-title">能耗规律挖掘</div>
            <div class="module-desc">
                分析产线能耗与产量的关联关系，生成季度能源成本分析报告
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-label">分析报告</div>
                    <div class="stat-value" id="reportCount">12</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">关联度</div>
                    <div class="stat-value" id="correlation">0.85</div>
                </div>
            </div>
        </div>

        <div class="quick-actions">
            <h2>快速操作</h2>
            <div class="action-buttons">
                <button class="action-btn" onclick="window.location.href='${pageContext.request.contextPath}/analysis/pv-prediction'">
                    📊 查看预测对比
                </button>
                <button class="action-btn" onclick="window.location.href='${pageContext.request.contextPath}/analysis/energy-pattern'">
                    📈 分析能耗趋势
                </button>
                <button class="action-btn" onclick="exportReport()">
                    📥 导出分析报告
                </button>
                <button class="action-btn" onclick="refreshData()">
                    🔄 刷新数据
                </button>
            </div>
        </div>

        <div class="recent-tasks">
            <h2>最近任务</h2>
            <div class="task-list">
                <div class="task-item">
                    <div class="task-info">
                        <div class="task-icon analysis">📊</div>
                        <div>
                            <div class="task-name">光伏预测模型v2.1优化分析</div>
                            <div class="task-time">2024-01-15 14:30</div>
                        </div>
                    </div>
                    <div class="task-status completed">已完成</div>
                </div>
                <div class="task-item">
                    <div class="task-info">
                        <div class="task-icon report">📈</div>
                        <div>
                            <div class="task-name">Q4能耗成本分析报告生成</div>
                            <div class="task-time">2024-01-14 09:15</div>
                        </div>
                    </div>
                    <div class="task-status completed">已完成</div>
                </div>
                <div class="task-item">
                    <div class="task-info">
                        <div class="task-icon model">⚡</div>
                        <div>
                            <div class="task-name">产线能耗与产量关联度分析</div>
                            <div class="task-time">2024-01-13 16:45</div>
                        </div>
                    </div>
                    <div class="task-status inprogress">进行中</div>
                </div>
                <div class="task-item">
                    <div class="task-info">
                        <div class="task-icon analysis">☀️</div>
                        <div>
                            <div class="task-name">光伏发电效率优化建议</div>
                            <div class="task-time">2024-01-12 11:20</div>
                        </div>
                    </div>
                    <div class="task-status pending">待处理</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function refreshData() {
            fetch('${pageContext.request.contextPath}/api/analysis/workspace-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('modelVersion').textContent = data.data.modelVersion;
                        document.getElementById('avgDeviation').textContent = data.data.avgDeviation + '%';
                        document.getElementById('reportCount').textContent = data.data.reportCount;
                        document.getElementById('correlation').textContent = data.data.correlation;
                    }
                })
                .catch(error => {
                    console.error('刷新数据失败:', error);
                });
        }

        function exportReport() {
            alert('导出功能开发中...');
        }

        window.onload = function() {
            refreshData();
        };
    </script>
</body>
</html>