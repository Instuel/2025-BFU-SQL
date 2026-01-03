<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>配电网监测 - 变压器监测数据</h2>
  <p style="color:#64748b;margin-top:6px;">异常运行状态触发告警联动。</p>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-weight:600;font-size:16px;">变压器监测数据清单</div>
        <div style="color:#94a3b8;font-size:12px;margin-top:4px;">支持按时间范围/设备筛选</div>
      </div>
      <form method="get" action="${pageContext.request.contextPath}/dist" style="display:flex;gap:12px;flex-wrap:wrap;">
        <input type="hidden" name="module" value="dist"/>
        <input type="hidden" name="action" value="data_transformer_list"/>
        <label>变压器编号
          <select name="transformerId" style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option value="">全部</option>
            <c:forEach items="${transformerOptions}" var="option">
              <option value="${option.transformerId}" <c:if test="${selectedTransformerId == option.transformerId}">selected</c:if>>
                ${option.transformerName} (#${option.transformerId})
              </option>
            </c:forEach>
          </select>
        </label>
        <button class="btn btn-primary">筛选</button>
      </form>
    </div>

    <table class="table" style="margin-top:16px;width:100%;">
      <thead>
      <tr>
        <th>数据编号</th>
        <th>变压器编号</th>
        <th>采集时间</th>
        <th>负载率(%)</th>
        <th>绕组温度(℃)</th>
        <th>铁芯温度(℃)</th>
        <th>运行状态</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${transformerData}" var="item">
        <tr>
          <td>${item.dataId}</td>
          <td>${item.transformerName} (#${item.transformerId})</td>
          <td><c:out value="${item.collectTime}" default="-"/></td>
          <td><c:out value="${item.loadRate}" default="-"/></td>
          <td><c:out value="${item.windingTemp}" default="-"/></td>
          <td><c:out value="${item.coreTemp}" default="-"/></td>
          <td><span class="status-badge normal">运行中</span></td>
        </tr>
      </c:forEach>
      <c:if test="${empty transformerData}">
        <tr>
          <td colspan="7" style="text-align:center;color:#94a3b8;">暂无变压器监测数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
