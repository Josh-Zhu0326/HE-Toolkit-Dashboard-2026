# Workspace snapshots are plain, versioned R objects. Storage backends must not
# depend on Shiny reactives or temporary upload paths.

workspace_schema_version <- "1.0.0"

workspace_artifact_dataset_requirements <- list(
  oe_result = "oe_results",
  flow_statistics = "flow_statistics",
  joined_core = "joined_core",
  processed_dataset_checkpoint = "joined_core",
  analysis_dataset = "analysis_dataset",
  hev_result = "hev_data",
  model_result = "model_result"
)

workspace_dataset_artifact_ids <- function(dataset_name) {
  names(Filter(
    function(required_names) dataset_name %in% required_names,
    workspace_artifact_dataset_requirements
  ))
}

workspace_saved_input_ids <- c(
  "main_nav",
  "meta_paste",
  "date_range_biol",
  "date_range_flow",
  "date_range_wq",
  "donor_mapping_paste",
  "donor_list_paste",
  "win_width_selector",
  "win_step_selector",
  "choose_lags",
  "choose_join_method",
  "analysis_record_id",
  "basic_model_flow_var",
  "basic_model_ecology_var",
  "site_selector",
  "biol_metric_selector",
  "flow_metric_selector",
  "HEV_date_range",
  "HEV_show_all_metrics",
  "HEV_show_high_low",
  "HEV_show_status",
  "env_data_display",
  "flow_data_display",
  "imp_flow_data_display",
  "flow_stats_display",
  "wq_plot_type",
  "wq_date_col",
  "wq_numeric_var",
  "wq_group_col",
  "rhs_plot_type",
  "rhs_variable",
  "rhs_group_col"
)

workspace_app_version <- function() {
  configured <- getOption("hetoolkit.app_version", "")
  if (is.character(configured) && length(configured) == 1L && nzchar(configured)) {
    return(configured)
  }

  deployed_sha <- Sys.getenv("GITHUB_SHA", unset = "")
  if (nzchar(deployed_sha)) substr(deployed_sha, 1L, 12L) else "development"
}

validate_workspace_name <- function(workspace_name) {
  if (!is.character(workspace_name) || length(workspace_name) != 1L ||
      is.na(workspace_name)) {
    stop("Workspace name must be one text value.", call. = FALSE)
  }

  workspace_name <- trimws(workspace_name)
  if (!nzchar(workspace_name)) {
    stop("Enter a workspace name before saving.", call. = FALSE)
  }
  if (nchar(workspace_name, type = "chars") > 80L) {
    stop("Workspace name must be 80 characters or fewer.", call. = FALSE)
  }
  if (grepl("[[:cntrl:]]", workspace_name)) {
    stop("Workspace name cannot contain control characters.", call. = FALSE)
  }

  workspace_name
}

workspace_directory_name <- function(workspace_name) {
  workspace_name <- validate_workspace_name(workspace_name)
  directory_name <- gsub(
    "[^\\p{L}\\p{N}._-]+",
    "-",
    enc2utf8(workspace_name),
    perl = TRUE
  )
  directory_name <- gsub("[-_.]{2,}", "-", directory_name)
  directory_name <- gsub("^[-_.]+|[-_.]+$", "", directory_name)
  directory_name <- substr(directory_name, 1L, 64L)
  if (!nzchar(directory_name)) {
    directory_name <- "workspace"
  }

  windows_reserved <- c(
    "CON", "PRN", "AUX", "NUL",
    paste0("COM", 1:9), paste0("LPT", 1:9)
  )
  if (toupper(directory_name) %in% windows_reserved) {
    directory_name <- paste0("workspace-", directory_name)
  }

  directory_name
}

new_workspace_id <- function(saved_at = Sys.time()) {
  random_suffix <- paste(sample(c(letters, 0:9), 8L, replace = TRUE), collapse = "")
  paste(
    format(as.POSIXct(saved_at), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    Sys.getpid(),
    random_suffix,
    sep = "-"
  )
}

validate_workspace_registry <- function(registry) {
  expected_ids <- he_artifact_ids()
  if (!is.list(registry) || !setequal(names(registry), expected_ids) ||
      anyDuplicated(names(registry))) {
    stop("Workspace artifact registry does not match the current application schema.", call. = FALSE)
  }

  required_fields <- c("artifact_id", "status", "output_revision")
  for (artifact_id in expected_ids) {
    artifact <- registry[[artifact_id]]
    if (!is.list(artifact) || !all(required_fields %in% names(artifact)) ||
        !identical(artifact$artifact_id, artifact_id)) {
      stop(sprintf("Workspace artifact '%s' is invalid.", artifact_id), call. = FALSE)
    }
    if (!is.character(artifact$status) || length(artifact$status) != 1L ||
        !artifact$status %in% he_workflow_state_labels) {
      stop(sprintf("Workspace artifact '%s' has an unknown status.", artifact_id), call. = FALSE)
    }
  }

  invisible(TRUE)
}

validate_workspace_session <- function(workflow_session) {
  if (!is.list(workflow_session) ||
      !all(c("task_id", "stage_index") %in% names(workflow_session))) {
    stop("Workspace workflow session is invalid.", call. = FALSE)
  }

  task_id <- workflow_session$task_id
  if (!is.null(task_id) &&
      (!is.character(task_id) || length(task_id) != 1L ||
       !task_id %in% he_workflow_task_ids())) {
    stop("Workspace contains an unknown Task.", call. = FALSE)
  }

  stage_index <- workflow_session$stage_index
  if (length(stage_index) != 1L || is.na(stage_index) ||
      stage_index < 1L || stage_index > length(he_workflow_stages)) {
    stop("Workspace contains an invalid workflow Stage.", call. = FALSE)
  }

  invisible(TRUE)
}

new_workspace_snapshot <- function(
    workspace_name,
    workflow_artifacts,
    workflow_session,
    input_values = list(),
    runtime_state = list(),
    datasets = list(),
    current_panel = NULL,
    app_version = workspace_app_version(),
    saved_at = Sys.time(),
    workspace_id = new_workspace_id(saved_at)) {
  workspace_name <- validate_workspace_name(workspace_name)
  datasets <- datasets[!vapply(datasets, is.null, logical(1))]

  snapshot <- list(
    schema_version = workspace_schema_version,
    workspace = list(
      workspace_id = workspace_id,
      workspace_name = workspace_name,
      directory_name = workspace_directory_name(workspace_name),
      saved_at = format(as.POSIXct(saved_at), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      app_version = app_version
    ),
    state = list(
      workflow_artifacts = workflow_artifacts,
      workflow_session = workflow_session,
      current_panel = current_panel,
      input_values = input_values,
      runtime_state = runtime_state
    ),
    datasets = datasets
  )

  validate_workspace_snapshot(snapshot)
  snapshot
}

validate_workspace_snapshot <- function(snapshot, require_dataset_coverage = TRUE) {
  if (!is.list(snapshot) ||
      !all(c("schema_version", "workspace", "state", "datasets") %in% names(snapshot))) {
    stop("Workspace snapshot is incomplete.", call. = FALSE)
  }
  if (!identical(snapshot$schema_version, workspace_schema_version)) {
    stop(
      sprintf(
        "Workspace schema '%s' is not supported by this application.",
        as.character(snapshot$schema_version)
      ),
      call. = FALSE
    )
  }

  workspace_fields <- c(
    "workspace_id", "workspace_name", "directory_name", "saved_at", "app_version"
  )
  if (!is.list(snapshot$workspace) ||
      !all(workspace_fields %in% names(snapshot$workspace))) {
    stop("Workspace identity metadata is incomplete.", call. = FALSE)
  }
  validate_workspace_name(snapshot$workspace$workspace_name)
  if (!identical(
    snapshot$workspace$directory_name,
    workspace_directory_name(snapshot$workspace$workspace_name)
  )) {
    stop("Workspace directory name does not match its display name.", call. = FALSE)
  }

  state_fields <- c(
    "workflow_artifacts", "workflow_session", "current_panel",
    "input_values", "runtime_state"
  )
  if (!is.list(snapshot$state) || !all(state_fields %in% names(snapshot$state))) {
    stop("Workspace state is incomplete.", call. = FALSE)
  }
  validate_workspace_registry(snapshot$state$workflow_artifacts)
  validate_workspace_session(snapshot$state$workflow_session)

  for (field in c("input_values", "runtime_state")) {
    value <- snapshot$state[[field]]
    if (!is.list(value) || (length(value) > 0L && is.null(names(value)))) {
      stop(sprintf("Workspace %s must be a named list.", field), call. = FALSE)
    }
  }

  if (!is.list(snapshot$datasets) ||
      (length(snapshot$datasets) > 0L &&
       (is.null(names(snapshot$datasets)) || anyDuplicated(names(snapshot$datasets))))) {
    stop("Workspace datasets must be a uniquely named list.", call. = FALSE)
  }
  if (length(snapshot$datasets) > 0L &&
      any(!grepl("^[A-Za-z0-9_.-]+$", names(snapshot$datasets)))) {
    stop("Workspace dataset names contain unsupported characters.", call. = FALSE)
  }
  if (isTRUE(require_dataset_coverage)) {
    for (artifact_id in names(workspace_artifact_dataset_requirements)) {
      artifact <- snapshot$state$workflow_artifacts[[artifact_id]]
      if (!artifact_is_current(artifact)) {
        next
      }
      required_names <- workspace_artifact_dataset_requirements[[artifact_id]]
      if (!any(required_names %in% names(snapshot$datasets))) {
        stop(
          sprintf(
            "Current workflow artifact '%s' is missing its saved data object.",
            artifact_id
          ),
          call. = FALSE
        )
      }
    }
  }

  invisible(TRUE)
}

prepare_workspace_for_restore <- function(snapshot, require_dataset_coverage = TRUE) {
  validate_workspace_snapshot(
    snapshot,
    require_dataset_coverage = require_dataset_coverage
  )
  workflow_session <- snapshot$state$workflow_session

  if (is.null(workflow_session$task_id)) {
    workflow_session$stage_index <- 1L
  } else {
    task <- get_he_workflow_task(workflow_session$task_id)
    workflow_session$stage_index <- workflow_resume_stage(
      task,
      snapshot$state$workflow_artifacts
    )
  }

  snapshot$state$workflow_session <- workflow_session
  snapshot
}

workspace_state_summary <- function(snapshot) {
  snapshot <- prepare_workspace_for_restore(snapshot)
  registry <- snapshot$state$workflow_artifacts
  statuses <- vapply(registry, `[[`, character(1), "status")

  list(
    workspace_id = snapshot$workspace$workspace_id,
    workspace_name = snapshot$workspace$workspace_name,
    saved_at = snapshot$workspace$saved_at,
    app_version = snapshot$workspace$app_version,
    task_id = snapshot$state$workflow_session$task_id,
    resume_stage = snapshot$state$workflow_session$stage_index,
    dataset_count = length(snapshot$datasets),
    status_counts = as.list(table(factor(statuses, levels = he_workflow_state_labels)))
  )
}
