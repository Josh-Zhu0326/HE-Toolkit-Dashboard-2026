# BUG-001: Analysis Pairing Can Fail at 99% with a Missing TRUE/FALSE Error

## Summary

During the initial smoke test, the Biology–Flow pairing operation failed while processing the Analysis workflow.

The operation reached `99%` and did not complete successfully.

The R Console reported:

```text
Error in if: missing value where TRUE/FALSE needed
```

No complete joined dataset was produced during the failing run.

The issue has not been reproduced consistently in later controlled retests.

## Status

Open – not consistently reproducible

## Severity

To be confirmed

## Priority

Medium

## Environment

- Branch: `main`
- Platform: Windows 11
- Browser: Google Chrome
- Test type: Smoke Testing / Functional Retesting
- Initial test data: Dashboard-provided demo data
- Analysis settings:
  - Lag: `0`
  - Join method: `A`

## Related Test Cases

- ST-05A
- FT-08A-R1
- FT-08A-R2

## Preconditions

For the original failing run:

1. The Dashboard was launched successfully.
2. Demo metadata were loaded.
3. Biology data were imported.
4. Environmental data were imported.
5. Flow data were imported.
6. RICT predictions were completed.
7. O:E ratios were calculated.
8. Flow processing was completed.
9. Flow Statistics were generated.
10. The Analysis page was opened.

## Steps to Reproduce

The issue was originally observed using the following workflow:

1. Launch the Dashboard.
2. Import the supplied demo metadata.
3. Import Biology data.
4. Import Environmental data.
5. Import Flow data.
6. Run RICT predictions.
7. Calculate O:E ratios.
8. Complete Flow processing.
9. Calculate Flow Statistics.
10. Navigate to `Analysis`.
11. Select:
    - Lag: `0`
    - Join method: `A`
12. Click `Pair biology and flow data`.
13. Observe the progress indicator and R Console.

## Expected Result

The Dashboard should complete the Biology–Flow pairing operation and display the joined dataset.

If a valid data prerequisite prevents pairing, the Dashboard should:

- identify the affected condition;
- display a clear user-facing message;
- terminate the progress state cleanly;
- leave the Dashboard in a usable state.

## Actual Result

During the original smoke test, the operation reached `99%` and remained in a loading state.

No complete joined dataset was displayed.

The R Console reported:

```text
Error in if: missing value where TRUE/FALSE needed
```

The error was reported from `server.R#1385`.

Additional warnings indicated that:

- some Biology dates preceded the earliest Flow Statistics window;
- several Biology site IDs were not found in the metadata mapping;
- several Flow site IDs were not found in the metadata mapping.

## Initial Impact

During the original failing run:

- the main Analysis workflow could not be completed;
- downstream Analysis functions depending on the joined dataset were blocked;
- the HEV workflow was also blocked because paired Biology–Flow data were unavailable.

## Retest Result: 10-Site Customer Subset

A controlled retest was performed using a fixed 10-site customer subset with:

- successfully imported HDE Flow data;
- successfully calculated Flow Statistics;
- successful RICT prediction;
- successful O:E calculation.

The previous error:

```text
Error in if: missing value where TRUE/FALSE needed
```

did not occur.

Instead, the Dashboard displayed a clear user-facing warning that one or more Biology samples preceded the start date of the earliest available Flow period for several sites.

The R Console reported the same date-range mismatch condition.

The original `BUG-001` error was therefore not reproduced with the 10-site subset.

## Retest Result: 20-Site Customer Subset

A further retest was performed using a fixed 20-site customer subset.

The previous error:

```text
Error in if: missing value where TRUE/FALSE needed
```

did not occur.

The Dashboard generated paired Biology–Flow data and displayed a clear user-facing warning that some Biology samples preceded the earliest available Flow period for several sites.

This result was consistent with the 10-site retest.

The current limitation in this run was a data time-range mismatch rather than the original Analysis pairing error.

## Retest Result: Demo Data Without Flow Imputation

A controlled retest was performed using the Dashboard-provided demo data without:

- donor mapping;
- additional donor Flow data;
- Flow imputation.

The Biology–Flow pairing operation completed without reproducing:

```text
Error in if: missing value where TRUE/FALSE needed
```

The Dashboard instead displayed a valid warning relating to Biology sample dates preceding the earliest available Flow period.

## Retest Result: Demo Data With Flow Imputation

A second demo-data retest was performed using:

- donor mapping;
- additional donor Flow data;
- Flow imputation;
- Flow Statistics;
- the same Analysis settings as the original failing run.

The previous error:

```text
Error in if: missing value where TRUE/FALSE needed
```

did not occur.

The Analysis pairing operation completed successfully.

## Current Assessment

The original Analysis pairing failure is not currently consistently reproducible.

The issue occurred during the initial smoke test but was not reproduced in the following controlled retests:

- 10-site customer subset;
- 20-site customer subset;
- demo dataset without Flow imputation;
- demo dataset with donor mapping, additional donor Flow data, and Flow imputation.

This suggests that the original failure may depend on:

- a specific data state;
- a specific combination of imported records;
- an intermediate reactive state;
- another condition that has not yet been isolated.

The available evidence does not currently support the conclusion that Flow imputation alone causes the failure.

The issue should remain open as an intermittent or data-state-dependent defect until the original failure can be reproduced reliably or the root cause is identified.

## Impact

The original failure was significant because it blocked:

- Biology–Flow pairing;
- downstream Analysis outputs;
- HEV outputs dependent on paired data.

However, because the issue has not been reproduced in multiple controlled retests, the current frequency and practical impact remain uncertain.

## Evidence

- `ST-05A_pairing_error.png`
- Original R Console output showing:

```text
Error in if: missing value where TRUE/FALSE needed
```

- 10-site retest showing a data time-range warning instead of the original error.
- 20-site retest showing paired data and a data time-range warning.
- Demo-data retests with and without Flow imputation where the original error did not occur.

## Suggested Investigation

1. Compare the exact application state from the original failing run with the successful retests.
2. Review the logic around `server.R#1385`.
3. Check whether the affected `if` condition can receive:
   - `NA`;
   - an empty value;
   - a vector instead of a single `TRUE` or `FALSE`.
4. Review whether missing site mappings or missing date-window values can produce an `NA` condition.
5. Add defensive validation before the affected conditional logic.
6. Add targeted logging around the affected code path.
7. Add an automated regression test if a reproducible triggering dataset is identified.

## Suggested Fix

A fix should not be applied solely on the basis of the currently available evidence unless the root cause is confirmed.

At minimum, the affected conditional logic should be reviewed to ensure that:

- `NA` values are handled explicitly;
- missing prerequisite data produce clear validation messages;
- the pairing workflow terminates cleanly after failure;
- the progress indicator does not remain indefinitely at `99%`.

## Retest Criteria

The defect can be considered resolved when:

1. The original triggering condition can be reproduced and identified, or the vulnerable conditional logic is confirmed.
2. The pairing workflow no longer throws:

```text
Error in if: missing value where TRUE/FALSE needed
```

3. Missing or invalid prerequisite data are handled with a clear user-facing message.
4. The progress state terminates correctly after both success and failure.
5. The joined dataset is generated successfully for valid inputs.
6. A regression test covers the confirmed root cause or triggering data condition.