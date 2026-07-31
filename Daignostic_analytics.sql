-- ============================================================
-- File 5: Diagnostic_analytics.sql
-- Purpose: Market saturation, per-capita demand, and rent-
--          adjusted profitability — the layer that identifies
--          underserved, high-potential cities and drives the
--          final top-city recommendation.
--
-- Note: Revenue figures below are divided by 2 to approximate
-- average annual revenue, since the dataset covers two complete
-- calendar years (2024 and 2025 — verified via month-by-month
-- transaction counts, ruling out a partial final year).
-- ============================================================

USE market_expansion;

-- ------------------------------------------------------------
-- Market Saturation Index: average annual revenue per store
-- Cities with fewer than 3 active stores are excluded
-- ------------------------------------------------------------

SELECT
  store_city,
  COUNT(DISTINCT store_number) AS active_stores,
  SUM(sales_dollars) / 2 AS avg_annual_revenue,
  (SUM(sales_dollars) / 2) / COUNT(DISTINCT store_number) AS revenue_per_store
FROM iowa_sales_master
WHERE store_city != ''
GROUP BY store_city
HAVING active_stores >= 3
ORDER BY revenue_per_store DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Per-Capita Demand: revenue relative to the 21+ population
-- Normalizes for city size so smaller cities with strong demand aren't overshadowed by simply being large.
-- ------------------------------------------------------------

SELECT
  s.store_city,
  d.population_21_plus,
  SUM(s.sales_dollars) / 2 AS avg_annual_revenue,
  (SUM(s.sales_dollars) / 2) / d.population_21_plus AS revenue_per_adult
FROM iowa_sales_master s
INNER JOIN city_demographics d ON s.store_city = d.city
WHERE d.population_21_plus > 1000
GROUP BY s.store_city, d.population_21_plus
ORDER BY revenue_per_adult DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Combined Diagnostic View: saturation + per-capita demand +
-- rent proxy in one table. Median gross rent (residential, ACS) is used as a disclosed stand-in for unavailable commercial lease data.
-- ------------------------------------------------------------

SELECT
  s.store_city,
  d.population_21_plus,
  d.median_gross_rent,
  COUNT(DISTINCT s.store_number) AS active_stores,
  SUM(s.sales_dollars) / 2 AS avg_annual_revenue,
  (SUM(s.sales_dollars) / 2) / COUNT(DISTINCT s.store_number) AS revenue_per_store,
  (SUM(s.sales_dollars) / 2) / d.population_21_plus AS revenue_per_adult
FROM iowa_sales_master s
INNER JOIN city_demographics d ON s.store_city = d.city
WHERE d.population_21_plus > 1000
  AND d.median_gross_rent IS NOT NULL
GROUP BY s.store_city, d.population_21_plus, d.median_gross_rent
HAVING active_stores >= 3
ORDER BY revenue_per_adult DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Monthly Growth Rate: percent change in revenue, month over month
-- ------------------------------------------------------------

WITH monthly AS (
  SELECT
    YEAR(date_ordered_clean) AS yr,
    MONTH(date_ordered_clean) AS mo,
    SUM(sales_dollars) AS monthly_revenue
  FROM iowa_sales_master
  GROUP BY yr, mo
)
SELECT
  yr, mo, monthly_revenue,
  LAG(monthly_revenue) OVER (ORDER BY yr, mo) AS prev_month_revenue,
  ROUND(
    (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY yr, mo))
    / LAG(monthly_revenue) OVER (ORDER BY yr, mo) * 100,
  2) AS pct_growth
FROM monthly
ORDER BY yr, mo;

-- ------------------------------------------------------------
-- FINAL SYNTHESIS: Top city candidates for expansion
-- Ranked by revenue per adult (per-capita demand), cross-checked
-- against saturation (revenue per store) and cost (median rent).
-- This is the table the final written recommendation is drawn from.
-- ------------------------------------------------------------

SELECT
  s.store_city,
  d.population_21_plus,
  d.median_gross_rent,
  COUNT(DISTINCT s.store_number) AS active_stores,
  SUM(s.sales_dollars) / 2 AS avg_annual_revenue,
  (SUM(s.sales_dollars) / 2) / COUNT(DISTINCT s.store_number) AS revenue_per_store,
  (SUM(s.sales_dollars) / 2) / d.population_21_plus AS revenue_per_adult
FROM iowa_sales_master s
INNER JOIN city_demographics d ON s.store_city = d.city
WHERE d.population_21_plus > 1000 AND d.median_gross_rent IS NOT NULL
GROUP BY s.store_city, d.population_21_plus, d.median_gross_rent
HAVING active_stores >= 3
ORDER BY revenue_per_adult DESC
LIMIT 10;