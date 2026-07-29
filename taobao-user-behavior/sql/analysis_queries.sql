-- ============================================================
-- 淘宝用户行为分析 - 核心 SQL 查询
-- 数据表: taobao.userbehavi (c1用户, c2商品, c3品类, c4行为, c5时间戳)
-- 时间范围: 2017-11-25 ~ 2017-12-03
-- ============================================================

-- ============================================================
-- 一、流量分析
-- ============================================================

-- 1. 每日 PV/UV 趋势
select date(from_unixtime(c5)) date,
       count(*) pv,
       count(distinct c1) uv,
    count(*) / count(distinct c1) 'pv/uv'
from userbehavi
where c4 = 'pv'
group by date;

-- 2. 分时段活跃度（按小时）
select hour(from_unixtime(c5)) hour,
       count(*) pv,
       count(distinct c1) uv,
    count(*)/count(distinct c1) 'pv/uv'
from userbehavi
where c4='pv'
group by hour;

-- ============================================================
-- 二、用户行为转化漏斗
-- ============================================================

-- 3. 行为类型总量
select c4,count(c4)
from userbehavi
group by c4;

-- 4. 商品级转化漏斗（同人同商品口径）
SELECT
    COUNT(DISTINCT c1) total_users,
    COUNT(DISTINCT CASE WHEN c4 IN ('cart','fav') THEN c1 END) cart_fav_users,
    COUNT(DISTINCT CASE WHEN c4 = 'buy' THEN c1 END) buy_users
FROM userbehavi
WHERE c5 BETWEEN 1512316200 AND 1512316800;

WITH user_prod AS (
    SELECT c1, c2,
           MAX(CASE WHEN c4='pv' THEN 1 ELSE 0 END) has_pv,
           MAX(CASE WHEN c4 IN ('cart','fav') THEN 1 ELSE 0 END) has_cart_fav,
           MAX(CASE WHEN c4='buy' THEN 1 ELSE 0 END) has_buy
    FROM userbehavi
    GROUP BY c1, c2
)
SELECT
    COUNT(*) total_user_prod,
    SUM(has_cart_fav) cart_fav_cnt,
    SUM(has_buy) buy_cnt,
    ROUND(100 * SUM(has_cart_fav) / SUM(has_pv), 2) pv_to_cart_fav_rate,
    ROUND(100 * SUM(has_buy) / SUM(has_pv), 2) pv_to_buy_rate
FROM user_prod
WHERE has_pv = 1;

-- ============================================================
-- 三、用户留存
-- ============================================================

-- 5. 次日留存率（按日）
select d1.date,count(distinct d2.c1)/count( distinct d1.c1) '次日留存率' from
(select distinct c1,date(from_unixtime(c5)) date
 from userbehavi) d1
left join (select distinct c1,date(from_unixtime(c5)) date
           from userbehavi) d2
on d2.date=date_add(d1.date,interval 1 day)
       and d1.c1=d2.c1
group by d1.date
order by d1.date;

select distinct date(from_unixtime(c5)) from userbehavi;

WITH daily_users AS (
    SELECT DISTINCT c1, DATE(FROM_UNIXTIME(c5)) dt
    FROM userbehavi
)
SELECT d1.dt,count(distinct d1.c1) pv_num,
       COUNT(DISTINCT d2.c1) / COUNT(DISTINCT d1.c1) retention_1d
FROM daily_users d1
LEFT JOIN daily_users d2
    ON d1.c1 = d2.c1 AND d2.dt = DATE_ADD(d1.dt, INTERVAL 1 DAY)
GROUP BY d1.dt
ORDER BY d1.dt;

-- ============================================================
-- 四、复购与频次
-- ============================================================

-- 7. 复购率
WITH prod_buyers AS (
    SELECT c1, c2, COUNT(*) buy_times
    FROM userbehavi
    WHERE c4 = 'buy'
    GROUP BY c1, c2
)
SELECT
    COUNT(*) '总购买数',
    SUM(CASE WHEN buy_times >= 2 THEN 1 ELSE 0 END) '复购数',
    ROUND(100 * SUM(CASE WHEN buy_times >= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) '复购率'
FROM prod_buyers;

-- 8. 购买频次分布
WITH user_buy_cnt AS (
    SELECT c1, COUNT(*) buy_times
    FROM userbehavi
    WHERE c4 = 'buy'
    GROUP BY c1
)
SELECT
    buy_times '购买次数',
    COUNT(*) '用户数',
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 4) '占比'
FROM user_buy_cnt
GROUP BY buy_times
ORDER BY buy_times;

-- ============================================================
-- 五、RFM 用户分层
-- ============================================================

-- 9. RFM 四类分层
WITH buy_users AS (
    SELECT
        c1,
        COUNT(*) frequency,
        DATEDIFF('2017-12-03', MAX(DATE(FROM_UNIXTIME(c5)))) recency
    FROM userbehavi
    WHERE c4 = 'buy'
    GROUP BY c1
),
medians AS (
    SELECT
        AVG(recency) r_avg,
        AVG(frequency) f_avg
    FROM buy_users
),
tagged AS (
    SELECT
        CASE
            WHEN b.recency <= m.r_avg AND b.frequency >= m.f_avg THEN '重要价值用户'
            WHEN b.recency <= m.r_avg AND b.frequency <  m.f_avg THEN '重要发展用户'
            WHEN b.recency >  m.r_avg AND b.frequency >= m.f_avg THEN '重要保持用户'
            ELSE '重要挽留用户'
        END user_type
    FROM buy_users b
    CROSS JOIN medians m
)
SELECT
    user_type,
    COUNT(*) user_cnt,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) pct
FROM tagged
GROUP BY user_type
ORDER BY user_cnt DESC;

-- ============================================================
-- 六、商品与品类分析
-- ============================================================

-- 10. 热门商品 Top 10（按浏览量）
SELECT
    c2 product_id,
    COUNT(*) pv
FROM userbehavi
WHERE c4 = 'pv'
GROUP BY c2
ORDER BY pv DESC
LIMIT 10;

-- 11. 热销商品 Top 10（按购买量+转化率）
SELECT
    c2 product_id,
    SUM(CASE WHEN c4 = 'pv'  THEN 1 ELSE 0 END) pv,
    SUM(CASE WHEN c4 = 'buy' THEN 1 ELSE 0 END) buy_cnt,
    ROUND(100 * SUM(CASE WHEN c4 = 'buy' THEN 1 ELSE 0 END) /
                NULLIF(SUM(CASE WHEN c4 = 'pv' THEN 1 ELSE 0 END), 0), 2) conversion_pct
FROM userbehavi
GROUP BY c2
ORDER BY buy_cnt DESC
LIMIT 10;
-- 12. 高转化品类 Top 10
SELECT
    c3 category_id,
    SUM(CASE WHEN c4 = 'pv'  THEN 1 ELSE 0 END) pv,
    SUM(CASE WHEN c4 = 'buy' THEN 1 ELSE 0 END) buy_cnt,
    ROUND(100 * SUM(CASE WHEN c4 = 'buy' THEN 1 ELSE 0 END) /
                NULLIF(SUM(CASE WHEN c4 = 'pv' THEN 1 ELSE 0 END), 0), 2) conversion_pct
FROM userbehavi
GROUP BY c3
HAVING pv >= 1000  -- 过滤掉太小众的品类
ORDER BY conversion_pct DESC
LIMIT 10;

-- 13. 品类四象限分类
WITH cat_stats AS (
    SELECT
        c3 category_id,
        SUM(CASE WHEN c4 = 'pv'  THEN 1 ELSE 0 END) pv,
        SUM(CASE WHEN c4 = 'buy' THEN 1 ELSE 0 END) buy_cnt
    FROM userbehavi
    GROUP BY c3
),
medians AS (
    SELECT AVG(pv) pv_avg, AVG(buy_cnt) buy_avg
    FROM cat_stats
),
tagged AS (
    SELECT
        CASE
            WHEN c.pv >= m.pv_avg AND c.buy_cnt >= m.buy_avg THEN '明星品类'
            WHEN c.pv >= m.pv_avg AND c.buy_cnt <  m.buy_avg THEN '流量浪费'
            WHEN c.pv <  m.pv_avg AND c.buy_cnt >= m.buy_avg THEN '利基品类'
            ELSE '长尾品类'
        END quadrant
    FROM cat_stats c
    CROSS JOIN medians m
)
SELECT
    quadrant,
    COUNT(*) cat_cnt,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) pct
FROM tagged
GROUP BY quadrant
ORDER BY cat_cnt DESC;