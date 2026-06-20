# This file provides the user interface (layout, style) for the dashboard

# Title, layout and main settings ----
tagList(
  add_busy_spinner(spin = "fading-circle", color="#00a33b", position="bottom-left"),
page_navbar(
  theme = bs_theme(navbar_bg = "#008938", bg = "#FFF", fg = "black", version = 5, bootswatch = "minty"),
  title = "HE Toolkit Dashboard",
  tags$head(
    tags$script(type="text/javascript", src = "logo.js"),
    tags$style(type='text/css', ".irs-grid-text { font-size: 10pt; }"),
    tags$style(HTML("
      .hint-text {
        color: #5c6770;
        font-size: 0.86rem;
        line-height: 1.35;
        margin-top: -0.35rem;
        margin-bottom: 0.75rem;
      }
      .upload-status {
        border-left: 4px solid #008938;
        background: #f5fbf7;
        padding: 0.85rem 1rem;
        margin: 0.75rem 0 1rem 0;
      }
      .upload-status-warning {
        border-left-color: #ff9933;
        background: #fff8ee;
      }
      .upload-status-error {
        border-left-color: #d9534f;
        background: #fff1f1;
      }
      .upload-status-info {
        border-left-color: #5c6770;
        background: #f4f6f7;
      }
      .introduction-page {
        font-size: 17px;
        line-height: 1.5;
      }
      .introduction-page .dataTables_wrapper {
        font-size: 14px;
      }
      .introduction-page .wq-rhs-mapping-example {
        width: 100%;
        max-width: 940px;
        margin: 1.25rem auto 2rem auto;
        padding-right: 15px;
        padding-left: 15px;
      }
      .wq-rhs-action-button,
      .wq-rhs-mapping-example .dt-buttons button,
      .wq-rhs-mapping-example .dt-buttons .btn,
      .wq-rhs-mapping-example .buttons-copy {
        --bs-btn-color: #333;
        --bs-btn-bg: #e9e9e9;
        --bs-btn-border-color: #999;
        --bs-btn-hover-color: #111;
        --bs-btn-hover-bg: #dcdcdc;
        --bs-btn-hover-border-color: #777;
        --bs-btn-active-color: #111;
        --bs-btn-active-bg: #d4d4d4;
        --bs-btn-active-border-color: #666;
        color: #333 !important;
        background: linear-gradient(to bottom, #fff 0%, #e9e9e9 100%) !important;
        background-color: #e9e9e9 !important;
        border: 1px solid #999 !important;
        border-radius: 2px !important;
        box-shadow: none !important;
      }
      .wq-rhs-action-button:hover,
      .wq-rhs-mapping-example .dt-buttons button:hover,
      .wq-rhs-mapping-example .dt-buttons .btn:hover,
      .wq-rhs-mapping-example .buttons-copy:hover {
        color: #111 !important;
        background: linear-gradient(to bottom, #f5f5f5 0%, #dcdcdc 100%) !important;
        background-color: #dcdcdc !important;
        border-color: #777 !important;
      }
      .wq-rhs-action-button:focus,
      .wq-rhs-mapping-example .dt-buttons button:focus,
      .wq-rhs-mapping-example .dt-buttons .btn:focus,
      .wq-rhs-mapping-example .buttons-copy:focus {
        box-shadow: 0 0 0 0.2rem rgba(0, 137, 56, 0.2) !important;
      }
      .wq-rhs-mapping-example .dt-buttons button:active,
      .wq-rhs-mapping-example .dt-buttons .btn:active,
      .wq-rhs-mapping-example .buttons-copy:active {
        color: #111 !important;
        background: linear-gradient(to bottom, #ededed 0%, #d4d4d4 100%) !important;
        background-color: #d4d4d4 !important;
        border-color: #666 !important;
      }
      .shiny-output-error-validation {
        color: #ff9933;
        font-weight: bold;
      }
      "))
  ),
  
  # INTRO PAGE ----
    nav_panel(
      title = "Introduction",
      div(
        class = "introduction-page",
        htmlOutput("intro_page"),
        div(
          class = "wq-rhs-mapping-example",
          h1("WQ/RHS site-ID mapping example"),
          p("This example shows the extended site metadata format needed for WQ/RHS import. WQ site ID SW-A4070115 is the candidate Water Quality Archive sampling point CHEW KEYNSHAM M. RHS survey ID 6145 is the mapping used for biology site 291 in HE Toolkit CaseStudy2 and has been verified in the official RHS open dataset."),
          p("Both values are included for demonstration and reference. WQ and RHS IDs should not be assumed to match biology or flow site IDs, and final mappings should be confirmed by the user or client."),
          DT::dataTableOutput("wq_rhs_mapping_example")
        )
      )
    ),
  
  # SECOND PAGE ----
    nav_panel(title = "Import datasets", 
            navset_card_tab(
              
  ## Sidebar ----
            sidebar = sidebar("", width = 300, position = "right",
              div(style="text-align: center;", actionButton("clear_all", "CLEAR ALL", style="color: #DD6B55; background-color: #FFF; border-color: #008938", icon = shiny::icon("eraser", verify_fa = FALSE))),
              br(),
              textAreaInput("meta_paste", "Paste site metadata here"),
              nav_item("Site Metadata",
                         tableOutput("table1")),
              br(),
              dateRangeInput("date_range_biol", "Select start and end dates for biology samples:", start="1990-01-01", end=as.character(Sys.Date())),
              dateRangeInput("date_range_flow", "Select start and end dates for flow data:", start="1990-01-01", end=as.character(Sys.Date())),
              div(style="text-align: center;", actionButton("import_inv", "Import biology data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              br(),
              div(style="text-align: center;", actionButton("import_env", "Import environmental data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              br(),
              div(style="text-align: center;", actionButton("import_flow", "Import flow data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              br(),
              dateRangeInput("date_range_wq", "Select start and end dates for WQ data:", start="2020-01-01", end=as.character(Sys.Date())),
              div(style="text-align: center;", actionButton("import_wq_site_ids", "Import WQ using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              br(),
              div(style="text-align: center;", actionButton("import_rhs_site_ids", "Import RHS using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              plotOutput("import_flow_bar")
            ),
            
  ## Main body ----
            nav_panel("View invertebrate data",
                      tableOutput("biol_table")),
            nav_panel("View environmental data",
                      radioButtons(inputId = "env_data_display", "Display:", choices = c("Data", "PCA")),
                      fluidRow(uiOutput(outputId = "env_tab_pca", height = 600))
            ),
            nav_panel("View flow data",
                      radioButtons(inputId = "flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                      uiOutput(outputId = "flow_heatmap")
            ),
            nav_panel("View WQ data",
                      uiOutput("wq_site_import_status"),
                      DT::dataTableOutput("wq_site_import_preview")
            ),
            nav_panel("View RHS data",
                      uiOutput("rhs_site_import_status"),
                      DT::dataTableOutput("rhs_site_import_preview")
            ),
            nav_panel("View map of sites",
                      leafletOutput("map0", height = 600))
            )
  ),
  
  # THIRD PAGE ----
    nav_panel("Process invertebrate data",
            navset_card_tab(
              
  ## Sidebar ----  
           sidebar = sidebar("", position = "right",
              div(style="text-align: center;", actionButton("run_rict", "Run RICT predictions", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("calculator", verify_fa = FALSE))),
              br(),
              div(style="text-align: center;", actionButton("calc_OE", "Calculate O:E ratios", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("calculator", verify_fa = FALSE)))
            ),
   
  ## Main body ----  
   nav_panel("View RICT predictions",
             dataTableOutput("predictions_table")),
   nav_panel("View O:E ratios",
             dataTableOutput("OE_table"))
            )
   ),
  
  # FOURTH PAGE ----
    nav_panel("Process flow data",
            navset_card_tab(
            
              
  ## Sidebar ----  
            
            sidebar = sidebar("", width = 300, position = "right",
              textAreaInput("donor_mapping_paste", "Paste donor mapping here"),
              nav_item("Donor mapping",
                         tableOutput("table2")),
              textAreaInput("donor_list_paste", "Paste additional flow donor sites here"),
              nav_item("Donor list",
                         tableOutput("table3")),
              br(),
              div(style="text-align: center;", actionButton("import_donor_flow", "Import additional donor flow data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))),
              br(),
              div(style="text-align: center;", actionButton("impute_flow", "Impute missing flow data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("calculator", verify_fa = FALSE))),
              br(),
              sliderInput('win_width_selector', 'Select win_width (months)', min= 3, 
                          max= 36, value = 6, sep = ""),
              sliderInput('win_step_selector', 'Select win_step (months)', min= 1, 
                          max= 12, value = 6, sep = ""),
              div(style="text-align: center;", actionButton("calc_flow_stats", "Calculate flow statistics", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("calculator", verify_fa = FALSE)))
              
            ),
            
  ## Main body ----  
            
            nav_panel("View imputed flow data",
                      radioButtons(inputId = "imp_flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                      uiOutput(outputId = "flow_heatmap_imp")
            ),
            nav_panel("View flow stats",
                      radioButtons(inputId = "flow_stats_display", "Display:", choices = c("Time-varying", "Long-term")),
                      dataTableOutput("flow_stats_table")
                      )
  )
),

 # FIFTH PAGE ----
   nav_panel("Join HE data",
          navset_card_tab(
            
  ## Sidebar ----
      sidebar = sidebar("", width = 300, position = "right",
            pickerInput(inputId = "choose_lags", label = "Select lags", choices = 0:10, multiple = TRUE),
            pickerInput(inputId = "choose_join_method", label = "Select join method", choices = c("A", "B"), multiple = FALSE),
            div(style="text-align: center;", actionButton("join_he", "Pair biology and flow data", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("link", verify_fa = FALSE)))
          ),
          nav_panel("View joined data",
                    dataTableOutput("join_he_table")),
          nav_panel("View pairwise correlations",
                    plotOutput("corr_plots")),
          nav_panel("View historical coverage",
                    plotOutput("flow_hull"))
)
),

  # SIXTH PAGE ----
    nav_panel("HEV",
          navset_card_tab(
            
  ## Sidebar ----
        
            sidebar = sidebar("", width = 300, position = "right",
            uiOutput("picker"),
            pickerInput(inputId = "biol_metric_selector", label = "Select biomonitoring index", 
                        choices = c("WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE"), multiple = FALSE),
            pickerInput(inputId = "flow_metric_selector", label = "Select flow metric", 
                        choices = c("Q5", "Q5z", "Q10", "Q10z",
                                    "Q30", "Q30z", "Q50", "Q50z",
                                    "Q70", "Q70z", "Q75", "Q75z",
                                    "Q80", "Q80z", "Q85", "Q85z",
                                    "Q90", "Q90z", "Q95", "Q95z",
                                    "Q99", "Q99z"), multiple = FALSE),
            sliderInput('HEV_date_range', 'Select date range', min= 1990, max= Sys.Date() %>% data.table::year() %>% as.numeric(), 
                        value = c(1990, 2025), sep = "", round = TRUE),
            div(style="text-align: center;", actionButton("renderHEV", "Create HEV plot", style="color: black; background-color: #FFF; border-color: #008938", icon = shiny::icon("chart-simple", verify_fa = FALSE)))
          ),
          fluidRow(plotOutput("HEV_plot"),
                   downloadSelectUI("HEVPlot"),
                   downloadButtonUI("HEVPlot"))
)
),

  # WQ/RHS UPLOAD DEMO ----
    nav_panel("WQ/RHS Upload Demo",
      layout_columns(
        col_widths = c(12),
        card(
          card_header("Introduction"),
          p("Use this demo page to upload local Water Quality (WQ) and River Habitat Survey (RHS) CSV files for early validation and preview."),
          p("No joining, modelling, RICT calculation, or HE workflow integration is run from this page yet.")
        ),
        card(
          card_header("Upload WQ CSV"),
          p("Water Quality data usually contains monitoring site identifiers, sample dates, determinands, measured results, units, and optional qualifiers."),
          div(class = "hint-text",
              "Expected columns are flexible for this first demo. Helpful site identifier columns include: biol_site_id, wq_site_id, site_id, monitoring_site_id. Date or measurement columns are also recommended."),
          fileInput("wq_csv", "Choose WQ CSV file", accept = c(".csv", "text/csv")),
          h5("WQ validation status"),
          uiOutput("wq_validation_status"),
          h5("WQ preview"),
          div(class = "hint-text", "This preview shows the first rows of your uploaded file. No modelling has been run yet."),
          dataTableOutput("wq_preview")
        ),
        card(
          card_header("Upload RHS CSV"),
          p("River Habitat Survey data usually contains survey identifiers plus habitat metrics or descriptors such as HMS, HQA, channel, bank, substrate, vegetation, and flow-type fields."),
          div(class = "hint-text",
              "Expected columns are flexible for this first demo. rhs_survey_id is preferred because HE Toolkit imports RHS records by survey ID. Other helpful identifier columns include: biol_site_id, rhs_site_id, site_id, survey_id."),
          fileInput("rhs_csv", "Choose RHS CSV file", accept = c(".csv", "text/csv")),
          h5("RHS validation status"),
          uiOutput("rhs_validation_status"),
          h5("RHS preview"),
          div(class = "hint-text", "This preview shows the first rows of your uploaded file. No modelling has been run yet."),
          dataTableOutput("rhs_preview")
        ),
        card(
          card_header("Notes / Next steps"),
          tags$ul(
            tags$li("This page accepts CSV files only in this first implementation step."),
            tags$li("Validation is intentionally friendly and non-blocking while the final WQ and RHS schemas are still being designed."),
            tags$li("The next step is to define mapping columns and aggregation rules before joining WQ/RHS data to the HE workflow.")
          )
        )
      )
    ),
    
  # Navbar links ----
  nav_menu(
    title = "Links",
    align = "left",
    nav_item(link_git),
    nav_item(link_web)
  )
)
)
