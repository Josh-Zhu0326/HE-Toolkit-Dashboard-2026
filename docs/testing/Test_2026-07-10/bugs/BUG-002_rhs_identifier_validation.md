# BUG-002: Metadata validation uses the wrong RHS identifier

## Summary

The Dashboard currently treats `rhs_site_id` as the required RHS mapping identifier and may reject metadata containing only `rhs_survey_id`.

The customer has confirmed that `rhs_survey_id` should be sufficient for the RHS workflow because RHS is being treated as site-level data.

This means the current metadata validation behaviour does not match the confirmed requirement.

## Severity

Medium

## Priority

High

## Environment

- Branch: `main`
- Platform: Windows 11
- Browser: Google Chrome
- Test type: Functional Testing
- Test data: Customer-provided metadata

## Related Test Cases

- FT-01B
- FT-01C
- FT-01D
- FT-05A

## Preconditions

Customer metadata contains one or both of the following fields:

- `rhs_site_id`
- `rhs_survey_id`

## Steps to Reproduce

1. Launch the Dashboard.
2. Open the metadata upload / validation workflow.
3. Upload metadata containing `rhs_survey_id` but no `rhs_site_id`.
4. Run metadata validation.
5. Observe the validation result.
6. Repeat using metadata containing both `rhs_site_id` and `rhs_survey_id` with different values.

## Expected Result

- `rhs_survey_id` is accepted as the supported RHS identifier.
- `rhs_site_id` is not required for the RHS workflow.
- The Dashboard does not reject the file solely because `rhs_site_id` and `rhs_survey_id` contain different values.
- The Dashboard does not silently treat `rhs_site_id` as equivalent to `rhs_survey_id`.

## Actual Result

- Metadata containing only `rhs_survey_id` was reported as missing `rhs_site_id`.
- Metadata containing both `rhs_site_id` and `rhs_survey_id` with different values was rejected as conflicting.
- Metadata containing only `rhs_site_id` was accepted as the RHS mapping identifier.

## Customer-Confirmed Requirement

The customer confirmed that:

> `rhs_survey_id` should be sufficient for the RHS workflow because RHS is being treated as site-level data.

## Impact

- Valid customer metadata may be rejected.
- The current validation rules may force users to modify correct customer data to fit the current schema.
- There is a risk of using the wrong RHS identifier in downstream import and mapping logic.
- Current behaviour may lead to incomplete or incorrect RHS record matching.

## Evidence

- FT-01B
- FT-01C
- FT-01D
- FT-05A
- `FT-05A_rhs_identifier_mapping_inconsistency.png`

## Suggested Fix

- Update metadata validation to use `rhs_survey_id` as the supported RHS identifier.
- Remove `rhs_site_id` as a required RHS field.
- Remove or revise any logic that silently copies or converts `rhs_site_id` into `rhs_survey_id`.
- Add automated regression tests for:
  - `rhs_survey_id` only
  - `rhs_site_id` only
  - both identifiers present
  - different values in the two fields

## Retest Criteria

The defect can be considered fixed when:

1. Metadata containing only `rhs_survey_id` passes validation.
2. `rhs_site_id` is no longer required.
3. Metadata is not rejected solely because the two RHS identifier fields differ.
4. No silent conversion from `rhs_site_id` to `rhs_survey_id` occurs.
5. RHS import uses the intended `rhs_survey_id`.
6. Relevant automated regression tests pass.