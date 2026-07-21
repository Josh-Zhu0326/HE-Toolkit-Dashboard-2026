# model_interface_helpers.R
# This is the safe middle step between the UI and the model.
# Users don't touch R, they just pick variables and press Run. The server calls
# run_model(), and run_model() always gives back the same kind of result and
# never lets a raw R error show up on screen. If something fails it comes back
# as status = "error" with a plain message.
#
# The actual model already exists:
#   build_basic_flow_ecology_model(data, flow_var, ecology_var)
#   input : the joined data plus two column names
#   does  : lm(ecology ~ flow) on the complete numeric rows
#   output: list(status, messages, plot, summary)
#
# run_model() just wraps it:
#   input : data = the joined data, params = list(flow_var, ecology_var, model_type)
#   output: list(status, messages, plot, summary)  (same shape)
#
# Needs dashboard_backlog_helpers.R for build_basic_flow_ecology_model.

SUPPORTED_MODEL_TYPES <- c("linear")

# a standard error result, so the caller never has to deal with raw errors
model_error <- function(msg) {
  list(status = "error", messages = msg, plot = NULL, summary = NULL)
}

run_model <- function(data, params = list()) {

  # read the parameters, default the model type to linear
  flow_var    <- params$flow_var
  ecology_var <- params$ecology_var
  model_type  <- if (is.null(params$model_type)) "linear" else params$model_type

  # check everything before running, and return a friendly message if not ok

  # is the model type one we support?
  if (!model_type %in% SUPPORTED_MODEL_TYPES) {
    return(model_error(paste0(
      "Model type '", model_type, "' is not supported. ",
      "Available: ", paste(SUPPORTED_MODEL_TYPES, collapse = ", "), "."
    )))
  }

  # do we actually have data?
  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0) {
    return(model_error(
      "No joined data available. Please complete the previous steps before modelling."
    ))
  }

  # did the user pick both variables?
  if (is.null(flow_var) || is.null(ecology_var) ||
      !nzchar(flow_var) || !nzchar(ecology_var)) {
    return(model_error("Please select both a flow variable and an ecology variable."))
  }

  # do those variables exist in the data?
  if (!all(c(flow_var, ecology_var) %in% names(data))) {
    return(model_error("The selected variables were not found in the data. Please reselect."))
  }

  # run the model. tryCatch catches any error so nothing raw reaches the user.
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

  # last safety check: make sure we got a proper result back
  if (is.null(result) || is.null(result$status)) {
    return(model_error("The model returned no result. Please try again."))
  }
  result
}
