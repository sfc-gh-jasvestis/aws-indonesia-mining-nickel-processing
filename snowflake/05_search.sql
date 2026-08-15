-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PROCESS_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, PLANT_ID, PROCESS_STAGE
  WAREHOUSE = PROCESSING_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.PROCESS_DOCS
);
