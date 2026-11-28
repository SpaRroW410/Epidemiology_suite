# Stepped-Wedge CRT module: Calculate / Formula-Help / Reference sub-tabs.
# Two designs chosen by the outcome: continuous (Hooper et al. 2016) or binary (logit scale, Xia et al. 2021).

stepped_wedge_meta <- list(
  id = "stepped_wedge",
  nav_title = "Stepped-Wedge CRT"
)

mod_stepped_wedge_ui <- function(id) {
  ns <- NS(id)
  is_outcome <- function(value) sprintf("input['%s'] == '%s'", ns("outcome"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(ns("outcome"), "Outcome", choices = c("Continuous" = "continuous", "Binary (yes / no)" = "binary"),
                   selected = "continuous", inline = TRUE),
      conditionalPanel(condition = is_outcome("continuous"), tagList(
      numericInput(ns("nsubjects"), "Subjects per cluster per time point (m)",
                   value = 10, min = 0.001, step = 1),
      numericInput(ns("ntimes"), "Number of post-baseline time points (T)",
                   value = 4, min = 2, step = 1),
      numericInput(ns("d"), "Expected (absolute) treatment effect (d)",
                   value = 0.25, step = 0.05),
      numericInput(ns("icc"), "Intracluster correlation (ICC)",
                   value = 0.05, min = 0, max = 0.999, step = 0.01),
      numericInput(ns("rho_c"), "Cluster autocorrelation (rho_c)",
                   value = 0.5, min = 0, max = 1, step = 0.05),
      numericInput(ns("rho_s"), "Individual autocorrelation (rho_s; 0 = cross-sectional)",
                   value = 0, min = 0, max = 1, step = 0.05),
      numericInput(ns("vart"), "Total outcome variance", value = 1, min = 0.0001, step = 0.1),
      numericInput(ns("alpha"), "Two-sided alpha", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      )),
      conditionalPanel(condition = is_outcome("binary"), tagList(
      numericInput(ns("b_p0"), "Risk of the outcome on control", value = 0.2, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("b_p1"), "Risk of the outcome on the intervention", value = 0.14, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("b_n"), "People per cluster in each period", value = 50, min = 1, step = 1),
      numericInput(ns("b_steps"), "Number of steps (there is one more period: the first, all on control)", value = 3, min = 2, step = 1),
      numericInput(ns("b_tau"), "SD of the cluster effect on the log odds scale (tau)", value = 0.2, min = 0, step = 0.05),
      numericInput(ns("b_time"), "Change in log odds in each later period (0 = no time trend)", value = 0, step = 0.05),
      numericInput(ns("b_alpha"), "Two-sided alpha", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("b_power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      )),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(stepped_wedge_content$normal$title),
      render_formula_block(stepped_wedge_content$normal$formula_latex),
      shiny::markdown(stepped_wedge_content$normal$explanation),
      h5("Worked example"),
      shiny::markdown(stepped_wedge_content$normal$worked_example),
      hr(),
      h4(stepped_wedge_content$binary$title),
      render_formula_block(stepped_wedge_content$binary$formula_latex),
      shiny::markdown(stepped_wedge_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(stepped_wedge_content$binary$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), stepped_wedge_content$normal$citation),
      p(strong("Implemented via: "), code(stepped_wedge_content$normal$backend)),
      hr(),
      p(strong("Binary outcome. Citation: "), stepped_wedge_content$binary$citation),
      p(strong("Implemented via: "), code(stepped_wedge_content$binary$backend))
    )
  )
}

mod_stepped_wedge_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    binary <- reactive(identical(input$outcome, "binary"))
    result <- reactive({
      if (binary()) {
        req(input$b_p0, input$b_p1, input$b_n, input$b_steps, input$b_tau, input$b_time, input$b_alpha, input$b_power)
        return(tryCatch(
          list(ok = TRUE, value = calc_stepped_wedge_binary(
            p0 = input$b_p0, p1 = input$b_p1, nsubjects = input$b_n, nsteps = input$b_steps, tau = input$b_tau,
            time_effect = input$b_time, alpha = input$b_alpha, power = input$b_power)),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        ))
      }
      req(input$nsubjects, input$ntimes, input$d, input$icc, input$rho_c,
          input$rho_s, input$vart, input$alpha, input$power)

      tryCatch(
        list(ok = TRUE, value = calc_stepped_wedge_normal(
          nsubjects = input$nsubjects, ntimes = input$ntimes, d = input$d,
          icc = input$icc, rho_c = input$rho_c, rho_s = input$rho_s,
          vart = input$vart, alpha = input$alpha, power = input$power
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
      if (binary()) {
        return(tagList(
          p(strong("Required clusters crossing over at each step: "), v$nclusters),
          p(strong("Total clusters (steps x clusters per step): "), v$total_clusters),
          p(sprintf("Achieved power = %.3f; odds ratio %.3f.", v$achieved_power, v$odds_ratio))
        ))
      }
      tagList(
        p(strong("Required clusters crossing over at each step: "), v$nclusters),
        p(strong("Total clusters (steps x nclusters per step): "), v$nclusters * (input$ntimes)),
        p(sprintf("Achieved power = %.3f (design effect: cluster %.3f x time %.3f = VIF %.3f)",
                   v$achieved_power, v$deff_cluster, v$deff_time, v$vif))
      )
    })

    render_export_handlers(output, result, function() if (binary()) stepped_wedge_content$binary else stepped_wedge_content$normal)

    render_power_curves(output, function() {
      if (binary()) {
        req(input$b_p0, input$b_p1, input$b_n, input$b_steps, input$b_tau, input$b_time, input$b_alpha, input$b_power)
        return(list(
          calc_fn = calc_stepped_wedge_binary,
          args = list(p0 = input$b_p0, p1 = input$b_p1, nsubjects = input$b_n, nsteps = input$b_steps, tau = input$b_tau,
                      time_effect = input$b_time, alpha = input$b_alpha, power = input$b_power),
          effect = list(param = "p1", values = curve_range_proportion(), label = "Risk on the intervention"),
          power = list(param = "power", values = curve_range_power())
        ))
      }
      req(input$nsubjects, input$ntimes, input$d, input$icc, input$rho_c,
          input$rho_s, input$vart, input$alpha, input$power)
      list(
        calc_fn = calc_stepped_wedge_normal,
        args = list(nsubjects = input$nsubjects, ntimes = input$ntimes, d = input$d,
                     icc = input$icc, rho_c = input$rho_c, rho_s = input$rho_s,
                     vart = input$vart, alpha = input$alpha, power = input$power),
        effect = list(param = "d", values = curve_range_multiplicative(input$d), label = "d (treatment effect)"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
