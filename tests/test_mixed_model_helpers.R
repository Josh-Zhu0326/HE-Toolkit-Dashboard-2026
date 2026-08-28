# test_mixed_model_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_mixed_model_helpers.R: all checks passed"
#
# The actual model fit needs the lme4 package. If lme4 is not installed, the
# fit-specific checks are skipped and we only confirm the friendly message.

source(file.path("R", "workflow_config.R"))
source(file.path("R", "analysis_model_helpers.R"))
source(file.path("R", "mixed_model_helpers.R"))

# build a multi-site dataset: 8 sites, 5 years each (40 rows)
set.seed(1)
sites <- paste0("S", 1:8)
years <- 2019:2023
grid <- expand.grid(biol_site_id = sites, sampling_year = years, stringsAsFactors = FALSE)
grid$sample_id <- paste0("R", seq_len(nrow(grid)))
grid$Q95z_lag0 <- round(rnorm(nrow(grid)), 3)
# strong site effect (sd 1.0 vs residual 0.2) so the fit is NOT singular and
# lme4 does not print a boundary/singular warning
site_effect <- stats::setNames(rnorm(length(sites), sd = 1.0), sites)
grid$LIFE_F_OE <- 1 + 0.2 * grid$Q95z_lag0 + site_effect[grid$biol_site_id] +
  rnorm(nrow(grid), sd = 0.2)

spec <- list(response = "LIFE_F_OE", flow_predictors = "Q95z_lag0")

# --- 1. Fewer than 5 sites -> blocked (MC-O01) -------------------------------
few <- grid[grid$biol_site_id %in% sites[1:3], ]
res_few <- run_mixed_model(few, spec)
stopifnot(identical(res_few$status, "blocked"))
stopifnot(grepl("at least 5 sites", res_few$messages))

# --- 2. Raw flow predictor rejected for multi-site (MC-O05 / DEC-21) ---------
res_raw <- run_mixed_model(grid, list(response = "LIFE_F_OE", flow_predictors = "Q95_lag0"))
stopifnot(identical(res_raw$status, "blocked"))
stopifnot(grepl("Z-score flow", res_raw$messages))

# --- 3. Routing: run_analysis_model sends multi-site data to the mixed path --
routed <- run_analysis_model(grid, spec)
stopifnot(routed$model_path == "multi_site_mixed")   # never single_site_additive

# --- 4. Result always has the contract fields (MC-R06), any status -----------
for (f in c("status","messages","formula","model_path","random_effect_structure",
            "n_input","n_complete","n_excluded","site_count","fixed_effects",
            "random_effects","fit_metrics","diagnostics","convergence_status",
            "singularity_status","provenance")) {
  stopifnot(f %in% names(routed))
}

# --- 5. If lme4 is available, the model actually fits ------------------------
if (requireNamespace("lme4", quietly = TRUE)) {
  res <- run_mixed_model(grid, spec)
  stopifnot(res$status %in% c("success", "warning"))
  stopifnot(res$model_path == "multi_site_mixed")
  stopifnot(res$site_count == 8)
  stopifnot(!is.null(res$fixed_effects))
  stopifnot(!is.null(res$random_effects))
  stopifnot(!is.null(res$fit_metrics$r2_marginal))       # Nakagawa R2 (MC-O09)
  stopifnot(grepl("biol_site_id", res$random_effect_structure))
  cat("  (lme4 present: mixed model fitted and checked)\n")
} else {
  stopifnot(identical(run_mixed_model(grid, spec)$status, "failed"))
  cat("  (lme4 not installed: skipped fit checks)\n")
}

cat("test_mixed_model_helpers.R: all checks passed\n")
