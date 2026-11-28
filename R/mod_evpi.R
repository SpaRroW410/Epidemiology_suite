# Value of Information (EVPI/EVSI) module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same design-radio pattern as
# mod_variance.R (docs/SDD.md #8) -- EVPI (a bound on the value of any
# future research) vs. EVSI/ENBS (the value, and optimal size, of a
# specific proposed study).

evpi_meta <- list(
  id = "evpi",
  nav_title = "Value of Information (EVPI/EVSI)"
)

mod_evpi_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "EVPI (value of perfect information)" = "evpi",
          "EVSI / optimal sample size (ENBS)" = "evsi"
        ),
        selected = "evpi"
      ),
      numericInput(ns("mean_inb"), "Mean incremental net benefit (mean_inb)", value = 1000, step = 100),
      numericInput(ns("sd_inb"), "SD of incremental net benefit (sd_inb)", value = 3000, min = 0.0001, step = 100),
      numericInput(ns("population"), "Population (current + future patients over the decision horizon)",
                   value = 1, min = 1, step = 1),
      conditionalPanel(
        condition = design_is("evsi"),
        numericInput(ns("sampling_sd"), "Per-patient outcome SD in the proposed study (sampling_sd)",
                     value = 8000, min = 0.0001, step = 100),
        numericInput(ns("cost_per_patient"), "Cost per patient sampled", value = 500, min = 0.0001, step = 50),
        numericInput(ns("fixed_cost"), "Fixed cost of running the study", value = 0, min = 0, step = 1000),
        numericInput(ns("n_max"), "Maximum sample size to consider", value = 100000, min = 10, step = 1000)
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
      shiny::markdown(evpi_content$shared$explanation),
      hr(),
      h4(evpi_content$evpi$title),
      render_formula_block(evpi_content$evpi$formula_latex),
      hr(),
      h4(evpi_content$evsi$title),
      render_formula_block(evpi_content$evsi$formula_latex),
      hr(),
      h5("Worked example"),
      shiny::markdown(evpi_content$shared$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), evpi_content$shared$citation),
      p(strong("Implemented via: "), code(evpi_content$evpi$backend))
    )
  )
}

mod_evpi_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$mean_inb, input$sd_inb, input$population)

      tryCatch({
        value <- if (input$design == "evpi") {
          calc_evpi_normal(mean_inb = input$mean_inb, sd_inb = input$sd_inb, population = input$population)
        } else {
          req(input$sampling_sd, input$cost_per_patient, input$fixed_cost, input$n_max)
          calc_enbs_optimal_n(
            mean_inb = input$mean_inb, sd_inb = input$sd_inb, sampling_sd = input$sampling_sd,
            cost_per_patient = input$cost_per_patient, population = input$population,
            fixed_cost = input$fixed_cost, n_max = input$n_max
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
      if (res$design == "evpi") {
        tagList(
          p(strong("EVPI per patient: "), signif(v$evpi_per_patient, 4)),
          p(strong("Population EVPI: "), signif(v$evpi_population, 4)),
          p(class = "text-muted",
            "This is the maximum possible value of ANY future research -- no real (finite) study can be worth more.")
        )
      } else {
        boundary_note <- if (v$at_search_boundary) {
          p(class = "text-danger",
            "The optimum sits at your maximum sample size -- more sampling is still worthwhile at this cap. Consider raising n_max.")
        } else {
          NULL
        }
        tagList(
          p(strong("Recommended (ENBS-optimal) sample size: "), v$n_optimal),
          p(strong("Expected net benefit of sampling at this size: "), signif(v$enbs_at_optimal, 4)),
          p(strong("EVSI at this size (population-scaled): "), signif(v$evsi_at_optimal, 4)),
          p(strong("Population EVPI (upper bound for comparison): "), signif(v$evpi_population, 4)),
          boundary_note
        )
      }
    })

    # evpi_content's per-design entries carry title/backend but not
    # citation -- that's on the shared entry (see the Reference tab above,
    # and mod_tsa.R/mod_multilevel.R for the same shape).
    render_export_handlers(output, result, function() {
      modifyList(evpi_content[[input$design]], list(citation = evpi_content$shared$citation))
    })

    # Curves (ROADMAP P1 item 10): only the EVSI/ENBS design returns a sample
    # size (the ENBS-optimal n). EVPI is a monetary value, not an n, so it has
    # no curve of this kind. A warmed-up ENBS search takes ~10 ms, so it runs
    # live.
    render_power_curves(output, function() {
      if (input$design != "evsi") return(NULL)
      req(input$mean_inb, input$sd_inb, input$population, input$sampling_sd,
          input$cost_per_patient, input$fixed_cost, input$n_max)
      list(
        calc_fn = calc_enbs_optimal_n,
        args = list(mean_inb = input$mean_inb, sd_inb = input$sd_inb, sampling_sd = input$sampling_sd,
                     cost_per_patient = input$cost_per_patient, population = input$population,
                     fixed_cost = input$fixed_cost, n_max = input$n_max),
        effect = list(param = "mean_inb", values = curve_range_multiplicative(abs(input$mean_inb)),
                      label = "Mean incremental net benefit",
                      title = "ENBS-optimal n vs. mean incremental net benefit"),
        power = list(param = "cost_per_patient", values = curve_range_multiplicative(input$cost_per_patient),
                     label = "Cost per patient sampled",
                     title = "ENBS-optimal n vs. cost per patient")
      )
    })
  })
}
