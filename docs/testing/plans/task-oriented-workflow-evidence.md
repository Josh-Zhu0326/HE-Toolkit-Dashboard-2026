# Task-Oriented Workflow Engineering Evidence

This document defines the reproducible engineering evidence run for the
task-oriented workflow claims reported in the dissertation. The tooling records
and tests existing application behaviour; it does not change the Shiny
application's runtime paths, state transitions, or user interface.

This evidence set has a deliberately narrow interpretation:

- B01-B07 are the core claim evidence for task-oriented workflow safety,
  selectivity, consistency, recovery, and traceability;
- the complete `testthat` and standalone suites provide regression context,
  showing that the added workflow verification has not broken other covered
  behaviour; and
- the run is not evidence for every claim in the dissertation or every aspect
  of the project.

## Evidence question

The evidence set must allow an independent reviewer to establish:

1. which exact commit was tested;
2. which operating system, R runtime, packages, and commands were used;
3. which task-oriented workflow claims and regression checks were tested; and
4. whether the run can be repeated from a clean clone.

The runner deliberately rejects a symbolic revision such as `main`, a short
SHA, a dirty worktree, a checkout that differs from `origin/main`, an output
directory inside the repository, or an existing output directory. These gates
prevent an evidence attempt from becoming ambiguous or being overwritten.

## Responsibility boundary

This branch adds evidence tooling and tests only. The repository owner is
responsible for pushing the branch, creating and reviewing the pull request,
merging it to `main`, and optionally tagging the merged baseline. The evidence
run occurs only after that merge; results from this implementation branch are
development verification, not reportable claim evidence.

## Baseline evidence procedure

Use a new clone and a new output directory for every attempt. Replace the
placeholders below with the real repository URL, the complete 40-character
merged commit SHA, and an attempt identifier such as `attempt-01`.

```bash
cd /tmp
git clone <repository-url> hetoolkit-task-workflow-test
cd hetoolkit-task-workflow-test
git checkout <BASELINE_SHA>
git fetch origin main
git status --short
git rev-parse HEAD
git rev-parse origin/main

Rscript --vanilla scripts/run_task_oriented_workflow_evidence.R \
  <BASELINE_SHA> \
  /Users/katherinal/Desktop/SummerProject/HE-Toolkit-Dashboard-2026-evidence/task-oriented-workflow/<BASELINE_SHA>/<ATTEMPT_ID>
```

The checkout may be detached, but all of these conditions must hold:

- `BASELINE_SHA` is a complete 40-character hexadecimal SHA;
- `HEAD`, `origin/main`, and `BASELINE_SHA` are identical;
- the worktree is clean before and after the run; and
- the evidence path is absolute, outside the clone, and does not already
  exist.

The runner creates empty temporary user and site R libraries, disables user R
profiles and environment files, installs the declared dashboard dependencies,
and then records the exact installed versions. The project does not currently
contain `renv.lock`; the package manifest and `sessionInfo()` therefore define
the dependency reproducibility boundary without claiming a lockfile guarantee.

## Core claim evidence: B01-B07

These seven scenarios are the primary evidence produced by this workflow. Each
scenario maps a task-oriented workflow claim to a precondition, action,
expected state transition, automated observation, and optional UI record.

| ID | Claim exercised | Required observation |
|---|---|---|
| B01 | Missing prerequisite safety | Missing Flow Statistics leave `joined_core` blocked and non-current, with a reason and recovery action. |
| B02 | Upstream invalidation | A new Flow revision stales dependent descendants while unrelated evidence remains current. |
| B03 | Selective invalidation | A WQ change leaves `joined_core` current while WQ-derived evidence becomes stale. |
| B04 | Filter rebuild and traceability | Exclude/restore rebuilds `analysis_dataset`, stales HEV/model outputs, preserves joined data, and records the action. |
| B05 | Model specification safety | A model-specification change makes the retained model result stale without invalidating unrelated outputs. |
| B06 | Failure recovery | A failed model attempt remains explicit and non-current; no fallback result is exportable, and a reviewed retry creates a new current revision. |
| B07 | Resume consistency | State logic and the server both select the earliest unmet required stage. |

## Regression context

The same command also runs and records:

- dependency installation in isolated temporary libraries;
- the dashboard startup preflight;
- the complete `tests/testthat` suite;
- every top-level `tests/test_*.R` standalone script in its own R process; and
- a post-run Git cleanliness check.

These checks demonstrate regression context around the B01-B07 evidence. They
do not turn this evidence set into validation of the whole dissertation or the
entire project. The testthat report records test files, cases, expectations,
passes, failures, errors, warnings, skips, and elapsed time. Warnings and skips
are not silently treated as an unqualified pass.

## Evidence output

A completed attempt has this structure (additional log files may be present):

```text
<attempt>/
├── task-workflow-baseline.txt
├── session-info.txt
├── package-versions.csv
├── manifest.json
├── run-status.txt
├── git-status-after.txt
├── standalone-summary.csv
├── SHA256SUMS
├── automated-tests/
│   ├── testthat-results.rds
│   ├── testthat-cases.csv
│   ├── testthat-events.csv
│   ├── testthat-summary.json
│   ├── boundary-scenarios.csv
│   └── boundary-scenarios.md
├── logs/
│   ├── dependency-install.log
│   ├── startup-preflight.log
│   ├── testthat.log
│   └── standalone/
└── ui/
    ├── B01/record.md
    └── ... B02-B07 ...
```

`manifest.json` identifies the evidence kind as
`task-oriented-workflow-engineering-evidence`. `SHA256SUMS` makes later
accidental changes detectable. Do not edit a generated attempt in place. If a
command or observation must be corrected, use a new attempt identifier and
retain the earlier attempt as an audit record.

## Exit status and review

| Exit status | Meaning |
|---:|---|
| 0 | All automated requirements passed; no warning or skip requires review. |
| 1 | Hard failure: a command, test, boundary scenario, or cleanliness gate failed. |
| 2 | Automated requirements passed, but warnings or skipped tests require a written explanation. |

An exit status of 2 is not equivalent to failure, but it is also not an
unqualified result. Explain each warning or skip in the task-oriented workflow
evidence notes and state whether it affects a reported claim.

## UI observations

The runner creates one `record.md` template for each boundary scenario. Use
synthetic fixtures only. Fill in the execution times, browser version, viewport,
fixture, observed behaviour, and PASS/FAIL decision. Add one screenshot or a
small before/after pair where visual state is part of the claim; do not create a
large screenshot collection without a claim-to-observation purpose.

The UI record must use the same baseline SHA and attempt as the automated
results. If a UI observation fails, retain it as a failed attempt and
investigate before reporting the claim.

## Dissertation reporting rule

The dissertation's task-oriented workflow section and its associated evidence
table must be populated from `manifest.json`, `testthat-summary.json`, and
`boundary-scenarios.csv`, not from historical test counts. Report the complete
commit SHA, execution date, R version, operating system, cases, expectations,
failures, errors, warnings, skips, regression-suite result, and B01-B07 result.

Suggested wording:

> The reported task-oriented workflow engineering results were reproduced
> against commit `<BASELINE_SHA>` in the environment recorded in the
> accompanying evidence manifest.

Do not generalise this wording to all dissertation results. The primary run
covers the recorded macOS/R environment and the explicitly listed automated
scope. It does not, by itself, claim Windows-launcher validation, successful
integration with authorised external services, or validation of every project
requirement.
