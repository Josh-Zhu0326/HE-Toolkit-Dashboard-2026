# Client HEV and Modelling Data Contract Check

Reviewed on: 2026-08-14

Source: latest client reply covering HEV thresholds, raw daily Flow, Flow statistics, window/lag/join settings, Q/Qz usage, and further user testing.

This check records what the current repository already supports, what is documented but not yet fully implemented, and which items are most relevant to the Data Pipeline workstream.

## Summary

The repository already records several client-confirmed requirements in the decision log and data contracts, especially `DEC-37`, `DC-12`, `DEC-03`, `DEC-21`, and `RTM-25`.

This implementation pass aligns the first set of client-confirmed settings in the Shiny workflow: HEV now exposes an explicit raw daily Flow versus Flow statistics mode, lag selection is restricted to 0/1, HEV Flow-statistic choices are reduced to raw Q10/Q95, and HEV provenance records the selected Flow mode.

The client attachment `HelperFunction.R` has now been reviewed. Threshold/status boundary values from lines 65-86 have been extracted into a dedicated HEV threshold helper instead of copying the legacy plotting function into the dashboard.

## Contract Check

| Area | Client-confirmed rule | Current repository evidence | Status | Follow-up action |
| --- | --- | --- | --- | --- |
| HEV Flow source modes | HEV should support both raw daily Flow and calculated Flow statistics. Raw daily Flow should not require `calc_flowstats()`. | `DEC-37`, `DC-12`, and `RTM-25` document this. `ui.R` now exposes `daily_flow` and `flow_statistics`; `server.R` checks mode-specific prerequisites. | Implemented in this pass | Continue regression testing with real client data. |
| HEV raw daily mode | Raw daily mode should use current validated daily Flow records. | `build_hev_daily_flow_data()` maps daily `flow_site_id/date/flow` records to biology sites and joins available O:E observations by `biol_site_id/date`. | Implemented in this pass | Confirm visual behaviour with the real HEV plotting function and real daily Flow data. |
| HEV Flow-statistics mode | Flow-statistics HEV remains valid, but only when current Flow Statistics exist. | Existing Flow-statistics path remains available and is selected explicitly through the HEV Flow mode control. | Implemented in this pass | Continue checking stale-state behaviour during manual testing. |
| HEV join settings | For HEV Flow-statistics, use `method = B` and `join_type = add_biol`. | `HEV_data_result()` now uses `method = "B"` with `join_type = "add_biol"`. | Implemented in this pass | Verify with the client's expected HEV output examples. |
| Modelling join settings | For modelling/joined analysis data, use `method = A` and `join_type = add_flows`. | `join_data_result()` uses `join_type = "add_flows"`; `ui.R` and `normalise_join_settings()` now restrict core join settings to method `A`. | Implemented in this pass | Continue checking downstream model selectors against DEC-21. |
| Lag values | Lag should be limited to `0` or `1`. | `ui.R` now exposes only 0 and 1. `normalise_join_settings()` also rejects unsupported lag values server-side. | Implemented in this pass | Keep regression tests for UI bypass attempts. |
| Window width and step | HEV Flow-statistics windows should be 6 months or 1 year, with width and step the same. Modelling windows should allow width 6-36 months and step 1-12 months. | Shared Flow-statistics width now starts at 6 months; step remains 1-12. HEV-specific 6/12 width-step equality is not yet separated from modelling. | Partial | Split HEV and modelling window controls, or validate contextual use before calculation/join. |
| Q values for HEV | HEV should use raw Q values, not Qz. Dashboard can focus on Q10 and Q95. | HEV selector now exposes only raw Q10 and Q95 for Flow-statistics mode; raw daily mode uses the canonical `flow` field. | Implemented in this pass | Verify with real HEV output expectations. |
| Qz values for modelling | Modelling should use standardised Q fields where cross-site comparability is needed. | `DEC-21` and `DC-08` say single-site models may use raw Q10/Q95, while multi-site mixed-effects models must use Q10z/Q95z. This is slightly more nuanced than the latest email wording. | Mostly documented | Keep the DEC-21 distinction unless the client explicitly supersedes it. Make UI/model validation explain raw Q versus Qz. |
| Status boundary lines | Threshold/status boundary lines should use confirmed metric-specific values. | `R/hev_threshold_helpers.R` records WHPT ASPT/NTAXA WFD bands and LIFE/PSI thresholds from `HelperFunction.R` lines 65-86. HEV plotting can draw these when the status-boundary option is selected. | Implemented in this pass | Confirm visual presentation with client example outputs. |
| Q/Qz explanation | Users need clear explanation of Q values and standardised Q values. | Existing UI labels expose Q/Qz names but do not explain them in user-facing terms. | Partial | Add concise help text/tooltips near HEV and modelling selectors. |
| Volunteer/testing items | Client mentions Katie/PJ and future testing volunteers. | This is project coordination rather than Data Pipeline implementation. | Not Di-owned | Record for testing/user-study owner. |

## Data Pipeline Ownership View

The items most relevant to Di/Data Pipeline are:

- Enforcing valid lag values (`0` and `1`) at UI/server validation boundaries. Implemented in this pass.
- Ensuring joined/analysis data exposes the agreed Q10/Q95 raw and Qz fields with lag 0/1 provenance.
- Confirming raw daily Flow can be passed to HEV without requiring Flow Statistics. Implemented in this pass.
- Keeping HEV mode provenance clear: mode, source dataset, source revision/fingerprint, mapped site IDs, date range, and selected Flow field/statistic. Implemented in this pass.
- Checking that modelling receives the correct Flow predictors for the selected model path.

The items that should be coordinated with other workstreams are:

- UI wording and selector layout for raw Q versus Qz.
- Final visual styling of HEV threshold/status boundary overlays against client example outputs.
- Final modelling interpretation and mixed-effects model behaviour.
- Volunteer contact and further user testing.

## Recommended Next Step

Before changing code, create or update implementation tasks for:

1. Complete the remaining HEV-specific window-control separation or contextual validation.
2. Run manual HEV checks with real daily Flow and Flow-statistics datasets.
3. Compare the threshold/status-boundary overlays against the client example outputs.
