# Warning and Error Rule List for Client Review

Date: 2026-07-02  
Branch: `docs/warning-error-rule-list`  
Purpose: collect the warning/error rules observed during local dashboard testing so the client can confirm severity, wording, and expected user behaviour before broader code changes are implemented.

## 1. Severity Definitions

| Severity | Meaning | Should the workflow continue? |
|---|---|---|
| Error | The input or previous workflow step is missing, invalid, or would produce unreliable results. | No. The user must fix the issue first. |
| Warning | The app can continue, but the result may be incomplete, partly unavailable, or should be interpreted carefully. | Yes, if enough valid data remains. |
| Info | Guidance or confirmation that helps the user understand the next step or result. | Yes. |

## 2. Current Design Principle

In the current design, biology and flow data are treated as the core workflow. WQ and RHS data are treated as optional additional datasets. If WQ or RHS data is not available, the dashboard should still allow users to continue with the original biology-flow workflow.

The current app can import WQ/RHS data, map records to biology site IDs for preview, and add optional site-level `wq_*` and `rhs_*` summary columns to the joined HE dataset. The first implementation uses conservative site-level summaries; the exact WQ aggregation windows, determinands, RHS variables, and modelling use should still be confirmed with the client.

The general rule is:

- **Error**: the workflow cannot continue until the problem is fixed.
- **Warning**: the workflow can continue, but users should understand that the output may be incomplete.
- **Info**: the step has been completed successfully, or the user needs simple guidance for the next action.

## 3. Client Confirmation Needed

Please confirm:

1. Whether each proposed severity is correct.
2. Whether the suggested user-facing message is understandable for non-coder users.
3. Whether warnings should allow users to continue or should block downstream workflow steps.
4. Whether WQ and RHS should remain optional additional datasets.
5. Whether the current site-level WQ/RHS summary approach is acceptable, or whether time-window and variable-specific rules are required.
6. Whether any rules should be prioritised for implementation in the next sprint.

## 4. Proposed Rules

| Rule ID | Workflow step | Trigger condition | Current/observed behaviour | Proposed severity | Proposed user-facing message | User action | Client confirmation needed |
|---|---|---|---|---|---|---|---|
| META-001 | Import datasets | Metadata input is empty. | App shows a validation message. | Error | Please add site metadata before importing data. | Paste or upload metadata. | Confirm wording. |
| META-002 | Import datasets | Required metadata columns are missing for the selected import action. | Some validation exists, but messages are inconsistent across modules. | Error | Metadata must include the required columns for this step: `{required_columns}`. | Add the missing column(s). | Confirm required columns for each data type. |
| META-003 | Import datasets | `flow_input` is blank or not one of the supported values. | Known risk: invalid values can interrupt the workflow. | Error | Flow input must be either `HDE` or `NRFA`. Please check the `flow_input` column. | Correct `flow_input`. | Confirm supported values and whether more values are expected. |
| META-004 | Import datasets | Site IDs are pasted as numeric values rather than text. | Known project issue: numeric IDs may fail in some paths. | Warning first; Error only if conversion or joining fails. | Site IDs should be treated as text. The app will try to convert them automatically, but please check the ID format if joining fails. | Re-paste IDs or upload a corrected file if needed. | Confirm whether the app should automatically coerce IDs to text. |
| META-005 | Import datasets | Site metadata CSV is uploaded and parsed successfully. | Observed success message in the app. | Info | Site metadata imported successfully. Parsed ID columns: `biol_site_id`, `flow_site_id`, `wq_site_id`, `rhs_survey_id`. | Continue to data import. | Confirm whether this confirmation message is useful. |
| BIO-001 | Import datasets | Biology import is requested before valid `biol_site_id` values are available. | App may show no output or a generic validation message. | Error | Please provide at least one valid `biol_site_id` before importing biology data. | Add valid biology site IDs. | Confirm wording. |
| BIO-002 | Process invertebrate data | RICT predictions are requested before biology data is imported. | Alert appears in some cases. | Error | Please import biology data before running RICT predictions. | Return to Import datasets and import biology data. | Confirm wording. |
| BIO-003 | Process invertebrate data | O:E ratios are requested before RICT predictions have been generated. | Alert appears in some cases. | Error | Please run RICT predictions before calculating O:E ratios. | Run RICT predictions first. | Confirm wording. |
| WQ-001 | Import datasets | WQ import is requested but metadata has no `wq_site_id` column. | Newly added WQ workflow depends on `wq_site_id`. | Error | Please provide a `wq_site_id` column before importing water quality data. | Add WQ site mapping. | Confirm whether alternative WQ ID columns should be accepted. |
| WQ-002 | Import datasets | `wq_site_id` values are blank, `NA`, or `TBC`. | App should not attempt confirmed imports for unconfirmed mappings. | Warning | No confirmed WQ site IDs are available yet. Please provide confirmed `wq_site_id` values to import WQ data. | Add confirmed WQ IDs. | Confirm whether `TBC` should be treated as warning or error. |
| WQ-003 | Import datasets | WQ API returns data but some requested determinands are unavailable. | Observed warning for determinands `0162` and `0019`; import still returned records. | Warning | WQ data was imported, but some determinands were not available from the source. Results may be incomplete. | Review imported WQ table and notes. | Confirm whether missing determinands should block later modelling. |
| WQ-004 | Import datasets | WQ data is imported successfully. | Local test imported 26 WQ records for the test WQ site. | Info | WQ data imported successfully. | Continue to data checking. | Confirm whether record counts should be shown. |
| RHS-001 | Import datasets | RHS import is requested but metadata has no `rhs_survey_id` column. | Newly added RHS workflow depends on survey IDs. | Error | Please provide a `rhs_survey_id` column before importing RHS data. | Add RHS survey IDs. | Confirm whether RHS site IDs should ever be used as survey IDs. |
| RHS-002 | Import datasets | `rhs_survey_id` values are blank, `NA`, or `TBC`. | App should not import unconfirmed mappings. | Warning | No confirmed RHS survey IDs are available yet. Please provide confirmed `rhs_survey_id` values to import RHS data. | Add confirmed RHS survey IDs. | Confirm whether `TBC` should be warning or error. |
| RHS-003 | Import datasets | Local RHS CSV is uploaded without an identifier column. | Existing validation expects `rhs_survey_id` where possible. | Error | Your RHS file is missing a survey identifier column. Please include `rhs_survey_id` where possible. | Correct the uploaded CSV. | Confirm acceptable fallback ID columns. |
| RHS-004 | Import datasets | RHS upload is valid but no records match the site metadata. | Potential empty output. | Warning | RHS data was loaded, but no records matched the current site metadata. | Check mapping IDs. | Confirm whether this should block joining/modelling. |
| RHS-005 | Import datasets | User clicks Import RHS before uploading an RHS CSV file. | Observed during local workflow testing. | Error | Please upload an RHS CSV file before importing RHS data. | Upload an RHS CSV file. | Confirm wording. |
| RHS-006 | Import datasets | RHS data is uploaded and imported successfully. | Local test used one RHS test record with habitat variables. | Info | RHS data imported successfully. | Continue to data checking. | Confirm whether record counts should be shown. |
| FLOW-001 | Import datasets | Flow import is requested without valid `flow_site_id` and `flow_input`. | App may show validation messages. | Error | Please provide `flow_site_id` and `flow_input` before importing flow data. | Add flow metadata. | Confirm wording. |
| FLOW-002 | Import datasets | Duplicate site/input combinations are found. | Observed warning: duplicate site-input combinations were dropped. | Warning | Duplicate flow site/input combinations were found and duplicate rows were ignored. | Review metadata for repeated sites. | Confirm whether duplicates should be automatically dropped or block import. |
| FLOW-003 | Process flow data | Donor mapping text box is empty before imputation. | App shows a validation message. | Error | If imputing flows, please add donor mapping. | Paste donor mapping. | Confirm whether imputation should also support automatic donor selection. |
| FLOW-004 | Process flow data | Donor mapping has fewer than two columns. | Previously could lead to unclear downstream errors. | Error | Donor mapping must contain two columns: `station` and `donor_station`. | Correct donor mapping table. | Confirm column names. |
| FLOW-005 | Process flow data | A station in donor mapping is not present in imported flow data. | Observed during testing; app now shows a clearer validation message. | Error | One or more stations in the donor mapping were not found in the imported flow data. | Check that `station` values match imported `flow_site_id` values. | Confirm wording. |
| FLOW-006 | Process flow data | Donor station is listed in donor mapping but has not been imported. | Observed during testing. | Error | One or more donor stations have not been imported yet. Add them to the donor list and click `Import additional donor flow data` first. | Add donor station to donor list and import it. | Confirm wording and workflow. |
| FLOW-007 | Process flow data | Equipercentile imputation is run with fewer than two flow stations. | Observed error from `hetoolkit::impute_flow`: minimum two stations required. | Error | Please add at least one additional donor station and click `Import additional donor flow data` before imputing. The equipercentile method needs at least two flow stations. | Import donor flow data first. | Confirm whether other imputation methods should be offered for single-station cases. |
| FLOW-008 | Process flow data | Donor list is empty but donor mapping requires extra donor sites. | App shows a validation message. | Error | If imputing flows, please add additional donor sites as required. | Paste donor list. | Confirm wording. |
| FLOW-009 | Process flow data | Donor list has invalid `flow_input` values. | Existing validation allows only `HDE` or `NRFA`. | Error | Please ensure all donor flow inputs are listed as either `HDE` or `NRFA`. | Correct donor list. | Confirm supported values. |
| FLOW-010 | Process flow data | Flow statistics calculation is requested before flow data exists. | Alert appears in some cases. | Error | Please import flow data before calculating flow statistics. | Import flow data first. | Confirm wording. |
| FLOW-011 | Process flow data | Flow statistics calculation fails because imputed/final flow data is not available or invalid. | Can appear as missing output. | Error | Flow statistics could not be calculated. Please check that flow data has been imported and, if required, imputed successfully. | Review flow import/imputation steps. | Confirm whether raw flow data can be used when imputation is skipped. |
| JOIN-001 | Join HE data | Pairing is requested before O:E ratios exist. | Alert may appear depending on prior state. | Error | O:E ratios are missing. Please calculate O:E ratios before joining biology and flow data. | Return to Process invertebrate data. | Confirm wording. |
| JOIN-002 | Join HE data | Pairing is requested before flow statistics exist. | Observed alert: `Flow statistics are missing`. | Error | Flow statistics are missing. Please calculate flow statistics before joining biology and flow data. | Return to Process flow data and calculate flow statistics. | Confirm wording. |
| JOIN-003 | Join HE data | Selected lag/join method produces no matched records. | Potential empty joined table. | Warning | No joined records were produced for the selected lag and join method. Please try another setting or check the input data. | Change lag/method or review data. | Confirm whether this should be warning or error. |
| JOIN-004 | WQ/RHS integration | WQ records are available with `biol_site_id` and the user creates the joined HE dataset. | Current implementation adds site-level `wq_*` summary columns to `join_data()`. | Info | WQ summary columns have been added to the joined HE dataset. | Continue to checking, visualisation or modelling. | Confirm whether site-level summaries are acceptable or whether date-window aggregation is required. |
| JOIN-005 | WQ/RHS integration | RHS records are available with `biol_site_id` and the user creates the joined HE dataset. | Current implementation adds site-level `rhs_*` summary columns to `join_data()`. | Info | RHS summary columns have been added to the joined HE dataset. | Continue to checking, visualisation or modelling. | Confirm which RHS metrics should be included. |
| JOIN-006 | Future WQ/RHS integration | Join keys have inconsistent data types across datasets, for example character vs integer. | Potential integration risk when WQ/RHS variables are joined to the HE dataset. Current join code already converts biology and flow IDs to character. | Error | Some site ID fields have inconsistent formats and could not be joined. Please check that all site IDs are stored as text. | Check ID columns or allow automatic text conversion. | Confirm whether the app should automatically convert all join keys to text. |
| TABLE-001 | Data table display | A joined or preview data table cannot be rendered because the data contains unsupported/list-type columns or hidden errors. | General diagnostic rule for future robustness; not specific to the current core biology-flow join. | Error | The data table could not be displayed. Please check the data format or previous processing step. | Review the previous processing/join step and data format. | Confirm whether this should show a more specific diagnostic message. |
| HEV-001 | HEV | User opens HEV page before joined data exists. | Controls may appear but plot area is empty. | Error | Joined data is missing. Please pair biology and flow data before creating an HEV plot. | Complete Join HE data step. | Confirm wording. |
| HEV-002 | HEV | User selects site/index/flow metric/date range with no available records. | Plot area can remain blank. | Warning | No records are available for this site, biomonitoring index, flow metric, and date range. | Change selection or date range. | Confirm whether no-data plots should show a blank plot with explanation. |
| HEV-003 | HEV | User has selected valid parameters but has not clicked `Create HEV plot`. | Plot area remains blank until action button is clicked. | Info | Select options and click `Create HEV plot` to generate the figure. | Click button. | Confirm whether this guidance should be displayed on the page. |
| MODEL-001 | Modelling MVP | User runs a model before joined data exists. | Future workflow requirement. | Error | Please create the joined HE dataset before running a model. | Complete Join HE data first. | Confirm wording. |
| MODEL-002 | Modelling MVP | Response variable or predictor variable is not selected. | Future workflow requirement. | Error | Please select one response variable and one predictor variable. | Select variables. | Confirm wording. |
| MODEL-003 | Modelling MVP | Selected response or predictor variable is not numeric. | Future workflow requirement. | Error | The selected variables must be numeric for this model. | Select numeric variables. | Confirm whether categorical predictors should be supported later. |
| MODEL-004 | Modelling MVP | Selected variables contain missing values. | Future workflow requirement. | Warning | Some rows contain missing values and will be removed from the model. | Continue or choose different variables. | Confirm acceptable missing-data behaviour. |
| MODEL-005 | Modelling MVP | Model runs successfully. | Future workflow requirement. | Info | Model completed successfully. Please review the plot and model summary. | Review outputs or download results. | Confirm expected outputs. |
| SETUP-001 | Developer setup documentation | User opens the old project folder or a backup folder in RStudio. | Observed RStudio warning/error when old `HE-Toolkit-Dashboard-2026-main` path no longer existed. | Documentation note, not an app rule. | The selected project folder cannot be found. Please open the current `HE-Toolkit-Dashboard-2026` project. | Open the correct `.Rproj` file. | Confirm this belongs in developer/user setup documentation rather than the app. |

## 5. Rules Observed During Local Testing

The following issues or behaviours were directly encountered during local testing:

- `FLOW-005`: donor mapping station did not match imported flow data.
- `FLOW-006`: donor station was listed but not imported yet.
- `FLOW-007`: equipercentile imputation failed when only one flow station was available.
- `JOIN-002`: joining failed because flow statistics had not yet been calculated.
- `HEV-003`: HEV page appeared blank before the user clicked `Create HEV plot`.
- `WQ-003`: WQ import succeeded but showed non-fatal missing determinand warnings for `0162` and `0019`.
- `META-005`: metadata CSV upload succeeded and the app displayed the parsed ID columns clearly.
- `RHS-005`: RHS import was requested before an RHS CSV file was uploaded.
- `SETUP-001`: RStudio was initially opened against an old or backup project path. This should be handled in setup documentation rather than as an app warning.

The following WQ/RHS join rules now have an initial implementation, but still need client confirmation:

- `JOIN-004`: WQ variables are added as optional site-level summary columns after they are available with `biol_site_id`.
- `JOIN-005`: RHS variables are added as optional site-level summary columns after they are available with `biol_site_id`.
- `JOIN-006`: WQ/RHS join keys should be normalised to avoid character/integer mismatches.
- `TABLE-001`: table rendering errors should show a clear diagnostic message instead of a generic frontend failure.

## 6. Recommended Next Implementation Priority

| Priority | Rule IDs | Reason |
|---|---|---|
| High | `META-002`, `META-003`, `FLOW-005`, `FLOW-006`, `FLOW-007`, `JOIN-001`, `JOIN-002`, `HEV-001` | These prevent workflow interruption and make required previous steps clear in the current core biology-flow workflow. |
| Medium | `WQ-001`, `WQ-002`, `WQ-003`, `WQ-004`, `RHS-001`, `RHS-002`, `RHS-003`, `RHS-004`, `RHS-005`, `RHS-006`, `FLOW-002`, `FLOW-011`, `JOIN-004`, `JOIN-005`, `JOIN-006`, `TABLE-001`, `HEV-002` | These improve data-quality transparency and support refinement of the current WQ/RHS integration. |
| Low | `META-005`, `HEV-003`, `MODEL-001` to `MODEL-005`, `SETUP-001` | These are guidance, future modelling, or documentation improvements rather than immediate core workflow blockers. |

## 7. Open Questions for Client

1. Should `TBC` mapping values always be treated as unavailable, or should users be allowed to import partial datasets with `TBC` rows skipped?
2. Should duplicate flow metadata rows be automatically dropped, or should the app stop and ask users to remove duplicates?
3. Should missing WQ determinands block modelling, or should the dashboard continue with a warning?
4. Should RHS records be imported only by `rhs_survey_id`, or should `rhs_site_id` be supported in a separate workflow?
5. Should the flow imputation page offer non-donor methods such as linear or exponential imputation when only one flow station is available?
6. Should empty HEV outputs display a placeholder message directly in the plot area?
7. Is the current confirmation message shown after WQ/RHS data are added to the joined dataset useful for non-coder users?
8. Should the dashboard show a join summary, for example number of matched and unmatched WQ/RHS records?
9. Should all join keys be automatically converted to text before joining?
10. Should the future modelling MVP remove missing rows automatically with a warning, or should users choose how to handle missing data?
11. Should local setup issues, such as opening the wrong project folder, be documented separately from app warning/error rules?

## 8. Suggested Client Review Summary

For client review, the key design decision is that the dashboard should separate blocking errors from non-blocking data-quality warnings. Biology and flow should remain the core required workflow. WQ and RHS should enrich the joined HE dataset where available, but their absence should not stop users from completing the original biology-flow analysis unless the user has explicitly selected WQ/RHS import or modelling based on those variables.

The most important client confirmations are:

- whether WQ/RHS should remain optional datasets;
- whether the proposed ID fields are correct;
- whether unmatched or missing WQ/RHS records should be warnings rather than errors;
- whether the current WQ/RHS site-level summary join is acceptable for the next review;
- whether the app should show matched/unmatched record summaries after joining;
- whether the future modelling MVP should automatically remove rows with missing values or ask the user first.
