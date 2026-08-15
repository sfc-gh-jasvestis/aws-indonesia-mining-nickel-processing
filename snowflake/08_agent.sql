-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Nickel Processing Optimization
-- ============================================================================
USE DATABASE NICKEL_PROCESSING;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.PROCESS_OPTIMIZATION_AGENT
  COMMENT = 'Nickel Processing Optimization AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'NICKEL_PROCESSING.APP.PROCESSING_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'NICKEL_PROCESSING.SEARCH.PROCESS_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Mining & Nickel Processing information')
  )
  SYSTEM_PROMPT = 'You are the Process Optimization Agent for Indonesian nickel HPAL and RKEF plants, helping engineers maximize nickel recovery rates and minimize energy consumption across 8 processing lines.';
