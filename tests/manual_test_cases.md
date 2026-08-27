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
- Required columns are recognised: `biol_site_id`, `flow_site_id`, `wq_site_id`, `rhs_survey_id`.
- An omitted or blank `flow_input` defaults to `HDE`; explicit `HDE` and `NRFA` values are accepted.
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

## TC-005 WQ CSV File Validation

Steps:
1. Go to Data Import > Local File Import.
2. Expand Legacy WQ workflow upload.
3. Upload `tests/fixtures/wq.csv`.

Expected result:
- WQ file validates successfully.
- Preview table shows WQ rows.
- No modelling or O:E calculation is triggered.

## TC-006 RHS CSV File Validation

Steps:
1. Go to Data Import > Local File Import.
2. Expand Legacy RHS workflow upload.
3. Upload `tests/fixtures/rhs.csv`.

Expected result:
- RHS file validates successfully.
- Preview table shows RHS rows.
- No modelling or O:E calculation is triggered.

## TC-040 Standalone Validation Sandbox Retirement

Steps:
1. Open the Utilities menu and review the primary navigation.
2. Go to Data Import > Local File Import.
3. Confirm the five Data Contract v2.0 CSV checkpoints are available for the current Task.
4. Confirm any applicable legacy workflow upload is shown only in a collapsed compatibility section.

Expected result:
- No File Validation Sandbox page or Utilities link is available.
- No DC-11 workbook or single-CSV runtime checkpoint is shown.
- Existing WQ/RHS workflow uploads remain reachable only for Tasks that require those data types.
- The historical workbook validation helper remains outside the user-facing runtime path.

## TC-007 WQ Data Plot Controls

Steps:
1. Upload the mapping CSV.
2. Upload WQ CSV through the Stage 1 legacy workflow entry, or import WQ using site IDs if network/API access is available.
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
2. Upload RHS CSV through the Stage 1 legacy workflow entry, or import RHS using site IDs if available.
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
3. Upload `tests/fixtures/local_flow_extra_columns.csv`.

Expected result:
- File validates successfully.
- Preview table shows local flow rows.
- Required input columns are `flow_site_id`, `date`, and `flow`; `biol_site_id` and `flow_input` are not required.
- The uploaded data become the operational Flow data source.
- The extra-column fixture reports **Pass with Warning**, lists `flow_input`, `biol_site_id`, and `note` as ignored, and exposes only `flow_site_id`, `date`, and `flow` operationally.

## TC-013 Invalid Local Flow Schema or Values

Steps:
1. Upload a local flow CSV missing `flow_site_id`, `date`, or `flow`, or containing blank site IDs or non-numeric flow values.

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
- Missing or blank metadata `flow_input` values use `HDE`.

## TC-016 HEV Single Plot

Steps:
1. Complete the existing biology-flow workflow required for HEV.
2. Go to HEV Plots.
3. Select Flow Statistics as the Flow data mode.
4. Select one biology metric and one calculated Flow statistic.
5. Click Create HEV plot.

Expected result:
- The existing single HEV plot renders from the selected `calc_flowstats()` result.
- The provenance summary identifies `flow_statistics`, the selected statistic, and the source revision/fingerprint.
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
3. Select Flow Statistics as the Flow data mode.
4. Check Overlay low-flow and high-flow statistics.
5. Click Create HEV plot.

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

## TC-041 Joined Dataset Boundary

Steps:
1. Build or load a core Joined HE dataset.
2. Attempt optional WQ/RHS enrichment using one successful source and one unavailable or invalid source.
3. Derive the analysis dataset from either the core or enriched source.
4. Apply a record exclusion.

Expected result:
- The original `joined_core` remains unchanged.
- A separate `joined_enriched` is created only from successful enrichment sources.
- Failed optional enrichment is recorded as a warning and does not invalidate `joined_core`.
- The analysis dataset records whether it was derived from `joined_core` or `joined_enriched`.
- Filtering changes only the analysis dataset and does not write back to either joined dataset.

## TC-042 HEV Current Output and Download History

Steps:
1. Build or load a current analysis dataset.
2. Generate an HEV plot for one Flow data mode, site, date range, biology metric, and Flow field/statistic.
3. Confirm the source/provenance summary is shown.
4. Change one HEV setting without regenerating.
5. Regenerate the HEV plot and download it.

Expected result:
- The HEV result records the Flow data mode, source dataset, source fingerprint/revision, filter version, mapped biology and Flow site IDs, selected field/statistic, and date range.
- Changing HEV settings marks the previous result stale and prevents it being downloaded as the current result.
- Regenerating creates a current HEV result again.
- Download history records the download format and the provenance of the downloaded HEV result.

## TC-043 HEV Raw Daily Flow

Steps:
1. Import and validate Biology, Environmental, site-mapping, and raw daily Flow data.
2. Process Biology and calculate O:E ratios.
3. Do not calculate Flow Statistics, or ensure that no current Flow Statistics result exists.
4. Go to HEV Plots and select Raw daily Flow as the Flow data mode.
5. Select a mapped site, biology metric, and date range containing daily Flow records.
6. Click Create HEV plot.

Expected result:
- The HEV plot renders a continuous line from the canonical numeric `flow` field and the selected biology observations.
- Flow Statistics are not requested or required.
- Exact daily dates and the explicit biology-to-Flow site mapping are used.
- The provenance summary and downloaded plot history identify `daily_flow`, the daily Flow source revision/fingerprint, mapped site IDs, `flow`, and the selected date range.
- A missing, stale, invalid, duplicated, or unmapped daily Flow source produces an actionable message and does not silently use Flow Statistics.

## TC-044 HEV Flow Mode Switching and Recovery

Steps:
1. Generate a current HEV plot in Raw daily Flow mode.
2. Change the Flow data mode to Flow Statistics without regenerating.
3. Confirm the previous plot is stale and cannot be downloaded as the current result.
4. Calculate or confirm current Flow Statistics, choose a statistic, and regenerate the plot.
5. Make the selected Flow Statistics unavailable or stale and retry generation.
6. Restore valid Flow Statistics and retry in the same session.

Expected result:
- Changing modes marks the previous HEV output stale.
- The Flow Statistics plot uses the selected `calc_flowstats()` field rather than raw `flow`.
- An unavailable selected mode is blocked without falling back to the other mode or overwriting the previous successful result.
- Correcting the selected source allows an explicit same-session retry to succeed.
- Provenance and download history distinguish the two modes and their respective source revisions/fingerprints.
