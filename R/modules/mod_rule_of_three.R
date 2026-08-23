# Rule of Three module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8).
# Like Pilot/Feasibility, this is a closed-form rule-of-thumb tool, not a
# formal hypothesis-test power calculation.

rule_of_three_meta <- list(
  id = "rule_of_three",
  nav_title = "Rule of Three"
)

mod_rule_of_three_ui <- function(id) {
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
          "Upper bound on the true rate, given zero events observed" = "bound",
          "Sample size to detect at least one event" = "n_required"
        )
      ),
      conditionalPanel(
        condition = design_is("bound"),
        numericInput(ns("n"), "Subjects observed (with zero events seen)", value = 30, min = 1, step = 1),
        numericInput(ns("conf_level_bound"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("n_required"),
        numericInput(ns("p"), "Assumed true event rate", value = 0.01, min = 0.0001, max = 0.9999, step = 0.001),
        numericInput(ns("conf_level_n"), "Desired probability of observing >= 1 event", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(rule_of_three_content$bound$title),
      render_formula_block(rule_of_three_content$bound$formula_latex),
      shiny::markdown(rule_of_three_content$bound$explanation),
      h5("Worked example"),
      shiny::markdown(rule_of_three_content$bound$worked_example),
      hr(),
      h4(rule_of_three_content$n_required$title),
      render_formula_block(rule_of_three_content$n_required$formula_latex),
      shiny::markdown(rule_of_three_content$n_required$explanation),
      h5("Worked example"),
      shiny::markdown(rule_of_three_content$n_required$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(rule_of_three_content$bound$title),
      p(strong("Citation: "), rule_of_three_content$bound$citation),
      p(strong("Implemented via: "), code(rule_of_three_content$bound$backend)),
      hr(),
      h4(rule_of_three_content$n_required$title),
      p(strong("Citation: "), rule_of_three_content$n_required$citation),
      p(strong("Implemented via: "), code(rule_of_three_content$n_required$backend))
    )
  )
}

mod_rule_of_three_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "bound") {
        req(input$n, input$conf_level_bound)
        tryCatch(
          list(ok = TRUE, value = calc_rule_of_three_bound(
            n = input$n, conf_level = input$conf_level_bound
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p, input$conf_level_n)
        tryCatch(
          list(ok = TRUE, value = calc_rule_of_three_n(
            p = input$p, conf_level = input$conf_level_n
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
      if (input$design == "bound") {
        tagList(
          p(strong("Approximate upper bound (\"3/n\" rule): "), sprintf("%.4f", v$approx_bound)),
          p(strong("Exact upper bound: "), sprintf("%.4f", v$exact_bound))
        )
      } else {
        tagList(
          p(strong("Exact required sample size: "), v$n_exact),
          p(strong("Approximate (\"3/p\" rule): "), v$n_approx)
        )
      }
    })
  })
}
