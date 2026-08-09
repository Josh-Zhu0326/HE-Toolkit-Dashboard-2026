# RAW-01–25 Final Browser / Manual Verification Report

**Project:** HE Toolkit Shiny Dashboard
**Branch:** `qa/raw-user-facing-recovery`
**Browser/manual test date:** 2026-08-09
**Browser/manual baseline:** `b0f1bd5` (`docs: align RAW matrix with final recovery status`)
**Automated verification baseline:** `19daf7a` (`refactor: consolidate RAW message and test helpers`)
**Relationship between baselines:** `b0f1bd5` is a documentation-only descendant of `19daf7a`; no production or test behaviour changed between the automated gate and the browser/manual smoke session.
**Prepared by:** Benyu Zhu
**Scope:** RAW-01–RAW-25 recovery verification only. DATA-01 and DATA-02 are tracked separately and are not resolved by this report.

---

## 1. Purpose

This report records the final browser/manual verification performed after the RAW user-facing recovery implementation and automated regression gate.

The verification focused on the following behaviours:

- invalid or incomplete user input is blocked with clear user-facing guidance;
- recoverable failures do not expose raw R, parser, plotting, network, or filesystem implementation details;
- valid upstream state is retained where required;
- the user can correct the input and retry in the same Shiny session;
- failed operations terminate cleanly rather than remaining in permanent loading states;
- prerequisites and stale/current-state rules are enforced before downstream processing;
- HEV plotting and download workflows recover correctly;
- browser evidence complements, rather than duplicates, deterministic automated recovery coverage.

This report does **not** make the formal Gate D / RC release decision.

---

## 2. Test Environment

- Application: HE Toolkit Shiny Dashboard
- Execution mode: local Shiny session
- Browser: Google Chrome
- Local application URL: `127.0.0.1`
- Operating system: Windows
- Test data set:
  - `biol_site_id = 291`
  - `flow_site_id = 27090`
  - normal Flow source = `NRFA`
  - `wq_site_id = SW-A4070115`
  - `rhs_survey_id = 6145`
- HEV verification:
  - site = `291`
  - biomonitoring index = `WHPT_ASPT_OE`
  - flow metric = `Q5`
  - join lag = `0`
  - join method = `A`

The standard pilot mapping used during the browser session was:

```csv
biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id
291,27090,NRFA,SW-A4070115,6145
```

---

## 3. Automated Regression Gate

The final automated gate was executed before browser/manual smoke verification.

### 3.1 testthat

- Cases: **154**
- Expectations: **1,056**
- Passed: **1,056**
- Failures: **0**
- Errors: **0**
- Warnings: **0**
- Skips: **0**
- Exit code: **0**

### 3.2 Standalone regression scripts

- Total scripts: **18**
- Pass: **16**
- Pass with Warning: **2**
- Fail: **0**
- All scripts exited with code `0`.

Existing warning-only scripts:

1. `test_mixed_model_helpers.R`
   - historical singular-fit / random-effect variance warnings;
   - no new warning category introduced.
2. `test_server_site_import.R`
   - historical Leaflet `derivePoints(..., "addCircleMarkers")` interrupted-promise warnings;
   - no new warning category introduced.

---

## 4. Status Definitions

- **Pass** — expected behaviour observed and recovery requirement satisfied.
- **Pass with Warning** — expected recovery behaviour succeeded, but a non-blocking warning was also observed.
- **Pass (Automated + Browser Normal Path)** — failure recovery is deterministically covered by automation while the browser confirms the non-failure user path.
- **Pass (Automated)** — deterministic automated recovery evidence exists; destructive or artificial browser fault injection was intentionally not performed.
- **Not Executed / Outstanding** — the authoritative browser scenario was not performed and remains outstanding.
- **Superseded / N/A** — the historical failure mechanism no longer exists in the current implementation.
- **Deferred / Known Limitation** — intentionally outside the current recovery patch scope.

---

## 5. Final RAW Verification Summary

| RAW | Final Status | Browser / Manual Result | Evidence |
|---|---|---|---|
| RAW-01 | **Not Executed / Outstanding** | The authoritative missing-`ggnewscale` dependency failure was not injected during this browser session. | No browser screenshot required; scenario remains outstanding. |
| RAW-02 | Pass | Path-like / malformed donor mapping input was converted to safe validation rather than raw file/path errors. | `RAW02_01_path_like_donor_mapping_safe_failure.png`, `RAW02_02_invalid_donor_mapping_schema_blocked.png` |
| RAW-03 | Pass | Invalid Flow-source / mapping values were blocked safely before processing. | `RAW03_01_invalid_flow_input_blocked.png`, `RAW03_02_blank_flow_site_id_blocked.png` |
| RAW-04 | Pass | Empty and whitespace-only donor mapping were blocked with the intended donor-mapping guidance; existing Flow Statistics were retained. | `RAW04_01_blank_donor_mapping_blocked.png`, `RAW04_02_whitespace_donor_mapping_blocked.png` |
| RAW-05 | Pass | Invalid replacement metadata did not remain current; valid replacement restored the mapping in the same session. | `RAW05_01_invalid_replacement_not_current.png`, `RAW05_02_valid_retry_restores_mapping.png` |
| RAW-06 | Pass | Structurally malformed CSV produced controlled validation; valid retry succeeded. | `RAW06_01_malformed_csv_controlled_failure.png`, `RAW06_02_valid_retry_after_malformed_csv.png` |
| RAW-07 | Pass | Missing required `biol_site_id` blocked correctly; optional WQ/RHS absence did not block the core Biology/Flow workflow. | `RAW07_01_missing_required_biol_site_id_blocked.png`, `RAW07_02_optional_wq_rhs_absent_non_blocking.png` |
| RAW-08 | Pass | Invalid mapping upload and equivalent invalid pasted mapping were both rejected consistently. | `RAW08_01_invalid_upload_validation.png`, `RAW08_02_invalid_paste_validation.png` |
| RAW-09 | Pass | Missing or blank `flow_site_id` was blocked with explicit user-facing validation. | `RAW09_01_missing_flow_site_id_blocked.png`, `RAW09_02_blank_flow_site_id_blocked.png` |
| RAW-10 | Pass | Missing or blank `flow_input` defaulted to HDE with an explicit non-blocking informational message. | `RAW10_01_missing_flow_input_defaults_HDE.png`, `RAW10_02_blank_flow_input_defaults_HDE.png` |
| RAW-11 | Pass | Flow processing without imported Flow data was blocked instead of producing downstream failure. | `RAW11_01_flow_processing_blocked_without_flow.png` |
| RAW-12 | Pass | O:E calculation without Biology data was blocked with a Biology prerequisite message. | `RAW12_01_oe_blocked_without_biology.png` |
| RAW-13 | Pass | RICT prediction without current Environmental data was blocked with an Environmental prerequisite message. | `RAW13_01_rict_blocked_without_environment.png` |
| RAW-14 | Pass | O:E calculation without current RICT predictions was blocked with the correct RICT prerequisite message. | `RAW14_01_oe_blocked_without_rict.png` |
| RAW-15 | **Pass with Warning** | Join was blocked without current Flow Statistics; after calculating Flow Statistics, same-session retry generated Joined HE successfully. | `RAW15_01_join_blocked_without_flow_statistics.png`, `RAW15_02_join_retry_after_flow_statistics.png` |
| RAW-16 | **Pass with Warning** | Join was blocked without current O:E; after calculating O:E, same-session retry generated Joined HE successfully. | `RAW16_01_join_blocked_without_oe.png`, `RAW16_02_join_retry_after_oe.png` |
| RAW-17 | Pass | HEV generation was blocked without current Joined HE; after rebuilding the join, explicit same-session retry generated a current HEV plot. | `RAW17_01_hev_blocked_without_joined_he.png`, `RAW17_02_hev_retry_after_joined_he.png` |
| RAW-18 | Pass | Invalid/unusable plot range produced a controlled failed plot request; upstream state remained current and retry after correcting the range succeeded. | `RAW18_01_hev_plot_failure_controlled.png`, `RAW18_02_hev_plot_retry_success.png` |
| RAW-19 | Pass (Automated + Browser Normal Path) | Browser download path verified for PDF/JPEG/PNG; PDF opened successfully. Writer-failure recovery remains covered by automated tests. | `RAW19_01_hev_pdf_download_and_open.png`, `RAW19_02_hev_all_formats_downloaded.png` |
| RAW-20 | **Superseded / N/A** | Historical runtime-generated Flow CSV reopen mechanism is not used by the current architecture. | No browser screenshot required. |
| RAW-21 | Pass (Automated) | Filesystem/permission-style recovery covered by deterministic automation. Destructive Windows permission fault injection was intentionally not performed. | Automated evidence only. |
| RAW-22 | Pass | Valid HDE donor request failed externally with safe UI messaging while existing Flow Statistics were retained; correcting source to NRFA succeeded in the same session. | `RAW22_01_additional_donor_external_failure_safe.png`, `RAW22_02_additional_donor_retry_success.png` |
| RAW-23 | Pass | Workbook checkpoint basic browser smoke remained stable before upload and after a valid workbook. NULL/empty/NA/blank/invalid sheet inputs are covered by automation. | Browser smoke completed; screenshot not retained. |
| RAW-24 | Pass | Multiple browser failures displayed safe user-facing messages without exposing paths, `fread`, `conditionMessage`, `ggplot`, traceback, or other internal implementation details. | Reuses RAW-02, RAW-06, RAW-18 and RAW-22 evidence. |
| RAW-25 | **Deferred / Known Limitation** | Global timeout/cancellation/busy-state lifecycle framework was intentionally not implemented in this recovery patch. | No browser test required for closure. |

---

## 6. Detailed Browser / Manual Results

### General Browser Smoke

**Status:** Pass

Coverage:

- the dashboard launched successfully;
- all five task routes opened;
- Stage 1 through Stage 5 navigation was checked;
- returning to Stage 1 / task selection remained functional;
- no blank page or permanent loading was observed.

**Evidence**

- `SMOKE_01_task_and_stage_navigation.png`

This general navigation smoke is not evidence for RAW-01.

### RAW-01 — Missing `ggnewscale` Dependency / Recovery

**Status:** Not Executed / Outstanding

The authoritative RAW-01 scenario requires verification of recovery when the `ggnewscale` dependency is unavailable. Missing-`ggnewscale` dependency injection was not performed during this final browser session. RAW-01 is therefore neither claimed fixed nor browser-verified and remains an outstanding browser scenario consistent with the recovery matrix.

**Evidence:** No dedicated screenshot required; the scenario was not executed.

### RAW-02 — Safe Donor Mapping / Path-Like Input Handling

**Status:** Pass

Path-like donor input and malformed donor-mapping structure were rejected with controlled user-facing validation. No raw local path failure, parser traceback, or unhandled R condition was surfaced to the user.

Existing Flow Statistics remained visible during the failed donor-input attempts.

**Evidence**

- `RAW02_01_path_like_donor_mapping_safe_failure.png`
- `RAW02_02_invalid_donor_mapping_schema_blocked.png`

### RAW-03 — Invalid Flow Mapping / Source Input

**Status:** Pass

Invalid Flow input values and invalid/blank required Flow mapping values were blocked before external processing. The UI instructed the user to correct the mapping rather than exposing implementation details.

**Evidence**

- `RAW03_01_invalid_flow_input_blocked.png`
- `RAW03_02_blank_flow_site_id_blocked.png`

### RAW-04 — Blank / Whitespace Donor Mapping

**Status:** Pass

With Flow data and Flow Statistics already available, imputation was attempted without usable donor mapping.

Observed behaviour:

- empty donor mapping was blocked;
- whitespace-only donor mapping was also treated as empty;
- the UI displayed the intended donor-mapping guidance;
- existing Flow Statistics remained available;
- the application did not remain in a loading state.

**Evidence**

- `RAW04_01_blank_donor_mapping_blocked.png`
- `RAW04_02_whitespace_donor_mapping_blocked.png`

### RAW-05 — Invalid Replacement Must Not Remain Current

**Status:** Pass

A valid mapping was first established. It was then replaced by invalid/header-only metadata.

Observed behaviour:

- invalid replacement was rejected;
- the invalid replacement was not treated as current validated metadata;
- a valid mapping could be supplied again in the same session;
- the valid retry restored the current mapping state.

**Evidence**

- `RAW05_01_invalid_replacement_not_current.png`
- `RAW05_02_valid_retry_restores_mapping.png`

### RAW-06 — Structurally Malformed CSV Recovery

**Status:** Pass

A structurally malformed metadata CSV was uploaded.

Observed controlled message:

> Site metadata could not be read or validated. Please correct the CSV structure and try again.

The dashboard remained responsive. A valid metadata CSV could then be uploaded successfully in the same session.

**Evidence**

- `RAW06_01_malformed_csv_controlled_failure.png`
- `RAW06_02_valid_retry_after_malformed_csv.png`

### RAW-07 — Required vs Optional Mapping

**Status:** Pass

Two behaviours were checked:

1. Missing required `biol_site_id`: blocked with explicit required-column guidance.
2. WQ/RHS optional columns absent: core Biology and Flow mapping remained valid, the UI explicitly stated that optional WQ/RHS mapping was not supplied, and the core workflow could continue.

**Evidence**

- `RAW07_01_missing_required_biol_site_id_blocked.png`
- `RAW07_02_optional_wq_rhs_absent_non_blocking.png`

### RAW-08 — Upload / Paste Validation Equivalence

**Status:** Pass

Equivalent invalid mapping content was supplied through the supported mapping paths.

Observed behaviour:

- invalid upload was rejected;
- invalid pasted mapping was also rejected;
- the same required-value rule was applied;
- invalid content was not treated as current mapping.

**Evidence**

- `RAW08_01_invalid_upload_validation.png`
- `RAW08_02_invalid_paste_validation.png`

### RAW-09 — Required `flow_site_id`

**Status:** Pass

Both required-column failure modes were checked:

- `flow_site_id` column missing;
- `flow_site_id` present but blank.

Both were blocked with specific mapping guidance and did not continue to Flow import.

**Evidence**

- `RAW09_01_missing_flow_site_id_blocked.png`
- `RAW09_02_blank_flow_site_id_blocked.png`

### RAW-10 — Default HDE Source

**Status:** Pass

Metadata was supplied with `flow_input` missing and with `flow_input` blank.

In both cases:

- mapping validation succeeded;
- `flow_input` was resolved to `HDE`;
- the UI displayed a non-blocking informational message explaining that HDE had been selected as the default source.

**Evidence**

- `RAW10_01_missing_flow_input_defaults_HDE.png`
- `RAW10_02_blank_flow_input_defaults_HDE.png`

### RAW-11 — Flow Processing Without Flow Data

**Status:** Pass

Flow-processing actions were attempted without imported Flow data.

Observed behaviour:

- the action was blocked;
- the user was instructed to import Flow data;
- no downstream Flow-processing crash occurred.

**Evidence**

- `RAW11_01_flow_processing_blocked_without_flow.png`

### RAW-12 — Biology Prerequisite Before O:E

**Status:** Pass

O:E calculation was attempted before Biology data had been imported.

Observed message:

> Biology data are required before calculating O:E ratios. Import or restore Biology data, then calculate O:E ratios again.

The action was blocked and no O:E result was created.

**Evidence**

- `RAW12_01_oe_blocked_without_biology.png`

### RAW-13 — Environmental Prerequisite Before RICT

**Status:** Pass

After Biology data were available, RICT prediction was attempted without current Environmental data.

Observed message:

> Current Environmental data are required before running RICT predictions. Import or regenerate Environmental data, then run RICT predictions again.

The action was blocked cleanly.

**Evidence**

- `RAW13_01_rict_blocked_without_environment.png`

### RAW-14 — RICT Prerequisite Before O:E

**Status:** Pass

After Biology and Environmental data were available, O:E calculation was attempted before current RICT predictions existed.

Observed message:

> Current RICT predictions are required before calculating O:E ratios. Run RICT predictions before calculating O:E ratios.

The action was blocked cleanly.

**Evidence**

- `RAW14_01_oe_blocked_without_rict.png`

### RAW-15 — Flow Statistics Prerequisite Before Join

**Status:** Pass with Warning

The Stage 3 join was attempted with Biology, Environmental, RICT, O:E and Flow available, but Flow Statistics intentionally not current. Lag `0` and method `A` were selected.

Initial result:

- Stage 3 became `Blocked`;
- Joined HE was not generated;
- the user was instructed to calculate/regenerate Flow Statistics.

Recovery:

- Flow Statistics were calculated in the same Shiny session;
- the join was explicitly retried;
- Joined HE was generated and Stage 3 completed.

Non-blocking warning observed after successful join:

> One or more biology samples precede the start date of the earliest flow period at site(s) 291.

This is a data-coverage warning and did not prevent Joined HE generation.

**Evidence**

- `RAW15_01_join_blocked_without_flow_statistics.png`
- `RAW15_02_join_retry_after_flow_statistics.png`

### RAW-16 — O:E Prerequisite Before Join

**Status:** Pass with Warning

The Stage 3 join was attempted while current O:E ratios were intentionally absent.

Initial result:

- Stage 3 became `Blocked`;
- Joined HE was not generated;
- the UI explicitly required current O:E ratios.

Recovery:

- O:E ratios were calculated in the same Shiny session;
- the join was explicitly retried with lag `0` and method `A`;
- Joined HE was generated successfully.

The same non-blocking Flow-period coverage warning was observed after the successful join.

**Evidence**

- `RAW16_01_join_blocked_without_oe.png`
- `RAW16_02_join_retry_after_oe.png`

### RAW-17 — Joined HE Prerequisite / HEV Currentness

**Status:** Pass

Stage 2 prerequisites were prepared, but Stage 3 pairing was intentionally skipped.

Initial HEV request:

- O:E ratios ready;
- Flow Statistics ready;
- Joined HE not current / not available;
- Stage 4 became `Blocked`;
- no HEV plot was generated;
- download was unavailable.

Observed message:

> The Joined HE Dataset is missing or out of date. Rebuild or regenerate the Joined HE Dataset, then create the HEV plot again.

Recovery:

- Stage 3 Joined HE was generated;
- Stage 4 was revisited;
- HEV generation was explicitly retried;
- site `291`, `WHPT_ASPT_OE`, `Q5` produced a current HEV plot;
- readiness checks were green and Stage 4 completed.

**Evidence**

- `RAW17_01_hev_blocked_without_joined_he.png`
- `RAW17_02_hev_retry_after_joined_he.png`

### RAW-18 — Plot Failure and Same-Session Recovery

**Status:** Pass

A valid HEV plot first existed. The plot date range was then changed to an unusable range and the plot was regenerated.

Failure result:

- Stage 4 entered `Failed`;
- the request terminated rather than remaining in permanent loading;
- the UI displayed a safe recovery message;
- the previous valid HEV output was retained as history but explicitly not current;
- O:E, Flow Statistics, Joined HE and the current analysis dataset remained available.

Observed safe message:

> The plot could not be created because the required data is missing or invalid. Check the plot inputs and current results, then try again.

Recovery:

- the valid date range was restored;
- `Create HEV plot` was explicitly retried in the same session;
- the HEV plot regenerated successfully;
- Stage 4 returned to `Complete`;
- current HEV output and download became available again.

**Evidence**

- `RAW18_01_hev_plot_failure_controlled.png`
- `RAW18_02_hev_plot_retry_success.png`

### RAW-19 — Download / Writer Recovery

**Status:** Pass (Automated + Browser Normal Path)

Browser normal-path verification:

- PDF download succeeded;
- downloaded PDF opened successfully and contained the expected HEV plot;
- JPEG download succeeded;
- PNG download succeeded;
- HEV state remained current after download.

Destructive/manual writer-failure injection was not performed. Writer and download failure recovery remain covered by automated tests.

**Evidence**

- `RAW19_01_hev_pdf_download_and_open.png`
- `RAW19_02_hev_all_formats_downloaded.png`

**Browser writer-failure injection:** Not Executed.

### RAW-20 — Historical Runtime Flow CSV Reopen Failure

**Status:** Superseded / N/A

The historical RAW-20 failure concerned a runtime-generated Flow CSV being missing or deleted before a later reopen/read step.

The current dashboard does not use that runtime-generated Flow CSV reopen architecture:

- Flow import returns in-memory data;
- HDE/NRFA Flow data are retained through Shiny state;
- no equivalent current `27034.csv`-style reopen dependency was found.

The closest current temporary-file behaviour is handled by other file/filesystem recovery work.

**Additional production change required:** No.
**Browser evidence required:** No.

### RAW-21 — Permission / Filesystem Recovery

**Status:** Pass (Automated)

Deterministic automated tests cover permission-style and filesystem failure recovery, including safe user-facing handling and state retention.

A destructive browser/manual permission failure was intentionally not injected because doing so would require altering Windows directory permissions or the runtime filesystem environment and would provide little additional evidence over the automated boundary tests.

**Manual destructive fault injection:** Not Executed.

### RAW-22 — External Import Failure and Retry

**Status:** Pass

A structurally valid donor request was used:

```csv
flow_site_id,flow_input
27090,HDE
```

The request passed input/schema validation but external Flow retrieval/processing failed.

Observed failure behaviour:

- controlled source-specific message;
- no raw HTTP/curl/parser/R traceback exposed;
- existing Flow data remained loaded;
- existing Flow Statistics remained calculated;
- no permanent loading.

Observed message:

> Additional donor Flow data could not be retrieved or processed. Check the donor site list, source and date range, then try again.

Recovery:

The donor source was corrected in the same Shiny session:

```csv
flow_site_id,flow_input
27090,NRFA
```

The external request was retried and the UI confirmed:

> Additional flow data successfully imported

**Evidence**

- `RAW22_01_additional_donor_external_failure_safe.png`
- `RAW22_02_additional_donor_retry_success.png`

### RAW-23 — Workbook Preview / Observer Recovery

**Status:** Pass

Browser smoke was performed on the `Utilities → CSV validation → DC-11 workbook checkpoint` path.

Observed behaviour:

- the checkpoint page remained stable before a workbook was uploaded;
- no raw reactive/observer error or permanent loading occurred in the initial state;
- after a valid workbook was supplied, the preview-sheet selector and workbook preview became available;
- the checkpoint remained validation-only and did not replace the active import/join/model/HEV workflow state.

Automated tests cover the internal preview-sheet edge states:

- `NULL`;
- empty;
- `NA`;
- blank;
- invalid/non-existent sheet input.

The production UI does not expose a normal user path for selecting a non-existent sheet, so browser-only invalid-sheet injection was not performed.

**Screenshot evidence:** Not retained.

### RAW-24 — User-Facing Error Message Safety

**Status:** Pass

RAW-24 was verified through multiple browser failure scenarios rather than by creating an additional artificial error.

Relevant browser cases included:

- malformed metadata CSV;
- donor/path-like input;
- invalid donor schema;
- failed HEV plot request;
- external donor Flow retrieval failure.

Across these cases, the UI used controlled messages and did not visibly expose:

- local Windows/Unix/UNC paths;
- `fread`;
- `conditionMessage`;
- traceback text;
- `ggplot` / `ggsave` internals;
- raw curl/network internals;
- internal R object names.

This browser evidence complements the dedicated RAW-24 automated safety tests.

**Evidence reused from:** RAW-02, RAW-06, RAW-18 and RAW-22.

No additional screenshot was required.

### RAW-25 — Global Lifecycle / Timeout / Repeated-Click Control

**Status:** Deferred / Known Limitation

RAW-25 is intentionally deferred from the current recovery patch.

The current branch does not claim a global implementation of:

- universal timeout policy;
- cancellation framework;
- global busy/running manager;
- repeated-click lock;
- universal button-state manager;
- application-wide lifecycle/finalization framework.

The simplification work removed unused local donor/imputation running flags rather than introducing a partial replacement.

RAW-25 should be handled as a dedicated future lifecycle refactor rather than mixed into the completed RAW recovery patch.

---

## 7. Non-Blocking Warning Observed During Join Verification

RAW-15 and RAW-16 completed successfully but produced the same non-blocking warning:

> One or more biology samples precede the start date of the earliest flow period at site(s) 291.

Assessment:

- the warning is related to Biology/Flow temporal coverage;
- it did not prevent Joined HE generation;
- it did not invalidate the RAW prerequisite/recovery behaviour under test;
- therefore RAW-15 and RAW-16 are recorded as **Pass with Warning**.

No defect was raised from this warning in this verification session.

---

## 8. Browser Evidence Inventory

The final browser evidence folder should use:

```text
docs/week09/browser_test_evidence/
```

Expected evidence filenames:

```text
SMOKE_01_task_and_stage_navigation.png
RAW02_01_path_like_donor_mapping_safe_failure.png
RAW02_02_invalid_donor_mapping_schema_blocked.png
RAW03_01_invalid_flow_input_blocked.png
RAW03_02_blank_flow_site_id_blocked.png
RAW04_01_blank_donor_mapping_blocked.png
RAW04_02_whitespace_donor_mapping_blocked.png
RAW05_01_invalid_replacement_not_current.png
RAW05_02_valid_retry_restores_mapping.png
RAW06_01_malformed_csv_controlled_failure.png
RAW06_02_valid_retry_after_malformed_csv.png
RAW07_01_missing_required_biol_site_id_blocked.png
RAW07_02_optional_wq_rhs_absent_non_blocking.png
RAW08_01_invalid_upload_validation.png
RAW08_02_invalid_paste_validation.png
RAW09_01_missing_flow_site_id_blocked.png
RAW09_02_blank_flow_site_id_blocked.png
RAW10_01_missing_flow_input_defaults_HDE.png
RAW10_02_blank_flow_input_defaults_HDE.png
RAW11_01_flow_processing_blocked_without_flow.png
RAW12_01_oe_blocked_without_biology.png
RAW13_01_rict_blocked_without_environment.png
RAW14_01_oe_blocked_without_rict.png
RAW15_01_join_blocked_without_flow_statistics.png
RAW15_02_join_retry_after_flow_statistics.png
RAW16_01_join_blocked_without_oe.png
RAW16_02_join_retry_after_oe.png
RAW17_01_hev_blocked_without_joined_he.png
RAW17_02_hev_retry_after_joined_he.png
RAW18_01_hev_plot_failure_controlled.png
RAW18_02_hev_plot_retry_success.png
RAW19_01_hev_pdf_download_and_open.png
RAW19_02_hev_all_formats_downloaded.png
RAW22_01_additional_donor_external_failure_safe.png
RAW22_02_additional_donor_retry_success.png
```

RAW-01, RAW-20, RAW-21, RAW-23, RAW-24 and RAW-25 do not require dedicated screenshot files in this final report.

---

## 9. Remaining Limitations / Out-of-Scope Items

Browser/manual recovery smoke completed with the following explicit outstanding scenarios and limitations:

1. **RAW-01 missing-`ggnewscale` dependency injection** — not executed; the authoritative dependency-failure recovery scenario remains outstanding, with no implementation or automated coverage claimed.
2. **RAW-19 browser writer-failure injection** — not executed; failure recovery is covered by automated tests; normal browser PDF/JPEG/PNG download path passed.
3. **RAW-21 destructive permission injection** — not executed; filesystem/permission recovery is covered by automation.
4. **RAW-23 invalid-sheet browser injection** — not executed because the production UI does not expose a normal path to select a non-existent sheet; automated coverage exercises NULL/empty/NA/blank/invalid sheet states.
5. **RAW-25** — deferred; no global timeout/cancellation/busy-state framework is claimed.
6. **DATA-01 / DATA-02** — remain separately documented scientific/data risks; this RAW report does not claim to resolve or re-audit them.

---

## 10. Final Assessment

### Automated recovery gate

**PASS**

- 1,056 / 1,056 testthat expectations passed.
- 18 / 18 standalone scripts exited successfully.
- No new automated warnings were introduced.

### Browser / manual recovery smoke

**COMPLETED WITH DOCUMENTED LIMITATIONS**

The implemented RAW recovery scope was broadly verified across metadata replacement, malformed CSV handling, required/optional mapping validation, Flow-source defaulting, donor/imputation validation, Biology / Environmental / RICT / O:E / Flow Statistics prerequisite gates, Joined HE currentness, HEV currentness, controlled plot failure and same-session retry, external donor Flow failure and same-session recovery, HEV PDF/JPEG/PNG normal download path, workbook checkpoint stability, and user-facing error sanitisation.

RAW-01 remains **Not Executed / Outstanding** because the authoritative missing-`ggnewscale` dependency-failure scenario was not injected during this session. The separate task/stage navigation check passed only as general browser smoke.

RAW-15 and RAW-16 are **Pass with Warning** because Joined HE was generated successfully while a non-blocking Biology/Flow temporal coverage warning was displayed.

RAW-20 is **Superseded / N/A**.

RAW-19 writer-failure and RAW-21 destructive permission/filesystem browser fault injection were not executed; their recovery results rely on automation plus, for RAW-19, a passing browser normal download path.

RAW-23 basic browser smoke passed without a retained screenshot and automated edge-case coverage passed; invalid-sheet browser injection was not executed. RAW-24 passes based on automated coverage plus browser evidence reused from RAW-02, RAW-06, RAW-18 and RAW-22.

RAW-25 remains **Deferred / Known Limitation**.

### Final RAW verification conclusion

**The current RAW recovery implementation is ready for QA evidence review and subsequent project-level release/gate review.**

This report does not itself declare Gate D `GO`, freeze an RC, or resolve DATA-01 / DATA-02.

---

## 11. Suggested Repository Placement

Report:

```text
docs/week09/RAW-01-25_Final_Browser_Manual_Verification_Report.md
```

Evidence:

```text
docs/week09/browser_test_evidence/
```

Recommended final QA evidence commit message:

```text
docs: add final RAW browser recovery evidence
```
