-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): S&P Global Commodity Insights
--   Real data: https://app.snowflake.com/marketplace/listing/GZT0Z5I4XY0
--   Using mock table: ENERGY_CONSUMPTION
CREATE TABLE IF NOT EXISTS RAW.ENERGY_CONSUMPTION (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

