# Plot overlap regression evidence

Date: 2026-08-03

Branch: `codex/fix-plot-overlap`

Base: `origin/main` at `88f74dc93a704fd86939caed2d17bd6edb521140`

## Scope

This check covers the image-generation overlap bug observed in plot smoke outputs with long site IDs and PCA labels.

## Reproduction

Command:

```sh
Rscript tests/manual/generate_plot_smoke_tests.R
```

Pre-fix visual QA found overlapping labels in:

- `tests/manual/plot_smoke/env_pca_long_labels.png`
- `tests/manual/plot_smoke/wq_preview_mean_bar_long_site_ids.png`
- `tests/manual/plot_smoke/rhs_record_count_long_site_ids.png`

## Fix Evidence

The smoke command was rerun after the fix. Multimodal visual inspection confirmed:

- PCA labels are placed with repelled text and connector segments instead of being drawn directly on top of nearby labels.
- WQ/RHS long site ID plots switch to a horizontal layout.
- Long axis labels are truncated in the plot while full IDs remain available in tables and CSV exports.

Updated evidence images:

- `tests/manual/plot_smoke/env_pca_long_labels.png`
- `tests/manual/plot_smoke/wq_preview_mean_bar_long_site_ids.png`
- `tests/manual/plot_smoke/rhs_record_count_long_site_ids.png`

## Verification Commands

```sh
Rscript tests/test_wq_rhs_plots.R
Rscript tests/manual/generate_plot_smoke_tests.R
```
