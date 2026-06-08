# This file contains the server function, allowing user interactions with the dashboard to be executed

function(input, output, session){
  
  # INTRO PAGE ----
  
  output$intro_page <- renderUI({
    tags$iframe(seamless="seamless", 
                src= "prefix/intro_page.html",
                style="border:0; position:relative; top:0; left:0; right:0; bottom:0; width:100%; height:1000px")
  })
  
  # DATA IMPORTING ----
  ## Metadata ----
  ### loading ----
  metadata <- reactive({ 
    
  #### error message for absent metadata ----
    validate(
      need(input$meta_paste != "", "Please add metadata")
    )
    
    if (input$meta_paste != '') {
      metadata <- fread(paste(input$meta_paste, collapse = "\n"), colClasses = "character")
      metadata <-as.data.frame(metadata)
    }
  })
  
  ### displaying ----
  output$table1 <- function() {
    
  #### error messages for incorrect data formats ----
    metadata_req_col_biol <- 'biol_site_id'
    metadata_req_col_flow <- 'flow_site_id'
    metadata_req_col_flow_input <- 'flow_input'
    metadata_req_flow_input_types <- c('HDE', 'NRFA')
    
    metadata_col_names <- colnames(metadata())
    flow_input <- metadata()$flow_input
    
    match <- flow_input %in% metadata_req_flow_input_types
    
    validate(
      need(metadata_req_col_biol %in% metadata_col_names, "You don't have a correctly named list of biology site IDs"),
      need(metadata_req_col_flow %in% metadata_col_names, "You don't have a correctly named list of flow site IDs"),
      need(metadata_req_col_flow_input %in% metadata_col_names, "You don't have a correctly named list of flow inputs"),
      need(!str_contains(match, "FALSE"), "Please ensure all your flow inputs are listed as either 'HDE' or 'NRFA'")
      
    )
    
    metadata() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "250px")
  }
  
  ## Biology data ----
  ### importing ----
  biol_data <- reactive({
    req(input$import_inv)
    
    biol_sites <- as.character(metadata()$biol_site_id)
    
    import_inv(source = "parquet", sites = biol_sites, start_date = input$date_range_biol[1],
               end_date = input$date_range_biol[2])
  })
  
  
  #### warning message for unID'd sites----
  observeEvent(input$import_inv, {
    
    missed_biol_sites <- metadata() %>% filter(!biol_site_id %in% biol_data()$biol_site_id) %>% select(biol_site_id)
    missed_biol_sites_text <- gsub("c\\(|\\)",'', missed_biol_sites)
    
    if(length(missed_biol_sites > 0)) {
      
      shinyalert(paste("Biology data could not be found for site(s)", paste(missed_biol_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  output$biol_table <- function() {
    biol_data() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "500px")
  }
  
  ## Environmental data ----
  ### importing ----
  env_data <- reactive({
    req(input$import_env)
    
    biol_sites <- as.character(metadata()$biol_site_id)
    
    import_env(sites = biol_sites) %>% mutate(across(BOULDERS_COBBLES: SILT_CLAY, ~tidyr::replace_na(.,0)))
  })
  
  #### warning message for unID'd sites----
  observeEvent(input$import_env, {
    
    missed_env_sites <- metadata() %>% filter(!biol_site_id %in% env_data()$biol_site_id) %>% select(biol_site_id)
    missed_env_sites_text <- gsub("c\\(|\\)",'', missed_env_sites)
    
    if(length(missed_env_sites > 0)) {
      
      shinyalert(paste("Environmental base data could not be found for site(s)", paste(missed_env_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  
  showEnvplot <- reactiveVal(TRUE)
  
  observeEvent(input$env_data_display, {
    showEnvplot(!showEnvplot())
  })
  
  output$env_tab_pca <- renderUI({
    if (showEnvplot()){
      plotOutput("env_fig")
    }
    else{
      tableOutput("env_table")
    }
  })
  
  #### render table ----
  output$env_table <- function() {
    env_data() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "500px")
  }
  
  #### render PCA ----
  output$env_fig <- renderPlot({
    plot_sitepca_dash(env_data(), vars = c("ALTITUDE", "SLOPE", "WIDTH", "DEPTH", 
                                           "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SILT_CLAY"), 
                      eigenvectors = TRUE, label_by = "biol_site_id")
  })
  
  
  ## Flow data ----
  ### importing ----
  flow_data <- reactive({
    req(input$import_flow)
    
    flow_sites <- as.character(metadata()$flow_site_id)
    flow_inputs <- as.character(metadata()$flow_input)
    
    import_flow(sites = flow_sites, inputs = flow_inputs, start_date = input$date_range_flow[1],
                end_date = input$date_range_flow[2])
  })
  
  
  #### warning message for unID'd sites----
  observeEvent(input$import_flow, {
    
    missed_flow_sites <- metadata() %>% filter(!flow_site_id %in% flow_data()$flow_site_id) %>% select(flow_site_id)
    missed_flow_sites_text <- gsub("c\\(|\\)",'', missed_flow_sites)
    
    if(length(missed_flow_sites > 0)) {
      
      shinyalert(paste("Flow data could not be found for station(s)", paste(missed_flow_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  
  showHeatmap <- reactiveVal(TRUE)
  
  observeEvent(input$flow_data_display, {
    showHeatmap(!showHeatmap())
  })
  
  output$flow_heatmap <- renderUI({
    if (showHeatmap()){
      plotOutput("flow_fig")
    }
    else{
      tableOutput("flow_table")
    }
  })
  
  #### render table ----
  output$flow_table <- function() {
    plot_heatmap(data = flow_data(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(3) %>%
      kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "300px")
  }
  
  #### render heatmap ----
  output$flow_fig <- renderPlot({
    plot_heatmap_dash(data = flow_data(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(1) %>% grid.arrange() %>% print()
  })
  
  
  ## Map of sites ----
  
  map_data <- reactive({
    req(input$import_env)
    
    temp.eastnorths <- osg_parse(env_data()$NGR_10_FIG, coord_system = "WGS84") %>% as.data.frame()
    
    cbind(env_data(), temp.eastnorths) %>%
      dplyr::select(AGENCY_AREA, WATER_BODY, CATCHMENT, biol_site_id, lat, lon)
    
  })
  
  output$map0 <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      addCircleMarkers(data = map_data(), ~unique(lon), ~unique(lat), 
                       layerId = ~unique(biol_site_id), popup = ~paste(unique(biol_site_id), "<br>", 
                                                                       WATER_BODY))
  })
  
  
  # INVERT DATA PROCESSING ----
  
  ## RICT predictions ----
  ### calculating ----
  predict_data <- reactive({
    req(input$run_rict)
    
    env_data <- env_data()
    
    keeps <- c("biol_site_id", "SEASON", "TL2_WHPT_ASPT_AbW_DistFam", "TL2_WHPT_NTAXA_AbW_DistFam",
               "TL3_LIFE_Fam_DistFam", "TL3_PSI_Fam")
    
    predict_indices(env_data = env_data, file_format = "EDE", all_indices = TRUE) %>% 
      select(keeps) %>% dplyr::rename(Season = SEASON) %>%
      dplyr::mutate(Season = case_when(Season == 1 ~ "Spring", Season == 2 ~ "Summer",
                                       Season == 3 ~ "Autumn"))
    
  })
  
  #### error message for absent env data ----
  env_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(env_data())
    env_data_exist(TRUE)
  })
  
  observeEvent(input$run_rict, {
    
    if(!env_data_exist()) {
      
      shinyalert(title = "Please import environmental base data",
                 type = "error")
    } 
    
  })
  
  #### warning message for incomplete env data ----
  observeEvent(input$run_rict, {
    
    if(sum(is.na(env_data()$ALTITUDE),	
           is.na(env_data()$SLOPE),	
           is.na(env_data()$DISCHARGE),	
           is.na(env_data()$DIST_FROM_SOURCE),
           is.na(env_data()$WIDTH),	
           is.na(env_data()$DEPTH),	
           is.na(env_data()$ALKALINITY),	
           is.na(env_data()$BOULDERS_COBBLES),	
           is.na(env_data()$PEBBLES_GRAVEL),	
           is.na(env_data()$SAND),	
           is.na(env_data()$SILT_CLAY)) > 0) {
      
      shinyalert(title = "One or more sites are missing the complete set of environmental base data required for RICT predictions",
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  output$predictions_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      predict_data(),
      options = list(
        scrollY = "600px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "RICT_predictions"),
              list(extend = 'excel', filename = "RICT_predictions"),
              list(extend = 'pdf', filename = "RICT_predictions")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  
  ## O:E ratios ----
  ### calculating ----
  biol_all <- reactive({
    req(input$calc_OE)
    
    predict_data <- predict_data()
    env_data <- env_data()
    biol_data_2 <- biol_data() %>% distinct(biol_site_id, Year, Season, .keep_all = TRUE)
    biol_data_2 <- dplyr::left_join(biol_data_2, predict_data, by = c("biol_site_id", "Season"))
    biol_data_2 <- dplyr::left_join(biol_data_2, env_data, by = "biol_site_id")
    
    biol_data_2 %>%
      mutate(WHPT_ASPT_O = WHPT_ASPT, WHPT_ASPT_E = TL2_WHPT_ASPT_AbW_DistFam, WHPT_ASPT_OE = WHPT_ASPT_O/WHPT_ASPT_E,
             WHPT_NTAXA_O = WHPT_N_TAXA, WHPT_NTAXA_E = TL2_WHPT_NTAXA_AbW_DistFam, WHPT_NTAXA_OE = WHPT_NTAXA_O/WHPT_NTAXA_E,
             LIFE_F_O = LIFE_FAMILY_INDEX, LIFE_F_E = TL3_LIFE_Fam_DistFam, LIFE_F_OE = LIFE_F_O/LIFE_F_E,
             PSI_O = PSI_FAMILY_SCORE, PSI_E = TL3_PSI_Fam, PSI_OE = PSI_O/PSI_E, date = SAMPLE_DATE) %>% 
      select(c(biol_site_id, SAMPLE_ID, date, Month, Year, Season, NGR_10_FIG, WFD_WATERBODY_ID:CALCIUM,
               WHPT_ASPT_O:PSI_OE))
    
    
  })
  
  #### error message for absent biol data ----
  
  biol_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_data())
    biol_data_exist(TRUE)
  })
  
  observeEvent(input$calc_OE, {
    
    if(!biol_data_exist()) {
      
      shinyalert(title = "Please import biology data",
                 type = "error")
    } 
    
  })
  
  #### warning message for incomplete biol data ----
  observeEvent(input$calc_OE, {
    
    if(sum(is.na(biol_all()$WHPT_ASPT_O),	
           is.na(biol_all()$LIFE_F_O),	
           is.na(biol_all()$WHPT_NTAXA_O),	
           is.na(biol_all()$PSI_O)) > 0) {
      
      shinyalert(title = "One or more sites are missing observed WHPT, LIFE and/or PSI scores required for O:E calculations",
                 type = "warning")
    } 
    
  })
  
  #### error message for absent predict data ----
  
  predict_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(predict_data())
    predict_data_exist(TRUE)
  })
  
  observeEvent(input$calc_OE, {
    
    if(!predict_data_exist()) {
      
      shinyalert(title = "Please run RICT predictions",
                 type = "error")
    } 
    
  })
  
  ### displaying ----
  output$OE_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      biol_all(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "biol_data_O:E"),
              list(extend = 'excel', filename = "biol_data_O:E"),
              list(extend = 'pdf', filename = "biol_data_O:E")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  # FLOW DATA PROCESSING ----
  ## Flow imputation----
  ### donor mapping ----
  #### upload ----
  donor_mapping <- reactive({ 
    
  ##### error message for absent donor mapping ----
    validate(
      need(input$donor_mapping_paste != "", "If imputing flows please add donor mapping")
    )
    
    if (input$donor_mapping_paste != '') {
      donor_mapping <- fread(paste(input$donor_mapping_paste, collapse = "\n"), colClasses = "character")
      donor_mapping <-as.data.frame(donor_mapping)
    }
  })
  
  #### display ----
  output$table2 <- function() {
    
  ##### error message for incorrect flow site IDs ----
    
    flow_sites_list <- metadata()$flow_site_id
    sites_req_donor <- donor_mapping()[,1]
    match <- sites_req_donor %in% flow_sites_list
    
    validate(
      need(!str_contains(match, "FALSE"), "Donee flow sites not detected in original metadata")
    )
    
    donor_mapping() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "150px")
  }
  
  ### donor site list ----
  #### upload ----
  donor_list <- reactive({ 
    
  ##### error message for absent extra flow site list ----
    validate(
      need(input$donor_list_paste != "", "If imputing flows please add additional donor sites as required")
    )
    
    if (input$donor_list_paste != '') {
      donor_list <- fread(paste(input$donor_list_paste, collapse = "\n"), colClasses = "character")
      donor_list <-as.data.frame(donor_list)
    }
  })
  
  #### display ----
  output$table3 <- function() {
    
  ##### error messages for incorrect data formats ----
    donor_req_col_ID <- 'flow_site_id'
    donor_req_col_input <- 'flow_input'
    donor_req_col_flow_input <- 'flow_input'
    donor_req_flow_input_types <- c('HDE', 'NRFA')
    
    donor_sites_col_names <- colnames(donor_list())
    
    donor_mapping_sites <- donor_mapping()[,2]
    metadata_sites <- metadata()$flow_site_id
    donor_list_sites <- donor_list()$flow_site_id
    all_flow_sites <- c(metadata_sites, donor_list_sites)
    
    flow_input <- donor_list()$flow_input
    match <- flow_input %in% donor_req_flow_input_types
    
    validate(
      need(donor_req_col_ID %in% donor_sites_col_names, "You don't have a correctly named list of flow site IDs"),
      need(donor_req_col_input %in% donor_sites_col_names, "You don't have a correctly named list of flow inputs"),
      need(all(donor_mapping_sites %in% all_flow_sites), "One or more named donor sites are absent from both original metadata and additional donor list"),
      need(!str_contains(match, "FALSE"), "Please ensure all your flow inputs are listed as either 'HDE' or 'NRFA'")
      
    )
    
    donor_list() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "150px")
  }
  
  ### impute flow data ----
  #### get extra flow data if needed ----
  flow_data_extra <- reactive({
    req(input$import_donor_flow)
    
    donor_sites <- as.character(donor_list()$flow_site_id)
    donor_inputs <- as.character(donor_list()$flow_input)
    
    donor_data <- import_flow(sites = donor_sites, inputs = donor_inputs, start_date = input$date_range_flow[1],
                              end_date = input$date_range_flow[2])
    
    bind_rows(flow_data(), donor_data)
    
  })
  
  #### alert message for successful import ----
  
  import_donor_flow_success <- reactiveVal(FALSE)
  
  observe({
    req(flow_data_extra())
    import_donor_flow_success(TRUE)
  })
  
  observeEvent(input$import_donor_flow, {
    
    if(import_donor_flow_success()) {
      
      shinyalert(title = "Additional flow data successfully imported",
                 type = "success")
    } 
    
  })
  
  #### warning message for unID'd donor sites ----
  observeEvent(input$import_donor_flow, {
    
    missed_donor_sites <- donor_list() %>% filter(!flow_site_id %in% flow_data_extra()$flow_site_id) %>% select(flow_site_id)
    missed_donor_sites_text <- gsub("c\\(|\\)",'', missed_donor_sites)
    
    if(length(missed_donor_sites > 0)) {
      
      shinyalert(paste("Flow data could not be found for donor station(s)", paste(missed_donor_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  #### run imputation ----
  
  extra_check <- reactiveVal(TRUE)
  
  observeEvent(flow_data_extra(), {
    extra_check(!extra_check())
  })
  
  flow_data_forimp <- reactive({
    
    if (extra_check()){
      flow_data_forimp <- flow_data()
      
    }
    else{
      flow_data_forimp <- flow_data_extra()
      
    }
    
  })
  
  flow_data_imputed <- reactive({
    req(input$impute_flow)
    
    donor_mapping <- as.data.frame(donor_mapping())
    
    impute_flow(flow_data_forimp(), site_col = "flow_site_id", date_col = "date", flow_col = "flow", 
                method = "equipercentile", donor = donor_mapping)
    
  })
  
  #### displaying ----
  
  showHeatmapimp <- reactiveVal(TRUE)
  
  observeEvent(input$imp_flow_data_display, {
    showHeatmapimp(!showHeatmapimp())
  })
  
  output$flow_heatmap_imp <- renderUI({
    if (showHeatmapimp()){
      plotOutput("flow_fig_imp")
    }
    else{
      tableOutput("flow_table_imp")
    }
  })
  
  ##### render table ----
  output$flow_table_imp <- function() {
    plot_heatmap(data = flow_data_imputed(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(3) %>%
      kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "300px")
  }
  
  ##### render heatmap ----
  output$flow_fig_imp <- renderPlot({
    plot_heatmap_dash(data = flow_data_imputed(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(1) %>% grid.arrange() %>% print()
  })
  
  
  ## Calculating flow stats ----
  
  ### run calculation ----
  
  imp_check <- reactiveVal(TRUE)
  
  observeEvent(flow_data_imputed(), {
    imp_check(!imp_check())
  })
  
  flow_data_final <- reactive({
    
    if (imp_check()){
      flow_data_final <- flow_data()
      
    }
    else{
      flow_data_final <- flow_data_imputed()
      
    }
    
  })
  
  flow_stats <- reactive({
    req(input$calc_flow_stats)
    
    flow_data_final <- flow_data_final()
    
    flow_data_final$flow[flow_data_final$flow <= 0] <- NA
    
    calc_flowstats(data = flow_data_final, site_col = "flow_site_id", date_col = "date",
                   flow_col = "flow", win_width = paste(input$win_width_selector, "months"), 
                   win_step = paste(input$win_step_selector, "months"))
  })
  
  
  #### error message for absent flow data ----
  
  flow_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(flow_data())
    flow_data_exist(TRUE)
  })
  
  observeEvent(input$calc_flow_stats, {
    
    if(!flow_data_exist()) {
      
      shinyalert(title = "Please import flow data",
                 type = "error")
    } 
    
  })
  
  ### display table ----
  
  flowStatsDisplay <- reactiveVal(TRUE)
  
  observeEvent(input$flow_stats_display, {
    flowStatsDisplay(!flowStatsDisplay())
  })
  
  flow_stats_data <- reactive({
    if (flowStatsDisplay()){
      flow_stats() %>% pluck(2)
    }
    else{
      flow_stats() %>% pluck(1)
    }
  })
  
  output$flow_stats_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      flow_stats_data(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "flow_stats"),
              list(extend = 'excel', filename = "flow_stats"),
              list(extend = 'pdf', filename = "flow_stats")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  
  # JOIN HE DATA ----
  ## Run join calculations ----
  ### default join type for modelling ----
  
  join_data <- reactive({
    req(input$join_he)
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    join_he(biol_data = biol_all(), flow_stats = flowstats_1, mapping = mapping,
            lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_flows")
    
  })
  
  ### join type for plotting ----
  
  join_data_addbiol <- reactive({
    req(input$join_he)
    
    all.combinations <- expand.grid(biol_site_id = unique(biol_data()$biol_site_id), 
                                    Year = min(biol_data()$Year):max(biol_data()$Year), 
                                    Season = c("Spring", "Autumn"), stringsAsFactors = FALSE)
    
    biol_data1 <- all.combinations %>%
      left_join(biol_all())
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    join_he(biol_data =  biol_data1, flow_stats = flowstats_1, mapping = mapping,
            lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_biol")
    
  })
  
  ### error message for absent biology data ----
  
  biol_all_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_all())
    biol_all_data_exist(TRUE)
  })
  
  observeEvent(input$join_he, {
    
    if(!biol_all_data_exist()) {
      
      shinyalert(title = "Processed biology data are missing",
                 type = "error")
    } 
    
  })
  
  ### error message for absent flow stats ----
  
  flow_stats_exist <- reactiveVal(FALSE)
  
  observe({
    req(flow_stats())
    flow_stats_exist(TRUE)
  })
  
  observeEvent(input$join_he, {
    
    if(!flow_stats_exist()) {
      
      shinyalert(title = "Flow statistics are missing",
                 type = "error")
    } 
    
  })
  
  ### error message for unselected lag(s) ----
  
  observeEvent(input$join_he, {
    
    if(is.null(input$choose_lags)) {
      
      shinyalert(title = "Please select one or more lag periods",
                 type = "error")
    } 
    
  })
  
  ### warning message for biol data predating flow records ----
  
  observeEvent(input$join_he, {
    
    biol_starts <- biol_data() %>% group_by(biol_site_id) %>% summarise(biol_start = min(SAMPLE_DATE))
    flow_starts <- flow_stats() %>% pluck(1) %>% group_by(flow_site_id) %>% summarise(flow_start = min(start_date))
    
    metadata <- metadata()
    metadata$biol_site_id <- as.character(metadata$biol_site_id)
    metadata$flow_site_id <- as.character(metadata$flow_site_id)
    
    biol_starts <- biol_starts %>% left_join(metadata %>% select(c(biol_site_id, flow_site_id)), by = "biol_site_id")
    biol_flow_starts <- biol_starts %>% left_join(flow_starts, by = "flow_site_id")
    
    biol_precede_sites <- biol_flow_starts %>% filter(biol_start < flow_start) %>% pull(biol_site_id)
    biol_precede_sites_text <- gsub("c\\(|\\)",'', biol_precede_sites)
    
    if(sum(biol_flow_starts$biol_start < biol_flow_starts$flow_start) > 0) {
      
      shinyalert(title = paste("One or more biology samples precede the start date of the earliest flow period at site(s) ", paste(biol_precede_sites_text, collapse = ",")),
                 type = "warning")
    } 
    
  })
  
  ## Display joined data ----
  ### table ----
  
  output$join_he_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      join_data(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "he_data_joined"),
              list(extend = 'excel', filename = "he_data_joined"),
              list(extend = 'pdf', filename = "he_data_joined")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  ### plots ----
  #### correlations ----
  output$corr_plots <- renderPlot({
    GGally::ggpairs(join_data(), columns=c("LIFE_F_OE", "WHPT_ASPT_OE", "Q95z_lag0", "Q10z_lag0"), 
                    upper = list(continuous = GGally::wrap("cor")),
                    diag = list(continuous = "densityDiag"),
                    lower = list(continuous = GGally::wrap("points")))+
      theme(text = element_text(size = 14))
    
  })
  
  #### coverage hull ----
  
  output$flow_hull <- renderPlot({
    
    plot_rngflows(data = join_data_addbiol(), flow_stats = c("Q95z_lag0", "Q10z_lag0"), 
                  biol_metric = "LIFE_F_OE", wrap_by = NULL, label = "Year") +
      theme(text = element_text(size = 16))
    
  })
  
  # HEV ----
  ## Create HEV dataset ----
  
  HEV_data <- reactive({
    req(input$join_he)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    biol_data_hev <- dplyr::filter(biol_all(), biol_site_id %in% unique(mapping$biol_site_id))
    flow_data_hev <- dplyr::filter(flowstats_1, flow_site_id %in% unique(mapping$flow_site_id))
    
    hev_data <- expand.grid(
      biol_site_id = unique(biol_data_hev$biol_site_id), 
      date = seq.Date(as.Date("1990-01-01"), as.Date(Sys.Date()), by="day"), 
      stringsAsFactors = FALSE)
    
    hev_data$Month <- lubridate::month(hev_data$date)
    hev_data$Year <- lubridate::year(hev_data$date)
    
    hev_data <- hev_data %>%
      left_join(biol_data_hev, by = c("biol_site_id", "date", "Year"))
    
    hev_data$Season <- factor(hev_data$Season, levels = c("Spring", "Summer" ,"Autumn"))
    
    join_he(biol_data =  hev_data, flow_stats = flow_data_hev, mapping = mapping,
            method = "A", join_type = "add_biol") %>% select(-"win_no_lag0") %>% 
      rename_all(funs(str_replace_all(., '_lag0', '')))
    
  })
  
  ## Plotting ----
  ### reactive expression to select site ----
  
  output$picker <- renderUI({
    pickerInput(inputId = 'site_selector', 
                label = 'Choose site', 
                choices = unique(HEV_data()$biol_site_id),
                options = list(`actions-box` = TRUE),multiple = F)
  })
  
  HEV_plot_data <- reactive({
    
    HEV_plot_data <- HEV_data() %>% 
      filter(biol_site_id == input$site_selector)
    
    return(HEV_plot_data)
    
  })
  
  ### activate initial plot upon site selection
  HEV_go <- reactive({
    req(input$renderHEV)
    
    HEV_plot_data()
    
  }) 
  
  ### error message for absent joined data ----
  
  HEV_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(HEV_data())
    HEV_data_exist(TRUE)
  })
  
  observeEvent(input$renderHEV, {
    
    if(!HEV_data_exist()) {
      
      shinyalert(title = "Paired biology-flow data are missing",
                 type = "error")
    } 
    
  })
  
  ### render HEV plot with download option ----
  
  HEV_plot <- reactive({
    plot_hev_dash(data = HEV_go() %>% filter(Year >= input$HEV_date_range[1] & Year <= input$HEV_date_range[2]),
                                      date_col = "date", 
                                      flow_stat = input$flow_metric_selector,
                                      biol_metric = input$biol_metric_selector,
                                      multiplot = FALSE,
                                      clr_by = "Season")
  })

  output$HEV_plot <- renderPlot({
    HEV_plot()
  }) 
  
  downloadServer("HEVPlot", HEV_plot)
  
  # CLEAR HISTORY OPTION ----
  
  observeEvent(input$clear_all, {
    shinyalert(title = "This will clear all existing data and outputs. Do you want to continue?", 
               callbackR = function(x) {
                 if(x == TRUE)
                   session$reload()
               },
               type = "warning",
               showCancelButton = TRUE,
               confirmButtonCol = '#DD6B55',
               confirmButtonText = 'Yes, go ahead')
    
  })
}