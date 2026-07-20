# test_model_interface_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_model_interface_helpers.R: all checks passed"

source(file.path("R", "dashboard_backlog_helpers.R"))
source(file.path("R", "model_interface_helpers.R"))

# Small synthetic joined-style dataset with a clear linear relationship.
set.seed(1)
joined <- data.frame(
  Q95     = 1:20,
  LIFE_OE = 2 * (1:20) + rnorm(20, sd = 0.5),
  stringsAsFactors = FALSE
)

# --- 1. Valid run returns a success result with plot + summary --------------
ok <- run_model(joined, list(flow_var = "Q95", ecology_var = "LIFE_OE"))
stopifnot(identical(ok$status, "success"))
stopifnot(!is.null(ok$summary))
stopifnot(!is.null(ok$plot))
stopifnot(ok$summary$direction == "positive")   # slope ~ +2

# --- 2. Missing data -> friendly error, not a crash -------------------------
stopifnot(identical(run_model(NULL, list(flow_var = "Q95", ecology_var = "LIFE_OE"))$status, "error"))
stopifnot(identical(run_model(joined[0, ], list(flow_var = "Q95", ecology_var = "LIFE_OE"))$status, "error"))

# --- 3. Unselected / invalid variables -> friendly error --------------------
stopifnot(identical(run_model(joined, list(flow_var = "", ecology_var = "LIFE_OE"))$status, "error"))
stopifnot(identical(run_model(joined, list(flow_var = "nope", ecology_var = "LIFE_OE"))$status, "error"))

# --- 4. Too few complete rows -> friendly error (boundary) ------------------
tiny <- data.frame(Q95 = c(1, 2), LIFE_OE = c(2, 4))
stopifnot(identical(run_model(tiny, list(flow_var = "Q95", ecology_var = "LIFE_OE"))$status, "error"))

# --- 5. Unsupported model type -> friendly error ----------------------------
bad_type <- run_model(joined, list(flow_var = "Q95", ecology_var = "LIFE_OE", model_type = "randomforest"))
stopifnot(identical(bad_type$status, "error"))
stopifnot(grepl("not supported", bad_type$messages))

# --- 6. Result always has the expected shape --------------------------------
for (r in list(ok, bad_type)) {
  stopifnot(all(c("status", "messages", "plot", "summary") %in% names(r)))
}

cat("test_model_interface_helpers.R: all checks passed\n")
