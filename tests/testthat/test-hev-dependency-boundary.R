source(testthat::test_path("..", "..", "R", "hev_dependency_helpers.R"))

testthat::test_that("RAW-01 missing HEV dependency has the agreed safe message", {
  result <- hev_dependency_check(package_available = FALSE)

  testthat::expect_identical(result$status, "error")
  testthat::expect_identical(
    result$message,
    paste(
      "The required package ggnewscale is missing.",
      "Please install project dependencies before using the HEV plot feature."
    )
  )
  testthat::expect_false(grepl("Error in|loadNamespace|library path", result$message))
})

testthat::test_that("HEV dependency preflight passes when the package is available", {
  result <- hev_dependency_check(package_available = TRUE)

  testthat::expect_identical(result$status, "success")
  testthat::expect_match(result$message, "available", fixed = TRUE)
})
