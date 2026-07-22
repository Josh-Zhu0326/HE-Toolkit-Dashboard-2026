# Keep this file as the single Task/Stage contract for the five-stage workflow.
# Preserve internal IDs; apply client wording changes only to user-facing labels.

he_workflow_stages <- list(
  list(
    stage_id = "prepare_data",
    stage_label = "Prepare Sites and Data",
    description = "Import source data, site metadata, mappings, or a validated processed dataset."
  ),
  list(
    stage_id = "process_data",
    stage_label = "Check and Process Data",
    description = "Validate inputs and explicitly generate processed biology and flow outputs."
  ),
  list(
    stage_id = "build_dataset",
    stage_label = "Build HE Dataset",
    description = "Join biomonitoring indices with flow statistics and other environmental data."
  ),
  list(
    stage_id = "explore_refine",
    stage_label = "Explore and Refine Relationships",
    description = "Explore the Joined HE dataset and record non-destructive filtering decisions."
  ),
  list(
    stage_id = "model_export",
    stage_label = "Model and Export",
    description = "Fit eligible models and export only current outputs with their data history."
  )
)

# Keep one mapping only; update Resume and UI tests when assigning a new Stage.
he_artifact_stage_index <- c(
  biology_input = 1L,
  environment_input = 1L,
  flow_input = 1L,
  site_mapping = 1L,
  wq_input = 1L,
  rhs_input = 1L,
  processed_biology = 2L,
  processed_environment = 2L,
  processed_flow = 2L,
  oe_result = 2L,
  flow_statistics = 2L,
  joined_core = 3L,
  joined_enriched = 3L,
  processed_dataset_checkpoint = 3L,
  filter_selection = 4L,
  exclusion_log = 4L,
  analysis_dataset = 4L,
  hev_result = 4L,
  model_spec = 5L,
  model_result = 5L
)

he_workflow_tasks <- list(
  list(
    task_id = "ecological_condition",
    task_label = "Assess ecological condition",
    description = "Calculate expected values and O:E ratios.",
    primary_output = "Expected values and O:E ratios",
    stage_path = c("R", "R", "-", "O", "O"),
    required_artifacts = c("biology_input", "environment_input", "oe_result"),
    reusable_artifacts = c("processed_biology", "processed_environment", "oe_result"),
    completion_artifact = "oe_result",
    valid_next_tasks = c("build_he_dataset", "generate_hev", "he_modelling")
  ),
  list(
    task_id = "flow_regime",
    task_label = "Summarise the flow regime",
    description = "Review coverage and calculate Q10, Q50 and Q95 with a clear data source.",
    primary_output = "Flow statistics and coverage summary",
    stage_path = c("R", "R", "-", "O", "O"),
    required_artifacts = c("flow_input", "flow_statistics"),
    reusable_artifacts = c("processed_flow", "flow_statistics"),
    completion_artifact = "flow_statistics",
    valid_next_tasks = c("build_he_dataset", "generate_hev", "he_modelling")
  ),
  list(
    task_id = "build_he_dataset",
    task_label = "Join biomonitoring indices with flow statistics and other environmental data",
    description = "Build a Joined HE dataset while keeping source and optional enrichment layers separate.",
    primary_output = "Joined HE dataset",
    stage_path = c("R", "R", "R", "O", "O"),
    required_artifacts = c(
      "oe_result",
      "flow_statistics",
      "joined_core",
      "processed_dataset_checkpoint"
    ),
    reusable_artifacts = c("joined_core", "joined_enriched", "analysis_dataset", "processed_dataset_checkpoint"),
    completion_artifact = "processed_dataset_checkpoint",
    valid_next_tasks = c("generate_hev", "he_modelling")
  ),
  list(
    task_id = "generate_hev",
    task_label = "Generate HEV plots",
    description = "Produce HEV plots with daily flows or flow statistics.",
    primary_output = "HEV plots, data and data history",
    stage_path = c("R", "R", "R", "R", "O"),
    required_artifacts = c("joined_core", "analysis_dataset", "hev_result"),
    reusable_artifacts = c("processed_dataset_checkpoint", "analysis_dataset", "hev_result"),
    completion_artifact = "hev_result",
    valid_next_tasks = c("he_modelling")
  ),
  list(
    task_id = "he_modelling",
    task_label = "Undertake HE modelling",
    description = "Fit, compare and visualise regression-based HE models.",
    primary_output = "Current model, diagnostics and data history",
    stage_path = c("R", "R", "R", "R", "R"),
    required_artifacts = c("joined_core", "analysis_dataset", "model_result"),
    reusable_artifacts = c("processed_dataset_checkpoint", "analysis_dataset", "model_result"),
    completion_artifact = "model_result",
    valid_next_tasks = c("generate_hev")
  )
)

he_workflow_state_labels <- c(
  "not_started",
  "blocked",
  "ready",
  "running",
  "complete",
  "warning",
  "stale",
  "failed"
)

he_workflow_task_ids <- function(tasks = he_workflow_tasks) {
  vapply(tasks, `[[`, character(1), "task_id")
}

he_workflow_stage_ids <- function(stages = he_workflow_stages) {
  vapply(stages, `[[`, character(1), "stage_id")
}

get_he_workflow_task <- function(task_id) {
  matches <- vapply(
    he_workflow_tasks,
    function(task) identical(task$task_id, task_id),
    logical(1)
  )

  if (!any(matches)) {
    stop(sprintf("Unknown workflow task ID: %s", task_id), call. = FALSE)
  }

  he_workflow_tasks[[which(matches)[[1]]]]
}

required_stage_ids <- function(task) {
  he_workflow_stage_ids()[task$stage_path == "R"]
}

optional_stage_ids <- function(task) {
  he_workflow_stage_ids()[task$stage_path == "O"]
}

validate_he_workflow_config <- function(
    tasks = he_workflow_tasks,
    stages = he_workflow_stages,
    artifact_ids = he_artifact_ids(),
    artifact_stage_index = he_artifact_stage_index,
    artifact_dependencies = he_artifact_dependencies) {
  # Add new mandatory fields here before using them in Stage or Task entries.
  required_stage_fields <- c("stage_id", "stage_label", "description")
  required_task_fields <- c(
    "task_id", "task_label", "description", "primary_output", "stage_path",
    "required_artifacts", "reusable_artifacts", "completion_artifact",
    "valid_next_tasks"
  )

  # Check required fields before calling helpers that assume a complete entry.
  for (stage_number in seq_along(stages)) {
    missing_fields <- setdiff(required_stage_fields, names(stages[[stage_number]]))
    if (length(missing_fields) > 0L) {
      stop(
        sprintf(
          "Workflow stage %d is missing required field(s): %s",
          stage_number,
          paste(missing_fields, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  for (task_number in seq_along(tasks)) {
    missing_fields <- setdiff(required_task_fields, names(tasks[[task_number]]))
    if (length(missing_fields) > 0L) {
      stop(
        sprintf(
          "Workflow Task %d is missing required field(s): %s",
          task_number,
          paste(missing_fields, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  stage_ids <- he_workflow_stage_ids(stages)
  task_ids <- he_workflow_task_ids(tasks)

  # Do not change counts or IDs without updating the frozen matrix and exact tests.
  if (length(stage_ids) != 5L || anyDuplicated(stage_ids)) {
    stop("Workflow config must contain five uniquely identified stages.", call. = FALSE)
  }

  if (length(task_ids) != 5L || anyDuplicated(task_ids)) {
    stop("Workflow config must contain five uniquely identified Tasks.", call. = FALSE)
  }

  # Register artifacts in workflow_state.R before referencing or mapping them here.
  unknown_stage_artifacts <- setdiff(names(artifact_stage_index), artifact_ids)
  if (length(unknown_stage_artifacts) > 0L) {
    stop(
      sprintf(
        "Artifact-stage mapping contains unknown artifact ID(s): %s",
        paste(unknown_stage_artifacts, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invalid_stage_numbers <- artifact_stage_index[
    is.na(artifact_stage_index) |
      artifact_stage_index < 1L |
      artifact_stage_index > length(stage_ids)
  ]
  if (length(invalid_stage_numbers) > 0L) {
    stop("Artifact-stage mapping contains an invalid stage number.", call. = FALSE)
  }

  # Keep paths, artifact contracts, and next Tasks in sync with matrix tests.
  for (task in tasks) {
    if (length(task$stage_path) != length(stage_ids) ||
        any(!task$stage_path %in% c("R", "O", "-"))) {
      stop(sprintf("Task %s has an invalid five-stage path.", task$task_id), call. = FALSE)
    }

    referenced_artifacts <- unique(c(
      task$required_artifacts,
      task$reusable_artifacts,
      task$completion_artifact
    ))
    unknown_artifacts <- setdiff(referenced_artifacts, artifact_ids)
    if (length(unknown_artifacts) > 0L) {
      stop(
        sprintf(
          "Task %s refers to unknown artifact ID(s): %s",
          task$task_id,
          paste(unknown_artifacts, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    unmapped_artifacts <- setdiff(referenced_artifacts, names(artifact_stage_index))
    if (length(unmapped_artifacts) > 0L) {
      stop(
        sprintf(
          "Task %s refers to artifact(s) without a stage mapping: %s",
          task$task_id,
          paste(unmapped_artifacts, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    required_stage_numbers <- unname(artifact_stage_index[task$required_artifacts])
    non_required_artifacts <- task$required_artifacts[
      task$stage_path[required_stage_numbers] != "R"
    ]
    if (length(non_required_artifacts) > 0L) {
      stop(
        sprintf(
          "Task %s has required artifact(s) mapped to a non-required Stage: %s",
          task$task_id,
          paste(non_required_artifacts, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    if (length(task$required_artifacts) == 0L ||
        length(task$completion_artifact) != 1L ||
        !task$completion_artifact %in% task$required_artifacts) {
      stop(sprintf("Task %s has an invalid completion contract.", task$task_id), call. = FALSE)
    }

    unknown_next_tasks <- setdiff(task$valid_next_tasks, task_ids)
    if (length(unknown_next_tasks) > 0L) {
      stop(
        sprintf(
          "Task %s refers to unknown next Task(s): %s",
          task$task_id,
          paste(unknown_next_tasks, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  validate_he_artifact_dependencies(artifact_dependencies)

  dependency_artifact_ids <- names(artifact_dependencies)
  if (!setequal(dependency_artifact_ids, artifact_ids)) {
    stop("Artifact dependency graph and registry IDs must match.", call. = FALSE)
  }

  unmapped_dependency_artifacts <- setdiff(
    dependency_artifact_ids,
    names(artifact_stage_index)
  )
  if (length(unmapped_dependency_artifacts) > 0L) {
    stop(
      sprintf(
        "Artifact dependency graph contains unmapped artifact ID(s): %s",
        paste(unmapped_dependency_artifacts, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # Keep dependencies within the same or an earlier Stage.
  for (artifact_id in dependency_artifact_ids) {
    dependency_ids <- artifact_dependencies[[artifact_id]]
    later_dependency_ids <- dependency_ids[
      artifact_stage_index[dependency_ids] > artifact_stage_index[[artifact_id]]
    ]
    if (length(later_dependency_ids) > 0L) {
      stop(
        sprintf(
          "Artifact %s depends on later-Stage artifact(s): %s",
          artifact_id,
          paste(later_dependency_ids, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}
