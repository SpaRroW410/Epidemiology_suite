# Non-Inferiority module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_proportion.R (docs/SDD.md #8).

noninferiority_meta <- list(
  id = "noninferiority",
  nav_title = "Non-Inferiority"
)

mod_noninferiority_ui <- function(id) {
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
          "Two means" = "means",
          "Two proportions" = "proportions",
          "Odds ratio" = "odds_ratio",
          "Hazard ratio (Cox PH)" = "hazard_ratio"
        )
      ),
      conditionalPanel(
        condition = design_is("means"),
        numericInput(ns("mean_new"), "Expected mean, new-treatment group", value = 0.20),
        numericInput(ns("mean_standard"), "Expected mean, standard-treatment group", value = 0.20),
        numericInput(ns("sd"), "Expected standard deviation", value = 0.10, min = 0.0001),
        numericInput(ns("margin"), "Non-inferiority margin (> 0)", value = 0.05, min = 0.0001),
        numericInput(ns("alpha"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio"), "Allocation ratio (new : standard)", value = 1, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("proportions"),
        numericInput(ns("p_new"), "p (new-treatment group proportion)", value = 0.85, min = 0, max = 1, step = 0.01),
        numericInput(ns("p_standard"), "p (standard-treatment group proportion)", value = 0.65, min = 0, max = 1, step = 0.01),
        numericInput(ns("margin_prop"), "Non-inferiority margin (0-1)", value = 0.10, min = 0.001, max = 0.99, step = 0.01),
        numericInput(ns("alpha_prop"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_prop"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio_prop"), "Allocation ratio (new : standard)", value = 1, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("odds_ratio"),
        numericInput(ns("pt_or"), "pt (probability of outcome, test/new-treatment group)",
                     value = 0.4, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("pc_or"), "pc (probability of outcome, control/standard group)",
                     value = 0.25, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("margin_or"), "Non-inferiority margin (log-odds-ratio scale)", value = 0.2, step = 0.05),
        numericInput(ns("k_or"), "Allocation ratio (k = n_test/n_control)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("alpha_or"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_or"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("hazard_ratio"),
        numericInput(ns("hr_val"), "Expected hazard ratio (treatment vs. control)", value = 2, min = 0.001, step = 0.1),
        numericInput(ns("margin_hr"), "Non-inferiority margin (log-hazard-ratio scale)", value = 0.5, step = 0.05),
        numericInput(ns("p1_hr"), "p1 (proportion allocated to treatment)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("d_hr"), "d (probability of observing an event)", value = 0.8, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("alpha_hr"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_hr"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(noninferiority_content$means$title),
      render_formula_block(noninferiority_content$means$formula_latex),
      shiny::markdown(noninferiority_content$means$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$means$worked_example),
      hr(),
      h4(noninferiority_content$proportions$title),
      render_formula_block(noninferiority_content$proportions$formula_latex),
      shiny::markdown(noninferiority_content$proportions$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$proportions$worked_example),
      hr(),
      h4(noninferiority_content$odds_ratio$title),
      render_formula_block(noninferiority_content$odds_ratio$formula_latex),
      shiny::markdown(noninferiority_content$odds_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$odds_ratio$worked_example),
      hr(),
      h4(noninferiority_content$hazard_ratio$title),
      render_formula_block(noninferiority_content$hazard_ratio$formula_latex),
      shiny::markdown(noninferiority_content$hazard_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$hazard_ratio$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(noninferiority_content$means$title),
      p(strong("Citation: "), noninferiority_content$means$citation),
      p(strong("Implemented via: "), code(noninferiority_content$means$backend)),
      hr(),
      h4(noninferiority_content$proportions$title),
      p(strong("Citation: "), noninferiority_content$proportions$citation),
      p(strong("Implemented via: "), code(noninferiority_content$proportions$backend)),
      hr(),
      h4(noninferiority_content$odds_ratio$title),
      p(strong("Citation: "), noninferiority_content$odds_ratio$citation),
      p(strong("Implemented via: "), code(noninferiority_content$odds_ratio$backend)),
      hr(),
      h4(noninferiority_content$hazard_ratio$title),
      p(strong("Citation: "), noninferiority_content$hazard_ratio$citation),
      p(strong("Implemented via: "), code(noninferiority_content$hazard_ratio$backend))
    )
  )
}

mod_noninferiority_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "means") {
        req(input$mean_new, input$mean_standard, input$sd, input$margin,
            input$alpha, input$power, input$ratio)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_means(
            mean_new = input$mean_new, mean_standard = input$mean_standard,
            sd = input$sd, margin = input$margin,
            alpha = input$alpha, power = input$power, ratio = input$ratio
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "proportions") {
        req(input$p_new, input$p_standard, input$margin_prop, input$alpha_prop,
            input$power_prop, input$ratio_prop)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_proportions(
            p_new = input$p_new, p_standard = input$p_standard, margin = input$margin_prop,
            alpha = input$alpha_prop, power = input$power_prop, ratio = input$ratio_prop
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "odds_ratio") {
        req(input$pt_or, input$pc_or, input$margin_or, input$k_or, input$alpha_or, input$power_or)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_or(
            pt = input$pt_or, pc = input$pc_or, margin = input$margin_or,
            k = input$k_or, alpha = input$alpha_or, power = input$power_or
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$hr_val, input$margin_hr, input$p1_hr, input$d_hr, input$alpha_hr, input$power_hr)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_hr(
            hr = input$hr_val, margin = input$margin_hr, p1 = input$p1_hr,
            d = input$d_hr, alpha = input$alpha_hr, power = input$power_hr
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
      if (input$design %in% c("means", "proportions")) {
        tagList(
          p(strong("Required sample size, new group: "), v$n_new),
          p(strong("Required sample size, standard group: "), v$n_standard),
          p(strong("Total sample size: "), v$n_total)
        )
      } else if (input$design == "odds_ratio") {
        tagList(
          p(strong("Required sample size, test group: "), v$n_test),
          p(strong("Required sample size, control group: "), v$n_control),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Implied odds ratio: %.4f", v$or))
        )
      } else {
        p(strong("Required total sample size: "), v$n)
      }
    })

    render_export_handlers(output, result, function() noninferiority_content[[input$design]])
  })
}
