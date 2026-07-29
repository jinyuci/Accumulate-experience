# 英国在线零售分析 (UK Online Retail Analysis)

基于 UCI Online Retail 数据集的批发零售分析项目，覆盖数据清洗、RFM 客户分层、产品销售分析。

---

## 📊 数据概览

| 指标 | 数值 |
|------|------|
| 数据来源 | UCI Machine Learning Repository |
| 原始数据量 | 541,909 行 |
| 清洗后数据量 | 397,884 行 (73.4%) |
| 时间范围 | 2010-12-01 ~ 2011-12-09 (1年) |
| 数据清洗 | CustomerID缺失 24.9% / 退货 2.0% / 异常单价 0.5% |

---

## 🔍 分析框架

### 1. 数据清洗
- CustomerID 缺失：135,080 行（匿名交易/批发客户）
- 退货/取消：10,624 行（Quantity < 0 覆盖更全）
- 异常单价：2,517 行（UnitPrice ≤ 0，免费样品或数据错误）

### 2. 整体销售
- **总销售额**：£8,911,408
- **有效订单**：18,532 单
- **有效客户**：4,338 人
- **客单价**：£481
- **人均消费**：£2,054
- **单均商品数**：278.9 件（批发特征明显）

### 3. 客户分析 (RFM)
- R：距最后一天(2011-12-09)的天数
- F：独立订单数
- M：消费总额（含金额维度，比淘宝项目更完整）
- RFM 8 类分层

### 4. 产品分析
- 热销商品 Top 10（按销量）
- 营收商品 Top 10（按销售额）
- 退货率排名（按退货件数/售出件数）
- 商品单价分布

### 5. 时间分析
- **周六零交易** —— 英国周末无物流，网站关闭下单
- 周日交易量最低
- 工作日为交易主力

---

## 🛠️ 技术栈

- **数据库**：MySQL (阿里云 RDS)
- **可视化**：Tableau Desktop / Excel
- **数据源**：UCI Online Retail Dataset

---

## 📁 项目结构

```
uk-online-retail/
├── README.md
├── sql/
│   └── analysis_queries.sql    # 数据分析 SQL 脚本
├── data/
│   └── OnlineRetail_england.csv
└── images/
    └── dashboard.png
```

---

## 🚀 如何复现

1. 下载 UCI Online Retail 数据集
2. 导入 MySQL：见仓库根目录的 `import_retail.py`
3. 运行 `sql/analysis_queries.sql` 中的查询
4. 分析结果导入 Tableau 或 Excel 可视化
