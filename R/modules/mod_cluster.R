# Cluster / Design Effect module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same module contract as mod_roc.R (docs/SDD.md #8)
# -- a single calculation, no design radio needed. Takes an already-computed
# simple-random-sample base n (from any other module) and inflates it for
# cluster sampling.

cluster_meta <- list(
  id = "cluster",
  nav_title = "Cluster / Design Effect"
)

mod_cluster_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("n_base"), "Base sample size (simple random sampling)",
                   value = 200, min = 1, step = 1),
      numericInput(ns("icc"), "Intraclass correlation coefficient (ICC / rho)",
                   value = 0.05, min = 0, max = 0.999, step = 0.01),
      numericInput(ns("cluster_size"), "Average cluster size (subjects per cluster)",
                   value = 10, min = 1, step = 1),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(cluster_content$deff$title),
      render_formula_block(cluster_content$deff$formula_latex),
      shiny::markdown(cluster_content$deff$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(cluster_content$deff$title),
      p(strong("Citation: "), cluster_content$deff$citation),
      p(strong("Implemented via: "), code(cluster_content$deff$backend))
    )
  )
}

mod_cluster_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$n_base, input$icc, input$cluster_size)
      tryCatch(
        list(ok = TRUE, value = calc_cluster_deff(
          n_base = input$n_base, icc = input$icc, cluster_size = input$cluster_size
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
      tagList(
        p(strong("Design effect (DEFF): "), sprintf("%.3f", v$deff)),
        p(strong("Cluster-adjusted (effective) sample size: "), v$n_effective)
      )
    })
  })
}
