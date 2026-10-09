-- Synthetic line-day observations for nickel processing lines (RKEF and HPAL
-- stages). Nothing is seeded as a prediction. Randomness is HASH-seeded, so every
-- rebuild is reproducible: per-line age and upset propensity, wear between
-- maintenance shutdowns, missed PM, stage-weighted upset causes, and two
-- site-wide captive power trips. Plants and lines are fictional.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.LINES AS
WITH lines AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS LINE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 24))
), draws AS (
  SELECT LINE_INDEX,
         MOD(ABS(HASH(LINE_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(LINE_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(LINE_INDEX, 'pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(LINE_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(LINE_INDEX, 'grade')), 1000000) / 1e6 AS U_GRADE
  FROM lines
)
SELECT 'PL-' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic line ' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (8 and 5 are coprime): every site and stage is present.
       CASE MOD(LINE_INDEX, 8) WHEN 0 THEN 'Morowali' WHEN 1 THEN 'Morowali' WHEN 2 THEN 'Morowali'
            WHEN 3 THEN 'Weda Bay' WHEN 4 THEN 'Weda Bay' WHEN 5 THEN 'Konawe' WHEN 6 THEN 'Pomalaa'
            ELSE 'Obi Island' END AS REGION,
       CASE MOD(LINE_INDEX, 5) WHEN 0 THEN 'Rotary Kiln' WHEN 1 THEN 'Electric Furnace'
            WHEN 2 THEN 'Autoclave' WHEN 3 THEN 'CCD Circuit' ELSE 'MHP Precipitation' END AS CATEGORY,
       IFF(MOD(LINE_INDEX, 5) < 2, 'RKEF', 'HPAL') AS ROUTE,
       LINE_INDEX,
       ROUND(1 + U_AGE * 9, 1) AS AGE_YEARS,
       -- Base daily upset probability 0.4%-3%; ~15% of lines are chronic (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_UPSET_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       -- Saprolite feed (RKEF) is richer than limonite feed (HPAL).
       ROUND(IFF(MOD(LINE_INDEX, 5) < 2, 1.70 + U_GRADE * 0.30, 1.10 + U_GRADE * 0.40), 2) AS FEED_GRADE_PCT,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.LINE_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), power_trips AS (
  -- Two site-wide captive power plant trips in the window.
  SELECT * FROM VALUES (27, 'Morowali', 3.5), (64, 'Weda Bay', 2.0) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT l.ID AS ENTITY_ID, l.LINE_INDEX, l.CATEGORY, l.REGION, l.AGE_YEARS,
         l.BASE_UPSET_RATE, l.PM_INTERVAL_DAYS, l.PM_COMPLETION_PROB, l.FEED_GRADE_PCT,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + l.LINE_INDEX * 5, l.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'upset')), 1000000) / 1e6 AS U_UPSET,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'feed')), 1000000) / 1e6 AS U_FEED,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         p.HOURS AS TRIP_HOURS
  FROM RAW.LINES l CROSS JOIN days d
  LEFT JOIN power_trips p ON p.DAY_INDEX = d.DAY_INDEX AND p.REGION = l.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Wear (refractory, scale, seals) rises between PM; weak discipline carries it over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR
  FROM base
), upsets AS (
  SELECT *,
         CASE WHEN TRIP_HOURS IS NOT NULL THEN 1
              WHEN U_UPSET < LEAST(0.5, BASE_UPSET_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 15)) / 4 THEN 2
              WHEN U_UPSET < LEAST(0.5, BASE_UPSET_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 15)) THEN 1
              ELSE 0 END AS UPSET_COUNT
  FROM pm
), timed AS (
  SELECT *,
         -- Line-down hours: exponential, mean depends on the stage.
         CASE WHEN UPSET_COUNT = 0 THEN 0.0
              WHEN TRIP_HOURS IS NOT NULL THEN TRIP_HOURS
              ELSE LEAST(20.0, ROUND(UPSET_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Rotary Kiln' THEN 4.0 WHEN 'Electric Furnace' THEN 4.5
                                 WHEN 'Autoclave' THEN 3.5 WHEN 'CCD Circuit' THEN 2.0 ELSE 2.5 END), 1))
         END AS DOWNTIME_HOURS
  FROM upsets
), output AS (
  SELECT *,
         PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
         -- Dry ore throughput 50-85 t/h while running.
         ROUND((PLANNED_HOURS - DOWNTIME_HOURS) * (50 + U_FEED * 35)) AS ORE_FEED_T,
         -- Stage nickel recovery: base by stage, minus wear, age and the upset hit.
         LEAST(0.995, GREATEST(0.60,
           CASE CATEGORY WHEN 'Rotary Kiln' THEN 0.975 WHEN 'Electric Furnace' THEN 0.930
                         WHEN 'Autoclave' THEN 0.950 WHEN 'CCD Circuit' THEN 0.965 ELSE 0.960 END
           - 0.025 * WEAR - 0.004 * AGE_YEARS / 10 - 0.006 * U_NOISE
           - UPSET_COUNT * (0.04 + 0.08 * U_HIT))) AS RECOVERY,
         -- Energy per dry tonne by stage; wear and upsets add losses.
         CASE CATEGORY WHEN 'Rotary Kiln' THEN 0.11 WHEN 'Electric Furnace' THEN 0.42
                       WHEN 'Autoclave' THEN 0.06 WHEN 'CCD Circuit' THEN 0.015 ELSE 0.025 END
           * (1 + 0.08 * WEAR + 0.15 * UPSET_COUNT + 0.04 * U_NOISE) AS MWH_PER_T
  FROM timed
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS, OPERATING_HOURS,
       UPSET_COUNT,
       CASE WHEN UPSET_COUNT = 0 THEN 'None'
            WHEN TRIP_HOURS IS NOT NULL THEN 'Captive power trip'
            WHEN CATEGORY = 'Rotary Kiln' THEN IFF(U_CAUSE < 0.5, 'Kiln ring build-up', IFF(U_CAUSE < 0.8, 'Burner flame instability', 'Feed chute blockage'))
            WHEN CATEGORY = 'Electric Furnace' THEN IFF(U_CAUSE < 0.45, 'Electrode breakage', IFF(U_CAUSE < 0.8, 'Slag foaming', 'Refractory hot spot'))
            WHEN CATEGORY = 'Autoclave' THEN IFF(U_CAUSE < 0.5, 'Scale build-up', IFF(U_CAUSE < 0.8, 'Acid dosing deviation', 'Agitator seal failure'))
            WHEN CATEGORY = 'CCD Circuit' THEN IFF(U_CAUSE < 0.6, 'Flocculant underdosing', 'Underflow pump failure')
            ELSE IFF(U_CAUSE < 0.6, 'pH control drift', 'Filter press blinding') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       ORE_FEED_T,
       ROUND(ORE_FEED_T * FEED_GRADE_PCT / 100, 3) AS NI_FEED_T,
       ROUND(ORE_FEED_T * FEED_GRADE_PCT / 100 * RECOVERY, 3) AS NI_RECOVERED_T,
       ROUND(ORE_FEED_T * MWH_PER_T + DOWNTIME_HOURS * 0.4, 1) AS ENERGY_MWH,
       ROUND(0.6 + 2.2 * WEAR + 2.5 * UPSET_COUNT + U_NOISE * 0.6, 2) AS SETPOINT_DEV_PCT,
       ROUND(225 + 30 * WEAR + 25 * UPSET_COUNT + U_NOISE * 10, 1) AS SHELL_TEMP_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM output;

-- Critical spares coverage per line (snapshot).
CREATE TABLE RAW.CRITICAL_SPARES AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Rotary Kiln' THEN 'Burner nozzle set' WHEN 'Electric Furnace' THEN 'Electrode column section'
                     WHEN 'Autoclave' THEN 'Agitator seal kit' WHEN 'CCD Circuit' THEN 'Underflow pump impeller'
                     ELSE 'Filter cloth set' END AS PART_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'hand')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.LINES;
