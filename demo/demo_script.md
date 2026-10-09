# Indonesia Nickel Processing

**Indonesia - Nickel Ore Processing (RKEF and HPAL)**
Use case: Nickel recovery monitoring and process-upset risk

> Processing operations for a synthetic network of 24 process lines across 5 Indonesian nickel processing sites: dynamic tables, a holdout-evaluated upset-risk classifier, a nickel-recovery forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile nickel recovery, energy intensity and availability from RAW line data, with checks in `run_core.py`
- **Upset-risk classification** gives a holdout-evaluated next-7-day process-upset probability per line
- **Nickel-recovery forecast** projects 14 days of network-wide recovery with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.LINES` (24 rows) |
| Fact table | `RAW.LINE_DAILY` (2,160 line-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `UPSET_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.UPSET_RISK_SCORES`, `ML.UPSET_RISK_HOLDOUT_METRICS`, `ML.RECOVERY_FORECAST`, `ML.SETPOINT_DEV_ANOMALIES` |

Sites: Morowali, Weda Bay, Konawe, Pomalaa, Obi Island (real locations; plants, lines and operators are fictional).
Process stages: Rotary Kiln and Electric Furnace (RKEF); Autoclave, CCD Circuit and MHP Precipitation (HPAL).

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Nickel Recovery | 92.9% |
| Process Upsets | 133 |
| Energy Intensity | 0.140 MWh/t |
| Ore Processed (dry t) | 3,471,929 |
| Line Availability | 99.2% |
| Lines Monitored | 24 |
| Critical Spares Coverage | 60.7% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily nickel recovery, nickel not recovered by root cause, line table
2. Predictive: holdout metrics, risk bands, 14-day nickel-recovery forecast, setpoint deviation anomalies
3. Line Health: availability, critical spares coverage, PM compliance against nickel recovery, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-line nickel recovery ranges from 90.2% to 95.2%. Pomalaa is the lowest site, at 92.0%.
- Kiln ring build-up costs the most contained nickel of the 14 upset causes.
- The risk model is evaluated on a time-based holdout: precision 0.58 and recall 0.38 at 0.5, against a 0.31 base rate. Present it as triage, not a guarantee.
- Site-wide captive power trips are excluded from upset labels, because they are not line-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
