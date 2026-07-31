-- Iowa Liquor Sales — Market Expansion Analysis
-- FILE 1: DATABASE SETUP AND BULK DATA INGESTION
-- Purpose: Create the database, import raw sales data (2024-2025)
--          and the three Census/Iowa Data Hub reference tables.
-- Source: data.iowa.gov (Iowa Liquor Sales), data.census.gov (ACS)


-- 1. Initialize Database Environment
CREATE DATABASE IF NOT EXISTS market_expansion;
USE market_expansion;

-- 2. Define Master Sales Schema
CREATE TABLE IF NOT EXISTS sales_2024_p1 (
    invoice_id VARCHAR(100),
    date_ordered VARCHAR(50),
    store_number INT,
    store_name VARCHAR(255),
    store_address VARCHAR(255),
    store_city VARCHAR(100),
    store_zip VARCHAR(50),
    county_fips VARCHAR(50),
    county_name VARCHAR(100),
    category_number VARCHAR(50),
    category_name VARCHAR(255),
    vendor_number VARCHAR(50),
    vendor_name VARCHAR(255),
    item_number VARCHAR(50),
    item_description VARCHAR(255),
    pack INT,
    bottle_volume_ml INT,
    sales_bottles INT,
    sales_dollars DECIMAL(15,4),
    sales_liters DECIMAL(15,4),
    sales_gallons DECIMAL(15,4)
);

-- Clone schema structure across remaining 9 transaction batch tables
CREATE TABLE sales_2024_p2 LIKE sales_2024_p1;
CREATE TABLE sales_2024_p3 LIKE sales_2024_p1;
CREATE TABLE sales_2024_p4 LIKE sales_2024_p1;
CREATE TABLE sales_2024_p5 LIKE sales_2024_p1;

CREATE TABLE sales_2025_p1 LIKE sales_2024_p1;
CREATE TABLE sales_2025_p2 LIKE sales_2024_p1;
CREATE TABLE sales_2025_p3 LIKE sales_2024_p1;
CREATE TABLE sales_2025_p4 LIKE sales_2024_p1;
CREATE TABLE sales_2025_p5 LIKE sales_2024_p1;

-- 3. Execute Bulk Data Loading for Sales Batches
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2024_1261_rows_part_0001.csv" INTO TABLE sales_2024_p1 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2024_1261_rows_part_0002.csv" INTO TABLE sales_2024_p2 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2024_1261_rows_part_0003.csv" INTO TABLE sales_2024_p3 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2024_1261_rows_part_0004.csv" INTO TABLE sales_2024_p4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2024_1261_rows_part_0005.csv" INTO TABLE sales_2024_p5 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2025_1262_rows_part_0001.csv" INTO TABLE sales_2025_p1 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2025_1262_rows_part_0002.csv" INTO TABLE sales_2025_p2 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2025_1262_rows_part_0003.csv" INTO TABLE sales_2025_p3 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2025_1262_rows_part_0004.csv" INTO TABLE sales_2025_p4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/iowa_liquor_sales_2025_1262_rows_part_0005.csv" INTO TABLE sales_2025_p5 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 4. Consolidate Batches into Master Table
CREATE TABLE iowa_sales_master LIKE `sales_2024_p1`;

INSERT INTO iowa_sales_master SELECT * FROM `sales_2024_p1`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2024_p2`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2024_p3`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2024_p4`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2024_p5`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2025_p1`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2025_p2`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2025_p3`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2025_p4`;
INSERT INTO iowa_sales_master SELECT * FROM `sales_2025_p5`;

-- Drop temporary staging tables to free memory
DROP TABLE sales_2024_p1, sales_2024_p2, sales_2024_p3, sales_2024_p4, sales_2024_p5,
           sales_2025_p1, sales_2025_p2, sales_2025_p3, sales_2025_p4, sales_2025_p5;

-- 5. Define and Import Census Reference Tables
CREATE TABLE raw_population (
  place_fips_code VARCHAR(20),
  city VARCHAR(100),
  county_fips_code VARCHAR(20),
  county VARCHAR(100),
  calendar_year VARCHAR(20),     
  estimate INT,
  primary_latitude DECIMAL(10,7),
  primary_longitude DECIMAL(10,7),
  primary_point VARCHAR(100)
);

CREATE TABLE raw_age (
  GEO_ID VARCHAR(30),
  NAME VARCHAR(100),
  total_population INT,
  population_21_plus INT
);

CREATE TABLE raw_rent (
  GEO_ID VARCHAR(30),
  NAME VARCHAR(100),
  median_gross_rent VARCHAR(20)   
);

LOAD DATA LOCAL INFILE "E:/iowa project data/raw_pop.csv" INTO TABLE raw_population FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/raw_age.csv" INTO TABLE raw_age FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "E:/iowa project data/raw_rent.csv" INTO TABLE raw_rent FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
