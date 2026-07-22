# Week 7 Goal-Stage Path Matrix - v1

> Date: 14 July 2026
> Status: Review baseline
> Document owner: Lin (Modelling/Evaluation)
> Reviewer: Yutong (UX/Workflow)

## 1. Scope

This document maps five user Goals onto one shared five-stage workflow. Goals describe desired outcomes; Stages describe where work occurs. The Goal Selector highlights a predefined path and must not create a second navigation system or workflow engine.

Authoritative supporting specifications are the [client decision log](../client-decision-log-v1.md), [data contract](data-contract-v1.md), [modelling contract](modelling-contract-v1.md), and [requirement traceability matrix](requirement-traceability-matrix-v1.md).

## 2. Shared Workflow and Path Matrix

1. **Prepare Sites and Data**
2. **Check and Process Data**
3. **Build HE Dataset**
4. **Explore and Refine Relationships**
5. **Model and Export**

Stage 4 supports the controlled loop `explore -> filter/restore -> regenerate analysis_dataset -> re-explore`.

### Legend

- `R`: required.
- `O`: optional.
- `-`: outside the Goal path.
- `R*`: required processing whose result may be satisfied by a validated direct joined-dataset upload.

| Goal ID | User outcome | S1 | S2 | S3 | S4 | S5 | Primary output |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| `ecological_condition` | Assess ecological condition | R | R | - | O | O | RICT and calculated O:E |
| `flow_regime` | Summarise the flow regime | R | R | - | O | O | Q10/Q50/Q95 and flow provenance |
| `analysis_dataset` | Build an analysis-ready HE dataset | R | R* | R* | R | O | Versioned `analysis_dataset` |
| `hydroecological_change` | Visualise hydroecological change | R | R* | R* | R | O | HEV plot, data, and provenance |
| `flow_ecology_relationship` | Explore flow-ecology relationships | R | R* | R* | R | R | Eligible model, diagnostics, and provenance |

## 3. Common Contract Rules

### Data layers and direct upload

- The only downstream data layers are `joined_core`, optional `joined_enriched`, and `analysis_dataset`; none may overwrite another.
- Standard processing creates `joined_core` from processed biology/O:E and flow statistics. Selected valid WQ/RHS creates a separate `joined_enriched`.
- Direct `joined_dataset_optional` upload still requires Stage 1 schema validation. Its canonical core projection becomes immutable `joined_core` with upload-origin provenance; selected valid enrichment becomes separate `joined_enriched`.
- For direct upload, Stage 2-3 prerequisites are recorded as satisfied using `validated direct upload` checkpoint evidence. This is not a new workflow state and must not imply that the Dashboard performed upstream calculations.
- Every path derives `analysis_dataset` from the selected valid joined source. No filtering produces filtering version `0`.
- Direct-upload provenance records file fingerprint, schema version, source classification, and the limitation that upstream calculations cannot be reconstructed from the upload alone.

### Dependency and error scope

- Filtering or restoration rebuilds only `analysis_dataset` and makes dependent exploration, HEV, and model results stale; joined datasets remain unchanged.
- HEV and modelling always use the current valid, non-stale `analysis_dataset`.
- A stale result may remain viewable with a clear label but cannot satisfy a downstream prerequisite.
- Errors block the affected record or action first. A whole Goal is blocked only when no eligible path or output remains.
- Unselected WQ/RHS is not applicable and produces no warning state; show only an informational core-only scope notice. Missing, stale, incomplete, or failed enrichment is reported as a warning only when the user selected the corresponding enrichment, context view, or predictor.

### Common output provenance

Applicable outputs and downloads record source dataset/fingerprint, filtering version, input and output counts, selected sites/time range, exclusions, warnings, processing choices, and software/package versions.

## 4. Goal Contracts

### G01 - Ecological Condition

#### Required inputs

- `biology_samples` with at least one supported index column.
- Valid `environmental_site_data` with canonical fields and alkalinity or an approved proxy.
- Required biology-environment associations.

#### Required steps

- S1: import and preview.
- S2: validate samples/sites, flag duplicates, review environmental eligibility, run RICT, and calculate O:E.

#### Optional steps

- Review environmental PCA/outliers in S4.
- Export in S5.

#### Final outputs

- RICT predictions.
- Calculated observed/expected and O:E metrics.
- Validation summary and provenance.

#### Blocking conditions

- No supported index column or no eligible biology records after validation.
- No valid biology-environment associations.
- No candidate site satisfies the required environmental contract.

#### Record-level errors

- A record with no usable index or association receives a record-level error and is excluded; it does not block valid records.

#### Warning conditions

- Duplicate date/month-year samples.
- Alkalinity proxy use, PCA/outlier flags, or ignored user-supplied O:E.

### G02 - Flow Regime

#### Required inputs

- Valid `site_mapping` for external retrieval, or local `flow_daily` containing `flow_site_id`, `date`, and `flow`.

#### Required steps

- S1: import or retrieve flow.
- S2: assess coverage, gaps, and usability, then calculate Q10/Q50/Q95.

#### Optional steps

- Provenance-recorded imputation.
- S4 historical-range/completeness review and S5 export.

#### Recovery rule

- External retrieval attempts HDE first.
- NRFA is used only after recognised HDE no-coverage/failure, with reason, actual source, and affected sites recorded; it is not an equal-priority user-selected source.

#### Final outputs

- Q10/Q50/Q95 and coverage/completeness summary.
- Actual source, fallback reason, imputation status, and provenance.

#### Blocking conditions

- No valid external or local source.
- Missing local required fields, unusable dates/flows, or insufficient usable records for the requested statistic.

#### Warning conditions

- Gaps/incomplete coverage or applied imputation.
- Transparent NRFA fallback or mapped sites without usable observations.

### G03 - Analysis Dataset

#### Required inputs

- Standard branch: valid processed biology/O:E, processed flow, and biology-flow mapping.
- Direct branch: schema-valid `joined_dataset_optional` with required core identifiers, dates, calculated ecology, flow fields, and auditable upload provenance.

#### Required steps

- Standard branch: S1 validation -> S2 processing -> S3 `joined_core`.
- Direct branch: S1 validation -> canonical core/enrichment materialisation with validated-upload evidence.
- Both branches: derive versioned `analysis_dataset` in S4.

#### Optional steps

- Create or select `joined_enriched`.
- Filter/restore with `exclusion_log`.
- Export joined source, analysis data, summaries, and provenance.

#### Final outputs

- Immutable `joined_core` and optional versioned `joined_enriched`.
- Versioned `analysis_dataset`.
- Join, matching, missingness, and exclusion summaries.

#### Blocking conditions

- Standard branch: missing/stale processed inputs or unresolved required mapping.
- Direct branch: invalid canonical joined schema or insufficient upload provenance.
- Either branch: no valid core records or unresolved scientifically ambiguous key expansion.

#### Warning conditions

- Partial unmatched records or retained duplicates/replicates.
- Selected enrichment failure or partial coverage.
- Filtering/restoration that makes downstream results stale.

### G04 - Hydroecological Change

#### Required inputs

- Current valid, non-stale `analysis_dataset` containing matched ecological response and flow fields.
- Version `0` when no exclusions exist.

#### Required steps

- Complete or satisfy S1-S3 prerequisites.
- S4: derive/select `analysis_dataset`, confirm sites/records/time range/variables, and generate HEV from that dataset.

#### HEV eligibility rules

- Select exactly one `biol_site_id`.
- Select one or two numeric flow metrics and one to four numeric biology/O:E metrics.
- Evaluate metrics after applying the selected site and date range; a biology panel requires at least two complete finite paired time points.
- A flow metric is usable only when it has at least two finite paired values and non-zero variation.
- Skip an individual biology panel with a warning when it has fewer than two complete pairs or zero variation.
- At least one usable flow metric and one usable biology panel must remain.

#### HEV execution rules

- HEV reads the current `analysis_dataset` fingerprint/filtering version and must not mutate it, `exclusion_log`, or either joined dataset.
- Record filtering/restoration must rebuild `analysis_dataset`; display-only site/time selections are HEV parameters recorded in provenance.
- Changes to the analysis dataset, selected variables, display selection, or HEV settings make the prior HEV `stale`.
- HEV requires an explicit Generate/Regenerate action; failure affects only that action and preserves upstream data and any prior labelled result.
- A stale HEV may remain viewable with a stale label but cannot be exported as the current HEV until regenerated.

#### Optional steps

- Filter/restore and regenerate stale HEV.
- Display explicitly selected WQ/RHS context.
- Export in S5.

#### Final outputs

- HEV plot and plot data.
- `analysis_dataset`, filtering, and upstream-source fingerprints.
- Selection details and provenance.

#### Blocking conditions

- Missing, invalid, or stale `analysis_dataset`.
- The selected site count is not exactly one.
- The selected metric counts fall outside one to two flow metrics or one to four biology/O:E metrics.
- No eligible numeric flow metric or no eligible biology/O:E panel remains.

#### Warning conditions

- Incomplete flow coverage, exclusions, duplicates, proxies, or imputation affecting displayed records.
- An individual biology panel is skipped because it has fewer than two complete paired time points or zero variation.
- An unusable selected flow metric is omitted while another eligible flow metric remains.
- Selected WQ/RHS context that is missing, stale, or incomplete.

### G05 - Flow-Ecology Relationship

#### Required inputs

- Current valid, non-stale `analysis_dataset`.
- One numeric ecological response and at least one eligible numeric flow predictor.
- Valid site and sampling-year information for the selected path.

#### Required steps

- S4: review/refine analysis data.
- S5: select variables, validate eligibility, route by valid site count, then fit, diagnose, and export when eligible.

#### Optional steps

- Select up to two flow, one valid WQ, and one valid RHS predictor.
- Restore exclusions and regenerate before refitting.

#### Final outputs

- Model path/formula, coefficients, and applicable fit metrics/diagnostics.
- Analysis/exclusion summary and model/filter/source/software provenance.

#### Blocking conditions

- Missing, invalid, or stale analysis data.
- Absent, non-numeric, duplicate, or constant variables; absent/stale selected enrichment predictor; or invalid flow field for the model path.
- Predictor count exceeded, prohibited random-effects structure, insufficient complete cases, exact linear dependence, or unmet year rules.
- Mixed-model readiness or fitting failure. These conditions block the model action, not unrelated Goals or upstream results.

#### Warning conditions

- Complete-case loss from missingness/filtering.
- Explicit removal of a constant-year term or high correlation/multicollinearity under the frozen contract.
- Unselected WQ/RHS produces no warning.

#### Confirmed modelling constraints

- Single-site additive models may use eligible raw Q10/Q95 lag fields.
- Multi-site mixed-effects models may use only Q10z/Q95z lag fields.
- Mixed models permit only `(1 | biol_site_id)` or `(sampling_year_centered | biol_site_id)`.
- WQ/RHS predictors require valid corresponding enrichment in the current `analysis_dataset`.
- UI and server validation enforce identical eligibility/count rules.
- Until the mixed-model readiness gate passes, multi-site execution remains `not_ready` and must never fall back silently to pooled `lm()`.

## 5. Review Gate

The matrix may become `Frozen v1` only when:

1. Architecture/State and UX/Workflow approve every required/optional path.
2. Goal Selector, data contract, state matrix, and RTM use the same Stage 3-4 ownership and three-layer/direct-upload semantics.
3. Every blocking/warning condition maps to an approved workflow state and checkpoint without creating additional state values.
4. Case Study 2 reaches its intended core output without WQ/RHS, and the unresolved mixed-model path remains correctly `not_ready`.