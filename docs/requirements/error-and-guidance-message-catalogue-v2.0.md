# Error and Guidance Message Catalogue — v2.0

> Date: 25 August 2026  
> Status: **Controlled v2.0 catalogue; structural blockers frozen, complete severity matrix deferred under `OPEN-14`**  
> Historical baseline: [Week 8 complete error list](WK8-09_Complete_Error_List.md)  
> Authorities: [Data Contract v2.0](../contracts/data-contract-v2.0.md), [Dependency/State v2.0](../contracts/dependency-state-matrix-v2.0.md), [Modelling Contract v2.0](../contracts/modelling-contract-v2.0.md), [Task-Stage v2.0](../contracts/task-stage-path-matrix-v2.0.md), and [RTM v2.0](../contracts/requirement-traceability-matrix-v2.0.md)

## 1. Message and state rules

Raw R errors, stack traces, package names, console output, credentials, and local paths must not be shown to ordinary users. Technical details may be retained in access-controlled developer logs.

`Information`, `Warning`, and `Error` describe message presentation; they are not workflow states. Workflow effects use the eight states in Dependency/State v2.0. A pre-run blocker is `blocked`, an attempted action with no usable output is `failed`, and `warning` requires a usable current output.

Every displayed message identifies the affected file, record, site, branch, or action; explains the consequence; provides a next action; and preserves unrelated current outputs. Only the structural blockers explicitly frozen below are complete pending `OPEN-14`.

## 2. Task and Stage guidance

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `TASK-01` | User selects a disabled Stage | Information | No artifact state; navigation denied | This stage is not used for the selected Task. | Continue with the next required stage shown in the Task workspace. | `DEC-38`; `RTM-26` |
| `TASK-02` | Flow, WQ, or RHS input requested on Task 1 | Information | Action unavailable | Task 1 accepts Biology and site-environmental data only. | Change Task if you need to add Flow, WQ, or RHS data. | `DEC-38`; Task-Stage v2.0 |
| `TASK-03` | Start or Resume finds incomplete work | Information | Route to earliest required recoverable Stage | Continue from the earliest required stage that is not complete. | Follow the highlighted stage and checkpoint action. | Task-Stage v2.0; Dependency/State v2.0 |

## 3. Local CSV upload and structural validation

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `FILE-01` | No applicable file selected | Information | Input node remains `not_started` | No file has been selected yet. | Download the example for this data type, then select a CSV when ready. | `DC2-01`; `RTM-01` |
| `FILE-02` | File is unavailable after selection | Error | Affected input is `blocked` before import | The selected file is no longer available. | Select the file again and retry. | `DC2-01` |
| `FILE-03` | CSV cannot be parsed safely | Error | Affected file is `blocked` | This file could not be read as a valid CSV. | Use the example template, save as UTF-8 comma-separated CSV, and upload again. | `DC2-01`; `RTM-29` |
| `FILE-04` | Headers exist but no records | Error | Affected file is `blocked` | This file contains no data rows. | Add at least one valid record and upload again. | `DC2-01` |
| `FILE-05` | Unsupported primary upload type | Error | Affected file is `blocked` | This upload accepts CSV files only. | Export the data as CSV and retry. | `DEC-40`; `DC2-01` |
| `FILE-06` | Required header missing | Error | Affected file is `blocked` | This file is missing required columns: {fields}. | Add the named columns using the {data_type} template and upload again. | `DC2-01`; `RTM-29` |
| `FILE-07` | Duplicate header | Error | Affected file is `blocked` | This file contains duplicate column headings: {fields}. | Rename or remove duplicates so every heading is unique. | `DC2-01`; `RTM-29` |
| `FILE-08` | Unsafe required type | Error | Affected file is `blocked` | Some required values have an unsafe type: {fields}. | Correct the listed dates, numbers, or identifiers and retry. | `DC2-01`; `RTM-29` |
| `FILE-09` | Extra non-conflicting columns | Information | Valid file may remain `complete` | This file was accepted. Additional columns were ignored: {fields}. | Review the list; no action is required unless the wrong template was used. | `DC2-01`; `RTM-29` |
| `FILE-10` | File does not match selected data type | Error | Affected file is `blocked` | This file does not match the {data_type} template. | Choose the correct data type or upload a file using its example template. | `DC2-01` |

## 4. Source, identifier, and mapping guidance

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `SRC-01` | No Local/Explorer source selected | Information | Dependent action is `blocked` | Choose the current {data_type} source before continuing. | Select Local or Data Explorer. | `DC2-02`; `RTM-27` |
| `SRC-02` | Active source changes | Warning | Derived current outputs become `stale` | Results using the previous {data_type} source are out of date. | Regenerate the affected outputs shown by the Dashboard. | `DC2-02`, `DC2-06`; Dependency/State v2.0 |
| `SRC-03` | Combined source requested | Information | Mode unavailable; no state change | Combining Local and Data Explorer records is not available in this version. | Select one current source. | `OPEN-13`; `DC2-02` |
| `SRC-04` | HDE unavailable and NRFA succeeds | Warning | Flow output is usable with `warning` | HDE data were unavailable for {sites}; NRFA data were used instead. | Review the actual source and coverage before continuing. | `DEC-12`; `RTM-12` |
| `MAP-01` | Required identifier missing/blank | Error | Affected mapping/import is `blocked` | Required identifiers are missing: {fields_or_records}. | Complete the listed identifiers, preserving leading zeros, and retry. | Data Contract v2.0 |
| `MAP-02` | Unsupported RHS identifier | Error | RHS branch is `blocked` | RHS data must use `rhs_survey_id`. | Rename the source field at the permitted ingestion boundary and remove legacy duplicates. | `DEC-11`; `RTM-11` |
| `MAP-03` | Non-Biology coordinates absent | Information | No blocking effect | Coordinates are not required for Flow, WQ, or RHS data. | Continue with identifier mapping. | `DEC-43`; `RTM-22` |
| `MAP-04` | Extra non-Biology coordinate columns | Information | No blocking effect | Non-Biology coordinate columns were ignored. | No action is required unless the wrong template was uploaded. | `DEC-43`; `DC2-04` |
| `MAP-05` | Some identifiers do not match | Warning | Usable subset may be `warning` | Some records could not be matched: {identifiers}. | Review the listed identifiers and decide whether to correct the mapping or continue with reduced coverage. | `RTM-19`, `RTM-22` |

## 5. Data quality, core, and enrichment

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `DATA-01` | Required date invalid | Error | Affected action is `blocked` | Some required dates are missing or invalid: {records}. | Correct the listed dates and retry. | Data Contract v2.0 |
| `DATA-02` | Required numeric value invalid | Error | Affected action is `blocked` | Some required values are missing or are not valid numbers: {records}. | Correct the listed values and retry. | Data Contract v2.0 |
| `DATA-03` | Same-site/same-day Biology, Flow, or WQ conflicts | Error | Resolution-dependent action is `blocked` | Conflicting records were found for the same site and date. | Review the records and choose an available retain, average, or remove action. | `DEC-33`; `RTM-23` |
| `DATA-04` | Requested averaging is not safely supported | Error | Resolution action remains `blocked` | These records cannot be averaged safely with the current rules. | Retain or remove an eligible record, or leave the conflict unresolved. | `OPEN-10`; `RTM-23` |
| `DATA-05` | Same Biology month-year but different dates | Warning | Usable data may continue with `warning` | Multiple Biology samples occur in the same month and year. All records were retained. | Review the samples before analysis; no automatic aggregation was applied. | `DEC-23`; `RTM-23` |
| `CORE-01` | Biology/environment prerequisites missing | Error | O:E action is `blocked` | Expected values and O:E ratios cannot be calculated until the listed Biology or site-environmental inputs are ready. | Complete the named prerequisite and retry. | `RTM-02`, `RTM-16`, `RTM-17` |
| `CORE-02` | Flow statistics requested without current Flow | Error | Flow-statistics action is `blocked` | Select and validate a current daily Flow source before calculating Flow statistics. | Return to the Flow input and retry after validation. | `RTM-15`, `RTM-27` |
| `CORE-03` | Unsupported lag | Error | Join/statistic request is `blocked` | Select a supported lag: 0, 1, 3, 6, or 12. | Correct the lag selection and retry. | `DEC-39`; `RTM-03` |
| `CORE-04` | Core join prerequisites missing | Error | Core Join is `blocked` | The Joined HE dataset cannot be created until the listed prerequisites are current. | Complete the named O:E, Flow-statistics, identifier, or Join-setting step. | `RTM-19`; Dependency/State v2.0 |
| `CORE-05` | Core join returns no matches | Error | Attempted core Join is `failed` | No Biology and Flow records matched the current identifiers and settings. | Review identifiers, coverage, lags, and Join settings, then retry. | `RTM-19` |
| `CORE-06` | Core join excludes records | Warning | Current core output is `warning` | The Joined HE dataset was created, but some records could not be matched. | Review the excluded records before continuing. | `RTM-19` |
| `WQ-01` | WQ not selected | Information | WQ branch is `not_started` | WQ enrichment has not been selected. Core results can continue. | Add WQ later only if required. | Dependency/State v2.0 |
| `WQ-02` | Missing determinand | Error | WQ request is `blocked` | Select a WQ determinand before building the summary. | Choose the determinand and retry. | `DEC-42`; `RTM-28` |
| `WQ-03` | Start before 2000 or reversed range | Error | WQ request is `blocked` | Choose a valid WQ date range beginning on or after 1 January 2000. | Correct the start and end dates and retry. | `DC2-05`; `RTM-05` |
| `WQ-04` | Selected WQ request returns no usable output | Error | WQ branch is `failed`; core unaffected | No usable WQ records were produced for the selected sites, dates, and determinand. Core results remain available. | Review the selection and source, then retry only if enrichment is required. | Dependency/State v2.0 |
| `WQ-05` | WQ output uses a valid subset | Warning | WQ output is `warning`; core unaffected | The WQ summary was created, but some records were excluded or adjusted. | Review the affected records and provenance. | `RTM-05`, `RTM-06`, `RTM-24` |
| `RHS-01` | RHS not selected | Information | RHS branch is `not_started` | RHS enrichment has not been selected. Core results can continue. | Add RHS later only if required. | Dependency/State v2.0 |
| `RHS-02` | Selected RHS request returns no usable output | Error | RHS branch is `failed`; core unaffected | No usable RHS records were produced for the selected survey IDs. Core results remain available. | Review the identifiers and source, then retry only if enrichment is required. | Dependency/State v2.0 |
| `RHS-03` | RHS data validate but provide no eligible enrichment | Warning | Usable validation output may be `warning`; no preview plot | RHS data were read, but no eligible enrichment field is available. | Review `HQA` and `HMSRBB`; RHS preview plots are not provided. | `DEC-42`; `RTM-20`, `RTM-28` |

## 6. HEV and modelling

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `HEV-01` | Raw-daily mode lacks current daily Flow | Error | Raw-daily HEV request is `blocked` | Raw-daily HEV needs a current daily Flow dataset. | Select and validate Local or Data Explorer Flow, then retry. | `DEC-37`; `RTM-25` |
| `HEV-02` | Statistics mode lacks current Flow statistics | Error | Statistics HEV request is `blocked` | Flow-statistics HEV needs a current calculated Flow statistic. | Calculate and select the statistic, then retry. | `DEC-37`; `RTM-25` |
| `HEV-03` | Selected HEV mode fails | Error | Targeted HEV result is `failed`; other mode preserved | The selected HEV result could not be created. The other Flow mode was not substituted. | Review the mode-specific inputs and retry. | Dependency/State v2.0 |
| `HEV-04` | Flow heatmap cannot be generated | Error | Heatmap action is `failed`; other outputs preserved | The Flow heatmap could not be created with the current data. | Review the selected sites, dates, and values, then retry. | `DEC-48`; `RTM-32` |
| `MODEL-01` | No current analysis data | Error | Model action is `blocked` | Modelling needs a current Joined HE dataset and analysis revision. | Complete the required data stages or regenerate stale data. | Modelling Contract v2.0 |
| `MODEL-02` | Raw Q95 submitted | Error | Candidate request is `blocked` | Raw Q95 is not an eligible modelling predictor. Select Q95z. | Choose a supported Q95z lag field and retry. | `DEC-46`; `RTM-21` |
| `MODEL-03` | Builder limit exceeded | Error | Candidate request is `blocked` | The model selection exceeds the supported predictor or interaction limits. | Reduce the selection to the limits shown in the builder. | `DEC-45`; `RTM-09` |
| `MODEL-04` | Multiple-site structure/scientific setting unresolved | Information | Affected model path is `blocked` | This model structure is awaiting scientific review and cannot be verified yet. | Choose an available reviewed structure or wait for the modelling rule to be approved. | `OPEN-08`; `RTM-08B`, `RTM-10` |
| `MODEL-05` | Reviewed sufficiency rule not met | Error | Candidate request is `blocked` | There are not enough eligible complete records for this model. | Review exclusions, select better-supported variables, or provide more data. | Modelling Contract v2.0; `OPEN-08` |
| `MODEL-06` | GAM execution produces no usable candidate | Error | Candidate attempt is `failed`; history preserved | The candidate model could not be fitted with the current data and selections. | Review the formula, data messages, and exclusions, then retry with an eligible configuration. | `RTM-08A`, `RTM-08B` |
| `MODEL-07` | Candidates do not share a comparable sample basis | Error | Comparison is `blocked` | These candidate models cannot be compared fairly because they use different records. | Review the disclosed sample basis and create comparable candidates. | `DEC-47`; `RTM-30` |
| `MODEL-08` | No preferred model selected | Information | Diagnostics action is `blocked` | Select a preferred candidate before generating partial effects or diagnostics. | Compare the candidates and select one preferred model. | `DEC-47`; `RTM-30` |
| `MODEL-09` | Preferred-model diagnostics fail | Error | Diagnostics are `failed`; candidate/preferred fit preserved | Diagnostics could not be generated for the preferred model. The fitted candidate remains available. | Review the diagnostic message and model specification before retrying. | Modelling Contract v2.0 |

## 7. Output, progress, and fallback guidance

| ID | Trigger | Message type | Workflow effect | User-facing message | Next action | Authority |
|---|---|---|---|---|---|---|
| `OUTPUT-01` | One-site PCA request | Information | PCA action unavailable | PCA cannot be run with data from only one site | Add another eligible site or choose a different analysis. | `DEC-48`; `RTM-31` |
| `OUTPUT-02` | Current input/settings changed | Warning | Affected result is `stale` | This result is out of date because its source data or settings changed. | Regenerate the affected result before using or exporting it. | Dependency/State v2.0 |
| `OUTPUT-03` | Download requested without current result | Information | No state change | There is no current result available to download. | Create or regenerate the result, then retry. | Dependency/State v2.0 |
| `OUTPUT-04` | Download cannot be created | Error | Download attempt is `failed`; source result preserved | The download could not be created. | Retry once; if the problem continues, contact support with the Task and time. | Dependency/State v2.0 |
| `OUTPUT-05` | Measurable long operation is active | Information | Target remains `running` | {operation} is in progress: {progress}. | Wait; duplicate execution is disabled. | `DEC-48`; `RTM-33` |
| `OUTPUT-06` | Operation ends without usable result | Error | Target is `failed`; prior valid result preserved | The operation did not complete and no new result was saved. | Review the named cause and retry the affected action. | Dependency/State v2.0 |
| `OUTPUT-07` | Unexpected handled failure | Error | Smallest safe target is `failed` | Something unexpected prevented this step from completing. Existing valid results were preserved. | Retry once; if it happens again, record the Task, Stage, time, and selected options and contact support. | Dependency/State v2.0 |

## 8. Deferred boundaries

This catalogue does not define new severities or automatic handling for:

- the complete CSV warning/blocker matrix (`OPEN-14`);
- five cross-source record identity keys and `combined` conflict resolution (`OPEN-13`);
- the authoritative Biology-coordinate source (`OPEN-15`);
- missing WQ source units; or
- Biology date versus Year/Month/Season disagreement.

Until those rules are decided, the Dashboard must preserve inputs, avoid silent correction or overwrite, apply only the frozen structural blockers, and avoid claiming that the catalogue is complete.

## 9. Acceptance gate

Every implemented message must be tested for trigger, exact or parameterised text, presentation type, workflow effect, affected scope, next action, accessibility announcement, raw-detail suppression, and preservation of unrelated outputs. Browser evidence is required for representative Information, Warning, blocked, failed, stale, and recovery cases.

Any change that adds scientific meaning or changes a blocker/warning boundary requires a controlled decision before implementation.
