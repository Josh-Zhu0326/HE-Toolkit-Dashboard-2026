# Bo Sun - Week 7 Architecture/State Report

Period: 13-17 July 2026

Repository: `HE-Toolkit-Dashboard-2026`

Role: Architecture/State owner; UX/Workflow and QA/Reproducibility reviewer

## Executive Summary

This work establishes the Week 7 v1.0 Architecture/State baseline requested by the team plan and informed by the Environment Agency client email. It converts the agreed workflow boundaries into machine-readable configuration, documents the five goals and five stages, defines the seven workflow states, and adds automated evidence for the critical stale-propagation rules.

No O:E, WQ/RHS import, HEV, local-file import, or modelling calculation was changed. Full runtime stale propagation and a generic workflow engine remain intentionally out of scope for this week.

## Client Requirements Addressed

The architecture reflects the following confirmed decisions:

- WQ and RHS are optional supporting datasets added after the biology-flow core join.
- Missing WQ/RHS data must not block the core workflow.
- Filtering changes only the final analysis dataset.
- Goal selection highlights the existing five-stage path and does not introduce separate navigation.
- `rhs_survey_id` is the standard RHS identifier.
- HDE is the preferred flow source and NRFA fallback requires visible provenance.

## Deliverables Completed

### 1. Workflow configuration skeleton

`R/workflow_state_helpers.R` provides:

- `workflow_stage_config()` for the five workflow stages;
- `workflow_goal_config()` and `workflow_goal_matrix()` for five user goals;
- `workflow_dependency_map()` for core, enriched and analysis data dependencies;
- `workflow_state_definitions()` and `derive_workflow_state()` for the seven states;
- `workflow_stale_targets()` for deterministic downstream invalidation;
- `new_workflow_checkpoint()` for the agreed checkpoint structure;
- `validate_workflow_configuration()` for configuration integrity.

The module is sourced from `global.R` but does not alter any current calculation.

### 2. Dependency and state specification

`docs/week07/architecture-state-specification.md` freezes:

- five stages and five goal paths;
- required versus optional workflow steps;
- `joined_core`, `joined_enriched` and `analysis_dataset` boundaries;
- seven state meanings and continuation rules;
- stale propagation and output-viewability rules;
- the checkpoint contract.

### 3. Automated architecture tests

`tests/test_workflow_state_helpers.R` verifies configuration integrity and the required stale boundaries:

- WQ/RHS enrichment does not invalidate `joined_core`;
- filtering does not modify or invalidate either joined dataset;
- model-variable changes invalidate only `model_result`;
- biology changes invalidate O:E and all dependent join, exploration, HEV and model outputs.

### 4. Reproducible local-data fixtures

A five-site snapshot was downloaded from public Environment Agency services using IDs selected from `NDMN site metadata.xlsx`. The snapshot includes mapping, biology, environmental, HDE flow, WQ and RHS files, plus coverage and provenance records. The offline fixture test confirms ID preservation, frozen schemas, WQ/RHS mapping and plot generation. Detailed evidence is recorded in `docs/week07/ndmn-local-fixture-test-report.md`.

## Reviewer Findings

### UX/Workflow review

The current dashboard has clear top-level navigation, but the Week 7 Goal Selector/Stepper is not yet connected to a shared state source. The new configuration is ready for Lin's UI prototype to consume in a later scoped change. The UI must keep top-level navigation available and use goals only to highlight the existing path.

### QA/Reproducibility review

The architecture module has no network dependency and its tests are deterministic. Review of the current branch also found existing Data Pipeline contract conflicts that are outside Bo's ownership and should be handled by the assigned owner:

- `ui.R` user-facing mapping guidance still names `rhs_site_id` and still requires local `flow_input`;
- `R/site_mapping_helpers.R` can still copy legacy `rhs_site_id` to `rhs_survey_id`;
- `R/dashboard_backlog_helpers.R` still requires and validates local `flow_input`;
- the Introduction example in `server.R` still uses NRFA.

These are release-relevant Week 7 issues, but changing them in the Architecture/State submission would mix ownership and PR scope.

## Test Evidence

The following checks passed on 21 July 2026:

```powershell
Rscript --vanilla tests\test_workflow_state_helpers.R
Rscript --vanilla tests\test_site_mapping.R
Rscript --vanilla tests\test_backlog_helpers.R
Rscript --vanilla tests\test_wq_rhs_plots.R
Rscript --vanilla tests\test_server_site_import.R
Rscript --vanilla -e "invisible(lapply(c('global.R','ui.R','server.R'), parse)); cat('syntax ok\n')"
```

The dashboard also completed a startup smoke test by listening on `http://127.0.0.1:3847`. The temporary process was then stopped and the port was confirmed closed. Existing server tests emitted only the previously observed Leaflet interrupted-promise warnings; no test failed.

## Scope Boundary and Next Step

This delivery defines and tests the architecture contract. The next Architecture/State iteration should connect existing Shiny events to a small session-state store, render checkpoint evidence in Lin's Stepper, and mark stale outputs at runtime. That work should be implemented only after the Data Pipeline schema corrections are merged so that state transitions are based on the final input contract.
