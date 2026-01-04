<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<div class="main-content dashboard-page">
  <div class="dashboard-container exec-project">
    <div class="dashboard-header">
      <div class="exec-screen-topbar">
        <div>
          <h1>科研项目</h1>
          <p>提交科研项目申请与结题报告（管理层入口）</p>
        </div>
        <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execDesk">← 返回工作台</a>
      </div>
    </div>

    <c:if test="${not empty execFlashMessage}">
      <div class="dashboard-alert ${execFlashType}">
        <c:out value="${execFlashMessage}"/>
      </div>
    </c:if>

    <div class="exec-two-col">
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

          <label>项目名称</label>
          <input class="dashboard-input" type="text" name="projectTitle" maxlength="100" placeholder="例如：企业能耗预测与优化" required/>

          <label style="margin-top:10px;">项目摘要</label>
          <textarea class="dashboard-textarea" name="projectSummary" rows="5" maxlength="800" placeholder="项目背景、目标、预期成果..."></textarea>

          <div class="dashboard-form-actions">
            <button type="submit" class="dashboard-btn primary">提交申请</button>
          </div>
        </form>
      </section>

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

          <label>选择项目</label>
          <select class="dashboard-input" name="projectId" required>
            <option value="">-- 请选择 --</option>
            <c:forEach items="${openProjects}" var="p">
              <option value="${p.projectId}"><c:out value="${p.title}"/>（<c:out value="${p.status}"/>）</option>
            </c:forEach>
          </select>

          <label style="margin-top:10px;">结题报告</label>
          <textarea class="dashboard-textarea" name="closeReport" rows="6" maxlength="1200" placeholder="总结成果、关键指标、落地情况、后续建议..." required></textarea>

          <div class="dashboard-form-actions">
            <button type="submit" class="dashboard-btn primary">提交结题</button>
          </div>
        </form>

        <c:if test="${empty openProjects}">
          <div class="dashboard-empty" style="margin-top:10px;">暂无可结题项目。</div>
        </c:if>
      </section>
    </div>

    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">项目列表</div>
          <div class="dashboard-section-hint">展示最近项目（可扩展为审批流/附件/里程碑等）。</div>
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
                  <td class="cell-wrap"><c:out value="${p.title}"/></td>
                  <td>
                    <span class="workbench-tag <c:out value='${p.status=="已结题" ? "success" : "info"}'/>"><c:out value="${p.status}"/></span>
                  </td>
                  <td><c:out value="${p.applicant}"/></td>
                  <td><c:out value="${p.applyTime}"/></td>
                  <td><c:out value="${p.closeTime}"/></td>
                </tr>
                <c:if test="${not empty p.summary || not empty p.closeReport}">
                  <tr class="row-sub">
                    <td colspan="6">
                      <c:if test="${not empty p.summary}">
                        <div class="subtext"><b>摘要：</b><c:out value="${p.summary}"/></div>
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
