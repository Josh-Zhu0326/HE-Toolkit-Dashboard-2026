# Dependency and State Matrix — v2.0

> Date: 25 August 2026  
> Status: **Controlled v2.0 baseline; implementation not yet verified**  
> Historical baselines: [v1.0](dependency-state-matrix-v1.0.md) and [v1.1](dependency-state-matrix-v1.1.md)  
> Authority: [Client Decision Log v1.3](../decisions/client-decision-log-v1.md), [Data Contract v2.0](data-contract-v2.0.md), [Modelling Contract v2.0](modelling-contract-v2.0.md), [Task-Stage Matrix v2.0](task-stage-path-matrix-v2.0.md), and [RTM v2.0](requirement-traceability-matrix-v2.0.md)

## 1. Scope

This contract consolidates the active dependency, state, invalidation, recovery, and continuation rules. States attach to versioned artifacts and actions, not pages. Task cards and Stages project those states without creating another state machine.

A `-` Stage is disabled and has no projected workflow state. Optional WQ/RHS enrichment is an optional branch inside an accessible Stage; it does not make that Stage optional.

## 2. Public state contract

Only these eight public artifact states are permitted:

| State | Meaning | Satisfies a downstream prerequisite? |
|---|---|:---:|
| `not_started` | No attempt or current output exists; this also covers an unselected optional enrichment branch. | No |
| `blocked` | A prerequisite, eligibility rule, unresolved policy, or scientific gate prevents safe execution. | No |
| `ready` | Current prerequisites are valid and the action may be started. | No |
| `running` | An explicit action is executing; duplicate execution is disabled. | No |
| `complete` | A current usable output exists without a relevant non-blocking issue. | Yes |
| `warning` | A current usable output exists with a relevant non-blocking issue. | Yes |
| `stale` | Retained output exists but no longer matches the current dependency/configuration fingerprint. | No |
| `failed` | Execution was attempted and produced no usable current output. | No |

Canonical transitions:

```text
not_started -> ready | blocked
blocked     -> ready
ready       -> running
running     -> complete | warning | failed
complete | warning -> stale
stale       -> running
failed      -> ready
```

Synchronous validation may produce `complete` or `warning` without a visible `running` interval. Input changes never trigger high-cost processing automatically. A failed attempt never deletes the last successful version.

## 3. Stateful artifact register

| Stage | Artifact/node | Required current inputs | Explicit output/action |
|---|---|---|---|
| 1 | `biology_validated` | Selected Local or Explorer Biology source | Validated Biology revision and evidence |
| 1 | `environment_validated` | Selected Local or Explorer site-environmental source | Validated environmental revision and proxy evidence |
| 1 | `flow_validated` | Selected Local or Explorer daily Flow source | Validated daily Flow revision and actual-source provenance |
| 1 | `wq_validated` | Selected Local or Explorer WQ source | Validated WQ revision |
| 1 | `rhs_validated` | Selected Local or Explorer RHS source | Validated RHS revision |
| 1 | `identifier_mapping` | Required Biology/Flow/WQ/RHS identifiers | Join fingerprints; only Biology has a map-coordinate dependency |
| 2 | `rict_predictions` | `environment_validated` | Expected ecological indices |
| 2 | `oe_result` | `biology_validated`, `rict_predictions` | Dashboard-calculated O:E revision |
| 2 | `flow_statistics` | `flow_validated`, statistic/window/lag configuration | Requested Q10/Q95 fields for lags `0,1,3,6,12` |
| 2 | `wq_summary` | `wq_validated`, determinand, valid dates from `2000-01-01` | WQ plots/table summary and provenance |
| 3 | `joined_core` | `oe_result`, `flow_statistics`, identifier mapping, join configuration | Immutable core HE dataset |
| 3 | `wq_enrichment` | `joined_core`, eligible WQ summary/mapping | WQ enrichment result |
| 3 | `rhs_enrichment` | `joined_core`, validated RHS/mapping | RHS enrichment result |
| 3 | `joined_enriched` | `joined_core` and at least one successful selected enrichment | Separate enriched dataset |
| 3 | `processed_dataset_checkpoint` | Current eligible core/enriched revision | Versioned download/re-upload checkpoint |
| 4 | `analysis_dataset` | Selected current joined source and filter/exclusion configuration | Non-destructive analysis revision |
| 4 | `exclusion_log` | Selected source and filter/restore history | Audit record matching the analysis revision |
| 4 | `relationship_exploration` | Current `analysis_dataset`, selected variables/view | Relationship outputs |
| 4 | `hev_daily_result` | Current aligned Biology/O:E and selected daily Flow | Raw-daily HEV output without a Flow-statistics prerequisite |
| 4 | `hev_statistics_result` | Current `analysis_dataset` and selected Flow statistic | Flow-statistics HEV output |
| 5 | `model_candidate` | Current `analysis_dataset`, eligible GAM configuration | Immutable candidate model result |
| 5 | `model_comparison` | Two or more comparable current candidates | `summary()`/`AIC()` comparison with sample basis |
| 5 | `preferred_model` | Explicit user selection of a current candidate | Preferred-model reference |
| 5 | `model_diagnostics` | Current preferred model | Applicable `draw()`, `gam.check()`, and `appraise()` outputs |

Task 3 completes at `processed_dataset_checkpoint` and neither requires nor creates `analysis_dataset`. Disabled Task Stages expose none of their nodes and cannot be reached through direct navigation, Resume, or primary actions.

## 4. Source and branch rules

### 4.1 Local and Explorer sources

Each data type retains its Local and Explorer source revisions independently. Selecting or switching the active source creates a new selection fingerprint, preserves the inactive source, and invalidates only artifacts derived from the old selection. Flow statistics always consume the explicitly selected current Flow source.

`combined` mode and cross-source conflict classification remain unavailable until `OPEN-13` defines record identity/comparison keys.

### 4.2 Optional WQ/RHS enrichment

| Selection/outcome | Enrichment state | Enriched output | Core path |
|---|---|---|---|
| Not selected | `not_started` for the enrichment node only | No new enriched version | Unaffected; no warning |
| Selected, prerequisites missing | `blocked` | No new enriched version | Unaffected; identify the prerequisite |
| Fully successful | `complete` | New current enriched version | Unaffected |
| Partially successful | `warning` | New auditable version containing successful enrichment | Unaffected |
| Fully failed | `failed` | No new version; retain labelled history | Unaffected |

WQ/RHS changes never make `joined_core` stale. They propagate beyond enrichment only when the selected analysis source uses the affected enriched revision.

### 4.3 HEV modes

Daily and Flow-statistics HEV modes have independent configuration fingerprints. Failure or staleness in one mode must not cause silent substitution with the other or overwrite its last valid result.

### 4.4 GAM lifecycle

Single-site and multiple-site modelling both use `mgcv::gam()`. Q95 model inputs accept Q95z only. A fit creates a new candidate rather than overwriting history; comparison-set changes affect `model_comparison`, preferred selection affects `preferred_model`, and only the preferred model enables `model_diagnostics`.

`OPEN-08` keeps affected GAM execution `blocked` or explicitly experimental until families, smooths/site terms, sufficiency, diagnostics, and scientific tolerances are reviewed. A blocked or failed multiple-site model never falls back silently to a pooled or single-site model.

## 5. Targeted invalidation

| Change trigger | Becomes stale or requires a new revision | Must remain valid |
|---|---|---|
| Selected Biology source/content | Biology validation, O:E, joined layers, analysis, HEV, and models derived from it | Environment and Flow branches |
| Selected environmental source/content | Environmental validation, RICT, O:E, joined layers, analysis, and dependants | Biology validation and Flow branch |
| Selected daily Flow source/content | Flow validation/statistics, joined layers, applicable analysis, both affected HEV modes, and models | Biology/environment/O:E |
| Flow statistic/window/lag selection | Flow statistics, joined layers and their downstream analysis/statistics-HEV/models | Validated daily Flow and raw-daily HEV when otherwise unchanged |
| WQ source, date, determinand, or rule | WQ validation/summary/enrichment and selected enriched dependants | `joined_core` and RHS branch |
| RHS source or rule | RHS validation/enrichment and selected enriched dependants | `joined_core` and WQ branch |
| Biology map-coordinate revision | Biology map output | Data joins and modelling unless the identifier mapping also changed |
| Selected joined source or filter/restore rule | `analysis_dataset`, exclusion log, relationship outputs, applicable HEV, and models | Joined datasets |
| HEV mode/site/date/metric/display setting | Only the targeted HEV result | Analysis, relationship outputs, and models |
| New model configuration | New `model_candidate`; comparison set may change | Earlier candidates and non-model outputs |
| Preferred-model selection | Preferred reference and diagnostics | Candidate fits and comparison evidence |
| Upstream model-data revision | Derived candidates, comparison, preferred reference, and diagnostics | Labelled historical model versions |
| Change Task | No otherwise-current artifact | All valid reusable outputs |

## 6. Outcome and recovery boundaries

- Missing required headers, duplicate headers, unreadable CSV structure, or unsafe required types block the affected file; extra non-conflicting columns may be informational.
- The complete warning/blocker catalogue remains deferred under `OPEN-14`; implementation must not weaken the frozen structural blockers.
- Same-site/same-day Biology, Flow, or WQ duplicates block the affected resolution-dependent action until the user makes an eligible retain/average/remove decision. Biology records sharing only a month-year remain flagged without automatic alteration.
- A WQ/RHS failure never fails or stales a valid core result. At least one usable selected enrichment may produce `warning`; zero usable selected enrichment produces `failed` for enrichment only.
- A long operation remains `running` while active. Duration alone never causes `failed`; measurable operations show meaningful monotonic progress.
- Failure is scoped to the smallest scientifically safe file, record, site, branch, or action and preserves unrelated current outputs and labelled history.
- Only current `complete` or `warning` artifacts satisfy prerequisites or export as current results. Stale/failed artifacts may be exported only as explicitly labelled history/debug evidence.

## 7. Minimum checkpoint and provenance record

Every stateful artifact records at least:

```text
node_id, state, target_fingerprint, output_fingerprint,
source_node_versions, source_mode, generated_at, evidence_summary,
messages, affected_output, required_user_action, next_recommended_step,
can_run, can_regenerate, last_successful_version
```

Checkpoints name the current scope, evidence, cause, and next action. `running` disables duplicate execution; `stale` identifies what changed; `blocked` names the missing decision or prerequisite; `failed` provides a retry path without hiding unrelated results.

## 8. Open and deferred boundaries

| Item | Current state rule |
|---|---|
| `OPEN-02` dissolved-oxygen determinand | DO-dependent action is `blocked`; do not guess or interchange determinands. |
| `OPEN-08` GAM scientific settings | Affected model path is `blocked` or explicitly experimental, never `Verified`. |
| `OPEN-13` record identity keys | No `combined` source mode or automatic conflict state. |
| `OPEN-14` complete CSV severity matrix | Apply only the frozen structural safety boundary. |
| `OPEN-15` Biology-coordinate authority | Retain the existing Biology location path; do not infer a new source. |
| Missing WQ source unit | Continue inherited WQ handling; introduce no new automatic policy. |
| Biology date/Year/Month/Season disagreement | Preserve inputs and existing validation; do not reconcile automatically. |

## 9. Verification gate

Version 2.0 is implementation-`Verified` only when automated or controlled evidence covers:

1. the exact eight-state enum and canonical transitions;
2. strict Task path projection and disabled-Stage bypass prevention;
3. source switching, retained alternatives, fingerprints, and targeted stale propagation;
4. core/enriched isolation and Task 3 completion without `analysis_dataset`;
5. both HEV dependency paths without silent substitution;
6. candidate/comparison/preferred/diagnostic GAM states and prohibited fallback;
7. duplicate, structural validation, warning, failure, retry, history, and export boundaries; and
8. the targeted invalidation cases in Section 5.

Any state, dependency, or invalidation change requires a controlled decision and a new contract revision.
