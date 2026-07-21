# NDMN Local Fixture Test Report

Owner: Bo Sun

Date: 21 July 2026

Status: Offline fixture suite complete

## Purpose

This report records the construction and verification of a small local-data snapshot based on `NDMN site metadata.xlsx`. The snapshot supports reproducible tests without repeatedly calling Environment Agency services.

## Selection

Five source rows were deliberately selected to cover different identifier formats rather than to estimate population statistics:

- alphanumeric HDE ID: `SX26F065`;
- numeric-looking HDE IDs: `521210` and `2024`;
- suffix HDE ID: `2859TH`;
- leading-zero HDE ID: `050101012`.

All biology, flow, WQ and RHS identifiers are stored and tested as text. The standard mapping contains `rhs_survey_id` only.

## Downloaded Snapshot

| Dataset | Window | Rows | Requested IDs | Returned IDs |
|---|---|---:|---:|---:|
| Site mapping | Static | 5 | 5 | 5 |
| Biology samples | 2015-01-01 to 2024-12-31 | 107 | 5 | 5 |
| Environmental site data | Static | 5 | 5 | 5 |
| HDE daily flow | 2020-01-01 to 2024-12-31 | 9,135 | 5 | 5 |
| WQ long data | 2022-01-01 to 2024-12-31 | 520 | 5 | 5 |
| RHS site-level data | Static | 5 | 5 | 5 |

Data were downloaded with `hetoolkit` 2.1.3. The builder and exact source notes are stored with the fixtures.

## Data Quality Results

- Every requested ID returned records in its corresponding dataset.
- The flow file contains all 1,827 dates for each of five sites, giving 9,135 site-date rows.
- Three source flow values for `050101012` are missing. They remain missing; no imputation was applied to the raw fixture.
- WQ determinands are `0111`, `0180` and `9924`.
- WQ qualifier `<` is present and preserved. Detection-limit values were not halved or otherwise transformed.
- WQ coordinates were removed from the observation-level file.
- RHS dates were explicitly parsed from source `d-m-y` strings and stored as ISO `YYYY-MM-DD` values.
- `HMSRBB` is sourced from `Hms.Rsctned.Bnk.Bed.Sub.Score`.
- Biology files contain observed indices only and do not include uploaded O:E values.

## Offline Test Coverage

`tests/test_ndmn_local_fixtures.R` verifies:

- exact mapping schema and all five identifier families;
- leading-zero preservation through the dashboard CSV readers;
- at least one supported biological index per sample;
- the environmental alkalinity-or-proxy condition;
- complete flow date-site coverage and retained missing values;
- WQ schema, determinands, qualifier and coordinate exclusions;
- RHS survey identifier, ISO date, HMSRBB and HQA fields;
- WQ and RHS mapping back to `biol_site_id`;
- WQ time-series and RHS numeric plot creation using real local records;
- coverage and provenance metadata.

## Result

The real local fixture test passed. Existing helper, plotting and workflow-state regression tests also remained green during the fixture implementation.

## Known Integration Boundary

The fixtures implement the frozen Week 7 contracts. The current `Local File Import` and supporting mapping validators still contain legacy requirements (`rhs_site_id`, local `flow_input`, and taxon/abundance biology columns). Therefore:

- the fixture suite is ready for offline development and helper-level tests;
- WQ/RHS mapped plotting works with the real fixture records;
- direct UI upload of every frozen-contract file requires the separate Data Pipeline schema correction before it can be claimed as complete.

No O:E, HEV, WQ/RHS import, local-import, or modelling calculation was modified in this fixture PR.
