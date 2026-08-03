source("global.R")

set.seed(20260803)

pca_data <- data.frame(
  biol_site_id = sprintf("BIO_SITE_%02d_LONG_LABEL", 1:18),
  ALTITUDE = rnorm(18, 80, 20),
  SLOPE = rnorm(18, 2, 0.5),
  WIDTH = rnorm(18, 6, 1.5),
  DEPTH = rnorm(18, 0.4, 0.1),
  ALKALINITY = rnorm(18, 120, 25),
  DISCHARGE = rnorm(18, 3, 1),
  TEMPERATURE = rnorm(18, 12, 2),
  group = rep(c("North", "South", "Central"), each = 6),
  stringsAsFactors = FALSE
)

pca_plot <- plot_sitepca_dash(
  pca_data,
  vars = c("ALTITUDE", "SLOPE", "WIDTH", "DEPTH", "ALKALINITY", "DISCHARGE", "TEMPERATURE"),
  label_by = "biol_site_id",
  colour_by = "group"
)

stopifnot(inherits(pca_plot, "ggplot"))
stopifnot(grepl("^PC1 \\([0-9.]+%\\)$", pca_plot$labels$x))
stopifnot(grepl("^PC2 \\([0-9.]+%\\)$", pca_plot$labels$y))

geom_classes <- vapply(pca_plot$layers, function(layer) class(layer$geom)[[1]], character(1))
if (requireNamespace("ggrepel", quietly = TRUE)) {
  stopifnot("GeomTextRepel" %in% geom_classes)
} else {
  stopifnot("GeomText" %in% geom_classes)
}

cat("PCA plot layout tests passed\n")
