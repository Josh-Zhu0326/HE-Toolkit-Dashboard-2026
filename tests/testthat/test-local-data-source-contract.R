testthat::test_that("the five client-confirmed local CSV contracts are defined", {
  testthat::expect_identical(
    names(local_dataset_contracts()),
    c("biology", "environment", "flow", "wq", "rhs")
  )
  testthat::expect_identical(
    local_source_modes(),
    c(
      "External data only" = "external",
      "Use local data instead" = "local",
      "Combine external and local data" = "combine"
    )
  )
})

testthat::test_that("each local CSV template contains one valid example row", {
  for (dataset_type in names(local_dataset_contracts())) {
    template <- local_dataset_template_data(dataset_type)
    contract <- local_dataset_contracts()[[dataset_type]]
    testthat::expect_identical(
      names(template),
      contract$required,
      info = dataset_type
    )
    testthat::expect_equal(nrow(template), 1L, info = dataset_type)
    testthat::expect_true(
      validate_local_dataset(template, dataset_type)$status %in% c("success", "warning"),
      info = dataset_type
    )
  }
})

testthat::test_that("local Biology requires identifiers, dates and at least one index", {
  biology <- data.frame(
    biol_site_id = "B01",
    SAMPLE_ID = "S01",
    SAMPLE_DATE = "2024-05-01",
    WHPT_ASPT = "6.1",
    WHPT_N_TAXA = "",
    LIFE_FAMILY_INDEX = "",
    PSI_FAMILY_SCORE = "",
    Month = "5",
    Year = "2024",
    Season = "Spring",
    stringsAsFactors = FALSE
  )
  result <- validate_local_dataset(biology, "biology")
  testthat::expect_identical(result$status, "success")
  testthat::expect_s3_class(result$data$SAMPLE_DATE, "Date")
  testthat::expect_type(result$data$Year, "integer")

  no_index <- biology
  no_index[c("WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE")] <- ""
  testthat::expect_identical(
    validate_local_dataset(no_index, "biology")$status,
    "error"
  )

  missing_index_column <- biology[, setdiff(names(biology), "WHPT_N_TAXA"), drop = FALSE]
  testthat::expect_identical(
    validate_local_dataset(missing_index_column, "biology")$status,
    "error"
  )
})

testthat::test_that("local Flow preserves identifiers and rejects invalid values", {
  flow <- data.frame(
    flow_site_id = "00123",
    date = "2024-01-01",
    flow = "12.4",
    stringsAsFactors = FALSE
  )
  result <- validate_local_dataset(flow, "flow")
  testthat::expect_identical(result$status, "success")
  testthat::expect_identical(result$data$flow_site_id, "00123")
  testthat::expect_equal(result$data$flow, 12.4)

  flow$flow <- "not-a-number"
  testthat::expect_identical(validate_local_dataset(flow, "flow")$status, "error")
})

testthat::test_that("local Environmental rows require alkalinity or proxy chemistry", {
  environment <- local_dataset_template_data("environment")
  without_proxy_columns <- environment[, setdiff(names(environment), c(
    "CONDUCTIVITY", "TOTAL_HARDNESS", "CALCIUM"
  )), drop = FALSE]
  testthat::expect_identical(
    validate_local_dataset(without_proxy_columns, "environment")$status,
    "error"
  )

  environment$ALKALINITY <- ""
  environment$CONDUCTIVITY <- ""

  missing_proxy <- validate_local_dataset(environment, "environment")
  testthat::expect_identical(missing_proxy$status, "error")
  testthat::expect_match(
    missing_proxy$messages,
    "provide at least one of CONDUCTIVITY, TOTAL_HARDNESS, CALCIUM",
    fixed = TRUE
  )

  environment$TOTAL_HARDNESS <- "120"
  hardness_proxy <- validate_local_dataset(environment, "environment")
  testthat::expect_identical(hardness_proxy$status, "success")
  testthat::expect_equal(hardness_proxy$data$TOTAL_HARDNESS, 120)

  two_rows <- rbind(environment, environment)
  two_rows$biol_site_id <- c("B01", "B02")
  two_rows$TOTAL_HARDNESS <- c("120", "")
  row_level <- validate_local_dataset(two_rows, "environment")
  testthat::expect_identical(row_level$status, "error")
  testthat::expect_match(row_level$messages, "row(s) 2", fixed = TRUE)
})

testthat::test_that("source modes replace or append without silent deduplication", {
  external <- data.frame(id = c("A", "B"), value = c(1, 2))
  local <- data.frame(id = c("B", "C"), value = c(20, 30))

  external_only <- resolve_local_data_source(external, local, "external", "dataset")
  local_only <- resolve_local_data_source(external, local, "local", "dataset")
  combined <- resolve_local_data_source(external, local, "combine", "dataset")

  external_resolved <- external_only$data
  local_resolved <- local_only$data
  attr(external_resolved, "source_provenance") <- NULL
  attr(local_resolved, "source_provenance") <- NULL
  testthat::expect_identical(external_resolved, external)
  testthat::expect_identical(local_resolved, local)
  testthat::expect_equal(nrow(combined$data), 4L)
  testthat::expect_equal(sum(combined$data$id == "B"), 2L)
  testthat::expect_identical(combined$provenance$output_rows, 4L)
  testthat::expect_identical(
    source_resolution_provenance(combined$data),
    combined$provenance
  )
  testthat::expect_match(
    summarise_source_resolution(combined$provenance, "Test"),
    "2 external, 2 local",
    fixed = TRUE
  )

  blocked <- resolve_local_data_source(external, NULL, "combine", "dataset")
  testthat::expect_identical(blocked$status, "blocked")
  testthat::expect_null(blocked$data)
})

testthat::test_that("combine mode canonicalises external fields and keeps local fields strict", {
  external <- data.frame(
    flow_site_id = "F01",
    date = as.Date("2024-01-01"),
    flow = 9
  )
  local <- data.frame(
    flow_site_id = "F01",
    date = as.Date("2024-01-02"),
    flow = 10
  )
  combined <- resolve_local_data_source(external, local, "combine", "Flow")
  testthat::expect_identical(names(combined$data), c("flow_site_id", "date", "flow"))
  testthat::expect_equal(nrow(combined$data), 2L)

  extra <- transform(external, external_note = "HDE")
  reordered <- external[, rev(names(external)), drop = FALSE]
  missing <- external[, setdiff(names(external), "flow"), drop = FALSE]
  extra_result <- resolve_local_data_source(extra, local, "combine", "Flow")
  reordered_result <- resolve_local_data_source(reordered, local, "combine", "Flow")
  testthat::expect_identical(extra_result$status, "success")
  testthat::expect_identical(extra_result$provenance$external_dropped_fields, "external_note")
  testthat::expect_identical(reordered_result$status, "success")

  blocked <- resolve_local_data_source(missing, local, "combine", "Flow")
  testthat::expect_identical(blocked$status, "blocked")
  testthat::expect_match(blocked$messages, "cannot be converted", fixed = TRUE)

  invalid_local <- transform(local, local_note = "not canonical")
  blocked_local <- resolve_local_data_source(external, invalid_local, "combine", "Flow")
  testthat::expect_identical(blocked_local$status, "blocked")
  testthat::expect_match(blocked_local$messages, "canonical column contract", fixed = TRUE)
})

testthat::test_that("local CSV validation blocks unexpected and reordered columns", {
  biology <- local_dataset_template_data("biology")
  biology$EXTRA <- "not allowed"
  testthat::expect_identical(validate_local_dataset(biology, "biology")$status, "error")
  testthat::expect_match(
    validate_local_dataset(biology, "biology")$messages,
    "Unexpected column(s): EXTRA",
    fixed = TRUE
  )

  reordered <- biology[, rev(setdiff(names(biology), "EXTRA")), drop = FALSE]
  testthat::expect_identical(validate_local_dataset(reordered, "biology")$status, "error")
  testthat::expect_match(
    validate_local_dataset(reordered, "biology")$messages,
    "wrong order",
    fixed = TRUE
  )
})

testthat::test_that("realistic external WQ and RHS records are adapted before combination", {
  validated_wq <- validate_local_dataset(local_dataset_template_data("wq"), "wq")$data
  local_wq <- cbind(
    biol_site_id = "B01",
    validated_wq,
    stringsAsFactors = FALSE
  )
  external_wq <- data.frame(
    biol_site_id = "B01",
    wq_site_id = "WQ01",
    wq_site_name = "External WQ site",
    easting = 123456,
    northing = 654321,
    area = "Example area",
    date_time = "2024-01-01",
    det_id = "0180",
    determinand = "Orthophosphate reactive as P",
    result = 0.1,
    unit = "mg/L",
    qualifier = NA_character_,
    observation = NA_character_,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  wq_result <- resolve_local_data_source(external_wq, local_wq, "combine", "WQ")

  testthat::expect_identical(wq_result$status, "success")
  testthat::expect_identical(names(wq_result$data), canonical_source_fields("WQ"))
  testthat::expect_true(all(c("easting", "northing", "area") %in%
    wq_result$provenance$external_dropped_fields))
  testthat::expect_true(is.na(wq_result$data$notes[[1L]]))

  validated_rhs <- validate_local_dataset(local_dataset_template_data("rhs"), "rhs")$data
  local_rhs <- cbind(
    biol_site_id = "B01",
    validated_rhs,
    stringsAsFactors = FALSE
  )
  external_rhs <- data.frame(
    biol_site_id = "B01",
    Survey.ID = "RHS01",
    Survey.Status = "Complete",
    HQA = 60,
    HMS.Score = 22,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  rhs_result <- resolve_local_data_source(external_rhs, local_rhs, "combine", "RHS")

  testthat::expect_identical(rhs_result$status, "success")
  testthat::expect_identical(names(rhs_result$data), canonical_source_fields("RHS"))
  testthat::expect_false("HMS.Score" %in% names(rhs_result$data))
  testthat::expect_equal(rhs_result$data$HMSRBB[[1L]], 22)
  testthat::expect_true("Survey.Status" %in% rhs_result$provenance$external_dropped_fields)
  testthat::expect_match(
    paste(rhs_result$messages, collapse = " "),
    "HMS.Score to HMSRBB",
    fixed = TRUE
  )
  testthat::expect_match(
    rhs_result$provenance$external_adapter_messages,
    "HMS.Score to HMSRBB",
    fixed = TRUE
  )
})

testthat::test_that("external Biology and Environmental extras are explicitly projected", {
  local_biology <- validate_local_dataset(
    local_dataset_template_data("biology"),
    "biology"
  )$data
  external_biology <- local_biology
  external_biology$SAMPLE_VERSION <- 1L
  biology_result <- resolve_local_data_source(
    external_biology,
    local_biology,
    "combine",
    "Biology"
  )

  testthat::expect_identical(biology_result$status, "success")
  testthat::expect_identical(names(biology_result$data), canonical_source_fields("Biology"))
  testthat::expect_identical(
    biology_result$provenance$external_dropped_fields,
    "SAMPLE_VERSION"
  )

  local_environment <- validate_local_dataset(
    local_dataset_template_data("environment"),
    "environment"
  )$data
  external_environment <- local_environment
  external_environment$AGENCY_AREA <- "Example area"
  environment_result <- resolve_local_data_source(
    external_environment,
    local_environment,
    "combine",
    "Environmental"
  )

  testthat::expect_identical(environment_result$status, "success")
  testthat::expect_identical(
    names(environment_result$data),
    canonical_source_fields("Environmental")
  )
  testthat::expect_identical(
    environment_result$provenance$external_dropped_fields,
    "AGENCY_AREA"
  )
})

testthat::test_that("conflicting external RHS aliases block combination", {
  external_rhs <- data.frame(
    biol_site_id = "B01",
    rhs_survey_id = "RHS01",
    HQA = 60,
    HMSRBB = 21,
    HMS.Score = 22,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  validated_rhs <- validate_local_dataset(local_dataset_template_data("rhs"), "rhs")$data
  local_rhs <- cbind(
    biol_site_id = "B01",
    validated_rhs,
    stringsAsFactors = FALSE
  )

  result <- resolve_local_data_source(external_rhs, local_rhs, "combine", "RHS")
  testthat::expect_identical(result$status, "blocked")
  testthat::expect_match(result$messages, "conflicting HMS.Score and HMSRBB", fixed = TRUE)
})
