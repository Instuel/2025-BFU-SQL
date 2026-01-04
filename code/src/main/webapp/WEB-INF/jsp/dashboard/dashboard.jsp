<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<c:set var="roleType" value="${sessionScope.currentRoleType}" />

<div class="main-content dashboard-page">
  <c:choose>
    <c:when test="${roleType == 'ADMIN'}">
      <div class="admin-workspace-container">
        <div class="admin-workspace-header">
          <h1>系统管理员工作台</h1>
          <p>统一管理用户权限、告警规则与数据运维，保障平台稳定运行。</p>
        </div>

        <div class="admin-module-card">
          <div class="admin-module-icon rbac">👥</div>
          <div class="admin-module-title">账号与权限维护</div>
          <div class="admin-module-desc">维护全员账号信息、角色分配与负责区域限制，确保权限最小化。</div>
          <div class="admin-module-stats">
            <div class="admin-stat-item">
              <div class="admin-stat-value">126</div>
              <div class="admin-stat-label">在岗账号</div>
            </div>
            <div class="admin-stat-item">
              <div class="admin-stat-value">8</div>
              <div class="admin-stat-label">待审批申请</div>
            </div>
          </div>
        </div>

        <div class="admin-module-card">
          <div class="admin-module-icon alarm">🚨</div>
          <div class="admin-module-title">告警规则配置</div>
          <div class="admin-module-desc">调整设备温度阈值、峰谷时段与告警升级逻辑，提升响应效率。</div>
          <div class="admin-module-stats">
            <div class="admin-stat-item">
              <div class="admin-stat-value">42</div>
              <div class="admin-stat-label">活跃规则</div>
            </div>
            <div class="admin-stat-item">
              <div class="admin-stat-value">5</div>
              <div class="admin-stat-label">待审核变更</div>
            </div>
          </div>
        </div>

        <div class="admin-module-card">
          <div class="admin-module-icon param">🧭</div>
          <div class="admin-module-title">峰谷与参数配置</div>
          <div class="admin-module-desc">维护峰谷电价时段、设备运行参数与能耗核算规则。</div>
          <div class="admin-module-stats">
            <div class="admin-stat-item">
              <div class="admin-stat-value">3</div>
              <div class="admin-stat-label">生效策略</div>
            </div>
            <div class="admin-stat-item">
              <div class="admin-stat-value">12</div>
              <div class="admin-stat-label">待发布配置</div>
            </div>
          </div>
        </div>

        <div class="admin-module-card">
          <div class="admin-module-icon db">💾</div>
          <div class="admin-module-title">数据备份与恢复</div>
          <div class="admin-module-desc">执行备份策略与恢复演练，监控数据库容量与查询性能。</div>
          <div class="admin-module-stats">
            <div class="admin-stat-item">
              <div class="admin-stat-value">98.4%</div>
              <div class="admin-stat-label">备份成功率</div>
            </div>
            <div class="admin-stat-item">
              <div class="admin-stat-value">72%</div>
              <div class="admin-stat-label">磁盘占用</div>
            </div>
          </div>
        </div>

        <div class="admin-system-status">
          <div class="admin-section-title">系统运行状态</div>
          <div class="admin-status-grid">
            <div class="admin-status-item normal">
              <div class="admin-status-label">数据库响应时间</div>
              <div class="admin-status-value">168 ms</div>
            </div>
            <div class="admin-status-item normal">
              <div class="admin-status-label">接口可用率</div>
              <div class="admin-status-value">99.92%</div>
            </div>
            <div class="admin-status-item warning">
              <div class="admin-status-label">磁盘占用</div>
              <div class="admin-status-value">72% / 1.4 TB</div>
            </div>
            <div class="admin-status-item normal">
              <div class="admin-status-label">备份最近执行</div>
              <div class="admin-status-value">2025-03-18 02:00</div>
            </div>
          </div>
        </div>

        <div class="admin-quick-actions">
          <div class="admin-section-title">常用操作</div>
          <div class="admin-action-buttons">
            <button class="admin-action-btn primary">📌 新建角色模板</button>
            <button class="admin-action-btn success">✅ 发布规则更新</button>
            <button class="admin-action-btn warning">⚙️ 发起备份</button>
            <button class="admin-action-btn danger">🧯 恢复演练</button>
          </div>
        </div>
      </div>
    </c:when>

    <c:when test="${roleType == 'ENERGY'}">
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>能源管理员工作台</h1>
          <p>聚焦能耗报表、数据质量审核与节能优化方案，实时追踪能耗成效。</p>
          <div class="dashboard-meta">
            <div class="dashboard-meta-item">覆盖区域：A1 / A2 / B1 厂区</div>
            <div class="dashboard-meta-item">重点能源类型：电 / 天然气 / 蒸汽</div>
            <div class="dashboard-meta-item">本月峰谷策略：已启用 3 套</div>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">待审核能耗记录</div>
            <div class="dashboard-stat-value"><c:out value="${pendingReviewCount}" default="--"/></div>
            <div class="dashboard-stat-trend up">▲ 3 条新增</div>
            <div class="dashboard-stat-subtext">数据质量差待复核</div>
          </div>
          <div class="dashboard-stat-card gas">
            <div class="dashboard-stat-label">高耗能区域</div>
            <div class="dashboard-stat-value"><c:out value="${highConsumptionCount}" default="--"/></div>
            <div class="dashboard-stat-trend down">▼ 2 处优化完成</div>
            <div class="dashboard-stat-subtext">重点关注：A2 车间</div>
          </div>
          <div class="dashboard-stat-card pv">
            <div class="dashboard-stat-label">节能方案执行中</div>
            <div class="dashboard-stat-value"><c:out value="${activePlanCount}" default="--"/></div>
            <div class="dashboard-stat-trend up">▲ 1 项新增</div>
            <div class="dashboard-stat-subtext">完成率：66%</div>
          </div>
        </div>

        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div>
              <div class="dashboard-chart-title">区域能耗报表与峰谷分析</div>
              <div class="dashboard-section-hint">支持不同区域、不同能源类型的月度报表与峰谷曲线对比。</div>
            </div>
            <div class="dashboard-chart-actions">
              <span class="dashboard-badge">最新报表：2025-03</span>
              <span class="dashboard-badge">峰谷分析：更新中</span>
              <a class="dashboard-chart-action-btn" href="${ctx}/app?module=energy&view=report_overview">查看报表</a>
            </div>
          </div>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>报表名称</th>
                <th>区域</th>
                <th>能源类型</th>
                <th>本月能耗</th>
                <th>峰谷差值</th>
                <th>异常标记</th>
              </tr>
              </thead>
              <tbody>
              <tr>
                <td>天然气月度能耗</td>
                <td>A1 厂区</td>
                <td>天然气</td>
                <td>30,880 m³</td>
                <td>18%</td>
                <td><span class="trend-tag down">需复核</span></td>
              </tr>
              <tr>
                <td>电力峰谷分析</td>
                <td>B1 厂区</td>
                <td>电</td>
                <td>128,600 kWh</td>
                <td>21%</td>
                <td><span class="trend-tag up">符合预期</span></td>
              </tr>
              <tr>
                <td>蒸汽能耗日报</td>
                <td>A2 车间</td>
                <td>蒸汽</td>
                <td>8,640 t</td>
                <td>12%</td>
                <td><span class="trend-tag down">待排查</span></td>
              </tr>
              </tbody>
            </table>
          </div>
        </section>

        <div class="content-grid">
          <div class="dashboard-main-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">能耗数据质量审核</div>
                  <div class="dashboard-section-hint">对标“数据质量差”记录，完成复核与异常原因标注。</div>
                </div>
                <div class="dashboard-chart-actions">
                  <a class="dashboard-chart-action-btn" href="${ctx}/app?module=energy&view=data_review">进入审核</a>
                </div>
              </div>
              <div class="workbench-list">
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">A2 车间天然气计量异常</div>
                    <div class="workbench-item-desc">2025-03-16 15:00 ～ 16:00 读数跳变</div>
                  </div>
                  <span class="workbench-tag warning">待复核</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">B1 厂区电表通讯异常</div>
                    <div class="workbench-item-desc">已通知运维检查采集器状态</div>
                  </div>
                  <span class="workbench-tag info">处理中</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">A1 厂区蒸汽数据缺失</div>
                    <div class="workbench-item-desc">补采数据需确认真实性</div>
                  </div>
                  <span class="workbench-tag warning">待复核</span>
                </div>
              </div>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">能耗优化方案跟踪</div>
                  <div class="dashboard-section-hint">调整峰谷时段与负荷策略，追踪节能效果。</div>
                </div>
                <div class="dashboard-chart-actions">
                  <a class="dashboard-chart-action-btn" href="${ctx}/app?module=energy&view=optimization_plan">方案管理</a>
                </div>
              </div>
              <div class="workbench-grid">
                <div class="workbench-card">
                  <div class="workbench-card-title">峰谷用电时段调整</div>
                  <div class="workbench-card-desc">B1 厂区峰时负荷外移至 22:00 后。</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag success">节能 6.2%</span>
                    <span class="workbench-tag info">执行中</span>
                  </div>
                </div>
                <div class="workbench-card">
                  <div class="workbench-card-title">高耗能设备排查</div>
                  <div class="workbench-card-desc">重点排查 A2 空压机群组，确认泄漏点。</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag warning">待复查</span>
                    <span class="workbench-tag info">排查中</span>
                  </div>
                </div>
                <div class="workbench-card">
                  <div class="workbench-card-title">蒸汽回收优化</div>
                  <div class="workbench-card-desc">提升冷凝水回收率，降低蒸汽损耗。</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag success">完成</span>
                    <span class="workbench-tag info">已归档</span>
                  </div>
                </div>
              </div>
            </section>
          </div>

          <div class="dashboard-side-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">高耗能区域排查</div>
                <div class="dashboard-chart-actions">
                  <a class="dashboard-chart-action-btn" href="${ctx}/app?module=energy&view=investigation_list">发起排查</a>
                </div>
              </div>
              <div class="alarm-list">
                <div class="alarm-item">
                  <div class="alarm-level high">重点排查</div>
                  <div class="alarm-time">A2 车间 / 空压系统</div>
                  <div class="alarm-content">单位产线能耗高出基准 18%。</div>
                  <div class="alarm-device">责任人：能源管理员</div>
                </div>
                <div class="alarm-item">
                  <div class="alarm-level medium">持续观察</div>
                  <div class="alarm-time">B1 厂区 / 机加工段</div>
                  <div class="alarm-content">电耗连续三周高于目标线。</div>
                  <div class="alarm-device">需评估工艺负荷</div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </c:when>

    <c:when test="${roleType == 'OM'}">
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>运维人员工作台</h1>
          <p>集中处理告警工单、设备故障与预防性维护计划。</p>
          <div class="dashboard-meta">
            <div class="dashboard-meta-item">负责区域：A1 厂区 / B1 变电所</div>
            <div class="dashboard-meta-item">高等级告警：2 条未处理</div>
            <div class="dashboard-meta-item">本周维护计划：5 项</div>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="dashboard-stat-card alarm">
            <div class="dashboard-stat-label">待响应告警</div>
            <div class="dashboard-stat-value">5</div>
            <div class="dashboard-stat-trend up">▲ 2 条高等级</div>
            <div class="dashboard-stat-subtext">需 30 分钟内响应</div>
          </div>
          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">处理中工单</div>
            <div class="dashboard-stat-value">8</div>
            <div class="dashboard-stat-trend down">▼ 3 条已关闭</div>
            <div class="dashboard-stat-subtext">超时风险：1 条</div>
          </div>
          <div class="dashboard-stat-card efficiency">
            <div class="dashboard-stat-label">预防性维护计划</div>
            <div class="dashboard-stat-value">5</div>
            <div class="dashboard-stat-trend up">▲ 2 项新增</div>
            <div class="dashboard-stat-subtext">本周完成率：40%</div>
          </div>
        </div>

        <div class="content-grid">
          <div class="dashboard-main-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">运维工单通知</div>
                  <div class="dashboard-section-hint">高等级告警需优先处理并确认现场反馈。</div>
                </div>
              </div>
              <div class="workbench-list">
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">35KV 配电房温度过高</div>
                    <div class="workbench-item-desc">工单编号：OM-20250318-01</div>
                  </div>
                  <span class="workbench-tag danger">高等级</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">PV 逆变器离线告警</div>
                    <div class="workbench-item-desc">工单编号：OM-20250318-04</div>
                  </div>
                  <span class="workbench-tag warning">处理中</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">A1 车间水压波动</div>
                    <div class="workbench-item-desc">工单编号：OM-20250318-06</div>
                  </div>
                  <span class="workbench-tag info">待处理</span>
                </div>
              </div>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">现场处理结果登记</div>
                  <div class="dashboard-section-hint">处理后需填写故障原因、恢复时间并上传附件。</div>
                </div>
              </div>
              <div class="workbench-grid">
                <div class="workbench-card">
                  <div class="workbench-card-title">变压器 T-01 散热风机更换</div>
                  <div class="workbench-card-desc">提交故障分析与照片，完成恢复确认。</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag success">待提交</span>
                    <span class="workbench-tag info">附件 2 个</span>
                  </div>
                </div>
                <div class="workbench-card">
                  <div class="workbench-card-title">水泵控制柜报警复位</div>
                  <div class="workbench-card-desc">记录处理耗时与原因分类。</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag warning">处理中</span>
                    <span class="workbench-tag info">预计完成 18:30</span>
                  </div>
                </div>
              </div>
            </section>
          </div>

          <div class="dashboard-side-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">设备台账与维护计划</div>
              </div>
              <div class="workbench-list compact">
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">变压器 T-01</div>
                    <div class="workbench-item-desc">下次校准：2025-03-25</div>
                  </div>
                  <span class="workbench-tag info">需安排</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">主配电柜 MDB-02</div>
                    <div class="workbench-item-desc">巡检周期：每周一</div>
                  </div>
                  <span class="workbench-tag success">正常</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">逆变器 PV-INV-07</div>
                    <div class="workbench-item-desc">检查散热通道</div>
                  </div>
                  <span class="workbench-tag warning">本周</span>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </c:when>

    <c:when test="${roleType == 'ANALYST'}">
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>数据分析师工作台</h1>
          <p>聚焦预测模型偏差、能耗规律挖掘与多维报告输出。</p>
          <div class="dashboard-meta">
            <div class="dashboard-meta-item">当前模型版本：<c:out value="${analystOverview.modelVersion}" default="--"/></div>
            <div class="dashboard-meta-item">数据窗口：<c:out value="${analystOverview.dataWindowLabel}" default="--"/></div>
            <div class="dashboard-meta-item">本周报告：<c:out value="${analystOverview.pendingReportCount}" default="0"/> 份待提交</div>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="dashboard-stat-card pv">
            <div class="dashboard-stat-label">预测偏差均值</div>
            <div class="dashboard-stat-value">
              <c:choose>
                <c:when test="${not empty analystOverview.avgDeviationRate}">
                  <fmt:formatNumber value="${analystOverview.avgDeviationRate}" minFractionDigits="1" maxFractionDigits="1"/>%
                </c:when>
                <c:otherwise>--</c:otherwise>
              </c:choose>
            </div>
            <div class="dashboard-stat-trend down"><c:out value="${analystOverview.deviationTrend}" default="暂无对比数据"/></div>
            <div class="dashboard-stat-subtext"><c:out value="${analystOverview.weatherHint}" default="--"/></div>
          </div>
          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">关联分析任务</div>
            <div class="dashboard-stat-value"><c:out value="${analystOverview.correlationTaskCount}" default="0"/></div>
            <div class="dashboard-stat-trend up">▲ 聚焦产线能耗关联</div>
            <div class="dashboard-stat-subtext">产线能耗与产量耦合分析</div>
          </div>
          <div class="dashboard-stat-card efficiency">
            <div class="dashboard-stat-label">分析报告输出</div>
            <div class="dashboard-stat-value"><c:out value="${analystOverview.reportCount}" default="0"/></div>
            <div class="dashboard-stat-trend up">▲ 待审报告持续更新</div>
            <div class="dashboard-stat-subtext">
              <c:choose>
                <c:when test="${not empty reportItems}">
                  <c:out value="${reportItems[0].reportTitle}"/>
                </c:when>
                <c:otherwise>季度能源成本分析</c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>

        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div>
              <div class="dashboard-chart-title">光伏预测偏差分析</div>
              <div class="dashboard-section-hint">对比预测值与实际值差异，追踪模型优化效果。</div>
            </div>
            <div class="dashboard-chart-actions">
              <span class="dashboard-badge">偏差阈值：±6%</span>
              <span class="dashboard-badge">最新评估：2025-03-18</span>
            </div>
          </div>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>场站</th>
                <th>预测值</th>
                <th>实际值</th>
                <th>偏差</th>
                <th>影响因素</th>
                <th>优化建议</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach items="${forecastInsights}" var="insight">
                <tr>
                  <td><c:out value="${insight.pointName}" default="--"/></td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty insight.forecastVal}">
                        <fmt:formatNumber value="${insight.forecastVal}" minFractionDigits="1" maxFractionDigits="1"/> kWh
                      </c:when>
                      <c:otherwise>--</c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty insight.actualVal}">
                        <fmt:formatNumber value="${insight.actualVal}" minFractionDigits="1" maxFractionDigits="1"/> kWh
                      </c:when>
                      <c:otherwise>--</c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty insight.deviationRate}">
                        <fmt:formatNumber value="${insight.deviationRate}" minFractionDigits="1" maxFractionDigits="1"/>%
                      </c:when>
                      <c:otherwise>--</c:otherwise>
                    </c:choose>
                  </td>
                  <td><c:out value="${insight.weatherFactor}" default="--"/></td>
                  <td><c:out value="${insight.optimizationAdvice}" default="--"/></td>
                </tr>
              </c:forEach>
              <c:if test="${empty forecastInsights}">
                <tr>
                  <td colspan="6" style="text-align:center;color:#94a3b8;">暂无预测偏差分析数据</td>
                </tr>
              </c:if>
              </tbody>
            </table>
          </div>
        </section>

        <div class="content-grid">
          <div class="dashboard-main-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">能耗规律挖掘</div>
                  <div class="dashboard-section-hint">分析产线能耗与产量、排产的关联关系。</div>
                </div>
              </div>
              <div class="workbench-grid">
                <c:forEach items="${energyInsights}" var="insight">
                  <div class="workbench-card">
                    <div class="workbench-card-title">
                      <c:out value="${insight.lineName}" default="产线"/> /
                      <c:out value="${insight.factoryName}" default="厂区"/>
                    </div>
                    <div class="workbench-card-desc">
                      单位产量能耗：
                      <c:choose>
                        <c:when test="${not empty insight.energyPerOutput}">
                          <fmt:formatNumber value="${insight.energyPerOutput}" minFractionDigits="2" maxFractionDigits="2"/>
                        </c:when>
                        <c:otherwise>--</c:otherwise>
                      </c:choose>
                    </div>
                    <div class="workbench-card-meta">
                      <span class="workbench-tag info">
                        相关系数
                        <c:choose>
                          <c:when test="${not empty insight.corrCoeff}">
                            <fmt:formatNumber value="${insight.corrCoeff}" minFractionDigits="2" maxFractionDigits="2"/>
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </span>
                      <span class="workbench-tag <c:out value='${insight.savingPotential == \"存在节能潜力\" ? \"warning\" : \"success\"}'/>">
                        <c:out value="${insight.savingPotential}" default="--"/>
                      </span>
                    </div>
                  </div>
                </c:forEach>
                <c:if test="${empty energyInsights}">
                  <div class="workbench-card">
                    <div class="workbench-card-title">暂无产线能耗关联数据</div>
                    <div class="workbench-card-desc">请先维护产线产量与能耗映射。</div>
                  </div>
                </c:if>
              </div>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">多维分析报告</div>
                  <div class="dashboard-section-hint">为管理层提供季度能源成本与节能潜力分析。</div>
                </div>
              </div>
              <div class="workbench-list">
                <c:forEach items="${reportItems}" var="report">
                  <div class="workbench-list-item">
                    <div>
                      <div class="workbench-item-title"><c:out value="${report.reportTitle}" default="季度能源成本分析报告"/></div>
                      <div class="workbench-item-desc">
                        <c:out value="${report.factoryName}" default="厂区"/> /
                        <c:out value="${report.energyType}" default="能源"/> 成本
                        <c:choose>
                          <c:when test="${not empty report.totalCost}">
                            <fmt:formatNumber value="${report.totalCost}" minFractionDigits="0" maxFractionDigits="0"/> 元
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </div>
                    </div>
                    <c:set var="reportStatus" value="${report.reportStatus}"/>
                    <span class="workbench-tag <c:out value='${reportStatus == \"需关注\" ? \"warning\" : (reportStatus == \"表现良好\" ? \"success\" : \"info\")}'/>">
                      <c:out value="${reportStatus}" default="待提交"/>
                    </span>
                  </div>
                </c:forEach>
                <c:if test="${empty reportItems}">
                  <div class="workbench-list-item">
                    <div>
                      <div class="workbench-item-title">季度能源成本分析报告</div>
                      <div class="workbench-item-desc">暂无可生成报表数据</div>
                    </div>
                    <span class="workbench-tag info">待生成</span>
                  </div>
                </c:if>
              </div>
            </section>
          </div>

          <div class="dashboard-side-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">模型优化清单</div>
              </div>
              <div class="workbench-list compact">
                <c:forEach items="${modelOptimizations}" var="item">
                  <div class="workbench-list-item">
                    <div>
                      <div class="workbench-item-title"><c:out value="${item.title}" default="--"/></div>
                      <div class="workbench-item-desc"><c:out value="${item.desc}" default="--"/></div>
                    </div>
                    <c:set var="statusText" value="${item.status}"/>
                    <span class="workbench-tag <c:out value='${fn:contains(statusText, \"已\") || fn:contains(statusText, \"完成\") ? \"success\" : (fn:contains(statusText, \"待\") || fn:contains(statusText, \"排队\") ? \"warning\" : \"info\")}'/>">
                      <c:out value="${statusText}" default="--"/>
                    </span>
                  </div>
                </c:forEach>
                <c:if test="${empty modelOptimizations}">
                  <div class="workbench-list-item">
                    <div>
                      <div class="workbench-item-title">暂无优化事项</div>
                      <div class="workbench-item-desc">模型运行稳定</div>
                    </div>
                    <span class="workbench-tag info">正常</span>
                  </div>
                </c:if>
              </div>
            </section>
          </div>
        </div>
      </div>
    </c:when>

    <c:when test="${roleType == 'EXEC'}">
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>企业管理层工作台</h1>
          <p>快速掌握能源运行总览、光伏收益与高等级告警，支撑决策。</p>
          <div class="dashboard-meta">
            <div class="dashboard-meta-item">月度能耗总结：<c:out value="${execOverview.monthLabel}"/></div>
            <div class="dashboard-meta-item">高等级告警：<c:out value="${execOverview.alarmHighCount}"/> 条</div>
            <div class="dashboard-meta-item">科研项目：<c:out value="${execOverview.pendingProjectCount}"/> 项待跟进</div>
            <div class="dashboard-meta-item">实时刷新：<c:out value="${execRealtime.statTime}"/></div>
          </div>
        </div>

        <c:if test="${not empty execFlashMessage}">
          <div class="dashboard-alert <c:out value='${execFlashType}'/>">
            <span><c:out value="${execFlashMessage}"/></span>
          </div>
        </c:if>

        <div class="dashboard-grid">
          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">月度综合能耗</div>
            <div class="dashboard-stat-value">
              <fmt:formatNumber value="${execOverview.monthlyConsumption}" pattern="#,##0.##"/> kWh
            </div>
            <div class="dashboard-stat-trend <c:out value='${execOverview.monthlyChangeRate != null && execOverview.monthlyChangeRate < 0 ? "down" : "up"}'/>">
              <c:choose>
                <c:when test="${execOverview.monthlyChangeRate != null}">
                  <c:out value="${execOverview.monthlyChangeRate < 0 ? '▼' : '▲'}"/>
                  <fmt:formatNumber value="${execOverview.monthlyChangeRate}" type="percent" maxFractionDigits="1"/> 环比
                </c:when>
                <c:otherwise>暂无同比数据</c:otherwise>
              </c:choose>
            </div>
            <div class="dashboard-stat-subtext">降本目标达成
              <fmt:formatNumber value="${execOverview.targetCompletion}" type="percent" maxFractionDigits="0"/>
            </div>
          </div>
          <div class="dashboard-stat-card pv">
            <div class="dashboard-stat-label">光伏收益</div>
            <div class="dashboard-stat-value">¥ <fmt:formatNumber value="${execOverview.pvTotalRevenue}" pattern="#,##0.##"/></div>
            <div class="dashboard-stat-trend up">本月发电：<fmt:formatNumber value="${execOverview.pvGenKwh}" pattern="#,##0.##"/> kWh</div>
            <div class="dashboard-stat-subtext">自用电节省：¥ <fmt:formatNumber value="${execOverview.pvSelfSaving}" pattern="#,##0.##"/></div>
          </div>
          <div class="dashboard-stat-card alarm">
            <div class="dashboard-stat-label">高等级告警</div>
            <div class="dashboard-stat-value"><c:out value="${execOverview.alarmHighCount}"/></div>
            <div class="dashboard-stat-trend up">▲ 近 7 天新增 <c:out value="${execOverview.alarmRecentHighCount}"/> 条</div>
            <div class="dashboard-stat-subtext">需管理层决策</div>
          </div>

          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">实时汇总（最新）</div>
            <div class="dashboard-stat-value">
              <fmt:formatNumber value="${execRealtime.totalKwh}" pattern="#,##0.##"/> kWh
            </div>
            <div class="dashboard-stat-trend up">
              水 <fmt:formatNumber value="${execRealtime.totalWaterM3}" pattern="#,##0.##"/> m³ ·
              蒸汽 <fmt:formatNumber value="${execRealtime.totalSteamT}" pattern="#,##0.##"/> t ·
              天然气 <fmt:formatNumber value="${execRealtime.totalGasM3}" pattern="#,##0.##"/> m³
            </div>
            <div class="dashboard-stat-subtext">
              24h 告警 <c:out value="${execRealtime.totalAlarm}"/>（高 <c:out value="${execRealtime.alarmHigh}"/> / 中 <c:out value="${execRealtime.alarmMid}"/> / 低 <c:out value="${execRealtime.alarmLow}"/>）
            </div>
          </div>
        </div>

        <div class="content-grid">
          <div class="dashboard-main-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">能耗总结与降本评估</div>
                  <div class="dashboard-section-hint">查看月度/季度能耗总结与降本增效目标进度。</div>
                </div>
                <div class="dashboard-chart-actions">
                  <button class="dashboard-chart-action-btn">月度</button>
                  <button class="dashboard-chart-action-btn">季度</button>
                </div>
              </div>
              <div class="table-container">
                <table class="data-table">
                  <thead>
                  <tr>
                    <th>周期</th>
                    <th>总能耗</th>
                    <th>能耗成本</th>
                    <th>环比变化</th>
                    <th>降本评估</th>
                  </tr>
                  </thead>
                  <tbody>
                  <c:forEach items="${execMonthlySummaries}" var="item">
                    <tr>
                      <td><c:out value="${item.periodLabel}"/></td>
                      <td><fmt:formatNumber value="${item.totalConsumption}" pattern="#,##0.##"/></td>
                      <td>¥ <fmt:formatNumber value="${item.totalCost}" pattern="#,##0.##"/></td>
                      <td>
                        <c:choose>
                          <c:when test="${item.changeRate != null}">
                            <fmt:formatNumber value="${item.changeRate}" type="percent" maxFractionDigits="1"/>
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </td>
                      <td><span class="trend-tag <c:out value='${item.changeRate != null && item.changeRate < 0 ? "up" : "down"}'/>"><c:out value="${item.trendTag}"/></span></td>
                    </tr>
                  </c:forEach>
                  </tbody>
                </table>
              </div>
              <div class="dashboard-section-divider"></div>
              <div class="table-container">
                <table class="data-table">
                  <thead>
                  <tr>
                    <th>季度</th>
                    <th>总能耗</th>
                    <th>能耗成本</th>
                    <th>环比变化</th>
                    <th>目标完成</th>
                  </tr>
                  </thead>
                  <tbody>
                  <c:forEach items="${execQuarterlySummaries}" var="item">
                    <tr>
                      <td><c:out value="${item.periodLabel}"/></td>
                      <td><fmt:formatNumber value="${item.totalConsumption}" pattern="#,##0.##"/></td>
                      <td>¥ <fmt:formatNumber value="${item.totalCost}" pattern="#,##0.##"/></td>
                      <td>
                        <c:choose>
                          <c:when test="${item.changeRate != null}">
                            <fmt:formatNumber value="${item.changeRate}" type="percent" maxFractionDigits="1"/>
                          </c:when>
                          <c:otherwise>--</c:otherwise>
                        </c:choose>
                      </td>
                      <td><span class="trend-tag <c:out value='${item.goalStatus == "达标" ? "up" : "down"}'/>"><c:out value="${item.goalStatus}"/></span></td>
                    </tr>
                  </c:forEach>
                  </tbody>
                </table>
              </div>
              <div class="dashboard-callout">
                本月综合能耗费用
                ¥ <fmt:formatNumber value="${execOverview.monthlyCost}" pattern="#,##0.##"/>，
                结合光伏自用电节省
                ¥ <fmt:formatNumber value="${execOverview.pvSelfSaving}" pattern="#,##0.##"/>，
                可优先推进高耗能设备改造。
              </div>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">历史趋势分析</div>
                  <div class="dashboard-section-hint">支持多周期查询；同比/环比为负标记为“能耗下降”，为正标记为“能耗上升”。</div>
                </div>
              </div>

              <form class="dashboard-inline-form" method="get" action="${ctx}/app">
                <input type="hidden" name="module" value="dashboard"/>
                <label>能源类型
                  <select name="trendEnergyType">
                    <option value="电" <c:out value='${execTrendEnergyType=="电" ? "selected" : ""}'/>>电</option>
                    <option value="水" <c:out value='${execTrendEnergyType=="水" ? "selected" : ""}'/>>水</option>
                    <option value="蒸汽" <c:out value='${execTrendEnergyType=="蒸汽" ? "selected" : ""}'/>>蒸汽</option>
                    <option value="天然气" <c:out value='${execTrendEnergyType=="天然气" ? "selected" : ""}'/>>天然气</option>
                  </select>
                </label>
                <label>统计周期
                  <select name="trendCycle">
                    <option value="日" <c:out value='${execTrendCycle=="日" ? "selected" : ""}'/>>日</option>
                    <option value="周" <c:out value='${execTrendCycle=="周" ? "selected" : ""}'/>>周</option>
                    <option value="月" <c:out value='${execTrendCycle=="月" ? "selected" : ""}'/>>月</option>
                    <option value="季度" <c:out value='${execTrendCycle=="季度" ? "selected" : ""}'/>>季度</option>
                  </select>
                </label>
                <button type="submit" class="dashboard-btn">查询</button>
              </form>

              <c:choose>
                <c:when test="${empty execTrends}">
                  <div class="dashboard-empty">暂无历史趋势数据（请确认已执行业务线5补丁 SQL 并插入 Stat_History_Trend 测试数据）。</div>
                </c:when>
                <c:otherwise>
                  <div class="table-container">
                    <table class="data-table">
                      <thead>
                      <tr>
                        <th>日期</th>
                        <th>能耗/发电</th>
                        <th>同比</th>
                        <th>环比</th>
                        <th>标记</th>
                      </tr>
                      </thead>
                      <tbody>
                      <c:forEach items="${execTrends}" var="t">
                        <tr>
                          <td><c:out value="${t.statDate}"/></td>
                          <td><fmt:formatNumber value="${t.value}" pattern="#,##0.##"/></td>
                          <td><c:out value="${t.yoyRate}"/>%</td>
                          <td><c:out value="${t.momRate}"/>%</td>
                          <td><span class="trend-tag <c:out value='${t.trendTag=="能耗下降" ? "up" : "down"}'/>"><c:out value="${t.trendTag}"/></span></td>
                        </tr>
                      </c:forEach>
                      </tbody>
                    </table>
                  </div>
                </c:otherwise>
              </c:choose>

              <div class="dashboard-section-divider"></div>
              <div class="dashboard-chart-header" style="margin-top:0;">
                <div>
                  <div class="dashboard-chart-title">能耗溯源 · Top 厂区（本月·电）</div>
                  <div class="dashboard-section-hint">当发现总能耗异常上升，可快速定位高耗能厂区。</div>
                </div>
              </div>
              <c:choose>
                <c:when test="${empty execTopFactories}">
                  <div class="dashboard-empty">暂无厂区能耗统计数据。</div>
                </c:when>
                <c:otherwise>
                  <div class="table-container">
                    <table class="data-table">
                      <thead>
                      <tr>
                        <th>厂区</th>
                        <th>能耗</th>
                        <th>成本</th>
                      </tr>
                      </thead>
                      <tbody>
                      <c:forEach items="${execTopFactories}" var="f">
                        <tr>
                          <td><c:out value="${f.factoryName}"/></td>
                          <td><fmt:formatNumber value="${f.totalConsumption}" pattern="#,##0.##"/></td>
                          <td>¥ <fmt:formatNumber value="${f.totalCost}" pattern="#,##0.##"/></td>
                        </tr>
                      </c:forEach>
                      </tbody>
                    </table>
                  </div>
                </c:otherwise>
              </c:choose>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">重大事项决策</div>
                  <div class="dashboard-section-hint">高等级告警与重点节能改造项目需管理层审批。</div>
                </div>
              </div>
              <div class="workbench-grid">
                <c:forEach items="${execDecisionItems}" var="item">
                  <div class="workbench-card">
                    <div class="workbench-card-title"><c:out value="${item.title}"/></div>
                    <div class="workbench-card-desc">
                      <c:out value="${item.description}"/>
                      <c:if test="${not empty item.alarmContent}">
                        <span class="dashboard-inline-note">关联告警：<c:out value="${item.alarmContent}"/></span>
                      </c:if>
                    </div>
                    <div class="workbench-card-meta">
                      <span class="workbench-tag info"><c:out value="${item.decisionType}"/></span>
                      <span class="workbench-tag <c:out value='${item.status == "待决策" ? "warning" : "success"}'/>"><c:out value="${item.status}"/></span>
                      <span class="workbench-tag info">预算 ¥ <fmt:formatNumber value="${item.estimateCost}" pattern="#,##0.##"/></span>
                    </div>
                    <form class="dashboard-inline-form" method="post" action="${ctx}/app?module=dashboard&action=decisionUpdate">
                      <input type="hidden" name="decisionId" value="${item.decisionId}"/>
                      <select name="status">
                        <option value="待决策">待决策</option>
                        <option value="已批准">已批准</option>
                        <option value="暂缓">暂缓</option>
                      </select>
                      <button type="submit" class="dashboard-btn">更新决策</button>
                    </form>
                  </div>
                </c:forEach>
              </div>
            </section>
          </div>

          <div class="dashboard-side-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">高等级告警推送</div>
              </div>
              <c:choose>
                <c:when test="${empty execHighAlarms}">
                  <div class="dashboard-empty">暂无高等级告警推送</div>
                </c:when>
                <c:otherwise>
                  <div class="workbench-list compact">
                    <c:forEach items="${execHighAlarms}" var="alarm">
                      <div class="workbench-list-item">
                        <div>
                          <div class="workbench-item-title"><c:out value="${alarm.content}"/></div>
                          <div class="workbench-item-desc">
                            <c:out value="${alarm.occurTime}"/> · <c:out value="${alarm.factoryName}"/>
                          </div>
                        </div>
                        <span class="workbench-tag danger">高等级</span>
                      </div>
                    </c:forEach>
                  </div>
                </c:otherwise>
              </c:choose>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">科研项目管理</div>
              </div>
              <div class="dashboard-form">
                <div class="dashboard-form-title">科研项目申请</div>
                <form method="post" action="${ctx}/app?module=dashboard&action=projectApply">
                  <div class="dashboard-form-row">
                    <label>项目名称</label>
                    <input type="text" name="projectTitle" placeholder="请输入项目名称"/>
                  </div>
                  <div class="dashboard-form-row">
                    <label>申报摘要</label>
                    <textarea name="projectSummary" rows="3" placeholder="简述研究目标与预期成果"></textarea>
                  </div>
                  <div class="dashboard-form-actions">
                    <button type="submit" class="dashboard-btn primary">提交申请</button>
                  </div>
                </form>
              </div>

              <div class="dashboard-form">
                <div class="dashboard-form-title">结题报告提交</div>
                <form method="post" action="${ctx}/app?module=dashboard&action=projectClose">
                  <div class="dashboard-form-row">
                    <label>选择项目</label>
                    <select name="projectId">
                      <c:choose>
                        <c:when test="${not empty execOpenProjects}">
                          <c:forEach items="${execOpenProjects}" var="project">
                            <option value="${project.projectId}"><c:out value="${project.projectTitle}"/></option>
                          </c:forEach>
                        </c:when>
                        <c:otherwise>
                          <option value="">暂无可结题项目</option>
                        </c:otherwise>
                      </c:choose>
                    </select>
                  </div>
                  <div class="dashboard-form-row">
                    <label>结题摘要</label>
                    <textarea name="closeReport" rows="3" placeholder="说明关键成果与验收情况"></textarea>
                  </div>
                  <div class="dashboard-form-actions">
                    <button type="submit" class="dashboard-btn">提交结题</button>
                  </div>
                </form>
              </div>

              <div class="workbench-list compact">
                <c:forEach items="${execProjects}" var="project">
                  <div class="workbench-list-item">
                    <div>
                      <div class="workbench-item-title"><c:out value="${project.projectTitle}"/></div>
                      <div class="workbench-item-desc">
                        负责人：<c:out value="${project.applicant}"/> · 申报：<c:out value="${project.applyDate}"/>
                      </div>
                    </div>
                    <span class="workbench-tag info"><c:out value="${project.projectStatus}"/></span>
                  </div>
                </c:forEach>
              </div>
            </section>
          </div>
        </div>
      </div>
    </c:when>

    <c:when test="${roleType == 'DISPATCHER'}">
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>运维工单管理员工作台</h1>
          <p>负责告警真实性审核、工单派发与处理结果复查。</p>
          <div class="dashboard-meta">
            <div class="dashboard-meta-item">待审核告警：6 条</div>
            <div class="dashboard-meta-item">在途工单：14 条</div>
            <div class="dashboard-meta-item">超时提醒：2 条</div>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="dashboard-stat-card alarm">
            <div class="dashboard-stat-label">待审核告警</div>
            <div class="dashboard-stat-value">6</div>
            <div class="dashboard-stat-trend up">▲ 2 条新增</div>
            <div class="dashboard-stat-subtext">需排除误报</div>
          </div>
          <div class="dashboard-stat-card energy">
            <div class="dashboard-stat-label">工单派发中</div>
            <div class="dashboard-stat-value">8</div>
            <div class="dashboard-stat-trend down">▼ 3 条已关闭</div>
            <div class="dashboard-stat-subtext">超时风险：2 条</div>
          </div>
          <div class="dashboard-stat-card efficiency">
            <div class="dashboard-stat-label">复查待确认</div>
            <div class="dashboard-stat-value">4</div>
            <div class="dashboard-stat-trend up">▲ 1 条新增</div>
            <div class="dashboard-stat-subtext">需复派：1 条</div>
          </div>
        </div>

        <div class="content-grid">
          <div class="dashboard-main-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">告警真实性审核</div>
                  <div class="dashboard-section-hint">排除通讯波动等误报，确认有效告警再派单。</div>
                </div>
              </div>
              <div class="workbench-list">
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">设备离线告警 - PV-INV-07</div>
                    <div class="workbench-item-desc">疑似通讯波动，需核实</div>
                  </div>
                  <span class="workbench-tag warning">待核实</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">变压器 T-01 温度过高</div>
                    <div class="workbench-item-desc">已确认有效告警</div>
                  </div>
                  <span class="workbench-tag danger">已确认</span>
                </div>
              </div>
            </section>

            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div>
                  <div class="dashboard-chart-title">工单派发与进度跟踪</div>
                  <div class="dashboard-section-hint">超时未响应需提醒运维人员。</div>
                </div>
              </div>
              <div class="workbench-grid">
                <div class="workbench-card">
                  <div class="workbench-card-title">OM-20250318-01</div>
                  <div class="workbench-card-desc">35KV 配电房故障 - 运维人员：李工</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag danger">超时 20 分钟</span>
                    <span class="workbench-tag info">待响应</span>
                  </div>
                </div>
                <div class="workbench-card">
                  <div class="workbench-card-title">OM-20250318-03</div>
                  <div class="workbench-card-desc">A1 车间水压波动 - 运维人员：王工</div>
                  <div class="workbench-card-meta">
                    <span class="workbench-tag warning">处理中</span>
                    <span class="workbench-tag info">预计 18:00 完成</span>
                  </div>
                </div>
              </div>
            </section>
          </div>

          <div class="dashboard-side-content">
            <section class="dashboard-chart-section">
              <div class="dashboard-chart-header">
                <div class="dashboard-chart-title">处理结果复查</div>
              </div>
              <div class="workbench-list compact">
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">变压器 T-01 故障</div>
                    <div class="workbench-item-desc">处理后温度仍偏高</div>
                  </div>
                  <span class="workbench-tag danger">需复派</span>
                </div>
                <div class="workbench-list-item">
                  <div>
                    <div class="workbench-item-title">光伏逆变器离线</div>
                    <div class="workbench-item-desc">恢复正常，待归档</div>
                  </div>
                  <span class="workbench-tag success">通过</span>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </c:when>

    <c:otherwise>
      <div class="dashboard-container">
        <div class="dashboard-header">
          <h1>默认工作台</h1>
          <p>当前账号尚未分配角色，请联系系统管理员完成权限配置。</p>
        </div>
      </div>
    </c:otherwise>
  </c:choose>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
