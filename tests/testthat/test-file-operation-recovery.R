source(testthat::test_path("..", "..", "R", "file_operation_helpers.R"))
source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))

testthat::test_that("RAW-19 file boundary returns success and sanitises writer failures", {
  success <- safe_file_operation(function() "created-file")
  raw_detail <- "Permission denied while opening C:/Users/private/output.csv"
  failure <- safe_file_operation(function() stop(raw_detail, call. = FALSE))

  testthat::expect_identical(success$status, "success")
  testthat::expect_identical(success$value, "created-file")
  testthat::expect_null(success$diagnostic)
  testthat::expect_identical(failure$status, "failed")
  testthat::expect_identical(failure$failure, "file_operation_error")
  testthat::expect_match(failure$diagnostic, raw_detail, fixed = TRUE)
  testthat::expect_match(failure$message, "The file could not be created or saved", fixed = TRUE)
  testthat::expect_match(failure$message, "destination is available and writable", fixed = TRUE)
  testthat::expect_false(grepl("Permission denied|C:/Users|output.csv", failure$message, fixed = FALSE))
})

testthat::test_that("RAW-19 failed derivative operation retains source state and retries", {
  source_artifact <- list(status = "complete", revision = 4L, data = data.frame(value = 1:2))
  download_history <- character()
  attempts <- 0L
  write_attempt <- function() {
    attempts <<- attempts + 1L
    if (attempts == 1L) {
      stop("write_csv failed at /private/runtime/result.csv", call. = FALSE)
    }
    "result.csv"
  }

  first <- safe_file_operation(write_attempt)
  if (identical(first$status, "success")) {
    download_history <- c(download_history, first$value)
  }
  retained_after_failure <- source_artifact
  second <- safe_file_operation(write_attempt)
  if (identical(second$status, "success")) {
    download_history <- c(download_history, second$value)
  }

  testthat::expect_identical(first$status, "failed")
  testthat::expect_identical(source_artifact, retained_after_failure)
  testthat::expect_identical(second$status, "success")
  testthat::expect_identical(second$value, "result.csv")
  testthat::expect_identical(download_history, "result.csv")
  testthat::expect_identical(attempts, 2L)
})

testthat::test_that("RAW-21 RHS runtime setup uses safe failure and supports retry", {
  original_dir <- getwd()
  raw_detail <- "Permission denied creating C:/Users/private/hetoolkit-rhs"
  failed_error <- tryCatch(
    import_rhs_in_temp_directory(
      "R1",
      importer = function(...) stop("importer must not run"),
      directory_factory = function() stop(raw_detail, call. = FALSE)
    ),
    dashboard_file_operation_error = identity
  )
  failure <- file_operation_condition_result(failed_error)

  testthat::expect_s3_class(failed_error, "dashboard_file_operation_error")
  testthat::expect_identical(failure$status, "failed")
  testthat::expect_match(failure$diagnostic, raw_detail, fixed = TRUE)
  testthat::expect_false(grepl("Permission denied|C:/Users|hetoolkit-rhs", failure$message))
  testthat::expect_identical(getwd(), original_dir)

  retry_dir <- NULL
  retry <- import_rhs_in_temp_directory(
    "R1",
    importer = function(source, surveys, save, save_dwnld, save_dir) {
      testthat::expect_identical(surveys, "R1")
      testthat::expect_identical(normalizePath(getwd()), normalizePath(save_dir))
      data.frame(Survey.ID = surveys, HQA = 42, stringsAsFactors = FALSE)
    },
    directory_factory = function() {
      retry_dir <<- tempfile("hetoolkit-rhs-retry-")
      retry_dir
    }
  )

  testthat::expect_identical(retry$rhs_survey_id, "R1")
  testthat::expect_identical(getwd(), original_dir)
  testthat::expect_false(dir.exists(retry_dir))
})
