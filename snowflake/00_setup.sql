-- ============================================================================
-- Nickel Processing Optimization
-- HPAL and RKEF process optimization for Indonesia's nickel smelters — ML.FORECAST predicts recovery rates, Dynamic Tables build real-time plant dashboards, and Cortex AI generates operator recommendations.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS NICKEL_PROCESSING;
CREATE WAREHOUSE IF NOT EXISTS PROCESSING_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE NICKEL_PROCESSING;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE PROCESSING_WH;
