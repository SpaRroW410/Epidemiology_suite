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
  case_control = c(p0 = "Exposure among controls", pE = "Probability of exposure", pD = "Proportion of the cohort with the event"),
  # STUDY-08 (16 Nov 2026): wording from each function's own help page; a name is listed only where it has one meaning in the calculator
  mendelian = c(beta = "Causal effect, SD of outcome per SD of exposure", r2 = "Share of the exposure explained by the instrument (R-squared)",
                or = "Causal odds ratio per SD of exposure", controls_per_case = "Controls per case", n_cases = "Cases available",
                n = "Participants available"),
  its = c(effect = "Change to detect", effect_type = "Kind of change", sd = "SD of the series around its trend", rho = "Autocorrelation",
          pre_fraction = "Share of time points before the interruption", n_pre = "Time points before the interruption",
          n_post = "Time points after the interruption", baseline_trend = "Baseline trend in the model",
          both_changes = "Level and slope change estimated together", max_n = "Largest number of time points tried"),
  tsa = c(outcome = "Effect measure", mc = "Anticipated effect", pC = "Event probability, control arm", p1 = "Event probability, intervention arm",
          sd_mc = "Standard deviation of the outcome", beta = "Type II error rate", side = "Sides of the test",
          heterogeneity = "Anticipated heterogeneity between trials"),
  analyze_meta = c(estimate = "Study estimates", lower = "Lower confidence limits", upper = "Upper confidence limits", se = "Standard errors",
                   measure = "Kind of estimate", labels = "Study labels", ci_level = "Confidence level of the studies' intervals"),
  sccs = c(eexpo = "Relative incidence to detect", risk = "Length of the risk period", astart = "Age at start of observation",
           aend = "Age at end of observation", p = "Proportion of cases exposed", eage = "Age-group relative incidences",
           agegrp = "Age-group cut points"),
  simon = c(pu = "Unacceptable response rate", pa = "Desirable response rate", beta = "Type II error rate", nmax = "Largest total sample size searched"),
  pilot = c(n = "Pilot sample size per arm"),
  did = c(delta = "Effect to detect", sd = "SD of the outcome between units", rho = "Correlation between a unit's measurements",
          n_pre = "Time points before the start", n_post = "Time points after the start", ratio = "Comparison units per intervention unit",
          n_intervention = "Intervention units available"),
  stepped_wedge = c(nsubjects = "People per cluster in each period", ntimes = "Time points after the baseline period", d = "Treatment effect to detect",
                    icc = "Intracluster correlation", rho_c = "Cluster autocorrelation", rho_s = "Individual autocorrelation", vart = "Total outcome variance",
                    p0 = "Risk on control", p1 = "Risk on the intervention", nsteps = "Number of steps",
                    tau = "SD of the cluster effect (log odds)", time_effect = "Change in log odds per later period"),
  lqas = c(p_upper = "Proportion defining an acceptable area", p_lower = "Proportion defining an unacceptable area",
           beta = "Consumer's risk", n_max = "Largest sample size searched"),
  stratified = c(Nh = "Population size of each stratum", Sh = "Standard deviation in each stratum", e = "Margin of error (absolute)",
                 type = "Allocation"),
  crossover = c(delta = "Mean difference to detect"),
  regression = c(num_predictors = "Number of predictors", r2_reduced = "R-squared of the reduced model", r2_full = "R-squared of the full model",
                 num_predictors_added = "Predictors added", num_predictors_total = "Predictors in the full model"),
  resource_equation = c(k_groups = "Number of groups", n_per_group = "Units per group", e_target = "Error degrees of freedom wanted"),
  subgroup_interaction = c(n_main_total = "Total sample size for the main effect", effect_ratio = "Interaction effect / main effect"),
  capture_recapture = c(n1 = "First-sample (marking) size", precision = "Relative half-width of the interval"),
  attrition = c(n_required = "Number required for analysis", losses = "Expected losses", arms = "Arm labels", stages = "Stage labels",
                dropout = "Drop-out from the treatment arm", dropin = "Drop-in to treatment from the control arm"),
  randomization = c(n = "Number of participants", arms = "Arms", method = "Method", block_sizes = "Block sizes", strata = "Strata"),
  epidemic_model = c(r0 = "Basic reproduction number (R0)", infectious_period = "Mean infectious period (days)",
                     latent_period = "Mean latent period (days)", coverage = "Vaccination coverage", vaccine_efficacy = "Vaccine efficacy",
                     initial_infected = "Infectious people at day 0", days = "Days simulated", steps_per_day = "Calculation steps per day",
                     method = "Method", growth_rate = "Growth rate per day", doubling_time = "Doubling time (days)",
                     final_attack = "Share of the population infected in the end", immune_share = "Share immune before the epidemic"),
  analyze_2x2 = c(a = "Exposed with the outcome", b = "Exposed without the outcome", c = "Unexposed with the outcome",
                  d = "Unexposed without the outcome", design = "Study design"),
  analyze_ci = c(n = "Sample size", mean = "Sample mean", x = "Number of events"),
  analyze_rates = c(events_exposed = "Events, exposed", person_time_exposed = "Person-time, exposed", events_unexposed = "Events, unexposed",
                    person_time_unexposed = "Person-time, unexposed", multiplier = "Rates reported per", events = "Events",
                    person_time = "Person-time", strata = "Strata"),
  analyze_vaccine = c(design = "Kind of data", cases_vaccinated = "Cases, vaccinated", cases_unvaccinated = "Cases, unvaccinated",
                      n_vaccinated = "Participants or person-time, vaccinated", n_unvaccinated = "Participants or person-time, unvaccinated",
                      controls_vaccinated = "Controls, vaccinated", controls_unvaccinated = "Controls, unvaccinated"),
  analyze_outbreak = c(cases = "Cases", at_risk = "Population at risk", deaths = "Deaths", recovered = "Recovered", exposures = "Exposures",
                       labels = "Exposure labels", secondary_cases = "Secondary cases", contacts = "Susceptible contacts"),
  analyze_compare = c(n1 = "Sample size, group 1", n2 = "Sample size, group 2", mean1 = "Mean, group 1", mean2 = "Mean, group 2",
                      sd1 = "SD, group 1", sd2 = "SD, group 2", x1 = "Events, group 1", x2 = "Events, group 2"),
  evpi = c(mean_inb = "Prior mean of the incremental net benefit", sd_inb = "Prior SD of the incremental net benefit",
           sampling_sd = "SD of one patient's outcome", cost_per_patient = "Cost per patient", fixed_cost = "Fixed cost of the study",
           n_max = "Largest sample size searched", n = "Sample size of the proposed study"),
  rmst = c(ac_period = "Accrual period", tot_time = "Total study time", tau = "Truncation time", shape0 = "Weibull shape, control",
           shape1 = "Weibull shape, treatment", scale0 = "Weibull scale, control", scale1 = "Weibull scale, treatment",
           allocation1 = "Proportion allocated to treatment"),
  competing_risks = c(lambda_11 = "Cause-specific hazard of the event, group 1", hr_1 = "Cause-specific hazard ratio",
                      hr_all = "Any-cause hazard ratio", rr = "Share of failures due to the event, group 1", accrual = "Accrual period",
                      follow_up = "Follow-up period", attrition = "Loss to follow-up", a1 = "Proportion allocated to group 1")
)

.study_labels_result <- c(
  n = "Sample size", n_total = "Total sample size", n_per_group = "Sample size per group", n1 = "Sample size, group 1",
  n2 = "Sample size, group 2", n_unadjusted = "Before inflating for non-response", n_enrolled = "To enrol", n_enrol = "To enrol",
  d_absolute = "Absolute precision", epsilon_relative = "Relative precision", achieved_power = "Achieved power", power = "Power",
  deff = "Design effect", n_effective = "Sample size after the design effect", icc = "Intracluster correlation (ICC)",
  n_clusters = "Number of clusters", events = "Number of events", z = "z value",
  n_cases = "Cases", n_controls = "Controls", n_intervention = "Intervention units", n_comparison = "Comparison units", n_pre = "Time points before the interruption", n_post = "Time points after the interruption",
  se = "Standard error", df = "Degrees of freedom", n_total_adjusted = "Heterogeneity-adjusted information size",
  adjustment_factor = "Adjustment factor", fixed_estimate = "Fixed-effect estimate",
  fixed_lower = "Fixed-effect lower limit", fixed_upper = "Fixed-effect upper limit", fixed_p = "Fixed-effect p-value",
  random_estimate = "Random-effects estimate", random_lower = "Random-effects lower limit", random_upper = "Random-effects upper limit",
  random_p = "Random-effects p-value", Q = "Cochran's Q", Q_p = "p-value of Q", I2 = "I-squared (%)", tau2 = "Between-study variance (tau-squared)"
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
