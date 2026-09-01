# Documentation Guide

Project documentation is organised by purpose rather than by file extension or
the week in which a file was created. Dates and historical week references are
retained inside the documents and in Git history.

## Main Sections

| Directory | Contents |
|---|---|
| [`operations/`](operations/) | Hosting, deployment, and operating guidance |
| [`decisions/`](decisions/) | Client decisions and controlled project decisions |
| [`contracts/`](contracts/) | Data, modelling, dependency, workflow, and traceability contracts |
| [`requirements/`](requirements/) | Workflow requirements, warning rules, and error catalogues |
| [`design/`](design/) | Workflow designs, UI prototypes, and data templates |
| [`research/`](research/) | Background material and study materials |
| [`testing/`](testing/) | Test plans, execution reports, evidence, and test data |
| [`project/`](project/) | Audits, readiness records, and weekly evidence |

## Useful Entry Points

- [Client decision log](decisions/client-decision-log-v1.md)
- [Frozen data contract v2.0](contracts/data-contract-v2.0.md) ([historical baseline](contracts/data-contract-v1.0.md))
- [Frozen modelling requirements v2.0](contracts/modelling-contract-v2.0.md) ([historical baseline](contracts/modelling-contract-v1.0.md))
- [Requirement traceability matrix v2.0](contracts/requirement-traceability-matrix-v2.0.md) ([historical baseline](contracts/requirement-traceability-matrix-v1.0.md))
- [Frozen Task-Stage paths v2.0](contracts/task-stage-path-matrix-v2.0.md) ([v1.1 historical baseline](contracts/task-stage-path-matrix-v1.1.md))
- [Current dependency/state matrix v2.0](contracts/dependency-state-matrix-v2.0.md) ([v1.1 historical baseline](contracts/dependency-state-matrix-v1.1.md))
- [UI-to-Shiny mapping v2.0](design/workflows/ui-to-shiny-mapping-v2.0.md) ([v1.1 historical baseline](design/workflows/ui-to-shiny-mapping-v1.1.md))
- [Error and guidance catalogue v2.0](requirements/error-and-guidance-message-catalogue-v2.0.md) ([Week 8 historical baseline](requirements/WK8-09_Complete_Error_List.md))
- [Gate D technical readiness](project/readiness/gate-d-technical-readiness.md)
- [Browser verification report](testing/reports/browser-2026-08-09/RAW-01-25_Final_Browser_Manual_Verification_Report.md)
- [Dissertation final engineering evidence](testing/plans/dissertation-final-evidence.md)
- [Windows customer crash diagnostics](operations/windows-customer-crash-diagnostics.md)

## Placement Rules

- Keep runtime code and assets outside `docs/`; Shiny-served assets belong in
  the repository-level `www/` directory.
- Put reusable automated test fixtures in `tests/fixtures/`. Put data retained
  only as documentation or manual evidence in `testing/data/`.
- Store screenshots and generated evidence beside their testing purpose under
  `testing/evidence/`, grouped by test run or evidence set.
- Store future contracts by subject in `contracts/`, not in new week-numbered
  directories.
- Use lower-case kebab-case for new directory names. Preserve externally agreed
  filenames when renaming would weaken traceability.

Some decision-log sources deliberately point to files in adjacent project
workspaces. Those external references are provenance links and are not expected
to resolve from a standalone clone of this repository.
