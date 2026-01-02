<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智慧能源管理系统 - 注册</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/dashboard.css">
</head>
<body>
    <div class="register-container">
        <div class="register-header">
            <h1>用户注册</h1>
            <p>Smart Energy Management System</p>
        </div>
        
        <c:if test="${not empty error}">
            <div class="error-message">${error}</div>
        </c:if>
        
        <form action="${pageContext.request.contextPath}/register" method="post">
            <div class="form-group">
                <label for="loginAccount">登录账号</label>
                <input type="text" id="loginAccount" name="loginAccount" required 
                       placeholder="请输入登录账号" value="${param.loginAccount}">
            </div>
            
            <div class="form-group">
                <label for="realName">真实姓名</label>
                <input type="text" id="realName" name="realName" required 
                       placeholder="请输入真实姓名" value="${param.realName}">
            </div>
            
            <div class="form-group">
                <label for="department">部门</label>
                <input type="text" id="department" name="department" 
                       placeholder="请输入部门" value="${param.department}">
            </div>
            
            <div class="form-group">
                <label for="contactPhone">联系电话</label>
                <input type="text" id="contactPhone" name="contactPhone" 
                       placeholder="请输入联系电话" value="${param.contactPhone}">
            </div>
            
            <div class="form-group">
                <label for="password">密码</label>
                <input type="password" id="password" name="password" required 
                       placeholder="请输入密码">
            </div>
            
            <div class="form-group">
                <label for="confirmPassword">确认密码</label>
                <input type="password" id="confirmPassword" name="confirmPassword" required 
                       placeholder="请再次输入密码">
            </div>
            
            <button type="submit" class="btn-register">注册</button>
        </form>
        
        <div class="login-link">
            已有账号？<a href="${pageContext.request.contextPath}/login">立即登录</a>
        </div>
    </div>
</body>
</html>
