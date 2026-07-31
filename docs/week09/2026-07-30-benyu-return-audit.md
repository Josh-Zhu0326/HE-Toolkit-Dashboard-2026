# Benyu Return-to-Project Audit — 2026-07-30

> Audit scope: repository evidence available locally on 2026-07-30. This is a read-only audit apart from this report. Remote refs were compared without checkout, fetch, merge, or network/API access. Participant-identifying material was not inspected or reproduced.

## 1. Executive Summary

- The audited worktree started clean on `main`; `HEAD` and the locally cached `origin/main` are both `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca` (PR #64 merge). There are no local tags and no ahead/behind commits.
- Main now contains the five-Task/five-Stage UI shell, shared Task/Stage configuration, an in-memory artifact registry, revision gates, local Flow operation, WQ/RHS validation/mapping, the WQ contract summary, and basic single-predictor `lm()` support.
- The current automated suite passed: 87 test cases / 346 expectations, with 0 failures, 0 errors, 0 warnings, and 0 skips. Eight standalone scripts also exited 0; the batch emitted two non-failing Leaflet `derivePoints()` warnings.
- Syntax parsing passed and a clean R 4.6.1 local startup smoke returned HTTP 200. This proves startup only, not a browser E2E research path.
- No unique RC commit/tag/manifest was found. No tag exists, and neither commit messages nor research records identify an RC.
- No Gate D record or evidenced `GO`, `GO WITH DOCUMENTED SCOPE REDUCTION`, or `NO-GO` decision was found.
- No repository evidence proves two real pilots. `docs/week08/pilot execution.md` is a blank session pack/template; branch `origin/zhaohang/week09-pilot-test-results` contains a task-script test result, not two de-identified participant session packets.
- No repository evidence proves formal sessions have started. Ethics approval is claimed in the decision log, but the same record requires an authoritative controlled ethics record, which is not present.
- Task 4 filter/restore and the contract-aware single-site/multi-site model guard exist only as unmerged helper/tests on `origin/yutong/filtering`; even there they are not wired to Shiny runtime.
- Main can mark Task 5 complete after fitting `stats::lm(ecology ~ flow)` without checking site count. On multi-site data this creates a material risk of presenting pooled `lm()` as the Task 5 result while the mixed path is contractually `not_ready`.
- RAW-01–25 are documented only as an error watch-list; there is no one-to-one executed recovery matrix. Several upload/prerequisite cases are implemented and indirectly tested, but many download, external failure, path-sanitisation, and permanent-loading recoveries are not.
- Benyu’s urgent gap is a traceable release chain tied to one approved RC: current browser E2E, Case Study 2/fixed fixture/reference parity, RAW recovery evidence, and formal governance/pilot records.

## 2. Git Baseline

### Baseline facts

| Field | Evidence-backed result |
|---|---|
| Actual local directory | `C:\Users\Benyu\Desktop\summer project\HE-Toolkit-Shiny-UI-Dashborad` (the filesystem name differs from the requested `...Dashboard`) |
| Branch | `main` |
| HEAD | `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca` |
| Locally cached `origin/main` | `9d0c7e9336e30c4e16ee83579a0cbcf39af0a3ca` |
| Ahead/behind | `0/0`; `git status -sb` showed `## main...origin/main` |
| Start status | Clean; no staged, modified, or untracked files |
| Tags | None (`git tag --sort=-creatordate` returned no output) |
| `origin/main...HEAD` | No stat or name-status differences |
| Network freshness | Unclear. No `fetch` was run, so all `origin/*` conclusions use locally cached refs only. |

### Recent 20 commits

| Commit | Main change |
|---|---|
| `9d0c7e9` | Merge PR #64, v2.2 UI parity |
| `3d716ea` | UI-to-Shiny mapping status changed to FROZEN |
| `620ba9f` | README project links |
| `7b200c1` | Shiny workflow UI aligned with v2.2 |
| `ce8eb95` | Merge user-facing error-guidance PR |
| `4d7afd3` | Adds guidance document only |
| `eab6802` | Merge v2.2 Shiny integration |
| `537507f` | Merge WQ contract summary |
| `7ac2606` | WQ plot spacing/manual image update |
| `631da1b` | WQ contract review fixes and tests |
| `e45b217` | Merge filtering PR |
| `4fcb1fb` | Mapping review status/date edits |
| `8622437` | UI-to-Shiny mapping and workflow server tests |
| `6b34efc` | Plot smoke generator and generated images |
| `c04a1c6` | WQ contract workflow and standalone test |
| `8111a0f` | Pilot session pack/template |
| `fb97ca8` | Merge workflow-freeze PR |
| `efb6473` | Merge filtering PR |
| `be1dc1c` | Exact duplicates changed to flag-and-retain |
| `053905f` | Workflow-freeze branch merge from main |

### Relevant remote refs

| Remote ref | Relationship to main | Unmerged evidence |
|---|---:|---|
| `origin/lin/fix/v22-ui-parity` | main-only 1, branch-only 0 | Fully contained in main |
| `origin/lin/fix/v22-ui-parity-followup` | main-only 0, branch-only 2 | `6782f4b`, `c663ec8`; 21-file diff adds recovery/state/server tests and 11 browser screenshots plus a Week 9 record |
| `origin/yutong/filtering` | main-only 0, branch-only 2 | `af7567e`, `758d73e`; adds Task 4 selection/restore helpers, single-site model guard, fixture, and two standalone tests; no Shiny UI/server wiring |
| `origin/zhaohang/week09-pilot-test-results` | main-only 0, branch-only 1 | `2198e0f`; adds one task-script test record |

Other locally cached unmerged refs are `origin/Volta0411-patch-2`, `origin/Volta0411-patch-3`, and `origin/feature/week7-architecture-real-fixtures`. The latter is four branch-only commits but diverges 23 main commits and therefore cannot be assumed RC-ready. There is research-relevant work only on personal/topic refs; none is part of the audited main build.

## 3. Changes Since the Previous Baseline

Status terms in this section are limited to the requested vocabulary. “Executed” refers to this audit unless an earlier/branch record is explicitly named.

### UI / Workflow, Runtime State, Data Pipeline, Analysis / Modelling

| # | Audit item | Status | Files/functions/lines; commit/branch | Tests and execution | Missing evidence / research impact / next step |
|---:|---|---|---|---|---|
| 1 | v2.2 UI parity; five Tasks/five Stages | Partially implemented | `R/workflow_config.R:4-117`; `R/workflow_ui.R`; `server.R:5-111`; `ui.R:212-228`; `7b200c1`, PR #64 | Workflow config/state/UI/server tests executed and passed | Automated markup/state evidence is strong, but main lacks real current browser acceptance; follow-up browser evidence is unmerged. Merge/review follow-up and rerun on RC. |
| 2 | Unified Task Selector/Start/Resume/Stage guidance | Verified complete | Single contract `he_workflow_tasks`, `he_workflow_stages`, `get_he_workflow_task()`, `workflow_resume_stage()`; `R/workflow_config.R:1-160`, `server.R:40-72` | Config/UI/server tests executed and passed | Completion applies to code/config integration, not browser study readiness. Preserve single-source tests on RC. |
| 3 | Runtime state, artifact status, revision | Partially implemented | `new_he_artifact()` schema and registry, `R/workflow_state.R:32-53,139-177`; Flow/join revisions `server.R:228-237` | State/server tests executed and passed | State is memory-only; not all artifacts have real backing data/version metadata, and no cross-session provenance exists. Add serialised checkpoint contract. |
| 4 | Precise stale propagation | Partially implemented | Dependency graph `R/workflow_state.R:5-25`; `invalidate_he_artifacts_from()` at 179-200; join setting gate `server.R:321-358` | State and server stale tests executed and passed | Main tests cover synthetic/server state, not current browser recovery. Branch follow-up contains additional evidence only. |
| 5 | Block stale analysis/download | Partially implemented | `join_data()` revision `req()` at `server.R:2067-2079`; `HEV_data()` gate at 2390-2397; model fetch catches unavailable join at 2290 | Server stale tests executed; no download/browser test | DataTable/download controls do not uniformly consult `artifact_is_current`; no explicit user-facing stale-download E2E. Add direct download-handler and browser assertions. |
| 6 | Biology local import | Partially implemented | `validate_local_invertebrate()` `R/dashboard_backlog_helpers.R:88-100`; UI `ui.R:398-416`; runtime `server.R:1199-1240` | Standalone and server site-import tests passed | Valid upload is only previewed and explicitly does not enter O:E. Required “local Biology import” research path is not operational end-to-end. |
| 7 | Flow local import | Verified complete | `validate_local_flow()` at `R/dashboard_backlog_helpers.R:102-158`; source precedence `server.R:1213-1280,1460-1469` | Contract and server tests executed/passed, including replacement/stale cases | No current real-browser record, so release evidence remains missing even though runtime is verified by tests. |
| 8 | WQ local import | Partially implemented | `read_uploaded_csv_safely()`, `validate_wq_upload()`, mapping and contract summary; `server.R:465-524,586-643,786-1056` | WQ contract/site mapping/plot scripts passed | Upload/mapping/summary exist, but no `joined_enriched` runtime completion and no WQ valid/invalid/warning/recovery browser matrix. |
| 9 | RHS local import | Partially implemented | `validate_rhs_upload()` `server.R:526-570`; `normalise_rhs_records()` `R/site_mapping_helpers.R:177-232` | RHS contract/site mapping/plot scripts passed | Preview/mapping exists; no `joined_enriched` completion or current browser recovery evidence. |
| 10 | Valid/invalid/warning/recovery handling | Partially implemented | Guarded upload helpers, `format_validation_message()`, `run_model()`; error guidance `docs/week08/WK8-09_Complete_Error_List.md` | Invalid local Flow/mapping/model tests passed; old ST-07E/F browser evidence is at `7cf242f`, not current | Coverage is indirect and incomplete; execute RAW-linked recovery cases at RC. |
| 11 | HDE default / NRFA alternative | Partially implemented | `normalise_site_metadata_flow_input()` `R/site_mapping_helpers.R:71-110`; DEC-12/DEC-29 | Default/provenance tests passed | Code supports explicit HDE/NRFA and HDE default, but no automatic HDE-failure-to-NRFA fallback reason/provenance; RTM-12 remains Partial. |
| 12 | `rhs_survey_id` contract | Verified complete | `R/site_mapping_helpers.R:20-35,126-152,177-212`; `R/dashboard_backlog_helpers.R:22-86`; commits around PR #62 | RHS contract and site mapping tests executed/passed | Current browser evidence remains absent but code/contract is directly tested. |
| 13 | `joined_core` vs optional enrichment | Partially implemented | Dependency boundary `R/workflow_state.R:19-23`; core scope UI `R/workflow_ui.R:554+`; WQ/RHS handled separately | State/UI tests passed | `joined_enriched` is declared but never set in `server.R`; optional layers are not actually joined. |
| 14 | Missing WQ/RHS still allows core | Verified complete | Core join depends only on O:E, Flow stats, mapping; `R/workflow_state.R:19-23`; core-only UI | State/UI tests executed/passed | Verified for dependency/runtime code; browser release evidence still needed. |
| 15 | Joined HE dataset download | Partially implemented | DataTable Buttons at `server.R:2219-2239`; checkpoint artifact at 2090-2094 | Server test proves checkpoint becomes current; no download content test | Export lacks a dedicated versioned handler/provenance and currentness evidence. Test actual downloaded file/schema. |
| 16 | Processed dataset schema/version validation | Evidence missing | Only artifact labels/config; no schema/version validator found | Not discovered/executed | Cross-session/research reproducibility cannot be guaranteed. Define and test schema version. |
| 17 | Checksum/integrity validation | Evidence missing | No checksum code or manifest found | Not discovered/executed | Dataset/fixture identity is unproven. Add checksums to RC manifest and import validation. |
| 18 | Cross-session re-upload | Evidence missing | No processed-dataset upload route found | Not executed | Participants cannot reliably resume across sessions from an exported checkpoint. Implement contract before study claims. |
| 19 | Data/source revision/exclusion history restoration | Partially implemented | In-memory output revisions/history strings in `R/workflow_state.R:38-48`; exclusion log is generated, not restorable | State/log tests passed | No persistence or re-upload restoration. Add versioned history payload and recovery test. |
| 20 | Same-site/same-day duplicate detection | Blocked | `filter_records()` only flags exact duplicate rows; comment explicitly defers sample-level rule, `R/filtering_helpers.R:83-89` | Standalone filtering test passed for exact duplicate only | Scientific rule is unfrozen; do not infer same-day/month rule. Obtain decision and fixture. |
| 21 | Retain all | Partially implemented | Exact duplicates are retained by default (`filter_records()`:83-105; `be1dc1c`) | Standalone filter test passed | No explicit Task 4 action/UI and no analysis-level selection on main. Wire and browser-test. |
| 22 | Average duplicates | Evidence missing | No averaging implementation found | Not discovered/executed | Unsafe to claim; scientific aggregation rules absent. Freeze rule before implementing. |
| 23 | Remove selected record | Evidence missing | Main has automatic invalid-row exclusion only; branch helper `exclude_record()` is unmerged and unwired | Branch standalone test not executed because not in audited worktree | Task 4 cannot perform participant-selected removal on main. Review/merge and integrate branch implementation. |
| 24 | Block analysis until duplicate action chosen | Evidence missing | No duplicate-action state/gate found | Not discovered/executed | Ambiguous duplicates can reach analysis. Freeze detection/action policy and gate downstream results. |
| 25 | Task 4 filter | Partially implemented | Main local-upload filter `R/filtering_helpers.R`, not joined-data Task 4; branch `origin/yutong/filtering` has `apply_filter_selection()` | Main helper tests passed; branch test not run | Required analysis filter is absent from main/runtime. |
| 26 | Task 4 restore | Evidence missing | Only unmerged `restore_record()` helper; no main UI/server | Not executed | Participant cannot restore an analysis exclusion. |
| 27 | Exclusion log | Partially implemented | `build_exclusion_log()` and UI/download, `R/exclusion_log_helpers.R`, `server.R:1295-1316` | Standalone tests passed | Log concerns local invertebrate validation, not Task 4 exclusion/restore history. |
| 28 | Re-plot after filter | Evidence missing | No main analysis selection/filter event wired to plots | Not executed | Task 4 success path unavailable. |
| 29 | Preserve original `joined_core`/`joined_enriched` | Partially implemented | Dependency design keeps filter separate (`R/workflow_state.R:12,19-25`); branch tests assert original unchanged | Main state test passed; no runtime filter | Design is correct but no main Task 4 runtime or enriched dataset. |
| 30 | Task 5 predictor change | Partially implemented | UI two selectors; observer stales model via `model_spec`, `server.R:2262-2336` | Server test covers model completion; predictor-change observer not browser-tested | Only one Flow and one ecology field, not frozen predictor categories/limits. |
| 31 | Task 5 re-fit | Partially implemented | `input$run_basic_model` calls `run_model()`, `server.R:2287-2321` | Standalone/server tests passed | Basic exploratory `lm()` only; no current browser or reference parity. |
| 32 | Diagnostics | Partially implemented | Summary has slope, p-value, R² and scatter/trend, `R/dashboard_backlog_helpers.R:179-204` | Model helper tests passed | No residual/influence diagnostics despite artifact wording “diagnostics”. |
| 33 | Model export | Evidence missing | No model download handler found | Not discovered/executed | Task 5 required export is absent. |
| 34 | Model history/current-result marker | Partially implemented | Artifact status/revision and basic result reactive | State/server tests passed | No durable model history, result ID, formula/provenance download, or browser evidence. |
| 35 | Single-site numerical parity | Evidence missing | Synthetic slope check only; planned `tests/reference/reference_single_site_lm.R` and fixture do not exist | Standalone helper passed, but not independent parity | Scientific equivalence is unproven. Add independent reference/tolerance evidence. |
| 36 | Mixed-effects remains `not_ready` | Blocked | Contract says `not_ready`; main runtime has no site-count route and completes Task 5 with basic `lm()` | No mixed-path guard test on main | Runtime does not enforce the contract. Merge/integrate a site-count guard before RC. |
| 37 | Pooled `lm()` masquerade risk | Partially implemented | `build_basic_flow_ecology_model()` always runs `stats::lm(ecology ~ flow)`, lines 160-204; Task completion at `server.R:2302-2312` | Tests use single-site/synthetic data and do not reject multi-site | Material scientific risk: multi-site joined data can complete Task 5 with pooled `lm()`. Treat as release blocker. |
| 38 | Dissolved oxygen `OPEN-02` decision/scope reduction | Blocked | `not_ready_open_02` enforced in `R/wq_contract_helpers.R:269-315`; OPEN-02 remains Blocked in RTM | WQ contract test passed the not-ready guard | Safe interim code exists, but no formal closure/scope-reduction decision. Gate D must record whether excluded. |

### Testing / Recovery and Research Execution

| # | Audit item | Status | Evidence and execution | Missing evidence / impact / next step |
|---:|---|---|---|---|
| 39 | RAW-01–25 user messages | Partially implemented | All IDs documented in `docs/week05/5.3_Error_List.md`; later guidance in `docs/week08/WK8-09_Complete_Error_List.md` | Guidance commit `4d7afd3` changed docs only; IDs are not traced to runtime/test IDs. Build one-to-one RTM. |
| 40 | RAW-01–25 recovery paths | Evidence missing | A few indirect recoveries exist (invalid-to-valid upload; local Flow replacement; model retry) | No complete executed recovery matrix/screenshots/current commit. Execute all 25 or record justified N/A. |
| 41 | Browser E2E | Evidence missing | July 10 Chrome records target `7cf242f`/`08b595a`; follow-up browser screenshots are unmerged | No two full formal paths on current main/clean RC. Run current clean-session E2E with downloads/recovery. |
| 42 | Case Study 2 | Evidence missing | Mentioned only in contracts; no runner/fixture/execution record found | Core scientific reference path is unverified. Add fixed input, expected outputs, command and log. |
| 43 | Fixed five-site fixture | Evidence missing | RTM-13 explicitly says fixed tiered fixtures do not exist; no such fixture found | Normal-use repeatability/performance evidence absent. Create only after approved data/fixture work. |
| 44 | Clean-session reproduction | Partially implemented | This audit ran `--vanilla` suite and startup HTTP smoke | No clean-session full workflow, browser actions, downloads, or environment manifest. |
| 45 | Pilot 1 | Evidence missing | Week 8 file is a blank pack/template | No de-identified completed packet or actual run record. Confirm controlled storage before claiming. |
| 46 | Pilot 2 | Evidence missing | Same as Pilot 1 | Same gap. |
| 47 | Pilot issue triage | Evidence missing | Blank triage table in template; branch task-script record has recommendations only | No two-session consolidated severity/fix/regression trail. |
| 48 | Gate D decision | Evidence missing | No “Gate D” repository match and no GO/NO-GO record | Formal research must not be inferred ready. Team must provide/approve record. |
| 49 | RC freeze | Evidence missing | No tag, RC manifest, or commit message | Results cannot be tied to one immutable build. |
| 50 | Formal-study protocol | Evidence missing | No formal-study protocol v1 found; Week 8 pilot pack is not a formal protocol | Methods/version cannot be audited. |
| 51 | Analysis plan | Evidence missing | `docs/testing/experimental-design.md` is software-test design, not a formal study analysis plan | Analysis decisions could drift after data collection. |
| 52 | Materials manifest | Evidence missing | No versioned manifest found | Conditions/material versions cannot be compared. |
| 53 | Condition allocation | Evidence missing | No allocation record found | Fairness/randomisation cannot be verified. |
| 54 | Formal session evidence | Unclear | No repository record; authorised external storage was not queried | Do not conclude sessions occurred or did not occur. Team confirmation required. |
| 55 | Daily completeness/deviation/version governance | Evidence missing | No daily QA, deviation, pause, session-version, or version-change log found | If sessions begin, completeness and version deviations cannot be governed. Create before formal collection. |

## 4. Benyu Task Status

| Task | Status | Existing Evidence | Missing Evidence | Research Impact | Recommended Next Action |
|---|---|---|---|---|---|
| DEBT-07 | Partially implemented | This audit supplies an exact current command/commit/environment log for testthat, 8 standalone scripts, syntax, and startup; all executable offline entries passed | Case Study 2, fixed five-site fixture, independent single-site parity, browser E2E, full manual critical tests, external import tests, and a retained CI/release log | Automated confidence is good but not equivalent to release evidence | Repeat the complete inventory on the selected clean RC and attach durable logs/artifacts |
| DEBT-15 | Evidence missing | RAW-01–25 definitions; guarded helpers and indirect tests for some uploads/prerequisites; old invalid-upload recovery record | Per-ID trigger, classification, retained state, owner, linked test, current execution, screenshot/log, and recovery result | Unhandled recovery can interrupt or contaminate formal tasks | Execute and sign off the 25-row recovery matrix against the RC |
| WK9-06 | Evidence missing | Scattered automated tests, old July 10 smoke/functional records, plot images, unmerged UI follow-up evidence | One coherent chain tied to exact RC/environment: current browser E2E, Case Study 2, fixed fixture, parity, RAW matrix, regressions, severity list, clean session | Gate D cannot rely on a reproducible release packet | Consolidate DEBT-07/15 results into one immutable QA release evidence packet |

## 5. Reviewer Checks

| Check | Status | Evidence found | Gap / action |
|---|---|---|---|
| DEBT-02 | Evidence missing | Worktree was clean; R 4.6.1/platform captured in this audit | No unique RC/tag, environment/dependency manifest, fixture checksum, materials version, or exact full rebuild instructions |
| DEBT-03 | Evidence missing | Old Chrome paths exist for pre-Week-9 commits; unmerged branch contains UI scenarios/screenshots | No two full formal-task E2E records on one clean RC with timestamps, downloads, recovery, and reviewer |
| DEBT-08 | Partially implemented | Separate local validators/tests for Biology, Flow, WQ, RHS; core/enrichment dependency tests | Biology is preview-only; WQ/RHS are not joined; no four-source browser valid/invalid/warning/recovery matrix |
| WK9-09 | Evidence missing | Pilot pack/template and one unmerged task-script test | No proven Pilot 1/2, de-identified packets, consolidated triage, fixes, regressions, or blocker/major closure |
| WK9-12 | Evidence missing | Ethics approval is claimed in decision log | No daily completeness, deviation, RC/session-version, pause/version policy, anonymous manifest, or completeness review |

## 6. Test Inventory

### Executable automated entries

| Entry | Type | Safety | Execution method/status |
|---|---|---|---|
| `tests/testthat.R` | Automated runner | Offline/read-only | Executed with R 4.6.1; passed |
| `tests/testthat/test-dashboard-backlog-helpers.R` | Automated unit/contract | Safe | Included; passed |
| `tests/testthat/test-flow-mapping-contract.R` | Contract test | Safe | Included; passed |
| `tests/testthat/test-flow-metadata-defaults.R` | Contract test | Safe | Included; passed |
| `tests/testthat/test-local-flow-contract.R` | Contract test | Safe | Included; passed |
| `tests/testthat/test-rhs-contract.R` | Contract test | Safe | Included; passed |
| `tests/testthat/test-server-local-flow-source.R` | Automated integration | Safe; mocks external import | Included; passed |
| `tests/testthat/test-setup.R` | Runner smoke | Safe | Included; passed |
| `tests/testthat/test-site-metadata-helpers.R` | Automated unit/contract | Safe; temp directory cleaned | Included; passed |
| `tests/testthat/test-workflow-config.R` | Contract test | Safe | Included; passed |
| `tests/testthat/test-workflow-server.R` | Automated integration | Safe; mocked business functions | Included; passed |
| `tests/testthat/test-workflow-state.R` | Automated unit | Safe | Included; passed |
| `tests/testthat/test-workflow-ui.R` | Automated UI-markup/contract | Safe; not browser E2E | Included; passed |
| `tests/test_backlog_helpers.R` | Standalone unit/integration | Safe | Executed; passed |
| `tests/test_exclusion_log_helpers.R` | Standalone unit | Safe | Executed; passed |
| `tests/test_filtering_helpers.R` | Standalone unit | Safe | Executed; passed |
| `tests/test_model_interface_helpers.R` | Standalone unit | Safe | Executed; passed |
| `tests/test_server_site_import.R` | Standalone Shiny integration | Safe; no real service | Executed; passed with batch warnings noted below |
| `tests/test_site_mapping.R` | Standalone contract | Safe; writes only inside temporary directory and cleans it | Executed; passed |
| `tests/test_wq_contract_helpers.R` | Standalone scientific/contract | Safe | Executed; passed |
| `tests/test_wq_rhs_plots.R` | Standalone integration | Safe | Executed; passed |

### Manual, research, and operational entries

| Entry | Type | Safety / status |
|---|---|---|
| `tests/manual/generate_plot_smoke_tests.R` | Manual/scientific plot smoke generator | Not executed: calls `ggsave()` to tracked PNG paths and would modify evidence |
| `tests/manual_test_cases.md` | Manual functional cases TC-001–TC-023 | Documentation only; no current execution fields |
| `tests/manual_test_matrix.csv` | Manual functional/checklist TC-001–TC-039 | Documentation only; duplicate expectation TC-028 conflicts with current retain policy |
| `docs/testing/Test_2026-07-10/Smoke_test_execution_2026-07-10.md` | Browser/manual smoke evidence | Existing executed record, but baseline `7cf242f`, not current |
| `docs/testing/Test_2026-07-10/Functional_Test_Execution_Record.md` | Manual/customer functional evidence | Existing record at `7cf242f`/`08b595a`; not current RC evidence |
| `docs/testing/high-level-test-plan.md`, `docs/testing/Test_Plan.md`, `docs/week03/testing-checklist.md` | Research readiness / documentation-only checklist | Not execution evidence |
| `docs/week08/pilot execution.md` | Pilot/manual research pack | Template only |
| `docs/week07/requirement-traceability-matrix-v1.md` | Research readiness/RTM | Exists but status/evidence links are incomplete |
| `01_Update_Dashboard.cmd` | Operational updater | Not executed: network clone/pull and possible installer |
| `02_Setup_R_and_Run_Dashboard.cmd` | Setup/start runner | Not executed: may install R/packages and access GitHub/CRAN; its syntax/startup substeps were reproduced safely |

No `.sh`, `.ps1`, Makefile/task runner, browser automation framework, Case Study 2 runner, fixed five-site runner, or independent reference-parity script was found.

## 7. Test Execution Results

Environment for all successful audit runs: `main` at `9d0c7e9`; Windows 11 x64 build 26200; R 4.6.1 (2026-06-24 ucrt), `x86_64-w64-mingw32`; `--vanilla`; Europe/London. No package installation or external API was used.

| Command | Start–end UTC | Exit | Pass/fail/error/skip/warning | Result and evidence location |
|---|---|---:|---|---|
| `Rscript --version`; `Rscript --vanilla tests/testthat.R` via PATH | 15:36:51–15:36:52 | Not started | N/A | `Rscript` absent from PATH; no tests executed. Audit console output. |
| `C:\Program Files\R\R-4.6.1\bin\Rscript.exe --vanilla tests/testthat.R` | 15:37:09–15:37:29 | 0 | Summary reporter: 0 failure/error/warning/skip | Passed; audit console output |
| Silent count rerun of `tests/testthat/` | 15:38:18–15:38:37 | 0 | 87 cases; 346 passed expectations; 0/0/0/0 | Passed; audit console output |
| Eight `tests/test_*.R` standalone scripts, individually launched | 15:38:47–15:38:56 | all 0 | 8 scripts; 169 discovered `stopifnot()` calls; 0 failed scripts; 2 batch warnings | Passed. Warnings: two `derivePoints()` “restarting interrupted promise evaluation”; audit console output |
| Parse `global.R`, `ui.R`, `server.R` | 15:39:25–15:39:25 | 0 | Syntax pass | Passed; audit console output |
| `shiny::runApp('.', port=38127, host='127.0.0.1', launch.browser=FALSE)` plus local HTTP probe | 15:39:43–15:39:56 | 0-equivalent | HTTP 200; server deliberately stopped | Startup smoke passed; not browser E2E; audit console output |

An intermediate audit-only counting command ran all testthat cases but then exited 1 because `table()` was incorrectly applied to a list result column. It was replaced by the successful numeric aggregation above. This was an audit script error, not a repository test failure.

### Discovered / executed disposition

- **Discovered and executed:** testthat runner and all 12 files beneath `tests/testthat/`; all eight top-level standalone test scripts; syntax parse; startup smoke.
- **Passed:** all repository tests that were executed.
- **Failed repository tests:** none.
- **Skipped by test framework:** none.
- **Not executed:** tracked plot generator (would overwrite evidence); TC-001–TC-039 manual cases (interactive browser and no authorised evidence capture session); July 10 records (historical, not commands); real Biology/HDE/NRFA/WQ/RHS services (external/customer-service restriction); updater/setup `.cmd` files (network/install mutation); Case Study 2, five-site fixture, numerical reference, and browser automation (not found); unmerged-branch tests (not in audited main, and checkout prohibited).
- **Research-path impact:** passing automation supports code-level confidence but cannot close browser/recovery/scientific/reference/formal-readiness gates. Suggested severity: **Major** for missing current E2E/release chain; **Blocker** for pooled multi-site `lm()` and absence of RC/Gate D before any formal study.

No test-created repository files remained after execution; `git status --short` was still empty before report creation.

## 8. RAW-01–25 Recovery Coverage

“Manual evidence” below distinguishes current evidence from old evidence. None of the rows has a complete current RC recovery packet with trigger, expected retained state, execution timestamps, result, screenshot/log, owner, and sign-off.

| RAW ID | Documented | Implemented | Automated Test | Manual Execution Evidence | Recovery Evidence | Status | Gap |
|---|---|---|---|---|---|---|---|
| RAW-01 | Yes, week05:7 | No explicit missing-`ggnewscale` guard | None linked | None | None | Evidence missing | Feature-time missing package can still raise a raw dependency error |
| RAW-02 | Yes, week05:8 | No `tryCatch` around donor mapping `fread()` | None linked | None | None | Evidence missing | Malformed/non-readable donor input recovery unproved |
| RAW-03 | Yes, week05:9 | No safe wrapper around donor text `fread()` | None linked | None | None | Evidence missing | Raw parser error may escape |
| RAW-04 | Yes, week05:10 | Empty input has `validate(need())` | None RAW-linked | None | None | Partially implemented | Friendly block exists; retry/retained-state evidence absent |
| RAW-05 | Yes, week05:11 | Guarded upload helpers | Local Flow/site metadata indirect tests | Old ST-07E/F at `7cf242f` | Invalid WQ then valid WQ, old build | Partially implemented | No current per-source recovery evidence |
| RAW-06 | Yes, week05:12 | Guarded CSV read | Invalid upload indirect tests | Old ST-07E/F | Old invalid-to-valid recovery | Partially implemented | No current Biology/Flow/WQ/RHS matrix |
| RAW-07 | Yes, week05:13 | Validators reject missing columns | Contract tests passed | Old ST-07C plus historical functional records | Limited | Partially implemented | Not RAW-linked/current; all upload types not covered |
| RAW-08 | Yes, week05:14 | Mapping validation | Missing-column test passed | Historical only | None current | Partially implemented | Retry and retained artifacts not evidenced |
| RAW-09 | Yes, week05:15 | Mapping validation | Mapping contract indirect tests | Historical only | None current | Partially implemented | Same |
| RAW-10 | Yes, week05:16 | Superseded: missing source defaults HDE per DEC-12 | Default/provenance tests passed | None current | Deterministic default tested | Closed by documented scope reduction | Need current browser wording/provenance evidence |
| RAW-11 | Yes, week05:17 | “Please import flow data” alert | Workflow/server indirect tests | Historical old flow tests | None current | Partially implemented | Busy-state and successful retry not proved |
| RAW-12 | Yes, week05:18 | Biology prerequisite alert | Server integration indirect | Historical | None current | Partially implemented | Retry/retained state missing |
| RAW-13 | Yes, week05:19 | Environmental prerequisite alert | Server integration indirect | Historical | None current | Partially implemented | Same |
| RAW-14 | Yes, week05:20 | RICT prerequisite alert | Server integration indirect | Historical | None current | Partially implemented | Same |
| RAW-15 | Yes, week05:21 | Flow-stat prerequisite alert | Server integration indirect | Historical | Unmerged follow-up has a recovery scenario | Partially implemented | No main/RC recovery evidence |
| RAW-16 | Yes, week05:22 | Processed-biology join alert, not exact `oe_ratios` guard | Server integration indirect | Historical | None current | Partially implemented | Definition/runtime mapping is not one-to-one |
| RAW-17 | Yes, week05:23 | HEV prerequisite alert | Server integration indirect | Historical ST-06 blocked | None current | Partially implemented | Regenerate-and-download recovery missing |
| RAW-18 | Yes, week05:24 | WQ/RHS/model helpers guarded; legacy plots incomplete | Plot/model scripts passed | Plot images exist but are not recovery logs | Limited helper evidence | Partially implemented | No all-plot exception/browser recovery |
| RAW-19 | Yes, week05:25 | No download write-error catch found | None | None | None | Evidence missing | Permission/write recovery and retained state absent |
| RAW-20 | Yes, week05:26 | No explicit missing generated-flow-file handler found | None | None | None | Evidence missing | Runtime temporary-file failure untested |
| RAW-21 | Yes, week05:27 | No general permission-error handler | None | None | None | Evidence missing | Download/temp permission recovery absent |
| RAW-22 | Yes, week05:28 | WQ/RHS imports are caught; core external imports are not uniformly caught | Server tests mock external import only | Historical service runs, not failure recovery | None current | Partially implemented | Offline/timeout/double-failure matrix absent |
| RAW-23 | Yes, week05:29 | Model/uploads have catches; no application-wide boundary | Indirect tests | Historical BUG-001/003 show failures | Failure evidence, not recovery | Partially implemented | Raw reactive errors may still escape |
| RAW-24 | Yes, week05:30 | No systematic sanitisation; some `conditionMessage(e)` reaches user text | None | None | None | Evidence missing | Local paths/internal detail may be exposed |
| RAW-25 | Yes, week05:31 | No main timeout/busy recovery found | None on main | Historical BUG-003 shows persistent loading failure; follow-up branch claims recovery | No main recovery | Evidence missing | Permanent loading remains unclosed on audited main |

No RAW row has a recorded owner/current status in the RAW definition file. The Week 8 guidance document uses different IDs and does not provide execution or recovery evidence.

## 9. Research Readiness Evidence

| Required evidence | Classification | Repository evidence / finding |
|---|---|---|
| Gate D decision and GO/conditional GO/NO-GO | Not found | No matching record |
| Unique RC commit/tag | Not found | No tags; no RC commit/manifest |
| RC candidate manifest | Not found | — |
| Environment/session info | Exists but incomplete | This audit captures R/platform; no project environment manifest |
| Dependency manifest | Not found | `manifest.json` is not evidenced as the frozen R dependency/RC manifest; no `renv.lock`/session package manifest |
| Dataset checksum manifest | Not found | — |
| Formal-study protocol v1 | Not found | Pilot pack is not formal protocol |
| Analysis plan v1 | Not found | Software-test experimental design is not formal analysis plan |
| Materials manifest v1 | Not found | — |
| Condition allocation | Not found | — |
| Ethics/material cross-check | Claimed but evidence missing | `docs/client-decision-log-v1.md:130` says ethics approved but requires controlled authoritative record, which is absent |
| Pilot 1 packet | Template only | `docs/week08/pilot execution.md` blank pack |
| Pilot 2 packet | Template only | Same |
| Pilot issue triage | Template only | Blank table in pack |
| Blocker/major regression evidence | Exists but incomplete | Old July 10 defect/retest records; no current RC closure |
| Formal anonymous session manifests | Not found | — |
| Daily QA/completeness report | Not found | — |
| Protocol deviation log | Not found | — |
| Pause/version-change log | Not found | — |
| Week 9 evidence note | Claimed but evidence missing on main | UI Week 9 record exists only on unmerged follow-up branch |
| RTM | Exists but incomplete | `docs/week07/requirement-traceability-matrix-v1.md`; many planned/partial/blocked items and stale links |
| Marking evidence matrix | Not found | — |
| Contribution record | Not found | — |

### Readiness determinations

1. **Gate D supported?** No evidence found.
2. **Unique RC?** No.
3. **Formal study started?** Unclear; no repository evidence.
4. **All formal work on one RC/material version?** Unclear and presently unverifiable.
5. **Two real pilots complete?** No evidence found.
6. **Formal blocker=0 record?** Not found.
7. **Mixed model and OPEN-02 excluded from success criteria?** Interim `not_ready` rules exist, but no Gate D/scope-reduction record formally excludes them.
8. **Participant-data governance risk?** Conditional Blocker: if sessions have started, the absence of session manifests, version/deviation logs, and the authoritative controlled ethics/material record prevents auditability. No participant data were inspected.

## 10. Current Risks

### Blocker

| ID | Evidence | Impact | Owner if known | Recommended action |
|---|---|---|---|---|
| B-01 | No RC tag/manifest and no Gate D decision | Formal results cannot be tied to an approved immutable build | Research lead / release owner | Freeze one commit only after branch decisions and attach Gate D record |
| B-02 | `build_basic_flow_ecology_model()` uses pooled `lm()` with no site-count guard; Task 5 marks complete | Multi-site scientific result can violate DEC-08/OPEN-06 | Modelling owner | Enforce one-site route and multi-site `not_ready`; add negative regression |
| B-03 | Main lacks joined-data filter/restore and validated Task 5 export/history | Formal Task B may be impossible or require facilitator workaround | Task 4/5 owners | Integrate and browser-test required runtime before RC |
| B-04 | No authoritative session/version/deviation governance record | If formal sessions started, ethics/version auditability is insufficient | Research governance owner | Pause counting data until controlled records are confirmed |

### Major

| ID | Evidence | Impact | Owner if known | Recommended action |
|---|---|---|---|---|
| M-01 | No current two-path browser E2E | Automation may miss task-blocking UI/recovery/download failures | Benyu / QA | Run clean-session E2E on selected RC |
| M-02 | RAW matrix lacks current execution for most IDs | Errors may require restart, leak detail, or leave stale outputs usable | Benyu / QA plus feature owners | Execute per-ID recovery matrix |
| M-03 | Critical fixes/evidence split across three unmerged refs | Current main and evidence claims diverge | Release owner | Review branch-only commits and explicitly accept/reject before freeze |
| M-04 | No Case Study 2, fixed five-site, checksum, or independent parity evidence | Scientific reproducibility and fixture identity are unproven | QA / modelling / data owners | Build immutable reference packet and compare numerically |
| M-05 | `joined_enriched` declared but never produced | WQ/RHS acceptance can be mistaken for complete enrichment | Data pipeline owner | Implement or formally reduce scope |

### Minor

| ID | Evidence | Impact | Owner if known | Recommended action |
|---|---|---|---|---|
| m-01 | `tests/manual_test_matrix.csv` TC-028 says duplicate removed, while code/tests retain it | Manual tester may record a false failure/pass | QA documentation | Align manual expectation with DEC-23 |
| m-02 | Artifact wording says “diagnostics/data history” beyond actual outputs | Users/reviewers may overestimate delivered evidence | UI/model owner | Use precise wording until outputs exist |

### Enhancement

| ID | Evidence | Impact | Owner if known | Recommended action |
|---|---|---|---|---|
| E-01 | DEC-34 lists site map/GAM/reports/UI additions outside core | No effect on current core readiness if kept out of acceptance | Backlog owner | Keep separate from blocker closure |

## 11. Benyu’s Next Three Actions

### 1. Establish the auditable release baseline

- **Why now:** every later result is ambiguous without Gate D and one RC; three relevant branches are not in main.
- **Inputs:** this audit; `main`; the three relevant remote refs; decision log; RTM; ethics record reference from the team.
- **Steps:** convene a short release review; decide accept/reject for each branch-only commit; confirm Task 4/5 and OPEN-02/mixed-model scope; record Gate D outcome; identify one commit; require clean worktree, environment/dependency/material/checksum manifests.
- **Output:** signed Gate D record and one RC SHA/tag/manifest (created by authorised release owner, not by this audit).
- **Done when:** one immutable build and materials version are uniquely named and all scope reductions are explicit.
- **Wait for team confirmation:** **Yes**—Gate D, branch inclusion, ethics location, and RC authority cannot be inferred.

### 2. Execute DEBT-07 / WK9-06 as one clean release run

- **Why now:** current automation passes, but browser, Case Study 2, fixed fixture, parity, and downloads remain unevidenced.
- **Inputs:** selected RC; clean machine/session; fixed five-site and Case Study 2 fixtures; expected numerical reference; formal task scripts.
- **Steps:** capture environment/session info and checksums; run testthat and all standalone tests; start app cleanly; execute both full browser paths through upload→validation→checkpoint→join→HEV/model→filter/restore→stale→regenerate→download; compare single-site output to independent reference; retain logs/screenshots/download hashes; classify defects.
- **Output:** one timestamped QA release packet tied to the RC.
- **Done when:** command/output counts, browser actual-vs-expected, artifacts, regressions, reviewer, and zero unresolved blockers are recorded.
- **Wait for team confirmation:** **Yes** for RC/fixtures/reference; execution itself does not require further design changes.

### 3. Close DEBT-15 and pilot/governance evidence before formal collection

- **Why now:** recovery and governance gaps can contaminate primary measures or make sessions unauditable.
- **Inputs:** RAW definitions, Week 8 guidance, RC build, formal protocol/materials, controlled pilot/session storage.
- **Steps:** map RAW-01–25 to runtime/test IDs; execute trigger and recovery while checking retained current artifacts; capture safe screenshots/logs; record owner/status; run/verify Pilot 1 and Pilot 2 packets; consolidate issue triage/regressions; initialise daily completeness, deviation, pause, and version logs.
- **Output:** signed 25-row recovery matrix plus de-identified pilot/governance packet.
- **Done when:** every RAW row is Passed, justified N/A, or linked to a blocking issue; two pilot packets and governance reviews are complete on the same RC/material version.
- **Wait for team confirmation:** **Yes**—confirm whether existing pilots/sessions are in authorised non-Git storage and who may review them.

## 12. Questions Requiring Team Confirmation

1. Was Gate D formally held, and where is the authoritative decision record?
2. Which exact commit, if any, is the intended RC, and are the three unmerged Week 9 refs intended to enter it?
3. Are Pilot 1 and Pilot 2 packets stored in authorised non-Git storage, and do they contain complete de-identified evidence?
4. Have formal sessions started; if so, which RC/material versions were used and where are anonymous manifests/deviation logs?
5. Where is the authoritative ethics approval/material cross-check required by the decision log?
6. Are Task 4 filter/restore, mixed-model `not_ready`, and OPEN-02 explicitly included in or reduced from formal success criteria?

## 13. Evidence Index

### Files and functions

- Workflow: `R/workflow_config.R`, `R/workflow_state.R`, `R/workflow_ui.R`, `server.R`, `ui.R`.
- Data/contracts: `R/dashboard_backlog_helpers.R`, `R/site_mapping_helpers.R`, `R/wq_contract_helpers.R`, `R/filtering_helpers.R`, `R/exclusion_log_helpers.R`, `R/model_interface_helpers.R`.
- Key functions: `workflow_resume_stage()`, `set_he_artifact_status()`, `invalidate_he_artifacts_from()`, `artifact_is_current()`, `validate_local_flow()`, `normalise_site_metadata_flow_input()`, `normalise_rhs_records()`, `build_wq_contract_summary()`, `filter_records()`, `build_exclusion_log()`, `run_model()`, `build_basic_flow_ecology_model()`.

### Tests and records

- `tests/testthat.R`; all files under `tests/testthat/`.
- `tests/test_backlog_helpers.R`, `tests/test_exclusion_log_helpers.R`, `tests/test_filtering_helpers.R`, `tests/test_model_interface_helpers.R`, `tests/test_server_site_import.R`, `tests/test_site_mapping.R`, `tests/test_wq_contract_helpers.R`, `tests/test_wq_rhs_plots.R`.
- `tests/manual/generate_plot_smoke_tests.R`, `tests/manual_test_cases.md`, `tests/manual_test_matrix.csv`.
- `docs/testing/Test_2026-07-10/Smoke_test_execution_2026-07-10.md`, `Functional_Test_Execution_Record.md`, `observation_log.md`.
- `docs/week05/5.3_Error_List.md`, `docs/week08/WK8-09_Complete_Error_List.md`, `docs/week08/pilot execution.md`.
- `docs/client-decision-log-v1.md`, Week 7 data/dependency/modelling/RTM contracts, Week 8 UI mapping.

### Commits, branches, tags

- Main evidence commits: `af984c6`, `be1dc1c`, `c04a1c6`, `6b34efc`, `8622437`, `4d7afd3`, `7b200c1`, `3d716ea`, merge `9d0c7e9`.
- Branch-only commits: `6782f4b`, `c663ec8`, `af7567e`, `758d73e`, `2198e0f`.
- Compared refs: `origin/lin/fix/v22-ui-parity`, `origin/lin/fix/v22-ui-parity-followup`, `origin/yutong/filtering`, `origin/zhaohang/week09-pilot-test-results`.
- Tags: none.

### Commands and audit logs

- Git: all baseline commands requested in the audit; `git branch -r --merged/--no-merged`, `git rev-list --left-right --count`, branch logs/diffs, RC/pilot commit searches.
- Discovery: `rg --files`; targeted `rg -n` searches for workflow, stale, downloads, RAW, readiness, pilots, governance, fixtures, and test entries.
- Execution: R 4.6.1 testthat runner/count rerun; eight standalone scripts; parse check; bounded localhost Shiny startup/HTTP smoke; `sessionInfo()`.
- Current-run logs exist in the audit console and are summarised in Section 7; no extra report/log file was created.
