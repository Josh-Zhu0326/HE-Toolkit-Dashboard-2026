# NDMN Five-Site Local Test Dataset

This folder is an offline test snapshot built from five rows in `NDMN site metadata.xlsx` and public Environment Agency data services. It is intentionally small enough for repeatable dashboard tests and includes several identifier formats.

## Selected mappings

| Source workbook row | Biology ID | Flow ID | WQ ID | RHS survey ID |
|---:|---|---|---|---:|
| 2 | 10708 | SX26F065 | SW-81520521 | 40266 |
| 6 | 8314 | 521210 | SW-E7000500 | 39906 |
| 11 | 34310 | 2859TH | TH-PCNR0145 | 39880 |
| 16 | 90187 | 050101012 | SO-Y0004498 | 39884 |
| 40 | 54017 | 2024 | MD-25029400 | 39615 |

The selection covers alphanumeric, numeric-looking, and leading-zero flow IDs. All identifiers must be read as text. `rhs_site_id` is deliberately excluded because `rhs_survey_id` is the frozen standard identifier.

## Files

- `site_mapping_5_sites.csv`: standard mapping with HDE recorded as the flow source.
- `biology_samples_5_sites.csv`: 2015-2024 observed biological indices; no uploaded O:E values.
- `environmental_site_data_5_sites.csv`: site-level environmental predictors and proxy-alkalinity fields.
- `flow_daily_5_sites.csv`: 2020-2024 local flow contract (`flow_site_id,date,flow`).
- `wq_long_standard_5_sites.csv`: 2022-2024 WQ observations for determinands 111, 180 and 9924.
- `rhs_site_level_5_sites.csv`: RHS survey-level HMSRBB and HQA values.
- `coverage_summary.csv`: requested and returned site counts.
- `provenance.csv`: source, retrieval window, package version and processing notes.

## Public sources

- Biology and environmental data: `https://environment.data.gov.uk/ecology/explorer/downloads/`
- Flow data: `http://environment.data.gov.uk/hydrology/`
- Water quality data: `https://environment.data.gov.uk/water-quality-beta`
- RHS data: `https://environment.data.gov.uk/api/file/download`

The snapshot was produced with `hetoolkit` 2.1.3. WQ detection-limit qualifiers are preserved; no value/2 substitution or other enrichment processing has been applied.

The flow snapshot contains all 9,135 expected site-date rows. Three source flow values for `050101012` are missing and remain missing by design; the fixture does not impute raw observations.

## Rebuild and test

Run the builder only when intentionally refreshing the snapshot because it downloads national biology/environment/RHS files and makes external API requests:

```powershell
Rscript --vanilla scripts\build_ndmn_local_fixtures.R
```

Normal tests are offline:

```powershell
Rscript --vanilla tests\test_ndmn_local_fixtures.R
```

The fixtures follow the frozen Week 7 contract. The current Local File Import UI still uses legacy biology/flow validation rules; updating those validators remains a separate Data Pipeline task.
