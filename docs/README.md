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
- [Data contract](contracts/data-contract-v1.md)
- [Requirement traceability matrix](contracts/requirement-traceability-matrix-v1.md)
- [Current dependency/state matrix](contracts/dependency-state-matrix-v1.1.md)
- [Gate D technical readiness](project/readiness/gate-d-technical-readiness.md)
- [Browser verification report](testing/reports/browser-2026-08-09/RAW-01-25_Final_Browser_Manual_Verification_Report.md)

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
