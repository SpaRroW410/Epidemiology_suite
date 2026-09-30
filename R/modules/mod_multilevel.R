# Multilevel / Hierarchical Model module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same design-radio pattern as
# mod_variance.R (docs/SDD.md #8) -- two-level (subjects with repeated
# measures) and three-level (subjects nested in clusters) designs.

multilevel_meta <- list(
  id = "multilevel",
  nav_title = "Multilevel / Hierarchical Model"
)

mod_multilevel_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Two-level (subjects, repeated measures)" = "two_level",
          "Three-level (subjects nested in clusters)" = "three_level"
        ),
        selected = "two_level"
      ),
      numericInput(ns("n1"), "Number of measurement occasions (n1)", value = 11, min = 2, step = 1),
      numericInput(ns("T_end"), "Study duration (T_end)", value = 10, min = 0.0001, step = 1),
      numericInput(ns("var_ratio"), "Slope variance ratio (var_ratio)", value = 0.02, min = 0.0001, step = 0.01),
      conditionalPanel(
        condition = design_is("three_level"),
        numericInput(ns("n2"), "Subjects per cluster (n2)", value = 10, min = 1, step = 1),
        numericInput(ns("icc_slope"), "Slope ICC (fraction of slope variance that is between-cluster)",
                     value = 0.1, min = 0, max = 0.999, step = 0.05)
      ),
      numericInput(ns("delta"), "Expected difference between arms by end of study (delta)", value = -0.9, step = 0.1),
      numericInput(ns("sigma_error"), "Residual (single-occasion) SD (sigma_error)", value = 10, min = 0.0001, step = 1),
      hr(),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      shiny::markdown(multilevel_content$shared$explanation),
      hr(),
      h4(multilevel_content$two_level$title),
      render_formula_block(multilevel_content$two_level$formula_latex),
      hr(),
      h4(multilevel_content$three_level$title),
      render_formula_block(multilevel_content$three_level$formula_latex),
      hr(),
      h5("Worked example"),
      shiny::markdown(multilevel_content$shared$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), multilevel_content$shared$citation),
      p(strong("Implemented via: "), code(multilevel_content$two_level$backend))
    )
  )
}

mod_multilevel_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$n1, input$T_end, input$var_ratio, input$delta,
          input$sigma_error, input$alpha, input$power)

      tryCatch({
        value <- if (input$design == "two_level") {
          calc_multilevel_two_level(
            n1 = input$n1, T_end = input$T_end, var_ratio = input$var_ratio,
            delta = input$delta, sigma_error = input$sigma_error,
            alpha = input$alpha, power = input$power
          )
        } else {
          req(input$n2, input$icc_slope)
          calc_multilevel_three_level(
            n1 = input$n1, n2 = input$n2, T_end = input$T_end, var_ratio = input$var_ratio,
            icc_slope = input$icc_slope, delta = input$delta, sigma_error = input$sigma_error,
            alpha = input$alpha, power = input$power
          )
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (res$design == "two_level") {
        tagList(
          p(strong("Required sample size per arm: "), v$n_per_arm),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required clusters per arm: "), v$n_clusters_per_arm),
          p(sprintf("Total clusters: %d (%d subjects per arm, %d total)",
                     v$n_total_clusters, v$n_clusters_per_arm * v$n_subjects_per_cluster,
                     v$n_total_subjects)),
          p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
        )
      }
    })

    # multilevel_content's per-design entries carry title/backend but not
    # citation -- that's on the shared entry (see mod_tsa.R/mod_evpi.R for
    # the same shape).
    render_export_handlers(output, result, function() {
      modifyList(multilevel_content[[input$design]], list(citation = multilevel_content$shared$citation))
    })
  })
}
