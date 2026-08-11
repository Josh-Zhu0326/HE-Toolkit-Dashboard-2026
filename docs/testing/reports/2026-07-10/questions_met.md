# Data Clarification Questions

We identified the following points while testing the customer-provided `NDMN site metadata` file against the current Dashboard validation rules.

## 1. RHS Identifiers

The provided `NDMN site metadata` file contains both `rhs_site_id` and `rhs_survey_id`, and the two fields contain different values in the same rows.

Could you please confirm whether:

- both identifiers are required and represent different levels of RHS information, for example site-level and survey-level identifiers; or
- only one of these fields should be used as the primary RHS identifier for the Dashboard workflow?

The current Dashboard validation treats different `rhs_site_id` and `rhs_survey_id` values in the same row as conflicting.

## 2. Flow Data Source

The provided metadata does not currently contain a `flow_input` column.

For testing purposes, we have temporarily assumed `NRFA` as the `flow_input` value because the current Dashboard demo metadata uses NRFA.

Could you please confirm whether NRFA is the correct source for the supplied `flow_site_id` values, or whether another source such as HDE or a different data source should be used?

Until this is confirmed, NRFA will be treated as a testing assumption rather than a confirmed production setting.

## 3. Expected WQ Import Volume and Performance

The provided NDMN metadata contains 49 WQ site IDs, and importing WQ data for all sites may take a relatively long time because the Dashboard retrieves data site by site.

Could you please clarify:

- Is importing approximately 49 WQ sites in a single operation representative of normal expected use, or is this considered a relatively large batch?
- What would be an acceptable completion time for importing this amount of WQ data?
- Is the current import duration acceptable from a user perspective (20 mins for 49 WQ sites), or would you expect the Dashboard to provide faster processing or clearer progress feedback for long-running imports?

This information would help us define appropriate performance and usability acceptance criteria for WQ data import.