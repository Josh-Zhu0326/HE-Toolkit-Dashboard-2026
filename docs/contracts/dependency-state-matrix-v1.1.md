# Dependency and State Matrix - v1.1

> Date: 4 August 2026  
> Status: Runtime-aligned amendment  
> Supersedes: the public state vocabulary, transitions, outcome labels, and checkpoint-state rows in the [Week 7 v1 review baseline](dependency-state-matrix-v1.md)  
> Runtime source of truth: [`R/workflow_config.R`](../../R/workflow_config.R)

## 1. Scope

This amendment aligns the state matrix with the implemented workflow while preserving the Week 7 v1 dependency graph, node register, invalidation boundaries, recovery cases, and scientific rules.

The runtime already uses eight public artifact states. This document therefore changes the specification only; it does not introduce another state machine or require runtime-state migration.

Helper and validation functions may continue to use local values such as `success`, `error`, `info`, or `not_ready`. These are not public workflow states and must be translated at the server boundary.

## 2. Public state contract

Only the following eight public workflow states are permitted:

| State | Canonical meaning | May satisfy a downstream prerequisite? | Primary user action |
|---|---|:---:|---|
| `not_started` | No attempt or current output is recorded for the current target. An optional branch that has not been selected remains in this state. | No | Start the action or select the optional branch. |
| `blocked` | A prerequisite, eligibility rule, or readiness gate prevents safe execution. No execution failure is claimed. | No | Correct or supply the named prerequisite. |
| `ready` | Current prerequisites are valid, but no current output has been generated. | No | Run or generate explicitly. |
| `running` | An explicit action is executing for the current target. | No | Wait; duplicate execution is disabled. |
| `complete` | A current usable output exists without a relevant non-blocking issue. | Yes | Review, continue, or export. |
| `warning` | A current usable output exists with a relevant non-blocking issue. | Yes | Review the issue; continue or correct and regenerate. |
| `stale` | A previous output exists, but its dependency or configuration no longer matches the current target. | No | Review the labelled history and regenerate. |
| `failed` | Execution was attempted but did not produce a usable current output. | No | Correct the actionable cause and retry. |

Only `complete` and `warning` are current and may satisfy downstream prerequisites.

## 3. Canonical transitions

```text
not_started
  -> ready | blocked

blocked
  -> ready

ready
  -> running

running
  -> complete | warning | failed

complete | warning
  -> stale

stale
  -> running

failed
  -> ready
```

Synchronous validation or import may produce `complete`/`warning` without exposing a visible `running` interval. An input change never starts a high-cost calculation automatically.

## 4. Migration from the v1 vocabulary

The Week 7 v1 state terms are interpreted as follows:

| v1 term or situation | v1.1 workflow state |
|---|---|
| `not_ready`: optional branch not selected | `not_started` |
| `not_ready`: required input, mapping, selection, eligibility rule, or readiness gate missing | `blocked` |
| Required upstream artifact is out of date | Upstream `stale`; dependent action `blocked` until regeneration |
| Workflow-node `error` after attempted execution | `failed` |
| Record/message severity `error` | Remains `error`; it is not a workflow state |
| `ready`, `running`, `complete`, `warning`, `stale` | Unchanged |

The distinction is based on the required recovery action:

- `not_started`: begin or select;
- `blocked`: satisfy a prerequisite;
- `failed`: correct an attempted execution and retry.

## 5. Updated outcome rules

### 5.1 Optional enrichment

| Selection/outcome | Enrichment state | Enriched output | Core path |
|---|---|---|---|
| Not selected | `not_started`, optional | No new enriched version | Unaffected |
| Selected but prerequisites missing | `blocked` | No new enriched version | Unaffected; explain the missing prerequisite |
| Selected and fully successful | `complete` | New current enriched version | Unaffected |
| Selected and partially successful | `warning` | New auditable version containing successful enrichment | Unaffected |
| Selected and fully failed | `failed` | No new enriched version; preserve previous labelled history | Unaffected |

### 5.2 Modelling and HEV readiness

- An unattempted model or HEV configuration remains `not_started`.
- An attempted action with missing response, predictors, site, metrics, or an open readiness gate is `blocked`.
- Candidate multi-site execution remains `blocked` until the mixed-model readiness gate closes.
- A fitting or generation attempt that executes and produces no usable output is `failed`.
- A blocked or failed model must never fall back silently to pooled `lm()`.

### 5.3 Operational failures

- Duration alone never changes `running` to `failed`.
- Explicit API failure, timeout, invalid response, or calculation failure after execution starts produces `failed` at the smallest safe scope.
- At least one usable output plus recoverable record/site failures normally produces `warning`; zero usable outputs after execution normally produces `failed`.
- Failures in WQ or RHS never make `joined_core` stale or failed.

## 6. Checkpoint behaviour

| State | Minimum checkpoint behaviour |
|---|---|
| `not_started` | Explain what can be started or selected. |
| `blocked` | Name the missing or invalid prerequisite and link to the relevant Stage. |
| `ready` | Explain what will be generated and provide the explicit action. |
| `running` | Show operation and scope; disable duplicate execution. |
| `complete` | Summarise current evidence, version, and next step. |
| `warning` | Show usable output, affected scope, implication, and continue/retry actions. |
| `stale` | Show what changed and provide the regeneration action. |
| `failed` | Show the actionable cause and retry path while preserving unrelated results. |

Top-level navigation remains accessible in every state.

## 7. Unchanged v1 rules

The following Week 7 v1 content remains authoritative:

- stateful node register and dependency backbone;
- core, optional-enrichment, direct-upload, analysis, HEV, and model invalidation boundaries;
- current/stale export restrictions;
- targeted stale propagation and mandatory boundary tests;
- non-destructive filtering and provenance requirements;
- HDE-first retrieval with NRFA as the alternative source after recognised HDE failure or no coverage.

## 8. Minimum acceptance check

The runtime enum must remain exactly:

```text
not_started, blocked, ready, running,
complete, warning, stale, failed
```

Any future state addition, removal, or rename requires a new matrix version and corresponding UI, persistence, Resume, and regression-test review.

## 9. Change record

| Version | Date | Change |
|---|---|---|
| v1 | 14 July 2026 | Seven-state review baseline using `not_ready` and workflow `error`. |
| v1.1 | 4 August 2026 | Aligned the specification with the implemented eight-state runtime by splitting `not_ready` into `not_started`/`blocked` and using `failed` for attempted execution failure. |
