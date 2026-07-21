# BUG-003: Flow Statistics Calculation Fails and Remains Loading When Duplicate Dates Are Detected

## Summary

The Flow Statistics calculation fails when duplicate dates are detected in the imported HDE Flow dataset.

The issue was observed while testing a customer-derived dataset containing 49 mapped Flow sites.

The R Console reported:

```text
Error in calc_flowstats: Duplicate dates identified
```

No Flow Statistics output was generated, and the Dashboard remained in a loading state.

It is not yet confirmed whether the duplicate dates originate from:

- the HDE source data;
- one or more specific Flow sites;
- multiple records being returned for the same site and date;
- or the Dashboard import or transformation process.

The issue appears to be data-dependent and requires further investigation.

## Status

Open – reproduction uses non-canonical metadata input

## Severity

To be confirmed

## Priority

Medium

## Environment

- Branch: `main`
- Current retest baseline: `08b595a`
- Platform: Windows 11
- Browser: Google Chrome
- Flow source: `HDE`
- Test type: Functional Testing
- Test data: 49-site customer-derived HDE metadata dataset
- Number of mapped Flow sites: 49

## Related Test Cases

- FT-07A
- FT-07A-R1
- FT-07A-R2

## Preconditions

1. The Dashboard is launched successfully.
2. A 49-site customer-derived metadata dataset is loaded successfully.
3. HDE Flow data are imported successfully.
4. Imported Flow data are displayed in the Dashboard.

## Steps to Reproduce

The original issue was observed using the following workflow:

1. Launch the Dashboard.
2. Load the 49-site customer-derived metadata dataset.
3. Import Flow data using HDE.
4. Confirm that imported Flow data are displayed successfully.
5. Navigate to `Process Flow`.
6. Click `Calculate flow statistics`.
7. Observe the R Console and Dashboard behaviour.

## Expected Result

The Dashboard should calculate and display Flow Statistics for the imported Flow data.

If duplicate dates are detected, the Dashboard should handle them in a defined and user-visible way.

For example, the Dashboard should either:

- process duplicate records according to a documented rule;
- prevent calculation and display a clear user-facing validation message;
- or identify the affected site and date records so that the user can take corrective action.

The loading state should always terminate after either success or failure.

## Actual Result

The Flow Statistics calculation failed.

The R Console reported:

```text
Error in calc_flowstats: Duplicate dates identified
```

No Flow Statistics output was generated.

The Dashboard remained in a loading state and did not display a clear user-facing error message explaining the failure.

## Test Input Limitation

The original failing run used a temporary RHS metadata workaround in which `rhs_survey_id` values were duplicated into `rhs_site_id` to satisfy the legacy metadata validator.

This workaround is not compliant with the confirmed canonical RHS metadata contract and should not be used as a normative regression fixture.

The duplicate-date failure is retained as an observed test result because it occurred after HDE Flow data were imported successfully.

However, `BUG-003` should be re-executed using canonical metadata containing `rhs_survey_id` without `rhs_site_id` once `BUG-002` has been resolved.

Until that retest is completed, the original reproduction has a non-canonical test-input limitation.

## Current Assessment

The controlled subset tests use fixed, nested site sets:

- 10-site subset: the first 10 customer sites;
- 20-site subset: the first 20 customer sites;
- 49-site dataset: all 49 customer sites.

The 10-site subset completed successfully.

The 20-site subset also completed Flow Statistics calculation successfully.

The 49-site dataset failed with:

```text
Error in calc_flowstats: Duplicate dates identified
```

Because the 10-site and 20-site datasets are fixed subsets of the 49-site dataset, the available evidence suggests that the failure may be triggered by one or more sites included after the first 20 records rather than by dataset size alone.

Further investigation is required to identify:

- which specific site or sites contain duplicate-date records;
- the specific duplicated dates and record counts;
- whether the duplicate records originate directly from HDE;
- or whether duplicates are introduced during Dashboard data processing.

The confirmed defect at this stage is that the Dashboard does not recover cleanly when duplicate dates are detected and does not provide a clear user-facing explanation of the failure.

### Retest Result: 10-Site Subset

A controlled retest was performed using the fixed first 10 customer sites from the same customer-derived HDE metadata.

The 10-site subset completed successfully:

- HDE Flow data were imported successfully.
- Flow Statistics were calculated successfully.
- The calculated Flow Statistics table was displayed correctly.
- The previous `Duplicate dates identified` error did not occur.

The Flow Statistics results were generated successfully, although the progress indicator remained at `99%`. This progress behaviour is tracked separately under `OBS-007`.

This indicates that the Flow Statistics calculation does not fail for all customer data.

### Retest Result: 20-Site Subset

A controlled retest was performed using the fixed first 20 customer sites from the same customer-derived HDE metadata.

The 20-site subset completed successfully:

- HDE Flow data were imported successfully.
- Flow Statistics were calculated successfully.
- The calculated Flow Statistics table was displayed.
- The progress indicator reached `100%`.
- The previous `Duplicate dates identified` error did not occur.

Because the 10-site and 20-site datasets are fixed nested subsets of the 49-site dataset, the available evidence suggests that the failure may be triggered by one or more sites included after the first 20 records rather than by dataset size alone.

## Impact

- Flow Statistics cannot be generated for the affected dataset.
- Downstream Analysis may be blocked because Flow Statistics are unavailable.
- The user receives no clear in-app explanation of the failure.
- The Dashboard may remain in a permanent loading state.
- Customer datasets containing duplicate-date records may not be processed successfully.

## Evidence

- `../test_2026-07-10_evidence/FT-07A_flow_statistics_duplicate_dates_error.png`

The Console evidence shows:

```text
Error in calc_flowstats: Duplicate dates identified
```

The captured failure evidence also shows that Flow Statistics did not complete successfully.

No separate loading-state screenshot is currently referenced because only the available committed evidence should be listed in this defect record.

## Suggested Investigation

1. Identify the `flow_site_id` values containing duplicate dates.
2. Identify the specific duplicated dates and record counts.
3. Determine whether the duplicate records originate directly from HDE.
4. Check whether the import or transformation pipeline introduces duplicates.
5. Compare the fixed:
   - 10-site subset;
   - 20-site subset;
   - 49-site dataset.
6. Narrow the affected site range using fixed nested subsets.
7. Define the expected duplicate-date handling behaviour.
8. Reproduce the issue using canonical `rhs_survey_id`-only metadata after `BUG-002` is resolved.

## Suggested Fix

The appropriate fix should depend on the investigation result.

At minimum:

- the Dashboard should not remain indefinitely in a loading state after the calculation fails;
- the user should receive a clear error message;
- the affected site and duplicate-date information should be made available where possible.

If duplicate records are expected from the source data, the application should implement and document a deterministic handling rule.

## Retest Criteria

The defect can be considered resolved when:

1. Flow Statistics complete successfully for valid datasets without duplicate-date conflicts.
2. Duplicate-date datasets are handled according to a defined rule.
3. The Dashboard displays a clear user-facing message when calculation cannot continue.
4. The affected site and duplicate records can be identified where applicable.
5. The loading state terminates correctly after both success and failure.
6. Fixed 10-site, 20-site, and 49-site test datasets have documented results.
7. Relevant regression tests pass.
8. The duplicate-date behaviour has been retested using canonical metadata containing `rhs_survey_id` without `rhs_site_id`.