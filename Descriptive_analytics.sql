-- ============================================================
-- File 4: Descriptive_analytics.sql
-- Purpose: Baseline "what does the market look like" 
-- establishes the shape of the data before any comparative analysis is built on top.
-- ============================================================

USE market_expansion;

-- Total revenue and transaction volume by year
SELECT
  YEAR(date_ordered_clean) AS sales_year,
  SUM(sales_dollars) AS total_revenue,
  COUNT(DISTINCT invoice_id) AS total_transactions
FROM iowa_sales_master
GROUP BY sales_year
ORDER BY sales_year;

-- Revenue by city (top 20)
SELECT store_city, SUM(sales_dollars) AS total_revenue
FROM iowa_sales_master
WHERE store_city != ''
GROUP BY store_city
ORDER BY total_revenue DESC
LIMIT 20;

-- Active store count by city (top 20)
SELECT store_city, COUNT(DISTINCT store_number) AS active_stores
FROM iowa_sales_master
WHERE store_city != ''
GROUP BY store_city
ORDER BY active_stores DESC
LIMIT 20;

-- Top-selling categories statewide, by revenue and volume
SELECT category_name, SUM(sales_dollars) AS total_revenue, SUM(sales_bottles) AS total_bottles
FROM iowa_sales_master
WHERE category_name IS NOT NULL
GROUP BY category_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Monthly revenue trend across the full dataset
SELECT
    YEAR(date_ordered_clean) AS yr,
    MONTH(date_ordered_clean) AS mo,
    COUNT(*) AS transaction_count,
    SUM(sales_dollars) AS monthly_revenue
FROM iowa_sales_master
GROUP BY yr, mo
ORDER BY yr, mo;