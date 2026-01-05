<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>配电网监测 - 配电房总览</h2>
  <p style="color:#64748b;margin-top:6px;">覆盖配电房基础信息、负责人、运行状态与数据完整性。</p>

  <%@ include file="/WEB-INF/jsp/dist/_dist_nav.jsp" %>

  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-bottom:18px;">
    <div class="stat-card energy">
      <div class="stat-label">配电房数量</div>
      <div class="stat-value">${roomStats.roomCount}</div>
      <div class="stat-change positive">配电房总数</div>
    </div>
    <div class="stat-card alarm">
      <div class="stat-label">回路数量</div>
      <div class="stat-value small">${roomStats.circuitCount}</div>
      <div class="stat-change positive">已接入回路</div>
    </div>
    <div class="stat-card success">
      <div class="stat-label">变压器数量</div>
      <div class="stat-value small">${roomStats.transformerCount}</div>
      <div class="stat-change positive">关联设备</div>
    </div>
    <div class="stat-card pv">
      <div class="stat-label">最新采集时间</div>
      <div class="stat-value small"><c:out value="${roomStats.latestCircuitTime}" default="-"/></div>
      <div class="stat-change positive">回路最新数据</div>
    </div>
  </div>

  <div class="card">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-weight:600;font-size:16px;">配电房列表</div>
        <div style="color:#94a3b8;font-size:12px;margin-top:4px;">支持按电压等级、运行状态筛选</div>
      </div>
      <div style="display:flex;gap:12px;flex-wrap:wrap;">
        <label>电压等级
          <select style="margin-left:6px;padding:8px 10px;border-radius:8px;border:1px solid #e2e8f0;">
            <option>全部</option>
            <option>35kV</option>
            <option>0.4kV</option>
          </select>
        </label>
        <label>运行状态
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
        <th>配电房编号</th>
        <th>名称</th>
        <th>位置描述</th>
        <th>电压等级</th>
        <th>变压器数量</th>
        <th>负责人</th>
        <th>联系方式</th>
        <th>运行状态</th>
        <th>操作</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${rooms}" var="room">
        <tr>
          <td>${room.roomId}</td>
          <td>${room.roomName}</td>
          <td><c:out value="${room.location}" default="-"/></td>
          <td>${room.voltageLevel}</td>
          <td>${room.transformerCount}</td>
          <td><c:out value="${room.managerName}" default="-"/></td>
          <td><c:out value="${room.managerPhone}" default="-"/></td>
          <td><span class="status-badge normal">运行中</span></td>
          <td>
            <a class="btn btn-link" href="${pageContext.request.contextPath}/dist?module=dist&action=room_detail&id=${room.roomId}">详情</a>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty rooms}">
        <tr>
          <td colspan="9" style="text-align:center;color:#94a3b8;">暂无配电房数据</td>
        </tr>
      </c:if>
      </tbody>
    </table>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
