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
       outcome_type = "proportion", groups = "3plus", dependency = NA, reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "means_single", label = "Single mean vs. known value",
       answers = "Answers: \"How many subjects do I need to detect that my population's mean differs from a known/reference value?\"",
       outcome_type = "mean", groups = "1", dependency = NA, reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "single"),

  list(key = "means_two_indep", label = "Two independent means",
       answers = "Answers: \"How many subjects per group do I need to detect a difference between two independent groups' means?\"",
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "two_sample"),

  list(key = "means_two_dep", label = "Two paired means (e.g. pre-post)",
       answers = "Answers: \"How many subjects do I need to detect a change in mean within the same subjects (pre-post)?\"",
       outcome_type = "mean", groups = "2", dependency = "dependent", reference_based = NA,
       built = TRUE, nav_target = "Means",
       module_input_id = "means-design", design_value = "paired"),

  list(key = "means_k", label = "Three or more group means",
       answers = "Answers: \"How many subjects per group do I need to detect any difference across 3+ group means?\"",
       outcome_type = "mean", groups = "3plus", dependency = NA, reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

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
       module_input_id = "agreement-design", design_value = "icc")
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
       catalog_keys = c("means_single", "means_two_indep", "means_two_dep", "means_k")),
  list(id = "case_control", label = "Case-Control",
       hint = "Unmatched case-control study, odds ratio based.",
       catalog_keys = character(0)),
  list(id = "cohort", label = "Cohort / Relative Risk",
       hint = "Cohort or cross-sectional study estimating relative risk.",
       catalog_keys = character(0)),
  list(id = "diagnostic", label = "Diagnostic Accuracy",
       hint = "Estimating sensitivity/specificity given expected prevalence.",
       catalog_keys = c("diagnostic_precision", "diagnostic_vs_reference",
                         "diagnostic_two_indep", "diagnostic_two_paired")),
  list(id = "correlation", label = "Correlation",
       hint = "Detecting a Pearson correlation between two continuous variables.",
       catalog_keys = character(0)),
  list(id = "agreement", label = "Agreement / Reliability",
       hint = "Inter-rater/method agreement when there's no gold standard (Cohen's kappa, ICC).",
       catalog_keys = c("agreement_kappa", "agreement_icc")),
  list(id = "precision", label = "Precision-based (CI-width)",
       hint = "Estimating with a target confidence-interval width rather than testing a hypothesis.",
       catalog_keys = character(0)),
  list(id = "survival", label = "Survival",
       hint = "Log-rank or accrual/follow-up based survival study designs.",
       catalog_keys = character(0)),
  list(id = "posthoc_power", label = "Post-hoc / Achieved Power",
       hint = "Achieved power for planning a replication study.",
       catalog_keys = character(0))
)

catalog_entry <- function(key) {
  Find(function(e) identical(e$key, key), calculator_catalog)
}
