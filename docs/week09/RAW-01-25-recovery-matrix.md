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
| Implemented message | None for parse failure; only later validation messages such as “Donee flow sites not detected in original metadata”. |
| Recovery action | Correct the donor mapping text and resubmit; the UI must remain responsive and must not require re-import of already valid metadata/Flow. |
| Expected retained state | Donor text, metadata, imported Flow, chosen dates/settings, and prior valid artifacts remain; failed imputation/join outputs are not marked successful. |
| Implementation evidence | `server.R:1746-1756`, especially unguarded `fread()` at 1754. |
| Automated test | None. |
| Manual test | Paste malformed/path-like donor mapping; submit; assert no raw console-only failure, friendly UI feedback, loading ends, controls/navigation work, correct-and-retry succeeds without re-upload. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-04B` covers a valid donor path/warnings, not this parse failure or recovery. |
| RC re-test required | Yes |
| Gap | Unguarded parser; no automation; no current browser recovery/retention evidence. |
| Severity | Major |
| Recommended action | Wrap donor parsing, validate schema before use, preserve text, and add malformed-to-valid recovery automation. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-03

| Field | Required content |
|---|---|
| RAW ID | RAW-03 |
| Error scenario | Donor text is passed directly to `fread()` and exposes its raw parser error. |
| Trigger | Submit structurally invalid donor mapping or donor-list text. |
| Affected workflow/task | Flow processing / donor mapping, donor list, imputation. |
| Blocking classification | Blocking |
| Expected user-facing message | “The input format is invalid. Please check the donor-site format before importing.” |
| Implemented message | Donor mapping has none; donor list normalisation catches only the later normalisation error and can display raw `conditionMessage(e)`. |
| Recovery action | Keep pasted text available, show the expected format, allow correction and retry without session reset. |
| Expected retained state | Metadata, imported Flow, prior completed artifacts, date range and donor inputs remain; no stale imputation/statistic/join may be treated as current. |
| Implementation evidence | Unguarded mapping/list reads at `server.R:1754` and `server.R:1786`; raw `conditionMessage()` at `server.R:1788-1792`. |
| Automated test | None. |
| Manual test | Exercise malformed mapping and malformed donor-list variants separately; verify safe UI message, no path/stack trace, spinner exit, retained inputs, back navigation, and successful retry. |
| Current execution result | Not Executed |
| Release evidence | None; historical `ST-04B` is a successful/expected-warning path only. |
| RC re-test required | Yes |
| Gap | Parser errors are not consistently caught or sanitised. |
| Severity | Major |
| Recommended action | Introduce one safe donor parser with schema validation and tests for mapping/list invalid-to-valid recovery. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-04

| Field | Required content |
|---|---|
| RAW ID | RAW-04 |
| Error scenario | Empty or whitespace-only donor input. |
| Trigger | Attempt donor mapping/list processing with blank input. |
| Affected workflow/task | Flow processing / donor imputation. |
| Blocking classification | Blocking for imputation; non-blocking for workflows that do not request imputation. |
| Expected user-facing message | “Please enter donor-site information before importing donor flow data.” |
| Implemented message | “If imputing flows please add donor mapping” and “If imputing flows please add additional donor sites as required”. |
| Recovery action | Paste the required donor information or leave the optional imputation path; retry from the same Stage. |
| Expected retained state | Existing metadata/Flow and any unrelated completed artifacts remain; empty input is not treated as success. |
| Implementation evidence | `validate(need())` at `server.R:1749-1751` and `server.R:1781-1783`. |
| Automated test | None. |
| Manual test | Blank and whitespace-only mapping/list; verify blocker only when imputation is requested, message wording, no raw error, controls usable, and valid retry. |
| Current execution result | Not Executed |
| Release evidence | None. |
| RC re-test required | Yes |
| Gap | No automated or current browser evidence; whitespace-only handling and retained state are unproved; wording differs from authority. |
| Severity | Minor |
| Recommended action | Add exact blank/whitespace tests and align the two messages and optional-path behaviour. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

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
| Implementation evidence | `R/dashboard_backlog_helpers.R:1-19`; `server.R:448-478,481-490,526-535,1198-1227`; replacement invalidation at `server.R:1254-1256`. |
| Automated test | Near-scenario: `tests/testthat/test-site-metadata-helpers.R:31`, “header-only site metadata CSV is reported as empty”; replacement-state test `tests/testthat/test-server-local-flow-source.R:162`, “replacing valid Local Flow with an invalid file removes the previous local source”. |
| Manual test | `TC-029`; historical `ST-07E`/`ST-07F`. RC must repeat zero-byte and header-only for every upload type, then valid replacement without restart. |
| Current execution result | Pass — linked automated slices passed; multi-source browser recovery was not executed. |
| Release evidence | Current command record in Section 5; old `ST-07E`/`ST-07F` text is historical and not RC evidence. |
| RC re-test required | Yes |
| Gap | No complete per-source recovery matrix, screenshots, file-input retention evidence, or final RC run. |
| Severity | Major |
| Recommended action | Parameterise empty-file automation for all upload controls and execute invalid-to-valid browser recovery on RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes (near-scenario); Executed current main: Yes; Final RC evidence: No. |

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
| Implementation evidence | Safe reads at `R/dashboard_backlog_helpers.R:1-19`, `R/site_mapping_helpers.R:54-69`, `server.R:448-478`; upload rendering at `server.R:586-605,686-719,1198-1227`. |
| Automated test | `tests/testthat/test-site-metadata-helpers.R:48`, “existing non-CSV input is reported as unreadable”; replacement test at `tests/testthat/test-server-local-flow-source.R:162`. |
| Manual test | Historical `ST-07E` and recovery `ST-07F`; RC: malformed delimiter/quotes/inconsistent rows for each upload, followed by valid replacement. |
| Current execution result | Pass — linked parser/replacement slices passed; full browser matrix was not executed. |
| Release evidence | Section 5 current command record; July `ST-07E/F` is historical only. |
| RC re-test required | Yes |
| Gap | No exact all-control automation; no retained-state, loading, or final RC screenshots. |
| Severity | Major |
| Recommended action | Add shared upload-contract tests and RC browser recovery evidence for every file control. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current main: Yes; Final RC evidence: No. |

### RAW-07

| Field | Required content |
|---|---|
| RAW ID | RAW-07 |
| Error scenario | Required columns are missing after upload. |
| Trigger | Upload a readable CSV that omits columns required by that source contract. |
| Affected workflow/task | Stage 1 validation for mapping, Local Biology/Flow, WQ/RHS. |
| Blocking classification | Blocking for required-source schema errors; WQ/RHS warning/error classification is path-specific and partly unclear. |
| Expected user-facing message | “The uploaded file is missing required columns. Please check the file format and upload again.” |
| Implemented message | Source-specific lists, e.g. “Local flow CSV is missing required column(s): ...”; WQ missing site ID is a warning, while RHS missing `rhs_survey_id` is also currently a warning. |
| Recovery action | Add/rename required columns and re-upload; optional-source warning must not block core work. |
| Expected retained state | Existing unrelated artifacts remain; invalid required source is blocked; old/stale source cannot continue into Flow stats/join/model/download. |
| Implementation evidence | `R/dashboard_backlog_helpers.R:22-100,102-158`; WQ/RHS validators `server.R:481-570`; flow invalidation `server.R:1254-1280`. |
| Automated test | `tests/testthat/test-local-flow-contract.R:38`, “missing required Local Flow columns are rejected”; `tests/testthat/test-dashboard-backlog-helpers.R:4`; standalone `tests/test_backlog_helpers.R:11-18`; WQ contract missing-column checks in `tests/test_wq_contract_helpers.R:94-97`. |
| Manual test | `TC-003`, `TC-013`; historical `ST-07C`; repeat every upload contract on RC. |
| Current execution result | Pass — linked schema tests passed. |
| Release evidence | Section 5 current command record; historical `ST-07C` is not current/RC. |
| RC re-test required | Yes |
| Gap | No single classification contract across sources; RHS required-column warning may incorrectly allow progress; browser recovery and stale-output blocking unproved. |
| Severity | Major |
| Recommended action | Freeze required-vs-optional schema severity, test every source, and verify stale downstream actions are disabled. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current main: Yes; Final RC evidence: No. |

### RAW-08

| Field | Required content |
|---|---|
| RAW ID | RAW-08 |
| Error scenario | Metadata lacks `biol_site_id`. |
| Trigger | Parse/upload mapping used by Biology-related work without `biol_site_id`. |
| Affected workflow/task | Stage 1 site mapping; Biology import, O:E, join. |
| Blocking classification | Blocking when the selected Task requires Biology; potentially non-blocking for a source-only mapping, so Task-aware classification is not fully explicit. |
| Expected user-facing message | “The metadata file is missing the required column biol_site_id.” |
| Implemented message | “Mapping CSV is missing required column(s): biol_site_id.” |
| Recovery action | Add `biol_site_id`, re-upload/revalidate, then resume the earliest blocked Stage. |
| Expected retained state | Entered mapping and unrelated valid artifacts remain; Biology-dependent outputs are blocked/stale, not silently reused. |
| Implementation evidence | `validate_supporting_mapping()` at `R/dashboard_backlog_helpers.R:22-86`; upload feedback at `server.R:686-719`; Task resume at `R/workflow_state.R:234-287`. |
| Automated test | `tests/testthat/test-dashboard-backlog-helpers.R:4`, “mapping validation reports a missing biol_site_id column”; resume/stale state tests in `tests/testthat/test-workflow-state.R:116-145` are cross-cutting, not the upload trigger. |
| Manual test | `TC-003`; upload missing `biol_site_id`, confirm error, correct file, resume, and verify prior unrelated artifacts. |
| Current execution result | Pass — direct validation test passed; browser recovery was not executed. |
| Release evidence | Section 5 current test record only. |
| RC re-test required | Yes |
| Gap | No current end-to-end retry, Task-aware severity, retained-state, or stale-use proof. |
| Severity | Major |
| Recommended action | Add Shiny-server invalid-to-valid mapping test plus RC browser evidence of resume and state retention. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes; Executed current main: Yes; Final RC evidence: No. |

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
| Implementation evidence | `R/dashboard_backlog_helpers.R:22-86,102-158`; source revision reset `server.R:250-275,1254-1280`; stale propagation `R/workflow_state.R:179-204`. |
| Automated test | Near-scenario: `tests/testthat/test-local-flow-contract.R:38-55`, including missing/blank `flow_site_id`; stale replacement tests `tests/testthat/test-server-local-flow-source.R:162-260`. No exact metadata-file RAW trigger test. |
| Manual test | `TC-003`, `TC-013`; validate mapping and Local Flow variants, recover, then prove old Flow stats/join/download cannot be reused. |
| Current execution result | Pass — Local Flow and stale-state slices passed; exact mapping/browser path was not executed. |
| Release evidence | Section 5 current test record only. |
| RC re-test required | Yes |
| Gap | Exact metadata scenario and UI recovery are not automated; download-currentness remains unproved. |
| Severity | Major |
| Recommended action | Add exact mapping trigger plus stale join/HEV/model/download browser assertions. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: Yes (near-scenario); Executed current main: Yes; Final RC evidence: No. |

### RAW-10

| Field | Required content |
|---|---|
| RAW ID | RAW-10 |
| Error scenario | Authority expected missing `flow_input` to error; later decision makes missing/blank values default to HDE. |
| Trigger | Metadata omits `flow_input` or supplies blank/NA values. |
| Affected workflow/task | Stage 1 mapping; external Flow source selection. |
| Blocking classification | Non-blocking under the later HDE-default contract. |
| Expected user-facing message | RAW authority: “The metadata file is missing the required column flow_input.” Later guidance: “HDE was selected as the default Flow source.” |
| Implemented message | No error; HDE is assigned with provenance. Upload success text does not explicitly announce every defaulted row. |
| Recovery action | Review the provenance/default; change individual sites to NRFA if required, then re-import/recalculate Flow-derived outputs. |
| Expected retained state | Mapping and unrelated artifacts remain; changing a source invalidates Flow-derived artifacts without session reset. |
| Implementation evidence | `normalise_site_metadata_flow_input()` at `R/site_mapping_helpers.R:71-114`; use in `server.R:696-724,749-765`; Flow invalidation at `server.R:250-275`. |
| Automated test | `tests/testthat/test-flow-metadata-defaults.R:17-78`; `tests/testthat/test-flow-mapping-contract.R:17-29`; provenance/server tests `tests/testthat/test-server-local-flow-source.R:93-160`. |
| Manual test | `TC-002`, `TC-015`; historical FT-01G/H were not run on the updated implementation. RC must confirm visible default/provenance and source-change recovery. |
| Current execution result | Pass — default/provenance automation passed. |
| Release evidence | Section 5 current test record; no current browser/RC evidence. |
| RC re-test required | Yes |
| Gap | Authority and later scope differ; UI acknowledgement and RC provenance evidence are missing. |
| Severity | Minor |
| Recommended action | Formally annotate RAW-10 as superseded by the HDE-default decision and add a browser assertion for visible provenance. |
| Coverage states | Documented: Yes; Implemented: Yes (prevention/scope change); Automated test exists: Yes; Executed current main: Yes; Final RC evidence: No. |

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
| Implemented message | “Please import biology data.” |
| Recovery action | Return to Data Input, import Biology, complete required processing, and retry. |
| Expected retained state | Metadata, Environment, Flow and unrelated outputs remain; no stale O:E/join/HEV/model is current. |
| Implementation evidence | Alert `server.R:1667-1684`; workflow artifacts `server.R:1652-1665`; dependency invalidation `R/workflow_state.R:179-204`. |
| Automated test | No exact missing-Biology click/recovery assertion; workflow-state tests are indirect. |
| Manual test | RC: trigger without Biology, verify alert/UI/console/spinner, navigate back, import, retry, and check no unnecessary re-upload. |
| Current execution result | Not Executed |
| Release evidence | Historical `TC-014`/`ST-04A` are happy paths, not current recovery. |
| RC re-test required | Yes |
| Gap | No exact test or current recovery evidence; old artifacts and loading behaviour unproved. |
| Severity | Major |
| Recommended action | Add direct prerequisite/server test and RC browser recovery capture. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-13

| Field | Required content |
|---|---|
| RAW ID | RAW-13 |
| Error scenario | RICT prediction requested before Environmental data exist. |
| Trigger | Click RICT prediction without a current Environmental import. |
| Affected workflow/task | Biology processing / RICT; O:E and downstream analysis. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please import environmental data before running RICT predictions.” |
| Implemented message | “Please import environmental base data.” |
| Recovery action | Import Environmental data, then rerun RICT. |
| Expected retained state | Metadata, Biology, Flow and unrelated artifacts remain; no stale prediction/O:E is current. |
| Implementation evidence | Alert `server.R:1567-1583`; unguarded import/calculation path `server.R:1375-1379,1544-1555`. |
| Automated test | None for this trigger. |
| Manual test | RC: click RICT without Environment, verify blocking message and no console-only failure, import data, retry, inspect retained state. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-04A`/`FT-06A` are success paths only. |
| RC re-test required | Yes |
| Gap | No exact automation/recovery; Environment import has no uniform external-error wrapper. |
| Severity | Major |
| Recommended action | Test prerequisite and external-import failure separately; capture both recovery paths on RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-14

| Field | Required content |
|---|---|
| RAW ID | RAW-14 |
| Error scenario | O:E requested before RICT predictions exist. |
| Trigger | Click O:E after Biology import but before successful RICT. |
| Affected workflow/task | Biology processing / O:E. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please run RICT predictions before calculating O:E ratios.” |
| Implemented message | “Please run RICT predictions.” |
| Recovery action | Run RICT successfully, then retry O:E. |
| Expected retained state | Biology/Environment/Flow inputs remain; failed O:E does not clear RICT prerequisites or mark downstream outputs current. |
| Implementation evidence | Alert `server.R:1700-1717`; O:E reactive `server.R:1632-1650`. |
| Automated test | None for this trigger/retry. |
| Manual test | RC: skip RICT, request O:E, verify alert/spinner/navigation, run RICT, retry O:E, verify prior inputs retained. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-04A` is a completed sequence, not missing-prerequisite recovery. |
| RC re-test required | Yes |
| Gap | No exact automation/browser evidence and no proof the reactive error is also represented in UI. |
| Severity | Major |
| Recommended action | Add prerequisite test and RC recovery screenshot/log with artifact-state assertions. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-15

| Field | Required content |
|---|---|
| RAW ID | RAW-15 |
| Error scenario | Join requested before current Flow statistics exist. |
| Trigger | Click Biology–Flow join without Flow statistics, or after Flow source changes and old statistics become stale. |
| Affected workflow/task | Task “Build Joined HE dataset”; Stage 3 Processing / join; downstream HEV/model/download. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please calculate flow statistics before joining biology and flow data.” |
| Implemented message | “Flow statistics are missing.” |
| Recovery action | Return to Flow processing, calculate statistics from the current source, return to join, and rerun. |
| Expected retained state | Valid Biology/O:E and mapping remain; completed old join/HEV/model/download must be stale/blocked, not usable as success. |
| Implementation evidence | Alert `server.R:2160-2177`; revision gates `server.R:1952-1967,2050-2079`; state invalidation `server.R:250-275`, `R/workflow_state.R:179-204`. |
| Automated test | No exact missing-prerequisite UI test. Indirect stale tests: `tests/testthat/test-server-local-flow-source.R:213-260`, `tests/testthat/test-workflow-server.R:127-205`. |
| Manual test | RC: attempt join before stats; then create stats and join; change Flow source and verify old join, HEV, model and every download cannot be used until regeneration. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-05A` failed for another backend error; it is not current RAW-15 evidence. |
| RC re-test required | Yes |
| Gap | Missing one-to-one test, current browser recovery, and download-currentness proof. |
| Severity | Major |
| Recommended action | Add direct prerequisite and stale-download tests; execute full recovery chain on RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No (indirect state tests only); Executed current main: No; Final RC evidence: No. |

### RAW-16

| Field | Required content |
|---|---|
| RAW ID | RAW-16 |
| Error scenario | Join requested before O:E/processed Biology exists. |
| Trigger | Click join without a current `biol_all()`/O:E result. |
| Affected workflow/task | Task “Build Joined HE dataset”; Stage 3 join; downstream HEV/model/download. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please calculate O:E ratios before joining biology and flow data.” |
| Implemented message | “Processed biology data are missing.” |
| Recovery action | Complete RICT and O:E, return to Analysis, and rerun join. |
| Expected retained state | Mapping, Flow and Flow statistics remain; incomplete/stale joined/HEV/model/download artifacts remain blocked. |
| Implementation evidence | Alert `server.R:2141-2158`; join uses `biol_all()` at `server.R:2050-2063`; stale dependencies at `R/workflow_state.R:5-25,179-204`. |
| Automated test | No exact trigger/retry assertion; workflow state/config tests are indirect. |
| Manual test | RC: attempt join before O:E; complete O:E; retry; verify Flow stats retained and no stale output/download use. |
| Current execution result | Not Executed |
| Release evidence | None current; July join records are historical and encountered other failures. |
| RC re-test required | Yes |
| Gap | Runtime wording is less specific; no exact test or browser recovery/state evidence. |
| Severity | Major |
| Recommended action | Align the prerequisite message, add a direct test, and capture RC retry plus stale gates. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-17

| Field | Required content |
|---|---|
| RAW ID | RAW-17 |
| Error scenario | HEV plot requested before a current joined dataset exists. |
| Trigger | Click “Create HEV plot” without a successful current join, including after inputs/settings make the old join stale. |
| Affected workflow/task | Task “Generate HEV plots”; Stage 4 HEV. |
| Blocking classification | Blocking |
| Expected user-facing message | “Please join biology and flow data before creating an HEV plot.” |
| Implemented message | “Paired biology-flow data are missing.” |
| Recovery action | Return to the earliest blocked Stage, regenerate join, return to HEV, and render again. |
| Expected retained state | Inputs and current upstream artifacts remain; an old HEV plot/download cannot be used as current; no session reset or re-upload should be needed. |
| Implementation evidence | Alert `server.R:2426-2443`; revision gate `server.R:2356-2397`; resume logic `R/workflow_state.R:234-287`. |
| Automated test | No exact HEV click/recovery test. Cross-cutting resume/stale tests: `tests/testthat/test-workflow-state.R:116-145`, `tests/testthat/test-workflow-server.R:127-205`. |
| Manual test | `TC-016` normal path; historical `ST-06` saw the message but was blocked. RC must test missing and stale joins, back navigation, regeneration, plot and download. |
| Current execution result | Not Executed |
| Release evidence | Historical `ST-06` at an older build only; no current/final RC recovery packet. |
| RC re-test required | Yes |
| Gap | No current browser or exact automation; HEV download does not itself assert artifact currentness. |
| Severity | Major |
| Recommended action | Add HEV prerequisite/stale download test and execute the whole retry chain on RC. |
| Coverage states | Documented: Yes; Implemented: Yes; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-18

| Field | Required content |
|---|---|
| RAW ID | RAW-18 |
| Error scenario | Plotting receives missing, empty, invalid, or incompatible data and exposes a `ggplot` error. |
| Trigger | Select invalid/no plot data, missing date/numeric fields, invalid HEV inputs, or a plotting exception. |
| Affected workflow/task | WQ/RHS plots, WQ summary, PCA/heatmap, analysis plots, HEV. |
| Blocking classification | Blocking for that plot only; normally non-blocking for other workflows. |
| Expected user-facing message | “The plot could not be created because the required data is missing or invalid.” |
| Implemented message | WQ/RHS helpers return specific friendly messages such as “A WQ time series needs a date-like column”; model plotting is guarded. Legacy/HEV plotting has no general safe wrapper. |
| Recovery action | Keep valid data and selections, choose valid variables/date range or regenerate prerequisites, then retry the plot. |
| Expected retained state | Upstream data/results and prior valid artifacts remain; failed new plot is not marked complete; other pages stay usable. |
| Implementation evidence | Partial: `R/wq_rhs_plot_helpers.R:122-190,193-267`; `server.R:1030-1033,1151-1171`; unguarded HEV at `server.R:2456-2477`; raw HEV helper at `global.R:337-869`. |
| Automated test | `tests/test_wq_rhs_plots.R:36-91` includes missing date/numeric friendly-message assertions; model plot/error tests in `tests/test_model_interface_helpers.R`; no legacy/HEV exception test. |
| Manual test | `TC-007`, `TC-009`, `TC-016–TC-021`; execute missing/invalid data and forced plotting error on every plot family. |
| Current execution result | Pass — WQ/RHS/model helper slices passed; HEV/legacy/browser recovery was not executed. |
| Release evidence | Section 5 current helper results; existing plot images are output examples, not recovery evidence. |
| RC re-test required | Yes |
| Gap | Partial coverage only; no application-wide plot wrapper, exact HEV test, loading/state retention, or browser evidence. |
| Severity | Major |
| Recommended action | Standardise a safe plot result contract and add tests for every plot family before RC rerun. |
| Coverage states | Documented: Yes; Implemented: Partial; Automated test exists: Yes (partial); Executed current main: Yes; Final RC evidence: No. |

### RAW-19

| Field | Required content |
|---|---|
| RAW ID | RAW-19 |
| Error scenario | Download handler cannot create/open the requested output file. |
| Trigger | Write failure, invalid destination, or output writer/`ggsave()` failure. |
| Affected workflow/task | WQ/RHS CSV/PNG, exclusion log, HEV plot, table/download outputs. |
| Blocking classification | Blocking for the download; non-blocking for the already completed analysis. |
| Expected user-facing message | “The file could not be created. Please try again or check file permissions.” |
| Implemented message | Only “No ... data are available to download” preconditions on selected WQ/RHS downloads; no write-failure catch. |
| Recovery action | Preserve the completed in-memory result; retry download, regenerate only if necessary, and contact support if persistent. |
| Expected retained state | All inputs and completed artifacts remain; no re-upload/reprocessing solely because a file write failed. |
| Implementation evidence | Unguarded handlers `server.R:741-747,967-985,1048-1056,1182-1196,1313-1316`; HEV module `global.R:879-890`. |
| Automated test | None for write failure or retained state. |
| Manual test | `TC-008`, `TC-010`, `TC-016`, `TC-022`, `TC-033` cover happy paths only. RC fault injection must force writer/permission failure, verify UI message and successful retry. |
| Current execution result | Not Executed |
| Release evidence | None. Existing downloaded/plot files do not prove failure recovery. |
| RC re-test required | Yes |
| Gap | No safe write boundary, no error UI, no automation, no browser evidence. |
| Severity | Major |
| Recommended action | Wrap every download writer in one sanitised error contract and test failure plus retry without recomputation. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

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
| Implemented message | None general. |
| Recovery action | Preserve current results; use an authorised writable runtime location/retry; do not require data re-upload unless the source itself is inaccessible. |
| Expected retained state | Inputs, completed artifacts, plots/tables and navigation remain usable; failed file is not presented as downloaded. |
| Implementation evidence | Unguarded writers listed under RAW-19; temp RHS helper `R/site_mapping_helpers.R:215-232` has cleanup but no user-facing permission contract. |
| Automated test | None. |
| Manual test | In an isolated RC sandbox, inject a non-writable target/temp directory without altering production data; verify friendly message, no leaked path, result retention, and retry. |
| Current execution result | Not Executed |
| Release evidence | None. |
| RC re-test required | Yes |
| Gap | No permission handler, safe fault-injection test, or recovery evidence. |
| Severity | Major |
| Recommended action | Centralise file operations with sanitised permission errors and deterministic isolated tests. |
| Coverage states | Documented: Yes; Implemented: No; Automated test exists: No; Executed current main: No; Final RC evidence: No. |

### RAW-22

| Field | Required content |
|---|---|
| RAW ID | RAW-22 |
| Error scenario | External data source returns HTTP/timeout/URL failure. |
| Trigger | Biology, Environment, Flow, WQ or RHS service is unavailable or times out. |
| Affected workflow/task | Stage 1 external imports and every dependent Task. |
| Blocking classification | Blocking for a required requested source; non-blocking for optional WQ/RHS and for workflows with an operational local alternative. |
| Expected user-facing message | “The external data source could not be reached. Please check the connection and try again.” |
| Implemented message | WQ: “WQ data could not be imported ... Check the IDs, dates, and network connection.” RHS has similar guarded result. Biology, Environment and external Flow have no uniform catch. |
| Recovery action | Keep IDs/date ranges/local uploads; retry service once, use approved local alternative where supported, or continue core workflow without optional WQ/RHS. |
| Expected retained state | All local inputs and unrelated current artifacts remain; failed source/dependent outputs are not successful; optional failure does not block core. |
| Implementation evidence | Partial: WQ catch `server.R:848-864`; RHS catch `server.R:897-920`; unguarded required imports `server.R:1335-1339,1375-1379,1438-1447`; external Flow wrapper directly calls service at `R/site_mapping_helpers.R:117-124`. |
| Automated test | No failure/timeout test. `tests/test_server_site_import.R` and `tests/testthat/test-server-local-flow-source.R` mock successful external imports/local precedence only. |
| Manual test | RC isolated service stubs: timeout/HTTP/empty response for all five sources, retry success, optional-source continuation, local Flow fallback/precedence, retained state and spinner termination. Do not use real services for fault injection. |
| Current execution result | Not Executed — the mocked success test ran (with two Leaflet warnings) but the RAW failure trigger did not. |
| Release evidence | Historical live-service successes are not outage recovery and not RC evidence. |
| RC re-test required | Yes |
| Gap | Partial implementation, inconsistent blocking classification, no deterministic failure automation or RC browser evidence. |
| Severity | Major |
| Recommended action | Use one external-call result contract with timeout/fallback semantics and stubbed failure tests for every source. |
| Coverage states | Documented: Yes; Implemented: Partial; Automated test exists: No for failure recovery; Executed current main: No; Final RC evidence: No. |

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
