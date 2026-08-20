# Diagnostic Accuracy module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R / mod_means.R (docs/
# SDD.md #8): a `design` radioButtons()/conditionalPanel() switch across the
# four designs in Akoglu (2022) -- see R/calc/calc_diagnostic.R and
# R/content/content_diagnostic.R for the formulas and citations.

diagnostic_meta <- list(
  id = "diagnostic",
  nav_title = "Diagnostic Accuracy"
)

mod_diagnostic_ui <- function(id) {
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
          "Sensitivity & specificity - precision-based (no reference value)" = "precision",
          "Sensitivity & specificity vs. known/reference value (hypothesis test)" = "vs_reference",
          "Two independent (unpaired) diagnostic tests" = "two_indep",
          "Two paired diagnostic tests (same subjects)" = "two_paired"
        ),
        selected = "precision"
      ),
      conditionalPanel(
        condition = design_is("precision"),
        numericInput(ns("sens"), "Expected sensitivity (Sn)", value = 0.90, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec"), "Expected specificity (Sp)", value = 0.85, min = 0, max = 1, step = 0.01),
        numericInput(ns("prevalence"), "Expected prevalence of the target condition (P)",
                     value = 0.10, min = 0, max = 1, step = 0.01),
        numericInput(ns("prec_sens"), "Desired precision for sensitivity (W_Sn)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("prec_spec"), "Desired precision for specificity (W_Sp)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("conf_level"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("vs_reference"),
        numericInput(ns("sens0"), "Sn0 (reference/null sensitivity)", value = 0.90, min = 0, max = 1, step = 0.01),
        numericInput(ns("sens1"), "Sn1 (expected sensitivity of new test)", value = 0.95, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec0"), "Sp0 (reference/null specificity)", value = 0.80, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec1"), "Sp1 (expected specificity of new test)", value = 0.85, min = 0, max = 1, step = 0.01),
        numericInput(ns("prevalence_ref"), "Expected prevalence of the target condition (P)",
                     value = 0.40, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("two_indep"),
        numericInput(ns("p1_indep"), "P1 (test 1's expected Sn or Sp)", value = 0.80, min = 0, max = 1, step = 0.01),
        numericInput(ns("p2_indep"), "P2 (test 2's expected Sn or Sp)", value = 0.70, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("two_paired"),
        numericInput(ns("p1_paired"), "P1 (test 1's expected Sn or Sp)", value = 0.80, min = 0, max = 1, step = 0.01),
        numericInput(ns("p2_paired"), "P2 (test 2's expected Sn or Sp)", value = 0.70, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("vs_reference", "two_indep", "two_paired"),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(diagnostic_content$precision$title),
      withMathJax(HTML(diagnostic_content$precision$formula_latex)),
      shiny::markdown(diagnostic_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$precision$worked_example),
      hr(),
      h4(diagnostic_content$vs_reference$title),
      withMathJax(HTML(diagnostic_content$vs_reference$formula_latex)),
      shiny::markdown(diagnostic_content$vs_reference$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$vs_reference$worked_example),
      hr(),
      h4(diagnostic_content$two_indep$title),
      withMathJax(HTML(diagnostic_content$two_indep$formula_latex)),
      shiny::markdown(diagnostic_content$two_indep$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$two_indep$worked_example),
      hr(),
      h4(diagnostic_content$two_paired$title),
      withMathJax(HTML(diagnostic_content$two_paired$formula_latex)),
      shiny::markdown(diagnostic_content$two_paired$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$two_paired$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(diagnostic_content$precision$title),
      p(strong("Citation: "), diagnostic_content$precision$citation),
      p(strong("Implemented via: "), code(diagnostic_content$precision$backend)),
      hr(),
      h4(diagnostic_content$vs_reference$title),
      p(strong("Citation: "), diagnostic_content$vs_reference$citation),
      p(strong("Implemented via: "), code(diagnostic_content$vs_reference$backend)),
      hr(),
      h4(diagnostic_content$two_indep$title),
      p(strong("Citation: "), diagnostic_content$two_indep$citation),
      p(strong("Implemented via: "), code(diagnostic_content$two_indep$backend)),
      hr(),
      h4(diagnostic_content$two_paired$title),
      p(strong("Citation: "), diagnostic_content$two_paired$citation),
      p(strong("Implemented via: "), code(diagnostic_content$two_paired$backend))
    )
  )
}

mod_diagnostic_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "precision") {
        req(input$sens, input$spec, input$prevalence, input$prec_sens,
            input$prec_spec, input$conf_level)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_accuracy(
            sens = input$sens, spec = input$spec, prevalence = input$prevalence,
            prec_sens = input$prec_sens, prec_spec = input$prec_spec,
            conf_level = input$conf_level
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "vs_reference") {
        req(input$sens0, input$sens1, input$spec0, input$spec1,
            input$prevalence_ref, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_vs_reference(
            sens0 = input$sens0, sens1 = input$sens1,
            spec0 = input$spec0, spec1 = input$spec1,
            prevalence = input$prevalence_ref,
            alpha = input$alpha, power = input$power, alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "two_indep") {
        req(input$p1_indep, input$p2_indep, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_two_indep(
            p1 = input$p1_indep, p2 = input$p2_indep,
            alpha = input$alpha, power = input$power, alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p1_paired, input$p2_paired, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_two_paired(
            p1 = input$p1_paired, p2 = input$p2_paired,
            alpha = input$alpha, power = input$power, alternative = input$alternative
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
      if (input$design %in% c("precision", "vs_reference")) {
        tagList(
          p(strong("Required total sample size: "), v$n,
            sprintf(" (%s binds)", v$binding)),
          p(sprintf("Sensitivity requires n = %d; specificity requires n = %d", v$n_sens, v$n_spec)),
          p(sprintf("At this prevalence, that's ~%d diseased and ~%d non-diseased subjects",
                    v$n_diseased, v$n_healthy))
        )
      } else if (input$design == "two_indep") {
        tagList(
          p(strong("Required sample size per test/pathway: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total)
        )
      } else {
        tagList(
          p(strong("Sample size range: "), sprintf("%d (Psi_min) to %d (Psi_max)", v$n_min, v$n_max)),
          p(sprintf("Psi_min = %.4f, Psi_max = %.4f", v$psi_min, v$psi_max)),
          p("Choose based on how correlated you expect the two tests' results to be; ",
            "the upper bound is the conservative default.")
        )
      }
    })
  })
}
