# This file provides the user interface (layout, style) for the dashboard

# Title, layout and main settings ----
tagList(
  add_busy_spinner(spin = "fading-circle", color="#00a33b", position="bottom-left"),
page_navbar(
  id = "main_nav",
  theme = bs_theme(navbar_bg = "#008938", bg = "#f6f8f7", fg = "#17231d", version = 5, bootswatch = "minty"),
  title = "HE Toolkit Dashboard",
  tags$head(
    tags$script(type="text/javascript", src = "logo.js"),
    tags$style(type='text/css', ".irs-grid-text { font-size: 10pt; }"),
    tags$style(HTML("
      .hint-text {
        color: #5c6770;
        font-size: 0.92rem;
        line-height: 1.45;
        margin-bottom: 0.75rem;
      }
      .dashboard-page {
        max-width: 1240px;
        margin: 0 auto;
        padding: 1.25rem 1rem 2.5rem 1rem;
      }
      .dashboard-card {
        width: 100%;
        border: 1px solid #dfe8e2;
        border-radius: 8px;
        box-shadow: 0 1px 8px rgba(20, 45, 32, 0.05);
        margin-bottom: 1rem;
      }
      .wide-plot-card {
        max-width: none;
      }
      .wide-plot-scroll {
        width: 100%;
        overflow-x: auto;
        padding-bottom: 0.5rem;
      }
      .wide-plot-scroll .shiny-plot-output {
        min-width: 920px;
      }
      .section-title {
        margin-bottom: 0.2rem;
        color: #17231d;
        font-weight: 650;
      }
      .page-lead {
        color: #40504a;
        font-size: 1rem;
        line-height: 1.55;
        max-width: 980px;
      }
      .workflow-note {
        border-left: 4px solid #008938;
        background: #eef8f2;
        padding: 0.9rem 1rem;
        margin: 0.85rem 0 1rem 0;
      }
      .control-stack .form-group,
      .control-stack .shiny-input-container {
        width: 100%;
        margin-bottom: 0.85rem;
      }
      .action-stack .btn,
      .download-row .btn {
        width: 100%;
        margin-bottom: 0.65rem;
      }
      .download-row {
        margin-top: 0.75rem;
      }
      .sidebar-section {
        border-bottom: 1px solid #dfe8e2;
        padding-bottom: 1rem;
        margin-bottom: 1rem;
      }
      .sidebar-section:last-child {
        border-bottom: 0;
      }
      .sidebar-section h5 {
        font-size: 0.95rem;
        font-weight: 650;
        margin-bottom: 0.7rem;
      }
      .plot-frame {
        min-height: 430px;
      }
      .upload-status {
        border-left: 4px solid #008938;
        background: #f5fbf7;
        padding: 0.85rem 1rem;
        margin: 0.75rem 0 1rem 0;
        border-radius: 6px;
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
      .home-summary {
        max-width: 1040px;
        margin: 1rem auto 0 auto;
        padding: 0 15px;
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
      .client-action-button,
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
      .client-action-button:hover,
      .wq-rhs-mapping-example .dt-buttons button:hover,
      .wq-rhs-mapping-example .dt-buttons .btn:hover,
      .wq-rhs-mapping-example .buttons-copy:hover {
        color: #111 !important;
        background: linear-gradient(to bottom, #f5f5f5 0%, #dcdcdc 100%) !important;
        background-color: #dcdcdc !important;
        border-color: #777 !important;
      }
      .wq-rhs-action-button:focus,
      .client-action-button:focus,
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
      .site-metadata-upload .btn-file,
      .site-metadata-upload .btn-default,
      .site-metadata-upload .btn-secondary {
        color: #333 !important;
        background: linear-gradient(to bottom, #fff 0%, #e9e9e9 100%) !important;
        background-color: #e9e9e9 !important;
        border: 1px solid #999 !important;
        border-radius: 2px !important;
        box-shadow: none !important;
      }
      .site-metadata-upload .btn-file:hover,
      .site-metadata-upload .btn-default:hover,
      .site-metadata-upload .btn-secondary:hover {
        color: #111 !important;
        background: linear-gradient(to bottom, #f5f5f5 0%, #dcdcdc 100%) !important;
        border-color: #777 !important;
      }
      .shiny-output-error-validation {
        color: #ff9933;
        font-weight: bold;
      }
      
      .wf-bar {
        display:flex; align-items:center; gap:0;
        margin:0 0 1.5rem 0; padding:1rem 1.25rem;
        background:#f6f8f7; border:1px solid #dfe8e2; border-radius:8px;
      }
      .wf-step { display:flex; align-items:center; flex:1; position:relative; }
      .wf-step:not(:last-child)::after {
        content:''; flex:1; height:2px; background:#dfe8e2; margin:0 0.5rem;
      }
      .wf-step.done:not(:last-child)::after { background:#008938; }
      .wf-circle {
        width:28px; height:28px; border-radius:50%;
        border:2px solid #dfe8e2; background:white;
        display:flex; align-items:center; justify-content:center;
        font-size:0.8rem; font-weight:600; color:#5c6770; flex-shrink:0;
      }
      .wf-step.done  .wf-circle { background:#008938; border-color:#008938; color:white; }
      .wf-step.active .wf-circle { background:white;  border-color:#008938; color:#008938; }
      .wf-label { font-size:0.78rem; color:#5c6770; margin-left:0.4rem; white-space:nowrap; }
      .wf-step.active .wf-label { color:#008938; font-weight:600; }
      .wf-step.done   .wf-label { color:#17231d; }

      .cp-card {
        display:flex; align-items:flex-start; gap:0.6rem;
        padding:0.55rem 0.8rem; border-radius:6px;
        margin-bottom:0.4rem; font-size:0.88rem;
      }
      .cp-card.pass { background:#eef8f2; border-left:3px solid #008938; }
      .cp-card.warn { background:#fff8ee; border-left:3px solid #ff9933; }
      .cp-card.fail { background:#fff1f1; border-left:3px solid #d9534f; }
      .cp-icon { font-weight:bold; flex-shrink:0; margin-top:1px; }
      .cp-card.pass .cp-icon { color:#008938; }
      .cp-card.warn .cp-icon { color:#b87000; }
      .cp-card.fail .cp-icon { color:#d9534f; }
            "))
        ),
  
  # INTRO PAGE ----
    nav_panel(
      title = "Home",
      div(
        class = "introduction-page",
        div(
          class = "home-summary",
          
      # cards ----
          h2(class = "section-title", style = "font-size:1.5rem; margin-bottom:0.3rem;",
             "What would you like to do?"),
          p(class = "page-lead", style = "margin-bottom:1.2rem;",
            "Select a task to jump to the relevant page."),
          div(
            class = "workflow-note",
            tags$strong("Note: "),
            "HEV Plot automatically chains Flow Statistics, O:E, and data joining steps. ",
            "WQ and RHS are supporting evidence only — not used in O:E calculations."
          ),
          
      layout_columns(
        col_widths = c(4, 4, 4),
        card(
          class = "dashboard-card",
          card_header(tags$strong("Import Data")),
          p(class = "hint-text", "Import biology, environmental, flow, WQ, and RHS datasets."),
          p(class = "hint-text", style = "color:#5c6770; font-size:0.82rem;",
            "Start here before running any workflow"),
          div(style = "margin-top:auto;",
              actionButton("goto_import", "Go to Data Import \u2192",
                           style = "background:#008938; border-color:#008938; color:white; width:100%;"))
        ),
        card(
          class = "dashboard-card",
          card_header(tags$strong("O:E Ratio")),
          p(class = "hint-text", "Calculate observed vs expected ecological scores using RICT predictions."),
          p(class = "hint-text", style = "color:#2E6B3E; font-size:0.82rem;",
            "Needs: biology + environmental data only"),
          div(style = "margin-top:auto;",
              actionButton("goto_oe", "Go to Process Biology \u2192",
                           style = "background:#008938; border-color:#008938; color:white; width:100%;"))
        ),
        card(
          class = "dashboard-card",
          card_header(tags$strong("Flow Statistics")),
          p(class = "hint-text", "Impute missing flow data and calculate windowed flow statistics."),
          p(class = "hint-text", style = "color:#2E6B3E; font-size:0.82rem;",
            "Needs: flow data"),
          div(style = "margin-top:auto;",
              actionButton("goto_flow", "Go to Process Flow \u2192",
                           style = "background:#008938; border-color:#008938; color:white; width:100%;"))
        )
      ),
      layout_columns(
        col_widths = c(4, 4, 4),
        card(
          class = "dashboard-card",
          card_header(tags$strong("Analysis")),
          p(class = "hint-text", "Pair biology and flow, explore correlations and flow-ecology models."),
          p(class = "hint-text", style = "color:#5c6770; font-size:0.82rem;",
            "Exploratory — does not alter O:E"),
          div(style = "margin-top:auto;",
              actionButton("goto_analysis", "Go to Analysis \u2192",
                           style = "background:#5c6770; border-color:#5c6770; color:white; width:100%;"))
        ),
        card(
          class = "dashboard-card",
          card_header(tags$strong("HEV Plot")),
          p(class = "hint-text", "Full hydroecological evaluation — flow statistics, O:E ratios, and HEV visualisation."),
          p(class = "hint-text", style = "color:#2E6B3E; font-size:0.82rem;",
            "Needs: biology + environmental + flow data"),
          div(style = "margin-top:auto;",
              actionButton("goto_hev", "Go to HEV Plots \u2192",
                           style = "background:#008938; border-color:#008938; color:white; width:100%;"))
        ),
        card(
          class = "dashboard-card",
          card_header(tags$strong("WQ / RHS Review")),
          p(class = "hint-text", "Review mapped Water Quality and River Habitat Survey supporting data."),
          p(class = "hint-text", style = "color:#5c6770; font-size:0.82rem;",
            "Supporting evidence — not part of O:E"),
          div(style = "margin-top:auto;",
              actionButton("goto_wqrhs", "Go to WQ/RHS Data \u2192",
                           style = "background:#5c6770; border-color:#5c6770; color:white; width:100%;"))
        )
      ),
          
          tags$hr(style = "margin: 2rem 0;"
                  ),
          card(
            class = "dashboard-card",
            card_header("Dashboard review guide"),
            p(class = "page-lead", "Use this dashboard to import hydro-ecology datasets, process existing HE Toolkit workflows, and review supporting Water Quality (WQ) and River Habitat Survey (RHS) evidence."),
            div(
              class = "workflow-note",
              tags$strong("Important: "),
              "WQ and RHS are supporting mapped datasets only. They are not used in the O:E calculation."
            ),
            layout_columns(
              col_widths = c(4, 4, 4),
              div(tags$strong("Mapping"), p(class = "hint-text", "Upload or paste site IDs that connect biology, flow, WQ, and RHS records.")),
              div(tags$strong("WQ/RHS review"), p(class = "hint-text", "Preview mapped supporting data, generate plots, and download mapped outputs.")),
              div(tags$strong("Core HE workflow"), p(class = "hint-text", "Existing biology, flow, O:E, and HEV workflow outputs remain separate."))
            )
          )
        ),
        htmlOutput("intro_page"),
        div(
          class = "wq-rhs-mapping-example",
          h2(class = "section-title", "WQ/RHS site-ID mapping example"),
          p("This example shows the extended site metadata format needed for WQ/RHS import. WQ site ID SW-A4070115 is the candidate Water Quality Archive sampling point CHEW KEYNSHAM M. RHS survey ID 6145 is the mapping used for biology site 291 in HE Toolkit CaseStudy2 and has been verified in the official RHS open dataset."),
          p("Both values are included for demonstration and reference. WQ and RHS IDs should not be assumed to match biology or flow site IDs, and final mappings should be confirmed by the user or client."),
          DT::dataTableOutput("wq_rhs_mapping_example")
        )
      )
    ),
  
  # SECOND PAGE ----
    nav_panel(title = "Data Import", 
            navset_card_tab(
              
  ## Sidebar ----
            sidebar = sidebar("", width = 330, position = "right",
              div(class = "sidebar-section action-stack",
                h5("Session"),
                actionButton("clear_all", "Clear all", class = "client-action-button", icon = shiny::icon("eraser", verify_fa = FALSE))
              ),
              div(class = "sidebar-section control-stack",
                h5("Mapping"),
                textAreaInput("meta_paste", "Paste site metadata here"),
                div(
                  class = "site-metadata-upload",
                  fileInput(
                    "site_metadata_csv",
                    "Or upload site metadata CSV",
                    accept = c(".csv", "text/csv"),
                    buttonLabel = "Choose site IDs CSV",
                    placeholder = "No CSV selected"
                  )
                ),
                div(
                  class = "hint-text",
                  "Required mapping columns: biol_site_id, flow_site_id, wq_site_id, rhs_survey_id. Optional flow_input defaults to HDE. Use TBC for unconfirmed WQ/RHS mappings."
                ),
                uiOutput("site_metadata_upload_status"),
                div(class = "download-row",
                  downloadButton(
                    "download_demo_site_metadata",
                    "Download demo mapping CSV",
                    class = "wq-rhs-action-button"
                  )
                ),
                tags$strong("Validated site metadata"),
                tableOutput("table1")
              ),
              div(class = "sidebar-section control-stack action-stack",
                h5("Core HE imports"),
                dateRangeInput("date_range_biol", "Biology sample dates", start="1990-01-01", end=as.character(Sys.Date())),
                dateRangeInput("date_range_flow", "Flow data dates", start="1990-01-01", end=as.character(Sys.Date())),
                actionButton("import_inv", "Import biology data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE)),
                actionButton("import_env", "Import environmental data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE)),
                actionButton("import_flow", "Import flow data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
              ),
              div(class = "sidebar-section control-stack action-stack",
                h5("Supporting WQ/RHS imports"),
                dateRangeInput("date_range_wq", "WQ data dates", start="2020-01-01", end=as.character(Sys.Date())),
                actionButton("import_wq_site_ids", "Import WQ using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE)),
                actionButton("import_rhs_site_ids", "Import RHS using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
              ),
              plotOutput("import_flow_bar")
            ),
            
  ## Main body ----
            nav_panel("Biology Data",
                      div(class = "dashboard-page",
                        card(class = "dashboard-card",
                          card_header("Imported biology data"),
                          p(class = "hint-text", "Review the biology records imported for the mapped biology site IDs."),
                          tableOutput("biol_table")
                        )
                      )),
            nav_panel("Environmental Data",
                      div(class = "dashboard-page",
                        card(class = "dashboard-card",
                          card_header("Environmental base data"),
                          radioButtons(inputId = "env_data_display", "Display:", choices = c("Data", "PCA")),
                          fluidRow(uiOutput(outputId = "env_tab_pca", height = 600))
                        )
                      )
            ),
            nav_panel("Flow Data",
                      div(class = "dashboard-page",
                        card(class = "dashboard-card wide-plot-card",
                          card_header("Imported flow data"),
                          radioButtons(inputId = "flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                          div(class = "wide-plot-scroll", uiOutput(outputId = "flow_heatmap"))
                        )
                      )
            ),
            nav_panel("WQ Data",
                      div(class = "dashboard-page",
                        h3(class = "section-title", "Water Quality supporting data"),
                        p(class = "page-lead", "Mapped WQ data can be reviewed, plotted, and downloaded here. These data remain separate from O:E calculations."),
                        layout_columns(
                          col_widths = c(12, 12),
                          card(class = "dashboard-card",
                            card_header("Mapped WQ preview"),
                            uiOutput("wq_site_import_status"),
                            DT::dataTableOutput("wq_site_import_preview"),
                            div(class = "download-row",
                              downloadButton("download_mapped_wq_csv", "Download mapped WQ data as CSV", class = "wq-rhs-action-button")
                            )
                          ),
                          card(class = "dashboard-card",
                            card_header("WQ plots"),
                            div(class = "hint-text", "Plots use mapped WQ data only. WQ data are mapped through wq_site_id when a site metadata mapping is available."),
                            selectInput(
                              "wq_plot_type",
                              "WQ plot type",
                              choices = c("Time series", "Boxplot by biological site ID", "Mean bar chart by biological site ID")
                            ),
                            uiOutput("wq_plot_controls"),
                            div(class = "plot-frame", plotOutput("wq_mapped_plot", height = 420)),
                            div(class = "download-row",
                              downloadButton("download_wq_plot", "Download current WQ plot as PNG", class = "wq-rhs-action-button")
                            )
                          )
                        )
                      )
            ),
            nav_panel("RHS Data",
                      div(class = "dashboard-page",
                        h3(class = "section-title", "River Habitat Survey supporting data"),
                        p(class = "page-lead", "Mapped RHS data can be reviewed, plotted, and downloaded here. Missing or TBC RHS IDs are handled safely."),
                        layout_columns(
                          col_widths = c(12, 12),
                          card(class = "dashboard-card",
                            card_header("Mapped RHS preview"),
                            uiOutput("rhs_site_import_status"),
                            DT::dataTableOutput("rhs_site_import_preview"),
                            div(class = "download-row",
                              downloadButton("download_mapped_rhs_csv", "Download mapped RHS data as CSV", class = "wq-rhs-action-button")
                            )
                          ),
                          card(class = "dashboard-card",
                            card_header("RHS plots"),
                            div(class = "hint-text", "Plots use mapped RHS data only. RHS data are mapped through rhs_survey_id when a site metadata mapping is available."),
                            selectInput(
                              "rhs_plot_type",
                              "RHS plot type",
                              choices = c("Numeric variable by biological site ID", "Categorical count/bar plot", "Record count by biological site ID")
                            ),
                            uiOutput("rhs_plot_controls"),
                            div(class = "plot-frame", plotOutput("rhs_mapped_plot", height = 420)),
                            div(class = "download-row",
                              downloadButton("download_rhs_plot", "Download current RHS plot as PNG", class = "wq-rhs-action-button")
                            )
                          )
                        )
                      )
            ),
            nav_panel("Local File Import",
                      div(class = "dashboard-page",
                        h3(class = "section-title", "Local CSV file import"),
                        p(class = "page-lead", "Upload local files for validation. A valid Local Flow upload is used as the Flow data source; local invertebrate data remain separate from O:E."),
                        layout_columns(
                          col_widths = c(6, 6),
                          card(class = "dashboard-card",
                            card_header("Local invertebrate CSV"),
                            div(class = "hint-text", "Required columns: biol_site_id, date, taxon, abundance."),
                            fileInput("local_inv_csv", "Choose local invertebrate CSV", accept = c(".csv", "text/csv")),
                            uiOutput("local_inv_status"),
                            DT::dataTableOutput("local_inv_preview")
                          ),
                          card(class = "dashboard-card",
                            card_header("Local flow CSV"),
                            div(class = "hint-text", "Required columns: flow_site_id, date, flow. A valid upload is used as the Flow data source."),
                            fileInput("local_flow_csv", "Choose local flow CSV", accept = c(".csv", "text/csv")),
                            uiOutput("local_flow_status"),
                            DT::dataTableOutput("local_flow_preview")
                          )
                        )
                      )
            ),
            nav_panel("Site Map",
                      div(class = "dashboard-page",
                        card(class = "dashboard-card",
                          card_header("Mapped monitoring sites"),
                          leafletOutput("map0", height = 600)
                        )
                      ))
            )
  ),
  
  # THIRD PAGE ----
    nav_panel("Process Biology",
            navset_card_tab(
              
  ## Sidebar ----  
           sidebar = sidebar("", position = "right",
               div(class = "sidebar-section",
                   h5("Readiness check"),
                   uiOutput("cp_biology")
                   ),
              div(class = "sidebar-section action-stack",
                h5("Biology processing"),
                actionButton("run_rict", "Run RICT predictions", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE)),
                actionButton("calc_OE", "Calculate O:E ratios", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
              )
            ),
   
  ## Main body ----  
   nav_panel("RICT Predictions",
             div(class = "dashboard-page",
                 wf_progress_bar(active_step = 2),
               card(class = "dashboard-card",
                 card_header("RICT predictions"),
                 p(class = "hint-text", "Predicted biological index values used by the existing O:E workflow."),
                 dataTableOutput("predictions_table")
               )
             )),
   nav_panel("O:E Ratios",
             div(class = "dashboard-page",
               card(class = "dashboard-card",
                 card_header("O:E ratios"),
                 p(class = "hint-text", "Existing O:E calculation output. WQ and RHS supporting data are not used here."),
                 dataTableOutput("OE_table")
               )
             ))
            )
   ),
  
  # FOURTH PAGE ----
    nav_panel("Process Flow",
            navset_card_tab(
            
              
  ## Sidebar ----  
            
            sidebar = sidebar("", width = 300, position = "right",
              div(class = "sidebar-section",
                  h5("Readiness check"),
                  uiOutput("cp_flow")
              ),
              div(class = "sidebar-section control-stack",
                h5("Donor flow setup"),
                textAreaInput("donor_mapping_paste", "Paste donor mapping here"),
                tags$strong("Donor mapping"),
                tableOutput("table2"),
                textAreaInput("donor_list_paste", "Paste additional flow donor sites here"),
                tags$strong("Donor list"),
                tableOutput("table3")
              ),
              div(class = "sidebar-section action-stack",
                h5("Imputation"),
                actionButton("import_donor_flow", "Import additional donor flow data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE)),
                actionButton("impute_flow", "Impute missing flow data", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
              ),
              div(class = "sidebar-section control-stack action-stack",
                h5("Flow statistics"),
                sliderInput('win_width_selector', 'Window width (months)', min= 3, 
                            max= 36, value = 6, sep = ""),
                sliderInput('win_step_selector', 'Window step (months)', min= 1, 
                            max= 12, value = 6, sep = ""),
                actionButton("calc_flow_stats", "Calculate flow statistics", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
              )
              
            ),
            
  ## Main body ----  
            
            nav_panel("Imputed Flow Data",
                      div(class = "dashboard-page",
                          wf_progress_bar(active_step = 3),
                        card(class = "dashboard-card wide-plot-card",
                          card_header("Imputed flow data"),
                          radioButtons(inputId = "imp_flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                          div(class = "wide-plot-scroll", uiOutput(outputId = "flow_heatmap_imp"))
                        )
                      )
            ),
            nav_panel("Flow Statistics",
                      div(class = "dashboard-page",
                          wf_progress_bar(active_step = 3),
                        card(class = "dashboard-card",
                          card_header("Calculated flow statistics"),
                          radioButtons(inputId = "flow_stats_display", "Display:", choices = c("Time-varying", "Long-term")),
                          dataTableOutput("flow_stats_table")
                        )
                      )
                      )
  )
),

 # FIFTH PAGE ----
   nav_panel("Analysis",
          navset_card_tab(
            
  ## Sidebar ----
      sidebar = sidebar("", width = 300, position = "right",
            div(class = "sidebar-section control-stack action-stack",
              h5("Pair biology and flow"),
              pickerInput(inputId = "choose_lags", label = "Select lags", choices = 0:10, multiple = TRUE),
              pickerInput(inputId = "choose_join_method", label = "Select join method", choices = c("A", "B"), multiple = FALSE),
              actionButton("join_he", "Pair biology and flow data", class = "client-action-button", icon = shiny::icon("link", verify_fa = FALSE))
            )
          ),
          nav_panel("Joined Data",
                    div(class = "dashboard-page",
                        wf_progress_bar(active_step = 4),
                      card(class = "dashboard-card",
                        card_header("Paired biology-flow data"),
                        dataTableOutput("join_he_table")
                      )
                    )),
          nav_panel("Pairwise Correlations",
                    div(class = "dashboard-page",
                      card(class = "dashboard-card",
                        card_header("Pairwise correlation plots"),
                        plotOutput("corr_plots")
                      )
                    )),
          nav_panel("Historical Coverage",
                    div(class = "dashboard-page",
                      card(class = "dashboard-card",
                        card_header("Historical flow and biology coverage"),
                        plotOutput("flow_hull")
                      )
                    )),
          nav_panel("Flow-Ecology Model",
                    div(class = "dashboard-page",
                      h3(class = "section-title", "Basic flow-ecology model"),
                      p(class = "page-lead", "Optional exploratory analysis only. This does not alter O:E calculations."),
                      card(class = "dashboard-card",
                        card_header("Model setup and result"),
                        uiOutput("basic_model_controls"),
                        div(class = "action-stack",
                          actionButton("run_basic_model", "Run basic model", class = "client-action-button", icon = shiny::icon("chart-line", verify_fa = FALSE))
                        ),
                        uiOutput("basic_model_status"),
                        DT::dataTableOutput("basic_model_summary"),
                        plotOutput("basic_model_plot", height = 420)
                      )
                    ))
)
),

  # SIXTH PAGE ----
    nav_panel("HEV Plots",
          navset_card_tab(
            
  ## Sidebar ----
        
            sidebar = sidebar("", width = 300, position = "right",
            div(class = "sidebar-section control-stack",
              h5("HEV plot setup"),
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
                          value = c(1990, 2025), sep = "", round = TRUE)
            ),
            div(class = "sidebar-section",
              h5("Display options"),
              checkboxInput("HEV_show_all_metrics", "Show all 4 HEV plots", value = FALSE),
              checkboxInput("HEV_show_high_low", "Overlay low-flow and high-flow statistics", value = FALSE),
              checkboxInput("HEV_show_status", "Show available status class boundaries", value = FALSE)
            ),
            div(class = "sidebar-section",
                h5("Readiness check"),
                uiOutput("cp_hev")
            ),
            div(class = "sidebar-section action-stack",
              actionButton("renderHEV", "Create HEV plot", class = "client-action-button", icon = shiny::icon("chart-simple", verify_fa = FALSE))
            )
          ),
          div(class = "dashboard-page",
              wf_progress_bar(active_step = 5),
            h3(class = "section-title", "Hydro-ecological variation plot"),
            p(class = "page-lead", "Review HEV plots for selected biological and flow metrics. Existing HEV download behaviour is preserved."),
            card(class = "dashboard-card",
              card_header("HEV output"),
              uiOutput("hev_status_message"),
              plotOutput("HEV_plot"),
              div(class = "download-row",
                downloadSelectUI("HEVPlot"),
                downloadButtonUI("HEVPlot")
              )
            )
          )
)
),

  # WQ/RHS UPLOAD DEMO ----
    nav_panel("CSV Validation Sandbox",
      layout_columns(
        col_widths = c(12),
        card(
          class = "dashboard-card",
          card_header("Introduction"),
          p("Use this page to quickly validate and preview local Water Quality (WQ) and River Habitat Survey (RHS) CSV files before moving them into the mapped supporting-data workflow."),
          p("No RICT calculation, O:E calculation, or production modelling is run from this page.")
        ),
        card(
          class = "dashboard-card",
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
          class = "dashboard-card",
          card_header("Upload RHS CSV"),
          p("River Habitat Survey data usually contains survey identifiers plus habitat metrics or descriptors such as HMS, HQA, channel, bank, substrate, vegetation, and flow-type fields."),
          div(class = "hint-text",
              "Local RHS CSV files must use rhs_survey_id as the identifier column."),
          fileInput("rhs_csv", "Choose RHS CSV file", accept = c(".csv", "text/csv")),
          h5("RHS validation status"),
          uiOutput("rhs_validation_status"),
          h5("RHS preview"),
          div(class = "hint-text", "This preview shows the first rows of your uploaded file. No modelling has been run yet."),
          dataTableOutput("rhs_preview")
        ),
        card(
          class = "dashboard-card",
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
