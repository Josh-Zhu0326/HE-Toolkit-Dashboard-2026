# Pilot Task Script Test Results

Date: 29 July 2026

Tested revision: `ce8eb95` (`main`)

Overall result: **5 tasks passed and 1 task partially passed**

## Test Scope

The current dashboard was tested from start to finish by following the six tasks in the Pilot Task Script and checking the expected results in the Pilot Facilitator Guide.

The pilot mapping used:

| Field | Test value |
|---|---|
| `biol_site_id` | `291` |
| `flow_site_id` | `27090` |
| `flow_input` | `NRFA` |
| `wq_site_id` | `SW-A4070115` |
| `rhs_survey_id` | `6145` |

## Task Results

| Task | Result | Actual result |
|---|---|---|
| 1. Start a new analysis | **Partial pass** | The HEV workflow can be selected. However, the Home page does not clearly list Biology, Environmental and Flow as the required datasets. |
| 2. Import the required data | **Pass** | The mapping CSV passed validation. Biology, Environmental and NRFA Flow data were imported successfully. |
| 3. Process and join the data | **Pass** | RICT predictions, O:E ratios and Flow Statistics were produced. Lag `0` and join method `A` created the Joined Data table. The expected early-biology-sample warning was shown. |
| 4. Run a basic model | **Pass** | The model completed with `WHPT_ASPT_O` and `Q5_lag0`, and displayed both a result table and a plot. |
| 5. Create an HEV plot | **Pass** | The plot was created for site `291`, biological metric `WHPT_ASPT_OE` and flow metric `Q5`. The PDF download control was available. |
| 6. Test donor-flow validation | **Pass** | Attempting imputation with an empty donor mapping displayed a clear validation message. Existing Flow Statistics remained available afterwards. |

## Verified Outputs

- Biology import: 26 records.
- Environmental import: 1 site record.
- Flow import: 13,359 daily records for site `27090`.
- Flow import contained 1,748 missing values in two gaps.
- RICT predictions: 3 seasonal predictions.
- O:E results: 26 records.
- Flow Statistics: 63 time windows.
- Joined Data: 26 records.
- Join warning: one or more biology samples precede the earliest flow period for site `291`.

The basic model result matched the Facilitator Guide:

| Measure | Result |
|---|---:|
| Observations | 14 |
| Slope | 0.0075029 |
| Direction | Positive |
| p-value | 0.1353 |
| R-squared | 0.1760 |

## Automated Checks

- All `testthat` tests passed.
- All 36 R files passed syntax parsing.
- No application code was changed during this test.

## Issues and Recommended Actions

1. **Task 1 wording and interface mismatch:** add Biology, Environmental and Flow to the HEV requirements shown on the Home page, or update the Pilot Task Script so participants are not asked to find information that is not displayed.
2. **Donor warning wording:** the current warning works, but it could explain the next action more directly, for example: "Add donor mapping and donor flow data before running imputation."
3. **Non-blocking R warnings:** deprecated `dplyr` usage and plotting warnings were printed during processing. They did not stop the workflow but should be cleaned up later.

## Conclusion

The main pilot workflow can be completed successfully. Tasks 2 to 6 produced the expected outputs, and the model values matched the Facilitator Guide. Before participant testing, Task 1 should be aligned with the information shown on the Home page.
