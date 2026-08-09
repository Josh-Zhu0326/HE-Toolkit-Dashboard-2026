source(testthat::test_path("..", "..", "R", "csv_input_helpers.R"))
source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))
source(testthat::test_path("..", "..", "R", "model_interface_helpers.R"))

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
