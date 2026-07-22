# Week 7 Dependency and State Matrix - v1

> Date: 14 July 2026
> Status: Review baseline
> Document owner: Lin (Modelling/Evaluation)
> Architecture/State owner: Bo
> Reviewer: Yutong (UX/Workflow)

## 1. Purpose and scope

This document defines the dependency, state, stale-propagation, recovery, and continuation contract for the shared five-stage Dashboard workflow.

It implements the paths in the [Goal-Stage Path Matrix](goal-stage-path-matrix-v1.md) without creating a second navigation system or a general workflow engine. States attach to versioned workflow nodes and outputs, not to pages. Goal cards summarise their required nodes; they do not own a separate state machine.

Authoritative supporting specifications are the [client decision log](../client-decision-log-v1.md), [data contract](data-contract-v1.md), [modelling contract](modelling-contract-v1.md), and [requirement traceability matrix](requirement-traceability-matrix-v1.md). The original dependency whiteboard remains design evidence, but this matrix supersedes its single joined-dataset node and direct WQ/RHS-to-model paths.

## 2. Public state contract

Only the following seven public state values are permitted:

| State | Canonical meaning | May satisfy a downstream prerequisite? | Primary user action |
|---|---|:---:|---|
| `not_ready` | A required prerequisite is missing/invalid, an optional branch is not selected, or a readiness gate is open. | No | Complete or select the missing prerequisite. |
| `ready` | Prerequisites for the target fingerprint are valid, but no current output has been generated. | No | Run or generate explicitly. |
| `running` | An explicit action is executing for the target fingerprint. | No | Wait; duplicate execution is disabled. |
| `complete` | A current output exists for the target fingerprint and has no relevant non-blocking issue. | Yes | Review, continue, or export. |
| `warning` | A current, usable output exists, but a relevant non-blocking issue is recorded. | Yes | Review the warning; continue or correct and regenerate. |
| `error` | The current attempt failed and no usable output exists for the target fingerprint. | No | Correct the problem and retry. |
| `stale` | A previous output exists, but its dependency/configuration fingerprint no longer matches the current target. | No | Review the labelled old result; regenerate from the earliest stale dependency. |

### 2.1 Canonical transitions

```text
not_ready
  -> prerequisites satisfied
ready
  -> explicit action
running
  -> complete | warning | error

complete | warning
  -> dependency or configuration fingerprint changes
stale
  -> explicit regenerate
running

error
  -> blocking condition corrected
ready
```

An input change never starts a high-cost calculation automatically.

### 2.2 Current and previous versions

- State is evaluated for the current target fingerprint.
- A failed current attempt must not delete the last successful artifact.
- When the target changes, the last successful artifact is retained as stale/history with its fingerprint, timestamp, warnings, and provenance.
- If a same-fingerprint refresh fails while a valid current artifact still exists, retain the artifact's `complete`/`warning` state and record the failed attempt separately; do not incorrectly invalidate valid evidence.
- A stale result may be viewed, but it cannot satisfy a downstream prerequisite or be exported as the current result.
- If no prior output exists, use `not_ready` or `ready`, never `stale`.

### 2.3 Warning semantics

`warning` means that a usable current output exists. A pre-run non-blocking message does not turn a node into `warning`; the node remains `ready` until the action produces an output. Relevant messages remain visible in the checkpoint.

Downstream nodes inherit warning evidence through provenance, but they become `warning` only when that issue affects their records, scientific interpretation, or user decision. Warnings from unused optional branches do not contaminate a core-based output.

### 2.4 Error scope

Errors block the smallest scientifically safe record, site, source, or action scope first. They must not clear unrelated successful inputs, outputs, or the session. A whole node becomes `error` when no eligible current output can be produced or when partial continuation would create scientific ambiguity.

## 3. Minimum state/checkpoint record

Each stateful node records at least:

```text
node_id
state
target_fingerprint
output_fingerprint
source_node_versions
generated_at
evidence_summary
warning_or_error_codes
affected_output
required_user_action
next_recommended_step
can_run
can_regenerate
last_successful_version
```

These fields are a contract for traceability and checkpoints, not a requirement to build a general workflow engine.

## 4. Dependency projections and configuration fingerprints

### 4.1 Mapping projections

The UI may use one `site_mapping` sheet, but dependency tracking must calculate separate logical fingerprints:

| Fingerprint | Fields/meaning | Must not invalidate |
|---|---|---|
| `flow_import_locator` | Flow site, coordinates, requested source/default source information used for external retrieval. | Biology/environment processing. |
| `core_join_mapping` | Biology-to-flow pairing used by the core join. | Flow import, RICT/O:E, and flow statistics. |
| `wq_mapping` | Biology-to-WQ pairing and WQ coordinates. | `joined_core` and RHS processing. |
| `rhs_mapping` | Biology-to-`rhs_survey_id` pairing and RHS coordinates. | `joined_core` and WQ processing. |

This is logical dependency scoping, not a request for multiple user files.

### 4.2 Configuration fingerprints

The following configurations trigger targeted invalidation but do not add public state values:

- Flow source, imputation method, donor mapping, and flow-statistics settings.
- Join method, lags, windows, and selected enrichment sources.
- Selected joined source and filtering/exclusion version.
- Relationship-exploration variables and view settings.
- HEV site, date range, flow metrics, biology/O:E metrics, and display settings.
- Model response, predictors, path, and random-effects structure.

## 5. Stateful node register

| Stage | Node | Required prerequisites | Explicit action/output |
|---|---|---|---|
| 1 | `core_mapping` | Mapping input containing the required core projection. | Validate mapping and calculate import/join fingerprints. |
| 1 | `wq_mapping` | Selected WQ mapping input. | Validate WQ mapping. |
| 1 | `rhs_mapping` | Selected RHS mapping using `rhs_survey_id`. | Validate RHS mapping. |
| 1 | `biology_validated` | `biology_samples`. | Validate biology and produce record-level evidence. |
| 1 | `environment_validated` | `environmental_site_data`. | Validate canonical environmental fields and proxy eligibility. |
| 1 | `flow_validated` | Valid local flow, or an HDE-first external retrieval with transparent NRFA recovery. | Import/validate flow and record actual source. |
| 1 | `wq_validated` | Selected WQ upload/query result. | Import/validate WQ observations. |
| 1 | `rhs_validated` | Selected RHS data. | Import/validate RHS site-level data. |
| 1 | `direct_joined_validated` | Optional direct joined upload. | Validate schema and upload provenance. |
| 2 | `rict_predictions` | `environment_validated`. | Run RICT/predict expected indices. |
| 2 | `oe_result` | `biology_validated` and `rict_predictions`. | Calculate O:E. |
| 2 | `imputed_flow` | `flow_validated` and selected imputation configuration. | Impute flow; optional branch. |
| 2 | `flow_statistics` | Current validated or selected imputed flow and statistics configuration. | Calculate flow statistics. |
| 3 | `joined_core` | Standard branch: O:E, flow statistics, core mapping, and join configuration; direct branch: validated core projection. | Build immutable core and join summary. |
| 3 | `wq_enrichment` | `joined_core`, WQ data/mapping, and frozen WQ rules. | Run WQ enrichment. |
| 3 | `rhs_enrichment` | `joined_core`, RHS data/mapping, and RHS rules. | Run RHS enrichment. |
| 3 | `joined_enriched` | `joined_core` plus at least one successful selected enrichment; or a validated direct-upload enrichment projection. | Build a separate enriched dataset without overwriting core. |
| 4 | `analysis_dataset` | Selected valid joined source and filter/exclusion configuration. | Materialise analysis version; no filtering is version `0`. |
| 4 | `exclusion_log` | Selected source and filter/restore history. | Generate/update with the same analysis version while retaining audit history. |
| 4 | `environment_exploration` | Current environmental data/results. | Generate environmental view. |
| 4 | `flow_exploration` | Current flow data/statistics. | Generate completeness/range view. |
| 4 | `relationship_exploration` | Current `analysis_dataset` and selected variables. | Generate/re-generate relationship views. |
| 4 | `hev_result` | Current `analysis_dataset` and eligible HEV configuration. | Generate/re-generate HEV. |
| 5 | `model_result` | Current `analysis_dataset`, valid model configuration, and applicable readiness gate. | Fit, diagnose, and package the eligible model result. |

Exports are not separate long-lived state nodes. A download action may read only the current `complete`/`warning` version and must include its state and provenance. Stale or error artifacts may be downloaded only as explicitly labelled historical/debug evidence, never as the current result.

## 6. Canonical dependency backbone

```text
biology -> biology_validated --------------------+
                                                   -> oe_result
environment -> environment_validated -> RICT ----+

external flow target -> HDE -- recognised failure/no coverage --> NRFA
local flow ---------------------------------------------------------+
                                                                    v
                                                             flow_validated
                                                                    |
                                                optional imputation-+
                                                                    v
                                                             flow_statistics

oe_result + flow_statistics + core_join_mapping + join config
                              |
                              v
                         joined_core
                              |
             +----------------+----------------+
             |                                 |
      WQ enrichment                      RHS enrichment
             |                                 |
             +---------------+-----------------+
                             v
                       joined_enriched

joined_core -----------+
                       +--> selected joined source + filter/restore
joined_enriched --------+                  |
                                           v
                                  analysis_dataset
                                   + exclusion_log
                                           |
                       +-------------------+------------------+
                       v                   v                  v
             relationship views       HEV result        model result
```

### 6.1 Direct-upload branch

```text
validated direct joined upload
  -> canonical core projection -> joined_core
  -> optional valid enrichment projection -> joined_enriched
  -> selected source -> analysis_dataset
```

Stage 2-3 prerequisites may be recorded as satisfied by `validated direct upload` evidence, but this must not claim that the Dashboard performed upstream RICT, O:E, flow-statistics, or enrichment calculations.

## 7. Stale-propagation matrix

### 7.1 Core path

| Change trigger | Nodes that become stale | Nodes that remain valid | Required regeneration order |
|---|---|---|---|
| Biology input | `biology_validated`, `oe_result`, `joined_core`, both enrichment results, `joined_enriched`, `analysis_dataset`/`exclusion_log`, relationship views, HEV, and model. | Environment/RICT and flow outputs. | Validate biology -> O:E -> core -> selected enrichment -> analysis -> downstream. |
| Environmental input | `environment_validated`, RICT, O:E, environmental exploration, core, enrichment, analysis, and analysis-dependent downstream nodes. | Biology validation and flow outputs. | Validate environment -> RICT -> O:E -> core -> downstream. |
| Flow observations | `flow_validated`, imputation, flow statistics, affected flow exploration, core, enrichment, analysis, and analysis-dependent downstream nodes. | Biology and environment/RICT/O:E. | Import/validate -> optional impute -> statistics -> core -> downstream. |
| Flow import locator/source | The affected `core_mapping` projection, external flow import, and every output derived from it. | Biology/environment; an unused local-flow branch. | Validate mapping -> HDE/NRFA recovery -> flow processing -> downstream. |
| Biology-flow join mapping | The affected `core_mapping` projection, `joined_core`, and all outputs derived from it. | O:E, imported flow, imputation, and flow statistics. | Validate mapping -> build core -> downstream. |
| Imputation configuration | `imputed_flow`, flow statistics, imputation-dependent flow views, core, and its downstream outputs. | Raw validated flow. | Impute -> statistics -> core -> downstream. |
| Flow-statistics configuration | Flow statistics, statistics-dependent flow views, core, and its downstream outputs. | Validated/imputed flow. | Calculate statistics -> core -> downstream. |
| Join method/lags/windows | Core, both enrichment results, enriched, analysis/exclusion log, relationship views, HEV, and model. | O:E and flow statistics. | Build core -> selected enrichment -> analysis -> downstream. |

### 7.2 Optional enrichment

| Change trigger | Nodes that become stale | Nodes that must remain valid | Conditional propagation |
|---|---|---|---|
| WQ observations/query result | WQ validation and WQ enrichment. | `joined_core` and RHS processing. | If current enriched contains WQ, enriched is stale; only analysis/downstream derived from that enriched version become stale. |
| WQ mapping or scientific rule | `wq_mapping` when mapping fields changed, plus WQ enrichment. | WQ validation, core, and RHS processing. | Same conditional propagation. |
| RHS data | RHS validation and RHS enrichment. | `joined_core` and WQ processing. | If current enriched contains RHS, enriched and its dependants become stale. |
| RHS mapping | `rhs_mapping` and RHS enrichment. | RHS validation, core, and WQ processing. | Same conditional propagation. |
| Selected enrichment set | `joined_enriched`. | `joined_core` and validated source data. | Analysis/downstream become stale only when they use the affected enriched source. |
| Enrichment retry succeeds | A new enriched version is required. | `joined_core`; a current core-based analysis. | Core-based analysis remains current until the user selects the new enriched version. |

WQ/RHS changes must never make `joined_core` stale. If the current `analysis_dataset` is derived from core, an unused enrichment change must not make that analysis or its downstream outputs stale.

### 7.3 Direct joined upload

| Change trigger | Required invalidation |
|---|---|
| Uploaded file content or schema version changes. | Direct validation, direct core/enriched projections, analysis/exclusion log, and all outputs derived from those versions become stale. |
| Current source branch switches between standard and direct upload. | Joined layers and their downstream outputs become stale; upstream artifacts from both branches are preserved. |
| Only optional enrichment fields in a direct upload change. | Direct enriched and its dependants become stale; the unchanged direct core projection remains valid. |

### 7.4 Analysis, exploration, and model configuration

| Change trigger | Nodes that become stale | Nodes that remain valid |
|---|---|---|
| Selected joined source changes. | `analysis_dataset`, `exclusion_log`, relationship views, HEV, and model. | Both joined datasets. |
| Filter/exclude/restore configuration changes. | `analysis_dataset`, `exclusion_log`, relationship views, HEV, and model. | Core/enriched, O:E, and flow statistics. On explicit Apply/Generate, create the new analysis and audit-log version. |
| Relationship variables/view configuration changes. | `relationship_exploration` only. | Analysis, HEV, and model. |
| HEV site/date/metrics/settings change. | `hev_result` only. | Analysis, relationship exploration, and model. |
| Model response/predictors/random structure change. | `model_result` only. | Analysis and all exploration outputs. |
| Modelling contract or relevant package implementation changes. | Affected model results. | All data layers and exploration outputs. |

### 7.5 Mandatory boundary tests

1. A WQ change leaves `joined_core` in its current `complete`/`warning` state.
2. A filtering change leaves both joined datasets byte/content equivalent and in their current states.
3. A model-variable change makes only `model_result` stale.
4. A biology change makes O:E, core/enriched, analysis, relationship views, HEV, and model stale while leaving RICT and flow outputs current.
5. An RHS-mapping-only change does not trigger flow re-import or core rebuild.
6. A HEV-setting-only change does not alter `analysis_dataset` or model state.

## 8. Warning, error, and continuation matrix

### 8.1 Non-blocking warnings

| Condition | Affected output | Continuation rule |
|---|---|---|
| Same-site same-date/month-year biology duplicates. | Biology/O:E and outputs using those records. | Retain all records; continue with duplicate evidence. |
| Approved alkalinity proxy used. | Environment/RICT/O:E and affected outputs. | Continue with proxy provenance. |
| User-supplied O:E ignored. | Biology validation. | Continue using Dashboard-calculated O:E. |
| Flow gaps remain but requested statistics are calculable. | Flow statistics and affected outputs. | Continue with completeness evidence. |
| Imputation applied. | Imputed flow/statistics and affected outputs. | Continue with method/donor/count provenance. |
| HDE falls back transparently to NRFA. | Flow and outputs using those sites. | Continue with requested/actual source and reason. |
| Some flow sites fail but a valid subset remains. | Flow output. | Continue using successful sites and report failures. |
| WQ below-detection-limit substitution is applied. | WQ enrichment. | Continue while preserving source value/qualifier. |
| Selected WQ/RHS enrichment has partial coverage. | `joined_enriched`. | Continue with explicit coverage and missingness. |
| Legacy `HMS.Score` is successfully normalised to `HMSRBB`. | RHS processing. | Continue; never re-emit the legacy field. |
| One HEV biology panel is unusable but another remains eligible. | HEV. | Skip the affected panel and continue with a warning. |
| Sampling year is constant. | Eligible single-site model. | Remove the year term explicitly and record why. |
| High correlation/multicollinearity is below a frozen blocking boundary. | Model result. | Continue with diagnostics and warning provenance. |

For recoverable record/site operations, at least one valid output plus failed records normally yields `warning`; zero valid outputs yields `error`. Scientifically ambiguous key expansion is never downgraded to warning.

### 8.2 Normal conditions that do not create warning state

- Unselected WQ/RHS is optional: its node is `not_ready` with `required_for_goal = false`, and it does not affect the Goal summary or create warning state. Show only an informational core-only scope notice.
- User-directed filtering is normal: a successfully generated filtered `analysis_dataset` is `complete`; filtering version and `exclusion_log` are provenance. Decision-critical automatic/model-specific exclusion may still create a warning at the affected output.
- A valid direct joined upload may be `complete`; its upload origin and inability to reconstruct upstream calculations are provenance, not automatically a warning.
- A long WQ query remains `running`. Approximately 20 minutes for 49 sites is plausible and is not by itself a warning or error.

### 8.3 Errors and preservation boundaries

| Error condition | Blocked scope | Results that must remain available |
|---|---|---|
| No supported biology index/schema. | Biology validation and O:E. | Environment, flow, and unrelated inputs. |
| Environmental contract fails for every candidate site. | RICT/O:E. | Biology raw/validation and flow. |
| HDE and NRFA both fail for one site. | That flow site. | Other successful flow sites. |
| Every requested flow site fails. | Flow processing. | Biology/environment outputs. |
| WQ timeout, API failure, or invalid response. | WQ branch. | Core and RHS branch. |
| RHS identifier/schema failure. | RHS branch. | Core and WQ branch. |
| Every selected enrichment fails. | New enriched generation; no new enriched version is created. | Current core and any previous labelled enriched version. |
| Core join has zero matches or unresolved scientifically ambiguous expansion. | New core and its current downstream path. | O:E, flow statistics, and previous labelled core version. |
| Filtering produces zero eligible records. | New analysis generation. | Joined datasets and last valid analysis version. |
| HEV has no usable flow metric or biology panel. | HEV action. | Analysis and other exploration outputs. |
| Model eligibility/fitting fails. | Model action. | Analysis, HEV, and exploration outputs. |

### 8.4 `not_ready`, not `error`

- An optional enrichment is not selected.
- Dissolved-oxygen determinand semantics remain unresolved.
- The mixed-model contract/readiness gate remains open.
- Model response/predictors have not yet been selected.
- HEV site and eligible metrics have not yet been selected.
- A required upstream output is stale and awaits regeneration.

## 9. Special operational rules

### 9.1 HDE-first flow retrieval

- External retrieval attempts HDE first.
- NRFA may be used only after recognised HDE no-coverage/failure.
- Successful fallback produces usable flow output with a warning and source provenance.
- A double failure is scoped to the affected site; the whole flow node is `error` only when no usable requested site remains.
- Local flow is a separate valid input branch and does not participate in HDE-to-NRFA fallback.

### 9.2 WQ query duration and test scale

- Query execution remains `running` while the request is active.
- Duration alone never changes `running` to `error`.
- Explicit API failure, timeout, or invalid response produces `error` for the WQ branch.
- User cancellation returns to `ready` when prerequisites remain valid and records a cancelled-attempt checkpoint; it is not automatically an error.
- Normal usability/acceptance testing uses fewer than 10 sites.
- 20-site and 49-site runs are separate extended/performance evidence; 49 sites are not a normal usability pass/fail case.

### 9.3 Optional enrichment outcomes

| Selection/outcome | Enrichment state | Enriched output | Core path |
|---|---|---|---|
| Not selected. | `not_ready`, optional. | No new enriched version. | Unaffected. |
| Selected but prerequisites missing. | `not_ready`. | No new enriched version. | Unaffected; explain missing selected prerequisite. |
| Selected and fully successful. | `complete`. | New current enriched version. | Unaffected. |
| Selected and partially successful. | `warning`. | New enriched version contains only successful, auditable enrichment. | Unaffected. |
| Selected and fully failed. | `error`. | No new enriched version; preserve previous version as labelled history. | Unaffected. |

If WQ succeeds and RHS fails, or vice versa, `joined_enriched` may be produced with the successful source and `warning` state. It must record which selected source failed.

### 9.4 Modelling readiness

- Exactly one valid site after model-specific exclusions selects the single-site additive path.
- Two or more valid sites identify only a candidate multi-site path.
- Until every `MC-O01`-`MC-O11` item is closed and the readiness gate passes, candidate multi-site execution remains `not_ready`.
- `not_ready` must never be presented as a fit failure and must never fall back silently to pooled `lm()`.
- After contract freeze, convergence, singularity, variance, warning/export, and numerical-parity states follow the reviewed modelling contract.

## 10. Checkpoint behaviour

Every visible checkpoint uses:

```text
status
evidence_summary
affected_output
required_user_action
next_recommended_step
```

Minimum behaviour by state:

| State | Checkpoint behaviour |
|---|---|
| `not_ready` | Name the missing/invalid prerequisite and link to the relevant shared stage. |
| `ready` | Explain what will be generated and provide the explicit action. |
| `running` | Show operation, scope, elapsed/progress evidence where available, and disable duplicate action. |
| `complete` | Summarise evidence, version, and next recommended step. |
| `warning` | Show usable output, affected records/sites, scientific implication, and continue/retry actions. |
| `error` | Show actionable cause and retry path while preserving unrelated and prior results. |
| `stale` | Show what changed, old/current fingerprints, view-old action, and regenerate action/blocked prerequisite. |

Top-level navigation remains accessible in every state. An error on one page/action must not trap the user or hide valid results elsewhere.

## 11. Review and freeze gate

This matrix may become `Frozen v1` only when:

1. Architecture/State owner and UX/Workflow reviewer approve the seven-state semantics, node register, and propagation rules.
2. Goal Selector, Goal-Stage matrix, data contract, state matrix, and RTM use the same Stage 3-4 ownership and three-layer/direct-upload semantics.
3. Every required node has a user-facing checkpoint and explicit regenerate/retry action.
4. Automated or reproducible manual tests cover the six mandatory stale boundaries in Section 7.5.
5. Recovery tests prove that WQ/RHS/flow/model failures preserve unrelated valid outputs and the session.
6. Case Study 2 reaches core, analysis, HEV, and eligible export outputs without WQ/RHS.
7. Dissolved oxygen remains `not_ready` until `OPEN-02` closes, and mixed-model execution remains `not_ready` until `OPEN-06` closes.
8. Unselected enrichment uses the same Goal-aware rule across the data contract, Goal-Stage matrix, and dependency/state matrix: an informational core-only scope notice with no warning state; warning begins only after a selected enrichment is missing, stale, incomplete, or fails.

## 12. Traceability

| Contract area | Decisions/requirements |
|---|---|
| Non-destructive filtering and stale propagation | `DEC-07`, `RTM-07` |
| Single-site/multi-site model readiness | `DEC-08`-`DEC-10`, `DEC-21`, `RTM-08A`, `RTM-08B`, `RTM-09`, `RTM-10`, `RTM-21`, `OPEN-06` |
| HDE default and NRFA recovery | `DEC-12`, `RTM-12` |
| Core/enriched separation and optional WQ/RHS | `DEC-19`, `RTM-19` |
| RHS identifier and mapping | `DEC-11`, `DEC-22`, `RTM-11`, `RTM-22` |
| Biology duplicate warnings | `DEC-23`, `RTM-23` |
| WQ rules and unresolved dissolved oxygen | `DEC-05`, `DEC-06`, `DEC-24`, `RTM-05`, `RTM-06`, `RTM-24`, `OPEN-02` |