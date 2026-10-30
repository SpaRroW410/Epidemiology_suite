# Multiplicity Adjustment module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same module contract as mod_means.R (docs/SDD.md
# #8) -- a "base test" radio selects which of this app's own already-
# verified formulas to re-run with a Bonferroni/Sidak-adjusted alpha.

multiplicity_meta <- list(
  id = "multiplicity",
  nav_title = "Multiplicity Adjustment"
)

mod_multiplicity_ui <- function(id) {
  ns <- NS(id)

  # See mod_proportion.R for why conditionalPanel() conditions are built
  # with ns() rather than hardcoded -- same reasoning applies here.
  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Base test to re-run with the adjusted alpha",
        choices = c(
          "One proportion vs. reference" = "proportion_1s",
          "Two independent proportions" = "proportion_2s",
          "One mean vs. reference" = "means_1s",
          "Two independent means" = "means_2s",
          "Two independent means, FDR (Benjamini-Hochberg)-controlled" = "fdr_means_2s",
          "Two-sample microarray/genomics, FDR-controlled (exact)" = "fdr_microarray",
          "Multi-arm trial vs. common control (Dunnett)" = "dunnett"
        ),
        selected = "proportion_2s"
      ),
      conditionalPanel(
        condition = design_is("proportion_1s"),
        numericInput(ns("p0"), "p0 (reference proportion)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p1_prop1s"), "p1 (expected proportion)", value = 0.65, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("proportion_2s"),
        numericInput(ns("p1"), "p1 (group 1 proportion)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2"), "p2 (group 2 proportion)", value = 0.65, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("means_1s"),
        numericInput(ns("mu0"), "mu0 (reference mean)", value = 0),
        numericInput(ns("mu1_means1s"), "mu1 (expected mean)", value = 0.5),
        numericInput(ns("sd_1s"), "sd (expected standard deviation)", value = 1, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("means_2s"),
        numericInput(ns("mu1_means2s"), "mu1 (group 1 mean)", value = 10),
        numericInput(ns("mu2_means2s"), "mu2 (group 2 mean)", value = 12),
        numericInput(ns("sd_2s"), "sd (common/pooled standard deviation)", value = 5, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("fdr_means_2s"),
        numericInput(ns("d_fdr"), "Cohen's d (effect size for the truly non-null tests)",
                     value = 1, min = 0.001, step = 0.1),
        numericInput(ns("pi1_fdr"), "pi1 (assumed proportion of the m tests that are truly non-null)",
                     value = 0.25, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("fdr_level"), "Target false discovery rate (FDR)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("fdr_microarray"),
        numericInput(ns("delta_fdrma"), "delta (common difference in mean expression between groups)",
                     value = 1, step = 0.1),
        numericInput(ns("sigma_fdrma"), "sigma (common within-group standard deviation)",
                     value = 0.5, min = 0.0001, step = 0.1),
        numericInput(ns("pi0_fdrma"), "pi0 (assumed proportion of genes/tests that are truly NOT differentially expressed)",
                     value = 0.95, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("fdr_level_fdrma"), "Target false discovery rate (FDR)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("max_n_fdrma"), "Maximum per-group sample size to search up to",
                     value = 35, min = 3, step = 1),
        selectInput(ns("side_fdrma"), "Alternative",
                    choices = c("Two-sided" = "two-sided", "Upper" = "upper", "Lower" = "lower")),
        numericInput(ns("power_fdrma"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("dunnett"),
        numericInput(ns("d_dunnett"), "Cohen's d (same for every active arm vs. control)",
                     value = 0.5, min = 0.001, step = 0.1),
        numericInput(ns("k_dunnett"), "Number of active (non-control) arms, k", value = 3, min = 2, step = 1)
      ),
      hr(),
      conditionalPanel(
        condition = paste0("!(", design_is("dunnett", "fdr_microarray"), ")"),
        numericInput(ns("m"), "Number of planned simultaneous comparisons (m)", value = 4, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = paste0("!(", design_is("fdr_means_2s", "fdr_microarray"), ")"),
        numericInput(ns("alpha"), "Family-wise significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01)
      ),
      conditionalPanel(
        condition = paste0("!(", design_is("fdr_means_2s", "fdr_microarray", "dunnett"), ")"),
        radioButtons(
          ns("method"), "Correction method",
          choices = c("Bonferroni (always valid)" = "bonferroni",
                      "Sidak (exact under independence)" = "sidak"),
          selected = "bonferroni"
        )
      ),
      advanced_options_ui(
        ns, condition = paste0("!(", design_is("fdr_means_2s", "fdr_microarray", "dunnett"), ")"),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = paste0("!(", design_is("fdr_microarray"), ")"),
        numericInput(ns("power"), "Desired power (average power, for the FDR design; per-comparison power otherwise)", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
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
      h4(multiplicity_content$overview$title),
      render_formula_block(multiplicity_content$overview$formula_latex),
      shiny::markdown(multiplicity_content$overview$explanation),
      h5("Worked example"),
      shiny::markdown(multiplicity_content$overview$worked_example),
      hr(),
      h4(multiplicity_content$fdr$title),
      render_formula_block(multiplicity_content$fdr$formula_latex),
      shiny::markdown(multiplicity_content$fdr$explanation),
      h5("Worked example"),
      shiny::markdown(multiplicity_content$fdr$worked_example),
      hr(),
      h4(multiplicity_content$fdr_microarray$title),
      render_formula_block(multiplicity_content$fdr_microarray$formula_latex),
      shiny::markdown(multiplicity_content$fdr_microarray$explanation),
      h5("Worked example"),
      shiny::markdown(multiplicity_content$fdr_microarray$worked_example),
      hr(),
      h4(multiplicity_content$dunnett$title),
      render_formula_block(multiplicity_content$dunnett$formula_latex),
      shiny::markdown(multiplicity_content$dunnett$explanation),
      h5("Worked example"),
      shiny::markdown(multiplicity_content$dunnett$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(multiplicity_content$overview$title),
      p(strong("Citation: "), multiplicity_content$overview$citation),
      p(strong("Implemented via: "), code(multiplicity_content$overview$backend)),
      hr(),
      h4(multiplicity_content$fdr$title),
      p(strong("Citation: "), multiplicity_content$fdr$citation),
      p(strong("Implemented via: "), code(multiplicity_content$fdr$backend)),
      hr(),
      h4(multiplicity_content$fdr_microarray$title),
      p(strong("Citation: "), multiplicity_content$fdr_microarray$citation),
      p(strong("Implemented via: "), code(multiplicity_content$fdr_microarray$backend)),
      hr(),
      h4(multiplicity_content$dunnett$title),
      p(strong("Citation: "), multiplicity_content$dunnett$citation),
      p(strong("Implemented via: "), code(multiplicity_content$dunnett$backend))
    )
  )
}

mod_multiplicity_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$m, input$power)
      tryCatch(
        list(ok = TRUE, value = switch(
          input$design,
          proportion_1s = {
            req(input$p0, input$p1_prop1s, input$method, input$alpha, input$alternative)
            calc_multiplicity_proportion_1s(
              p0 = input$p0, p1 = input$p1_prop1s, m = input$m, method = input$method,
              alpha = input$alpha, power = input$power, alternative = input$alternative
            )
          },
          proportion_2s = {
            req(input$p1, input$p2, input$method, input$alpha, input$alternative)
            calc_multiplicity_proportion_2s(
              p1 = input$p1, p2 = input$p2, m = input$m, method = input$method,
              alpha = input$alpha, power = input$power, alternative = input$alternative
            )
          },
          means_1s = {
            req(input$mu0, input$mu1_means1s, input$sd_1s, input$method, input$alpha, input$alternative)
            calc_multiplicity_means_1s(
              mu0 = input$mu0, mu1 = input$mu1_means1s, sd = input$sd_1s, m = input$m,
              method = input$method, alpha = input$alpha, power = input$power,
              alternative = input$alternative
            )
          },
          means_2s = {
            req(input$mu1_means2s, input$mu2_means2s, input$sd_2s, input$method, input$alpha, input$alternative)
            calc_multiplicity_means_2s(
              mu1 = input$mu1_means2s, mu2 = input$mu2_means2s, sd = input$sd_2s, m = input$m,
              method = input$method, alpha = input$alpha, power = input$power,
              alternative = input$alternative
            )
          },
          fdr_means_2s = {
            req(input$d_fdr, input$pi1_fdr, input$fdr_level)
            calc_multiplicity_fdr_means(
              d = input$d_fdr, m = input$m, pi1 = input$pi1_fdr,
              fdr_level = input$fdr_level, power = input$power
            )
          },
          fdr_microarray = {
            req(input$delta_fdrma, input$sigma_fdrma, input$pi0_fdrma,
                input$fdr_level_fdrma, input$max_n_fdrma, input$side_fdrma, input$power_fdrma)
            calc_fdr_microarray_two_sample(
              delta = input$delta_fdrma, sigma = input$sigma_fdrma,
              fdr_level = input$fdr_level_fdrma, power = input$power_fdrma,
              pi0 = input$pi0_fdrma, max_n = as.integer(input$max_n_fdrma),
              side = input$side_fdrma
            )
          },
          dunnett = {
            req(input$d_dunnett, input$k_dunnett, input$alpha)
            calc_multiplicity_dunnett(
              d = input$d_dunnett, k = as.integer(input$k_dunnett),
              alpha = input$alpha, power = input$power
            )
          }
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
      if (input$design == "fdr_microarray") {
        tagList(
          p(strong("Required sample size: "), v$n_per_group, " per group (", v$n_total, " total)"),
          p(sprintf("Achieved power = %.4f (critical value = %.3f, pi0 = %.3f, FDR level = %.3f)",
                     v$achieved_power, v$critical_value, v$inputs$pi0, v$inputs$fdr_level))
        )
      } else if (!is.null(v$alpha_star)) {
        tagList(
          p(strong("Required sample size: "), v$n_per_group, " per group (", v$n_total, " total)"),
          p(sprintf("Per-test alpha* = %.5f (m = %d, m1 = %d truly non-null, m0 = %d truly null, FDR level = %.3f)",
                     v$alpha_star, v$m, v$m1, v$m0, v$inputs$fdr_level))
        )
      } else if (!is.null(v$n_per_arm)) {
        tagList(
          p(strong("Required sample size: "), v$n_per_arm, " per arm (", v$n_total,
            sprintf(" total, %d arms including control)", v$k + 1)),
          p(sprintf("Dunnett critical value = %.3f (k = %d active arms vs. control); achieved power = %.3f",
                     v$critical_value, v$k, v$achieved_power))
        )
      } else {
        n_line <- if (!is.null(v$n_total)) {
          p(strong("Required sample size: "), v$n_per_group, " per group (", v$n_total, " total)")
        } else {
          p(strong("Required total sample size: "), v$n)
        }
        tagList(
          n_line,
          p(sprintf("Adjusted per-comparison alpha = %.5f (from family-wise alpha = %.3f, m = %d, %s)",
                     v$alpha_adjusted, v$inputs$alpha_family, v$m, v$method))
        )
      }
    })

    render_export_handlers(output, result, function() {
      key <- input$design
      remap <- c("proportion_1s" = "overview", "proportion_2s" = "overview", "means_1s" = "overview", "means_2s" = "overview", "fdr_means_2s" = "fdr")
      multiplicity_content[[if (key %in% names(remap)) remap[[key]] else key]]
    })

    # Power curves (ROADMAP P1 item 10): wired for the four designs that
    # re-run an already-wired single-effect base test (proportion_1s/2s,
    # means_1s/2s). "fdr_means_2s" and "fdr_microarray" use a different
    # power concept (average/FDR-level power, not family-wise alpha) and
    # are left for a later batch. "dunnett" has a single scalar effect
    # (Cohen's d) but calc_multiplicity_dunnett() is NOT wired here: each
    # call does an internal mvtnorm::qmvt() root search (~1.4s), so a
    # 40-point grid takes ~47s per curve (measured) -- unusable in a plain
    # reactive. It would need a Calculate-button-gated pattern like the
    # Monte Carlo designs (item 7's monte_carlo_calculate_ui()), not a
    # live curve; left for a dedicated follow-up.
    render_power_curves(output, function() {
      if (input$design == "proportion_1s") {
        req(input$p0, input$p1_prop1s, input$m, input$method, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_multiplicity_proportion_1s,
          args = list(p0 = input$p0, p1 = input$p1_prop1s, m = input$m, method = input$method,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "p1", values = curve_range_proportion(), label = "p1 (expected proportion)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "proportion_2s") {
        req(input$p1, input$p2, input$m, input$method, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_multiplicity_proportion_2s,
          args = list(p1 = input$p1, p2 = input$p2, m = input$m, method = input$method,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "p2", values = curve_range_proportion(), label = "p2 (group 2 proportion)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "means_1s") {
        req(input$mu0, input$mu1_means1s, input$sd_1s, input$m, input$method,
            input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_multiplicity_means_1s,
          args = list(mu0 = input$mu0, mu1 = input$mu1_means1s, sd = input$sd_1s, m = input$m,
                       method = input$method, alpha = input$alpha, power = input$power,
                       alternative = input$alternative),
          effect = list(param = "mu1", values = curve_range_around(input$mu0, 3 * input$sd_1s),
                        label = "mu1 (expected mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "means_2s") {
        req(input$mu1_means2s, input$mu2_means2s, input$sd_2s, input$m, input$method,
            input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_multiplicity_means_2s,
          args = list(mu1 = input$mu1_means2s, mu2 = input$mu2_means2s, sd = input$sd_2s, m = input$m,
                       method = input$method, alpha = input$alpha, power = input$power,
                       alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(input$mu1_means2s, 3 * input$sd_2s),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "fdr_means_2s") {
        req(input$d_fdr, input$pi1_fdr, input$fdr_level, input$m, input$power)
        list(
          calc_fn = calc_multiplicity_fdr_means,
          args = list(d = input$d_fdr, m = input$m, pi1 = input$pi1_fdr,
                       fdr_level = input$fdr_level, power = input$power),
          effect = list(param = "d", values = curve_range_multiplicative(input$d_fdr), label = "Cohen's d"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "fdr_microarray") {
        req(input$delta_fdrma, input$sigma_fdrma, input$pi0_fdrma, input$fdr_level_fdrma,
            input$max_n_fdrma, input$side_fdrma, input$power_fdrma)
        list(
          calc_fn = calc_fdr_microarray_two_sample,
          args = list(delta = input$delta_fdrma, sigma = input$sigma_fdrma,
                       fdr_level = input$fdr_level_fdrma, power = input$power_fdrma,
                       pi0 = input$pi0_fdrma, max_n = as.integer(input$max_n_fdrma),
                       side = input$side_fdrma),
          effect = list(param = "delta", values = curve_range_multiplicative(abs(input$delta_fdrma)),
                        label = "delta (difference in mean expression)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "dunnett") {
        req(input$d_dunnett, input$k_dunnett, input$alpha, input$power)
        list(
          calc_fn = calc_multiplicity_dunnett,
          args = list(d = input$d_dunnett, k = as.integer(input$k_dunnett),
                       alpha = input$alpha, power = input$power),
          effect = list(param = "d", values = curve_range_multiplicative(input$d_dunnett, n = 8),
                        label = "Cohen's d"),
          power = list(param = "power", values = curve_range_power(n = 8)),
          gated = list(note = "Each point needs a multivariate-t quantile search (~1.4 s), so these 16 points take about 20-25 seconds.")
        )
      } else {
        NULL
      }
    }, input = input)
  })
}
