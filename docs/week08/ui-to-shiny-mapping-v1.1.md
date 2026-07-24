# UI-to-Shiny Mapping — v1.1

> Prototype baseline: [`workflow-stepper-prototype-v2.2.html`](../week07/workflow-stepper-prototype-v2.2.html)
> Controlled implementation date: 23 July 2026
> Status: **PENDING REVIEW**
> Owner: Lin (UX/Workflow)
> Reviewer: Bo (Architecture/State)

## 1. Purpose and authority

This document controls how the v2.2 workflow concepts are implemented in the
real Shiny application. It does not create a second workflow model. The
authoritative five Tasks, five Stages, paths, completion artifacts, and reusable
outputs remain in [`R/workflow_config.R`](../../R/workflow_config.R); runtime
status and stale propagation remain in
[`R/workflow_state.R`](../../R/workflow_state.R).

A row is `Complete` only when its visible UI, server behaviour, and automated
evidence use the same source of truth. Prototype-only JavaScript state and demo
values are not implementation evidence.

## 2. Controlled mapping

| v2.2 element | Single data source | Shiny implementation | Server behaviour | Acceptance evidence | Status |
|---|---|---|---|---|---|
| Current Task | `workflow_session$task_id` plus Task config | `workflow_header_ui()` renders the global Task context, primary output, Utilities, and five-Stage navigation above every work page | Task selection sets `task_id`, derives Resume, and opens the real Stage workspace; Change Task clears only the current Task and Stage | `tests/testthat/test-workflow-ui.R` — global Header contract; `tests/testthat/test-workflow-server.R` — selection and Change Task tests | Complete |
| Task cards | Task config plus artifact registry | `workflow_task_selector_ui()` renders all five cards, required Stages, current reusable outputs, and the `workflow_resume_stage()` result | Start/Resume selects the configured Task and derives its Stage from current artifacts | `tests/testthat/test-workflow-ui.R` — five-card, metadata, completion, state-attribute, and prototype-structure tests | Complete |
| Five-stage navigation | `he_workflow_stages` plus each Task's `stage_path` | `workflow_stage_nav_ui()` is the only primary navigation; the legacy Navbar is hidden and Stage 2 exposes Biology/Flow work areas only when both are needed | Stage observers accept only Stages used by the current Task and switch the single existing real work page instance | `tests/testthat/test-workflow-ui.R` and `tests/testthat/test-workflow-server.R` — route, sub-navigation, disabled Stage, and inaccessible Stage tests | Complete |
| Required steps | Task `required_artifacts`, `he_artifact_stage_index`, and registry | `workflow_required_steps_ui()` renders only the current Stage's required artifacts and real states | Existing artifact adapters update the shared registry after business outcomes | `tests/testthat/test-workflow-ui.R` — required-step and optional-enrichment isolation tests; `tests/testthat/test-workflow-state.R` | Complete |
| Checkpoint | Required artifact metadata in the registry | `workflow_checkpoint_ui()` renders each required artifact's `status`, `data_source`, `history_summary`, `blocking_reason`, and `next_action` | No checkpoint state is fabricated; it reads the same registry updated by business-result adapters | `tests/testthat/test-workflow-ui.R` — real metadata, recovery guidance, state attributes, and placeholder-removal tests | Complete |
| Primary action | `workflow_nav_target(task_id, stage_index)` plus each real page's existing Run/Import/Join/Generate handler | The separate `Open X` button is removed because the selected Stage already contains the real work page; calculation buttons remain explicit inside that page | Stage selection changes only the visible work page; it never completes an artifact or runs a calculation | `tests/testthat/test-workflow-ui.R` route tests and `tests/testthat/test-workflow-server.R` Stage-routing tests | Complete |
| Change Task | `workflow_session` reset policy | `change_task` is rendered in the global Workflow Header | Clears `task_id`, resets Stage to 1, returns to the Task Selector, and preserves `workflow_artifacts` | `tests/testthat/test-workflow-server.R` — non-destructive Change Task regression | Complete |
| Core-only scope | Explicit WQ/RHS file-selection state plus Task config | `workflow_core_scope_ui()` shows an informational `role="note"` for Tasks 3–5 when neither enrichment is selected | Does not mutate or block `joined_core`; selected/attempted WQ or RHS follows its own artifact state | `tests/testthat/test-workflow-ui.R` — informational visibility/accessibility test; `tests/testthat/test-workflow-state.R` — WQ never stales core | Complete |
| Advanced controls | Submitted Join request plus canonical `choose_lags`/`choose_join_method` signature | `Build HE Dataset` controls remain the only Join-setting inputs | Controls are snapshotted only on Join; later semantic changes stale `joined_core` and current descendants, preserve cached metadata/output revisions, clear current revision gates, and never trigger a Join | `tests/testthat/test-workflow-server.R` — initialization guard, canonical setting, exact stale boundary, preserved revisions, and no-recalculation test | Complete |
| Status announcement | Current Task, Stage, required artifact states, and next actions | Hidden `aria-live="polite"` / `aria-atomic="true"` output uses `workflow_status_announcement_text()` | Re-renders when Task, Stage, artifact state, or next action changes | `tests/testthat/test-workflow-ui.R` accessibility test and `tests/testthat/test-workflow-server.R` reactive announcement test | Complete |

## 3. Controlled differences from v2.2

The v2.2 HTML is a structural and interaction prototype, not a runtime state
authority. The following differences are accepted and intentional:

1. User-facing `Goal` wording is replaced by `Task`; canonical identifiers are
   the five frozen `task_id` values.
2. Prototype demo values, synthetic checkpoint messages, and browser-local
   progress are not migrated. Shiny renders current registry metadata.
3. The legacy expert navbar and its duplicate navigation choices are hidden.
   The global Workflow Header and Stage bar are the only primary navigation;
   Utilities holds the Task selector, CSV validation, and external links.
4. The prototype's separate Primary action is replaced by the real Stage
   workspace immediately below the Header. A calculation still requires its
   existing explicit Import, Run, Join, Generate, or Model action.
5. The prototype's `analysis_dataset` and `NRFA fallback` labels are not exposed
   in user-facing workflow UI.
6. WQ and RHS are optional enrichment. When neither is selected, the UI states
   core-only scope without warning and without blocking `joined_core`.

## 4. Server and state invariants

1. Button clicks may mark an artifact `running`; only a real business result or
   a relevant input change may update its outcome/currentness state.
2. Task cards, Stage navigation, required steps, Checkpoint, and announcements
   consume one artifact registry; none keeps independent completion state.
3. Join settings are canonicalised as sorted unique integer lags plus one method.
   Loading controls does not stale anything.
4. A successful Join stores the submitted setting signature. A later semantic
   change retains the previous output revision and metadata, marks only current
   dependent artifacts stale, and requires another explicit Join.
5. `filter_selection` and `model_spec` are independent inputs and remain current
   when only Join settings change.
6. Change Task never clears reusable artifacts.

## 5. Automated verification

The controlled acceptance evidence is provided by the automated test suite:

- `tests/testthat/test-workflow-ui.R` — Task cards, five-stage navigation,
  required steps, Checkpoint metadata, accessibility, terminology, and routing.
- `tests/testthat/test-workflow-server.R` — Task selection, Stage routing,
  Change Task, announcements, Join-setting stale behaviour, and explicit-run
  protection.
- `tests/testthat/test-workflow-state.R` — artifact dependencies, completion,
  stale propagation, and Core-only invariants.

Run the complete verification suite with:

```bash
R_USER_CACHE_DIR=/tmp/he-toolkit-r-cache Rscript tests/testthat.R
```

Acceptance requires zero failures, errors, and warnings. Browser screenshots are
not controlled release evidence.

## 6. Completion and review record

This implementation does not change the five `task_id` values, five-Stage
paths, artifact schema, dependency graph, or scientific rules. Any future change
to those contracts requires a controlled change decision before implementation.

| Role | Name | Review date | Decision |
|---|---|---|---|
| Owner — UX/Workflow | Lin | `2026-07-22` | Implementation complete; submitted for independent review |
| Reviewer — Architecture/State | Bo | `2026-07-23` | Pending |

Status: **FROZEN**
