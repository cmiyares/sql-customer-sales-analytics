-- Create a schema for the project
CREATE SCHEMA IF NOT EXISTS retail;

-- Use that schema
SET search_path TO retail;

-- Create a raw table where the CSV will be imported
DROP TABLE IF EXISTS retail_raw;

CREATE TABLE retail_raw (
    invoiceno TEXT,
    stockcode TEXT,
    description TEXT,
    quantity TEXT,
    invoicedate TEXT,
    unitprice TEXT,
    customerid TEXT,
    country TEXT
);

-- Test message
SELECT 'retail_raw ready for CSV import' AS status;