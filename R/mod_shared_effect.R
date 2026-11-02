# Shared inputs for the effect of a calculation, so a calculator can take what people usually know (owner's request of 2 Nov 2026; layouts as
# in OpenEpi's sample-size forms): one of an odds ratio, a risk ratio, a risk difference or the other proportion; Cohen's f from group means
# and SD or from eta-squared; Cohen's d from a difference and an SD. The arithmetic is calc_effect_size.R's (verified there); these helpers only
# lay out the inputs and turn them into the arguments of the calculation. Each family has a UI function, a function giving the value
# (or the arguments of the calculation) from `input`, and a server function for the live line under the inputs.

.sh_cond <- function(ns, id, ...) paste(sprintf("input['%s'] == '%s'", ns(id), c(...)), collapse = " || ")
# a number with `digits` significant digits and no padding (formatC(format = "g") pads with a leading space)
.sh_fmt <- function(x, digits = 4) format(signif(x, digits), trim = TRUE)
.sh_num <- function(x) if (is.null(x) || length(x) != 1 || is.na(x)) NULL else x

# --- the other group's proportion: one of p1, OR, RR, RD ----------------------------------------------------------------------
# `p1_id` is the id the calculator already used for the proportion, so its server code and tests still find it.
prop_given_ui <- function(ns, prefix, p1_id, p1_label, p1_default, ref_label = "the reference group", min = 0.001) {
  given <- paste0(prefix, "_given")
  tagList(
    radioButtons(ns(given), "Effect to detect, given as",
                 choiceNames = list(p1_label, tagList("Odds ratio", info_tip("odds_ratio")), tagList("Risk (prevalence) ratio", info_tip("risk_ratio")),
                                    tagList("Risk difference", info_tip("risk_difference"))),
                 choiceValues = c("p1", "OR", "RR", "RD"), inline = FALSE),
    conditionalPanel(.sh_cond(ns, given, "p1"), numericInput(ns(p1_id), p1_label, value = p1_default, min = min, max = 1 - min, step = 0.01)),
    conditionalPanel(.sh_cond(ns, given, "OR"), numericInput(ns(paste0(prefix, "_OR")), paste0("Odds ratio, compared with ", ref_label), value = 2, min = 0.01, step = 0.1)),
    conditionalPanel(.sh_cond(ns, given, "RR"), numericInput(ns(paste0(prefix, "_RR")), paste0("Risk (prevalence) ratio, compared with ", ref_label), value = 2, min = 0.01, step = 0.1)),
    conditionalPanel(.sh_cond(ns, given, "RD"), numericInput(ns(paste0(prefix, "_RD")), paste0("Risk difference, compared with ", ref_label), value = 0.1, step = 0.01)),
    uiOutput(ns(paste0(prefix, "_equiv")))
  )
}

# The arguments of calc_*() for the chosen route: list(p1 = ...), list(OR = ...), list(RR = ...) or list(RD = ...)
prop_given_args <- function(input, prefix, p1_id) {
  mode <- input[[paste0(prefix, "_given")]]
  if (is.null(mode)) mode <- "p1"
  switch(mode,
    p1 = { req(input[[p1_id]]); list(p1 = input[[p1_id]]) },
    OR = { req(input[[paste0(prefix, "_OR")]]); list(OR = input[[paste0(prefix, "_OR")]]) },
    RR = { req(input[[paste0(prefix, "_RR")]]); list(RR = input[[paste0(prefix, "_RR")]]) },
    RD = { req(input[[paste0(prefix, "_RD")]]); list(RD = input[[paste0(prefix, "_RD")]]) })
}

# The other group's proportion as a number (for the power curves, which vary it): NULL while the inputs are incomplete or impossible.
prop_given_p1 <- function(input, prefix, p1_id, p_ref) {
  if (is.null(.sh_num(p_ref))) return(NULL)
  args <- tryCatch(prop_given_args(input, prefix, p1_id), error = function(e) NULL)
  if (is.null(args)) return(NULL)
  tryCatch(do.call(calc_es_proportions, c(list(p_ref), args))$p1, error = function(e) NULL)
}

# The line under the inputs: all the equivalents, as OpenEpi shows them. `ref` is a function returning the reference proportion.
prop_given_server <- function(input, output, prefix, p1_id, ref, ref_name = "the reference group") {
  output[[paste0(prefix, "_equiv")]] <- renderUI({
    p0 <- .sh_num(ref())
    if (is.null(p0) || p0 <= 0 || p0 >= 1) return(NULL)
    args <- tryCatch(prop_given_args(input, prefix, p1_id), error = function(e) NULL)
    if (is.null(args)) return(NULL)
    e <- tryCatch(do.call(calc_es_proportions, c(list(p0), args)), error = function(e) e)
    if (inherits(e, "error")) return(div(class = "text-danger small mb-2", conditionMessage(e)))
    div(class = "text-muted small mb-2", sprintf(
      "Compared with %s (%s): proportion %s, odds ratio %s, risk ratio %s, risk difference %s.",
      ref_name, .sh_fmt(p0, 4), .sh_fmt(e$p1, 4), .sh_fmt(e$OR, 4),
      .sh_fmt(e$RR, 4), .sh_fmt(e$RD, 3)))
  })
}

# --- Cohen's f: entered, or from group means and SD, or from eta-squared ---------------------------------------------------------
effect_f_ui <- function(ns, id, default = 0.25) {
  as <- paste0(id, "_as")
  tagList(
    radioButtons(ns(as), tagList("Effect size (Cohen's f)", info_tip("cohens_f")), inline = TRUE,
                 choices = c("Enter f" = "f", "From group means and SD" = "means", "From eta-squared" = "eta2")),
    conditionalPanel(.sh_cond(ns, as, "f"), numericInput(ns(id), "Cohen's f effect size", value = default, min = 0.001, step = 0.01)),
    conditionalPanel(.sh_cond(ns, as, "means"),
      textInput(ns(paste0(id, "_means")), "Group means (separated by commas)", value = "10, 12, 15"),
      numericInput(ns(paste0(id, "_sd")), tagList("Common SD within groups", info_tip("sd_variance")), value = 6, min = 0.0001)),
    conditionalPanel(.sh_cond(ns, as, "eta2"), numericInput(ns(paste0(id, "_eta2")), tagList("Eta-squared", info_tip("eta2")), value = 0.06, min = 0.0001, max = 0.99, step = 0.01)),
    uiOutput(ns(paste0(id, "_equiv")))
  )
}
effect_f_value <- function(input, id) {
  mode <- input[[paste0(id, "_as")]]
  if (is.null(mode)) mode <- "f"
  switch(mode,
    f = { req(input[[id]]); input[[id]] },
    means = { req(input[[paste0(id, "_means")]], input[[paste0(id, "_sd")]])
              calc_es_f(means = .es_parse_numbers(input[[paste0(id, "_means")]], "group means"), sd = input[[paste0(id, "_sd")]])$f },
    eta2 = { req(input[[paste0(id, "_eta2")]]); calc_es_f(eta2 = input[[paste0(id, "_eta2")]])$f })
}
effect_f_server <- function(input, output, id) {
  output[[paste0(id, "_equiv")]] <- renderUI({
    f <- tryCatch(effect_f_value(input, id), shiny.silent.error = function(e) NULL, error = function(e) e)
    if (is.null(f)) return(NULL)
    if (inherits(f, "error")) return(div(class = "text-danger small mb-2", conditionMessage(f)))
    div(class = "text-muted small mb-2", sprintf("Cohen's f = %s (f-squared %s, eta-squared %s): %s.", formatC(f, digits = 3, format = "f"),
                                                formatC(f^2, digits = 3, format = "f"), formatC(f^2 / (1 + f^2), digits = 3, format = "f"),
                                                sub(" \\(.*", "", .es_interpret(f, "f"))))
  })
}

# --- Cohen's d: entered, or from the difference and an SD or variance ------------------------------------------------------------
effect_d_ui <- function(ns, id, default = 0.5, label = "Cohen's d") {
  as <- paste0(id, "_as")
  tagList(
    radioButtons(ns(as), tagList("Effect size (Cohen's d)", info_tip("cohens_d")), inline = TRUE,
                 choices = c("Enter d" = "d", "From a difference and an SD" = "sd", "From a difference and a variance" = "var")),
    conditionalPanel(.sh_cond(ns, as, "d"), numericInput(ns(id), label, value = default, min = 0.001, step = 0.1)),
    conditionalPanel(.sh_cond(ns, as, "sd", "var"), numericInput(ns(paste0(id, "_diff")), "Difference between the means", value = 5)),
    conditionalPanel(.sh_cond(ns, as, "sd"), numericInput(ns(paste0(id, "_sd")), "Common SD", value = 10, min = 0.0001)),
    conditionalPanel(.sh_cond(ns, as, "var"), numericInput(ns(paste0(id, "_var")), tagList("Common variance", info_tip("sd_variance")), value = 100, min = 0.0001)),
    uiOutput(ns(paste0(id, "_equiv")))
  )
}
effect_d_value <- function(input, id) {
  mode <- input[[paste0(id, "_as")]]
  if (is.null(mode)) mode <- "d"
  switch(mode,
    d = { req(input[[id]]); input[[id]] },
    sd = { req(input[[paste0(id, "_diff")]], input[[paste0(id, "_sd")]]); abs(input[[paste0(id, "_diff")]]) / input[[paste0(id, "_sd")]] },
    var = { req(input[[paste0(id, "_diff")]], input[[paste0(id, "_var")]])
            if (input[[paste0(id, "_var")]] <= 0) stop("The variance must be greater than 0.", call. = FALSE)
            abs(input[[paste0(id, "_diff")]]) / sqrt(input[[paste0(id, "_var")]]) })
}
effect_d_server <- function(input, output, id) {
  output[[paste0(id, "_equiv")]] <- renderUI({
    d <- tryCatch(effect_d_value(input, id), shiny.silent.error = function(e) NULL, error = function(e) e)
    if (is.null(d)) return(NULL)
    if (inherits(d, "error")) return(div(class = "text-danger small mb-2", conditionMessage(d)))
    div(class = "text-muted small mb-2", sprintf("Cohen's d = %s: %s.", formatC(d, digits = 3, format = "f"), sub(" \\(.*", "", .es_interpret(d, "d"))))
  })
}
