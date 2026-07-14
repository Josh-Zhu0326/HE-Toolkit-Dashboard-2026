# BUG-003: Flow Statistics Calculation Fails and Remains Loading When Duplicate Dates Are Detected

## Summary

The Flow Statistics calculation fails when duplicate dates are detected in the imported HDE Flow dataset.

The issue was observed while testing the customer-derived dataset containing 49 mapped Flow sites.

The R Console reported:

`Error in calc_flowstats: Duplicate dates identified`

No Flow Statistics output was generated, and the Dashboard remained in a loading state.

At this stage, it is not yet confirmed whether the duplicate dates are caused by:

- the HDE source data;
- the number or combination of selected Flow sites;
- multiple records being returned for the same site and date;
- or the Dashboard import / transformation process.

The issue therefore appears to be data-dependent and requires further investigation.

## Severity

To be confirmed

## Priority

Medium

## Environment

- Branch: `main`
- Platform: Windows 11
- Browser: Google Chrome
- Flow source: HDE
- Test type: Functional Testing
- Test data: Customer-derived metadata workaround dataset
- Number of mapped Flow sites: 49

## Preconditions

1. The Dashboard is launched successfully.
2. Customer-derived metadata is uploaded successfully.
3. `flow_input` is set to `HDE`.
4. The temporary RHS metadata workaround is used to bypass `BUG-002`.
5. HDE Flow data are imported successfully.
6. Imported Flow data are displayed in the Dashboard.

## Steps to Reproduce

1. Launch the Dashboard.
2. Upload the customer-derived metadata workaround file.
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

`Error in calc_flowstats: Duplicate dates identified`

No Flow Statistics output was generated.

The Dashboard remained in a loading state and did not display a clear user-facing error message explaining the failure.

## Current Assessment

The controlled subset tests use fixed, nested site sets:

- 10-site subset: the first 10 customer sites;
- 20-site subset: the first 20 customer sites;
- 49-site dataset: all 49 customer sites.

The 10-site subset completed successfully.

The 20-site subset also progressed through Flow Statistics calculation successfully.

The 49-site dataset failed with:

`Error in calc_flowstats: Duplicate dates identified`

Because the 10-site and 20-site subsets are fixed subsets of the 49-site dataset, this suggests that the failure is more likely to be triggered by one or more sites included after the first 20 records, rather than by dataset size alone.

Further investigation is required to identify:

- which specific site or sites contain duplicate-date records;
- whether the duplicate records originate directly from HDE;
- or whether duplicates are introduced during Dashboard data processing.

The confirmed defect at this stage is that the Dashboard does not recover cleanly when duplicate dates are detected and does not provide a clear user-facing explanation of the failure.

### Retest Result

A controlled retest was performed using a 10-site subset of the same customer-derived HDE metadata.

The 10-site subset completed successfully:

- HDE Flow data were imported successfully.
- Flow Statistics were calculated successfully.
- The calculated Flow Statistics table was displayed correctly.
- The previous `Duplicate dates identified` error did not occur.

This indicates that the failure observed with the 49-site dataset is data-dependent and may be triggered by one or more specific sites or duplicate-date records in the larger dataset, rather than by the Flow Statistics function failing for all customer data.

## Impact

- Flow Statistics cannot be generated for the affected dataset.
- Downstream Analysis may be blocked because Flow Statistics are unavailable.
- The user receives no clear in-app explanation of the failure.
- The Dashboard may remain in a permanent loading state.
- Large or realistic customer datasets containing duplicate-date records may not be processed successfully.

## Evidence

- R Console screenshot showing:

  `Error in calc_flowstats: Duplicate dates identified`

- Process Flow screenshot showing the Dashboard remaining in a loading state.

## Suggested Investigation

1. Identify the `flow_site_id` values containing duplicate dates.
2. Identify the specific duplicated dates and record counts.
3. Determine whether the duplicate records originate directly from HDE.
4. Check whether the import or transformation pipeline introduces duplicates.
5. Repeat the Flow Statistics test using controlled subsets:
   - 5 sites
   - 10 sites
   - 20 sites
   - 49 sites
6. Compare whether the failure depends on:
   - dataset size;
   - specific sites;
   - or specific duplicate-date records.
7. Define the expected duplicate-date handling behaviour.

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
6. Controlled subset tests with 5, 10, 20, and 49 sites have been executed and documented.
7. Relevant regression tests pass.