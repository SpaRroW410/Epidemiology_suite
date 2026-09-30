# ROC / AUC module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the design-radio pattern (docs/SDD.md #8) -- single-AUC-vs-
# chance and compare-two-correlated-AUCs designs.

roc_meta <- list(
  id = "roc",
  nav_title = "ROC / AUC"
)

mod_roc_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  include_partial_auc_is_true <- sprintf("input['%s']", ns("include_partial_auc"))

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single AUC vs. chance (0.5)" = "single_auc",
          "Compare two correlated (paired) AUCs" = "compare_two"
        )
      ),
      conditionalPanel(
        condition = design_is("single_auc"),
        numericInput(ns("auc"), "Expected AUC", value = 0.73, min = 0.501, max = 0.999, step = 0.01),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("kappa"), "Ratio of controls to cases (kappa)", value = 1.7, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("compare_two"),
        numericInput(ns("A1"), "Curve 1: binormal A parameter", value = 2.6, step = 0.1),
        numericInput(ns("B1"), "Curve 1: binormal B parameter", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("A2"), "Curve 2: binormal A parameter", value = 1.9, step = 0.1),
        numericInput(ns("B2"), "Curve 2: binormal B parameter", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("rn"), "Correlation between tests in controls (rn)", value = 0.6, min = -0.999, max = 0.999, step = 0.01),
        numericInput(ns("ra"), "Correlation between tests in cases (ra)", value = 0.6, min = -0.999, max = 0.999, step = 0.01),
        numericInput(ns("delta_compare"), "AUC difference to detect (delta)", value = 0.037, step = 0.001),
        numericInput(ns("alpha_compare"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_compare"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("kappa_compare"), "Ratio of controls to cases (kappa)", value = 1, min = 0.1, step = 0.1),
        checkboxInput(ns("include_partial_auc"), "Restrict to a partial AUC (false-positive-rate range)", value = FALSE),
        conditionalPanel(
          condition = include_partial_auc_is_true,
          numericInput(ns("fpr12"), "Curve 1: FPR upper bound", value = 0.2, min = 0, max = 1, step = 0.01),
          numericInput(ns("fpr11"), "Curve 1: FPR lower bound", value = 0, min = 0, max = 1, step = 0.01),
          numericInput(ns("fpr22"), "Curve 2: FPR upper bound", value = 0.2, min = 0, max = 1, step = 0.01),
          numericInput(ns("fpr21"), "Curve 2: FPR lower bound", value = 0, min = 0, max = 1, step = 0.01)
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(roc_content$single_auc$title),
      render_formula_block(roc_content$single_auc$formula_latex),
      shiny::markdown(roc_content$single_auc$explanation),
      h5("Worked example"),
      shiny::markdown(roc_content$single_auc$worked_example),
      hr(),
      h4(roc_content$compare_two_aucs$title),
      render_formula_block(roc_content$compare_two_aucs$formula_latex),
      shiny::markdown(roc_content$compare_two_aucs$explanation),
      h5("Worked example"),
      shiny::markdown(roc_content$compare_two_aucs$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(roc_content$single_auc$title),
      p(strong("Citation: "), roc_content$single_auc$citation),
      p(strong("Implemented via: "), code(roc_content$single_auc$backend)),
      hr(),
      h4(roc_content$compare_two_aucs$title),
      p(strong("Citation: "), roc_content$compare_two_aucs$citation),
      p(strong("Implemented via: "), code(roc_content$compare_two_aucs$backend))
    )
  )
}

mod_roc_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "single_auc") {
        req(input$auc, input$alpha, input$power, input$kappa)
        tryCatch(
          list(ok = TRUE, value = calc_roc_auc(
            auc = input$auc, alpha = input$alpha, power = input$power, kappa = input$kappa
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$A1, input$B1, input$A2, input$B2, input$rn, input$ra, input$delta_compare,
            input$alpha_compare, input$power_compare, input$kappa_compare)
        fpr_args <- list(fpr11 = NULL, fpr12 = NULL, fpr21 = NULL, fpr22 = NULL)
        if (isTRUE(input$include_partial_auc)) {
          req(input$fpr11, input$fpr12, input$fpr21, input$fpr22)
          fpr_args <- list(fpr11 = input$fpr11, fpr12 = input$fpr12,
                            fpr21 = input$fpr21, fpr22 = input$fpr22)
        }
        tryCatch(
          list(ok = TRUE, value = do.call(calc_compare_two_aucs, c(
            list(A1 = input$A1, B1 = input$B1, A2 = input$A2, B2 = input$B2,
                 rn = input$rn, ra = input$ra, delta = input$delta_compare,
                 alpha = input$alpha_compare, power = input$power_compare, kappa = input$kappa_compare),
            fpr_args
          ))),
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
      tagList(
        p(strong("Required cases (diseased): "), v$n_cases),
        p(strong("Required controls (non-diseased): "), v$n_controls),
        p(strong("Total sample size: "), v$n_total)
      )
    })

    render_export_handlers(output, result, function() {
      key <- input$design
      remap <- c("compare_two" = "compare_two_aucs")
      roc_content[[if (key %in% names(remap)) remap[[key]] else key]]
    })
  })
}
