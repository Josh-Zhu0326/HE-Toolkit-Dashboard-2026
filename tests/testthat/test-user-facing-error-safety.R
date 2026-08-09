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
    "Workspace failed at D:\\restricted\\state.rds",
    "Workspace failed at /Users/developer/private/state.rds",
    "Workspace failed at /home/developer/private/state.rds",
    "Workspace failed at /tmp/private/state.rds",
    "Workspace failed at path:/tmp/private/state.rds",
    "Workspace failed at path:/Users/developer/state.rds",
    "Workspace failed at location:/Library/Frameworks/foo",
    "Workspace failed at file:/srv/private/file.rds",
    "Workspace read failed at /Library/Frameworks/toolkit/state.rds",
    "Workspace read failed at /Applications/HE Toolkit/state.rds",
    "Workspace read failed at /Volumes/private/state.rds",
    "Workspace read failed at /srv/dashboard/state.rds",
    "Workspace read failed at /var/lib/dashboard/state.rds",
    "Workspace failed at /",
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

  benign_messages <- c(
    safe_message,
    "Workspace recovery guidance: https://example.org/help",
    "Workspace recovery guidance: http://example.org/help",
    "Workspace recovery guidance: https://docs.example.org/help/workspaces/recovery?mode=safe",
    "Workspace help is available at https://example.org/docs/a/b/c",
    "Workspace help is available at https://example.org/#/help/recovery",
    "Workspace help is available at http://localhost:8080/#/workflow/stage",
    "Workspace input/output label is required.",
    "Dataset numerator/denominator values are valid.",
    "Workspace selection must be yes/no before continuing."
  )
  for (benign_message in benign_messages) {
    testthat::expect_false(raw24_contains_internal_detail(benign_message))
    testthat::expect_identical(
      raw24_safe_condition_message(simpleError(benign_message), safe_prefixes, fallback),
      benign_message
    )
  }
})

testthat::test_that("RAW-24 rejects file URIs without rejecting HTTP URLs", {
  fallback <- "Workspace could not be saved. Check the name and local storage configuration."
  safe_prefixes <- c("Workspace", "Dataset")
  filesystem_uri_messages <- c(
    "Workspace failed at file:///Library/secret.rds",
    "Workspace failed at file:///tmp/private/state.rds",
    "Workspace failed at file:///Users/developer/state.rds",
    "Workspace failed at file:////server/share/secret.rds"
  )
  web_url_messages <- c(
    "Workspace recovery guidance: https://example.org/help",
    "Workspace recovery guidance: https://example.org/#/help/recovery",
    "Workspace recovery guidance: http://localhost:8080/#/workflow/stage"
  )

  for (unsafe_message in filesystem_uri_messages) {
    testthat::expect_true(raw24_contains_internal_detail(unsafe_message))
    sanitised <- raw24_safe_condition_message(
      simpleError(unsafe_message),
      safe_prefixes,
      fallback
    )
    testthat::expect_identical(sanitised, fallback)
    testthat::expect_false(grepl("file:|secret|private", sanitised, ignore.case = TRUE))
  }
  for (safe_message in web_url_messages) {
    testthat::expect_false(raw24_contains_internal_detail(safe_message))
    testthat::expect_identical(
      raw24_safe_condition_message(simpleError(safe_message), safe_prefixes, fallback),
      safe_message
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
