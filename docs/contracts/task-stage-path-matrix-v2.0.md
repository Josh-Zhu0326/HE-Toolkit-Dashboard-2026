# Task-Stage Path Matrix — v2.0 (Frozen Paths)

> Date: 25 August 2026  
> Status: **Frozen path requirements; implementation not yet verified**  
> Supersedes: [Task-Stage Path Matrix v1.1](task-stage-path-matrix-v1.1.md) for new work  
> Authority: `DEC-26`–`DEC-28`, `DEC-35`, `DEC-38`; client email `SRC-09` in the [Client Decision Log](../decisions/client-decision-log-v1.md)  
> Traceability: `RTM-26`, `RTM-35`, `RTM-36` in [RTM v2.0](requirement-traceability-matrix-v2.0.md)

## 1. Scope and symbols

This document defines the single primary five-stage workflow, the Stage path for each Task, Task completion artifacts, and cross-Task reuse. Detailed data, modelling, dependency, and validation rules remain in their authoritative contracts.

- `R`: required and accessible.
- `-`: disabled, greyed out, and inaccessible.

There are no optional Stages in v2.0. A validated processed-dataset upload may satisfy eligible prerequisites for Tasks 4 and 5, but it does not create another Stage or path symbol.

## 2. Task paths

| Task | Internal `task_id` | S1 | S2 | S3 | S4 | S5 | Primary output |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| Assess ecological condition | `ecological_condition` | R | R | - | - | - | Expected values and O:E ratios |
| Summarise the flow regime | `flow_regime` | R | R | - | - | - | Flow statistics and coverage summary |
| Combine biology, flow and environmental data | `build_he_dataset` | R | R | R | - | - | Joined HE dataset |
| Generate HEV plots | `generate_hev` | R | R | R | R | - | HEV plots, data and data history |
| Undertake HE modelling | `he_modelling` | R | R | R | R | R | Current model, diagnostics and data history |

This table is the path authority. Task cards, Stage guidance, progress, and Start/Resume behaviour must derive from the same configuration. Task 1 offers only Biology and site-environmental import; Flow, WQ, and RHS import are not available on that route.

## 3. Completion and reuse

| `task_id` | Required artifacts | Completion artifact | Reusable outputs | Valid next Tasks |
|---|---|---|---|---|
| `ecological_condition` | `biology_input`, `environment_input`, `oe_result` | `oe_result` | `processed_biology`, `processed_environment`, `oe_result` | Tasks 3, 4, 5 |
| `flow_regime` | `flow_input`, `flow_statistics` | `flow_statistics` | `processed_flow`, `flow_statistics` | Tasks 3, 4, 5 |
| `build_he_dataset` | `oe_result`, `flow_statistics`, `joined_core`, `processed_dataset_checkpoint` | `processed_dataset_checkpoint` | `joined_core`, `joined_enriched`, `processed_dataset_checkpoint` | Tasks 4, 5 |
| `generate_hev` | `joined_core`, `analysis_dataset`, `hev_result` | `hev_result` | `processed_dataset_checkpoint`, `analysis_dataset`, `hev_result` | Task 5 |
| `he_modelling` | `joined_core`, `analysis_dataset`, `model_result` | `model_result` | `processed_dataset_checkpoint`, `analysis_dataset`, `model_result` | Task 4 |

Task 3 completes at its Stage 3 checkpoint and must not produce or require the Stage 4 `analysis_dataset`. Valid reusable outputs are preserved when changing Tasks; reuse must not imply that skipped calculations ran in the current session.

## 4. Navigation and state rules

1. **Start Task** opens the earliest required Stage whose required artifact is incomplete, blocked, failed, or stale.
2. **Resume Task** derives its destination from current artifact state, not navigation history.
3. A `-` Stage cannot be reached through the normal UI, direct navigation, resume logic, or a primary action, and it does not contribute to progress.
4. **Change Task** returns to Task selection without deleting valid reusable outputs.
5. Source or upstream changes invalidate only affected descendants; filtering never overwrites upstream datasets.
6. Every visible primary action routes to a real handler; unresolved scientific work remains explicitly blocked or experimental.
7. User-facing wording uses `Task`, the controlled output names, `Data source`, and `Data history`; active configuration uses only the five ordered `task_id` values and no `goal_id` alias.

## 5. Authorities and verification gate

| Concern | Authority |
|---|---|
| Client scope, wording, and paths | [Client Decision Log](../decisions/client-decision-log-v1.md) |
| Data inputs, layers, and provenance | [Data Contract v2.0](data-contract-v2.0.md) |
| Model eligibility and outputs | [Modelling Contract v2.0](modelling-contract-v2.0.md) |
| Requirements and evidence states | [RTM v2.0](requirement-traceability-matrix-v2.0.md) |
| Artifact states and invalidation | [Dependency/State Matrix v2.0](dependency-state-matrix-v2.0.md) |

Implementation is `Verified` only when configuration and automated evidence cover the exact 5×5 paths, disabled-Stage bypass prevention, Task 1 input restrictions, Task 3 checkpoint completion, Start/Resume/Change Task, progress calculation, reusable-output preservation, visible wording, and the absence of an active `goal_id` alias.

Any path change requires a controlled decision and a contract revision.
