-- sql/03_rfm.sql
-- Purpose: RFM segmentation using window functions (NTILE)

SET search_path TO retail;

WITH params AS (
  SELECT MAX(invoice_ts)::date AS as_of_date
  FROM v_sales_clean
),
customer_base AS (
  SELECT
    customer_id,
    MAX(invoice_ts)::date AS last_purchase_date,
    COUNT(DISTINCT invoice_no) AS frequency,
    SUM(line_revenue) AS monetary
  FROM v_sales_clean
  GROUP BY 1
),
rfm AS (
  SELECT
    c.*,
    (p.as_of_date - c.last_purchase_date) AS recency_days
  FROM customer_base c
  CROSS JOIN params p
),
scored AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency DESC)  AS f_score,
    NTILE(5) OVER (ORDER BY monetary DESC)   AS m_score
  FROM rfm
)
SELECT
  customer_id,
  recency_days,
  frequency,
  ROUND(monetary::numeric, 2) AS monetary,
  r_score, f_score, m_score,
  (r_score + f_score + m_score) AS rfm_total,
  CASE
    WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
    WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
    WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential'
    ELSE 'At Risk'
  END AS segment
FROM scored
ORDER BY rfm_total DESC, monetary DESC
LIMIT 50;