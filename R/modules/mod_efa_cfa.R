# EFA/CFA Subjects-Per-Item Guidance module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same module contract as mod_pilot.R
# (docs/SDD.md #8) -- a rule-of-thumb calculator, not a hypothesis-test
# formula. See R/calc/calc_efa_cfa.R and R/content/content_efa_cfa.R.

efa_cfa_meta <- list(
  id = "efa_cfa",
  nav_title = "Psychometrics Sample Size Guidance"
)

mod_efa_cfa_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Rule-of-thumb (subjects-per-item)" = "rule_of_thumb",
          "RMSEA-based power (CFA/SEM test of close fit)" = "rmsea",
          "IRT item calibration (rule-of-thumb by model type)" = "irt_calibration"
        ),
        selected = "rule_of_thumb"
      ),
      conditionalPanel(
        condition = design_is("rule_of_thumb"),
        div(class = "alert alert-info",
            strong("Rule of thumb, not a formula: "),
            "there is no accepted power calculation for factor analysis sample ",
            "size -- these are published participant-to-item ratios, refined ",
            "over decades of practice, not a solved hypothesis test."),
        numericInput(ns("n_items"), "Number of items (EFA) or free parameters (CFA/SEM)",
                     value = 20, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("rmsea"),
        numericInput(ns("df_rmsea"), "Model degrees of freedom (df)", value = 20, min = 1, step = 1),
        numericInput(ns("rmsea0"), "RMSEA0 (null, e.g. 0.05 = \"close fit\")", value = 0.05, min = 0, step = 0.01),
        numericInput(ns("rmseaA"), "RMSEA_A (alternative, e.g. 0.08 = \"mediocre fit\")", value = 0.08, min = 0, step = 0.01),
        numericInput(ns("group_rmsea"), "Number of groups", value = 1, min = 1, step = 1),
        numericInput(ns("alpha_rmsea"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_rmsea"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("irt_calibration"),
        div(class = "alert alert-info",
            strong("Rule of thumb, not a formula: "),
            "there is no accepted power calculation for IRT item calibration -- ",
            "these are published minimum-N guidelines from Monte Carlo parameter-",
            "recovery studies, not a solved hypothesis test."),
        selectInput(
          ns("irt_model"), "IRT model",
          choices = c("Rasch / 1PL (difficulty only)" = "rasch_1pl",
                      "2PL (difficulty + discrimination)" = "twopl",
                      "3PL (+ guessing)" = "threepl",
                      "Polytomous (graded response / partial credit)" = "polytomous")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(efa_cfa_content$rule_of_thumb$title),
      render_formula_block(efa_cfa_content$rule_of_thumb$formula_latex),
      shiny::markdown(efa_cfa_content$rule_of_thumb$explanation),
      h5("Worked example"),
      shiny::markdown(efa_cfa_content$rule_of_thumb$worked_example),
      hr(),
      h4(efa_cfa_content$rmsea$title),
      render_formula_block(efa_cfa_content$rmsea$formula_latex),
      shiny::markdown(efa_cfa_content$rmsea$explanation),
      h5("Worked example"),
      shiny::markdown(efa_cfa_content$rmsea$worked_example),
      hr(),
      h4(efa_cfa_content$irt_calibration$title),
      render_formula_block(efa_cfa_content$irt_calibration$formula_latex),
      shiny::markdown(efa_cfa_content$irt_calibration$explanation),
      h5("Worked example"),
      shiny::markdown(efa_cfa_content$irt_calibration$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(efa_cfa_content$rule_of_thumb$title),
      p(strong("Citation: "), efa_cfa_content$rule_of_thumb$citation),
      p(strong("Implemented via: "), code(efa_cfa_content$rule_of_thumb$backend)),
      hr(),
      h4(efa_cfa_content$rmsea$title),
      p(strong("Citation: "), efa_cfa_content$rmsea$citation),
      p(strong("Implemented via: "), code(efa_cfa_content$rmsea$backend)),
      hr(),
      h4(efa_cfa_content$irt_calibration$title),
      p(strong("Citation: "), efa_cfa_content$irt_calibration$citation),
      p(strong("Implemented via: "), code(efa_cfa_content$irt_calibration$backend))
    )
  )
}

mod_efa_cfa_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "rule_of_thumb") {
        req(input$n_items)
        tryCatch(
          list(ok = TRUE, value = calc_efa_cfa_sample_size(n_items = input$n_items)),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "rmsea") {
        req(input$df_rmsea, input$rmsea0, input$rmseaA, input$group_rmsea,
            input$alpha_rmsea, input$power_rmsea)
        tryCatch(
          list(ok = TRUE, value = calc_sem_rmsea_samplesize(
            rmsea0 = input$rmsea0, rmseaA = input$rmseaA, df = input$df_rmsea,
            power = input$power_rmsea, alpha = input$alpha_rmsea, group = input$group_rmsea
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$irt_model)
        tryCatch(
          list(ok = TRUE, value = calc_irt_calibration_guidance(model = input$irt_model)),
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
      if (input$design == "rule_of_thumb") {
        tagList(
          tags$table(class = "table table-sm",
            tags$thead(tags$tr(tags$th("Ratio"), tags$th("Recommended N"), tags$th("Comrey & Lee (1992) label"))),
            tags$tbody(
              tags$tr(tags$td("5:1 (minimum)"), tags$td(v$n_5to1), tags$td(v$adjective_5to1)),
              tags$tr(tags$td("10:1 (commonly recommended)"), tags$td(v$n_10to1), tags$td(v$adjective_10to1)),
              tags$tr(tags$td("20:1 (more robust)"), tags$td(v$n_20to1), tags$td(v$adjective_20to1))
            )
          ),
          div(class = "text-muted small",
              "These ratios assume nothing else is known about expected communalities ",
              "or factor overdetermination -- see the Formula/Help tab's caveat ",
              "(MacCallum et al. 1999) before treating any of these as a firm target.")
        )
      } else if (input$design == "rmsea") {
        tagList(
          p(strong("Required total sample size: "), v$n),
          p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Conservative minimum N: "), v$n_minimum),
          p(strong("N for more precise/stable calibration: "), v$n_precise),
          div(class = "text-muted small", v$note)
        )
      }
    })

    render_export_handlers(output, result, function() efa_cfa_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): only "rmsea" has a power argument.
    # It scans candidate n one at a time (~0.31 s per call), so its curves
    # are click-gated with a short grid.
    render_power_curves(output, function() {
      if (input$design != "rmsea") return(NULL)
      req(input$df_rmsea, input$rmsea0, input$rmseaA, input$group_rmsea,
          input$alpha_rmsea, input$power_rmsea)
      list(
        calc_fn = calc_sem_rmsea_samplesize,
        args = list(rmsea0 = input$rmsea0, rmseaA = input$rmseaA, df = input$df_rmsea,
                     power = input$power_rmsea, alpha = input$alpha_rmsea, group = input$group_rmsea),
        effect = list(param = "rmseaA", values = curve_range_within(input$rmsea0, max(0.15, 1.5 * input$rmseaA), n = 10),
                      label = "RMSEA_A (alternative)"),
        power = list(param = "power", values = curve_range_power(n = 10)),
        gated = list(note = "Each point scans candidate sample sizes (~0.3 s), so these 20 points take about 10-12 seconds.")
      )
    }, input = input)
  })
}
