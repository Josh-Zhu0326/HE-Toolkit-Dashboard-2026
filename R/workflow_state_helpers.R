HE_WORKFLOW_STATES <- c(
  "not_ready",
  "ready",
  "running",
  "complete",
  "warning",
  "error",
  "stale"
)

workflow_state_definitions <- function() {
  data.frame(
    status = HE_WORKFLOW_STATES,
    meaning = c(
      "Required prerequisites are missing.",
      "Prerequisites are satisfied and the action can run.",
      "The action is currently running.",
      "The output exists and matches current upstream inputs.",
      "The output or prerequisite is usable, but needs user attention.",
      "The current action failed; independent workflow branches remain usable.",
      "The output is retained for review but was created from older inputs."
    ),
    output_viewable = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE),
    can_continue = c(FALSE, TRUE, FALSE, TRUE, TRUE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )
}

workflow_stage_config <- function() {
  list(
    input_mapping = list(
      id = "input_mapping",
      order = 1L,
      label = "Input and mapping",
      steps = c("select_goal", "provide_site_mapping", "upload_or_select_sources")
    ),
    import_validate = list(
      id = "import_validate",
      order = 2L,
      label = "Import and validation",
      steps = c(
        "validate_inputs",
        "import_biology",
        "import_environment",
        "import_flow",
        "import_wq",
        "import_rhs"
      )
    ),
    process_core = list(
      id = "process_core",
      order = 3L,
      label = "Core processing",
      steps = c(
        "calculate_rict",
        "calculate_oe",
        "impute_flow",
        "calculate_flow_statistics"
      )
    ),
    join_enrich = list(
      id = "join_enrich",
      order = 4L,
      label = "Join and optional enrichment",
      steps = c("create_joined_core", "create_joined_enriched")
    ),
    explore_model_export = list(
      id = "explore_model_export",
      order = 5L,
      label = "Explore, filter, model and export",
      steps = c(
        "review_exploration",
        "filter_analysis_data",
        "create_hev",
        "fit_model",
        "export_results"
      )
    )
  )
}

workflow_goal_config <- function(goal_id = NULL) {
  goals <- list(
    validate_inputs = list(
      id = "validate_inputs",
      label = "Validate and review input data",
      required_inputs = c("At least one supported input dataset"),
      required_steps = c("select_goal", "upload_or_select_sources", "validate_inputs"),
      optional_steps = c("provide_site_mapping", "import_wq", "import_rhs"),
      final_outputs = c("Validation checkpoint", "Data preview"),
      blocking_conditions = c("Unreadable file", "Empty dataset", "Missing required fields for the selected dataset"),
      warning_conditions = c("Optional mapping IDs are missing", "Duplicate samples need review")
    ),
    calculate_oe = list(
      id = "calculate_oe",
      label = "Calculate biological O:E",
      required_inputs = c("Site mapping", "Biology data", "Environmental site data"),
      required_steps = c(
        "select_goal",
        "provide_site_mapping",
        "upload_or_select_sources",
        "validate_inputs",
        "import_biology",
        "import_environment",
        "calculate_rict",
        "calculate_oe"
      ),
      optional_steps = character(0),
      final_outputs = c("RICT expected indices", "Biological O:E results"),
      blocking_conditions = c("Biology data are missing", "Environmental prerequisites are invalid", "RICT predictions are unavailable"),
      warning_conditions = c("Duplicate biology samples", "Proxy alkalinity used", "Some optional biological indices are absent")
    ),
    assess_flow_hev = list(
      id = "assess_flow_hev",
      label = "Calculate flow statistics and HEV",
      required_inputs = c("Site mapping", "Biological O:E results", "Flow data"),
      required_steps = c(
        "select_goal",
        "provide_site_mapping",
        "upload_or_select_sources",
        "validate_inputs",
        "import_biology",
        "import_environment",
        "import_flow",
        "calculate_rict",
        "calculate_oe",
        "calculate_flow_statistics",
        "create_joined_core",
        "create_hev"
      ),
      optional_steps = c("impute_flow"),
      final_outputs = c("Flow statistics", "Joined core dataset", "HEV plot"),
      blocking_conditions = c("Flow data are missing", "Biological O:E results are missing", "Site mapping is incomplete for the selected sites"),
      warning_conditions = c("Flow gaps remain", "Some mapped sites have no imported records")
    ),
    build_joined_dataset = list(
      id = "build_joined_dataset",
      label = "Build a joined analysis dataset",
      required_inputs = c("Site mapping", "Biological O:E results", "Flow statistics"),
      required_steps = c(
        "select_goal",
        "provide_site_mapping",
        "upload_or_select_sources",
        "validate_inputs",
        "import_biology",
        "import_environment",
        "import_flow",
        "calculate_rict",
        "calculate_oe",
        "calculate_flow_statistics",
        "create_joined_core"
      ),
      optional_steps = c("impute_flow", "import_wq", "import_rhs", "create_joined_enriched"),
      final_outputs = c("joined_core", "joined_enriched when optional enrichment is selected"),
      blocking_conditions = c("Biological O:E results are missing", "Flow statistics are missing", "Biology-flow mapping is invalid"),
      warning_conditions = c("WQ or RHS mapping is TBC", "Optional enrichment has partial coverage")
    ),
    model_and_export = list(
      id = "model_and_export",
      label = "Explore, filter, model and export",
      required_inputs = c("joined_core or joined_enriched"),
      required_steps = c(
        "select_goal",
        "review_exploration",
        "filter_analysis_data",
        "fit_model",
        "export_results"
      ),
      optional_steps = c("import_wq", "import_rhs", "create_joined_enriched", "create_hev"),
      final_outputs = c("analysis_dataset", "exclusion_log", "model_result", "Exported results"),
      blocking_conditions = c("No joined dataset is available", "No complete numeric observations remain after filtering", "Model specification is invalid"),
      warning_conditions = c("Filtering removes substantial data", "High predictor correlation", "Optional WQ/RHS enrichment is unavailable")
    )
  )

  if (is.null(goal_id)) {
    return(goals)
  }

  if (!goal_id %in% names(goals)) {
    stop("Unknown workflow goal: ", goal_id, call. = FALSE)
  }

  goals[[goal_id]]
}

workflow_goal_matrix <- function() {
  goals <- workflow_goal_config()
  do.call(
    rbind,
    lapply(goals, function(goal) {
      data.frame(
        goal_id = goal$id,
        goal = goal$label,
        required_inputs = paste(goal$required_inputs, collapse = "; "),
        required_steps = paste(goal$required_steps, collapse = "; "),
        optional_steps = paste(goal$optional_steps, collapse = "; "),
        final_outputs = paste(goal$final_outputs, collapse = "; "),
        blocking_conditions = paste(goal$blocking_conditions, collapse = "; "),
        warning_conditions = paste(goal$warning_conditions, collapse = "; "),
        stringsAsFactors = FALSE
      )
    })
  )
}

workflow_dependency_map <- function() {
  data.frame(
    upstream = c(
      "site_mapping", "site_mapping", "site_mapping", "site_mapping", "site_mapping",
      "environmental_data", "biology_data", "predicted_indices",
      "flow_data", "flow_data", "flow_imputed",
      "site_mapping", "oe_results", "flow_statistics",
      "joined_core", "mapped_wq_data", "mapped_rhs_data",
      "joined_enriched", "analysis_dataset", "analysis_dataset", "joined_core"
    ),
    downstream = c(
      "biology_data", "environmental_data", "flow_data", "mapped_wq_data", "mapped_rhs_data",
      "predicted_indices", "oe_results", "oe_results",
      "flow_imputed", "flow_statistics", "flow_statistics",
      "joined_core", "joined_core", "joined_core",
      "joined_enriched", "joined_enriched", "joined_enriched",
      "analysis_dataset", "exploration_result", "model_result", "hev_result"
    ),
    optional = c(
      FALSE, FALSE, FALSE, TRUE, TRUE,
      FALSE, FALSE, FALSE,
      TRUE, FALSE, TRUE,
      FALSE, FALSE, FALSE,
      FALSE, TRUE, TRUE,
      FALSE, FALSE, FALSE, FALSE
    ),
    relationship = c(
      "selects biology sites", "selects environmental sites", "selects flow sites", "maps optional WQ sites", "maps optional RHS surveys",
      "produces expected indices", "provides observed indices", "provides expected indices",
      "may be gap-filled", "supports direct calculation", "supports calculation after optional imputation",
      "provides biology-flow mapping", "provides processed biology", "provides time-varying flow statistics",
      "provides the immutable core", "adds optional WQ summaries", "adds optional RHS descriptors",
      "is filtered without mutation", "supports exploration", "supports modelling", "supports HEV plotting"
    ),
    stringsAsFactors = FALSE
  )
}

workflow_stale_seeds <- function() {
  list(
    mapping_changed = c("biology_data", "environmental_data", "flow_data", "mapped_wq_data", "mapped_rhs_data"),
    biology_changed = c("oe_results"),
    environmental_changed = c("predicted_indices"),
    flow_changed = c("flow_imputed", "flow_statistics"),
    wq_enrichment_changed = c("joined_enriched"),
    rhs_enrichment_changed = c("joined_enriched"),
    filtering_changed = c("analysis_dataset"),
    exploration_options_changed = c("exploration_result"),
    model_variables_changed = c("model_result")
  )
}

workflow_stale_targets <- function(change_id) {
  seeds <- workflow_stale_seeds()
  if (!change_id %in% names(seeds)) {
    stop("Unknown workflow change: ", change_id, call. = FALSE)
  }

  dependencies <- workflow_dependency_map()
  stale <- unique(seeds[[change_id]])
  frontier <- stale

  while (length(frontier) > 0) {
    next_targets <- unique(dependencies$downstream[dependencies$upstream %in% frontier])
    next_targets <- setdiff(next_targets, stale)
    if (length(next_targets) == 0) {
      break
    }
    stale <- c(stale, next_targets)
    frontier <- next_targets
  }

  unique(stale)
}

derive_workflow_state <- function(
  prerequisites_ready = FALSE,
  has_output = FALSE,
  is_running = FALSE,
  has_warning = FALSE,
  has_error = FALSE,
  is_stale = FALSE
) {
  if (isTRUE(has_error)) {
    return("error")
  }
  if (isTRUE(is_running)) {
    return("running")
  }
  if (isTRUE(is_stale) && isTRUE(has_output)) {
    return("stale")
  }
  if (isTRUE(has_warning)) {
    return("warning")
  }
  if (isTRUE(has_output)) {
    return("complete")
  }
  if (isTRUE(prerequisites_ready)) {
    return("ready")
  }
  "not_ready"
}

new_workflow_checkpoint <- function(
  status,
  evidence_summary,
  affected_output,
  required_user_action,
  next_recommended_step
) {
  if (!status %in% HE_WORKFLOW_STATES) {
    stop("Invalid workflow status: ", status, call. = FALSE)
  }

  fields <- list(
    evidence_summary = evidence_summary,
    affected_output = affected_output,
    required_user_action = required_user_action,
    next_recommended_step = next_recommended_step
  )
  if (any(vapply(fields, function(value) length(value) != 1L || is.na(value) || !nzchar(trimws(value)), logical(1)))) {
    stop("Checkpoint fields must be non-empty scalar text values.", call. = FALSE)
  }

  c(list(status = status), fields)
}

validate_workflow_configuration <- function() {
  stages <- workflow_stage_config()
  goals <- workflow_goal_config()
  stage_steps <- unique(unlist(lapply(stages, `[[`, "steps"), use.names = FALSE))
  goal_steps <- unique(unlist(lapply(goals, function(goal) c(goal$required_steps, goal$optional_steps)), use.names = FALSE))

  errors <- character(0)
  if (length(stages) != 5L) {
    errors <- c(errors, "Exactly five workflow stages are required.")
  }
  if (length(goals) != 5L) {
    errors <- c(errors, "Exactly five workflow goals are required.")
  }
  if (!identical(workflow_state_definitions()$status, HE_WORKFLOW_STATES)) {
    errors <- c(errors, "Workflow state definitions do not match the frozen seven-state vocabulary.")
  }
  unknown_steps <- setdiff(goal_steps, stage_steps)
  if (length(unknown_steps) > 0) {
    errors <- c(errors, paste("Goal configuration contains unknown steps:", paste(unknown_steps, collapse = ", ")))
  }

  list(valid = length(errors) == 0L, errors = errors)
}
