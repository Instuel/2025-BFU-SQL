<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>业务参数配置 - 系统管理员</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="param-container">
        <div class="param-header">
            <h1>业务参数配置</h1>
            <p>配置峰谷时段划分标准、大屏展示刷新频率等关键参数</p>
        </div>

        <div class="param-categories">
            <div class="category-card active" onclick="switchCategory('time')">
                <div class="category-icon">⏰</div>
                <div class="category-title">峰谷时段划分</div>
                <div class="category-desc">配置电价峰谷时段划分标准</div>
            </div>
            <div class="category-card" onclick="switchCategory('display')">
                <div class="category-icon">📺</div>
                <div class="category-title">大屏展示配置</div>
                <div class="category-desc">配置大屏刷新频率和展示参数</div>
            </div>
            <div class="category-card" onclick="switchCategory('alarm')">
                <div class="category-icon">🚨</div>
                <div class="category-title">告警参数配置</div>
                <div class="category-desc">配置告警相关参数和阈值</div>
            </div>
            <div class="category-card" onclick="switchCategory('system')">
                <div class="category-icon">⚙️</div>
                <div class="category-title">系统参数配置</div>
                <div class="category-desc">配置系统运行参数</div>
            </div>
        </div>

        <div class="param-content">
            <div id="time-content" class="content-section">
                <div class="content-title">峰谷时段划分标准</div>
                
                <div class="param-group">
                    <div class="group-title">峰时段配置</div>
                    <div class="param-item">
                        <div class="param-label">峰时段1</div>
                        <div class="time-range">
                            <input type="time" class="param-input time-input" id="peak1Start" value="08:00">
                            <span>至</span>
                            <input type="time" class="param-input time-input" id="peak1End" value="12:00">
                        </div>
                        <div class="param-desc">上午峰时段，电价较高</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">峰时段2</div>
                        <div class="time-range">
                            <input type="time" class="param-input time-input" id="peak2Start" value="14:00">
                            <span>至</span>
                            <input type="time" class="param-input time-input" id="peak2End" value="17:00">
                        </div>
                        <div class="param-desc">下午峰时段，电价较高</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">峰时段3</div>
                        <div class="time-range">
                            <input type="time" class="param-input time-input" id="peak3Start" value="19:00">
                            <span>至</span>
                            <input type="time" class="param-input time-input" id="peak3End" value="21:00">
                        </div>
                        <div class="param-desc">晚间峰时段，电价最高</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">谷时段配置</div>
                    <div class="param-item">
                        <div class="param-label">谷时段1</div>
                        <div class="time-range">
                            <input type="time" class="param-input time-input" id="valley1Start" value="23:00">
                            <span>至</span>
                            <input type="time" class="param-input time-input" id="valley1End" value="07:00">
                        </div>
                        <div class="param-desc">夜间谷时段，电价最低</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">谷时段2</div>
                        <div class="time-range">
                            <input type="time" class="param-input time-input" id="valley2Start" value="12:00">
                            <span>至</span>
                            <input type="time" class="param-input time-input" id="valley2End" value="14:00">
                        </div>
                        <div class="param-desc">中午谷时段，电价较低</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">平时段配置</div>
                    <div class="param-item">
                        <div class="param-label">平时段说明</div>
                        <div class="param-desc">除峰谷时段外的其他时段为平时段，电价中等</div>
                    </div>
                </div>
            </div>

            <div id="display-content" class="content-section hidden">
                <div class="content-title">大屏展示配置</div>
                
                <div class="param-group">
                    <div class="group-title">刷新频率配置</div>
                    <div class="param-item">
                        <div class="param-label">数据刷新频率</div>
                        <input type="number" class="param-input" id="dataRefreshRate" value="5" min="1" max="60">
                        <div class="param-unit">秒</div>
                        <div class="param-desc">大屏数据自动刷新的时间间隔</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">告警刷新频率</div>
                        <input type="number" class="param-input" id="alarmRefreshRate" value="10" min="1" max="60">
                        <div class="param-unit">秒</div>
                        <div class="param-desc">告警信息自动刷新的时间间隔</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">图表刷新频率</div>
                        <input type="number" class="param-input" id="chartRefreshRate" value="30" min="1" max="300">
                        <div class="param-unit">秒</div>
                        <div class="param-desc">图表数据自动刷新的时间间隔</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">展示参数配置</div>
                    <div class="param-item">
                        <div class="param-label">显示历史数据天数</div>
                        <input type="number" class="param-input" id="historyDays" value="7" min="1" max="90">
                        <div class="param-unit">天</div>
                        <div class="param-desc">大屏显示的历史数据时间范围</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">实时数据保留时长</div>
                        <input type="number" class="param-input" id="realtimeRetention" value="24" min="1" max="168">
                        <div class="param-unit">小时</div>
                        <div class="param-desc">实时数据在数据库中的保留时长</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">告警显示数量</div>
                        <input type="number" class="param-input" id="alarmDisplayCount" value="10" min="5" max="50">
                        <div class="param-unit">条</div>
                        <div class="param-desc">大屏同时显示的告警数量</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">功能开关</div>
                    <div class="param-item">
                        <div class="param-label">启用自动刷新</div>
                        <label class="switch">
                            <input type="checkbox" id="autoRefresh" checked>
                            <span class="slider"></span>
                        </label>
                        <div class="param-desc">是否启用大屏数据自动刷新功能</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">启用动画效果</div>
                        <label class="switch">
                            <input type="checkbox" id="animationEffect" checked>
                            <span class="slider"></span>
                        </label>
                        <div class="param-desc">是否启用大屏数据变化的动画效果</div>
                    </div>
                </div>
            </div>

            <div id="alarm-content" class="content-section hidden">
                <div class="content-title">告警参数配置</div>
                
                <div class="param-group">
                    <div class="group-title">告警级别配置</div>
                    <div class="param-item">
                        <div class="param-label">高等级告警阈值</div>
                        <input type="number" class="param-input" id="highAlarmThreshold" value="90" min="1" max="100">
                        <div class="param-unit">%</div>
                        <div class="param-desc">设备参数超过此百分比时触发高等级告警</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">中等级告警阈值</div>
                        <input type="number" class="param-input" id="mediumAlarmThreshold" value="75" min="1" max="100">
                        <div class="param-unit">%</div>
                        <div class="param-desc">设备参数超过此百分比时触发中等级告警</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">低等级告警阈值</div>
                        <input type="number" class="param-input" id="lowAlarmThreshold" value="60" min="1" max="100">
                        <div class="param-unit">%</div>
                        <div class="param-desc">设备参数超过此百分比时触发低等级告警</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">告警处理配置</div>
                    <div class="param-item">
                        <div class="param-label">告警自动升级时间</div>
                        <input type="number" class="param-input" id="alarmEscalationTime" value="30" min="5" max="120">
                        <div class="param-unit">分钟</div>
                        <div class="param-desc">告警未处理时自动升级的时间间隔</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">告警重复通知间隔</div>
                        <input type="number" class="param-input" id="alarmNotifyInterval" value="15" min="5" max="60">
                        <div class="param-unit">分钟</div>
                        <div class="param-desc">未处理告警重复通知的时间间隔</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">告警历史保留天数</div>
                        <input type="number" class="param-input" id="alarmHistoryDays" value="90" min="30" max="365">
                        <div class="param-unit">天</div>
                        <div class="param-desc">告警历史记录在数据库中的保留天数</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">告警通知配置</div>
                    <div class="param-item">
                        <div class="param-label">启用邮件通知</div>
                        <label class="switch">
                            <input type="checkbox" id="emailNotify" checked>
                            <span class="slider"></span>
                        </label>
                        <div class="param-desc">是否启用告警邮件通知功能</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">启用短信通知</div>
                        <label class="switch">
                            <input type="checkbox" id="smsNotify">
                            <span class="slider"></span>
                        </label>
                        <div class="param-desc">是否启用告警短信通知功能</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">启用系统内通知</div>
                        <label class="switch">
                            <input type="checkbox" id="systemNotify" checked>
                            <span class="slider"></span>
                        </label>
                        <div class="param-desc">是否启用系统内告警通知功能</div>
                    </div>
                </div>
            </div>

            <div id="system-content" class="content-section hidden">
                <div class="content-title">系统参数配置</div>
                
                <div class="param-group">
                    <div class="group-title">数据采集配置</div>
                    <div class="param-item">
                        <div class="param-label">数据采集频率</div>
                        <input type="number" class="param-input" id="dataCollectionRate" value="1" min="1" max="60">
                        <div class="param-unit">分钟</div>
                        <div class="param-desc">设备数据采集的时间间隔</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">数据批量处理大小</div>
                        <input type="number" class="param-input" id="batchSize" value="1000" min="100" max="10000">
                        <div class="param-unit">条</div>
                        <div class="param-desc">批量处理数据时的记录数量</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">数据压缩阈值</div>
                        <input type="number" class="param-input" id="compressThreshold" value="30" min="1" max="365">
                        <div class="param-unit">天</div>
                        <div class="param-desc">超过此天数的历史数据将进行压缩存储</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">性能优化配置</div>
                    <div class="param-item">
                        <div class="param-label">查询超时时间</div>
                        <input type="number" class="param-input" id="queryTimeout" value="30" min="5" max="300">
                        <div class="param-unit">秒</div>
                        <div class="param-desc">数据库查询的最大执行时间</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">连接池最大连接数</div>
                        <input type="number" class="param-input" id="maxConnections" value="50" min="10" max="200">
                        <div class="param-unit">个</div>
                        <div class="param-desc">数据库连接池的最大连接数量</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">缓存过期时间</div>
                        <input type="number" class="param-input" id="cacheExpireTime" value="300" min="60" max="3600">
                        <div class="param-unit">秒</div>
                        <div class="param-desc">系统缓存的过期时间</div>
                    </div>
                </div>

                <div class="param-group">
                    <div class="group-title">安全配置</div>
                    <div class="param-item">
                        <div class="param-label">密码最小长度</div>
                        <input type="number" class="param-input" id="minPasswordLength" value="8" min="6" max="20">
                        <div class="param-unit">字符</div>
                        <div class="param-desc">用户密码的最小长度要求</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">登录失败锁定次数</div>
                        <input type="number" class="param-input" id="maxLoginAttempts" value="5" min="3" max="10">
                        <div class="param-unit">次</div>
                        <div class="param-desc">连续登录失败达到此次数后锁定账户</div>
                    </div>
                    <div class="param-item">
                        <div class="param-label">账户锁定时间</div>
                        <input type="number" class="param-input" id="lockoutDuration" value="30" min="5" max="120">
                        <div class="param-unit">分钟</div>
                        <div class="param-desc">账户锁定后的解锁时间</div>
                    </div>
                </div>
            </div>

            <div class="action-bar">
                <button class="btn btn-secondary" onclick="resetParams()">重置参数</button>
                <button class="btn btn-primary" onclick="saveParams()">保存配置</button>
            </div>
        </div>
    </div>

    <script>
        let currentCategory = 'time';

        function switchCategory(category) {
            currentCategory = category;
            
            document.querySelectorAll('.category-card').forEach(card => {
                card.classList.remove('active');
            });
            event.currentTarget.classList.add('active');
            
            document.querySelectorAll('.content-section').forEach(section => {
                section.classList.add('hidden');
            });
            document.getElementById(category + '-content').classList.remove('hidden');
        }

        function saveParams() {
            const params = {};
            
            if (currentCategory === 'time') {
                params.category = 'time';
                params.peak1Start = document.getElementById('peak1Start').value;
                params.peak1End = document.getElementById('peak1End').value;
                params.peak2Start = document.getElementById('peak2Start').value;
                params.peak2End = document.getElementById('peak2End').value;
                params.peak3Start = document.getElementById('peak3Start').value;
                params.peak3End = document.getElementById('peak3End').value;
                params.valley1Start = document.getElementById('valley1Start').value;
                params.valley1End = document.getElementById('valley1End').value;
                params.valley2Start = document.getElementById('valley2Start').value;
                params.valley2End = document.getElementById('valley2End').value;
            } else if (currentCategory === 'display') {
                params.category = 'display';
                params.dataRefreshRate = document.getElementById('dataRefreshRate').value;
                params.alarmRefreshRate = document.getElementById('alarmRefreshRate').value;
                params.chartRefreshRate = document.getElementById('chartRefreshRate').value;
                params.historyDays = document.getElementById('historyDays').value;
                params.realtimeRetention = document.getElementById('realtimeRetention').value;
                params.alarmDisplayCount = document.getElementById('alarmDisplayCount').value;
                params.autoRefresh = document.getElementById('autoRefresh').checked;
                params.animationEffect = document.getElementById('animationEffect').checked;
            } else if (currentCategory === 'alarm') {
                params.category = 'alarm';
                params.highAlarmThreshold = document.getElementById('highAlarmThreshold').value;
                params.mediumAlarmThreshold = document.getElementById('mediumAlarmThreshold').value;
                params.lowAlarmThreshold = document.getElementById('lowAlarmThreshold').value;
                params.alarmEscalationTime = document.getElementById('alarmEscalationTime').value;
                params.alarmNotifyInterval = document.getElementById('alarmNotifyInterval').value;
                params.alarmHistoryDays = document.getElementById('alarmHistoryDays').value;
                params.emailNotify = document.getElementById('emailNotify').checked;
                params.smsNotify = document.getElementById('smsNotify').checked;
                params.systemNotify = document.getElementById('systemNotify').checked;
            } else if (currentCategory === 'system') {
                params.category = 'system';
                params.dataCollectionRate = document.getElementById('dataCollectionRate').value;
                params.batchSize = document.getElementById('batchSize').value;
                params.compressThreshold = document.getElementById('compressThreshold').value;
                params.queryTimeout = document.getElementById('queryTimeout').value;
                params.maxConnections = document.getElementById('maxConnections').value;
                params.cacheExpireTime = document.getElementById('cacheExpireTime').value;
                params.minPasswordLength = document.getElementById('minPasswordLength').value;
                params.maxLoginAttempts = document.getElementById('maxLoginAttempts').value;
                params.lockoutDuration = document.getElementById('lockoutDuration').value;
            }

            fetch('${pageContext.request.contextPath}/api/admin/params', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(params)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showNotification('配置保存成功！', 'success');
                } else {
                    showNotification('配置保存失败：' + data.message, 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showNotification('配置保存失败：网络错误', 'error');
            });
        }

        function resetParams() {
            if (confirm('确定要重置当前类别的所有参数吗？')) {
                loadParams();
                showNotification('参数已重置', 'success');
            }
        }

        function loadParams() {
            fetch('${pageContext.request.contextPath}/api/admin/params?category=' + currentCategory)
            .then(response => response.json())
            .then(data => {
                if (data.success && data.params) {
                    const params = data.params;
                    
                    if (currentCategory === 'time') {
                        if (params.peak1Start) document.getElementById('peak1Start').value = params.peak1Start;
                        if (params.peak1End) document.getElementById('peak1End').value = params.peak1End;
                        if (params.peak2Start) document.getElementById('peak2Start').value = params.peak2Start;
                        if (params.peak2End) document.getElementById('peak2End').value = params.peak2End;
                        if (params.peak3Start) document.getElementById('peak3Start').value = params.peak3Start;
                        if (params.peak3End) document.getElementById('peak3End').value = params.peak3End;
                        if (params.valley1Start) document.getElementById('valley1Start').value = params.valley1Start;
                        if (params.valley1End) document.getElementById('valley1End').value = params.valley1End;
                        if (params.valley2Start) document.getElementById('valley2Start').value = params.valley2Start;
                        if (params.valley2End) document.getElementById('valley2End').value = params.valley2End;
                    } else if (currentCategory === 'display') {
                        if (params.dataRefreshRate) document.getElementById('dataRefreshRate').value = params.dataRefreshRate;
                        if (params.alarmRefreshRate) document.getElementById('alarmRefreshRate').value = params.alarmRefreshRate;
                        if (params.chartRefreshRate) document.getElementById('chartRefreshRate').value = params.chartRefreshRate;
                        if (params.historyDays) document.getElementById('historyDays').value = params.historyDays;
                        if (params.realtimeRetention) document.getElementById('realtimeRetention').value = params.realtimeRetention;
                        if (params.alarmDisplayCount) document.getElementById('alarmDisplayCount').value = params.alarmDisplayCount;
                        if (params.autoRefresh !== undefined) document.getElementById('autoRefresh').checked = params.autoRefresh;
                        if (params.animationEffect !== undefined) document.getElementById('animationEffect').checked = params.animationEffect;
                    } else if (currentCategory === 'alarm') {
                        if (params.highAlarmThreshold) document.getElementById('highAlarmThreshold').value = params.highAlarmThreshold;
                        if (params.mediumAlarmThreshold) document.getElementById('mediumAlarmThreshold').value = params.mediumAlarmThreshold;
                        if (params.lowAlarmThreshold) document.getElementById('lowAlarmThreshold').value = params.lowAlarmThreshold;
                        if (params.alarmEscalationTime) document.getElementById('alarmEscalationTime').value = params.alarmEscalationTime;
                        if (params.alarmNotifyInterval) document.getElementById('alarmNotifyInterval').value = params.alarmNotifyInterval;
                        if (params.alarmHistoryDays) document.getElementById('alarmHistoryDays').value = params.alarmHistoryDays;
                        if (params.emailNotify !== undefined) document.getElementById('emailNotify').checked = params.emailNotify;
                        if (params.smsNotify !== undefined) document.getElementById('smsNotify').checked = params.smsNotify;
                        if (params.systemNotify !== undefined) document.getElementById('systemNotify').checked = params.systemNotify;
                    } else if (currentCategory === 'system') {
                        if (params.dataCollectionRate) document.getElementById('dataCollectionRate').value = params.dataCollectionRate;
                        if (params.batchSize) document.getElementById('batchSize').value = params.batchSize;
                        if (params.compressThreshold) document.getElementById('compressThreshold').value = params.compressThreshold;
                        if (params.queryTimeout) document.getElementById('queryTimeout').value = params.queryTimeout;
                        if (params.maxConnections) document.getElementById('maxConnections').value = params.maxConnections;
                        if (params.cacheExpireTime) document.getElementById('cacheExpireTime').value = params.cacheExpireTime;
                        if (params.minPasswordLength) document.getElementById('minPasswordLength').value = params.minPasswordLength;
                        if (params.maxLoginAttempts) document.getElementById('maxLoginAttempts').value = params.maxLoginAttempts;
                        if (params.lockoutDuration) document.getElementById('lockoutDuration').value = params.lockoutDuration;
                    }
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
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
            loadParams();
        };
    </script>
</body>
</html>
