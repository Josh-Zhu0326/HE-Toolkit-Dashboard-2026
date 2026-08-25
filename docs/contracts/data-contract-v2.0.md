# System-Level Data Contract — v2.0 (Frozen)

> Date: 25 August 2026
>
> Status: **Frozen v2.0**
>
> Freeze date: 25 August 2026
>
> Frozen scope: Sections 1–3 and the current boundaries in `DC2-01`–`DC2-06`. Section 4 topics are explicitly excluded from this freeze.
>
> Historical baseline: [Data Contract](data-contract-v1.0.md)
>
> Decision authority: [Client Decision Log v1.3](../decisions/client-decision-log-v1.md), `DEC-39`–`DEC-44` and `DEC-46`
>
> Traceability: [Requirement Traceability Matrix v2.0](requirement-traceability-matrix-v2.0.md); implementation evidence remains pending

## 1. Scope

This version records the latest client-directed changes while preserving v1.1 as the historical implementation baseline.

It covers:

- five separate local CSV types;
- independent Local and Data Explorer input paths;
- Q10/Q95 fields for lags `0`, `1`, `3`, `6`, and `12`;
- WQ operational date limits; and
- removal of non-Biology coordinate requirements.

Combined-source conflict resolution, model-predictor eligibility, and the other topics in Section 4 are deferred.

### Superseded v1 rules

| v1 rule | v2.0 rule |
|---|---|
| `DC-08`: eight lag-0/1 fields | Replaced by `DC2-03`. |
| `DC-11`: multi-sheet XLSX primary input | Replaced by `DC2-01`. |
| `DC-11`: Flow/WQ/RHS coordinates | Replaced by `DC2-04`. |
| `DC-10`: no operational WQ lower date | Amended by `DC2-05`. |

## 2. Contract Rules

### DC2-01: Five Separate CSV Inputs

CSV is the primary local-input format. Use one file for each applicable data type; a multi-sheet XLSX workbook is not required for v2.0 acceptance.

#### Biology

```text
biol_site_id
SAMPLE_ID
SAMPLE_DATE
WHPT_ASPT
WHPT_N_TAXA
LIFE_FAMILY_INDEX
PSI_FAMILY_SCORE
Month
Year
Season
```

Explicit ingestion mappings:

| CSV field | Internal field |
|---|---|
| `SAMPLE_ID` | `sample_id` |
| `SAMPLE_DATE` | `date` |
| `LIFE_FAMILY_INDEX` | `LIFE_F` |
| `PSI_FAMILY_SCORE` | `PSI_F` |
| `Month` | `month` |
| `Year` | `sampling_year` |
| `Season` | `season` |

At least one supported biological index must contain usable values. Uploaded O:E fields do not replace Dashboard-generated O:E results.

#### Site environmental

```text
biol_site_id
NGR_10_FIG
ALTITUDE
SLOPE
DIST_FROM_SOURCE
DISCHARGE
WIDTH
DEPTH
BOULDERS_COBBLES
PEBBLES_GRAVEL
SAND
SILT_CLAY
ALKALINITY
CONDUCTIVITY
MIN_SAMPLE_DATE
MAX_SAMPLE_DATE
COUNT_OF_SAMPLES
```

`NGR_10_FIG` is retained as supplied but is not automatically promoted to a new map-coordinate contract.

#### Daily Flow

```text
flow_site_id
date
flow
```

A valid local Flow file is an operational Flow source and must be usable by Flow-statistics processing.

#### Water Quality

```text
wq_site_id
date_time
det_id
qualifier
result
```

`det_id` remains a four-character identifier. `date_time` must be parseable and `result` numeric for eligible records. Unit handling continues under inherited `DC-10`.

#### RHS

```text
rhs_survey_id
HQA
HMSRBB
```

`rhs_survey_id` and `HMSRBB` remain the sole canonical identifier and condition field.

#### Shared validation boundary

- Missing required headers, duplicate headers, unreadable CSV structure, or unsafe required types block that file.
- Extra non-conflicting columns may be ignored with an informational message.
- Each CSV type requires its own example template and validation result.
- Missing optional WQ or RHS data does not block the core path.

Traceability: `DEC-40`, `DEC-44`; `RTM-01`, `RTM-15`, `RTM-18`, `RTM-29`.

### DC2-02: Input Sources

Current acceptance supports:

| Mode | Rule |
|---|---|
| `local` | Use the current validated local CSV dataset. |
| `explorer` | Use the current validated Data Explorer/import-function dataset. |

- Switching source makes the selected dataset current without deleting the retained alternative source.
- Source changes invalidate only the affected processed dataset and its descendants.
- Flow-statistics processing consumes the explicitly selected current Flow dataset, whether Local or Explorer.
- `combined` mode and automatic cross-source conflict classification are deferred until record identity keys are defined.

Traceability: `DEC-41`; `RTM-27`.

### DC2-03: Flow Fields and Lags

Supported lags:

```text
0, 1, 3, 6, 12
```

For each supported lag `L`, the canonical fields are:

```text
Q10_lagL
Q10z_lagL
Q95_lagL
Q95z_lagL
flow_window_start_lagL
flow_window_end_lagL
flow_window_duration_lagL
```

- Only requested lags need to be materialised; the request and resulting fields must be recorded.
- Q50 may remain descriptive but is outside this joined/modelling field set.
- Standardisation provenance records site grouping, centre, scale, and any failure reason.
- Raw-daily HEV mode uses `flow`, not lag fields.
- Field availability does not determine model eligibility; [Modelling Contract v2.0](modelling-contract-v2.0.md) permits only Q95z as a Q95 modelling predictor.

Traceability: `DEC-39`, `DEC-46`; `RTM-03`, `RTM-21`.

### DC2-04: Biology-Only Map Boundary

- Only Biology sites appear on the map.
- Flow, WQ, and RHS inputs do not require coordinate fields.
- Their extra coordinate columns may be ignored with an informational message.
- `site_mapping` retains identifiers needed for joins but no longer requires non-Biology coordinate pairs.
- Biology popups may use validated site ID, water body, sample count, and first/last sampling years.
- This version does not redefine the existing Biology-coordinate source.

Traceability: `DEC-43`; `RTM-18`, `RTM-22`.

### DC2-05: WQ Date Boundary

- `Build WQ summary` is a processed Stage 2 artifact.
- The earliest selectable WQ start date is `2000-01-01`.
- Earlier, reversed, or unparseable requested boundaries block the WQ request.
- Earlier raw local records may be retained for source fidelity but do not enter the current summary; report the excluded count.
- Summary provenance records requested/effective dates, source revision, exclusions, determinand rules, and generation time.

Traceability: `DEC-42`; `RTM-05`, `RTM-28`.

### DC2-06: Source Provenance

Every in-scope processed dataset records at least:

```text
data_type
source_mode
active_source_fingerprint_or_request
input_record_count
processed_output_fingerprint
generated_at
```

Source records are not overwritten. A source change creates a new output revision and fingerprint. Conflict-specific provenance activates only when deferred `combined` mode enters acceptance.

Traceability: `DEC-41`; `RTM-27`.

## 3. Inherited v1.1 Rules

Unless explicitly replaced above, the following remain active:

- `DC-01`: `rhs_survey_id` only;
- `DC-02`: daily Flow field semantics;
- `DC-03`–`DC-04`: `flow_input` and transparent HDE/NRFA fallback;
- `DC-05`–`DC-07`: optional enrichment, immutable joined layers, and non-destructive filtering;
- `DC-09`: `HMSRBB` only;
- `DC-10`: WQ determinand, unit, qualifier, and detection-limit rules; and
- `DC-12`: explicit HEV Flow modes.

XLSX may remain only as a clearly labelled compatibility adapter. It cannot define or weaken the v2.0 CSV contract.

## 4. Deferred Topics

These items are outside the current change and do not block the remaining v2.0 work:

| Topic | Current boundary |
|---|---|
| Five record identity keys | Do not implement `combined` mode or automatic conflict classification. |
| Complete CSV warning/blocker matrix | Retain existing structural safety checks. |
| Biology-coordinate authority | Retain the existing Biology-location path. |
| Missing WQ source unit | Continue inherited `DC-10`; add no new policy. |
| Biology date/year/month/season disagreement | Preserve inputs and existing validation; do not reconcile automatically. |

Deferred means not currently implemented or accepted, not resolved.

## 5. Implementation Readiness Gates

Contract freeze records the agreed in-scope data rules; it does not claim implementation or release completion. Before implementation acceptance:

1. Publish the five CSV templates.
2. Maintain RTM v2.0 requirements, acceptance criteria, and evidence states.
3. Update affected Task, dependency, UI, and modelling contracts.
4. Test the five schemas, Local/Explorer ingestion, lag fields, WQ date boundary, and non-Biology coordinate removal.
5. Obtain Data Pipeline, QA/Reproducibility, and relevant Modelling review.

## 6. Traceability Summary

| ID | Invariant | Decisions |
|---|---|---|
| `DC2-01` | Five separate CSV inputs | `DEC-40`, `DEC-44` |
| `DC2-02` | Independent Local and Explorer sources | `DEC-41` |
| `DC2-03` | Q10/Q95 fields for lags `0,1,3,6,12` | `DEC-39`, `DEC-46` |
| `DC2-04` | Biology-only map boundary | `DEC-43` |
| `DC2-05` | WQ starts no earlier than `2000-01-01` | `DEC-42` |
| `DC2-06` | Source selection remains traceable | `DEC-41` |
