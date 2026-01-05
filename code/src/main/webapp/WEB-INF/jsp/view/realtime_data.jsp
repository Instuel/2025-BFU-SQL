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
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
        <div>
          <div style="font-weight:600;font-size:16px;">实时设备数据</div>
          <div style="color:#94a3b8;font-size:12px;margin-top:4px;">共 ${realtimeDataList.size()} 条记录</div>
        </div>
      </div>

      <div style="overflow-x:auto;">
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead>
            <tr style="background:#f8fafc;border-bottom:2px solid #e2e8f0;">
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">设备类型</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">设备名称</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">型号规格</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">厂区</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">配电房</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压等级</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">最新采集时间</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">绕组温度(℃)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">铁芯温度(℃)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">负载率(%)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压(kV)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电流(A)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">开关状态</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">设备状态</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty realtimeDataList}">
                <tr>
                  <td colspan="14" style="padding:32px;text-align:center;color:#94a3b8;">暂无实时数据</td>
                </tr>
              </c:when>
              <c:otherwise>
                <c:forEach items="${realtimeDataList}" var="item">
                  <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px 8px;">
                      <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#f1f5f9;color:#64748b;">${item.Device_Type}</span>
                    </td>
                    <td style="padding:10px 8px;font-weight:500;color:#1e293b;">${item.Device_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Model_Spec}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Factory_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Room_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Voltage_Level}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Latest_Collect_Time}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Winding_Temp}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Core_Temp}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Load_Rate}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Voltage}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Current_Val}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Switch_Status}</td>
                    <td style="padding:10px 8px;">
                      <c:if test="${item.Status_Color == '红色'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#dc2626;color:white;">异常</span>
                      </c:if>
                      <c:if test="${item.Status_Color == '绿色'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#10b981;color:white;">正常</span>
                      </c:if>
                      <c:if test="${item.Status_Color == '灰色'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#94a3b8;color:white;">未知</span>
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
      <p>• <strong>数据获取</strong>：使用窗口函数ROW_NUMBER()按采集时间倒序排序，取每个设备的最新一条数据</p>
      <p>• <strong>设备类型</strong>：变压器和回路，通过UNION ALL合并查询结果</p>
      <p>• <strong>状态颜色</strong>：异常-红色、正常-绿色、其他-灰色</p>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
