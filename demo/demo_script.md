# Demo Script: Nickel Processing Optimization
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake optimizes nickel processing — Dynamic Tables maintain real-time plant KPIs, ML.FORECAST projects recovery rates, ML.ANOMALY_DETECTION flags process drift, and Cortex AI generates shift-level operator guidance"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Ir. Dedi Kurniawan** | VP Processing & Technology | React App (SPCS) | Recovery rates, energy efficiency, acid consumption, product quality, plant availability |
| **Fitri Handayani** | Process Engineer | Amazon QuickSight | Temperature/pressure optimization, autoclave performance, MHP precipitation, acid leaching kinetics |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | PLANT_SENSORS (1000000), PRODUCTION_BATCHES (50000), ENERGY_CONSUMPTION (200000), MAINTENANCE_LOGS (10000), PROCESS_DOCS (120), ACID_REAGENT_USAGE (30000) |
| **CURATED** | 4 Dynamic Tables | PLANT_KPI_DASHBOARD, RECOVERY_ANALYTICS, ENERGY_EFFICIENCY, PROCESS_DRIFT |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, SUMMARIZE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 120 documents indexed |
| **Agent** | PROCESS_OPTIMIZATION_AGENT | Semantic View + Search tools |


---

## The Story

Indonesia's nickel processing plants run HPAL and RKEF technology to convert laterite ore into battery-grade products. With recovery rates varying from 84-92% across lines and energy intensity 12% above benchmark, the VP Processing needs real-time visibility into process performance — and ML-driven recommendations to close the efficiency gap worth Rp 180 billion annually.

---

## Script

### [0:00–0:45] PLANT OVERVIEW

**Show**: Plant Overview tab

> "Eight processing lines across Morowali and Weda Bay — average nickel recovery at 89.2%."

**Action**: Point at 89.2% recovery KPI

### [0:45–1:30] PROCESS ANALYTICS

**Show**: Process Analytics tab

> "One million sensor readings across temperature, pressure, flow, and pH per day."

**Action**: Show autoclave temperature profile for Line 3

### [1:30–2:15] PREDICTIVE OPTIMIZATION

**Show**: Predictive Optimization tab

> "ML.FORECAST projects Line 3 recovery dropping to 84% if temperature drift continues."

**Action**: Show recovery forecast with confidence bands

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Dedi asks: 'What's the average nickel recovery across all HPAL lines?'"

**Action**: Type recovery question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services in the dual-build architecture."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST on nickel recovery rates** — Only demo using ML.FORECAST for metallurgical recovery prediction in HPAL/RKEF
2. **Process drift anomaly detection** — ML flags process parameter drift before it impacts product quality
3. **AI-generated operator recommendations** — Cortex AI produces shift-level process adjustment guidance from sensor data
4. **Indonesian HPAL/RKEF context** — Realistic nickel processing with autoclave, acid leaching, and MHP precipitation
5. **1M sensor readings per day via Snowpipe Streaming** — Only demo ingesting high-frequency process data for real-time plant optimization


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.RAW.PLANT_SENSORS` → 1000000
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.RAW.PRODUCTION_BATCHES` → 50000
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.RAW.ENERGY_CONSUMPTION` → 200000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.ML.RECOVERY_RATE_FORECAST_RESULTS` → >0
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.ML.PROCESS_DRIFT_RESULTS WHERE IS_ANOMALY = TRUE` → >=2

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM NICKEL_PROCESSING.AI.MAINTENANCE_CLASSIFICATION` → 10000

