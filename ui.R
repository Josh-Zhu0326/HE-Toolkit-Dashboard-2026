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
      .shiny-output-error-validation {
        color: #ff9933;
        font-weight: bold;
      }
      "))
  ),
  
  # INTRO PAGE ----
    nav_panel(title = "Introduction", htmlOutput("intro_page")),
  
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
    
  # Navbar links ----
  nav_menu(
    title = "Links",
    align = "left",
    nav_item(link_git),
    nav_item(link_web)
  )
)
)
