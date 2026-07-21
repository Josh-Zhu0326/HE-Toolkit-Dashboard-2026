options(stringsAsFactors = FALSE)

required_packages <- c("dplyr", "hetoolkit", "lubridate", "readr")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Install required packages before building fixtures: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(hetoolkit)
  library(readr)
})

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
output_dir <- file.path(repo_root, "tests", "fixtures", "ndmn_local_5_sites")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

download_dir <- tempfile("ndmn-fixture-download-")
dir.create(download_dir, recursive = TRUE)
original_dir <- getwd()
setwd(download_dir)
on.exit(setwd(original_dir), add = TRUE)
on.exit(unlink(download_dir, recursive = TRUE, force = TRUE), add = TRUE)

fixture_mapping <- data.frame(
  source_workbook_row = c("2", "6", "11", "16", "40"),
  biol_site_id = c("10708", "8314", "34310", "90187", "54017"),
  flow_site_id = c("SX26F065", "521210", "2859TH", "050101012", "2024"),
  flow_input = rep("HDE", 5),
  wq_site_id = c("SW-81520521", "SW-E7000500", "TH-PCNR0145", "SO-Y0004498", "MD-25029400"),
  rhs_survey_id = c("40266", "39906", "39880", "39884", "39615")
)

biology_start <- "2015-01-01"
biology_end <- "2024-12-31"
flow_start <- "2020-01-01"
flow_end <- "2024-12-31"
wq_start <- "2022-01-01"
wq_end <- "2024-12-31"
wq_determinands <- c(111, 180, 9924)
retrieved_at_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)

assert_columns <- function(data, required, label) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop(label, " is missing expected column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

write_fixture <- function(data, filename) {
  readr::write_csv(data, file.path(output_dir, filename), na = "")
  message("Wrote ", filename, " (", nrow(data), " rows)")
}

message("Downloading biology data...")
biology_raw <- hetoolkit::import_inv(
  source = "parquet",
  sites = fixture_mapping$biol_site_id,
  start_date = biology_start,
  end_date = biology_end,
  save = FALSE,
  save_dwnld = FALSE
)
assert_columns(
  biology_raw,
  c("biol_site_id", "SAMPLE_ID", "SAMPLE_DATE", "WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE"),
  "Downloaded biology data"
)
biology <- biology_raw |>
  dplyr::transmute(
    biol_site_id = as.character(.data$biol_site_id),
    sample_id = as.character(.data$SAMPLE_ID),
    date = as.Date(.data$SAMPLE_DATE),
    WHPT_ASPT = as.numeric(.data$WHPT_ASPT),
    WHPT_NTAXA = as.numeric(.data$WHPT_N_TAXA),
    LIFE_F = as.numeric(.data$LIFE_FAMILY_INDEX),
    PSI_F = as.numeric(.data$PSI_FAMILY_SCORE)
  ) |>
  dplyr::arrange(.data$biol_site_id, .data$date, .data$sample_id)

message("Downloading environmental site data...")
environment_raw <- hetoolkit::import_env(sites = fixture_mapping$biol_site_id, save = FALSE, save_dwnld = FALSE)
assert_columns(
  environment_raw,
  c(
    "biol_site_id", "NGR_PREFIX", "EASTING", "NORTHING", "ALTITUDE", "SLOPE", "DISCHARGE",
    "DIST_FROM_SOURCE", "WIDTH", "DEPTH", "ALKALINITY", "CONDUCTIVITY", "TOTAL_HARDNESS", "CALCIUM",
    "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND", "SILT_CLAY"
  ),
  "Downloaded environmental data"
)
environment <- environment_raw |>
  dplyr::transmute(
    biol_site_id = as.character(.data$biol_site_id),
    NGR_prefix = as.character(.data$NGR_PREFIX),
    easting = as.character(.data$EASTING),
    northing = as.character(.data$NORTHING),
    altitude = as.numeric(.data$ALTITUDE),
    slope = as.numeric(.data$SLOPE),
    discharge = as.numeric(.data$DISCHARGE),
    distance_from_source = as.numeric(.data$DIST_FROM_SOURCE),
    width = as.numeric(.data$WIDTH),
    depth = as.numeric(.data$DEPTH),
    alkalinity = as.numeric(.data$ALKALINITY),
    conductivity = as.numeric(.data$CONDUCTIVITY),
    total_hardness = as.numeric(.data$TOTAL_HARDNESS),
    calcium = as.numeric(.data$CALCIUM),
    boulders_cobbles = as.numeric(.data$BOULDERS_COBBLES),
    pebbles_gravel = as.numeric(.data$PEBBLES_GRAVEL),
    sand = as.numeric(.data$SAND),
    silt_clay = as.numeric(.data$SILT_CLAY)
  ) |>
  dplyr::arrange(.data$biol_site_id)

message("Downloading HDE flow data...")
flow_raw <- hetoolkit::import_flow(
  sites = fixture_mapping$flow_site_id,
  inputs = fixture_mapping$flow_input,
  start_date = flow_start,
  end_date = flow_end
)
assert_columns(flow_raw, c("flow_site_id", "date", "flow"), "Downloaded flow data")
flow <- flow_raw |>
  dplyr::transmute(
    flow_site_id = as.character(.data$flow_site_id),
    date = as.Date(.data$date),
    flow = as.numeric(.data$flow)
  ) |>
  dplyr::arrange(.data$flow_site_id, .data$date)

message("Downloading WQ data...")
wq_raw <- hetoolkit::import_wq(
  source = NULL,
  sites = fixture_mapping$wq_site_id,
  dets = wq_determinands,
  start_date = wq_start,
  end_date = wq_end,
  save = FALSE
)
assert_columns(
  wq_raw,
  c("wq_site_id", "date_time", "det_id", "determinand", "result", "unit", "qualifier", "observation"),
  "Downloaded WQ data"
)
wq <- wq_raw |>
  dplyr::transmute(
    wq_site_id = as.character(.data$wq_site_id),
    date = as.Date(.data$date_time),
    det_id = as.character(.data$det_id),
    det_label = as.character(.data$determinand),
    result = as.numeric(.data$result),
    unit = as.character(.data$unit),
    qualifier = as.character(.data$qualifier),
    observation = as.character(.data$observation)
  ) |>
  dplyr::arrange(.data$wq_site_id, .data$date, .data$det_id)

message("Downloading RHS data...")
rhs_raw <- hetoolkit::import_rhs(
  source = NULL,
  surveys = fixture_mapping$rhs_survey_id,
  save = FALSE,
  save_dwnld = FALSE
)
assert_columns(
  rhs_raw,
  c("Survey.ID", "Survey.Date", "Location", "HQA", "Hms.Rsctned.Bnk.Bed.Sub.Score"),
  "Downloaded RHS data"
)
rhs <- rhs_raw |>
  dplyr::transmute(
    rhs_survey_id = as.character(.data$Survey.ID),
    survey_date = as.Date(lubridate::dmy(as.character(.data$Survey.Date), quiet = TRUE)),
    location = as.character(.data$Location),
    HMSRBB = as.numeric(.data$Hms.Rsctned.Bnk.Bed.Sub.Score),
    HQA = as.numeric(.data$HQA)
  ) |>
  dplyr::arrange(.data$rhs_survey_id)

mapping <- fixture_mapping |>
  dplyr::select(-"source_workbook_row")

write_fixture(mapping, "site_mapping_5_sites.csv")
write_fixture(biology, "biology_samples_5_sites.csv")
write_fixture(environment, "environmental_site_data_5_sites.csv")
write_fixture(flow, "flow_daily_5_sites.csv")
write_fixture(wq, "wq_long_standard_5_sites.csv")
write_fixture(rhs, "rhs_site_level_5_sites.csv")

coverage <- data.frame(
  dataset = c("site_mapping", "biology_samples", "environmental_site_data", "flow_daily", "wq_long_standard", "rhs_site_level"),
  rows = c(nrow(mapping), nrow(biology), nrow(environment), nrow(flow), nrow(wq), nrow(rhs)),
  requested_ids = rep(nrow(mapping), 6),
  returned_ids = c(
    length(unique(mapping$biol_site_id)),
    length(unique(biology$biol_site_id)),
    length(unique(environment$biol_site_id)),
    length(unique(flow$flow_site_id)),
    length(unique(wq$wq_site_id)),
    length(unique(rhs$rhs_survey_id))
  )
)
write_fixture(coverage, "coverage_summary.csv")

provenance <- data.frame(
  dataset = coverage$dataset,
  source = c(
    "NDMN site metadata.xlsx",
    "EA Ecology and Fish Data Explorer",
    "EA Ecology and Fish Data Explorer",
    "EA Hydrology Data Explorer via hetoolkit::import_flow",
    "EA Water Quality Explorer via hetoolkit::import_wq",
    "EA River Habitat Survey Open Data via hetoolkit::import_rhs"
  ),
  retrieval_time_utc = rep(retrieved_at_utc, 6),
  start_date = c("", biology_start, "", flow_start, wq_start, ""),
  end_date = c("", biology_end, "", flow_end, wq_end, ""),
  package_version = rep(as.character(utils::packageVersion("hetoolkit")), 6),
  notes = c(
    "Coverage-selected source rows 2, 6, 11, 16 and 40; rhs_site_id intentionally excluded from the standard mapping.",
    "Historical window fixed for reproducibility; uploaded O:E values are not included.",
    "Site-level fields standardised to the Week 7 data contract.",
    paste0(
      "Local flow schema contains flow_site_id, date and flow only; HDE source is recorded in site mapping. ",
      "hetoolkit 2.1.3 emitted readr parsing warnings while processing HDE metadata/quality fields; ",
      sum(!is.finite(flow$flow)), " missing flow values were retained and date-site coverage was verified offline."
    ),
    "Determinands 111, 180 and 9924; qualifiers are preserved and results are not detection-limit adjusted.",
    "HMSRBB uses Hms.Rsctned.Bnk.Bed.Sub.Score; rhs_survey_id is the only mapping identifier."
  )
)
write_fixture(provenance, "provenance.csv")

message("Real local fixture build complete: ", normalizePath(output_dir, winslash = "/"))
