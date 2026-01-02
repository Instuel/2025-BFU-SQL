<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 - 服务器错误</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
</head>
<body>
    <div class="error-container">
        <div class="error-code">500</div>
        <div class="error-message">服务器错误</div>
        <div class="error-description">抱歉，服务器处理请求时出现错误</div>
        <a href="${pageContext.request.contextPath}/" class="btn-home">返回首页</a>
    </div>
</body>
</html>
