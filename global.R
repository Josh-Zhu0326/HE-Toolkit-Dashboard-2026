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

plot_hev_dash <- function(data,
                          date_col,
                          flow_stat,
                          biol_metric,
                          multiplot = TRUE,
                          save = FALSE,
                          save_dir = getwd(),
                          clr_by = NULL,
                          show_status = FALSE,
                          river_type = "non_chalk"){
  
  
  if(is.data.frame(data) == FALSE){stop("Data frame 'data' not found")}
  
  if((date_col %in% colnames(data)) == FALSE)
  {stop("Specified date column was not identified in 'data'")}
  
  if(all(unique(flow_stat) %in% colnames(data)) == FALSE)
  {stop("Specified flow statistics were not identified in 'data'")}
  
  if(all(unique(biol_metric) %in% colnames(data)) == FALSE)
  {stop("Specified biology metrics were not identified in 'data'")}
  
  if(is.logical(multiplot) == FALSE) {stop("multiplot is not logical")}
  
  if(is.logical(save) == FALSE) {stop("Save is not logical")}
  
  if(file.exists(save_dir) == FALSE) {stop("Specified save directory does not exist")}
  
  if(length(biol_metric) > 4){stop("More then 4 biology metrics have been selected")}
  
  if(length(flow_stat) > 2){stop("More then 2 flow statistics have been selected")}
  
  if(is.null(clr_by) == FALSE && isTRUE(clr_by %in% names(data)) == FALSE)
  {stop("clr_by variable does not exist in data")}

  river_type <- normalise_hev_river_type(river_type)
  
  # Pull-in data
  
  data$flow_stat_1 <- dplyr::pull(data, flow_stat[1])
  
  if(is.numeric(data$flow_stat_1) == FALSE)
  {stop("Selected flow_stat is non-numeric")}
  
  if(is.na(flow_stat[2]) == FALSE){
    
    data$flow_stat_2 <- dplyr::pull(data, flow_stat[2])
    
    if(is.numeric(data$flow_stat_2) == FALSE)
    {stop("Second flow_stat is non-numeric")}
    
  }
  
  if(is.na(flow_stat[2]) == TRUE){
    
    data$flow_stat_2 <- NA}
  
  data$biol_metric_1 <- dplyr::pull(data, biol_metric[1])
  
  if(is.numeric(data$biol_metric_1) == FALSE)
  {stop("Selected biol_metric is non-numeric")}
  
  if(is.na(biol_metric[2]) == FALSE){
    
    data$biol_metric_2 <- dplyr::pull(data, biol_metric[2])
    
    if(is.numeric(data$biol_metric_2) == FALSE)
    {stop("Second biol_metric is non-numeric")}
    
  }
  
  if(is.na(biol_metric[3]) == FALSE){
    
    data$biol_metric_3 <- dplyr::pull(data, biol_metric[3])
    
    if(is.numeric(data$biol_metric_3) == FALSE)
    {stop("Third biol_metric is non-numeric")}
    
  }
  
  if(is.na(biol_metric[4]) == FALSE){
    
    data$biol_metric_4 <- dplyr::pull(data, biol_metric[4])
    
    if(is.numeric(data$biol_metric_4) == FALSE)
    {stop("Fourth biol_metric is non-numeric")}
    
  }
  
  data$plot_date <- dplyr::pull(data, date_col)
  
  if(is.null(clr_by) == FALSE){
    data$clr_by <- dplyr::pull(data, clr_by)}
  
  # Set-up data transformation
  
  # get y1 range
  
  if(is.na(flow_stat[2]) == FALSE){
    
    y1a_min <- min(data$flow_stat_1, na.rm = TRUE)
    y1b_min <- min(data$flow_stat_2, na.rm = TRUE)
    
    if(isTRUE(y1a_min <= y1b_min) == TRUE){y1_min <- y1a_min}
    else {y1_min <- y1b_min}
    
    y1a_max <- max(data$flow_stat_1, na.rm = TRUE)
    y1b_max <- max(data$flow_stat_2, na.rm = TRUE)
    
    if(isTRUE(y1a_max >= y1b_max) == TRUE){y1_max <- y1a_max}
    else {y1_max <- y1b_max}
    
    y1_range <- y1_max - y1_min
    
  }
  
  if(is.na(flow_stat[2]) == TRUE){
    
    y1_min <- min(data$flow_stat_1, na.rm = TRUE)
    y1_max <- max(data$flow_stat_1, na.rm = TRUE)
    y1_range <- y1_max - y1_min
    
  }
  
  # Get y2 range
  
  y2_min <- min(data$biol_metric_1, na.rm = TRUE)
  y2_max <- max(data$biol_metric_1, na.rm = TRUE)
  y2_range <- y2_max - y2_min
  
  # range ratio
  rangeratio_1 <- y1_range/y2_range
  minadj_1 <- y1_min - y2_min*rangeratio_1
  
  data$y2trans <- data$biol_metric_1 * rangeratio_1 + minadj_1
  
  #Define colours
  #cols <- RColorBrewer::brewer.pal(8, "Dark2")
  
  if(is.na(flow_stat[2]) == FALSE){
    
    # First plot
    
    p1 <- data %>%
      ggplot2::ggplot() +
      geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
      geom_line(data, mapping = aes(x = plot_date, y = flow_stat_2, colour = '#0072B2')) +
      scale_color_identity(name = "Flow Statistics",
                           breaks = c('#56B4E9', '#0072B2'),
                           labels = c(flow_stat[1], flow_stat[2]),
                           guide = "legend") +
      ggnewscale::new_scale_color() +
      geom_point(data, mapping = aes(x = plot_date, y = y2trans, colour = clr_by)) +
      scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_1)/rangeratio_1,
                                                            name = biol_metric[1])) +
      labs(x = date_col, y = "") +
      scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
      #ggtitle(biol_metric[1]) +
      theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                      hjust = 0.5),
            legend.title = element_blank(),
            legend.text = element_text(size = 10),
            axis.text.x = element_text(size = 10),
            axis.text.y = element_text(size = 10),
            axis.title.x = element_text(size = 12),
            axis.title.y.left = element_text(size = 12),
            axis.title.y.right = element_text(size = 12))

    if (isTRUE(show_status)) {
      p1 <- add_hev_status_layers(p1, biol_metric[1], rangeratio_1, minadj_1, y2_min, y2_max, river_type)
    }
    
    if(is.na(biol_metric[2]) == FALSE){
      
      # Get y3 range
      
      y3_min <- min(data$biol_metric_2, na.rm = TRUE)
      y3_max <- max(data$biol_metric_2, na.rm = TRUE)
      y3_range <- y3_max - y3_min
      
      # range ratio
      rangeratio_2 <- y1_range/y3_range
      minadj_2 <- y1_min - y3_min*rangeratio_2
      
      data$y3trans <- data$biol_metric_2 * rangeratio_2 + minadj_2
      
      p2 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_2, colour = '#0072B2')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9', '#0072B2'),
                             labels = c(flow_stat[1], flow_stat[2]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y3trans, colour = clr_by)) +
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_2)/rangeratio_2, name = biol_metric[2])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[2]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p2 <- add_hev_status_layers(p2, biol_metric[2], rangeratio_2, minadj_2, y3_min, y3_max, river_type)
      }
      
    }
    
    if(is.na(biol_metric[3]) == FALSE){
      
      # Get y4 range
      
      y4_min <- min(data$biol_metric_3, na.rm = TRUE)
      y4_max <- max(data$biol_metric_3, na.rm = TRUE)
      y4_range <- y4_max - y4_min
      
      # range ratio
      rangeratio_3 <- y1_range/y4_range
      minadj_3 <- y1_min - y4_min*rangeratio_3
      
      data$y4trans <- data$biol_metric_3 * rangeratio_3 + minadj_3
      
      
      p3 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_2, colour = '#0072B2')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9', '#0072B2'),
                             labels = c(flow_stat[1], flow_stat[2]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y4trans, colour = clr_by)) +
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_3)/rangeratio_3, name = biol_metric[3])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[3]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p3 <- add_hev_status_layers(p3, biol_metric[3], rangeratio_3, minadj_3, y4_min, y4_max, river_type)
      }
      
    }
    
    if(is.na(biol_metric[4]) == FALSE){
      
      # Get y5 range
      
      y5_min <- min(data$biol_metric_4, na.rm = TRUE)
      y5_max <- max(data$biol_metric_4, na.rm = TRUE)
      y5_range <- y5_max - y5_min
      
      # range ratio
      rangeratio_4 <- y1_range/y5_range
      minadj_4 <- y1_min - y5_min*rangeratio_4
      
      data$y5trans <- data$biol_metric_4 * rangeratio_4 + minadj_4
      
      p4 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_2, colour = '#0072B2')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9', '#0072B2'),
                             labels = c(flow_stat[1], flow_stat[2]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y5trans, colour = clr_by)) +
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_3)/rangeratio_3, name = biol_metric[4])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[3]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p4 <- add_hev_status_layers(p4, biol_metric[4], rangeratio_4, minadj_4, y5_min, y5_max, river_type)
      }
      
    }
    
  }
  
  if(is.na(flow_stat[2]) == TRUE){
    
    
    # First plot
    
    p1 <- data %>%
      ggplot2::ggplot() +
      geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
      scale_color_identity(name = "Flow Statistics",
                           breaks = c('#56B4E9'),
                           labels = c(flow_stat[1]),
                           guide = "legend") +
      ggnewscale::new_scale_color() +
      geom_point(data, mapping = aes(x = plot_date, y = y2trans, colour = clr_by)) +
      scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_1)/rangeratio_1,
                                                            name = biol_metric[1])) +
      labs(x = date_col, y = "") +
      scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
      #ggtitle(biol_metric[1]) +
      theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                      hjust = 0.5),
            legend.title = element_blank(),
            legend.text = element_text(size = 10),
            axis.text.x = element_text(size = 10),
            axis.text.y = element_text(size = 10),
            axis.title.x = element_text(size = 12),
            axis.title.y.left = element_text(size = 12),
            axis.title.y.right = element_text(size = 12))

    if (isTRUE(show_status)) {
      p1 <- add_hev_status_layers(p1, biol_metric[1], rangeratio_1, minadj_1, y2_min, y2_max, river_type)
    }
    
    if(is.na(biol_metric[2]) == FALSE){
      
      # Get y3 range
      
      y3_min <- min(data$biol_metric_2, na.rm = TRUE)
      y3_max <- max(data$biol_metric_2, na.rm = TRUE)
      y3_range <- y3_max - y3_min
      
      # range ratio
      rangeratio_2 <- y1_range/y3_range
      minadj_2 <- y1_min - y3_min*rangeratio_2
      
      data$y3trans <- data$biol_metric_2 * rangeratio_2 + minadj_2
      
      p2 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9'),
                             labels = c(flow_stat[1]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y3trans, colour = clr_by)) +
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_2)/rangeratio_2, name = biol_metric[2])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[2]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p2 <- add_hev_status_layers(p2, biol_metric[2], rangeratio_2, minadj_2, y3_min, y3_max, river_type)
      }
      
    }
    
    if(is.na(biol_metric[3]) == FALSE){
      
      # Get y4 range
      
      y4_min <- min(data$biol_metric_3, na.rm = TRUE)
      y4_max <- max(data$biol_metric_3, na.rm = TRUE)
      y4_range <- y4_max - y4_min
      
      # range ratio
      rangeratio_3 <- y1_range/y4_range
      minadj_3 <- y1_min - y4_min*rangeratio_3
      
      data$y4trans <- data$biol_metric_3 * rangeratio_3 + minadj_3
      
      
      p3 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9'),
                             labels = c(flow_stat[1]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y4trans, colour = clr_by)) +
        
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_3)/rangeratio_3, name = biol_metric[3])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[3]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p3 <- add_hev_status_layers(p3, biol_metric[3], rangeratio_3, minadj_3, y4_min, y4_max, river_type)
      }
      
    }
    
    if(is.na(biol_metric[4]) == FALSE){
      
      # Get y5 range
      
      y5_min <- min(data$biol_metric_4, na.rm = TRUE)
      y5_max <- max(data$biol_metric_4, na.rm = TRUE)
      y5_range <- y5_max - y5_min
      
      # range ratio
      rangeratio_4 <- y1_range/y5_range
      minadj_4 <- y1_min - y5_min*rangeratio_4
      
      data$y5trans <- data$biol_metric_4 * rangeratio_4 + minadj_4
      
      p4 <- data %>%
        ggplot2::ggplot() +
        geom_line(data, mapping = aes(x = plot_date, y = flow_stat_1, colour = '#56B4E9')) +
        scale_color_identity(name = "Flow Statistics",
                             breaks = c('#56B4E9'),
                             labels = c(flow_stat[1]),
                             guide = "legend") +
        ggnewscale::new_scale_color() +
        geom_point(data, mapping = aes(x = plot_date, y = y5trans, colour = clr_by)) +
        scale_y_continuous(name = "Flow", sec.axis = sec_axis(~ (. - minadj_3)/rangeratio_3, name = biol_metric[4])) +
        labs(x = date_col, y = "") +
        scale_color_discrete(breaks = ~ .x[!is.na(.x)]) +
        #ggtitle(biol_metric[3]) +
        theme(plot.title = element_text(color = "black", size = 10, face = "bold",
                                        hjust = 0.5),
              legend.title = element_blank(),
              legend.text = element_text(size = 10),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(size = 12),
              axis.title.y.left = element_text(size = 12),
              axis.title.y.right = element_text(size = 12))

      if (isTRUE(show_status)) {
        p4 <- add_hev_status_layers(p4, biol_metric[4], rangeratio_4, minadj_4, y5_min, y5_max, river_type)
      }
    }
    
  }
  
  if(length(biol_metric) == 1){
    
    print(p1)
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", biol_metric[1], "_Plot.png"), plot = p1)}
    
    hevPlot <- p1
    
    return(hevPlot)
    
  }
  
  if(length(biol_metric) == 2 && multiplot == FALSE){
    
    print(p1)
    print(p2)
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", biol_metric[1], "_Plot.png"), plot = p1)
      ggsave(paste0(save_dir, sep = "/", biol_metric[2], "_Plot.png"), plot = p2)}
    
    hevPlot <- list(p1, p2)
    return(hevPlot)
    
  }
  
  if(length(biol_metric) == 2 && multiplot == TRUE){
    
    plot_a <- ggpubr::ggarrange(p1, p2, ncol = 2, common.legend = TRUE, legend = "bottom")
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", "Multi_Plot.png"), plot = plot_a)}
    
    return(plot_a)
    
  }
  
  
  if(length(biol_metric) == 3 && multiplot == FALSE){
    
    print(p1)
    print(p2)
    print(p3)
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", biol_metric[1], "_Plot.png"), plot = p1)
      ggsave(paste0(save_dir, sep = "/", biol_metric[2], "_Plot.png"), plot = p2)
      ggsave(paste0(save_dir, sep = "/", biol_metric[3], "_Plot.png"), plot = p3)}
    
    hevPlot <- list(p1, p2, p3)
    return(hevPlot)
    
  }
  
  if(length(biol_metric) == 3 && multiplot == TRUE){
    
    plot_a <- ggpubr::ggarrange(p1, p2, p3, ncol = 2, nrow = 2, common.legend = TRUE, legend = "bottom")
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", "Multi_Plot.png"), plot = plot_a)}
    
    return(plot_a)
    
  }
  
  if(length(biol_metric) == 4 && multiplot == FALSE){
    
    print(p1)
    print(p2)
    print(p3)
    print(p4)
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", biol_metric[1], "_Plot.png"), plot = p1)
      ggsave(paste0(save_dir, sep = "/", biol_metric[2], "_Plot.png"), plot = p2)
      ggsave(paste0(save_dir, sep = "/", biol_metric[3], "_Plot.png"), plot = p3)
      ggsave(paste0(save_dir, sep = "/", biol_metric[4], "_Plot.png"), plot = p4)}
    
    hevPlot <- list(p1, p2, p3, p4)
    return(hevPlot)
    
  }
  
  if(length(biol_metric) == 4 && multiplot == TRUE){
    
    plot_a <- ggpubr::ggarrange(p1, p2, p3, p4, ncol = 2, nrow = 2, common.legend = TRUE, legend = "bottom")
    
    if(save == TRUE){
      ggsave(paste0(save_dir, sep = "/", "Multi_Plot.png"), plot = plot_a)}
    
    return(plot_a)
    
  }
  
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
