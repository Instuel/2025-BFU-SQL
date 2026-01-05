<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>配电网监测 - 变压器列表</h2>
  <p style="color:#64748b;margin-top:6px;">关注负载率与绕组温度，异常状态触发告警。</p>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-weight:600;font-size:16px;">变压器运行清单</div>
        <div style="color:#94a3b8;font-size:12px;margin-top:4px;">运行状态为异常时需联动告警</div>
      </div>
      <form action="${pageContext.request.contextPath}/dist" method="get" style="display:flex;gap:12px;flex-wrap:wrap;">
        <input type="hidden" name="module" value="dist"/>
        <input type="hidden" name="action" value="transformer_list"/>
        <label>设备运行状态
          <select name="transformerStatus" style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option value="">全部</option>
            <option value="正常" <c:if test="${transformerStatus == '正常'}">selected</c:if>>正常</option>
            <option value="异常" <c:if test="${transformerStatus == '异常'}">selected</c:if>>异常</option>
          </select>
        </label>
        <button class="btn btn-primary" type="submit">筛选</button>
      </form>
    </div>

    <table class="table" style="margin-top:16px;width:100%;">
      <thead>
      <tr>
        <th>变压器编号</th>
        <th>所属配电房</th>
        <th>负载率</th>
        <th>绕组温度(℃)</th>
        <th>铁芯温度(℃)</th>
        <th>采集时间</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${transformers}" var="transformer">
        <tr>
          <td>${transformer.transformerId}</td>
          <td><c:out value="${transformer.roomName}" default="-"/></td>
          <td><c:out value="${transformer.loadRate}" default="-"/></td>
          <td><c:out value="${transformer.windingTemp}" default="-"/></td>
          <td><c:out value="${transformer.coreTemp}" default="-"/></td>
          <td><c:out value="${transformer.collectTime}" default="-"/></td>
          <td>
            <a class="btn btn-link" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_detail&id=${transformer.transformerId}">详情</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty transformers}">
        <tr>
          <td colspan="7" style="text-align:center;color:#94a3b8;">暂无变压器数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
    
    <c:if test="${transformerTotalCount > 0}">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-top:16px;padding-top:16px;border-top:1px solid #e2e8f0;">
        <div style="color:#64748b;font-size:14px;">
          共 ${transformerTotalCount} 条记录，第 ${transformerPage} / <c:out value="${(transformerTotalCount + transformerPageSize - 1) / transformerPageSize}" default="1"/> 页
        </div>
        <div style="display:flex;gap:8px;">
          <c:if test="${transformerPage > 1}">
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_list&transformerStatus=${transformerStatus}&page=1">首页</a>
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_list&transformerStatus=${transformerStatus}&page=${transformerPage - 1}">上一页</a>
          </c:if>
          <c:if test="${transformerPage < (transformerTotalCount + transformerPageSize - 1) / transformerPageSize}">
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_list&transformerStatus=${transformerStatus}&page=${transformerPage + 1}">下一页</a>
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_list&transformerStatus=${transformerStatus}&page=${(transformerTotalCount + transformerPageSize - 1) / transformerPageSize}">末页</a>
          </c:if>
        </div>
      </div>
    </c:if>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
