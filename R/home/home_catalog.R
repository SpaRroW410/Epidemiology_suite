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

  list(key = "correlation_pearson",
       label = "Pearson correlation",
       answers = paste(
         "Answers: \"How many subjects do I need to detect a correlation",
         "of a given size between two continuous variables?\""
       ),
       outcome_type = "correlation", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Correlation",
       module_input_id = NA, design_value = NA),

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

  list(key = "cluster_deff",
       label = "Cluster / multistage sampling -- design effect (DEFF)",
       answers = paste(
         "Answers: \"I already have a simple-random-sample size -- how much",
         "bigger does it need to be if I'm sampling in clusters (villages,",
         "schools, facilities) rather than individuals?\""
       ),
       outcome_type = "cluster", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Cluster / Design Effect",
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

  list(key = "roc_single_auc",
       label = "Single ROC AUC vs. chance (0.5)",
       answers = paste(
         "Answers: \"How many cases and controls do I need to show my",
         "test's AUC is significantly better than chance?\""
       ),
       outcome_type = "roc", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "ROC / AUC",
       module_input_id = NA, design_value = NA),

  list(key = "regression_r2",
       label = "Multiple linear regression, R-squared deviation from zero",
       answers = paste(
         "Answers: \"How many subjects do I need to detect that my",
         "regression model's overall R-squared is significantly greater",
         "than zero, given a fixed number of predictors?\""
       ),
       outcome_type = "regression", groups = NA, dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Multiple Regression",
       module_input_id = NA, design_value = NA),

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
       module_input_id = "rule_of_three-design", design_value = "n_required")
)

# Families for the "by study design" finder -- mirrors docs/SDD.md #7's
# calculator catalog table. "Proportions" is the only family with built
# calculators right now; selecting it reveals its catalog entries above.
study_design_families <- list(
  list(id = "proportions", label = "Proportions",
       hint = "Prevalence/frequency studies, or comparing proportions/rates between groups.",
       catalog_keys = c("proportion_single_precision", "proportion_single",
                         "proportion_two_indep", "proportion_two_dep", "proportion_k")),
  list(id = "means", label = "Means",
       hint = "Comparing a continuous measurement within or between groups.",
       catalog_keys = c("means_single_precision", "means_single", "means_two_indep",
                         "means_two_indep_unequal_n", "means_two_dep", "means_k")),
  list(id = "case_control", label = "Case-Control",
       hint = "Case-control study (unmatched or matched), odds ratio based.",
       catalog_keys = c("case_control_unmatched", "case_control_matched")),
  list(id = "cohort", label = "Cohort / Relative Risk",
       hint = "Cohort or cross-sectional study estimating relative risk.",
       catalog_keys = c("cohort_rr")),
  list(id = "diagnostic", label = "Diagnostic Accuracy",
       hint = "Estimating sensitivity/specificity given expected prevalence.",
       catalog_keys = c("diagnostic_precision", "diagnostic_vs_reference",
                         "diagnostic_two_indep", "diagnostic_two_paired",
                         "diagnostic_ppv_npv", "diagnostic_likelihood_ratio")),
  list(id = "correlation", label = "Correlation",
       hint = "Detecting a Pearson correlation between two continuous variables.",
       catalog_keys = c("correlation_pearson")),
  list(id = "agreement", label = "Agreement / Reliability",
       hint = "Inter-rater/method agreement when there's no gold standard (Cohen's kappa, ICC, Cronbach's alpha, Bland-Altman).",
       catalog_keys = c("agreement_kappa", "agreement_icc", "agreement_cronbach",
                         "agreement_bland_altman")),
  list(id = "chi_square", label = "Chi-Square Tests",
       hint = "Categorical distribution/association testing (goodness of fit, R x C tables).",
       catalog_keys = c("chisq_gof", "chisq_independence")),
  list(id = "precision", label = "Precision-based (CI-width)",
       hint = "Estimating with a target confidence-interval width rather than testing a hypothesis.",
       catalog_keys = c("proportion_single_precision", "means_single_precision",
                         "incidence_rate_precision")),
  list(id = "incidence_rate", label = "Incidence Rate",
       hint = "Estimating or comparing incidence rates from person-time data.",
       catalog_keys = c("incidence_rate_precision", "rate_comparison")),
  list(id = "exact_tests", label = "Exact Tests",
       hint = "Small-sample exact tests for proportions (binomial, Fisher's exact).",
       catalog_keys = c("exact_binomial", "exact_fisher")),
  list(id = "survival", label = "Survival",
       hint = "Log-rank, Cox regression, or accrual/follow-up based survival study designs.",
       catalog_keys = c("logrank", "cox_binary", "cox_continuous")),
  list(id = "cluster_sampling", label = "Cluster / Multistage Sampling",
       hint = "Inflating an existing sample size for cluster-sampled (rather than individually-sampled) surveys.",
       catalog_keys = c("cluster_deff")),
  list(id = "stratified_sampling", label = "Stratified Sampling",
       hint = "Surveys where the population is divided into strata, sampled independently within each.",
       catalog_keys = c("stratified_sampling")),
  list(id = "clinical_trials", label = "Clinical Trials",
       hint = "Pilot/feasibility studies, Phase II designs, crossover, equivalence, and non-inferiority testing.",
       catalog_keys = c("pilot_feasibility", "simon_two_stage", "crossover_2x2",
                         "tost_means", "tost_proportions", "noninferiority_means",
                         "noninferiority_proportions")),
  list(id = "regression", label = "Regression",
       hint = "Testing whether a multiple regression model explains more variance than chance.",
       catalog_keys = c("regression_r2")),
  list(id = "safety_surveillance", label = "Safety / Surveillance",
       hint = "Bounding an unseen adverse-event rate, or planning to catch a rare event.",
       catalog_keys = c("rule_of_three_bound", "rule_of_three_n_required")),
  list(id = "prediction", label = "Prediction Model Development",
       hint = "Developing a new multivariable prediction/diagnostic model without excessive overfitting.",
       catalog_keys = c("prediction_binary", "prediction_continuous", "prediction_survival")),
  list(id = "roc", label = "ROC / AUC",
       hint = "Diagnostic test discrimination via the area under the ROC curve.",
       catalog_keys = c("roc_single_auc")),
  list(id = "posthoc_power", label = "Post-hoc / Achieved Power",
       hint = "Achieved power for planning a replication study.",
       catalog_keys = character(0))
)

catalog_entry <- function(key) {
  Find(function(e) identical(e$key, key), calculator_catalog)
}
