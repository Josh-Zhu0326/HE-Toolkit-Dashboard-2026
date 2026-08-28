# This file provides the user interface (layout, style) for the dashboard

# Title, layout and main settings ----
tagList(
  tags$head(
    # Load workflow styles once here; keep workflow markup in workflow_ui.R.
    workflow_style_tags(),
    workflow_task_policy_script(),
    tags$style(type='text/css', ".irs-grid-text { font-size: 10pt; }"),
    tags$style(HTML("
      .hint-text {
        color: #5c6770;
        font-size: 0.92rem;
        line-height: 1.45;
        margin-bottom: 0.75rem;
      }
      .dashboard-page {
        width: 100%;
        max-width: var(--wf-page-max, 1480px);
        margin: 0 auto;
        padding: 1.25rem 1rem 2.5rem 1rem;
      }
      .dashboard-page-wide {
        max-width: none;
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
        width: 100% !important;
        min-width: 920px;
      }
      .plot-frame .shiny-plot-output,
      .dashboard-page-wide .shiny-plot-output {
        width: 100% !important;
        max-width: 100%;
      }
      .dataTables_wrapper,
      .dataTables_scroll {
        width: 100% !important;
        max-width: 100%;
      }
      .dataTables_scrollBody {
        overflow-x: auto !important;
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
      .wq-rhs-action-button,
      .client-action-button {
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
      .client-action-button:hover {
        color: #111 !important;
        background: linear-gradient(to bottom, #f5f5f5 0%, #dcdcdc 100%) !important;
        background-color: #dcdcdc !important;
        border-color: #777 !important;
      }
      .wq-rhs-action-button:focus,
      .client-action-button:focus {
        box-shadow: 0 0 0 0.2rem rgba(0, 137, 56, 0.2) !important;
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
      @media (max-width: 959px) {
        .dashboard-page {
          padding-right: 0.75rem;
          padding-left: 0.75rem;
        }
        .wide-plot-scroll .shiny-plot-output {
          min-width: 100%;
        }
      }
            "))
        ),
  add_busy_spinner(spin = "fading-circle", color="#00a33b", position="bottom-left"),
page_navbar(
  id = "main_nav",
  theme = bs_theme(
    navbar_bg = "#245f3b",
    bg = "#f4f6f4",
    fg = "#1f2a24",
    version = 5,
    bootswatch = "minty"
  ),
  title = "HE Toolkit Dashboard",
  header = tagList(
    uiOutput("workflow_header"),
    uiOutput("workflow_stage_overview")
  ),
  
  # INTRO PAGE ----
    nav_panel(
      title = "Home",
      div(
        class = "workflow-home-page",
        uiOutput("workflow_shell"),
        div(
          class = "workflow-guide",
          tags$details(
            tags$summary("Data and mapping guide"),
            p(class = "page-lead", "Use site IDs to connect biology, flow, water-quality and River Habitat Survey records. WQ and RHS are optional enrichment and never block a valid core HE dataset."),
            p("When HDE has no data for a site, NRFA can be used as an alternative flow-data source."),
            tags$strong("Example site mapping"),
            DT::dataTableOutput("wq_rhs_mapping_example")
          )
        )
      )
    ),
  
  # SECOND PAGE ----
    nav_panel(title = "Data Import",
      div(
        class = "workflow-stage-workspace",
            navset_card_tab(
              
  ## Sidebar ----
            sidebar = sidebar("", width = 330, position = "right",
              div(class = "sidebar-section action-stack",
                h5("Session"),
                actionButton("clear_all", "Clear all", class = "client-action-button workflow-secondary-action", icon = shiny::icon("eraser", verify_fa = FALSE))
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
                  "Required core mapping columns: biol_site_id and flow_site_id. Optional WQ/RHS mappings use wq_site_id and rhs_survey_id. Optional flow_input defaults to HDE. Use TBC for unconfirmed WQ/RHS mappings."
                ),
                uiOutput("site_metadata_upload_status"),
                uiOutput("flow_source_default_status"),
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
                div(
                  `data-task-imports` = "biology",
                  dateRangeInput("date_range_biol", "Biology sample dates", start="1990-01-01", end=as.character(Sys.Date())),
                  actionButton("import_inv", "Import biology data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
                ),
                div(
                  `data-task-imports` = "environment",
                  actionButton("import_env", "Import environmental data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
                ),
                div(
                  `data-task-imports` = "flow",
                  dateRangeInput("date_range_flow", "Flow data dates", start="1990-01-01", end=as.character(Sys.Date())),
                  actionButton("import_flow", "Import flow data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
                )
              ),
              div(class = "sidebar-section control-stack action-stack", `data-task-imports` = "flow",
                h5("Additional donor Flow"),
                div(class = "hint-text", "Add donor mappings and import any donor Flow sites that are not already present in the main Flow data."),
                textAreaInput("donor_mapping_paste", "Paste donor mapping here"),
                tags$strong("Donor mapping"),
                tableOutput("table2"),
                textAreaInput("donor_list_paste", "Paste additional flow donor sites here"),
                tags$strong("Donor list"),
                tableOutput("table3"),
                actionButton("import_donor_flow", "Import additional donor flow data", class = "client-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
              ),
              div(class = "sidebar-section control-stack action-stack", `data-task-imports` = "wq,rhs",
                h5("Optional WQ/RHS inputs"),
                div(class = "hint-text", "Upload or retrieve supporting data here. WQ/RHS are applied later as optional enrichment and never block the core biology-flow dataset."),
                div(
                  `data-task-imports` = "wq",
                  dateRangeInput(
                    "date_range_wq",
                    "WQ data dates",
                    start = "2020-01-01",
                    end = as.character(Sys.Date()),
                    min = "2000-01-01",
                    max = as.character(Sys.Date())
                  ),
                  actionButton("import_wq_site_ids", "Import WQ using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
                ),
                div(
                  `data-task-imports` = "rhs",
                  actionButton("import_rhs_site_ids", "Import RHS using site IDs", class="wq-rhs-action-button", icon = shiny::icon("file-arrow-down", verify_fa = FALSE))
                )
              )
            ),
            
  ## Main body ----
            nav_panel("Biology Data",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "biology", `data-task-import-panel` = "true",
                        card(class = "dashboard-card",
                          card_header("Imported biology data"),
                          p(class = "hint-text", "Review the biology records imported for the mapped biology site IDs."),
                          tableOutput("biol_table")
                        )
                      )),
            nav_panel("Environmental Data",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "environment", `data-task-import-panel` = "true",
                        card(class = "dashboard-card",
                          card_header("Environmental base data"),
                          radioButtons(inputId = "env_data_display", "Display:", choices = c("Data", "PCA")),
                          fluidRow(uiOutput(outputId = "env_tab_pca", height = 600))
                        )
                      )
            ),
            nav_panel("Flow Data",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "flow", `data-task-import-panel` = "true",
                        card(class = "dashboard-card wide-plot-card",
                          card_header("Imported flow data"),
                          p(class = "hint-text", "This view refreshes when the main Flow source or additional donor Flow data is imported."),
                          radioButtons(inputId = "flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                          div(class = "wide-plot-scroll", uiOutput(outputId = "flow_heatmap")),
                          conditionalPanel(
                            condition = "input.flow_data_display === 'Heatmap'",
                            div(
                              class = "download-row",
                              downloadSelectUI("FlowHeatmap", choices = c("PDF", "CSV", "PNG")),
                              downloadButtonUI("FlowHeatmap")
                            )
                          )
                        )
                      )
            ),
            nav_panel("WQ Data",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "wq", `data-task-import-panel` = "true",
                        h3(class = "section-title", "Water Quality supporting data"),
                        p(class = "page-lead", "Mapped WQ source data can be reviewed and downloaded here. Build the processed WQ summary in Stage 2."),
                        layout_columns(
                          col_widths = 12,
                          card(class = "dashboard-card", full_screen = TRUE,
                            card_header("Mapped WQ preview"),
                            uiOutput("wq_site_import_status"),
                            DT::dataTableOutput("wq_site_import_preview"),
                            div(class = "download-row",
                              downloadButton("download_mapped_wq_csv", "Download mapped WQ data as CSV", class = "wq-rhs-action-button")
                            )
                          )
                        )
                      )
            ),
            nav_panel("RHS Data",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "rhs", `data-task-import-panel` = "true",
                        h3(class = "section-title", "River Habitat Survey supporting data"),
                        p(class = "page-lead", "Mapped RHS data can be reviewed and downloaded here. Missing or TBC RHS IDs are handled safely."),
                        layout_columns(
                          col_widths = 12,
                          card(class = "dashboard-card", full_screen = TRUE,
                            card_header("Mapped RHS preview"),
                            uiOutput("rhs_site_import_status"),
                            DT::dataTableOutput("rhs_site_import_preview"),
                            div(class = "download-row",
                              downloadButton("download_mapped_rhs_csv", "Download mapped RHS data as CSV", class = "wq-rhs-action-button")
                            )
                          )
                        )
                      )
            ),
            nav_panel("Local File Import",
                      div(class = "dashboard-page dashboard-page-wide", `data-task-imports` = "biology,environment,flow,wq,rhs", `data-task-import-panel` = "true",
                        local_csv_checkpoint_panel(),
                        tags$details(
                          class = "dashboard-card",
                          `data-task-imports` = "biology",
                          tags$summary(class = "card-header", "Legacy taxon-level Biology exclusion log"),
                          div(
                            class = "card-body",
                            div(
                              class = "hint-text",
                              "This compatibility checkpoint uses the existing biol_site_id, date, taxon and abundance format. It is separate from the Data Contract v2.0 Biology CSV above."
                            ),
                            fileInput(
                              "local_inv_csv",
                              "Choose legacy taxon-level Biology CSV",
                              accept = c(".csv", "text/csv")
                            ),
                            uiOutput("local_inv_status"),
                            DT::dataTableOutput("local_inv_preview"),
                            h5("Exclusion log"),
                            div(class = "hint-text", "Records removed or flagged during the existing filtering workflow, with the reason for each."),
                            uiOutput("exclusion_log_status"),
                            DT::dataTableOutput("exclusion_log_table"),
                            downloadButton("download_exclusion_log", "Download exclusion log as CSV")
                          )
                        ),
                        tags$details(
                          class = "dashboard-card",
                          `data-task-imports` = "wq",
                          tags$summary(class = "card-header", "Legacy WQ workflow upload"),
                          div(
                            class = "card-body",
                            div(
                              class = "hint-text",
                              "This temporary compatibility entry keeps the existing mapped WQ workflow available while Data Contract v2.0 ingestion is completed. Use the WQ checkpoint above for the primary upload-time validation result."
                            ),
                            fileInput("wq_csv", "Choose legacy workflow WQ CSV", accept = c(".csv", "text/csv")),
                            uiOutput("wq_validation_status"),
                            h5("WQ preview"),
                            DT::dataTableOutput("wq_preview")
                          )
                        ),
                        tags$details(
                          class = "dashboard-card",
                          `data-task-imports` = "rhs",
                          tags$summary(class = "card-header", "Legacy RHS workflow upload"),
                          div(
                            class = "card-body",
                            div(
                              class = "hint-text",
                              "This temporary compatibility entry keeps the existing mapped RHS workflow available while Data Contract v2.0 ingestion is completed. Use the RHS checkpoint above for the primary upload-time validation result."
                            ),
                            fileInput("rhs_csv", "Choose legacy workflow RHS CSV", accept = c(".csv", "text/csv")),
                            uiOutput("rhs_validation_status"),
                            h5("RHS preview"),
                            DT::dataTableOutput("rhs_preview")
                          )
                        )
                      )
            ),
            nav_panel("Site Map",
                      div(class = "dashboard-page dashboard-page-wide",
                        card(class = "dashboard-card",
                          card_header("Mapped monitoring sites"),
                          uiOutput("site_map_status"),
                          leafletOutput("map0", height = 600)
                        )
                      ))
            )
      )
  ),
  
  # THIRD PAGE ----
    nav_panel("Process Biology",
      div(
        class = "workflow-stage-workspace",
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
             div(class = "dashboard-page dashboard-page-wide",
               card(class = "dashboard-card",
                 card_header("RICT predictions"),
                 p(class = "hint-text", "Predicted biological index values used by the existing O:E workflow."),
                 dataTableOutput("predictions_table")
               )
             )),
   nav_panel("O:E Ratios",
             div(class = "dashboard-page dashboard-page-wide",
               card(class = "dashboard-card",
                 card_header("O:E ratios"),
                 p(class = "hint-text", "Existing O:E calculation output. WQ and RHS supporting data are not used here."),
                 dataTableOutput("OE_table")
               )
             ))
            )
      )
   ),
  
  # FOURTH PAGE ----
    nav_panel("Process Flow",
      div(
        class = "workflow-stage-workspace",
            navset_card_tab(
            
              
  ## Sidebar ----  
            
            sidebar = sidebar("", width = 300, position = "right",
              div(class = "sidebar-section",
                  h5("Readiness check"),
                  uiOutput("cp_flow")
              ),
              div(class = "sidebar-section action-stack",
                h5("Flow imputation"),
                div(class = "hint-text", "Uses the donor mapping and additional donor Flow prepared in Stage 1."),
                actionButton("impute_flow", "Impute missing flow data", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
              ),
              div(class = "sidebar-section control-stack action-stack",
                h5("Flow statistics"),
                sliderInput('win_width_selector', 'Window width (months)', min= 6,
                            max= 36, value = 6, sep = ""),
                sliderInput('win_step_selector', 'Window step (months)', min= 1, 
                            max= 12, value = 6, sep = ""),
                actionButton("calc_flow_stats", "Calculate flow statistics", class = "client-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
              )
              
            ),
            
  ## Main body ----  
            
            nav_panel("Imputed Flow Data",
                      div(class = "dashboard-page dashboard-page-wide",
                        card(class = "dashboard-card wide-plot-card",
                          card_header("Imputed flow data"),
                          p(class = "hint-text", "This view refreshes after additional donor Flow is imported and after Flow imputation is completed."),
                          radioButtons(inputId = "imp_flow_data_display", "Display:", choices = c("Completeness stats", "Heatmap")),
                          div(class = "wide-plot-scroll", uiOutput(outputId = "flow_heatmap_imp")),
                          conditionalPanel(
                            condition = "input.imp_flow_data_display === 'Heatmap'",
                            div(
                              class = "download-row",
                              downloadSelectUI("ImputedFlowHeatmap", choices = c("PDF", "CSV", "PNG")),
                              downloadButtonUI("ImputedFlowHeatmap")
                            )
                          )
                        )
                      )
            ),
            nav_panel("Flow Statistics",
                      div(class = "dashboard-page dashboard-page-wide",
                        card(class = "dashboard-card",
                          card_header("Calculated flow statistics"),
                          radioButtons(inputId = "flow_stats_display", "Display:", choices = c("Time-varying", "Long-term")),
                          dataTableOutput("flow_stats_table")
                        )
                      )
                      )
  )
  )
),

  # STAGE 2 — WQ PROCESSING ----
  nav_panel(
    "Process WQ",
    div(
      class = "workflow-stage-workspace",
      div(
        class = "dashboard-page dashboard-page-wide",
        h3(class = "section-title", "Process Water Quality data"),
        p(
          class = "page-lead",
          "Use the validated Stage 1 WQ source to inspect contracted plots and build the reusable Stage 2 WQ summary."
        ),
        radioButtons(
          "wq_stage2_display",
          "Display:",
          choices = c("Plots" = "plot", "Summary table" = "summary"),
          selected = "plot",
          inline = TRUE
        ),
        conditionalPanel(
          condition = "input.wq_stage2_display === 'plot'",
          card(
            class = "dashboard-card",
            full_screen = TRUE,
            card_header("WQ preview plots"),
            div(
              class = "hint-text",
              "Choose one determinand. Plots always use result over date_time and group records by wq_site_id."
            ),
            uiOutput("wq_plot_controls"),
            selectInput(
              "wq_plot_type",
              "WQ plot type",
              choices = c("Time series", "Boxplot")
            ),
            div(class = "plot-frame", plotOutput("wq_mapped_plot", height = 520)),
            div(
              class = "download-row",
              downloadButton("download_wq_plot", "Download current WQ plot as PNG", class = "wq-rhs-action-button")
            )
          )
        ),
        conditionalPanel(
          condition = "input.wq_stage2_display === 'summary'",
          card(
            class = "dashboard-card",
            full_screen = TRUE,
            card_header("Contracted WQ summary"),
            div(
              class = "hint-text",
              "Builds the Stage 2 biology-anchored summary for orthophosphate 0180 and ammonia 0111. Dissolved oxygen remains pending OPEN-02."
            ),
            div(
              class = "action-stack",
              actionButton("build_wq_contract_summary", "Build WQ summary", class = "wq-rhs-action-button", icon = shiny::icon("calculator", verify_fa = FALSE))
            ),
            uiOutput("wq_contract_summary_status"),
            DT::dataTableOutput("wq_contract_summary_table"),
            uiOutput("wq_contract_summary_provenance"),
            div(
              class = "download-row",
              downloadButton("download_wq_contract_summary_csv", "Download WQ summary CSV", class = "wq-rhs-action-button")
            )
          )
        )
      )
    )
  ),

  # STAGE 3 ----
  nav_panel(
    "Build HE Dataset",
    div(
      class = "workflow-stage-workspace",
      navset_card_tab(
      sidebar = sidebar(
        "",
        width = 300,
        position = "right",
        div(
          class = "sidebar-section control-stack action-stack",
          h5("Pair biology and flow"),
          pickerInput(
            inputId = "choose_lags",
            label = "Select lags",
            choices = SUPPORTED_FLOW_LAGS,
            multiple = TRUE
          ),
          pickerInput(
            inputId = "choose_join_method",
            label = "Select join method",
            choices = "A",
            multiple = FALSE
          ),
          actionButton(
            "join_he",
            "Pair biology and flow data",
            class = "client-action-button",
            icon = shiny::icon("link", verify_fa = FALSE)
          ),
          tags$hr(),
          h5("Processed dataset checkpoint"),
          fileInput(
            "processed_dataset_checkpoint_file",
            "Upload checkpoint",
            accept = c(".rds", "application/octet-stream")
          ),
          actionButton(
            "load_processed_dataset_checkpoint",
            "Load checkpoint",
            class = "client-action-button",
            icon = shiny::icon("file-arrow-up", verify_fa = FALSE)
          ),
          uiOutput("processed_dataset_checkpoint_status"),
          uiOutput("processed_dataset_checkpoint_download"),
          tags$hr(),
          h5("Optional enrichment"),
          checkboxGroupInput(
            "selected_enrichments",
            "Add supporting data",
            choices = c("Water Quality" = "wq", "River Habitat Survey" = "rhs")
          ),
          actionButton(
            "build_joined_enriched",
            "Build enriched dataset",
            class = "client-action-button",
            icon = shiny::icon("layer-group", verify_fa = FALSE)
          ),
          checkboxInput(
            "use_joined_enriched",
            "Use enriched dataset for analysis",
            value = FALSE
          ),
          uiOutput("joined_enrichment_status"),
          uiOutput("analysis_source_status")
        )
      ),
      nav_panel(
        "Joined Data",
        div(
          class = "dashboard-page dashboard-page-wide",
          card(
            class = "dashboard-card",
            card_header("Paired biology-flow data"),
            dataTableOutput("join_he_table")
          ),
          card(
            class = "dashboard-card",
            card_header("Optional enriched data"),
            dataTableOutput("joined_enriched_table")
          )
        )
      )
      )
    )
  ),

  # STAGE 4 ----
  nav_panel(
    "Explore Relationships",
    div(
      class = "workflow-stage-workspace",
      navset_card_tab(
      nav_panel(
        "Analysis Selection",
        div(
          class = "dashboard-page dashboard-page-wide",
          card(
            class = "dashboard-card",
            card_header("Sample selection"),
            p(
              class = "hint-text",
              "Every sample in the Joined HE dataset starts selected. Untick any samples you want to leave out, then choose Apply selection. Excluded samples are dropped from the correlation plots, Historical Coverage and the Stage 5 model, but the Joined HE dataset itself is never changed."
            ),
            uiOutput("analysis_selection_summary"),
            div(
              class = "action-stack",
              actionButton(
                "analysis_select_all_samples",
                "Select all",
                class = "client-action-button"
              ),
              actionButton(
                "analysis_clear_all_samples",
                "Clear selection",
                class = "client-action-button"
              ),
              actionButton(
                "apply_analysis_sample_selection",
                "Apply selection",
                class = "client-action-button"
              )
            ),
            DT::dataTableOutput("analysis_sample_table")
          ),
          card(
            class = "dashboard-card",
            card_header("Exclude or restore a single record"),
            tags$details(
              tags$summary("Adjust one record by ID (optional)"),
              p(
                class = "hint-text",
                "Use this to exclude or restore a single record by its identifier without changing the rest of the current sample selection."
              ),
              uiOutput("analysis_record_selector"),
              div(
                class = "action-stack",
                actionButton(
                  "exclude_analysis_record",
                  "Exclude record",
                  class = "client-action-button"
                ),
                actionButton(
                  "restore_analysis_record",
                  "Restore record",
                  class = "client-action-button"
                )
              )
            )
          ),
          card(
            class = "dashboard-card",
            card_header("Exclusion and restore log"),
            DT::dataTableOutput("analysis_exclusion_log_table")
          )
        )
      ),
      nav_panel(
        "Pairwise Correlations",
        div(
          class = "dashboard-page dashboard-page-wide",
          card(
            class = "dashboard-card",
            card_header("Pairwise correlation plots"),
            plotOutput("corr_plots")
          )
        )
      ),
      nav_panel(
        "Historical Coverage",
        div(
          class = "dashboard-page dashboard-page-wide",
          card(
            class = "dashboard-card",
            card_header("Historical flow and biology coverage"),
            plotOutput("flow_hull")
          )
        )
      )
      )
    )
  ),

  # STAGE 5 ----
  nav_panel(
    "Model and Export",
    div(
      class = "dashboard-page dashboard-page-wide workflow-stage-workspace",
      h3(class = "section-title", "Build and diagnose an HE model"),
      p(
        class = "page-lead",
        "Select variables, fit the eligible single-site or multi-site model, review its diagnostics and export the current results."
      ),
      card(
        class = "dashboard-card",
        card_header("1. Select variables and fit the model"),
        uiOutput("basic_model_controls"),
        div(
          class = "action-stack",
          actionButton(
            "run_basic_model",
            "Fit model",
            class = "client-action-button",
            icon = shiny::icon("chart-line", verify_fa = FALSE)
          )
        ),
        uiOutput("basic_model_status")
      ),
      card(
        class = "dashboard-card",
        card_header("2. Review model results"),
        uiOutput("basic_model_result_review")
      ),
      card(
        class = "dashboard-card",
        card_header("3. Review residual diagnostics"),
        uiOutput("basic_model_diagnostic_review")
      ),
      card(
        class = "dashboard-card",
        card_header("4. Export the current model"),
        uiOutput("basic_model_download_controls")
      )
    )
  ),

  # SIXTH PAGE ----
    nav_panel("HEV Plots",
      div(
        class = "workflow-stage-workspace",
        layout_sidebar(
            
  ## Sidebar ----
        
            sidebar = sidebar("", width = 300, position = "right",
            div(class = "sidebar-section control-stack",
              h5("HEV plot setup"),
              uiOutput("picker"),
              radioButtons(
                inputId = "hev_flow_data_mode",
                label = "Flow data mode",
                choices = c("Raw daily Flow" = "daily_flow", "Flow statistics" = "flow_statistics"),
                selected = "flow_statistics"
              ),
              pickerInput(inputId = "biol_metric_selector", label = "Select biomonitoring index", 
                          choices = HEV_BIOLOGY_METRICS, multiple = FALSE),
              pickerInput(inputId = "flow_metric_selector", label = "Select flow metric", 
                          choices = HEV_FLOW_STAT_METRICS, multiple = FALSE),
              sliderInput('HEV_date_range', 'Select date range', min= 1990, max= Sys.Date() %>% data.table::year() %>% as.numeric(), 
                          value = c(1990, 2025), sep = "", round = TRUE)
            ),
            div(class = "sidebar-section",
              h5("Display options"),
              checkboxInput("HEV_show_all_metrics", "Show all 4 HEV plots", value = FALSE),
              checkboxInput("HEV_show_high_low", "Overlay low-flow and high-flow statistics", value = FALSE),
              checkboxInput("HEV_show_status", "Show available status class boundaries", value = FALSE),
              radioButtons(
                inputId = "hev_river_type",
                label = "River type for LIFE threshold",
                choices = c("Non-chalk" = "non_chalk", "Chalk" = "chalk"),
                selected = "non_chalk"
              )
            ),
            div(class = "sidebar-section",
                h5("Readiness check"),
                uiOutput("cp_hev")
            ),
            div(class = "sidebar-section action-stack",
              actionButton("renderHEV", "Generate HEV plot", class = "client-action-button", icon = shiny::icon("chart-simple", verify_fa = FALSE))
            )
          ),
          div(class = "dashboard-page dashboard-page-wide",
            h3(class = "section-title", "Generate and interpret HEV plots"),
            p(class = "page-lead", "Generate HEV plots for selected biological and flow metrics, review the patterns and export the current result."),
            card(class = "dashboard-card",
              card_header("Current HEV plot"),
              uiOutput("hev_status_message"),
              uiOutput("hev_provenance_summary"),
              plotOutput("HEV_plot"),
              div(class = "download-row",
                downloadSelectUI("HEVPlot"),
                downloadButtonUI("HEVPlot")
              ),
              DT::dataTableOutput("hev_download_history_table")
            ),
            card(class = "dashboard-card",
              card_header("Interpretation checklist"),
              tags$ul(
                tags$li("Check the direction, timing and consistency of the biological and flow patterns."),
                tags$li("Compare high-flow, low-flow or status overlays only when those options are available and selected."),
                tags$li("Review data coverage and provenance before drawing or reporting conclusions.")
              )
            )
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
