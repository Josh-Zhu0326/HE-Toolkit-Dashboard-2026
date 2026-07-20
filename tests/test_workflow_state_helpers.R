source(file.path("R", "workflow_state_helpers.R"))

configuration <- validate_workflow_configuration()
stopifnot(isTRUE(configuration$valid))
stopifnot(length(workflow_goal_config()) == 5L)
stopifnot(length(workflow_stage_config()) == 5L)
stopifnot(identical(workflow_state_definitions()$status, HE_WORKFLOW_STATES))

goal_matrix <- workflow_goal_matrix()
stopifnot(nrow(goal_matrix) == 5L)
stopifnot(all(c(
  "required_inputs",
  "required_steps",
  "optional_steps",
  "final_outputs",
  "blocking_conditions",
  "warning_conditions"
) %in% names(goal_matrix)))

wq_stale <- workflow_stale_targets("wq_enrichment_changed")
stopifnot("joined_enriched" %in% wq_stale)
stopifnot("analysis_dataset" %in% wq_stale)
stopifnot("model_result" %in% wq_stale)
stopifnot(!"joined_core" %in% wq_stale)
stopifnot(!"oe_results" %in% wq_stale)

rhs_stale <- workflow_stale_targets("rhs_enrichment_changed")
stopifnot(setequal(rhs_stale, wq_stale))

filter_stale <- workflow_stale_targets("filtering_changed")
stopifnot(all(c("analysis_dataset", "exploration_result", "model_result") %in% filter_stale))
stopifnot(!"joined_core" %in% filter_stale)
stopifnot(!"joined_enriched" %in% filter_stale)

model_stale <- workflow_stale_targets("model_variables_changed")
stopifnot(identical(model_stale, "model_result"))

biology_stale <- workflow_stale_targets("biology_changed")
stopifnot(all(c(
  "oe_results",
  "joined_core",
  "joined_enriched",
  "analysis_dataset",
  "exploration_result",
  "model_result",
  "hev_result"
) %in% biology_stale))
stopifnot(!"predicted_indices" %in% biology_stale)

stopifnot(identical(derive_workflow_state(), "not_ready"))
stopifnot(identical(derive_workflow_state(prerequisites_ready = TRUE), "ready"))
stopifnot(identical(derive_workflow_state(is_running = TRUE), "running"))
stopifnot(identical(derive_workflow_state(has_output = TRUE), "complete"))
stopifnot(identical(derive_workflow_state(has_warning = TRUE), "warning"))
stopifnot(identical(derive_workflow_state(has_error = TRUE), "error"))
stopifnot(identical(derive_workflow_state(has_output = TRUE, is_stale = TRUE), "stale"))

checkpoint <- new_workflow_checkpoint(
  status = "warning",
  evidence_summary = "Two RHS survey IDs are TBC.",
  affected_output = "joined_enriched",
  required_user_action = "Confirm RHS survey IDs before RHS enrichment.",
  next_recommended_step = "Continue with joined_core or update the mapping."
)
stopifnot(identical(checkpoint$status, "warning"))
stopifnot(identical(checkpoint$affected_output, "joined_enriched"))

invalid_checkpoint <- try(
  new_workflow_checkpoint("unknown", "Evidence", "Output", "Action", "Next"),
  silent = TRUE
)
stopifnot(inherits(invalid_checkpoint, "try-error"))

cat("workflow state helper tests passed\n")
