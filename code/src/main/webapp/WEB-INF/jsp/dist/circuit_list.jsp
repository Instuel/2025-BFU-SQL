<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>配电网监测 - 回路列表</h2>
  <p style="color:#64748b;margin-top:6px;">分钟级采集，支持电压/电流越限标记。</p>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-weight:600;font-size:16px;">回路运行清单</div>
        <div style="color:#94a3b8;font-size:12px;margin-top:4px;">异常回路将高亮展示</div>
      </div>
      <div style="display:flex;gap:12px;flex-wrap:wrap;">
        <label>所属配电房
          <select style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option>全部</option>
            <option>DR-001 总配电房</option>
            <option>DR-002 分配电房 1</option>
          </select>
        </label>
        <label>异常状态
          <select style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option>全部</option>
            <option>正常</option>
            <option>异常</option>
          </select>
        </label>
        <button class="btn btn-primary">筛选</button>
      </div>
    </div>

    <table class="table" style="margin-top:16px;width:100%;">
      <thead>
      <tr>
        <th>回路编号</th>
        <th>回路名称</th>
        <th>所属配电房</th>
        <th>电压(kV)</th>
        <th>电流(A)</th>
        <th>有功功率(kW)</th>
        <th>功率因数</th>
        <th>开关状态</th>
        <th>采集时间</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${circuits}" var="circuit">
        <tr>
          <td>${circuit.circuitId}</td>
          <td><c:out value="${circuit.circuitName}" default="-"/></td>
          <td><c:out value="${circuit.roomName}" default="-"/></td>
          <td><c:out value="${circuit.voltage}" default="-"/></td>
          <td><c:out value="${circuit.currentVal}" default="-"/></td>
          <td><c:out value="${circuit.activePower}" default="-"/></td>
          <td><c:out value="${circuit.powerFactor}" default="-"/></td>
          <td><c:out value="${circuit.switchStatus}" default="-"/></td>
          <td><c:out value="${circuit.collectTime}" default="-"/></td>
          <td>
            <a class="btn btn-link" href="${pageContext.request.contextPath}/dist?module=dist&action=circuit_detail&id=${circuit.circuitId}">详情</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty circuits}">
        <tr>
          <td colspan="10" style="text-align:center;color:#94a3b8;">暂无回路数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
