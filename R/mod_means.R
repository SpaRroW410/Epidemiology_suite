# Means module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R (docs/SDD.md #8) --
# UI + server + metadata, so this file is itself a template for the next
# t-test-adjacent module.

means_meta <- list(
  id = "means",
  nav_title = "Means"
)


# --- the effect of a two-group comparison, as OpenEpi's mean-difference form takes it: both means or their difference (or Cohen's d), and
# a standard deviation or a variance ------------------------------------------------------------------------------------------------
# `sfx` is the design's id suffix ("two", "unequal", "welch"): the means keep their old ids mu1_<sfx>, mu2_<sfx>, and the SDs sd_<sfx> (one common
# SD) or sd1_<sfx>, sd2_<sfx> (separate SDs, `separate = TRUE`).
.means_effect_ui <- function(ns, sfx, mu1, mu2, sd = NULL, sd1 = NULL, sd2 = NULL, allow_d = TRUE) {
  eff <- paste0("effect_as_", sfx); spr <- paste0("spread_as_", sfx)
  separate <- !is.null(sd1)
  id <- function(base) ns(paste0(base, "_", sfx))
  tagList(
    radioButtons(ns(eff), "Effect to detect, given as", inline = TRUE,
                 choices = c("Both means" = "means", "The difference between the means" = "diff", if (allow_d) c("Cohen's d" = "d"))),
    conditionalPanel(.sh_cond(ns, eff, "means"),
      numericInput(id("mu1"), "mu1 (group 1 mean)", value = mu1),
      numericInput(id("mu2"), "mu2 (group 2 mean)", value = mu2)),
    conditionalPanel(.sh_cond(ns, eff, "diff"), numericInput(id("diff"), "Difference between the means (group 1 minus group 2)", value = mu1 - mu2)),
    if (allow_d) conditionalPanel(.sh_cond(ns, eff, "d"), numericInput(id("d"), tagList("Cohen's d", info_tip("cohens_d")), value = 0.5, step = 0.1)),
    conditionalPanel(if (allow_d) paste0("input['", ns(eff), "'] != 'd'") else "true",
      radioButtons(ns(spr), tagList("Spread", info_tip("sd_variance")), inline = TRUE,
                   choices = c("Standard deviation" = "sd", "Variance" = "var")),
      if (separate) tagList(
        conditionalPanel(.sh_cond(ns, spr, "sd"),
          numericInput(id("sd1"), "sd1 (group 1 standard deviation)", value = sd1, min = 0.0001),
          numericInput(id("sd2"), "sd2 (group 2 standard deviation)", value = sd2, min = 0.0001)),
        conditionalPanel(.sh_cond(ns, spr, "var"),
          numericInput(id("var1"), "Variance, group 1", value = sd1^2, min = 0.0001),
          numericInput(id("var2"), "Variance, group 2", value = sd2^2, min = 0.0001)))
      else tagList(
        conditionalPanel(.sh_cond(ns, spr, "sd"), numericInput(id("sd"), "sd (common/pooled standard deviation)", value = sd, min = 0.0001)),
        conditionalPanel(.sh_cond(ns, spr, "var"), numericInput(id("var"), "Variance (common/pooled)", value = sd^2, min = 0.0001)))
    ),
    uiOutput(ns(paste0("effect_equiv_", sfx)))
  )
}

# The arguments of calc_means_*() for the chosen route (what is recorded in the export), as list(mu1 =, mu2 =, sd =) / list(diff =, variance =) / list(d =)
.means_args <- function(input, sfx, separate = FALSE) {
  get <- function(base) input[[paste0(base, "_", sfx)]]
  eff <- input[[paste0("effect_as_", sfx)]]; if (is.null(eff)) eff <- "means"
  spr <- input[[paste0("spread_as_", sfx)]]; if (is.null(spr)) spr <- "sd"
  if (eff == "d") { req(get("d")); return(list(d = get("d"))) }
  out <- if (eff == "means") { req(get("mu1"), get("mu2")); list(mu1 = get("mu1"), mu2 = get("mu2")) } else { req(get("diff")); list(diff = get("diff")) }
  if (separate) {
    if (spr == "sd") { req(get("sd1"), get("sd2")); c(out, list(sd1 = get("sd1"), sd2 = get("sd2"))) }
    else { req(get("var1"), get("var2")); c(out, list(var1 = get("var1"), var2 = get("var2"))) }
  } else {
    if (spr == "sd") { req(get("sd")); c(out, list(sd = get("sd"))) } else { req(get("var")); c(out, list(variance = get("var"))) }
  }
}

# The same as plain numbers, for the power curves: mu1, mu2 (the difference is group 1 - group 2) and the SD(s). With a difference, mu2 = 0; with Cohen's d,
# mu1 = d, mu2 = 0 and the SD is 1.
.means_resolved <- function(input, sfx, separate = FALSE) {
  a <- .means_args(input, sfx, separate)
  sdv <- function(sd, v) if (!is.null(sd)) sd else sqrt(v)
  # exact [[ ]]: `a$d` would also match `a$diff`
  if (!is.null(a[["d"]])) return(list(mu1 = a[["d"]], mu2 = 0, sd = 1, sd1 = 1, sd2 = 1))
  mu <- if (!is.null(a[["diff"]])) c(a[["diff"]], 0) else c(a[["mu1"]], a[["mu2"]])
  if (separate) list(mu1 = mu[1], mu2 = mu[2], sd1 = sdv(a[["sd1"]], a[["var1"]]), sd2 = sdv(a[["sd2"]], a[["var2"]]))
  else list(mu1 = mu[1], mu2 = mu[2], sd = sdv(a[["sd"]], a[["variance"]]))
}

# One line under the inputs: the difference, the SD(s) and the Cohen's d they give
.means_effect_server <- function(input, output, sfx, separate = FALSE) {
  output[[paste0("effect_equiv_", sfx)]] <- renderUI({
    r <- tryCatch(.means_resolved(input, sfx, separate), shiny.silent.error = function(e) NULL, error = function(e) NULL)
    if (is.null(r)) return(NULL)
    sd_txt <- if (separate) sprintf("SDs %s and %s", .sh_fmt(r$sd1, 4), .sh_fmt(r$sd2, 4)) else sprintf("SD %s", .sh_fmt(r$sd, 4))
    sp <- if (separate) sqrt((r$sd1^2 + r$sd2^2) / 2) else r$sd
    div(class = "text-muted small mb-2", sprintf("Difference %s, %s: Cohen's d = %s (using %s).", .sh_fmt(r$mu1 - r$mu2, 4), sd_txt,
                                                 formatC(abs(r$mu1 - r$mu2) / sp, digits = 3, format = "f"),
                                                 if (separate) "the average of the two variances" else "the common SD"))
  })
}


# The spread of the paired differences: the SD itself, or the two SDs and their correlation
.paired_sd_args <- function(input) {
  if (identical(input$paired_sd_as, "sds_r")) { req(input$paired_sd1, input$paired_sd2, input$paired_r); list(sd1 = input$paired_sd1, sd2 = input$paired_sd2, r = input$paired_r) }
  else { req(input$sd_diff); list(sd_diff = input$sd_diff) }
}

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
      tags$details(
        class = "mb-3",
        tags$summary("Only have a median and IQR? Estimate the mean and SD"),
        div(class = "mt-2",
          p(class = "small text-muted",
            "Wan et al. (2014): mean = (q1 + median + q3) / 3, SD = (q3 - q1) / (2 x qnorm((0.75n - 0.125) / (n + 0.25))), about",
            "IQR / 1.35 for a large n. Enter the results as the mean(s) and SD below. The estimates assume roughly normal data; for a",
            "clearly skewed outcome a rank-based test (Wilcoxon / Mann-Whitney, in Non-Parametric Tests) is the alternative."),
          div(class = "row g-2",
            div(class = "col-6 col-md-3", numericInput(ns("iqr_median"), "Median", value = 45)),
            div(class = "col-6 col-md-3", numericInput(ns("iqr_q1"), "First quartile (q1)", value = 38)),
            div(class = "col-6 col-md-3", numericInput(ns("iqr_q3"), "Third quartile (q3)", value = 54)),
            div(class = "col-6 col-md-3", numericInput(ns("iqr_n"), "Sample size (n)", value = 60, min = 2))
          ),
          uiOutput(ns("iqr_result"))
        )
      ),
      conditionalPanel(
        condition = design_is("single_precision"),
        numericInput(ns("mean_precision"), "Expected mean (must be non-zero)", value = 75),
        numericInput(ns("sd_precision"), "Expected standard deviation",
                     value = 15, min = 0.0001),
        numericInput(ns("epsilon_precision"), "Desired precision (epsilon)",
                     value = 0.20, min = 0.0001),
        selectInput(ns("error_precision"), "Precision expressed as",
                    choices = c("Relative (fraction of the mean, e.g. 0.10 = +/- 10%)" = "relative",
                                "Absolute (same units as the mean)" = "absolute")),
        numericInput(ns("conf_level_precision"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        nonresponse_input(ns("nonresponse_precision")),
        uiOutput(ns("precision_equiv")),
        precision_guidance_ui("mean")
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
        .means_effect_ui(ns, "two", mu1 = 12.5, mu2 = 11.5, sd = 2)
      ),
      conditionalPanel(
        condition = design_is("two_sample_unequal_n"),
        .means_effect_ui(ns, "unequal", mu1 = 10, mu2 = 9.4, sd = 1),
        numericInput(ns("n1_unequal"), "n1 (group 1 size, already fixed)",
                     value = 90, min = 2, step = 1)
      ),
      conditionalPanel(
        condition = design_is("welch"),
        .means_effect_ui(ns, "welch", mu1 = 0, mu2 = 0.5, sd1 = 1, sd2 = 2, allow_d = FALSE),
        numericInput(ns("ratio_welch"), with_tip("Allocation ratio (group 2 : group 1)", "allocation_ratio"),
                     value = 1, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("paired"),
        numericInput(ns("mean_diff"), "Mean of the paired differences", value = 2),
        radioButtons(ns("paired_sd_as"), tagList("Spread of the differences", info_tip("paired_dz")), inline = TRUE,
                     choices = c("SD of the differences" = "sd_diff", "Two SDs and their correlation" = "sds_r")),
        conditionalPanel(.sh_cond(ns, "paired_sd_as", "sd_diff"),
          numericInput(ns("sd_diff"), "SD of the paired differences", value = 5, min = 0.0001)),
        conditionalPanel(.sh_cond(ns, "paired_sd_as", "sds_r"),
          fluidRow(column(6, numericInput(ns("paired_sd1"), "SD, first measurement", value = 4, min = 0.0001)),
                   column(6, numericInput(ns("paired_sd2"), "SD, second measurement", value = 4, min = 0.0001))),
          numericInput(ns("paired_r"), tagList("Correlation between the two measurements", info_tip("correlation")), value = 0.2, min = -0.99, max = 0.99, step = 0.05)),
        uiOutput(ns("paired_equiv"))
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
      advanced_options_ui(
        ns, condition = design_is("single_precision", "single", "two_sample", "two_sample_unequal_n", "welch", "paired"),
        conditionalPanel(
          condition = design_is("single_precision"),
          numericInput(ns("N_precision"),
                       "Population size N (optional; leave blank for a large/community population)",
                       value = NA, min = 1)
        ),
        conditionalPanel(
          condition = design_is("single", "two_sample", "two_sample_unequal_n", "welch", "paired"),
          selectInput(
            ns("alternative"), "Alternative hypothesis",
            choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
          )
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
    .means_effect_server(input, output, "two")
    .means_effect_server(input, output, "unequal")
    .means_effect_server(input, output, "welch", separate = TRUE)
    output$paired_equiv <- renderUI({
      a <- tryCatch(.paired_sd_args(input), shiny.silent.error = function(e) NULL, error = function(e) NULL)
      if (is.null(a) || is.null(input$mean_diff) || is.na(input$mean_diff)) return(NULL)
      e <- tryCatch(calc_es_paired(input$mean_diff, sd_diff = a$sd_diff, sd1 = a$sd1, sd2 = a$sd2, r = a$r), error = function(e) e)
      if (inherits(e, "error")) return(div(class = "text-danger small mb-2", conditionMessage(e)))
      div(class = "text-muted small mb-2", sprintf("SD of the differences %s: d for the differences (d_z) = %s.", .sh_fmt(e$sd_diff, 4),
                                                  formatC(e$d_z, digits = 3, format = "f")))
    })
    output$iqr_result <- renderUI({
      r <- tryCatch(calc_mean_sd_from_median_iqr(input$iqr_median, input$iqr_q1, input$iqr_q3, input$iqr_n), error = function(e) e)
      if (inherits(r, "error")) return(div(class = "text-danger small", conditionMessage(r)))
      p(strong(sprintf("Estimated mean %s, SD %s", format(signif(r$mean, 4)), format(signif(r$sd, 4)))),
        span(class = "text-muted small", sprintf(" (SD = IQR / %.3f)", r$divisor)))
    })
    output$precision_equiv <- renderUI({
      precision_equivalents_ui(precision_equivalents_text(input$mean_precision, input$epsilon_precision, input$error_precision,
                                                          input$conf_level_precision, "mean"))
    })
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
        N <- .input_or_null(input$N_precision)
        return(tryCatch(
          list(ok = TRUE, value = calc_means_single_precision(
            mean = input$mean_precision, sd = input$sd_precision,
            epsilon = input$epsilon_precision, error = input$error_precision,
            conf_level = input$conf_level_precision, N = N,
            nonresponse = .nonresponse_value(input$nonresponse_precision)
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
        tryCatch(
          list(ok = TRUE, value = do.call(calc_means_2s_indep, c(.means_args(input, "two"), list(
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )))),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "two_sample_unequal_n") {
        req(input$n1_unequal)
        tryCatch(
          list(ok = TRUE, value = do.call(calc_means_2s_unequal_n, c(.means_args(input, "unequal"), list(
            n1 = input$n1_unequal, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )))),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "welch") {
        req(input$ratio_welch)
        tryCatch(
          list(ok = TRUE, value = do.call(calc_means_welch, c(.means_args(input, "welch", separate = TRUE), list(
            ratio = input$ratio_welch, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )))),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$mean_diff)
        tryCatch(
          list(ok = TRUE, value = do.call(calc_means_paired, c(list(
            mean_diff = input$mean_diff), .paired_sd_args(input), list(
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )))),
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
          p(strong("Required sample size (to analyze): "), v$n),
          if (!is.null(v$N)) p(sprintf("(finite population correction applied, N = %s)", v$N)),
          nonresponse_result_ui(v$n_enrolled, v$n, v$inputs$nonresponse),
          p(sprintf("Precision (%s): +/- %s in the units of the mean = +/- %s of the mean.", v$inputs$error,
                    .prec_fmt(v$d_absolute), .prec_pct(v$epsilon_relative))),
          precision_notes_ui(v$precision_notes)
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
        r <- .means_resolved(input, "two")
        req(input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_2s_indep,
          args = list(mu1 = r$mu1, mu2 = r$mu2, sd = r$sd,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(r$mu1, 3 * r$sd),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "welch") {
        r <- .means_resolved(input, "welch", separate = TRUE)
        req(input$ratio_welch, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_welch,
          args = list(mu1 = r$mu1, mu2 = r$mu2,
                       sd1 = r$sd1, sd2 = r$sd2, ratio = input$ratio_welch,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(r$mu1, 3 * r$sd1),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "paired") {
        a <- .paired_sd_args(input)
        sdd <- if (!is.null(a$sd_diff)) a$sd_diff else calc_es_paired(input$mean_diff, sd1 = a$sd1, sd2 = a$sd2, r = a$r)$sd_diff
        req(input$mean_diff, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_paired,
          args = list(mean_diff = input$mean_diff, sd_diff = sdd,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "mean_diff", values = curve_range_around(0, 3 * sdd),
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
        r <- .means_resolved(input, "unequal")
        req(input$n1_unequal, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_means_2s_unequal_n,
          args = list(mu1 = r$mu1, mu2 = r$mu2, sd = r$sd,
                       n1 = input$n1_unequal, alpha = input$alpha, power = input$power,
                       alternative = input$alternative),
          effect = list(param = "mu2", values = curve_range_around(r$mu1, 3 * r$sd),
                        label = "mu2 (group 2 mean)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else {
        NULL
      }
    })
  })
}
