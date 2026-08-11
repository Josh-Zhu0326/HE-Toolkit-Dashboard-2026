# Test Plan for Dashboard Improvement User Stories

## 1. Purpose

This test plan defines the manual tests required to verify the proposed HE Toolkit Dashboard improvements. The tests focus on workflow guidance, local file upload, Water Quality and RHS support, donor-site input validation, error recovery, user-friendly error messages, progress feedback, dependency setup, runtime-generated file management and empty-state guidance.

## 2. Test Scope

### Included

* Step-by-step workflow guidance
* Local file upload
* Water Quality data import or upload
* RHS data import or upload
* Donor-site input validation
* Error recovery after failed actions
* User-friendly error messages
* Progress feedback for long-running operations
* Dependency setup and missing-package handling
* Runtime-generated file management
* Empty-state guidance
* Regression testing of the existing demo workflow

### Not Included

* Full statistical validation of HE Toolkit algorithms
* Testing every possible biomonitoring index and flow metric combination
* Large-volume performance testing
* Formal accessibility testing
* Automated test implementation

## 3. Test Environment

* **Deployment type:** Local deployment
* **Application launch method:** R Shiny application running locally
* **Browser:** Google Chrome
* **Operating system:** Windows 11
* **Test data:**

  * Demo metadata provided by the dashboard
  * Valid local metadata CSV
  * Valid local biology CSV
  * Valid local environmental CSV
  * Valid local flow CSV
  * Valid Water Quality CSV
  * Valid RHS CSV
  * CSV file with missing required columns
  * Unsupported file type, such as `.txt` or `.pdf`
  * Valid donor-site input
  * Invalid donor-site input

## 4. Test Status Definitions

| Status     | Meaning                                                                                             |
| ---------- | --------------------------------------------------------------------------------------------------- |
| Pass       | The test behaves as expected.                                                                       |
| Fail       | The test does not behave as expected and requires investigation.                                    |
| Blocked    | The test cannot be executed because the feature is not implemented or the environment is not ready. |
| Not tested | The test has not yet been executed.                                                                 |

---

# 5. Test Cases

## US-01: Improve Step-by-Step Workflow Guidance

### TP-01: Check Main Page Guidance

| Field              | Details                                                                                                                                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Related User Story | US-01                                                                                                                                                                                                                          |
| Priority           | High                                                                                                                                                                                                                           |
| Objective          | Confirm that each main page briefly explains its purpose and required prerequisite data.                                                                                                                                       |
| Preconditions      | Dashboard is running locally.                                                                                                                                                                                                  |
| Steps              | 1. Open the dashboard. 2. Visit each main page: Introduction, Import datasets, Process invertebrate data, Process flow data, Join HE data and HEV. 3. Check whether each page explains its purpose and required previous step. |
| Expected Result    | Each page includes clear guidance about what the page is for and what data or previous step is required.                                                                                                                       |
| Status             | Not tested                                                                                                                                                                                                                     |

### TP-02: Check Overall Workflow Order

| Field              | Details                                                                                                                                     |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-01                                                                                                                                       |
| Priority           | Medium                                                                                                                                      |
| Objective          | Confirm that users can understand the workflow order from data import to HEV plot generation.                                               |
| Preconditions      | Dashboard is running locally.                                                                                                               |
| Steps              | 1. Review the navigation structure. 2. Review any workflow guidance on the Introduction page. 3. Check whether the order of steps is clear. |
| Expected Result    | The dashboard makes the workflow order clear: import data, process data, join data, generate HEV plot.                                      |
| Status             | Not tested                                                                                                                                  |

---

## US-02: Add Local File Upload Page

### TP-03: Upload Valid Local Data File

| Field              | Details                                                                                |
| ------------------ | -------------------------------------------------------------------------------------- |
| Related User Story | US-02                                                                                  |
| Priority           | High                                                                                   |
| Objective          | Confirm that users can upload a supported local data file.                             |
| Preconditions      | Local file upload page or section has been implemented. A valid CSV file is available. |
| Steps              | 1. Open the local file upload page. 2. Upload a valid CSV file. 3. Confirm the upload. |
| Expected Result    | The file is accepted and displayed in a preview table.                                 |
| Status             | Blocked until upload feature is implemented                                            |

### TP-04: Reject Unsupported File Type

| Field              | Details                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Related User Story | US-02                                                                                                              |
| Priority           | High                                                                                                               |
| Objective          | Confirm that unsupported file types are rejected.                                                                  |
| Preconditions      | Local file upload page or section has been implemented. An unsupported file such as `.pdf` or `.txt` is available. |
| Steps              | 1. Open the local file upload page. 2. Upload an unsupported file type.                                            |
| Expected Result    | The file is rejected and a clear error message explains the supported file formats.                                |
| Status             | Blocked until upload feature is implemented                                                                        |

### TP-05: Reject File with Missing Required Columns

| Field              | Details                                                                                                        |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-02                                                                                                          |
| Priority           | High                                                                                                           |
| Objective          | Confirm that uploaded files with missing required columns are rejected.                                        |
| Preconditions      | Local file upload page or section has been implemented. A CSV file with missing required columns is available. |
| Steps              | 1. Upload a CSV file missing one or more required columns. 2. Review the validation message.                   |
| Expected Result    | The dashboard identifies the missing required columns and prevents the file from being used.                   |
| Status             | Blocked until upload feature is implemented                                                                    |

### TP-06: Use Uploaded Data in Later Workflow Stages

| Field              | Details                                                                                                                                              |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-02                                                                                                                                                |
| Priority           | High                                                                                                                                                 |
| Objective          | Confirm that uploaded data can be used by downstream dashboard pages where applicable.                                                               |
| Preconditions      | Valid local files have been uploaded successfully.                                                                                                   |
| Steps              | 1. Upload valid local metadata and data files. 2. Open the relevant downstream pages. 3. Attempt supported processing steps using the uploaded data. |
| Expected Result    | Uploaded data is available to later workflow stages and can be processed where the data format supports it.                                          |
| Status             | Blocked until upload feature is implemented                                                                                                          |

---

## US-03: Support Water Quality and RHS Data

### TP-07: Import or Upload Valid Water Quality Data

| Field              | Details                                                                                                        |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-03                                                                                                          |
| Priority           | High                                                                                                           |
| Objective          | Confirm that valid Water Quality data can be imported or uploaded and previewed.                               |
| Preconditions      | WQ data support has been implemented or confirmed. A valid WQ test file is available.                          |
| Steps              | 1. Open the relevant import or upload page. 2. Import or upload a valid WQ file. 3. Review the preview output. |
| Expected Result    | The WQ file is accepted and displayed in a readable preview table.                                             |
| Status             | Blocked until WQ support is implemented or confirmed                                                           |

### TP-08: Import or Upload Valid RHS Data

| Field              | Details                                                                                                         |
| ------------------ | --------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-03                                                                                                           |
| Priority           | High                                                                                                            |
| Objective          | Confirm that valid RHS data can be imported or uploaded and previewed.                                          |
| Preconditions      | RHS data support has been implemented or confirmed. A valid RHS test file is available.                         |
| Steps              | 1. Open the relevant import or upload page. 2. Import or upload a valid RHS file. 3. Review the preview output. |
| Expected Result    | The RHS file is accepted and displayed in a readable preview table.                                             |
| Status             | Blocked until RHS support is implemented or confirmed                                                           |

### TP-09: Reject Invalid WQ Data

| Field              | Details                                                                               |
| ------------------ | ------------------------------------------------------------------------------------- |
| Related User Story | US-03                                                                                 |
| Priority           | High                                                                                  |
| Objective          | Confirm that invalid or incomplete WQ files are rejected with a clear message.        |
| Preconditions      | WQ validation has been implemented. An invalid WQ test file is available.             |
| Steps              | 1. Upload or import an invalid WQ file. 2. Review the validation message.             |
| Expected Result    | The dashboard explains what is wrong with the WQ file and does not show raw R errors. |
| Status             | Blocked until WQ validation is implemented                                            |

### TP-10: Reject Invalid RHS Data

| Field              | Details                                                                                |
| ------------------ | -------------------------------------------------------------------------------------- |
| Related User Story | US-03                                                                                  |
| Priority           | High                                                                                   |
| Objective          | Confirm that invalid or incomplete RHS files are rejected with a clear message.        |
| Preconditions      | RHS validation has been implemented. An invalid RHS test file is available.            |
| Steps              | 1. Upload or import an invalid RHS file. 2. Review the validation message.             |
| Expected Result    | The dashboard explains what is wrong with the RHS file and does not show raw R errors. |
| Status             | Blocked until RHS validation is implemented                                            |

---

## US-04: Validate Donor-Site Input Before Processing

### TP-11: Reject Invalid Donor-Site Input

| Field              | Details                                                                                                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-04                                                                                                                                    |
| Priority           | High                                                                                                                                     |
| Objective          | Confirm that invalid donor-site input is rejected before processing starts.                                                              |
| Preconditions      | Dashboard is running locally. Flow data has been imported.                                                                               |
| Steps              | 1. Open Process flow data. 2. Enter invalid text into the additional donor-site input field. 3. Click Import additional donor flow data. |
| Expected Result    | A clear validation message is displayed. Processing does not start. No raw `fread()` error or local file path is shown.                  |
| Status             | Not tested                                                                                                                               |

### TP-12: Accept Valid Donor-Site Input

| Field              | Details                                                                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-04                                                                                                                                         |
| Priority           | High                                                                                                                                          |
| Objective          | Confirm that valid donor-site input is still accepted.                                                                                        |
| Preconditions      | Dashboard is running locally. Flow data has been imported.                                                                                    |
| Steps              | 1. Open Process flow data. 2. Enter valid additional donor-site input using the supported format. 3. Click Import additional donor flow data. |
| Expected Result    | The donor-site input is accepted and the additional donor flow data is imported successfully.                                                 |
| Status             | Not tested                                                                                                                                    |

---

## US-05: Prevent Persistent Loading After Errors

### TP-13: Loading State Clears After Invalid Input

| Field              | Details                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Related User Story | US-05                                                                                                              |
| Priority           | High                                                                                                               |
| Objective          | Confirm that the dashboard does not remain stuck in a loading state after invalid input.                           |
| Preconditions      | Dashboard is running locally.                                                                                      |
| Steps              | 1. Submit invalid donor-site input. 2. Observe the loading indicator. 3. Wait for the error or validation message. |
| Expected Result    | The loading state clears after the error or validation message appears. The dashboard remains usable.              |
| Status             | Not tested                                                                                                         |

### TP-14: Other Pages Remain Usable After Failed Action

| Field              | Details                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Related User Story | US-05                                                                                                              |
| Priority           | High                                                                                                               |
| Objective          | Confirm that one failed action does not block controls on other pages.                                             |
| Preconditions      | Dashboard is running locally.                                                                                      |
| Steps              | 1. Trigger a handled validation error. 2. Navigate to another page. 3. Try interacting with controls on that page. |
| Expected Result    | Other pages and controls remain usable after the failed action.                                                    |
| Status             | Not tested                                                                                                         |

### TP-15: Prevent Repeated Button Clicks During Processing

| Field              | Details                                                                                                                                 |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-05                                                                                                                                   |
| Priority           | Medium                                                                                                                                  |
| Objective          | Confirm that users cannot repeatedly trigger the same operation while it is already running.                                            |
| Preconditions      | Valid data is available.                                                                                                                |
| Steps              | 1. Start a longer operation, such as Calculate flow statistics. 2. Try clicking the same button repeatedly while processing is running. |
| Expected Result    | The button is disabled or repeated clicks are ignored until processing finishes.                                                        |
| Status             | Not tested                                                                                                                              |

---

## US-06: Replace Raw R Errors with User-Friendly Messages

### TP-16: Missing Data Shows Clear Message

| Field              | Details                                                                                 |
| ------------------ | --------------------------------------------------------------------------------------- |
| Related User Story | US-06                                                                                   |
| Priority           | High                                                                                    |
| Objective          | Confirm that missing required data produces a clear user-facing message.                |
| Preconditions      | Dashboard is running with no metadata or imported data.                                 |
| Steps              | 1. Open a processing page before importing required data. 2. Click a processing button. |
| Expected Result    | The dashboard explains which required data is missing. No raw R error is displayed.     |
| Status             | Not tested                                                                              |

### TP-17: Invalid Input Shows Clear Message

| Field              | Details                                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-06                                                                                                            |
| Priority           | High                                                                                                             |
| Objective          | Confirm that invalid input errors are shown in plain language.                                                   |
| Preconditions      | Dashboard is running locally.                                                                                    |
| Steps              | 1. Enter invalid input into a field with validation. 2. Submit the input.                                        |
| Expected Result    | The error message explains the expected format and does not show raw R errors, stack traces or local file paths. |
| Status             | Not tested                                                                                                       |

### TP-18: Missing Package Shows Setup Guidance

| Field              | Details                                                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-06, US-08                                                                                                                      |
| Priority           | Medium                                                                                                                            |
| Objective          | Confirm that missing dependencies are handled with clear setup guidance.                                                          |
| Preconditions      | A required package is missing, or the missing-package condition can be simulated.                                                 |
| Steps              | 1. Launch the dashboard with a required dependency missing. 2. Open the affected page or feature.                                 |
| Expected Result    | The dashboard shows a clear message explaining the missing package and how to install it. No raw package error appears in the UI. |
| Status             | Not tested                                                                                                                        |

---

## US-07: Improve Progress Feedback for Long Operations

### TP-19: Progress Feedback During Flow Statistics Calculation

| Field              | Details                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| Related User Story | US-07                                                                                                  |
| Priority           | High                                                                                                   |
| Objective          | Confirm that long-running operations show visible progress feedback.                                   |
| Preconditions      | Valid flow data is imported and ready for flow statistics calculation.                                 |
| Steps              | 1. Open Process flow data. 2. Click Calculate flow statistics. 3. Observe the UI during processing.    |
| Expected Result    | A visible loading or progress message appears and indicates that flow statistics are being calculated. |
| Status             | Not tested                                                                                             |

### TP-20: Button Disabled During Long Operation

| Field              | Details                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| Related User Story | US-07                                                                                                  |
| Priority           | Medium                                                                                                 |
| Objective          | Confirm that users cannot start the same long operation multiple times.                                |
| Preconditions      | Valid flow data is imported and ready for flow statistics calculation.                                 |
| Steps              | 1. Click Calculate flow statistics. 2. Try to click the same button again while processing is running. |
| Expected Result    | The button is disabled or repeated clicks are ignored until the operation finishes.                    |
| Status             | Not tested                                                                                             |

### TP-21: Completion, Warning or Error Message Appears

| Field              | Details                                                                              |
| ------------------ | ------------------------------------------------------------------------------------ |
| Related User Story | US-07                                                                                |
| Priority           | Medium                                                                               |
| Objective          | Confirm that users receive feedback after processing finishes.                       |
| Preconditions      | Valid data is available.                                                             |
| Steps              | 1. Run a long operation. 2. Wait until processing finishes.                          |
| Expected Result    | The user receives results, a completion message, a warning or a clear error message. |
| Status             | Not tested                                                                           |

---

## US-08: Improve Dependency Setup and Missing-Package Handling

### TP-22: Setup Instructions Explain Package Installation

| Field              | Details                                                                           |
| ------------------ | --------------------------------------------------------------------------------- |
| Related User Story | US-08                                                                             |
| Priority           | High                                                                              |
| Objective          | Confirm that setup instructions explain how to install required R packages.       |
| Preconditions      | README or setup documentation has been updated.                                   |
| Steps              | 1. Open README or setup documentation. 2. Review the local setup section.         |
| Expected Result    | The documentation clearly explains how to install or restore required R packages. |
| Status             | Not tested                                                                        |

### TP-23: Missing Packages Are Detected Before Feature Failure

| Field              | Details                                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-08                                                                                                                           |
| Priority           | Medium                                                                                                                          |
| Objective          | Confirm that important missing packages are detected before affected features fail.                                             |
| Preconditions      | Dependency check has been implemented.                                                                                          |
| Steps              | 1. Start the dashboard in an environment with a missing required package. 2. Observe startup or page-level dependency messages. |
| Expected Result    | The missing package is detected and clear installation guidance is shown before the feature fails with a raw error.             |
| Status             | Not tested                                                                                                                      |

### TP-24: HEV Works After Dependencies Are Installed

| Field              | Details                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| Related User Story | US-08                                                                                                  |
| Priority           | High                                                                                                   |
| Objective          | Confirm that HEV plot generation works after required dependencies are installed.                      |
| Preconditions      | All required packages are installed. Joined data is available.                                         |
| Steps              | 1. Open HEV. 2. Select a site, biomonitoring index, flow metric and date range. 3. Create an HEV plot. |
| Expected Result    | The HEV plot is generated successfully.                                                                |
| Status             | Not tested                                                                                             |

---

## US-09: Manage Runtime-Generated Files Safely

### TP-25: Runtime CSV Files Are Ignored by Git

| Field              | Details                                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Related User Story | US-09                                                                                                               |
| Priority           | High                                                                                                                |
| Objective          | Confirm that runtime-generated flow CSV files are not shown as files ready to commit.                               |
| Preconditions      | `.gitignore` has been updated.                                                                                      |
| Steps              | 1. Run the dashboard workflow that generates site-level flow CSV files. 2. Stop the dashboard. 3. Run `git status`. |
| Expected Result    | Runtime-generated numeric CSV files do not appear as untracked files.                                               |
| Status             | Not tested                                                                                                          |

### TP-26: Runtime Imputation Images Are Ignored by Git

| Field              | Details                                                                          |
| ------------------ | -------------------------------------------------------------------------------- |
| Related User Story | US-09                                                                            |
| Priority           | High                                                                             |
| Objective          | Confirm that generated imputation images are not shown as files ready to commit. |
| Preconditions      | `.gitignore` has been updated.                                                   |
| Steps              | 1. Run flow imputation. 2. Stop the dashboard. 3. Run `git status`.              |
| Expected Result    | Files such as `*_Imputed_Values.png` do not appear as untracked files.           |
| Status             | Not tested                                                                       |

---

## US-10: Improve Empty-State Guidance

### TP-27: Empty Tables Show Guidance

| Field              | Details                                                                                   |
| ------------------ | ----------------------------------------------------------------------------------------- |
| Related User Story | US-10                                                                                     |
| Priority           | Medium                                                                                    |
| Objective          | Confirm that empty tables explain why no data is shown.                                   |
| Preconditions      | Dashboard is running with no data imported.                                               |
| Steps              | 1. Open table views before importing or processing data. 2. Review the empty table areas. |
| Expected Result    | Empty tables show a short message explaining what prerequisite action is required.        |
| Status             | Not tested                                                                                |

### TP-28: Empty Plot Areas Show Guidance

| Field              | Details                                                                               |
| ------------------ | ------------------------------------------------------------------------------------- |
| Related User Story | US-10                                                                                 |
| Priority           | Medium                                                                                |
| Objective          | Confirm that empty plot areas explain why no plot is shown.                           |
| Preconditions      | Dashboard is running before required data has been prepared.                          |
| Steps              | 1. Open HEV before joined data is available. 2. Review the plot area.                 |
| Expected Result    | The empty plot area explains which action is required before a plot can be generated. |
| Status             | Not tested                                                                            |

---

# 6. Regression Test: Existing Demo Workflow

After implementing the improvements, the original successful demo workflow should be retested to confirm that existing functionality has not been broken.

| Step | Action                                  | Expected Result                                                 | Status     |
| ---- | --------------------------------------- | --------------------------------------------------------------- | ---------- |
| 1    | Paste demo metadata                     | Metadata preview table is displayed                             | Not tested |
| 2    | Import biology data                     | Invertebrate data is displayed                                  | Not tested |
| 3    | Import environmental data               | Environmental data and PCA views are displayed                  | Not tested |
| 4    | Import flow data                        | Flow completeness stats and heatmap are displayed               | Not tested |
| 5    | Run RICT predictions                    | RICT prediction results are displayed                           | Not tested |
| 6    | Calculate O:E ratios                    | O:E ratio results are displayed                                 | Not tested |
| 7    | Import valid additional donor flow data | Donor flow data is imported                                     | Not tested |
| 8    | Impute missing flow data                | Missing values are reduced where valid donor data exists        | Not tested |
| 9    | Calculate flow statistics               | Time-varying and long-term flow statistics are displayed        | Not tested |
| 10   | Pair biology and flow data              | Joined data, correlations and historical coverage are displayed | Not tested |
| 11   | Create HEV plot                         | HEV plot is generated                                           | Not tested |
| 12   | Download HEV plot                       | PDF, PNG and JPEG downloads are readable                        | Not tested |

