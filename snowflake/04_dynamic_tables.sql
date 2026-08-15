-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA CURATED;

-- PLANT_KPI_DASHBOARD: Real-time plant KPIs: recovery, throughput, availability, energy intensity
-- Source: PLANT_SENSORS, PRODUCTION_BATCHES, ENERGY_CONSUMPTION
CREATE OR REPLACE DYNAMIC TABLE CURATED.PLANT_KPI_DASHBOARD
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PROCESSING_WH
AS
SELECT * FROM RAW.PLANT_SENSORS;
-- TODO: Replace with actual join/aggregation logic per demo

-- RECOVERY_ANALYTICS: Nickel recovery analysis by feed grade, temperature, and acid consumption
-- Source: PRODUCTION_BATCHES, PLANT_SENSORS, ACID_REAGENT_USAGE
CREATE OR REPLACE DYNAMIC TABLE CURATED.RECOVERY_ANALYTICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PROCESSING_WH
AS
SELECT * FROM RAW.PRODUCTION_BATCHES;
-- TODO: Replace with actual join/aggregation logic per demo

-- ENERGY_EFFICIENCY: Energy intensity metrics by plant and process stage
-- Source: ENERGY_CONSUMPTION, PRODUCTION_BATCHES
CREATE OR REPLACE DYNAMIC TABLE CURATED.ENERGY_EFFICIENCY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PROCESSING_WH
AS
SELECT * FROM RAW.ENERGY_CONSUMPTION;
-- TODO: Replace with actual join/aggregation logic per demo

-- PROCESS_DRIFT: Process parameter deviation from optimal operating envelope
-- Source: PLANT_SENSORS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PROCESS_DRIFT
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PROCESSING_WH
AS
SELECT * FROM RAW.PLANT_SENSORS;
-- TODO: Replace with actual join/aggregation logic per demo

