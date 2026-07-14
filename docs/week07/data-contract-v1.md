# Week 7 System-Level Data Contract — v1

> Date: 13 July 2026  
> Status: Frozen v1  
> Owner: Di (Data Pipeline)  
> Reviewer: Benyu (QA/Reproducibility)  
> Decision source: [Week 7 Client Decision Log](client-decision-log-v1.md)  
> Traceability source: [Week 7 Requirement Traceability Matrix](requirement-traceability-matrix-v1.md)

## 1. Purpose and Scope

This document is the system-level data contract for Dashboard v1. It aligns the core data semantics used by the template, validation, import, joining, filtering, modelling, and downloads. Its purpose is to eliminate conflicts among the legacy template, legacy helpers, UI guidance, and the latest client decisions.

This document freezes only system-level invariants that an individual module must not change independently. The complete field dictionary, units, types, allowed ranges, mixed-model data thresholds, and detailed UI wording will be frozen separately in the data dictionary, validation specification, and the [modelling contract](modelling-contract-v1.md).

## 2. Global Execution Rules

1. A canonical name in this document is the sole standard name for internal data, join keys, model selectors, provenance, and downloaded outputs.
2. Legacy fields may be handled only through compatibility rules explicitly defined in this document. Helpers and UI code must not introduce implicit aliases.
3. Downstream enrichment, filtering, or modelling must not modify upstream data layers in place.
4. Every default, fallback, compatibility conversion, data exclusion, or source change must produce user-visible information and downloadable provenance.
5. Implementation issues and tests must reference the applicable `DC-*` contract, `DEC-*` decision, and `RTM-*` requirement.

## 3. Frozen System-Level Data Invariants

### DC-01 — Sole RHS Identifier

**Specification**

- `rhs_survey_id` is the Dashboard's sole canonical RHS identifier.
- RHS is treated as site-level enrichment data.
- `site_mapping`, RHS import, `joined_enriched`, model inputs, provenance, and downloads all use `rhs_survey_id`.

**Prohibited behaviour**

- Do not use `rhs_site_id` as a standard field, alias, fallback key, or internal output.
- Do not silently convert `rhs_site_id` to `rhs_survey_id`.
- Do not infer that sites are mapped merely because biology, flow, WQ, and RHS identifier strings are equal.

**Invalid-input behaviour**

- When only `rhs_site_id` is supplied, schema validation must block RHS mapping/enrichment and instruct the user to provide `rhs_survey_id`.
- Missing RHS data must not block the biology-and-flow core path.

**Traceability**

- Decisions: `DEC-11`, `DEC-22`
- Requirements: `RTM-11`, `RTM-22`

### DC-02 — Standard Local `flow_daily` Input

**Specification**

The canonical schema for local daily-flow observations contains only:

```text
flow_site_id
date
flow
```

- `flow_site_id` must retain its original string representation, including leading zeros and alphanumeric identifiers.
- `date` represents the flow-observation date.
- `flow` represents the daily flow value; its unit and numeric validation are defined in the field dictionary.

**Prohibited behaviour**

- Local `flow_daily` must not require `flow_input`.
- If `flow_input` appears in a local flow file, it must not be used for flow-observation processing or source selection. Its warning/error treatment will be frozen in the validation specification.

**Invalid-input behaviour**

- If `flow_site_id`, `date`, or `flow` is missing, block local flow import and list the missing fields.
- A failed local flow import must not clear other uploaded data.

**Traceability**

- Decision: `DEC-15`
- Requirement: `RTM-15`

### DC-03 — `flow_input` Ownership and HDE Default

**Specification**

- `flow_input` belongs only to `site_mapping` and is used only to select an external flow source.
- The only canonical allowed values are `HDE` and `NRFA`.
- When `flow_input` is missing, blank, or not explicitly selected by the user, the system defaults to `HDE`.
- Processed site mapping must store the actual source, and provenance must record whether the default was applied.

**Invalid-input behaviour**

- A non-empty value other than `HDE` or `NRFA` must block the corresponding external flow import and list the allowed values.
- Do not silently select NRFA through fuzzy spelling, partial matching, or a legacy default.

**Traceability**

- Decisions: `DEC-12`, `DEC-15`
- Requirements: `RTM-12`, `RTM-15`

### DC-04 — Transparent NRFA Fallback

**Specification**

- HDE is the preferred source for external flow import.
- NRFA may be used only as a fallback when HDE has no coverage or HDE import fails.
- Fallback must never be silent.

**Required provenance**

```text
flow_site_id
requested_source
actual_source
fallback_applied
fallback_reason
import_status
timestamp
```

- The user-facing message must identify which sites used NRFA and why.
- If both HDE and NRFA fail, that flow import is an error, but it must not clear other successful inputs or processed results.

**Traceability**

- Decision: `DEC-12`
- Requirement: `RTM-12`

### DC-05 — WQ and RHS as Optional Enrichment

**Specification**

- WQ and RHS are optional supporting datasets added after `joined_core`.
- WQ/RHS do not participate in O:E calculation and must not become prerequisites for the biology-and-flow core path.
- When users do not supply WQ/RHS, mapping is incomplete, or enrichment fails, `joined_core` remains valid and available for exploration/export that does not depend on enrichment.
- Outputs that depend on missing WQ/RHS must remain `not_ready`. The corresponding predictors must not appear in the model selector, and server-side validation must reject attempts to bypass the UI while explaining the missing enrichment.
- If users continue along a core path that does not depend on enrichment, display a non-blocking warning. Do not fabricate, default-fill, or interpret missing values as zero.

**Traceability**

- Decision: `DEC-19`
- Requirement: `RTM-19`

### DC-06 — Three-Layer Analysis Data Boundary

**Canonical definitions**

```text
joined_core
= processed biology/O:E + processed flow statistics

joined_enriched
= a separate copy of joined_core + optional WQ/RHS enrichment

analysis_dataset
= a separately materialised modelling/exploration dataset derived from
  the selected valid joined source after user filtering
```

**Data-source selection**

- `joined_core` is the core join and must be established successfully first.
- WQ and RHS are independently selectable enrichments. If any selected source succeeds, create a separate `joined_enriched` containing only successful enrichments; never overwrite `joined_core`.
- If a selected enrichment fails, exclude that source from `joined_enriched`; record a warning, failure reason, coverage, and provenance; and retain a retry entry point.
- If every selected enrichment fails, or no enrichment is selected, do not create a new `joined_enriched`; downstream work continues from `joined_core`.
- When users choose to use successful enrichment, derive `analysis_dataset` from `joined_enriched`; otherwise derive it from `joined_core`.
- Every `analysis_dataset` must record `source_dataset`, source version/fingerprint, generation time, and current filtering version.

**Immutability rules**

- WQ/RHS enrichment changes may make only `joined_enriched`, its dependent `analysis_dataset`, and model results stale; they must not make `joined_core` stale.
- Filtering changes may rebuild only `analysis_dataset`, related exploration, and model state; they must not modify either joined dataset.

**Traceability**

- Decisions: `DEC-07`, `DEC-19`
- Requirements: `RTM-07`, `RTM-19`

### DC-07 — Filtering as a Non-Destructive Derivation

**Specification**

- Site/sample filtering must regenerate `analysis_dataset` from the currently selected valid joined source.
- Filtering must not modify or recalculate O:E, flow statistics, `joined_core`, or `joined_enriched`.
- Every exclusion must create an `exclusion_log` entry, and users must be able to restore records.

**Minimum `exclusion_log` record**

```text
record_id
site_id
sample_id
exclusion_reason
trigger
user_comment
timestamp
```

**State rules**

- A filtering change must make prior model results `stale`.
- Restoring a record must rebuild `analysis_dataset` while retaining an auditable exclusion/restoration history.
- Content comparison or fingerprints must verify that upstream joined datasets are identical before and after filtering.

**Traceability**

- Decision: `DEC-07`
- Requirement: `RTM-07`

### DC-08 — Default Joined/Modelling Flow Fields

**Canonical fields**

```text
Q10_lag0
Q10z_lag0
Q10_lag1
Q10z_lag1
Q95_lag0
Q95z_lag0
Q95_lag1
Q95z_lag1
```

**Specification**

- These eight fields are the default v1 joined/modelling flow contract.
- Joined output must also retain the corresponding flow-window/lag provenance.
- Q50 may remain available for descriptive flow-regime statistics, but it must not enter the default joined fields or model selector.
- A single-site additive model may use raw Q10/Q95 fields.
- Flow predictors in a multi-site mixed-effects model may use only Q10z/Q95z fields. Server-side validation must reject raw cross-site flow predictors submitted by bypassing the UI.

**Traceability**

- Decisions: `DEC-03`, `DEC-21`
- Requirements: `RTM-03`, `RTM-21`

### DC-09 — `HMSRBB` as the Sole Internal and Output Field

**Specification**

- `HMSRBB` is the canonical field name for the RHS condition variable.
- The template, internal data, `joined_enriched`, `analysis_dataset`, model selector, formula/provenance, and every download may use only `HMSRBB`.
- `HMSRBB` is eligible as a controlled RHS predictor.

**Legacy compatibility**

- When only `HMS.Score` exists, accept the input, perform a one-way rename to `HMSRBB`, and display a compatibility warning.
- When only `HMSRBB` exists, accept it without a legacy warning.
- When both fields exist and their values are identical, retain `HMSRBB`, remove the legacy field, and display a duplicate-compatibility warning.
- When both fields exist and their values conflict, block continuation and require user correction.
- Provenance records only whether the legacy rename was performed and its warning; it must never re-emit `HMS.Score`.

**Traceability**

- Decision: `DEC-20`
- Requirement: `RTM-20`

### DC-10 — WQ Determinand, Unit, and Detection-Limit Normalisation

**Canonical registry**

| V1 summary field | Canonical `det_id` | Canonical determinand | Canonical unit | Aggregation |
|---|---|---|---|---|
| `orthophosphate_mean` | `0180` | `Orthophosphate reactive as P` | `mg/L` | mean |
| `ammonia_p90` | `0111` | `Ammoniacal Nitrogen as N` | `mg/L` | P90 |
| `dissolved_oxygen_p10` | Pending `OPEN-02`: `9901` or `9924` | Do not guess before confirmation | Do not assume before confirmation | P10 |

**Identifier rules**

- `det_id` is required in input and must be stored as a four-character string in validated, processed, joined, provenance, and downloaded data.
- Numeric `180`, character `"180"`, and character `"0180"` may all be explicitly normalised to `"0180"`; `111`, `"111"`, and `"0111"` are similarly normalised to `"0111"`.
- `det_id` is the matching key. Do not silently determine a summary type from determinand display text alone.
- `0119` (un-ionised ammonia) is a different determinand from `0111`. It may remain in raw WQ data, but it must not be used for `ammonia_p90`, converted to `0111`, or listed as an alias of `0111`.
- When `det_id` and determinand text clearly conflict, block that record from enrichment and report the ID, text, and allowed canonical mapping.

**Display-name and unit normalisation**

- Recognised package display aliases for `0180` include `Orthophosphate, reactive as P` and `Orthophospht`; standard output uses only `Orthophosphate reactive as P`.
- The recognised package display alias for `0111` includes `Ammonia(N)`; standard output uses only `Ammoniacal Nitrogen as N`.
- Unit aliases `mg/L`, `mg/l`, and `MILLIGRAM PER LITRE` are normalised to `mg/L`.
- A unit outside this registry must not be converted silently. The record must not enter the corresponding summary and must produce an actionable validation error.
- Processed WQ must retain at least `source_result`, `source_unit`, `source_qualifier`, `analysis_value`, `canonical_unit`, `normalization_applied`, and `normalization_reason`.

**Detection-limit and three-year-window rules**

- When the source qualifier denotes a below-detection-limit result, set `analysis_value = source_result / 2`; ordinary observations retain their original value.
- Summaries use only `analysis_value`, but source result, qualifier, and transformation provenance must remain downloadable and reversible.
- V1 uses a fixed rolling three-calendar-year window anchored to each biology record's `sampling_year`. For `sampling_year = Y`, include WQ observations whose calendar year is `Y - 2`, `Y - 1`, or `Y`; equivalently, the inclusive boundaries are 1 January of `Y - 2` and 31 December of `Y`.
- Records outside those inclusive calendar-year boundaries must not enter the summary. A missing, blank, or unparseable `sampling_year` blocks WQ matching for that biology record and produces a field-level error without invalidating `joined_core`.
- `orthophosphate_mean` uses the mean, and `ammonia_p90` uses the default type 7 from R `quantile(..., probs = 0.90)`.

**Traceability**

- Decisions: `DEC-05`, `DEC-06`, `DEC-24`
- Requirements: `RTM-05`, `RTM-06`, `RTM-18`, `RTM-24`

### DC-11 — XLSX v1 Canonical Sheet/Column Order

**Ownership and version rules**

- XLSX sheet names, column names, and column order are a `TEAM-V1` data contract and do not require client confirmation field by field.
- The importer must validate names and order against the schema version. The difference report must list missing, unexpected, and out-of-order fields.
- A legacy workbook may enter an explicit migration/compatibility path, but it must not change the v1 canonical order.
- The following is the frozen v1 order. Rows from the same sheet may be bound only when names and order match exactly.

**`site_mapping`**

```text
biol_site_id, biol_easting, biol_northing,
flow_site_id, flow_easting, flow_northing, flow_input,
wq_site_id, wq_easting, wq_northing,
rhs_survey_id, rhs_easting, rhs_northing
```

**`biology_samples`**

```text
biol_site_id, sample_id, date, sampling_year, season, month,
sample_type, sample_method,
WHPT_ASPT, WHPT_NTAXA, LIFE_F, PSI_F, notes
```

- The uploaded sheet must not contain O:E fields; the Dashboard generates O:E after processing.
- At least one of `WHPT_ASPT`, `WHPT_NTAXA`, `LIFE_F`, or `PSI_F` must be supplied as a supported index.
- `sampling_year` is the sole canonical year field in uploaded, processed, and joined biology data. `sample_year` must not be accepted or generated as an alias.

**`environmental_site_data`**

```text
biol_site_id, WATER_BODY, NGR_PREFIX, EASTING, NORTHING,
WFD_WATERBODY_ID, ALTITUDE, SLOPE, DIST_FROM_SOURCE,
DISCHARGE, WIDTH, DEPTH, BOULDERS_COBBLES, PEBBLES_GRAVEL,
SAND, SILT_CLAY, ALKALINITY, CONDUCTIVITY,
TOTAL_HARDNESS, CALCIUM, notes
```

- `NGR_PREFIX` is required and must match this exact case. `NGR_prefix` must not be accepted or generated as an alias.

**`flow_daily`**

```text
flow_site_id, date, flow
```

**`wq_long_standard`**

```text
wq_site_id, wq_site_name, date_time, det_id, determinand,
result, unit, qualifier, observation, notes
```

- Site coordinates and `area` must not appear in this observation-level sheet.

**`rhs_summary`**

```text
rhs_survey_id, biol_site_id, survey_date, HMSRBB, HMS.Class,
HQA, HQA.Adjusted, Hms.Poaching.Sub.Score,
Bed.Material.Description, Predominant.Flow.Type, habitat_notes
```

**`joined_dataset_optional` (derived/export order)**

```text
biol_site_id, sample_id, date, flow_site_id, wq_site_id, rhs_survey_id,
sampling_year,
WHPT_ASPT_OE, WHPT_NTAXA_OE, LIFE_F_OE, PSI_OE,
Q10_lag0, Q10z_lag0, Q10_lag1, Q10z_lag1,
Q95_lag0, Q95z_lag0, Q95_lag1, Q95z_lag1,
flow_window_start_lag0, flow_window_end_lag0, flow_window_duration_lag0,
flow_window_start_lag1, flow_window_end_lag1, flow_window_duration_lag1,
wq_window_start, wq_window_end, wq_window_duration_years,
orthophosphate_mean, orthophosphate_record_count,
ammonia_p90, ammonia_record_count,
dissolved_oxygen_p10, dissolved_oxygen_record_count,
HMSRBB, HQA, matching_notes
```

- `dissolved_oxygen_p10` and its count column may be reserved in the schema, but they must remain `not_ready` and must not contain guessed values until `OPEN-02` is closed.
- `sampling_year_centered` is not stored in `joined_core` or `joined_enriched`. It is derived from the current `analysis_dataset` at modelling time using DEC-09, so filtering may change the centring reference without modifying either joined layer. The centred value, reference midpoint, valid-year range, and fitted formula must be retained in model provenance and model downloads.
- `field_dictionary` and `validation_rules` are metadata sheets and do not participate in observation row-binding; their internal order is managed by their corresponding versioned table structures.

**Traceability**

- Decisions: `DEC-01`, `DEC-09`, `DEC-14`, `DEC-15`, `DEC-18`, `DEC-22`, `DEC-25`
- Requirements: `RTM-01`, `RTM-09`, `RTM-14`, `RTM-15`, `RTM-18`, `RTM-22`

## 4. Data Flow and Immutable Boundaries

```text
raw/local/external inputs
        |
        v
validated and processed biology/environment/flow
        |
        v
joined_core ---------------------------------------+
        |                                          |
        | optional WQ/RHS enrichment               | no enrichment selected
        v                                          |
joined_enriched                                    |
        |                                          |
        +--------------------+---------------------+
                             |
                             | derive + filter; never mutate source
                             v
                     analysis_dataset
                             |
                             v
                    exploration / modelling
```

### Boundaries That Must Not Be Crossed

- Import/validation must not automatically start expensive downstream calculations.
- Enrichment must not overwrite or damage `joined_core`.
- Filtering must not write back to either joined dataset.
- Modelling must not modify `analysis_dataset` or upstream data.
- Prior results may remain viewable, but a result in `stale` state must not continue as downstream input.

## 5. Contract Verification Gate

This document may move from a review baseline to `Frozen v1` only when all of the following are true:

1. Every contract from `DC-01` through `DC-11` has corresponding `DEC-*` and `RTM-*` references.
2. Every canonical field has exactly one meaning and one standard name in this document.
3. Input, internal data, downloads, and model selectors contain no conflicting legacy contract such as `rhs_site_id`, local `flow_input`, default Q50, or output `HMS.Score`.
4. Automated or reproducible manual tests can verify the sources, mutability, and stale boundaries of `joined_core`, `joined_enriched`, and `analysis_dataset`.
5. The Data Pipeline owner and reviewer have reviewed this contract, and every exception is recorded as a new decision/open item rather than an undocumented implementation deviation.

## 6. Subsequent Content Not Frozen by This Document

- Complete authoritative units, allowed values, and conditional-validation metadata for environmental fields and other non-WQ measurement fields.
- The exact `det_id`, canonical name, and unit for dissolved-oxygen P10, managed by `OPEN-02`.
- Whether CSV fallback enters formal v1 acceptance.
- Minimum site/sample thresholds and singular-fit/non-convergence behaviour for mixed-effects models, currently tracked in the [modelling-contract review baseline](modelling-contract-v1.md).
- Detailed warning/error wording, UI layout, and checkpoint styling.

These items must be frozen in the applicable data dictionary, validation specification, `OPEN-02`, `OPEN-03`, `OPEN-06`, or [modelling contract](modelling-contract-v1.md). Implementers must not decide them implicitly in code.

## 7. Traceability Summary

| Contract ID | System invariant | Decision | Requirement |
|---|---|---|---|
| `DC-01` | RHS uses only `rhs_survey_id` | `DEC-11`, `DEC-22` | `RTM-11`, `RTM-22` |
| `DC-02` | Local `flow_daily` contains only three canonical fields | `DEC-15` | `RTM-15` |
| `DC-03` | `flow_input` belongs only to `site_mapping`; HDE is the default | `DEC-12`, `DEC-15` | `RTM-12`, `RTM-15` |
| `DC-04` | NRFA fallback is transparent and recorded in provenance | `DEC-12` | `RTM-12` |
| `DC-05` | WQ/RHS are optional enrichment only | `DEC-19` | `RTM-19` |
| `DC-06` | `joined_core → joined_enriched → analysis_dataset` data-layer boundary | `DEC-07`, `DEC-19` | `RTM-07`, `RTM-19` |
| `DC-07` | Filtering rebuilds only `analysis_dataset` | `DEC-07` | `RTM-07` |
| `DC-08` | Eight raw/Z-score Q10/Q95 lag fields | `DEC-03`, `DEC-21` | `RTM-03`, `RTM-21` |
| `DC-09` | Internal data and outputs use only `HMSRBB` | `DEC-20` | `RTM-20` |
| `DC-10` | WQ determinand, four-character ID, unit aliases, detection limit, and summary contract | `DEC-05`, `DEC-06`, `DEC-24` | `RTM-05`, `RTM-06`, `RTM-18`, `RTM-24` |
| `DC-11` | XLSX v1 canonical sheet/column order | `DEC-01`, `DEC-09`, `DEC-14`, `DEC-15`, `DEC-18`, `DEC-22`, `DEC-25` | `RTM-01`, `RTM-09`, `RTM-14`, `RTM-15`, `RTM-18`, `RTM-22` |
