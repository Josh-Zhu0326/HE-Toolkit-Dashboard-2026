# mixed_model_helpers.R
# The multi-site mixed-effects model, following the FROZEN rules in
# docs/contracts/modelling-contract-v1.md (MC-O01 to MC-O11).
#
# In plain terms: when the analysis data has enough sites and rows, we fit a
# mixed model with a random effect for site. We check the data is big enough,
# pick a random intercept or a random slope, check the predictors aren't too
# correlated, and report honestly if it doesn't converge. We NEVER quietly fall
# back to a plain lm().
#
# Needs the lme4 package. R-squared uses performance::r2_nakagawa if available,
# otherwise MuMIn::r.squaredGLMM. If a needed package is missing we return a
# clear "failed" message instead of crashing.
#
# Frozen thresholds (from the contract):
#   MC-O01 min sites            = 5
#   MC-O02 min complete cases   = max(20, 10 * number of fixed-effect params)
#   MC-O03 min obs per site     = 3
#   MC-O06 drop-rate warning    = 20%
#   MC-O07 VIF block / warn     = >10 block, 5-10 warn, |r|>0.9 warn

MIXED_MIN_SITES        <- 5L
MIXED_MIN_OBS_PER_SITE <- 3L
MIXED_MIN_CASES_FLOOR  <- 20L
MIXED_CASES_PER_PARAM  <- 10L
MIXED_DROP_WARN_FRAC   <- 0.20
MIXED_VIF_BLOCK        <- 10
MIXED_VIF_WARN         <- 5
MIXED_CORR_WARN        <- 0.9

# --- small helpers -----------------------------------------------------------

# VIF for a set of numeric predictors (needs at least 2). Returns named values.
.mixed_vif <- function(df, vars) {
  vars <- vars[vars %in% names(df)]
  if (length(vars) < 2) return(stats::setNames(rep(1, length(vars)), vars))
  stats::setNames(vapply(vars, function(v) {
    others <- setdiff(vars, v)
    form <- stats::as.formula(paste(v, "~", paste(others, collapse = " + ")))
    r2 <- tryCatch(summary(stats::lm(form, data = df))$r.squared, error = function(e) NA_real_)
    if (is.na(r2) || r2 >= 1) Inf else 1 / (1 - r2)
  }, numeric(1)), vars)
}

# largest absolute pairwise correlation among numeric predictors
.mixed_max_cor <- function(df, vars) {
  vars <- vars[vars %in% names(df)]
  if (length(vars) < 2) return(0)
  cm <- suppressWarnings(stats::cor(df[, vars, drop = FALSE], use = "complete.obs"))
  cm[!lower.tri(cm)] <- NA
  m <- suppressWarnings(max(abs(cm), na.rm = TRUE))
  if (is.finite(m)) m else 0
}

# MC-O04: can we use a random slope? majority of sites need >=3 distinct years
# and some within-site variation in the year term.
.mixed_slope_ok <- function(df, site_col, year_term) {
  per_site <- split(df[[year_term]], df[[site_col]])
  ok <- vapply(per_site, function(y) {
    y <- y[is.finite(y)]
    length(unique(y)) >= 3 && stats::var(y) > 0
  }, logical(1))
  length(ok) > 0 && mean(ok) > 0.5
}

.mixed_result <- function(status, messages, ...) {
  base <- list(
    status = status, messages = messages,
    formula = NA_character_, model_path = "multi_site_mixed",
    random_effect_structure = NA_character_,
    n_input = NA_integer_, n_complete = NA_integer_, n_excluded = NA_integer_,
    site_count = NA_integer_, year_range = NA_character_, year_center = NA_real_,
    fixed_effects = NULL, random_effects = NULL,
    fit_metrics = NULL, diagnostics = NULL,
    convergence_status = NA_character_, singularity_status = NA_character_,
    provenance = NULL, diagnostic = NULL
  )
  modifyList(base, list(...))
}

# --- main --------------------------------------------------------------------

run_mixed_model <- function(analysis_dataset, model_spec,
                            site_col = "biol_site_id", year_col = "sampling_year",
                            provenance = list()) {

  if (!requireNamespace("lme4", quietly = TRUE)) {
    return(.mixed_result("failed", "The lme4 package is required for the mixed model but is not installed."))
  }

  response   <- model_spec$response
  flow_preds <- model_spec$flow_predictors
  wq_pred    <- model_spec$wq_predictor
  rhs_pred   <- model_spec$rhs_predictor

  # MC-O05 / DEC-21: multi-site flow predictors must be the Z-score fields.
  raw_flow <- flow_preds[!grepl("z_lag", flow_preds)]
  if (length(raw_flow) > 0) {
    return(.mixed_result("blocked", paste0(
      "Multi-site models must use Z-score flow predictors (Q10z/Q95z). ",
      "Raw flow predictor(s) not allowed: ", paste(raw_flow, collapse = ", "), ".")))
  }

  predictors <- c(flow_preds, wq_pred, rhs_pred)
  predictors <- predictors[!is.null(predictors) & nzchar(predictors)]
  needed <- c(response, predictors, site_col)
  if (!all(needed %in% names(analysis_dataset))) {
    missing <- setdiff(needed, names(analysis_dataset))
    return(.mixed_result("blocked",
      paste0("These columns are not in the analysis data: ", paste(missing, collapse = ", "), ".")))
  }

  df <- analysis_dataset
  n_input <- nrow(df)

  # MC-O05: centre the year, standardise WQ predictors (flow already Z-scored)
  use_year <- FALSE; year_center <- NA_real_; year_range <- NA_character_
  if (year_col %in% names(df)) {
    yr <- suppressWarnings(as.numeric(df[[year_col]]))
    valid_years <- unique(yr[is.finite(yr)])
    if (length(valid_years) >= 2) {
      year_center <- (min(valid_years) + max(valid_years)) / 2
      df$sampling_year_centered <- yr - year_center
      year_range <- paste0(min(valid_years), "-", max(valid_years))
      use_year <- TRUE
    }
  }
  scaled_note <- character(0)
  if (!is.null(wq_pred) && nzchar(wq_pred) && wq_pred %in% names(df)) {
    v <- suppressWarnings(as.numeric(df[[wq_pred]]))
    if (stats::sd(v, na.rm = TRUE) > 0) {
      df[[wq_pred]] <- (v - mean(v, na.rm = TRUE)) / stats::sd(v, na.rm = TRUE)
      scaled_note <- c(scaled_note, paste0(wq_pred, " standardised (mean 0, SD 1)"))
    }
  }

  year_term  <- if (use_year) "sampling_year_centered" else NULL
  model_vars <- c(response, predictors, year_term)
  numeric_fixed <- c(flow_preds, if (!is.null(wq_pred) && nzchar(wq_pred)) wq_pred, year_term)

  # MC-O06: complete-case, drop NA/Inf, report loss, warn if > 20%
  ok_rows <- stats::complete.cases(df[, model_vars, drop = FALSE]) &
    apply(df[, numeric_fixed, drop = FALSE], 1, function(r) all(is.finite(suppressWarnings(as.numeric(r)))))
  cc <- df[ok_rows, , drop = FALSE]
  n_complete <- nrow(cc)
  n_excluded <- n_input - n_complete
  warnings_msg <- character(0)
  if (n_input > 0 && n_excluded / n_input > MIXED_DROP_WARN_FRAC) {
    warnings_msg <- c(warnings_msg, paste0(
      round(100 * n_excluded / n_input), "% of rows were dropped for missing values."))
  }

  # MC-O03: keep only sites with >= 3 complete observations
  site_counts <- table(as.character(cc[[site_col]]))
  good_sites <- names(site_counts)[site_counts >= MIXED_MIN_OBS_PER_SITE]
  dropped_small <- setdiff(names(site_counts), good_sites)
  cc <- cc[as.character(cc[[site_col]]) %in% good_sites, , drop = FALSE]
  if (length(dropped_small) > 0) {
    warnings_msg <- c(warnings_msg, paste0(
      length(dropped_small), " site(s) had fewer than ", MIXED_MIN_OBS_PER_SITE,
      " complete rows and were excluded from the fit."))
  }
  site_count <- length(unique(as.character(cc[[site_col]])))

  # MC-O01: at least 5 sites
  if (site_count < MIXED_MIN_SITES) {
    return(.mixed_result("blocked", paste0(
      "A mixed model needs at least ", MIXED_MIN_SITES, " sites; only ", site_count,
      " have enough data. Use the single-site model instead."),
      n_input = n_input, n_complete = n_complete, n_excluded = n_excluded, site_count = site_count))
  }

  # MC-O04: random slope only if the majority of sites support it
  slope <- use_year && .mixed_slope_ok(cc, site_col, "sampling_year_centered")
  re_struct <- if (slope) "(sampling_year_centered | biol_site_id)" else "(1 | biol_site_id)"
  n_random_params <- if (slope) 3L else 1L    # var(intercept)[+var(slope)+cov]
  fixed_terms <- c(predictors, year_term)
  n_fixed <- length(fixed_terms) + 1L         # + intercept

  # MC-O02: enough complete cases
  min_cases <- max(MIXED_MIN_CASES_FLOOR, MIXED_CASES_PER_PARAM * n_fixed)
  if (n_complete < min_cases) {
    return(.mixed_result("blocked", paste0(
      "Not enough complete rows for a mixed model (have ", n_complete, ", need ", min_cases, ")."),
      n_input = n_input, n_complete = n_complete, n_excluded = n_excluded, site_count = site_count))
  }

  # MC-O07: collinearity among numeric fixed predictors
  vif <- .mixed_vif(cc, numeric_fixed)
  max_vif <- suppressWarnings(max(vif, na.rm = TRUE))
  max_cor <- .mixed_max_cor(cc, numeric_fixed)
  if (is.finite(max_vif) && max_vif > MIXED_VIF_BLOCK) {
    return(.mixed_result("blocked", paste0(
      "Predictors are too collinear to fit safely (max VIF ", round(max_vif, 1),
      " > ", MIXED_VIF_BLOCK, "). Remove a predictor."),
      n_input = n_input, n_complete = n_complete, n_excluded = n_excluded, site_count = site_count))
  }
  if (is.finite(max_vif) && max_vif >= MIXED_VIF_WARN) {
    warnings_msg <- c(warnings_msg, paste0("Some predictors are moderately collinear (max VIF ", round(max_vif, 1), ")."))
  }
  if (max_cor > MIXED_CORR_WARN) {
    warnings_msg <- c(warnings_msg, paste0("Two predictors are highly correlated (|r| ", round(max_cor, 2), ")."))
  }

  # --- fit the model, catching convergence problems ------------------------
  formula_txt <- paste(response, "~", paste(fixed_terms, collapse = " + "), "+", re_struct)
  conv_msgs <- character(0)
  fit <- withCallingHandlers(
    tryCatch(
      lme4::lmer(stats::as.formula(formula_txt), data = cc, REML = TRUE),
      error = function(e) e
    ),
    warning = function(w) { conv_msgs <<- c(conv_msgs, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  if (inherits(fit, "error")) {
    return(.mixed_result("failed", "The mixed model did not converge or could not be fitted.",
      formula = formula_txt, random_effect_structure = re_struct,
      n_input = n_input, n_complete = n_complete, n_excluded = n_excluded, site_count = site_count,
      convergence_status = "failed to converge", diagnostic = conditionMessage(fit)))
  }

  # MC-O08: convergence / singularity state
  converged <- length(grep("converge|failed to converge", conv_msgs, ignore.case = TRUE)) == 0
  singular  <- tryCatch(lme4::isSingular(fit), error = function(e) FALSE)
  convergence_status <- if (converged) "converged" else "convergence warning"
  singularity_status <- if (singular) "singular fit" else "not singular"
  if (!converged) {
    return(.mixed_result("failed",
      "The mixed model reported a convergence problem. Try fewer predictors or a random-intercept-only model.",
      formula = formula_txt, random_effect_structure = re_struct,
      n_input = n_input, n_complete = n_complete, n_excluded = n_excluded, site_count = site_count,
      convergence_status = convergence_status, singularity_status = singularity_status))
  }
  if (singular) {
    warnings_msg <- c(warnings_msg,
      "The fit is singular (a random-effect variance is near zero). Consider a random-intercept-only or single-site model.")
  }

  # --- pull out results ----------------------------------------------------
  sm <- summary(fit)
  fe <- as.data.frame(stats::coef(sm))
  fe$term <- rownames(fe); rownames(fe) <- NULL
  vc <- as.data.frame(lme4::VarCorr(fit))

  # MC-O09: Nakagawa marginal / conditional R2
  r2 <- tryCatch({
    if (requireNamespace("performance", quietly = TRUE)) {
      x <- suppressMessages(suppressWarnings(performance::r2_nakagawa(fit)))
      list(marginal = as.numeric(x$R2_marginal), conditional = as.numeric(x$R2_conditional),
           source = paste0("performance ", as.character(utils::packageVersion("performance"))))
    } else if (requireNamespace("MuMIn", quietly = TRUE)) {
      x <- suppressMessages(suppressWarnings(MuMIn::r.squaredGLMM(fit)))
      list(marginal = as.numeric(x[1, "R2m"]), conditional = as.numeric(x[1, "R2c"]),
           source = paste0("MuMIn ", as.character(utils::packageVersion("MuMIn"))))
    } else {
      list(marginal = NA_real_, conditional = NA_real_, source = "R2 package not installed")
    }
  }, error = function(e) list(marginal = NA_real_, conditional = NA_real_, source = paste0("R2 error: ", conditionMessage(e))))

  diagnostics <- data.frame(
    fitted = as.numeric(stats::fitted(fit)),
    residual = as.numeric(stats::resid(fit)),
    stringsAsFactors = FALSE
  )

  status <- if (length(warnings_msg) > 0) "warning" else "success"
  messages <- if (status == "warning") paste(warnings_msg, collapse = " ") else "Mixed-effects model fitted."

  .mixed_result(status, messages,
    formula = formula_txt,
    random_effect_structure = re_struct,
    n_input = n_input, n_complete = n_complete, n_excluded = n_excluded,
    site_count = site_count, year_range = year_range, year_center = year_center,
    fixed_effects = fe, random_effects = vc,
    fit_metrics = list(r2_marginal = r2$marginal, r2_conditional = r2$conditional,
                       r2_source = r2$source, aic = stats::AIC(fit), n_obs = n_complete),
    diagnostics = diagnostics,
    convergence_status = convergence_status, singularity_status = singularity_status,
    provenance = c(provenance, list(
      response = response, predictors = predictors,
      random_effect_structure = re_struct, scaling = scaled_note,
      max_vif = max_vif, max_abs_correlation = max_cor,
      software = R.version.string,
      lme4_version = as.character(utils::packageVersion("lme4")),
      fitted_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))))
}
