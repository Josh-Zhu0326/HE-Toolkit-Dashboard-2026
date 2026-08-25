# UI-to-Shiny Mapping — v2.0

> Date: 25 August 2026  
> Status: **Frozen mapping requirements; implementation not yet verified**  
> Historical implementation baseline: [v1.1](ui-to-shiny-mapping-v1.1.md)  
> Authorities: [Task-Stage v2.0](../../contracts/task-stage-path-matrix-v2.0.md), [Dependency/State v2.0](../../contracts/dependency-state-matrix-v2.0.md), [Data Contract v2.0](../../contracts/data-contract-v2.0.md), [Modelling Contract v2.0](../../contracts/modelling-contract-v2.0.md), and [RTM v2.0](../../contracts/requirement-traceability-matrix-v2.0.md)

## 1. Scope and evidence rule

This document maps current contract requirements to the real Shiny UI and server surfaces. Contracts define required behaviour; `R/workflow_config.R`, `R/workflow_state.R`, UI/server code, tests, and browser captures are implementation evidence rather than requirement authority.

A row is `Verified` only when the visible UI, server behaviour, state transitions, and retained evidence all satisfy the same v2.0 rule. Historical v1.1 evidence supports `Partial` status only where the underlying behaviour remains relevant.

## 2. Controlled mapping

| UI concern | Contract source | Required Shiny mapping | Required server/state behaviour | Evidence required | Status |
|---|---|---|---|---|---|
| Current Task and cards | Task-Stage v2.0; `RTM-35`, `RTM-36` | Global Task context and five cards use the controlled wording and ordered `task_id` values; no visible `Goal` or active `goal_id` alias | Start/Resume derives from current artifacts; Change Task preserves valid reusable outputs | Task-card, wording, configuration, Start/Resume, and Change Task tests | Partial |
| Five-stage navigation | Task-Stage v2.0; `RTM-26` | The shared Stage navigation exposes `R` Stages and greys out `-` Stages; Task 1 Stage 1 shows only Biology and site-environmental input | Enforce `R,R,-,-,-`; `R,R,-,-,-`; `R,R,R,-,-`; `R,R,R,R,-`; `R,R,R,R,R` through UI, direct routing, Resume, and actions; disabled Stages do not count toward progress | Exact-path, disabled-bypass, Task 1 scope, Resume, and progress tests | Partial |
| Required steps and checkpoint | Task-Stage v2.0; Dependency/State v2.0 | Required steps and checkpoints display current artifact state, evidence, cause, next action, and reusable completion evidence | `-` Stages expose no artifact state; Task 3 completes at Stage 3 and neither requires nor creates `analysis_dataset` | Artifact-state, route-only evidence, Task 3 completion, stale, retry, and accessibility tests | Partial |
| Local CSV upload | Data Contract v2.0; `RTM-01`, `RTM-29` | Applicable Task Stage 1 shows the relevant Biology, site-environmental, daily-Flow, WQ, or RHS template before its upload; no primary XLSX dependency | Validate each file independently; structural failures block that file; safe extras are informational; orange feedback does not weaken blocker rules | Five schema/template/upload, Task-scope, severity, recovery, and accessibility tests | Not started |
| Local/Explorer selection | Data Contract v2.0; Dependency/State v2.0; `RTM-27` | Each applicable data type provides an explicit Local/Explorer current-source choice without a `combined` option | Preserve both source revisions; switching updates the selection fingerprint and invalidates only affected descendants; Flow statistics consume selected Flow | Source switching, retained alternative, fingerprint, stale-boundary, and no-combined-mode tests | Partial |
| Core and optional enrichment | Data Contract v2.0; Dependency/State v2.0; `RTM-19` | Core-only scope is informational; WQ/RHS are optional branches inside an accessible Stage, not optional Stages | Unselected enrichment is `not_started` for that branch; selected missing input is `blocked`; enrichment failure never fails or stales `joined_core` | Core/enriched isolation, partial success, failure preservation, and selected-source propagation tests | Partial |
| WQ and RHS presentation | Data Contract v2.0; `RTM-05`, `RTM-28` | Stage 2 places WQ plots above the summary with table/plot toggle; require determinand; use `result`, `date_time`, and `wq_site_id`; remove bar/generic selectors and RHS preview plots | Reject dates before `2000-01-01`, reversed ranges, and missing determinand; retain excluded-count and date provenance | WQ date/UI/view/field/grouping tests and absence-of-RHS-preview evidence | Not started |
| Join and lag controls | Data Contract v2.0; `RTM-03` | Join controls offer only lag values `0,1,3,6,12` and the contracted join settings | Snapshot settings only on explicit Join; later semantic changes stale affected current descendants, preserve history, and never auto-run Join | Lag-option, canonical signature, no-auto-run, targeted stale, and retained-history tests | Partial |
| HEV modes | Dependency/State v2.0; `RTM-25` | HEV exposes explicit raw-daily Flow and calculated Flow-statistics modes with mode-specific prerequisites and provenance | Raw-daily mode does not require Flow statistics; one mode never silently substitutes for or overwrites the other | Mode construction, prerequisites, switching, stale isolation, plot, download, and provenance tests | Not started |
| Five-step GAM builder | Modelling Contract v2.0; `RTM-08A`, `RTM-08B`, `RTM-09`, `RTM-10`, `RTM-21` | Builder enforces one receptor, up to two Flow predictors, optional WQ/RHS/year/season, up to two supported interactions, reviewed multiple-site structure, and Q95z-only Q95 choices | UI/server eligibility must match; unsupported terms are rejected; `OPEN-08` keeps affected execution blocked or explicitly experimental; no silent fallback | Builder-limit, formula, Q95z, structure, blocked-state, and prohibited-fallback tests | Blocked |
| Candidate and preferred-model lifecycle | Modelling Contract v2.0; `RTM-30` | Show immutable candidate history, `summary()`/`AIC()` comparison, preferred-model selection, and three-significant-figure result tables | New fits do not overwrite candidates; disclose comparison sample basis; enable `draw()`, `gam.check()`, and `appraise()` only for the preferred model | Candidate history, comparison, preferred selection, diagnostics gate, precision, and export tests | Not started |
| Long-operation progress | Dependency/State v2.0; `RTM-33` | Measurable operations show meaningful task-specific progress; duplicate execution is disabled | Progress is monotonic and ends in a valid success/warning/failed state; duration alone never causes failure | Progress-event, accessibility, cancellation/failure, and non-measurable-operation tests | Partial |
| Confirmed defects and presentation | `RTM-31`, `RTM-32`, `RTM-34` | Show the exact one-site PCA message, correct the Flow heatmap, and improve full-screen table/figure/menu presentation | Defect handling preserves unrelated current artifacts and does not invent completion | PCA regression, heatmap fixture, representative viewport, and retained browser evidence | Not started |

## 3. Server and state invariants

1. One artifact registry supplies Task cards, Stage navigation, checkpoints, announcements, and Resume; none keeps independent completion state.
2. A button click may set `running`; only a real output or relevant input/configuration change updates outcome or currentness.
3. Only `complete` and `warning` satisfy downstream prerequisites. `blocked`, `failed`, and `stale` retain an actionable recovery path and labelled history.
4. A `-` Stage cannot be opened by visible controls, direct navigation, Resume, or a primary action and has no projected artifact state.
5. Source, lag, filter, HEV, and model changes follow the targeted invalidation rules in Dependency/State v2.0; no change triggers an expensive calculation automatically.
6. Model, HEV, import, WQ, or enrichment failure is scoped to the smallest safe action and preserves unrelated valid outputs.
7. User-facing wording uses `Task`, controlled output names, `Data source`, and `Data history`; implementation-only identifiers are not exposed.

## 4. Verification plan

Evidence must include:

- automated UI, server, state, configuration, and accessibility tests;
- controlled browser evidence for all five Task routes and representative desktop viewports;
- blocked, warning, failed, stale, retry, source-switch, and Change Task recovery cases;
- explicit proof that disabled Stages, `combined` source mode, Raw Q95 modelling, and preferred-only diagnostics cannot be bypassed; and
- links from each applicable RTM v2.0 row to the retained test or browser artifact.

Historical v1.1 tests and screenshots remain historical evidence. They do not verify a changed v2.0 criterion without re-execution against the current implementation.

## 5. Status summary and review gate

| Status | Count |
|---|---:|
| `Verified` | 0 |
| `Partial` | 7 |
| `Blocked` | 1 |
| `Not started` | 5 |

This mapping becomes implementation-`Verified` only when all rows have current evidence, open scientific rules are represented honestly, all authority links resolve, the complete automated suite passes in a clean environment, and retained browser evidence confirms the critical end-to-end paths.

Any mapping change that alters a frozen contract requires a controlled decision and contract revision before implementation.
