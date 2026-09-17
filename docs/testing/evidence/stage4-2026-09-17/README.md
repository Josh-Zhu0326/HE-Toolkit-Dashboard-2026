# Stage 4 rendering verification

Verified on 2026-09-17 with synthetic test fixtures.

- `pairwise-correlations.png`: full browser screenshot of the dashboard after loading a checkpoint with lag 3 and no WHPT_ASPT_OE field. The correlation matrix renders using the available fields.
- `historical-coverage-exclusion.png`: PNG captured from the real Shiny Historical Coverage output in `test-stage4-plots.R` after excluding sample S2. This is a server-rendered plot, not a browser screenshot. The full Flow history is retained while the sample coverage changes.

Browser checks also verified that clearing all selected samples shows a data-sufficiency message, restoring the selection redraws the correlation matrix, and the session stays connected. Checkpoint-only Historical Coverage explains that a fresh Biology–Flow pairing is required because the checkpoint does not contain full Flow history.

The targeted regression run passed 490 assertions with no failures, errors or warnings:

```r
options(device = function(...) grDevices::pdf(file = NULL))
testthat::test_dir(
  "tests/testthat",
  filter = "stage4-plots|plot-recovery|workflow-server|stage3-enrichment-currentness|hev-plot-helpers|processed-dataset-checkpoint",
  reporter = "summary"
)
```

`Rscript --vanilla tests/test_analysis_filter_helpers.R` also passed.
