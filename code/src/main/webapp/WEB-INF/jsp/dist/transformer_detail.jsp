<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;justify-content:space-between;">
    <div>
      <h2>配电网监测 - 变压器详情</h2>
      <div style="color:#64748b;font-size:12px;margin-top:4px;">变压器编号：<c:out value="${transformer.transformerId}" default="-"/></div>
    </div>
    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dist?module=dist&action=transformer_list">返回列表</a>
  </div>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div class="card" style="margin-bottom:18px;">
    <h3 style="margin-bottom:12px;">基础信息</h3>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;">
      <div>
        <div style="color:#94a3b8;font-size:12px;">所属配电房</div>
        <div style="font-weight:600;"><c:out value="${transformer.roomName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">台账号</div>
        <div style="font-weight:600;"><c:out value="${transformer.ledgerName}" default="-"/></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">运行状态</div>
        <div><span class="status-badge normal">实时监测</span></div>
      </div>
      <div>
        <div style="color:#94a3b8;font-size:12px;">规格型号</div>
        <div style="font-weight:600;"><c:out value="${transformer.modelSpec}" default="-"/></div>
      </div>
    </div>
  </div>

  <div class="card" style="margin-bottom:18px;">
    <div style="display:flex;align-items:center;justify-content:space-between;">
      <h3>最新监测数据</h3>
      <a class="btn btn-link" href="${pageContext.request.contextPath}/dist?module=dist&action=data_transformer_list">查看历史数据</a>
    </div>
    <table class="table" style="width:100%;margin-top:12px;">
      <thead>
      <tr>
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
          <td><c:out value="${item.collectTime}" default="-"/></td>
          <td><c:out value="${item.loadRate}" default="-"/></td>
          <td><c:out value="${item.windingTemp}" default="-"/></td>
          <td><c:out value="${item.coreTemp}" default="-"/></td>
          <td><span class="status-badge normal">运行中</span></td>
        </tr>
      </c:forEach>
      <c:if test="${empty transformerData}">
        <tr>
          <td colspan="5" style="text-align:center;color:#94a3b8;">暂无监测数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>

  <div class="card">
    <h3 style="margin-bottom:12px;">关联告警</h3>
    <table class="table" style="width:100%;">
      <thead>
      <tr>
        <th>告警编号</th>
        <th>告警类型</th>
        <th>发生时间</th>
        <th>等级</th>
        <th>告警内容</th>
        <th>处理状态</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${alarmItems}" var="alarm">
        <tr>
          <td>${alarm.alarmId}</td>
          <td><c:out value="${alarm.alarmType}" default="-"/></td>
          <td><c:out value="${alarm.occurTime}" default="-"/></td>
          <td><c:out value="${alarm.alarmLevel}" default="-"/></td>
          <td><c:out value="${alarm.content}" default="-"/></td>
          <td><span class="status-badge normal"><c:out value="${alarm.processStatus}" default="-"/></span></td>
        </tr>
      </c:forEach>
      <c:if test="${empty alarmItems}">
        <tr>
          <td colspan="6" style="text-align:center;color:#94a3b8;">暂无关联告警</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
