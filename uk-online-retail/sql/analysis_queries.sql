-- ============================================================
-- 英国在线零售分析 - 核心 SQL 查询
-- 数据表: online_retail.retail
-- ============================================================

-- ============================================================
-- 一、数据清洗
-- ============================================================

-- 1. CustomerID 缺失
SELECT COUNT(*) FROM retail WHERE CustomerID IS NULL;

-- 2. 退货/取消 (InvoiceNo 以 C 开头)
SELECT COUNT(*) FROM retail WHERE InvoiceNo LIKE 'C%';

-- 3. 退货 (Quantity 为负)
SELECT COUNT(*) FROM retail WHERE Quantity < 0;

-- 4. 异常单价
SELECT COUNT(*) FROM retail WHERE UnitPrice <= 0;

-- 5. 清洗后数据概览
SELECT
    COUNT(*) clean_rows,
    ROUND(SUM(Quantity * UnitPrice), 2) total_revenue,
    COUNT(DISTINCT InvoiceNo) total_orders,
    COUNT(DISTINCT CustomerID) total_customers
FROM retail
WHERE Quantity > 0         -- 数据过滤条件
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0;

-- ============================================================
-- 二、整体销售分析
-- ============================================================

-- 6. 月度销售趋势
select date_format(InvoiceDate,'%Y-%m') y_m,
       count(distinct InvoiceNo) y_orders,
       round(sum(Quantity*UnitPrice),2) month_revenue,
       round(sum(Quantity*UnitPrice) / count(distinct InvoiceNo),2) '客单价'
from retail
WHERE Quantity > 0         -- 数据过滤条件
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0
group by y_m;

-- 7. 各国家销售占比
SELECT
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) revenue,
    ROUND(100 * SUM(Quantity * UnitPrice) / SUM(SUM(Quantity * UnitPrice)) OVER(), 2) pct
FROM retail
WHERE Quantity > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0
GROUP BY Country
ORDER BY revenue DESC;
-- ============================================================
-- 三、客户分析 (RFM)
-- ============================================================

-- 8. RFM 计算
with rfm as (select CustomerID,
                    datediff('2011-12-09', max(InvoiceDate)) r,
                    count(distinct InvoiceNo) f,
                    round(sum(Quantity * UnitPrice), 2) m
             from retail
             WHERE Quantity > 0 -- 数据过滤条件
               AND InvoiceNo NOT LIKE 'C%'
               AND CustomerID IS NOT NULL
               AND UnitPrice > 0
             group by CustomerID)
select  CustomerID,
        r,
        f,
        m
from rfm
order by r;

-- 9. RFM 8类分层
with rfm as (select CustomerID,
                    datediff('2011-12-09', max(InvoiceDate)) r,
                    count(distinct InvoiceNo) f,
                    round(sum(Quantity * UnitPrice), 2) m
             from retail
             WHERE Quantity > 0 -- 数据过滤条件
               AND InvoiceNo NOT LIKE 'C%'
               AND CustomerID IS NOT NULL
               AND UnitPrice > 0
             group by CustomerID),
avgs as (select
            avg(r) avg_r,
            avg(f) avg_f,
            avg(m) avg_m
        from rfm
),
tag as (
    select case when (r<avg_r and f>avg_f and m>avg_m) then '重要价值客户'
           when (r>avg_r and f>avg_f and m>avg_m) then '重要挽留客户'
           when (r<avg_r and f>avg_f and m<avg_m) then '重要发展客户'
           when (r>avg_r and f>avg_f and m<avg_m) then '一般发展客户'
           when (r<avg_r and f<avg_f and m>avg_m) then '重要保持客户'
           when (r>avg_r and f<avg_f and m>avg_m) then '一般保持客户'
           when (r<avg_r and f<avg_f and m<avg_m) then '一般价值用户'
           else '一般挽留用户'
    end user_type
    from rfm cross join avgs
)
select user_type,
       count(*),
       round(100*count(*)/sum(count(*)) over(),2) pct
from tag
group by user_type
order by user_type;

-- 10. 复购率
with customer_orders as(
    select CustomerID,
           count(distinct InvoiceNo) order_cnt
    from retail
    WHERE Quantity > 0 -- 数据过滤条件
               AND InvoiceNo NOT LIKE 'C%'
               AND CustomerID IS NOT NULL
               AND UnitPrice > 0
    group by CustomerID
)
select
sum(case when order_cnt >= 2 then 1 else 0 end) re_cus,
count(*) total_cus,
round(100*sum(case when order_cnt >= 2 then 1 else 0 end) / count(*),2) re_rate
from customer_orders;

-- 11. Top 10 客户（按消费总额）
select CustomerID,
       count(distinct InvoiceNo) orders,
       round(sum(Quantity*UnitPrice),2) total_spent
from retail
WHERE Quantity > 0 -- 数据过滤条件
               AND InvoiceNo NOT LIKE 'C%'
               AND CustomerID IS NOT NULL
               AND UnitPrice > 0
    group by CustomerID
    order by total_spent desc
limit 10;

-- ============================================================
-- 四、产品分析
-- ============================================================

-- 12. 热销商品 Top 10（按销量）
SELECT StockCode,
       SUM(Quantity) AS total_sold,
       COUNT(DISTINCT InvoiceNo) AS order_count
FROM retail
WHERE Quantity > 0 AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL AND UnitPrice > 0
GROUP BY StockCode ORDER BY total_sold DESC LIMIT 10;

-- 13. 营收商品 Top 10（按销售额）
select StockCode,
       sum(Quantity) total_sold,
       count(distinct InvoiceNo) d_num
from retail
WHERE Quantity > 0 -- 数据过滤条件
               AND InvoiceNo NOT LIKE 'C%'
               AND CustomerID IS NOT NULL
               AND UnitPrice > 0
    group by StockCode
order by d_num desc;

-- 14. 退货率排名
WITH stats AS (
    SELECT StockCode,
           SUM(CASE WHEN Quantity < 0 THEN ABS(Quantity) ELSE 0 END) AS return_qty,
           SUM(CASE WHEN Quantity > 0 THEN Quantity ELSE 0 END) AS sold_qty
    FROM retail
    WHERE CustomerID IS NOT NULL AND UnitPrice > 0
    GROUP BY StockCode
)
SELECT StockCode, sold_qty, return_qty,
       ROUND(100 * return_qty / NULLIF(sold_qty, 0), 2) AS return_rate
FROM stats WHERE sold_qty > 0
ORDER BY return_rate DESC LIMIT 10;

-- 15. 商品单价分布
SELECT
    CASE
        WHEN UnitPrice <= 1 THEN '0-1 £'
        WHEN UnitPrice <= 5 THEN '1-5 £'
        WHEN UnitPrice <= 10 THEN '5-10 £'
        WHEN UnitPrice <= 50 THEN '10-50 £'
        WHEN UnitPrice <= 100 THEN '50-100 £'
        WHEN UnitPrice <= 500 THEN '100-500 £'
        ELSE '500 £ 以上'
    END AS price_range,
    COUNT(DISTINCT StockCode) product_count,
    ROUND(100 * COUNT(DISTINCT StockCode) / SUM(COUNT(DISTINCT StockCode)) OVER(), 2) ct
FROM retail
WHERE Quantity > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0
GROUP BY price_range
ORDER BY MIN(UnitPrice);

-- ============================================================
-- 五、时间分析
-- ============================================================

-- 16. 一周内哪天最忙
    CASE DAYOFWEEK(InvoiceDate)
        WHEN 1 THEN '周日'
        WHEN 2 THEN '周一'
        WHEN 3 THEN '周二'
        WHEN 4 THEN '周三'
        WHEN 5 THEN '周四'
        WHEN 6 THEN '周五'
        WHEN 7 THEN '周六'
    END weekday,
    COUNT(DISTINCT InvoiceNo) orders,
    SUM(Quantity) items_sold
FROM retail
WHERE Quantity > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0
GROUP BY weekday, DAYOFWEEK(InvoiceDate)
ORDER BY DAYOFWEEK(InvoiceDate);

-- 17. 一天内哪个时段最忙
SELECT
    CASE
        WHEN HOUR(InvoiceDate) BETWEEN 0 AND 6  THEN '凌晨 (0-6)'
        WHEN HOUR(InvoiceDate) BETWEEN 7 AND 8 THEN '早晨 (7-8)'
        WHEN HOUR(InvoiceDate) BETWEEN 7 AND 11 THEN '上午 (9-11)'
        WHEN HOUR(InvoiceDate) BETWEEN 12 AND 13 THEN '午间 (12-13)'
        WHEN HOUR(InvoiceDate) BETWEEN 14 AND 16 THEN '下午 (14-16)'
        WHEN HOUR(InvoiceDate) BETWEEN 17 AND 19 THEN '傍晚 (17-19)'
        ELSE '晚上 (20-23)'
    END time_period,
    COUNT(DISTINCT InvoiceNo) orders,
    ROUND(100 * COUNT(DISTINCT InvoiceNo) /
          SUM(COUNT(DISTINCT InvoiceNo)) OVER(), 2) pct
FROM retail
WHERE Quantity > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0
GROUP BY time_period
ORDER BY MIN(HOUR(InvoiceDate));

-- ============================================================
-- 六、购物篮分析
-- ============================================================

-- 18. 平均每单商品数
select round(SUM(Quantity)/count(distinct InvoiceNo),1) avg_order_cnt
from retail
WHERE Quantity > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UnitPrice > 0;

-- 19. 最常一起购买的商品 Top 5
SELECT
    a.StockCode product_a,
    MAX(a.Description) name_a,
    b.StockCode product_b,
    MAX(b.Description) name_b,
    COUNT(DISTINCT a.InvoiceNo) together_count
FROM retail a
JOIN retail b
    ON a.InvoiceNo = b.InvoiceNo
    AND a.StockCode < b.StockCode
WHERE a.Quantity > 0 AND b.Quantity > 0
  AND a.InvoiceNo NOT LIKE 'C%'
  AND a.CustomerID IS NOT NULL AND b.CustomerID IS NOT NULL
  AND a.UnitPrice > 0 AND b.UnitPrice > 0
GROUP BY product_a, product_b
ORDER BY together_count DESC
LIMIT 5;
