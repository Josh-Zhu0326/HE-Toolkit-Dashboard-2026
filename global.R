# This is a supporting/pre-processing file that will run before the dashboard starts 

# Load packages ----

## Shiny stuff ----
library(shiny)
library(bslib)
library(rsconnect)
library(shinybusy)
library(shinyWidgets)
library(shinyalert)
library(fontawesome)

## Tidyverse ----
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(sjmisc)
library(naniar)

## Tables ----
library(DT)
library(data.table)
library(kableExtra)

## Plotting ----
library(ggplot2)
library(gridExtra)
library(GGally)
library(leaflet)

## HE ----
library(hetoolkit)
library(rnrfa)
library(lme4)
library(performance)

options(sass.cache = FALSE)

addResourcePath("prefix", "www")
source(file.path("R", "user_message_safety_helpers.R"))
source(file.path("R", "file_operation_helpers.R"))
source(file.path("R", "csv_input_helpers.R"))
source(file.path("R", "local_csv_contract_helpers.R"))
source(file.path("R", "local_csv_checkpoint_helpers.R"))
source(file.path("R", "source_conflict_helpers.R"))
source(file.path("R", "external_import_recovery_helpers.R"))
source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "site_map_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))
source(file.path("R", "plot_recovery_helpers.R"))
source(file.path("R", "wq_contract_helpers.R"))
source(file.path("R", "hev_dependency_helpers.R"))
source(file.path("R", "dashboard_backlog_helpers.R"))
# Keep this order: workflow config/state define the contract, workspace modules
# consume it, then the UI renders it.
source(file.path("R", "workflow_config.R"))
source(file.path("R", "workflow_state.R"))
source(file.path("R", "workspace_state.R"))
source(file.path("R", "workspace_auth.R"))
source(file.path("R", "workspace_storage.R"))
source(file.path("R", "processed_dataset_checkpoint.R"))
source(file.path("R", "workflow_ui.R"))
source(file.path("R", "filtering_helpers.R"))
source(file.path("R", "duplicate_choice_helpers.R"))
source(file.path("R", "workbook_validation_helpers.R"))
source(file.path("R", "exclusion_log_helpers.R"))
source(file.path("R", "model_interface_helpers.R"))
source(file.path("R", "analysis_filter_helpers.R"))
source(file.path("R", "joined_dataset_boundary_helpers.R"))
source(file.path("R", "analysis_model_helpers.R"))
source(file.path("R", "mixed_model_helpers.R"))
source(file.path("R", "hev_output_helpers.R"))
source(file.path("R", "hev_threshold_helpers.R"))

# runApp(launch.browser=TRUE)
# rsconnect::writeManifest()

# Dashboard functions ----
## Overwrite plot_sitepca function ----

plot_sitepca_dash <- function(data = NULL,
                        vars = NULL,
                        eigenvectors = FALSE,
                        label_by = NULL,
                        colour_by  = NULL,
                        plotly = FALSE,
                        save = FALSE,
                        save_dir = getwd(),
                        ...){
  
  # Errors:
  # make sure the right data had been input:
  if(is.null(data)) {stop("data missing, with no default")}
  if(!is.data.frame(data)) {stop("data input must be a dataframe")}
  
  # vars is not specified, missing from data, invalid format
  if(is.null(vars)) {stop("vars is missing, please specify")}
  if(is.character(vars)==FALSE) {stop("vars must be vector of character strings")}
  if(anyNA(vars)) {stop("vars contains NAs, not valid in list of vars")}
  if(length(vars %in% colnames(data))!=length(vars)) {stop("missmatch between vars names and names in input dataframe")}
  
  # label_by
  if(!is.null(label_by) && is.character(label_by)==FALSE) {stop("label_by must be character string")}
  if(!is.null(label_by) && length(label_by)>1) {stop("use only one variable as a label name")}
  if(!is.null(label_by) && !label_by %in% colnames(data)) {stop("missmatch between label_by name and names in input dataframe")}
  
  # colour_by
  if(!is.null(colour_by) && is.character(colour_by)==FALSE) {stop("colour_by must be character string or vector of character strings")}
  if(!is.null(colour_by) && length(colour_by %in% colnames(data))!=length(colour_by)) {stop("missmatch between colour_by names and names in input dataframe")}
  
  # check logical value for logical inputs
  if(is.logical(eigenvectors)==FALSE) {stop("eigenvectors must be a logical statement")}
  if(is.logical(plotly)==FALSE) {stop("plotly must be a logical statement")}
  
  # Check save settings are valid
  if(file.exists(save_dir) == FALSE) {stop("Specified save directory does not exist")}
  if(is.logical(save) == FALSE) {stop("Save is not logical")}
  
  # Format input data
  data <- as_tibble(data)
  
  # want to keep label_by and colour_by for site ID and water body for labels and groupings (--> z and colours in ggplot)...
  data <- subset(data, select = c(vars, label_by, colour_by))
  
  # Drop sites with NA for one or more variables
  if(nrow(data[!complete.cases(data), ])>0){
    warning(paste(nrow(data[!complete.cases(data), ]),"sites omitted due to incomplete data"))
  }
  data <- data[complete.cases(data), ]
  
  # Run PCA (dropping column with site ID)
  sitepca <- prcomp(data %>% dplyr::select(dplyr::all_of(vars)), center = TRUE, scale. = TRUE)
  
  # set label_id to rownames of sitepca output to use in plotting
  if(!is.null(label_by)){
    temp <- tibble::column_to_rownames(data, var = label_by)
    row.names(sitepca$x) <- row.names(temp)
  }
  
  pc_variance <- round(100 * (sitepca$sdev^2 / sum(sitepca$sdev^2)), 2)
  cbbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

  if(!is.null(label_by)){
    scores <- as.data.frame(sitepca$x[, c("PC1", "PC2"), drop = FALSE])
    scores$.label <- row.names(sitepca$x)
    if(!is.null(colour_by)){
      data <- data %>% dplyr::mutate_at(colour_by, as.character)
      scores$.colour <- data[[colour_by]]
    }

    p <- ggplot2::ggplot(scores, ggplot2::aes(x = PC1, y = PC2)) +
      ggplot2::geom_point(
        ggplot2::aes(colour = if(!is.null(colour_by)) .colour else NULL),
        size = 2.5,
        alpha = 0.85
      ) +
      ggplot2::labs(
        x = paste0("PC1 (", pc_variance[[1]], "%)"),
        y = paste0("PC2 (", pc_variance[[2]], "%)")
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(axis.text = element_text(size = 12), axis.title = element_text(size = 12))

    if (requireNamespace("ggrepel", quietly = TRUE)) {
      p <- p +
        ggrepel::geom_text_repel(
          ggplot2::aes(label = .label, colour = if(!is.null(colour_by)) .colour else NULL),
          size = 3.2,
          max.overlaps = Inf,
          min.segment.length = 0,
          box.padding = 0.35,
          point.padding = 0.25,
          show.legend = FALSE
        )
    } else {
      p <- p +
        ggplot2::geom_text(
          ggplot2::aes(label = .label, colour = if(!is.null(colour_by)) .colour else NULL),
          size = 3.2,
          check_overlap = TRUE,
          vjust = -0.6,
          show.legend = FALSE
        )
    }

    if(eigenvectors==TRUE){
      loadings <- as.data.frame(sitepca$rotation[, c("PC1", "PC2"), drop = FALSE])
      loadings$.label <- row.names(loadings)
      scale_factor <- min(diff(range(scores$PC1)), diff(range(scores$PC2))) * 0.35
      loadings$PC1 <- loadings$PC1 * scale_factor
      loadings$PC2 <- loadings$PC2 * scale_factor
      p <- p +
        ggplot2::geom_segment(
          data = loadings,
          ggplot2::aes(x = 0, y = 0, xend = PC1, yend = PC2),
          arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm")),
          inherit.aes = FALSE,
          colour = "black"
        )
      if (requireNamespace("ggrepel", quietly = TRUE)) {
        p <- p +
          ggrepel::geom_text_repel(
            data = loadings,
            ggplot2::aes(x = PC1, y = PC2, label = .label),
            inherit.aes = FALSE,
            size = 3,
            colour = "black"
          )
      } else {
        p <- p +
          ggplot2::geom_text(
            data = loadings,
            ggplot2::aes(x = PC1, y = PC2, label = .label),
            inherit.aes = FALSE,
            size = 3,
            colour = "black",
            check_overlap = TRUE
          )
      }
    }

    if(!is.null(colour_by)){
      p <- p +
        ggplot2::labs(colour = stringr::str_to_title(sub("_", " ", colour_by))) +
        ggplot2::scale_colour_manual(values = cbbPalette) +
        ggplot2::theme(
          legend.key = element_rect(fill = NA, color = NA),
          legend.position = "bottom",
          legend.direction = "horizontal",
          legend.margin = margin(0, 0, 0, 0),
          legend.box.margin = margin(-5, -5, 0, -5)
        )
    }
  } else {
    shape = 19
    loadings = FALSE; loadings.label = FALSE; loadings.label.size = NULL; loadings.colour = NULL; loadings.label.colour = NULL
    loadings.label.vjust <- NULL

    if(eigenvectors==TRUE) {loadings = TRUE; loadings.label = TRUE; loadings.label.size = 5; loadings.colour = 'blue'; loadings.label.colour = "blue";loadings.label.vjust= 1.5}

    p <- ggplot2::autoplot(sitepca, shape = shape, loadings = loadings, loadings.label = loadings.label,
                           loadings.label.size = loadings.label.size, loadings.colour = loadings.colour, loadings.label.colour = loadings.label.colour,
                           loadings.label.vjust = loadings.label.vjust) +
                           theme(axis.text = element_text(size = 14), axis.title = element_text(size=15))

    if(!is.null(colour_by)){
      data<-data %>% dplyr::mutate_at(colour_by, as.character)
      loadings.colour = "black"; loadings.label.colour = "black"
      p <- ggplot2::autoplot(sitepca, data=data, shape = shape, loadings = loadings, loadings.label = loadings.label, loadings.label.size = loadings.label.size, loadings.colour = loadings.colour, loadings.label.colour = loadings.label.colour, colour = colour_by) +
        labs(colour = stringr::str_to_title(sub("_"," ",colour_by))) +
        theme(legend.key = element_rect(fill = NA, color = NA),
              axis.text = element_text(size = 12),
              axis.title = element_text(size = 12),
              legend.position = "bottom",
              legend.direction = "horizontal",
              legend.margin=margin(0,0,0,0),
              legend.box.margin=margin(-10,-10,0,-10)) +
        scale_colour_manual(values=cbbPalette)
    }
  }
  
  # p <- p + ggplot2::ggtitle("Bi-plot of principal components 1 and 2")
  
  # save plot
  if(save == TRUE){
    ggplot2::ggsave(plot = p, path = save_dir, filename = paste("PCA_plot.png", sep = "."))
  }
  
  # convert ggplot to plotly
  if (isTRUE(plotly)){
    p <- p + ggplot2::theme(legend.position = "right", legend.direction = "vertical")
    p <- plotly::ggplotly(p)
  }
  
  return(p)
  
}



## Overwrite plot_heatmap function ----

plot_heatmap_dash <- function(data,
                         x,
                         y,
                         fill,
                         colour = "viridis",
                         lab.x = x,
                         lab.y = y,
                         lab.legend = fill,
                         limits = FALSE,
                         dual = FALSE,
                         list_out = TRUE,
                         save = FALSE,
                         save_dir = getwd(),
                         ...){
  
  # Errors:
  # make sure the right data had been input:
  if(is.null(data)) {stop("data missing, with no default")}
  if(!is.data.frame(data)) {stop("data input must be a dataframe")}
  
  # x is not specified, missing from data, invalid format, or contains NAs
  if(is.null(x)) {stop("x is missing, please specify")}
  if(x %in% colnames(data) == FALSE) {stop("x cannot be found in input dataframe")}
  
  # y is not specified, missing from data or invalid format
  if(is.null(y)) {stop("y is missing, please specify")}
  if(y %in% colnames(data) == FALSE) {stop("y cannot be found in input dataframe")}
  
  # fill is not specified or missing from data
  if(is.null(fill)) {stop("fill is missing, please specify")}
  if(fill %in% colnames(data) == FALSE) {stop("fill cannot be found in input dataframe")}
  
  # colour is not valid colour scheme
  if(colour %in% c("magma" ,"A", "inferno","B", "plasma", "C", "viridis","D", "cividis","E") == FALSE) {stop("colour input not valid colour scheme")}
  
  # check logical values provided for logical imput settings
  if(is.logical(limits)==FALSE) {stop("logical value of limits variable must be provided")}
  if(is.logical(list_out)==FALSE) {stop("logical value of list_out variable must be provided")}
  if(is.logical(dual)==FALSE) {stop("logical value of dual variable must be provided")}
  
  # check save settings are valid
  if(file.exists(save_dir) == FALSE) {stop("Specified save directory does not exist")}
  if(is.logical(save) == FALSE) {stop("Save is not logical")}
  
  
  # format input data
  data <- tibble::as_tibble(data)
  data <- data %>% dplyr::rename(x = all_of(x),y = all_of(y), fill = all_of(fill))
  data <- subset(data, select = c(x, y, fill))
  
  # error if NAs in x or y
  if(anyNA(data$x)) {stop("x contains NAs, NAs not a valid value of x")}
  if(anyNA(data$y)) {stop("y contains NAs, NAs not a valid value of y")}
  
  # order the data
  data <- data[order(data$x),]
  
  # replace any empty character strings ("") in the dataset with an NA
  #data <- data %>% dplyr::mutate_all(list(~dplyr::na_if(.,"")))
  data <- data %>% dplyr::mutate_if(is.character, list(~dplyr::na_if(.,"")))
  
  
  # limit size of the data set if limits = TRUE
  if(limits == TRUE) {
    data <- subset(data, x %in% unique(data$x)[1:30] & y %in% unique(data$y)[1:20])
    warning("limits set to TRUE, dataset being trimmed to a maximum of the first 30 unique x values and first 20 unique y values, no effect if less than 30 x and 20 y occur within the dataset. If trimming is not wanted set 'limits' = FALSE")
  }
  
  # for plotting breaks - convert x into a factor if more than 10 unique values
  if (length(unique(data$x)) > 10) {data$x <- as.factor(data$x)}
  
  # plot heatmap
  if(length(unique(data$fill))<3) {data$fill<- as.character(data$fill)} # handle as discrete variable, particularly relevant for presence/absence data recorded as 0 or 1
  
  p <- ggplot2::ggplot(data, aes(x=x, y=y, fill=fill)) +
    geom_tile() +
    scale_x_discrete(breaks=levels(data$x)[seq(1, nlevels(data$x), length.out = 5)]) +
    theme(legend.margin=margin(0,0,0,0), legend.box.margin=margin(-10,0,-10,-10), axis.text = element_text(size = 14), axis.title = element_text(size = 14),
          legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +  
    labs(title = NULL, subtitle = NULL, x = stringr::str_to_title(lab.x), y = stringr::str_to_title(lab.y), fill = stringr::str_to_title(lab.legend))
  
  if(typeof(data$fill)=="double") {
    p <- p + viridis::scale_fill_viridis(option = colour, na.value="white")
  } else {
    p <- p + viridis::scale_fill_viridis(option = colour, discrete = TRUE, na.value="white")
  }
  
  out <- list()
  out[[1]] <- p
  
  # create data tables
  if(list_out == TRUE || dual==TRUE) {
    #  options(dplyr.summarise.inform=F)
    out[[2]] <- data %>%
      dplyr::group_by(x) %>%
      dplyr::summarise(across(.cols= "fill", list(missing = ~length(which(is.na(fill))), total = ~length(fill), prop_missing = ~length(which(is.na(fill)))/length(fill)), .names = "{.fn}"))
    
    out[[3]] <- data %>%
      dplyr::group_by(y) %>%
      dplyr::summarise(across(.cols= "fill", list(missing = ~length(which(is.na(fill))), total = ~length(fill), prop_missing = ~length(which(is.na(fill)))/length(fill)), .names = "{.fn}"))
    
    miss <- data %>%
      dplyr::group_by(y) %>%
      miss_var_run( var = fill) %>%
      group_by(y,is_na) %>%
      dplyr::summarise(number_of_gaps = n(), smallest_gap = min(run_length), biggest_gap = max(run_length))
    
    out[[3]] <- dplyr::left_join(out[[3]],subset(miss, is_na=="missing", select = c(y,number_of_gaps, smallest_gap, biggest_gap)), by = "y")
    
    rm(miss)
    
    #  options(dplyr.summarise.inform=T)
  }
  
  # add the histogram of missingness to the heatmap
  if(dual == TRUE) {
    right.plot <- ggplot2::ggplot(out[[3]], aes(x=y,y=prop_missing)) +
      geom_bar(stat="identity") +
      scale_x_discrete(labels=NULL) +
      labs(x = NULL, y = "Proportion missing") +
      coord_flip()
    
    legend <- g_legend(p + theme(legend.position = "bottom"))
    
    lay <- rbind(c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(1,1,1,2),
                 c(3,3,3,3))
    
    p <- gridExtra::grid.arrange(p + theme(legend.position = 'none'), right.plot, legend, layout_matrix = lay)
    out[[1]] <- p
  }
  
  if(save == TRUE) {
    ggplot2::ggsave(plot = p, path = save_dir, filename = paste(paste("heatmap_plot",x,y,fill,sep="_"),"png", sep = "."))
  }
  
  # remove the data tables if made for dual plot but not wanted
  if(list_out == FALSE) out <- out[[1]]
  
  return(out)
  
}


## helper functions

g_legend <- function(a_gplot){
  tmp <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(a_gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  legend
}



## Overwrite plot_hev function ----

hev_axis_transform <- function(flow_values, biology_values) {
  if (!is.numeric(flow_values) || !is.numeric(biology_values)) {
    stop("Flow and biology values must be numeric.", call. = FALSE)
  }

  finite_flow <- flow_values[is.finite(flow_values)]
  finite_biology <- biology_values[is.finite(biology_values)]
  if (length(finite_flow) == 0L || length(finite_biology) == 0L) {
    stop("Flow and biology values must contain finite observations.", call. = FALSE)
  }

  flow_range <- range(finite_flow)
  biology_range <- range(finite_biology)
  flow_width <- diff(flow_range)
  biology_width <- diff(biology_range)
  if (!is.finite(flow_width) || flow_width <= 0) {
    stop("Selected Flow values must contain more than one distinct finite value.", call. = FALSE)
  }
  if (!is.finite(biology_width) || biology_width <= 0) {
    stop("The selected biology metric must contain more than one distinct finite value.", call. = FALSE)
  }

  ratio <- unname(flow_width / biology_width)
  offset <- unname(flow_range[[1L]] - biology_range[[1L]] * ratio)

  list(
    flow_range = unname(flow_range),
    biology_range = unname(biology_range),
    ratio = ratio,
    offset = offset,
    forward = function(value) value * ratio + offset,
    inverse = function(value) (value - offset) / ratio
  )
}

hev_metric_plot_theme <- function() {
  ggplot2::theme(
    plot.title = ggplot2::element_text(
      color = "black",
      size = 10,
      face = "bold",
      hjust = 0.5
    ),
    legend.title = ggplot2::element_blank(),
    legend.text = ggplot2::element_text(size = 10),
    axis.text.x = ggplot2::element_text(size = 10),
    axis.text.y = ggplot2::element_text(size = 10),
    axis.title.x = ggplot2::element_text(size = 12),
    axis.title.y.left = ggplot2::element_text(size = 12),
    axis.title.y.right = ggplot2::element_text(size = 12)
  )
}

build_hev_metric_plot <- function(data,
                                  date_col,
                                  flow_metrics,
                                  biology_metric,
                                  colour_col = NULL,
                                  show_status = FALSE,
                                  river_type = "non_chalk") {
  required_columns <- unique(c(date_col, flow_metrics, biology_metric, colour_col))
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "HEV plot data are missing required column(s): %s.",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (!all(vapply(data[flow_metrics], is.numeric, logical(1)))) {
    stop("Selected Flow statistics must be numeric.", call. = FALSE)
  }
  if (!is.numeric(data[[biology_metric]])) {
    stop("The selected biology metric must be numeric.", call. = FALSE)
  }

  axis_transform <- hev_axis_transform(
    unlist(data[flow_metrics], use.names = FALSE),
    data[[biology_metric]]
  )

  flow_data <- tidyr::pivot_longer(
    data[, unique(c(date_col, flow_metrics)), drop = FALSE],
    cols = dplyr::all_of(flow_metrics),
    names_to = ".flow_metric",
    values_to = ".flow_value"
  )
  flow_data$.flow_metric <- factor(
    flow_data$.flow_metric,
    levels = flow_metrics
  )

  metric_data <- data
  metric_data$.biology_scaled <- axis_transform$forward(
    metric_data[[biology_metric]]
  )
  flow_colours <- stats::setNames(
    c("#56B4E9", "#0072B2")[seq_along(flow_metrics)],
    flow_metrics
  )

  plot <- ggplot2::ggplot(
    flow_data,
    ggplot2::aes(
      x = .data[[date_col]],
      y = .flow_value,
      colour = .flow_metric,
      group = .flow_metric
    )
  ) +
    ggplot2::geom_line() +
    ggplot2::scale_colour_manual(
      name = "Flow Statistics",
      values = flow_colours,
      breaks = flow_metrics,
      labels = flow_metrics,
      guide = "legend"
    ) +
    ggnewscale::new_scale_colour()

  point_mapping <- if (is.null(colour_col)) {
    ggplot2::aes(
      x = .data[[date_col]],
      y = .biology_scaled
    )
  } else {
    ggplot2::aes(
      x = .data[[date_col]],
      y = .biology_scaled,
      colour = .data[[colour_col]]
    )
  }
  plot <- plot +
    ggplot2::geom_point(
      data = metric_data,
      mapping = point_mapping,
      inherit.aes = FALSE
    ) +
    ggplot2::scale_y_continuous(
      name = "Flow",
      sec.axis = ggplot2::sec_axis(
        transform = axis_transform$inverse,
        name = biology_metric
      )
    ) +
    ggplot2::labs(x = date_col, y = "") +
    hev_metric_plot_theme()

  if (!is.null(colour_col)) {
    plot <- plot +
      ggplot2::scale_colour_discrete(
        breaks = function(values) values[!is.na(values)]
      )
  }

  if (isTRUE(show_status)) {
    plot <- add_hev_status_layers(
      plot,
      biology_metric,
      axis_transform$ratio,
      axis_transform$offset,
      axis_transform$biology_range[[1L]],
      axis_transform$biology_range[[2L]],
      river_type
    )
  }

  plot
}

plot_hev_dash <- function(data,
                          date_col,
                          flow_stat,
                          biol_metric,
                          multiplot = TRUE,
                          save = FALSE,
                          save_dir = getwd(),
                          clr_by = NULL,
                          show_status = FALSE,
                          river_type = "non_chalk") {
  if (!is.data.frame(data)) {
    stop("Data frame 'data' not found.", call. = FALSE)
  }
  if (!is.character(date_col) || length(date_col) != 1L ||
      is.na(date_col) || !nzchar(date_col) || !date_col %in% names(data)) {
    stop("Specified date column was not identified in 'data'.", call. = FALSE)
  }
  if (!is.logical(multiplot) || length(multiplot) != 1L || is.na(multiplot)) {
    stop("multiplot must be one logical value.", call. = FALSE)
  }
  if (!is.logical(save) || length(save) != 1L || is.na(save)) {
    stop("save must be one logical value.", call. = FALSE)
  }
  if (!is.character(save_dir) || length(save_dir) != 1L ||
      is.na(save_dir) || !dir.exists(save_dir)) {
    stop("Specified save directory does not exist.", call. = FALSE)
  }

  flow_stat <- normalise_hev_metric_selection(flow_stat)
  biol_metric <- normalise_hev_metric_selection(biol_metric)
  if (length(flow_stat) == 0L || length(flow_stat) > 2L) {
    stop("Select one or two Flow statistics.", call. = FALSE)
  }
  if (length(biol_metric) == 0L || length(biol_metric) > 4L) {
    stop("Select between one and four biology metrics.", call. = FALSE)
  }

  missing_flow <- setdiff(flow_stat, names(data))
  if (length(missing_flow) > 0L) {
    stop("Specified Flow statistics were not identified in 'data'.", call. = FALSE)
  }
  missing_biology <- setdiff(biol_metric, names(data))
  if (length(missing_biology) > 0L) {
    stop("Specified biology metrics were not identified in 'data'.", call. = FALSE)
  }
  if (!is.null(clr_by) &&
      (!is.character(clr_by) || length(clr_by) != 1L ||
       is.na(clr_by) || !nzchar(clr_by) || !clr_by %in% names(data))) {
    stop("clr_by variable does not exist in data.", call. = FALSE)
  }

  river_type <- normalise_hev_river_type(river_type)
  plots <- stats::setNames(
    lapply(biol_metric, function(metric) {
      build_hev_metric_plot(
        data = data,
        date_col = date_col,
        flow_metrics = flow_stat,
        biology_metric = metric,
        colour_col = clr_by,
        show_status = show_status,
        river_type = river_type
      )
    }),
    biol_metric
  )

  if (length(plots) == 1L) {
    print(plots[[1L]])
    if (isTRUE(save)) {
      ggplot2::ggsave(
        file.path(save_dir, paste0(biol_metric[[1L]], "_Plot.png")),
        plot = plots[[1L]]
      )
    }
    return(plots[[1L]])
  }

  if (!isTRUE(multiplot)) {
    invisible(lapply(plots, print))
    if (isTRUE(save)) {
      Map(
        function(plot, metric) {
          ggplot2::ggsave(
            file.path(save_dir, paste0(metric, "_Plot.png")),
            plot = plot
          )
        },
        plots,
        biol_metric
      )
    }
    return(unname(plots))
  }

  arrange_arguments <- c(
    unname(plots),
    list(
      ncol = 2L,
      common.legend = TRUE,
      legend = "bottom"
    )
  )
  if (length(plots) > 2L) {
    arrange_arguments$nrow <- 2L
  }
  combined_plot <- do.call(ggpubr::ggarrange, arrange_arguments)

  if (isTRUE(save)) {
    ggplot2::ggsave(
      file.path(save_dir, "Multi_Plot.png"),
      plot = combined_plot
    )
  }

  combined_plot
}

## Download functionality for HEV plots ----

downloadButtonUI <- function(id) {
  downloadButton(NS(id, "dl_plot"))
}
downloadSelectUI <- function(id, choices = c("PDF", "JPEG", "PNG")) {
  selectInput(NS(id, "format"), label = "", choices = choices, width = "125px")
}
downloadServer <- function(id, plot,
                           download_data = NULL,
                           can_download = function() TRUE,
                           on_download = function(format, file) NULL,
                           context = "plot",
                           write_plot = function(file, plot) {
                             ggplot2::ggsave(file, plot = plot, width = 10, height = 5)
                           }) {
  moduleServer(id, function(input, output, session) {
    write_download <- function(file, format = input$format) {
      validate(need(isTRUE(can_download()), "Regenerate the current plot before downloading."))
      format <- toupper(format)
      if (identical(format, "CSV")) {
        validate(need(is.function(download_data), "The current data are not available for CSV download."))
        export_data <- download_data()
        validate(need(is.data.frame(export_data), "The current data are not available for CSV download."))
        result <- safe_file_operation(function() {
          utils::write.csv(export_data, file, row.names = FALSE, na = "")
        })
      } else {
        result <- safe_file_operation(function() write_plot(file, plot()))
      }
      if (!identical(result$status, "success")) {
        message(sprintf(
          "RAW-19/21 file-operation diagnostic [%s/%s]: %s",
          context,
          result$failure,
          result$diagnostic
        ))
        showNotification(result$message, type = "error", duration = 10)
        validate(need(FALSE, result$message))
      }
      on_download(format, file)
      invisible(result$value)
    }

    output$dl_plot <- downloadHandler(
      filename = function() {
        file_format <- tolower(input$format)
        paste0(id, ".", file_format)
      },
      content = function(file) {
        write_download(file)
      }
    )

    list(write_download = write_download)
  })
}

# Links ----
## Link to github

link_git <- tags$a(
  shiny::icon("github"), "HE Toolkit GitHub site",
  href = "https://github.com/APEM-LTD/hetoolkit",
  target = "_blank"
)

## Link to toolkit website

link_web <- tags$a(
  shiny::icon("globe"), "HE Toolkit website",
  href = "https://apem-ltd.github.io/hetoolkit/index.html",
  target = "_blank"
)

# Checkpoint ----
cp_card <- function(status, message) {
  icon <- switch(status, pass = "\u2713", warn = "!", fail = "\u00D7")
  div(class = paste("cp-card", status),
      div(class = "cp-icon", icon),
      div(message)
  )
}
