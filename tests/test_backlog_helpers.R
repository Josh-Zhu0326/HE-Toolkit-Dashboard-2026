source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))
source(file.path("R", "dashboard_backlog_helpers.R"))

mapping <- read_dashboard_csv(file.path("tests", "fixtures", "mapping.csv"), "Mapping")
stopifnot(identical(mapping$status, "success"))
mapping_validation <- validate_supporting_mapping(mapping$data)
stopifnot(identical(mapping_validation$status, "warning"))
stopifnot(any(grepl("rhs_survey_id", mapping_validation$messages)))

missing_mapping <- data.frame(
  biol_site_id = "291",
  flow_site_id = "27090",
  flow_input = "NRFA",
  stringsAsFactors = FALSE
)
missing_validation <- validate_supporting_mapping(missing_mapping)
stopifnot(identical(missing_validation$status, "error"))

duplicated_mapping <- data.frame(
  biol_site_id = c("291", "291"),
  flow_site_id = c("27090", "27091"),
  flow_input = c("NRFA", "NRFA"),
  wq_site_id = c("WQ1", "WQ2"),
  rhs_survey_id = c("RHS1", "RHS2"),
  stringsAsFactors = FALSE
)
duplicated_validation <- validate_supporting_mapping(duplicated_mapping)
stopifnot(identical(duplicated_validation$status, "warning"))

local_flow <- read_dashboard_csv(file.path("tests", "fixtures", "local_flow.csv"), "Local flow")
stopifnot(identical(validate_local_flow(local_flow$data)$status, "success"))

bad_flow <- local_flow$data
bad_flow$flow_input[[1]] <- "BAD"
stopifnot(identical(validate_local_flow(bad_flow)$status, "error"))

local_inv <- read_dashboard_csv(file.path("tests", "fixtures", "local_invertebrate.csv"), "Local invertebrate")
stopifnot(identical(validate_local_invertebrate(local_inv$data)$status, "success"))

model_data <- data.frame(
  LIFE_F_OE = c(0.9, 1.1, 1.2, 0.8),
  Q95z_lag0 = c(-0.2, 0.1, 0.3, -0.5),
  stringsAsFactors = FALSE
)
model <- build_basic_flow_ecology_model(model_data, "Q95z_lag0", "LIFE_F_OE")
stopifnot(identical(model$status, "success"))
stopifnot(inherits(model$plot, "ggplot"))
stopifnot(nrow(model$summary) == 1)

small_model <- build_basic_flow_ecology_model(model_data[1:2, ], "Q95z_lag0", "LIFE_F_OE")
stopifnot(identical(small_model$status, "error"))

cat("backlog helper tests passed\n")
