# Simon Two-Stage module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

simon_meta <- list(
  id = "simon",
  nav_title = "Simon Two-Stage"
)

mod_simon_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("pu"), "pu (unacceptable response rate)", value = 0.2, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("pa"), "pa (desirable response rate)", value = 0.4, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("alpha"), "Target type I error (alpha)", value = 0.1, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("beta"), "Target type II error (beta)", value = 0.1, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("nmax"), "Maximum total sample size to search", value = 100, min = 10, max = 1000, step = 10),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(simon_content$ph2simon$title),
      render_formula_block(simon_content$ph2simon$formula_latex),
      shiny::markdown(simon_content$ph2simon$explanation),
      h5("Worked example"),
      shiny::markdown(simon_content$ph2simon$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(simon_content$ph2simon$title),
      p(strong("Citation: "), simon_content$ph2simon$citation),
      p(strong("Implemented via: "), code(simon_content$ph2simon$backend))
    )
  )
}

mod_simon_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$pu, input$pa, input$alpha, input$beta, input$nmax)
      tryCatch(
        list(ok = TRUE, value = calc_simon(
          pu = input$pu, pa = input$pa, alpha = input$alpha, beta = input$beta,
          nmax = input$nmax
        )),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      mm <- res$value$minimax
      op <- res$value$optimal
      tagList(
        h5("Minimax design (smallest maximum n)"),
        p(sprintf("Stop early if <= %d responses in the first %d patients; otherwise continue to %d total, needing > %d responses overall.",
                  mm$r1, mm$n1, mm$n, mm$r)),
        p(sprintf("EN(pu) = %.2f, PET(pu) = %.3f", mm$EN, mm$PET)),
        hr(),
        h5("Optimal design (smallest expected n under pu)"),
        p(sprintf("Stop early if <= %d responses in the first %d patients; otherwise continue to %d total, needing > %d responses overall.",
                  op$r1, op$n1, op$n, op$r)),
        p(sprintf("EN(pu) = %.2f, PET(pu) = %.3f", op$EN, op$PET))
      )
    })

    render_export_handlers(output, result, function() simon_content$ph2simon)

    # Power curves (ROADMAP P1 item 10): Simon's design takes a type II
    # error beta (power = 1 - beta) and returns nested minimax/optimal
    # designs, so it is called through an adapter that exposes `power` and
    # flattens the two designs' maximum n into top-level fields -- the
    # curve then plots the minimax design's maximum n. ph2simon measured
    # ~60ms/call, so a 20-point grid is used.
    simon_by_power <- function(pu, pa, alpha, power, nmax) {
      r <- calc_simon(pu = pu, pa = pa, alpha = alpha, beta = 1 - power, nmax = nmax)
      new_ss_result(list(
        n_minimax = r$minimax$n, n_optimal = r$optimal$n,
        inputs = list(pu = pu, pa = pa, alpha = alpha, power = power, nmax = nmax)
      ))
    }
    render_power_curves(output, function() {
      req(input$pu, input$pa, input$alpha, input$beta, input$nmax)
      list(
        calc_fn = simon_by_power,
        args = list(pu = input$pu, pa = input$pa, alpha = input$alpha,
                     power = 1 - input$beta, nmax = input$nmax),
        effect = list(param = "pa", values = curve_range_within(input$pu, 1, n = 20),
                      label = "pa (desirable response rate) -- minimax design's maximum n"),
        power = list(param = "power", values = curve_range_power(n = 20))
      )
    })
  })
}
