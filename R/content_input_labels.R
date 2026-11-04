# Readable names for the inputs and results recorded in a study (Studies, phase S-3). The results keep the calculation functions' short
# argument names (p1, sd, conf_level, ...), which the Studies tab and the Word file show as "Label (name)".
#
# Only names that mean the same thing in every calculator are labelled here; a name whose meaning depends on the calculator or the design
# (d is a margin of error in one and Cohen's d in another; r a correlation or an allocation ratio; p1 an expected proportion in a one-sample
# design and group 1's in a two-sample one; sd1 a group's SD or a measurement's) is labelled only for the calculators listed in
# .study_labels_module where it has one meaning, and otherwise shown as it is. Nothing is guessed.

.study_labels_input <- c(
  alpha = "Significance level", power = "Power", conf_level = "Confidence level", alternative = "Alternative hypothesis",
  seed = "Random seed", nsim = "Number of simulated data sets", nonresponse = "Expected non-response / loss to follow-up",
  N = "Population size", population = "Population size", prevalence = "Prevalence", sens = "Sensitivity", spec = "Specificity",
  icc = "Intracluster correlation (ICC)", cluster_size = "Cluster size", conf_width = "Width of the confidence interval",
  hr = "Hazard ratio", HR = "Hazard ratio", OR = "Odds ratio", or = "Odds ratio", RR = "Risk ratio", RD = "Risk difference",
  odds_ratio = "Odds ratio", mu0 = "Reference mean", sd = "Standard deviation", sd_diff = "SD of the differences",
  mean_diff = "Mean of the differences", diff = "Difference between the means", variance = "Variance",
  pE = "Event probability, experimental group", pC = "Event probability, control group",
  error = "Precision expressed as", epsilon = "Relative precision", deff = "Design effect", n_base = "Sample size before the design effect",
  kappa = "Kappa", effect_size = "Effect size", ratio = "Allocation ratio", margin = "Margin", cv = "Coefficient of variation",
  r2 = "R-squared", sigma = "Standard deviation"
)

# Names whose meaning depends on the calculator (registry id -> name -> label)
.study_labels_module <- list(
  proportion = c(p = "Expected proportion", d = "Margin of error (absolute)", p0 = "Reference proportion"),
  means = c(mean = "Expected mean", mu1 = "Expected mean", r = "Correlation between the two measurements"),
  cluster = c(b = "Subjects per cluster", p = "Expected proportion", rho = "Intracluster correlation", N_psu = "Number of clusters in the population"),
  rate = c(rate = "Expected rate", rate_ref = "Rate in the reference group", rate_ratio = "Rate ratio", prop_exposed = "Proportion exposed"),
  cohort = c(p0 = "Risk in the unexposed group", p1 = "Risk in the exposed group"),
  case_control = c(p0 = "Exposure among controls", pE = "Probability of exposure", pD = "Proportion of the cohort with the event")
)

.study_labels_result <- c(
  n = "Sample size", n_total = "Total sample size", n_per_group = "Sample size per group", n1 = "Sample size, group 1",
  n2 = "Sample size, group 2", n_unadjusted = "Before inflating for non-response", n_enrolled = "To enrol", n_enrol = "To enrol",
  d_absolute = "Absolute precision", epsilon_relative = "Relative precision", achieved_power = "Achieved power", power = "Power",
  deff = "Design effect", n_effective = "Sample size after the design effect", icc = "Intracluster correlation (ICC)",
  n_clusters = "Number of clusters", events = "Number of events", z = "z value"
)

# "Label (name)", or the name alone when no label applies
.study_label <- function(name, module = NULL, kind = c("input", "result")) {
  kind <- match.arg(kind)
  lab <- NULL
  if (kind == "input" && !is.null(module) && !is.null(.study_labels_module[[module]])) {
    m <- .study_labels_module[[module]]
    if (name %in% names(m)) lab <- m[[name]]
  }
  if (is.null(lab)) {
    dict <- if (kind == "input") .study_labels_input else .study_labels_result
    if (name %in% names(dict)) lab <- dict[[name]]
  }
  if (is.null(lab)) name else paste0(lab, " (", name, ")")
}

# A named list relabelled: names become "Label (name)"
.study_relabel <- function(x, module = NULL, kind = "input") {
  if (length(x) == 0) return(x)
  names(x) <- vapply(names(x), .study_label, character(1), module = module, kind = kind)
  x
}
