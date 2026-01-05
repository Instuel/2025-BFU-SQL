<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<div class="main-content dashboard-page">
  <div class="dashboard-container exec-screen">
    <div class="dashboard-header">
      <div class="exec-screen-topbar">
        <div>
          <h1>大屏</h1>
          <p>支持自定义展示模块与指标（能源总览 / 光伏总览 / 配电网运行状态 / 告警统计），实时汇总按分钟更新。</p>
        </div>
        <div class="exec-screen-actions">
          <button class="dashboard-btn" type="button" id="btnCustomize">自定义</button>
          <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execHighAlarm">高等级告警</a>
          <a class="dashboard-btn" href="${ctx}/app?module=dashboard&view=execDesk">← 返回工作台</a>
        </div>
      </div>
    </div>

    <c:if test="${not empty execFlashMessage}">
      <div class="dashboard-alert ${execFlashType}">
        <c:out value="${execFlashMessage}"/>
      </div>
    </c:if>

    <!-- 自定义弹层（偏前端：localStorage 保存） -->
    <div class="exec-modal" id="customModal" aria-hidden="true">
      <div class="exec-modal-mask" data-close="1"></div>
      <div class="exec-modal-panel">
        <div class="exec-modal-header">
          <div>
            <div class="exec-modal-title">自定义大屏</div>
            <div class="exec-modal-sub">选择展示模块与关键指标（仅影响当前浏览器显示，不改变数据库配置）。</div>
          </div>
          <button class="dashboard-btn" type="button" data-close="1">关闭</button>
        </div>

        <div class="exec-modal-body">
          <div class="exec-modal-grid">
            <div class="exec-modal-block">
              <div class="exec-modal-block-title">展示模块</div>
              <label class="exec-check"><input type="checkbox" data-pref-module="energy" checked/> 能源总览</label>
              <label class="exec-check"><input type="checkbox" data-pref-module="pv" checked/> 光伏总览</label>
              <label class="exec-check"><input type="checkbox" data-pref-module="dist" checked/> 配电网运行状态</label>
              <label class="exec-check"><input type="checkbox" data-pref-module="alarm" checked/> 告警统计</label>

              <div class="exec-modal-block-title" style="margin-top:14px;">模块排序</div>
              <div class="dashboard-section-hint">拖拽/上下移动可调整模块在大屏中的展示顺序。</div>
              <div class="exec-sort-list" id="prefOrderList"></div>

              <div class="exec-modal-block-title" style="margin-top:14px;">布局</div>
              <div class="exec-inline">
                <select class="dashboard-input" style="width:140px;" id="prefModuleCols">
                  <option value="1">1 列</option>
                  <option value="2" selected>2 列</option>
                  <option value="3">3 列</option>
                </select>
                <span class="dashboard-section-hint">大屏模块列数（窄屏将自动变为 1 列）</span>
              </div>

              <div class="exec-modal-block-title" style="margin-top:14px;">自动刷新</div>
              <div class="exec-inline">
                <label class="exec-check" style="margin:0;"><input type="checkbox" id="prefRefreshEnabled" checked/> 启用</label>
                <input class="dashboard-input" style="width:120px;" type="number" min="30" step="30" id="prefRefreshSec" value="60"/>
                <span class="dashboard-section-hint">秒（推荐 60 秒：分钟级更新）</span>
              </div>
            </div>

            <div class="exec-modal-block">
              <div class="exec-modal-block-title">关键指标（勾选后显示）</div>
              <div class="exec-fields">
                <div class="exec-fields-col">
                  <div class="exec-fields-title">能源总览</div>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:totalKwh" checked/> 总用电量</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:totalWaterM3" checked/> 总用水量</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:totalSteamT" checked/> 总蒸汽</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:totalGasM3" checked/> 总天然气</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:monthlyCost" checked/> 本月费用</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="energy:targetCompletion" checked/> 目标完成度</label>
                </div>

                <div class="exec-fields-col">
                  <div class="exec-fields-title">光伏总览</div>
                  <label class="exec-check"><input type="checkbox" data-pref-field="pv:todayGen" checked/> 今日发电量</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="pv:deviceNormal" checked/> 设备正常/故障</label>
                </div>

                <div class="exec-fields-col">
                  <div class="exec-fields-title">配电网运行状态</div>
                  <label class="exec-check"><input type="checkbox" data-pref-field="dist:roomCount" checked/> 配电室数</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="dist:circuitCount" checked/> 回路数</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="dist:transformerCount" checked/> 变压器数</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="dist:latestCircuitTime" checked/> 最新采集</label>
                </div>

                <div class="exec-fields-col">
                  <div class="exec-fields-title">告警统计</div>
                  <label class="exec-check"><input type="checkbox" data-pref-field="alarm:alarmSplit" checked/> 高/中/低告警</label>
                  <label class="exec-check"><input type="checkbox" data-pref-field="alarm:recentHigh" checked/> 最新高告警列表</label>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="exec-modal-footer">
          <button class="dashboard-btn" type="button" id="btnReset">恢复默认</button>
          <button class="dashboard-btn" type="button" id="btnExport">导出配置</button>
          <button class="dashboard-btn" type="button" id="btnImport">导入配置</button>
          <input type="file" id="importFile" accept="application/json" style="display:none;"/>
          <button class="dashboard-btn primary" type="button" id="btnApply">应用</button>
        </div>
      </div>
    </div>

    <!-- 0) 四大展示模块（可自定义显示） -->
    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">大屏展示模块</div>
          <div class="dashboard-section-hint">共 4 个模块：能源总览、光伏总览、配电网运行状态、告警统计。</div>
        </div>
        <div class="dashboard-meta">
          <div class="dashboard-meta-item">最近刷新：<span id="rt_lastRefresh"><c:out value="${screenRealtime.statTime}"/></span></div>
          <div class="dashboard-meta-item">服务端时间：<span id="rt_serverTime">--</span></div>
        </div>
      </div>

      <div class="exec-module-grid" id="moduleGrid">
        <!-- 能源总览 -->
        <div class="exec-module" data-module="energy" id="mod_energy">
          <div class="exec-module-head">
            <div class="exec-module-title">能源总览</div>
            <div class="exec-module-sub">实时汇总 + 月度概览</div>
          </div>
          <div class="exec-kpi-grid">
            <div class="exec-kpi" data-field="totalKwh" data-module="energy">
              <div class="exec-kpi-label">总用电量(kWh)</div>
              <div class="exec-kpi-value" id="kpi_totalKwh"><fmt:formatNumber value="${screenRealtime.totalKwh}" pattern="#,#00.###"/></div>
            </div>
            <div class="exec-kpi" data-field="totalWaterM3" data-module="energy">
              <div class="exec-kpi-label">总用水量(m³)</div>
              <div class="exec-kpi-value" id="kpi_totalWater"><fmt:formatNumber value="${screenRealtime.totalWaterM3}" pattern="#,#00.###"/></div>
            </div>
            <div class="exec-kpi" data-field="totalSteamT" data-module="energy">
              <div class="exec-kpi-label">总蒸汽(t)</div>
              <div class="exec-kpi-value" id="kpi_totalSteam"><fmt:formatNumber value="${screenRealtime.totalSteamT}" pattern="#,#00.###"/></div>
            </div>
            <div class="exec-kpi" data-field="totalGasM3" data-module="energy">
              <div class="exec-kpi-label">总天然气(m³)</div>
              <div class="exec-kpi-value" id="kpi_totalGas"><fmt:formatNumber value="${screenRealtime.totalGasM3}" pattern="#,#00.###"/></div>
            </div>
            <div class="exec-kpi" data-field="monthlyCost" data-module="energy">
              <div class="exec-kpi-label">本月费用(¥)</div>
              <div class="exec-kpi-value" id="kpi_monthlyCost"><fmt:formatNumber value="${monthlyOverview.monthlyCost}" pattern="#,#00.##"/></div>
              <div class="exec-kpi-sub" id="kpi_monthlyCostRate">
                <c:choose>
                  <c:when test="${monthlyOverview.monthlyCostChangeRate != null}">
                    <span class="trend-tag <c:out value='${monthlyOverview.monthlyCostChangeRate >= 0 ? "down" : "up"}'/>">
                      <c:out value="${monthlyOverview.monthlyCostChangeRate}"/>%
                    </span>
                  </c:when>
                  <c:otherwise><span class="trend-tag info">--</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="exec-kpi" data-field="targetCompletion" data-module="energy">
              <div class="exec-kpi-label">目标完成度</div>
              <div class="exec-kpi-value" id="kpi_target">
                <c:choose>
                  <c:when test="${monthlyOverview.targetCompletion != null}"><c:out value="${monthlyOverview.targetCompletion}"/>%</c:when>
                  <c:otherwise>--</c:otherwise>
                </c:choose>
              </div>
              <div class="exec-kpi-sub">目标：本月成本降低</div>
            </div>
          </div>
        </div>

        <!-- 光伏总览 -->
        <div class="exec-module" data-module="pv" id="mod_pv">
          <div class="exec-module-head">
            <div class="exec-module-title">光伏总览</div>
            <div class="exec-module-sub">设备状态 + 今日发电</div>
          </div>
          <div class="exec-kpi-grid">
            <div class="exec-kpi" data-field="todayGen" data-module="pv">
              <div class="exec-kpi-label">今日发电量(kWh)</div>
              <div class="exec-kpi-value" id="kpi_pvTodayGen">
                <c:choose>
                  <c:when test="${pvStats.todayGen != null}"><fmt:formatNumber value="${pvStats.todayGen}" pattern="#,#00.###"/></c:when>
                  <c:otherwise>--</c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="exec-kpi" data-field="deviceNormal" data-module="pv">
              <div class="exec-kpi-label">设备(总/正常/故障/离线)</div>
              <div class="exec-kpi-value" id="kpi_pvDevice">
                <c:out value="${pvStats.totalCount}"/> / <c:out value="${pvStats.normalCount}"/> / <c:out value="${pvStats.faultCount}"/> / <c:out value="${pvStats.offlineCount}"/>
              </div>
            </div>
            <div class="exec-kpi" data-module="pv">
              <div class="exec-kpi-label">本月光伏发电(kWh)</div>
              <div class="exec-kpi-value" id="kpi_pvMonthGen"><fmt:formatNumber value="${monthlyOverview.pvGenKwh}" pattern="#,#00.###"/></div>
              <div class="exec-kpi-sub">自用 <fmt:formatNumber value="${monthlyOverview.pvSelfKwh}" pattern="#,#00.###"/> / 上网 <fmt:formatNumber value="${monthlyOverview.pvGridKwh}" pattern="#,#00.###"/></div>
            </div>
            <div class="exec-kpi" data-module="pv">
              <div class="exec-kpi-label">收益估算(¥)</div>
              <div class="exec-kpi-value" id="kpi_pvRevenue"><fmt:formatNumber value="${monthlyOverview.pvTotalRevenue}" pattern="#,#00.##"/></div>
              <div class="exec-kpi-sub">自用节省 + 上网收益</div>
            </div>
          </div>
        </div>

        <!-- 配电网运行状态 -->
        <div class="exec-module" data-module="dist" id="mod_dist">
          <div class="exec-module-head">
            <div class="exec-module-title">配电网运行状态</div>
            <div class="exec-module-sub">规模概览 + 最新采集</div>
          </div>
          <div class="exec-kpi-grid">
            <div class="exec-kpi" data-field="roomCount" data-module="dist">
              <div class="exec-kpi-label">配电室数</div>
              <div class="exec-kpi-value" id="kpi_roomCount"><c:out value="${distStats.roomCount}"/></div>
            </div>
            <div class="exec-kpi" data-field="circuitCount" data-module="dist">
              <div class="exec-kpi-label">回路数</div>
              <div class="exec-kpi-value" id="kpi_circuitCount"><c:out value="${distStats.circuitCount}"/></div>
            </div>
            <div class="exec-kpi" data-field="transformerCount" data-module="dist">
              <div class="exec-kpi-label">变压器数</div>
              <div class="exec-kpi-value" id="kpi_transformerCount"><c:out value="${distStats.transformerCount}"/></div>
            </div>
            <div class="exec-kpi" data-field="latestCircuitTime" data-module="dist">
              <div class="exec-kpi-label">最新采集时间</div>
              <div class="exec-kpi-value" id="kpi_latestCircuit"><c:out value="${distStats.latestCircuitTime}"/></div>
            </div>
            <div class="exec-kpi" data-module="dist">
              <div class="exec-kpi-label">快速入口</div>
              <div class="exec-kpi-value"><a class="link" href="${ctx}/app?module=dist">进入配电网模块 →</a></div>
              <div class="exec-kpi-sub">查看配电室/回路/变压器详情</div>
            </div>
          </div>
        </div>

        <!-- 告警统计 -->
        <div class="exec-module" data-module="alarm" id="mod_alarm">
          <div class="exec-module-head">
            <div class="exec-module-title">告警统计</div>
            <div class="exec-module-sub">实时拆分 + 高等级告警</div>
          </div>
          <div class="exec-kpi-grid">
            <div class="exec-kpi" data-field="alarmSplit" data-module="alarm">
              <div class="exec-kpi-label">告警总数</div>
              <div class="exec-kpi-value" id="kpi_alarmTotal"><c:out value="${screenRealtime.totalAlarm}"/></div>
              <div class="exec-kpi-sub" id="kpi_alarmSplit">
                <span class="workbench-tag danger">高 <span id="kpi_alarmHigh"><c:out value="${screenRealtime.alarmHigh}"/></span></span>
                <span class="workbench-tag warning">中 <span id="kpi_alarmMid"><c:out value="${screenRealtime.alarmMid}"/></span></span>
                <span class="workbench-tag info">低 <span id="kpi_alarmLow"><c:out value="${screenRealtime.alarmLow}"/></span></span>
              </div>
            </div>
            <div class="exec-kpi" data-module="alarm">
              <div class="exec-kpi-label">本月告警(高)</div>
              <div class="exec-kpi-value"><c:out value="${monthlyOverview.alarmHighCount}"/></div>
              <div class="exec-kpi-sub">本月总 <c:out value="${monthlyOverview.alarmTotalCount}"/>，近7天高 <c:out value="${monthlyOverview.alarmRecentHighCount}"/></div>
            </div>
            <div class="exec-kpi" data-field="recentHigh" data-module="alarm" style="grid-column: 1 / -1;">
              <div class="exec-kpi-label">最新高等级告警</div>
              <div class="exec-kpi-value" style="font-size:14px;">
                <c:choose>
                  <c:when test="${empty highAlarms}">暂无高等级告警</c:when>
                  <c:otherwise>
                    <ul class="exec-alarm-list" id="alarmList">
                      <c:forEach items="${highAlarms}" var="a">
                        <li>
                          <span class="workbench-tag danger">高</span>
                          <span class="exec-alarm-time"><c:out value="${a.occurTime}"/></span>
                          <span class="exec-alarm-content"><c:out value="${a.content}"/></span>
                        </li>
                      </c:forEach>
                    </ul>
                  </c:otherwise>
                </c:choose>
              </div>
              <div class="exec-kpi-sub">
                点击右上角“高等级告警”查看详情，或
                <a class="link" href="${ctx}/app?module=dashboard&view=execHighAlarm">查看全部 →</a>
              </div>
            </div>
          </div>
        </div>

      </div>
    </section>

    <!-- 1) 大屏展示配置（数据库） -->
    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">大屏展示配置</div>
          <div class="dashboard-section-hint">配置表（Dashboard_Config）：配置编号、展示模块、数据刷新频率、展示字段、排序规则、权限等级。</div>
        </div>
      </div>

      <c:choose>
        <c:when test="${empty screenConfigs}">
          <div class="dashboard-empty">暂无配置数据（请确认 Dashboard_Config 表已初始化）。</div>
        </c:when>
        <c:otherwise>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>配置编号</th>
                <th>展示模块</th>
                <th>数据刷新频率</th>
                <th>展示字段</th>
                <th>排序规则</th>
                <th>权限等级</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach items="${screenConfigs}" var="cfg">
                <tr>
                  <td>
                    <c:out value="${cfg.configId}"/>
                    <c:if test="${cfg.configCode != '-'}">
                      <span class="trend-tag info" style="margin-left:8px;"><c:out value="${cfg.configCode}"/></span>
                    </c:if>
                  </td>
                  <td><c:out value="${cfg.moduleName}"/></td>
                  <td>
                    <c:out value="${cfg.refreshInterval}"/>
                    <c:out value="${cfg.refreshUnit}"/>
                  </td>
                  <td class="cell-wrap"><c:out value="${cfg.displayFields}"/></td>
                  <td><c:out value="${cfg.sortRule}"/></td>
                  <td><c:out value="${cfg.authLevel}"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>

    <!-- 2) 实时汇总数据（表格明细） -->
    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">实时汇总数据</div>
          <div class="dashboard-section-hint">按分钟级更新：用电/用水/蒸汽/天然气/光伏、告警拆分。</div>
        </div>
        <div class="dashboard-meta">
          <div class="dashboard-meta-item">统计时间：<span id="rt_statTime"><c:out value="${screenRealtime.statTime}"/></span></div>
        </div>
      </div>

      <div class="table-container">
        <table class="data-table" id="rtTable">
          <thead>
          <tr>
            <th>统计时间</th>
            <th>总用电量(kWh)</th>
            <th>总用水量(m³)</th>
            <th>总蒸汽消耗量(t)</th>
            <th>总天然气消耗量(m³)</th>
            <th>光伏总发电量(kWh)</th>
            <th>光伏自用电量(kWh)</th>
            <th>总告警次数</th>
            <th>高/中/低告警数</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td id="rt_td_time"><c:out value="${screenRealtime.statTime}"/></td>
            <td id="rt_td_kwh"><fmt:formatNumber value="${screenRealtime.totalKwh}" pattern="#,#00.###"/></td>
            <td id="rt_td_water"><fmt:formatNumber value="${screenRealtime.totalWaterM3}" pattern="#,#00.###"/></td>
            <td id="rt_td_steam"><fmt:formatNumber value="${screenRealtime.totalSteamT}" pattern="#,#00.###"/></td>
            <td id="rt_td_gas"><fmt:formatNumber value="${screenRealtime.totalGasM3}" pattern="#,#00.###"/></td>
            <td id="rt_td_pvgen"><fmt:formatNumber value="${screenRealtime.pvGenKwh}" pattern="#,#00.###"/></td>
            <td id="rt_td_pvself"><fmt:formatNumber value="${screenRealtime.pvSelfKwh}" pattern="#,#00.###"/></td>
            <td id="rt_td_alarm"><c:out value="${screenRealtime.totalAlarm}"/></td>
            <td id="rt_td_alarm_split">
              <span class="workbench-tag danger">高 <span id="rt_alarmHigh"><c:out value="${screenRealtime.alarmHigh}"/></span></span>
              <span class="workbench-tag warning">中 <span id="rt_alarmMid"><c:out value="${screenRealtime.alarmMid}"/></span></span>
              <span class="workbench-tag info">低 <span id="rt_alarmLow"><c:out value="${screenRealtime.alarmLow}"/></span></span>
            </td>
          </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- 3) 历史趋势数据（多周期 + 同比/环比标记 + 简单预测） -->
    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">历史趋势数据</div>
          <div class="dashboard-section-hint">多周期查询；同比/环比自动标记；提供简单预测（近3期均值）。</div>
        </div>
      </div>

      <form class="dashboard-inline-form" method="get" action="${ctx}/app">
        <input type="hidden" name="module" value="dashboard"/>
        <input type="hidden" name="view" value="execScreen"/>
        <label>能源类型
          <select name="trendEnergyType" id="trendEnergyType">
            <option value="电" <c:out value='${trendEnergyType=="电" ? "selected" : ""}'/>>电</option>
            <option value="水" <c:out value='${trendEnergyType=="水" ? "selected" : ""}'/>>水</option>
            <option value="蒸汽" <c:out value='${trendEnergyType=="蒸汽" ? "selected" : ""}'/>>蒸汽</option>
            <option value="天然气" <c:out value='${trendEnergyType=="天然气" ? "selected" : ""}'/>>天然气</option>
            <option value="光伏" <c:out value='${trendEnergyType=="光伏" ? "selected" : ""}'/>>光伏</option>
          </select>
        </label>
        <label>统计周期
          <select name="trendCycle" id="trendCycle">
            <option value="日" <c:out value='${trendCycle=="日" ? "selected" : ""}'/>>日</option>
            <option value="周" <c:out value='${trendCycle=="周" ? "selected" : ""}'/>>周</option>
            <option value="月" <c:out value='${trendCycle=="月" ? "selected" : ""}'/>>月</option>
            <option value="季度" <c:out value='${trendCycle=="季度" ? "selected" : ""}'/>>季度</option>
          </select>
        </label>
        <button type="submit" class="dashboard-btn primary">查询</button>
      </form>

      <div class="exec-two-col" style="margin-top:10px;">
        <div>
          <c:choose>
            <c:when test="${empty screenTrends}">
              <div class="dashboard-empty">暂无历史趋势数据（请确认 Stat_History_Trend 已插入测试数据）。</div>
            </c:when>
            <c:otherwise>
              <div class="table-container">
                <table class="data-table" id="trendTable">
                  <thead>
                  <tr>
                    <th>统计时间</th>
                    <th>能耗/发电量</th>
                    <th>同比</th>
                    <th>环比</th>
                    <th>行业均值</th>
                    <th>标记</th>
                  </tr>
                  </thead>
                  <tbody>
                  <c:forEach items="${screenTrends}" var="t">
                    <tr data-value="${t.value}" data-yoy="${t.yoyRate}" data-mom="${t.momRate}">
                      <td><c:out value="${t.statDate}"/></td>
                      <td><fmt:formatNumber value="${t.value}" pattern="#,#00.###"/></td>
                      <td>
                        <c:choose>
                          <c:when test="${t.yoyRate != null}">
                            <span class="trend-tag <c:out value='${t.yoyRate >= 0 ? "down" : "up"}'/>">同比 <c:out value='${t.yoyRate >= 0 ? "↑" : "↓"}'/> <c:out value="${t.yoyRate}"/>%</span>
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </td>
                      <td>
                        <c:choose>
                          <c:when test="${t.momRate != null}">
                            <span class="trend-tag <c:out value='${t.momRate >= 0 ? "down" : "up"}'/>">环比 <c:out value='${t.momRate >= 0 ? "↑" : "↓"}'/> <c:out value="${t.momRate}"/>%</span>
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </td>
                      <td>
                        <c:choose>
                          <c:when test="${t.industryAvg != null}"><fmt:formatNumber value="${t.industryAvg}" pattern="#,#00.###"/></c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </td>
                      <td>
                        <span class="trend-tag info"><c:out value="${t.trendTag}"/></span>
                      </td>
                    </tr>
                  </c:forEach>
                  </tbody>
                </table>
              </div>
            </c:otherwise>
          </c:choose>
        </div>

        <div>
          <div class="exec-analysis-card">
            <div class="exec-analysis-title">简单分析</div>
            <div class="exec-analysis-row">
              <div class="exec-analysis-k">当前选择</div>
              <div class="exec-analysis-v"><span id="an_energy"><c:out value="${trendEnergyType}"/></span> / <span id="an_cycle"><c:out value="${trendCycle}"/></span></div>
            </div>
            <div class="exec-analysis-row">
              <div class="exec-analysis-k">预测(近3期均值)</div>
              <div class="exec-analysis-v"><span id="an_forecast">--</span></div>
            </div>
            <div class="exec-analysis-row">
              <div class="exec-analysis-k">同比/环比标记</div>
              <div class="exec-analysis-v"><span id="an_flags">--</span></div>
            </div>
            <div class="exec-analysis-row">
              <div class="exec-analysis-k">建议</div>
              <div class="exec-analysis-v" id="an_hint">--</div>
            </div>
            <div class="dashboard-section-hint" style="margin-top:10px;">注：预测为简单统计方法，用于快速感知趋势，非严谨预测模型。</div>
          </div>
        </div>
      </div>
    </section>
  </div>
</div>

<script>
(function(){
  const ctx = '${ctx}';
  const userId = '${sessionScope.currentUser != null ? sessionScope.currentUser.userId : "0"}';
  const PREF_KEY = 'execScreenPrefs_v2_' + userId;

  const modal = document.getElementById('customModal');
  const btnCustomize = document.getElementById('btnCustomize');
  const btnApply = document.getElementById('btnApply');
  const btnReset = document.getElementById('btnReset');
  const btnExport = document.getElementById('btnExport');
  const btnImport = document.getElementById('btnImport');
  const importFile = document.getElementById('importFile');
  const refreshInput = document.getElementById('prefRefreshSec');
  const refreshEnabled = document.getElementById('prefRefreshEnabled');
  const moduleColsSel = document.getElementById('prefModuleCols');
  const orderListEl = document.getElementById('prefOrderList');

  function defaultPrefs(){
    return {
      refreshEnabled: true,
      refreshSec: 60,
      moduleCols: 2,
      moduleOrder: ['energy','pv','dist','alarm'],
      modules: {energy:true, pv:true, dist:true, alarm:true},
      fields: {
        energy:{totalKwh:true,totalWaterM3:true,totalSteamT:true,totalGasM3:true,monthlyCost:true,targetCompletion:true},
        pv:{todayGen:true,deviceNormal:true},
        dist:{roomCount:true,circuitCount:true,transformerCount:true,latestCircuitTime:true},
        alarm:{alarmSplit:true,recentHigh:true}
      }
    };
  }

  function loadPrefs(){
    try{
      const raw = localStorage.getItem(PREF_KEY);
      if(!raw) return defaultPrefs();
      const p = JSON.parse(raw);
      const d = defaultPrefs();
      // 轻量合并（向后兼容）
      p.refreshEnabled = (p.refreshEnabled === false) ? false : true;
      p.refreshSec = Number(p.refreshSec || d.refreshSec);
      p.moduleCols = Number(p.moduleCols || d.moduleCols);
      p.moduleCols = Math.min(3, Math.max(1, p.moduleCols));

      // moduleOrder 兼容：如果缺失则用默认；如包含未知模块则过滤
      const order = Array.isArray(p.moduleOrder) ? p.moduleOrder.slice() : d.moduleOrder.slice();
      const known = new Set(d.moduleOrder);
      const filtered = order.filter(x=>known.has(x));
      d.moduleOrder.forEach(x=>{ if(!filtered.includes(x)) filtered.push(x); });
      p.moduleOrder = filtered;

      p.modules = Object.assign(d.modules, p.modules||{});
      p.fields = Object.assign(d.fields, p.fields||{});
      for(const k in d.fields){
        p.fields[k] = Object.assign(d.fields[k], (p.fields||{})[k]||{});
      }
      return p;
    }catch(e){
      return defaultPrefs();
    }
  }

  function savePrefs(p){
    localStorage.setItem(PREF_KEY, JSON.stringify(p));
  }

  function openModal(){
    modal.setAttribute('aria-hidden','false');
    modal.classList.add('open');
  }
  function closeModal(){
    modal.setAttribute('aria-hidden','true');
    modal.classList.remove('open');
  }

  function syncModalFromPrefs(p){
    refreshInput.value = p.refreshSec;
    if(refreshEnabled) refreshEnabled.checked = !!p.refreshEnabled;
    if(moduleColsSel) moduleColsSel.value = String(p.moduleCols || 2);

    document.querySelectorAll('[data-pref-module]').forEach(cb=>{
      const m = cb.getAttribute('data-pref-module');
      cb.checked = !!p.modules[m];
    });
    document.querySelectorAll('[data-pref-field]').forEach(cb=>{
      const parts = cb.getAttribute('data-pref-field').split(':');
      const m = parts[0], f = parts[1];
      cb.checked = !!(p.fields[m] && p.fields[m][f]);
    });

    renderOrderList(p);
  }


  function moduleTitle(id){
    const map = {energy:'能源总览', pv:'光伏总览', dist:'配电网运行状态', alarm:'告警统计'};
    return map[id] || id;
  }

  function moveInArray(arr, fromIdx, toIdx){
    const a = arr.slice();
    const [item] = a.splice(fromIdx, 1);
    a.splice(toIdx, 0, item);
    return a;
  }

  function renderOrderList(p){
    if(!orderListEl) return;
    orderListEl.innerHTML = '';
    const list = p.moduleOrder || ['energy','pv','dist','alarm'];

    list.forEach((id, i)=>{
      const row = document.createElement('div');
      row.className = 'exec-sort-item';
      row.draggable = true;
      row.dataset.mid = id;

      // 注意：JSP 会把“$ + 花括号”的写法当作 EL 表达式解析，因此这里用字符串拼接，避免模板字符串。
      const title = moduleTitle(id);
      const disableUp = (i === 0) ? 'disabled' : '';
      const disableDown = (i === list.length - 1) ? 'disabled' : '';
      row.innerHTML =
        '<div class="exec-sort-left">'
          + '<div class="exec-drag-handle" title="拖拽排序">⠿</div>'
          + '<div class="exec-sort-name" title="' + title + '">' + title + '</div>'
        + '</div>'
        + '<div class="exec-sort-actions">'
          + '<button type="button" class="exec-mini-btn" data-act="up" ' + disableUp + '>上移</button>'
          + '<button type="button" class="exec-mini-btn" data-act="down" ' + disableDown + '>下移</button>'
        + '</div>';

      // 拖拽
      row.addEventListener('dragstart', (e)=>{
        e.dataTransfer.setData('text/plain', id);
      });
      row.addEventListener('dragover', (e)=>e.preventDefault());
      row.addEventListener('drop', (e)=>{
        e.preventDefault();
        const fromId = e.dataTransfer.getData('text/plain');
        const toId = id;
        if(!fromId || fromId === toId) return;
        const fromIdx = p.moduleOrder.indexOf(fromId);
        const toIdx = p.moduleOrder.indexOf(toId);
        if(fromIdx<0 || toIdx<0) return;
        p.moduleOrder = moveInArray(p.moduleOrder, fromIdx, toIdx);
        savePrefs(p);
        renderOrderList(p);
        applyPrefs(p);
      });

      // 上下移
      row.querySelectorAll('button[data-act]').forEach(btn=>{
        btn.addEventListener('click', ()=>{
          const act = btn.getAttribute('data-act');
          const curIdx = p.moduleOrder.indexOf(id);
          if(curIdx<0) return;
          if(act==='up' && curIdx>0){
            p.moduleOrder = moveInArray(p.moduleOrder, curIdx, curIdx-1);
          } else if(act==='down' && curIdx<p.moduleOrder.length-1){
            p.moduleOrder = moveInArray(p.moduleOrder, curIdx, curIdx+1);
          }
          savePrefs(p);
          renderOrderList(p);
          applyPrefs(p);
        });
      });

      orderListEl.appendChild(row);
    });
  }

  function prefsFromModal(){
    const p = loadPrefs();
    p.refreshEnabled = refreshEnabled ? !!refreshEnabled.checked : true;
    p.refreshSec = Math.max(30, Number(refreshInput.value||60));
    if(moduleColsSel){
      p.moduleCols = Math.min(3, Math.max(1, Number(moduleColsSel.value||2)));
    }
    if(!Array.isArray(p.moduleOrder) || !p.moduleOrder.length){
      p.moduleOrder = ['energy','pv','dist','alarm'];
    }

    document.querySelectorAll('[data-pref-module]').forEach(cb=>{
      p.modules[cb.getAttribute('data-pref-module')] = cb.checked;
    });
    document.querySelectorAll('[data-pref-field]').forEach(cb=>{
      const parts = cb.getAttribute('data-pref-field').split(':');
      const m = parts[0], f = parts[1];
      if(!p.fields[m]) p.fields[m] = {};
      p.fields[m][f] = cb.checked;
    });
    return p;
  }

  function applyPrefs(p){
    // 布局：模块列数（窄屏由 CSS 媒体查询兜底）
    const grid = document.getElementById('moduleGrid');
    if(grid){
      grid.style.setProperty('--exec-mod-cols', String(p.moduleCols || 2));
      // 排序：按 moduleOrder 重新排列 DOM
      if(Array.isArray(p.moduleOrder) && p.moduleOrder.length){
        p.moduleOrder.forEach(mid=>{
          const el = document.getElementById('mod_' + mid);
          if(el) grid.appendChild(el);
        });
      }
    }

    // 模块显示 + 指标显示
    document.querySelectorAll('.exec-module').forEach(mod=>{
      const m = mod.getAttribute('data-module');
      mod.style.display = p.modules[m] ? '' : 'none';
      mod.querySelectorAll('[data-field]').forEach(kpi=>{
        const f = kpi.getAttribute('data-field');
        const show = p.fields[m] ? !!p.fields[m][f] : true;
        kpi.style.display = show ? '' : 'none';
      });
    });

    // 刷新
    if(window.__exec_refresh_timer){
      clearInterval(window.__exec_refresh_timer);
      window.__exec_refresh_timer = null;
    }
    if(p.refreshEnabled){
      window.__exec_refresh_timer = setInterval(fetchScreenData, (p.refreshSec||60) * 1000);
    }
  }

  function formatNumber(n){
    const x = Number(n);
    if(!isFinite(x)) return '--';
    return x.toLocaleString(undefined, {maximumFractionDigits: 3});
  }

  function setText(id, val){
    const el = document.getElementById(id);
    if(el) el.textContent = val;
  }

  function fetchScreenData(){
    fetch(ctx + '/app?module=dashboard&view=execScreen&ajax=screenData', {cache:'no-store'})
      .then(r=>r.json())
      .then(d=>{
        if(!d) return;
        const rt = d.realtime || {};
        setText('rt_lastRefresh', rt.statTime || '--');
        setText('rt_statTime', rt.statTime || '--');
        setText('rt_td_time', rt.statTime || '--');

        setText('kpi_totalKwh', formatNumber(rt.totalKwh));
        setText('kpi_totalWater', formatNumber(rt.totalWaterM3));
        setText('kpi_totalSteam', formatNumber(rt.totalSteamT));
        setText('kpi_totalGas', formatNumber(rt.totalGasM3));

        setText('rt_td_kwh', formatNumber(rt.totalKwh));
        setText('rt_td_water', formatNumber(rt.totalWaterM3));
        setText('rt_td_steam', formatNumber(rt.totalSteamT));
        setText('rt_td_gas', formatNumber(rt.totalGasM3));
        setText('rt_td_pvgen', formatNumber(rt.pvGenKwh));
        setText('rt_td_pvself', formatNumber(rt.pvSelfKwh));
        setText('rt_td_alarm', (rt.totalAlarm==null?'--':rt.totalAlarm));

        setText('kpi_alarmTotal', (rt.totalAlarm==null?'--':rt.totalAlarm));
        setText('kpi_alarmHigh', (rt.alarmHigh==null?'--':rt.alarmHigh));
        setText('kpi_alarmMid', (rt.alarmMid==null?'--':rt.alarmMid));
        setText('kpi_alarmLow', (rt.alarmLow==null?'--':rt.alarmLow));
        setText('rt_alarmHigh', (rt.alarmHigh==null?'--':rt.alarmHigh));
        setText('rt_alarmMid', (rt.alarmMid==null?'--':rt.alarmMid));
        setText('rt_alarmLow', (rt.alarmLow==null?'--':rt.alarmLow));

        const pv = d.pvStats || {};
        setText('kpi_pvTodayGen', pv.todayGen==null?'--':formatNumber(pv.todayGen));
        // 不要用模板字符串，避免被 JSP 当作 EL 解析
        setText('kpi_pvDevice', (pv.totalCount||0) + ' / ' + (pv.normalCount||0) + ' / ' + (pv.faultCount||0) + ' / ' + (pv.offlineCount||0));

        const dist = d.distStats || {};
        setText('kpi_roomCount', dist.roomCount==null?'--':dist.roomCount);
        setText('kpi_circuitCount', dist.circuitCount==null?'--':dist.circuitCount);
        setText('kpi_transformerCount', dist.transformerCount==null?'--':dist.transformerCount);
        setText('kpi_latestCircuit', dist.latestCircuitTime || '--');

        setText('rt_serverTime', d.serverTime || '--');

        // 告警列表
        const list = Array.isArray(d.highAlarms) ? d.highAlarms : [];
        const ul = document.getElementById('alarmList');
        if(ul){
          ul.innerHTML = list.length ? '' : '<li>暂无高等级告警</li>';
          list.slice(0,6).forEach(a=>{
            const li = document.createElement('li');
            li.innerHTML = '<span class="workbench-tag danger">高</span>'
              + '<span class="exec-alarm-time">' + (a.occurTime||'') + '</span>'
              + '<span class="exec-alarm-content"></span>';
            li.querySelector('.exec-alarm-content').textContent = a.content || '';
            ul.appendChild(li);
          });
        }
      })
      .catch(()=>{});
  }

  function analyzeTrends(){
    const table = document.getElementById('trendTable');
    if(!table) return;
    const rows = Array.from(table.querySelectorAll('tbody tr'));
    const vals = rows.map(r=>Number(r.getAttribute('data-value'))).filter(v=>isFinite(v));
    const yoy = rows.map(r=>Number(r.getAttribute('data-yoy'))).filter(v=>isFinite(v));
    const mom = rows.map(r=>Number(r.getAttribute('data-mom'))).filter(v=>isFinite(v));

    if(vals.length){
      const last3 = vals.slice(0,3); // 按时间倒序
      const forecast = last3.reduce((a,b)=>a+b,0) / last3.length;
      setText('an_forecast', formatNumber(forecast));
    }

    const lastRow = rows[0];
    if(lastRow){
      const ly = Number(lastRow.getAttribute('data-yoy'));
      const lm = Number(lastRow.getAttribute('data-mom'));
      const flags = [];
      if(isFinite(ly)) flags.push('同比' + (ly>=0?'↑':'↓') + Math.abs(ly) + '%');
      if(isFinite(lm)) flags.push('环比' + (lm>=0?'↑':'↓') + Math.abs(lm) + '%');
      setText('an_flags', flags.length?flags.join('，'):'--');

      let hint = '建议：保持监控，结合产线/气候/检修因素做解释。';
      if(isFinite(ly) && Math.abs(ly) >= 10){
        hint = ly >= 0 ? '建议：同比上升明显，优先排查异常耗能点与工况变化。' : '建议：同比下降明显，可复盘节能措施并固化策略。';
      } else if(isFinite(lm) && Math.abs(lm) >= 10){
        hint = lm >= 0 ? '建议：环比上升明显，检查短期异常/峰谷策略/告警事件。' : '建议：环比下降明显，继续跟踪是否为长期趋势。';
      }
      const el = document.getElementById('an_hint');
      if(el) el.textContent = hint;
    }
  }

  // 事件
  btnCustomize && btnCustomize.addEventListener('click', ()=>{
    const p = loadPrefs();
    syncModalFromPrefs(p);
    openModal();
  });

  modal && modal.addEventListener('click', (e)=>{
    const t = e.target;
    if(t && t.getAttribute && t.getAttribute('data-close')==='1'){
      closeModal();
    }
  });

  btnReset && btnReset.addEventListener('click', ()=>{
    const p = defaultPrefs();
    savePrefs(p);
    syncModalFromPrefs(p);
    applyPrefs(p);
  });

  btnApply && btnApply.addEventListener('click', ()=>{
    const p = prefsFromModal();
    savePrefs(p);
    applyPrefs(p);
    closeModal();
  });


  // 导出/导入
  function downloadJson(filename, obj){
    const blob = new Blob([JSON.stringify(obj, null, 2)], {type:'application/json'});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(()=>URL.revokeObjectURL(a.href), 300);
  }

  btnExport && btnExport.addEventListener('click', ()=>{
    const p = loadPrefs();
    downloadJson('exec_screen_prefs.json', p);
  });

  btnImport && btnImport.addEventListener('click', ()=>{
    if(importFile) importFile.click();
  });

  importFile && importFile.addEventListener('change', ()=>{
    const f = importFile.files && importFile.files[0];
    if(!f) return;
    const rd = new FileReader();
    rd.onload = ()=>{
      try{
        const obj = JSON.parse(String(rd.result||'{}'));
        const d = defaultPrefs();
        const merged = Object.assign(d, obj||{});
        savePrefs(merged);
        syncModalFromPrefs(merged);
        applyPrefs(merged);
      }catch(e){
        alert('导入失败：配置文件不是合法 JSON');
      }finally{
        importFile.value = '';
      }
    };
    rd.readAsText(f, 'utf-8');
  });


  // init
  const prefs = loadPrefs();
  syncModalFromPrefs(prefs);
  applyPrefs(prefs);
  fetchScreenData();
  analyzeTrends();
})();
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
