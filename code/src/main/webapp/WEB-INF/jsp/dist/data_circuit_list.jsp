<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>配电网监测 - 回路监测数据</h2>
  <p style="color:#64748b;margin-top:6px;">分钟级采集，越限数据自动标记。</p>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-weight:600;font-size:16px;">回路监测数据清单</div>
        <div style="color:#94a3b8;font-size:12px;margin-top:4px;">支持按时间范围/回路筛选</div>
      </div>
      <form method="get" action="${pageContext.request.contextPath}/dist" style="display:flex;gap:12px;flex-wrap:wrap;">
        <input type="hidden" name="module" value="dist"/>
        <input type="hidden" name="action" value="data_circuit_list"/>
        <label>回路编号
          <select name="circuitId" style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option value="">全部</option>
            <c:forEach items="${circuitOptions}" var="option">
              <option value="${option.circuitId}" <c:if test="${selectedCircuitId == option.circuitId}">selected</c:if>>
                ${option.circuitName} (#${option.circuitId})
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
        <th>回路编号</th>
        <th>采集时间</th>
        <th>电压(kV)</th>
        <th>电流(A)</th>
        <th>有功功率(kW)</th>
        <th>无功功率(kVar)</th>
        <th>功率因数</th>
        <th>开关状态</th>
        <th>所属配电房</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${circuitData}" var="item">
        <tr>
          <td>${item.dataId}</td>
          <td>${item.circuitName} (#${item.circuitId})</td>
          <td><c:out value="${item.collectTime}" default="-"/></td>
          <td><c:out value="${item.voltage}" default="-"/></td>
          <td><c:out value="${item.currentVal}" default="-"/></td>
          <td><c:out value="${item.activePower}" default="-"/></td>
          <td><c:out value="${item.reactivePower}" default="-"/></td>
          <td><c:out value="${item.powerFactor}" default="-"/></td>
          <td><c:out value="${item.switchStatus}" default="-"/></td>
          <td><c:out value="${item.roomName}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty circuitData}">
        <tr>
          <td colspan="10" style="text-align:center;color:#94a3b8;">暂无回路监测数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
