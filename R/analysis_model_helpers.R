# analysis_model_helpers.R
# This is for WK8-08. It runs the model on the analysis_dataset.
#
# Important: the modelling contract is not final yet, so for now I only do the
# single-site model. If there are two or more sites I return "not_ready" and do
# NOT run a mixed model or a pooled lm(). I also don't set any number the
# contract hasn't decided yet.
#
# model_spec is a list, for example:
#   list(response = "LIFE_F_OE",
#        flow_predictors = c("Q95_lag0", "Q10_lag0"),   # up to 2
#        wq_predictor = NULL,                            # up to 1
#        rhs_predictor = NULL)                           # up to 1
#
# Things I assumed (please tell me if they should change):
# - site column is "biol_site_id", year column is "sampling_year".
# - the single-site R2 is the normal lm R2.

# a result with all the fields filled in with defaults, so every path returns
# the same shape
.model_result <- function(status, messages, ...) {
  base <- list(
    status = status, messages = messages,
    formula = NA_character_, model_path = NA_character_,
    random_effect_structure = "not applicable",
    n_input = NA_integer_, n_complete = NA_integer_, n_excluded = NA_integer_,
    site_count = NA_integer_, year_range = NA_character_, year_center = NA_real_,
    fixed_effects = NULL, random_effects = "not applicable",
    fit_metrics = NULL, diagnostics = NULL,
    convergence_status = "not applicable", singularity_status = "not applicable",
    provenance = NULL
  )
  modifyList(base, list(...))
}

run_analysis_model <- function(analysis_dataset, model_spec,
                               site_col = "biol_site_id", year_col = "sampling_year",
                               provenance = list()) {

  response    <- model_spec$response
  flow_preds  <- model_spec$flow_predictors
  wq_pred     <- model_spec$wq_predictor
  rhs_pred    <- model_spec$rhs_predictor
  predictors  <- c(flow_preds, wq_pred, rhs_pred)
  predictors  <- predictors[!is.null(predictors) & nzchar(predictors)]

  # basic checks. if something is wrong we return a friendly message.
  if (is.null(analysis_dataset) || !is.data.frame(analysis_dataset) || nrow(analysis_dataset) == 0) {
    return(.model_result("blocked", "No analysis data available. Build the analysis dataset first."))
  }
  if (is.null(response) || !nzchar(response) || length(predictors) == 0) {
    return(.model_result("blocked", "Select a response variable and at least one predictor."))
  }
  # limits on how many predictors of each kind
  if (length(flow_preds) > 2) return(.model_result("blocked", "At most two flow predictors are allowed."))
  if (length(wq_pred)  > 1)   return(.model_result("blocked", "At most one WQ predictor is allowed."))
  if (length(rhs_pred) > 1)   return(.model_result("blocked", "At most one RHS predictor is allowed."))

  needed <- c(response, predictors, site_col)
  if (!all(needed %in% names(analysis_dataset))) {
    missing <- setdiff(needed, names(analysis_dataset))
    return(.model_result("blocked",
      paste0("These columns are not in the analysis data: ", paste(missing, collapse = ", "), ".")))
  }

  # centre the year, but only if there's a year column with at least 2 years
  df <- analysis_dataset
  year_center <- NA_real_; year_range <- NA_character_; use_year <- FALSE
  if (year_col %in% names(df)) {
    yr <- suppressWarnings(as.numeric(df[[year_col]]))
    valid_years <- unique(yr[!is.na(yr)])
    if (length(valid_years) >= 2) {
      year_center <- (min(valid_years) + max(valid_years)) / 2
      df$sampling_year_centered <- yr - year_center
      year_range <- paste0(min(valid_years), "-", max(valid_years))
      use_year <- TRUE
    }
  }

  model_vars <- c(response, predictors, if (use_year) "sampling_year_centered")
  n_input <- nrow(df)
  complete <- stats::complete.cases(df[, model_vars, drop = FALSE])
  model_df <- df[complete, , drop = FALSE]
  n_complete <- nrow(model_df)
  n_excluded <- n_input - n_complete

  # count how many sites we have. this decides which model to use.
  sites <- unique(as.character(model_df[[site_col]]))
  site_count <- length(sites)

  base_fields <- list(
    n_input = n_input, n_complete = n_complete, n_excluded = n_excluded,
    site_count = site_count, year_range = year_range, year_center = year_center,
    provenance = c(provenance, list(
      response = response, predictors = predictors, uses_year = use_year,
      software = R.version.string, fitted_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ))
  )

  if (site_count == 0) {
    return(do.call(.model_result, c(list("blocked",
      "No valid sites after removing incomplete rows. Check the data or the filter."), base_fields)))
  }

  # two or more sites: route to the mixed-effects model (frozen contract).
  # run_mixed_model does its own data-sufficiency gating (needs >= 5 sites) and
  # never falls back to a pooled lm().
  if (site_count >= 2) {
    return(run_mixed_model(analysis_dataset, model_spec,
                           site_col = site_col, year_col = year_col,
                           provenance = provenance))
  }

  # one site: run the normal single-site model.
  # we need enough rows to fit it - at least (number of terms) + 1
  n_terms <- length(model_vars) - 1 + 1   # predictors (+year) + intercept
  if (n_complete < n_terms + 1) {
    return(do.call(.model_result, c(list("blocked",
      paste0("Not enough complete rows to fit the model (have ", n_complete,
             ", need at least ", n_terms + 1, ")."))
      , c(base_fields, list(model_path = "single_site_additive")))))
  }

  rhs_terms <- c(predictors, if (use_year) "sampling_year_centered")
  formula_txt <- paste(response, "~", paste(rhs_terms, collapse = " + "))

  fit <- tryCatch(stats::lm(stats::as.formula(formula_txt), data = model_df),
                  error = function(e) e)
  if (inherits(fit, "error")) {
    return(do.call(.model_result, c(list("error",
      paste0("The model could not be fitted. (", conditionMessage(fit), ")")),
      c(base_fields, list(model_path = "single_site_additive", formula = formula_txt)))))
  }

  sm <- summary(fit)
  coefs <- as.data.frame(sm$coefficients)
  coefs$term <- rownames(coefs)
  rownames(coefs) <- NULL

  fit_metrics <- list(
    r_squared = sm$r.squared,
    adj_r_squared = sm$adj.r.squared,
    sigma = sm$sigma,
    n_obs = n_complete
  )
  diagnostics <- data.frame(
    fitted = as.numeric(stats::fitted(fit)),
    residual = as.numeric(stats::resid(fit)),
    stringsAsFactors = FALSE
  )

  do.call(.model_result, c(list("success", "Single-site additive model fitted."),
    c(base_fields, list(
      model_path = "single_site_additive",
      formula = formula_txt,
      random_effect_structure = "not applicable (single-site lm)",
      random_effects = "not applicable (single-site lm)",
      convergence_status = "not applicable (lm)",
      singularity_status = "not applicable (lm)",
      fixed_effects = coefs,
      fit_metrics = fit_metrics,
      diagnostics = diagnostics
    ))))
}

# turn a model result into flat tables the user can download.
# returns a list with:
#   summary: a two-column table (field, value) with the main numbers and the
#            provenance (what data, what formula, software, time, etc.)
#   coefficients: the fixed-effects table, or NULL if the model didn't fit
model_result_export <- function(result) {
  fm <- result$fit_metrics
  get <- function(x, default = NA) if (is.null(x)) default else x

  # start with the main fields
  fields <- list(
    status = result$status,
    model_path = get(result$model_path),
    formula = get(result$formula),
    n_input = get(result$n_input),
    n_complete = get(result$n_complete),
    n_excluded = get(result$n_excluded),
    site_count = get(result$site_count),
    year_range = get(result$year_range),
    year_center = get(result$year_center),
    r_squared = if (is.null(fm)) NA else fm$r_squared,
    adj_r_squared = if (is.null(fm)) NA else fm$adj_r_squared,
    sigma = if (is.null(fm)) NA else fm$sigma,
    convergence_status = get(result$convergence_status),
    singularity_status = get(result$singularity_status),
    messages = get(result$messages)
  )

  # add every provenance item too (response, predictors, software, time, and
  # anything the caller passed in like source dataset or filter version)
  prov <- result$provenance
  if (!is.null(prov)) {
    for (nm in names(prov)) {
      val <- prov[[nm]]
      fields[[paste0("provenance_", nm)]] <- paste(val, collapse = "; ")
    }
  }

  summary <- data.frame(
    field = names(fields),
    value = vapply(fields, function(v) paste(as.character(v), collapse = "; "), character(1)),
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  list(summary = summary, coefficients = result$fixed_effects)
}
