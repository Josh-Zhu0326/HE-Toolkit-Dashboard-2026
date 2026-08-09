# RAW-01–25 Recovery Coverage Audit

Audit date: 2026-07-30  
Audit scope: current local `main` / current `HEAD`; this is not final RC sign-off.

## 1. Audit Baseline

| Item | Value |
|---|---|
| Branch | `main` |
| HEAD | `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca` |
| Locally cached `origin/main` | `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca` |
| Ahead / behind | `0 / 0` from `git rev-list --left-right --count origin/main...HEAD` |
| Network freshness | Unclear. No fetch or external-service call was made, so `origin/main` means the locally cached ref. |
| Start worktree | `?? docs/week09/`; this directory already contained the user-owned untracked `docs/week09/2026-07-30-benyu-return-audit.md`. The requested report target did not exist. |
| OS | Windows 11 x64, build 26200 |
| PowerShell | 5.1.26100.8737 |
| Git | 2.52.0.windows.1 |
| R | 4.6.1 (2026-06-24 ucrt), `x86_64-w64-mingw32/x64` |
| R timezone / locale | `Europe/London`; Chinese (Simplified) China UTF-8 locale, `LC_NUMERIC=C` |
| R invocation | `C:\Program Files\R\R-4.6.1\bin\Rscript.exe --vanilla`; `Rscript` was not on `PATH` |
| Restrictions observed | No application/test-code edit, dependency change, external service, real customer data, commit, push, merge, reset, rebase, stash, or evidence overwrite. |

Interpretation used in this audit:

- **Documented** means the RAW definition exists in the authority below.
- **Implemented** means a runtime path prevents or handles the scenario. `Partial` is not counted as full alignment, but is included in the “any implementation” total.
- **Automated test exists** means a test asserts this scenario or a close, explicitly identified slice. Merely loading the file does not count.
- **Executed current main** means that linked automation was actually run at the baseline commit in this audit.
- **Final RC evidence available** is `No` for every row. Current-main console results and old July records are not final RC evidence.
- A row-level `Pass` means only the linked automated slice passed; it does not close unexecuted browser, recovery, retained-state, or RC checks.

## 2. Source of RAW-01–25

The authoritative source is `docs/week05/5.3_Error_List.md`.

- Lines 7–31 define exactly one row each for `RAW-01` through `RAW-25`.
- The identifiers are continuous, unique, and complete: 25 definitions, no missing ID and no duplicate ID.
- Lines 33–39 add common acceptance criteria: friendly UI message; no raw R error, stack trace, or local path; loading state must end; other pages/controls remain usable; repeated clicks must be prevented while processing.
- `docs/week08/WK8-09_Complete_Error_List.md` is useful later guidance, especially `OUTPUT-08` to `OUTPUT-12`, but uses a different identifier scheme and does not replace the RAW authority.
- Historical July test records and `docs/week09/2026-07-30-benyu-return-audit.md` are supporting evidence only, not definitions and not current/final RC execution.

Conclusion: a complete RAW-01–25 definition set does exist.

## 3. Coverage Summary

### Five-state coverage

| State | Count | Basis |
|---|---:|---|
| Documented | 25 | All IDs exist in the authoritative source. |
| Implemented — direct | 14 | RAW-04–17 have a direct guard, prevention rule, or prerequisite message, though wording/state evidence is sometimes incomplete. |
| Implemented — partial | 4 | RAW-18, RAW-22, RAW-23, RAW-24 are covered only on selected paths. |
| Implemented — any direct or partial | 18 | Direct plus partial; this is the “implemented quantity” used in the hand-off summary. |
| Not implemented | 7 | RAW-01, RAW-02, RAW-03, RAW-19, RAW-20, RAW-21, RAW-25. |
| Automated test exists — scenario/near-scenario | 8 | RAW-05, RAW-06, RAW-07, RAW-08, RAW-09, RAW-10, RAW-18, RAW-23. No test is labelled with a RAW ID. |
| Test executed on current main — RAW rows | 8 | The same eight rows had linked automation run. |
| Current RAW-row result: Pass | 8 | Linked automated slices passed. |
| Current RAW-row result: Pass with Warning | 0 | No scenario-level RAW assertion emitted a warning. |
| Current RAW-row result: Fail | 0 | No executed scenario-level RAW assertion failed. |
| Current RAW-row result: Not Executed | 17 | No safe existing scenario-level automation; browser/external/fault-injection/RC work was not run. |
| Final RC evidence available | 0 | Current-main output and historical evidence are not final RC evidence. |
| Final RC re-test required | 25 | Every RAW item must be re-run on the selected frozen RC. |

### Command-level result

The testthat runner passed. All eight standalone scripts exited 0. The standalone batch, and a confirming rerun of `tests/test_server_site_import.R`, emitted two non-blocking Leaflet `derivePoints()` warnings, so that command scope is recorded as **Pass with Warning**. This command-level warning does not convert untested RAW-22 failure recovery into an executed RAW scenario.

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
| Implemented message | None. Namespace calls are made directly. |
| Recovery action | Stop the operation; keep the session usable; an administrator restores the frozen RC dependencies, then the user retries the HEV plot. Do not ask a study participant to change packages mid-session. |
| Expected retained state | Site mapping, imported data, processed Biology/Flow, join, selections, and any prior valid plot remain intact and clearly marked current/stale as appropriate. |
| Implementation evidence | Not implemented. Direct calls at `global.R:485,524,565,605,637,675,715,755`; no `requireNamespace()`/friendly dependency guard was found. |
| Automated test | None. |
| Manual test | RC fault-injection step: in an isolated RC environment only, make `ggnewscale` unavailable, render each HEV variant, verify friendly message, spinner termination, navigation, retained join, and recovery after restoring the approved environment. |
| Current execution result | Not Executed |
| Release evidence | None. |
| RC re-test required | Yes |
| Gap | No dependency guard, no test, no retained-state/browser evidence. Raw R error and permanent loading remain possible. |
| Severity | Major |
| Recommended action | Add an environment preflight and feature-level safe message in a future code change; add an isolated missing-package recovery test and RC screenshot/log. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

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
| Current execution result | Automated Pass on `qa/raw-user-facing-recovery`; browser verification pending. |
| Release evidence | Historical `ST-04B` covers a valid donor path/warnings, not this parse failure or recovery. |
| RC re-test required | Yes |
| Gap | Previously identified implementation gap resolved on `qa/raw-user-facing-recovery`. Browser recovery/retention evidence is still pending. |
| Severity | Major |
| Recommended action | Run the malformed-to-valid browser recovery case on the selected RC and retain screenshot/log evidence. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Current execution result | Automated Pass on `qa/raw-user-facing-recovery`; browser verification pending. |
| Release evidence | None; historical `ST-04B` is a successful/expected-warning path only. |
| RC re-test required | Yes |
| Gap | Previously identified implementation gap resolved on `qa/raw-user-facing-recovery`. Browser recovery/retention evidence is still pending. |
| Severity | Major |
| Recommended action | Run separate malformed mapping and donor-list correct-and-retry browser cases on the selected RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Automated implementation gap closed; browser/Pilot evidence remains pending. |
| Severity | Minor |
| Recommended action | Run the Pilot Task 6 browser recovery check and capture the retained-state evidence. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | `TC-029`; historical `ST-07E`/`ST-07F`. RC must repeat zero-byte and header-only for every upload type, then valid replacement without restart. |
| Phase 2B automated test | `tests/testthat/test-site-metadata-helpers.R` covers header-only metadata. `tests/testthat/test-server-local-flow-source.R` covers valid-to-invalid-to-valid replacement recovery for metadata, Local Flow, Local Biology, WQ, and RHS while checking retained unrelated state. |
| Current execution result | Pass — linked automated slices passed; multi-source browser recovery was not executed. |
| Release evidence | Previously identified gap - resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. Historical `ST-07E`/`ST-07F` remains supporting evidence only. |
| RC re-test required | Yes |
| Gap | The previous stale-current replacement gap is closed in automated coverage. Per-control browser screenshots, file-input behaviour, and final RC evidence remain pending. |
| Severity | Major |
| Recommended action | Execute invalid-to-valid browser recovery for each upload control on the selected RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | Historical `ST-07E` and recovery `ST-07F`; RC: malformed delimiter/quotes/inconsistent rows for each upload, followed by valid replacement. |
| Phase 2B automated test | `tests/testthat/test-site-metadata-helpers.R` compares malformed uploaded and pasted metadata. `tests/testthat/test-server-local-flow-source.R` covers malformed Local Flow and WQ replacement, old-current invalidation, controlled text, and same-session retry. |
| Current execution result | Pass — linked parser/replacement slices passed; full browser matrix was not executed. |
| Release evidence | Previously identified gap - resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. July `ST-07E/F` remains historical only. |
| RC re-test required | Yes |
| Gap | The previous raw-parser/stale-current gap is closed for the Phase 2B upload paths. Browser loading-state and final RC screenshots remain pending. |
| Severity | Major |
| Recommended action | Execute malformed-to-valid browser recovery for every Phase 2B upload control on the selected RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | `TC-003`, `TC-013`; historical `ST-07C`; repeat every upload contract on RC. |
| Phase 2B automated test | `tests/testthat/test-dashboard-backlog-helpers.R` covers required core and optional-absence severity. `tests/testthat/test-server-local-flow-source.R` covers optional missing, valid, supplied-invalid, retained core join, and valid retry. |
| Current execution result | Pass — linked schema tests passed. |
| Release evidence | Previously identified gap - resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. Historical `ST-07C` is not current/RC evidence. |
| RC re-test required | Yes |
| Gap | The previous classification inconsistency and RHS/WQ supplied-invalid warning gap are closed. Browser recovery and final RC evidence remain pending. |
| Severity | Major |
| Recommended action | Verify required/optional message severity and disabled stale actions in the RC browser pass. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Current execution result | Pass — direct validation test passed; browser recovery was not executed. |
| Release evidence | Previously identified gap - resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | The previous upload/paste inconsistency and stale-current gap are closed in server automation. Browser retained-state evidence remains pending. |
| Severity | Major |
| Recommended action | Capture RC browser evidence of upload/paste correction, resume, and state retention. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Current execution result | Pass — Local Flow and stale-state slices passed; exact mapping/browser path was not executed. |
| Release evidence | Previously identified gap - resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | The exact metadata invalid-replacement gap is closed in server automation. Browser and download-currentness evidence remain pending. |
| Severity | Major |
| Recommended action | Run stale Flow/join/HEV/model/download browser assertions on the selected RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | `TC-002`, `TC-015`; historical FT-01G/H were not run on the updated implementation. RC must confirm visible default/provenance and source-change recovery. |
| Current execution result | Pass — default/provenance automation passed. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | UI acknowledgement is implemented; final browser/RC provenance evidence remains pending. |
| Severity | Minor |
| Recommended action | Confirm the informational notice and HDE provenance in the browser/Pilot run. |
| Coverage states | Documented: Yes; Implemented: Yes (later HDE-default decision); Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Automated test | No exact click-without-Flow assertion. `tests/testthat/test-server-local-flow-source.R:162-260` covers invalid replacement/stale state only. |
| Manual test | Add RC case: click without Flow, navigate back, import valid Local Flow, retry, verify retained inputs and current-only results. |
| Current execution result | Not Executed |
| Release evidence | Historical normal Flow tests do not establish this recovery. |
| RC re-test required | Yes |
| Gap | No exact automation/browser recovery; possible simultaneous reactive console error and busy-state behaviour are unproved. |
| Severity | Major |
| Recommended action | Add a Shiny server test for the prerequisite alert and a browser retry/state-retention case. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No (only indirect state tests); Executed current main: No; Final RC evidence: No. |

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
| Manual test | RC: trigger without Biology, verify alert/UI/console/spinner, navigate back, import, retry, and check no unnecessary re-upload. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Automated recovery/state gap closed; browser spinner and navigation evidence remains pending. |
| Severity | Major |
| Recommended action | Capture the browser retry, spinner termination and retained-state evidence in Pilot/RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | RC: click RICT without Environment, verify blocking message and no console-only failure, import data, retry, inspect retained state. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Prerequisite recovery is automated; external-service failure handling remains outside Phase 2A and browser evidence is pending. |
| Severity | Major |
| Recommended action | Capture the prerequisite retry in Pilot/RC; retain the separate external-import failure gap for later work. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | RC: skip RICT, request O:E, verify alert/spinner/navigation, run RICT, retry O:E, verify prior inputs retained. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Automated block/retry and controlled message are complete; browser evidence remains pending. |
| Severity | Major |
| Recommended action | Capture the blocked notification, spinner termination and retry in Pilot/RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | RC: attempt join before stats; then create stats and join; change Flow source and verify old join, HEV, model and every download cannot be used until regeneration. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Direct automation and stale-input non-consumption are complete; browser/download evidence remains pending. |
| Severity | Major |
| Recommended action | Execute the browser recovery chain and confirm current-only downloads on Pilot/RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | RC: attempt join before O:E; complete O:E; retry; verify Flow stats retained and no stale output/download use. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Runtime wording and automated recovery are complete; browser recovery/state evidence remains pending. |
| Severity | Major |
| Recommended action | Capture the missing/stale O:E browser retry and retained Flow state in Pilot/RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Manual test | `TC-016` normal path; historical `ST-06` saw the message but was blocked. RC must test missing and stale joins, back navigation, regeneration, plot and download. |
| Current execution result | Pass — targeted automation. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. |
| RC re-test required | Yes |
| Gap | Exact automation and current-only HEV evaluation are complete; browser/download evidence remains pending. |
| Severity | Major |
| Recommended action | Confirm the blocked plot/download, rebuild and retry path in Pilot/RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Implementation evidence | Historical partial evidence retained: `R/wq_rhs_plot_helpers.R:122-190,193-267`; `server.R:1030-1033,1151-1171`; formerly unguarded HEV at `server.R:2456-2477`; raw HEV helper at `global.R:337-869`. Completion evidence: `R/plot_recovery_helpers.R` provides the plot-only result boundary; `server.R` applies it to WQ/RHS summary/mapped plots, PCA, both Flow heatmaps, analysis correlation/coverage, basic-model rendering and HEV. HEV failure finalises `hev_result` as failed while retaining previous plot/data/provenance and download history. |
| Automated test | Historical helper evidence retained: `tests/test_wq_rhs_plots.R:36-91` and `tests/test_model_interface_helpers.R`. `tests/testthat/test-plot-recovery.R` covers thrown, NULL, unsupported and delayed-render failures plus a corrected retry; `tests/testthat/test-workflow-server.R` covers HEV exception/unusable result, safe UI text, failed-not-running/current state, retained upstream/HEV history and same-session retry success. |
| Manual test | `TC-007`, `TC-009`, `TC-016–TC-021`; execute missing/invalid data and forced plotting error on every plot family. |
| Current execution result | Pass — targeted deterministic plot-boundary and workflow-server automation; browser recovery was not executed. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser verification pending. Historical plot images remain output examples, not recovery evidence. |
| RC re-test required | Yes |
| Gap | Automated implementation and exact HEV failure/finalisation/retention/retry coverage are complete; browser evidence remains pending. |
| Severity | Major |
| Recommended action | Verify the controlled messages and retry path for each listed plot family in the Pilot/RC browser run. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Current execution result | Pass — targeted deterministic file-boundary, HEV download/history and workflow-server automation; browser recovery was not executed. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser/manual verification pending. Existing downloaded/plot files remain output examples, not recovery evidence. |
| RC re-test required | Yes |
| Gap | Automated implementation and write-failure/retention/retry coverage are complete; browser/manual evidence remains pending. |
| Severity | Major |
| Recommended action | Verify controlled download failure and retry for each listed output family during browser/manual verification. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

### RAW-20

| Field | Required content |
|---|---|
| RAW ID | RAW-20 |
| Error scenario | A required runtime-generated Flow CSV is absent. |
| Trigger | A downstream step attempts to read an expected temporary/generated Flow file that was never created or was removed. |
| Affected workflow/task | Flow import/processing and all Flow-dependent outputs. |
| Blocking classification | Blocking |
| Expected user-facing message | “The required temporary flow file could not be found. Please re-import the flow data.” |
| Implemented message | No explicit generated-file handler found. Current application code does not directly reference `27034.csv`; the RAW scenario may be legacy, but it has not been formally retired. |
| Recovery action | Re-import current Flow data, recalculate statistics, then regenerate join/HEV/model/download. |
| Expected retained state | Mapping, Biology/Environment/O:E and user settings remain; Flow-derived outputs are stale/blocked. |
| Implementation evidence | No matching runtime handler/reference. General Flow source revision reset at `server.R:250-275` is not a missing-file recovery. |
| Automated test | None. |
| Manual test | RC/contract review first confirms whether generated files still exist. If applicable, remove only an isolated temp file, trigger read, verify message/state, re-import and regenerate. If obsolete, record justified N/A and retire the RAW definition formally. |
| Current execution result | Not Executed |
| Release evidence | None. |
| RC re-test required | Yes |
| Gap | Applicability unclear; no formal retirement, implementation, test, or evidence. |
| Severity | Major |
| Recommended action | Decide whether RAW-20 is live; implement/test it or record an approved scope retirement with replacement architecture evidence. |
| Coverage states | Documented: Yes; Implemented: No / applicability unclear; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

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
| Current execution result | Pass — targeted deterministic permission/filesystem, retained-state and retry automation; browser recovery was not executed. |
| Release evidence | Previously identified gap — resolved on `qa/raw-user-facing-recovery`. Implementation complete; browser/manual verification pending. |
| RC re-test required | Yes |
| Gap | Automated implementation and deterministic permission/filesystem retention/retry coverage are complete; browser/manual evidence remains pending. |
| Severity | Major |
| Recommended action | Verify controlled permission/filesystem failure and retry across the listed runtime file paths during browser/manual verification. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

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
| Implementation evidence | Previously partial boundary resolved on `qa/raw-user-facing-recovery`: `safe_external_import()` classifies request errors, NULL/empty results and unusable result structures; `server.R` applies it to Biology, Environment, external Flow, additional donor Flow, WQ and RHS, records internal diagnostics separately from UI text, updates workflow currentness only after usable success, and resets donor running flags with `on.exit()`. |
| Automated test | `tests/testthat/test-donor-external-recovery.R` uses mocked failures/results for all covered paths, including service error, NULL/empty and invalid schema classification, failed-currentness, unrelated-state retention, running reset and success after retry. Existing local-Flow precedence and site-import tests remain linked regression coverage. |
| Manual test | RC isolated service stubs: timeout/HTTP/empty response for all five sources, retry success, optional-source continuation, local Flow fallback/precedence, retained state and spinner termination. Do not use real services for fault injection. |
| Current execution result | Automated failure/retry cases Pass on `qa/raw-user-facing-recovery`; browser verification pending. |
| Release evidence | Historical live-service successes are not outage recovery and not RC evidence. |
| RC re-test required | Yes |
| Gap | Previously identified application-boundary and deterministic automation gaps resolved on `qa/raw-user-facing-recovery`. RC browser evidence and application-wide timeout/button-lock policy remain pending. |
| Severity | Major |
| Recommended action | Run RC browser/fault-injection verification for each source; address global timeout/cancellation and application-wide button-lock consistency under RAW-25. |
| Coverage states | Documented: Yes; Implemented: Yes for the scoped external operations; Automated test exists: Yes; Executed current branch: Yes; Final RC evidence: No. |

### RAW-23

| Field | Required content |
|---|---|
| RAW ID | RAW-23 |
| Error scenario | Unhandled Shiny reactive/backend error appears only in console or as raw UI error. |
| Trigger | Any unexpected processing/join/plot/model reactive failure. |
| Affected workflow/task | Application-wide; especially Flow statistics, join, HEV, model and downloads. |
| Blocking classification | Blocking for the failed operation; other valid workflows should remain usable. |
| Expected user-facing message | “Something went wrong while processing this step. Please check your input and try again.” |
| Implemented message | Upload/model/WQ/RHS paths have local catches. There is no application-wide boundary; model catch includes raw `conditionMessage(e)` in parentheses. |
| Recovery action | End loading, show sanitised step-specific feedback, preserve existing valid state, allow back navigation and one retry; never mark failed output complete. |
| Expected retained state | Existing valid data/artifacts are intentionally unchanged unless their source changed; target artifact becomes failed/blocked, not success; no session reset. |
| Implementation evidence | Partial model wrapper `R/model_interface_helpers.R:27-82`; artifact failure path `server.R:2287-2320`; many legacy reactives remain unguarded, e.g. `server.R:1335-1470,1544-1650,1952-2063,2356-2477`. |
| Automated test | Partial: `tests/test_model_interface_helpers.R` asserts friendly results for no data/invalid variables/forced errors; workflow failed-state/resume tests in `tests/testthat/test-workflow-state.R:133-145`. No application-wide reactive exception test. |
| Manual test | `TC-021`, `TC-036–TC-039`; RC must inject backend failures at Flow stats, join, HEV, model and download, observe UI and R Console together, retry, and verify retained/current state. |
| Current execution result | Pass — model-interface slice passed; general Shiny error recovery was not executed. |
| Release evidence | Current helper result in Section 5. Historical `ST-05A`/`BUG-001` and `FT-07A`/`BUG-003` prove earlier raw/permanent failures, not current recovery. |
| RC re-test required | Yes |
| Gap | No global/step boundary, path-safe message guarantee, browser recovery, or complete target-state assertions. |
| Severity | Blocker |
| Recommended action | Before RC sign-off, add safe boundaries around critical reactives and deterministic failure/retry tests; remove raw exception text from user messages. |
| Coverage states | Documented: Yes; Implemented: Partial; Automated test exists: Yes (model slice only); Executed current main: Yes (model slice only); Final RC evidence: No. |

### RAW-24

| Field | Required content |
|---|---|
| RAW ID | RAW-24 |
| Error scenario | Local/developer filesystem path is exposed to the user. |
| Trigger | A parser/model/file exception contains `C:/Users/...` or another internal path and `conditionMessage(e)` reaches UI. |
| Affected workflow/task | Upload, donor input, model, download/temp and any fallback exception path. |
| Blocking classification | Blocking for the failed operation; information-disclosure risk application-wide. |
| Expected user-facing message | “An internal file-reading error occurred. Please check your input and try again.” |
| Implemented message | Upload wrappers sanitise selected read failures; metadata normalisation and donor/model paths can display `conditionMessage(e)`. |
| Recovery action | Correct/retry input without seeing internal details; preserve valid state; support logs may retain details only in an authorised location. |
| Expected retained state | Existing valid artifacts and inputs remain, failed target is not successful, and no local path appears in UI/download filename. |
| Implementation evidence | Partial safe upload messages `R/dashboard_backlog_helpers.R:1-19`, `server.R:448-478`; leaks possible at `server.R:696-704,752-756,1788-1792` and `R/model_interface_helpers.R:70-74`. |
| Automated test | None explicitly injects a path-bearing condition and asserts it is absent from rendered UI. |
| Manual test | Inject a synthetic error containing a fake path in every exception boundary; assert UI/DOM/screenshot lacks path/stack trace while authorised console log can be correlated. |
| Current execution result | Not Executed |
| Release evidence | None. |
| RC re-test required | Yes |
| Gap | No systematic sanitisation, negative disclosure test, or browser/RC evidence. |
| Severity | Major |
| Recommended action | Separate user-safe errors from internal diagnostics and add path/stack-trace redaction tests. |
| Coverage states | Documented: Yes; Implemented: Partial; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-25

| Field | Required content |
|---|---|
| RAW ID | RAW-25 |
| Error scenario | Backend processing fails or stalls and the dashboard remains permanently loading. |
| Trigger | Flow statistics/join/plot/external operation fails, hangs, or leaves Shiny busy state unresolved. |
| Affected workflow/task | Application-wide; critical historical examples are Flow statistics and Biology–Flow pairing. |
| Blocking classification | Blocking |
| Expected user-facing message | “The operation could not be completed. Please check your input and try again.” |
| Implemented message | No timeout/cancel/busy-recovery message on current main. `add_busy_spinner()` only reflects busy state. |
| Recovery action | Loading must terminate; prevent duplicate submission; show safe failure; keep other controls/pages usable; allow back navigation and retry without session reset. |
| Expected retained state | All previously valid artifacts and input selections remain; no half-built/stale target is usable; no re-upload unless the input source itself changed. |
| Implementation evidence | Spinner at `ui.R:205`; no timeout/cancel guard found. Critical processing paths remain unguarded at `server.R:1952-2063,2356-2477`. |
| Automated test | None on current main for timeout/permanent-loading/browser busy recovery. |
| Manual test | RC deterministic delay/error injection for Flow stats, join, external import and plot: assert spinner ends, button re-enables, duplicate clicks blocked, safe UI message, navigation/back works, artifacts retained, retry succeeds. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-05A`, `FT-07A`, `FT-07A-R1`, `BUG-001`, and `BUG-003` record 99%/permanent loading on older builds. They are failure evidence, not current/final RC recovery evidence. |
| RC re-test required | Yes |
| Gap | No timeout/cancellation/recovery implementation, automation, current browser result, or RC evidence. |
| Severity | Blocker |
| Recommended action | Treat busy-state recovery as an RC gate: implement bounded operations/finalisation and add deterministic browser tests before formal use. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

## 5. Current Executable Test Results

All commands ran from the repository root on `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca`. Times are Europe/London (`+01:00`). No test command contacted a real external service or modified tracked application/test/evidence files.

### Automated test inventory

All discovered testthat files were included by the runner. “Cross-cutting” means the file tests state/navigation/currentness relevant to recovery, but does not execute the named RAW trigger.

| Test file | RAW relationship | Current disposition |
|---|---|---|
| `tests/testthat/test-dashboard-backlog-helpers.R` | RAW-08 direct missing-`biol_site_id` validation | Executed; Pass |
| `tests/testthat/test-flow-mapping-contract.R` | RAW-10 Flow-source contract; RAW-07 mapping-schema context | Executed; Pass |
| `tests/testthat/test-flow-metadata-defaults.R` | RAW-10 missing/blank/default/provenance | Executed; Pass |
| `tests/testthat/test-local-flow-contract.R` | RAW-05–07 and RAW-09 local-upload/column/value slices | Executed; Pass |
| `tests/testthat/test-rhs-contract.R` | RAW-07 RHS identifier/schema slice | Executed; Pass |
| `tests/testthat/test-server-local-flow-source.R` | RAW-05–07/09/10 recovery and invalidation slices; RAW-11/15/17 stale-state context | Executed; Pass |
| `tests/testthat/test-setup.R` | Runner integrity only; no RAW trigger | Executed; Pass |
| `tests/testthat/test-site-metadata-helpers.R` | RAW-05/06 empty/missing/unreadable file slices; RAW-08–10 context | Executed; Pass |
| `tests/testthat/test-workflow-config.R` | Cross-cutting prerequisite/reuse/currentness contract for RAW-11–17/23/25 | Executed; Pass; no RAW trigger |
| `tests/testthat/test-workflow-server.R` | Cross-cutting retained state, stale propagation and completed-artifact state for RAW-11–17/23/25 | Executed; Pass; no RAW trigger |
| `tests/testthat/test-workflow-state.R` | Cross-cutting stale/failed/resume/currentness for RAW-11–17/23/25 | Executed; Pass; no RAW trigger |
| `tests/testthat/test-workflow-ui.R` | Cross-cutting checkpoint/recovery guidance/navigation markup for RAW-11–17/23/25 | Executed; Pass; no RAW trigger |
| `tests/test_backlog_helpers.R` | RAW-07–10 and RAW-18 helper slices | Executed; Pass |
| `tests/test_exclusion_log_helpers.R` | Cross-cutting silent deletion/warning/audit-log risk | Executed; Pass; no RAW trigger |
| `tests/test_filtering_helpers.R` | Cross-cutting deletion/retention/warning classification risk | Executed; Pass; no RAW trigger |
| `tests/test_model_interface_helpers.R` | RAW-18/23 partial safe-model/plot error; RAW-24 context | Executed; Pass |
| `tests/test_server_site_import.R` | RAW-22 mocked success context only; not outage/failure recovery | Executed; Pass with Warning |
| `tests/test_site_mapping.R` | RAW-08–10 validation/default slices; RAW-22 import helper context | Executed; Pass |
| `tests/test_wq_contract_helpers.R` | RAW-07/18-related data errors/warnings and explicit aggregation/exclusion provenance | Executed; Pass |
| `tests/test_wq_rhs_plots.R` | RAW-18 invalid/missing plot-input messages | Executed; Pass |

### Execution log

| Command | Start | End | Exit | Result | RAW association |
|---|---|---|---:|---|---|
| `C:\Program Files\R\R-4.6.1\bin\Rscript.exe --vanilla tests/testthat.R` | 17:24:01.387 | 17:24:20.342 | 0 | Pass; testthat summary reporter showed no failure/error/warning/skip | RAW-05–10, RAW-23 slices; cross-cutting state/resume/stale coverage |
| `...\Rscript.exe --vanilla tests/test_backlog_helpers.R` | 17:24:36.267 | 17:24:37.095 | 0 | Pass | RAW-07–10, RAW-18 helper coverage |
| `...\Rscript.exe --vanilla tests/test_exclusion_log_helpers.R` | 17:24:37.100 | 17:24:37.385 | 0 | Pass | Cross-cutting silent exclusion/logging risk; not a one-to-one RAW trigger |
| `...\Rscript.exe --vanilla tests/test_filtering_helpers.R` | 17:24:37.386 | 17:24:37.627 | 0 | Pass | Cross-cutting delete/retain/warning risk; not a one-to-one RAW trigger |
| `...\Rscript.exe --vanilla tests/test_model_interface_helpers.R` | 17:24:37.627 | 17:24:38.342 | 0 | Pass | RAW-18, RAW-23 partial |
| `...\Rscript.exe --vanilla tests/test_server_site_import.R` | 17:24:38.343 | 17:24:42.183 | 0 | Pass with Warning at batch scope; two Leaflet warnings appeared | RAW-22 success/mocked-import context only; RAW-22 failure recovery not executed |
| `...\Rscript.exe --vanilla tests/test_site_mapping.R` | 17:24:42.184 | 17:24:42.858 | 0 | Pass | RAW-08–10 |
| `...\Rscript.exe --vanilla tests/test_wq_contract_helpers.R` | 17:24:42.859 | 17:24:43.787 | 0 | Pass | RAW-07/18-related data validation and explicit WQ transformations |
| `...\Rscript.exe --vanilla tests/test_wq_rhs_plots.R` | 17:24:43.787 | 17:24:45.010 | 0 | Pass | RAW-18 partial |
| Confirming rerun: `...\Rscript.exe --vanilla tests/test_server_site_import.R 2>&1` | 17:24:56.404 | 17:25:00.333 | 0 | **Pass with Warning**; exactly two `derivePoints(...): restarting interrupted promise evaluation` warnings | Confirms warning source; not a RAW-22 outage test |

The eight standalone scripts were enumerated by `tests/test_*.R` and all were executed. The repository also contains:

- 12 files under `tests/testthat/`, all included by `tests/testthat.R`.
- `tests/manual/generate_plot_smoke_tests.R`, not executed because it writes/overwrites plot evidence.
- `TC-001`–`TC-039` in `tests/manual_test_matrix.csv` / `tests/manual_test_cases.md`, not executed because they require an interactive browser and an authorised evidence session.
- Historical July smoke/functional/bug records, inspected but not re-executed.

Tests not executed:

- Browser E2E/manual cases: require interactive UI and retained screenshots/logs tied to a selected RC.
- Real Biology/HDE/NRFA/WQ/RHS calls: prohibited external services.
- Missing-package, permission, timeout and service-failure injection: no existing safe isolated harness; dependency/environment mutation was prohibited.
- Plot smoke generator: would overwrite existing evidence.
- Final RC rerun: no frozen/identified final RC exists in this audit.

## 6. Missing Evidence

### Implementation gap

- RAW-01–03, RAW-19–21 and RAW-25 have no adequate implementation.
- RAW-18, RAW-22–24 are only partially guarded.
- Required external imports (Biology, Environment, Flow) lack the WQ/RHS-style safe wrapper.
- Download writers do not catch or sanitise file-creation failures.
- Busy/loading has no timeout, cancellation or guaranteed finalisation path.
- `conditionMessage(e)` can expose internal details.
- Stale-state metadata exists, but not every download/UI consumer explicitly checks currentness.

### Automation gap

- No test contains a RAW ID, so traceability is inferred rather than contractual.
- No exact automation for RAW-01–04, RAW-11–17, RAW-19–22, RAW-24 or RAW-25.
- No path-redaction, download-write-failure, permission, timeout, spinner-finalisation, duplicate-click, or app-wide reactive-error test.
- No automated browser assertion that stale output cannot feed join, HEV, model or download.

### Manual execution gap

- No RAW-01–25 scenario was executed in a current browser session during this audit.
- Retained input/artifact state, back navigation, no-session-reset, no-re-upload, and retry success are therefore unproved.
- `TC-001`–`TC-039` exist, but they are not RAW-linked and have no current execution packet.

### Browser E2E gap

- No current-main browser run proves UI message, spinner termination, control re-enable, no raw console-only failure, stale-output blocking, download behaviour and recovery in one trace.
- Historical July screenshots target older builds and include failures; they cannot be promoted to current or final RC evidence.

### RC-only verification gap

- There is no identified frozen RC/tag/manifest in scope.
- All 25 rows lack RC commit/environment, start/end, actor/reviewer, actual-vs-expected, safe screenshot/log, output hash and sign-off.
- Fault injection must use isolated RC stubs/sandboxes, never production services or customer data.

## 7. Risks

### Blocker

- **RAW-23:** no application-wide safe reactive boundary. Historical join/Flow failures showed R Console errors and missing UI recovery; current code still has critical unguarded paths.
- **RAW-25:** no permanent-loading recovery. Historical `ST-05A`, `FT-07A` and `FT-07A-R1` recorded 99%/loading defects, and current main has no timeout/finalisation test.
- **DATA-01:** `server.R:1637` silently keeps only the first Biology row per `biol_site_id`/Year/Season before O:E. No user message, provenance or direct regression test proves this deletion is scientifically intended.
- **DATA-02:** `server.R:1378` silently converts Environmental `NA` values to zero before RICT. This can change scientific outputs without a visible warning or retained source-vs-normalised audit trail.

### Major

- **RAW IDs:** RAW-01–03, RAW-05–09, RAW-11–22 and RAW-24.
- **Stale-output use:** state tests mark outputs stale, but direct browser/download currentness tests are absent; stale join/HEV/model/download use remains an RC risk.
- **State recovery:** in-memory state has no cross-session recovery; a reset requires re-upload, and no serialised checkpoint restoration exists.
- **Silent expansion/performance:** `server.R:2112-2117` creates site/year/season combinations and `server.R:2368-2377` creates daily rows from 1990 to current date before joins. Row-count/provenance guards and loading recovery are absent.
- **Warning/blocker mismatch:** WQ/RHS missing identifiers can be warnings while later operations require them; required-vs-optional severity is not consistently frozen across all UI paths.
- **Download and path disclosure:** writer failures are unhandled and several user-facing paths include raw `conditionMessage(e)`.

### Minor

- **RAW-04:** blank donor inputs have guards but wording, whitespace handling and recovery evidence are incomplete.
- **RAW-10:** later HDE-default behaviour is implemented/tested, but the original RAW definition has not been formally marked superseded and browser provenance is missing.

### Enhancement

- Add explicit RAW IDs to automated/manual test metadata and emit a machine-readable recovery manifest.
- Add a non-production fault-injection profile for package/service/filesystem/timeout failures.

Notes on data transformations:

- WQ contract exclusions and below-detection transformations at `R/wq_contract_helpers.R:150-181` do emit warnings and are covered by standalone tests.
- The mean bar plot at `R/wq_rhs_plot_helpers.R:181` is explicitly a “Mean” plot, but RC should still capture the aggregation choice and record count.
- These explicit paths do not mitigate the silent Biology deletion and Environment NA-to-zero risks above.

## 8. RC Re-test Plan

All RAW-01–25 require re-test after the final RC is frozen.

### Required baseline for every RC run

1. Record RC commit/tag, clean `git status`, `origin/main` relationship, OS/R/package lock/manifest and fixture checksums.
2. Use isolated synthetic fixtures and stubbed external services; never real customer data or production APIs.
3. For each trigger, capture start/end, command/manual ID, UI screenshot/DOM text, relevant safe console log, spinner/button state, artifact registry/currentness, retained inputs, navigation/back behaviour, retry result and reviewer.
4. Verify the failed operation never reports success and stale outputs cannot feed join, HEV, model or any download.
5. Run the valid recovery action and retain output/download hashes where applicable.

| RC batch | RAW IDs | Required execution | Evidence required |
|---|---|---|---|
| Dependency and donor parsing | RAW-01–04 | Isolated missing-package preflight; malformed/path-like/empty/whitespace donor mapping and donor list; correct-and-retry | Safe UI text, no path/stack, spinner end, donor/input retention, successful retry |
| Local upload recovery | RAW-05–07 | Zero-byte, header-only, malformed and missing-column variants for metadata/Biology/Flow/WQ/RHS; replace with valid files | Per-control screenshots, no session reset, required/optional severity, old-source invalidation, retained unrelated artifacts |
| Mapping fields/default | RAW-08–10 | Missing `biol_site_id`, missing `flow_site_id`, missing/blank `flow_input`, explicit HDE/NRFA; repair and resume | Message/provenance, Task-aware blocking, stage resume, Flow-derived invalidation |
| Prerequisite chain | RAW-11–17 | Trigger each action out of order; then complete the missing prerequisite and retry | Exact message, UI plus console correlation, no permanent loading, retained upstream state, no stale join/HEV/model/download |
| Plot recovery | RAW-18 | Missing/empty/invalid WQ/RHS/PCA/heatmap/analysis/HEV data and a forced plotting exception | Friendly message for every plot family, retained data/selections, failed artifact state, successful retry |
| File/download faults | RAW-19–21 | Isolated writer failure, missing temp/generated file if still applicable, and permission denial | Sanitised message, no leaked path, in-memory result retention, retry/download hash; approved N/A record if RAW-20 retired |
| External outage | RAW-22 | Stub timeout/HTTP/empty response for Biology/Environment/Flow/WQ/RHS; retry; local/optional fallback | Per-source classification, retained IDs/dates/local data, core workflow availability, spinner termination |
| General exception/redaction/loading | RAW-23–25 | Inject failures containing fake raw R text/path plus deterministic delays/errors in Flow stats/join/HEV/model/download | No raw/path UI, safe console correlation, target not successful, loading ends, button re-enables, duplicate click blocked, navigation/retry |
| Full regression | RAW-01–25 | Re-run `tests/testthat.R`, all eight standalone tests, all linked manual cases, then two clean full workflow paths | Timestamped logs, screenshots, artifact/currentness checks, downloads and hashes, issue links, reviewer sign-off |

RC exit rule: every RAW row must be `Pass` or an explicitly approved, justified N/A; no open Blocker; every Major has an approved disposition; command-level warnings must be recorded as `Pass with Warning`, not Pass.

## 9. Recommended Next Actions

1. **Close the two release-blocking recovery boundaries:** implement and automate safe critical-reactive finalisation for RAW-23/25, including spinner/button recovery, sanitised UI feedback, retained state and retry.
2. **Create one deterministic RAW fault-injection suite:** cover donor/upload/package, external stub failures, path redaction, download/permission failures and stale-output prevention; label every test with RAW IDs.
3. **Freeze the RC and execute the full 25-row browser packet:** include the DATA-01/DATA-02 scientific transformation decisions, exact commit/environment, screenshots/logs, currentness checks, download hashes and reviewer sign-off.
