# model_interface_helpers.R
# -----------------------------------------------------------------------------
# A single, safe entry point between the dashboard UI and the statistical model.
#
# Non-coding users never touch R. They pick variables in the UI and press Run;
# the server calls run_model() and shows whatever it returns. run_model()
# guarantees a consistent, structured result and NEVER lets a raw R error reach
# the user -- any failure comes back as status = "error" with a plain message.
#
# EXISTING MODEL (confirmed I/O)
#   build_basic_flow_ecology_model(data, flow_var, ecology_var)
#     input : joined HE data.frame + two column names
#     does  : lm(ecology ~ flow) on complete numeric cases
#     output: list(status, messages, plot, summary)
#
# run_model() wraps that model:
#   input : data  = joined HE data.frame (downstream of filtering/join)
#           params = list(flow_var =, ecology_var =, model_type = "linear")
#   output: list(status, messages, plot, summary)   (same shape as above)
#
# Depends on: dashboard_backlog_helpers.R (build_basic_flow_ecology_model).
# -----------------------------------------------------------------------------

SUPPORTED_MODEL_TYPES <- c("linear")

# Consistent error result so the caller never has to handle raw errors.
model_error <- function(msg) {
  list(status = "error", messages = msg, plot = NULL, summary = NULL)
}

run_model <- function(data, params = list()) {

  # --- Read + default the parameters --------------------------------------
  flow_var    <- params$flow_var
  ecology_var <- params$ecology_var
  model_type  <- if (is.null(params$model_type)) "linear" else params$model_type

  # --- Pre-flight validation (friendly messages, no raw errors) -----------
  if (!model_type %in% SUPPORTED_MODEL_TYPES) {
    return(model_error(paste0(
      "Model type '", model_type, "' is not supported. ",
      "Available: ", paste(SUPPORTED_MODEL_TYPES, collapse = ", "), "."
    )))
  }

  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0) {
    return(model_error(
      "No joined data available. Please complete the previous steps before modelling."
    ))
  }

  if (is.null(flow_var) || is.null(ecology_var) ||
      !nzchar(flow_var) || !nzchar(ecology_var)) {
    return(model_error("Please select both a flow variable and an ecology variable."))
  }

  if (!all(c(flow_var, ecology_var) %in% names(data))) {
    return(model_error("The selected variables were not found in the data. Please reselect."))
  }

  # --- Run the model, catching ANY failure --------------------------------
  result <- tryCatch(
    switch(
      model_type,
      linear = build_basic_flow_ecology_model(
        data = data, flow_var = flow_var, ecology_var = ecology_var
      )
    ),
    error = function(e) {
      model_error(paste0(
        "The model could not be fitted with the selected variables. ",
        "Please try different variables or check the data. (", conditionMessage(e), ")"
      ))
    }
  )

  # --- Guarantee the expected shape ---------------------------------------
  if (is.null(result) || is.null(result$status)) {
    return(model_error("The model returned no result. Please try again."))
  }
  result
}
