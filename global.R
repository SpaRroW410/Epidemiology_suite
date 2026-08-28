# Libraries + sourcing for all R/ files. app.R sources this before building the UI.

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(shiny, bslib, pwr, presize, epiR, clinfun, powerSurvEpi, PowerTOST, Exact,
               pmsampsize, pROC, TrialSize, powerMediation)

for (f in list.files("R/calc", pattern = "\\.R$", full.names = TRUE)) source(f)
for (f in list.files("R/content", pattern = "\\.R$", full.names = TRUE)) source(f)
for (f in list.files("R/home", pattern = "\\.R$", full.names = TRUE)) source(f)
for (f in list.files("R/modules", pattern = "\\.R$", full.names = TRUE)) source(f)

# Module registry: adding a calculator means appending one entry here, not
# editing the navbar-building code in app.R (SDD #8).
module_registry <- list(
  list(id = proportion_meta$id, title = proportion_meta$nav_title,
       ui = mod_proportion_ui, server = mod_proportion_server),
  list(id = means_meta$id, title = means_meta$nav_title,
       ui = mod_means_ui, server = mod_means_server),
  list(id = diagnostic_meta$id, title = diagnostic_meta$nav_title,
       ui = mod_diagnostic_ui, server = mod_diagnostic_server),
  list(id = agreement_meta$id, title = agreement_meta$nav_title,
       ui = mod_agreement_ui, server = mod_agreement_server),
  list(id = case_control_meta$id, title = case_control_meta$nav_title,
       ui = mod_case_control_ui, server = mod_case_control_server),
  list(id = cohort_meta$id, title = cohort_meta$nav_title,
       ui = mod_cohort_ui, server = mod_cohort_server),
  list(id = correlation_meta$id, title = correlation_meta$nav_title,
       ui = mod_correlation_ui, server = mod_correlation_server),
  list(id = chisq_meta$id, title = chisq_meta$nav_title,
       ui = mod_chisq_ui, server = mod_chisq_server),
  list(id = pilot_meta$id, title = pilot_meta$nav_title,
       ui = mod_pilot_ui, server = mod_pilot_server),
  list(id = simon_meta$id, title = simon_meta$nav_title,
       ui = mod_simon_ui, server = mod_simon_server),
  list(id = tost_meta$id, title = tost_meta$nav_title,
       ui = mod_tost_ui, server = mod_tost_server),
  list(id = logrank_meta$id, title = logrank_meta$nav_title,
       ui = mod_logrank_ui, server = mod_logrank_server),
  list(id = rate_meta$id, title = rate_meta$nav_title,
       ui = mod_rate_ui, server = mod_rate_server),
  list(id = regression_meta$id, title = regression_meta$nav_title,
       ui = mod_regression_ui, server = mod_regression_server),
  list(id = noninferiority_meta$id, title = noninferiority_meta$nav_title,
       ui = mod_noninferiority_ui, server = mod_noninferiority_server),
  list(id = rule_of_three_meta$id, title = rule_of_three_meta$nav_title,
       ui = mod_rule_of_three_ui, server = mod_rule_of_three_server),
  list(id = exact_tests_meta$id, title = exact_tests_meta$nav_title,
       ui = mod_exact_tests_ui, server = mod_exact_tests_server),
  list(id = prediction_meta$id, title = prediction_meta$nav_title,
       ui = mod_prediction_ui, server = mod_prediction_server),
  list(id = roc_meta$id, title = roc_meta$nav_title,
       ui = mod_roc_ui, server = mod_roc_server),
  list(id = cluster_meta$id, title = cluster_meta$nav_title,
       ui = mod_cluster_ui, server = mod_cluster_server),
  list(id = stratified_meta$id, title = stratified_meta$nav_title,
       ui = mod_stratified_ui, server = mod_stratified_server),
  list(id = crossover_meta$id, title = crossover_meta$nav_title,
       ui = mod_crossover_ui, server = mod_crossover_server),
  list(id = anova_general_meta$id, title = anova_general_meta$nav_title,
       ui = mod_anova_general_ui, server = mod_anova_general_server),
  list(id = logistic_meta$id, title = logistic_meta$nav_title,
       ui = mod_logistic_ui, server = mod_logistic_server),
  list(id = sccs_meta$id, title = sccs_meta$nav_title,
       ui = mod_sccs_ui, server = mod_sccs_server),
  list(id = rm_anova_meta$id, title = rm_anova_meta$nav_title,
       ui = mod_rm_anova_ui, server = mod_rm_anova_server),
  list(id = nonparametric_meta$id, title = nonparametric_meta$nav_title,
       ui = mod_nonparametric_ui, server = mod_nonparametric_server),
  list(id = ratio_meta$id, title = ratio_meta$nav_title,
       ui = mod_ratio_ui, server = mod_ratio_server)
)

# Top-navbar grouping: which module ids collapse under which dropdown menu, in
# which order. Mirrors docs/checklist_by_design.md's own Part-1 study-design
# section numbers (already simple -> difficult) so the navbar doesn't invent a
# second taxonomy on top of the checklist's. Modules with no single natural
# study-design home (general G*Power-style test families) are grouped together
# in the last entry; they remain individually discoverable by test family via
# the Home hub's "Browse calculators" toggle (R/home/home_catalog.R's
# test_families), which points at these same module ids.
module_groups <- list(
  list(title = "Descriptive & Estimation",
       module_ids = c("proportion", "means", "rate", "ratio")),
  list(title = "Survey & Cross-Sectional",
       module_ids = c("stratified", "cluster")),
  list(title = "Observational Studies",
       module_ids = c("case_control", "cohort", "sccs")),
  list(title = "Diagnostic & Screening",
       module_ids = c("diagnostic", "roc")),
  list(title = "Agreement & Reliability",
       module_ids = c("agreement")),
  list(title = "Clinical Trials",
       module_ids = c("pilot", "simon", "tost", "noninferiority", "crossover")),
  list(title = "Survival Analysis",
       module_ids = c("logrank")),
  list(title = "Prediction Models",
       module_ids = c("prediction")),
  list(title = "Surveillance",
       module_ids = c("rule_of_three")),
  list(title = "General Statistical Tests",
       module_ids = c("correlation", "chisq", "regression", "anova_general",
                       "logistic", "exact_tests", "rm_anova", "nonparametric"))
)
