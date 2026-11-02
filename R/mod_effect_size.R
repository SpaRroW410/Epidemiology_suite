# Effect Size module (owner's request of 2 Nov 2026): work out the quantity a sample-size calculator asks for -- Cohen's d, f, h, w, an
# odds ratio, a hazard ratio -- from what is usually known. Calculate / Formula-Help / Reference sub-tabs, design-radio contract as in
# mod_rate.R (docs/SDD.md #8). The calculations are in calc_effect_size.R (and calc_median_iqr.R, calc_case_control.R), the text in
# content_effect_size.R, the (i) tips in mod_shared_info.R. The proportions design follows OpenEpi's "fill in 1 of the following" form.

effect_size_meta <- list(
  id = "effect_size",
  nav_title = "Effect Size"
)

.es_designs <- c(
  "Two means: Cohen's d and Hedges' g" = "two_means",
  "Cohen's d from a t statistic" = "from_t",
  "Paired measurements: d for the differences" = "paired_means",
  "Several means: Cohen's f" = "anova_f",
  "Two proportions: odds ratio, risk ratio, risk difference, h (also for case-control)" = "proportions",
  "Chi-square: Cohen's w" = "chisq_w",
  "Hazard ratio from median survival or survival probabilities" = "hazard_ratio",
  "Convert between d, r, odds ratio, R-squared and f-squared" = "correlation",
  "Mean and SD from a median and interquartile range" = "median_iqr",
  "Matched case-control: phi from a table of matched pairs" = "matched_pairs"
)

# "10, 12 15" -> c(10, 12, 15); stops with a plain message when something is not a number
.es_parse_numbers <- function(text, label) {
  if (is.null(text) || !nzchar(trimws(text))) stop(sprintf("Enter the %s.", label), call. = FALSE)
  v <- suppressWarnings(as.numeric(strsplit(trimws(text), "[,; \t]+")[[1]]))
  if (anyNA(v)) stop(sprintf("The %s must be numbers separated by commas or spaces.", label), call. = FALSE)
  v
}
# a table typed one row per line
.es_parse_table <- function(text) {
  rows <- Filter(nzchar, trimws(strsplit(if (is.null(text)) "" else text, "\n")[[1]]))
  if (length(rows) < 2) stop("Enter at least two rows of counts, one row per line.", call. = FALSE)
  m <- lapply(rows, .es_parse_numbers, label = "table")
  if (length(unique(lengths(m))) != 1) stop("Every row of the table must have the same number of counts.", call. = FALSE)
  do.call(rbind, m)
}
.es_opt <- function(x) if (is.null(x) || length(x) != 1 || is.na(x)) NULL else x

mod_effect_size_ui <- function(id) {
  ns <- NS(id)
  is_ <- function(input, ...) paste(sprintf("input['%s'] == '%s'", ns(input), c(...)), collapse = " || ")
  design_is <- function(...) is_("design", ...)
  num <- function(id, label, value, ...) numericInput(ns(id), label, value = value, ...)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Work out the effect size a sample-size calculator asks for from what you already know, then enter it there."),
      radioButtons(ns("design"), "What do you have, and what do you need?", choices = .es_designs, selected = "two_means"),

      # ---- two means
      conditionalPanel(
        condition = design_is("two_means"),
        radioButtons(ns("means_as"), "Group means", inline = TRUE,
                     choices = c("Enter both means" = "means", "Enter the difference" = "diff")),
        conditionalPanel(condition = is_("means_as", "means"),
          fluidRow(column(6, num("mean1", "Mean, group 1", 132.86)), column(6, num("mean2", "Mean, group 2", 127.44)))),
        conditionalPanel(condition = is_("means_as", "diff"),
          num("diff", "Difference between the means (group 1 minus group 2)", 5.42)),
        radioButtons(ns("spread_as"), tagList("Spread", info_tip("sd_variance")), inline = TRUE,
                     choices = c("Standard deviation" = "sd", "Variance" = "var")),
        conditionalPanel(condition = is_("spread_as", "sd"),
          fluidRow(column(6, num("sd1", "SD, group 1", 15.34, min = 0)), column(6, num("sd2", "SD, group 2 (blank = same as group 1)", 18.23, min = 0)))),
        conditionalPanel(condition = is_("spread_as", "var"),
          fluidRow(column(6, num("var1", "Variance, group 1", 235.32, min = 0)), column(6, num("var2", "Variance, group 2 (blank = same as group 1)", 332.33, min = 0)))),
        fluidRow(column(6, num("n1", "Group 1 size (optional)", NA, min = 2)), column(6, num("n2", "Group 2 size (optional)", NA, min = 2))),
        p(class = "text-muted small", "With both sizes you also get Hedges' g and an interval for d; without them equal group sizes are assumed.")
      ),
      # ---- from t
      conditionalPanel(
        condition = design_is("from_t"),
        num("t_stat", "t statistic", 2.4),
        radioButtons(ns("t_kind"), "Kind of test", inline = TRUE,
                     choices = c("Two independent groups" = "two", "Paired or one sample" = "paired")),
        conditionalPanel(condition = is_("t_kind", "two"),
          fluidRow(column(6, num("t_n1", "Group 1 size", 30, min = 2)), column(6, num("t_n2", "Group 2 size", 30, min = 2)))),
        conditionalPanel(condition = is_("t_kind", "paired"), num("t_n", "Number of pairs (or subjects)", 25, min = 2))
      ),
      # ---- paired
      conditionalPanel(
        condition = design_is("paired_means"),
        num("pd_mean", "Mean of the differences (after minus before)", 4),
        radioButtons(ns("pd_as"), "What do you know about the spread?",
                     choices = c("The SD of the differences" = "sd_diff",
                                 "The two SDs and their correlation" = "sds_r",
                                 "The two SDs and the SD of the differences (to find the correlation)" = "sds_sd")),
        conditionalPanel(condition = is_("pd_as", "sd_diff", "sds_sd"), num("pd_sd_diff", "SD of the differences", 11.76, min = 0)),
        conditionalPanel(condition = is_("pd_as", "sds_r", "sds_sd"),
          fluidRow(column(6, num("pd_sd1", "SD, first measurement", 12, min = 0)), column(6, num("pd_sd2", "SD, second measurement", 14, min = 0)))),
        conditionalPanel(condition = is_("pd_as", "sds_r"), num("pd_r", "Correlation between the two measurements", 0.6, min = -0.99, max = 0.99, step = 0.05))
      ),
      # ---- f
      conditionalPanel(
        condition = design_is("anova_f"),
        radioButtons(ns("f_from"), "Work out f from", inline = FALSE,
                     choices = c("The group means and the SD" = "means", "Eta-squared" = "eta2", "An F statistic" = "F", "Cohen's d (two groups)" = "d")),
        conditionalPanel(condition = is_("f_from", "means"),
          textInput(ns("f_means"), "Group means (separated by commas)", "10, 12, 15"),
          num("f_sd", tagList("Common SD within groups", info_tip("sd_variance")), 6, min = 0),
          textInput(ns("f_n"), "Group sizes, same order (optional)", "")),
        conditionalPanel(condition = is_("f_from", "eta2"), num("f_eta2", tagList("Eta-squared", info_tip("eta2")), 0.06, min = 0, max = 0.99, step = 0.01)),
        conditionalPanel(condition = is_("f_from", "F"),
          fluidRow(column(4, num("f_F", "F statistic", 4.2, min = 0)), column(4, num("f_df1", "Numerator df", 2, min = 1)), column(4, num("f_df2", "Denominator df", 87, min = 1)))),
        conditionalPanel(condition = is_("f_from", "d"), num("f_d", "Cohen's d", 0.5))
      ),
      # ---- proportions
      conditionalPanel(
        condition = design_is("proportions"),
        num("p0", tagList("Proportion in the reference group (p0)", info_tip("p0_controls")), 0.05, min = 0.0001, max = 0.9999, step = 0.01),
        p(class = "text-muted small mb-1", "Cohort or trial: the unexposed or control group. Case-control: the controls exposed."),
        div(class = "alert alert-info py-1 small", "Fill in ONE of the following; the others are calculated."),
        radioButtons(ns("prop_given"), NULL,
                     choiceNames = list(tagList("Odds ratio", info_tip("odds_ratio")), "Proportion in the other group (p1; case-control: cases exposed)",
                                        tagList("Risk (prevalence) ratio", info_tip("risk_ratio")), tagList("Risk difference", info_tip("risk_difference"))),
                     choiceValues = c("OR", "p1", "RR", "RD")),
        conditionalPanel(condition = is_("prop_given", "OR"), num("prop_OR", "Odds ratio", 2, min = 0.0001, step = 0.1)),
        conditionalPanel(condition = is_("prop_given", "p1"), num("prop_p1", "p1", 0.0952, min = 0.0001, max = 0.9999, step = 0.01)),
        conditionalPanel(condition = is_("prop_given", "RR"), num("prop_RR", "Risk ratio", 1.9, min = 0.0001, step = 0.1)),
        conditionalPanel(condition = is_("prop_given", "RD"), num("prop_RD", "Risk difference (p1 - p0)", 0.045, step = 0.005))
      ),
      # ---- chi-square
      conditionalPanel(
        condition = design_is("chisq_w"),
        radioButtons(ns("w_from"), "Work out w from", choices = c("A table of counts" = "table", "A chi-square statistic and N" = "chisq",
                                                                  "Proportions expected under the null and the alternative" = "probs")),
        conditionalPanel(condition = is_("w_from", "table"),
          textAreaInput(ns("w_table"), "Counts, one row per line (e.g. exposed / unexposed by outcome yes / no)", "30, 15\n20, 35", rows = 3)),
        conditionalPanel(condition = is_("w_from", "chisq"),
          fluidRow(column(6, num("w_chisq", "Chi-square statistic", 8.5, min = 0)), column(6, num("w_n", "Total N", 120, min = 1)))),
        conditionalPanel(condition = is_("w_from", "probs"),
          textInput(ns("w_p0"), "Proportions under the null (sum to 1)", "0.25, 0.25, 0.25, 0.25"),
          textInput(ns("w_p1"), "Proportions under the alternative (sum to 1)", "0.40, 0.20, 0.20, 0.20"))
      ),
      # ---- hazard ratio
      conditionalPanel(
        condition = design_is("hazard_ratio"),
        radioButtons(ns("hr_from"), "Work out the hazard ratio from",
                     choices = c("Median survival of each arm (assumes exponential survival)" = "median",
                                 "Survival probabilities at the same time" = "surv", "Event probabilities over the same follow-up" = "p")),
        conditionalPanel(condition = is_("hr_from", "median"),
          fluidRow(column(6, num("hr_me", "Median, experimental arm", 18, min = 0)), column(6, num("hr_mc", "Median, control arm", 12, min = 0)))),
        conditionalPanel(condition = is_("hr_from", "surv"),
          fluidRow(column(6, num("hr_se", "Survival, experimental", 0.6293, min = 0.0001, max = 0.9999, step = 0.01)), column(6, num("hr_sc", "Survival, control", 0.511, min = 0.0001, max = 0.9999, step = 0.01)))),
        conditionalPanel(condition = is_("hr_from", "p"),
          fluidRow(column(6, num("hr_pe", "Event probability, experimental", 0.3707, min = 0.0001, max = 0.9999, step = 0.01)), column(6, num("hr_pc", "Event probability, control", 0.489, min = 0.0001, max = 0.9999, step = 0.01))))
      ),
      # ---- conversions
      conditionalPanel(
        condition = design_is("correlation"),
        radioButtons(ns("cv_from"), "I have", inline = TRUE,
                     choices = c("Cohen's d" = "d", "Correlation r" = "r", "Odds ratio (approx.)" = "OR", "R-squared" = "r2", "f-squared" = "f2")),
        conditionalPanel(condition = is_("cv_from", "d"), num("cv_d", "Cohen's d", 0.5)),
        conditionalPanel(condition = is_("cv_from", "r"), num("cv_r", "Correlation r", 0.3, min = -0.99, max = 0.99, step = 0.05)),
        conditionalPanel(condition = is_("cv_from", "OR"), num("cv_OR", "Odds ratio", 2, min = 0.0001, step = 0.1)),
        conditionalPanel(condition = is_("cv_from", "r2"), num("cv_r2", "R-squared", 0.13, min = 0.0001, max = 0.99, step = 0.01)),
        conditionalPanel(condition = is_("cv_from", "f2"), num("cv_f2", "f-squared", 0.15, min = 0.0001, step = 0.01)),
        conditionalPanel(condition = is_("cv_from", "d", "r"),
          fluidRow(column(6, num("cv_n1", "Group 1 size (optional, for the exact d - r relation)", NA, min = 2)), column(6, num("cv_n2", "Group 2 size (optional)", NA, min = 2))))
      ),
      # ---- median and IQR
      conditionalPanel(
        condition = design_is("median_iqr"),
        p(class = "text-muted small", "For a skewed outcome summarised by a median and IQR. Assumes roughly normal data; the rank-based tests are the alternative."),
        fluidRow(column(6, num("iqr_median", tagList("Median", info_tip("median_iqr")), 45)), column(6, num("iqr_n", "Sample size (n)", 60, min = 2))),
        fluidRow(column(6, num("iqr_q1", "First quartile (q1)", 38)), column(6, num("iqr_q3", "Third quartile (q3)", 54)))
      ),
      # ---- matched pairs
      conditionalPanel(
        condition = design_is("matched_pairs"),
        p(class = "text-muted small mb-1", tagList("Number of matched case-control pairs in which: ", info_tip("matched_pairs"))),
        fluidRow(column(6, num("mp_both", "both were exposed", 30, min = 0)), column(6, num("mp_case", "only the case was exposed", 25, min = 0))),
        fluidRow(column(6, num("mp_control", "only the control was exposed", 10, min = 0)), column(6, num("mp_neither", "neither was exposed", 35, min = 0)))
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      lapply(unname(.es_designs), function(d) {
        e <- effect_size_content[[d]]
        tagList(h4(e$title), render_formula_block(e$formula_latex), shiny::markdown(e$explanation),
                h5("Worked example"), shiny::markdown(e$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      lapply(unname(.es_designs), function(d) {
        e <- effect_size_content[[d]]
        tagList(h4(e$title), p(strong("Citation: "), e$citation), p(strong("Implemented via: "), code(e$backend)), hr())
      })
    )
  )
}

mod_effect_size_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)
      d <- input$design
      tryCatch({
        value <- switch(d,
          two_means = {
            req(input$means_as, input$spread_as)
            var_mode <- input$spread_as == "var"
            calc_es_two_means(
              mean1 = if (input$means_as == "means") { req(input$mean1); input$mean1 },
              mean2 = if (input$means_as == "means") { req(input$mean2); input$mean2 },
              diff = if (input$means_as == "diff") { req(input$diff); input$diff },
              sd1 = if (!var_mode) .es_opt(input$sd1), sd2 = if (!var_mode) .es_opt(input$sd2),
              var1 = if (var_mode) .es_opt(input$var1), var2 = if (var_mode) .es_opt(input$var2),
              n1 = .es_opt(input$n1), n2 = .es_opt(input$n2))
          },
          from_t = {
            req(input$t_stat, input$t_kind)
            if (input$t_kind == "two") { req(input$t_n1, input$t_n2); calc_es_from_t(input$t_stat, input$t_n1, input$t_n2) }
            else { req(input$t_n); calc_es_from_t(input$t_stat, input$t_n) }
          },
          paired_means = {
            req(input$pd_mean, input$pd_as)
            switch(input$pd_as,
              sd_diff = calc_es_paired(input$pd_mean, sd_diff = input$pd_sd_diff),
              sds_r = calc_es_paired(input$pd_mean, sd1 = input$pd_sd1, sd2 = input$pd_sd2, r = input$pd_r),
              sds_sd = calc_es_paired(input$pd_mean, sd_diff = input$pd_sd_diff, sd1 = input$pd_sd1, sd2 = input$pd_sd2))
          },
          anova_f = {
            req(input$f_from)
            switch(input$f_from,
              means = calc_es_f(means = .es_parse_numbers(input$f_means, "group means"), sd = input$f_sd,
                                n = if (nzchar(trimws(if (is.null(input$f_n)) "" else input$f_n))) .es_parse_numbers(input$f_n, "group sizes")),
              eta2 = calc_es_f(eta2 = input$f_eta2),
              F = calc_es_f(F_stat = input$f_F, df1 = input$f_df1, df2 = input$f_df2),
              d = calc_es_f(d = input$f_d))
          },
          proportions = {
            req(input$p0, input$prop_given)
            switch(input$prop_given,
              OR = calc_es_proportions(input$p0, OR = input$prop_OR), p1 = calc_es_proportions(input$p0, p1 = input$prop_p1),
              RR = calc_es_proportions(input$p0, RR = input$prop_RR), RD = calc_es_proportions(input$p0, RD = input$prop_RD))
          },
          chisq_w = {
            req(input$w_from)
            switch(input$w_from,
              table = calc_es_chisq_w(table = .es_parse_table(input$w_table)),
              chisq = calc_es_chisq_w(chisq = input$w_chisq, n = input$w_n),
              probs = calc_es_chisq_w(p0 = .es_parse_numbers(input$w_p0, "null proportions"), p1 = .es_parse_numbers(input$w_p1, "alternative proportions")))
          },
          hazard_ratio = {
            req(input$hr_from)
            switch(input$hr_from,
              median = calc_es_hazard_ratio(median_e = input$hr_me, median_c = input$hr_mc),
              surv = calc_es_hazard_ratio(surv_e = input$hr_se, surv_c = input$hr_sc),
              p = calc_es_hazard_ratio(pe = input$hr_pe, pc = input$hr_pc))
          },
          correlation = {
            req(input$cv_from)
            n1 <- .es_opt(input$cv_n1); n2 <- .es_opt(input$cv_n2)
            if (is.null(n1) || is.null(n2) || !input$cv_from %in% c("d", "r")) { n1 <- NULL; n2 <- NULL }
            switch(input$cv_from,
              d = calc_es_convert(d = input$cv_d, n1 = n1, n2 = n2), r = calc_es_convert(r = input$cv_r, n1 = n1, n2 = n2),
              OR = calc_es_convert(OR = input$cv_OR), r2 = calc_es_convert(r2 = input$cv_r2), f2 = calc_es_convert(f2 = input$cv_f2))
          },
          median_iqr = {
            req(input$iqr_median, input$iqr_q1, input$iqr_q3, input$iqr_n)
            calc_mean_sd_from_median_iqr(input$iqr_median, input$iqr_q1, input$iqr_q3, input$iqr_n)
          },
          matched_pairs = {
            req(input$mp_both, input$mp_case, input$mp_control, input$mp_neither)
            calc_matched_pairs_phi(input$mp_both, input$mp_case, input$mp_control, input$mp_neither)
          })
        list(ok = TRUE, design = d, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      .es_render(res$design, res$value)
    })

    render_export_handlers(output, result, function() effect_size_content[[input$design]])
  })
}

# --- result display ---------------------------------------------------------------------------------
.es_line <- function(label, value, tip = NULL, big = FALSE) {
  p(class = "mb-1", if (big) strong(paste0(label, ": ")) else paste0(label, ": "), if (big) strong(value) else value,
    if (!is.null(tip)) info_tip(tip))
}
.es_f3 <- function(x) formatC(x, digits = 3, format = "f")

.es_render <- function(design, v) {
  reading <- if (!is.null(v$interpretation)) p(class = "text-muted small", "Reading: ", v$interpretation)
  switch(design,
    two_means = tagList(
      .es_line("Cohen's d", .es_f3(v$d), "cohens_d", big = TRUE),
      .es_line("Difference between the means", .es_f3(v$difference)),
      .es_line("Pooled SD", .es_f3(v$pooled_sd), "pooled_sd"),
      if (!is.null(v$hedges_g)) tagList(
        .es_line("Hedges' g", .es_f3(v$hedges_g), "hedges_g"),
        .es_line(sprintf("%s interval for d (large-sample)", .prec_pct(v$inputs$conf_level)), sprintf("%s to %s", .es_f3(v$d_lower), .es_f3(v$d_upper)))
      ) else p(class = "text-muted small", "Equal group sizes assumed; give both sizes for Hedges' g and an interval."),
      reading),
    from_t = tagList(
      .es_line(if (is.null(v$inputs$n2)) "d for paired / one-sample data (d_z)" else "Cohen's d", .es_f3(v$d), "cohens_d", big = TRUE),
      if (!is.null(v$hedges_g)) .es_line("Hedges' g", .es_f3(v$hedges_g), "hedges_g"),
      .es_line("Degrees of freedom", v$df), reading),
    paired_means = tagList(
      .es_line("d for the differences (d_z)", .es_f3(v$d_z), "paired_dz", big = TRUE),
      .es_line("SD of the differences", .es_f3(v$sd_diff)),
      if (!is.null(v$correlation)) .es_line("Correlation between the two measurements", .es_f3(v$correlation), "correlation"),
      reading),
    anova_f = tagList(
      .es_line("Cohen's f", .es_f3(v$f), "cohens_f", big = TRUE), .es_line("f-squared", .es_f3(v$f2)),
      .es_line("Eta-squared", .es_f3(v$eta2), "eta2"), reading),
    proportions = tagList(
      .es_line("Proportion in the reference group (p0)", sprintf("%s (%s%%)", .es_f3(v$p0), .es_f3(100 * v$p0))),
      .es_line("Proportion in the other group (p1)", sprintf("%s (%s%%)", .es_f3(v$p1), .es_f3(100 * v$p1)), big = TRUE),
      .es_line("Odds ratio", .es_f3(v$OR), "odds_ratio", big = TRUE),
      .es_line("Risk (prevalence) ratio", .es_f3(v$RR), "risk_ratio"),
      .es_line("Risk difference", .es_f3(v$RD), "risk_difference"),
      .es_line("Number needed to treat", if (is.finite(v$NNT)) format(round(v$NNT, 1)) else "not defined (no difference)", "nnt"),
      .es_line("Cohen's h", .es_f3(v$h), "cohens_h"), reading),
    chisq_w = tagList(
      .es_line("Cohen's w", .es_f3(v$w), "cohens_w", big = TRUE),
      if (!is.null(v$chisq)) .es_line("Chi-square", .es_f3(v$chisq)),
      if (!is.null(v$df)) .es_line("Degrees of freedom", v$df),
      if (!is.null(v$cramers_v)) .es_line("Cramer's V", .es_f3(v$cramers_v)), reading),
    hazard_ratio = tagList(
      .es_line("Hazard ratio", .es_f3(v$hr), "hazard_ratio", big = TRUE), .es_line("ln(hazard ratio)", .es_f3(v$log_hr)),
      p(class = "text-muted small", "Based on: ", v$basis)),
    correlation = if (!is.null(v$d)) tagList(
      .es_line("Cohen's d", .es_f3(v$d), "cohens_d", big = TRUE), .es_line("Correlation r", .es_f3(v$r), "correlation"),
      .es_line("Odds ratio (approximate)", .es_f3(v$OR_approx), "odds_ratio"), .es_line("R-squared", .es_f3(v$r2)),
      .es_line("f-squared", .es_f3(v$f2)), reading) else tagList(
      .es_line("R-squared (eta-squared)", .es_f3(v$r2), "eta2"), .es_line("f-squared", .es_f3(v$f2)),
      .es_line("Cohen's f", .es_f3(v$f), "cohens_f", big = TRUE), reading),
    median_iqr = tagList(
      .es_line("Estimated mean", .es_f3(v$mean), "median_iqr", big = TRUE), .es_line("Estimated SD", .es_f3(v$sd), "sd_variance", big = TRUE),
      p(class = "text-muted small", sprintf("SD = IQR / %.3f. Assumes roughly normal data.", v$divisor))),
    matched_pairs = tagList(
      .es_line("phi", .es_f3(v$phi), "phi", big = TRUE),
      .es_line("Pairs", v$n_pairs),
      .es_line("Controls exposed (p0)", sprintf("%s (%s%%)", .es_f3(v$p0), .es_f3(100 * v$p0)), "p0_controls"),
      .es_line("Cases exposed (p1)", sprintf("%s (%s%%)", .es_f3(v$p1), .es_f3(100 * v$p1))),
      .es_line("Odds ratio of exposure", .es_f3(v$OR), "odds_ratio"),
      .es_line("Matched-pairs odds ratio (b / c)", if (is.finite(v$OR_matched)) .es_f3(v$OR_matched) else "not finite (no control-only pairs)"))
  )
}
