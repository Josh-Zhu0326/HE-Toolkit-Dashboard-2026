test_project_root <- normalizePath(
  testthat::test_path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)

workflow_dashboard_server <- local({
  previous_dir <- getwd()
  setwd(test_project_root)
  on.exit(setwd(previous_dir), add = TRUE)
  source("global.R")
  source("server.R")$value
})

shiny_upload_input <- function(path, type = "text/csv") {
  list(
    name = basename(path),
    size = file.info(path)$size,
    type = type,
    datapath = normalizePath(path, winslash = "/", mustWork = TRUE)
  )
}

muffle_interrupted_workflow_promise <- function(expression) {
  withCallingHandlers(
    expression,
    warning = function(warning) {
      if (grepl(
        "restarting interrupted promise evaluation",
        conditionMessage(warning),
        fixed = TRUE
      )) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

set_inputs_ignoring_interrupted_promises <- function(session, ...) {
  muffle_interrupted_workflow_promise(session$setInputs(...))
}
