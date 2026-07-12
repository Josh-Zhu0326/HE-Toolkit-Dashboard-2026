## Bug Summary

Biology–Flow data pairing reaches 99% but does not complete. No joined dataset is displayed, and the R Console reports an error caused by a missing logical value in an `if` condition.

## Environment

- **Branch:** main
- **Commit ID:** 7cf242f
- **Operating System:** Windows 11
- **Browser:** Google Chrome
- **Test Data:** Dashboard-provided demo data

## Steps to Reproduce

1. Launch the Dashboard.
2. Import the supplied demo metadata.
3. Import Biology, Environmental, and Flow data.
4. Run RICT predictions and calculate O:E ratios.
5. Impute missing Flow data.
6. Calculate Flow Statistics.
7. Open `Analysis` → `Joined Data`.
8. Select a valid lag and join method.
9. Click `Pair biology and flow data`.
10. Observe the progress indicator and R Console.

## Expected Result

The pairing operation should complete and display the joined Biology–Flow dataset.

## Actual Result

The operation reached 99% and remained in a loading state. No joined dataset was displayed.

The R Console reported:

```text
Error in if: missing value where TRUE/FALSE needed
```

The error was reported from:

```text
server.R#1385
```

Additional warnings indicated that:

- some Biology dates preceded the earliest Flow Statistics window;
- several Biology site IDs were not found in the metadata mapping;
- several Flow site IDs were not found in the metadata mapping.

## Severity

High

## Impact

The error prevents the user from completing the main Analysis workflow and blocks subsequent analysis functions that depend on the joined dataset.

## Evidence

- `ST-05A_pairing_error.png`