source("global.R")
dashboard_server <- source("server.R")$value

metadata_text <- paste(
  "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
  "291,27090,NRFA,SW-A4070115,TBC",
  sep = "\n"
)

artifact_pattern <- "^(WQ_DATA_METRICS\\.rds|RHS_survey_summary_.*\\.rds|River_Habitat_Survey.*\\.(zip|xlsx))$"
artifacts_before <- list.files(pattern = artifact_pattern)

shiny::testServer(dashboard_server, {
  upload_path <- normalizePath("demo_site_metadata.csv", winslash = "/", mustWork = TRUE)
  session$setInputs(site_metadata_csv = list(
    name = "demo_site_metadata.csv",
    size = file.info(upload_path)$size,
    type = "text/csv",
    datapath = upload_path
  ))
  session$flushReact()
  stopifnot(identical(site_metadata_upload_result()$status, "success"))

  session$setInputs(
    meta_paste = metadata_text,
    date_range_wq = as.Date(c("2024-01-01", "2025-01-01"))
  )

  session$setInputs(import_rhs_site_ids = 1)
  session$flushReact()
  stopifnot(is.null(rhs_site_import_data()))
  stopifnot(identical(rhs_site_import_result()$status, "warning"))

  if (identical(Sys.getenv("RUN_LIVE_WQ_TEST"), "true")) {
    session$setInputs(import_wq_site_ids = 1)
    session$flushReact()
    imported <- wq_site_import_data()
    stopifnot(!is.null(imported), nrow(imported) > 0)
    stopifnot(all(imported$biol_site_id == "291"))
    stopifnot(all(imported$wq_site_id == "SW-A4070115"))
    stopifnot(identical(wq_site_import_result()$status, "success"))
  }
})

artifacts_after <- list.files(pattern = artifact_pattern)
stopifnot(identical(artifacts_before, artifacts_after))
cat("server site import tests passed\n")
