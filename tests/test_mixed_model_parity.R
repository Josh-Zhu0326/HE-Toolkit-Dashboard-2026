# test_mixed_model_parity.R
# Numerical parity for the mixed model (MC-O10).
# The fixed-effect estimates from run_mixed_model() (lme4) are checked against an
# independent implementation (nlme::lme, a base "recommended" package) fitted on
# the same model frame. They must agree within 1e-4.
#
# Run in RStudio: Source this file. Needs lme4 and nlme.
# If lme4 is not installed the check is skipped with a message.

source(file.path("R", "mixed_model_helpers.R"))

if (!requireNamespace("lme4", quietly = TRUE) || !requireNamespace("nlme", quietly = TRUE)) {
  cat("test_mixed_model_parity.R: skipped (needs lme4 and nlme)\n")
} else {

  # A well-behaved multi-site dataset with a clear site effect (so the fit is
  # NOT singular) and only 2 distinct years per site (so the model uses a random
  # intercept, matching the nlme reference random = ~1 | biol_site_id).
  set.seed(42)
  sites <- paste0("S", 1:8)
  rows <- do.call(rbind, lapply(sites, function(s) {
    data.frame(biol_site_id = s,
               sampling_year = c(2020, 2020, 2021, 2021),
               Q95z_lag0 = round(rnorm(4), 3),
               stringsAsFactors = FALSE)
  }))
  site_effect <- stats::setNames(rnorm(length(sites), sd = 1.0), sites)   # strong -> not singular
  rows$LIFE_F_OE <- 1 + 0.3 * rows$Q95z_lag0 +
    0.1 * (rows$sampling_year - 2020.5) +
    site_effect[rows$biol_site_id] + rnorm(nrow(rows), sd = 0.2)

  spec <- list(response = "LIFE_F_OE", flow_predictors = "Q95z_lag0")
  res <- run_mixed_model(rows, spec)

  stopifnot(res$status %in% c("success", "warning"))
  stopifnot(res$model_path == "multi_site_mixed")
  stopifnot(res$random_effect_structure == "(1 | biol_site_id)")   # intercept-only
  stopifnot(!is.null(res$fixed_effects))

  # Independent reference: same model frame with nlme.
  ref_df <- rows
  ref_df$sampling_year_centered <- ref_df$sampling_year - 2020.5     # same centring
  ref <- nlme::lme(LIFE_F_OE ~ Q95z_lag0 + sampling_year_centered,
                   random = ~ 1 | biol_site_id, data = ref_df, method = "REML")
  ref_fe <- nlme::fixef(ref)

  model_fe <- stats::setNames(res$fixed_effects$Estimate, res$fixed_effects$term)
  common <- intersect(names(ref_fe), names(model_fe))
  stopifnot(length(common) == length(ref_fe))            # all terms line up

  diffs <- abs(model_fe[common] - ref_fe[common])
  cat("  max fixed-effect difference vs nlme:", format(max(diffs), scientific = TRUE), "\n")
  stopifnot(max(diffs) < 1e-4)                            # MC-O10 tolerance

  cat("test_mixed_model_parity.R: all checks passed\n")
}
