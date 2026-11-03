# "Calculate this" links from a calculator to the Effect Size converters, and "Use this value" back (owner's request of 2 Nov 2026).
#
# A calculator that asks for a number the converters can produce (Cohen's d or f, a hazard ratio, an odds ratio, an SD, ...) shows a small
# "Calculate this" link under that input. The link opens the matching Effect Size converter; once the converter has a result, "Use this value"
# puts the number into the calculator's input and goes back to the calculator. Nothing is calculated here: the numbers are the converters'
# (calc_effect_size.R, calc_median_iqr.R), this file only carries the request one way and the value the other.
#
# One entry of .es_link_specs per linked input:
#   module   the calculator's registry id            input    the numeric input's id inside the calculator
#   label    what the number is (button text)        design   the Effect Size design (value of its `design` radio) the link opens
#   keys     fields of that design's result that can be sent (the first one present is used)
#   set_es   radios of the Effect Size page to preset (named list: input id -> value)
#   set_calc radios of the calculator to switch, so the filled input is the one in use (named list: input id -> value)
#   prefill  converter inputs filled from what the calculator already holds (named list: converter input id -> calculator input id),
#            so the user does not type the same numbers twice; a calculator input that is empty is skipped
#   set_es may also give a function of the calculator's `input` instead of a value (e.g. open the converter on the route the
#   calculator was using)
# test-effect_links.R checks every entry against the calculators' pages and the converters' results.

.es_link_specs <- list(
  # Cohen's d (from a t statistic and the group sizes)
  list(module = "means", input = "d_two", label = "Cohen's d", design = "from_t", keys = "d", set_calc = list(effect_as_two = "d")),
  list(module = "means", input = "d_unequal", label = "Cohen's d", design = "from_t", keys = "d", set_calc = list(effect_as_unequal = "d")),
  list(module = "multiplicity", input = "d_fdr", label = "Cohen's d", design = "from_t", keys = "d", set_calc = list(d_fdr_as = "d")),
  list(module = "multiplicity", input = "d_dunnett", label = "Cohen's d", design = "from_t", keys = "d", set_calc = list(d_dunnett_as = "d")),
  list(module = "bayesian", input = "effect_size_bfda", label = "Cohen's d", design = "from_t", keys = "d"),
  list(module = "meta_power", input = "d_effect", label = "Cohen's d", design = "from_t", keys = "d", set_calc = list(es_type = "d")),
  list(module = "nonparametric", input = "effect_size_ks", label = "the standardized shift (d)", design = "from_t", keys = "d"),
  list(module = "nonparametric", input = "effect_size_runs", label = "the standardized shift (d)", design = "from_t", keys = "d"),
  # Cohen's f and f-squared
  list(module = "nonparametric", input = "f_kw", label = "Cohen's f", design = "anova_f", keys = "f", set_calc = list(f_kw_as = "f"),
       set_es = list(f_from = function(input) if (identical(input[["f_kw_as"]], "eta2")) "eta2" else "means"),
       prefill = list(f_means = "f_kw_means", f_sd = "f_kw_sd", f_eta2 = "f_kw_eta2")),
  list(module = "nonparametric", input = "f_fr", label = "Cohen's f", design = "anova_f", keys = "f", set_calc = list(f_fr_as = "f"),
       set_es = list(f_from = function(input) if (identical(input[["f_fr_as"]], "eta2")) "eta2" else "means"),
       prefill = list(f_means = "f_fr_means", f_sd = "f_fr_sd", f_eta2 = "f_fr_eta2")),
  list(module = "rm_anova", input = "f", label = "Cohen's f", design = "anova_f", keys = "f", set_calc = list(f_as = "f"),
       set_es = list(f_from = function(input) if (identical(input[["f_as"]], "eta2")) "eta2" else "means"),
       prefill = list(f_means = "f_means", f_sd = "f_sd", f_eta2 = "f_eta2")),
  list(module = "anova_general", input = "f2", label = "f-squared", design = "anova_f", keys = "f2", set_calc = list(effect_size_type = "f2"),
       set_es = list(f_from = "eta2"), prefill = list(f_eta2 = "eta2")),
  # correlation, from Cohen's d
  list(module = "correlation", input = "r_pb", label = "r", design = "correlation", keys = "r", set_es = list(cv_from = "d")),
  list(module = "meta_power", input = "r_effect", label = "r", design = "correlation", keys = "r", set_es = list(cv_from = "d"),
       set_calc = list(es_type = "r"), prefill = list(cv_d = "d_effect")),
  # hazard ratio
  list(module = "logrank", input = "hr_logrank", label = "the hazard ratio", design = "hazard_ratio", keys = "hr", set_calc = list(hr_as_logrank = "value"),
       set_es = list(hr_from = function(input) if (identical(input[["hr_as_logrank"]], "implied")) "p" else "median"),
       prefill = list(hr_me = "hr_median_e", hr_mc = "hr_median_c", hr_pe = "pE", hr_pc = "pC")),
  list(module = "logrank", input = "hr_strat", label = "the hazard ratio", design = "hazard_ratio", keys = "hr"),
  list(module = "logrank", input = "hr_wlr", label = "the hazard ratio", design = "hazard_ratio", keys = "hr"),
  list(module = "group_sequential", input = "hr_survival", label = "the hazard ratio", design = "hazard_ratio", keys = "hr"),
  list(module = "noninferiority", input = "hr_val", label = "the hazard ratio", design = "hazard_ratio", keys = "hr"),
  list(module = "case_control", input = "hr", label = "the hazard ratio", design = "hazard_ratio", keys = "hr"),
  # odds ratio, from proportions
  list(module = "case_control", input = "OR", label = "the odds ratio", design = "proportions", keys = "OR", set_calc = list(effect_as = "or"),
       prefill = list(p0 = "p0")),
  list(module = "glmm", input = "or", label = "the odds ratio", design = "proportions", keys = "OR", prefill = list(p0 = "baseline_prob")),
  # standard deviation, from a median and interquartile range; SD of paired differences
  list(module = "means", input = "sd_precision", label = "the SD", design = "median_iqr", keys = "sd"),
  list(module = "means", input = "sd_single", label = "the SD", design = "median_iqr", keys = "sd"),
  list(module = "means", input = "sd_anova", label = "the SD", design = "median_iqr", keys = "sd"),
  list(module = "means", input = "sd_two", label = "the SD", design = "median_iqr", keys = "sd", set_calc = list(spread_as_two = "sd")),
  list(module = "means", input = "sd_unequal", label = "the SD", design = "median_iqr", keys = "sd", set_calc = list(spread_as_unequal = "sd")),
  list(module = "means", input = "sd_diff", label = "the SD of the differences", design = "paired_means", keys = "sd_diff",
       set_calc = list(paired_sd_as = "sd_diff"), set_es = list(pd_as = "sds_r"),
       prefill = list(pd_mean = "mean_diff", pd_sd1 = "paired_sd1", pd_sd2 = "paired_sd2", pd_r = "paired_r"))
)

.es_link_spec <- function(module, input) {
  for (s in .es_link_specs) if (identical(s$module, module) && identical(s$input, input)) return(s)
  NULL
}
.es_link_id <- function(input) paste0("es_", input)
# a set_es entry: a fixed value, or a function of the calculator's input
.es_set_value <- function(x, input) if (is.function(x)) x(input) else x

# The link under a calculator input. `ns` is the module's ns(); the module is taken from it ("means-" -> "means").
es_link_ui <- function(ns, input) {
  module <- sub("-$", "", ns(""))
  spec <- .es_link_spec(module, input)
  if (is.null(spec)) stop("No Effect Size link is defined for ", module, "$", input, ".", call. = FALSE)
  div(class = "small mb-2 es-link",
      actionLink(ns(.es_link_id(input)), "Calculate this", title = sprintf("Open the Effect Size converter for %s; the result can be sent back here.", spec$label)))
}

.module_title <- function(module_id) {
  for (m in module_registry()) if (identical(m$id, module_id)) return(m$title)
  module_id
}

# The pending request, shared by the calculators and the Effect Size page: NULL, or list(spec =, title =).
es_link_state <- function(root) {
  if (is.null(root$userData$es_link)) root$userData$es_link <- shiny::reactiveVal(NULL)
  root$userData$es_link
}

# Called in a calculator's server: opens the converter when one of its links is clicked.
es_links_server <- function(input, session) {
  module <- sub("-$", "", session$ns(""))
  root <- session$rootScope()
  title <- .module_title(module)
  for (s in Filter(function(s) identical(s$module, module), .es_link_specs)) local({
    spec <- s
    observeEvent(input[[.es_link_id(spec$input)]], {
      es_link_state(root)(list(spec = spec, title = title))
      jump_to_module(root, effect_size_meta$nav_title)
      updateRadioButtons(root, paste0(effect_size_meta$id, "-design"), selected = spec$design)
      for (n in names(spec$set_es)) updateRadioButtons(root, paste0(effect_size_meta$id, "-", n), selected = .es_set_value(spec$set_es[[n]], input))
      for (n in names(spec$prefill)) {
        v <- input[[spec$prefill[[n]]]]
        if (is.null(v) || length(v) != 1 || (!is.character(v) && is.na(v))) next
        id <- paste0(effect_size_meta$id, "-", n)
        if (is.character(v)) updateTextInput(root, id, value = v) else updateNumericInput(root, id, value = v)
      }
    }, ignoreInit = TRUE)
  })
  invisible(NULL)
}

# The number to send: the first of the spec's keys present in the converter's result, to four significant figures; NULL if none.
.es_link_value <- function(spec, res) {
  if (is.null(res) || !isTRUE(res$ok)) return(NULL)
  for (k in spec$keys) {
    x <- res$value[[k]]
    if (is.numeric(x) && length(x) == 1 && is.finite(x)) return(signif(x, 4))
  }
  NULL
}

# The panel under the converter's result: "Use this value" and a way back.
es_link_panel <- function(ns, link, res) {
  if (is.null(link)) return(NULL)
  val <- .es_link_value(link$spec, res)
  # pinned to the bottom of the window (.pin-result, run_app.R) so the button stays in view while the inputs above are changed
  div(class = "pin-result",
      div(class = "alert alert-info py-2 mb-0",
          p(class = "mb-1 small", "Opened from ", strong(paste0(link$title, "."))),
          if (is.null(val)) p(class = "mb-1 small", sprintf("This result does not give %s. Choose a design that does, or go back without it.", link$spec$label))
          else actionButton(ns("use_value"), sprintf("Use %s = %s in %s", link$spec$label, format(val, trim = TRUE), link$title), class = "btn-primary btn-sm"),
          actionLink(ns("back_without"), sprintf("Back to %s without a value", link$title), class = "ms-2 small")))
}

# Called in the Effect Size server: the two buttons of the panel.
es_link_back_server <- function(input, session, result) {
  root <- session$rootScope()
  link <- es_link_state(root)
  observeEvent(input$use_value, {
    lk <- link(); req(lk)
    val <- .es_link_value(lk$spec, result()); req(val)
    module <- lk$spec$module
    for (n in names(lk$spec$set_calc)) updateRadioButtons(root, paste0(module, "-", n), selected = lk$spec$set_calc[[n]])
    updateNumericInput(root, paste0(module, "-", lk$spec$input), value = val)
    link(NULL)
    jump_to_module(root, lk$title)
  })
  observeEvent(input$back_without, {
    lk <- link(); req(lk)
    link(NULL)
    jump_to_module(root, lk$title)
  })
  list(link = link)
}
