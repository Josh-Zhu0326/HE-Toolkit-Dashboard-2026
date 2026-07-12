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

## 4. Test Environment

- **Tester:** Benyu Zhu
- **Branch:** main
- **Commit ID:** 7cf242f
- **Operating System:** Windows 11
- **Browser:** Google Chrome
- **Test Environment:** Local
- **Application:** HE Toolkit Dashboard

The commit ID and environment must be updated if testing continues against a newer version of the Dashboard.

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

## 7. Test Execution

### 7.1 FT-01: Customer Metadata Validation

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-01A | Source Metadata Baseline Validation | Review the customer-provided metadata for record count, expected columns, missing values, duplicate records, and duplicate identifiers | The source metadata contains 49 records, 5 expected identifier columns, and no unexpected missing or duplicate values | The customer metadata contains 49 records across 5 identifier columns. No missing values, duplicate rows, or duplicate identifier values were found. | Pass | — |
| FT-01B | RHS Site ID Only | Import customer metadata containing `rhs_site_id` but no `rhs_survey_id` | The Dashboard recognises `rhs_site_id` as the RHS mapping identifier and reports only genuinely missing required fields | The Dashboard accepted `rhs_site_id` as the required RHS identifier. Validation was blocked only because the customer metadata does not contain the required `flow_input` column. | Blocked | Customer data clarification required for `flow_input` |
| FT-01C | RHS Survey ID Only | Import customer metadata containing `rhs_survey_id` but no `rhs_site_id` | The Dashboard accepts `rhs_survey_id` if it is supported as an alternative RHS mapping identifier, or clearly reports the required mapping rule | The Dashboard reported that both `flow_input` and `rhs_site_id` were missing. This confirms that `rhs_survey_id` is not currently accepted as a replacement for the required `rhs_site_id` field. | Pass | — |
| FT-01D | Both RHS Identifiers Present | Import customer metadata containing both `rhs_site_id` and `rhs_survey_id` with different values in the same rows | The Dashboard accepts both identifiers if they represent distinct RHS site-level and survey-level identifiers, or clearly reports the required mapping rule | The Dashboard reported that `rhs_site_id` and `rhs_survey_id` contained conflicting values. Clarification is required to confirm whether both identifiers are valid and should be retained. Validation was also blocked because `flow_input` is not present. | Blocked | Data model clarification required for RHS identifiers and `flow_input` |

### 7.2 FT-02: Biology / Environmental Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-02A | Customer Biology Data Import | Upload the customer-derived metadata test file and import Biology data using the customer-provided `biol_site_id` values | Biology data are retrieved successfully for valid customer site IDs, unavailable site IDs are reported clearly, and the Dashboard remains usable | The customer metadata was loaded successfully with 49 rows. Biology data were imported and displayed in the Biology Data table with valid site, sample, and date fields. No blocking error was observed. | Pass | — |
| FT-02B | Customer Environmental Data Import and Display | Import Environmental data for the customer-provided mapped biology sites and review both Data and PCA views | Environmental data are retrieved successfully and both tabular and PCA outputs are displayed clearly without a blocking error | Environmental data were imported successfully and displayed correctly in the Data view. The PCA view was also generated, but the large number of site labels and variable labels overlapped heavily, reducing readability. | Pass with Warning | OBS-009; `FT-02B_environmental_pca_overplotting.png` |

### 7.3 FT-03: Flow Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-03A | Customer Flow Import Using Assumed NRFA Source | Import Flow data using the customer-provided `flow_site_id` values with `flow_input` temporarily set to `NRFA` for all records | Valid NRFA site IDs are retrieved successfully, unsupported site IDs are reported clearly, and the Dashboard remains usable | Flow import could not be completed because one or more customer-provided `flow_site_id` values could not be retrieved from NRFA. The Console reported `URL does not seem to exist for these NRFA site(s); no data retrieved`. This indicates that the assumption that all customer Flow sites use NRFA is not valid. | Blocked | Customer clarification required for the correct `flow_input` source |
| FT-03B | Customer Flow Identifier Format Handling | Review the customer-provided `flow_site_id` values and verify that mixed-format identifiers are preserved before import | Numeric, leading-zero, alphabetic, and mixed-format Flow site IDs retain their original values without unintended conversion | The customer metadata contains mixed Flow identifier formats, including numeric, leading-zero, alphabetic, and alphanumeric values. These values were preserved in the test CSV, but full import behaviour could not be validated until the correct `flow_input` source is confirmed. | Blocked | Customer clarification required for the correct `flow_input` source |

### 7.4 FT-04: Water Quality Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-04A | Customer WQ Data Import | Import WQ data using all 49 customer-provided `wq_site_id` values | WQ data are retrieved successfully for valid site IDs, unavailable sites are reported clearly, and the Dashboard remains usable throughout the import | WQ data import completed successfully using all 49 customer-provided WQ site IDs. The import processed sites sequentially and took approximately 20 minutes to complete. | Pass | Performance acceptance criteria to be confirmed with the customer |

### 7.5 FT-05: RHS Data Import

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-05A | Customer RHS Data Import | Import RHS data using the customer-provided RHS identifiers | RHS data are retrieved and mapped successfully using the identifier required by the RHS workflow | The RHS source dataset was downloaded successfully and 9 records were mapped to 9 biology sites. The RHS page states that records are mapped through `rhs_survey_id` and that RHS site IDs are not used as survey IDs. However, the current metadata validation requires `rhs_site_id` and prevents different `rhs_site_id` and `rhs_survey_id` values from being used together. | Pass with Warning | OBS-008; `FT-05A_rhs_identifier_mapping_inconsistency.png` |

### 7.6 FT-06: Biology Processing

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-06A | Customer RICT Prediction | Run `RICT predictions` using the imported customer Biology and Environmental data | RICT predictions complete successfully and produce prediction output without a blocking error | RICT predictions completed successfully and prediction results were displayed for the customer dataset. | Pass | — |
| FT-06B | Customer O:E Ratio Calculation | Calculate `O:E ratios` after successful RICT prediction | O:E ratios are calculated successfully when the required observed biological scores are available, or a clear message is displayed when required inputs are missing | O:E ratio calculation could not proceed because one or more sites were missing observed WHPT, LIFE and/or PSI scores required for O:E calculations. The Dashboard displayed a clear user-facing message and remained usable. | Blocked | Missing required observed biological scores in the available customer dataset |

### 7.7 FT-07: Flow Processing

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-07A | Customer Flow Processing | Run Flow imputation and Flow Statistics using successfully imported customer Flow data | Flow processing completes successfully and produces imputed Flow data and Flow Statistics | Testing could not proceed because the correct `flow_input` source for the customer-provided `flow_site_id` values has not yet been confirmed, and customer Flow data could not be imported successfully. | Blocked | Customer clarification required for `flow_input` |

### 7.8 FT-08: Analysis

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-08A | Customer Biology–Flow Analysis | Pair processed Biology and Flow data and generate Analysis outputs | Biology and Flow data are paired successfully and Analysis outputs are generated | Testing could not proceed because customer Flow data were unavailable and O:E ratio calculation was blocked by missing observed biological scores. | Blocked | Blocked by unresolved Flow data source and missing O:E inputs |

### 7.9 FT-09: HEV Plots

| Test ID | Test Area | Test Step | Expected Result | Actual Result | Status | Evidence |
|---|---|---|---|---|---|---|
| FT-09A | Customer HEV Plot Generation | Generate HEV plots using valid paired Biology–Flow data | HEV plots are generated successfully | Testing could not proceed because paired Biology–Flow data were not available. | Blocked | Blocked by FT-08A |
