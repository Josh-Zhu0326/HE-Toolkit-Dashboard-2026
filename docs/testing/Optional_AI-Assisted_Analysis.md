## Optional AI-Assisted Analysis

AI-assisted analysis is an optional stretch objective for the project.

If sufficient development time and suitable technical resources are available, the dashboard may include an AI-assisted feature to help users understand and interpret their data, statistical results, tables, and visualisations.

The AI feature is intended to support Environment Agency and Defra users who understand environmental and statistical concepts but may benefit from additional assistance when interpreting dashboard outputs.

The AI feature may help users to:

* summarise selected datasets or analysis results;
* explain statistical results in user-readable language;
* describe patterns visible in tables or visualisations;
* highlight missing data, unusual values, or possible areas of interest;
* explain technical or statistical terminology;
* suggest relevant follow-up questions or dashboard tasks;
* produce a draft interpretation that the user can review.

The AI feature should not replace the dashboard's validated R calculations.

Core statistical calculations, data processing, correlations, visualisations, and exported values should continue to be produced by the implemented and tested R functions.

AI-generated content should be clearly identified as AI-generated assistance rather than a verified scientific conclusion.

Users should remain responsible for reviewing the AI-generated interpretation before using it in decision-making or formal reporting.

The AI feature may be implemented as:

* an optional assistant available on analysis and results pages;
* an optional interpretation panel next to tables or plots; or
* a separate AI-assisted analysis task.

The final interface location and technical implementation remain to be confirmed.

---

## Additional AI Test Objectives

If the optional AI-assisted feature is implemented, testing will also verify that:

* the AI feature is clearly presented as optional;
* users can complete the core dashboard tasks without using AI;
* the AI receives the correct selected data or dashboard result;
* AI-generated summaries accurately reflect the supplied results;
* numerical values quoted by the AI match the dashboard outputs;
* the AI does not invent datasets, variables, sites, statistics, or conclusions;
* uncertain or incomplete information is described appropriately;
* AI-generated content is clearly labelled;
* users are warned that AI-generated interpretations require review;
* the AI uses language understandable to the intended users;
* the AI does not expose internal prompts, system information, or technical implementation details;
* invalid or unavailable AI responses do not prevent users from continuing to use the dashboard;
* users can regenerate, dismiss, or ignore an AI response;
* the original data and verified statistical outputs remain unchanged by the AI feature;
* sensitive or restricted data are not transmitted to an external AI service without appropriate approval.

---

## AI-Assisted Analysis Test Scope

### Conditionally In Scope

The following areas will be included only if the optional AI-assisted feature is implemented:

* access to the AI assistance feature;
* selection of data or results for AI analysis;
* generation of plain-language summaries;
* explanation of tables, plots, and statistical results;
* consistency between AI statements and dashboard outputs;
* handling of missing or incomplete information;
* handling of unsupported user requests;
* communication of uncertainty;
* labelling of AI-generated content;
* user review and acceptance of AI-generated interpretations;
* AI service errors and timeouts;
* protection of the core dashboard workflow when the AI service is unavailable;
* privacy and data-transfer controls;
* AI usability evaluation.

### Out of Scope Unless Separately Agreed

The following AI-related capabilities are outside the current scope unless explicitly agreed with the client:

* autonomous scientific decision-making;
* automatic approval of environmental conclusions;
* replacement of validated statistical calculations with AI-generated calculations;
* model training using sensitive Environment Agency or Defra data;
* unrestricted transfer of local files to third-party AI services;
* automatic submission of AI-generated text into formal reports without user review;
* assessment or certification of the AI feature for regulatory decision-making.

---

## Optional AI-Assisted Analysis Test Item

If implemented, testing will verify that:

* the AI feature is available only where appropriate;
* the user can see which dataset, table, plot, or result is being analysed;
* the AI analyses the currently selected result rather than an outdated result;
* quoted numbers match the verified dashboard output;
* the explanation does not contradict the underlying data;
* unsupported conclusions are avoided;
* missing context is acknowledged;
* the AI distinguishes observations from possible interpretations;
* suggested next steps are relevant to the available dashboard tasks;
* user-facing language is understandable;
* technical terminology is explained where necessary;
* AI-generated text is clearly labelled;
* the user can continue without accepting the AI response;
* AI failure does not cause the dashboard to crash;
* sensitive information is handled according to the agreed data policy.

The AI should distinguish between:

* a direct observation from the supplied data;
* a statistical result produced by the dashboard;
* a possible interpretation;
* a suggested follow-up action.

For example, an appropriate response may state:

> The selected site shows lower recorded flow values during the displayed period. This is an observation from the current dataset. Further investigation may be required before determining the cause.

The AI should not state:

> The site is experiencing ecological decline because of reduced flow.

unless that conclusion is directly supported by the verified analysis and approved interpretation rules.

---

## AI Testing Approach

### Grounded Output Testing

The AI will be provided with known dashboard results, and its response will be compared with the original values.

Testing will verify that:

* site names are correct;
* variable names are correct;
* dates and time periods are correct;
* numerical values are correct;
* trends are described consistently with the visualisation;
* missing values are not represented as observed values.

### Hallucination Testing

The AI will be tested using incomplete or limited data.

It should not invent:

* additional monitoring sites;
* unavailable measurements;
* unsupported causes;
* statistical significance;
* environmental events;
* recommendations not supported by the supplied information.

Where the available information is insufficient, the AI should clearly state that a reliable conclusion cannot be made.

### Uncertainty Testing

Testing will verify that the AI communicates uncertainty when:

* data are incomplete;
* sample sizes are small;
* relevant variables are unavailable;
* results are ambiguous;
* correlations do not establish causation;
* a requested conclusion is not supported by the analysis.

### Numerical Consistency Testing

Any number included in the AI-generated response should be checked against the dashboard output.

This includes:

* percentages;
* counts;
* dates;
* correlation values;
* missing-value totals;
* site totals;
* summary statistics.

A response that contains an incorrect material value should be recorded as a defect.

### Failure and Recovery Testing

Testing will cover:

* AI service timeout;
* unavailable AI service;
* invalid AI response;
* empty AI response;
* interrupted network connection;
* repeated requests;
* excessively long user input.

The core dashboard should remain usable when AI assistance is unavailable.

A user-readable message should be displayed, for example:

> AI assistance is temporarily unavailable. Your data and analysis results have not been affected. You can continue using the dashboard or try again later.

### Privacy and Data Handling Testing

Before an external AI service is used, the project team should confirm:

* which data are sent to the service;
* whether complete files or only selected summaries are transmitted;
* whether personal, sensitive, or restricted information may be included;
* where the service processes or stores the data;
* whether user approval is required;
* whether the client has approved the selected service.

Testing should verify that data outside the agreed scope are not sent to the AI service.

---

## Optional AI Workflow Coverage

| Workflow ID | Test Scenario                                          | Expected Outcome                                                 |
| ----------- | ------------------------------------------------------ | ---------------------------------------------------------------- |
| AI-WF-01    | Complete a core task without using AI                  | The task can be completed normally                               |
| AI-WF-02    | Request an explanation of a generated plot             | The response reflects the selected plot and its data             |
| AI-WF-03    | Request a summary of data-quality results              | Missing values and completeness results are described accurately |
| AI-WF-04    | Request analysis when no result is selected            | The system asks the user to select or generate a result          |
| AI-WF-05    | Change the source data after generating an AI response | The old response is cleared or marked as outdated                |
| AI-WF-06    | AI service is unavailable                              | The dashboard remains usable and displays a clear message        |
| AI-WF-07    | Ask for a conclusion unsupported by the data           | The AI explains that the conclusion cannot be established        |
| AI-WF-08    | AI quotes a numerical result                           | The quoted value matches the verified dashboard output           |
| AI-WF-09    | User ignores or dismisses AI assistance                | The user can continue without interruption                       |
| AI-WF-10    | Export an AI-generated interpretation                  | The content is clearly labelled and requires user review         |

---

## Additional AI Entry Criteria

Testing of the optional AI feature may begin when:

* the intended purpose of the AI feature has been agreed;
* the AI feature's location within the interface has been agreed;
* the data supplied to the AI have been defined;
* the AI service or model has been selected;
* data-protection and client-approval requirements have been reviewed;
* expected AI behaviour has been documented;
* representative test prompts and verified dashboard results are available;
* the core dashboard calculations used by the AI have already been tested.

---

## Additional AI Exit Criteria

If the optional AI feature is implemented, its testing may be considered complete when:

* the agreed AI test cases have been executed;
* AI-generated numerical statements have been checked against dashboard results;
* no unresolved critical defect causes the AI to materially misrepresent the supplied data;
* AI content is clearly labelled;
* uncertainty and insufficient evidence are communicated appropriately;
* the dashboard remains functional when the AI service fails;
* privacy and data-transfer behaviour have been reviewed;
* known AI limitations have been documented;
* the client has reviewed the intended role of the AI feature.

Failure to complete the optional AI feature should not prevent completion of the core dashboard project, provided that the agreed core task-oriented workflow has been delivered and tested.

---

## Additional AI Risks and Mitigation

| Risk                                     | Possible Impact                                       | Mitigation                                                                       |
| ---------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| AI invents facts or results              | Users may rely on incorrect information               | Ground responses in verified dashboard outputs and test for unsupported claims   |
| AI quotes incorrect numerical values     | Analysis may be misinterpreted                        | Compare all material values against the original dashboard result                |
| AI presents suggestions as conclusions   | Users may over-trust generated content                | Label observations, interpretations, and suggestions separately                  |
| Users assume AI output is verified       | Generated text may be used without review             | Display a clear AI label and user-review warning                                 |
| Sensitive data are sent externally       | Privacy or client-policy requirements may be breached | Minimise transmitted data and obtain approval before using external services     |
| AI service is unavailable                | The assistance function may fail                      | Keep the core dashboard independent from the AI service                          |
| AI response is too technical             | Non-programming users may not understand it           | Use user-readable prompts and evaluate responses with representative users       |
| AI response is too general               | The feature may provide little practical value        | Supply relevant dashboard context and test task-specific prompts                 |
| AI uses outdated results                 | The interpretation may not match current data         | Clear or invalidate responses when source data change                            |
| Optional AI work delays core development | Required dashboard functions may remain incomplete    | Prioritise the six core tasks and implement AI only when sufficient time remains |

---

## Additional Assumptions and Dependencies

The optional AI-assisted feature assumes that:

* the six core task-oriented dashboard functions remain the project priority;
* AI development will begin only when sufficient project time remains;
* the client will confirm the intended role of the AI feature;
* the AI is primarily intended to assist interpretation rather than replace validated analysis;
* suitable data can be supplied to the model safely;
* the selected AI service is technically and financially available;
* client approval will be obtained before restricted data are sent to an external service;
* AI-generated text will be reviewed by the user before formal use.

The exact model, provider, hosting arrangement, interface location, data-transfer process, and acceptance thresholds remain `TBC`.
