# Exact Tests module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8).

exact_tests_meta <- list(
  id = "exact_tests",
  nav_title = "Exact Tests"
)

mod_exact_tests_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Binomial test, single proportion" = "binomial",
          "Fisher's exact test, two independent proportions" = "fisher",
          "Boschloo's exact test, two independent proportions (unconditional)" = "boschloo",
          "Exact Poisson test, single rate vs. reference" = "poisson",
          "Sign test (paired data / one-sample median)" = "sign"
        )
      ),
      conditionalPanel(
        condition = design_is("binomial"),
        numericInput(ns("p0"), "p0 (reference proportion)", value = 0.10, min = 0, max = 1, step = 0.01),
        numericInput(ns("p1_bin"), "p1 (expected proportion)", value = 0.30, min = 0, max = 1, step = 0.01),
        numericInput(ns("alpha_bin"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_bin"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative_bin"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = design_is("fisher"),
        numericInput(ns("p1_fisher"), "p1 (group 1 proportion)", value = 0.15, min = 0, max = 1, step = 0.01),
        numericInput(ns("p2_fisher"), "p2 (group 2 proportion)", value = 0.60, min = 0, max = 1, step = 0.01),
        numericInput(ns("alpha_fisher"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_fisher"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio_fisher"), "Allocation ratio (group 2 : group 1)", value = 2, min = 0.1, step = 0.1),
        selectInput(
          ns("alternative_fisher"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = design_is("boschloo"),
        numericInput(ns("p1_boschloo"), "p1 (group 1 proportion)", value = 0.30, min = 0, max = 1, step = 0.01),
        numericInput(ns("p2_boschloo"), "p2 (group 2 proportion)", value = 0.60, min = 0, max = 1, step = 0.01),
        numericInput(ns("alpha_boschloo"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_boschloo"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio_boschloo"), "Allocation ratio (group 2 : group 1)", value = 1, min = 0.1, step = 0.1),
        selectInput(
          ns("alternative_boschloo"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = design_is("poisson"),
        numericInput(ns("rate0_poisson"), "rate0 (reference/standard rate)", value = 5, min = 0.0001, step = 0.1),
        numericInput(ns("rate1_poisson"), "rate1 (expected/anticipated true rate)", value = 10, min = 0.0001, step = 0.1),
        numericInput(ns("alpha_poisson"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_poisson"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative_poisson"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = design_is("sign"),
        numericInput(ns("p_pos_sign"), "Expected proportion of pairs with a positive difference",
                     value = 0.7, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("alpha_sign"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_sign"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative_sign"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(exact_tests_content$binomial$title),
      render_formula_block(exact_tests_content$binomial$formula_latex),
      shiny::markdown(exact_tests_content$binomial$explanation),
      h5("Worked example"),
      shiny::markdown(exact_tests_content$binomial$worked_example),
      hr(),
      h4(exact_tests_content$fisher$title),
      render_formula_block(exact_tests_content$fisher$formula_latex),
      shiny::markdown(exact_tests_content$fisher$explanation),
      h5("Worked example"),
      shiny::markdown(exact_tests_content$fisher$worked_example),
      hr(),
      h4(exact_tests_content$boschloo$title),
      render_formula_block(exact_tests_content$boschloo$formula_latex),
      shiny::markdown(exact_tests_content$boschloo$explanation),
      h5("Worked example"),
      shiny::markdown(exact_tests_content$boschloo$worked_example),
      hr(),
      h4(exact_tests_content$poisson$title),
      render_formula_block(exact_tests_content$poisson$formula_latex),
      shiny::markdown(exact_tests_content$poisson$explanation),
      h5("Worked example"),
      shiny::markdown(exact_tests_content$poisson$worked_example),
      hr(),
      h4(exact_tests_content$sign_test$title),
      render_formula_block(exact_tests_content$sign_test$formula_latex),
      shiny::markdown(exact_tests_content$sign_test$explanation),
      h5("Worked example"),
      shiny::markdown(exact_tests_content$sign_test$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(exact_tests_content$binomial$title),
      p(strong("Citation: "), exact_tests_content$binomial$citation),
      p(strong("Implemented via: "), code(exact_tests_content$binomial$backend)),
      hr(),
      h4(exact_tests_content$fisher$title),
      p(strong("Citation: "), exact_tests_content$fisher$citation),
      p(strong("Implemented via: "), code(exact_tests_content$fisher$backend)),
      hr(),
      h4(exact_tests_content$boschloo$title),
      p(strong("Citation: "), exact_tests_content$boschloo$citation),
      p(strong("Implemented via: "), code(exact_tests_content$boschloo$backend)),
      hr(),
      h4(exact_tests_content$poisson$title),
      p(strong("Citation: "), exact_tests_content$poisson$citation),
      p(strong("Implemented via: "), code(exact_tests_content$poisson$backend)),
      hr(),
      h4(exact_tests_content$sign_test$title),
      p(strong("Citation: "), exact_tests_content$sign_test$citation),
      p(strong("Implemented via: "), code(exact_tests_content$sign_test$backend))
    )
  )
}

mod_exact_tests_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "binomial") {
        req(input$p0, input$p1_bin, input$alpha_bin, input$power_bin, input$alternative_bin)
        tryCatch(
          list(ok = TRUE, value = calc_binomial_exact(
            p0 = input$p0, p1 = input$p1_bin, alpha = input$alpha_bin,
            power = input$power_bin, alternative = input$alternative_bin
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "fisher") {
        req(input$p1_fisher, input$p2_fisher, input$alpha_fisher, input$power_fisher,
            input$ratio_fisher, input$alternative_fisher)
        tryCatch(
          list(ok = TRUE, value = calc_fisher_exact(
            p1 = input$p1_fisher, p2 = input$p2_fisher, alpha = input$alpha_fisher,
            power = input$power_fisher, ratio = input$ratio_fisher,
            alternative = input$alternative_fisher
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "boschloo") {
        req(input$p1_boschloo, input$p2_boschloo, input$alpha_boschloo, input$power_boschloo,
            input$ratio_boschloo, input$alternative_boschloo)
        tryCatch(
          list(ok = TRUE, value = calc_boschloo_exact(
            p1 = input$p1_boschloo, p2 = input$p2_boschloo, alpha = input$alpha_boschloo,
            power = input$power_boschloo, ratio = input$ratio_boschloo,
            alternative = input$alternative_boschloo
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "poisson") {
        req(input$rate0_poisson, input$rate1_poisson, input$alpha_poisson,
            input$power_poisson, input$alternative_poisson)
        tryCatch(
          list(ok = TRUE, value = calc_poisson_exact(
            rate0 = input$rate0_poisson, rate1 = input$rate1_poisson,
            alpha = input$alpha_poisson, power = input$power_poisson,
            alternative = input$alternative_poisson
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p_pos_sign, input$alpha_sign, input$power_sign, input$alternative_sign)
        tryCatch(
          list(ok = TRUE, value = calc_sign_test(
            p_pos = input$p_pos_sign, alpha = input$alpha_sign,
            power = input$power_sign, alternative = input$alternative_sign
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
      if (input$design %in% c("fisher", "boschloo")) {
        tagList(
          p(strong("Required sample size per group: "), sprintf("n1 = %d, n2 = %d", v$n1, v$n2)),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Achieved exact power at this n: %.4f", v$achieved_power))
        )
      } else if (input$design == "poisson") {
        tagList(
          p(strong("Required person-time: "), v$person_time),
          p(sprintf("Expected number of events at rate1: %.2f", v$expected_events)),
          p(sprintf("Achieved exact power at this person-time: %.4f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Achieved exact power at this n: %.4f", v$achieved_power))
        )
      }
    })

    render_export_handlers(output, result, function() {
      key <- input$design
      remap <- c("sign" = "sign_test")
      exact_tests_content[[if (key %in% names(remap)) remap[[key]] else key]]
    })
  })
}
