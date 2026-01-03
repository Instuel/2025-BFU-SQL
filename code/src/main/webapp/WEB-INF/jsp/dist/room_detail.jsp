<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;">
    <div>
      <h2>配电网监测 - 配电房详情</h2>
      <div style="color:#64748b;font-size:12px;margin-top:4px;">配电房编号：<c:out value="${room.roomId}" default="-"/></div>
    </div>
    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=room_list">返回列表</a>
  </div>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card" style="margin-bottom:18px;">
    <h3 style="margin-bottom:12px;">基础信息</h3>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;">
      <div>
        <div style="color:#94a3b8;font-size:12px;">名称</div>
        <div style="font-weight:600;"><c:out value="${room.roomName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">位置描述</div>
        <div style="font-weight:600;"><c:out value="${room.location}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">电压等级</div>
        <div style="font-weight:600;"><c:out value="${room.voltageLevel}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">变压器数量</div>
        <div style="font-weight:600;">${fn:length(transformers)}</div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">所属厂区</div>
        <div style="font-weight:600;"><c:out value="${room.factoryName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">负责人</div>
        <div style="font-weight:600;"><c:out value="${room.managerName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">联系方式</div>
        <div style="font-weight:600;"><c:out value="${room.managerPhone}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">运行状态</div>
        <div><span class="status-badge normal">运行中</span></div>
      </div>
    </div>
  </div>

  <div class="card" style="margin-bottom:18px;">
    <h3 style="margin-bottom:12px;">关联回路</h3>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>回路编号</th>
        <th>回路名称</th>
        <th>最新电压(kV)</th>
        <th>电流(A)</th>
        <th>有功功率(kW)</th>
        <th>功率因数</th>
        <th>采集时间</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${circuits}" var="circuit">
        <tr>
          <td>${circuit.circuitId}</td>
          <td><c:out value="${circuit.circuitName}" default="-"/></td>
          <td><c:out value="${circuit.voltage}" default="-"/></td>
          <td><c:out value="${circuit.currentVal}" default="-"/></td>
          <td><c:out value="${circuit.activePower}" default="-"/></td>
          <td><c:out value="${circuit.powerFactor}" default="-"/></td>
          <td><c:out value="${circuit.collectTime}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty circuits}">
        <tr>
          <td colspan="7" style="text-align:center;color:#94a3b8;">暂无回路数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>

  <div class="card">
    <h3 style="margin-bottom:12px;">关联变压器</h3>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>变压器编号</th>
        <th>变压器名称</th>
        <th>负载率(%)</th>
        <th>绕组温度(℃)</th>
        <th>铁芯温度(℃)</th>
        <th>采集时间</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${transformers}" var="transformer">
        <tr>
          <td>${transformer.transformerId}</td>
          <td><c:out value="${transformer.transformerName}" default="-"/></td>
          <td><c:out value="${transformer.loadRate}" default="-"/></td>
          <td><c:out value="${transformer.windingTemp}" default="-"/></td>
          <td><c:out value="${transformer.coreTemp}" default="-"/></td>
          <td><c:out value="${transformer.collectTime}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty transformers}">
        <tr>
          <td colspan="6" style="text-align:center;color:#94a3b8;">暂无变压器数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
