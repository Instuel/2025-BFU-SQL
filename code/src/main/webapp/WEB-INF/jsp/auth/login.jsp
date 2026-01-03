<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>智慧能源管理系统 - 登录</title>
  <link rel="stylesheet" href="${ctx}/css/common.css">
  <link rel="stylesheet" href="${ctx}/css/components.css">
  <link rel="stylesheet" href="${ctx}/css/biz/auth.css">
</head>
<body class="auth-wrapper">

<div class="login-container">
  <div class="login-header">
    <h1>智慧能源管理系统</h1>
    <p>Smart Energy Management System</p>
  </div>

  <c:if test="${not empty requestScope.error}">
    <div class="error-message">${requestScope.error}</div>
  </c:if>

  <c:if test="${not empty param.success}">
    <div class="success-message">${param.success}</div>
  </c:if>

  <form action="${ctx}/auth?action=login" method="post">
    <div class="form-group">
      <label for="loginAccount">登录账号</label>
      <input type="text" id="loginAccount" name="loginAccount" required
             placeholder="请输入登录账号" value="${param.loginAccount}">
    </div>

    <div class="form-group">
      <label for="loginPassword">密码</label>
      <input type="password" id="loginPassword" name="loginPassword" required
             placeholder="请输入密码">
    </div>

    <button type="submit" class="btn-login">登录</button>
  </form>

  <div class="register-link">
    还没有账号？<a href="${ctx}/auth?action=registerPage">立即注册</a>
  </div>
</div>

</body>
</html>
