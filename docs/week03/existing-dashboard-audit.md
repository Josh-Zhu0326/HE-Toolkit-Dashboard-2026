# Existing Dashboard Audit

## 1. Purpose

This document records the current functionality, user inputs, outputs, usability characteristics and potential improvement opportunities of the existing HE Toolkit Dashboard.

## 2. Audit Information

* **Audit date:** 20 June 2026
* **Auditor:** Josh Zhu
* **Deployment type:** Local deployment
* **Application launch method:** R Shiny application running locally
* **Repository branch:** `main`
* **Commit:** `33b9ec1`
* **Browser:** Google Chrome 149, 64-bit
* **Operating system:** Windows 11 Home, 64-bit, Version 25H2
* **OS build:** 26200.8328
* **Processor:** 13th Gen Intel Core i7-13650HX
* **Memory:** 16 GB RAM
* **Test dataset:** Demo metadata and associated biology, environmental and flow data provided through the dashboard
* **Target users:** Environment Agency staff and other users with limited R programming experience

## 3. Audit Scope

### Included

* Existing dashboard pages and modules
* Navigation and workflow
* User input requirements
* Data import functionality
* Data processing functionality
* Data visualisation and outputs
* Validation and error messages
* General usability
* Accessibility and interface consistency
* Help text and documentation

### Not Included

* Detailed source-code review
* Statistical validation of every HE Toolkit function
* Formal performance testing
* Formal user testing with external participants
* Evaluation of the redesigned dashboard

## 4. Existing Feature Inventory

| Page / Module           | Purpose                                                                                                             | User inputs                                           | Outputs                                                             | Initial status                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------- |
| Introduction / Overview | Introduces the dashboard, expected workflow and required input data                                                 | None                                                  | Instructions, metadata guidance, demo data and documentation links  | Page loads successfully                                        |
| Import datasets         | Allows users to enter metadata, import invertebrate, environmental and flow data, and preview the imported datasets | Site metadata, biology date range and flow date range | Imported datasets, preview tables, site map and validation messages | Page loads successfully; import functions not yet fully tested |
| Process invertebrate data | Processes imported invertebrate data by running RICT predictions and calculating observed-to-expected ratios | Imported invertebrate data and processing selections | RICT prediction results and O:E ratio results | Page loads successfully; processing functions not yet tested |
| Process flow data | Imports donor flow data, imputes missing flow values and calculates flow statistics | Imported flow data, donor mapping, donor-site list, display type, window width and window step | Imputed flow data and calculated flow statistics | Page, tabs and display options work; processing functions not yet fully tested |
| Join HE data | Pairs processed biology and flow data using selected lags and a joining method | Processed biology data, processed flow data, selected lags and join method | Joined dataset, pairwise correlations and historical coverage | Page and result tabs work; data-pairing function not yet fully tested |
| HEV | Creates and downloads an HEV plot using selected biomonitoring and flow variables | Joined hydroecological data, biomonitoring index, flow metric and date range | HEV plot and downloadable plot file | Page and controls load successfully; plot generation and download not yet tested |
| Links | Provides access to external HE Toolkit resources and documentation | Selection of an external link | HE Toolkit GitHub repository and documentation website | Dropdown menu and both external links work successfully |

## 5. Module Details

### 5.1 Introduction / Overview

#### Purpose

Provides an introduction to the HE Toolkit Dashboard and explains the expected data inputs and general workflow.

#### Main Functions

* Introduces the purpose of the dashboard
* Explains the general workflow of the HE Toolkit
* Describes the required site metadata
* Explains the standard metadata column names
* Describes biology and flow data requirements
* Provides demo metadata for exploring the dashboard
* Explains how flow donor sites are used
* Provides links to additional HE Toolkit documentation
* Provides contact information for questions, bug reports and improvement suggestions
* Warns users that some processes may take time to complete
* Explains that familiarity with some HE Toolkit functions and arguments may be required

#### User Inputs

* None

#### Outputs

* Dashboard instructions
* General workflow guidance
* Metadata format guidance
* Demo metadata
* Flow donor-site guidance
* Links to external documentation
* Contact information

#### Initial Status

* The page loads successfully
* Instructions and demo information are displayed
* Navigation links are visible
* No interactive input is required on this page

---

### 5.2 Import Datasets

#### Purpose

Allows users to enter site metadata, import hydroecological datasets and preview the imported data before continuing to the data-processing stages.

#### Main Functions

* Allows users to paste site metadata into the dashboard
* Checks whether site metadata has been provided
* Allows users to select a start date and an end date for biology samples
* Allows users to select a start date and an end date for flow data
* Imports invertebrate data
* Imports environmental data
* Imports flow data
* Displays imported invertebrate data
* Displays imported environmental data
* Displays imported flow data
* Displays the locations of imported sites on a map
* Allows users to clear all imported data and reset the page

#### User Inputs

* Site metadata
* Biology sample start date
* Biology sample end date
* Flow data start date
* Flow data end date
* Selection of the relevant import button

#### Outputs

* Imported invertebrate dataset
* Imported environmental dataset
* Imported flow dataset
* Data preview tables
* Map of imported sites
* Metadata validation messages

#### Initial Status

* The page loads successfully
* The metadata text box is displayed
* The biology and flow date selectors are displayed
* The biology, environmental and flow import buttons are displayed
* A `Please add metadata` validation message is displayed when metadata has not been entered
* The environmental data, flow data and site map preview tabs can all be opened successfully
* No errors occur when switching between the preview tabs
* The data preview area is empty before data is imported
* Data import and data display functions have not yet been fully tested
* The environmental data view supports both `Data` and `PCA` display modes
* The flow data view supports both `Completeness stats` and `Heatmap` display modes
* All four display modes can be selected and displayed successfully
* No errors occur when switching between the display options
- The site map loads successfully and displays imported site locations
- The map can be moved and zoomed using the available controls
- No noticeable loading delay or errors occur when using the map

---

### 5.3 Process Invertebrate Data

#### Purpose

Allows users to process imported invertebrate data by running RICT predictions and calculating observed-to-expected ratios.

#### Main Functions

* Runs RICT predictions using imported invertebrate data
* Calculates observed-to-expected ratios
* Displays the generated RICT prediction results
* Displays the calculated observed-to-expected ratios
* Allows users to switch between the RICT prediction and O:E ratio result tabs

#### User Inputs

* Imported invertebrate data from the `Import datasets` page
* Selection of the `Run RICT predictions` button
* Selection of the `Calculate O:E ratios` button

#### Outputs

* RICT prediction results
* Observed-to-expected ratio results
* Result tables or other result displays within the corresponding tabs

#### Initial Status

- The page loads successfully
- The `View RICT predictions` and `View O:E ratios` tabs are displayed
- The two result tabs can be opened and switched between successfully
- No errors occur when switching between the tabs
- The `Run RICT predictions` and `Calculate O:E ratios` buttons are displayed
- The result area is empty before invertebrate data has been imported and processed
- The prediction and ratio calculation functions have not yet been fully tested
- RICT predictions were generated successfully using the imported demo data
- The calculation completed in approximately 2 seconds
- A results table containing 39 entries was displayed
- Pagination, copy and download controls were available
- O:E ratios were calculated successfully using the imported demo data
- The calculation completed in less than 1 second
- A results table containing 580 entries was displayed
- Pagination, copy and download controls were available

---

### 5.4 Process Flow Data

#### Purpose

Allows users to import additional donor flow data, impute missing flow values and calculate flow statistics from imported flow data.

#### Main Functions

* Allows users to enter flow donor-site mapping information
* Allows users to enter a list of additional flow donor sites
* Imports additional donor flow data
* Imputes missing values in the flow dataset
* Allows users to select between time-varying and long-term result displays
* Allows users to configure the flow-statistics window width
* Allows users to configure the flow-statistics window step
* Calculates flow statistics
* Displays imputed flow data
* Displays calculated flow statistics
* Allows users to switch between the imputed flow data and flow statistics tabs

#### User Inputs

* Imported flow data from the `Import datasets` page
* Flow donor-site mapping information
* Additional flow donor-site information
* Selection of the `Import additional donor flow data` button
* Selection of the `Impute missing flow data` button
* Display option:

  * Time-varying
  * Long-term
* Window width in months
* Window step in months
* Selection of the `Calculate flow statistics` button

#### Outputs

* Imported donor flow data
* Imputed flow dataset
* Time-varying flow results
* Long-term flow results
* Calculated flow statistics
* Validation and status messages

#### Initial Status

* The page loads successfully
* The `View imputed flow data` and `View flow stats` tabs are displayed
* The two result tabs can be opened and switched between successfully
* No errors occur when switching between the result tabs
* The `Time-varying` and `Long-term` display options can be selected successfully
* No errors occur when switching between the display options
* The donor mapping and additional donor-site text boxes are displayed
* The donor flow import, flow imputation and flow-statistics buttons are displayed
* The window-width and window-step controls are displayed
* A `Please add metadata` validation message is displayed when the required metadata has not been entered
* The result areas are empty before flow data has been imported and processed
* Flow import, imputation and flow-statistics calculations have not yet been fully tested
- Flow imputation completed in approximately 3 seconds using the supplied donor mapping
- Imputation succeeded for a site whose donor station was already available in the imported flow dataset
- A site mapped to an unavailable donor station remained unimputed
- The completeness statistics were updated after processing
- The Heatmap display loaded successfully in approximately 2 seconds
- Valid additional donor flow data were imported successfully
- A clear success confirmation message was displayed
- The import completed almost immediately
- Re-running the imputation after importing donor site `27034` successfully reduced the missing values for flow site `27090`
- The updated completeness statistics were displayed correctly
- The valid donor import and imputation workflow completed without errors
- Flow statistics were calculated successfully using a 6-month window width and a 6-month window step
- The calculation completed in approximately 37 seconds
- The time-varying results table contained 693 entries
- Pagination, copy and download controls were available
- Switching between the `Time-varying` and `Long-term` result displays was almost immediate

---

### 5.5 Join HE Data

#### Purpose

Allows users to pair processed biology and flow data, apply selected time lags and review the resulting joined hydroecological dataset.

#### Main Functions

* Allows users to select one or more time lags
* Allows users to select a data-joining method
* Pairs biology data with flow data
* Displays the joined hydroecological dataset
* Displays pairwise correlations for the joined data
* Displays the historical coverage of the paired datasets
* Allows users to switch between the joined data, pairwise correlations and historical coverage tabs

#### User Inputs

* Processed biology data
* Processed flow data
* Selected time lags
* Selected join method
* Selection of the `Pair biology and flow data` button

#### Outputs

* Joined biology and flow dataset
* Pairwise correlation results
* Historical data coverage information
* Validation and status messages

#### Initial Status

* The page loads successfully
* The `View joined data`, `View pairwise correlations` and `View historical coverage` tabs can be opened and switched between successfully
* No errors occur when switching between the result tabs
* The lag-selection control can be opened and used successfully
* The join-method control can be opened and changed successfully
* The `Pair biology and flow data` button is responsive
* A `Please add metadata` validation message is displayed when the required metadata has not been entered
* The result areas are empty before biology and flow data have been processed and paired
* The end-to-end data-pairing function and generated results have not yet been fully tested
- Joined data were generated successfully using lag `0` and join method `A`
- The joined-data table contained 580 entries
- A warning identified biology samples that occurred before the earliest available flow period
- Further inspection is required to confirm whether unmatched early samples contain missing flow-statistic values
- Biology and flow data were paired successfully using lag `0` and join method `A`
- The pairing completed in approximately 3 seconds
- The joined-data table contained 580 entries
- The pairwise-correlation visualisation was generated successfully
- The historical-coverage visualisation was generated successfully
- A warning was displayed because some biology samples preceded the earliest available flow period
- No errors occurred when switching between the three result views

---

### 5.6 HEV

#### Purpose

Allows users to create and download an HEV plot using a selected biomonitoring index, flow metric and date range.

#### Main Functions

* Allows users to select a biomonitoring index
* Allows users to select a flow metric
* Allows users to define the date range used in the analysis
* Creates an HEV plot from the selected variables
* Displays the generated plot
* Allows users to select a download file format
* Allows users to download the generated plot

#### User Inputs

* Joined hydroecological data from the previous processing stages
* Selected biomonitoring index
* Selected flow metric
* Selected start year
* Selected end year
* Selection of the `Create HEV plot` button
* Selected download format

#### Outputs

* Generated HEV plot
* Downloadable plot file
* Plot-generation or validation messages

#### Initial Status

* The page loads successfully
* The biomonitoring-index selector can be opened and changed successfully
* The flow-metric selector can be opened and changed successfully
* The date-range controls can be adjusted successfully
* The `Create HEV plot` button is responsive
* The download-format selector can be opened and changed successfully
* The download button is displayed and responsive
* No errors occur when interacting with the controls
* The plot area is empty before the required data have been prepared and the plot has been generated
* Plot generation, result accuracy and file download have not yet been fully tested with processed data
- The site, biomonitoring-index, flow-metric and date-range controls are displayed
- The plot area fails to render because the required `ggnewscale` package is not installed
- A raw R package error is displayed directly to the user
- HEV plot generation and download functionality cannot currently be tested
- HEV plot generation initially failed because the `ggnewscale` package was not installed in the local R environment
- After installing `ggnewscale`, the HEV plot was generated successfully
- The site, biomonitoring-index, flow-metric and date-range controls functioned correctly
- The generated plot displayed the selected biological index and flow metric over time
- The generated HEV plot was downloaded successfully in PDF, PNG and JPEG formats
- All downloaded files opened successfully
- The downloaded plots contained complete axes, legends and plotted data
- No blank output, clipping or missing labels were observed

---

### 5.7 Links

#### Purpose

Provides users with direct access to external HE Toolkit resources and documentation.

#### Main Functions

* Displays a dropdown menu containing external HE Toolkit links
* Provides access to the HE Toolkit GitHub repository
* Provides access to the HE Toolkit documentation website
* Opens the selected external resource in the browser

#### User Inputs

* Selection of the `Links` dropdown menu
* Selection of one of the available external links

#### Outputs

* HE Toolkit GitHub repository
* HE Toolkit documentation website

#### Initial Status

* The `Links` dropdown menu opens successfully
* The `HE Toolkit GitHub site` link can be selected successfully
* The `HE Toolkit website` link can be selected successfully
* Both links open the expected external resources
* No errors occur when opening the links

## 6. Audit Findings

### AUD-01: Invalid Donor Input Causes Persistent Global Loading State

* **Area:** Process flow data
* **Severity:** High
* **Status:** Confirmed and reproducible

#### Description

The application does not correctly validate invalid text entered into the additional flow donor-sites field. The supplied text is passed to `fread()` and interpreted as a file path.

When the file cannot be found or read, the raw backend error is displayed directly in the interface. The application then remains in a global loading state for more than ten minutes.

Although users can still navigate to other pages, controls on those pages may not respond normally and prerequisite-data validation messages may be delayed or blocked.

#### Steps to Reproduce

1. Start the dashboard locally.
2. Open the `Process flow data` page.
3. Enter invalid free text into the `Paste additional flow donor sites here` field.
4. Select `Import additional donor flow data`.
5. Navigate to the `Process invertebrate data` page.
6. Select `Run RICT predictions` or `Calculate O:E ratios`.
7. Observe that the application remains in a global loading state and the expected missing-data validation does not appear normally.

#### Expected Result

* The donor-site input should be validated before processing.
* Invalid input should produce a clear user-facing validation message.
* The application should immediately return to an idle state.
* Raw backend errors and local file-system paths should not be displayed.
* Other pages and controls should remain usable.

#### Actual Result

* The invalid input is passed to `fread()`.
* A file-not-found or unreadable-file error is produced.
* The raw error message and local working-directory path are displayed in the interface.
* A global loading overlay remains active for more than ten minutes.
* Other page controls and validation messages do not respond normally.
* The application must be stopped and restarted to recover.

#### User Impact

* Users may believe that the application has frozen.
* Users may repeatedly select buttons and trigger additional processing attempts.
* The current dashboard session becomes effectively unusable.
* Technical error details are exposed to non-technical users.
* Local file-system information is unnecessarily displayed.

#### Recommendation

* Validate donor-site input before calling `fread()`.
* Reject empty, malformed or unsupported input immediately.
* Display a concise and user-friendly validation message.
* Wrap import operations in structured error handling.
* Ensure the application always exits the busy state after an error.
* Disable processing buttons until prerequisite data are available.
* Do not expose raw errors or local file-system paths in the user interface.

---

### AUD-02: Missing Local Dependency Prevents HEV Plot Generation

- **Area:** HEV / Environment setup
- **Severity:** High
- **Status:** Reproduced and resolved locally after dependency installation

#### Description

The HEV page requires the `ggnewscale` package. The dependency is referenced in `global.R` and declared in `manifest.json`, but it was not installed in the local R environment after the repository was cloned.

As a result, the HEV plot could not be rendered and a raw R package error was displayed directly in the dashboard.

#### Recommendation

- Provide clear local dependency-installation instructions.
- Consider providing a reproducible dependency file such as `renv.lock`.
- Check required packages when the application starts.
- Replace raw R dependency errors with user-friendly setup guidance.

#### Re-test Result

After installing the declared `ggnewscale` dependency and restarting the application, the HEV plot was generated successfully. This confirms that the failure was caused by incomplete local dependency setup rather than the HEV plotting workflow itself.

## 7. Functional Walkthrough

This section records an end-to-end walkthrough of the dashboard using valid demo data. The purpose is to confirm whether a user can complete the expected hydroecological workflow successfully.

### 7.1 Test Data

- **Metadata source:** Demo metadata provided on the Introduction page
- **Metadata status:** Successfully imported and displayed
- **Biology data:** Successfully imported using the default date range from 1990-01-01 to 2026-06-20
- **Biology import time:** Approximately 7 seconds
- **Environmental data:** Successfully imported and displayed
- **Environmental data import time:** Approximately 1 second
- **Flow data:** Successfully imported using the default date range from 1990-01-01 to 2026-06-20
- **Flow data import time:** Approximately 6 seconds
- **Test date:** 20 June 2026

### 7.2 Workflow Results

| Step | Page | Action | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| 1 | Import datasets | Paste valid demo metadata | Metadata is accepted and site information is displayed | | PASS |
| 2 | Import datasets | Import biology data using the default date range from 1990-01-01 to 2026-06-20 | Biology data are imported and displayed | Biology data were imported successfully in approximately 7 seconds and displayed in the invertebrate data preview table. A loading indicator was shown during processing and disappeared after completion. | Pass |
| 3 | Import datasets | Import environmental data | Environmental data are imported and displayed | Environmental data were imported successfully in approximately 1 second and displayed in the environmental data preview table. A loading indicator appeared during the import, but it was easy to miss because the operation completed quickly and the indicator was visually unobtrusive. | Pass |
| 4 | Import datasets | Import flow data using the default date range from 1990-01-01 to 2026-06-20 | Flow data are imported and displayed | Flow data were imported successfully in approximately 6 seconds. Flow completeness statistics were displayed in the `View flow data` tab, including missing-value counts, proportions and gap information for each flow site. | Pass |
| 5 | Import datasets | Switch between environmental `Data` and `PCA`, and flow `Completeness stats` and `Heatmap` views | Each display mode is shown correctly | All four display modes opened successfully without errors | Pass |
| 6 | Import datasets | View imported sites on the map and test the map controls | Imported sites are displayed and the map can be moved and zoomed | The site map loaded successfully with site markers displayed. The map could be moved using the mouse and zoomed using both the mouse wheel and the `+` and `-` controls. No noticeable loading delay or errors occurred. | Pass |
| 7 | Process invertebrate data | Run RICT predictions using the imported biology and environmental data | RICT prediction results are generated and displayed | RICT predictions were generated successfully in approximately 2 seconds. A results table containing 39 entries was displayed, with pagination, copy and download controls available. | Pass |
| 8 | Process invertebrate data | Calculate O:E ratios using the imported data and generated RICT predictions | O:E ratio results are generated and displayed | O:E ratio results were generated successfully in less than 1 second. A results table containing 580 entries was displayed, with pagination, copy and download controls available. | Pass |
| 9 | Process flow data | Impute missing flow data using the provided donor mapping | Missing flow values are imputed and the updated completeness statistics are displayed | The imputation completed in approximately 3 seconds. Missing values for flow site `28023` were reduced from 2148 to 628 using donor station `28043`. Missing values for flow site `27090` remained unchanged because its mapped donor station `27034` had not yet been imported. The Heatmap view loaded successfully in approximately 2 seconds. | Partial Pass |
| 10 | Process flow data | Import the additional donor flow site using the demo input | Additional donor flow data are imported and a success message is displayed | Additional flow data for donor site `27034` were imported successfully. A confirmation message appeared almost immediately after selecting `Import additional donor flow data`. | Pass |
| 11 | Process flow data | Re-run flow imputation after importing donor site `27034` | Missing values for flow site `27090` are reduced using the newly imported donor data | The imputation completed successfully. Missing values for flow site `27090` were reduced from 1709 to 628, the number of gaps was reduced from 2 to 1, and the largest gap was reduced from 1081 to 628. The resulting completeness statistics matched those of donor site `27034`. | Pass |
| 12 | Process flow data | Calculate flow statistics using the default window width and window step of 6 months | Flow statistics are calculated and displayed in both time-varying and long-term views | Flow statistics were generated successfully in approximately 37 seconds. The time-varying results table contained 693 entries and provided pagination, copy and download controls. Switching between the `Time-varying` and `Long-term` display modes was almost immediate. | Pass |
| 13 | Join HE data | Pair biology and flow data using lag `0` and join method `A` | Joined hydroecological data, pairwise correlations and historical coverage are generated | The pairing process completed successfully in approximately 3 seconds. A warning indicated that some biology samples preceded the earliest available flow period. The joined-data table contained 580 entries, and both the pairwise-correlation matrix and historical-coverage visualisation were generated successfully without errors. | Pass with warning |
| 14 | HEV | Open the HEV page before installing all local dependencies | HEV page loads and the plot can be created | Plot generation failed because `ggnewscale` was not installed in the local R environment. A raw R error was displayed. | Fail |
| 15 | HEV | Re-test HEV plot generation after installing the `ggnewscale` package | An HEV plot is generated using the selected site, biomonitoring index, flow metric and date range | The HEV plot was generated successfully for site `291` using biomonitoring index `WHPT_ASPT_OE`, flow metric `Q5` and the default date range after the missing `ggnewscale` dependency was installed. | Pass |
| 16 | HEV | Download the generated HEV plot in PDF, PNG and JPEG formats | Each selected file format is downloaded and contains a complete, readable version of the generated plot | The HEV plot was downloaded and opened successfully in PDF, PNG and JPEG formats. All three files contained the complete plot, including both axes, data points, the Q5 flow line and the seasonal legends. No blank output, clipping or missing labels were observed. | Pass |

### 7.3 Usability Observations

- The dashboard displays a loading indicator during environmental data import. However, because the indicator is located in the lower-left corner and the operation completes quickly, users may not notice it.
- Calculating flow statistics took approximately 37 seconds. A clear progress message or estimated processing status could help reassure users during longer calculations.
- The warning about biology samples preceding the available flow period was useful, but the long comma-separated list of affected site IDs was difficult to read because of poor line wrapping.

## 8. Usability Observations

- The loading indicator is located in the lower-left corner and may be easy to miss during short operations.
- Calculating flow statistics took approximately 37 seconds. More visible progress feedback would reassure users that processing is continuing.
- The warning listing sites with incomplete historical coverage was useful, but the long comma-separated list was difficult to read.
- Several pages display large empty areas before data are imported or processed.

## 9. Priority Recommendations

### High Priority

1. Validate donor-site input before passing it to `fread()`.
2. Ensure the application always exits the loading state after an error.
3. Replace raw R errors and local file paths with user-friendly messages.
4. Provide clear instructions for installing or restoring required R dependencies.

### Medium Priority

1. Improve progress feedback for longer calculations.
2. Disable processing buttons until prerequisite data are available.
3. Improve the formatting of warnings containing long lists of site IDs.

### Low Priority

1. Make the loading indicator more visually noticeable.
2. Add clearer placeholder guidance to empty result areas.

## 10. Summary

The existing HE Toolkit Dashboard supports the complete core workflow from metadata and data import through invertebrate processing, flow processing, data joining, HEV plot generation and plot download.

Using the provided demo data, the main workflow was completed successfully. Biology, environmental and flow data were imported, RICT predictions and O:E ratios were generated, missing flow data were imputed, flow statistics were calculated, biology and flow data were joined, and an HEV plot was generated and downloaded in PDF, PNG and JPEG formats.

Two significant issues were identified. Invalid additional donor-site input can trigger a raw `fread()` error and leave the application in a persistent loading state. In addition, the HEV page initially failed when the required `ggnewscale` dependency was not installed locally, although the feature worked after the dependency was installed.

The highest-priority improvements are stronger input validation, safer error handling, clearer dependency setup instructions and more visible progress feedback.