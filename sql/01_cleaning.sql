-- sql/01_cleaning.sql
-- Purpose: convert raw text columns into typed fields + create clean analysis views

CREATE SCHEMA IF NOT EXISTS retail;
SET search_path TO retail;

-- 1) Create a typed table from the raw import
DROP TABLE IF EXISTS retail_typed;

CREATE TABLE retail_typed AS
SELECT
  trim(invoiceno) AS invoice_no,
  trim(stockcode) AS stock_code,
  NULLIF(trim(description), '') AS description,
  NULLIF(trim(customerid), '') AS customer_id,
  trim(country) AS country,

  -- Safe numeric casts
  NULLIF(trim(quantity), '')::integer AS quantity,
  NULLIF(trim(unitprice), '')::numeric(10,2) AS unit_price,

  -- This dataset commonly has timestamps like: "12/1/2010 8:26"
  to_timestamp(trim(invoicedate), 'MM/DD/YYYY HH24:MI') AS invoice_ts
FROM retail_raw;

-- 2) Clean sales lines (positive qty + price, require customer)
DROP VIEW IF EXISTS v_sales_clean;
CREATE VIEW v_sales_clean AS
SELECT
  invoice_no,
  stock_code,
  description,
  customer_id,
  country,
  quantity,
  unit_price,
  invoice_ts,
  (quantity * unit_price) AS line_revenue
FROM retail_typed
WHERE customer_id IS NOT NULL
  AND invoice_ts IS NOT NULL
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND quantity > 0
  AND unit_price > 0;

-- 3) Returns lines (optional, kept separate)
DROP VIEW IF EXISTS v_returns;
CREATE VIEW v_returns AS
SELECT
  invoice_no,
  stock_code,
  description,
  customer_id,
  country,
  quantity,
  unit_price,
  invoice_ts,
  (quantity * unit_price) AS line_revenue
FROM retail_typed
WHERE customer_id IS NOT NULL
  AND invoice_ts IS NOT NULL
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND quantity < 0;

-- 4) Quick checks
SELECT COUNT(*) AS raw_rows FROM retail_raw;
SELECT COUNT(*) AS typed_rows FROM retail_typed;
SELECT COUNT(*) AS clean_sales_rows FROM v_sales_clean;
SELECT COUNT(*) AS returns_rows FROM v_returns;