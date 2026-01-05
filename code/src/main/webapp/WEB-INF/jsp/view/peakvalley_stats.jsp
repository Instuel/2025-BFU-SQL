<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px;">
    <a href="${pageContext.request.contextPath}/view?module=view&action=list" class="btn btn-secondary" style="padding:6px 12px;font-size:13px;">← 返回</a>
    <h2>${viewTitle}</h2>
  </div>
  <p style="color:#64748b;margin-top:6px;">${viewDescription}</p>

  <div style="margin-top:20px;">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:12px;">
        <div>
          <div style="font-weight:600;font-size:16px;">峰谷电价统计</div>
          <div style="color:#94a3b8;font-size:12px;margin-top:4px;">共 ${peakValleyList.size()} 条记录</div>
        </div>
        <form action="${pageContext.request.contextPath}/view" method="get" style="display:flex;gap:8px;align-items:center;">
          <input type="hidden" name="module" value="view"/>
          <input type="hidden" name="action" value="peakvalley_stats"/>
          <label style="font-size:13px;color:#64748b;">统计日期</label>
          <input type="date" name="statDate" value="${statDate}" style="padding:6px 10px;border-radius:6px;border:1px solid #e2e8f0;font-size:13px;"/>
          <button class="btn btn-primary" type="submit" style="padding:6px 16px;font-size:13px;">查询</button>
        </form>
      </div>

      <div style="overflow-x:auto;">
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead>
            <tr style="background:#f8fafc;border-bottom:2px solid #e2e8f0;">
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">统计日期</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">厂区</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">配电房</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压等级</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">峰谷类型</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电价倍率</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">回路数</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">总用电量(kWh)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">平均功率(kW)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">最大功率(kW)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">预估成本(元)</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty peakValleyList}">
                <tr>
                  <td colspan="11" style="padding:32px;text-align:center;color:#94a3b8;">暂无统计数据</td>
                </tr>
              </c:when>
              <c:otherwise>
                <c:forEach items="${peakValleyList}" var="item">
                  <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px 8px;color:#64748b;">${item.Stat_Date}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Factory_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Room_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Voltage_Level}</td>
                    <td style="padding:10px 8px;">
                      <c:if test="${item.Peak_Type == '尖峰'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#dc2626;color:white;">尖峰</span>
                      </c:if>
                      <c:if test="${item.Peak_Type == '高峰'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#ef4444;color:white;">高峰</span>
                      </c:if>
                      <c:if test="${item.Peak_Type == '平段'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#f59e0b;color:white;">平段</span>
                      </c:if>
                      <c:if test="${item.Peak_Type == '低谷'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#10b981;color:white;">低谷</span>
                      </c:if>
                    </td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Price_Rate}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Circuit_Count}</td>
                    <td style="padding:10px 8px;font-weight:600;color:#1e293b;">${item.Total_Power_KWH}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Avg_Active_Power_KW}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Max_Active_Power_KW}</td>
                    <td style="padding:10px 8px;font-weight:600;color:#ef4444;">${item.Estimated_Cost}</td>
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
      <p>• <strong>统计维度</strong>：按日期、厂区、配电房、峰谷时段分组统计</p>
      <p>• <strong>峰谷类型</strong>：尖峰、高峰、平段、低谷，对应不同电价倍率</p>
      <p>• <strong>预估成本</strong>：总用电量 × 电价倍率 × 基础电价</p>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
