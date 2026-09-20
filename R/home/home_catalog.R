# Data for the Home page's two calculator finders (by study design, and by
# groups/data type). Content is data, same principle as R/content/*.R --
# adding a calculator means adding/flipping a catalog entry here, not
# rewriting the finder UI/server logic in home_finder.R.
#
# Each entry:
#   key          - unique id
#   label        - shown to the user
#   answers      - plain-language "what question does this calculator
#                   answer?" sentence, shown alongside the label so someone
#                   who doesn't yet know which calculator they need can tell
#                   two similar-looking options apart before clicking.
#   outcome_type - "proportion" | "mean" (used by the groups/data-type finder)
#   groups       - "1" | "2" | "3plus"  (used by the groups/data-type finder)
#   dependency   - "independent" | "dependent" | NA (only meaningful when groups == "2")
#   reference_based - TRUE | FALSE | NA (only meaningful when groups == "1":
#                      TRUE = hypothesis test against a known/reference value,
#                      FALSE = precision-based estimate, no reference value.
#                      NA = the distinction doesn't apply / isn't split yet.)
#   built        - TRUE if a module implements this; FALSE shows "coming soon"
#   nav_target   - nav_panel title to jump to when built
#   module_input_id - fully-qualified (namespaced) input id of the module's
#                      internal design selector, updated on jump (NA if none)
#   design_value - value to preset that input to (NA if none)

calculator_catalog <- list(
  list(key = "proportion_single_precision",
       label = "Single proportion — precision-based (no reference value)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate my own",
         "prevalence to within +/-d%?\" -- no benchmark, no power, no",
         "hypothesis, just a precision target and a confidence level."
       ),
       outcome_type = "proportion", groups = "1", dependency = NA, reference_based = FALSE,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "precision"),

  list(key = "proportion_single", label = "Single proportion vs. known/reference value",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that my",
         "population differs from some external benchmark?\" -- needs a",
         "null value, an expected value, and a power target."
       ),
       outcome_type = "proportion", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "single"),

  list(key = "proportion_two_indep", label = "Two independent proportions",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference between two independent groups' proportions?\" --",
         "needs both groups' expected proportions and a power target."
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "two_sample"),

  list(key = "proportion_posthoc_pairwise",
       label = "Post-hoc pairwise comparison of proportions (Bonferroni-adjusted)",
       answers = paste(
         "Answers: \"How many subjects do I need to compare two specific",
         "group proportions out of several planned pairwise comparisons,",
         "correcting for running multiple tests at once?\""
       ),
       outcome_type = "proportion", groups = "3plus", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "posthoc_pairwise"),

  list(key = "proportion_two_dep", label = "Two paired/dependent proportions (e.g. before-after, matched pairs)",
       answers = paste(
         "Answers: \"How many matched pairs do I need to detect a change",
         "in proportion within the same subjects (or matched pairs)?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "dependent", reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "proportion_k", label = "Three or more group proportions",
       answers = "Answers: \"How many subjects per group do I need to detect any difference across 3+ group proportions?\"",
       # Cross-referenced to the Chi-Square Tests module's independence
       # design (a k-groups x outcome-categories table), per the master
       # checklists' "every calculator reachable from both files" principle
       # -- not a separate implementation.
       outcome_type = "proportion", groups = "3plus", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "independence"),

  list(key = "means_single_precision",
       label = "Single mean — precision-based (no reference value)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate my own mean",
         "to within a desired precision?\" -- no benchmark, no power, no",
         "hypothesis, just a precision target and a confidence level."
       ),
       outcome_type = "mean", groups = "1", dependency = NA, reference_based = FALSE,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "single_precision"),

  list(key = "means_single", label = "Single mean vs. known value",
       answers = "Answers: \"How many subjects do I need to detect that my population's mean differs from a known/reference value?\"",
       outcome_type = "mean", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "single"),

  list(key = "means_two_indep", label = "Two independent means",
       answers = "Answers: \"How many subjects per group do I need to detect a difference between two independent groups' means?\"",
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "two_sample"),

  list(key = "means_two_indep_unequal_n",
       label = "Two independent means, unequal group sizes",
       answers = paste(
         "Answers: \"I already have a fixed number of subjects in one",
         "group -- how many do I need in the other to reach my desired",
         "power?\""
       ),
       # Distinct outcome_type sentinel (not "mean") so this never collides
       # with means_two_indep in the groups/data-type finder -- only
       # reachable via "by study design", same reasoning as Diagnostic
       # Accuracy/Agreement/Case-Control/Cohort/Correlation/Chi-square above.
       outcome_type = "means_unequal_n", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "two_sample_unequal_n"),

  list(key = "means_welch",
       label = "Two independent means, unequal variances (Welch's t-test)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference between two independent groups' means, when the two",
         "groups are expected to have genuinely different variability",
         "(not just different sample sizes)?\""
       ),
       outcome_type = "means_welch", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "welch"),

  list(key = "means_two_dep", label = "Two paired means (e.g. pre-post)",
       answers = "Answers: \"How many subjects do I need to detect a change in mean within the same subjects (pre-post)?\"",
       outcome_type = "mean", groups = "2", dependency = "dependent", reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "paired"),

  list(key = "means_k", label = "Three or more group means",
       answers = "Answers: \"How many subjects per group do I need to detect any difference across 3+ group means (one-way ANOVA)?\"",
       outcome_type = "mean", groups = "3plus", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "anova"),

  list(key = "means_planned_contrast", label = "Planned linear contrast among k group means",
       answers = paste(
         "Answers: \"How many subjects do I need to test one specific,",
         "pre-specified comparison across 3+ group means -- e.g. a linear",
         "dose-response trend -- rather than the omnibus ANOVA question",
         "of whether any groups differ at all?\""
       ),
       outcome_type = "mean", groups = "3plus", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "planned_contrast"),

  list(key = "means_posthoc_pairwise",
       label = "Post-hoc pairwise comparison of means (Bonferroni-adjusted)",
       answers = paste(
         "Answers: \"How many subjects do I need to compare two specific",
         "group means out of several planned pairwise comparisons,",
         "correcting for running multiple tests at once?\""
       ),
       outcome_type = "mean", groups = "3plus", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "posthoc_pairwise"),

  # Diagnostic Accuracy entries: outcome_type/groups don't apply to this
  # family (it's not a "how many groups" comparison in the usual sense), so
  # these are only reachable via the "by study design" finder, not "by
  # groups & data type" -- the groups finder just never matches them.
  list(key = "diagnostic_precision",
       label = "Sensitivity & specificity — precision-based (no reference value)",
       answers = paste(
         "Answers: \"How many subjects (diseased + non-diseased) do I need",
         "to estimate my test's sensitivity and specificity to a desired",
         "precision, given the condition's prevalence?\""
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "precision"),

  list(key = "diagnostic_vs_reference",
       label = "Sensitivity & specificity vs. known/reference value",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that my test's",
         "sensitivity/specificity differs from a known/reference value?\"",
         "-- needs reference and expected Sn/Sp, prevalence, and a power target."
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "vs_reference"),

  list(key = "diagnostic_two_indep",
       label = "Two independent (unpaired) diagnostic tests",
       answers = paste(
         "Answers: \"How many subjects per test do I need to detect a",
         "difference in sensitivity (or specificity) between two",
         "different tests run on two independent groups of subjects?\""
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "two_indep"),

  list(key = "diagnostic_two_paired",
       label = "Two paired diagnostic tests (same subjects)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a difference in",
         "sensitivity (or specificity) between two tests both run on the",
         "same subjects?\" -- returns a range rather than a single number."
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "two_paired"),

  # Agreement/Reliability entries: same reasoning as Diagnostic Accuracy
  # above -- not a "how many groups" comparison, so only reachable via "by
  # study design".
  list(key = "agreement_kappa",
       label = "Cohen's kappa (categorical agreement, no gold standard)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate agreement",
         "between two raters/methods (categorical rating) to a desired",
         "precision, when there's no reference standard to compare",
         "either one against?\""
       ),
       outcome_type = "agreement", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Agreement / Reliability",
       module_input_id = "agreement-design", design_value = "kappa"),

  list(key = "agreement_icc",
       label = "Intraclass correlation - ICC (continuous agreement, no gold standard)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate agreement",
         "between two raters/methods (continuous measurement) to a",
         "desired precision, when there's no reference standard?\""
       ),
       outcome_type = "agreement", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Agreement / Reliability",
       module_input_id = "agreement-design", design_value = "icc"),

  list(key = "agreement_cronbach",
       label = "Cronbach's alpha (scale internal consistency)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate my scale's",
         "Cronbach's alpha to a desired precision?\""
       ),
       outcome_type = "agreement", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Agreement / Reliability",
       module_input_id = "agreement-design", design_value = "cronbach"),

  list(key = "agreement_bland_altman",
       label = "Bland-Altman limits of agreement",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate the limits",
         "of agreement between two measurement methods to a desired",
         "precision?\""
       ),
       outcome_type = "agreement", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Agreement / Reliability",
       module_input_id = "agreement-design", design_value = "bland_altman"),

  list(key = "agreement_ccc",
       label = "Lin's concordance correlation coefficient (CCC)",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate a combined",
         "precision-and-accuracy agreement coefficient between two",
         "continuous measurement methods, to a desired precision?\""
       ),
       outcome_type = "agreement", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Agreement / Reliability",
       module_input_id = "agreement-design", design_value = "ccc"),

  # Case-Control / Cohort entries: same reasoning as Diagnostic Accuracy
  # above -- these compare exposure vs. outcome status, not "groups" in the
  # proportion/mean sense, so only reachable via "by study design".
  list(key = "case_control_unmatched",
       label = "Unmatched case-control study",
       answers = paste(
         "Answers: \"How many cases and controls do I need to detect a",
         "given odds ratio, sampling cases and controls independently",
         "(not matched to each other)?\""
       ),
       outcome_type = "case_control", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Case-Control",
       module_input_id = "case_control-design", design_value = "unmatched"),

  list(key = "case_control_matched",
       label = "Matched case-control study (1:1 or 1:m)",
       answers = paste(
         "Answers: \"How many matched case-control pairs (or sets) do I",
         "need to detect a given odds ratio, when each case is",
         "individually matched to one or more controls?\""
       ),
       outcome_type = "case_control", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Case-Control",
       module_input_id = "case_control-design", design_value = "matched"),

  list(key = "case_crossover",
       label = "Case-crossover study",
       answers = paste(
         "Answers: \"How many cases do I need for a case-crossover study,",
         "comparing each case's own exposure in a hazard period to their",
         "own exposure in one or more control periods?\" (uses the same",
         "matched case-control calculator -- a case-crossover design is",
         "mathematically a 1:M matched case-control design with M control",
         "periods per case, per Maclure 1991/Mittleman et al. 1995,",
         "confirmed by Dharmarajan, Lee & Izem 2019, who also document",
         "that this formula can underestimate the true required N for",
         "case-crossover specifically)"
       ),
       outcome_type = "case_control", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Case-Control",
       module_input_id = "case_control-design", design_value = "matched"),

  list(key = "case_control_nested",
       label = "Nested case-control study",
       answers = paste(
         "Answers: \"How many matched sets (cases + controls) do I need,",
         "sampling cases and controls from within an existing cohort and",
         "comparing them via conditional logistic regression?\""
       ),
       outcome_type = "case_control", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Case-Control",
       module_input_id = "case_control-design", design_value = "nested"),

  list(key = "case_control_case_cohort",
       label = "Case-cohort study",
       answers = paste(
         "Answers: \"How large a random subcohort do I need to sample from",
         "my already-assembled cohort, so that it plus all eventual cases",
         "gives me enough power to detect a given hazard ratio?\""
       ),
       outcome_type = "case_control", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Case-Control",
       module_input_id = "case_control-design", design_value = "case_cohort"),

  list(key = "cohort_rr",
       label = "Cohort study (relative risk)",
       answers = paste(
         "Answers: \"How many exposed and unexposed subjects do I need to",
         "detect a given relative risk, following both groups forward to",
         "see who develops the outcome?\""
       ),
       outcome_type = "cohort", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Cohort / RR",
       module_input_id = NA, design_value = NA),

  list(key = "sccs_samplesize",
       label = "Self-controlled case series (SCCS)",
       answers = paste(
         "Answers: \"How many cases do I need for a self-controlled case",
         "series study -- comparing each case's own event rate during a",
         "risk period (e.g. after a vaccine) to their own rate at other",
         "times, with no separate control group?\""
       ),
       outcome_type = "sccs", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Self-Controlled Case Series",
       module_input_id = NA, design_value = NA),

  list(key = "capture_recapture",
       label = "Two-sample mark-recapture (Chapman-Petersen), precision-based",
       answers = paste(
         "Answers: \"I'm planning a mark-recapture study to estimate an",
         "unknown population size N -- given a first-sample (marking)",
         "size and a rough planning guess at N, how large does my second",
         "sample need to be to estimate N to a target precision?\""
       ),
       outcome_type = "capture_recapture", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Capture-Recapture",
       module_input_id = NA, design_value = NA),

  list(key = "ecological_guidance",
       label = "Ecological study guidance (group-level design, no formula)",
       answers = paste(
         "Answers: \"I'm planning an ecological (group-level) study -- how",
         "many groups/areas do I need?\" (guidance, not a formula: unlike",
         "this app's individual-level calculators, the unit of analysis",
         "here is a group, and the design carries its own interpretive",
         "hazard -- the ecological fallacy -- regardless of group count)"
       ),
       outcome_type = "ecological", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Ecological Study Guidance",
       module_input_id = NA, design_value = NA),

  list(key = "efa_cfa_guidance",
       label = "EFA/CFA subjects-per-item sample size guidance",
       answers = paste(
         "Answers: \"I'm planning an exploratory or confirmatory factor",
         "analysis / scale validation study -- how many participants do",
         "I need relative to my number of items?\" (rule-of-thumb ratios,",
         "not a solved hypothesis-test formula)"
       ),
       outcome_type = "efa_cfa", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "EFA/CFA Sample Size Guidance",
       module_input_id = "efa_cfa-design", design_value = "rule_of_thumb"),

  list(key = "sem_rmsea",
       label = "CFA/SEM test of close fit via RMSEA",
       answers = paste(
         "Answers: \"How many participants do I need for a confirmatory",
         "factor analysis or SEM to test whether the model achieves",
         "close fit (or reject poor fit), given its degrees of freedom",
         "and a null vs. alternative RMSEA value?\" (a genuine closed-",
         "form hypothesis-test power calculation, unlike the rule-of-",
         "thumb guidance above)"
       ),
       outcome_type = "efa_cfa", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "EFA/CFA Sample Size Guidance",
       module_input_id = "efa_cfa-design", design_value = "rmsea"),

  list(key = "evpi",
       label = "Value of information (EVPI) for a cost-effectiveness decision",
       answers = paste(
         "Answers: \"Given the uncertainty in an existing cost-effectiveness",
         "analysis (mean and SD of the incremental net benefit from a",
         "probabilistic sensitivity analysis), is it worth doing more",
         "research at all, and what's the maximum any future study could",
         "be worth?\""
       ),
       outcome_type = "evpi", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Value of Information (EVPI/EVSI)",
       module_input_id = "evpi-design", design_value = "evpi"),

  list(key = "evsi_enbs",
       label = "Value of sample information (EVSI) and optimal sample size (ENBS)",
       answers = paste(
         "Answers: \"How large should a specific proposed follow-up study",
         "be, to maximize its expected net benefit once its cost is",
         "weighed against the decision uncertainty it would resolve?\""
       ),
       outcome_type = "evpi", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Value of Information (EVPI/EVSI)",
       module_input_id = "evpi-design", design_value = "evsi"),

  list(key = "correlation_pearson",
       label = "Pearson correlation",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a correlation",
         "of a given size between two continuous variables?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "single"),

  list(key = "correlation_two_independent",
       label = "Compare two independent correlations",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference in correlation strength between two independent",
         "groups?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "two_independent"),

  list(key = "correlation_two_dependent",
       label = "Compare two dependent (overlapping) correlations",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that a",
         "variable Y correlates more strongly with X1 than with X2, when",
         "X1 and X2 are both measured on the SAME subjects as Y?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "two_dependent"),

  list(key = "correlation_point_biserial",
       label = "Point-biserial correlation",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a correlation",
         "of a given size between a continuous outcome and a naturally",
         "dichotomous (two-group) variable?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "point_biserial"),

  list(key = "correlation_regression_slope",
       label = "Simple linear regression slope",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a bivariate",
         "regression slope of a given size (in raw units), given the",
         "predictor's and outcome's standard deviations?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "regression_slope"),

  list(key = "correlation_partial",
       label = "Partial correlation (controlling for k covariates)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a correlation",
         "between two variables after statistically controlling for one",
         "or more other covariates?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "partial"),

  list(key = "correlation_spearman",
       label = "Spearman rank correlation (ARE-inflated)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a Spearman",
         "rank correlation, when the relationship is expected to be",
         "monotonic but not necessarily linear, or the variables are",
         "ordinal?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = "correlation-design", design_value = "spearman"),

  # Chi-Square Tests entries: not a "how many groups" comparison in the
  # proportion/mean sense, so only reachable via "by study design" -- except
  # "independence" is also cross-referenced from proportion_k above, since
  # a k-group proportion comparison IS a chi-square independence test.
  list(key = "chisq_gof",
       label = "Chi-square goodness of fit",
       answers = paste(
         "Answers: \"How many subjects do I need to test whether a",
         "categorical variable's distribution matches an expected/",
         "hypothesized distribution?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "gof"),

  list(key = "chisq_independence",
       label = "Chi-square test of independence / association (R x C table)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect an association",
         "between two categorical variables (e.g. group and outcome",
         "category) in an R x C contingency table?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "independence"),

  list(key = "chisq_mcnemar",
       label = "McNemar's test (paired proportions)",
       answers = paste(
         "Answers: \"How many pairs do I need to detect an asymmetry in",
         "how a binary outcome switches, when the same subjects are",
         "measured twice (before/after, or two raters)?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "mcnemar"),

  list(key = "chisq_mantelhaenszel",
       label = "Mantel-Haenszel test (stratified proportions)",
       answers = paste(
         "Answers: \"How many subjects do I need to compare two groups'",
         "response proportions while adjusting for confounding strata",
         "(age bands, severity categories, propensity-score strata), via",
         "a Mantel-Haenszel-weighted test?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "mantelhaenszel"),

  list(key = "chisq_cochran_armitage",
       label = "Cochran-Armitage trend test (dose-response)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a monotonic",
         "trend in response proportion across ordered dose/exposure",
         "groups?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "cochran_armitage"),

  list(key = "cochran_q",
       label = "Cochran's Q test (k >= 3 paired/repeated binary measurements)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a difference",
         "among k >= 3 related (repeated/paired) binary measurements'",
         "success rates -- e.g. k raters, k diagnostic methods, or k",
         "repeated time points on the same subjects -- generalizing",
         "McNemar's test beyond two conditions?\""
       ),
       outcome_type = "chisq", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Chi-Square Tests",
       module_input_id = "chisq-design", design_value = "cochran_q"),

  list(key = "logrank",
       label = "Log-rank test (comparing two survival curves)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a given hazard",
         "ratio between two groups' survival curves over a fixed",
         "follow-up period?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "logrank"),

  list(key = "cox_binary",
       label = "Cox proportional-hazards regression -- binary covariate",
       answers = paste(
         "Answers: \"How many subjects do I need for a Cox regression",
         "analysis where the predictor of interest is binary (e.g.",
         "exposed vs. unexposed)?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "cox_binary"),

  list(key = "cox_continuous",
       label = "Cox proportional-hazards regression -- continuous covariate",
       answers = paste(
         "Answers: \"How many subjects do I need for a Cox regression",
         "analysis where the predictor of interest is continuous (e.g.",
         "age, biomarker level)?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "cox_continuous"),

  list(key = "survival_stratified",
       label = "Stratified log-rank test, exponential survival",
       answers = paste(
         "Answers: \"How many subjects do I need for a stratified log-rank",
         "test (e.g. across multiple sites or age bands) with exponential",
         "survival and a hazard ratio constant across strata?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "stratified"),

  list(key = "survival_noncompliance",
       label = "Log-rank test with accrual, follow-up & noncompliance",
       answers = paste(
         "Answers: \"How many subjects do I need for a survival trial with",
         "gradual enrollment (accrual), a minimum follow-up period, and",
         "some drop-in/non-adherence between arms diluting the treatment",
         "effect?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "noncompliance"),

  list(key = "weighted_logrank",
       label = "Weighted log-rank test under non-proportional hazards (Monte Carlo)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a treatment",
         "effect that isn't constant over time -- e.g. a DELAYED benefit",
         "that only appears later, or an EARLY effect that fades -- using",
         "a weighted (Fleming-Harrington G-rho family) log-rank test",
         "rather than the ordinary log-rank test?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Log-Rank / Survival",
       module_input_id = "logrank-design", design_value = "weighted_logrank"),

  list(key = "competing_risks_joint",
       label = "Joint cause-specific/any-cause hazard test (competing risks)",
       answers = paste(
         "Answers: \"How many cause-1 events and total patients do I need",
         "for a competing-risks trial that jointly tests the",
         "cause-specific hazard and the any-cause hazard, rather than",
         "either alone?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Competing Risks",
       module_input_id = NA, design_value = NA),

  list(key = "rmst_comparison",
       label = "Restricted mean survival time (RMST) comparison",
       answers = paste(
         "Answers: \"How many patients per arm do I need to detect a",
         "difference in restricted mean survival time (RMST) between two",
         "arms -- a model-free alternative to the hazard ratio that",
         "doesn't require the proportional-hazards assumption -- for a",
         "superiority or non-inferiority test?\""
       ),
       outcome_type = "survival", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "RMST Comparison",
       module_input_id = NA, design_value = NA),

  list(key = "longitudinal_slope_diff",
       label = "Longitudinal group-slope-difference test (GEE/GLS, Liu & Liang)",
       answers = paste(
         "Answers: \"How many subjects do I need for a longitudinal",
         "trial (e.g. tracking cognitive decline or a biomarker over",
         "repeated visits) to detect a difference in the RATE OF CHANGE",
         "(slope) between two groups, under a random-intercept/random-",
         "slope covariance structure?\""
       ),
       outcome_type = "means", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Longitudinal / MMRM",
       module_input_id = "longitudinal-design", design_value = "slope_diff"),

  list(key = "multilevel_two_level",
       label = "Multilevel model, two-level (subjects, repeated measures)",
       answers = paste(
         "Answers: \"How many subjects do I need for a longitudinal",
         "trial analyzed with a random-intercept/random-slope",
         "hierarchical (mixed) model, testing a treatment-group",
         "difference in the RATE OF CHANGE over time?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multilevel / Hierarchical Model",
       module_input_id = "multilevel-design", design_value = "two_level"),

  list(key = "multilevel_three_level",
       label = "Multilevel model, three-level (subjects nested in clusters)",
       answers = paste(
         "Answers: \"How many clusters (schools, clinics, wards) do I",
         "need for a cluster-randomized longitudinal trial analyzed",
         "with a 3-level hierarchical mixed model, testing a",
         "treatment-group difference in the rate of change over",
         "time?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multilevel / Hierarchical Model",
       module_input_id = "multilevel-design", design_value = "three_level"),

  list(key = "meta_power_k",
       label = "Required number of studies (k) for a planned meta-analysis",
       answers = paste(
         "Answers: \"How many studies (of a given size) do I need in a",
         "planned meta-analysis to reliably detect a true summary",
         "effect, accounting for between-study heterogeneity",
         "(I-squared)?\""
       ),
       outcome_type = "meta_analysis", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Meta-Analysis Power",
       module_input_id = NA, design_value = NA),

  list(key = "mmrm_ar1",
       label = "MMRM with dropout, AR(1) correlation (Lu, Luo & Chen)",
       answers = paste(
         "Answers: \"How many subjects do I need for a longitudinal",
         "trial comparing two arms' mean outcome using a mixed model of",
         "repeated measures (MMRM), accounting for dropout/missing data",
         "and an AR(1) correlation structure between visits?\""
       ),
       outcome_type = "means", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Longitudinal / MMRM",
       module_input_id = "longitudinal-design", design_value = "mmrm_ar1"),

  list(key = "cluster_deff",
       label = "Cluster / multistage sampling -- design effect (DEFF)",
       answers = paste(
         "Answers: \"I already have a simple-random-sample size -- how much",
         "bigger does it need to be if I'm sampling in clusters (villages,",
         "schools, facilities) rather than individuals?\""
       ),
       outcome_type = "cluster", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Cluster / Design Effect",
       module_input_id = "cluster-design", design_value = "deff"),

  list(key = "cluster_deff_variable",
       label = "Cluster / multistage sampling -- design effect, variable cluster size",
       answers = paste(
         "Answers: \"Same as the design-effect calculator above, but my",
         "clusters don't all recruit the same number of subjects -- how",
         "does that extra variability in cluster size change how much",
         "bigger my sample needs to be?\""
       ),
       outcome_type = "cluster", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Cluster / Design Effect",
       module_input_id = "cluster-design", design_value = "deff_variable"),

  list(key = "cluster_survey",
       label = "Cluster survey precision (WHO EPI-style, proportion)",
       answers = paste(
         "Answers: \"How many clusters and how many individuals do I",
         "need for a cluster survey (e.g. a WHO EPI-style immunization-",
         "coverage survey) estimating a proportion to a target",
         "precision?\""
       ),
       outcome_type = "cluster", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Cluster / Design Effect",
       module_input_id = "cluster-design", design_value = "survey"),

  list(key = "stepped_wedge_normal",
       label = "Stepped-wedge cluster-randomized trial (continuous outcome)",
       answers = paste(
         "Answers: \"How many clusters do I need for a stepped-wedge",
         "cluster-randomized trial, where every cluster starts on control",
         "and crosses over to the intervention at a randomized time,",
         "rather than half staying on control throughout?\""
       ),
       outcome_type = "means", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Stepped-Wedge CRT",
       module_input_id = NA, design_value = NA),

  list(key = "stratified_sampling",
       label = "Stratified sampling -- total size and per-stratum allocation",
       answers = paste(
         "Answers: \"My population is split into strata (urban/rural, age",
         "groups, departments) -- how many subjects do I need overall, and",
         "how should they be split across strata?\""
       ),
       outcome_type = "stratified", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Stratified Sampling",
       module_input_id = NA, design_value = NA),

  list(key = "lqas",
       label = "Lot Quality Assurance Sampling (LQAS)",
       answers = paste(
         "Answers: \"How many people do I need to sample in a rapid",
         "program-monitoring survey to classify an area as high- or",
         "low-performing against two coverage thresholds, controlling",
         "both misclassification risks?\""
       ),
       outcome_type = "lqas", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "LQAS",
       module_input_id = NA, design_value = NA),

  list(key = "resource_equation",
       label = "Resource equation method (animal studies)",
       answers = paste(
         "Answers: \"For a small exploratory animal study with no prior",
         "effect-size estimate to power against, how many animals per",
         "group gives an adequate (but not wasteful) error degrees of",
         "freedom, per Mead's rule of thumb?\""
       ),
       outcome_type = "resource_equation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Resource Equation (Animal Studies)",
       module_input_id = "resource_equation-mode", design_value = "size"),

  list(key = "subgroup_interaction",
       label = "Subgroup / interaction testing sample-size inflation (4x rule)",
       answers = paste(
         "Answers: \"I've already sized my trial to detect a main",
         "treatment effect -- how much bigger does it need to be to",
         "reliably detect whether that effect DIFFERS between two",
         "subgroups (a treatment-by-subgroup interaction)?\""
       ),
       outcome_type = "subgroup_interaction", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Subgroup / Interaction Testing",
       module_input_id = NA, design_value = NA),

  list(key = "qualitative_guidance",
       label = "Qualitative / mixed methods sample size guidance",
       answers = paste(
         "Answers: \"I'm planning a qualitative interview study -- how",
         "many participants do I need?\" (guidance, not a formula: this",
         "presents saturation, information power, and purposive/",
         "theoretical sampling frameworks rather than computing a",
         "number)"
       ),
       outcome_type = "qualitative", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Qualitative Sample Size Guidance",
       module_input_id = NA, design_value = NA),

  list(key = "glmm_lmm_continuous",
       label = "Cluster-randomized trial, continuous outcome (Monte Carlo LMM)",
       answers = paste(
         "Answers: \"How many clusters (clinics, schools, villages) do",
         "I need for a cluster-randomized trial with a continuous",
         "outcome, analyzed with a random-intercept linear mixed",
         "model?\" (Monte Carlo: directly simulates and refits the",
         "actual mixed-model analysis, since no closed-form formula",
         "exists for it)"
       ),
       outcome_type = "glmm", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Monte Carlo Mixed Models",
       module_input_id = "glmm-design", design_value = "lmm_continuous"),

  list(key = "glmm_binary",
       label = "Cluster-randomized trial, binary outcome (Monte Carlo GLMM)",
       answers = paste(
         "Answers: \"How many clusters do I need for a cluster-",
         "randomized trial with a binary outcome, analyzed with a",
         "random-intercept logistic mixed model (GLMM)?\" (Monte Carlo:",
         "directly simulates and refits the actual mixed-model",
         "analysis, since no closed-form formula exists for it)"
       ),
       outcome_type = "glmm", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Monte Carlo Mixed Models",
       module_input_id = "glmm-design", design_value = "glmm_binary"),

  list(key = "growth_curve_lmm",
       label = "Growth curve model, group difference in slope (Monte Carlo LMM)",
       answers = paste(
         "Answers: \"How many subjects per group do I need for a",
         "longitudinal trial testing whether two groups differ in their",
         "RATE OF CHANGE over time (a growth curve), analyzed with a",
         "random-intercept/random-slope linear mixed model?\" (Monte",
         "Carlo: directly simulates and refits the actual mixed-model",
         "analysis, since no closed-form formula exists for it -- the",
         "same technique the `simr` package wraps)"
       ),
       outcome_type = "glmm", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Monte Carlo Mixed Models",
       module_input_id = "glmm-design", design_value = "growth_curve"),

  list(key = "crossover_2x2",
       label = "2x2 crossover trial (continuous outcome) -- test for a difference",
       answers = paste(
         "Answers: \"How many subjects do I need for a 2x2 crossover trial",
         "(each subject gets both treatments, in one of two sequences)",
         "comparing mean outcomes between treatments?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Crossover Trial (2x2)",
       module_input_id = NA, design_value = NA),

  list(key = "anova_general",
       label = "Factorial ANOVA / ANCOVA (general F-test)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a main effect,",
         "interaction, or covariate-adjusted group effect in a factorial",
         "ANOVA or ANCOVA?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Factorial ANOVA / ANCOVA",
       module_input_id = NA, design_value = NA),

  list(key = "logistic_binary",
       label = "Logistic regression -- binary predictor",
       answers = paste(
         "Answers: \"How many subjects do I need for a logistic regression",
         "with a binary predictor (exposed vs. unexposed)?\""
       ),
       outcome_type = "binary", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Logistic Regression",
       module_input_id = "logistic-design", design_value = "binary"),

  list(key = "logistic_continuous",
       label = "Logistic regression -- continuous predictor",
       answers = paste(
         "Answers: \"How many subjects do I need for a logistic regression",
         "with a continuous predictor (e.g. age, a biomarker level)?\""
       ),
       outcome_type = "binary", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Logistic Regression",
       module_input_id = "logistic-design", design_value = "continuous"),

  list(key = "logistic_ordinal",
       label = "Ordinal (proportional odds) regression, two groups",
       answers = paste(
         "Answers: \"How many subjects do I need to compare two groups on",
         "an ordinal outcome with 3 or more ordered categories (e.g. a",
         "pain severity scale), via a proportional-odds model?\""
       ),
       outcome_type = "ordinal", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Logistic Regression",
       module_input_id = "logistic-design", design_value = "ordinal"),

  list(key = "logistic_binary_adjusted",
       label = "Multiple logistic regression, covariate-adjusted -- binary predictor",
       answers = paste(
         "Answers: \"How many subjects do I need for a binary predictor in",
         "a MULTIPLE logistic regression model, adjusting for its",
         "correlation (R-squared) with other covariates in the model?\""
       ),
       outcome_type = "binary", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Logistic Regression",
       module_input_id = "logistic-design", design_value = "binary_adjusted"),

  list(key = "logistic_continuous_adjusted",
       label = "Multiple logistic regression, covariate-adjusted -- continuous predictor",
       answers = paste(
         "Answers: \"How many subjects do I need for a continuous",
         "predictor in a MULTIPLE logistic regression model, adjusting for",
         "its correlation (R-squared) with other covariates in the",
         "model?\""
       ),
       outcome_type = "binary", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Logistic Regression",
       module_input_id = "logistic-design", design_value = "continuous_adjusted"),

  list(key = "rm_anova_between",
       label = "Repeated-measures ANOVA -- between-subjects effect",
       answers = paste(
         "Answers: \"How many subjects do I need to detect an overall",
         "between-group effect in a repeated-measures design?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "RM-ANOVA / Mixed ANOVA",
       module_input_id = "rm_anova-design", design_value = "between"),

  list(key = "rm_anova_within",
       label = "Repeated-measures ANOVA -- within-subjects effect",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a",
         "within-subjects (e.g. change-over-time) effect in a",
         "repeated-measures design?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "RM-ANOVA / Mixed ANOVA",
       module_input_id = "rm_anova-design", design_value = "within"),

  list(key = "wilcoxon_rank_sum",
       label = "Wilcoxon rank-sum test (Mann-Whitney U)",
       answers = paste(
         "Answers: \"How many subjects do I need to compare two",
         "independent groups on a continuous/ordinal outcome, without",
         "assuming normality?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "rank_sum"),

  list(key = "wilcoxon_signed_rank",
       label = "Wilcoxon signed-rank test (one sample / paired)",
       answers = paste(
         "Answers: \"How many subjects do I need to test whether a",
         "median (or paired-difference median) differs from zero,",
         "without assuming normality?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "signed_rank"),

  list(key = "kendall_tau",
       label = "Kendall's tau (nonparametric association)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect an association",
         "between two continuous variables, without assuming bivariate",
         "normality?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "kendall"),

  list(key = "kruskal_wallis",
       label = "Kruskal-Wallis test (k independent groups)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference among 3 or more independent groups, without",
         "assuming normality?\""
       ),
       outcome_type = "continuous", groups = "3+", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "kruskal_wallis"),

  list(key = "jonckheere_terpstra",
       label = "Jonckheere-Terpstra test (ordered alternatives)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a monotonic",
         "trend in a continuous outcome across ordered groups (e.g.",
         "increasing dose levels), without assuming normality?\""
       ),
       outcome_type = "continuous", groups = "3+", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "jonckheere"),

  list(key = "friedman",
       label = "Friedman test (k related/repeated measurements)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a difference",
         "among 3 or more repeated measurements/conditions on the SAME",
         "subjects, without assuming normality?\""
       ),
       outcome_type = "continuous", groups = "3+", dependency = "paired", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "friedman"),

  list(key = "ks_two_sample",
       label = "Kolmogorov-Smirnov test (two independent samples, Monte Carlo)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "distributional difference between two independent samples via",
         "the Kolmogorov-Smirnov test, when no closed-form power formula",
         "exists?\""
       ),
       outcome_type = "continuous", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "ks"),

  list(key = "wald_wolfowitz_runs",
       label = "Wald-Wolfowitz runs test (two independent samples, Monte Carlo)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "distributional difference between two independent samples via",
         "the Wald-Wolfowitz runs test, when no closed-form power formula",
         "exists?\""
       ),
       outcome_type = "continuous", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "runs"),

  list(key = "animal_rank_test",
       label = "Animal/preclinical K-sample rank test (Lehmann alternative, Monte Carlo)",
       answers = paste(
         "Answers: \"For a small preclinical/animal study with one control",
         "group and one or more treated groups, how many animals per group",
         "do I need to detect an assumed odds ratio under Heller (2006)'s",
         "Lehmann alternative, via the Kruskal-Wallis or Jonckheere-Terpstra",
         "rank statistic?\""
       ),
       outcome_type = "ordinal", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Nonparametric Tests",
       module_input_id = "nonparametric-design", design_value = "animal_rank"),

  list(key = "rm_anova_interaction",
       label = "Mixed (split-plot) ANOVA -- group x time interaction",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a group-by-time",
         "interaction (does the change over time differ between groups)?\""
       ),
       outcome_type = "continuous", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "RM-ANOVA / Mixed ANOVA",
       module_input_id = "rm_anova-design", design_value = "interaction"),

  list(key = "pilot_feasibility",
       label = "Pilot / feasibility study",
       answers = paste(
         "Answers: \"Roughly how many subjects do I need for a pilot",
         "study, and how precisely will that pilot estimate the",
         "variance I'll use to plan my main trial?\" -- guidance, not a",
         "hypothesis-test formula."
       ),
       outcome_type = "pilot", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Pilot / Feasibility",
       module_input_id = NA, design_value = NA),

  list(key = "simon_two_stage",
       label = "Simon two-stage Phase II design",
       answers = paste(
         "Answers: \"How many patients do I need for a single-arm Phase",
         "II trial that can stop early if the treatment looks",
         "ineffective?\""
       ),
       outcome_type = "phase2", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Simon Two-Stage",
       module_input_id = NA, design_value = NA),

  list(key = "tost_means",
       label = "Equivalence of two means (TOST)",
       answers = paste(
         "Answers: \"How many subjects do I need to show two group means",
         "are practically equivalent (within a margin), rather than to",
         "detect a difference?\""
       ),
       outcome_type = "equivalence", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Equivalence (TOST)",
       module_input_id = "tost-design", design_value = "means"),

  list(key = "tost_proportions",
       label = "Equivalence of two proportions (TOST)",
       answers = paste(
         "Answers: \"How many subjects do I need to show two group",
         "proportions are practically equivalent (within a margin),",
         "rather than to detect a difference?\""
       ),
       outcome_type = "equivalence", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Equivalence (TOST)",
       module_input_id = "tost-design", design_value = "proportions"),

  list(key = "tost_bioequivalence",
       label = "Pharmacokinetic bioequivalence crossover (TOST)",
       answers = paste(
         "Answers: \"How many subjects do I need for a bioequivalence",
         "crossover study (classical 2x2, or a full/partial replicate",
         "design), comparing a test and reference formulation's exposure",
         "via a log-scale ratio?\""
       ),
       outcome_type = "equivalence", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Equivalence (TOST)",
       module_input_id = "tost-design", design_value = "bioequivalence"),

  list(key = "tost_assurance",
       label = "Bioequivalence crossover, expected power (assurance)",
       answers = paste(
         "Answers: \"How many subjects do I need for a bioequivalence",
         "crossover study, accounting for the fact that my assumed CV is",
         "itself only an estimate from a smaller prior/pilot study?\""
       ),
       outcome_type = "equivalence", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Equivalence (TOST)",
       module_input_id = "tost-design", design_value = "assurance"),

  list(key = "noninferiority_means",
       label = "Non-inferiority trial, two means",
       answers = paste(
         "Answers: \"How many subjects do I need to show a new",
         "treatment's mean outcome isn't worse than a standard",
         "treatment's by more than an acceptable margin?\""
       ),
       outcome_type = "noninferiority", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Non-Inferiority",
       module_input_id = "noninferiority-design", design_value = "means"),

  list(key = "noninferiority_proportions",
       label = "Non-inferiority trial, two proportions",
       answers = paste(
         "Answers: \"How many subjects do I need to show a new",
         "treatment's success rate isn't worse than a standard",
         "treatment's by more than an acceptable margin?\""
       ),
       outcome_type = "noninferiority", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Non-Inferiority",
       module_input_id = "noninferiority-design", design_value = "proportions"),

  list(key = "noninferiority_or",
       label = "Non-inferiority trial, odds ratio",
       answers = paste(
         "Answers: \"How many subjects do I need to show a new",
         "treatment's odds of a binary outcome aren't worse than a",
         "standard treatment's by more than an acceptable margin,",
         "expressed as an odds ratio?\""
       ),
       outcome_type = "noninferiority", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Non-Inferiority",
       module_input_id = "noninferiority-design", design_value = "odds_ratio"),

  list(key = "noninferiority_hr",
       label = "Non-inferiority trial, hazard ratio (Cox PH)",
       answers = paste(
         "Answers: \"How many subjects do I need to show a new",
         "treatment's hazard (event) rate isn't worse than a standard",
         "treatment's by more than an acceptable margin, for a",
         "time-to-event outcome?\""
       ),
       outcome_type = "noninferiority", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Non-Inferiority",
       module_input_id = "noninferiority-design", design_value = "hazard_ratio"),

  list(key = "incidence_rate_precision",
       label = "Incidence rate, precision-based",
       answers = paste(
         "Answers: \"How many events (and how much person-time) do I need",
         "to estimate an incidence rate to a desired precision?\" -- no",
         "comparison group, just a precision target."
       ),
       outcome_type = "rate", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Incidence Rate",
       module_input_id = "rate-design", design_value = "precision"),

  list(key = "rate_comparison",
       label = "Comparison of two incidence rates",
       answers = paste(
         "Answers: \"How many subjects (or how much person-time) do I need",
         "to detect a given rate ratio between an exposed and a reference",
         "group?\""
       ),
       outcome_type = "rate", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Incidence Rate",
       module_input_id = "rate-design", design_value = "comparison"),

  list(key = "poisson_regression_continuous",
       label = "Poisson regression, continuous predictor",
       answers = paste(
         "Answers: \"How many subjects do I need to detect an association",
         "between a continuous exposure/biomarker and an event rate, via",
         "Poisson regression?\""
       ),
       outcome_type = "rate", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Incidence Rate",
       module_input_id = "rate-design", design_value = "poisson_regression"),

  list(key = "negative_binomial_rates",
       label = "Comparison of two negative binomial rates",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a given rate",
         "ratio between two groups' recurrent-event counts (e.g.",
         "hospitalizations, exacerbations, relapses), when the event",
         "counts are over-dispersed beyond what a plain Poisson model",
         "allows -- following the negative binomial model?\""
       ),
       outcome_type = "rate", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Incidence Rate",
       module_input_id = "rate-design", design_value = "negative_binomial"),

  list(key = "ratio_risk_ratio",
       label = "Risk ratio -- precision-based",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate a risk ratio",
         "to a target confidence-interval width, rather than to test a",
         "specific hypothesis?\""
       ),
       outcome_type = "ratio", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Ratio Estimation",
       module_input_id = "ratio-design", design_value = "risk_ratio"),

  list(key = "ratio_odds_ratio",
       label = "Odds ratio -- precision-based",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate an odds ratio",
         "to a target confidence-interval width, rather than to test a",
         "specific hypothesis?\""
       ),
       outcome_type = "ratio", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Ratio Estimation",
       module_input_id = "ratio-design", design_value = "odds_ratio"),

  list(key = "ratio_rate_ratio",
       label = "Rate ratio -- precision-based",
       answers = paste(
         "Answers: \"How many subjects (or how much person-time) do I need",
         "to estimate a rate ratio to a target precision level, rather",
         "than to test a specific hypothesis?\""
       ),
       outcome_type = "ratio", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Ratio Estimation",
       module_input_id = "ratio-design", design_value = "rate_ratio"),

  list(key = "diagnostic_ppv_npv",
       label = "Predictive values (PPV/NPV), precision-based",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate my test's",
         "positive and negative predictive values to a desired precision,",
         "given its sensitivity, specificity, and the condition's",
         "prevalence?\""
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "ppv_npv"),

  list(key = "diagnostic_likelihood_ratio",
       label = "Likelihood ratios (LR+/LR-), precision-based",
       answers = paste(
         "Answers: \"How many subjects do I need to estimate my test's",
         "positive or negative likelihood ratio to a desired precision?\""
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "likelihood_ratio"),

  list(key = "diagnostic_odds_ratio",
       label = "Diagnostic odds ratio (DOR)",
       answers = paste(
         "Answers: \"How many subjects do I need to test whether my",
         "test's diagnostic odds ratio differs from 1 (no",
         "discrimination), given its expected sensitivity and",
         "specificity?\""
       ),
       outcome_type = "diagnostic", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Diagnostic Accuracy",
       module_input_id = "diagnostic-design", design_value = "odds_ratio"),

  list(key = "exact_binomial",
       label = "Binomial test, single proportion (exact)",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that my",
         "proportion differs from a reference value, using the exact",
         "binomial distribution instead of the normal approximation?\""
       ),
       outcome_type = "exact", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Exact Tests",
       module_input_id = "exact_tests-design", design_value = "binomial"),

  list(key = "exact_fisher",
       label = "Fisher's exact test, two independent proportions",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference between two independent groups' proportions, using",
         "Fisher's exact test (better than the normal approximation for",
         "small samples)?\""
       ),
       outcome_type = "exact", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Exact Tests",
       module_input_id = "exact_tests-design", design_value = "fisher"),

  list(key = "exact_boschloo",
       label = "Boschloo's exact test, two independent proportions (unconditional)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to detect a",
         "difference between two independent groups' proportions, using",
         "the unconditional exact (Boschloo) test -- uniformly at least as",
         "powerful as Fisher's exact test?\""
       ),
       outcome_type = "exact", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Exact Tests",
       module_input_id = "exact_tests-design", design_value = "boschloo"),

  list(key = "exact_poisson",
       label = "Exact Poisson test, single rate vs. reference",
       answers = paste(
         "Answers: \"How much person-time do I need to observe to detect",
         "whether my population's incidence rate differs from a known",
         "background/standard rate, using the exact Poisson",
         "distribution?\""
       ),
       outcome_type = "exact", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Exact Tests",
       module_input_id = "exact_tests-design", design_value = "poisson"),

  list(key = "sign_test",
       label = "Sign test (paired data / one-sample median)",
       answers = paste(
         "Answers: \"How many pairs do I need to detect that differences",
         "tend to be positive more often than negative, without assuming",
         "a symmetric distribution of differences?\""
       ),
       outcome_type = "exact", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Exact Tests",
       module_input_id = "exact_tests-design", design_value = "sign"),

  list(key = "prediction_binary",
       label = "Prediction model development -- binary outcome",
       answers = paste(
         "Answers: \"How many subjects do I need to develop a new",
         "multivariable prediction model for a binary outcome, without",
         "excessive overfitting?\""
       ),
       outcome_type = "prediction", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Prediction Model",
       module_input_id = "prediction-design", design_value = "binary"),

  list(key = "prediction_continuous",
       label = "Prediction model development -- continuous outcome",
       answers = paste(
         "Answers: \"How many subjects do I need to develop a new",
         "multivariable prediction model for a continuous outcome,",
         "without excessive overfitting?\""
       ),
       outcome_type = "prediction", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Prediction Model",
       module_input_id = "prediction-design", design_value = "continuous"),

  list(key = "prediction_survival",
       label = "Prediction model development -- survival outcome",
       answers = paste(
         "Answers: \"How many subjects do I need to develop a new",
         "multivariable prediction model for a time-to-event outcome,",
         "without excessive overfitting?\""
       ),
       outcome_type = "prediction", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Prediction Model",
       module_input_id = "prediction-design", design_value = "survival"),

  list(key = "prediction_external_validation",
       label = "Prediction model external validation -- binary outcome",
       answers = paste(
         "Answers: \"How many subjects do I need to externally validate an",
         "already-developed prediction model for a binary outcome, so its",
         "O/E ratio, calibration slope, C-statistic (and optionally",
         "standardised net benefit) are all estimated precisely?\""
       ),
       outcome_type = "prediction", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Prediction Model",
       module_input_id = "prediction-design", design_value = "external_validation"),

  list(key = "roc_single_auc",
       label = "Single ROC AUC vs. chance (0.5)",
       answers = paste(
         "Answers: \"How many cases and controls do I need to show my",
         "test's AUC is significantly better than chance?\""
       ),
       outcome_type = "roc", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "ROC / AUC",
       module_input_id = "roc-design", design_value = "single_auc"),

  list(key = "roc_compare_two_aucs",
       label = "Compare two correlated (paired) ROC AUCs",
       answers = paste(
         "Answers: \"How many cases and controls do I need to detect",
         "that two diagnostic tests' AUCs differ, when both tests are",
         "applied to the same subjects?\""
       ),
       outcome_type = "roc", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "ROC / AUC",
       module_input_id = "roc-design", design_value = "compare_two"),

  list(key = "regression_r2",
       label = "Multiple linear regression, R-squared deviation from zero",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that my",
         "regression model's overall R-squared is significantly greater",
         "than zero, given a fixed number of predictors?\""
       ),
       outcome_type = "regression", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Multiple Regression",
       module_input_id = "regression-design", design_value = "r2"),

  list(key = "regression_r2_increase",
       label = "Hierarchical multiple regression, R-squared increase",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that adding a",
         "set of new predictors to my existing regression model",
         "significantly increases R-squared?\""
       ),
       outcome_type = "regression", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Multiple Regression",
       module_input_id = "regression-design", design_value = "r2_increase"),

  list(key = "rule_of_three_bound",
       label = "Upper bound on an unseen event rate (rule of three)",
       answers = paste(
         "Answers: \"I observed zero events in n subjects -- what's the",
         "worst-case true event rate that's still consistent with that?\""
       ),
       outcome_type = "safety", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Rule of Three",
       module_input_id = "rule_of_three-design", design_value = "bound"),

  list(key = "rule_of_three_n_required",
       label = "Sample size to detect at least one event",
       answers = paste(
         "Answers: \"Given an assumed true event rate, how many subjects",
         "do I need to have a good chance of observing at least one",
         "event?\""
       ),
       outcome_type = "safety", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Rule of Three",
       module_input_id = "rule_of_three-design", design_value = "n_required"),

  list(key = "rule_of_three_detect_imperfect",
       label = "Detect at least one case, imperfect test (finite population)",
       answers = paste(
         "Answers: \"How many units do I need to sample from a known-size",
         "population to be confident of detecting at least one case, if",
         "present, using a test with imperfect sensitivity/specificity",
         "(one test, or two combined in series/parallel)?\""
       ),
       outcome_type = "safety", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Rule of Three",
       module_input_id = "rule_of_three-design", design_value = "detect_imperfect"),

  list(key = "group_sequential_normal",
       label = "Group sequential design, continuous outcome",
       answers = paste(
         "Answers: \"How large a trial do I need, at most, if I plan to",
         "monitor a continuous outcome at several interim analyses and",
         "stop early for benefit (or futility)?\""
       ),
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Group Sequential Design",
       module_input_id = "group_sequential-design", design_value = "normal"),

  list(key = "group_sequential_binary",
       label = "Group sequential design, binary outcome",
       answers = paste(
         "Answers: \"How large a trial do I need, at most, if I plan to",
         "monitor a binary/proportion outcome at several interim",
         "analyses and stop early for benefit (or futility)?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Group Sequential Design",
       module_input_id = "group_sequential-design", design_value = "binary"),

  list(key = "group_sequential_survival",
       label = "Group sequential design, time-to-event outcome",
       answers = paste(
         "Answers: \"How many events do I need, at most, if I plan to",
         "monitor a survival/time-to-event trial at several interim",
         "analyses and stop early for benefit (or futility)?\""
       ),
       outcome_type = "survival", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Group Sequential Design",
       module_input_id = "group_sequential-design", design_value = "survival"),

  list(key = "lan_demets_normal",
       label = "Lan-DeMets alpha-spending design, continuous outcome (2 looks)",
       answers = paste(
         "Answers: \"How large a trial do I need, at most, if I plan a",
         "single interim look using the literal Lan-DeMets (O'Brien-",
         "Fleming-type or Pocock-type) alpha-spending function, rather",
         "than the power-family boundary reparameterization?\""
       ),
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Group Sequential Design",
       module_input_id = "group_sequential-design", design_value = "lan_demets_normal"),

  list(key = "tsa_rr",
       label = "Trial sequential analysis, risk ratio",
       answers = paste(
         "Answers: \"How large does the cumulative evidence base (across",
         "all trials in a meta-analysis) need to be for adequate power",
         "to detect an anticipated risk ratio, and what is the",
         "information-size threshold used to build TSA monitoring",
         "boundaries?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Trial Sequential Analysis",
       module_input_id = "tsa-outcome", design_value = "RR"),

  list(key = "tsa_or",
       label = "Trial sequential analysis, odds ratio",
       answers = paste(
         "Answers: \"How large does the cumulative evidence base need to",
         "be for adequate power to detect an anticipated odds ratio in a",
         "meta-analysis?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Trial Sequential Analysis",
       module_input_id = "tsa-outcome", design_value = "OR"),

  list(key = "tsa_rd",
       label = "Trial sequential analysis, risk difference",
       answers = paste(
         "Answers: \"How large does the cumulative evidence base need to",
         "be for adequate power to detect an anticipated absolute risk",
         "difference in a meta-analysis?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Trial Sequential Analysis",
       module_input_id = "tsa-outcome", design_value = "RD"),

  list(key = "tsa_md",
       label = "Trial sequential analysis, mean difference",
       answers = paste(
         "Answers: \"How large does the cumulative evidence base need to",
         "be for adequate power to detect an anticipated mean difference",
         "in a meta-analysis?\""
       ),
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Trial Sequential Analysis",
       module_input_id = "tsa-outcome", design_value = "MD"),

  list(key = "variance_single",
       label = "Single-variance test (vs. a reference SD)",
       answers = paste(
         "Answers: \"How many subjects do I need to test whether a",
         "population's variability (SD) differs from a specific",
         "reference value?\""
       ),
       outcome_type = "variance", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Variance Tests",
       module_input_id = "variance-design", design_value = "single"),

  list(key = "variance_two",
       label = "Two-variance test (compare two groups)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to test",
         "whether two groups have equal variability (SD), rather than",
         "comparing their means?\""
       ),
       outcome_type = "variance", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Variance Tests",
       module_input_id = "variance-design", design_value = "two"),

  list(key = "variance_sd_precision",
       label = "Precision-based SD estimation (CI width, no hypothesis test)",
       answers = paste(
         "Answers: \"How many subjects do I need so that a confidence",
         "interval for the true SD is no wider than a target multiple of",
         "the SD I end up observing?\" (no hypothesis, no power target --",
         "a precision question, the same chi-squared identity this app's",
         "Pilot/Feasibility module already uses in the opposite direction)"
       ),
       outcome_type = "variance", groups = "1", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Variance Tests",
       module_input_id = "variance-design", design_value = "sd_precision"),

  list(key = "multiplicity_proportion_1s",
       label = "Multiplicity-adjusted: one proportion vs. reference",
       answers = paste(
         "Answers: \"I'm planning several simultaneous comparisons of a",
         "proportion against a reference value -- how many subjects do I",
         "need per comparison after a Bonferroni/Sidak alpha correction?\""
       ),
       outcome_type = "proportion", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "proportion_1s"),

  list(key = "multiplicity_proportion_2s",
       label = "Multiplicity-adjusted: two independent proportions",
       answers = paste(
         "Answers: \"I'm planning several simultaneous two-proportion",
         "comparisons (e.g. several outcome variables) -- how many",
         "subjects per group do I need after a Bonferroni/Sidak alpha",
         "correction?\""
       ),
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "proportion_2s"),

  list(key = "multiplicity_means_1s",
       label = "Multiplicity-adjusted: one mean vs. reference",
       answers = paste(
         "Answers: \"I'm planning several simultaneous comparisons of a",
         "mean against a reference value -- how many subjects do I need",
         "per comparison after a Bonferroni/Sidak alpha correction?\""
       ),
       outcome_type = "means", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "means_1s"),

  list(key = "multiplicity_means_2s",
       label = "Multiplicity-adjusted: two independent means",
       answers = paste(
         "Answers: \"I'm planning several simultaneous two-mean",
         "comparisons (e.g. several outcome variables) -- how many",
         "subjects per group do I need after a Bonferroni/Sidak alpha",
         "correction?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "means_2s"),

  list(key = "multiplicity_fdr_means_2s",
       label = "Multiplicity-adjusted: two independent means, FDR (Benjamini-Hochberg)-controlled",
       answers = paste(
         "Answers: \"I'm planning m simultaneous two-mean comparisons where",
         "only some are expected to show a real effect -- how many subjects",
         "per group do I need to control the FALSE DISCOVERY RATE (rather",
         "than the more conservative family-wise error rate)?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "fdr_means_2s"),

  list(key = "multiplicity_fdr_microarray",
       label = "Multiplicity-adjusted: two-sample microarray/genomics, FDR-controlled (exact)",
       answers = paste(
         "Answers: \"I'm planning a microarray/RNA-seq-style experiment",
         "testing thousands of genes at once, with a known/assumed",
         "proportion truly not differentially expressed -- how many",
         "samples per group do I need for a target FALSE DISCOVERY RATE,",
         "using the exact Liu & Hwang (2007) method?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "fdr_microarray"),

  list(key = "multiplicity_dunnett",
       label = "Multi-arm trial vs. common control (Dunnett-adjusted)",
       answers = paste(
         "Answers: \"I'm planning a trial with several active treatment",
         "arms all compared to the SAME common control -- how many",
         "subjects per arm do I need, using the exact (less conservative",
         "than Bonferroni/Sidak) Dunnett correction for the shared",
         "control?\""
       ),
       outcome_type = "means", groups = "3plus", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Multiplicity Adjustment",
       module_input_id = "multiplicity-design", design_value = "dunnett"),

  list(key = "manova_hotelling",
       label = "Two-group Hotelling's T-squared test (MANOVA, two groups)",
       answers = paste(
         "Answers: \"How many subjects per group do I need to compare two",
         "independent groups on several continuous outcome variables",
         "JOINTLY (e.g. several correlated symptom scores or",
         "biomarkers), rather than testing each one separately?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "MANOVA / Hotelling's T²",
       module_input_id = NA, design_value = NA),

  list(key = "bayesian_assurance_or",
       label = "Bayesian assurance, two-arm proportions trial (log odds ratio)",
       answers = paste(
         "Answers: \"Given a prior distribution (not a single fixed value)",
         "for the true treatment effect, what sample size gives a target",
         "probability (assurance) that the trial's confidence interval",
         "will exclude a minimally-worthwhile effect?\""
       ),
       outcome_type = "proportions", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Bayesian Design Analysis",
       module_input_id = "bayesian-design", design_value = "assurance_or"),

  list(key = "bfda_ttest",
       label = "Bayes Factor Design Analysis, two-sample means",
       answers = paste(
         "Answers: \"What sample size gives me a target PROBABILITY that",
         "the actual Bayes factor will reach a chosen evidence threshold",
         "(e.g. BF10 > 10), rather than a target probability of a",
         "significant p-value?\""
       ),
       outcome_type = "means", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Bayesian Design Analysis",
       module_input_id = "bayesian-design", design_value = "bfda")
)

# Families for the "by study design" finder -- mirrors docs/SDD.md #7's
# calculator catalog table. "Proportions" is the only family with built
# calculators right now; selecting it reveals its catalog entries above.
study_design_families <- list(
  list(id = "proportions", label = "Proportions",
       hint = "Prevalence/frequency studies, or comparing proportions/rates between groups.",
       catalog_keys = c("proportion_single_precision", "proportion_single",
                         "proportion_two_indep", "proportion_posthoc_pairwise",
                         "proportion_two_dep", "proportion_k")),
  list(id = "means", label = "Means",
       hint = "Comparing a continuous measurement within or between groups.",
       catalog_keys = c("means_single_precision", "means_single", "means_two_indep",
                         "means_two_indep_unequal_n", "means_welch", "means_two_dep", "means_k",
                         "means_planned_contrast", "means_posthoc_pairwise")),
  list(id = "case_control", label = "Case-Control",
       hint = "Case-control study (unmatched, matched, nested, case-cohort, or case-crossover), odds ratio or hazard ratio based.",
       catalog_keys = c("case_control_unmatched", "case_control_matched",
                         "case_control_nested", "case_control_case_cohort",
                         "case_crossover")),
  list(id = "cohort", label = "Cohort / Relative Risk",
       hint = "Cohort or cross-sectional study estimating relative risk.",
       catalog_keys = c("cohort_rr")),
  list(id = "sccs", label = "Self-Controlled Case Series",
       hint = "Cases only, comparing each case's own event rate during a risk period to their own rate at other times.",
       catalog_keys = c("sccs_samplesize")),
  list(id = "diagnostic", label = "Diagnostic Accuracy",
       hint = "Estimating sensitivity/specificity given expected prevalence.",
       catalog_keys = c("diagnostic_precision", "diagnostic_vs_reference",
                         "diagnostic_two_indep", "diagnostic_two_paired",
                         "diagnostic_ppv_npv", "diagnostic_likelihood_ratio",
                         "diagnostic_odds_ratio")),
  list(id = "correlation", label = "Correlation",
       hint = "Detecting a Pearson correlation between two continuous variables, comparing correlation strength between two independent or two dependent (overlapping) groups, a point-biserial correlation, a simple regression slope, a partial correlation, or a Spearman rank correlation.",
       catalog_keys = c("correlation_pearson", "correlation_two_independent",
                         "correlation_two_dependent", "correlation_point_biserial",
                         "correlation_regression_slope", "correlation_partial",
                         "correlation_spearman")),
  list(id = "agreement", label = "Agreement / Reliability",
       hint = "Inter-rater/method agreement when there's no gold standard (Cohen's kappa, ICC, Cronbach's alpha, Bland-Altman, Lin's CCC).",
       catalog_keys = c("agreement_kappa", "agreement_icc", "agreement_cronbach",
                         "agreement_bland_altman", "agreement_ccc")),
  list(id = "chi_square", label = "Chi-Square Tests",
       hint = "Categorical distribution/association testing (goodness of fit, R x C tables, paired proportions, stratified/Mantel-Haenszel, dose-response trend, k >= 3 paired binary measurements).",
       catalog_keys = c("chisq_gof", "chisq_independence", "chisq_mcnemar",
                         "chisq_mantelhaenszel", "chisq_cochran_armitage", "cochran_q")),
  list(id = "precision", label = "Precision-based (CI-width)",
       hint = "Estimating with a target confidence-interval width rather than testing a hypothesis (Rothman-Greenland framing) -- a proportion, mean, incidence rate, ratio, or standard deviation.",
       catalog_keys = c("proportion_single_precision", "means_single_precision",
                         "incidence_rate_precision", "ratio_risk_ratio",
                         "ratio_odds_ratio", "ratio_rate_ratio", "variance_sd_precision")),
  list(id = "ratio_estimation", label = "Ratio Estimation",
       hint = "Precision-based estimation of a risk ratio, odds ratio, or rate ratio.",
       catalog_keys = c("ratio_risk_ratio", "ratio_odds_ratio", "ratio_rate_ratio")),
  list(id = "incidence_rate", label = "Incidence Rate",
       hint = "Estimating or comparing incidence rates from person-time data, Poisson regression with a continuous predictor, or comparing two over-dispersed (negative binomial) rates.",
       catalog_keys = c("incidence_rate_precision", "rate_comparison",
                         "poisson_regression_continuous", "negative_binomial_rates")),
  list(id = "exact_tests", label = "Exact Tests",
       hint = "Small-sample exact tests for proportions (binomial, Fisher's exact, Boschloo's unconditional exact, sign test) and rates (exact Poisson).",
       catalog_keys = c("exact_binomial", "exact_fisher", "exact_boschloo",
                         "exact_poisson", "sign_test")),
  list(id = "survival", label = "Survival",
       hint = "Log-rank, Cox regression, stratified log-rank, accrual/follow-up based survival study designs, a weighted log-rank test for non-proportional hazards, a competing-risks joint hazard test, or an RMST comparison.",
       catalog_keys = c("logrank", "cox_binary", "cox_continuous", "survival_stratified",
                         "survival_noncompliance", "weighted_logrank", "competing_risks_joint",
                         "rmst_comparison")),
  list(id = "cluster_sampling", label = "Cluster / Multistage Sampling",
       hint = "Inflating an existing sample size for cluster-sampled surveys, or solving a full cluster survey design (WHO EPI-style) directly.",
       catalog_keys = c("cluster_deff", "cluster_deff_variable", "cluster_survey")),
  list(id = "capture_recapture", label = "Capture-Recapture",
       hint = "Planning a two-sample mark-recapture study's second-sample size for a target precision on an unknown population size.",
       catalog_keys = c("capture_recapture")),
  list(id = "stratified_sampling", label = "Stratified Sampling",
       hint = "Surveys where the population is divided into strata, sampled independently within each.",
       catalog_keys = c("stratified_sampling")),
  list(id = "lqas", label = "Lot Quality Assurance Sampling (LQAS)",
       hint = "Rapid program-monitoring surveys that classify an area as high- or low-performing against two coverage thresholds, rather than estimating a proportion precisely.",
       catalog_keys = c("lqas")),
  list(id = "resource_equation", label = "Resource Equation (Animal Studies)",
       hint = "Small exploratory animal studies with no prior effect-size estimate to power against -- Mead's error-degrees-of-freedom rule of thumb.",
       catalog_keys = c("resource_equation")),
  list(id = "subgroup_interaction", label = "Subgroup / Interaction Testing",
       hint = "Inflating an already-computed main-effect sample size to reliably test whether the effect differs between subgroups (Brookes et al.'s \"4x rule\").",
       catalog_keys = c("subgroup_interaction")),
  list(id = "qualitative", label = "Qualitative / Mixed Methods",
       hint = "Reference guidance (saturation, information power, purposive/theoretical sampling) for planning a qualitative interview study -- not a formula.",
       catalog_keys = c("qualitative_guidance")),
  list(id = "ecological", label = "Ecological Studies",
       hint = "Reference guidance (unit-of-analysis, the ecological fallacy) for planning a group-level (ecological) study -- not a formula.",
       catalog_keys = c("ecological_guidance")),
  list(id = "efa_cfa", label = "Psychometrics / Scale Development",
       hint = "Subjects-per-item rule-of-thumb ratios for planning an exploratory or confirmatory factor analysis / scale validation study.",
       catalog_keys = c("efa_cfa_guidance", "sem_rmsea")),
  list(id = "evpi", label = "Health Economics / Value of Information",
       hint = "Expected Value of Perfect/Sample Information (EVPI/EVSI) and the sample size maximizing the Expected Net Benefit of Sampling (ENBS), for a cost-effectiveness decision already summarized by an incremental net benefit mean/SD.",
       catalog_keys = c("evpi", "evsi_enbs")),
  list(id = "glmm", label = "Monte Carlo Mixed Models",
       hint = "Cluster-randomized trials analyzed with a random-intercept (generalized) linear mixed model, or a longitudinal growth-curve model testing a group difference in slope, sized by direct Monte Carlo simulation since no closed-form formula exists.",
       catalog_keys = c("glmm_lmm_continuous", "glmm_binary", "growth_curve_lmm")),
  list(id = "clinical_trials", label = "Clinical Trials",
       hint = "Pilot/feasibility studies, Phase II designs, crossover, equivalence, non-inferiority, and group-sequential (interim-monitoring) testing.",
       catalog_keys = c("pilot_feasibility", "simon_two_stage", "crossover_2x2",
                         "tost_means", "tost_proportions", "tost_bioequivalence",
                         "tost_assurance",
                         "noninferiority_means", "noninferiority_proportions",
                         "noninferiority_or", "noninferiority_hr",
                         "group_sequential_normal", "group_sequential_binary",
                         "group_sequential_survival", "lan_demets_normal",
                         "stepped_wedge_normal")),
  list(id = "regression", label = "Regression",
       hint = "Testing whether a multiple regression model explains more variance than chance, whether adding predictors increases R-squared, a logistic regression predictor's effect (simple or covariate-adjusted), or two groups on an ordinal outcome (proportional odds).",
       catalog_keys = c("regression_r2", "regression_r2_increase", "logistic_binary",
                         "logistic_continuous", "logistic_ordinal",
                         "logistic_binary_adjusted", "logistic_continuous_adjusted")),
  list(id = "anova_general", label = "Factorial ANOVA / ANCOVA",
       hint = "Main effects, interactions, or covariate-adjusted group effects via the general linear model F-test.",
       catalog_keys = c("anova_general")),
  list(id = "rm_anova", label = "Repeated-Measures / Mixed ANOVA",
       hint = "Between-subjects, within-subjects, or group-by-time interaction effects in a repeated-measures or split-plot design.",
       catalog_keys = c("rm_anova_between", "rm_anova_within", "rm_anova_interaction")),
  list(id = "nonparametric", label = "Nonparametric Tests",
       hint = "Distribution-free alternatives to the t-test, one-way ANOVA, repeated-measures ANOVA, correlation test, and trend test, when normality can't be assumed.",
       catalog_keys = c("wilcoxon_rank_sum", "wilcoxon_signed_rank", "kendall_tau",
                         "kruskal_wallis", "jonckheere_terpstra", "friedman", "ks_two_sample",
                         "wald_wolfowitz_runs", "animal_rank_test")),
  list(id = "safety_surveillance", label = "Safety / Surveillance",
       hint = "Bounding an unseen adverse-event rate, planning to catch a rare event, or proving disease/defect freedom in a finite population with an imperfect test.",
       catalog_keys = c("rule_of_three_bound", "rule_of_three_n_required",
                         "rule_of_three_detect_imperfect")),
  list(id = "prediction", label = "Prediction Model Development",
       hint = "Developing a new multivariable prediction/diagnostic model without excessive overfitting, or externally validating an existing one.",
       catalog_keys = c("prediction_binary", "prediction_continuous", "prediction_survival",
                         "prediction_external_validation")),
  list(id = "roc", label = "ROC / AUC",
       hint = "Diagnostic test discrimination via the area under the ROC curve, single-curve or comparing two correlated curves.",
       catalog_keys = c("roc_single_auc", "roc_compare_two_aucs")),
  list(id = "variance", label = "Variance Tests",
       hint = "Testing whether a population's variability differs from a reference value, whether two groups' variability differs, or planning a precision-based (no-test) estimate of an SD.",
       catalog_keys = c("variance_single", "variance_two", "variance_sd_precision")),
  list(id = "multiplicity", label = "Multiplicity Adjustment",
       hint = "Sample size for a one- or two-sample proportion or mean comparison after a Bonferroni/Sidak correction, a false-discovery-rate (FDR)-controlled two-mean comparison, or a Dunnett-adjusted multi-arm-vs-control trial, for several planned simultaneous comparisons.",
       catalog_keys = c("multiplicity_proportion_1s", "multiplicity_proportion_2s",
                         "multiplicity_means_1s", "multiplicity_means_2s",
                         "multiplicity_fdr_means_2s", "multiplicity_fdr_microarray", "multiplicity_dunnett")),
  list(id = "manova", label = "MANOVA / Hotelling's T-Squared",
       hint = "Comparing two independent groups on several continuous outcome variables jointly, rather than testing each one separately.",
       catalog_keys = c("manova_hotelling")),
  list(id = "bayesian", label = "Bayesian Design Analysis",
       hint = "Sample size for a target prior-averaged power (assurance) when the true treatment effect is itself uncertain, rather than fixed at one assumed value, or a target probability that the actual Bayes factor reaches a chosen evidence threshold.",
       catalog_keys = c("bayesian_assurance_or", "bfda_ttest")),
  list(id = "longitudinal", label = "Longitudinal / MMRM",
       hint = "Comparing two groups' rate of change (slope) over repeated visits, under a random-intercept/random-slope covariance structure (GEE/GLS framework), or a mixed model of repeated measures (MMRM) with dropout and AR(1) correlation.",
       catalog_keys = c("longitudinal_slope_diff", "mmrm_ar1")),
  list(id = "multilevel_models", label = "Multilevel / Hierarchical Models",
       hint = "Two- and three-level hierarchical (mixed) models for a longitudinal trial, decomposing slope variance into subject- and (for 3-level) cluster-level components.",
       catalog_keys = c("multilevel_two_level", "multilevel_three_level")),
  list(id = "meta_analysis_power", label = "Meta-Analysis Power",
       hint = "Required number of studies (or achieved power) for a planned meta-analysis, under fixed-effect or heterogeneity-adjusted random-effects models, for Cohen's d, a correlation, or an odds ratio.",
       catalog_keys = c("meta_power_k"))
)

# Second index over the SAME calculator_catalog entries, grouped by
# statistical-test family instead of study design -- mirrors "Part 2 -- By
# Statistical Test" of the project's scope-review checklist (the source
# document docs/checklist_by_design.md and checklist_by_test.md were built
# from), the same way G*Power organizes its own test catalog. This is purely
# a second browsing lens for the Home hub's "Browse calculators" toggle: it
# points at the same built catalog_keys as study_design_families above, never
# duplicates a calculator. Only families with at least one already-built key
# are included; a calculator with no natural single-test-family home (e.g.
# most observational-study designs) simply doesn't appear here, only under
# study_design_families.
test_families <- list(
  list(id = "t_tests", label = "t Tests",
       hint = "Comparing one or two means (incl. Welch's unequal-variance test), a Bonferroni-adjusted post-hoc pairwise comparison, or a point-biserial correlation (Student's t framework).",
       catalog_keys = c("means_single", "means_two_indep",
                         "means_two_indep_unequal_n", "means_welch", "means_two_dep",
                         "means_posthoc_pairwise", "correlation_point_biserial")),
  list(id = "z_tests", label = "z Tests",
       hint = "Comparing proportions (incl. a Bonferroni-adjusted post-hoc pairwise comparison), a logistic-regression predictor's effect (simple or covariate-adjusted), or two groups on an ordinal outcome via proportional-odds regression (all normal-approximation frameworks).",
       catalog_keys = c("proportion_single", "proportion_two_indep",
                         "proportion_posthoc_pairwise", "logistic_binary",
                         "logistic_continuous", "logistic_ordinal",
                         "logistic_binary_adjusted", "logistic_continuous_adjusted")),
  list(id = "f_tests", label = "F Tests",
       hint = "One-way/factorial ANOVA, ANCOVA, multiple regression (incl. hierarchical R-squared increase), repeated-measures/mixed ANOVA, and planned linear contrasts (general linear model F-test framework).",
       catalog_keys = c("means_k", "regression_r2", "regression_r2_increase", "anova_general",
                         "rm_anova_between", "rm_anova_within", "rm_anova_interaction",
                         "means_planned_contrast")),
  list(id = "chi_square_tests", label = "Chi-Square Tests",
       hint = "Goodness of fit, tests of independence/association, paired-proportions (McNemar's, or Cochran's Q for k >= 3), stratified/Mantel-Haenszel, and dose-response trend testing for categorical data.",
       catalog_keys = c("chisq_gof", "chisq_independence", "chisq_mcnemar",
                         "chisq_mantelhaenszel", "chisq_cochran_armitage", "cochran_q")),
  list(id = "exact_tests", label = "Exact Tests",
       hint = "Small-sample exact tests for proportions (binomial, Fisher's exact, Boschloo's unconditional exact, sign test) and rates (exact Poisson) where the normal approximation is unreliable.",
       catalog_keys = c("exact_binomial", "exact_fisher", "exact_boschloo",
                         "exact_poisson", "sign_test")),
  list(id = "correlation_regression", label = "Correlation & Regression",
       hint = "Pearson correlation (single or comparing two independent or two dependent/overlapping groups), a simple regression slope, a partial correlation, a Spearman rank correlation, and multiple linear regression (incl. hierarchical R-squared increase).",
       catalog_keys = c("correlation_pearson", "correlation_two_independent",
                         "correlation_two_dependent", "correlation_regression_slope",
                         "correlation_partial", "correlation_spearman",
                         "regression_r2", "regression_r2_increase")),
  list(id = "survival_tests", label = "Survival Tests",
       hint = "Log-rank test, Cox proportional-hazards regression, stratified log-rank, accrual/follow-up/noncompliance-adjusted log-rank, a weighted log-rank test for non-proportional hazards, a competing-risks joint hazard test, and an RMST comparison for time-to-event outcomes.",
       catalog_keys = c("logrank", "cox_binary", "cox_continuous", "survival_stratified",
                         "survival_noncompliance", "weighted_logrank", "competing_risks_joint",
                         "rmst_comparison")),
  list(id = "agreement_statistics", label = "Agreement Statistics",
       hint = "Cohen's kappa, ICC, Cronbach's alpha, Bland-Altman limits of agreement, and Lin's CCC.",
       catalog_keys = c("agreement_kappa", "agreement_icc", "agreement_cronbach",
                         "agreement_bland_altman", "agreement_ccc")),
  list(id = "equivalence_noninferiority", label = "Equivalence / Non-Inferiority Test Forms",
       hint = "Two one-sided tests (TOST) for equivalence (incl. expected-power/assurance bioequivalence), non-inferiority margins, and crossover designs.",
       catalog_keys = c("tost_means", "tost_proportions", "tost_bioequivalence",
                         "tost_assurance",
                         "noninferiority_means", "noninferiority_proportions",
                         "noninferiority_or", "noninferiority_hr", "crossover_2x2")),
  list(id = "nonparametric_tests", label = "Nonparametric Tests",
       hint = "Distribution-free rank-based tests: Wilcoxon rank-sum, Wilcoxon signed-rank, Kendall's tau, Kruskal-Wallis, Jonckheere-Terpstra, Friedman, Kolmogorov-Smirnov, Wald-Wolfowitz runs, and an animal/preclinical K-sample rank test (the last three via Monte Carlo).",
       catalog_keys = c("wilcoxon_rank_sum", "wilcoxon_signed_rank", "kendall_tau",
                         "kruskal_wallis", "jonckheere_terpstra", "friedman", "ks_two_sample",
                         "wald_wolfowitz_runs", "animal_rank_test")),
  list(id = "group_sequential_designs", label = "Group Sequential Designs",
       hint = "Interim-monitoring trial designs with Pocock-to-O'Brien-Fleming efficacy/futility boundaries, for continuous, binary, or time-to-event outcomes; or the literal Lan-DeMets alpha-spending-function method for a continuous outcome (2 looks).",
       catalog_keys = c("group_sequential_normal", "group_sequential_binary",
                         "group_sequential_survival", "lan_demets_normal")),
  list(id = "trial_sequential_analysis", label = "Trial Sequential Analysis (Meta-Analysis)",
       hint = "Fixed-effect required/optimal information size (RIS/OIS) for a planned or cumulatively-updated meta-analysis, across risk ratio, odds ratio, risk difference, and mean difference outcomes.",
       catalog_keys = c("tsa_rr", "tsa_or", "tsa_rd", "tsa_md")),
  list(id = "variance_tests", label = "Variance Tests",
       hint = "Chi-squared test for a single variance against a reference value, F test for comparing two variances, and precision-based (CI-width) SD estimation.",
       catalog_keys = c("variance_single", "variance_two", "variance_sd_precision")),
  list(id = "multiplicity_adjustment", label = "Multiplicity Adjustment",
       hint = "Bonferroni or Sidak alpha correction applied to a one- or two-sample proportion or mean test, false-discovery-rate (FDR) control for a two-mean comparison, or a Dunnett-adjusted multi-arm-vs-control trial, for several planned simultaneous comparisons.",
       catalog_keys = c("multiplicity_proportion_1s", "multiplicity_proportion_2s",
                         "multiplicity_means_1s", "multiplicity_means_2s",
                         "multiplicity_fdr_means_2s", "multiplicity_fdr_microarray", "multiplicity_dunnett")),
  list(id = "manova_tests", label = "MANOVA / Hotelling's T-Squared",
       hint = "Two-group Hotelling's T-squared test, comparing two independent groups on several continuous outcome variables jointly.",
       catalog_keys = c("manova_hotelling")),
  list(id = "bayesian_tests", label = "Bayesian Design Analysis",
       hint = "Prior-averaged power (assurance) for a two-arm proportions trial when the true log odds ratio is itself uncertain, or Bayes Factor Design Analysis for a two-sample means comparison.",
       catalog_keys = c("bayesian_assurance_or", "bfda_ttest")),
  list(id = "longitudinal_tests", label = "Longitudinal / GEE Tests",
       hint = "Comparing two groups' rate of change (slope) over repeated visits, under a random-intercept/random-slope covariance structure (the GLS/GEE framework of Liu & Liang 1997), or a mixed model of repeated measures (MMRM) with dropout and AR(1) correlation (Lu, Luo & Chen 2008).",
       catalog_keys = c("longitudinal_slope_diff", "mmrm_ar1")),
  list(id = "multilevel_model_tests", label = "Multilevel / Hierarchical Model Tests",
       hint = "Testing a treatment-group slope difference under a 2- or 3-level hierarchical mixed model (extends Galbraith & Marschner 2002).",
       catalog_keys = c("multilevel_two_level", "multilevel_three_level"))
)

catalog_entry <- function(key) {
  Find(function(e) identical(e$key, key), calculator_catalog)
}
