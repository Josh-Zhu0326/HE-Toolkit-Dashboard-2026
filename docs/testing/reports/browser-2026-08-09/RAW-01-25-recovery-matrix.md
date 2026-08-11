# RAW-01–25 Recovery Coverage Audit

Historical audit date: 2026-07-30
Final corrective-review verification: 2026-08-09 on `qa/raw-user-facing-recovery`.
Final verified code baseline: `99b2a04` (committed local verification baseline).

## 1. Audit Baseline

### Current final automated-gate baseline

| Item | Value |
|---|---|
| Branch | `qa/raw-user-facing-recovery` |
| Final verified code baseline | `99b2a04` (committed local verification baseline) |
| Verification worktree | Clean after the temporary testthat-generated `Rplots.pdf` artifact was removed |
| Full testthat | 165 cases; 1176 expectations; 1176 passed; 0 failures; 0 errors; 0 warnings; 0 skips; exit code 0 |
| Standalone scripts | 18/18 exited 0; 16 Pass; 2 Pass with Warning; 0 Fail |
| Historical Pass with Warning | `tests/test_mixed_model_helpers.R`; `tests/test_server_site_import.R` |
| Browser/manual verification | Final browser/manual smoke session completed separately; see row-level results and the final report |

### Historical audit baseline

The original 2026-07-30 audit ran on local `main` at `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca`, with the locally cached `origin/main` at the same commit and a pre-existing untracked `docs/week09/` directory. That historical dirty-worktree observation and the original OS/R/tooling details remain provenance for the initial audit; they are not the current branch or worktree state.

Interpretation used in this audit:

- **Documented** means the RAW definition exists in the authority below.
- **Implemented** means the scoped runtime recovery path prevents or handles the scenario.
- **Automated test exists** means a test asserts this scenario or a close, explicitly identified slice. Merely loading the file does not count.
- **Executed current branch** means that linked automation was run at the final automated-gate commit.
- **Browser/manual verification** is separate from automated coverage and is recorded from the completed final smoke session at row level.
- A row-level automated `Pass` does not imply destructive browser fault injection; any unexecuted browser injection is stated explicitly.

## 2. Source of RAW-01–25

The authoritative source is `docs/requirements/5.3_Error_List.md`.

- Lines 7–31 define exactly one row each for `RAW-01` through `RAW-25`.
- The identifiers are continuous, unique, and complete: 25 definitions, no missing ID and no duplicate ID.
- Lines 33–39 add common acceptance criteria: friendly UI message; no raw R error, stack trace, or local path; loading state must end; other pages/controls remain usable; repeated clicks must be prevented while processing.
- `docs/requirements/WK8-09_Complete_Error_List.md` is useful later guidance, especially `OUTPUT-08` to `OUTPUT-12`, but uses a different identifier scheme and does not replace the RAW authority.
- Historical July test records and `docs/project/audits/2026-07-30-benyu-return-audit.md` are supporting evidence only, not definitions or current browser/manual execution.

Conclusion: a complete RAW-01–25 definition set does exist.

## 3. Coverage Summary

### Current disposition coverage

| Disposition | RAW IDs | Current evidence state |
|---|---|---|
| Implemented / scoped recovery complete | RAW-02–RAW-10, RAW-12–RAW-19, RAW-21–RAW-24 | Implementation complete; final browser/manual outcomes are recorded per row, including qualified automated-only fault-recovery evidence where applicable. |
| RAW-11 | RAW-11 | Implemented with direct passing workflow-server automation and passing final browser prerequisite verification. |
| Superseded / N/A | RAW-20 | No additional production implementation or dedicated browser screenshot required. |
| Deferred / Known limitation | RAW-25 | Not implemented in the current scope; future dedicated lifecycle/refactoring work recommended. |
| Pass (implementation + automated verification) | RAW-01 | Dependency preflight and server recovery are implemented and automated tests pass. Missing-`ggnewscale` browser dependency injection was Not Executed and is not claimed. |

All 25 RAW identifiers remain documented. RAW-labelled deterministic tests exist for multiple recovery paths alongside cross-cutting workflow tests. Automated coverage and browser/manual verification are reported separately, with RAW-01 passing on implementation plus automation while its browser dependency-failure injection remains Not Executed, RAW-20 Superseded / N/A and RAW-25 Deferred / Known Limitation.

### Command-level result

The final automated regression suite was executed against committed baseline `99b2a04`. The testthat gate passed 165 cases and 1176 expectations (1176 passed) with 0 failures, 0 errors, 0 warnings and 0 skips. The standalone gate had 18/18 established scripts exit 0: 16 Pass, 2 historical Pass with Warning, and 0 Fail. The two Pass with Warning scripts are `tests/test_mixed_model_helpers.R` and `tests/test_server_site_import.R`; no new warning category was introduced. Browser/manual results come from the completed final session plus the focused RAW-18 corrective smoke, not from this automated gate.

## 4. RAW-01–25 Matrix

### RAW-01

| Field | Required content |
|---|---|
| RAW ID | RAW-01 |
| Error scenario | Missing `ggnewscale` package exposes a raw dependency error when HEV plotting uses a second colour scale. |
| Trigger | Render an HEV path that reaches `ggnewscale::new_scale_color()` without the package installed. |
| Affected workflow/task | Task “Generate HEV plots”; Stage 4 Analysis / HEV feature. |
| Blocking classification | Blocking |
| Expected user-facing message | “The required package ggnewscale is missing. Please install project dependencies before using the HEV plot feature.” |
| Implemented message | “The required package ggnewscale is missing. Please install project dependencies before using the HEV plot feature.” |
| Recovery action | Stop the operation; keep the session usable; an administrator restores the approved project dependencies, then the user retries the HEV plot. Do not ask a study participant to change packages mid-session. |
| Expected retained state | Site mapping, imported data, processed Biology/Flow, join, selections, and any prior valid plot remain intact and clearly marked current/stale as appropriate. |
| Implementation evidence | `R/hev_dependency_helpers.R` implements `hev_dependency_check()` with a `requireNamespace("ggnewscale", quietly = TRUE)` preflight. The `renderHEV` observer in `server.R` runs that preflight before HEV prerequisites or plotting, clears the request, marks HEV blocked, shows the safe message and returns when the dependency is unavailable. |
| Automated test | `tests/testthat/test-hev-dependency-boundary.R` covers missing and available dependency results and exact safe wording. `tests/testthat/test-workflow-server.R`, “RAW-01 missing HEV dependency blocks safely and ends the request”, injects the missing-dependency result and asserts blocked HEV state plus safe UI output. Both pass in the corrective gate. |
| Manual test | Browser/manual fault-injection step: in an isolated environment only, make `ggnewscale` unavailable, render each HEV variant, verify friendly message, spinner termination, navigation, retained join, and recovery after restoring the approved environment. |
| Current execution result | Pass based on complete implementation and passing automated verification. Missing-`ggnewscale` dependency injection was Not Executed during the final browser/manual session. |
| Release evidence | Implementation and automated evidence above. No browser dependency-failure screenshot or manual injection is claimed. `SMOKE_01_task_and_stage_navigation.png` remains general navigation smoke and is not relabelled as RAW-01. |
| Browser/manual verification required | Missing-dependency browser injection remains Not Executed and should stay explicitly separate from the passing implementation/automated assessment. |
| Gap | Browser dependency-failure injection and recovery after restoring the approved environment were not executed; implementation and automated coverage are complete. |
| Severity | Major |
| Recommended action | Retain the passing implementation/automated evidence and, if later required, execute isolated browser dependency injection without treating the navigation smoke as RAW-01 evidence. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Automated assessment: Pass; Browser missing-dependency injection: Not Executed. |

### RAW-02

| Field | Required content |
|---|---|
| RAW ID | RAW-02 |
| Error scenario | Donor mapping input is interpreted by `fread()` as a non-readable file path. |
| Trigger | Submit malformed/single-line donor mapping text that `fread()` treats as a path. |
| Affected workflow/task | Flow processing / donor mapping and imputation. |
| Blocking classification | Blocking |
| Expected user-facing message | “The donor-site input could not be read. Please check the required format and try again.” |
| Implemented message | “The donor mapping could not be read or validated. Please correct the two-column donor-site mapping and try again.” Blank/whitespace input retains “If imputing flows please add donor mapping.” |
| Recovery action | Correct the donor mapping text and resubmit; the UI must remain responsive and must not require re-import of already valid metadata/Flow. |
| Expected retained state | Donor text, metadata, imported Flow, chosen dates/settings, and prior valid artifacts remain; failed imputation/join outputs are not marked successful. |
| Implementation evidence | Previously unguarded parser resolved on `qa/raw-user-facing-recovery`: `parse_donor_mapping()` in `R/site_mapping_helpers.R` forces text parsing, rejects parser warnings/errors and invalid two-column structures, and `server.R` routes failed attempts to a controlled result without replacing Flow Statistics. |
| Automated test | `tests/testthat/test-donor-external-recovery.R` covers blank-before-parser, malformed/path-like input, schema failure, redaction, retained Flow Statistics, running reset and same-session retry; `tests/testthat/test-workflow-server.R` retains RAW-04 regression coverage. |
| Manual test | Paste malformed/path-like donor mapping; submit; assert no raw console-only failure, friendly UI feedback, loading ends, controls/navigation work, correct-and-retry succeeds without re-upload. |
| Current execution result | Pass — automated coverage and final browser/manual recovery verification passed. |
| Release evidence | Current browser evidence: `RAW02_01_path_like_donor_mapping_safe_failure.png` and `RAW02_02_invalid_donor_mapping_schema_blocked.png`. Historical `ST-04B` remains supporting context only. |
| Browser/manual verification required | Yes |
| Gap | Previously identified implementation and browser recovery/retention evidence gaps are resolved. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-03

| Field | Required content |
|---|---|
| RAW ID | RAW-03 |
| Error scenario | Donor text is passed directly to `fread()` and exposes its raw parser error. |
| Trigger | Submit structurally invalid donor mapping or donor-list text. |
| Affected workflow/task | Flow processing / donor mapping, donor list, imputation. |
| Blocking classification | Blocking |
| Expected user-facing message | “The input format is invalid. Please check the donor-site format before importing.” |
| Implemented message | Donor mapping and donor-list parser failures now use stable messages. Donor list failures state that the list is invalid or unreadable, identify `flow_site_id` and accepted `flow_input` values, and instruct the user to retry. |
| Recovery action | Keep pasted text available, show the expected format, allow correction and retry without session reset. |
| Expected retained state | Metadata, imported Flow, prior completed artifacts, date range and donor inputs remain; no stale imputation/statistic/join may be treated as current. |
| Implementation evidence | Previously unguarded reads resolved on `qa/raw-user-facing-recovery`: `parse_donor_site_list()` in `R/site_mapping_helpers.R` sanitises parser/normalisation failures and validates the existing `flow_site_id` plus NRFA/HDE contract; `server.R` prevents malformed input reaching the donor importer and finalises donor import state on every return path. |
| Automated test | `tests/testthat/test-donor-external-recovery.R` covers blank, malformed and invalid donor-list structures, importer non-invocation, controlled external failure, state retention, finalisation and same-session retry. |
| Manual test | Exercise malformed mapping and malformed donor-list variants separately; verify safe UI message, no path/stack trace, spinner exit, retained inputs, back navigation, and successful retry. |
| Current execution result | Pass — automated coverage and final browser/manual verification passed. |
| Release evidence | Current browser evidence: `RAW03_01_invalid_flow_input_blocked.png` and `RAW03_02_blank_flow_site_id_blocked.png`. Historical `ST-04B` remains supporting context only. |
| Browser/manual verification required | Yes |
| Gap | Previously identified implementation and browser recovery/retention evidence gaps are resolved. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-04

| Field | Required content |
|---|---|
| RAW ID | RAW-04 |
| Error scenario | Empty or whitespace-only donor input. |
| Trigger | Attempt donor mapping/list processing with blank input. |
| Affected workflow/task | Flow processing / donor imputation. |
| Blocking classification | Blocking for imputation; non-blocking for workflows that do not request imputation. |
| Expected user-facing message | “Please enter donor-site information before importing donor flow data.” |
| Implemented message | “If imputing flows please add donor mapping.” and “If importing additional donor flows, please add the donor site list.” |
| Recovery action | Paste the required donor information or leave the optional imputation path; retry from the same Stage. |
| Expected retained state | Existing metadata/Flow and any unrelated completed artifacts remain; empty input is not treated as success. |
| Implementation evidence | Whitespace-aware `trimws()` guards run before either donor `fread()` call in `server.R`; validation does not change the Flow Statistics artifact. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-04 donor inputs reject all-whitespace text and allow in-session retry”: empty, spaces, tabs, newline, mixed whitespace, parser-not-called, retained Flow Statistics and valid retry. |
| Manual test | Blank and whitespace-only mapping/list; verify blocker only when imputation is requested, message wording, no raw error, controls usable, and valid retry. |
| Current execution result | Pass — targeted automation and final browser/manual verification passed. |
| Release evidence | Current browser evidence: `RAW04_01_blank_donor_mapping_blocked.png` and `RAW04_02_whitespace_donor_mapping_blocked.png`. |
| Browser/manual verification required | Yes |
| Gap | Automated implementation and browser/manual evidence gaps are closed. |
| Severity | Minor |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-05

| Field | Required content |
|---|---|
| RAW ID | RAW-05 |
| Error scenario | Uploaded CSV is empty. |
| Trigger | Upload zero-byte or header-only CSV to metadata, Local Biology/Flow, WQ, or RHS. |
| Affected workflow/task | Stage 1 Data Input across local upload features. |
| Blocking classification | Blocking for the affected required source; non-blocking for optional WQ/RHS and unrelated workflows. |
| Expected user-facing message | “The uploaded file is empty. Please upload a file containing valid data.” |
| Implemented message | Examples: “Local flow CSV appears to be empty”; “Your WQ file appears to be empty. Please upload a CSV file with at least one data row.” |
| Recovery action | Select a non-empty valid CSV and retry; optional-source failure must not block the Biology+Flow core path. |
| Expected retained state | Unrelated valid artifacts and mapping remain. An invalid replacement must not leave the old local source silently operational; browser file input may require re-selection, but no unrelated re-upload. |
| Implementation evidence | `read_dashboard_csv()` and the metadata reader reject empty content with controlled messages. Replacement observers reset the affected Biology, Flow, WQ, RHS, or site-mapping artifact before validation; only a valid retry completes it again. |
| Automated test | Near-scenario: `tests/testthat/test-site-metadata-helpers.R:31`, “header-only site metadata CSV is reported as empty”; replacement-state test `tests/testthat/test-server-local-flow-source.R:162`, “replacing valid Local Flow with an invalid file removes the previous local source”. |
| Manual test | `TC-029`; historical `ST-07E`/`ST-07F`. Browser/manual verification must repeat zero-byte and header-only for every upload type, then valid replacement without restart. |
| Phase 2B automated test | `tests/testthat/test-site-metadata-helpers.R` covers header-only metadata. `tests/testthat/test-server-local-flow-source.R` covers valid-to-invalid-to-valid replacement recovery for metadata, Local Flow, Local Biology, WQ, and RHS while checking retained unrelated state. |
| Current execution result | Pass — linked automated slices and final browser invalid-to-valid replacement verification passed. |
| Release evidence | Current browser evidence: `RAW05_01_invalid_replacement_not_current.png` and `RAW05_02_valid_retry_restores_mapping.png`. Historical `ST-07E`/`ST-07F` remains supporting evidence only. |
| Browser/manual verification required | Yes |
| Gap | The previous stale-current replacement gap is closed by automated and current browser evidence; exhaustive per-control screenshots were not required for this smoke session. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-06

| Field | Required content |
|---|---|
| RAW ID | RAW-06 |
| Error scenario | CSV separator/row structure/parser error. |
| Trigger | Upload malformed, inconsistent, or non-CSV content. |
| Affected workflow/task | Stage 1 Data Input across metadata, Local Biology/Flow, WQ, RHS. |
| Blocking classification | Blocking for the affected required source; non-blocking for optional WQ/RHS. |
| Expected user-facing message | “The uploaded file could not be read. Please check that it is a valid CSV file with the expected columns.” |
| Implemented message | “... CSV could not be read. Please upload a valid CSV file.” / “Your WQ/RHS file could not be read as CSV. Please check that it is a valid comma-separated file.” |
| Recovery action | Correct/re-export the CSV and replace it; remain in the current session. |
| Expected retained state | Unrelated artifacts remain; failed replacement is not operational; no stale old source is used downstream. |
| Implementation evidence | `read_character_csv()` converts parser errors and structural parser warnings into a controlled invalid result. Both metadata routes and all local upload readers use this boundary; parser text, paths, and implementation details do not enter UI messages. |
| Automated test | `tests/testthat/test-site-metadata-helpers.R:48`, “existing non-CSV input is reported as unreadable”; replacement test at `tests/testthat/test-server-local-flow-source.R:162`. |
| Manual test | Historical `ST-07E` and recovery `ST-07F`; Browser/manual: malformed delimiter/quotes/inconsistent rows for each upload, followed by valid replacement. |
| Phase 2B automated test | `tests/testthat/test-site-metadata-helpers.R` compares malformed uploaded and pasted metadata. `tests/testthat/test-server-local-flow-source.R` covers malformed Local Flow and WQ replacement, old-current invalidation, controlled text, and same-session retry. |
| Current execution result | Pass — linked parser/replacement automation and final browser malformed-to-valid recovery verification passed. |
| Release evidence | Current browser evidence: `RAW06_01_malformed_csv_controlled_failure.png` and `RAW06_02_valid_retry_after_malformed_csv.png`. July `ST-07E/F` remains historical only. |
| Browser/manual verification required | Yes |
| Gap | The previous raw-parser/stale-current gap is closed for the Phase 2B upload paths, with current browser evidence retained. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-07

| Field | Required content |
|---|---|
| RAW ID | RAW-07 |
| Error scenario | Required columns are missing after upload. |
| Trigger | Upload a readable CSV that omits columns required by that source contract. |
| Affected workflow/task | Stage 1 validation for mapping, Local Biology/Flow, WQ/RHS. |
| Blocking classification | Missing/invalid core `biol_site_id` or `flow_site_id` blocks site mapping. Missing WQ/RHS input is informational and non-blocking. A supplied WQ/RHS file without its usable identifier is invalid only for that optional feature. |
| Expected user-facing message | “The uploaded file is missing required columns. Please check the file format and upload again.” |
| Implemented message | Source-specific lists, e.g. “Local flow CSV is missing required column(s): ...”; WQ missing site ID is a warning, while RHS missing `rhs_survey_id` is also currently a warning. |
| Recovery action | Add/rename required columns and re-upload; optional-source warning must not block core work. |
| Expected retained state | Existing unrelated artifacts remain; invalid required source is blocked; old/stale source cannot continue into Flow stats/join/model/download. |
| Implementation evidence | `validate_supporting_mapping()` freezes core required versus optional mapping severity. Local Biology/Flow validators remain blocking when their supplied file is invalid. WQ/RHS observers reset only their optional artifacts; their absence remains informational. |
| Automated test | `tests/testthat/test-local-flow-contract.R:38`, “missing required Local Flow columns are rejected”; `tests/testthat/test-dashboard-backlog-helpers.R:4`; standalone `tests/test_backlog_helpers.R:11-18`; WQ contract missing-column checks in `tests/test_wq_contract_helpers.R:94-97`. |
| Manual test | `TC-003`, `TC-013`; historical `ST-07C`; repeat every upload contract during final browser/manual verification. |
| Phase 2B automated test | `tests/testthat/test-dashboard-backlog-helpers.R` covers required core and optional-absence severity. `tests/testthat/test-server-local-flow-source.R` covers optional missing, valid, supplied-invalid, retained core join, and valid retry. |
| Current execution result | Pass — linked schema tests and final browser required/optional mapping verification passed. |
| Release evidence | Current browser evidence: `RAW07_01_missing_required_biol_site_id_blocked.png` and `RAW07_02_optional_wq_rhs_absent_non_blocking.png`. Historical `ST-07C` remains historical only. |
| Browser/manual verification required | Yes |
| Gap | The previous classification inconsistency and RHS/WQ supplied-invalid warning gap are closed, with current browser evidence retained. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-08

| Field | Required content |
|---|---|
| RAW ID | RAW-08 |
| Error scenario | Metadata lacks `biol_site_id`. |
| Trigger | Parse/upload mapping used by Biology-related work without `biol_site_id`. |
| Affected workflow/task | Stage 1 site mapping; Biology import, O:E, join. |
| Blocking classification | Blocking for the core site-mapping artifact; optional WQ/RHS file absence remains non-blocking. |
| Expected user-facing message | “The metadata file is missing the required column biol_site_id.” |
| Implemented message | “Mapping CSV is missing required column(s): biol_site_id.” |
| Recovery action | Add `biol_site_id`, re-upload/revalidate, then resume the earliest blocked Stage. |
| Expected retained state | Entered mapping and unrelated valid artifacts remain; Biology-dependent outputs are blocked/stale, not silently reused. |
| Implementation evidence | Uploaded and pasted metadata both pass through `prepare_site_metadata_result()` and `validate_supporting_mapping()`. A replacement first clears `current_site_metadata`; invalid data blocks `site_mapping`, while a valid retry installs and completes the new mapping. |
| Automated test | `tests/testthat/test-dashboard-backlog-helpers.R:4`, “mapping validation reports a missing biol_site_id column”; resume/stale state tests in `tests/testthat/test-workflow-state.R:116-145` are cross-cutting, not the upload trigger. |
| Manual test | `TC-003`; upload missing `biol_site_id`, confirm error, correct file, resume, and verify prior unrelated artifacts. |
| Phase 2B automated test | `tests/testthat/test-dashboard-backlog-helpers.R` covers missing `biol_site_id`. `tests/testthat/test-server-local-flow-source.R` covers upload and paste replacement invalidation, equivalent outcomes, retained unrelated artifacts, and same-session retry. |
| Current execution result | Pass — direct validation automation and final browser upload/paste equivalence verification passed. |
| Release evidence | Current browser evidence: `RAW08_01_invalid_upload_validation.png` and `RAW08_02_invalid_paste_validation.png`. |
| Browser/manual verification required | Yes |
| Gap | The previous upload/paste inconsistency and stale-current gap are closed in automation and current browser evidence. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-09

| Field | Required content |
|---|---|
| RAW ID | RAW-09 |
| Error scenario | Metadata/Flow input lacks `flow_site_id`. |
| Trigger | Upload mapping or Local Flow without `flow_site_id`, then request Flow/join work. |
| Affected workflow/task | Stage 1 Flow mapping/input; Flow processing, join, HEV/model. |
| Blocking classification | Blocking for Flow-dependent Tasks. |
| Expected user-facing message | “The metadata file is missing the required column flow_site_id.” |
| Implemented message | Mapping: “Mapping CSV is missing required column(s): flow_site_id.” Local Flow: “Local flow CSV is missing required column(s): flow_site_id.” |
| Recovery action | Add/rename `flow_site_id`, upload again, validate Flow, then recalculate affected downstream outputs. |
| Expected retained state | Biology and unrelated inputs/results remain; Flow-derived statistics, join, HEV/model/download become blocked/stale until regeneration. |
| Implementation evidence | Core mapping validation requires non-blank `flow_site_id`; Local Flow applies the same value rule. Mapping replacement clears the active mapping and invalidates Flow-derived revisions. External Flow import additionally requires a current validated `site_mapping`. Missing/blank `flow_input` still defaults to HDE. |
| Automated test | Near-scenario: `tests/testthat/test-local-flow-contract.R:38-55`, including missing/blank `flow_site_id`; stale replacement tests `tests/testthat/test-server-local-flow-source.R:162-260`. No exact metadata-file RAW trigger test. |
| Manual test | `TC-003`, `TC-013`; validate mapping and Local Flow variants, recover, then prove old Flow stats/join/download cannot be reused. |
| Phase 2B automated test | `tests/testthat/test-local-flow-contract.R` covers missing/blank Local Flow `flow_site_id`. `tests/testthat/test-server-local-flow-source.R` covers exact uploaded/pasted mapping replacement, Flow/downstream invalidation, corrected retry, import blocking, and RAW-10 HDE default/provenance. |
| Current execution result | Pass — Local Flow/stale-state automation and final browser missing/blank `flow_site_id` verification passed. |
| Release evidence | Current browser evidence: `RAW09_01_missing_flow_site_id_blocked.png` and `RAW09_02_blank_flow_site_id_blocked.png`. |
| Browser/manual verification required | Yes |
| Gap | The metadata required-value gap is closed in server automation and current browser evidence. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-10

| Field | Required content |
|---|---|
| RAW ID | RAW-10 |
| Error scenario | Authority expected missing `flow_input` to error; later decision makes missing/blank values default to HDE. |
| Trigger | Metadata omits `flow_input` or supplies blank/NA values. |
| Affected workflow/task | Stage 1 mapping; external Flow source selection. |
| Blocking classification | Non-blocking under the later HDE-default contract. |
| Expected user-facing message | RAW authority: “The metadata file is missing the required column flow_input.” Later guidance: “HDE was selected as the default Flow source.” |
| Implemented message | Informational, non-blocking UI notice: “Flow source was not specified for [n] site(s). HDE has been selected as the default source.” HDE provenance remains row-level and explicit. |
| Recovery action | Review the provenance/default; change individual sites to NRFA if required, then re-import/recalculate Flow-derived outputs. |
| Expected retained state | Mapping and unrelated artifacts remain; changing a source invalidates Flow-derived artifacts without session reset. |
| Implementation evidence | `normalise_site_metadata_flow_input()` in `R/site_mapping_helpers.R`; `flow_source_default_status` in `server.R`; mapping status placement in `ui.R`. |
| Automated test | `tests/testthat/test-flow-metadata-defaults.R`; `tests/testthat/test-flow-mapping-contract.R`; `tests/testthat/test-server-local-flow-source.R`, including info styling/message for uploaded and pasted missing/blank values. |
| Manual test | `TC-002`, `TC-015`; historical FT-01G/H were not run on the updated implementation. Browser/manual verification must confirm visible default/provenance and source-change recovery. |
| Current execution result | Pass — default/provenance automation and final browser missing/blank `flow_input` verification passed. |
| Release evidence | Current browser evidence: `RAW10_01_missing_flow_input_defaults_HDE.png` and `RAW10_02_blank_flow_input_defaults_HDE.png`. |
| Browser/manual verification required | Yes |
| Gap | UI acknowledgement is implemented and current browser/manual provenance evidence is retained. |
| Severity | Minor |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes (later HDE-default decision); Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-11

| Field | Required content |
|---|---|
| RAW ID | RAW-11 |
| Error scenario | Flow statistics requested before Flow data exist. |
| Trigger | Click “Calculate flow statistics” without a valid current Flow source. |
| Affected workflow/task | Flow processing; prerequisite to join/HEV/model. |
| Blocking classification | Blocking for the requested calculation. |
| Expected user-facing message | “Please import flow data before running this calculation.” |
| Implemented message | “Please import flow data.” |
| Recovery action | Return to Data Input, import/validate Flow, then recalculate from the same session. |
| Expected retained state | Metadata, Biology, Environment, donor inputs and unrelated artifacts remain; no previous stale Flow statistics are exposed as current. |
| Implementation evidence | Alert `server.R:1987-2004`; current-revision gate `server.R:1952-1967`; Flow reset `server.R:250-275`. |
| Automated test | `tests/testthat/test-workflow-server.R`, “Flow-statistics attempt without Flow input becomes recoverably blocked”, directly exercises the request without Flow and asserts blocked status, prerequisite guidance and no current Flow-statistics revision. The final automated gate passes. |
| Manual test | Click without Flow, navigate back, import valid Local Flow, retry, and verify retained inputs and current-only results. |
| Current execution result | Pass — direct workflow-server automation and final browser prerequisite verification passed. |
| Release evidence | Current browser evidence: `RAW11_01_flow_processing_blocked_without_flow.png`. Automated coverage is direct and passing; historical normal Flow tests remain supporting context only. |
| Browser/manual verification required | Yes |
| Gap | Automated prerequisite handling and current browser-visible blocking behaviour are covered. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes (direct workflow-server coverage); Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-12

| Field | Required content |
|---|---|
| RAW ID | RAW-12 |
| Error scenario | O:E/Biology processing requested before Biology data exist. |
| Trigger | Click O:E calculation without imported current Biology. |
| Affected workflow/task | Biology processing / O:E; downstream join, HEV, model. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please import biology data before running this calculation.” |
| Implemented message | “Biology data are required before calculating O:E ratios. Import or restore Biology data, then calculate O:E ratios again.” |
| Recovery action | Return to Data Input, import Biology, complete required processing, and retry. |
| Expected retained state | Metadata, Environment, Flow and unrelated outputs remain; no stale O:E/join/HEV/model is current. |
| Implementation evidence | The priority O:E action preflight in `server.R` checks the current Biology artifact before setting an accepted request or running state; the O:E calculation listens only to accepted requests. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing Biology, blocked/not-running state, retained Environment/Flow, import and successful retry. |
| Manual test | Browser/manual: trigger without Biology, verify alert/UI/console/spinner, navigate back, import, retry, and check no unnecessary re-upload. |
| Current execution result | Pass — targeted automation and final browser prerequisite verification passed. |
| Release evidence | Current browser evidence: `RAW12_01_oe_blocked_without_biology.png`. |
| Browser/manual verification required | Yes |
| Gap | Automated recovery/state and current browser evidence gaps are closed. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-13

| Field | Required content |
|---|---|
| RAW ID | RAW-13 |
| Error scenario | RICT prediction requested before Environmental data exist. |
| Trigger | Click RICT prediction without a current Environmental import. |
| Affected workflow/task | Biology processing / RICT; O:E and downstream analysis. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please import environmental data before running RICT predictions.” |
| Implemented message | “Current Environmental data are required before running RICT predictions. Import or regenerate Environmental data, then run RICT predictions again.” |
| Recovery action | Import Environmental data, then rerun RICT. |
| Expected retained state | Metadata, Biology, Flow and unrelated artifacts remain; no stale prediction/O:E is current. |
| Implementation evidence | The priority RICT action preflight in `server.R` validates the current Environmental artifact before accepting a request or entering running; prediction processing listens only to accepted requests. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing and stale Environmental states, retained Biology, re-import and successful retry. |
| Manual test | Browser/manual: click RICT without Environment, verify blocking message and no console-only failure, import data, retry, inspect retained state. |
| Current execution result | Pass — targeted automation and final browser prerequisite verification passed. |
| Release evidence | Current browser evidence: `RAW13_01_rict_blocked_without_environment.png`. |
| Browser/manual verification required | Yes |
| Gap | Prerequisite recovery is automated and current browser evidence is retained; external-import recovery is tracked under RAW-22. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-14

| Field | Required content |
|---|---|
| RAW ID | RAW-14 |
| Error scenario | O:E requested before RICT predictions exist. |
| Trigger | Click O:E after Biology import but before successful RICT. |
| Affected workflow/task | Biology processing / O:E. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please run RICT predictions before calculating O:E ratios.” |
| Implemented message | “Current RICT predictions are required before calculating O:E ratios. Run RICT predictions before calculating O:E ratios.” |
| Recovery action | Run RICT successfully, then retry O:E. |
| Expected retained state | Biology/Environment/Flow inputs remain; failed O:E does not clear RICT prerequisites or mark downstream outputs current. |
| Implementation evidence | The O:E action preflight in `server.R` validates the current RICT artifact before accepting the request; the O:E event reactive cannot access predictions for a blocked click. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing RICT predictions, retained Biology/Environment, RICT run and successful O:E retry. |
| Manual test | Browser/manual: skip RICT, request O:E, verify alert/spinner/navigation, run RICT, retry O:E, verify prior inputs retained. |
| Current execution result | Pass — targeted automation and final browser prerequisite verification passed. |
| Release evidence | Current browser evidence: `RAW14_01_oe_blocked_without_rict.png`. |
| Browser/manual verification required | Yes |
| Gap | Automated block/retry, controlled messaging and current browser evidence are complete. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-15

| Field | Required content |
|---|---|
| RAW ID | RAW-15 |
| Error scenario | Join requested before current Flow statistics exist. |
| Trigger | Click Biology–Flow join without Flow statistics, or after Flow source changes and old statistics become stale. |
| Affected workflow/task | Task “Build Joined HE dataset”; Stage 3 Processing / join; downstream HEV/model/download. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please calculate flow statistics before joining biology and flow data.” |
| Implemented message | “Flow Statistics are missing or out of date. Calculate or regenerate Flow Statistics, then build the Joined HE Dataset again.” |
| Recovery action | Return to Flow processing, calculate statistics from the current source, return to join, and rerun. |
| Expected retained state | Valid Biology/O:E and mapping remain; completed old join/HEV/model/download must be stale/blocked, not usable as success. |
| Implementation evidence | The priority join preflight in `server.R` checks current Flow Statistics before creating `join_request` or entering running; join result reactives listen only to accepted requests. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing/stale Flow Statistics, no join calls, retained O:E, regeneration and successful retry. |
| Manual test | Browser/manual: attempt join before stats; then create stats and join; change Flow source and verify old join, HEV, model and every download cannot be used until regeneration. |
| Current execution result | Pass with Warning — targeted automation passed; final browser block/retry verification passed with a non-blocking Biology/Flow temporal coverage warning. |
| Release evidence | Current browser evidence: `RAW15_01_join_blocked_without_flow_statistics.png` and `RAW15_02_join_retry_after_flow_statistics.png`. |
| Browser/manual verification required | Yes |
| Gap | Direct automation, stale-input non-consumption and current browser block/retry evidence are complete. |
| Severity | Major |
| Recommended action | Retain the current evidence and documented non-blocking warning with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass with Warning. |

### RAW-16

| Field | Required content |
|---|---|
| RAW ID | RAW-16 |
| Error scenario | Join requested before O:E/processed Biology exists. |
| Trigger | Click join without a current `biol_all()`/O:E result. |
| Affected workflow/task | Task “Build Joined HE dataset”; Stage 3 join; downstream HEV/model/download. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please calculate O:E ratios before joining biology and flow data.” |
| Implemented message | “Current O:E ratios are required before building the Joined HE Dataset. Calculate or regenerate O:E ratios, then build the Joined HE Dataset again.” |
| Recovery action | Complete RICT and O:E, return to Analysis, and rerun join. |
| Expected retained state | Mapping, Flow and Flow statistics remain; incomplete/stale joined/HEV/model/download artifacts remain blocked. |
| Implementation evidence | The priority join preflight in `server.R` checks the current O:E artifact before creating `join_request`; the join result reactives reject missing/stale O:E. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing/stale O:E, no join calls, retained Flow Statistics, O:E regeneration and successful retry. |
| Manual test | Browser/manual: attempt join before O:E; complete O:E; retry; verify Flow stats retained and no stale output/download use. |
| Current execution result | Pass with Warning — targeted automation passed; final browser block/retry verification passed with a non-blocking Biology/Flow temporal coverage warning. |
| Release evidence | Current browser evidence: `RAW16_01_join_blocked_without_oe.png` and `RAW16_02_join_retry_after_oe.png`. |
| Browser/manual verification required | Yes |
| Gap | Runtime wording, automated recovery and current browser recovery/state evidence are complete. |
| Severity | Major |
| Recommended action | Retain the current evidence and documented non-blocking warning with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass with Warning. |

### RAW-17

| Field | Required content |
|---|---|
| RAW ID | RAW-17 |
| Error scenario | HEV plot requested before a current joined dataset exists. |
| Trigger | Click “Create HEV plot” without a successful current join, including after inputs/settings make the old join stale. |
| Affected workflow/task | Task “Generate HEV plots”; Stage 4 HEV. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please join biology and flow data before creating an HEV plot.” |
| Implemented message | “The Joined HE Dataset is missing or out of date. Rebuild or regenerate the Joined HE Dataset, then create the HEV plot again.” |
| Recovery action | Return to the earliest blocked Stage, regenerate join, return to HEV, and render again. |
| Expected retained state | Inputs and current upstream artifacts remain; an old HEV plot/download cannot be used as current; no session reset or re-upload should be needed. |
| Implementation evidence | The priority HEV action preflight in `server.R` checks the current Joined HE Dataset before accepting a plot request or entering running; HEV plot/download evaluation is gated by the accepted request and current join. |
| Automated test | `tests/testthat/test-workflow-server.R`, “RAW-12 to RAW-17 prerequisites block before run and recover in session”: missing/stale join, blocked/not-running HEV, old plot unavailable, retained upstream, rebuild and successful retry/current result. |
| Manual test | `TC-016` normal path; historical `ST-06` saw the message but was blocked. Browser/manual verification must test missing and stale joins, back navigation, regeneration, plot and download. |
| Current execution result | Pass — targeted automation and final browser block/rebuild/retry verification passed. |
| Release evidence | Current browser evidence: `RAW17_01_hev_blocked_without_joined_he.png` and `RAW17_02_hev_retry_after_joined_he.png`. |
| Browser/manual verification required | Yes |
| Gap | Exact automation, current-only HEV evaluation and current browser recovery evidence are complete. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-18

| Field | Required content |
|---|---|
| RAW ID | RAW-18 |
| Error scenario | Plotting receives missing, empty, invalid, or incompatible data and exposes a `ggplot` error. |
| Trigger | Select invalid/no plot data, missing date/numeric fields, invalid HEV inputs, or a plotting exception. |
| Affected workflow/task | WQ/RHS plots, WQ summary, PCA/heatmap, analysis plots, HEV. |
| Blocking classification | Blocking for that plot only; normally non-blocking for other workflows. |
| Expected user-facing message | “The plot could not be created because the required data is missing or invalid.” |
| Implemented message | WQ/RHS helpers retain their specific friendly validation; the shared plot-specific boundary and HEV status now use “The plot could not be created because the required data is missing or invalid. Check the plot inputs and current results, then try again.” |
| Recovery action | Keep valid data and selections, choose valid variables/date range or regenerate prerequisites, then retry the plot. |
| Expected retained state | Upstream data/results and prior valid artifacts remain; failed new plot is not marked complete; other pages stay usable. |
| Implementation evidence | Historical partial evidence retained: `R/wq_rhs_plot_helpers.R:122-190,193-267`; `server.R:1030-1033,1151-1171`; formerly unguarded HEV at `server.R:2456-2477`; raw HEV helper at `global.R:337-869`. Completion evidence: `R/plot_recovery_helpers.R` retains no-file-device preflight and adds `safe_final_plot_render()`, which draws accepted `ggplot`, `ggmatrix`, `grob`, `gtable`, `recordedplot`, `trellis` and nested/list results on the graphics device already opened by Shiny. `output$HEV_plot` calls that helper inside `renderPlot()` and returns invisibly, so the real output draw is controlled and is not repeated outside the boundary. HEV generation failure still finalises `hev_result` as failed while retaining previous plot/data/provenance and download history. |
| Automated test | Historical helper evidence retained: `tests/test_wq_rhs_plots.R:36-91` and `tests/test_model_interface_helpers.R`. `tests/testthat/test-plot-recovery.R` covers thrown, NULL, unsupported and delayed-render ggplot failures; all accepted plot classes; an object whose validation draw succeeds and final draw fails; nested/list final-draw failure; generic user text with retained diagnostics; and unchanged device state after validation/final-render success and failure. `tests/testthat/test-workflow-server.R` covers HEV exception/unusable result, safe UI text, failed-not-running/current state, retained upstream/HEV history and same-session retry success. |
| Manual test | `TC-007`, `TC-009`, `TC-016–TC-021`; execute missing/invalid data and forced plotting error on every plot family. |
| Current execution result | Pass — targeted deterministic plot-boundary/workflow-server automation and final browser controlled-failure/retry verification passed. |
| Release evidence | Current browser evidence: `RAW18_01_hev_plot_failure_controlled.png` and `RAW18_02_hev_plot_retry_success.png`. Historical plot images remain output examples, not recovery evidence. |
| Browser/manual verification required | Yes |
| Gap | The actual HEV Shiny output draw is now inside the controlled boundary. A focused browser smoke rechecked normal render, unusable `2026–2026` failure and corrected `1990–2025` retry; no artificial browser draw-time object injection is claimed. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-19

| Field | Required content |
|---|---|
| RAW ID | RAW-19 |
| Error scenario | Download handler cannot create/open the requested output file. |
| Trigger | Write failure, invalid destination, or output writer/`ggsave()` failure. |
| Affected workflow/task | WQ/RHS CSV/PNG, exclusion log, HEV plot, table/download outputs. |
| Blocking classification | Blocking for the download; non-blocking for the already completed analysis. |
| Expected user-facing message | “The file could not be created. Please try again or check file permissions.” |
| Implemented message | Preconditions remain specific to the source artifact. Writer/copy/export failures now use: “The file could not be created or saved. Check that the destination is available and writable, then try again.” |
| Recovery action | Preserve the completed in-memory result; retry download, regenerate only if necessary, and contact support if persistent. |
| Expected retained state | All inputs and completed artifacts remain; no re-upload/reprocessing solely because a file write failed. |
| Implementation evidence | Historical gap retained: unguarded handlers formerly at `server.R:741-747,967-985,1048-1056,1182-1196,1313-1316`; HEV module formerly at `global.R:879-890`. Completion evidence: `R/file_operation_helpers.R` provides the file-only result boundary; `server.R` applies it to demo metadata copy, mapped WQ/RHS CSV, WQ contract summary CSV, mapped WQ/RHS PNG, exclusion log CSV and processed Joined HE checkpoint; `global.R` applies it to HEV plot downloads and records HEV download history only after the file writer succeeds. |
| Automated test | `tests/testthat/test-file-operation-recovery.R` covers success, writer failure, safe text, retained source state, no false success record and same-session retry. `tests/testthat/test-workflow-server.R` covers HEV writer failure, safe UI condition, retained plot, unchanged history, successful retry and one success record only. |
| Manual test | `TC-008`, `TC-010`, `TC-016`, `TC-022`, `TC-033` retain happy-path coverage. Browser/manual fault injection must force writer failure and verify the controlled message, retained result and successful retry. |
| Current execution result | Pass — automated writer-failure recovery passed and the browser normal PDF/JPEG/PNG download path passed; manual writer-failure injection was not executed. |
| Release evidence | Current browser evidence: `RAW19_01_hev_pdf_download_and_open.png` and `RAW19_02_hev_all_formats_downloaded.png`. Writer-failure recovery evidence remains automated. |
| Browser/manual verification required | Yes |
| Gap | Automated write-failure/retention/retry coverage and browser normal-path evidence are complete; manual browser writer-failure injection was not executed. |
| Severity | Major |
| Recommended action | Retain the automated failure-recovery and browser normal-path evidence; do not describe the browser session as writer-failure injection. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Browser normal path: Pass; Manual writer-failure injection: Not Executed. |

### RAW-20

| Field | Required content |
|---|---|
| RAW ID | RAW-20 |
| Error scenario | Historical: a required runtime-generated Flow CSV is absent. |
| Trigger | Historical: a downstream step attempts to read an expected temporary/generated Flow file that was never created or was removed. |
| Affected workflow/task | Historical Flow import/processing and all Flow-dependent outputs. The current supported Flow path has no generated-file reopen step. |
| Blocking classification | Superseded / N/A for the current supported Flow architecture. Equivalent current Flow import failures remain blocking for Flow-dependent outputs. |
| Expected user-facing message | “The required temporary flow file could not be found. Please re-import the flow data.” |
| Implemented message | No dedicated generated-Flow-file message is required because the current dashboard never creates and reopens per-site Flow CSVs. Current Flow import failures use “Flow data could not be retrieved or processed. Check the selected sites, source and date range, then try again.” Current RHS temporary-filesystem failures use the existing sanitised file-operation message. |
| Recovery action | Retry the current HDE/NRFA Flow import in the same session; a failed import is not current and Flow-dependent outputs remain invalidated. For the current RHS temporary-file path, correct the transient filesystem/service condition and retry; cleanup and working-directory restoration run on exit. |
| Expected retained state | Mapping, Biology/Environment/O:E, optional unrelated inputs and user settings remain. Failed current Flow results are not marked current. A classified RHS temporary-filesystem failure retains the previous RHS data and workflow registry; a general failed RHS replacement is not treated as current. |
| Implementation evidence | **Superseded by current implementation / no additional code required.** `normalise_site_metadata_flow_input()` accepts only `HDE` and `NRFA`; `import_dashboard_flow()` calls `hetoolkit::import_flow()` and returns its data frame directly; `server.R` keeps that result in `external_flow_data()`/`flow_data()` and never writes or reopens a site CSV. Current installed `hetoolkit` HDE/NRFA import functions contain no file operations; its separate `FLOWFILES` reader is not reachable through the supported dashboard contract. Repository history, including the initial dashboard implementation, likewise calls `import_flow()` directly and contains no `27034.csv`/generated-Flow-CSV reopen path. The closest current supporting-file path is RHS: `import_rhs_in_temp_directory()` creates a unique temporary directory under `safe_file_operation()`, restores the previous working directory and removes the directory through `on.exit()`; `server.R` sanitises both classified filesystem failures and importer failures, preserves unrelated state, rejects failed replacement data and permits retry. Missing Shiny upload temp paths are independently guarded by `read_site_metadata_csv()`/`read_dashboard_csv()` and are not a remaining RAW-20 gap. |
| Automated test | `tests/testthat/test-file-operation-recovery.R` covers sanitised RHS setup failure, working-directory restoration, cleanup and retry. `tests/testthat/test-donor-external-recovery.R` covers RHS file/import failure, retained or invalidated state as appropriate, redaction and same-session retry, and covers current in-memory Flow import failure/retry. `tests/testthat/test-workflow-server.R` and `tests/test_site_mapping.R` retain workflow and supported HDE/NRFA mapping coverage. |
| Manual test | The historical generated-Flow-file deletion scenario is N/A. Browser/manual verification remains pending for current Flow failure/retry and RHS temporary-file recovery, including retained unrelated state and no raw path/error disclosure. |
| Current execution result | Superseded / N/A. |
| Release evidence | Current-code/history trace and automated recovery tests support the superseded disposition; no dedicated browser screenshot is required. |
| Browser/manual verification required | No dedicated RAW-20 browser scenario required. |
| Gap | No current production-code or browser-evidence gap for the superseded historical mechanism. |
| Severity | Major |
| Recommended action | Retain RAW-20 as a formally superseded historical case. |
| Coverage states | Documented: Yes; Disposition: Superseded / N/A; Additional implementation required: No; Replacement-path automated test exists: Yes; Executed current branch: Yes; Dedicated browser verification: N/A. |

### RAW-21

| Field | Required content |
|---|---|
| RAW ID | RAW-21 |
| Error scenario | Runtime temporary CSV/image cannot be written or accessed due to permission denial. |
| Trigger | Permission-denied fault in download/temp/plot output. |
| Affected workflow/task | Downloads, plot export, RHS temp import, any runtime file use. |
| Blocking classification | Blocking for the file operation; non-blocking for retained completed analysis. |
| Expected user-facing message | “The dashboard could not save a temporary file. Please check file permissions or try again.” |
| Implemented message | “The file could not be created or saved. Check that the destination is available and writable, then try again.” The wording does not claim a specific permission cause and does not expose paths or system details. |
| Recovery action | Preserve current results; use an authorised writable runtime location/retry; do not require data re-upload unless the source itself is inaccessible. |
| Expected retained state | Inputs, completed artifacts, plots/tables and navigation remain usable; failed file is not presented as downloaded. |
| Implementation evidence | Historical gap retained: unguarded writers listed under RAW-19; the RHS temp helper formerly had cleanup but no user-facing permission contract. Completion evidence: `R/file_operation_helpers.R` catches filesystem failures with safe user text plus internal diagnostics; `R/site_mapping_helpers.R` uses it for RHS temp-directory creation, working-directory access, restoration and cleanup; `server.R` restores the retained workflow registry and RHS data after a temp-filesystem failure while allowing retry. All RAW-19 writers reuse the same contract. |
| Automated test | `tests/testthat/test-file-operation-recovery.R` injects a path-bearing permission-style temp-directory failure, verifies redaction/current-directory retention/cleanup and retries successfully. `tests/testthat/test-donor-external-recovery.R` verifies a current RHS result and workflow registry survive a filesystem failure and a same-session retry succeeds. HEV coverage in `tests/testthat/test-workflow-server.R` verifies permission-style export failure does not create history. |
| Manual test | In an isolated browser/manual sandbox, inject a non-writable target/temp directory without altering production data; verify friendly text, no leaked path, result retention and retry. |
| Current execution result | Pass — targeted deterministic permission/filesystem retained-state and retry automation passed; destructive browser permission/filesystem fault injection was not executed. |
| Release evidence | Automated recovery evidence only; no dedicated browser screenshot is required. |
| Browser/manual verification required | Yes |
| Gap | Automated implementation and deterministic permission/filesystem retention/retry coverage are complete; destructive browser fault injection remains intentionally unexecuted. |
| Severity | Major |
| Recommended action | Retain the automated recovery evidence; do not claim destructive browser permission/filesystem injection. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Destructive browser fault injection: Not Executed. |

### RAW-22

| Field | Required content |
|---|---|
| RAW ID | RAW-22 |
| Error scenario | External data source returns HTTP/timeout/URL failure. |
| Trigger | Biology, Environment, Flow, WQ or RHS service is unavailable or times out. |
| Affected workflow/task | Stage 1 external imports and every dependent Task. |
| Blocking classification | Blocking for a required requested source; non-blocking for optional WQ/RHS and for workflows with an operational local alternative. |
| Expected user-facing message | “The external data source could not be reached. Please check the connection and try again.” |
| Implemented message | Biology, Environment, Flow, additional donor Flow, WQ and RHS use source-specific controlled “could not be retrieved or processed” messages with a correction/retry action. No message claims a network outage when the exact cause is unknown. |
| Recovery action | Keep IDs/date ranges/local uploads; retry service once, use approved local alternative where supported, or continue core workflow without optional WQ/RHS. |
| Expected retained state | All local inputs and unrelated current artifacts remain; failed source/dependent outputs are not successful; optional failure does not block core. |
| Implementation evidence | Previously partial boundary resolved on `qa/raw-user-facing-recovery`: `safe_external_import()` classifies request errors, NULL/empty results and unusable result structures; `server.R` applies it to Biology, Environment, external Flow, additional donor Flow, WQ and RHS, records internal diagnostics separately from UI text, and updates workflow currentness only after usable success. The unused internal `donor_flow_import_running` and `flow_imputation_running` flags were intentionally removed during final RAW-only simplification without reducing behavioural recovery coverage. |
| Automated test | `tests/testthat/test-donor-external-recovery.R` uses mocked failures/results for all covered paths, including service error, NULL/empty and invalid schema classification, failed-currentness, unrelated-state retention, retry results and call counts. Existing local-Flow precedence and site-import tests remain linked regression coverage. |
| Manual test | Use isolated service stubs for timeout/HTTP/empty response across all five sources, retry success, optional-source continuation, local Flow fallback/precedence, retained state and spinner termination. Do not use real services for fault injection. |
| Current execution result | Pass — automated failure/retry cases and final browser additional-donor failure/retry verification passed. |
| Release evidence | Current browser evidence: `RAW22_01_additional_donor_external_failure_safe.png` and `RAW22_02_additional_donor_retry_success.png`. Historical live-service successes remain historical context only. |
| Browser/manual verification required | Yes |
| Gap | Previously identified scoped application-boundary, deterministic automation and current browser evidence gaps are resolved. The application-wide lifecycle limitation remains deferred under RAW-25. |
| Severity | Major |
| Recommended action | Retain the current automated and browser evidence; track application-wide lifecycle consistency separately as RAW-25. |
| Coverage states | Documented: Yes; Implemented: Yes for the scoped external operations; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass. |

### RAW-23

| Field | Required content |
|---|---|
| RAW ID | RAW-23 |
| Error scenario | Unhandled Shiny reactive/backend error appears only in console or as raw UI error. |
| Trigger | Any unexpected processing/join/plot/model reactive failure. |
| Affected workflow/task | Application-wide; especially Flow statistics, join, HEV, model and downloads. |
| Blocking classification | Blocking for the failed operation; other valid workflows should remain usable. |
| Expected user-facing message | “Something went wrong while processing this step. Please check your input and try again.” |
| Implemented message | Scoped upload, workbook-preview, model, external-import, plot and file-operation paths use controlled user-facing messages. Raw model diagnostics are kept separate from UI messages. |
| Recovery action | End loading, show sanitised step-specific feedback, preserve existing valid state, allow back navigation and one retry; never mark failed output complete. |
| Expected retained state | Existing valid data/artifacts are intentionally unchanged unless their source changed; target artifact becomes failed/blocked, not success; no session reset. |
| Implementation evidence | Historical finding: model handling and several legacy reactives previously had incomplete boundaries and could expose raw detail. Current scoped completion: `R/model_interface_helpers.R` separates safe messages from diagnostics; the workbook preview observer guards missing/empty sheet input; shared external-import, plot and file-operation boundaries protect the critical recovery paths in scope; workflow artifact failure handling preserves valid upstream state. |
| Automated test | `tests/testthat/test-workflow-server.R` covers the workbook preview guard and workflow failure/retry state; `tests/testthat/test-user-facing-error-safety.R` covers model and user-facing message safety; targeted donor/external, plot and file recovery suites cover their critical boundaries. The final automated gate passes. |
| Manual test | Use `TC-021` and `TC-036–TC-039` plus scoped fault injection to observe UI and R Console together, retry, and verify retained/current state. |
| Current execution result | Pass — basic browser smoke passed and scoped automated edge-case coverage passed; invalid-sheet browser injection was not executed. |
| Release evidence | Browser smoke completed without a retained screenshot; NULL/empty/NA/blank/invalid sheet states are covered by automation. Historical `ST-05A`/`BUG-001` and `FT-07A`/`BUG-003` remain historical evidence only. |
| Browser/manual verification required | Yes |
| Gap | The scoped recovery, user-message safety and basic browser-smoke gaps are closed. Invalid-sheet browser injection was not executed; application-wide lifecycle consistency remains deferred under RAW-25. |
| Severity | Current residual QA evidence gap; not a current Blocker on the basis of the superseded historical RAW-23 finding. |
| Recommended action | Retain the automated edge-case result and record that no browser screenshot was retained and invalid-sheet browser injection was not executed. |
| Coverage states | Documented: Yes; Implemented: Yes for the scoped recovery paths; Automated test exists: Yes; Executed current branch: Yes; Basic browser smoke: Pass; Screenshot: Not retained; Invalid-sheet browser injection: Not Executed. |

### RAW-24

| Field | Required content |
|---|---|
| RAW ID | RAW-24 |
| Error scenario | Local/developer filesystem path is exposed to the user. |
| Trigger | A parser/model/file exception contains a POSIX, Windows drive or UNC absolute path and historically reached UI. |
| Affected workflow/task | Upload, donor input, model, download/temp and any fallback exception path. |
| Blocking classification | Blocking for the failed operation; information-disclosure risk application-wide. |
| Expected user-facing message | “An internal file-reading error occurred. Please check your input and try again.” |
| Implemented message | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Upload, donor, external-import, plot and file-operation boundaries use stable messages; model fitting, processed-checkpoint loading and workspace-save fallback presentation now keep raw diagnostics internal and expose only controlled actionable wording. |
| Recovery action | Correct/retry input without seeing internal details; preserve valid state; support logs may retain details only in an authorised location. |
| Expected retained state | Existing valid artifacts and inputs remain, failed target is not successful, and no local path appears in UI/download filename. |
| Implementation evidence | `R/model_interface_helpers.R` separates `messages` from `diagnostic`; `server.R` records model/checkpoint/workspace diagnostics internally and sanitises the affected UI fallback messages. `R/user_message_safety_helpers.R` protects complete HTTP/HTTPS URL tokens before boundary-aware detection for absolute POSIX paths, Windows drive paths with either separator and UNC share paths. POSIX paths remain unsafe after ordinary punctuation such as a label colon, while URL paths and hash routes are not reclassified as filesystem paths. POSIX root `/` is intentionally treated as an absolute path. Existing `safe_external_import()`, `safe_plot_result()` and `safe_file_operation()` contracts remain separate. |
| Automated test | `tests/testthat/test-user-facing-error-safety.R` covers `/Library/Frameworks`, `/Applications`, `/Volumes`, `/srv`, `/var`, `/Users`, `/home`, `/tmp` and root `/`; colon-adjacent POSIX paths; Windows `C:/` and `D:\\` paths; UNC paths; HTTP/HTTPS URLs including multiple components and hash routes; exact fallback wording; and retained `input/output`, `numerator/denominator` and `yes/no` prose. `tests/testthat/test-workflow-server.R` retains path-bearing checkpoint/workspace UI boundary, state and retry coverage. Existing donor/external, plot and file recovery tests retain targeted negative-disclosure assertions. |
| Manual test | Inject a synthetic error containing a fake path in every exception boundary; assert UI/DOM/screenshot lacks path/stack trace while authorised console log can be correlated. |
| Current execution result | Pass — targeted automated RAW-24 coverage plus final browser evidence reused from RAW-02, RAW-06, RAW-18 and RAW-22. |
| Release evidence | No dedicated RAW-24 screenshot required; current browser evidence is reused from RAW-02, RAW-06, RAW-18 and RAW-22. |
| Browser/manual verification required | Yes |
| Gap | Previously identified implementation, negative-disclosure automation and browser/manual evidence gaps are resolved. |
| Severity | Major |
| Recommended action | Retain the automated evidence and reused browser evidence with the final QA packet. |
| Coverage states | Documented: Yes; Implemented: Direct; Automated test exists: Yes; Executed current branch: Yes; Browser/manual verification: Pass via reused RAW-02/06/18/22 evidence. |

### RAW-25

| Field | Required content |
|---|---|
| RAW ID | RAW-25 |
| Error scenario | Backend processing fails or stalls and the dashboard remains permanently loading. |
| Trigger | Flow statistics/join/plot/external operation fails, hangs, or leaves Shiny busy state unresolved. |
| Affected workflow/task | Application-wide; critical historical examples are Flow statistics and Biology–Flow pairing. |
| Blocking classification | Deferred / Known limitation |
| Expected user-facing message | “The operation could not be completed. Please check your input and try again.” |
| Implemented message | Not implemented in the current scope. No application-wide timeout/cancellation/busy-recovery contract is claimed. |
| Recovery action | Loading must terminate; prevent duplicate submission; show safe failure; keep other controls/pages usable; allow back navigation and retry without session reset. |
| Expected retained state | All previously valid artifacts and input selections remain; no half-built/stale target is usable; no re-upload unless the input source itself changed. |
| Implementation evidence | Application-wide timeout, lifecycle, repeated-click protection and button-state consistency would require broader architectural changes and carry disproportionate regression risk relative to the current scope. Existing scoped mitigation provides dedicated recovery boundaries for external import, donor recovery, plot recovery, file/download/filesystem recovery, prerequisite/currentness, and user-safe error presentation. |
| Automated test | Scoped recovery boundaries have deterministic automated coverage. No application-wide timeout/lifecycle test is claimed for RAW-25. |
| Manual test | Future dedicated lifecycle/refactoring work should define deterministic delay/error injection and browser acceptance criteria for long-running and asynchronous actions. |
| Current execution result | Deferred; not implemented in the current scope. |
| Release evidence | Historical `ST-05A`, `FT-07A`, `FT-07A-R1`, `BUG-001`, and `BUG-003` record 99%/permanent loading on older builds. They remain historical failure evidence, not proof of current application-wide recovery. |
| Browser/manual verification required | No closure claim is made: application-wide RAW-25 consistency remains Deferred / Known Limitation. |
| Gap | Remaining limitation: application-wide timeout, lifecycle, repeated-click and button-state consistency is not guaranteed for every long-running or asynchronous action. |
| Severity | Deferred / Known limitation |
| Recommended action | Future dedicated lifecycle/refactoring work. RAW-25 is not an immediate implementation task for this branch. |
| Coverage states | Documented: Yes; Status: Deferred / Known limitation; Implemented in current scope: No; Existing scoped mitigations: Yes; Application-wide automated/browser verification: Not claimed. |

## 5. Current Executable Test Results

Final verified code baseline: `99b2a04` (committed local verification baseline).

The final automated regression suite was executed against committed baseline `99b2a04`. The verification worktree was clean except for the temporary `Rplots.pdf` generated by testthat; that artifact was removed and `git status` returned clean.

| Suite | Total | Pass | Pass with Warning | Fail | Other results | Exit code |
|---|---:|---:|---:|---:|---|---:|
| Full testthat | 165 cases / 1176 expectations | 1176 expectations | 0 | 0 | 0 errors; 0 warnings; 0 skips | 0 |
| Standalone scripts | 18 | 16 | 2 | 0 | — | 18/18 scripts exited 0 |

The two historical standalone Pass with Warning results are:

- `tests/test_mixed_model_helpers.R`
- `tests/test_server_site_import.R`

The expanded automated inventory includes RAW-labelled deterministic recovery tests and cross-cutting workflow/currentness coverage, including direct passing RAW-11 workflow-server coverage. The final counts supersede the old eight-script and 12-testthat-file inventory.

The full browser/manual suite was not rerun for the final corrective implementation. Because production HEV rendering changed, a focused RAW-18 Chrome smoke reused the pilot mapping and passed normal render, controlled unusable-range failure, and corrected same-session retry. Other row-level browser outcomes remain from the already completed final session and stay distinct from the final automated gate.

## 6. Missing Evidence

### Current implementation limitations

- RAW-25 is explicitly **Deferred / Known limitation**. Application-wide timeout, lifecycle, repeated-click protection and button-state consistency are not guaranteed for every long-running or asynchronous action.
- RAW-01 implementation and automated verification pass. Missing-`ggnewscale` browser dependency injection was not performed and remains explicitly **Not Executed**; no manual dependency-failure claim is made.
- DATA-01 and DATA-02 remain unresolved scientific-risk decisions, as recorded in Section 7.

The former gaps for RAW-02/03 donor parsing, RAW-18 plot recovery, RAW-19/21 file recovery, RAW-22 external imports, RAW-23 scoped safe boundaries and RAW-24 user-facing redaction are closed by the current implementation and automated evidence. RAW-20 is Superseded / N/A and requires no additional production implementation.

### Remaining QA evidence limitations

- RAW-01 missing-`ggnewscale` browser dependency injection was not executed; this is a browser-evidence limitation, not an implementation or automated-coverage gap.
- RAW-19 manual writer-failure injection and RAW-21 destructive browser permission/filesystem fault injection were not executed; their failure-recovery results are automated. RAW-19 also has a passing browser normal download path.
- RAW-23 basic browser smoke passed without a retained screenshot; automated edge-case coverage passed, but invalid-sheet browser injection was not executed.
- Historical July screenshots and failure records remain historical evidence and are not promoted to current browser/manual results.
- Automated results are not presented as destructive browser fault injection.

## 7. Risks

### Historical risk

- Historical RAW-02/03 parser failures, RAW-18 plotting failures, RAW-19/21 file failures, RAW-22 import failures, RAW-23 raw/console-only failures and RAW-24 path disclosure remain valuable defect provenance. They are not current Major or Blocker risks merely because they were severe before implementation.
- Historical `ST-05A`, `FT-07A`, `FT-07A-R1`, `BUG-001` and `BUG-003` retain evidence of loading/raw-error failures on older builds. They do not establish the current automated or browser result.

### Current residual risk

- **DATA-01:** `server.R:1637` silently keeps only the first Biology row per `biol_site_id`/Year/Season before O:E. No user message, provenance or direct regression test proves this deletion is scientifically intended.
- **DATA-02:** `server.R:1378` silently converts Environmental `NA` values to zero before RICT. This can change scientific outputs without a visible warning or retained source-vs-normalised audit trail.
- **RAW-25 — Deferred / Known limitation:** application-wide lifecycle consistency is not guaranteed for every long-running or asynchronous action. This is recommended for future dedicated lifecycle/refactoring work, not immediate implementation on this branch.
- **Browser/manual QA evidence:** the final smoke session is complete with the explicit RAW-01 browser-injection, RAW-19, RAW-21 and RAW-23 limitations above.
- **RAW-01:** dependency recovery is implemented and automated verification passes; only missing-dependency browser injection remains Not Executed.

WQ contract exclusions and below-detection transformations remain explicit and covered by standalone tests. They do not mitigate DATA-01 or DATA-02.

## 8. Final Browser/Manual Verification Outcome

The final browser/manual recovery smoke session is complete with documented limitations. RAW-01 passes based on implementation plus automated verification, while missing-`ggnewscale` browser injection remains Not Executed. RAW-20 is Superseded / N/A, and RAW-25 remains Deferred / Known Limitation. RAW-19/21 destructive browser fault injection and RAW-23 invalid-sheet browser injection were not executed.

## 9. Recommended Next Actions

1. Retain the final QA evidence/report with the automated baseline, qualified browser/manual results, RAW-20 Superseded / N/A disposition, RAW-25 Deferred limitation, and DATA-01/DATA-02 risks.
2. If browser evidence is later required for RAW-01, perform only the isolated missing-dependency injection and recovery verification; do not relabel general navigation smoke as RAW-01.
3. Schedule RAW-25 only as future dedicated lifecycle/refactoring work.
