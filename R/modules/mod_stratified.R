# Stratified Sampling module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same dynamic-inputs pattern as mod_chisq.R
# (docs/SDD.md #8) -- the number of strata is user-chosen, so the
# per-stratum Nh/Sh inputs are built via renderUI() + session$ns()
# rather than statically in mod_stratified_ui().

stratified_meta <- list(
  id = "stratified",
  nav_title = "Stratified Sampling"
)

mod_stratified_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      selectInput(ns("k"), "Number of strata", choices = 2:8, selected = 3),
      uiOutput(ns("strata_ui")),
      numericInput(ns("e"), "Desired absolute precision (e)", value = 0.1, min = 0.0001, step = 0.01),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      radioButtons(ns("type"), "Allocation",
                   choices = c("Proportional (allocate by stratum size)" = "proportional",
                               "Optimal / Neyman (allocate by size x SD)" = "optimal")),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(stratified_content$stratified$title),
      render_formula_block(stratified_content$stratified$formula_latex),
      shiny::markdown(stratified_content$stratified$explanation),
      h5("Worked example"),
      shiny::markdown(stratified_content$stratified$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(stratified_content$stratified$title),
      p(strong("Citation: "), stratified_content$stratified$citation),
      p(strong("Implemented via: "), code(stratified_content$stratified$backend))
    )
  )
}

mod_stratified_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$strata_ui <- renderUI({
      req(input$k)
      k <- as.integer(input$k)
      tagList(lapply(seq_len(k), function(i) {
        fluidRow(
          column(6, numericInput(session$ns(paste0("Nh_", i)), sprintf("Stratum %d: population size (Nh)", i),
                                  value = 1000, min = 2, step = 1)),
          column(6, numericInput(session$ns(paste0("Sh_", i)), sprintf("Stratum %d: standard deviation (Sh)", i),
                                  value = 1, min = 0, step = 0.1))
        )
      }))
    })

    result <- reactive({
      req(input$k, input$e, input$conf_level, input$type)
      k <- as.integer(input$k)
      Nh_vals <- lapply(seq_len(k), function(i) input[[paste0("Nh_", i)]])
      Sh_vals <- lapply(seq_len(k), function(i) input[[paste0("Sh_", i)]])
      req(!any(vapply(Nh_vals, is.null, logical(1))),
          !any(vapply(Sh_vals, is.null, logical(1))))

      tryCatch(
        list(ok = TRUE, value = calc_stratified_sampling(
          Nh = as.numeric(unlist(Nh_vals)), Sh = as.numeric(unlist(Sh_vals)),
          e = input$e, conf_level = input$conf_level, type = input$type
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
        p(strong("Total sample size: "), v$n_total),
        p("Per-stratum allocation: ",
          paste(sprintf("stratum %d = %d", seq_along(v$nh), v$nh), collapse = "; "))
      )
    })
  })
}
