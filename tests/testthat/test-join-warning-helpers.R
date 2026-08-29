testthat::test_that("join warning reports missing mappings and unavailable dates", {
  biology_data <- data.frame(
    biol_site_id = c("B1", "B1", "B2", "B3"),
    SAMPLE_DATE = as.Date(c("2020-06-01", "2020-05-01", "2020-01-01", NA))
  )
  flow_stats <- data.frame(
    flow_site_id = c("F1", "F1", "F3"),
    start_date = as.Date(c("2020-05-15", "2020-06-15", NA))
  )
  mapping <- data.frame(
    biol_site_id = c("B1", "B2", "B3"),
    flow_site_id = c("F1", "F2", "F3")
  )

  diagnostics <- biology_flow_start_diagnostics(biology_data, flow_stats, mapping)
  testthat::expect_identical(diagnostics$preceding_sites, "B1")
  testthat::expect_identical(diagnostics$missing_biology_date_sites, "B3")
  testthat::expect_identical(diagnostics$missing_flow_window_sites, "B2")
  testthat::expect_identical(diagnostics$missing_flow_start_sites, "B3")
  testthat::expect_identical(
    biology_flow_start_warning_messages(diagnostics),
    c(
      "Biology sample dates are missing for site(s): B3.",
      "No Flow Statistics window is available for Biology site(s): B2.",
      "Flow Statistics window start dates are missing for Biology site(s): B3.",
      "Biology samples precede the earliest Flow Statistics window for site(s): B1."
    )
  )

  mapping$flow_site_id[mapping$biol_site_id == "B2"] <- NA_character_
  diagnostics <- biology_flow_start_diagnostics(biology_data, flow_stats, mapping)
  testthat::expect_identical(
    diagnostics$missing_flow_mapping_sites,
    "B2"
  )
  testthat::expect_true(any(grepl(
    "Biology-to-Flow mapping is missing for Biology site(s): B2.",
    biology_flow_start_warning_messages(diagnostics),
    fixed = TRUE
  )))
})

testthat::test_that("invalid and non-finite date values become missing-date warnings", {
  biology_data <- data.frame(
    biol_site_id = c("B1", "B1", "B2", "B3"),
    SAMPLE_DATE = c("not-a-date", "2020-05-01", "", NA_character_)
  )
  flow_stats <- data.frame(
    flow_site_id = c("F1", "F1", "F2", "F3"),
    start_date = c("2020-06-01", "bad-flow-date", "2020-01-01", NA_character_)
  )
  mapping <- data.frame(
    biol_site_id = c("B1", "B2", "B3"),
    flow_site_id = c("F1", "F2", "F3")
  )

  testthat::expect_no_error({
    diagnostics <- biology_flow_start_diagnostics(biology_data, flow_stats, mapping)
  })
  testthat::expect_identical(
    diagnostics$missing_biology_date_sites,
    c("B1", "B2", "B3")
  )
  testthat::expect_identical(diagnostics$missing_flow_start_sites, c("B1", "B3"))
  testthat::expect_identical(diagnostics$preceding_sites, "B1")
})

testthat::test_that("empty inputs return stable diagnostics instead of failing", {
  empty_biology <- data.frame(
    biol_site_id = character(),
    SAMPLE_DATE = as.Date(character())
  )
  empty_flow <- data.frame(
    flow_site_id = character(),
    start_date = as.Date(character())
  )
  empty_mapping <- data.frame(
    biol_site_id = character(),
    flow_site_id = character()
  )

  diagnostics <- biology_flow_start_diagnostics(
    empty_biology,
    empty_flow,
    empty_mapping
  )
  testthat::expect_identical(
    diagnostics,
    list(
      preceding_sites = character(),
      missing_biology_date_sites = character(),
      missing_flow_mapping_sites = character(),
      missing_flow_window_sites = character(),
      missing_flow_start_sites = character()
    )
  )
  testthat::expect_identical(
    biology_flow_start_warning_messages(diagnostics),
    character()
  )
})

testthat::test_that("empty Flow data warns for every mapped Biology site", {
  biology_data <- data.frame(
    biol_site_id = c("B2", "B1"),
    SAMPLE_DATE = as.Date(c("2020-02-01", "2020-01-01"))
  )
  empty_flow <- data.frame(
    flow_site_id = character(),
    start_date = as.Date(character())
  )
  mapping <- data.frame(
    biol_site_id = c("B1", "B2"),
    flow_site_id = c("F1", "F2")
  )

  diagnostics <- biology_flow_start_diagnostics(biology_data, empty_flow, mapping)
  testthat::expect_identical(diagnostics$missing_flow_window_sites, c("B1", "B2"))
  testthat::expect_identical(
    biology_flow_start_warning_messages(diagnostics),
    "No Flow Statistics window is available for Biology site(s): B1, B2."
  )
})

testthat::test_that("blank mappings and unknown Flow sites produce distinct warnings", {
  biology_data <- data.frame(
    biol_site_id = c("B1", "B2", "B3"),
    SAMPLE_DATE = as.Date(rep("2020-01-01", 3L))
  )
  flow_stats <- data.frame(
    flow_site_id = "F1",
    start_date = as.Date("2020-01-01")
  )
  mapping <- data.frame(
    biol_site_id = c("B1", "B2", "B3"),
    flow_site_id = c(NA_character_, "   ", "F404")
  )

  diagnostics <- biology_flow_start_diagnostics(biology_data, flow_stats, mapping)
  testthat::expect_identical(diagnostics$missing_flow_mapping_sites, c("B1", "B2"))
  testthat::expect_identical(diagnostics$missing_flow_window_sites, "B3")
  testthat::expect_length(diagnostics$preceding_sites, 0L)
})

testthat::test_that("duplicate unsorted records use the earliest valid date once", {
  biology_data <- data.frame(
    biol_site_id = c("B2", "B1", "B1", "B2", "B1"),
    SAMPLE_DATE = as.Date(c(
      "2021-02-01", "2021-03-01", "2020-04-01", "2020-06-01", "2020-04-01"
    ))
  )
  flow_stats <- data.frame(
    flow_site_id = c("F2", "F1", "F1", "F2"),
    start_date = as.Date(c("2020-01-01", "2020-05-01", "2020-07-01", "2020-02-01"))
  )
  mapping <- data.frame(
    biol_site_id = c("B2", "B1"),
    flow_site_id = c("F2", "F1")
  )

  diagnostics <- biology_flow_start_diagnostics(biology_data, flow_stats, mapping)
  testthat::expect_identical(diagnostics$preceding_sites, "B1")
  testthat::expect_identical(
    biology_flow_start_warning_messages(diagnostics),
    "Biology samples precede the earliest Flow Statistics window for site(s): B1."
  )
})

testthat::test_that("date normalisation accepts Date, POSIXct, numeric and factor inputs", {
  expected <- as.Date(c("2020-01-01", "2020-01-02"))

  testthat::expect_identical(normalise_join_warning_dates(expected), expected)
  testthat::expect_identical(
    normalise_join_warning_dates(as.POSIXct(expected, tz = "UTC")),
    expected
  )
  testthat::expect_identical(
    normalise_join_warning_dates(as.numeric(expected)),
    expected
  )
  testthat::expect_identical(
    normalise_join_warning_dates(c(as.numeric(expected[[1L]]), Inf, -Inf, NA_real_)),
    as.Date(c("2020-01-01", NA, NA, NA))
  )
  testthat::expect_identical(
    normalise_join_warning_dates(factor(as.character(expected))),
    expected
  )
})
