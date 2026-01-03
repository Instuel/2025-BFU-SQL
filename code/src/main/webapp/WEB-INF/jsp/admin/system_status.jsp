<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>系统管理 - 系统状态</h2>
  <%@ include file="/WEB-INF/jsp/admin/admin_nav.jsp" %>

  <div class="stats-grid stats-grid-4" style="margin-top:16px;">
    <div class="stat-card energy">
      <div class="stat-label">系统用户</div>
      <div class="stat-value small">${systemCounters.userCount}</div>
      <div class="stat-change positive">账号总量</div>
    </div>
    <div class="stat-card pv">
      <div class="stat-label">角色类型</div>
      <div class="stat-value small">${systemCounters.roleCount}</div>
      <div class="stat-change positive">已分配角色</div>
    </div>
    <div class="stat-card alarm">
      <div class="stat-label">告警规则</div>
      <div class="stat-value small">${systemCounters.alarmRuleCount}</div>
      <div class="stat-change negative">需定期复核</div>
    </div>
    <div class="stat-card success">
      <div class="stat-label">权限条目</div>
      <div class="stat-value small">${systemCounters.permissionCount}</div>
      <div class="stat-change positive">模块授权</div>
    </div>
  </div>

  <div class="content-grid" style="margin-top:16px;">
    <div class="card">
      <h3 style="margin-bottom:16px;">数据库运行状态</h3>
      <table class="table" style="width:100%;">
        <tbody>
        <tr>
          <th style="width:160px;">最新备份时间</th>
          <td>${latestBackupTime}</td>
        </tr>
        <tr>
          <th>最近备份次数</th>
          <td>${systemCounters.backupCount}</td>
        </tr>
        <tr>
          <th>查询响应时间</th>
          <td>${dbLatencyMs} ms</td>
        </tr>
        <tr>
          <th>监控建议</th>
          <td>建议每日核查备份完整性，并在磁盘占用超过 75% 时发起扩容评估。</td>
        </tr>
        </tbody>
      </table>
    </div>
    <div class="card">
      <h3 style="margin-bottom:16px;">系统健康提醒</h3>
      <ul class="list">
        <li class="list-item">今日告警规则变更：2 项（需完成复核）</li>
        <li class="list-item">峰谷时段配置：4 套处于生效状态</li>
        <li class="list-item">权限清单与角色映射：建议每季度复核</li>
        <li class="list-item">备份恢复演练：下次计划 2025-04-05</li>
      </ul>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
