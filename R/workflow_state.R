# Keep workflow state logic free of Shiny dependencies; cover changes with pure tests.
# Update the config mapping and dependency tests whenever artifact IDs change.

# Update downstream invalidation tests whenever this dependency graph changes.
he_artifact_dependencies <- list(
  biology_input = character(),
  environment_input = character(),
  flow_input = character(),
  site_mapping = character(),
  wq_input = character(),
  rhs_input = character(),
  filter_selection = character(),
  model_spec = character(),
  processed_biology = "biology_input",
  processed_environment = "environment_input",
  processed_flow = c("flow_input", "site_mapping"),
  oe_result = c("processed_biology", "processed_environment"),
  flow_statistics = "processed_flow",
  joined_core = c("oe_result", "flow_statistics", "site_mapping"),
  joined_enriched = c("joined_core", "wq_input", "rhs_input"),
  exclusion_log = "filter_selection",
  analysis_dataset = c("joined_core", "joined_enriched", "filter_selection"),
  processed_dataset_checkpoint = "joined_core",
  hev_result = "analysis_dataset",
  model_result = c("analysis_dataset", "model_spec")
)

he_artifact_ids <- function(dependencies = he_artifact_dependencies) {
  names(dependencies)
}

new_he_artifact <- function(artifact_id) {
  if (!artifact_id %in% he_artifact_ids()) {
    stop(sprintf("Unknown workflow artifact ID: %s", artifact_id), call. = FALSE)
  }

  # Update the frozen state-schema test before adding or removing a field.
  list(
    artifact_id = artifact_id,
    status = "not_started",
    input_revisions = stats::setNames(integer(), character()),
    output_revision = 0L,
    validation_result = NULL,
    completed_at = as.POSIXct(NA),
    data_source = NULL,
    history_summary = NULL,
    blocking_reason = NULL,
    next_action = NULL
  )
}

new_he_artifact_registry <- function() {
  stats::setNames(lapply(he_artifact_ids(), new_he_artifact), he_artifact_ids())
}

validate_he_artifact_dependencies <- function(
    dependencies = he_artifact_dependencies) {
  ids <- names(dependencies)

  if (length(ids) == 0L || anyDuplicated(ids)) {
    stop("Artifact dependency IDs must be non-empty and unique.", call. = FALSE)
  }

  unknown <- setdiff(unique(unlist(dependencies, use.names = FALSE)), ids)
  if (length(unknown) > 0L) {
    stop(
      sprintf("Unknown artifact dependencies: %s", paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }

  cycle_start <- dependency_cycle_start(dependencies)
  if (!is.null(cycle_start)) {
    stop(sprintf("Artifact dependency cycle detected at %s.", cycle_start), call. = FALSE)
  }

  invisible(TRUE)
}

dependency_cycle_start <- function(dependencies) {
  visiting <- character()
  visited <- character()

  visit <- function(artifact_id) {
    if (artifact_id %in% visiting) {
      return(artifact_id)
    }
    if (artifact_id %in% visited) {
      return(NULL)
    }

    visiting <<- c(visiting, artifact_id)
    for (dependency_id in dependencies[[artifact_id]]) {
      found <- visit(dependency_id)
      if (!is.null(found)) {
        return(found)
      }
    }
    visiting <<- setdiff(visiting, artifact_id)
    visited <<- c(visited, artifact_id)
    NULL
  }

  for (artifact_id in names(dependencies)) {
    found <- visit(artifact_id)
    if (!is.null(found)) {
      return(found)
    }
  }
  NULL
}

workflow_descendants <- function(
    artifact_id,
    dependencies = he_artifact_dependencies) {
  if (!artifact_id %in% names(dependencies)) {
    stop(sprintf("Unknown workflow artifact ID: %s", artifact_id), call. = FALSE)
  }

  descendants <- character()
  frontier <- artifact_id

  while (length(frontier) > 0L) {
    direct <- names(Filter(
      function(required_ids) any(frontier %in% required_ids),
      dependencies
    ))
    new_ids <- setdiff(direct, c(artifact_id, descendants))
    if (length(new_ids) == 0L) {
      break
    }
    descendants <- c(descendants, new_ids)
    frontier <- new_ids
  }

  unique(descendants)
}

set_he_artifact_status <- function(
    registry,
    artifact_id,
    status,
    validation_result = NULL,
    data_source = NULL,
    history_summary = NULL,
    blocking_reason = NULL,
    next_action = NULL,
    input_revisions = NULL,
    completed_at = NULL) {
  # Route status changes through this function to preserve revision metadata.
  if (!artifact_id %in% names(registry)) {
    stop(sprintf("Unknown workflow artifact ID: %s", artifact_id), call. = FALSE)
  }
  if (!status %in% he_workflow_state_labels) {
    stop(sprintf("Unknown workflow status: %s", status), call. = FALSE)
  }

  artifact <- registry[[artifact_id]]
  artifact$status <- status
  artifact$validation_result <- validation_result
  artifact$data_source <- data_source
  artifact$history_summary <- history_summary
  artifact$blocking_reason <- blocking_reason
  artifact$next_action <- next_action

  if (!is.null(input_revisions)) {
    artifact$input_revisions <- input_revisions
  }

  if (status %in% c("complete", "warning")) {
    artifact$output_revision <- artifact$output_revision + 1L
    artifact$completed_at <- if (is.null(completed_at)) Sys.time() else completed_at
  }

  registry[[artifact_id]] <- artifact
  registry
}

invalidate_he_artifacts_from <- function(
    registry,
    changed_artifact_id,
    dependencies = he_artifact_dependencies) {
  # Keep invalidation transitive; verify every changed dependency in state tests.
  descendants <- workflow_descendants(changed_artifact_id, dependencies)

  for (artifact_id in descendants) {
    artifact <- registry[[artifact_id]]
    if (artifact$status %in% c("complete", "warning")) {
      artifact$status <- "stale"
      artifact$blocking_reason <- sprintf(
        "A dependency changed after %s was generated.",
        artifact_id
      )
      artifact$next_action <- sprintf("Regenerate %s.", artifact_id)
      registry[[artifact_id]] <- artifact
    }
  }

  registry
}

artifact_is_current <- function(artifact) {
  artifact$status %in% c("complete", "warning")
}

workflow_task_is_complete <- function(task, registry) {
  completion_artifact_id <- task$completion_artifact
  if (!completion_artifact_id %in% names(registry)) {
    stop(
      sprintf(
        "Task %s completion artifact is missing from runtime state: %s",
        task$task_id,
        completion_artifact_id
      ),
      call. = FALSE
    )
  }

  artifact_is_current(registry[[completion_artifact_id]])
}

artifact_has_workflow_progress <- function(artifact) {
  !identical(artifact$status, "not_started") || artifact$output_revision > 0L
}

workflow_required_stage_artifact_ids <- function(
    task,
    stage_index,
    artifact_stage_index = he_artifact_stage_index) {
  required_ids <- task$required_artifacts
  required_ids[artifact_stage_index[required_ids] == stage_index]
}

workflow_resume_stage <- function(
    task,
    registry,
    artifact_stage_index = he_artifact_stage_index) {
  # Preserve the earliest non-current required Stage rule in pure and server tests.
  required_stages <- which(task$stage_path == "R")
  if (length(required_stages) == 0L) {
    stop(sprintf("Task %s has no required Stage.", task$task_id), call. = FALSE)
  }

  task_artifact_ids <- unique(c(task$required_artifacts, task$reusable_artifacts))
  unknown_artifacts <- setdiff(task_artifact_ids, names(registry))
  if (length(unknown_artifacts) > 0L) {
    stop(
      sprintf(
        "Task %s refers to artifact(s) missing from runtime state: %s",
        task$task_id,
        paste(unknown_artifacts, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  unmapped_artifacts <- setdiff(task_artifact_ids, names(artifact_stage_index))
  if (length(unmapped_artifacts) > 0L) {
    stop(
      sprintf(
        "Task %s refers to artifact(s) without a Stage: %s",
        task$task_id,
        paste(unmapped_artifacts, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (stage_index in required_stages) {
    stage_artifact_ids <- workflow_required_stage_artifact_ids(
      task,
      stage_index,
      artifact_stage_index
    )

    if (length(stage_artifact_ids) > 0L) {
      stage_is_current <- vapply(
        registry[stage_artifact_ids],
        artifact_is_current,
        logical(1)
      )
      if (!all(stage_is_current)) {
        return(as.integer(stage_index))
      }
      next
    }

    later_artifact_ids <- task_artifact_ids[
      artifact_stage_index[task_artifact_ids] > stage_index
    ]
    later_progress_exists <- length(later_artifact_ids) > 0L && any(vapply(
      registry[later_artifact_ids],
      artifact_has_workflow_progress,
      logical(1)
    ))

    if (!later_progress_exists) {
      return(as.integer(stage_index))
    }
  }

  as.integer(max(required_stages))
}
