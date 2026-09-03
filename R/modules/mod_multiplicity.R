# Multiplicity Adjustment module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same module contract as mod_means.R (docs/SDD.md
# #8) -- a "base test" radio selects which of this app's own already-
# verified formulas to re-run with a Bonferroni/Sidak-adjusted alpha.

multiplicity_meta <- list(
  id = "multiplicity",
  nav_title = "Multiplicity Adjustment"
)

mod_multiplicity_ui <- function(id) {
  ns <- NS(id)

  # See mod_proportion.R for why conditionalPanel() conditions are built
  # with ns() rather than hardcoded -- same reasoning applies here.
  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Base test to re-run with the adjusted alpha",
        choices = c(
          "One proportion vs. reference" = "proportion_1s",
          "Two independent proportions" = "proportion_2s",
          "One mean vs. reference" = "means_1s",
          "Two independent means" = "means_2s"
        ),
        selected = "proportion_2s"
      ),
      conditionalPanel(
        condition = design_is("proportion_1s"),
        numericInput(ns("p0"), "p0 (reference proportion)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p1_prop1s"), "p1 (expected proportion)", value = 0.65, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("proportion_2s"),
        numericInput(ns("p1"), "p1 (group 1 proportion)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2"), "p2 (group 2 proportion)", value = 0.65, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("means_1s"),
        numericInput(ns("mu0"), "mu0 (reference mean)", value = 0),
        numericInput(ns("mu1_means1s"), "mu1 (expected mean)", value = 0.5),
        numericInput(ns("sd_1s"), "sd (expected standard deviation)", value = 1, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("means_2s"),
        numericInput(ns("mu1_means2s"), "mu1 (group 1 mean)", value = 10),
        numericInput(ns("mu2_means2s"), "mu2 (group 2 mean)", value = 12),
        numericInput(ns("sd_2s"), "sd (common/pooled standard deviation)", value = 5, min = 0.0001)
      ),
      hr(),
      numericInput(ns("m"), "Number of planned simultaneous comparisons (m)", value = 4, min = 1, step = 1),
      radioButtons(
        ns("method"), "Correction method",
        choices = c("Bonferroni (always valid)" = "bonferroni",
                    "Sidak (exact under independence)" = "sidak"),
        selected = "bonferroni"
      ),
      numericInput(ns("alpha"), "Family-wise significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power (per comparison)", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(
        ns("alternative"), "Alternative hypothesis",
        choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(multiplicity_content$overview$title),
      render_formula_block(multiplicity_content$overview$formula_latex),
      shiny::markdown(multiplicity_content$overview$explanation),
      h5("Worked example"),
      shiny::markdown(multiplicity_content$overview$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(multiplicity_content$overview$title),
      p(strong("Citation: "), multiplicity_content$overview$citation),
      p(strong("Implemented via: "), code(multiplicity_content$overview$backend))
    )
  )
}

mod_multiplicity_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$m, input$method, input$alpha, input$power, input$alternative)
      tryCatch(
        list(ok = TRUE, value = switch(
          input$design,
          proportion_1s = {
            req(input$p0, input$p1_prop1s)
            calc_multiplicity_proportion_1s(
              p0 = input$p0, p1 = input$p1_prop1s, m = input$m, method = input$method,
              alpha = input$alpha, power = input$power, alternative = input$alternative
            )
          },
          proportion_2s = {
            req(input$p1, input$p2)
            calc_multiplicity_proportion_2s(
              p1 = input$p1, p2 = input$p2, m = input$m, method = input$method,
              alpha = input$alpha, power = input$power, alternative = input$alternative
            )
          },
          means_1s = {
            req(input$mu0, input$mu1_means1s, input$sd_1s)
            calc_multiplicity_means_1s(
              mu0 = input$mu0, mu1 = input$mu1_means1s, sd = input$sd_1s, m = input$m,
              method = input$method, alpha = input$alpha, power = input$power,
              alternative = input$alternative
            )
          },
          means_2s = {
            req(input$mu1_means2s, input$mu2_means2s, input$sd_2s)
            calc_multiplicity_means_2s(
              mu1 = input$mu1_means2s, mu2 = input$mu2_means2s, sd = input$sd_2s, m = input$m,
              method = input$method, alpha = input$alpha, power = input$power,
              alternative = input$alternative
            )
          }
        )),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      n_line <- if (!is.null(v$n_total)) {
        p(strong("Required sample size: "), v$n_per_group, " per group (", v$n_total, " total)")
      } else {
        p(strong("Required total sample size: "), v$n)
      }
      tagList(
        n_line,
        p(sprintf("Adjusted per-comparison alpha = %.5f (from family-wise alpha = %.3f, m = %d, %s)",
                   v$alpha_adjusted, v$inputs$alpha_family, v$m, v$method))
      )
    })
  })
}
