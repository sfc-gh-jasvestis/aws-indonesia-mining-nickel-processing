-- Generated from generator/demo_specs/aws-indonesia-mining-nickel-processing.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-indonesia-mining-nickel-processing
-- This is the schema that is actually deployed for ID_MINING_NICKEL_PROCESSING.

-- ID_MINING_NICKEL_PROCESSING  (Nickel Processing Optimization)
-- generated from generator/demo_specs/aws-indonesia-mining-nickel-processing.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS ID_MINING_NICKEL_PROCESSING;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_PROCESSING.RAW;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_PROCESSING.CURATED;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_PROCESSING.APP;
USE DATABASE ID_MINING_NICKEL_PROCESSING;

-- 5 real regions; entity names carry their region so the two always agree
