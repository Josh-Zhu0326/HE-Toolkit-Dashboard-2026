source(file.path("R", "site_mapping_helpers.R"))

metadata_text <- paste(
  "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
  "291,27090,NRFA,SW-A4070115,TBC",
  sep = "\n"
)
parsed <- parse_site_metadata(metadata_text)
stopifnot(is.null(parsed$error))
stopifnot(identical(parsed$data$rhs_survey_id, "TBC"))
stopifnot(identical(usable_mapping_ids(parsed$data, "wq_site_id"), "SW-A4070115"))
stopifnot(length(usable_mapping_ids(parsed$data, "rhs_survey_id")) == 0)

uploaded <- read_site_metadata_csv("demo_site_metadata.csv")
stopifnot(is.null(uploaded$error))
stopifnot(is.null(validate_dashboard_site_metadata(uploaded$data)))
stopifnot(identical(uploaded$data$rhs_survey_id, "6145"))

stopifnot(is.null(validate_dashboard_site_metadata(data.frame(biol_site_id = "00291"))))
stopifnot(is.null(validate_dashboard_site_metadata(data.frame(wq_site_id = "SW-A4070115"))))
stopifnot(is.null(validate_dashboard_site_metadata(data.frame(rhs_survey_id = "6145"))))
stopifnot(is.null(validate_dashboard_site_metadata(data.frame(flow_site_id = "027090", flow_input = "NRFA"))))
stopifnot(!is.null(validate_dashboard_site_metadata(data.frame(site_id = "unknown"))))
stopifnot(!is.null(validate_dashboard_site_metadata(data.frame(flow_site_id = "027090"))))

invalid_flow <- uploaded$data
invalid_flow$flow_input <- "LOCAL"
stopifnot(!is.null(validate_dashboard_site_metadata(invalid_flow)))

leading_zero_file <- tempfile(fileext = ".csv")
writeLines("flow_site_id,flow_input\n027090,NRFA", leading_zero_file)
leading_zero <- read_site_metadata_csv(leading_zero_file)
unlink(leading_zero_file)
stopifnot(identical(leading_zero$data$flow_site_id, "027090"))

legacy <- parse_site_metadata("biol_site_id,rhs_site_id\n291,6145")
stopifnot(is.null(legacy$error))
stopifnot("rhs_survey_id" %in% names(legacy$data))
stopifnot(length(legacy$warnings) == 1)

duplicate <- parse_site_metadata("biol_site_id,wq_site_id\n291,A\n291,B")
stopifnot(!is.null(duplicate$error))

shared_metadata <- data.frame(
  biol_site_id = c("A", "B"),
  wq_site_id = c("WQ1", "WQ1"),
  rhs_survey_id = c("R1", "R1"),
  stringsAsFactors = FALSE
)
wq <- data.frame(wq_site_id = "WQ1", result = 2.5, stringsAsFactors = FALSE)
mapped_wq <- map_wq_records_to_biology(wq, shared_metadata)
stopifnot(nrow(mapped_wq) == 2)
stopifnot(setequal(mapped_wq$biol_site_id, c("A", "B")))

rhs <- data.frame(Survey.ID = "R1", HQA = 50, stringsAsFactors = FALSE)
mapped_rhs <- map_rhs_records_to_biology(rhs, shared_metadata)
stopifnot(nrow(mapped_rhs) == 2)
stopifnot("rhs_survey_id" %in% names(mapped_rhs))

original_dir <- getwd()
mock_importer <- function(source, surveys, save, save_dwnld, save_dir) {
  stopifnot(getwd() != original_dir)
  stopifnot(identical(surveys, "6145"))
  writeLines("temporary", "download.tmp")
  data.frame(Survey.ID = "6145", HQA = 42, stringsAsFactors = FALSE)
}
temp_rhs <- import_rhs_in_temp_directory("6145", importer = mock_importer)
stopifnot(identical(getwd(), original_dir))
stopifnot(identical(temp_rhs$rhs_survey_id, "6145"))

cat("site mapping tests passed\n")
