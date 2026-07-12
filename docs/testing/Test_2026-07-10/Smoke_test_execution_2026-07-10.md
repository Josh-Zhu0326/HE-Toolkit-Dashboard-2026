# Test Execution Record

## Test Baseline

* Test Date: 10 July 2026
* Tester: Benyu Zhu
* Branch: main
* Commit ID: 7cf242f
* Repository Status: Latest version pulled
* Operating System: Windows 11
* Browser: Google Chrome
* R Version: R version 4.6.0 (2026-04-24 ucrt)
* Test Environment: Local

## Test Status

* Not Run
* Pass
* Fail
* Blocked
* Not Applicable
* Pass with Warning

## Execution Log

| Test ID | Test Area                 | Expected Result                                                | Actual Result                                                                                     | Status            | Evidence                                  |
| ------- | ------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------- | ----------------------------------------- |
| ST-01   | Application Startup       | Dashboard starts successfully without a blocking error         | Dashboard opened successfully. Two navigation-container warnings were displayed in the R Console. | Pass with Warning | OBS-001; `ST-01_startup_warning.png`      |
| ST-02   | Page Navigation           | All main pages and sub-tabs open correctly                     | All checked pages and sub-tabs opened successfully without visible errors.                        | Pass              | —                                         |
| ST-03   | Site Metadata Import      | Metadata is parsed, validated, and displayed                   | Site metadata was uploaded and displayed successfully.                                            | Pass              | —                                         |
| ST-03A  | Biology Data Import       | Biology data is imported successfully                          | Biology data was imported successfully.                                                           | Pass              | —                                         |
| ST-03B  | Environmental Data Import | Environmental data is imported successfully                    | Environmental data was imported successfully.                                                     | Pass              | —                                         |
| ST-03C  | Flow Data Import          | Flow data is imported successfully                             | Flow data was imported successfully. Two duplicate site-input combinations were removed.          | Pass with Warning | OBS-002; `ST-03C_flow_import_warning.png` |
| ST-03D | Water Quality Data Import | Set the WQ date range and click `Import WQ using site IDs` | Water Quality data is imported successfully using the site IDs from the validated metadata | Water Quality data was imported successfully and 514 unique records were retrieved. However, determinand codes `0019`, `0135`, and `6396` were not found. | Pass with Warning | OBS-003; `ST-03D_wq_import_warning.png` |
| ST-03E | RHS Data Import | Click `Import RHS using site IDs` | RHS data is imported successfully using the site IDs from the validated metadata | The RHS source data was downloaded successfully. One RHS record was mapped to one biology site, displayed in the preview table, and used to generate an RHS plot without a blocking error. | Pass | — |
| ST-04A | Biology Data Processing | Open `Process Biology`, run `RICT predictions`, and calculate `O:E ratios` using the imported Biology and Environmental data | RICT predictions and O:E ratio calculations complete successfully, and the resulting data are displayed without a blocking error | RICT predictions completed successfully but generated non-blocking `dplyr` and `tidyselect` deprecation warnings. O:E ratios were then calculated successfully and displayed in the results table. | Pass with Warning | OBS-004; `ST-04A_rict_prediction_warning.png` |
| ST-04B | Flow Data Processing | Open `Process Flow`, import the demo additional donor flow data, paste the demo donor mapping, click `Impute missing flow data`, calculate Flow Statistics, and review the processed outputs | Flow imputation and Flow Statistics calculation complete successfully, and the resulting outputs are displayed without a blocking error | Flow imputation and Flow Statistics calculation both produced output successfully. Sites without configured donors were skipped with warnings also present in the previous version, and site `27090` could not be imputed because of insufficient overlapping donor data. The Flow Statistics progress indicator remained at 99% even though the results had already been generated. | Pass with Warning | OBS-005; OBS-006; OBS-007; `ST-04B_flow_imputation_warning.png`; `ST-04B_donor_mapping_validation_message.png`; `ST-04B_flow_statistics_progress_99.png` |
| ST-05A | Biology–Flow Data Pairing | Open `Analysis`, select at least one lag and a valid join method, then click `Pair biology and flow data` | Biology and Flow data are paired successfully, and the joined dataset is displayed without a blocking error | The pairing operation reached 99% but did not complete. The R Console reported `Error in if: missing value where TRUE/FALSE needed`, and no joined dataset was produced. | Fail | BUG-001; `ST-05A_pairing_error.png` |
| ST-05B | Pairwise Correlations | Open `Analysis` → `Pairwise Correlations` after generating the joined dataset | Pairwise correlation results are displayed successfully | Testing could not proceed because the joined Biology–Flow dataset was not generated due to BUG-001. | Blocked | BUG-001 |
| ST-05C | Historical Coverage | Open `Analysis` → `Historical Coverage` after generating the joined dataset | Historical coverage results are displayed successfully | Testing could not proceed because the joined Biology–Flow dataset was not generated due to BUG-001. | Blocked | BUG-001 |
| ST-05D | Flow-Ecology Model | Open `Analysis` → `Flow-Ecology Model` after generating the joined dataset | The model runs successfully and displays its output | Testing could not proceed because the joined Biology–Flow dataset was not generated due to BUG-001. | Blocked | BUG-001 |
| ST-06 | HEV Plot Generation | Open `HEV Plots`, select valid biomonitoring and Flow metrics, and click `Create HEV plot` | The HEV plot is generated and displayed successfully when valid paired Biology–Flow data are available | Testing could not proceed because the paired Biology–Flow dataset was not generated due to BUG-001. The Dashboard displayed `Paired biology-flow data are missing`. | Blocked | BUG-001; `ST-06_hev_plot_blocked.png` |
| ST-07A | Valid WQ CSV Validation | Open `CSV Validation Sandbox` and upload a valid WQ CSV file | The CSV is read successfully, validation feedback is displayed, and a readable data preview is shown without a blocking error | The valid WQ CSV was uploaded successfully. A success message and file preview were displayed without a blocking error. | Pass | — |
| ST-07B | Valid RHS CSV Validation | Open `CSV Validation Sandbox` and upload a valid RHS CSV file | The CSV is read successfully, validation feedback is displayed, and a readable data preview is shown without a blocking error | The valid RHS CSV was uploaded successfully. A success message and file preview were displayed without a blocking error. | Pass | — |
| ST-07C | WQ CSV Missing Site Identifier | Upload a WQ CSV without a recognised site-identifier column | The file is handled safely, clear validation feedback identifies the missing site-identifier column, and the Dashboard remains usable | The CSV was uploaded successfully. The validation message correctly reported that no recognised site-identifier column was present and listed the accepted column names. The preview remained available and the Dashboard stayed usable. | Pass | — |
| ST-07D | Unsupported File Type Restriction | Open the WQ file picker and check whether non-CSV files can be selected | The file picker restricts selectable files to supported CSV files | The file picker displayed CSV files only, and the `.xlsx` file was not available for selection. | Pass | — |
| ST-07E | Empty or Invalid CSV Validation | Upload an empty CSV or an invalid CSV file | The Dashboard displays a clear validation message and remains usable without exposing a raw application error | The file was rejected safely. The Dashboard displayed a clear message stating that the file could not be read as CSV and asked the user to check that it was a valid comma-separated file. | Pass | — |
| ST-07F | Validation Error Recovery | Upload an invalid WQ CSV and then replace it with a valid WQ CSV without restarting the Dashboard | The Dashboard clears or replaces the previous error, validates the new file successfully, and displays its preview | The Dashboard recovered from the invalid-file state. A valid WQ CSV was subsequently uploaded and previewed successfully without restarting the application. | Pass | — |







