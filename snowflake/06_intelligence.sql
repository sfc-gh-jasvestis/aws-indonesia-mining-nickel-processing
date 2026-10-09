-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic process-upset SOP corpus (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.PROCESS_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, l.CATEGORY
  FROM RAW.LINE_DAILY r JOIN RAW.LINES l ON l.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.UPSET_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' upset response' AS TITLE,
  'Synthetic demo SOP. Process stage: ' || CATEGORY || '. Upset cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: move the line to a safe hold state, divert off-spec material and notify the shift metallurgist. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%ring%' OR ROOT_CAUSE ILIKE '%chute%' THEN 'reduce feed rate, inspect the kiln inlet and shell scanner profile, and schedule ring removal if the build-up exceeds the inspection limit.'
       WHEN ROOT_CAUSE ILIKE '%burner%' THEN 'check fuel and primary air ratios against the burner setpoints and clean or replace the burner nozzle.'
       WHEN ROOT_CAUSE ILIKE '%electrode%' THEN 'lower furnace power, isolate the broken column, and slip or add an electrode section before restoring load.'
       WHEN ROOT_CAUSE ILIKE '%slag%' OR ROOT_CAUSE ILIKE '%refractory%' THEN 'reduce power input, check slag chemistry and bath level, and review the thermocouple map for refractory hot spots.'
       WHEN ROOT_CAUSE ILIKE '%scale%' OR ROOT_CAUSE ILIKE '%acid%' THEN 'compare acid-to-ore ratio and autoclave temperature with the operating window and plan a descaling shutdown if heat transfer keeps falling.'
       WHEN ROOT_CAUSE ILIKE '%seal%' OR ROOT_CAUSE ILIKE '%pump%' THEN 'switch to the standby unit, isolate and depressurise the failed unit, and replace the seal or impeller from critical spares.'
       WHEN ROOT_CAUSE ILIKE '%floccul%' OR ROOT_CAUSE ILIKE '%ph %' OR ROOT_CAUSE ILIKE 'ph%' THEN 'verify reagent dosing pumps and the online analyser against a manual sample and retune the control loop.'
       WHEN ROOT_CAUSE ILIKE '%filter%' THEN 'wash or replace the filter cloths and check feed solids before returning the press to service.'
       WHEN ROOT_CAUSE ILIKE '%power%' THEN 'confirm captive power plant status, follow the load-shedding sequence and restart the line in the approved order.'
       ELSE 'inspect the affected unit, record readings and escalate to the area engineer if readings are out of tolerance.'
     END
  || ' Step 3: if setpoint deviation exceeds 5% or shell temperature exceeds 290 C after recovery, keep the line on hold. '
  || 'Step 4: record the root cause, lost nickel tonnes and downtime in the plant maintenance system.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PROCESS_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.PROCESS_DOCS);

-- ---------- Setpoint deviation anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, SETPOINT_DEV_PCT::FLOAT AS SETPOINT_DEV
FROM RAW.LINE_DAILY;
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_TRAIN AS
SELECT * FROM ML.SETPOINT_DEV_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SETPOINT_DEV_SERIES);
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_DETECT AS
SELECT * FROM ML.SETPOINT_DEV_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SETPOINT_DEV_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.SETPOINT_DEV_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SETPOINT_DEV_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SETPOINT_DEV',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.SETPOINT_DEV_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS SETPOINT_DEV, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.SETPOINT_DEV_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SETPOINT_DEV_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SETPOINT_DEV'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.PROCESS_ANALYTICS
  TABLES (
    lines AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per process line, 90-day totals',
    risk AS ML.UPSET_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day process upset probability per line',
    causes AS CURATED.UPSET_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Process upsets by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_line AS risk (ENTITY_ID) REFERENCES lines)
  FACTS (
    lines.ni_recovered_f AS NI_RECOVERED_T,
    lines.ni_feed_f AS NI_FEED_T,
    lines.ore_feed_f AS ORE_FEED_T,
    lines.energy_f AS ENERGY_MWH,
    lines.upsets_f AS UPSET_COUNT,
    lines.downtime_hours_f AS DOWNTIME_HOURS,
    lines.operating_hours_f AS OPERATING_HOURS,
    lines.planned_hours_f AS PLANNED_HOURS,
    risk.upset_prob_f AS UPSET_PROB_7D,
    causes.cause_upsets_f AS UPSET_COUNT,
    causes.cause_ni_lost_f AS NI_LOST_T,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_ni_recovered_f AS NI_RECOVERED_T,
    daily.day_ni_feed_f AS NI_FEED_T,
    daily.day_upsets_f AS UPSET_COUNT
  )
  DIMENSIONS (
    lines.line_id AS ENTITY_ID WITH SYNONYMS = ('entities', 'line', 'process line', 'unit'),
    lines.line_name AS ENTITY_NAME,
    lines.site AS REGION WITH SYNONYMS = ('plant', 'site', 'region', 'industrial park') COMMENT = 'Indonesian processing site (fictional plants)',
    lines.process_stage AS CATEGORY WITH SYNONYMS = ('stage', 'line type', 'circuit') COMMENT = 'Rotary Kiln and Electric Furnace are RKEF; Autoclave, CCD Circuit and MHP Precipitation are HPAL',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    lines.line_count AS COUNT(lines.line_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of lines'),
    lines.nickel_recovery_pct AS 100 * SUM(lines.ni_recovered_f) / NULLIF(SUM(lines.ni_feed_f), 0)
      COMMENT = 'Nickel recovered / nickel in feed',
    lines.total_ni_recovered_t AS SUM(lines.ni_recovered_f),
    lines.process_upsets AS SUM(lines.upsets_f) WITH SYNONYMS = ('upsets', 'process events', 'trips'),
    lines.energy_mwh_per_t AS SUM(lines.energy_f) / NULLIF(SUM(lines.ore_feed_f), 0)
      COMMENT = 'Energy MWh per dry tonne of ore processed',
    lines.total_ore_feed_t AS SUM(lines.ore_feed_f) WITH SYNONYMS = ('throughput', 'ore processed'),
    lines.line_availability_pct AS 100 * SUM(lines.operating_hours_f) / NULLIF(SUM(lines.planned_hours_f), 0),
    lines.total_downtime_hours AS SUM(lines.downtime_hours_f),
    risk.avg_upset_prob AS AVG(risk.upset_prob_f),
    causes.cause_upsets AS SUM(causes.cause_upsets_f),
    causes.cause_ni_lost_t AS SUM(causes.cause_ni_lost_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_nickel_recovery_pct AS 100 * SUM(daily.day_ni_recovered_f) / NULLIF(SUM(daily.day_ni_feed_f), 0),
    daily.daily_upsets AS SUM(daily.day_upsets_f)
  )
  COMMENT = 'Synthetic Indonesia nickel processing analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.PROCESS_AGENT
  COMMENT = 'Process assistant over a synthetic network of Indonesian nickel processing lines'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give line IDs and numbers with units."
  orchestration: "Use process_analyst for nickel recovery, process upsets, energy intensity, throughput, lines, sites, risk and root causes. Use sop_search for upset response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: process_analyst
      description: "Nickel recovery, process upsets, energy per tonne, ore throughput, line availability, root causes and upset-risk scores"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic upset-response SOPs by process stage and cause"
tool_resources:
  process_analyst:
    semantic_view: __DEMO_DB__.APP.PROCESS_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.PROCESS_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), LINE_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, SETPOINT_DEV_PCT FLOAT, SHELL_TEMP_C FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION ID_NICKEL_PROC_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (LINE_ID, EVENT_TS, SETPOINT_DEV_PCT, SHELL_TEMP_C, SOP_HINT)
    SELECT t.LINE_ID, t.EVENT_TS, t.SETPOINT_DEV_PCT, t.SHELL_TEMP_C,
           'Check ' || ln.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.LINES ln ON ln.ID = t.LINE_ID
    LEFT JOIN ML.UPSET_RISK_SCORES r ON r.ENTITY_ID = t.LINE_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.LINE_ID = t.LINE_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('ID_NICKEL_PROC_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Indonesia nickel line alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.LINE_ID = t.LINE_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.UPSET_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.UPSET_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.UPSET_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.UPSET_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'SETPOINT_DEV_PCT', SETPOINT_DEV_PCT,
             'SHELL_TEMP_C', SHELL_TEMP_C, 'SETPOINT_DEV_7D', SETPOINT_DEV_7D, 'UPSETS_30D', UPSETS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:UPSET::FLOAT, 4) AS UPSET_PROB_7D,
         CASE WHEN PRED:probability:UPSET::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:UPSET::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
