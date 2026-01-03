<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>工作台 / 大屏总览</h2>
  <p>【占位】根据任务书业务线5：展示实时汇总（分钟级更新）与历史趋势（同比/环比）等。</p>
  <ul>
    <li>实时汇总：总用电/用水/蒸汽/天然气、光伏发电、自用电、告警统计…</li>
    <li>历史趋势：能源类型 + 周期（日/周/月） + 同比/环比 + 行业均值（可选）</li>
  </ul>
  <div style="border:1px dashed #aaa;padding:12px;border-radius:8px;">
    <b>占位组件</b>：这里后续接入图表/卡片/表格。
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
