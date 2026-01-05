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
          <div style="font-weight:600;font-size:16px;">异常回路列表</div>
          <div style="color:#94a3b8;font-size:12px;margin-top:4px;">共 ${circuitAbnormalList.size()} 条异常记录</div>
        </div>
      </div>

      <div style="overflow-x:auto;">
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead>
            <tr style="background:#f8fafc;border-bottom:2px solid #e2e8f0;">
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">数据ID</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">回路名称</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">厂区</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">配电房</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压等级</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">采集时间</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">电压(kV)</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">异常类型</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">异常等级</th>
              <th style="padding:12px 8px;text-align:left;font-weight:600;color:#475569;">阈值说明</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty circuitAbnormalList}">
                <tr>
                  <td colspan="10" style="padding:32px;text-align:center;color:#94a3b8;">暂无异常记录</td>
                </tr>
              </c:when>
              <c:otherwise>
                <c:forEach items="${circuitAbnormalList}" var="item">
                  <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px 8px;color:#64748b;">${item.Data_ID}</td>
                    <td style="padding:10px 8px;font-weight:500;color:#1e293b;">${item.Circuit_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Factory_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Room_Name}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Voltage_Level}</td>
                    <td style="padding:10px 8px;color:#64748b;">${item.Collect_Time}</td>
                    <td style="padding:10px 8px;font-weight:600;color:#ef4444;">${item.Voltage}</td>
                    <td style="padding:10px 8px;">
                      <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#fef2f2;color:#ef4444;">${item.Abnormal_Type}</span>
                    </td>
                    <td style="padding:10px 8px;">
                      <c:if test="${item.Abnormal_Level == '紧急'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#dc2626;color:white;">紧急</span>
                      </c:if>
                      <c:if test="${item.Abnormal_Level == '一般'}">
                        <span style="padding:4px 8px;border-radius:4px;font-size:12px;font-weight:500;background:#f59e0b;color:white;">一般</span>
                      </c:if>
                    </td>
                    <td style="padding:10px 8px;color:#94a3b8;font-size:12px;">${item.Threshold_Desc}</td>
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
      <p>• <strong>筛选条件</strong>：电压 > 37kV（过压）或 电压 < 33kV（欠压）</p>
      <p>• <strong>异常等级</strong>：电压 > 38kV 或 < 32kV 为紧急，电压 > 37kV 或 < 33kV 为一般</p>
      <p>• <strong>阈值说明</strong>：33kV系统允许电压33-37kV</p>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
