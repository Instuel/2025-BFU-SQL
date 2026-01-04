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

        <!-- 账号与权限维护 -->
        <a href="${ctx}/admin?action=list" class="admin-module-link">
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
        </a>

        <!-- 告警规则配置 -->
        <a href="${ctx}/admin?action=alarm_rule" class="admin-module-link">
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
        </a>

        <!-- 峰谷与参数配置 -->
        <a href="${ctx}/admin?action=peak_valley" class="admin-module-link">
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
        </a>

        <!-- 数据备份与恢复 -->
        <a href="${ctx}/admin?action=backup_restore" class="admin-module-link">
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
        </a>

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
            <a class="admin-action-btn primary" href="${ctx}/admin?action=role_assign">📌 新建角色模板</a>
            <a class="admin-action-btn success" href="${ctx}/admin?action=alarm_rule">✅ 发布规则更新</a>
            <a class="admin-action-btn warning" href="${ctx}/admin?action=backup_restore">⚙️ 发起备份</a>
            <a class="admin-action-btn danger" href="${ctx}/admin?action=backup_restore">🧯 恢复演练</a>
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
      <!-- 这里开始是你原来的 OM 工作台，我保持不变 -->
      ...（此处略，和你原文件一致）...
    </c:when>

    <c:when test="${roleType == 'ANALYST'}">
      ...（保持不变）...
    </c:when>

    <c:when test="${roleType == 'EXEC'}">
      ...（保持不变）...
    </c:when>

    <c:when test="${roleType == 'DISPATCHER'}">
      ...（保持不变）...
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
