<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<c:set var="recentTotal" value="${fn:length(recentProjects)}"/>
<c:set var="openTotal" value="${fn:length(openProjects)}"/>
<c:set var="closedTotal" value="0"/>
<c:set var="pendingTotal" value="0"/>

<c:forEach items="${recentProjects}" var="rp">
  <c:set var="st" value="${not empty rp.projectStatus ? rp.projectStatus : rp.status}"/>
  <c:if test="${st == '已结题'}"><c:set var="closedTotal" value="${closedTotal + 1}"/></c:if>
  <c:if test="${st != '已结题'}"><c:set var="pendingTotal" value="${pendingTotal + 1}"/></c:if>
</c:forEach>

<div class="main-content dashboard-page">
  <div class="dashboard-container exec-project">

    <div class="dashboard-header">
      <div class="exec-project-hero">
        <div>
          <div class="hero-title">
            <span class="hero-badge">科研项目</span>
            <h1>申报 / 结题</h1>
          </div>
          <p>提交科研项目申请与结题报告（企业管理层入口）。建议先提交申请，项目推进完成后再提交结题。</p>
        </div>

        <div class="exec-screen-actions">
          <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execDesk">← 返回工作台</a>
        </div>
      </div>
    </div>

    <c:if test="${not empty execFlashMessage}">
      <div class="dashboard-alert ${execFlashType}">
        <c:out value="${execFlashMessage}"/>
      </div>
    </c:if>

    <!-- 统计概览 -->
    <div class="exec-stat-grid">
      <div class="exec-stat-card">
        <div class="exec-stat-k">最近项目</div>
        <div class="exec-stat-v"><c:out value="${recentTotal}"/></div>
        <div class="exec-stat-sub">列表默认展示最近数据</div>
      </div>
      <div class="exec-stat-card">
        <div class="exec-stat-k">可结题项目</div>
        <div class="exec-stat-v"><c:out value="${openTotal}"/></div>
        <div class="exec-stat-sub">申请中 / 进行中</div>
      </div>
      <div class="exec-stat-card">
        <div class="exec-stat-k">已结题</div>
        <div class="exec-stat-v"><c:out value="${closedTotal}"/></div>
        <div class="exec-stat-sub">以项目状态为准</div>
      </div>
      <div class="exec-stat-card">
        <div class="exec-stat-k">未结题</div>
        <div class="exec-stat-v"><c:out value="${pendingTotal}"/></div>
        <div class="exec-stat-sub">包含申请中 / 进行中</div>
      </div>
    </div>

    <div class="exec-two-col">
      <!-- 申报 -->
      <section class="dashboard-chart-section">
        <div class="dashboard-chart-header">
          <div>
            <div class="dashboard-chart-title">提交科研项目申请</div>
            <div class="dashboard-section-hint">填写项目名称与摘要后提交，状态默认“申请中”。</div>
          </div>
        </div>

        <form class="dashboard-form" method="post" action="${ctx}/app">
          <input type="hidden" name="module" value="dashboard"/>
          <input type="hidden" name="action" value="projectApply"/>
          <input type="hidden" name="returnView" value="execProject"/>

          <!-- 按“上下”排版：项目名称在上、摘要在下（避免 label/输入框同行挤压） -->
          <div class="dashboard-form-row">
            <label>项目名称<span class="exec-required">*</span></label>
            <input class="dashboard-input" type="text" name="projectTitle" maxlength="100" placeholder="例如：企业能耗预测与优化" required/>
          </div>

          <div class="dashboard-form-row">
            <label>项目摘要</label>
            <textarea class="dashboard-textarea" name="projectSummary" rows="6" maxlength="800" placeholder="项目背景、目标、研究路线、预期成果..."></textarea>
          </div>

          <div class="exec-form-hint">
            建议摘要包含：问题背景、目标指标、数据来源、预期成果（论文/专利/系统/节能收益），方便后续结题对照。
          </div>

          <div class="dashboard-form-actions">
            <button type="submit" class="dashboard-btn primary">提交申请</button>
          </div>
        </form>
      </section>

      <!-- 结题 -->
      <section class="dashboard-chart-section">
        <div class="dashboard-chart-header">
          <div>
            <div class="dashboard-chart-title">提交结题报告</div>
            <div class="dashboard-section-hint">仅可对“申请中/进行中”的项目提交结题，提交后状态变更为“已结题”。</div>
          </div>
        </div>

        <form class="dashboard-form" method="post" action="${ctx}/app">
          <input type="hidden" name="module" value="dashboard"/>
          <input type="hidden" name="action" value="projectClose"/>
          <input type="hidden" name="returnView" value="execProject"/>

          <!-- 按“上下”排版：选择项目在上、结题报告在下 -->
          <div class="dashboard-form-row">
            <label>选择项目<span class="exec-required">*</span></label>
            <select class="dashboard-input" name="projectId" required>
              <option value="">-- 请选择 --</option>
              <c:forEach items="${openProjects}" var="p">
                <option value="${p.projectId}">
                  <c:out value="${not empty p.projectTitle ? p.projectTitle : p.title}"/>
                  （<c:out value="${not empty p.projectStatus ? p.projectStatus : p.status}"/>）
                </option>
              </c:forEach>
            </select>
          </div>

          <div class="dashboard-form-row">
            <label>结题报告<span class="exec-required">*</span></label>
            <textarea class="dashboard-textarea" name="closeReport" rows="8" maxlength="1200"
                      placeholder="总结成果、关键指标、落地情况、节能收益、风险与后续建议..." required></textarea>
          </div>

          <div class="exec-form-hint">
            建议结题内容包含：完成情况（对照申请目标）、数据与实验结果、上线/落地证明、收益评估、后续优化点。
          </div>

          <div class="dashboard-form-actions">
            <button type="submit" class="dashboard-btn primary">提交结题</button>
          </div>
        </form>

        <c:if test="${empty openProjects}">
          <div class="dashboard-empty" style="margin-top:10px;">暂无可结题项目。</div>
        </c:if>
      </section>
    </div>

    <!-- 列表 -->
    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">项目列表</div>
          <div class="dashboard-section-hint">展示最近项目（可扩展为审批流 / 附件 / 里程碑 / 负责人等）。</div>
        </div>
      </div>

      <c:choose>
        <c:when test="${empty recentProjects}">
          <div class="dashboard-empty">暂无项目数据。</div>
        </c:when>
        <c:otherwise>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>项目编号</th>
                <th>项目名称</th>
                <th>状态</th>
                <th>申请人</th>
                <th>申请时间</th>
                <th>结题时间</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach items="${recentProjects}" var="p">
                <tr>
                  <td><c:out value="${p.projectId}"/></td>
                  <td class="cell-wrap"><c:out value="${not empty p.projectTitle ? p.projectTitle : p.title}"/></td>
                  <td>
                    <c:set var="statusText" value="${not empty p.projectStatus ? p.projectStatus : p.status}"/>
                    <c:set var="tagCls" value="${statusText == '已结题' ? 'success' : (statusText == '申请中' ? 'warning' : 'info')}"/>
                    <span class="workbench-tag <c:out value='${tagCls}'/>"><c:out value="${statusText}"/></span>
                  </td>
                  <td><c:out value="${p.applicant}"/></td>
                  <td><c:out value="${not empty p.applyDate ? p.applyDate : p.applyTime}"/></td>
                  <td><c:out value="${not empty p.closeDate ? p.closeDate : p.closeTime}"/></td>
                </tr>

                <c:if test="${not empty p.projectSummary || not empty p.summary || not empty p.closeReport}">
                  <tr class="row-sub">
                    <td colspan="6">
                      <c:if test="${not empty p.projectSummary || not empty p.summary}">
                        <div class="subtext"><b>摘要：</b><c:out value="${not empty p.projectSummary ? p.projectSummary : p.summary}"/></div>
                      </c:if>
                      <c:if test="${not empty p.closeReport}">
                        <div class="subtext"><b>结题：</b><c:out value="${p.closeReport}"/></div>
                      </c:if>
                    </td>
                  </tr>
                </c:if>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
