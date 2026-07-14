# HE Toolkit Dashboard Manual Test Cases

Test URL: http://127.0.0.1:3838/

Fixture folder: `tests/fixtures`

These manual test cases are for client review and regression checking. WQ and RHS are supporting mapped datasets only and must not be used in the O:E calculation.

## Test Data

- Mapping CSV: `tests/fixtures/mapping.csv`
- WQ CSV: `tests/fixtures/wq.csv`
- RHS CSV: `tests/fixtures/rhs.csv`
- Local flow CSV: `tests/fixtures/local_flow.csv`
- Local invertebrate CSV: `tests/fixtures/local_invertebrate.csv`

## TC-001 Home Page Loads

Steps:
1. Open http://127.0.0.1:3838/.
2. Check the Home page content.

Expected result:
- The dashboard loads without errors.
- The Home page states that WQ and RHS are supporting mapped datasets.
- The Home page states that WQ and RHS are not used in the O:E calculation.

## TC-002 Valid Mapping CSV Upload

Steps:
1. Go to Data Import.
2. In the Mapping sidebar, upload `tests/fixtures/mapping.csv`.
3. Review the validation message and metadata preview.

Expected result:
- Mapping CSV is accepted.
- Required columns are recognised: `biol_site_id`, `flow_site_id`, `flow_input`, `wq_site_id`, `rhs_survey_id`.
- A warning may appear for `rhs_survey_id = TBC`.
- The app does not crash.

## TC-003 Mapping CSV Missing Required Columns

Steps:
1. Create or upload a CSV missing `wq_site_id` or `rhs_survey_id`.
2. Upload it in the Mapping sidebar.

Expected result:
- A clear validation error is shown.
- The Shiny app remains connected.

## TC-004 Duplicate Biology Site IDs

Steps:
1. Upload a mapping CSV containing duplicate `biol_site_id` values.

Expected result:
- A warning is shown explaining the duplicate biology site IDs.
- The app does not crash.

## TC-005 WQ CSV Validation Sandbox

Steps:
1. Go to CSV Validation Sandbox.
2. Upload `tests/fixtures/wq.csv` in the WQ section.

Expected result:
- WQ file validates successfully.
- Preview table shows WQ rows.
- No modelling or O:E calculation is triggered.

## TC-006 RHS CSV Validation Sandbox

Steps:
1. Go to CSV Validation Sandbox.
2. Upload `tests/fixtures/rhs.csv` in the RHS section.

Expected result:
- RHS file validates successfully.
- Preview table shows RHS rows.
- No modelling or O:E calculation is triggered.

## TC-007 WQ Data Plot Controls

Steps:
1. Upload the mapping CSV.
2. Upload WQ CSV in CSV Validation Sandbox, or import WQ using site IDs if network/API access is available.
3. Go to Data Import > WQ Data.
4. Try WQ plot types:
   - Time series
   - Boxplot by biological site ID
   - Mean bar chart by biological site ID

Expected result:
- WQ controls appear.
- Suitable numeric/date columns are detected.
- Plots render when enough data exists.
- Clear messages are shown if data are missing or unsuitable.

## TC-008 WQ Downloads

Steps:
1. Go to Data Import > WQ Data after WQ data are available.
2. Click Download mapped WQ data as CSV.
3. Click Download current WQ plot as PNG.

Expected result:
- CSV download is generated when mapped WQ data exist.
- PNG download is generated when a WQ plot exists.

## TC-009 RHS Data Plot Controls

Steps:
1. Upload the mapping CSV.
2. Upload RHS CSV in CSV Validation Sandbox, or import RHS using site IDs if available.
3. Go to Data Import > RHS Data.
4. Try RHS plot types:
   - Numeric variable by biological site ID
   - Categorical count/bar plot
   - Record count by biological site ID

Expected result:
- RHS controls appear.
- Numeric and categorical columns are detected.
- Plots render when enough data exists.
- `TBC` RHS mapping does not crash the app.

## TC-010 RHS Downloads

Steps:
1. Go to Data Import > RHS Data after RHS data are available.
2. Click Download mapped RHS data as CSV.
3. Click Download current RHS plot as PNG.

Expected result:
- CSV download is generated when mapped RHS data exist.
- PNG download is generated when a RHS plot exists.

## TC-011 Local Invertebrate CSV Upload

Steps:
1. Go to Data Import > Local File Import.
2. Upload `tests/fixtures/local_invertebrate.csv`.

Expected result:
- File validates successfully.
- Preview table shows local invertebrate rows.
- Local data do not automatically enter O:E.

## TC-012 Local Flow CSV Upload

Steps:
1. Go to Data Import > Local File Import.
2. Upload `tests/fixtures/local_flow.csv`.

Expected result:
- File validates successfully.
- Preview table shows local flow rows.
- `flow_input` values are accepted because they are `NRFA`.
- Local data do not automatically enter O:E.

## TC-013 Invalid Local Flow Input

Steps:
1. Upload a local flow CSV where `flow_input` is blank or not `NRFA`/`HDE`.

Expected result:
- A clear validation error is shown.
- The Shiny app remains connected.

## TC-014 Existing O:E Workflow Regression

Steps:
1. Use existing site metadata.
2. Import biology data.
3. Import environmental data.
4. Run RICT predictions.
5. Calculate O:E ratios.
6. View O:E ratios.

Expected result:
- Existing O:E outputs render as before.
- WQ/RHS data are not required.
- WQ/RHS data are not used in the O:E calculation.

## TC-015 Existing Flow Workflow Regression

Steps:
1. Import flow data.
2. View flow heatmap/completeness stats.
3. Calculate flow statistics.
4. View time-varying and long-term flow statistics.

Expected result:
- Existing flow outputs render as before.
- Invalid `flow_input` values are not allowed.

## TC-016 HEV Single Plot

Steps:
1. Complete the existing biology-flow workflow required for HEV.
2. Go to HEV Plots.
3. Select one biology metric and one flow metric.
4. Click Create HEV plot.

Expected result:
- Existing single HEV plot renders.
- Existing HEV download remains available.

## TC-017 HEV All Four Plots

Steps:
1. Complete the HEV prerequisites.
2. Go to HEV Plots.
3. Check Show all 4 HEV plots.
4. Click Create HEV plot.

Expected result:
- All four HEV plots render on the page when data are available.
- Existing HEV functionality remains available.

## TC-018 HEV High/Low Flow Overlay

Steps:
1. Complete the HEV prerequisites.
2. Go to HEV Plots.
3. Check Overlay low-flow and high-flow statistics.
4. Click Create HEV plot.

Expected result:
- High-flow and low-flow statistics are plotted together when matching columns exist.
- The app does not crash if matching columns are unavailable.

## TC-019 HEV Status Boundary Message

Steps:
1. Go to HEV Plots.
2. Check Show available status class boundaries.

Expected result:
- A clear warning message explains that confirmed boundary/class data are unavailable.
- No fake boundary lines are drawn.

## TC-020 Basic Flow-Ecology Model

Steps:
1. Complete the joined biology-flow workflow.
2. Go to Analysis > Flow-Ecology Model.
3. Select numeric flow and ecology variables.
4. Click Run basic model.

Expected result:
- Model summary table appears with slope, direction, p-value, and R-squared where available.
- Scatter plot with fitted trend line appears.
- Message explains that this is exploratory and does not alter O:E.

## TC-021 Basic Model Invalid Data

Steps:
1. Try to run the model before joined data are available, or with too few complete observations.

Expected result:
- A clear error message is shown.
- The Shiny app remains connected.

## TC-022 Downloads Visibility

Steps:
1. Review WQ Data, RHS Data, HEV Plots, and joined/O:E tables.

Expected result:
- Existing downloads remain visible.
- New WQ/RHS plot and mapped-data downloads are visible in the relevant sections.

## TC-023 Navigation Review

Steps:
1. Click through all top-level navigation tabs.

Expected result:
- Pages load without UI errors.
- Section titles and help text are understandable for a non-technical environmental science reviewer.
