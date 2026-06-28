# Hydroecology Toolkit Dashboard

## High-Level Test Plan

| Document Information | Details                        |
| -------------------- | ------------------------------ |
| Project              | Hydroecology Toolkit Dashboard |
| Document Type        | High-Level Test Plan           |
| Version              | 0.1                            |
| Status               | Draft                          |
| Author               | Benyu Zhu                      |
| Author Role          | Tester / QA Engineer           |
| Last Updated         | 2026-06-29                     |

---

## 1. Purpose

This document defines the high-level testing approach for the Hydroecology Toolkit Dashboard.

The purpose of testing is to verify that the dashboard is functionally correct, stable, understandable, and suitable for Environment Agency and Defra users who understand environmental data and statistical concepts but may have limited or no programming experience.

Testing will focus particularly on whether the dashboard supports the final **Option 3: Task-Oriented Workflow**.

Users should be able to select any available task, provide the inputs required by that task, and obtain the corresponding output without being required to follow the order of the underlying R functions.

The testing process will also evaluate whether:

* each task can be accessed and used independently;
* local files and existing site data are clearly distinguished;
* data requirements are explained before analysis begins;
* warnings and error messages are understandable to non-programming users;
* the outputs produced by the dashboard are accurate and meaningful;
* users can recover from invalid input without restarting the entire workflow.

---

## 2. System Overview

The Hydroecology Toolkit Dashboard provides a graphical interface for hydroecological data preparation, data-quality checking, missing flow-data processing, biological and flow analysis, HEV visualisation, and report export.

The final dashboard design uses **Option 3: Task-Oriented Workflow**.

Instead of requiring users to follow the order of the underlying R functions, the dashboard is organised around the goals that users want to achieve.

Users begin by selecting a task from the dashboard task-selection page.

The main task options are:

1. Prepare Data
2. Check Data Quality
3. Fill Missing Flow Data
4. Explore Biology–Flow Relationships
5. Create HEV Plot
6. Export Report

Each task represents a user goal and produces a meaningful task-specific output.

| Task                               | Main Inputs                                                  | Example Outputs                                              |
| ---------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Prepare Data                       | Metadata, biological data, environmental data, and flow data | A structured and prepared dataset                            |
| Check Data Quality                 | Existing site data or uploaded local files                   | Missing-value results, site map, and completeness statistics |
| Fill Missing Flow Data             | Flow data and relevant donor-site information                | Imputed flow data and donor-site summary                     |
| Explore Biology–Flow Relationships | Biological data and flow data                                | Joined data, correlations, and historical coverage           |
| Create HEV Plot                    | Data required for HEV visualisation                          | HEV plots and related visual outputs                         |
| Export Report                      | Available tables, datasets, analysis results, and plots      | Downloadable tables, plots, datasets, or reports             |

Users may enter any task directly when they have the data required by that task.

They are not required to:

* complete tasks from left to right;
* complete every available task;
* execute unrelated tasks first;
* understand the underlying sequence of R functions.

Each task should explain:

* what the task is used for;
* which inputs are required;
* which inputs are optional;
* which data sources are available;
* which file formats are accepted;
* what output will be produced;
* what the user should do when an input is missing or invalid.

The underlying R functions, processing sequence, internal object names, and advanced implementation details should be hidden from ordinary users.

---

## 3. Confirmed Client Requirements

### 3.1 Task-Oriented Workflow

The final dashboard design will use **Option 3: Task-Oriented Workflow**.

The dashboard will be organised around user tasks rather than the technical order of the underlying R functions.

Users should be able to select any task directly from the task-selection page.

Each task should:

* have a clear and meaningful name;
* explain its purpose;
* identify its required inputs;
* identify optional inputs where applicable;
* allow users to provide suitable data;
* validate the provided data before processing;
* produce a task-specific output;
* allow users to return to the task-selection page;
* allow users to continue to another task where appropriate.

The dashboard should not force users to complete unrelated tasks before accessing the task they need.

### 3.2 Target Users

The primary users of the dashboard are expected to include staff from the Environment Agency and Defra.

These users are expected to:

* understand environmental data;
* understand relevant statistical concepts;
* understand the purpose of hydroecological analysis;
* be able to interpret tables, charts, correlations, and summary statistics;
* have limited or no programming experience;
* have limited or no experience using R.

The dashboard should therefore allow users to apply their environmental and statistical knowledge without requiring them to write code or understand the internal R implementation.

### 3.3 User-Readable Language

All user-facing content should be written in language that Environment Agency and Defra users can understand.

This requirement applies to:

* task names;
* page instructions;
* field labels;
* help text;
* file requirements;
* validation messages;
* warnings;
* error messages;
* output descriptions;
* download instructions.

The dashboard should not display unhandled R errors, internal object names, R function names, stack traces, or other programming-specific messages to ordinary users.

A useful validation or error message should explain:

1. what happened;
2. which file, field, or input is affected;
3. what the user needs to do next.

For example, the dashboard should display:

> The uploaded flow file does not contain the required `site_id` column. Add a site identifier for each record and upload the file again.

It should not display:

> Error in `select()`: Can't select columns that don't exist.

Statistical and hydroecological terminology may be used because the intended users understand the subject area. However, unfamiliar terms should be supported by short explanations, examples, or tooltips where necessary.

### 3.4 Existing Site Data and Local Files

Existing site data and local files are different data sources and should be presented as clearly separate input options.

Where relevant, a task may allow users to choose between:

* existing site data available through the dashboard;
* files stored locally on the user's computer.

Local-file input may require:

* a separate local-file input page; or
* a clearly separated local-file section within the selected task.

The local-file input interface should explain:

* which files are required;
* which files are optional;
* accepted file formats;
* required column names;
* accepted date formats;
* accepted data types;
* required measurement units;
* how missing values should be represented;
* how multiple related files are matched;
* any relevant file-size limits.

### 3.5 File Templates

Where a defined file structure is required, the dashboard should provide downloadable templates.

Templates should include:

* required column names;
* example values;
* accepted data types;
* required and optional fields;
* accepted date formats;
* accepted measurement units;
* guidance on representing missing values;
* short descriptions of each field.

Different templates may be required for different types of input, such as:

* site data;
* biological data;
* environmental data;
* flow data;
* donor-site data;
* HEV input data.

The final list of templates and exact field requirements will be confirmed when the input requirements for each task have been fully defined.

---

## 4. Test Objectives

The main objectives of testing are to verify that:

* the dashboard starts successfully;
* the task-selection page loads correctly;
* all agreed task options are displayed;
* each task can be accessed directly;
* users are not required to complete unrelated tasks first;
* each task clearly explains its purpose;
* each task clearly identifies required and optional inputs;
* users can distinguish between existing site data and local files;
* local-file requirements are available before upload;
* downloadable templates match the dashboard's actual validation rules;
* valid data are accepted and processed correctly;
* invalid or incomplete data produce clear validation messages;
* validation messages identify the affected file or field;
* validation messages explain how the user can correct the problem;
* unhandled R errors are not shown to ordinary users;
* users can correct invalid input without losing unrelated valid inputs;
* task outputs are accurate;
* data transferred between relevant tasks remain consistent;
* users can return to the task-selection page;
* users can select another task without restarting the dashboard;
* outputs are updated, cleared, or marked as outdated when their source data change;
* users can export available partial or complete results;
* the dashboard remains stable when invalid input is provided;
* target users can complete tasks without programming knowledge.

---

## 5. Test Scope

### 5.1 In Scope

The following areas are included in the current testing scope:

* dashboard startup;
* home page and task-selection page;
* task names and task descriptions;
* direct access to each task;
* navigation between tasks;
* returning to the task-selection page;
* Prepare Data functionality;
* Check Data Quality functionality;
* Fill Missing Flow Data functionality;
* Explore Biology–Flow Relationships functionality;
* Create HEV Plot functionality;
* Export Report functionality;
* existing site-data selection;
* local-file input;
* separation of site data and local files;
* file-format guidance;
* downloadable file templates;
* required and optional field descriptions;
* file upload;
* file readability checks;
* required-column validation;
* data-type validation;
* date-format validation;
* missing-value validation;
* measurement-unit validation where applicable;
* compatibility between related files;
* data processing;
* task-specific calculations;
* table generation;
* plot generation;
* result export;
* partial-result export;
* error handling;
* user-readable warnings;
* user-readable validation messages;
* recovery from invalid input;
* data sharing between relevant tasks;
* outdated-result handling;
* non-linear workflow testing;
* end-to-end workflow testing;
* regression testing;
* basic browser compatibility;
* basic performance testing;
* usability evaluation;
* user acceptance testing.

### 5.2 Out of Scope

The following areas are outside the scope of the current project phase:

* complete unit testing of every function in the underlying R package;
* testing functions that are not included in the agreed dashboard scope;
* Environment Agency production-server deployment testing;
* Defra production-server deployment testing;
* penetration testing;
* specialist cybersecurity testing;
* high-volume enterprise load testing;
* testing the internal behaviour of third-party software;
* testing external datasets that the project team is not authorised to access;
* formal accessibility certification unless separately agreed.

These areas may be considered during future development, deployment, or maintenance phases.

---

## 6. Test Items

### 6.1 Dashboard Startup

Testing will verify that:

* the application starts successfully;
* the home page loads;
* no blocking error is displayed;
* the agreed task options are visible;
* the R console does not contain an error that prevents use of the application.

### 6.2 Task-Selection Page

Testing will verify that:

* each task is displayed clearly;
* task names match the agreed workflow;
* each task includes a short and understandable description;
* users can identify which task matches their goal;
* selecting a task opens the correct page;
* users can return to the task-selection page.

### 6.3 Prepare Data

Testing will verify that:

* the task can be accessed directly;
* required data inputs are clearly identified;
* metadata, biological data, environmental data, and flow data are handled correctly;
* valid files can be uploaded;
* invalid files are rejected clearly;
* prepared data use the expected structure;
* the prepared dataset can be downloaded or used by another relevant task;
* users do not need to understand the underlying R preparation functions.

### 6.4 Check Data Quality

Testing will verify that:

* the task can be accessed directly;
* users can select existing site data;
* users can upload local files where supported;
* missing values are detected;
* completeness statistics are correct;
* site information is displayed correctly;
* site maps are generated correctly where applicable;
* quality-checking results are explained clearly;
* quality-checking results can be exported.

### 6.5 Fill Missing Flow Data

Testing will verify that:

* the task can be accessed directly;
* required flow-data inputs are explained;
* donor-site requirements are explained;
* valid donor-site selections are accepted;
* invalid donor-site selections are rejected clearly;
* missing flow values are calculated correctly;
* imputed values can be distinguished from original values;
* an imputed flow dataset is produced;
* donor-site information is included in the output;
* the output can be downloaded or used by another relevant task.

### 6.6 Explore Biology–Flow Relationships

Testing will verify that:

* the task can be accessed directly;
* biological and flow-data requirements are explained;
* compatible datasets are joined correctly;
* incompatible datasets are identified;
* correlations are calculated correctly;
* historical coverage is displayed correctly;
* changes to input data or parameters update the results;
* outputs can be downloaded or used in a report.

### 6.7 Create HEV Plot

Testing will verify that:

* the task can be accessed directly;
* the required HEV inputs are explained;
* valid data produce the expected visualisation;
* invalid inputs produce clear messages;
* plot titles are correct;
* axis labels are correct;
* legends are correct;
* plotted values are accurate;
* changes to data or parameters update the plot;
* plots can be downloaded;
* plots can be included in an exported report.

### 6.8 Export Report

Testing will verify that:

* the task can be accessed directly;
* available results are listed clearly;
* users can select which results to export;
* users are not required to complete every task before exporting;
* only available and selected results are exported;
* unavailable results are not presented as completed;
* exported tables match the dashboard results;
* exported plots match the dashboard results;
* exported datasets match the current selected data;
* outdated results are not exported without a clear warning;
* the export action is disabled or explained clearly when no results are available.

### 6.9 Existing Site Data

Testing will verify that:

* existing site data are clearly labelled;
* site data are not confused with local files;
* available sites can be searched or selected where applicable;
* the selected site is displayed clearly;
* the source of the selected data is visible;
* users can change the selected site;
* related results update when the selected site changes.

### 6.10 Local-File Input

Testing will verify that:

* local-file input is clearly separated from existing site data;
* upload instructions are available before upload;
* required files are identified;
* optional files are identified;
* accepted file formats are stated;
* required columns are stated;
* date formats are stated;
* data types are stated;
* measurement units are stated where applicable;
* missing-value conventions are stated;
* users can download the relevant template;
* the official template is accepted when valid data are entered;
* invalid files are identified before analysis begins;
* replacing an invalid file does not unnecessarily remove other valid files.

### 6.11 User-Facing Messages

Testing will verify that:

* messages use language understandable to the intended users;
* messages do not expose unhandled R errors;
* the affected file or field is identified;
* the cause of the problem is explained;
* the required corrective action is explained;
* warnings are distinguishable from blocking errors;
* successful actions are confirmed clearly;
* technical terms are explained where necessary.

---

## 7. Test Approach

### 7.1 Requirement Review

Before formal test execution, the project team will review:

* the agreed workflow;
* task definitions;
* input requirements;
* output requirements;
* file-format requirements;
* acceptance criteria;
* client feedback.

Any unclear requirement should be recorded and confirmed before the related result is treated as pass or fail.

### 7.2 Smoke Testing

Smoke testing will verify that:

* the dashboard starts;
* the task-selection page loads;
* each main task page can be opened;
* no critical blocking error prevents further testing.

Smoke testing should be performed before more detailed testing begins.

### 7.3 Functional Testing

Functional testing will verify that each task performs its intended function when valid inputs are provided.

Examples include:

* preparing valid input data;
* detecting missing values;
* filling missing flow values;
* joining biological and flow data;
* calculating correlations;
* generating an HEV plot;
* exporting selected results.

### 7.4 Negative Testing

Negative testing will use invalid, incomplete, unsupported, or incorrectly formatted inputs.

Examples include:

* unsupported file formats;
* unreadable or corrupted files;
* empty files;
* files containing headers but no data;
* missing required columns;
* incorrectly named columns;
* invalid dates;
* text in numeric fields;
* unsupported units;
* duplicate identifiers;
* incompatible site identifiers;
* incompatible biological and flow datasets;
* attempts to run a task without required inputs;
* attempts to export when no results are available.

The expected result is not only that the dashboard rejects invalid input, but also that it explains the problem in understandable language.

### 7.5 Boundary Testing

Boundary testing will cover values near accepted limits.

Examples include:

* a file containing no data rows;
* a file containing one data row;
* the earliest accepted date;
* the latest accepted date;
* minimum parameter values;
* maximum parameter values;
* data containing no missing values;
* data containing all missing values in a relevant field;
* the maximum supported file size where defined.

### 7.6 Integration Testing

Integration testing will verify that data and outputs are transferred correctly between related tasks.

Example workflow:

```text
Prepare Data
    ↓
Check Data Quality
    ↓
Create HEV Plot
    ↓
Export Report
```

Another example:

```text
Fill Missing Flow Data
    ↓
Explore Biology–Flow Relationships
    ↓
Export Report
```

Integration testing should verify that:

* the correct dataset is transferred;
* identifiers remain consistent;
* no rows or columns are lost unexpectedly;
* the next task recognises the previous output;
* the final export uses the correct result version.

### 7.7 Task-Oriented Workflow Testing

Testing will verify that the dashboard supports the final Option 3 workflow.

The following behaviours should be tested:

* entering any task directly;
* skipping unrelated tasks;
* completing only one task;
* moving from one task to another;
* returning to the task-selection page;
* changing data sources;
* changing uploaded files;
* repeating a task with different inputs;
* exporting partial results;
* abandoning a task without causing the dashboard to fail.

### 7.8 Regression Testing

Regression testing will be performed after:

* a defect is fixed;
* validation logic is changed;
* task navigation is changed;
* input requirements are changed;
* output calculations are changed;
* the dashboard interface is changed.

Previously passed critical and high-priority test cases should be repeated to confirm that existing functionality has not been broken.

### 7.9 Compatibility Testing

The dashboard will be tested using the browsers available to the project team.

Planned browser coverage includes:

* Google Chrome;
* Microsoft Edge;
* Mozilla Firefox, where available.

The exact browser versions will be recorded during formal test execution.

### 7.10 Basic Performance Testing

Basic performance testing will record:

* dashboard startup time;
* page navigation time;
* site-data loading time;
* local-file upload time;
* data-validation time;
* data-processing time;
* plot-generation time;
* report-generation time.

Performance expectations should be agreed once realistic dataset sizes are available.

### 7.11 Usability Testing

Usability testing will evaluate whether target or representative users can:

* identify the correct task;
* understand the purpose of each task;
* choose the correct data source;
* distinguish site data from local files;
* identify the required files;
* find and use a file template;
* understand validation messages;
* correct invalid inputs;
* interpret outputs;
* move to another task;
* export the required results.

Usability evaluation may include:

* task-completion observation;
* completion time;
* error count;
* requests for assistance;
* Think-Aloud feedback;
* task-specific rating questions;
* System Usability Scale;
* short follow-up interviews.

---

## 8. Workflow Test Coverage

| Workflow ID | Test Scenario                                    | Expected Outcome                                                  |
| ----------- | ------------------------------------------------ | ----------------------------------------------------------------- |
| WF-01       | Open Prepare Data directly                       | The task opens without requiring another task                     |
| WF-02       | Open Check Data Quality directly                 | The user can provide suitable data and run the check              |
| WF-03       | Open Fill Missing Flow Data directly             | Required flow and donor-site inputs are explained                 |
| WF-04       | Open Explore Biology–Flow Relationships directly | Required biological and flow data are explained                   |
| WF-05       | Open Create HEV Plot directly                    | The user can provide valid HEV input and generate a plot          |
| WF-06       | Open Export Report directly with no results      | A clear message is displayed and invalid export is prevented      |
| WF-07       | Skip an unrelated task                           | The selected task remains available when its own inputs are valid |
| WF-08       | Return to the task-selection page                | The user can choose another task                                  |
| WF-09       | Switch from site data to local files             | The selected input source changes correctly                       |
| WF-10       | Replace an invalid local file                    | Other valid inputs remain available                               |
| WF-11       | Reuse output from another task                   | The correct output is accepted by the next task                   |
| WF-12       | Change source data after generating results      | Existing results are cleared, updated, or marked as outdated      |
| WF-13       | Repeat a task with different parameters          | The new result reflects the updated parameters                    |
| WF-14       | Export partial results                           | Only completed and selected results are exported                  |
| WF-15       | Recover from invalid input                       | The user can correct the input and continue                       |
| WF-16       | Complete a multi-task workflow                   | Data remain accurate and consistent across tasks                  |

---

## 9. Test Environment

| Component           | Planned Environment                               |
| ------------------- | ------------------------------------------------- |
| Operating System    | [Windows 11 / macOS / Linux]                      |
| R Version           | [TBC]                                             |
| Shiny Version       | [TBC]                                             |
| Browser             | [Chrome version / Edge version / Firefox version] |
| Source Control      | GitHub                                            |
| Test Deployment     | Local Shiny application                           |
| Test Data Location  | [TBC]                                             |
| Application Version | [Release number or Git commit]                    |
| Test Execution Date | [TBC]                                             |

The exact software versions, application version, and Git commit should be recorded when formal test execution begins.

---

## 10. Test Data

### 10.1 Valid Data

Valid datasets should:

* use supported file formats;
* contain all required columns;
* use accepted data types;
* use accepted date formats;
* use accepted measurement units;
* contain valid site identifiers;
* satisfy the requirements of the selected task.

### 10.2 Invalid Data

Invalid datasets may include:

* unsupported file formats;
* corrupted files;
* incorrect column names;
* invalid dates;
* text in numeric columns;
* unsupported units;
* invalid site identifiers;
* duplicated identifiers;
* incompatible files.

### 10.3 Incomplete Data

Incomplete datasets may include:

* missing required files;
* missing required columns;
* missing biological data;
* missing environmental data;
* missing flow data;
* missing site information;
* missing required values.

### 10.4 Boundary Data

Boundary datasets may include:

* an empty file;
* a file containing headers only;
* a dataset containing one record;
* minimum accepted parameter values;
* maximum accepted parameter values;
* data with no missing values;
* data with a high proportion of missing values.

### 10.5 Template-Based Data

The official templates should be tested by:

1. downloading the template from the dashboard;
2. retaining the required structure;
3. entering valid example values;
4. uploading the completed template;
5. confirming that it passes validation.

The template should not contradict the dashboard's validation rules.

### 10.6 Realistic Data

Where available and authorised, realistic hydroecological datasets should be used to represent expected Environment Agency or Defra use.

Sensitive or restricted data should not be included in the test repository without approval.

### 10.7 Larger Data

Larger representative datasets should be used to identify:

* slow uploads;
* slow validation;
* slow analysis;
* slow plot generation;
* browser responsiveness problems;
* session instability.

---

## 11. Entry Criteria

Formal testing may begin when:

* the relevant task requirements have been agreed;
* the workflow has been confirmed;
* the selected functionality has been implemented;
* the dashboard can be started;
* the test version has been identified;
* the test environment is available;
* required test data have been prepared;
* available templates have been prepared;
* acceptance criteria are available;
* there are no known defects preventing all testing.

Individual task testing may begin when that task is sufficiently complete, even if other tasks remain under development.

---

## 12. Exit Criteria

Testing may be considered complete when:

* all critical and high-priority test cases have been executed;
* all critical defects have been fixed and retested;
* no unresolved defect causes the dashboard to crash during a principal task;
* no unresolved critical defect causes incorrect scientific or statistical output;
* all agreed tasks can be accessed directly;
* required input validation has been tested;
* site-data and local-file input have been tested;
* official templates have been tested where available;
* user-facing warnings and errors have been reviewed;
* principal task-oriented workflows have been tested;
* agreed integration workflows have been tested;
* result-export behaviour has been tested;
* regression testing has been completed;
* usability evaluation has been completed;
* known limitations have been documented;
* a test summary report has been produced.

Low-priority defects may remain open if they are documented and accepted by the project team and client.

---

## 13. Defect Classification

### 13.1 Defect Severity

| Severity | Definition                                                                                     | Example                                                |
| -------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Critical | The dashboard cannot be used, data are corrupted, or critical scientific results are incorrect | The dashboard does not start                           |
| High     | A principal task cannot be completed                                                           | Valid flow data cannot be processed                    |
| Medium   | The task can be completed, but an important behaviour or usability issue exists                | The error message does not identify the missing column |
| Low      | A minor visual, wording, or formatting problem exists                                          | A label contains a spelling error                      |

### 13.2 Defect Priority

| Priority | Meaning                                             |
| -------- | --------------------------------------------------- |
| P1       | Must be fixed immediately or before further testing |
| P2       | Should be fixed before release or client evaluation |
| P3       | Should be fixed when time allows                    |
| P4       | Minor improvement for future consideration          |

Severity describes the impact of the defect. Priority describes how urgently it should be fixed.

---

## 14. Test Deliverables

The testing process is expected to produce:

* High-Level Test Plan;
* Detailed Test Plan;
* Requirements Traceability Matrix;
* Test Case Specification;
* Test Data;
* File-Template Test Record;
* Test Execution Record;
* Defect Log;
* Regression Test Record;
* Usability Evaluation Plan;
* Usability Evaluation Results;
* User Acceptance Test Record;
* Test Summary Report.

Supporting evidence may include:

* screenshots;
* exported files;
* console logs;
* browser information;
* Git commit identifiers;
* short screen recordings where appropriate.

---

## 15. Risks and Mitigation

| Risk                                         | Possible Impact                                        | Mitigation                                                              |
| -------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------- |
| Input requirements are incomplete            | Expected results and validation rules may be unclear   | Confirm required files, columns, formats, and units with the client     |
| Task requirements change during development  | Existing test cases may become outdated                | Link test cases to requirements and application versions                |
| Realistic test data are unavailable          | Testing may not represent real use                     | Create representative anonymised datasets and document limitations      |
| Templates do not match validation rules      | Users may be unable to upload correctly formatted data | Test every official template against the implemented validation         |
| Local files and site data are confusing      | Users may choose the wrong input method                | Use separate labels, instructions, and usability testing                |
| Technical R errors are shown to users        | Users may not understand or recover from errors        | Add user-readable validation and error handling                         |
| Input changes leave outdated results visible | Users may interpret old results as current             | Clear, recalculate, version, or mark affected results as outdated       |
| Limited access to EA or Defra users          | Usability findings may be incomplete                   | Use representative proxy users and record this limitation               |
| Limited project time                         | Lower-priority testing may not be completed            | Prioritise critical tasks, high-risk functions, and principal workflows |
| Browser behaviour differs                    | Some users may experience interface problems           | Test the agreed supported browsers                                      |
| Large datasets reduce performance            | Tasks may become slow or unresponsive                  | Test representative larger data and record processing times             |

---

## 16. Assumptions and Dependencies

The test plan currently assumes that:

* Option 3 is the confirmed final workflow;
* the six main task areas remain within the agreed project scope;
* the project team will define the required inputs for each task;
* the project team will define the accepted file formats;
* the project team will define required fields, data types, and units;
* suitable test data will be available or can be created;
* relevant HE Toolkit functions are available to the dashboard;
* the dashboard can be run in a local test environment;
* client representatives will be available to clarify important requirements.

Items that have not yet been confirmed should remain marked as `TBC` rather than being guessed.

---

