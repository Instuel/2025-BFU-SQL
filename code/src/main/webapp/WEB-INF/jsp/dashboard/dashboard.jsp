<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/common/header.jsp" %>
<%@ include file="/WEB-INF/jsp/common/sidebar.jsp" %>

<div class="main-content dashboard-page">
  <div class="dashboard-container">
    <div class="dashboard-header">
      <h1>大屏总览</h1>
      <p>聚合能源与光伏关键指标，按分钟级刷新实时汇总数据，支持多周期趋势分析。</p>
      <div class="dashboard-meta">
        <div class="dashboard-meta-item">最新汇总时间：2025-03-18 14:30</div>
        <div class="dashboard-meta-item">数据刷新频率：60 秒</div>
        <div class="dashboard-meta-item">展示模块：能源总览 / 光伏总览 / 配电网运行状态 / 告警统计</div>
      </div>
    </div>

    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">大屏展示配置</div>
          <div class="dashboard-section-hint">配置项支持展示字段自定义、排序规则与权限等级控制。</div>
        </div>
        <div class="dashboard-chart-actions">
          <span class="dashboard-badge">权限等级：管理员</span>
          <span class="dashboard-badge">排序规则：按时间降序</span>
        </div>
      </div>
      <div class="table-container">
        <table class="data-table">
          <thead>
          <tr>
            <th>配置编号</th>
            <th>展示模块</th>
            <th>刷新频率</th>
            <th>展示字段</th>
            <th>排序规则</th>
            <th>权限等级</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>CFG-0001</td>
            <td>能源总览</td>
            <td>60 秒</td>
            <td>总用电量 / 总用水量 / 总蒸汽量 / 总天然气量</td>
            <td>按时间降序</td>
            <td>管理员</td>
          </tr>
          <tr>
            <td>CFG-0002</td>
            <td>光伏总览</td>
            <td>120 秒</td>
            <td>光伏总发电量 / 自用电量 / 上网电量</td>
            <td>按能耗降序</td>
            <td>能源管理员</td>
          </tr>
          <tr>
            <td>CFG-0003</td>
            <td>配电网运行状态</td>
            <td>60 秒</td>
            <td>负荷率 / 线损率 / 设备在线率</td>
            <td>按时间降序</td>
            <td>运维人员</td>
          </tr>
          <tr>
            <td>CFG-0004</td>
            <td>告警统计</td>
            <td>30 秒</td>
            <td>总告警次数 / 高中低等级告警数</td>
            <td>按告警数量降序</td>
            <td>管理员</td>
          </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="dashboard-chart-section">
      <div class="dashboard-chart-header">
        <div>
          <div class="dashboard-chart-title">实时汇总数据</div>
          <div class="dashboard-section-hint">分钟级汇总能耗与告警数据，异常上升时可触发能耗溯源。</div>
        </div>
        <div class="dashboard-chart-actions">
          <button class="dashboard-chart-action-btn">分钟</button>
          <button class="dashboard-chart-action-btn">小时</button>
          <button class="dashboard-chart-action-btn">当日</button>
        </div>
      </div>
      <div class="dashboard-grid">
        <div class="dashboard-stat-card energy">
          <div class="dashboard-stat-label">总用电量</div>
          <div class="dashboard-stat-value">12,380 kWh</div>
          <div class="dashboard-stat-trend up">▲ 5.2% 同比</div>
          <div class="dashboard-stat-subtext">峰值时段：13:00-14:00</div>
        </div>
        <div class="dashboard-stat-card water">
          <div class="dashboard-stat-label">总用水量</div>
          <div class="dashboard-stat-value">2,460 m³</div>
          <div class="dashboard-stat-trend down">▼ 1.8% 环比</div>
          <div class="dashboard-stat-subtext">重点厂区：A1 车间</div>
        </div>
        <div class="dashboard-stat-card steam">
          <div class="dashboard-stat-label">总蒸汽消耗量</div>
          <div class="dashboard-stat-value">860 t</div>
          <div class="dashboard-stat-trend up">▲ 3.6% 同比</div>
          <div class="dashboard-stat-subtext">蒸汽效率：92.4%</div>
        </div>
        <div class="dashboard-stat-card gas">
          <div class="dashboard-stat-label">总天然气消耗量</div>
          <div class="dashboard-stat-value">1,120 m³</div>
          <div class="dashboard-stat-trend down">▼ 0.9% 同比</div>
          <div class="dashboard-stat-subtext">节能措施：负荷优化</div>
        </div>
        <div class="dashboard-stat-card pv">
          <div class="dashboard-stat-label">光伏总发电量</div>
          <div class="dashboard-stat-value">4,560 kWh</div>
          <div class="dashboard-stat-trend up">▲ 6.1% 环比</div>
          <div class="dashboard-stat-subtext">自用电量：3,890 kWh</div>
        </div>
        <div class="dashboard-stat-card alarm">
          <div class="dashboard-stat-label">告警统计</div>
          <div class="dashboard-stat-value">34 次</div>
          <div class="dashboard-stat-trend down">▼ 12% 本周</div>
          <div class="dashboard-stat-subtext">高等级：4 / 中等级：12 / 低等级：18</div>
        </div>
      </div>
      <div class="dashboard-callout">
        实时汇总数据按分钟级更新，若同比/环比指标出现持续异常，请及时触发“能耗溯源”操作，定位高耗能区域与设备。
      </div>
    </section>

    <div class="content-grid">
      <div class="dashboard-main-content">
        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div>
              <div class="dashboard-chart-title">历史趋势分析</div>
              <div class="dashboard-section-hint">支持电/水/蒸汽/天然气/光伏多能源类型的日/周/月对比。</div>
            </div>
            <div class="dashboard-chart-actions">
              <button class="dashboard-chart-action-btn">日</button>
              <button class="dashboard-chart-action-btn">周</button>
              <button class="dashboard-chart-action-btn">月</button>
            </div>
          </div>
          <div class="dashboard-chart-container">趋势图区域（同比/环比/行业均值）</div>
          <div class="table-container">
            <table class="data-table">
              <thead>
              <tr>
                <th>能源类型</th>
                <th>统计周期</th>
                <th>统计时间</th>
                <th>能耗/发电量</th>
                <th>同比增长率</th>
                <th>环比增长率</th>
                <th>行业均值</th>
                <th>趋势标记</th>
              </tr>
              </thead>
              <tbody>
              <tr>
                <td>电</td>
                <td>日</td>
                <td>2025-03-17</td>
                <td>12,380 kWh</td>
                <td>5.2%</td>
                <td>-1.4%</td>
                <td>11,900 kWh</td>
                <td><span class="trend-tag up">能耗上升</span></td>
              </tr>
              <tr>
                <td>水</td>
                <td>周</td>
                <td>2025-W11</td>
                <td>2,460 m³</td>
                <td>-2.1%</td>
                <td>-0.8%</td>
                <td>2,580 m³</td>
                <td><span class="trend-tag down">能耗下降</span></td>
              </tr>
              <tr>
                <td>蒸汽</td>
                <td>月</td>
                <td>2025-02</td>
                <td>23,400 t</td>
                <td>3.0%</td>
                <td>1.2%</td>
                <td>22,800 t</td>
                <td><span class="trend-tag up">能耗上升</span></td>
              </tr>
              <tr>
                <td>天然气</td>
                <td>月</td>
                <td>2025-02</td>
                <td>30,880 m³</td>
                <td>-1.6%</td>
                <td>-2.4%</td>
                <td>31,500 m³</td>
                <td><span class="trend-tag down">能耗下降</span></td>
              </tr>
              <tr>
                <td>光伏</td>
                <td>周</td>
                <td>2025-W11</td>
                <td>4,560 kWh</td>
                <td>6.1%</td>
                <td>2.8%</td>
                <td>4,200 kWh</td>
                <td><span class="trend-tag up">发电提升</span></td>
              </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div>
              <div class="dashboard-chart-title">决策动作与能耗溯源</div>
              <div class="dashboard-section-hint">当总能耗异常上升时，建议快速查看厂区/设备能耗占比。</div>
            </div>
          </div>
          <div class="dashboard-actions">
            <div class="dashboard-action-card">
              <div class="dashboard-action-title">能耗溯源分析</div>
              <div class="dashboard-action-desc">查看各厂区、设备能耗占比，识别高耗能单元与异常曲线。</div>
            </div>
            <div class="dashboard-action-card">
              <div class="dashboard-action-title">历史趋势报告</div>
              <div class="dashboard-action-desc">每月生成同比/环比趋势报告，用于评估节能措施效果。</div>
            </div>
          </div>
        </section>
      </div>

      <div class="dashboard-side-content">
        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div class="dashboard-chart-title">告警统计</div>
          </div>
          <div class="alarm-list">
            <div class="alarm-item">
              <div class="alarm-level high">高等级告警</div>
              <div class="alarm-time">2025-03-18 13:40</div>
              <div class="alarm-content">35KV 配电房温度过高，需立即巡检。</div>
              <div class="alarm-device">设备：主变压器 T-01</div>
            </div>
            <div class="alarm-item">
              <div class="alarm-level medium">中等级告警</div>
              <div class="alarm-time">2025-03-18 12:55</div>
              <div class="alarm-content">光伏逆变器离线 2 分钟，已自动重连。</div>
              <div class="alarm-device">设备：PV-INV-07</div>
            </div>
            <div class="alarm-item">
              <div class="alarm-level low">低等级告警</div>
              <div class="alarm-time">2025-03-18 12:30</div>
              <div class="alarm-content">A2 车间水压波动，持续观察。</div>
              <div class="alarm-device">设备：水压监测点 W-03</div>
            </div>
          </div>
        </section>

        <section class="dashboard-chart-section">
          <div class="dashboard-chart-header">
            <div class="dashboard-chart-title">光伏收益概览</div>
          </div>
          <div class="dashboard-stat-card pv">
            <div class="dashboard-stat-label">月度自用电节省电费</div>
            <div class="dashboard-stat-value">¥ 128,600</div>
            <div class="dashboard-stat-trend up">▲ 8.7% 环比</div>
            <div class="dashboard-stat-subtext">上网电量收益：¥ 43,200</div>
          </div>
        </section>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp" %>
