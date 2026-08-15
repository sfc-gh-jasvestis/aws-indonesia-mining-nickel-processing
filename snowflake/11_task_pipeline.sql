-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_SENSORS
  WAREHOUSE = PROCESSING_WH
  SCHEDULE = 'USING CRON */15 * * * * UTC'
  COMMENT = 'Ingest latest sensor readings from all process lines'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_DETECT_DRIFT
  WAREHOUSE = PROCESSING_WH
  AFTER APP.TASK_INGEST_SENSORS
  COMMENT = 'Run process drift anomaly detection'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_RECOVERY
  WAREHOUSE = PROCESSING_WH
  AFTER APP.TASK_DETECT_DRIFT
  COMMENT = 'Run ML.FORECAST on recovery rates per line'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_FORECAST_RECOVERY RESUME;
ALTER TASK APP.TASK_DETECT_DRIFT RESUME;
ALTER TASK APP.TASK_INGEST_SENSORS RESUME;
