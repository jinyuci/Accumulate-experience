# 淘宝用户行为分析 (Taobao User Behavior Analysis)

基于阿里云天池公开数据集的电商用户行为分析项目，覆盖数据清洗、AARRR 模型分析、RFM 用户分层和 Tableau 可视化仪表板。

---

## 📊 数据概览

| 指标 | 数值 |
|------|------|
| 数据来源 | 阿里云天池 UserBehavior.csv |
| 原始数据量 | 112,900,807 行 |
| 清洗后数据量 | 112,838,214 行 |
| 时间范围 | 2017-11-25 ~ 2017-12-03 (9天) |
| 字段 | 用户ID / 商品ID / 品类ID / 行为类型 / 时间戳 |

---

## 🔍 分析框架 (AARRR)

### 1. 用户获取 (Acquisition)
- **每日 PV/UV 趋势**：日均 PV 1,080 万，日均 UV 73 万
- **分时段活跃度**：高峰 18:00-23:00，峰值 20:00
- **人均浏览深度**：PV/UV ≈ 15

### 2. 用户激活 (Activation)
- **行为分布**：
  - 浏览(pv)：89.6%
  - 加购(cart)：5.5%
  - 收藏(fav)：2.9%
  - 购买(buy)：2.0%

### 3. 用户留存 (Retention)
- **次日留存率**：78% ~ 98%
- **三日留存率**：76% ~ 99%
- "双十二"预热期间留存率持续走高

### 4. 用户变现 (Revenue)
- **浏览→加购转化率**：5.26%（同人同商品口径）
- **浏览→购买转化率**：1.84%
- **复购率**：16.26%（购买 ≥ 2 次的用户占比）

### 5. 用户传播 (Referral)
- **RFM 分层**：
  - 重要价值用户：34.26%
  - 重要发展用户：33.26%
  - 重要保持用户：24.14%
  - 重要挽留用户：8.34%

---

## 📈 商品分析

- **热门商品 Top 10**（按浏览量）
- **热销商品 Top 10**（按购买量），部分商品转化率高达 78%
- **高转化品类** Top 10，最高品类转化率 99.7%
- **四象限分析**：明星品类 5.27%，流量浪费 1.23%，长尾 84.82%

---

## 📊 Tableau 仪表板

共 7 张工作表 + 1 个 Dashboard：

| 图表 | 类型 | 数据源 |
|------|------|--------|
| 日浏览量趋势 | 双轴折线图 | daily_pv_uv |
| 按小时浏览量 | 柱状图 | hourly_traffic |
| 用户行为漏斗 | 条形图 | funnel |
| 次日留存率 | 折线图 | retention |
| 购买频次分布 | 条形图 | buy_frequency |
| 品类四象限 | 散点图 | category_quadrant |
| RFM 分层 | 环形图 | rfm_segments |

---

## 📁 项目结构

```
taobao-user-behavior/
├── README.md
├── sql/
│   └── analysis_queries.sql    # 13 条核心分析 SQL
├── data/
│   ├── 1.csv ~ 13.csv          # 各任务查询结果
│   └── 品类象限数据.csv
├── tableau/
│   ├── user_beha.twb            # Tableau 工作簿
│   └── user_beha.twbx           # Tableau 打包工作簿
└── images/
    └── dashboard.png            # 仪表板截图（请添加）
```

---

## 🛠️ 技术栈

- **数据库**：MySQL (阿里云 RDS)
- **可视化**：Tableau Desktop
- **数据源**：阿里云天池公开数据集

---

## 🚀 如何复现

1. 下载阿里云天池 UserBehavior.csv
2. 导入 MySQL：见仓库根目录的 `import_taobao.py`
3. 运行 `sql/analysis_queries.sql` 中的查询
4. 将结果 CSV 导入 Tableau
5. 打开 `tableau/user_beha.twb` 查看仪表板
