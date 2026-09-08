# Resource Equation module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the design-radio pattern (docs/SDD.md #8) with two modes:
# recommend a sample size, or check the adequacy of a chosen one.

resource_equation_meta <- list(
  id = "resource_equation",
  nav_title = "Resource Equation (Animal Studies)"
)

mod_resource_equation_ui <- function(id) {
  ns <- NS(id)

  mode_is <- function(value) sprintf("input['%s'] == '%s'", ns("mode"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("mode"), "Mode",
        choices = c(
          "Recommend a sample size" = "size",
          "Check adequacy of a chosen sample size" = "check"
        )
      ),
      conditionalPanel(
        condition = mode_is("size"),
        numericInput(ns("k_groups_size"), "Number of treatment groups", value = 4, min = 2, step = 1),
        numericInput(ns("e_target"), "Target error degrees of freedom (E, typically 10-20)",
                     value = 10, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = mode_is("check"),
        numericInput(ns("k_groups_check"), "Number of treatment groups", value = 5, min = 2, step = 1),
        numericInput(ns("n_per_group_check"), "Animals per group", value = 10, min = 1, step = 1)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(resource_equation_content$size$title),
      render_formula_block(resource_equation_content$size$formula_latex),
      shiny::markdown(resource_equation_content$size$explanation),
      h5("Worked example"),
      shiny::markdown(resource_equation_content$size$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(resource_equation_content$size$title),
      p(strong("Citation: "), resource_equation_content$size$citation),
      p(strong("Implemented via: "), code(resource_equation_content$size$backend))
    )
  )
}

mod_resource_equation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$mode)
      if (input$mode == "size") {
        req(input$k_groups_size, input$e_target)
        tryCatch(
          list(ok = TRUE, value = calc_resource_equation_size(
            k_groups = input$k_groups_size, e_target = input$e_target
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$k_groups_check, input$n_per_group_check)
        tryCatch(
          list(ok = TRUE, value = calc_resource_equation_check(
            k_groups = input$k_groups_check, n_per_group = input$n_per_group_check
          )),
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
      if (input$mode == "size") {
        tagList(
          p(strong("Recommended total sample size: "), v$n_total),
          p(strong("Recommended per-group sample size: "), v$n_per_group),
          p(sprintf("Error degrees of freedom (E): %d", v$e))
        )
      } else {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Error degrees of freedom (E): %d", v$e)),
          p(strong("Verdict: "), v$verdict)
        )
      }
    })
  })
}
