source(testthat::test_path("..", "..", "R", "csv_input_helpers.R"))
source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))
source(testthat::test_path("..", "..", "R", "model_interface_helpers.R"))
source(testthat::test_path("..", "..", "R", "user_message_safety_helpers.R"))

testthat::test_that("RAW-24 condition messages allow domain text and reject internal detail", {
  fallback <- "Workspace could not be saved. Check the name and local storage configuration."
  safe_prefixes <- c("Workspace", "Dataset")
  safe_message <- "Workspace name must not be empty."
  unsafe_messages <- c(
    "Workspace failed at C:/Users/developer/AppData/Local/Temp/state.rds",
    "Workspace failed at /tmp/private/state.rds",
    "Workspace failed at \\\\server\\share\\state.rds",
    "Workspace conditionMessage internal function failure",
    "Workspace parser traceback in shiny.internal",
    "Workspace ggplot ggsave file.copy curl failure"
  )

  testthat::expect_identical(
    raw24_safe_condition_message(simpleError(safe_message), safe_prefixes, fallback),
    safe_message
  )
  for (unsafe_message in unsafe_messages) {
    testthat::expect_true(raw24_contains_internal_detail(unsafe_message))
    testthat::expect_identical(
      raw24_safe_condition_message(simpleError(unsafe_message), safe_prefixes, fallback),
      fallback
    )
  }
})

testthat::test_that("the interrupted-promise muffler preserves unrelated warnings", {
  testthat::expect_warning(
    muffle_interrupted_workflow_promise(warning("new warning category")),
    "new warning category",
    fixed = TRUE
  )
})

testthat::test_that("RAW-24 model failures separate the safe message from diagnostics and retry", {
  joined <- data.frame(
    biol_site_id = "B1",
    Q95 = 1:4,
    LIFE_OE = c(0.8, 0.9, 1.1, 1.2),
    stringsAsFactors = FALSE
  )
  joined_before_failure <- joined
  raw_detail <- paste(
    "lm.fit stats package failure at",
    "C:/Users/developer/AppData/Local/Temp/model-input.csv"
  )
  attempts <- 0L
  retrying_runner <- function(data, flow_var, ecology_var) {
    attempts <<- attempts + 1L
    if (attempts == 1L) {
      stop(raw_detail, call. = FALSE)
    }
    build_basic_flow_ecology_model(data, flow_var, ecology_var)
  }

  failure <- run_model(
    joined,
    list(flow_var = "Q95", ecology_var = "LIFE_OE"),
    model_runner = retrying_runner
  )
  retry <- run_model(
    joined,
    list(flow_var = "Q95", ecology_var = "LIFE_OE"),
    model_runner = retrying_runner
  )

  testthat::expect_identical(failure$status, "error")
  testthat::expect_identical(failure$messages, model_fit_failure_message())
  testthat::expect_identical(failure$diagnostic, raw_detail)
  testthat::expect_false(grepl(
    "conditionMessage|lm.fit|stats package|C:/Users|AppData|model-input",
    failure$messages
  ))
  testthat::expect_identical(joined, joined_before_failure)
  testthat::expect_identical(retry$status, "success")
  testthat::expect_null(retry$diagnostic)
  testthat::expect_identical(attempts, 2L)
})
