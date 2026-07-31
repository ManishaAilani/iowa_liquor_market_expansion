# Iowa Liquor Market Expansion Analysis

A SQL-driven market-entry analysis identifying the strongest candidate cities in Iowa for new retail liquor store investment, using 5.7M+ rows of real state wholesale transaction data (2024–2025) combined with U.S. Census demographic and cost-of-living data.

## Business Objective

Opening a new retail location is a multi-year, capital-intensive commitment — the wrong city means years of underperformance; the right one means a profitable, defensible market position. This project replaces guesswork with a data-driven framework: it identifies which Iowa cities show strong consumer demand, low retail saturation, and low relative operating cost — the profile of an underserved, high-potential market.

## Data Sources

| Dataset | Source | Purpose |
|---|---|---|
| Iowa Liquor Sales (2024–2025) | [data.iowa.gov](https://data.iowa.gov) | Wholesale transaction records — revenue, volume, product mix, store locations |
| City Population by County and Year | [data.iowa.gov](https://data.iowa.gov) | Population baseline for per-capita calculations |
| S0101 — Age and Sex (ACS 5-Year Estimates) | [data.census.gov](https://data.census.gov) | Legal drinking-age (21+) population share |
| B25064 — Median Gross Rent (ACS 5-Year Estimates) | [data.census.gov](https://data.census.gov) | Cost-of-operating proxy |

Raw data files are not included in this repository due to size (100MB+ per file) — download links above; scripts assume CSVs are loaded into a local MySQL instance.

## Tech Stack

- **MySQL 8.0** (MySQL Workbench)
- Standard SQL — window functions (`RANK()`, `LAG()`), CTEs, aggregate joins

## Project Structure

```
sql/
  01_setup_and_import.sql        -- database + table creation, raw data import
  02_clean_sales_data.sql        -- date fixes, city name standardization, dedup, indexing
  03_clean_reference_tables.sql  -- population/age/rent cleanup, city_demographics build
  04_descriptive_analytics.sql   -- baseline revenue, category, and store-count queries
  05_diagnostic_analytics.sql    -- saturation, per-capita demand, rent-adjusted synthesis
ER_diagram.png
README.md
```

## Methodology

**1. Data Import** — Ten raw CSV files (5 per year) loaded into staging tables and consolidated into one 5.7M-row master table.

**2. Sales Data Cleaning** — Converted text dates to true `DATE` type (confirmed day-first format using a real value of `28-04-2025`, since no month can exceed 12); standardized city name casing/whitespace; recovered ~1,900 rows with missing city values by cross-referencing store number and parsing store name; removed duplicate rows; indexed on city and date.

**3. Reference Data Cleaning** — Merged split-county cities (e.g., Norwalk) into single population totals using `SUM` + `GROUP BY`; excluded non-city "Balance of County" rows; converted suppressed rent values (Census privacy thresholds for small populations) to `NULL` rather than fabricating a number.

**4. City Name Reconciliation** — Cross-checked every city in the sales data against the demographic table; resolved ~15 spelling/formatting mismatches (e.g., "DEWITT" vs. "DE WITT") after confirming each was a genuine same-city match rather than a coincidental name overlap.

**5. Descriptive Analytics** — Established baseline figures: total revenue by year, revenue and active store count by city, top-selling product categories.

**6. Diagnostic Analytics** — Built the core recommendation logic: a Market Saturation Index (revenue per active store), Per-Capita Demand (revenue per legal-drinking-age resident), and a combined view layering in a rent-based cost proxy.

## Key Assumptions & Disclosed Limitations

- **Rent proxy**: Commercial lease data is not publicly available at city level. Median gross *residential* rent (Census ACS) is used as a stand-in cost-of-operating signal.
- **Population stability**: City population is treated as constant across both 2024 and 2025 sales periods, since population changes gradually relative to the granularity of this analysis.
- **Annualized revenue**: Revenue figures are divided by 2 to approximate average annual revenue.
- **7 excluded communities**: AMANA, DENMARK, DOUDS, PLEASANT VALLEY, TROY MILLS, WASHBURN, and WEVER appear in the sales data but have no standalone Census population figure (likely unincorporated communities counted within a township) and are excluded from per-capita and rent-based comparisons.
- **Store-level, not consumer-level, data**: Each row represents a wholesale order from the state to a licensed retailer, not an individual consumer purchase — "revenue" reflects retailer restocking volume, a proxy for consumer demand rather than a direct measure of it.

## Key Findings

**Statewide revenue**: $447.2M (2024) vs. $424.8M (2025) — a modest year-over-year decline in total revenue, alongside a larger drop in transaction count (2.59M → 1.67M), meaning average order size increased even as order volume fell.

**Top 10 cities by total revenue:**

| City | Total Revenue |
|---|---|
| Des Moines | $102,686,628 |
| Cedar Rapids | $56,082,476 |
| Davenport | $40,598,010 |
| West Des Moines | $38,737,718 |
| Council Bluffs | $30,391,131 |
| Sioux City | $28,465,458 |
| Ankeny | $27,253,528 |
| Iowa City | $25,348,840 |
| Waterloo | $24,852,722 |
| Dubuque | $21,682,783 |

Notably, Des Moines and Cedar Rapids both operate **98 active stores** — identical store counts — yet Des Moines generates nearly double the revenue per store (~$1.05M vs. ~$572K), an early signal that Des Moines demand outpaces its current store footprint even before adjusting for population or rent.

**Top 5 product categories by revenue:**

| Category | Revenue | Bottles Sold |
|---|---|---|
| American Vodkas | $131,984,170 | 12,985,436 |
| Canadian Whiskies | $95,606,030 | 5,750,435 |
| Straight Bourbon Whiskies | $80,241,591 | 3,438,829 |
| 100% Agave Tequila | $67,982,446 | 2,370,672 |
| Whiskey Liqueur | $53,536,266 | 9,322,470 |

American Vodkas lead by a wide margin — more than 38% ahead of the second-place category by revenue.

**Seasonality**: December is a consistent peak in both years (highest monthly transaction count and revenue — ~$41–42M), consistent with holiday-season demand.

## Recommendation: Top Cities for Expansion

| Rank | City | Revenue/Adult (annual) | Revenue/Store (annual) | Active Stores | 21+ Population | Median Rent |
|---|---|---|---|---|---|---|
| 1 | Mount Vernon | $1,308.03 | $1,141,040.83 | 3 | 2,617 | $780 |
| 2 | Windsor Heights | $1,180.26 | $657,910.44 | 7 | 3,902 | $1,498 |
| 3 | Spirit Lake | $620.91 | $267,424.51 | 10 | 4,307 | $911 |

**Why these cities:** Mount Vernon and Windsor Heights stand out on every dimension that matters for a low-risk, high-return entry — the highest per-capita demand in the state, strong existing revenue per store (meaning current retailers are not underperforming, demand genuinely supports high per-store sales), and comparatively low rent. Mount Vernon in particular combines the state's highest revenue-per-adult figure with only 3 active stores and the lowest rent of the three — the clearest single "underserved market" signal in the dataset. Spirit Lake is the strongest supported third candidate: while its per-capita figure trails the top two, it pairs solid demand with strong revenue-per-store economics and moderate rent — a healthier balance than alternatives like Toledo, which shows high per-capita demand but comparatively weak revenue per store ($105,885 across 7 stores), suggesting that market may already be closer to saturated relative to its size than the raw per-capita number implies.

**Disclosed data caveat**: DeWitt led the pure store-based saturation ranking by a wide margin (revenue/store: $1,177,573 across 6 stores) but does not appear in the per-capita or combined rankings. This is because DeWitt is one of 3 cities identified during data validation with a missing 21+ population figure in the underlying Census data, which silently excludes it from any per-capita calculation. Rather than either omitting this finding or promoting DeWitt without a complete picture, it is flagged here as a limitation — DeWitt may merit direct follow-up with a supplemental population source before being ruled in or out as a candidate.

**Growth context**: Monthly revenue growth shows a consistent seasonal pattern in both years — a strong pre-holiday surge in October (+24.1% in 2024, +13.9% in 2025) and December (+20.1% in 2025), followed by a sharp January pullback (-24.5% in 2025) — useful context for timing inventory and staffing decisions at any new location, though not a factor in city selection itself.

## How to Reproduce

1. Download the datasets listed under Data Sources
2. Update file paths in `01_setup_and_import.sql` to match your local CSV locations
3. Run the 5 scripts in numbered order in MySQL Workbench
