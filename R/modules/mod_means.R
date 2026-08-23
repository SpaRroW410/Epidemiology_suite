# Means module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R (docs/SDD.md #8) --
# UI + server + metadata, so this file is itself a template for the next
# t-test-adjacent module.

means_meta <- list(
  id = "means",
  nav_title = "Means"
)

mod_means_ui <- function(id) {
  ns <- NS(id)

  # See mod_proportion.R for why conditionalPanel() conditions are built
  # with ns() rather than hardcoded -- same reasoning applies here.
  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  design_is_not <- function(value) sprintf("input['%s'] != '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single mean, precision-based (no reference value)" = "single_precision",
          "Single mean vs. known/reference value (hypothesis test)" = "single",
          "Two independent means" = "two_sample",
          "Two independent means, unequal group sizes" = "two_sample_unequal_n",
          "Two paired means (before-after, matched pairs)" = "paired",
          "Three or more independent groups (one-way ANOVA)" = "anova"
        ),
        selected = "single"
      ),
      conditionalPanel(
        condition = design_is("single_precision"),
        numericInput(ns("mean_precision"), "Expected mean (must be non-zero)", value = 75),
        numericInput(ns("sd_precision"), "Expected standard deviation",
                     value = 15, min = 0.0001),
        numericInput(ns("epsilon_precision"), "Desired precision (epsilon)",
                     value = 0.20, min = 0.0001),
        selectInput(ns("error_precision"), "Precision expressed as",
                    choices = c("Relative (fraction of the mean)" = "relative",
                                "Absolute (same units as the mean)" = "absolute")),
        numericInput(ns("conf_level_precision"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("N_precision"),
                     "Population size N (optional; leave blank for a large/community population)",
                     value = NA, min = 1)
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("mu0"), "mu0 (reference mean)", value = 120),
        numericInput(ns("mu1_single"), "mu1 (expected mean)", value = 125),
        numericInput(ns("sd_single"), "sd (expected standard deviation)",
                     value = 15, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("two_sample"),
        numericInput(ns("mu1_two"), "mu1 (group 1 mean)", value = 12.5),
        numericInput(ns("mu2_two"), "mu2 (group 2 mean)", value = 11.5),
        numericInput(ns("sd_two"), "sd (common/pooled standard deviation)",
                     value = 2, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("two_sample_unequal_n"),
        numericInput(ns("mu1_unequal"), "mu1 (group 1 mean)", value = 10),
        numericInput(ns("mu2_unequal"), "mu2 (group 2 mean)", value = 9.4),
        numericInput(ns("sd_unequal"), "sd (common/pooled standard deviation)",
                     value = 1, min = 0.0001),
        numericInput(ns("n1_unequal"), "n1 (group 1 size, already fixed)",
                     value = 90, min = 2, step = 1)
      ),
      conditionalPanel(
        condition = design_is("paired"),
        numericInput(ns("mean_diff"), "Mean of the paired differences", value = 2),
        numericInput(ns("sd_diff"), "SD of the paired differences",
                     value = 5, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("anova"),
        selectInput(ns("k"), "Number of groups (k)", choices = 3:8, selected = 3),
        # Dynamically rendered below: one mean input per group, since the
        # number of inputs depends on k -- see props_ui in mod_agreement.R
        # for the same pattern.
        uiOutput(ns("group_means_ui")),
        numericInput(ns("sd_anova"), "Common/pooled standard deviation",
                     value = 4, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is_not("single_precision"),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("single", "two_sample", "two_sample_unequal_n", "paired"),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(means_content$single_precision$title),
      render_formula_block(means_content$single_precision$formula_latex),
      shiny::markdown(means_content$single_precision$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$single_precision$worked_example),
      hr(),
      h4(means_content$single$title),
      render_formula_block(means_content$single$formula_latex),
      shiny::markdown(means_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$single$worked_example),
      hr(),
      h4(means_content$two_sample$title),
      render_formula_block(means_content$two_sample$formula_latex),
      shiny::markdown(means_content$two_sample$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$two_sample$worked_example),
      hr(),
      h4(means_content$two_sample_unequal_n$title),
      render_formula_block(means_content$two_sample_unequal_n$formula_latex),
      shiny::markdown(means_content$two_sample_unequal_n$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$two_sample_unequal_n$worked_example),
      hr(),
      h4(means_content$paired$title),
      render_formula_block(means_content$paired$formula_latex),
      shiny::markdown(means_content$paired$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$paired$worked_example),
      hr(),
      h4(means_content$anova$title),
      render_formula_block(means_content$anova$formula_latex),
      shiny::markdown(means_content$anova$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$anova$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(means_content$single_precision$title),
      p(strong("Citation: "), means_content$single_precision$citation),
      p(strong("Implemented via: "), code(means_content$single_precision$backend)),
      hr(),
      h4(means_content$single$title),
      p(strong("Citation: "), means_content$single$citation),
      p(strong("Implemented via: "), code(means_content$single$backend)),
      hr(),
      h4(means_content$two_sample$title),
      p(strong("Citation: "), means_content$two_sample$citation),
      p(strong("Implemented via: "), code(means_content$two_sample$backend)),
      hr(),
      h4(means_content$two_sample_unequal_n$title),
      p(strong("Citation: "), means_content$two_sample_unequal_n$citation),
      p(strong("Implemented via: "), code(means_content$two_sample_unequal_n$backend)),
      hr(),
      h4(means_content$paired$title),
      p(strong("Citation: "), means_content$paired$citation),
      p(strong("Implemented via: "), code(means_content$paired$backend)),
      hr(),
      h4(means_content$anova$title),
      p(strong("Citation: "), means_content$anova$citation),
      p(strong("Implemented via: "), code(means_content$anova$backend))
    )
  )
}

mod_means_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$group_means_ui <- renderUI({
      req(input$k)
      k <- as.integer(input$k)
      defaults <- seq(9, by = 1, length.out = k)
      tagList(lapply(seq_len(k), function(i) {
        numericInput(session$ns(paste0("group_mean_", i)),
                     sprintf("Mean of group %d", i), value = defaults[i])
      }))
    })

    result <- reactive({
      req(input$design)

      if (input$design == "single_precision") {
        req(input$mean_precision, input$sd_precision, input$epsilon_precision,
            input$error_precision, input$conf_level_precision)
        N <- input$N_precision
        if (is.null(N) || is.na(N)) N <- NULL
        return(tryCatch(
          list(ok = TRUE, value = calc_means_single_precision(
            mean = input$mean_precision, sd = input$sd_precision,
            epsilon = input$epsilon_precision, error = input$error_precision,
            conf_level = input$conf_level_precision, N = N
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        ))
      }

      req(input$alpha, input$power)

      if (input$design == "anova") {
        req(input$k, input$sd_anova)
        k <- as.integer(input$k)
        mean_vals <- lapply(seq_len(k), function(i) input[[paste0("group_mean_", i)]])
        req(!any(vapply(mean_vals, is.null, logical(1))))
        group_means <- as.numeric(unlist(mean_vals))

        return(tryCatch(
          list(ok = TRUE, value = calc_means_anova(
            group_means = group_means, sd = input$sd_anova,
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        ))
      }

      req(input$alternative)

      if (input$design == "single") {
        req(input$mu0, input$mu1_single, input$sd_single)
        tryCatch(
          list(ok = TRUE, value = calc_means_1s(
            mu0 = input$mu0, mu1 = input$mu1_single, sd = input$sd_single,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "two_sample") {
        req(input$mu1_two, input$mu2_two, input$sd_two)
        tryCatch(
          list(ok = TRUE, value = calc_means_2s_indep(
            mu1 = input$mu1_two, mu2 = input$mu2_two, sd = input$sd_two,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "two_sample_unequal_n") {
        req(input$mu1_unequal, input$mu2_unequal, input$sd_unequal, input$n1_unequal)
        tryCatch(
          list(ok = TRUE, value = calc_means_2s_unequal_n(
            mu1 = input$mu1_unequal, mu2 = input$mu2_unequal, sd = input$sd_unequal,
            n1 = input$n1_unequal, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$mean_diff, input$sd_diff)
        tryCatch(
          list(ok = TRUE, value = calc_means_paired(
            mean_diff = input$mean_diff, sd_diff = input$sd_diff,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
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
      if (input$design == "single_precision") {
        tagList(
          p(strong("Required sample size: "), v$n),
          if (!is.null(v$N)) p(sprintf("(finite population correction applied, N = %s)", v$N))
        )
      } else if (input$design == "two_sample") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      } else if (input$design == "two_sample_unequal_n") {
        tagList(
          p(strong("Required size of group 2: "), v$n2),
          p(sprintf("(group 1 fixed at n1 = %d; total n = %d)", v$n1, v$n_total)),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      } else if (input$design == "anova") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Effect size f = %.4f", v$f))
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      }
    })
  })
}
