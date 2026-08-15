-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.PROCESSING_ANALYTICS
  COMMENT = 'Nickel processing plant performance, recovery, energy, and maintenance analytics'
AS
  TABLES (
    CURATED.PLANT_KPI_DASHBOARD AS plant_kpi_dashboard,CURATED.RECOVERY_ANALYTICS AS recovery_analytics,CURATED.ENERGY_EFFICIENCY AS energy_efficiency,CURATED.PROCESS_DRIFT AS process_drift
  );
