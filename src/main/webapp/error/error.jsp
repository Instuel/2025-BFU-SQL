<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统错误</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
</head>
<body>
    <div class="error-container">
        <div class="error-icon">⚠️</div>
        <div class="error-message">系统错误</div>
        <div class="error-description">
            系统处理您的请求时发生了错误，请稍后重试。<br>
            如果问题持续存在，请联系系统管理员。
        </div>
        <a href="${pageContext.request.contextPath}/" class="btn-home">返回首页</a>
    </div>
</body>
</html>
