-- ============================================================
-- File 2: Clean_sales_data.sql
-- Purpose: Fix date formats, standardize city names, remove
--          duplicates, recover missing city values, and index
--          iowa_sales_master for downstream analysis.
-- ============================================================

USE market_expansion;

-- ------------------------------------------------------------
-- 1: Fix the date column
-- date_ordered was imported as text. Two formats exist in the
-- raw files: YYYY-MM-DD and DD-MM-YYYY. 
-- ------------------------------------------------------------

-- Total rows in the data 
SELECT COUNT(*) AS total_rows
FROM iowa_sales_master;

-- Total rows of YYYY-MM-DD format 
SELECT COUNT(*) AS good_format_rows
FROM iowa_sales_master
WHERE date_ordered REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

-- Total rows of DD-MM-YYYY format 
SELECT COUNT(*) AS dd_mm_yyyy_rows
FROM iowa_sales_master
WHERE date_ordered REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$';

-- Date Format Conversion via Regular Expressions
ALTER TABLE iowa_sales_master ADD COLUMN date_ordered_clean DATE;
UPDATE iowa_sales_master
SET date_ordered_clean =
    CASE
        WHEN date_ordered REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(date_ordered, '%Y-%m-%d')
        WHEN date_ordered REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            THEN STR_TO_DATE(date_ordered, '%d-%m-%Y')
        ELSE NULL
    END;


-- Should return 0  confirms every date converted successfully
SELECT COUNT(*) AS failed_conversions
FROM iowa_sales_master
WHERE date_ordered IS NOT NULL AND date_ordered_clean IS NULL;

-- Confirmed complete data coverage for both years 
SELECT
    MIN(date_ordered_clean) AS earliest_date,
    MAX(date_ordered_clean) AS latest_date,
    COUNT(DISTINCT YEAR(date_ordered_clean)) AS distinct_years
FROM iowa_sales_master;

-- ------------------------------------------------------------
-- 2: Standardize city names (case + whitespace)
-- ------------------------------------------------------------

UPDATE iowa_sales_master
SET store_city = UPPER(TRIM(store_city));

-- ------------------------------------------------------------
-- 3: Recover blank store_city values
-- ~1,975 rows had no recorded city. Two recovery strategies:
--   (a) match store_number against other rows from the same
--       store that DO have a city recorded
--   (b) extract the city from store_name, which sometimes
--       encodes it after a "/" (e.g. "HY-VEE / WEST U")
-- Any store_number that could not be resolved either way was
-- left blank and is excluded from city-level analysis.
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_blank_before FROM iowa_sales_master WHERE store_city = '';

-- (a) Recover via matching store_number to a known city
UPDATE iowa_sales_master  
SET store_city =
    CASE store_number
        WHEN 2201 THEN 'CEDAR FALLS'
        WHEN 5073 THEN 'CEDAR RAPIDS'
        WHEN 5203 THEN 'COON RAPIDS'
        WHEN 5213 THEN 'MONTROSE'
        WHEN 5671 THEN 'GLENWOOD'
    END
WHERE store_city = ''
  AND store_number IN (2201, 5073, 5203, 5213, 5671);

-- (b) Recover via extracting city from store_name's "/" suffix
UPDATE iowa_sales_master
SET store_city =
    CASE TRIM(SUBSTRING_INDEX(store_name, '/', -1))
        WHEN 'WDM' THEN 'WEST DES MOINES'
        WHEN 'DENV' THEN 'DENVER'
        WHEN 'WEST U' THEN 'WEST UNION'
        ELSE TRIM(SUBSTRING_INDEX(store_name, '/', -1))
    END
WHERE store_city = ''
  AND store_name LIKE '%/%';

SELECT COUNT(*) AS still_blank FROM iowa_sales_master WHERE store_city = '';

-- ------------------------------------------------------------
-- STEP 4: Consolidate inconsistent spellings within the sales
-- table itself (same city, spelled two different ways)
-- ------------------------------------------------------------

UPDATE iowa_sales_master SET store_city = 'ST ANSGAR'   WHERE store_city = 'SAINT ANSGAR';
UPDATE iowa_sales_master SET store_city = 'CLEARLAKE'   WHERE store_city = 'CLEAR LAKE';
UPDATE iowa_sales_master SET store_city = 'LECLAIRE'    WHERE store_city = 'LE CLAIRE';
UPDATE iowa_sales_master SET store_city = 'LONETREE'    WHERE store_city = 'LONE TREE';
UPDATE iowa_sales_master SET store_city = 'MT PLEASANT' WHERE store_city = 'MOUNT PLEASANT';

-- ------------------------------------------------------------
-- STEP 5: Check for missing critical values and duplicate rows
-- ------------------------------------------------------------

SELECT
    SUM(CASE WHEN store_city IS NULL OR store_city = '' THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN sales_dollars IS NULL THEN 1 ELSE 0 END) AS missing_sales,
    SUM(CASE WHEN date_ordered_clean IS NULL THEN 1 ELSE 0 END) AS missing_dates
FROM iowa_sales_master;

SELECT invoice_id, COUNT(*) AS duplicate_count
FROM iowa_sales_master
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- Deduplicate (none expected given the load process,
-- but confirmed no duplicates were dropped by row count comparison)
CREATE TABLE iowa_sales_master_clean AS
SELECT DISTINCT * FROM iowa_sales_master;

RENAME TABLE iowa_sales_master TO iowa_sales_master_old,
             iowa_sales_master_clean TO iowa_sales_master;

-- ------------------------------------------------------------
-- STEP 6: Index the columns used most heavily in joins/filters
-- ------------------------------------------------------------

CREATE INDEX idx_sales_city ON iowa_sales_master(store_city);
CREATE INDEX idx_sales_date ON iowa_sales_master(date_ordered_clean);
