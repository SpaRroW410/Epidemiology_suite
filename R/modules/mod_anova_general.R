# Factorial ANOVA / ANCOVA module: Calculate / Formula-Help / Reference
# sub-tabs. Single calculation (no outer design radio, like mod_roc.R),
# but with a nested radio for how the effect size is specified (f-squared
# directly, or partial eta-squared) -- same nested-radio pattern as
# mod_prediction.R's r2_method.

anova_general_meta <- list(
  id = "anova_general",
  nav_title = "Factorial ANOVA / ANCOVA"
)

mod_anova_general_ui <- function(id) {
  ns <- NS(id)

  es_is <- function(value) sprintf("input['%s'] == '%s'", ns("effect_size_type"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("u"), "Numerator df for the effect being tested (u)", value = 3, min = 1, step = 1),
      p(class = "text-muted",
        "u = (a-1) for a main effect with a levels; u = (a-1)(b-1) for an a x b interaction."),
      radioButtons(ns("effect_size_type"), "Effect size input",
                   choices = c("Cohen's f-squared" = "f2", "Partial eta-squared" = "eta2")),
      conditionalPanel(
        condition = es_is("f2"),
        numericInput(ns("f2"), "Cohen's f-squared", value = 0.0625, min = 0.0001, step = 0.01)
      ),
      conditionalPanel(
        condition = es_is("eta2"),
        numericInput(ns("eta2"), "Partial eta-squared", value = 0.0588, min = 0.0001, max = 0.999, step = 0.01)
      ),
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
      h4(anova_general_content$anova_general$title),
      render_formula_block(anova_general_content$anova_general$formula_latex),
      shiny::markdown(anova_general_content$anova_general$explanation),
      h5("Worked example"),
      shiny::markdown(anova_general_content$anova_general$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(anova_general_content$anova_general$title),
      p(strong("Citation: "), anova_general_content$anova_general$citation),
      p(strong("Implemented via: "), code(anova_general_content$anova_general$backend))
    )
  )
}

mod_anova_general_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$u, input$effect_size_type, input$alpha, input$power)

      es <- if (input$effect_size_type == "f2") input$f2 else input$eta2
      req(es)

      tryCatch(
        list(ok = TRUE, value = calc_anova_general(
          u = input$u, effect_size = es, effect_size_type = input$effect_size_type,
          alpha = input$alpha, power = input$power
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
        p(sprintf("Denominator df: %d; Cohen's f-squared used: %.4f", v$v, v$f2))
      )
    })

    render_export_handlers(output, result, function() anova_general_content$anova_general)
  })
}
