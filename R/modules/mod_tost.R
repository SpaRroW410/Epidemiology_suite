# TOST Equivalence module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_proportion.R (docs/SDD.md #8).

tost_meta <- list(
  id = "tost",
  nav_title = "Equivalence (TOST)"
)

mod_tost_ui <- function(id) {
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
          "Bioequivalence crossover" = "bioequivalence",
          "Bioequivalence crossover, expected power (assurance)" = "assurance"
        )
      ),
      conditionalPanel(
        condition = design_is("means"),
        numericInput(ns("mean_diff"), "Expected difference in means (test - reference)", value = 0.5),
        numericInput(ns("margin"), "Equivalence margin (+/-)", value = 2, min = 0.0001),
        numericInput(ns("sd"), "Common/pooled standard deviation", value = 5, min = 0.0001),
        numericInput(ns("alpha"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("proportions"),
        numericInput(ns("p_new"), "p (new-treatment group proportion)", value = 0.50, min = 0, max = 1, step = 0.01),
        numericInput(ns("p_standard"), "p (standard-treatment group proportion)", value = 0.50, min = 0, max = 1, step = 0.01),
        numericInput(ns("margin_prop"), "Equivalence margin (+/-, on the proportion scale)", value = 0.20, min = 0.001, max = 0.99, step = 0.01),
        numericInput(ns("alpha_prop"), "Significance level, one-sided (alpha)", value = 0.10, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_prop"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio_prop"), "Allocation ratio (new : standard)", value = 1, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("bioequivalence"),
        numericInput(ns("cv_be"), "Intra-subject CV (log scale, e.g. 0.3 for 30%)",
                     value = 0.3, min = 0.001, step = 0.01),
        numericInput(ns("theta0_be"), "Assumed true test/reference ratio (theta0)",
                     value = 0.95, min = 0.001, step = 0.01),
        numericInput(ns("theta1_be"), "Lower bioequivalence limit (theta1)", value = 0.8, min = 0.001, step = 0.01),
        numericInput(ns("theta2_be"), "Upper bioequivalence limit (theta2)", value = 1.25, min = 0.001, step = 0.01),
        numericInput(ns("alpha_be"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_be"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("design_be"), "Crossover design", choices = c(
          "2x2 (classical crossover)" = "2x2",
          "2x2x4 (full replicate)" = "2x2x4",
          "2x3x3 (partial replicate)" = "2x3x3"
        ))
      ),
      conditionalPanel(
        condition = design_is("assurance"),
        numericInput(ns("cv_as"), "Intra-subject CV estimate (log scale, e.g. 0.3 for 30%)",
                     value = 0.3, min = 0.001, step = 0.01),
        numericInput(ns("prior_n_as"), "Prior/pilot study size (m subjects) that estimated the CV",
                     value = 30, min = 4, step = 1),
        numericInput(ns("theta0_as"), "Assumed true test/reference ratio (theta0)",
                     value = 0.95, min = 0.001, step = 0.01),
        numericInput(ns("theta1_as"), "Lower bioequivalence limit (theta1)", value = 0.8, min = 0.001, step = 0.01),
        numericInput(ns("theta2_as"), "Upper bioequivalence limit (theta2)", value = 1.25, min = 0.001, step = 0.01),
        numericInput(ns("alpha_as"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_as"), "Desired EXPECTED power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("design_as"), "Crossover design (prior study and planned study)", choices = c(
          "2x2 (classical crossover)" = "2x2",
          "2x2x4 (full replicate)" = "2x2x4",
          "2x3x3 (partial replicate)" = "2x3x3"
        ))
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(tost_content$means$title),
      render_formula_block(tost_content$means$formula_latex),
      shiny::markdown(tost_content$means$explanation),
      h5("Worked example"),
      shiny::markdown(tost_content$means$worked_example),
      hr(),
      h4(tost_content$proportions$title),
      render_formula_block(tost_content$proportions$formula_latex),
      shiny::markdown(tost_content$proportions$explanation),
      h5("Worked example"),
      shiny::markdown(tost_content$proportions$worked_example),
      hr(),
      h4(tost_content$bioequivalence$title),
      render_formula_block(tost_content$bioequivalence$formula_latex),
      shiny::markdown(tost_content$bioequivalence$explanation),
      h5("Worked example"),
      shiny::markdown(tost_content$bioequivalence$worked_example),
      hr(),
      h4(tost_content$assurance$title),
      render_formula_block(tost_content$assurance$formula_latex),
      shiny::markdown(tost_content$assurance$explanation),
      h5("Worked example"),
      shiny::markdown(tost_content$assurance$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(tost_content$means$title),
      p(strong("Citation: "), tost_content$means$citation),
      p(strong("Implemented via: "), code(tost_content$means$backend)),
      hr(),
      h4(tost_content$proportions$title),
      p(strong("Citation: "), tost_content$proportions$citation),
      p(strong("Implemented via: "), code(tost_content$proportions$backend)),
      hr(),
      h4(tost_content$bioequivalence$title),
      p(strong("Citation: "), tost_content$bioequivalence$citation),
      p(strong("Implemented via: "), code(tost_content$bioequivalence$backend)),
      hr(),
      h4(tost_content$assurance$title),
      p(strong("Citation: "), tost_content$assurance$citation),
      p(strong("Implemented via: "), code(tost_content$assurance$backend))
    )
  )
}

mod_tost_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "means") {
        req(input$mean_diff, input$margin, input$sd, input$alpha, input$power)
        tryCatch(
          list(ok = TRUE, value = calc_tost_means(
            mean_diff = input$mean_diff, margin = input$margin, sd = input$sd,
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "proportions") {
        req(input$p_new, input$p_standard, input$margin_prop, input$alpha_prop,
            input$power_prop, input$ratio_prop)
        tryCatch(
          list(ok = TRUE, value = calc_tost_proportions(
            p_new = input$p_new, p_standard = input$p_standard, margin = input$margin_prop,
            alpha = input$alpha_prop, power = input$power_prop, ratio = input$ratio_prop
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "bioequivalence") {
        req(input$cv_be, input$theta0_be, input$theta1_be, input$theta2_be,
            input$alpha_be, input$power_be, input$design_be)
        tryCatch(
          list(ok = TRUE, value = calc_tost_bioequivalence(
            cv = input$cv_be, theta0 = input$theta0_be, theta1 = input$theta1_be,
            theta2 = input$theta2_be, alpha = input$alpha_be, power = input$power_be,
            design = input$design_be
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$cv_as, input$prior_n_as, input$theta0_as, input$theta1_as, input$theta2_as,
            input$alpha_as, input$power_as, input$design_as)
        tryCatch(
          list(ok = TRUE, value = calc_tost_assurance(
            cv = input$cv_as, prior_n = input$prior_n_as, theta0 = input$theta0_as,
            theta1 = input$theta1_as, theta2 = input$theta2_as,
            alpha = input$alpha_as, power = input$power_as, design = input$design_as
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
      if (input$design == "means") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
        )
      } else if (input$design == "proportions") {
        tagList(
          p(strong("Required sample size, new group: "), v$n_new),
          p(strong("Required sample size, standard group: "), v$n_standard),
          p(strong("Total sample size: "), v$n_total)
        )
      } else if (input$design == "bioequivalence") {
        tagList(
          p(strong("Required total sample size: "), v$n_total),
          p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required total sample size: "), v$n_total),
          p(sprintf("Achieved EXPECTED power at this n: %.4f", v$achieved_expected_power))
        )
      }
    })

    render_export_handlers(output, result, function() tost_content[[input$design]])
  })
}
