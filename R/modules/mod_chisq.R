# Chi-Square Tests module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_agreement.R (docs/SDD.md #8),
# including its dynamic-inputs pattern: the goodness-of-fit design needs one
# pair of proportion inputs per category, and the independence design needs
# an R x C grid of joint proportions, so both are built via renderUI() +
# session$ns() rather than statically in mod_chisq_ui().

chisq_meta <- list(
  id = "chisq",
  nav_title = "Chi-Square Tests"
)

mod_chisq_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Goodness of fit" = "gof",
          "Test of independence / association (R x C table)" = "independence",
          "McNemar's test (paired proportions)" = "mcnemar"
        ),
        selected = "gof"
      ),
      conditionalPanel(
        condition = design_is("gof"),
        selectInput(ns("k_gof"), "Number of categories (k)", choices = 2:8, selected = 4),
        uiOutput(ns("gof_props_ui"))
      ),
      conditionalPanel(
        condition = design_is("independence"),
        fluidRow(
          column(6, selectInput(ns("rows"), "Number of rows", choices = 2:5, selected = 2)),
          column(6, selectInput(ns("cols"), "Number of columns", choices = 2:5, selected = 2))
        ),
        p(class = "text-muted",
          "Enter the proportion of the TOTAL sample expected in each cell (all cells sum to 1)."),
        uiOutput(ns("indep_props_ui"))
      ),
      conditionalPanel(
        condition = design_is("mcnemar"),
        numericInput(ns("p10"), "p10 (proportion switching positive -> negative)",
                     value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p01"), "p01 (proportion switching negative -> positive)",
                     value = 0.2, min = 0.001, max = 0.999, step = 0.01)
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
      h4(chisq_content$gof$title),
      render_formula_block(chisq_content$gof$formula_latex),
      shiny::markdown(chisq_content$gof$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$gof$worked_example),
      hr(),
      h4(chisq_content$independence$title),
      render_formula_block(chisq_content$independence$formula_latex),
      shiny::markdown(chisq_content$independence$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$independence$worked_example),
      hr(),
      h4(chisq_content$mcnemar$title),
      render_formula_block(chisq_content$mcnemar$formula_latex),
      shiny::markdown(chisq_content$mcnemar$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$mcnemar$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(chisq_content$gof$title),
      p(strong("Citation: "), chisq_content$gof$citation),
      p(strong("Implemented via: "), code(chisq_content$gof$backend)),
      hr(),
      h4(chisq_content$independence$title),
      p(strong("Citation: "), chisq_content$independence$citation),
      p(strong("Implemented via: "), code(chisq_content$independence$backend)),
      hr(),
      h4(chisq_content$mcnemar$title),
      p(strong("Citation: "), chisq_content$mcnemar$citation),
      p(strong("Implemented via: "), code(chisq_content$mcnemar$backend))
    )
  )
}

mod_chisq_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$gof_props_ui <- renderUI({
      req(input$k_gof)
      k <- as.integer(input$k_gof)
      default <- round(1 / k, 3)
      tagList(
        h5("Null (expected) proportions"),
        lapply(seq_len(k), function(i) {
          numericInput(session$ns(paste0("p0_", i)), sprintf("P0, category %d", i),
                       value = default, min = 0.001, max = 0.999, step = 0.01)
        }),
        h5("Alternative (anticipated) proportions"),
        lapply(seq_len(k), function(i) {
          numericInput(session$ns(paste0("p1_", i)), sprintf("P1, category %d", i),
                       value = default, min = 0.001, max = 0.999, step = 0.01)
        })
      )
    })

    output$indep_props_ui <- renderUI({
      req(input$rows, input$cols)
      r <- as.integer(input$rows)
      cols <- as.integer(input$cols)
      default <- round(1 / (r * cols), 3)
      col_width <- max(1, floor(12 / cols))
      tagList(lapply(seq_len(r), function(i) {
        fluidRow(lapply(seq_len(cols), function(j) {
          column(col_width, numericInput(
            session$ns(sprintf("p_%d_%d", i, j)), sprintf("Row %d, Col %d", i, j),
            value = default, min = 0.001, max = 0.999, step = 0.01
          ))
        }))
      }))
    })

    result <- reactive({
      req(input$design, input$alpha, input$power)

      if (input$design == "mcnemar") {
        req(input$p10, input$p01)
        tryCatch(
          list(ok = TRUE, value = calc_mcnemar(
            p10 = input$p10, p01 = input$p01, alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "gof") {
        req(input$k_gof)
        k <- as.integer(input$k_gof)
        p0_vals <- lapply(seq_len(k), function(i) input[[paste0("p0_", i)]])
        p1_vals <- lapply(seq_len(k), function(i) input[[paste0("p1_", i)]])
        req(!any(vapply(p0_vals, is.null, logical(1))),
            !any(vapply(p1_vals, is.null, logical(1))))

        tryCatch(
          list(ok = TRUE, value = calc_chisq_gof(
            P0 = as.numeric(unlist(p0_vals)), P1 = as.numeric(unlist(p1_vals)),
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$rows, input$cols)
        r <- as.integer(input$rows)
        cols <- as.integer(input$cols)
        vals <- lapply(seq_len(r), function(i) {
          lapply(seq_len(cols), function(j) input[[sprintf("p_%d_%d", i, j)]])
        })
        req(!any(vapply(unlist(vals, recursive = FALSE), is.null, logical(1))))
        P <- matrix(as.numeric(unlist(vals)), nrow = r, ncol = cols, byrow = TRUE)

        tryCatch(
          list(ok = TRUE, value = calc_chisq_independence(
            P = P, alpha = input$alpha, power = input$power
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
      if (input$design == "mcnemar") {
        tagList(
          p(strong("Required number of pairs: "), v$n)
        )
      } else {
        tagList(
          p(strong("Required total sample size (N): "), v$N),
          p(sprintf("Effect size w = %.4f, df = %d", v$w, v$df))
        )
      }
    })
  })
}
