-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Nickel Processing Optimization
-- Country: INDONESIA | Currency: IDR
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- PLANT_SENSORS: 1,000,000 rows — Real-time temperature, pressure, flow, and pH readings from all process lines
-- PRODUCTION_BATCHES: 50,000 rows — Batch production records with feed grade, recovery, and product spec
-- ENERGY_CONSUMPTION: 200,000 rows — Hourly energy consumption by plant, line, and equipment
-- MAINTENANCE_LOGS: 10,000 rows — Equipment maintenance records, failure modes, and downtime
-- PROCESS_DOCS: 120 rows — SOPs, metallurgical test reports, and process optimization studies
-- ACID_REAGENT_USAGE: 30,000 rows — Sulfuric acid and reagent consumption by line and batch
