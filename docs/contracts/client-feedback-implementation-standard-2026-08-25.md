# Client Feedback Implementation Standard - 25 August 2026

> Status: Controlled implementation baseline
>
> Authority: `SRC-09` client attachment plus the later `SRC-10` clarification
>
> Rule: `SRC-10` overrides `SRC-09` only where the later reply is explicit

## 1. Purpose

This document turns the latest client feedback into one implementation and
acceptance checklist. It separates a confirmed requirement from current code
status so that an existing demo cannot be mistaken for an approved standard.

Owner names below follow the established team roles. A named implementation
partner does not replace the accountable owner or reviewer.

## 2. Confirmed Standard and Current Gap

| Area | Confirmed requirement | Accountable owner / reviewer | Current baseline assessment | Required evidence |
|---|---|---|---|---|
| Task paths | Tasks 1-5 stop after Stages 2, 2, 3, 4, and 5 respectively. Unused later Stages are disabled. Task 1 offers Biology and Environmental/Site import only. | Lin / Bo | Partial: the earlier configuration contains optional later Stages. | Exact configuration and navigation tests for all five paths and Task 1 import visibility. |
| Local files | The user-facing route consists of five separate CSV files: Biology, Environmental/Site, daily Flow, WQ, and RHS. Each data view supplies its own example and blocking validation message. No user-facing XLSX route or standalone validation page remains. | Di / Benyu; Lin implements view placement | Partial: CSV controls and shared validators exist, but the competing validation sandbox and incomplete per-view routes remain. | Five schema/template/upload/routing tests plus a navigation test proving the standalone route is absent. |
| Combined sources | Local and Data Explorer records retain source identity. Conflicts are flagged and block continuation until the user chooses a source. No record is silently overwritten, removed, or deduplicated. | Di / Benyu | Partial: the final explicit conflict-resolution boundary is not complete. | Identity, conflict, explicit-choice, provenance, no-data-loss, and stale-propagation tests. |
| Flow statistics | Joining and modelling support lags 0, 1, 3, 6, and 12. Joined data retain Q10/Q95 raw and Z-score fields for each lag; Q50 remains descriptive. | Di / Benyu | Partial: the current path does not yet provide the full five-lag contract end to end. | Fixed-order joined-schema, provenance, selector, server-bypass, and numerical tests. |
| Model predictors | Both paths may use Q10z/Q95z. Single-site modelling may additionally use raw Q95 when feasible; multi-site modelling rejects raw Flow predictors. | Lin / Di | Partial and subject to `OPEN-08` for the final model engine. | Selector and server validation tests for both paths; engine-specific evidence after `OPEN-08`. |
| WQ processing and preview | Build WQ Summary belongs to Stage 2. Dates before 2000-01-01 are unavailable. Preview plots appear before the summary, toggle with results, offer time series or boxplot only, fix `date_time`/`result`, require a determinand, and group by `wq_site_id`. RHS preview plots are removed. | Di / Benyu; Lin implements UI controls | Partial: some WQ data helpers exist, but the confirmed interaction and Stage placement are incomplete. | Date-boundary, determinand/site filtering, plot-type, table/plot toggle, Stage-placement, and no-RHS-plot tests. |
| Site map | Display Biology markers only. Remove non-Biology coordinate fields. Popups show available Biology site ID, water body, sample count, and sample-year range; missing optional metadata does not suppress a valid marker. | Lin / Bo; Di supplies the data contract | Not started against the complete confirmed popup contract. | Prohibited-coordinate tests and map tests with complete and partial popup metadata. |
| PCA and operational UX | One-site PCA shows `PCA cannot be run with data from only one site`. Flow heatmaps work. Long operations provide informative progress. Content uses available screen width, tables/plots are navigable and legible, and appropriate model values use three significant figures. | Lin / Bo; Benyu supplies QA evidence | Partial: these items need objective acceptance evidence rather than visual sign-off alone. | Exact-message test, Flow-heatmap regression, progress/manual timing evidence, responsive screenshots, table/plot checks, and numeric-format tests. |
| Final modelling engine | The attachment proposes `mgcv::gam()` workflows, smooths/interactions, diagnostics, comparison and iterative refinement. These details are not frozen because the client expects further scientific input. | Lin / Di | Blocked by `OPEN-08`; existing `lm`/`lmer` helpers are provisional. | Client/scientific confirmation followed by formula, diagnostics, comparison, export, and numerical-parity tests. |

## 3. Data Schemas

The exact five source schemas and their one-way canonical conversions are
defined only in `DC-13` of
[`data-contract-v1.md`](data-contract-v1.md). Do not duplicate or silently
rename those fields in UI code, fixtures, or download helpers.

`TOTAL_HARDNESS` and `CALCIUM` remain governed by `OPEN-12`. Dissolved oxygen
P10 remains governed by `OPEN-02`. Neither uncertainty blocks the confirmed
CSV route, orthophosphate mean, or ammonia P90 work.

The Environmental CSV uses `NGR_10_FIG`; validated ingestion derives internal
`NGR_PREFIX`. The five-file confirmation does not define a sixth site-mapping
CSV, so the exact in-app creation and persistence of Biology-to-Flow/WQ/RHS
identifier mappings remains under `OPEN-13`. Equal identifier text must never
be treated as an implicit mapping.

## 4. Change-Control Rules

1. The decision log defines what was confirmed; the RTM defines acceptance and
   implementation status; current UI behaviour is evidence, not authority.
2. A superseded XLSX, lag, coordinate, or optional-Stage assumption must not
   drive new work.
3. A requirement moves to `Verified` only with reproducible evidence linked in
   the RTM.
4. Scientific choices under `OPEN-02`, `OPEN-08`, or `OPEN-12` must not be
   guessed in code.
5. Any later client answer receives a new source ID and decision entry before
   implementation changes are accepted.

## 5. Traceability

- Decisions: `DEC-38` to `DEC-48`
- Data contracts: `DC-08`, `DC-10`, `DC-11`, `DC-13`, `DC-14`, `DC-15`
- Requirements: `RTM-01`, `RTM-03`, `RTM-18`, `RTM-21`, `RTM-22`, and
  `RTM-26` to `RTM-31`
- Sources: `SRC-09`, `SRC-10`
