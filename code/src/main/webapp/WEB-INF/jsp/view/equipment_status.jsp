<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px;">
    <a href="${pageContext.request.contextPath}/view?module=view&action=list" class="btn btn-secondary" style="padding:6px 12px;font-size:13px;">← 返回</a>
    <h2>${viewTitle}</h2>
  </div>
  <p style="color:#64748b;margin-top:6px;">${viewDescription}</p>

  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin:20px 0;">
    <div class="stat-card energy">
      <div class="stat-label">配电房总数</div>
      <div class="stat-value">${equipmentStatusList.size()}</div>
      <div class="stat-change positive">覆盖配电房</div>
    </div>
    <div class="stat-card success">
      <div class="stat-label">优秀配电房</div>
      <div class="stat-value small">
        <c:set var="excellentCount" value="0"/>
        <c:forEach items="${equipmentStatusList}" var="item">
          <c:if test="${item.Health_Level == '优秀'}">
            <c:set var="excellentCount" value="${excellentCount + 1}"/>
          </c:if>
        </c:forEach>
        ${excellentCount}
      </div>
      <div class="stat-change positive">健康度≥90%</div>
    </div>
    <div class="stat-card alarm">
      <div class="stat-label">异常设备总数</div>
      <div class="stat-value small">
        <c:set var="abnormalCount" value="0"/>
        <c:forEach items="${equipmentStatusList}" var="item">
          <c:set var="abnormalCount" value="${abnormalCount + item.Abnormal_Transformers + item.Abnormal_Circuits}"/>
        </c:forEach>
        ${abnormalCount}
      </div>
      <div class="stat-change negative">需要关注</div>
    </div>
    <div class="stat-card pv">
      <div class="stat-label">平均健康度</div>
      <div class="stat-value small">
        <c:set var="totalHealth" value="0"/>
        <c:forEach items="${equipmentStatusList}" var="item">
          <c:set var="totalHealth" value="${totalHealth + item.Overall_Health_Score}"/>
        </c:forEach>
        <c:if test="${not empty equipmentStatusList}">
          <fmt:formatNumber type="number" pattern="0.00" value="${totalHealth / equipmentStatusList.size()}"/>
        </c:if>
        <c:if test="${empty equipmentStatusList}">0.00</c:if>
      </div>
      <div class="stat-change positive">整体状况</div>
    </div>
  </div>

  <div style="margin-top:20px;">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
        <div>
          <div style="font-weight:600;font-size:16px;">配电房设备健康状态</div>
          <div style="color:#94a3b8;font-size:12px;margin-top:4px;">共 ${equipmentStatusList.size()} 个配电房</div>
        </div>
      </div>

      <div style="overflow-x:auto;">
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead>
            <tr style="background:#f8fafc;border-bottom:2px solid #e2e8f0;">
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">配电房名称</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">厂区</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">位置</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压等级</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">负责人</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">变压器</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">回路</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">健康评分</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">健康等级</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty equipmentStatusList}">
                <tr>
                  <td colspan="9" style="padding:32px;text-align:center;color:#94a3b8;">暂无配电房数据</td>
                </tr>
              </c:when>
              <c:otherwise>
                <c:forEach items="${equipmentStatusList}" var="item">
                  <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px 8px;font-weight:500;color:#1e293b;">${item.Room_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Factory_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Location}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Voltage_Level}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Room_Manager}</td>
                    <td style="padding:10px 8px;color:#64748b;">
                      总数: ${item.Total_Transformers} | 正常: ${item.Normal_Transformers} | 异常: ${item.Abnormal_Transformers}
                    </td>
                    <td style="padding:10px 8px;color:#64748b;">
                      总数: ${item.Total_Circuits} | 正常: ${item.Normal_Circuits} | 异常: ${item.Abnormal_Circuits}
                    </td>
                    <td style="padding:10px 8px;font-weight:600;color:#1e293b;">${item.Overall_Health_Score}</td>
                    <td style="padding:10px 8px;">
                      <c:if test="${item.Health_Level == '优秀'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#10b981;color:white;">优秀</span>
                      </c:if>
                      <c:if test="${item.Health_Level == '良好'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#3b82f6;color:white;">良好</span>
                      </c:if>
                      <c:if test="${item.Health_Level == '一般'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#f59e0b;color:white;">一般</span>
                      </c:if>
                      <c:if test="${item.Health_Level == '较差'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#ef4444;color:white;">较差</span>
                      </c:if>
                      <c:if test="${item.Health_Level == '无设备'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#94a3b8;color:white;">无设备</span>
                      </c:if>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <div style="margin-top:20px;padding:16px;background:#f8fafc;border-radius:8px;border:1px solid #e2e8f0;">
    <div style="font-weight:600;font-size:14px;color:#1e293b;margin-bottom:8px;">视图说明</div>
    <div style="color:#64748b;font-size:13px;line-height:1.7;">
      <p>• <strong>健康评分</strong>：正常设备数/总设备数，保留2位小数</p>
      <p>• <strong>健康等级</strong>：优秀≥0.9、良好≥0.7、一般≥0.5、较差<0.5</p>
      <p>• <strong>设备统计</strong>：统计配电房内变压器和回路的总数、正常数、异常数</p>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
