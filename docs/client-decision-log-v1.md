# Week 7 Client Decision Log

> Scope: v1 decisions frozen from client feedback available by 13 July 2026.
>
> Controlled update: v1.1 adds the 17 and 21 July 2026 UI direction, terminology, and extension decisions without rewriting the historical Week 7 baseline.

## Version History

| Version | Date | Change |
|---|---|---|
| v1.0 | 2026-07-17 | Week 7 client-decision baseline. |
| v1.1 | 2026-07-21 | Added the confirmed Option A direction, Task terminology, eight wording replacements, extension priorities, and the ethics-status resolution. |

## 1. Decision Rules and Sources

The latest client confirmation overrides only conflicting older assumptions; earlier feedback remains valid where it is consistent.

| Basis | Meaning |
|---|---|
| `CLIENT` | Explicit client requirement or confirmation |
| `TEAM-V1` | Team-selected v1 default within an option accepted by the client |
| `INTERNAL` | Engineering, QA, or traceability safeguard added by the team |

| Source | Feedback record |
|---|---|
| `SRC-01` | [Upload, WQ, modelling, and volunteer testing](../../../ProjectInfo/client_feedback/2026-07-13_time-unknown-upload-wq-and-modelling-requirements.md) |
| `SRC-02` | [RHS, HDE, and WQ testing guidance](../../../ProjectInfo/client_feedback/2026-07-13_092000_rhs-hde-and-wq-testing-guidance.md) |
| `SRC-03` | [Data template and dependency map](../../../ProjectInfo/client_feedback/2026-07-10_122900_data-template-and-dependency-map.md) |
| `SRC-04` | [Local upload and whiteboard clarification](../../../ProjectInfo/client_feedback/2026-07-07_142800_local-data-upload-and-whiteboard-files.md) |
| `SRC-05` | HE Toolkit package [`import_wq()` documentation/implementation](../../../HE-Toolkit-Shiny-UI-APEM-LTD/R/import_wq.R) and [Case Study 1 WQ rules](../../../HE-Toolkit-Shiny-UI-APEM-LTD/vignettes/CaseStudy1.Rmd) |
| `SRC-06` | [UI direction and extension prioritisation](../../../ProjectInfo/client_feedback/2026-07-17_102650_ui-direction-and-extension-prioritisation.md) |
| `SRC-07` | [UI wording and extension priorities](../../../ProjectInfo/client_feedback/2026-07-21_115543_ui-wording-and-extension-priorities.md) |

## 2. Final Decisions

| ID | Final decision | Basis | Source | Required action |
|--|---|---|---|---|
| DEC-01 | Use one multi-sheet XLSX as the primary local upload; sheets are optional. CSV remains a compatibility fallback, not an equal-priority path. | `CLIENT + TEAM-V1` | `SRC-01` | Replace CSV-first specifications and update the template/importer contract. |
| DEC-02 | Require at least one supported biological index; do not require both `WHPT_ASPT` and `LIFE_F`. | `CLIENT` | `SRC-01` | Add cross-field validation. |
| DEC-03 | Default joined/modelling fields are the eight raw/Z-score Q10/Q95 lag 0/1 fields. Q50 may remain descriptive but is not a default joined/model field. | `CLIENT + INTERNAL` | `SRC-01` | Replace the previous six-field contract and update schema, selectors, provenance, and tests. |
| DEC-04 | Remove `area` from the Dashboard schema. | `CLIENT` | `SRC-01` | Remove it from templates, validation, and documentation. |
| DEC-05 | V1 uses a fixed rolling three-calendar-year WQ window. For a biology record with `sampling_year = Y`, include WQ observations from calendar years `Y - 2`, `Y - 1`, and `Y`, with both boundaries inclusive. Summaries are orthophosphate mean, ammonia P90, and dissolved oxygen P10. | `TEAM-V1 + CLIENT` | `SRC-01 + SRC-05` | Freeze and test the window boundaries and determinand-specific rules. |
| DEC-06 | Transform below-detection-limit WQ values using `value / 2`; retain the original qualifier and transformation provenance. | `CLIENT + INTERNAL` | `SRC-01` | Define transformed fields, warnings, and tests. |
| DEC-07 | Filtering changes only `analysis_dataset`; it must not recalculate O:E, flow statistics, `joined_core`, or `joined_enriched`. | `CLIENT` | `SRC-01` | Implement non-destructive filtering and `exclusion_log`. |
| DEC-08 | Use an additive model for single-site data and a mixed-effects model for multi-site data. | `CLIENT` | `SRC-01` | Define and validate two modelling paths. |
| DEC-09 | V1 allows up to two flow, one WQ, and one RHS predictor; calculate `sampling_year_centered = sampling_year - (min_year + max_year) / 2`. When at least two distinct valid years exist, applicable single-site and multi-site models include `sampling_year_centered` by default. Missing, entirely blank, or unparseable years block execution; partial missingness uses complete-case exclusion with a reported count; a constant year produces a warning, explicit removal of the year term, and a provenance record. | `TEAM-V1 + CLIENT` | `SRC-01` | Enforce predictor limits, verify the centred calculation and fitted formula, and test missing, invalid, partially missing, and constant-year behaviour. |
| DEC-10 | Mixed models allow only `(1 \| biol_site_id)` or `(sampling_year_centered \| biol_site_id)`. The latter is the internal midpoint-centred implementation of the client's conceptual `(sampling_year \| biol_site_id)` structure and uses the field defined in DEC-09. | `CLIENT + INTERNAL` | `SRC-01` | Restrict choices to the two actual fitted structures and validate model inputs. |
| DEC-11 | Define `rhs_survey_id` as the Dashboard's sole canonical RHS identifier and treat RHS as site-level enrichment. A mapping containing only `rhs_survey_id` passes. A mapping containing only `rhs_site_id` fails with an instruction to use `rhs_survey_id`. A mapping containing both fields fails with an instruction to remove `rhs_site_id`, regardless of whether their values match. Internal data, mappings, model inputs, provenance, and downloads retain only `rhs_survey_id`; the Dashboard must never silently convert `rhs_site_id` to `rhs_survey_id`. An external RHS interface field named `Survey.ID` may be explicitly renamed to `rhs_survey_id` at the ingestion boundary, after which `Survey.ID` must not persist as an internal alias. | `CLIENT + INTERNAL` | `SRC-02` | Remove `rhs_site_id` aliases and fallback behaviour; enforce the three mapping-input cases; implement the explicit `Survey.ID` ingestion-boundary rename; verify that internal data, mappings, model inputs, provenance, and downloads contain only `rhs_survey_id`. |
| DEC-12 | HDE is the default flow source; NRFA is used only for missing coverage or failure, with the reason and actual source recorded. | `CLIENT + INTERNAL` | `SRC-02` | Update defaults, messages, provenance, and tests. |
| DEC-13 | Normal WQ tests use fewer than 10 sites; 49 sites are stress/performance only. Maintain fixed 5/10/20/49-site fixtures. | `CLIENT + INTERNAL` | `SRC-02` | Create reproducible fixtures and separate normal from stress criteria. |
| DEC-14 | Row-bind local data only after column-name and column-order validation; expose final bound datasets, not import intermediates. | `CLIENT` | `SRC-04` | Add schema/order checks and remove intermediate-download requirements. |
| DEC-15 | Local `flow_daily` contains only `flow_site_id`, `date`, and `flow`; `flow_input` belongs only in `site_mapping`. | `CLIENT` | `SRC-03` | Update workbook schema and validation. |
| DEC-16 | Users do not upload O:E; the Dashboard calculates it after biology/environment validation and processing. | `CLIENT` | `SRC-03` | Remove O:E from uploads and define handling of unexpected O:E columns. |
| DEC-17 | Require canonical `NGR_PREFIX`, matching the HE Toolkit environmental import interface; the client's `NGR_prefix` wording refers to this same field and does not create an alias. Allow blank `ALKALINITY` only when `CONDUCTIVITY`, `TOTAL_HARDNESS`, or `CALCIUM` supports proxy estimation. | `CLIENT + INTERNAL` | `SRC-03 + SRC-05` | Add exact-name validation, conditional validation, and unit guidance. |
| DEC-18 | Require WQ `det_id`; store WQ/RHS coordinates in `site_mapping`, not observation-level WQ data. | `CLIENT` | `SRC-03` | Move fields and update template/validation. |
| DEC-19 | Build `joined_core` from processed biology/O:E and flow first; optionally create `joined_enriched` with WQ/RHS without invalidating the core on enrichment failure. | `CLIENT + INTERNAL` | `SRC-03` | Separate core join and enrichment operations, states, and tests. |
| DEC-20 | Apply one explicit, one-way normalisation from legacy `HMS.Score` to `HMSRBB` and display a compatibility warning; internal data and every output retain only `HMSRBB`. If both fields exist with identical values, retain `HMSRBB` and remove the legacy field; conflicting values block continuation. `HMSRBB` is available for controlled RHS predictor selection. | `CLIENT + INTERNAL` | `SRC-01` | Use only `HMSRBB` in the schema, template, joined data, model selector, downloads, and provenance; test legacy-only, new-only, matching dual fields, and conflicting dual fields. |
| DEC-21 | Single-site models may use raw Q10/Q95 predictors; multi-site mixed-effects models must use the Z-score-standardised Q10z/Q95z lag fields. | `CLIENT` | `SRC-01` | Separate eligible flow predictors by model path and reject raw cross-site flow predictors. |
| DEC-22 | `site_mapping` must hold separate easting/northing pairs for biology, flow, WQ, and RHS sites; RHS mapping uses `rhs_survey_id`. | `CLIENT` | `SRC-03` | Add and validate all four coordinate pairs without assuming that IDs or locations are equal. |
| DEC-23 | Multiple biology samples from the same site on the same date or in the same month-year produce a warning/flag only; the Dashboard must not automatically reject, delete, or aggregate them. If the user aggregates replicates, record the method. | `CLIENT + TEAM-V1` | `SRC-03` | Add duplicate-period detection, user-visible warnings, and aggregation provenance tests. |
| DEC-24 | Store WQ `det_id` as a four-character string in v1. Orthophosphate uses `0180` (`Orthophosphate reactive as P`, canonical unit `mg/L`) with the mean; ammonia uses `0111` (`Ammoniacal Nitrogen as N`, canonical unit `mg/L`) with P90. `0119` (un-ionised ammonia) is a different determinand and must not be treated as an alias of `0111` or silently included in ammonia P90. Normalise input unit aliases `mg/L`, `mg/l`, and `MILLIGRAM PER LITRE` to `mg/L`, while preserving the source value, source unit, qualifier, and normalisation provenance. | `TEAM-V1 + INTERNAL` | `SRC-01 + SRC-05` | Update the WQ registry, schema, normalisation, enrichment, and tests; the exact dissolved-oxygen determinand remains under the narrowed `OPEN-02`. |
| DEC-25 | XLSX sheet and column order is a versioned team data contract, not a client-confirmation item. The v1 importer validates the canonical order in `data-contract-v1.md`; the legacy workbook is migration input and cannot override the frozen schema. | `TEAM-V1 + INTERNAL` | `SRC-01 + SRC-03 + SRC-04` | Update the template, field dictionary, importer, order-difference messages, and row-bind tests to the frozen order. |

## 3. Controlled Update - 2026-07-21

The following decisions supplement the Week 7 baseline. They do not retrospectively alter the wording or status recorded in the original decisions above.

| ID | Final decision | Basis | Source | Required action |
|--|---|---|---|---|
| DEC-26 | Use Option A, the guided five-stage workflow, as the single primary workflow direction. Task selection may expose the appropriate five-stage route but must not create a competing navigation system. Preserve reusable completed outputs when users move between Tasks. | `CLIENT + INTERNAL` | `SRC-06 + SRC-07` | Integrate the Option A structure into the real Shiny application and derive Task/stage guidance from one shared configuration and runtime state. |
| DEC-27 | Use `Task`, not `Goal`, in all user-facing workflow labels, guidance, help text, tests of visible wording, and participant materials. Stable internal identifiers such as `goal_id` may remain where renaming would add compatibility risk, provided they are never presented to users. | `CLIENT + INTERNAL` | `SRC-07` | Replace visible `Goal` wording; keep any retained internal identifier explicitly documented as implementation-only. |
| DEC-28 | Apply the eight client-confirmed wording replacements in the controlled wording register below. Internal objects such as `analysis_dataset` may retain stable technical names, but those names must not be used as user-facing Task or output labels. | `CLIENT + INTERNAL` | `SRC-07` | Update the prototype-to-Shiny mapping, UI text, help text, visible-wording tests, and pilot materials. |
| DEC-29 | Explain flow-source behaviour in plain language: NRFA is an alternative flow-data source for sites not available through HDE. Do not show the unexplained phrase `NRFA fallback` to users; continue recording the actual source and reason internally. | `CLIENT + TEAM-V1` | `SRC-06 + SRC-07` | Use `Data source` and, where transformation history is shown, `Data history`; retain structured source/fallback fields in internal provenance. |
| DEC-30 | Local biology, flow, WQ, and RHS file import is required. A general-purpose workspace for adding, editing, merging, deleting, or renaming whole datasets is not required; image-data support is also out of scope. | `CLIENT` | `SRC-07` | Implement the agreed local-file contracts and retain record-level Task 4/5 refinement without building a general dataset manager. |
| DEC-31 | Provide processed-dataset download checkpoints and allow a processed dataset to be uploaded in a later session for Tasks 4 and 5. Direct automatic in-session hand-off is useful but not essential when download/re-upload provides a clear route. | `CLIENT + TEAM-V1` | `SRC-06 + SRC-07` | Treat download/re-upload as the v1 continuity path; preserve automatic hand-off as a separately prioritised enhancement. |
| DEC-32 | Tasks 4 and 5 are iterative. Users may filter or restore individual sites and samples and regenerate HEV outputs; modelling users may change predictors, re-fit, and retain enough history to compare model results. Upstream processed and joined data must remain non-destructive. | `CLIENT + INTERNAL` | `SRC-07` | Implement record-level exclusion/restoration, precise stale propagation, re-plot/re-fit behaviour, and auditable data/model history. |
| DEC-33 | Detect same-site, same-day biology, flow, and WQ duplicates and require an explicit user decision to retain, average, or remove records. Do not silently aggregate or delete duplicates. Detailed averaging and selection rules remain open where more than two or non-numeric records are involved. | `CLIENT + INTERNAL` | `SRC-07` | Add duplicate detection and an explainable blocker until the user chooses an eligible resolution; close the remaining scientific rules before implementing averaging. |
| DEC-34 | A colour-coded site-pairing map, a user guide/home page, constrained GAMs, selectable downloadable Task 4/5 reports, multiple flow-statistic windows, and raw-daily-flow/processed-statistic HEV display options are useful additions. They do not override the frozen core workflow or enter v1 acceptance without explicit prioritisation and acceptance criteria. | `CLIENT + INTERNAL` | `SRC-07` | Keep each addition as a separately scoped backlog item with dependencies, tests, and a report destination. |
| DEC-35 | The canonical internal Task identifier field is `task_id`. Its frozen ordered values are `ecological_condition`, `flow_regime`, `build_he_dataset`, `generate_hev`, and `he_modelling`. For the current implementation, this resolves DEC-27's conditional compatibility allowance in favour of `task_id`. The legacy `goal_id` field and earlier Goal IDs remain only in preserved historical documents; active configuration and runtime code do not maintain a second alias. | `TEAM-V1 + INTERNAL` | `SRC-07` | Enforce the exact identifier field, values, and order in automated tests; require controlled change and compatibility review before any future rename. |
| DEC-36 | Task 3 completes at its Stage 3 processed-dataset checkpoint. Stage 4 exploration/refinement is optional for Task 3 and remains required for iterative Tasks 4 and 5. | `TEAM-V1 + INTERNAL` | `SRC-07` | Use the Task 3 path `R, R, R, O, O`; exclude `analysis_dataset` from its Required artifacts; consume `processed_dataset_checkpoint` as its runtime completion artifact. |

### Controlled User-Facing Wording Register

| Previous wording | Confirmed user-facing wording |
|---|---|
| `Goal` | `Task` |
| `RICT and calculated O:E` | `Expected values and O:E ratios` |
| `Create separate core, enriched and filtered analysis layers` | `Join biomonitoring indices with flow statistics and other environmental data` |
| `Versioned analysis_dataset` | `Joined HE dataset` |
| `Visualise hydroecological change` | `Generate HEV plots` |
| `Generate an HEV view from a current, traceable analysis dataset` | `Produce HEV plots with daily flows or flow statistics` |
| `Explore flow-ecology relationships` | `Undertake HE modelling` |
| `Explore variables and fit an eligible multiple-predictor model` | `Fit, compare and visualise regression-based HE models` |

## 4. Deferred and Open Items

### Deferred beyond v1

| ID | Deferred feature | V1 alternative |
|---|---|---|
| DEF-01 | Configurable one-, two-, and three-year WQ windows | Fixed inclusive calendar-year window from `Y - 2` through `Y`, as defined in DEC-05 |
| DEF-02 | Flow–RHS interactions | Additive fixed effects |
| DEF-03 | General interactions and automatic predictor selection | Controlled manual selection |
| DEF-04 | GAM-based WQ prediction | Confirmed WQ summaries |
| DEF-05 | Map-based site pairing | Explicit ID mapping |
| DEF-06 | AI model interpretation | Fixed assumptions, warnings, and limitations |

### Open items

| ID | Question | Interim rule | Owner/deadline |
|---|---|---|---|
| OPEN-01 | Closed: ownership and v1 canonical XLSX column order | Follow `DEC-25` and the data contract; the team maintains authoritative environmental-unit guidance from RICT/package sources rather than treating it as a client-confirmation item | Closed — `DEC-25` |
| OPEN-02 | Exact dissolved-oxygen determinand for P10: `9901` (% saturation) or `9924` (O2, `mg/L`) | Do not guess, merge, or interchange them before client confirmation; orthophosphate `0180` and ammonia `0111` may be implemented independently | Zhaohang (Documentation/Client); confirm only this scientific semantic |
| OPEN-03 | Whether CSV fallback enters formal v1 acceptance | Treat it as compatibility-only | Freeze at Week 7 review |
| OPEN-04 | Availability and final count of six EA volunteers | Prepare an availability poll and participant information | Zhaohang (Documentation/Client) |
| OPEN-05 | Ethical approval by 21 July | Do not start formal research without approval | Go/no-go on 21 July |
| OPEN-06 | Minimum data conditions and failure handling for mixed-effects models | A [modelling-contract review baseline](modelling-contract-v1.md) exists, but do not mark the mixed-model path ready or `Verified` until every `MC-O*` item is reviewed and the contract is frozen; the single-site additive path may proceed independently | Lin (Modelling/Evaluation); resolve by freezing minimum sites, per-site/total complete cases, random-slope repeated observations, scaling/missingness rules, convergence/singularity handling, R²/reference parity, and warning/error/export boundaries |
| OPEN-07 | Exact placement of the user guide/home page | It must support, not compete with, the Option A primary navigation | UX/Workflow owner; resolve before implementation |
| OPEN-08 | GAM families, smoothing controls, diagnostics, and comparison outputs | Do not infer unsupported scientific defaults from the Case Study 2 example | Modelling/Evaluation owner; obtain client/scientific review |
| OPEN-09 | Whether three flow-statistic windows is a fixed maximum | Treat three as a recommendation, not a confirmed acceptance limit | Documentation/Client owner |
| OPEN-10 | Duplicate selection and averaging rules for more than two or non-numeric records | Detect and block the affected resolution action; never silently average or remove | Data Pipeline owner with scientific review |
| OPEN-11 | Required report format and permitted interpretation content | Do not promise interactive tabs in a static format or introduce AI interpretation | Documentation/Client and Modelling/Evaluation owners |

### Resolved Open Items

The original `OPEN-05` row is retained above as historical Week 7 evidence. Its active status is superseded by the resolution below.

| Open item | Resolution date | Resolution |
|---|---|---|
| OPEN-05 | 2026-07-21 | Ethics approval confirmed. Archive the authoritative approval reference/date, approved scope, participant-material versions, and data-handling boundaries in the controlled ethics record before counting pilot or formal-study data. |

## 5. Execution Rules

1. Every implementation issue must reference its `DEC-*` entry and source.
2. Superseded assumptions must not drive new implementation work.
3. `DEF-*` items do not enter the v1 sprint.
4. `OPEN-*` items block work only when scientific correctness or ethics depends on them.
5. Every issue requires an owner, reviewer, acceptance criteria, test evidence, and report destination.
