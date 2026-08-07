# WK8-16 biology duplicate contract

Date: 2026-08-07

Owner: Di

Scope: same-site/same-day and same-site/same-month-year Biology duplicate handling for the current analysis dataset.

## Implemented behaviour

- Detects Biology duplicate groups by `biol_site_id + date`.
- Detects Biology duplicate groups by `biol_site_id + month-year`.
- Requires an explicit user decision for each duplicate group before duplicate choices are treated as resolved.
- Supports `keep_all` to retain every source record while recording provenance.
- Supports `keep_record` to retain one selected record and exclude the other records from the current `analysis_dataset`.
- Uses the existing analysis filter/exclusion mechanism, so `joined_core` and `joined_enriched` are not modified.
- Records duplicate decision provenance in a duplicate choice log.

## Out of scope

- Automatic rejection, deletion, or aggregation.
- Scientific averaging rules for duplicate groups.
- Browser-level RC evidence; this remains a later QA activity.

## Verification

- `Rscript tests/test_duplicate_choice_helpers.R`
- `Rscript tests/testthat/test-workflow-server.R`
- Parse check for `R/duplicate_choice_helpers.R`, `server.R`, `ui.R`, and `global.R`
- `git diff --check`
