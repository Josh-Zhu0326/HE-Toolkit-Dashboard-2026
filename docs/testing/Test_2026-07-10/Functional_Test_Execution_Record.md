# Functional Test Execution Record

## 1. Purpose

This document records the detailed functional testing performed on the HE Toolkit Dashboard after completion of the initial smoke test.

The purpose of this test phase is to verify that the Dashboard functions correctly with customer-provided site metadata and that data can be imported, mapped, processed, and analysed as expected across the supported workflow.

The testing focuses on the following areas:

- customer metadata import and validation;
- preservation of site identifier values and formats;
- Biology data import;
- Environmental data import;
- Flow data import;
- Water Quality data import;
- RHS data import;
- Biology processing;
- Flow processing;
- Biology–Flow pairing and Analysis;
- HEV plot generation;
- error handling and recovery;
- data consistency between input, intermediate outputs, and final results.

This phase goes beyond smoke testing by checking detailed functional behaviour, data integrity, mapping correctness, and handling of valid, invalid, boundary, and incomplete inputs.

---

## 2. Test Scope

The primary test input for this phase is the customer-provided NDMN site metadata file.

The metadata contains identifiers used to link biological, flow, Water Quality, and RHS datasets.

The available identifier fields include:

- `biol_site_id`
- `flow_site_id`
- `wq_site_id`
- `rhs_site_id`
- `rhs_survey_id`

Detailed testing will verify that these identifiers are:

- imported correctly;
- preserved without unintended formatting changes;
- recognised by the relevant Dashboard modules;
- mapped to the correct supporting datasets;
- handled safely when values are missing, duplicated, or unsupported.

Special attention will be given to site identifiers containing:

- leading zeros;
- alphabetic characters;
- mixed alphabetic and numeric characters;
- different identifier lengths.

Examples include identifiers such as:

```text
050101012
022001
023009
029003
SX26F065
2859TH
```

These values must retain their original format throughout the workflow.

---

## 3. Test Data

### Primary Test Data

- **Customer-provided file:** `NDMN site metadata.xlsx`

This file is treated as the primary customer dataset for detailed functional testing.

Where required, the file may be converted into the input format accepted by the Dashboard while preserving all original identifier values.

### Supporting Test Data

Additional test inputs may be created from the customer-provided dataset to test:

- missing required fields;
- missing site identifiers;
- duplicated records;
- invalid identifier formats;
- empty files;
- unsupported file types;
- invalid dates;
- invalid numeric values;
- partial mappings;
- error recovery.

Any modified test file must be clearly named and must not overwrite the original customer-provided dataset.

---

## Test Environment

### Initial Functional Test Baseline

- Branch: `main`
- Commit ID: `7cf242f`
- Platform: Windows 11
- Browser: Google Chrome

### Current Retest Baseline

- Branch: `main`
- Commit ID: `08b595a`
- Platform: Windows 11
- Browser: Google Chrome

---

## 5. Test Status Definitions

- **Pass:** The actual result fully matches the expected result and no new warning or error is produced.
- **Pass with Warning:** The main function completes successfully, but one or more non-blocking warnings are produced.
- **Fail:** The actual result does not match the expected result, or an error prevents the function from completing correctly.
- **Blocked:** The test cannot proceed because of a prerequisite issue or another defect.
- **Not Run:** The test has not yet been executed.

---

## 6. Evidence Rules

- **Pass:** No screenshot required unless evidence is specifically useful.
- **Pass with Warning:** Attach relevant screenshots or logs and reference the related `OBS-xxx` record.
- **Fail:** Attach evidence and reference the related `BUG-xxx` record.
- **Blocked:** Reference the blocking defect and attach evidence where useful.
- **Not Run:** Record `—` in the Evidence column.

---

## 7. Customer-Confirmed Requirements

The following requirements were confirmed by the customer following the initial functional test execution.

| Requirement ID | Confirmed Requirement | Testing Impact |
|---|---|---|
| CR-01 | `rhs_survey_id` should be sufficient for the RHS workflow, as RHS is being treated as site-level data. | Metadata validation and RHS import should be retested using `rhs_survey_id` as the required RHS identifier. |
| CR-02 | HDE should be used as the preferred Flow data source. | Customer Flow data should be retested using `HDE` instead of the previous temporary `NRFA` assumption. |
| CR-03 | NRFA remains available for the minority of sites that may not be available through HDE. | NRFA should be treated as an alternative source rather than the default source for the customer dataset. |
| CR-04 | Approximately 20 minutes for importing 49 WQ sites is considered reasonable under the current WQ Data Explorer behaviour. | The previous 49-site WQ test should be treated as a large-batch performance baseline rather than a confirmed performance defect. |
| CR-05 | Most Dashboard users are expected to use fewer than 10 WQ sites, and very few are expected to use more than 20. | Future performance testing should prioritise smaller representative subsets, with larger datasets used as high-load scenarios. |

---

## 8. Test Execution

### 8.1 FT-01: Customer Metadata Validation

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-01A | Source Metadata Baseline Validation | Review the customer-provided metadata for record count, expected columns, missing values, duplicate records, and duplicate identifiers | The source metadata contains 49 records, 5 expected identifier columns, and no unexpected missing or duplicate values | The customer metadata contains 49 records across 5 identifier columns. No missing values, duplicate rows, or duplicate identifier values were found. | Pass | — |
| FT-01B | RHS Site ID Only | Import customer metadata containing `rhs_site_id` but no `rhs_survey_id` | The Dashboard reports that `rhs_survey_id` is required for the RHS workflow and does not silently treat `rhs_site_id` as an equivalent identifier | The Dashboard accepted `rhs_site_id` as the RHS mapping identifier. This conflicts with the customer-confirmed requirement that `rhs_survey_id` should be sufficient for the RHS workflow. | Fail | BUG-002 |
| FT-01C | RHS Survey ID Only | Import customer metadata containing `rhs_survey_id` but no `rhs_site_id` | The Dashboard accepts `rhs_survey_id` as the supported RHS identifier and does not require `rhs_site_id` | The Dashboard reported that both `flow_input` and `rhs_site_id` were missing. The missing `rhs_site_id` message conflicts with the customer-confirmed requirement that `rhs_survey_id` should be sufficient for the RHS workflow. | Fail | BUG-002 |
| FT-01D | Both RHS Identifiers Present | Import customer metadata containing both `rhs_site_id` and `rhs_survey_id` with different values in the same rows | The Dashboard uses `rhs_survey_id` as the supported RHS identifier and does not reject the file solely because the two identifier columns differ | The Dashboard reported that `rhs_site_id` and `rhs_survey_id` contained conflicting values and blocked validation. This conflicts with the customer-confirmed requirement that `rhs_survey_id` should be sufficient for the RHS workflow. | Fail | BUG-002 |

### 8.2 FT-02: Biology / Environmental Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-02A | Customer Biology Data Import | Upload the customer-derived metadata test file and import Biology data using the customer-provided `biol_site_id` values | Biology data are retrieved successfully for valid customer site IDs, unavailable site IDs are reported clearly, and the Dashboard remains usable | The customer metadata was loaded successfully with 49 rows. Biology data were imported and displayed in the Biology Data table with valid site, sample, and date fields. No blocking error was observed. | Pass | — |
| FT-02B | Customer Environmental Data Import and Display | Import Environmental data for the customer-provided mapped biology sites and review both Data and PCA views | Environmental data are retrieved successfully and both tabular and PCA outputs are displayed clearly without a blocking error | Environmental data were imported successfully and displayed correctly in the Data view. The PCA view was also generated, but the large number of site labels and variable labels overlapped heavily, reducing readability. | Pass with Warning | OBS-009; `FT-02B_environmental_pca_overplotting.png` |

### 8.3 FT-03: Flow Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-03A | Customer Flow Import Using HDE | Import customer Flow data using `HDE` as the customer-confirmed preferred Flow source | Flow data are retrieved successfully and displayed for the mapped customer sites | HDE Flow import completed successfully and the imported Flow data were displayed with completeness statistics. The Console reported parsing-related warnings during downstream filtering, but the warnings did not block the import. | Pass with Warning | Parsing warning observed during HDE import |
| FT-03B | Customer Flow Identifier Format Handling | Verify that mixed-format and leading-zero `flow_site_id` values are preserved during HDE Flow import | Character IDs and leading-zero IDs remain unchanged and are processed correctly | Mixed-format and leading-zero Flow site identifiers were preserved during the HDE import and appeared correctly in the imported Flow data output. | Pass | — |

### 8.4 FT-04: Water Quality Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-04A | Customer WQ Data Import | Import WQ data using all 49 customer-provided `wq_site_id` values | WQ data are retrieved successfully for valid site IDs, unavailable sites are reported clearly, and the Dashboard remains usable throughout the import | WQ data import completed successfully using all 49 customer-provided WQ site IDs. The import processed sites sequentially and took approximately 20 minutes to complete. | Pass | Performance acceptance criteria to be confirmed with the customer |

### 8.5 FT-05: RHS Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-05A | Customer RHS Data Import | Import RHS data using the customer-provided `rhs_survey_id` values through a temporary compatibility workaround where `rhs_site_id` is duplicated from `rhs_survey_id` | RHS data are retrieved and mapped successfully for the customer sites | The workaround metadata passed validation and the RHS import displayed 49 mapped entries. This confirms that the customer `rhs_survey_id` values can support the RHS workflow, while the current metadata validator still requires the temporary `rhs_site_id` compatibility field. | Pass with Warning | BUG-002; workaround used |
### 8.6 FT-06: Biology Processing

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-06A | Customer RICT Prediction | Run `RICT predictions` using the imported customer Biology and Environmental data | RICT predictions complete successfully and produce prediction output without a blocking error | RICT predictions completed successfully and prediction results were displayed for the customer dataset. | Pass | — |
| FT-06B | Customer O:E Ratio Calculation | Calculate O:E ratios after successful RICT prediction using the customer Biology and Environmental data | O:E ratios are calculated for records containing the required observed biological indices | RICT prediction completed successfully. O:E calculation was blocked because one or more sites were missing observed WHPT, LIFE and/or PSI scores required for the calculation. The Dashboard displayed a clear user-facing message and remained usable. | Blocked | Required observed biological index data are incomplete |
| FT-06B-R1 | O:E Calculation with 10-Site Subset | Calculate O:E ratios using the 10-site customer subset after successful RICT prediction | O:E ratios are calculated for records with sufficient observed biological indices | O:E calculation completed successfully and the results table was displayed. | Pass | — |

### 8.7 FT-07: Flow Processing

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-07A | Customer Flow Statistics Calculation | Calculate Flow Statistics using successfully imported customer HDE Flow data | Flow Statistics are calculated and displayed for the imported customer Flow dataset | The calculation failed with `Error in calc_flowstats: Duplicate dates identified`. No Flow Statistics output was generated and the interface remained in a loading state. | Fail | BUG-003 |
| FT-07A-R1 | Flow Statistics Calculation with 10-Site Subset | Calculate Flow Statistics using the 10-site customer HDE subset | Flow Statistics are calculated and displayed successfully, and the progress indicator completes | Flow Statistics calculation completed successfully and the calculated results table was displayed. However, the progress indicator remained at 99% and did not visibly complete. | Pass with Warning | OBS-007 |

### 8.8 FT-08: Analysis

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-08A | Customer Biology–Flow Analysis | Pair processed Biology and Flow data and generate Analysis outputs | Biology and Flow data are paired successfully and Analysis outputs are generated | Testing could not proceed because customer Flow data were unavailable and O:E ratio calculation was blocked by missing observed biological scores. | Blocked | Blocked by unresolved Flow data source and missing O:E inputs |
| FT-08A-R1 | Biology–Flow Pairing with 10-Site Subset | Pair Biology and Flow data using the 10-site customer subset | Pairing either completes successfully or clearly reports any valid data prerequisite issue | The previous `missing value where TRUE/FALSE needed` error did not occur. Pairing was stopped by a clear date-range mismatch warning because some Biology samples preceded the earliest available Flow period. | Blocked | Data prerequisite mismatch; BUG-001 not reproduced |
| FT-08A-R2 | Biology–Flow Pairing with 20-Site Subset | Pair Biology and Flow data using the fixed 20-site customer subset | Pairing completes or clearly reports valid data prerequisite issues | The previous `missing value where TRUE/FALSE needed` error did not occur. Paired data were generated, while the Dashboard displayed a clear warning that some Biology samples preceded the earliest available Flow period for several sites. | Pass with Warning | Data time-range mismatch; BUG-001 not reproduced |

### 8.9 FT-09: HEV Plots

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-09A | Customer HEV Plot Generation | Generate HEV plots using valid paired Biology–Flow data | HEV plots are generated successfully | Testing could not proceed because paired Biology–Flow data were not available. | Blocked | Blocked by FT-08A |

### 8.10 Pending Validation and Data-Source Requirement Tests

| Test ID | Test Name | Test Steps / Input | Expected Result | Actual Result | Status | Evidence / Notes |
|---|---|---|---|---|---|---|
| FT-01E | Metadata Validation with `rhs_survey_id` Only | Upload metadata containing `rhs_survey_id` but no `rhs_site_id` | Metadata validation passes and `rhs_survey_id` is accepted as the supported RHS identifier | Not yet executed because the updated RHS validation behaviour has not been implemented | Not Run | Awaiting implementation |
| FT-01F | Metadata Validation with `rhs_site_id` Only | Upload metadata containing `rhs_site_id` but no `rhs_survey_id` | Metadata validation does not silently treat `rhs_site_id` as equivalent to `rhs_survey_id` and provides a clear validation message | Not yet executed because the updated RHS validation behaviour has not been implemented | Not Run | Awaiting implementation |
| FT-01G | Missing `flow_input` Defaults to HDE | Upload site metadata without the `flow_input` column | Metadata validation passes and the Flow source defaults to `HDE` | Not yet executed because the HDE default behaviour has not been implemented | Not Run | Awaiting implementation |
| FT-01H | Explicit HDE / NRFA Flow Source Selection | Upload metadata containing valid `flow_input` values of `HDE` and `NRFA` | The Dashboard accepts both supported values and uses the selected source for each site | Not yet executed because the updated Flow source handling has not been implemented | Not Run | Awaiting implementation |
| FT-01I | Local Flow CSV Without `flow_input` | Upload a local Flow CSV containing only `flow_site_id`, `date`, and `flow` | The local Flow CSV is accepted without requiring a `flow_input` column | Not yet executed because the updated local Flow CSV schema has not been implemented. The current UI still lists `flow_input` as a required column. | Not Run | Awaiting implementation |
| FT-01J | Invalid `flow_input` Value | Upload metadata containing an unsupported `flow_input` value such as `ABC` | The Dashboard rejects the unsupported value and displays a clear validation message listing the accepted values `HDE` and `NRFA` | Not yet executed because the updated Flow source validation has not been implemented | Not Run | Awaiting implementation |
| FT-01K | Leading-Zero Flow Site ID Preservation | Upload metadata containing leading-zero and character-based `flow_site_id` values | Flow site identifiers are preserved exactly and are not converted to numeric values | Not yet executed against the updated validation workflow | Not Run | Awaiting implementation |