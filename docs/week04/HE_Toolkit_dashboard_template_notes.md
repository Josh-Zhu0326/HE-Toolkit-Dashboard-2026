# HE Toolkit Dashboard Standard Data Template

This workbook is a customer-fillable template for the HE Toolkit Dashboard. It is designed so that non-coding users can provide data in a consistent structure, while the dashboard can convert the workbook into inputs for the existing HE Toolkit workflow.

## Workbook Structure

The template contains these main sheets:

- `site_mapping`: links biology sites to flow, WQ, and RHS identifiers.
- `biology_samples`: sample-level biology metrics. The minimum required columns are `biol_site_id` and `date`.
- `environmental_site_data`: EDE/RICT-style site environmental variables used to calculate expected biology metrics and OE ratios.
- `flow_daily`: daily flow records. These can be passed to `calc_flowstats()` after import.
- `wq_long_standard`: long-format water quality records. WQ is time-varying, so `date_time` is required.
- `rhs_summary`: RHS survey or site-level habitat data.
- `joined_dataset_optional`: optional example of the shape expected after joining.
- `field_dictionary`: explanation of key fields.
- `validation_rules`: suggested import and modelling rules.

## Alignment With Existing HE Toolkit Functions

The current HE Toolkit function `join_he()` requires:

- biology data with `biol_site_id` and `date`
- flow statistics with `flow_site_id`, `start_date`, and `end_date`
- optional mapping with `biol_site_id` and `flow_site_id`

This template therefore separates raw daily flow (`flow_daily`) from the final flow statistics that the dashboard should calculate using `calc_flowstats()`.

The HE Toolkit functions `import_env()` and `predict_indices()` support the OE calculation workflow:

- `import_env()` imports site-level environmental data.
- `predict_indices()` uses those environmental variables with the RICT2 model to calculate expected macroinvertebrate index scores.
- OE ratios can then be calculated as observed biology metrics divided by expected scores.

The `environmental_site_data` sheet is included so the dashboard can support this fuller workflow, rather than relying only on already-calculated OE columns uploaded by the user.

The HE Toolkit function `import_wq()` returns WQ data in long format with fields such as:

- `wq_site_id`
- `date_time`
- `det_id`
- `determinand`
- `result`
- `unit`

The template keeps this long-format structure because it is easier to match WQ records to biology sample dates.

RHS is initially treated as site-level or survey-level information using `rhs_survey_id`, because RHS surveys are usually not high-frequency time series.

## Recommended MVP Import Logic

1. Read workbook sheets by exact sheet name.
2. Validate required columns.
3. Parse dates and numeric fields.
4. Use `environmental_site_data` to calculate expected biology metrics and OE ratios when OE columns are not already supplied.
5. Join biology to flow using `site_mapping`.
6. Calculate flow statistics from `flow_daily`.
7. Match WQ to biology samples using a confirmed rule, such as seasonal mean or nearest sample.
8. Attach RHS using `rhs_survey_id` or site-level mapping.
9. Show matching success and missing-value summaries before modelling.

## Key Client Questions Still To Confirm

- Which WQ determinands should be prioritised for the MVP?
- Should the MVP default WQ matching rule be seasonal mean or nearest sample?
- If multiple WQ records match one biology sample, should they be summarised using mean, median, minimum, maximum, or nearest sample?
- Should a maximum WQ date difference be enforced, such as 90 days?
- Can the MVP use `site_mapping` as the authoritative mapping between `biol_site_id`, `wq_site_id`, and `rhs_survey_id`?
- Will users upload already-calculated OE columns, or should the dashboard calculate OE from observed metrics plus `environmental_site_data`?
- Can RHS be treated as site-level/survey-level data for the MVP?
- If one biology site maps to multiple RHS surveys, which survey selection rule should be used?
- Which numeric WQ/RHS variables should appear in the modelling dropdown?
- Should incomplete rows be removed automatically, or should users first review a missing-value summary and decide whether to continue?

## Suggested Dashboard Behaviour

The dashboard should not silently import and model data. It should show:

- number of biology samples
- number of biology sites with environmental data available for OE calculation
- number of sites successfully mapped to flow
- number of samples matched with WQ
- number of sites/samples matched with RHS
- missing-value summary
- list of variables eligible for modelling

For the first modelling MVP, only numeric columns should appear as model response or predictor choices.
