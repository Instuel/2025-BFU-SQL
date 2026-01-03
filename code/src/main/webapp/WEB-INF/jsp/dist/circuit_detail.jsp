<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;">
    <div>
      <h2>配电网监测 - 回路详情</h2>
      <div style="color:#64748b;font-size:12px;margin-top:4px;">回路编号：<c:out value="${circuit.circuitId}" default="-"/></div>
    </div>
    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=circuit_list">返回列表</a>
  </div>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card" style="margin-bottom:18px;">
    <h3 style="margin-bottom:12px;">回路基础信息</h3>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;">
      <div>
        <div style="color:#94a3b8;font-size:12px;">所属配电房</div>
        <div style="font-weight:600;"><c:out value="${circuit.roomName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">设备编号</div>
        <div style="font-weight:600;"><c:out value="${circuit.ledgerName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">电压等级</div>
        <div style="font-weight:600;"><c:out value="${circuit.voltageLevel}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">开关状态</div>
        <div><span class="status-badge normal">以最新监测为准</span></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">运行状态</div>
        <div><span class="status-badge normal">实时监测</span></div>
      </div>
    </div>
  </div>

  <div class="card" style="margin-bottom:18px;">
    <div style="display:flex;align-items:center;justify-content:space-between;">
      <h3>最新监测数据</h3>
      <a class="btn btn-link" href="${pageContext.request.contextPath}/dist?module=dist&action=data_circuit_list">查看历史数据</a>
    </div>
    <table class="table" style="width:100%;margin-top:12px;">
      <thead>
      <tr>
        <th>采集时间</th>
        <th>电压(kV)</th>
        <th>电流(A)</th>
        <th>有功功率(kW)</th>
        <th>无功功率(kVar)</th>
        <th>功率因数</th>
        <th>开关状态</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${circuitData}" var="item">
        <tr>
          <td><c:out value="${item.collectTime}" default="-"/></td>
          <td><c:out value="${item.voltage}" default="-"/></td>
          <td><c:out value="${item.currentVal}" default="-"/></td>
          <td><c:out value="${item.activePower}" default="-"/></td>
          <td><c:out value="${item.reactivePower}" default="-"/></td>
          <td><c:out value="${item.powerFactor}" default="-"/></td>
          <td><c:out value="${item.switchStatus}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty circuitData}">
        <tr>
          <td colspan="7" style="text-align:center;color:#94a3b8;">暂无监测数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>

  <div class="card">
    <h3 style="margin-bottom:12px;">运维处理记录</h3>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>工单编号</th>
        <th>派单时间</th>
        <th>处理结果</th>
        <th>复查状态</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${workOrders}" var="order">
        <tr>
          <td>${order.orderId}</td>
          <td><c:out value="${order.dispatchTime}" default="-"/></td>
          <td><c:out value="${order.resultDesc}" default="-"/></td>
          <td><c:out value="${order.reviewStatus}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty workOrders}">
        <tr>
          <td colspan="4" style="text-align:center;color:#94a3b8;">暂无运维工单记录</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
