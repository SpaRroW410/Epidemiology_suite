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
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(simon_content$ph2simon$title),
      withMathJax(HTML(simon_content$ph2simon$formula_latex)),
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
  })
}
