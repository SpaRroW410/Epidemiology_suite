# Meta-Analysis Power module: Calculate / Formula-Help / Reference
# sub-tabs. Single-design module (solves for the required number of
# studies, k), following the same simple pattern as mod_evpi.R, but with
# an effect-size-type radio (Cohen's d / correlation r / odds ratio) since
# the underlying variance formula genuinely differs by type.

meta_power_meta <- list(
  id = "meta_power",
  nav_title = "Meta-Analysis Power"
)

mod_meta_power_ui <- function(id) {
  ns <- NS(id)

  es_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("es_type"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("es_type"), "Effect size type",
        choices = c("Cohen's d" = "d", "Correlation (r)" = "r", "Odds ratio (2x2 table)" = "or"),
        selected = "d"
      ),
      conditionalPanel(
        condition = es_is("d"),
        numericInput(ns("d_effect"), "Assumed true effect size (Cohen's d)", value = 0.3, step = 0.05)
      ),
      conditionalPanel(
        condition = es_is("r"),
        numericInput(ns("r_effect"), "Assumed true correlation (r)", value = 0.3, min = -0.999, max = 0.999, step = 0.05)
      ),
      conditionalPanel(
        condition = es_is("or"),
        p("Enter a single representative 2x2 table (exposed/unexposed x event/no-event):"),
        numericInput(ns("or_a"), "a (exposed, event)", value = 30, min = 1, step = 1),
        numericInput(ns("or_b"), "b (unexposed, event)", value = 20, min = 1, step = 1),
        numericInput(ns("or_c"), "c (exposed, no event)", value = 15, min = 1, step = 1),
        numericInput(ns("or_d"), "d (unexposed, no event)", value = 35, min = 1, step = 1)
      ),
      numericInput(ns("study_size"), "Participants per study", value = 30, min = 4, step = 1),
      numericInput(ns("i2"), "Heterogeneity (I-squared)", value = 0.3, min = 0, max = 0.999, step = 0.05),
      selectInput(ns("test_type"), "Test type", choices = c("Two-tailed" = "two-tailed", "One-tailed" = "one-tailed")),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      radioButtons(
        ns("model"), "Solve using",
        choices = c("Random-effects (accounts for heterogeneity; recommended)" = "random",
                    "Fixed-effect (assumes zero heterogeneity)" = "fixed"),
        selected = "random"
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(meta_power_content$power$title),
      render_formula_block(meta_power_content$power$formula_latex),
      shiny::markdown(meta_power_content$power$explanation),
      h5("Worked example"),
      shiny::markdown(meta_power_content$power$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), meta_power_content$power$citation),
      p(strong("Implemented via: "), code(meta_power_content$power$backend))
    )
  )
}

mod_meta_power_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$es_type, input$study_size, input$i2, input$test_type,
          input$alpha, input$power, input$model)

      tryCatch({
        con_table <- NULL
        effect_size <- NULL
        if (input$es_type == "d") {
          req(input$d_effect)
          effect_size <- input$d_effect
        } else if (input$es_type == "r") {
          req(input$r_effect)
          effect_size <- input$r_effect
        } else {
          req(input$or_a, input$or_b, input$or_c, input$or_d)
          con_table <- c(input$or_a, input$or_b, input$or_c, input$or_d)
        }

        k_res <- calc_meta_analysis_k(
          effect_size = effect_size, study_size = input$study_size, i2 = input$i2,
          es_type = input$es_type, test_type = input$test_type, alpha = input$alpha,
          power = input$power, con_table = con_table, model = input$model
        )
        power_res <- calc_meta_analysis_power(
          effect_size = effect_size, study_size = input$study_size, k = k_res$k, i2 = input$i2,
          es_type = input$es_type, test_type = input$test_type, alpha = input$alpha, con_table = con_table
        )
        list(ok = TRUE, k_res = k_res, power_res = power_res)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      k_res <- res$k_res
      power_res <- res$power_res
      tagList(
        p(strong("Required number of studies (k): "), k_res$k),
        p(sprintf("Achieved power: fixed-effect = %.3f, random-effects = %.3f",
                   power_res$fixed_power, power_res$random_power)),
        p(class = "text-muted",
          sprintf("Effect size used on the analysis scale: %.4f (variance/study = %.5f)",
                   power_res$effect_size_used, power_res$variance))
      )
    })

    render_export_handlers(output, result, function() meta_power_content$power,
                            value_fn = function(res) res$k_res)
  })
}
