<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>智慧能源管理系统</title>

    <!-- 全局样式 -->
  <link rel="stylesheet" href="${ctx}/css/common.css"/>
  <link rel="stylesheet" href="${ctx}/css/components.css"/>

  <!-- 业务线样式（为避免“部分页面样式不生效”，这里直接全量引入；各文件均为前缀化选择器，互不冲突） -->
  <link rel="stylesheet" href="${ctx}/css/biz/maintenance.css"/>
  <link rel="stylesheet" href="${ctx}/css/biz/dashboard.css"/>
  <link rel="stylesheet" href="${ctx}/css/biz/pv-manage.css"/>
  <link rel="stylesheet" href="${ctx}/css/biz/energy-stats.css"/>
  <link rel="stylesheet" href="${ctx}/css/biz/rbac.css"/>

  <!-- 保留原工程静态资源（如有） -->
  <link rel="stylesheet" href="${ctx}/static/css/main.css"/>
  <script src="${ctx}/static/js/main.js" defer></script>


</head>
<body>

<div class="header">
  <div>
    <h1>智慧能源管理系统</h1>
    <div style="opacity:.9;font-size:13px;margin-top:2px;">Energy Management System</div>
  </div>

  <div class="header-info">
    <c:if test="${not empty sessionScope.currentUser}">
      <div class="user-info">
        <img class="user-avatar" src="${ctx}/static/img/default-avatar.svg" alt="avatar"
             onerror="this.style.display='none'"/>
        <div>
          <div style="font-weight:600;line-height:1.2;">${sessionScope.currentUser.realName}</div>
          <div style="font-size:12px;opacity:.9;line-height:1.2;">${sessionScope.currentRoleType}</div>
        </div>
      </div>
      <a class="logout-btn" href="${ctx}/auth?action=logout">退出</a>
    </c:if>
  </div>
</div>

<div class="container">
