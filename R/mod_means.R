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
          "Two independent means, unequal variances (Welch's t-test)" = "welch",
          "Two paired means (before-after, matched pairs)" = "paired",
          "Three or more independent groups (one-way ANOVA)" = "anova",
          "Planned linear contrast (k-group means)" = "planned_contrast",
          "Post-hoc pairwise comparison (Bonferroni-adjusted)" = "posthoc_pairwise"
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
        condition = design_is("welch"),
        numericInput(ns("mu1_welch"), "mu1 (group 1 mean)", value = 0),
        numericInput(ns("mu2_welch"), "mu2 (group 2 mean)", value = 0.5),
        numericInput(ns("sd1_welch"), "sd1 (group 1 standard deviation)",
                     value = 1, min = 0.0001),
        numericInput(ns("sd2_welch"), "sd2 (group 2 standard deviation)",
                     value = 2, min = 0.0001),
        numericInput(ns("ratio_welch"), "Allocation ratio (group 2 : group 1)",
                     value = 1, min = 0.1, step = 0.1)
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
        condition = design_is("planned_contrast"),
        selectInput(ns("k_contrast"), "Number of groups (k)", choices = 2:8, selected = 4),
        numericInput(ns("sigma_contrast"), "Common/pooled standard deviation",
                     value = 0.22, min = 0.0001, step = 0.01),
        p(class = "text-muted",
          "For each group: mu = expected mean, c = contrast coefficient (must",
          "sum to 0 across groups), f = share of the total sample (must sum to 1)."),
        uiOutput(ns("contrast_ui"))
      ),
      conditionalPanel(
        condition = design_is("posthoc_pairwise"),
        numericInput(ns("tau_posthoc"), "Number of pairwise comparisons planned (tau)",
                     value = 3, min = 1, step = 1),
        numericInput(ns("sigma_posthoc"), "Common/pooled standard deviation",
                     value = 4, min = 0.0001),
        numericInput(ns("margin_posthoc"), "Assumed difference between this pair's means",
                     value = 3)
      ),
      conditionalPanel(
        condition = design_is_not("single_precision"),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("single", "two_sample", "two_sample_unequal_n", "welch", "paired"),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
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
      h4(means_content$welch$title),
      render_formula_block(means_content$welch$formula_latex),
      shiny::markdown(means_content$welch$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$welch$worked_example),
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
      shiny::markdown(means_content$anova$worked_example),
      hr(),
      h4(means_content$planned_contrast$title),
      render_formula_block(means_content$planned_contrast$formula_latex),
      shiny::markdown(means_content$planned_contrast$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$planned_contrast$worked_example),
      hr(),
      h4(means_content$posthoc_pairwise$title),
      render_formula_block(means_content$posthoc_pairwise$formula_latex),
      shiny::markdown(means_content$posthoc_pairwise$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$posthoc_pairwise$worked_example)
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
      h4(means_content$welch$title),
      p(strong("Citation: "), means_content$welch$citation),
      p(strong("Implemented via: "), code(means_content$welch$backend)),
      hr(),
      h4(means_content$paired$title),
      p(strong("Citation: "), means_content$paired$citation),
      p(strong("Implemented via: "), code(means_content$paired$backend)),
      hr(),
      h4(means_content$anova$title),
      p(strong("Citation: "), means_content$anova$citation),
      p(strong("Implemented via: "), code(means_content$anova$backend)),
      hr(),
      h4(means_content$planned_contrast$title),
      p(strong("Citation: "), means_content$planned_contrast$citation),
      p(strong("Implemented via: "), code(means_content$planned_contrast$backend)),
      hr(),
      h4(means_content$posthoc_pairwise$title),
      p(strong("Citation: "), means_content$posthoc_pairwise$citation),
      p(strong("Implemented via: "), code(means_content$posthoc_pairwise$backend))
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

    output$contrast_ui <- renderUI({
      req(input$k_contrast)
      k <- as.integer(input$k_contrast)
      default_f <- round(1 / k, 3)
      tagList(lapply(seq_len(k), function(i) {
        fluidRow(
          column(4, numericInput(session$ns(paste0("contrast_mu_", i)), sprintf("Group %d: mu", i), value = 0)),
          column(4, numericInput(session$ns(paste0("contrast_c_", i)), sprintf("Group %d: c", i), value = 0, step = 0.5)),
          column(4, numericInput(session$ns(paste0("contrast_f_", i)), sprintf("Group %d: f", i),
                                  value = default_f, min = 0.001, max = 0.999, step = 0.01))
        )
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

      if (input$design == "planned_contrast") {
        req(input$k_contrast, input$sigma_contrast)
        k <- as.integer(input$k_contrast)
        mu_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_mu_", i)]])
        c_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_c_", i)]])
        f_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_f_", i)]])
        req(!any(vapply(mu_vals, is.null, logical(1))),
            !any(vapply(c_vals, is.null, logical(1))),
            !any(vapply(f_vals, is.null, logical(1))))

        return(tryCatch(
          list(ok = TRUE, value = calc_means_planned_contrast(
            mu = as.numeric(unlist(mu_vals)), sigma = input$sigma_contrast,
            ci = as.numeric(unlist(c_vals)), fi = as.numeric(unlist(f_vals)),
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        ))
      }

      if (input$design == "posthoc_pairwise") {
        req(input$tau_posthoc, input$sigma_posthoc, input$margin_posthoc)
        return(tryCatch(
          list(ok = TRUE, value = calc_means_posthoc_pairwise(
            tau = input$tau_posthoc, sigma = input$sigma_posthoc,
            margin = input$margin_posthoc, alpha = input$alpha, power = input$power
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
      } else if (input$design == "welch") {
        req(input$mu1_welch, input$mu2_welch, input$sd1_welch, input$sd2_welch, input$ratio_welch)
        tryCatch(
          list(ok = TRUE, value = calc_means_welch(
            mu1 = input$mu1_welch, mu2 = input$mu2_welch,
            sd1 = input$sd1_welch, sd2 = input$sd2_welch,
            ratio = input$ratio_welch, alpha = input$alpha, power = input$power,
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
      } else if (input$design == "planned_contrast") {
        tagList(
          p(strong("Required total sample size: "), v$n_total),
          p("Per-group allocation (approximate, from rounding each group's share): ",
            paste(sprintf("group %d = %d", seq_along(v$n_per_group), v$n_per_group), collapse = "; "))
        )
      } else if (input$design == "posthoc_pairwise") {
        tagList(
          p(strong("Required sample size per group (this pair): "), v$n_per_group)
        )
      } else if (input$design == "welch") {
        tagList(
          p(strong("Required sample size: "), sprintf("n1 = %d, n2 = %d", v$n1, v$n2)),
          p(strong("Total sample size: "), v$n_total)
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      }
    })

    render_export_handlers(output, result, function() means_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): wired for the four designs with a
    # single scalar effect parameter and a power argument to vary.
    # "single_precision" has no power argument; "anova"/"planned_contrast"
    # have a vector of group means rather than one scalar effect size;
    # "posthoc_pairwise" is left for a later batch -- same incremental
    # rollout as items 8/9.
    render_power_curves(output, function() {
      if (input$design == "single") {
        req(input$mu0, input$mu1_single, input$sd_single, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_1s,
          args = list(mu0 = input$mu0, mu1 = input$mu1_single, sd = input$sd_single,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mu1", values = curve_range_around(input$mu0, 3 * input$sd_single),
                        label = "mu1 (expected mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "two_sample") {
        req(input$mu1_two, input$mu2_two, input$sd_two, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_2s_indep,
          args = list(mu1 = input$mu1_two, mu2 = input$mu2_two, sd = input$sd_two,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(input$mu1_two, 3 * input$sd_two),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "welch") {
        req(input$mu1_welch, input$mu2_welch, input$sd1_welch, input$sd2_welch,
            input$ratio_welch, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_welch,
          args = list(mu1 = input$mu1_welch, mu2 = input$mu2_welch,
                       sd1 = input$sd1_welch, sd2 = input$sd2_welch, ratio = input$ratio_welch,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(input$mu1_welch, 3 * input$sd1_welch),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "paired") {
        req(input$mean_diff, input$sd_diff, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_paired,
          args = list(mean_diff = input$mean_diff, sd_diff = input$sd_diff,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mean_diff", values = curve_range_around(0, 3 * input$sd_diff),
                        label = "mean_diff (mean of paired differences)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "posthoc_pairwise") {
        req(input$tau_posthoc, input$sigma_posthoc, input$margin_posthoc, input$alpha, input$power)
        list(
          calc_fn = calc_means_posthoc_pairwise,
          args = list(tau = input$tau_posthoc, sigma = input$sigma_posthoc, margin = input$margin_posthoc,
                       alpha = input$alpha, power = input$power),
          effect = list(param = "margin", values = curve_range_multiplicative(abs(input$margin_posthoc)),
                        label = "Assumed difference between this pair's means"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "anova") {
        # The effect is a whole vector of group means, so the curve scales
        # the differences between them (1 = as entered) via an adapter.
        req(input$k, input$sd_anova, input$alpha, input$power)
        k <- as.integer(input$k)
        mean_vals <- lapply(seq_len(k), function(i) input[[paste0("group_mean_", i)]])
        req(!any(vapply(mean_vals, is.null, logical(1))))
        group_means <- as.numeric(unlist(mean_vals))
        anova_by_scale <- function(group_means, scale, sd, alpha, power) {
          calc_means_anova(group_means = curve_scale_about(group_means, mean(group_means), scale),
                           sd = sd, alpha = alpha, power = power)
        }
        list(
          calc_fn = anova_by_scale,
          args = list(group_means = group_means, scale = 1, sd = input$sd_anova,
                       alpha = input$alpha, power = input$power),
          effect = list(param = "scale", values = curve_range_multiplicative(1),
                        label = "Multiplier on the differences between group means (1 = as entered)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "planned_contrast") {
        req(input$k_contrast, input$sigma_contrast, input$alpha, input$power)
        k <- as.integer(input$k_contrast)
        mu_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_mu_", i)]])
        c_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_c_", i)]])
        f_vals <- lapply(seq_len(k), function(i) input[[paste0("contrast_f_", i)]])
        req(!any(vapply(mu_vals, is.null, logical(1))), !any(vapply(c_vals, is.null, logical(1))),
            !any(vapply(f_vals, is.null, logical(1))))
        mu <- as.numeric(unlist(mu_vals))
        contrast_by_scale <- function(mu, scale, sigma, ci, fi, alpha, power) {
          calc_means_planned_contrast(mu = curve_scale_about(mu, mean(mu), scale), sigma = sigma,
                                      ci = ci, fi = fi, alpha = alpha, power = power)
        }
        list(
          calc_fn = contrast_by_scale,
          args = list(mu = mu, scale = 1, sigma = input$sigma_contrast, ci = as.numeric(unlist(c_vals)),
                       fi = as.numeric(unlist(f_vals)), alpha = input$alpha, power = input$power),
          effect = list(param = "scale", values = curve_range_multiplicative(1),
                        label = "Multiplier on the differences between group means (1 = as entered)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "single_precision") {
        req(input$mean_precision, input$sd_precision, input$epsilon_precision,
            input$error_precision, input$conf_level_precision)
        N <- input$N_precision
        if (is.null(N) || is.na(N)) N <- NULL
        list(
          calc_fn = calc_means_single_precision,
          args = list(mean = input$mean_precision, sd = input$sd_precision,
                       epsilon = input$epsilon_precision, error = input$error_precision,
                       conf_level = input$conf_level_precision, N = N),
          effect = list(param = "sd", values = curve_range_multiplicative(input$sd_precision),
                      label = "sd (expected standard deviation)",
                      title = "Required n vs. expected standard deviation"),
          power = list(param = "epsilon", values = curve_range_multiplicative(input$epsilon_precision, 0.25, 3),
                      label = "epsilon (desired precision)",
                      title = "Required n vs. precision (epsilon)")
        )
      } else if (input$design == "two_sample_unequal_n") {
        req(input$mu1_unequal, input$mu2_unequal, input$sd_unequal, input$n1_unequal,
            input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_2s_unequal_n,
          args = list(mu1 = input$mu1_unequal, mu2 = input$mu2_unequal, sd = input$sd_unequal,
                       n1 = input$n1_unequal, alpha = input$alpha, power = input$power,
                       alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(input$mu1_unequal, 3 * input$sd_unequal),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else {
        NULL
      }
    })
  })
}
