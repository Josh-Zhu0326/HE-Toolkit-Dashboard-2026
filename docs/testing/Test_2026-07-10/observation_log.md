# Observation Log

## OBS-001: Navigation Container Warning on Application Startup

- **Related Test ID:** ST-01
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Console Warning
- **Severity:** Low
- **Blocking:** No

### Steps to Reproduce

1. Open the project in RStudio.
2. Run:

   ```r
   shiny::runApp(".")
   ```

3. Open the Dashboard in Google Chrome.
4. Observe the R Console during application startup.

### Warning Message

```text
Navigation containers expect a collection of `bslib::nav_panel()` /
`shiny::tabPanel()`s and/or `bslib::nav_menu()` /
`shiny::navbarMenu()`s. Consider using `header` or `footer`
if you wish to place content above or below every panel's contents.
```

### Actual Behaviour

The Dashboard opened successfully, but the navigation-container warning appeared twice in the R Console during startup.

### Expected Behaviour

The Dashboard should start successfully without generating navigation-container warnings.

### Impact

The warning did not prevent the Dashboard from starting, loading, or being used. All checked navigation pages remained accessible.

### Initial Assessment

The warning indicates that ordinary UI content may have been placed directly inside a navigation container that expects navigation panels or menus. It is currently non-blocking but may indicate an incorrect UI structure.

### Evidence

- `ST-01_startup_warning.png`

---

## OBS-002: Duplicate Site-Input Combinations Removed During Flow Import

- **Related Test IDs:** ST-03C, FT-03A
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Data Validation Warning
- **Severity:** Low
- **Blocking:** No

### Steps to Reproduce

1. Open the Dashboard.
2. Upload the supported site metadata CSV.
3. Confirm that the metadata is validated and displayed.
4. Set the required flow-data date range.
5. Click `Import flow data`.
6. Observe the imported result and the R Console.

### Warning Message

```text
2 duplicate sites-inputs combination(s) identified and dropped
```

### Actual Behaviour

Flow data were imported successfully.

During the import process, two duplicate site-input combinations were identified and automatically removed.

The same warning was observed during both the initial smoke test and the later customer HDE Flow import.

### Expected Behaviour

Flow data should be imported successfully.

Any duplicated site-input combinations should be handled without causing the import to fail.

Where duplicate combinations are removed automatically, the Dashboard should report the behaviour clearly.

### Impact

The warning did not block the Flow data import.

However, two duplicated site-input combinations were excluded from processing.

The current evidence does not confirm whether the duplicated combinations originate from the uploaded metadata or are introduced during Flow import processing.

### Updated Assessment

This is a reproducible, non-blocking data-validation warning.

The warning was observed during:

- the initial smoke test (`ST-03C`);
- the customer HDE Flow import (`FT-03A`).

In both cases, Flow data were imported successfully and the duplicated site-input combinations were automatically removed.

The affected tests should remain classified as `Pass with Warning`.

Further investigation may be required to determine whether the duplicate combinations originate from the input metadata or are introduced during the Flow import process.

### Functional Retest Result

The same warning was reproduced during the customer HDE Flow import in `FT-03A`.

The R Console reported:

```text
2 duplicate sites-inputs combination(s) identified and dropped
```

The HDE Flow import completed successfully and the imported Flow data were displayed with completeness statistics.

This confirms that the warning is reproducible beyond the original smoke-test execution.

### Evidence

- `ST-03C_flow_import_warning.png`

---

## OBS-003: Water Quality Determinand Codes Not Found During Import

- **Related Test ID:** ST-03D
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Data Mapping Warning
- **Severity:** Low
- **Blocking:** No

### Steps to Reproduce

1. Open the Dashboard.
2. Upload and validate the supported site metadata CSV.
3. Set the required WQ data date range.
4. Click `Import WQ using site IDs`.
5. Wait for the import process to complete.
6. Observe the WQ data result and the R Console.

### Warning Message

```text
Water quality determinand not found:0019
Water quality determinand not found:0135
Water quality determinand not found:6396
```

### Actual Behaviour

The Water Quality data import completed successfully and retrieved 514 unique records. However, determinand codes `0019`, `0135`, and `6396` could not be found during the import process.

### Expected Behaviour

Water Quality data should be imported successfully. All determinand codes contained in the retrieved data should be recognised or handled safely with a clear, non-blocking warning.

### Impact

The warning did not prevent the WQ data from being imported. However, records associated with the unidentified determinand codes may have incomplete names, descriptions, units, or other metadata mappings.

### Initial Assessment

This appears to be a non-blocking data-mapping warning. The import itself succeeded, but the missing determinand mappings should be reviewed to determine whether they affect the WQ data preview, later analysis, plotting, or downloaded results.

### Evidence

- `ST-03D_wq_import_warning.png`

---

## OBS-004: Deprecation Warnings During RICT Prediction

- **Related Test ID:** ST-04A
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Code Deprecation Warning
- **Severity:** Low
- **Blocking:** No

### Steps to Reproduce

1. Open the Dashboard.
2. Import the required Biology and Environmental data.
3. Open the `Process Biology` page.
4. Click `Run RICT predictions`.
5. Wait for the prediction process to complete.
6. Observe the prediction result and the R Console.
7. Click `Calculate O:E ratios`.
8. Confirm that the O:E ratio results are displayed.

### Warning Message

```text
There was 1 warning in `dplyr::summarise()`.

In argument:
`across(.fns = (~sum(is.na(.x))))`

Using `across()` without supplying `.cols` was deprecated in dplyr 1.1.0.
Please supply `.cols` instead.
```

```text
Using an external vector in selections was deprecated in tidyselect 1.1.0.
Please use `all_of()` or `any_of()` instead.

Previously:
data %>% select(keeps)

Recommended:
data %>% select(all_of(keeps))
```

### Actual Behaviour

The RICT prediction process completed successfully, but the R Console displayed deprecation warnings from `dplyr` and `tidyselect`.

The subsequent O:E ratio calculation also completed successfully. The calculated results were displayed in the `O:E Ratios` table.

### Expected Behaviour

RICT predictions and O:E ratio calculations should complete successfully without generating deprecation warnings.

### Impact

The warnings did not prevent either operation from completing. The RICT prediction output was produced, and the O:E ratio results were displayed successfully.

However, the prediction code relies on deprecated syntax that may become incompatible with future versions of `dplyr` or `tidyselect`.

### Initial Assessment

This is a non-blocking code-maintenance issue rather than a functional failure.

The affected code should be updated by:

- explicitly supplying `.cols` in `across()`;
- replacing external-vector selections such as `select(keeps)` with `select(all_of(keeps))` or `select(any_of(keeps))`, depending on the intended behaviour.

### Evidence

- `ST-04A_rict_prediction_warning.png`

---

## OBS-005: Flow Imputation Warnings for Unmapped Sites and Insufficient Donor Overlap

- **Related Test ID:** ST-04B
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Flow Imputation Warning
- **Severity:** Low
- **Blocking:** No
- **Existing in Previous Version:** Yes
- **Regression:** No

### Steps to Reproduce

1. Open the Dashboard.
2. Import the supplied demo metadata and Flow data.
3. Open the `Process Flow` page.
4. Paste the supplied demo donor mapping:

   ```text
   station    donor_station
   28023      28043
   27090      27034
   ```

5. Paste the supplied demo additional donor-site data:

   ```text
   flow_site_id    flow_input
   27034           NRFA
   ```

6. Click `Import additional donor flow data`.
7. Click `Impute missing flow data`.
8. Observe the processed output and the R Console.

### Warning Message

```text
A donor site was not specified for site-28031
A donor site was not specified for site-28043
A donor site was not specified for site-28046
A donor site was not specified for site-47013
A donor site was not specified for site-47014
A donor site was not specified for site-48001
A donor site was not specified for site-48004
A donor site was not specified for site-49003
A donor site was not specified for site-72005
```

```text
27090-Equipercentile method cannot be applied for this site,
due to insufficient overlapping data with the donor site.
```

### Actual Behaviour

The additional donor Flow data were imported successfully, and the imputed Flow output was displayed.

Flow sites that were not included as donee sites in the donor mapping were skipped and generated warnings stating that no donor had been specified.

Site `27090` had a configured donor site, but the equipercentile method could not be applied because the donee and donor datasets did not contain sufficient overlapping observations.

### Expected Behaviour

Sites with valid donor mappings and sufficient overlapping data should be imputed successfully.

Sites without configured donors should be skipped safely, while sites with insufficient overlapping donor data should remain unimputed and generate a clear warning.

### Impact

The warnings did not block the Flow-processing operation or prevent the output table from being displayed.

Sites without configured donors were not imputed, and missing values for site `27090` may remain because of insufficient overlapping data with donor site `27034`.

### Initial Assessment

These warnings appear to reflect expected donor-mapping and data-availability limitations rather than a functional defect.

The same behaviour was observed in the previous version, so it is not considered a regression introduced by the current build.

### Evidence

- `ST-04B_flow_imputation_warning.png`

---

## OBS-006: Demo Donor Mapping Is Incorrectly Reported as Invalid

- **Related Test ID:** ST-04B
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** UI Validation Message
- **Severity:** Low
- **Blocking:** No
- **Existing in Previous Version:** To be confirmed
- **Regression:** To be confirmed

### Steps to Reproduce

1. Open the Dashboard.
2. Import the supplied demo metadata and Flow data.
3. Open the `Process Flow` page.
4. Paste the supplied demo donor mapping:

   ```text
   station    donor_station
   28023      28043
   27090      27034
   ```

5. Paste the supplied demo additional donor-site data:

   ```text
   flow_site_id    flow_input
   27034           NRFA
   ```

6. Click `Import additional donor flow data`.
7. Observe the donor-mapping validation messages displayed in the interface.

### Validation Messages

```text
Donee flow sites not detected in original metadata
```

```text
One or more named donor sites are absent from both original metadata
and additional donor list
```

### Actual Behaviour

The Dashboard reported that the supplied donee and donor sites could not be found.

However:

- donee sites `28023` and `27090` exist in the supplied demo metadata;
- donor site `28043` exists in the supplied demo metadata;
- donor site `27034` exists in the supplied additional donor-site list.

The Flow-imputation process still produced an output table.

### Expected Behaviour

The supplied demo donor mapping should be recognised as valid.

Donee sites that exist in the demo metadata and donor sites that exist in either the original metadata or the additional donor-site list should not be reported as missing.

### Impact

The validation messages did not block Flow imputation, but they may confuse users and incorrectly suggest that the official demo inputs are invalid.

### Initial Assessment

This appears to be a non-blocking validation-message issue.

Possible causes include:

- differences between numeric and character site-ID values;
- leading or trailing whitespace in pasted data;
- validation logic checking the wrong reactive object;
- validation messages not refreshing after additional donor data are imported.

### Evidence

- `ST-04B_donor_mapping_validation_message.png`

---

## OBS-007: Flow Statistics Progress Indicator Remains at 99% After Results Are Generated

- **Related Test ID:** ST-04B
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Progress Indicator / UI Feedback Issue
- **Severity:** Low
- **Blocking:** No
- **Existing in Previous Version:** To be confirmed
- **Regression:** Inconclusive

### Steps to Reproduce

1. Open the Dashboard.
2. Import the supplied demo metadata and Flow data.
3. Open the `Process Flow` page.
4. Import the supplied additional donor Flow data.
5. Paste the supplied demo donor mapping.
6. Click `Impute missing flow data`.
7. Click `Calculate flow statistics`.
8. Wait for the calculation to complete.
9. Observe the generated Flow Statistics output and the progress indicator.

### Actual Behaviour

The Flow Statistics results were generated and displayed successfully.

However, the progress indicator repeatedly moved through the calculation stages and remained at `99%` after the results had already appeared.

The issue does not occur consistently. In a later 20-site retest, the progress indicator reached 100%, while the 10-site retest produced valid Flow Statistics output but remained at 99%. This suggests that the issue may relate to progress-state reporting rather than the underlying calculation itself.

### Expected Behaviour

Once the Flow Statistics results have been generated successfully, the progress indicator should complete, close, or clearly show that processing has finished.

### Impact

The issue did not prevent the Flow Statistics output from being generated or displayed.

However, leaving the progress indicator at `99%` may cause users to believe that the calculation is still running or has become stuck.

### Updated Assessment

This appears to be a non-blocking and intermittent UI feedback issue rather than a processing failure.

The calculation itself can complete successfully, but the progress state is not always finalised consistently after the output becomes available.

The issue was reproduced in the original smoke test and again in a later 10-site retest, where valid Flow Statistics output was generated while the progress indicator remained at `99%`.

However, in a 20-site retest, the progress indicator reached `100%`.

This suggests that the issue affects progress-state reporting intermittently rather than the underlying Flow Statistics calculation.

### Evidence

- `ST-04B_flow_statistics_progress_99.png`

---

## OBS-008: Legacy RHS Identifier Aliasing Conflicts with the Canonical Metadata Contract

- **Status:** Upgraded to `BUG-002`
- **Related Test IDs:** FT-01B, FT-01C, FT-01D, FT-05A
- **Branch:** main
- **Initial Commit ID:** 7cf242f
- **Current Retest Baseline:** 08b595a
- **Type:** RHS Identifier Validation / Canonicalisation
- **Severity:** Medium
- **Blocking:** Partially

### Actual Behaviour

The current Dashboard does not consistently enforce `rhs_survey_id` as the canonical RHS identifier.

Observed behaviour includes:

- metadata containing only `rhs_survey_id` being reported as missing `rhs_site_id`;
- metadata containing only `rhs_site_id` being accepted as an RHS mapping identifier;
- `rhs_site_id` being made available internally as `rhs_survey_id`;
- metadata containing both fields with different values being rejected as conflicting;
- metadata containing both fields with identical values being accepted.

During testing, a temporary workaround duplicated `rhs_survey_id` values into `rhs_site_id`.

The workaround passed metadata validation and allowed 49 RHS entries to be displayed.

However, this workaround uses a non-canonical RHS alias and does not represent the confirmed metadata contract.

### Expected Behaviour

The Dashboard metadata contract should use `rhs_survey_id` as the canonical RHS identifier.

The expected behaviour is:

- metadata containing only `rhs_survey_id` is accepted;
- metadata containing `rhs_site_id` is rejected;
- metadata containing both RHS identifier columns is rejected, whether the values are identical or different;
- the user is clearly instructed to remove `rhs_site_id` and retain `rhs_survey_id`;
- `rhs_site_id` is not silently copied or aliased into `rhs_survey_id`;
- normalised internal and output data do not retain or generate `rhs_site_id`.

External RHS source fields may be explicitly mapped or renamed to `rhs_survey_id` at the import boundary where required.

### Impact

The current behaviour may:

- reject valid canonical metadata;
- accept non-canonical metadata;
- force users to modify valid source data to satisfy an obsolete field requirement;
- hide identifier-contract problems through silent aliasing;
- preserve obsolete schema behaviour in test fixtures and regression tests.

### Updated Assessment

The customer confirmed that `rhs_survey_id` should be sufficient for the RHS workflow.

The RHS metadata contract has therefore been clarified: `rhs_survey_id` is the supported canonical identifier, while `rhs_site_id` should not be accepted or generated by the Dashboard metadata workflow.

The current behaviour directly conflicts with this confirmed contract.

This observation has therefore been upgraded to `BUG-002`.

### Evidence

- `FT-05A_rhs_identifier_mapping_inconsistency.png`
- FT-01B
- FT-01C
- FT-01D
- FT-05A

The 49-entry RHS import achieved through the temporary duplicated-ID workaround is retained only as evidence of the current compatibility behaviour and should not be treated as a valid expected workflow.

---

## OBS-009: Environmental PCA Plot Becomes Difficult to Read with Many Sites

- **Related Test ID:** FT-02B
- **Branch:** main
- **Commit ID:** 7cf242f
- **Type:** Data Visualisation / Usability Issue
- **Severity:** Low
- **Blocking:** No

### Steps to Reproduce

1. Upload the customer-derived metadata containing 49 mapped biology sites.
2. Import Environmental data.
3. Open the `Environmental Data` tab.
4. Select the `PCA` display option.
5. Observe the generated PCA plot.

### Actual Behaviour

The Environmental data were imported successfully and the PCA plot was generated.

However, the plot contains a large number of site labels and environmental variable labels. Many labels overlap, making individual site IDs and variable relationships difficult to read.

### Expected Behaviour

The PCA plot should remain interpretable when a realistic number of customer sites are displayed.

### Impact

The issue does not prevent Environmental data from being imported or the PCA plot from being generated.

However, the current visualisation becomes difficult to interpret with the 49-site customer dataset, reducing its usability for larger datasets.

### Initial Assessment

This appears to be a non-blocking visualisation and usability issue.

Possible improvements could include optional label display, hover tooltips, selective labelling, zooming, or other methods to reduce label overlap.

### Evidence

- `FT-02B_environmental_pca_overplotting.png`

---

## OBS-010: WQ Import Performance Baseline for 49 Sites

- **Related Test ID:** FT-04A
- **Branch:** main
- **Initial Commit ID:** 7cf242f
- **Current Retest Baseline:** 08b595a
- **Type:** Performance Baseline
- **Severity:** N/A
- **Blocking:** No
- **Status:** Customer-confirmed expected behaviour

### Actual Behaviour

The WQ import for 49 customer sites completed successfully and retrieved 47,290 unique records.

The complete import took approximately 20 minutes.

### Customer Confirmation

The customer confirmed that approximately 20 minutes for 49 WQ sites is reasonable under the current WQ Data Explorer behaviour.

The customer also indicated that:

- fewer than 10 WQ sites is expected for most typical Dashboard users;
- very few Dashboard users are expected to process more than 20 WQ sites;
- 49 sites represents a realistic larger modelling-study workload.

### Assessment

The observed 20-minute duration is treated as a customer-confirmed large-batch performance baseline rather than a confirmed performance defect.

The result should therefore not be classified as a performance bug.

Future performance testing should prioritise fixed site subsets representing:

- 5 sites;
- 10 sites;
- 20 sites;
- 49 sites.

These datasets should be used to compare typical and high-load Dashboard scenarios.

### Evidence

The timing was recorded during FT-04A.

No additional screenshot was required because the import completed successfully and the customer subsequently confirmed the observed duration as reasonable for the tested workload.

---