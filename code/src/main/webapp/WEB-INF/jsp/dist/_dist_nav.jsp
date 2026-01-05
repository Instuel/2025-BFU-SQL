<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<div class="card" style="padding:16px;margin-bottom:18px;">
  <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;">
    <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:center;">
      <a class="btn btn-secondary" href="${ctx}/dist?module=dist&action=room_list">配电房</a>
      <a class="btn btn-secondary" href="${ctx}/dist?module=dist&action=circuit_list">回路</a>
      <a class="btn btn-secondary" href="${ctx}/dist?module=dist&action=transformer_list">变压器</a>
      <a class="btn btn-secondary" href="${ctx}/dist?module=dist&action=data_circuit_list">回路监测数据</a>
      <a class="btn btn-secondary" href="${ctx}/dist?module=dist&action=data_transformer_list">变压器监测数据</a>
    </div>
    <a class="btn btn-primary" href="${ctx}/view?module=view&action=list" style="font-weight:bold;padding:8px 20px;">业务视图查看</a>
  </div>
</div>
