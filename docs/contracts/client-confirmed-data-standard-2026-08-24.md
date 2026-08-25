# Client-Confirmed Data Standard

Frozen on: 2026-08-24

## Authority and Scope

This standard records Thomas Aspin's latest written answers about Flow lags,
modelling predictors, local-file formats, combined sources, and map
coordinates. It supersedes only conflicting earlier decisions. Unrelated
contracts remain unchanged.

Implementation must follow this precedence:

1. This client-confirmed standard, `SRC-09`, and `SRC-10`.
2. The controlled decisions in `client-decision-log-v1.md`.
3. The system invariants in `data-contract-v1.md`.
4. The acceptance criteria in `requirement-traceability-matrix-v1.md`.
5. Existing code, templates, demos, and historical test records.

## Frozen Rules

| Area | Frozen rule |
|---|---|
| Flow lags | Joining, joined outputs, provenance, and model predictor selection support lags `0`, `1`, `3`, `6`, and `12` months. Lag 3 must not be omitted from Stage 5. |
| Joined Flow fields | Q10 and Q95 raw and Z-score fields are retained for every supported lag, together with per-lag Flow-window provenance. Q50 is descriptive only. |
| Model predictors | Q10z and Q95z lag fields may be used in both model paths. A single-site model may additionally expose raw Q95 lag fields. Multi-site models must reject all raw Flow predictors. Raw Q10 is not added to the model selector by this confirmation. |
| Local files | The formal local-upload route uses five separate CSV files: Biology, Environmental/Site, daily Flow, WQ, and RHS. CSV is the only user-facing local template/upload format. Existing XLSX code may remain solely as an internal historical migration utility and must not appear in the Dashboard. |
| Combined sources | Local data must not silently override Data Explorer data. Conflicting records are flagged and require an explicit user source choice. No combined-source record may be silently deleted or deduplicated. |
| Exact duplicates | The client's reply did not separately confirm automatic removal of exact duplicates. Until confirmed, retain and flag them; do not silently remove them. |
| Map and coordinates | The Stage 1 map displays Biology sites only. Only Biology coordinates remain in the user-facing mapping contract. Flow, WQ, and RHS identifiers remain available for explicit site mapping, but their coordinate fields are removed. |

## Required Acceptance Boundaries

1. The lag selector and server accept exactly `0`, `1`, `3`, `6`, and `12`.
2. Joined data expose the complete fixed-order Q10/Q95 raw/Z and provenance
   fields for all five lags; unselected lag fields remain typed `NA`.
3. Stage 5 exposes only model-path-eligible Flow predictors and rejects an
   ineligible server-side submission.
4. Each of the five CSV types follows the source schema frozen in `DC-13`, has
   a downloadable example, upload-time validation, an explicit one-way
   canonical conversion, and an active downstream route.
5. Combined-source conflicts show both candidate records and remain blocking
   until the user chooses the source to retain.
6. Identical combined-source records are retained and flagged until a later
   decision explicitly authorises removal or aggregation.
7. The Stage 1 map and downloadable input standards contain no Flow, WQ, or RHS
   coordinate fields.

## Explicit Non-Decisions

- The exact dissolved-oxygen determinand remains under `OPEN-02`.
- Detailed automatic handling of exact duplicates remains open; no silent
  deletion is permitted.
- Whether `TOTAL_HARDNESS` and `CALCIUM` remain optional Environmental CSV
  columns is tracked under `OPEN-12`; until resolved, they are accepted in the
  fixed optional position and normalised to typed `NA` when absent.
- GAM families, smoothing controls, and diagnostics remain under `OPEN-08`.
- The standalone XLSX/CSV validation page is removed. Validation and an example
  CSV belong in each of the five dataset views.

## Traceability

- Decisions: `DEC-38` to `DEC-48`
- Requirements: `RTM-01`, `RTM-03`, `RTM-14`, `RTM-18`, `RTM-21`, `RTM-22`,
  and `RTM-26`
- Sources: `SRC-09` and `SRC-10`

The complete Task, WQ/RHS, validation-placement, map-popup, and operational
acceptance checklist is maintained in
[`client-feedback-implementation-standard-2026-08-25.md`](client-feedback-implementation-standard-2026-08-25.md).
