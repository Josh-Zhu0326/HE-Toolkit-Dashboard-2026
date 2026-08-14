source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workspace_state.R"))
source(testthat::test_path("..", "..", "R", "processed_dataset_checkpoint.R"))

processed_checkpoint_fixture <- function() {
  data.frame(
    biol_site_id = c("B1", "B1", "B2"),
    sample_id = c("S1", "S2", "S3"),
    date = as.Date(c("2020-05-01", "2021-10-01", "2022-05-01")),
    Year = 2020:2022,
    Q95_lag0 = c(1.2, 1.1, 1.0),
    Q95z_lag0 = c(-1, 0, 1),
    LIFE_F_OE = c(0.8, 1.0, 1.2),
    stringsAsFactors = FALSE
  )
}

testthat::test_that("processed dataset checkpoint round trip preserves data and provenance", {
  path <- tempfile("processed-checkpoint-", fileext = ".rds")
  on.exit(unlink(path, force = TRUE), add = TRUE)
  dataset <- processed_checkpoint_fixture()

  manifest <- write_processed_dataset_checkpoint(
    dataset,
    path,
    provenance = list(join_method = "A", lags = 0L),
    app_version = "test-commit",
    created_at = as.POSIXct("2026-08-04 12:00:00", tz = "UTC")
  )
  restored <- read_processed_dataset_checkpoint(path)

  testthat::expect_identical(restored$dataset, dataset)
  testthat::expect_identical(restored$manifest, manifest)
  testthat::expect_identical(restored$manifest$app_version, "test-commit")
  testthat::expect_identical(restored$manifest$provenance$join_method, "A")
  testthat::expect_match(restored$manifest$dataset_checksum, "^[0-9a-f]{32}$")
})

testthat::test_that("processed checkpoint HEV view preserves dates and normalises lag-zero names", {
  dataset <- processed_checkpoint_fixture()
  hev_data <- processed_dataset_checkpoint_hev_data(dataset)

  testthat::expect_s3_class(hev_data$date, "Date")
  testthat::expect_true("Q95" %in% names(hev_data))
  testthat::expect_false("Q95_lag0" %in% names(hev_data))
  testthat::expect_identical(hev_data$Q95, dataset$Q95_lag0)
  testthat::expect_true("Q95z" %in% names(hev_data))
  testthat::expect_false("Q95z_lag0" %in% names(hev_data))
  testthat::expect_identical(hev_data$Q95z, dataset$Q95z_lag0)

  testthat::expect_error(
    processed_dataset_checkpoint_hev_data(dataset[, names(dataset) != "date"]),
    "sample date required for HEV",
    fixed = TRUE
  )
})

testthat::test_that("processed dataset checkpoint rejects corruption and schema drift", {
  dataset <- processed_checkpoint_fixture()
  checkpoint <- new_processed_dataset_checkpoint(dataset, app_version = "test-commit")

  corrupted <- checkpoint
  corrupted$dataset$LIFE_F_OE[[1L]] <- 9.9
  testthat::expect_error(
    validate_processed_dataset_checkpoint(corrupted),
    "failed its integrity check",
    fixed = TRUE
  )

  drifted <- checkpoint
  drifted$dataset$unexpected <- 1:3
  testthat::expect_error(
    validate_processed_dataset_checkpoint(drifted),
    "schema does not match",
    fixed = TRUE
  )
})

testthat::test_that("processed dataset checkpoint requires downstream identity fields", {
  dataset <- data.frame(value = 1:3)
  testthat::expect_error(
    new_processed_dataset_checkpoint(dataset),
    "biol_site_id",
    fixed = TRUE
  )

  dataset$biol_site_id <- "B1"
  dataset$Year <- 2020:2022
  testthat::expect_error(
    new_processed_dataset_checkpoint(dataset),
    "record_id or sample_id",
    fixed = TRUE
  )
})
