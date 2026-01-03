<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>智慧能源管理系统 - 注册</title>
  <link rel="stylesheet" href="${ctx}/css/common.css">
  <link rel="stylesheet" href="${ctx}/css/components.css">
  <link rel="stylesheet" href="${ctx}/css/biz/auth.css">
</head>
<body class="auth-wrapper">

<div class="login-container" style="max-width:560px;">
  <div class="login-header">
    <h1>账号注册</h1>
    <p>请填写基本信息（后续可由管理员审核/分配角色）</p>
  </div>

  <c:if test="${not empty requestScope.error}">
    <div class="error-message">${requestScope.error}</div>
  </c:if>

  <form action="${ctx}/auth?action=register" method="post">
    <div class="form-group">
      <label for="loginAccount">账号</label>
      <input type="text" id="loginAccount" name="loginAccount" required placeholder="请输入账号">
    </div>

    <div class="form-group">
      <label for="realName">姓名</label>
      <input type="text" id="realName" name="realName" required placeholder="请输入姓名">
    </div>

    <div class="form-group">
      <label for="department">部门</label>
      <input type="text" id="department" name="department" placeholder="请输入部门（可选）">
    </div>

    <div class="form-group">
      <label for="contactPhone">电话</label>
      <input type="text" id="contactPhone" name="contactPhone" placeholder="请输入电话（可选）">
    </div>

    <div class="form-group">
      <label for="loginPassword">密码</label>
      <input type="password" id="loginPassword" name="loginPassword" required placeholder="请输入密码">
    </div>

    <button type="submit" class="btn btn-primary btn-lg" style="width:100%;">提交注册</button>

    <div class="auth-links">
      <a href="${ctx}/auth?action=loginPage">返回登录</a>
    </div>
  </form>
</div>

</body>
</html>
