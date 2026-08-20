# Data for the Home page's two calculator finders (by study design, and by
# groups/data type). Content is data, same principle as R/content/*.R --
# adding a calculator means adding/flipping a catalog entry here, not
# rewriting the finder UI/server logic in home_finder.R.
#
# Each entry:
#   key          - unique id
#   label        - shown to the user
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
       outcome_type = "proportion", groups = "1", dependency = NA, reference_based = FALSE,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "precision"),

  list(key = "proportion_single", label = "Single proportion vs. known/reference value",
       outcome_type = "proportion", groups = "1", dependency = NA, reference_based = TRUE,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "single"),

  list(key = "proportion_two_indep", label = "Two independent proportions",
       outcome_type = "proportion", groups = "2", dependency = "independent", reference_based = NA,
       built = TRUE, nav_target = "Proportions",
       module_input_id = "proportion-design", design_value = "two_sample"),

  list(key = "proportion_two_dep", label = "Two paired/dependent proportions (e.g. before-after, matched pairs)",
       outcome_type = "proportion", groups = "2", dependency = "dependent", reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "proportion_k", label = "Three or more group proportions",
       outcome_type = "proportion", groups = "3plus", dependency = NA, reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "means_single", label = "Single mean vs. known value",
       outcome_type = "mean", groups = "1", dependency = NA, reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "means_two_indep", label = "Two independent means",
       outcome_type = "mean", groups = "2", dependency = "independent", reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "means_two_dep", label = "Two paired means (e.g. pre-post)",
       outcome_type = "mean", groups = "2", dependency = "dependent", reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA),

  list(key = "means_k", label = "Three or more group means",
       outcome_type = "mean", groups = "3plus", dependency = NA, reference_based = NA,
       built = FALSE, nav_target = NA, module_input_id = NA, design_value = NA)
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
       catalog_keys = character(0)),
  list(id = "correlation", label = "Correlation",
       hint = "Detecting a Pearson correlation between two continuous variables.",
       catalog_keys = character(0)),
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
