<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:if test="${not empty sessionScope.user}">
    <c:redirect url="/dashboard"/>
</c:if>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智慧能源管理系统 - 公共门户</title>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="header">
        <h1>智慧能源管理系统</h1>
        <div class="header-nav">
            <a href="${pageContext.request.contextPath}/login">登录</a>
            <a href="${pageContext.request.contextPath}/register">注册</a>
        </div>
    </div>
    
    <div class="hero">
        <h2>智慧能源管理系统</h2>
        <p>Smart Energy Management System - 实时监控 · 智能分析 · 高效管理</p>
        <div class="hero-buttons">
            <button class="btn btn-primary" onclick="window.location.href='${pageContext.request.contextPath}/login'">立即登录</button>
            <button class="btn btn-secondary" onclick="window.location.href='${pageContext.request.contextPath}/register'">注册账号</button>
        </div>
    </div>
    
    <div class="stats-section">
        <div class="section-title">
            <h3>实时数据概览</h3>
            <p>Real-time Data Overview - 系统运行状态实时监控</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon energy">⚡</div>
                <div class="stat-value">12,580</div>
                <div class="stat-label">总用电量 (kWh)</div>
                <div class="stat-trend trend-up">
                    ↑ 8.5% 较昨日
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon alarm">⚠️</div>
                <div class="stat-value">3</div>
                <div class="stat-label">当前告警数</div>
                <div class="stat-trend trend-down">
                    ↓ 2 较上小时
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon pv">☀️</div>
                <div class="stat-value">2,847</div>
                <div class="stat-label">光伏发电量 (kWh)</div>
                <div class="stat-trend trend-up">
                    ↑ 12.3% 较昨日
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon factory">🏭</div>
                <div class="stat-value">5</div>
                <div class="stat-label">在线厂区数</div>
                <div class="stat-trend">
                    全部正常运行
                </div>
            </div>
        </div>
    </div>
    
    <div class="features-section">
        <div class="section-title">
            <h3>系统功能</h3>
            <p>System Features - 全方位能源管理解决方案</p>
        </div>
        
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">🏭</div>
                <h4>厂区管理</h4>
                <p>全面管理厂区信息，包括厂区基本信息、设备配置、能耗数据等，实现厂区能源的精细化管理。</p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">🔌</div>
                <h4>配电管理</h4>
                <p>实时监控配电房及配电设备运行状态，包括电压、电流、功率等关键参数，确保配电系统稳定运行。</p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">📊</div>
                <h4>能耗管理</h4>
                <p>综合能耗数据统计分析，提供能耗趋势分析、峰谷电价管理、能耗报表等功能，助力节能降耗。</p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">☀️</div>
                <h4>光伏管理</h4>
                <p>分布式光伏发电系统监控，实时监测光伏设备运行状态、发电量、并网情况，优化光伏利用效率。</p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">🚨</div>
                <h4>告警管理</h4>
                <p>实时告警监控与处理，支持告警分级、告警推送、工单管理等功能，及时发现并处理异常情况。</p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">📈</div>
                <h4>数据大屏</h4>
                <p>可视化数据展示大屏，实时呈现关键指标、趋势图表、地理分布等信息，直观展示系统运行状态。</p>
            </div>
        </div>
    </div>
    
    <div class="footer">
        <p>智慧能源管理系统 © 2025 Smart Energy Management System</p>
        <p>版本 1.0.0 | 技术支持</p>
    </div>

    <script>
        function fetchStats() {
            axios.get('${pageContext.request.contextPath}/api/public/stats')
                .then(response => {
                    if (response.data.success) {
                        updateStats(response.data.data);
                    } else {
                        console.error('获取统计数据失败:', response.data.message);
                    }
                })
                .catch(error => {
                    console.error('请求失败:', error);
                });
        }

        function updateStats(data) {
            const totalKwh = document.querySelector('.stat-card:nth-child(1) .stat-value');
            const totalAlarm = document.querySelector('.stat-card:nth-child(2) .stat-value');
            const pvGenKwh = document.querySelector('.stat-card:nth-child(3) .stat-value');
            const factoryCount = document.querySelector('.stat-card:nth-child(4) .stat-value');

            if (totalKwh && data.totalKwh !== undefined) {
                totalKwh.textContent = formatNumber(data.totalKwh);
            }

            if (totalAlarm && data.totalAlarm !== undefined) {
                totalAlarm.textContent = data.totalAlarm;
            }

            if (pvGenKwh && data.pvGenKwh !== undefined) {
                pvGenKwh.textContent = formatNumber(data.pvGenKwh);
            }

            if (factoryCount && data.factoryCount !== undefined) {
                factoryCount.textContent = data.factoryCount;
            }
        }

        function formatNumber(num) {
            if (num === undefined || num === null) return '0';
            return num.toLocaleString('zh-CN', { maximumFractionDigits: 0 });
        }

        document.addEventListener('DOMContentLoaded', function() {
            fetchStats();
            setInterval(fetchStats, 60000);
        });
    </script>
</body>
</html>
