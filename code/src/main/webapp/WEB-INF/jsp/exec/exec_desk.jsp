<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<div class="main-content dashboard-page">
  <div class="dashboard-container exec-desk">
    <div class="dashboard-header">
      <h1>企业管理层工作台</h1>
      <p>四个入口直达：大屏、告警推送、能耗总结、科研项目。</p>
    </div>

    <div class="exec-entry-grid">
      <a class="exec-entry-card" href="${ctx}/app?module=dashboard&view=execScreen">
        <div class="exec-entry-icon">🖥️</div>
        <div class="exec-entry-title">大屏</div>
        <div class="exec-entry-desc">查看大屏展示配置、实时汇总与历史趋势。</div>
        <div class="exec-entry-meta">业务线5 · 实时/趋势</div>
      </a>

      <a class="exec-entry-card" href="${ctx}/alarm?action=list&alarmLevel=高">
        <div class="exec-entry-icon">🚨</div>
        <div class="exec-entry-title">接收高等级告警推送</div>
        <div class="exec-entry-desc">快速查看高等级告警列表，辅助管理层决策。</div>
        <div class="exec-entry-meta">跳转至告警运维</div>
      </a>

      <a class="exec-entry-card" href="${ctx}/app?module=energy&view=report_overview">
        <div class="exec-entry-icon">📈</div>
        <div class="exec-entry-title">查看月度 / 季度能耗总结报告</div>
        <div class="exec-entry-desc">进入综合能耗模块查看月度与季度总结分析。</div>
        <div class="exec-entry-meta">跳转至综合能耗</div>
      </a>

      <a class="exec-entry-card" href="${ctx}/app?module=dashboard&view=execProject">
        <div class="exec-entry-icon">🧪</div>
        <div class="exec-entry-title">提交科研项目申请与结题报告</div>
        <div class="exec-entry-desc">科研项目申报、结题闭环（后续可扩展流程）。</div>
        <div class="exec-entry-meta">支持申报、结题与进度查看</div>
      </a>
    </div>

    <div class="dashboard-callout" style="margin-top:22px;">
      提示：目前已优先实现 <b>“大屏”</b> 功能，其余入口已完成跳转（可继续按需求细化页面）。
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
