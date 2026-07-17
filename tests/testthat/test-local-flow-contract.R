source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))

local_flow_fixture <- function(name) {
  testthat::test_path("..", "fixtures", name)
}

valid_local_flow <- function() {
  data.frame(
    flow_site_id = "00123",
    date = "2024-01-01",
    flow = "12.4",
    stringsAsFactors = FALSE
  )
}

testthat::test_that("minimal Local Flow schema is accepted without biology or source columns", {
  input <- read_dashboard_csv(local_flow_fixture("local_flow.csv"), "Local flow")
  result <- validate_local_flow(input$data)

  testthat::expect_identical(input$status, "success")
  testthat::expect_identical(result$status, "success")
  testthat::expect_false("biol_site_id" %in% names(result$data))
  testthat::expect_false("flow_input" %in% names(result$data))
  testthat::expect_identical(names(result$data), c("flow_site_id", "date", "flow"))
})

testthat::test_that("extra Local Flow columns are warned about and excluded from operational data", {
  input <- read_dashboard_csv(local_flow_fixture("local_flow_extra_columns.csv"), "Local flow")
  result <- validate_local_flow(input$data)

  testthat::expect_identical(input$status, "success")
  testthat::expect_identical(result$status, "warning")
  testthat::expect_true(any(grepl("Ignored extra Local flow column(s): flow_input, biol_site_id, note.", result$messages, fixed = TRUE)))
  testthat::expect_identical(names(result$data), c("flow_site_id", "date", "flow"))
  testthat::expect_identical(result$data$flow, 21.5)
})

testthat::test_that("missing required Local Flow columns are rejected", {
  for (column in c("flow_site_id", "date", "flow")) {
    input <- valid_local_flow()
    input[[column]] <- NULL
    result <- validate_local_flow(input)

    testthat::expect_identical(result$status, "error", info = column)
    testthat::expect_match(result$messages, column, fixed = TRUE, info = column)
  }
})

testthat::test_that("blank flow_site_id values are rejected", {
  input <- valid_local_flow()
  input$flow_site_id <- " "
  result <- validate_local_flow(input)

  testthat::expect_identical(result$status, "error")
  testthat::expect_match(result$messages, "blank flow_site_id", fixed = TRUE)
})

testthat::test_that("Local Flow leading-zero identifiers remain character data", {
  input <- read_dashboard_csv(local_flow_fixture("local_flow_leading_zero.csv"), "Local flow")
  result <- validate_local_flow(input$data)

  testthat::expect_identical(result$status, "success")
  testthat::expect_type(result$data$flow_site_id, "character")
  testthat::expect_identical(result$data$flow_site_id, "00123")
})

testthat::test_that("numeric and numeric-character flow values are accepted", {
  numeric_result <- validate_local_flow(transform(valid_local_flow(), flow = 12.4))
  character_result <- validate_local_flow(valid_local_flow())

  testthat::expect_identical(numeric_result$status, "success")
  testthat::expect_identical(character_result$status, "success")
  testthat::expect_type(numeric_result$data$flow, "double")
  testthat::expect_identical(character_result$data$flow, 12.4)
})

testthat::test_that("missing and blank flow values are rejected", {
  for (flow_value in list(NA_character_, "", "   ")) {
    input <- valid_local_flow()
    input$flow <- flow_value
    result <- validate_local_flow(input)

    testthat::expect_identical(result$status, "error")
    testthat::expect_match(result$messages, "missing or blank flow", fixed = TRUE)
  }
})

testthat::test_that("non-numeric flow values are rejected", {
  input <- valid_local_flow()
  input$flow <- "not-a-flow"
  result <- validate_local_flow(input)

  testthat::expect_identical(result$status, "error")
  testthat::expect_match(result$messages, "non-numeric flow", fixed = TRUE)
})

testthat::test_that("blank NA and invalid date values are rejected", {
  for (date_value in list("", NA_character_, "not-a-date")) {
    input <- valid_local_flow()
    input$date <- date_value
    result <- validate_local_flow(input)

    testthat::expect_identical(result$status, "error")
    testthat::expect_match(result$messages, "blank or invalid date", fixed = TRUE)
  }
})
