# test_analysis_model_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_analysis_model_helpers.R: all checks passed"

source(file.path("R", "analysis_model_helpers.R"))

joined <- read.csv(file.path("tests", "fixtures", "analysis_dataset.csv"),
                   stringsAsFactors = FALSE, colClasses = c(sample_id = "character"))

# --- 1. Single-site additive model fits and returns the contract fields -----
spec <- list(response = "LIFE_F_OE", flow_predictors = c("Q95_lag0", "Q10_lag0"))
res <- run_analysis_model(joined, spec)
stopifnot(identical(res$status, "success"))
stopifnot(res$model_path == "single_site_additive")
stopifnot(res$site_count == 1)
stopifnot(!is.null(res$fixed_effects))
stopifnot(!is.null(res$fit_metrics))
stopifnot(!is.null(res$diagnostics))
# year centring applied (5 distinct years in the fixture)
stopifnot(!is.na(res$year_center))
stopifnot(grepl("sampling_year_centered", res$formula))
# all MC-R06 fields are present
for (f in c("status","messages","formula","model_path","random_effect_structure",
            "n_input","n_complete","n_excluded","site_count","year_range","year_center",
            "fixed_effects","random_effects","fit_metrics","diagnostics",
            "convergence_status","singularity_status","provenance")) {
  stopifnot(f %in% names(res))
}

# --- 2. Two or more sites -> not_ready, never fits a pooled model ------------
multi <- joined
multi$biol_site_id <- c("291","291","292","292","292")
res_multi <- run_analysis_model(multi, spec)
stopifnot(identical(res_multi$status, "not_ready"))
stopifnot(res_multi$model_path == "multi_site_candidate")
stopifnot(is.null(res_multi$fixed_effects))         # nothing was fitted

# --- 3. Missing columns -> friendly blocked, not a crash --------------------
stopifnot(identical(run_analysis_model(joined, list(response = "nope",
          flow_predictors = "Q95_lag0"))$status, "blocked"))

# --- 4. No predictor selected -> blocked ------------------------------------
stopifnot(identical(run_analysis_model(joined, list(response = "LIFE_F_OE"))$status, "blocked"))

# --- 5. Too many flow predictors -> blocked (MC-R02) ------------------------
stopifnot(identical(run_analysis_model(joined,
          list(response = "LIFE_F_OE",
               flow_predictors = c("Q95_lag0","Q10_lag0","Q10z_lag0")))$status, "blocked"))

# --- 6. Empty data -> blocked, not a crash ----------------------------------
stopifnot(identical(run_analysis_model(joined[0, ], spec)$status, "blocked"))

cat("test_analysis_model_helpers.R: all checks passed\n")
