# Client Feedback Review Baseline

Frozen on: 2026-08-17

## Code Baseline

- Base branch: `main`
- Base commit: `384eaf8e8c93f4d39c99e35e639a12bfb101761b`
- Review branch: `di/client-feedback-lags`
- Review branch commit before the final correction pass: `a69c8930bf1111447105991d22c1e76ca729b592`
- Review comparison: the base commit against the review branch plus its staged correction work
- Test platform: macOS Darwin 24.5.0, R 4.6.0

The base commit remains fixed for this correction pass. Later changes on `main` must be handled in a separate synchronisation and conflict review.

## Requirement Precedence

Conflicts are resolved in this order:

1. Latest client email and attachment recorded as `SRC-09`.
2. Controlled decisions in `client-decision-log-v1.md`.
3. Frozen schemas in `data-contract-v1.md`.
4. Acceptance statements in `requirement-traceability-matrix-v1.md`.
5. Current implementation and automated tests.
6. Superseded templates, demos and earlier discussion.

Lower-priority evidence must be updated when it conflicts with a higher-priority source. Unresolved scientific choices are recorded as follow-up work and are not guessed in this pass.

## Frozen Contract For This Pass

| Area | Frozen rule |
|---|---|
| Local CSV schema | Each per-type CSV has one canonical ordered column list. Missing, unexpected or reordered columns block use and are reported. |
| Environmental chemistry | `ALKALINITY`, `CONDUCTIVITY`, `TOTAL_HARDNESS` and `CALCIUM` remain columns in the canonical Environmental CSV. Their values may be blank, but every row with blank `ALKALINITY` must contain at least one non-blank proxy value. |
| Source combination | External and local records may be row-bound only after both inputs have the same canonical names and order. No implicit extra-column union is permitted. |
| WQ/RHS mapping | Every supplied local WQ/RHS record must receive a non-blank `biol_site_id`. Partial or zero matching blocks only that optional enrichment source and reports matched/unmatched counts; it does not invalidate `joined_core`. |
| Join settings | Modelling/core joins support lags `0`, `1`, `3`, `6`, `12` and method `A` only. |
| Joined Flow fields | The canonical joined result exposes Q10/Q95 raw/Z fields and Flow-window provenance for all five supported lags in fixed order. Unselected lags remain typed `NA` columns. |
| Internal join keys | `win_no_lagX` is an internal lookup key and is removed after Flow-window provenance is derived. |
| Window duration | `flow_window_duration_lagX` is the inclusive number of calendar days from start through end. |

## Schema Boundaries

- **Workbook schema:** the multi-sheet XLSX contract used for standard user input and checkpoint validation.
- **Per-type CSV schema:** one exact ordered schema for each local Biology, Environmental, Flow, WQ and RHS upload.
- **Runtime schema:** temporary HE Toolkit fields may exist while an operation is running, but internal lookup fields must be removed at the relevant boundary.
- **Joined/export schema:** stable user-facing fields use the canonical five-lag order and do not expose `win_no_lagX`.

## Fixed Acceptance Checklist

This pass is accepted only when:

1. Correct CSVs pass; missing, unexpected and reordered fields fail with explicit messages.
2. Environmental alkalinity/proxy combinations pass or fail per row as frozen above.
3. WQ/RHS all-matched input succeeds; partial and zero matches block with counts.
4. Joined Flow fields cover lags 0/1/3/6/12 in canonical order and contain valid window provenance where selected.
5. Internal `win_no_lagX` fields do not persist in the canonical joined result.
6. Existing external import paths remain covered by regression tests.
7. Workbook validation, R parse checks, the complete automated suite and `git diff --check` pass.

## Review Stop Rule

Only data loss, incorrect calculation, a direct conflict with this frozen contract, a dashboard execution failure, a regression, or incorrect audit/provenance behaviour can block this pass. New formatting requests, future modelling work and unresolved client questions go to follow-up work rather than expanding this acceptance scope.
