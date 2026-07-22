# Task-Stage Path Matrix — v1.1

> Original baseline: [Goal-Stage Path Matrix v1](../week07/goal-stage-path-matrix-v1.md), preserved unchanged
> Controlled update date: 21 July 2026
> Status: Changes requested
> Owner: Lin (UX/Workflow)
> Reviewer: Bo (Architecture/State)

## 1. Purpose and Authority

This document answers five questions only:

1. Which user-facing Tasks exist?
2. Which Stages are required, optional, or unused for each Task?
3. Which artifact completes each Task?
4. Which outputs can be reused by another Task or session?
5. How do Start, Resume, and Change Task interpret the configured path?

It applies the 17 and 21 July controlled client updates while preserving the original v1 baseline. `Task` is the user-facing term and `task_id` is the canonical implementation identifier. Legacy `Goal ID` wording remains only in the preserved v1 historical baseline.

Detailed validation, duplicate handling, data-layer semantics, stale propagation, HEV eligibility, and modelling eligibility are governed by their authoritative contracts and are not duplicated here.

## 2. Shared Five-Stage Workflow

1. **Prepare Sites and Data**
2. **Check and Process Data**
3. **Build HE Dataset**
4. **Explore and Refine Relationships**
5. **Model and Export**

### Legend

- `R`: required.
- `O`: optional.
- `-`: not used by the selected Task.

A validated processed-dataset upload may satisfy eligible Stage 2–3 prerequisites for Tasks 4 and 5. This is a prerequisite-satisfaction route, not another Stage, path symbol, or workflow state.

## 3. Task-Stage Path Matrix

| Task | Internal `task_id` | S1 | S2 | S3 | S4 | S5 | Primary output |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| Assess ecological condition | `ecological_condition` | R | R | - | O | O | Expected values and O:E ratios |
| Summarise the flow regime | `flow_regime` | R | R | - | O | O | Flow statistics and coverage summary |
| Join biomonitoring indices with flow statistics and other environmental data | `build_he_dataset` | R | R | R | O | O | Joined HE dataset |
| Generate HEV plots | `generate_hev` | R | R | R | R | O | HEV plots, data and data history |
| Undertake HE modelling | `he_modelling` | R | R | R | R | R | Current model, diagnostics and data history |

This table is the path authority. Task cards, Stage guidance, required/optional markers, progress summaries, and Start/Resume behaviour must derive from the same configuration.

## 4. Completion and Reuse Matrix

Internal artifact names remain stable implementation terms; the UI uses the corresponding domain wording from the Task matrix.

| `task_id` | Required artifacts | Completion artifact | Reusable outputs | Valid next Tasks |
|---|---|---|---|---|
| `ecological_condition` | `biology_input`, `environment_input`, `oe_result` | `oe_result` | `processed_biology`, `processed_environment`, `oe_result` | Task 3, Task 4, Task 5 |
| `flow_regime` | `flow_input`, `flow_statistics` | `flow_statistics` | `processed_flow`, `flow_statistics` | Task 3, Task 4, Task 5 |
| `build_he_dataset` | `oe_result`, `flow_statistics`, `joined_core`, `processed_dataset_checkpoint` | `processed_dataset_checkpoint` | `joined_core`, `joined_enriched`, `analysis_dataset`, `processed_dataset_checkpoint` | Task 4, Task 5 |
| `generate_hev` | `joined_core`, `analysis_dataset`, `hev_result` | `hev_result` | `processed_dataset_checkpoint`, `analysis_dataset`, `hev_result` | Task 5 |
| `he_modelling` | `joined_core`, `analysis_dataset`, `model_result` | `model_result` | `processed_dataset_checkpoint`, `analysis_dataset`, `model_result` | Task 4 |

## 5. Cross-Task Invariants

1. Task selection highlights one route through the shared five Stages; it does not create a second navigation system.
2. Runtime artifact state is the source of readiness. A prior button click alone is not evidence of completion.
3. Valid reusable outputs are preserved when the user changes Task.
4. Processed-data download and later-session re-upload provide the v1 continuity route for Tasks 4 and 5.
5. `joined_core`, optional `joined_enriched`, and `analysis_dataset` remain separate internal layers; filtering never overwrites upstream data.
6. Unselected WQ/RHS enrichment does not block a valid core route.
7. Same-day duplicate decisions, invalidation boundaries, HEV rules, and model eligibility follow their authoritative contracts.
8. Visible wording uses `Task`, `Joined HE dataset`, `Data source`, and `Data history`; it does not expose `Versioned analysis_dataset` or unexplained `NRFA fallback` wording.

## 6. Navigation Rules

- **Start Task** opens the earliest required Stage whose required artifact is incomplete, blocked, failed, or stale.
- **Resume Task** uses current artifact state and revisions; it does not guess progress from navigation history.
- A user may open another used Stage, but a `-` Stage remains disabled for that Task.
- **Change Task** returns to the Task Selector without deleting reusable outputs.
- A later Task may consume a current reusable artifact or validated processed upload without implying that skipped calculations ran in the current session.
- Every visible primary action must route to a real Shiny handler or page.

## 7. Authoritative References

| Concern | Authority |
|---|---|
| Client wording, scope, and extension decisions | [Client Decision Log](../client-decision-log-v1.md) |
| Data layers, validation, duplicate handling, and source history | [Data Contract](../week07/data-contract-v1.md) and [v1.1 amendment](../week07/data-contract-v1.1.md) |
| Artifact dependencies, runtime states, and invalidation | [Dependency/State Matrix](../week07/dependency-state-matrix-v1.md) |
| Model eligibility and failure behaviour | [Modelling Contract](../week07/modelling-contract-v1.md) |
| Requirements, ownership, and test evidence | [Requirement Traceability Matrix](../week07/requirement-traceability-matrix-v1.md) |

Where another contract conflicts with this Task path after 21 July, record the conflict and resolve it through controlled change; do not silently maintain two path definitions.

## 8. Freeze Criteria

Version 1.1 may be marked **Frozen** only when:

1. UX/Workflow and Architecture/State approve all five paths.
2. The real workflow configuration contains exactly these five Tasks and five Stages, uses `task_id`, and contains no active `goal_id` field.
3. Config, Task Selector, Stage navigation, completion artifacts, and reuse rules agree.
4. Automated tests cover path validation, visible wording, Start/Resume, and non-destructive Change Task.
5. Every primary action reaches a real handler.
6. Any unresolved scientific path remains honestly blocked or `not_ready`.
7. Owner and reviewer complete the record below.

## 9. Remediation Evidence

Recorded on 22 July 2026:

- `DEC-35` records the canonical `task_id` field, values, order, and change-control rule.
- `DEC-36` resolves Task 3 completion at its Stage 3 processed-dataset checkpoint and makes Stage 4 optional for that Task.
- `tests/testthat/test-workflow-config.R` asserts the exact five Stage IDs, complete 5×5 Task paths, ordered Task IDs, full completion/reuse/next-Task contracts, and absence of an active `goal_id` field.
- `validate_he_workflow_config()` rejects missing required fields, unknown or unmapped artifacts, Required artifacts outside `R` Stages, later-Stage dependencies, invalid Stage paths, and unknown next Tasks.
- `workflow_resume_stage()` derives Start/Resume from runtime artifact status; pure-state and server tests cover new, reusable-output, complete, blocked, failed, and stale cases.
- Required-step UI and Stage status use only `required_artifacts`; unselected reusable enrichment cannot block the core route.
- `processed_dataset_checkpoint` remains a Stage 3 output and depends on `joined_core`, never on Stage 4 `analysis_dataset`.
- The legacy hard-coded `wf_progress_bar()` and all five real-page calls were removed; the configured Stage navigation is the only workflow stepper.
- Real import, processing, O:E, Flow-statistics, join, HEV, and modelling outcomes now update the shared artifact registry; upstream replacement uses dependency invalidation.
- `tests/testthat/test-workflow-server.R` drives mocked real business outputs through the Shiny server and verifies current artifacts through Task 3, HEV, and modelling; the Local Flow server test verifies stale propagation after source replacement.
- Task cards and the selected-Task workspace consume each Task's configured `completion_artifact` at runtime.
- Week 7 authority links now resolve to the relocated `docs/client-decision-log-v1.md` without changing the historical contract semantics.
- Task 4 and Task 5 primary-output wording is identical in the matrix, configuration, and exact wording tests.
- `R_USER_CACHE_DIR=/tmp/he-toolkit-r-cache Rscript tests/testthat.R` passes the complete automated suite.
- An active-code scan of `R/`, `server.R`, and `ui.R` finds no `goal_id` reference.
- `git diff --check` passes for the affected configuration, UI, test, decision-log, and matrix files.

## 10. Review Record

| Role | Name | Review date | Decision / accepted limitation |
|---|---|---|---|
| Owner — UX/Workflow | Lin | `2026-07-21` | Approved |
| Reviewer — Architecture/State | Bo | `2026-07-22` | Approved |

Status: **FROZEN**
