# RM-ANOVA / Mixed ANOVA module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_logistic.R
# (docs/SDD.md #8) -- one calc_rm_anova() engine, dispatched by a `type`
# design choice ("between", "within", "interaction").

rm_anova_meta <- list(
  id = "rm_anova",
  nav_title = "RM-ANOVA / Mixed ANOVA"
)

mod_rm_anova_ui <- function(id) {
  ns <- NS(id)

  mod_rm_anova_content <- rm_anova_content

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Effect to test",
        choices = c(
          "Between-subjects group effect" = "between",
          "Within-subjects (repeated-measures) effect" = "within",
          "Group x time interaction (mixed/split-plot)" = "interaction"
        ),
        selected = "between"
      ),
      numericInput(ns("ng"), "Number of between-subjects groups (ng)", value = 3, min = 1, step = 1),
      numericInput(ns("nm"), "Number of repeated measurements (nm)", value = 4, min = 2, step = 1),
      numericInput(ns("f"), "Cohen's f effect size", value = 0.36, min = 0.001, step = 0.01),
      numericInput(ns("nscor"), "Nonsphericity correction (epsilon, 1 = sphericity met)",
                   value = 0.7, min = 0.01, max = 1, step = 0.01),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(mod_rm_anova_content$between$title),
      render_formula_block(mod_rm_anova_content$between$formula_latex),
      shiny::markdown(mod_rm_anova_content$between$explanation),
      h5("Worked example"),
      shiny::markdown(mod_rm_anova_content$between$worked_example),
      hr(),
      h4(mod_rm_anova_content$within$title),
      render_formula_block(mod_rm_anova_content$within$formula_latex),
      shiny::markdown(mod_rm_anova_content$within$explanation),
      h5("Worked example"),
      shiny::markdown(mod_rm_anova_content$within$worked_example),
      hr(),
      h4(mod_rm_anova_content$interaction$title),
      render_formula_block(mod_rm_anova_content$interaction$formula_latex),
      shiny::markdown(mod_rm_anova_content$interaction$explanation),
      h5("Worked example"),
      shiny::markdown(mod_rm_anova_content$interaction$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(mod_rm_anova_content$between$title),
      p(strong("Citation: "), mod_rm_anova_content$between$citation),
      p(strong("Implemented via: "), code(mod_rm_anova_content$between$backend)),
      hr(),
      h4(mod_rm_anova_content$within$title),
      p(strong("Citation: "), mod_rm_anova_content$within$citation),
      p(strong("Implemented via: "), code(mod_rm_anova_content$within$backend)),
      hr(),
      h4(mod_rm_anova_content$interaction$title),
      p(strong("Citation: "), mod_rm_anova_content$interaction$citation),
      p(strong("Implemented via: "), code(mod_rm_anova_content$interaction$backend))
    )
  )
}

mod_rm_anova_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$ng, input$nm, input$f, input$nscor, input$alpha, input$power)

      tryCatch(
        list(ok = TRUE, value = calc_rm_anova(
          ng = input$ng, nm = input$nm, f = input$f, nscor = input$nscor,
          alpha = input$alpha, power = input$power, type = input$design
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
        p(strong("Required total sample size: "), v$n),
        p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
      )
    })

    render_export_handlers(output, result, function() rm_anova_content[[input$design]])

    render_power_curves(output, function() {
      req(input$ng, input$nm, input$f, input$nscor, input$alpha, input$power, input$design)
      list(
        calc_fn = calc_rm_anova,
        args = list(ng = input$ng, nm = input$nm, f = input$f, nscor = input$nscor,
                     alpha = input$alpha, power = input$power, type = input$design),
        effect = list(param = "f", values = curve_range_multiplicative(input$f), label = "Cohen's f effect size"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
