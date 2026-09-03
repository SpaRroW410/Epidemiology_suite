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
          "Two paired diagnostic tests (same subjects)" = "two_paired",
          "Predictive values (PPV/NPV), precision-based" = "ppv_npv",
          "Likelihood ratios (LR+/LR-), precision-based" = "likelihood_ratio",
          "Diagnostic odds ratio (DOR)" = "odds_ratio"
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
        condition = design_is("ppv_npv"),
        numericInput(ns("sens_ppv"), "Expected sensitivity (Sn)", value = 0.90, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec_ppv"), "Expected specificity (Sp)", value = 0.85, min = 0, max = 1, step = 0.01),
        numericInput(ns("prevalence_ppv"), "Expected prevalence of the target condition (P)",
                     value = 0.20, min = 0, max = 1, step = 0.01),
        numericInput(ns("prec_ppv"), "Desired precision for PPV (W_PPV)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("prec_npv"), "Desired precision for NPV (W_NPV)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("conf_level_ppv"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("likelihood_ratio"),
        numericInput(ns("sens_lr"), "Expected sensitivity (Sn)", value = 0.80, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec_lr"), "Expected specificity (Sp)", value = 0.73, min = 0, max = 1, step = 0.01),
        numericInput(ns("prevalence_lr"), "Expected prevalence of the target condition (P)",
                     value = 0.50, min = 0, max = 1, step = 0.01),
        selectInput(ns("lr_type"), "Likelihood ratio type",
                    choices = c("Positive (LR+)" = "positive", "Negative (LR-)" = "negative")),
        numericInput(ns("conf_width_lr"), "Desired CI width for the LR", value = 2.2, min = 0.01, step = 0.1),
        numericInput(ns("conf_level_lr"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("odds_ratio"),
        numericInput(ns("sens_dor"), "Expected sensitivity (Sn)", value = 0.80, min = 0, max = 1, step = 0.01),
        numericInput(ns("spec_dor"), "Expected specificity (Sp)", value = 0.70, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("vs_reference", "two_indep", "two_paired", "odds_ratio"),
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
      div(class = "text-muted mb-3",
          strong("No gold standard available? "),
          "All four designs below assume a reference/gold-standard test",
          "exists (even if the true disease status is only established",
          "later, e.g. by surgery or follow-up). If there is no reference",
          "standard at all -- you only have two raters or methods being",
          "compared to each other -- see the ",
          strong("Agreement / Reliability"), " tab instead (Cohen's kappa",
          "for categorical ratings, or ICC for continuous measurements)."),
      h4(diagnostic_content$precision$title),
      render_formula_block(diagnostic_content$precision$formula_latex),
      shiny::markdown(diagnostic_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$precision$worked_example),
      hr(),
      h4(diagnostic_content$vs_reference$title),
      render_formula_block(diagnostic_content$vs_reference$formula_latex),
      shiny::markdown(diagnostic_content$vs_reference$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$vs_reference$worked_example),
      hr(),
      h4(diagnostic_content$two_indep$title),
      render_formula_block(diagnostic_content$two_indep$formula_latex),
      shiny::markdown(diagnostic_content$two_indep$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$two_indep$worked_example),
      hr(),
      h4(diagnostic_content$two_paired$title),
      render_formula_block(diagnostic_content$two_paired$formula_latex),
      shiny::markdown(diagnostic_content$two_paired$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$two_paired$worked_example),
      hr(),
      h4(diagnostic_content$ppv_npv$title),
      render_formula_block(diagnostic_content$ppv_npv$formula_latex),
      shiny::markdown(diagnostic_content$ppv_npv$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$ppv_npv$worked_example),
      hr(),
      h4(diagnostic_content$likelihood_ratio$title),
      render_formula_block(diagnostic_content$likelihood_ratio$formula_latex),
      shiny::markdown(diagnostic_content$likelihood_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$likelihood_ratio$worked_example),
      hr(),
      h4(diagnostic_content$odds_ratio$title),
      render_formula_block(diagnostic_content$odds_ratio$formula_latex),
      shiny::markdown(diagnostic_content$odds_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$odds_ratio$worked_example)
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
      p(strong("Implemented via: "), code(diagnostic_content$two_paired$backend)),
      hr(),
      h4(diagnostic_content$ppv_npv$title),
      p(strong("Citation: "), diagnostic_content$ppv_npv$citation),
      p(strong("Implemented via: "), code(diagnostic_content$ppv_npv$backend)),
      hr(),
      h4(diagnostic_content$likelihood_ratio$title),
      p(strong("Citation: "), diagnostic_content$likelihood_ratio$citation),
      p(strong("Implemented via: "), code(diagnostic_content$likelihood_ratio$backend)),
      hr(),
      h4(diagnostic_content$odds_ratio$title),
      p(strong("Citation: "), diagnostic_content$odds_ratio$citation),
      p(strong("Implemented via: "), code(diagnostic_content$odds_ratio$backend))
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
      } else if (input$design == "two_paired") {
        req(input$p1_paired, input$p2_paired, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_two_paired(
            p1 = input$p1_paired, p2 = input$p2_paired,
            alpha = input$alpha, power = input$power, alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "ppv_npv") {
        req(input$sens_ppv, input$spec_ppv, input$prevalence_ppv,
            input$prec_ppv, input$prec_npv, input$conf_level_ppv)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_ppv_npv(
            sens = input$sens_ppv, spec = input$spec_ppv, prevalence = input$prevalence_ppv,
            prec_ppv = input$prec_ppv, prec_npv = input$prec_npv, conf_level = input$conf_level_ppv
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "likelihood_ratio") {
        req(input$sens_lr, input$spec_lr, input$prevalence_lr, input$lr_type,
            input$conf_width_lr, input$conf_level_lr)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_likelihood_ratio(
            sens = input$sens_lr, spec = input$spec_lr, prevalence = input$prevalence_lr,
            type = input$lr_type, conf_width = input$conf_width_lr, conf_level = input$conf_level_lr
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$sens_dor, input$spec_dor, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_diagnostic_odds_ratio(
            sens = input$sens_dor, spec = input$spec_dor,
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
      } else if (input$design == "two_paired") {
        tagList(
          p(strong("Sample size range: "), sprintf("%d (Psi_min) to %d (Psi_max)", v$n_min, v$n_max)),
          p(sprintf("Psi_min = %.4f, Psi_max = %.4f", v$psi_min, v$psi_max)),
          p("Choose based on how correlated you expect the two tests' results to be; ",
            "the upper bound is the conservative default.")
        )
      } else if (input$design == "ppv_npv") {
        tagList(
          p(strong("Required total sample size: "), v$n,
            sprintf(" (%s binds)", v$binding)),
          p(sprintf("PPV requires n = %d; NPV requires n = %d", v$n_ppv, v$n_npv)),
          p(sprintf("PPV = %.4f, NPV = %.4f at these inputs", v$ppv, v$npv))
        )
      } else if (input$design == "likelihood_ratio") {
        tagList(
          p(strong("Required total sample size: "), v$n),
          p(sprintf("Diseased: %d, Non-diseased: %d", v$n_diseased, v$n_healthy)),
          p(sprintf("LR = %.4f, expected CI [%.4f, %.4f]", v$lr, v$lwr, v$upr))
        )
      } else {
        tagList(
          p(strong("Required sample size, diseased group: "), v$n_diseased),
          p(strong("Required sample size, non-diseased group: "), v$n_healthy),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Diagnostic odds ratio (DOR) = %.4f", v$dor))
        )
      }
    })
  })
}
