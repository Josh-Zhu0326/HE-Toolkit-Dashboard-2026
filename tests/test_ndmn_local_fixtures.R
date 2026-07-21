source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))
source(file.path("R", "dashboard_backlog_helpers.R"))

fixture_dir <- file.path("tests", "fixtures", "ndmn_local_5_sites")
read_fixture <- function(filename) {
  data.table::fread(
    file.path(fixture_dir, filename),
    data.table = FALSE,
    colClasses = "character",
    encoding = "UTF-8"
  )
}

mapping <- read_fixture("site_mapping_5_sites.csv")
biology <- read_fixture("biology_samples_5_sites.csv")
environment <- read_fixture("environmental_site_data_5_sites.csv")
flow <- read_fixture("flow_daily_5_sites.csv")
wq <- read_fixture("wq_long_standard_5_sites.csv")
rhs <- read_fixture("rhs_site_level_5_sites.csv")
coverage <- read_fixture("coverage_summary.csv")
provenance <- read_fixture("provenance.csv")

expected_biology_ids <- c("10708", "8314", "34310", "90187", "54017")
expected_flow_ids <- c("SX26F065", "521210", "2859TH", "050101012", "2024")
expected_wq_ids <- c("SW-81520521", "SW-E7000500", "TH-PCNR0145", "SO-Y0004498", "MD-25029400")
expected_rhs_ids <- c("40266", "39906", "39880", "39884", "39615")

stopifnot(identical(
  names(mapping),
  c("biol_site_id", "flow_site_id", "flow_input", "wq_site_id", "rhs_survey_id")
))
stopifnot(!"rhs_site_id" %in% names(mapping))
stopifnot(nrow(mapping) == 5L)
stopifnot(setequal(mapping$biol_site_id, expected_biology_ids))
stopifnot(setequal(mapping$flow_site_id, expected_flow_ids))
stopifnot(setequal(mapping$wq_site_id, expected_wq_ids))
stopifnot(setequal(mapping$rhs_survey_id, expected_rhs_ids))
stopifnot(all(mapping$flow_input == "HDE"))
stopifnot(any(mapping$flow_site_id == "050101012"))

parsed_mapping <- parse_site_metadata(readr::format_csv(mapping))
stopifnot(is.null(parsed_mapping$error))
stopifnot(is.null(validate_dashboard_site_metadata(parsed_mapping$data)))

uploaded_mapping <- read_site_metadata_csv(file.path(fixture_dir, "site_mapping_5_sites.csv"))
stopifnot(is.null(uploaded_mapping$error))
stopifnot(any(uploaded_mapping$data$flow_site_id == "050101012"))

stopifnot(nrow(biology) == 107L)
stopifnot(setequal(unique(biology$biol_site_id), expected_biology_ids))
stopifnot(all(grepl("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", biology$date)))
biology_indices <- biology[c("WHPT_ASPT", "WHPT_NTAXA", "LIFE_F", "PSI_F")]
stopifnot(all(rowSums(!is.na(biology_indices) & nzchar(as.matrix(biology_indices))) >= 1L))
stopifnot(!any(grepl("_OE$", names(biology))))

stopifnot(nrow(environment) == 5L)
stopifnot(setequal(environment$biol_site_id, expected_biology_ids))
stopifnot(all(nzchar(environment$NGR_prefix)))
alkalinity_available <- nzchar(environment$alkalinity)
proxy_available <- nzchar(environment$conductivity) |
  nzchar(environment$total_hardness) |
  nzchar(environment$calcium)
stopifnot(all(alkalinity_available | proxy_available))

stopifnot(identical(names(flow), c("flow_site_id", "date", "flow")))
stopifnot(nrow(flow) == 9135L)
stopifnot(setequal(unique(flow$flow_site_id), expected_flow_ids))
stopifnot(any(flow$flow_site_id == "050101012"))
stopifnot(all(grepl("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", flow$date)))
stopifnot(!anyDuplicated(paste(flow$flow_site_id, flow$date)))
stopifnot(all(table(flow$flow_site_id) == 1827L))
flow_values <- suppressWarnings(as.numeric(flow$flow))
stopifnot(sum(!is.finite(flow_values)) == 3L)
stopifnot(all(tapply(is.finite(flow_values), flow$flow_site_id, sum) >= 1800L))
stopifnot(!"flow_input" %in% names(flow))

uploaded_flow <- read_dashboard_csv(file.path(fixture_dir, "flow_daily_5_sites.csv"), "NDMN local flow")
stopifnot(identical(uploaded_flow$status, "success"))
stopifnot(any(as.character(uploaded_flow$data$flow_site_id) == "050101012"))

stopifnot(nrow(wq) == 520L)
stopifnot(setequal(unique(wq$wq_site_id), expected_wq_ids))
stopifnot(setequal(unique(wq$det_id), c("0111", "0180", "9924")))
stopifnot(all(c("det_id", "qualifier", "observation") %in% names(wq)))
stopifnot(any(wq$qualifier == "<"))
stopifnot(!any(c("easting", "northing", "area") %in% names(wq)))

stopifnot(nrow(rhs) == 5L)
stopifnot(identical(names(rhs), c("rhs_survey_id", "survey_date", "location", "HMSRBB", "HQA")))
stopifnot(setequal(rhs$rhs_survey_id, expected_rhs_ids))
stopifnot(all(grepl("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", rhs$survey_date)))
stopifnot(all(is.finite(suppressWarnings(as.numeric(rhs$HMSRBB)))))
stopifnot(all(is.finite(suppressWarnings(as.numeric(rhs$HQA)))))

mapped_wq <- map_wq_records_to_biology(wq, mapping)
stopifnot(nrow(mapped_wq) == nrow(wq))
stopifnot(!any(is.na(mapped_wq$biol_site_id) | !nzchar(mapped_wq$biol_site_id)))

mapped_rhs <- map_rhs_records_to_biology(rhs, mapping)
stopifnot(nrow(mapped_rhs) == nrow(rhs))
stopifnot(!any(is.na(mapped_rhs$biol_site_id) | !nzchar(mapped_rhs$biol_site_id)))

wq_plot <- build_wq_plot(
  mapped_wq,
  plot_type = "Time series",
  numeric_var = "result",
  date_col = "date",
  group_col = "biol_site_id"
)
stopifnot(inherits(wq_plot$plot, "ggplot"))

rhs_plot <- build_rhs_plot(
  mapped_rhs,
  plot_type = "Numeric variable by biological site ID",
  variable = "HMSRBB",
  group_col = "biol_site_id"
)
stopifnot(inherits(rhs_plot$plot, "ggplot"))

stopifnot(nrow(coverage) == 6L)
stopifnot(nrow(provenance) == 6L)
stopifnot(all(nzchar(provenance$source)))
stopifnot(all(provenance$package_version == "2.1.3"))

cat("NDMN local fixture tests passed\n")
