<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>企业管理层工作台</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="workspace-container">
        <div class="workspace-header">
            <h1>企业管理层工作台</h1>
            <p>欢迎回来，企业管理层。查看能源运行总览、光伏收益及能耗分析报告。</p>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/executive/overview'">
            <div class="module-icon overview">
                📊
            </div>
            <div class="module-title">决策总览</div>
            <div class="module-desc">
                查看能源运行总览、光伏收益（自用电节省电费）、能耗溯源分析及告警统计。
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="totalEnergy">--</div>
                    <div class="stat-label">总能耗 (kWh)</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="pvRevenue">--</div>
                    <div class="stat-label">光伏收益 (元)</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="activeAlarms">--</div>
                    <div class="stat-label">活跃告警</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="efficiency">--</div>
                    <div class="stat-label">能效指数</div>
                </div>
            </div>
        </div>

        <div class="module-card" onclick="window.location.href='${pageContext.request.contextPath}/executive/report'">
            <div class="module-icon report">
                📈
            </div>
            <div class="module-title">能耗总结报告</div>
            <div class="module-desc">
                查看月度/季度总结报告，评估"降本增效"目标完成情况。
            </div>
            <div class="module-stats">
                <div class="stat-item">
                    <div class="stat-value" id="monthlyCost">--</div>
                    <div class="stat-label">本月成本 (万元)</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="savings">--</div>
                    <div class="stat-label">节能收益 (万元)</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="targetProgress">--</div>
                    <div class="stat-label">目标完成率</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value" id="reportCount">--</div>
                    <div class="stat-label">报告数量</div>
                </div>
            </div>
        </div>

        <div class="quick-actions">
            <h3>快捷操作</h3>
            <div class="action-buttons">
                <button class="action-btn primary" onclick="window.location.href='${pageContext.request.contextPath}/executive/overview'">
                    查看决策总览
                </button>
                <button class="action-btn primary" onclick="window.location.href='${pageContext.request.contextPath}/executive/report'">
                    生成能耗报告
                </button>
                <button class="action-btn secondary" onclick="exportData()">
                    导出数据
                </button>
                <button class="action-btn secondary" onclick="refreshData()">
                    刷新数据
                </button>
            </div>
        </div>
    </div>

    <script>
        function loadDashboardStats() {
            fetch('${pageContext.request.contextPath}/api/executive/dashboard-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('totalEnergy').textContent = data.data.totalEnergy || '--';
                        document.getElementById('pvRevenue').textContent = data.data.pvRevenue || '--';
                        document.getElementById('activeAlarms').textContent = data.data.activeAlarms || '--';
                        document.getElementById('efficiency').textContent = data.data.efficiency || '--';
                        document.getElementById('monthlyCost').textContent = data.data.monthlyCost || '--';
                        document.getElementById('savings').textContent = data.data.savings || '--';
                        document.getElementById('targetProgress').textContent = data.data.targetProgress || '--';
                        document.getElementById('reportCount').textContent = data.data.reportCount || '--';
                    }
                })
                .catch(error => {
                    console.error('加载统计数据失败:', error);
                });
        }

        function refreshData() {
            loadDashboardStats();
        }

        function exportData() {
            alert('数据导出功能正在开发中...');
        }

        window.onload = function() {
            loadDashboardStats();
        };
    </script>
</body>
</html>