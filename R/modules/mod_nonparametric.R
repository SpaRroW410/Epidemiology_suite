# Nonparametric Tests module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_logistic.R
# (docs/SDD.md #8) -- three distinct designs, each with its own
# calc_*() engine wrapping TrialSize:: (Chow, Shao & Wang 2003).

nonparametric_meta <- list(
  id = "nonparametric",
  nav_title = "Nonparametric Tests"
)

mod_nonparametric_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Wilcoxon rank-sum (Mann-Whitney U, two independent groups)" = "rank_sum",
          "Wilcoxon signed-rank (one sample / paired differences)" = "signed_rank",
          "Kendall's tau (nonparametric association)" = "kendall"
        ),
        selected = "rank_sum"
      ),
      conditionalPanel(
        condition = design_is("rank_sum"),
        numericInput(ns("k_rs"), "Allocation ratio (k = n1/n2)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("p1_rs"), "p1 = P(Y >= X)", value = 0.7, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_rs"), "p2", value = 0.8, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p3_rs"), "p3", value = 0.8, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("signed_rank"),
        numericInput(ns("p2_sr"), "p2", value = 0.3, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p3_sr"), "p3", value = 0.4, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p4_sr"), "p4", value = 0.05, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("kendall"),
        numericInput(ns("p1_k"), "p1 = concordance probability (tau = 2*p1 - 1)",
                     value = 0.6, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_k"), "p2", value = 0.7, min = 0.001, max = 0.999, step = 0.01)
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(nonparametric_content$wilcoxon_rank_sum$title),
      render_formula_block(nonparametric_content$wilcoxon_rank_sum$formula_latex),
      shiny::markdown(nonparametric_content$wilcoxon_rank_sum$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$wilcoxon_rank_sum$worked_example),
      hr(),
      h4(nonparametric_content$wilcoxon_signed_rank$title),
      render_formula_block(nonparametric_content$wilcoxon_signed_rank$formula_latex),
      shiny::markdown(nonparametric_content$wilcoxon_signed_rank$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$wilcoxon_signed_rank$worked_example),
      hr(),
      h4(nonparametric_content$kendall_tau$title),
      render_formula_block(nonparametric_content$kendall_tau$formula_latex),
      shiny::markdown(nonparametric_content$kendall_tau$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$kendall_tau$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(nonparametric_content$wilcoxon_rank_sum$title),
      p(strong("Citation: "), nonparametric_content$wilcoxon_rank_sum$citation),
      p(strong("Implemented via: "), code(nonparametric_content$wilcoxon_rank_sum$backend)),
      hr(),
      h4(nonparametric_content$wilcoxon_signed_rank$title),
      p(strong("Citation: "), nonparametric_content$wilcoxon_signed_rank$citation),
      p(strong("Implemented via: "), code(nonparametric_content$wilcoxon_signed_rank$backend)),
      hr(),
      h4(nonparametric_content$kendall_tau$title),
      p(strong("Citation: "), nonparametric_content$kendall_tau$citation),
      p(strong("Implemented via: "), code(nonparametric_content$kendall_tau$backend))
    )
  )
}

mod_nonparametric_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power)

      tryCatch({
        value <- if (input$design == "rank_sum") {
          req(input$k_rs, input$p1_rs, input$p2_rs, input$p3_rs)
          calc_wilcoxon_rank_sum(
            k = input$k_rs, p1 = input$p1_rs, p2 = input$p2_rs, p3 = input$p3_rs,
            alpha = input$alpha, power = input$power
          )
        } else if (input$design == "signed_rank") {
          req(input$p2_sr, input$p3_sr, input$p4_sr)
          calc_wilcoxon_signed_rank(
            p2 = input$p2_sr, p3 = input$p3_sr, p4 = input$p4_sr,
            alpha = input$alpha, power = input$power
          )
        } else {
          req(input$p1_k, input$p2_k)
          calc_kendall_tau(
            p1 = input$p1_k, p2 = input$p2_k, alpha = input$alpha, power = input$power
          )
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (res$design == "kendall") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Implied Kendall's tau: %.3f", v$tau))
        )
      } else {
        p(strong("Required sample size: "), v$n)
      }
    })
  })
}
