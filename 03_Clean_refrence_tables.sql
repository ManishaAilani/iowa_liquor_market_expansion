-- ============================================================
-- File 3: Clean_reference_tables.sql
-- Purpose: Clean population, age, and rent reference tables;
--          consolidate split-county cities; build the final
--          city_demographics table; reconcile city name
--          mismatches against iowa_sales_master.
-- ============================================================

USE market_expansion;

-- ------------------------------------------------------------
-- 1: Standardize city names in all three reference tables
-- ------------------------------------------------------------

UPDATE raw_population SET city = UPPER(TRIM(REPLACE(city, '(pt.)', '')));
UPDATE raw_age SET NAME = UPPER(TRIM(REPLACE(NAME, ' city, Iowa', '')));
UPDATE raw_rent SET NAME = UPPER(TRIM(REPLACE(NAME, ' city, Iowa', '')));

-- ------------------------------------------------------------
-- 2: Consolidate population, merging split-county cities
-- Some Iowa cities straddle a county line and appear as two (or
-- more) rows in the raw file — one per county fragment. SUM +
-- GROUP BY combines these into one true city total. Rows labeled
-- "Balance of [County] County" are unincorporated leftover
-- population, not real cities, and are excluded. Filtered to the
-- July 2024 estimate (most recent vintage available; population
-- treated as stable across both 2024 and 2025 sales periods).
-- ------------------------------------------------------------

CREATE TABLE raw_population_clean AS
SELECT
  city,
  SUM(estimate) AS total_population
FROM raw_population
WHERE calendar_year = '2024-07-01'
  AND city NOT LIKE 'BALANCE OF%'
GROUP BY city;

-- Check: Norwalk should appear as ONE row (~15,396), not two
SELECT city, total_population FROM raw_population_clean WHERE city = 'NORWALK';

-- ------------------------------------------------------------
-- 3: Clean the rent table
-- The Census suppresses rent estimates for very small
-- populations (shown as '-'). These become NULL rather than a
-- fabricated number, then the column is cast to a proper decimal.
-- ------------------------------------------------------------

UPDATE raw_rent
SET median_gross_rent = NULL
WHERE median_gross_rent IS NOT NULL
  AND median_gross_rent NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

ALTER TABLE raw_rent MODIFY median_gross_rent DECIMAL(10,2);

-- ------------------------------------------------------------
-- 4: Build the final city_demographics table
-- LEFT JOINs preserve every city even where age or rent data is
-- unavailable (rather than silently dropping them via INNER JOIN)
-- ------------------------------------------------------------

CREATE TABLE city_demographics AS
SELECT
  p.city,
  p.total_population,
  a.population_21_plus,
  r.median_gross_rent
FROM raw_population_clean p
LEFT JOIN raw_age a ON p.city = a.NAME
LEFT JOIN raw_rent r ON p.city = r.NAME;

-- ------------------------------------------------------------
-- 5: Reconcile remaining spelling mismatches between
-- city_demographics and iowa_sales_master. Verified each one is
-- a genuine same-city match (not a coincidental substring match
-- with an unrelated city) before renaming.
-- ------------------------------------------------------------

UPDATE city_demographics SET city = 'CLEARLAKE'   WHERE city = 'CLEAR LAKE';
UPDATE city_demographics SET city = 'DEWITT'      WHERE city = 'DE WITT';
UPDATE city_demographics SET city = 'GRAND MOUNDS' WHERE city = 'GRAND MOUND';
UPDATE city_demographics SET city = 'JEWELL'      WHERE city = 'JEWELL JUNCTION';
UPDATE city_demographics SET city = 'LECLAIRE'    WHERE city = 'LE CLAIRE';
UPDATE city_demographics SET city = 'LONETREE'    WHERE city = 'LONE TREE';
UPDATE city_demographics SET city = 'MT PLEASANT' WHERE city = 'MOUNT PLEASANT';
UPDATE city_demographics SET city = 'ST ANSGAR'   WHERE city = 'ST. ANSGAR';
UPDATE city_demographics SET city = 'ST CHARLES'  WHERE city = 'ST. CHARLES';
UPDATE city_demographics SET city = 'ST LUCAS'    WHERE city = 'ST. LUCAS';

-- ------------------------------------------------------------
-- 6: Final orphan check
-- Confirms every city in the sales data now has a demographic
-- match, EXCEPT 7 documented, genuinely small unincorporated
-- communities with no standalone Census population figure:
-- AMANA, DENMARK, DOUDS, PLEASANT VALLEY, TROY MILLS, WASHBURN,
-- WEVER. These are excluded from per-capita/rent-based analysis.
-- ------------------------------------------------------------

SELECT DISTINCT store_city
FROM iowa_sales_master
WHERE store_city NOT IN (SELECT city FROM city_demographics)
  AND store_city != '';
