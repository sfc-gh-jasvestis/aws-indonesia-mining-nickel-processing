-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_indonesia_mining_nickel_processing_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: RECOVERY_DROP_ALERT
CREATE OR REPLACE ALERT APP.RECOVERY_DROP_ALERT
  WAREHOUSE = PROCESSING_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Nickel recovery below threshold — process review needed'
IF (EXISTS (
  SELECT 1 FROM CURATED.PLANT_KPI_DASHBOARD
  WHERE 1=1 -- Condition: Recovery rate drops below 88% for any line for 4 consecutive batches
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_mining_nickel_processing_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Nickel Processing Optimization: Nickel recovery below threshold — process review needed',
    'Nickel recovery below threshold — process review needed'
  );

ALTER ALERT APP.RECOVERY_DROP_ALERT RESUME;

-- Alert: PROCESS_DRIFT_ALERT
CREATE OR REPLACE ALERT APP.PROCESS_DRIFT_ALERT
  WAREHOUSE = PROCESSING_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Process drift detected — operator intervention recommended'
IF (EXISTS (
  SELECT 1 FROM CURATED.PLANT_KPI_DASHBOARD
  WHERE 1=1 -- Condition: Operating parameters outside optimal envelope
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_mining_nickel_processing_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Nickel Processing Optimization: Process drift detected — operator intervention recommended',
    'Process drift detected — operator intervention recommended'
  );

ALTER ALERT APP.PROCESS_DRIFT_ALERT RESUME;

