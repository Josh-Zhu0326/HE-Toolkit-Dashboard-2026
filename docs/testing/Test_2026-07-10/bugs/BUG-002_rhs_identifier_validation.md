# BUG-002: Metadata Validation Accepts and Generates Non-Canonical RHS Aliases

## Summary

The Dashboard currently accepts and generates non-canonical RHS identifier behaviour involving `rhs_site_id`.

The confirmed RHS metadata contract uses `rhs_survey_id` as the supported canonical RHS identifier.

However, the current implementation can:

- accept `rhs_site_id` as an RHS identifier;
- copy or alias `rhs_site_id` into `rhs_survey_id`;
- accept metadata containing both fields when their values are identical;
- reject both fields only when their values differ.

This behaviour does not consistently enforce `rhs_survey_id` as the sole supported RHS identifier.

## Status

Open

## Severity

Medium

## Priority

High

## Environment

- Branch: `main`
- Initial test commit: `7cf242f`
- Current retest baseline: `08b595a`
- Platform: Windows 11
- Browser: Google Chrome
- Test type: Functional Testing
- Test data: Customer-provided and customer-derived metadata

## Related Test Cases

- FT-01B
- FT-01C
- FT-01D
- FT-01E
- FT-01F
- FT-01L
- FT-01M
- FT-05A

## Confirmed Requirement

The customer confirmed that `rhs_survey_id` should be sufficient for the RHS workflow because RHS is being treated as site-level data.

The resulting canonical metadata contract is:

- `rhs_survey_id` is the supported RHS identifier;
- `rhs_site_id` is not a supported Dashboard metadata field;
- metadata containing `rhs_site_id` should not be accepted as canonical input;
- the Dashboard should not silently copy or alias `rhs_site_id` into `rhs_survey_id`.

External source fields may be explicitly mapped or renamed to `rhs_survey_id` during import, but the normalised internal and output schema should not retain or generate `rhs_site_id`.

## Preconditions

Prepare metadata covering the following RHS identifier combinations:

1. `rhs_survey_id` only.
2. `rhs_site_id` only.
3. Both fields with identical values.
4. Both fields with different values.

## Steps to Reproduce

### Case A: `rhs_survey_id` Only

1. Launch the Dashboard.
2. Open the metadata upload workflow.
3. Upload metadata containing `rhs_survey_id` but no `rhs_site_id`.
4. Run metadata validation.
5. Observe the validation result.

### Case B: `rhs_site_id` Only

1. Restart or clear the Dashboard session.
2. Upload metadata containing `rhs_site_id` but no `rhs_survey_id`.
3. Run metadata validation.
4. Observe the validation result.

### Case C: Both Fields with Identical Values

1. Restart or clear the Dashboard session.
2. Upload metadata containing both `rhs_site_id` and `rhs_survey_id`.
3. Use identical values in both columns.
4. Run metadata validation.
5. Observe the validation result.

### Case D: Both Fields with Different Values

1. Restart or clear the Dashboard session.
2. Upload metadata containing both `rhs_site_id` and `rhs_survey_id`.
3. Use different values in the two columns.
4. Run metadata validation.
5. Observe the validation result.

## Expected Result

### Case A: `rhs_survey_id` Only

Metadata containing `rhs_survey_id` should be accepted as valid RHS metadata.

The Dashboard should not require `rhs_site_id`.

### Case B: `rhs_site_id` Only

Metadata containing `rhs_site_id` should be rejected.

The user should receive a clear validation message instructing them to provide `rhs_survey_id` and remove or rename the unsupported `rhs_site_id` field.

The Dashboard should not silently generate `rhs_survey_id` from `rhs_site_id`.

### Case C: Both Fields with Identical Values

Metadata containing both `rhs_site_id` and `rhs_survey_id` should be rejected.

The validation message should explain that `rhs_site_id` is not part of the supported Dashboard metadata schema and should be removed.

Identical values should not make the non-canonical alias acceptable.

### Case D: Both Fields with Different Values

Metadata containing both `rhs_site_id` and `rhs_survey_id` should be rejected.

The validation message should explain that `rhs_site_id` is not supported and should be removed.

The file should not be accepted by selecting one identifier silently.

## Actual Result

The current Dashboard behaviour does not consistently enforce the canonical RHS identifier contract.

Observed behaviour includes:

- metadata containing only `rhs_survey_id` being reported as missing `rhs_site_id`;
- metadata containing only `rhs_site_id` being accepted as the RHS mapping identifier;
- `rhs_site_id` being made available internally as `rhs_survey_id`;
- metadata containing both fields with different values being rejected as conflicting;
- metadata containing both fields with identical values being accepted.

A temporary test workaround duplicated `rhs_survey_id` values into `rhs_site_id`.

This workaround passed validation and allowed 49 RHS entries to be displayed.

However, the workaround uses an unsupported alias field and therefore does not represent valid behaviour under the confirmed RHS metadata contract.

## Impact

- Valid metadata containing only `rhs_survey_id` may be rejected.
- Non-canonical metadata containing `rhs_site_id` may be accepted.
- Users may be forced to modify valid source metadata to satisfy an obsolete schema requirement.
- Silent aliasing may hide identifier-contract problems.
- Test fixtures and regression expectations may preserve obsolete behaviour.
- Downstream RHS mapping may become difficult to interpret because the supported identifier is not enforced consistently.

## Current Assessment

This issue was originally recorded as `OBS-008` while the intended relationship between `rhs_site_id` and `rhs_survey_id` was awaiting customer clarification.

The customer has now confirmed that `rhs_survey_id` is sufficient for the RHS workflow.

The issue is therefore no longer an unresolved identifier-model question.

The current Dashboard behaviour conflicts with the confirmed canonical RHS metadata contract because it accepts or generates `rhs_site_id` aliases instead of enforcing `rhs_survey_id`.

`OBS-008` has therefore been upgraded to `BUG-002`.

## Evidence

- FT-01B
- FT-01C
- FT-01D
- FT-05A
- `FT-05A_rhs_identifier_mapping_inconsistency.png`

The existing RHS page and validation behaviour show inconsistent treatment of `rhs_site_id` and `rhs_survey_id`.

The successful 49-entry RHS workaround used duplicated `rhs_survey_id` values in `rhs_site_id` and is retained only as evidence of current compatibility behaviour, not as a valid expected workflow.

## Suggested Fix

- Remove `rhs_site_id` from the supported Dashboard metadata schema.
- Remove silent copying or aliasing from `rhs_site_id` to `rhs_survey_id`.
- Accept `rhs_survey_id` as the canonical RHS identifier.
- Reject metadata containing `rhs_site_id`, including when both RHS columns contain identical values.
- Display a clear validation message instructing the user to remove `rhs_site_id` and use `rhs_survey_id`.
- Where an external RHS source exposes a differently named survey identifier, explicitly map or rename that field to `rhs_survey_id` at the import boundary.
- Ensure normalised internal and output data do not retain or generate `rhs_site_id`.
- Update obsolete fixtures and automated tests that currently assert legacy aliasing behaviour.

## Retest Criteria

The defect can be considered resolved when:

1. Metadata containing only `rhs_survey_id` passes validation.
2. Metadata containing only `rhs_site_id` is rejected with a clear user-facing validation message.
3. Metadata containing both RHS identifier columns with identical values is rejected.
4. Metadata containing both RHS identifier columns with different values is rejected.
5. The validation message clearly instructs users to remove `rhs_site_id` and retain `rhs_survey_id`.
6. No helper silently copies or aliases `rhs_site_id` into `rhs_survey_id`.
7. External source identifier fields are explicitly canonicalised to `rhs_survey_id` where required.
8. Normalised internal and output schemas do not contain or generate `rhs_site_id`.
9. Updated regression tests pass.