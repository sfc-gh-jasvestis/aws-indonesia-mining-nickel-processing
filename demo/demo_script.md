# Nickel Processing Optimization

**Indonesia - Mining & Nickel Processing**
Use case: Processing Plant Optimization

> HPAL and RKEF process optimization for Indonesia's nickel smelters — ML.FORECAST predicts recovery rates, Dynamic Tables build real-time plant dashboards, and Cortex AI generates operator recommendations.

## Why Snowflake

Snowflake optimizes nickel processing — Dynamic Tables maintain real-time plant KPIs, ML.FORECAST projects recovery rates, ML.ANOMALY_DETECTION flags process drift, and Cortex AI generates shift-level operator guidance

- **ML.FORECAST on nickel recovery rates** - Only demo using ML.FORECAST for metallurgical recovery prediction in HPAL/RKEF
- **Process drift anomaly detection** - ML flags process parameter drift before it impacts product quality
- **AI-generated operator recommendations** - Cortex AI produces shift-level process adjustment guidance from sensor data
- **Indonesian HPAL/RKEF context** - Realistic nickel processing with autoclave, acid leaching, and MHP precipitation
- **1M sensor readings per day via Snowpipe Streaming** - Only demo ingesting high-frequency process data for real-time plant optimization

## What is deployed

| | |
|---|---|
| Database | `ID_MINING_NICKEL_PROCESSING` |
| Service | `ID_MINING_NICKEL_PROCESSING_APP` |
| Compute pool | `SEA_DEMOS_INDONESIA_POOL` |
| Dimension table | `RAW.PROCESS_DOCS` (20 rows) |
| Fact table | `RAW.PLANT_SENSORS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | IDR (Rp) |

Regions in play: Jakarta, North Sumatra, Riau, East Kalimantan, Sulawesi
Segments: RKEF Line, HPAL Line, Smelter, Refinery

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh ID_MINING_NICKEL_PROCESSING
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| NPI Output (MTD) | `42K tonnes` | total across Process Docs |
| Recovery Rate | `89.2%` | average per event |
| Energy Cost | `Rp 847B` | total across Process Docs |
| Kilns Active | `24/28` | average per event |
| Ore Grade Avg | `1.8% Ni` | average per event |
| Slag Ratio | `12:1` | average per event |
| Specific Energy | `4.2 MWh/t` | average per event |


## Demo flow

1. Plant Overview
2. Process Analytics
3. Predictive Optimization
4. Ask AI
5. Architecture & Data

## Talking points

- **8 lines** - HPAL and RKEF processing lines across 2 sites
- **89.2% recovery** - average nickel recovery rate
- **1M readings/day** - sensor data points from all process lines
- **45 MWh/t** - energy intensity (12% above best practice)
- **120 documents** - SOPs and metallurgical reports searchable
- **Rp 180B/year** - value of closing the efficiency gap

## Business impact

- Indonesia's HPAL and RKEF plants produced 1.6Mt of nickel products in 2023 (ESDM)
- 1% improvement in nickel recovery at Indonesian scale = US$200M+ additional annual revenue (Wood Mackenzie)
- AI-driven process optimization can reduce energy consumption by 8-15% in smelting operations (McKinsey Metals)
- Battery-grade nickel commands 20-30% premium over ferronickel — quality control is critical (Benchmark Mineral Intelligence)

---
Generated from `generator/demo_specs/aws-indonesia-mining-nickel-processing.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-indonesia-mining-nickel-processing` instead.
