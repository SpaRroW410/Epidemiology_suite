# Cluster / Design Effect module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_proportion.R
# (docs/SDD.md #8) -- two designs: inflating an externally-computed base n
# by the design effect (DEFF), or solving a full cluster survey (PSU + SSU
# counts) in one step for a proportion.

cluster_meta <- list(
  id = "cluster",
  nav_title = "Cluster / Design Effect"
)

mod_cluster_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Design-effect inflation (given a computed base n)" = "deff",
          "Design-effect inflation (variable cluster size)" = "deff_variable",
          "Cluster survey precision (WHO EPI-style, proportion)" = "survey"
        ),
        selected = "deff"
      ),
      conditionalPanel(
        condition = design_is("deff"),
        numericInput(ns("n_base"), "Base sample size (simple random sampling)",
                     value = 200, min = 1, step = 1),
        numericInput(ns("icc"), "Intraclass correlation coefficient (ICC / rho)",
                     value = 0.05, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("cluster_size"), "Average cluster size (subjects per cluster)",
                     value = 10, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("deff_variable"),
        numericInput(ns("n_base_var"), "Base sample size (simple random sampling)",
                     value = 100, min = 1, step = 1),
        numericInput(ns("icc_var"), "Intraclass correlation coefficient (ICC / rho)",
                     value = 0.05, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("cluster_size_var"), "Average cluster size (subjects per cluster)",
                     value = 20, min = 1, step = 1),
        numericInput(ns("cv_var"), "Coefficient of variation of cluster size (SD / mean)",
                     value = 0.5, min = 0, step = 0.05)
      ),
      conditionalPanel(
        condition = design_is("survey"),
        numericInput(ns("b_survey"), "Average individuals sampled per cluster (b)",
                     value = 75, min = 0.001, step = 1),
        numericInput(ns("b_sd_survey"), "SD of cluster size (optional; leave blank if constant)",
                     value = NA, min = 0),
        numericInput(ns("p_survey"), "p (expected proportion)",
                     value = 0.46, min = 0, max = 1, step = 0.01),
        numericInput(ns("epsilon_survey"), "Desired precision (epsilon)",
                     value = 0.10, min = 0.0001, step = 0.01),
        selectInput(ns("error_survey"), "Precision expressed as",
                    choices = c("Relative (fraction of p)" = "relative",
                                "Absolute (same scale as p)" = "absolute")),
        numericInput(ns("rho_survey"), "Intracluster correlation (rho)",
                     value = 0.20, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("N_psu_survey"),
                     "Total number of clusters in the population (optional; leave blank if unlimited)",
                     value = NA, min = 1),
        numericInput(ns("conf_level_survey"), "Confidence level",
                     value = 0.90, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(cluster_content$deff$title),
      render_formula_block(cluster_content$deff$formula_latex),
      shiny::markdown(cluster_content$deff$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff$worked_example),
      hr(),
      h4(cluster_content$deff_variable$title),
      render_formula_block(cluster_content$deff_variable$formula_latex),
      shiny::markdown(cluster_content$deff_variable$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff_variable$worked_example),
      hr(),
      h4(cluster_content$survey$title),
      render_formula_block(cluster_content$survey$formula_latex),
      shiny::markdown(cluster_content$survey$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$survey$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(cluster_content$deff$title),
      p(strong("Citation: "), cluster_content$deff$citation),
      p(strong("Implemented via: "), code(cluster_content$deff$backend)),
      hr(),
      h4(cluster_content$deff_variable$title),
      p(strong("Citation: "), cluster_content$deff_variable$citation),
      p(strong("Implemented via: "), code(cluster_content$deff_variable$backend)),
      hr(),
      h4(cluster_content$survey$title),
      p(strong("Citation: "), cluster_content$survey$citation),
      p(strong("Implemented via: "), code(cluster_content$survey$backend))
    )
  )
}

mod_cluster_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "deff") {
        req(input$n_base, input$icc, input$cluster_size)
        tryCatch(
          list(ok = TRUE, value = calc_cluster_deff(
            n_base = input$n_base, icc = input$icc, cluster_size = input$cluster_size
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "deff_variable") {
        req(input$n_base_var, input$icc_var, input$cluster_size_var, input$cv_var)
        tryCatch(
          list(ok = TRUE, value = calc_cluster_deff_variable(
            n_base = input$n_base_var, icc = input$icc_var,
            cluster_size = input$cluster_size_var, cv = input$cv_var
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$b_survey, input$p_survey, input$epsilon_survey, input$error_survey,
            input$rho_survey, input$conf_level_survey)
        b_sd <- input$b_sd_survey
        if (is.null(b_sd) || is.na(b_sd)) b_sd <- NULL
        N_psu <- input$N_psu_survey
        if (is.null(N_psu) || is.na(N_psu)) N_psu <- NULL
        tryCatch(
          list(ok = TRUE, value = calc_cluster_survey_binary(
            b = input$b_survey, b_sd = b_sd, p = input$p_survey,
            epsilon = input$epsilon_survey, error = input$error_survey,
            rho = input$rho_survey, N_psu = N_psu, conf_level = input$conf_level_survey
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (input$design == "deff") {
        tagList(
          p(strong("Design effect (DEFF): "), sprintf("%.3f", v$deff)),
          p(strong("Cluster-adjusted (effective) sample size: "), v$n_effective)
        )
      } else if (input$design == "deff_variable") {
        tagList(
          p(strong("Design effect (DEFF, variable cluster size): "), sprintf("%.3f", v$deff)),
          p(strong("Cluster-adjusted (effective) sample size: "), v$n_effective)
        )
      } else {
        tagList(
          p(strong("Required number of clusters (PSUs): "), v$n_psu),
          p(strong("Required total individuals (SSUs): "), v$n_ssu),
          p(sprintf("Design effect = %.3f", v$deff))
        )
      }
    })
  })
}
