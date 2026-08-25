# Week 7 Client Decision Log

> Scope: v1 decisions frozen from client feedback available by 13 July 2026.
>
> Controlled updates: v1.1 adds the 17 and 21 July 2026 UI direction, terminology, and extension decisions; v1.2 records the 10 August 2026 HEV Flow-display decision; v1.3 records the 14 August dashboard-improvement feedback and the five follow-up clarifications consolidated on 25 August 2026, without rewriting the historical Week 7 baseline.

## Version History

| Version | Date | Change |
|---|---|---|
| v1.0 | 2026-07-17 | Week 7 client-decision baseline. |
| v1.1 | 2026-07-21 | Added the confirmed Option A direction, Task terminology, eight wording replacements, extension priorities, and the ethics-status resolution. |
| v1.2 | 2026-08-11 | Added the client-confirmed requirement for selectable raw-daily-Flow and calculated-Flow-statistics HEV modes. |
| v1.3 | 2026-08-25 | Added task-specific Stage gating, the supported lag options, CSV-first local import, user-resolved source conflicts, Biology-only mapping, revised WQ/RHS presentation, and the GAM modelling direction. |

## 1. Decision Rules and Sources

The latest client confirmation overrides only conflicting older assumptions; earlier feedback remains valid where it is consistent.

| Basis | Meaning |
|---|---|
| `CLIENT` | Explicit client requirement or confirmation |
| `TEAM-V1` | Team-selected v1 default within an option accepted by the client |
| `INTERNAL` | Engineering, QA, or traceability safeguard added by the team |

| Source | Sender | Original sent | Subject / identifying detail |
|---|---|---|---|
| `SRC-01` | Thomas Aspin | 13 July 2026; time not supplied | `RE: Feedback Request on Redesign Dependencies, Local Upload Template, and Error List` — upload, WQ, modelling and volunteer-testing response |
| `SRC-02` | Thomas Aspin | 13 July 2026, 09:20 | `RE: Feedback Request on Redesign Dependencies, Local Upload Template, and Error List` — RHS identifier, HDE and WQ-testing response |
| `SRC-03` | Thomas Aspin, with Drew's input | 10 July 2026, 12:29 | `RE: Feedback Request on Redesign Dependencies, Local Upload Template, and Error List` — data-template and dependency-map response |
| `SRC-04` | Thomas Aspin | 7 July 2026, 14:28 | `RE: Feedback Request on Redesign Dependencies, Local Upload Template, and Error List` — local-upload and whiteboard-file response |
| `SRC-06` | Drew Constable | 17 July 2026, 10:26:50 UTC | `RE: HE Toolkit dashboard: UI direction and prioritisation of possible extensions` |
| `SRC-07` | Thomas Aspin | 21 July 2026, 11:55:43 UTC | `RE: HE Toolkit dashboard: UI direction and prioritisation of possible extensions` |
| `SRC-08` | Thomas Aspin | 10 August 2026, 11:55:35 UTC | `RE: Questions Following Dashboard User Testing`; attachments identified in the email as `HEV-plots.pdf` and `HelperFunction.R` |
| `SRC-09` | Thomas Aspin | 14 August 2026, 17:10; follow-up clarification recorded 25 August 2026, time not supplied | `RE: Questions Following Dashboard User Testing`; attachment identified as `Further dashboard improvements.docx`; five later answers are treated as part of this source record |


## 2. Final Decisions

| ID | Final decision | Basis | Source | Required action |
|--|---|---|---|---|
| DEC-01 | Use one multi-sheet XLSX as the primary local upload; sheets are optional. CSV remains a compatibility fallback, not an equal-priority path. | `CLIENT + TEAM-V1` | `SRC-01` | Replace CSV-first specifications and update the template/importer contract. |
| DEC-02 | Require at least one supported biological index; do not require both `WHPT_ASPT` and `LIFE_F`. | `CLIENT` | `SRC-01` | Add cross-field validation. |
| DEC-03 | Default joined/modelling fields are the eight raw/Z-score Q10/Q95 lag 0/1 fields. Q50 may remain descriptive but is not a default joined/model field. | `CLIENT + INTERNAL` | `SRC-01` | Replace the previous six-field contract and update schema, selectors, provenance, and tests. |
| DEC-04 | Remove `area` from the Dashboard schema. | `CLIENT` | `SRC-01` | Remove it from templates, validation, and documentation. |
| DEC-05 | V1 uses a fixed rolling three-calendar-year WQ window. For a biology record with `sampling_year = Y`, include WQ observations from calendar years `Y - 2`, `Y - 1`, and `Y`, with both boundaries inclusive. Summaries are orthophosphate mean, ammonia P90, and dissolved oxygen P10. | `TEAM-V1 + CLIENT` | `SRC-01` | Freeze and test the window boundaries and determinand-specific rules. |
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
| DEC-17 | Require canonical `NGR_PREFIX`, matching the HE Toolkit environmental import interface; the client's `NGR_prefix` wording refers to this same field and does not create an alias. Allow blank `ALKALINITY` only when `CONDUCTIVITY`, `TOTAL_HARDNESS`, or `CALCIUM` supports proxy estimation. | `CLIENT + INTERNAL` | `SRC-03` | Add exact-name validation, conditional validation, and unit guidance. |
| DEC-18 | Require WQ `det_id`; store WQ/RHS coordinates in `site_mapping`, not observation-level WQ data. | `CLIENT` | `SRC-03` | Move fields and update template/validation. |
| DEC-19 | Build `joined_core` from processed biology/O:E and flow first; optionally create `joined_enriched` with WQ/RHS without invalidating the core on enrichment failure. | `CLIENT + INTERNAL` | `SRC-03` | Separate core join and enrichment operations, states, and tests. |
| DEC-20 | Apply one explicit, one-way normalisation from legacy `HMS.Score` to `HMSRBB` and display a compatibility warning; internal data and every output retain only `HMSRBB`. If both fields exist with identical values, retain `HMSRBB` and remove the legacy field; conflicting values block continuation. `HMSRBB` is available for controlled RHS predictor selection. | `CLIENT + INTERNAL` | `SRC-01` | Use only `HMSRBB` in the schema, template, joined data, model selector, downloads, and provenance; test legacy-only, new-only, matching dual fields, and conflicting dual fields. |
| DEC-21 | Single-site models may use raw Q10/Q95 predictors; multi-site mixed-effects models must use the Z-score-standardised Q10z/Q95z lag fields. | `CLIENT` | `SRC-01` | Separate eligible flow predictors by model path and reject raw cross-site flow predictors. |
| DEC-22 | `site_mapping` must hold separate easting/northing pairs for biology, flow, WQ, and RHS sites; RHS mapping uses `rhs_survey_id`. | `CLIENT` | `SRC-03` | Add and validate all four coordinate pairs without assuming that IDs or locations are equal. |
| DEC-23 | Multiple biology samples from the same site on the same date or in the same month-year produce a warning/flag only; the Dashboard must not automatically reject, delete, or aggregate them. If the user aggregates replicates, record the method. | `CLIENT + TEAM-V1` | `SRC-03` | Add duplicate-period detection, user-visible warnings, and aggregation provenance tests. |
| DEC-24 | Store WQ `det_id` as a four-character string in v1. Orthophosphate uses `0180` (`Orthophosphate reactive as P`, canonical unit `mg/L`) with the mean; ammonia uses `0111` (`Ammoniacal Nitrogen as N`, canonical unit `mg/L`) with P90. `0119` (un-ionised ammonia) is a different determinand and must not be treated as an alias of `0111` or silently included in ammonia P90. Normalise input unit aliases `mg/L`, `mg/l`, and `MILLIGRAM PER LITRE` to `mg/L`, while preserving the source value, source unit, qualifier, and normalisation provenance. | `TEAM-V1 + INTERNAL` | `SRC-01` | Update the WQ registry, schema, normalisation, enrichment, and tests; the exact dissolved-oxygen determinand remains under the narrowed `OPEN-02`. |
| DEC-25 | XLSX sheet and column order is a versioned team data contract, not a client-confirmation item. The v1 importer validates the canonical order in `data-contract-v1.0.md`; the legacy workbook is migration input and cannot override the frozen schema. | `TEAM-V1 + INTERNAL` | `SRC-01 + SRC-03 + SRC-04` | Update the template, field dictionary, importer, order-difference messages, and row-bind tests to the frozen order. |

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

## 4. Controlled Update - 2026-08-10

The following decision promotes only the HEV Flow-display item identified in `DEC-34`. The other additions listed in `DEC-34` remain separately prioritised backlog items.

| ID | Final decision | Basis | Source | Required action |
|--|---|---|---|---|
| DEC-37 | HEV plots must support two selectable Flow display modes: (1) raw daily Flow from the current validated Flow dataset, and (2) processed Flow statistics generated by `calc_flowstats()`. Raw-daily mode must not require Flow Statistics to be calculated first. Both modes must retain site/date alignment, provenance, stale-state handling and download support. This decision supersedes only the raw-daily-flow/processed-statistic HEV scope position in `DEC-34`; the other `DEC-34` additions remain separately prioritised backlog items. | `CLIENT + INTERNAL` | `SRC-08` | Add the HEV Flow-data-mode selector, mode-specific prerequisites and data construction, provenance, automated tests and acceptance criteria. |

## 5. Controlled Update - 2026-08-25

The following decisions consolidate the 14 August feedback and the five follow-up clarifications recorded on 25 August. They control wherever they conflict with an earlier decision. Conditional client preferences are recorded as decision envelopes with explicit open items; they are not silently converted into unconditional requirements.

| ID | Final decision | Basis | Source | Required action |
|--|---|---|---|---|
| DEC-38 | Use strict Task-specific Stage paths: Task 1 `R,R,-,-,-`; Task 2 `R,R,-,-,-`; Task 3 `R,R,R,-,-`; Task 4 `R,R,R,R,-`; Task 5 `R,R,R,R,R`. A `-` Stage is greyed out and inaccessible. Task 1 offers only Biology and site-environmental import; Flow, WQ and RHS import are not offered on that route. This supersedes the optional later Stages in `DEC-36` while retaining Task 3 completion at its Stage 3 processed-data checkpoint. | `CLIENT` | `SRC-09` | Revise the Task-stage contract, navigation specification, guidance and acceptance tests before changing runtime configuration. |
| DEC-39 | The supported selectable lag values are `0`, `1`, `3`, `6`, and `12`, and the corresponding lagged Q10/Q95 predictors are available where applicable. Raw-daily HEV mode does not use lag settings. This supersedes the earlier lag scope in `DEC-03` and `SRC-08`. | `CLIENT` | `SRC-09` | Revise generated fields, selectors, diagrams, provenance, exports and tests as one controlled data-contract change. |
| DEC-40 | Make one separate CSV file for each local-data type—Biology, site environmental, daily Flow, WQ and RHS—the primary local-import contract and user-facing path. A combined multi-sheet XLSX workbook is not required in the main workflow. XLSX may remain only as non-essential backward compatibility if it does not complicate the CSV-first workflow. Provide a separate example/template and file-specific validation feedback for each CSV type. This supersedes `DEC-01` and the active XLSX-primary effect of `DEC-25`, and extends `DEC-30` to site-environmental local input. | `CLIENT` | `SRC-09` | Version the data contract; publish and validate five CSV schemas/templates; mark the former XLSX-primary specification as superseded. |
| DEC-41 | Local import is a first-class alternative to Data Explorer import. Users may use either source alone or combine both. When the same logical record has conflicting values, show both sources and differing fields and let the user retain the local record, retain the Explorer record, or exclude it. Never silently overwrite either source; retain the choice and provenance. Identical duplicates may be deduplicated only with a reported action and retained provenance. A local Flow upload must not replace existing Explorer Flow unintentionally and must be recognised by Flow-statistics processing. | `CLIENT + INTERNAL` | `SRC-09` | Define per-data-type identity/comparison keys, merge state, conflict UI, provenance and regression tests in the data and dependency contracts. |
| DEC-42 | `Build WQ summary` belongs in Stage 2. The earliest selectable WQ start date is `2000-01-01`. WQ preview plots appear above the summary with a table/plot toggle; retain time-series and boxplot views, remove the bar chart and generic numeric/date/grouping selectors, require a determinand selection, use `result` and `date_time`, and always group by `wq_site_id`. Remove RHS preview plots. | `CLIENT` | `SRC-09` | Revise the Stage/artifact mapping, WQ validation and presentation specification, RHS presentation scope and acceptance tests. |
| DEC-43 | Map Biology sites only. Biology popups show site ID, water body, sample count, and first/last sampling years. Non-Biology inputs do not require their own coordinates; additional unused coordinate columns should preferably be ignored with an informational notice rather than cause rejection or destructive alteration. This supersedes `DEC-22` and the WQ/RHS-coordinate clause of `DEC-18`; the `det_id` requirement in `DEC-18` remains valid. | `CLIENT + INTERNAL` | `SRC-09` | Remove non-Biology coordinate requirements from schemas and validation, define the authoritative Biology location source, and revise map acceptance criteria. |
| DEC-44 | Simplify or remove the standalone CSV-validation page. Put local upload in Stage 1 of each applicable Task, display the relevant example template before upload, and show upload-time validation feedback using the requested orange-warning interaction. The orange treatment does not make structurally unsafe data usable: schema/type failures that prevent safe processing remain blocking until the severity boundary is frozen. | `CLIENT + INTERNAL` | `SRC-09` | Create a per-file validation/severity specification and distinguish non-blocking quality warnings from blocking structural failures. |
| DEC-45 | Use `mgcv::gam()` for both single-site and multiple-site modelling through a five-step builder: choose model type; choose exactly one ecological receptor and up to two eligible Flow predictors; optionally choose one WQ predictor, one RHS predictor and sampling year/season; choose up to two supported Flow×season and/or Flow×RHS interactions; and, for multiple-site models, choose a reviewed site-intercept, year-by-site or selected-Flow-by-site structure expressed as valid `mgcv` terms. Centre sampling year on the dataset midpoint. This supersedes `DEC-08` and `DEC-10`, promotes the constrained-GAM item in `DEC-34`, and partially supersedes `DEF-02` and `DEF-03`. | `CLIENT + INTERNAL` | `SRC-09` | Replace the frozen v1 modelling contract with a reviewed v2 contract covering formulas, eligibility, data sufficiency, smoothing/random-effect terms, failure behaviour and numerical/scientific verification. |
| DEC-46 | Use Q95z as the only eligible Q95 predictor for both single-site and multiple-site models. Raw Q95 may remain available in the data for display or provenance but is not a modelling predictor. This selects the client-accepted Q95z-only branch, resolves `OPEN-12`, and supersedes `DEC-21` for Q95 eligibility. It does not independently request raw Q10. | `CLIENT + INTERNAL` | `SRC-09` | Enforce Q95z-only eligibility consistently in selectors, server-side validation, provenance and tests. |
| DEC-47 | Modelling is iterative: users may fit and assess a model, create alternatives, compare candidates initially through `summary()` and `AIC()`, and select a preferred model. Only after selection should the Dashboard generate appropriate partial-effect and diagnostic outputs, including `gratia::draw()`, `mgcv::gam.check()` and `gratia::appraise()`. Model-result tables use three significant figures. | `CLIENT + INTERNAL` | `SRC-09` | Define candidate/preferred-model history, comparison semantics, diagnostic gates, exports and acceptance evidence in the modelling and dependency contracts. |
| DEC-48 | Apply the specified usability and defect corrections: show `PCA cannot be run with data from only one site` for the one-site case; fix the Flow heatmap; replace indeterminate long-operation feedback with meaningful progress where progress can be measured; optimise the workspace for full-screen use; and improve table, figure and menu presentation across the Dashboard. | `CLIENT` | `SRC-09` | Trace each correction to an acceptance test and retained evidence; do not classify confirmed defects as optional visual backlog. |

### Supersession Register

| Earlier item | Controlled by | Effect |
|---|---|---|
| `DEC-01`, `DEC-25`, `OPEN-03` | `DEC-40` | CSV-per-type is primary; XLSX is no longer the primary acceptance path. |
| `DEC-03` and the lag rule in `SRC-08` | `DEC-39` | Supported lag values are `0,1,3,6,12` wherever lag settings apply. |
| `DEC-08`, `DEC-10`, `OPEN-06` | `DEC-45`, `OPEN-08` | The additive/mixed-effects v1 model architecture is replaced by a reviewed GAM/GAMM contract. |
| `DEC-18` coordinate clause, `DEC-22`, `DEF-05` | `DEC-43` | Only Biology sites require coordinate-backed mapping; non-Biology map layers are withdrawn. |
| `DEC-21` | `DEC-46` | Q95z is the only eligible Q95 predictor for both model paths; Raw Q95 is not a modelling predictor. |
| `DEC-30` | `DEC-40`, `DEC-41` | Local import now includes site-environmental CSV and may be combined with Explorer data under explicit conflict handling. |
| `DEC-34` GAM scope | `DEC-45`, `DEC-47` | GAM modelling is promoted from backlog to controlled client direction. |
| `DEC-36` | `DEC-38` | Former optional trailing Stages become disabled for Tasks 1–4. |

## 6. Deferred and Open Items

### Deferred beyond v1

| ID | Deferred feature | V1 alternative |
|---|---|---|
| DEF-01 | Configurable one-, two-, and three-year WQ windows | Fixed inclusive calendar-year window from `Y - 2` through `Y`, as defined in DEC-05 |
| DEF-02 | Superseded by `DEC-45`: controlled Flow–RHS interactions | No longer deferred; only the explicitly supported interaction choices enter the reviewed GAM contract. |
| DEF-03 | Partially superseded by `DEC-45`: controlled Flow×season and Flow×RHS interactions | Automatic predictor selection remains deferred; manual selection is controlled by the GAM contract. |
| DEF-04 | GAM-based WQ prediction | Confirmed WQ summaries |
| DEF-05 | Withdrawn by `DEC-43`: non-Biology map layers and map-based pairing | Retain explicit identifier mapping without plotting non-Biology sites. |
| DEF-06 | AI model interpretation | Fixed assumptions, warnings, and limitations |

### Open items

| ID | Question | Interim rule | Owner/deadline |
|---|---|---|---|
| OPEN-01 | Closed: ownership and v1 canonical XLSX column order | Follow `DEC-25` and the data contract; the team maintains authoritative environmental-unit guidance from RICT/package sources rather than treating it as a client-confirmation item | Closed — `DEC-25` |
| OPEN-02 | Exact dissolved-oxygen determinand for P10: `9901` (% saturation) or `9924` (O2, `mg/L`) | Do not guess, merge, or interchange them before client confirmation; orthophosphate `0180` and ammonia `0111` may be implemented independently | Zhaohang (Documentation/Client); confirm only this scientific semantic |
| OPEN-04 | Availability and final count of six EA volunteers | Prepare an availability poll and participant information | Zhaohang (Documentation/Client) |
| OPEN-05 | Ethical approval by 21 July | Do not start formal research without approval | Go/no-go on 21 July |
| OPEN-07 | Exact placement of the user guide/home page | It must support, not compete with, the Option A primary navigation | UX/Workflow owner; resolve before implementation |
| OPEN-08 | GAM families, basis dimensions/smoothing controls, data-sufficiency and convergence criteria, valid random-effect/factor-smooth terms, diagnostics and comparison rules | Do not copy illustrative formula fragments as production formulas or infer unsupported scientific defaults from Case Study 2 | Modelling/Evaluation owner with Data Pipeline and client/scientific review; close through modelling-contract v2 |
| OPEN-09 | Whether three flow-statistic windows is a fixed maximum | Treat three as a recommendation, not a confirmed acceptance limit | Documentation/Client owner |
| OPEN-10 | Duplicate selection and averaging rules for more than two or non-numeric records | Detect and block the affected resolution action; never silently average or remove | Data Pipeline owner with scientific review |
| OPEN-11 | Required report format and permitted interpretation content | Do not promise interactive tabs in a static format or introduce AI interpretation | Documentation/Client and Modelling/Evaluation owners |
| OPEN-13 | Exact identity key and comparison fields for identical/conflicting local-versus-Explorer records in each of the five data types | Detect no cross-source conflict until the relevant identity key is defined; never silently overwrite | Data Pipeline owner with domain review before data-contract revision |
| OPEN-14 | Which CSV validation findings are non-blocking orange warnings and which structural/type failures block processing | Missing required identifiers/fields, unreadable structure and unsafe types remain blocking until the full severity table is approved | Data Pipeline and QA owners before validation-specification freeze |
| OPEN-15 | Authoritative source and required fields for Biology-site coordinates after non-Biology coordinates are removed | Continue displaying only Biology sites; do not infer whether coordinates come from Biology CSV, site-environmental CSV or a reduced mapping record | Data Pipeline and UX/Workflow owners before data-contract revision |

### Resolved Open Items

The original `OPEN-05` row is retained above as historical Week 7 evidence. `OPEN-03` and `OPEN-06` are removed from the active table because later client decisions supersede their original scope.

| Open item | Resolution date | Resolution |
|---|---|---|
| OPEN-05 | 2026-07-21 | Ethics approval confirmed. Archive the authoritative approval reference/date, approved scope, participant-material versions, and data-handling boundaries in the controlled ethics record before counting pilot or formal-study data. |
| OPEN-03 | 2026-08-25 | Resolved by `DEC-40`: five separate CSV files are the primary local-import contract; XLSX is optional backward compatibility only if it does not complicate the main workflow. |
| OPEN-06 | 2026-08-25 | The frozen mixed-effects readiness question is superseded by `DEC-45`; GAM/GAMM readiness and scientific thresholds are reopened under `OPEN-08` and require modelling-contract v2. |
| OPEN-12 | 2026-08-25 | Resolved by `DEC-46`: use Q95z as the only eligible Q95 predictor for both single-site and multiple-site models. |

## 7. Execution Rules

1. Every implementation issue must reference its `DEC-*` entry and source.
2. Superseded assumptions must not drive new implementation work.
3. Active `DEF-*` items do not enter the v1 sprint; a superseded `DEF-*` row follows its controlling `DEC-*` entry.
4. `OPEN-*` items block work only when scientific correctness or ethics depends on them.
5. Every issue requires an owner, reviewer, acceptance criteria, test evidence, and report destination.
