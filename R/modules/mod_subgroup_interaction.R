# Subgroup / Interaction Testing module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same single-design module contract as
# mod_manova.R (docs/SDD.md #8) -- one calculation, no design radio
# needed.

subgroup_interaction_meta <- list(
  id = "subgroup_interaction",
  nav_title = "Subgroup / Interaction Testing"
)

mod_subgroup_interaction_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("n_main_total"), "Main-effect total sample size (both arms combined)",
                   value = 100, min = 2, step = 1),
      numericInput(ns("effect_ratio"),
                   "Interaction effect size, relative to the main effect (1.0 = same magnitude)",
                   value = 1, min = 0.001, step = 0.1),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(subgroup_interaction_content$standard$title),
      render_formula_block(subgroup_interaction_content$standard$formula_latex),
      shiny::markdown(subgroup_interaction_content$standard$explanation),
      h5("Worked example"),
      shiny::markdown(subgroup_interaction_content$standard$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(subgroup_interaction_content$standard$title),
      p(strong("Citation: "), subgroup_interaction_content$standard$citation),
      p(strong("Implemented via: "), code(subgroup_interaction_content$standard$backend))
    )
  )
}

mod_subgroup_interaction_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$n_main_total, input$effect_ratio)
      tryCatch(
        list(ok = TRUE, value = calc_subgroup_interaction(
          n_main_total = input$n_main_total, effect_ratio = input$effect_ratio
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
        p(strong("Required total sample size for the interaction test: "), v$n_interaction_total),
        p(sprintf("Inflation multiplier vs. the main-effect sample size: %.2fx", v$multiplier))
      )
    })

    render_export_handlers(output, result, function() subgroup_interaction_content$standard)
  })
}
