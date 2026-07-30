# test_analysis_model_parity.R
# Checks the single-site model against an independent hand-computed OLS, and
# checks the export tables. This covers the "numerical parity" and "export"
# parts of WK9-05 / DEBT-12.
# Run in RStudio: Source this file. Expect the "all checks passed" line.

source(file.path("R", "analysis_model_helpers.R"))

joined <- read.csv(file.path("tests", "fixtures", "analysis_dataset.csv"),
                   stringsAsFactors = FALSE, colClasses = c(SAMPLE_ID = "character"))

spec <- list(response = "LIFE_F_OE", flow_predictors = c("Q95_lag0", "Q10_lag0"))
res <- run_analysis_model(joined, spec)
stopifnot(identical(res$status, "success"))

# --- 1. Numerical parity: independent OLS via the normal equations ----------
# Rebuild the same model frame the function used:
#   LIFE_F_OE ~ Q95_lag0 + Q10_lag0 + sampling_year_centered
yr <- as.numeric(joined$Year)
year_center <- (min(unique(yr)) + max(unique(yr))) / 2
X <- cbind(1, joined$Q95_lag0, joined$Q10_lag0, yr - year_center)
y <- joined$LIFE_F_OE
beta_ref <- as.numeric(solve(t(X) %*% X, t(X) %*% y))   # independent coefficients

beta_model <- res$fixed_effects$Estimate                # from run_analysis_model
stopifnot(length(beta_model) == length(beta_ref))
stopifnot(max(abs(beta_model - beta_ref)) < 1e-6)       # must match the reference

# R-squared parity too
ss_res <- sum((y - X %*% solve(t(X) %*% X, t(X) %*% y))^2)
ss_tot <- sum((y - mean(y))^2)
r2_ref <- 1 - ss_res / ss_tot
stopifnot(abs(res$fit_metrics$r_squared - r2_ref) < 1e-6)

# --- 2. Export: summary + coefficients tables -------------------------------
ex <- model_result_export(res)
stopifnot(all(c("field", "value") %in% names(ex$summary)))
stopifnot("r_squared" %in% ex$summary$field)
stopifnot("formula" %in% ex$summary$field)
stopifnot(any(grepl("provenance_", ex$summary$field)))   # provenance included
stopifnot(!is.null(ex$coefficients))                     # coefficient table present
stopifnot(nrow(ex$coefficients) == length(beta_ref))

# --- 3. Export still works for a not_ready result (no crash) -----------------
multi <- joined
multi$biol_site_id <- c("291", "291", "292", "292", "292")
ex_multi <- model_result_export(run_analysis_model(multi, spec))
stopifnot(any(ex_multi$summary$field == "status"))
stopifnot(is.null(ex_multi$coefficients))                # nothing was fitted

cat("test_analysis_model_parity.R: all checks passed\n")
