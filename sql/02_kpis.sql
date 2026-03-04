-- sql/02_kpis.sql
-- Purpose: core business KPIs + trends + top customers/products

SET search_path TO retail;

-- 1) Monthly revenue, orders, customers, AOV
WITH invoice_level AS (
  SELECT
    date_trunc('month', invoice_ts)::date AS month,
    invoice_no,
    customer_id,
    SUM(line_revenue) AS invoice_revenue
  FROM v_sales_clean
  GROUP BY 1,2,3
)
SELECT
  month,
  COUNT(DISTINCT invoice_no) AS orders,
  COUNT(DISTINCT customer_id) AS customers,
  ROUND(SUM(invoice_revenue)::numeric, 2) AS revenue,
  ROUND(AVG(invoice_revenue)::numeric, 2) AS avg_order_value
FROM invoice_level
GROUP BY 1
ORDER BY 1;

-- 2) Top 10 customers by revenue
SELECT
  customer_id,
  COUNT(DISTINCT invoice_no) AS orders,
  ROUND(SUM(line_revenue)::numeric, 2) AS revenue,
  ROUND(AVG(line_revenue)::numeric, 2) AS avg_line_revenue
FROM v_sales_clean
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- 3) Top 10 products by revenue
SELECT
  stock_code,
  MAX(description) AS description,
  SUM(quantity) AS units_sold,
  ROUND(SUM(line_revenue)::numeric, 2) AS revenue
FROM v_sales_clean
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- 4) Revenue by country (top 10)
SELECT
  country,
  ROUND(SUM(line_revenue)::numeric, 2) AS revenue,
  COUNT(DISTINCT invoice_no) AS orders,
  COUNT(DISTINCT customer_id) AS customers
FROM v_sales_clean
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- 5) Return rate by revenue (optional but nice)
SELECT
  ROUND(
    (SELECT ABS(SUM(line_revenue)) FROM v_returns)::numeric
    /
    NULLIF((SELECT SUM(line_revenue) FROM v_sales_clean), 0)::numeric
  , 4) AS return_rate_by_revenue;