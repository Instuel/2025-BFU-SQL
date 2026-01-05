<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content">
  <h2>业务视图查看</h2>
  <p style="color:#64748b;margin-top:6px;">查看配电网监测系统的五个核心业务视图，支持异常监测、数据完整性校验、峰谷电价统计、实时数据监控和设备健康状态评估。</p>

  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;margin-top:24px;">
    
    <div class="card" style="border-left:4px solid #ef4444;cursor:pointer;" onclick="window.location.href='${pageContext.request.contextPath}/view?module=view&action=circuit_abnormal'">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
        <div style="width:40px;height:40px;background:#fef2f2;border-radius:8px;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:20px;">⚠️</span>
        </div>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:16px;color:#1e293b;">回路异常监测视图</div>
          <div style="color:#ef4444;font-size:12px;font-weight:500;">异常监测</div>
        </div>
      </div>
      <div style="color:#64748b;font-size:13px;line-height:1.6;">
        筛选电压越界的回路异常记录，支持按厂区追溯。提供异常类型分类（过压/欠压）和异常等级判断（严重/一般）。
      </div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;">
        <div style="display:flex;justify-content:space-between;font-size:12px;color:#94a3b8;">
          <span>数据来源：Data_Circuit</span>
          <span>实时更新</span>
        </div>
      </div>
    </div>

    <div class="card" style="border-left:4px solid #f59e0b;cursor:pointer;" onclick="window.location.href='${pageContext.request.contextPath}/view?module=view&action=data_integrity'">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
        <div style="width:40px;height:40px;background:#fffbeb;border-radius:8px;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:20px;">📊</span>
        </div>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:16px;color:#1e293b;">数据完整性校验视图</div>
          <div style="color:#f59e0b;font-size:12px;font-weight:500;">数据质量</div>
        </div>
      </div>
      <div style="color:#64748b;font-size:13px;line-height:1.6;">
        校验回路和变压器关键数据的完整性。检测数据缺失情况，提供数据完整性状态和缺失字段识别。
      </div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;">
        <div style="display:flex;justify-content:space-between;font-size:12px;color:#94a3b8;">
          <span>数据来源：Data_Circuit/Transformer</span>
          <span>实时校验</span>
        </div>
      </div>
    </div>

    <div class="card" style="border-left:4px solid #3b82f6;cursor:pointer;" onclick="window.location.href='${pageContext.request.contextPath}/view?module=view&action=peakvalley_stats'">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
        <div style="width:40px;height:40px;background:#eff6ff;border-radius:8px;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:20px;">💰</span>
        </div>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:16px;color:#1e293b;">每日峰谷电价统计视图</div>
          <div style="color:#3b82f6;font-size:12px;font-weight:500;">成本分析</div>
        </div>
      </div>
      <div style="color:#64748b;font-size:13px;line-height:1.6;">
        按厂区+配电房+峰谷时段统计用电量。计算总用电量、平均功率、最大功率，并根据峰谷电价计算预估电费成本。
      </div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;">
        <div style="display:flex;justify-content:space-between;font-size:12px;color:#94a3b8;">
          <span>数据来源：Config_PeakValley</span>
          <span>按日统计</span>
        </div>
      </div>
    </div>

    <div class="card" style="border-left:4px solid #10b981;cursor:pointer;" onclick="window.location.href='${pageContext.request.contextPath}/view?module=view&action=realtime_data'">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
        <div style="width:40px;height:40px;background:#ecfdf5;border-radius:8px;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:20px;">📡</span>
        </div>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:16px;color:#1e293b;">实时设备数据采集视图</div>
          <div style="color:#10b981;font-size:12px;font-weight:500;">实时监控</div>
        </div>
      </div>
      <div style="color:#64748b;font-size:13px;line-height:1.6;">
        获取变压器和回路的最新一条数据。使用窗口函数按采集时间倒序排序，提供设备状态颜色标识。
      </div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;">
        <div style="display:flex;justify-content:space-between;font-size:12px;color:#94a3b8;">
          <span>数据来源：Data_Circuit/Transformer</span>
          <span>实时更新</span>
        </div>
      </div>
    </div>

    <div class="card" style="border-left:4px solid #8b5cf6;cursor:pointer;" onclick="window.location.href='${pageContext.request.contextPath}/view?module=view&action=equipment_status'">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
        <div style="width:40px;height:40px;background:#f5f3ff;border-radius:8px;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:20px;">🏥</span>
        </div>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:16px;color:#1e293b;">配电房设备健康状态概览视图</div>
          <div style="color:#8b5cf6;font-size:12px;font-weight:500;">健康评估</div>
        </div>
      </div>
      <div style="color:#64748b;font-size:13px;line-height:1.6;">
        从配电房维度汇总设备运行状态全貌。统计设备总数、正常数、异常数，计算整体健康评分和状态等级。
      </div>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;">
        <div style="display:flex;justify-content:space-between;font-size:12px;color:#94a3b8;">
          <span>数据来源：Dist_Room/Circuit/Transformer</span>
          <span>实时评估</span>
        </div>
      </div>
    </div>

  </div>

  <div style="margin-top:32px;padding:20px;background:#f8fafc;border-radius:12px;border:1px solid #e2e8f0;">
    <div style="font-weight:600;font-size:15px;color:#1e293b;margin-bottom:12px;">视图说明</div>
    <div style="color:#64748b;font-size:13px;line-height:1.8;">
      <p>• <strong>回路异常监测视图</strong>：专门关注回路电压异常，支持按厂区追溯异常记录</p>
      <p>• <strong>数据完整性校验视图</strong>：确保数据采集的完整性，识别缺失字段</p>
      <p>• <strong>每日峰谷电价统计视图</strong>：支持峰谷电价下的用电成本分析</p>
      <p>• <strong>实时设备数据采集视图</strong>：提供设备最新运行状态，支持状态颜色标识</p>
      <p>• <strong>配电房设备健康状态概览视图</strong>：从配电房维度评估整体设备健康状况</p>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
