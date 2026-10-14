# Module registry: adding a calculator means appending one entry to
# module_registry() below (and the module's id to the right module_groups entry),
# not editing the navbar-building code in run_app() (SDD #8).
#
# module_registry() is a function, not a top-level object, so it is evaluated
# after the whole package namespace has loaded: it refers to every mod_*_meta
# object and mod_*_ui/server function, and package files load alphabetically.

module_registry <- function() {
  list(
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
         ui = mod_ratio_ui, server = mod_ratio_server),
    list(id = group_sequential_meta$id, title = group_sequential_meta$nav_title,
         ui = mod_group_sequential_ui, server = mod_group_sequential_server),
    list(id = variance_meta$id, title = variance_meta$nav_title,
         ui = mod_variance_ui, server = mod_variance_server),
    list(id = multiplicity_meta$id, title = multiplicity_meta$nav_title,
         ui = mod_multiplicity_ui, server = mod_multiplicity_server),
    list(id = manova_meta$id, title = manova_meta$nav_title,
         ui = mod_manova_ui, server = mod_manova_server),
    list(id = bayesian_meta$id, title = bayesian_meta$nav_title,
         ui = mod_bayesian_ui, server = mod_bayesian_server),
    list(id = competing_risks_meta$id, title = competing_risks_meta$nav_title,
         ui = mod_competing_risks_ui, server = mod_competing_risks_server),
    list(id = rmst_meta$id, title = rmst_meta$nav_title,
         ui = mod_rmst_ui, server = mod_rmst_server),
    list(id = longitudinal_meta$id, title = longitudinal_meta$nav_title,
         ui = mod_longitudinal_ui, server = mod_longitudinal_server),
    list(id = lqas_meta$id, title = lqas_meta$nav_title,
         ui = mod_lqas_ui, server = mod_lqas_server),
    list(id = resource_equation_meta$id, title = resource_equation_meta$nav_title,
         ui = mod_resource_equation_ui, server = mod_resource_equation_server),
    list(id = subgroup_interaction_meta$id, title = subgroup_interaction_meta$nav_title,
         ui = mod_subgroup_interaction_ui, server = mod_subgroup_interaction_server),
    list(id = qualitative_meta$id, title = qualitative_meta$nav_title,
         ui = mod_qualitative_ui, server = mod_qualitative_server),
    list(id = glmm_meta$id, title = glmm_meta$nav_title,
         ui = mod_glmm_ui, server = mod_glmm_server),
    list(id = capture_recapture_meta$id, title = capture_recapture_meta$nav_title,
         ui = mod_capture_recapture_ui, server = mod_capture_recapture_server),
    list(id = ecological_meta$id, title = ecological_meta$nav_title,
         ui = mod_ecological_ui, server = mod_ecological_server),
    list(id = efa_cfa_meta$id, title = efa_cfa_meta$nav_title,
         ui = mod_efa_cfa_ui, server = mod_efa_cfa_server),
    list(id = tsa_meta$id, title = tsa_meta$nav_title,
         ui = mod_tsa_ui, server = mod_tsa_server),
    list(id = multilevel_meta$id, title = multilevel_meta$nav_title,
         ui = mod_multilevel_ui, server = mod_multilevel_server),
    list(id = evpi_meta$id, title = evpi_meta$nav_title,
         ui = mod_evpi_ui, server = mod_evpi_server),
    list(id = stepped_wedge_meta$id, title = stepped_wedge_meta$nav_title,
         ui = mod_stepped_wedge_ui, server = mod_stepped_wedge_server),
    list(id = meta_power_meta$id, title = meta_power_meta$nav_title,
         ui = mod_meta_power_ui, server = mod_meta_power_server),
    list(id = analyze_2x2_meta$id, title = analyze_2x2_meta$nav_title,
         ui = mod_analyze_2x2_ui, server = mod_analyze_2x2_server),
    list(id = analyze_dx_meta$id, title = analyze_dx_meta$nav_title,
         ui = mod_analyze_dx_ui, server = mod_analyze_dx_server)
  )
}

# Navigation: the app is organised into WORKBENCHES (the top navbar: Home, Plan,
# Analyze, ...), each holding a vertical, grouped list of modules. bslib dropdowns
# cannot nest and 15 dropdowns no longer fit one navbar, so the old
# "one dropdown per group" layout became "one workbench per stage of a study, one
# header per group inside it". A workbench has:
#   id / title   the top-navbar value (input$main_nav) and label
#   nav_id       the id of its module list (input$<nav_id> = the open module's title)
#   groups       header + module ids, in display order
# Adding a calculator = add its entry to module_registry() above and its id to a
# group below; adding a workbench = add an entry here (run_app.R builds the rest).
#
# The sample-size groups mirror docs/checklist_by_design.md's own Part-1
# study-design section numbers (already simple -> difficult) so the navigation does
# not invent a second taxonomy on top of the checklist's. Modules with no single
# natural study-design home (general G*Power-style test families) are grouped
# together in the last group; they remain individually discoverable by test family
# via the Home hub's "Browse calculators" toggle (R/home_catalog.R's test_families),
# which points at these same module ids.
module_workbenches <- list(
  list(id = "plan", title = "Plan: Sample Size", nav_id = "plan_nav",
       groups = list(
      list(title = "Descriptive & Estimation",
           module_ids = c("proportion", "means", "rate", "ratio")),
      list(title = "Survey & Cross-Sectional",
           module_ids = c("stratified", "cluster", "lqas", "capture_recapture")),
      list(title = "Observational Studies",
           module_ids = c("case_control", "cohort", "sccs", "ecological")),
      list(title = "Diagnostic & Screening",
           module_ids = c("diagnostic", "roc")),
      list(title = "Agreement & Reliability",
           module_ids = c("agreement")),
      list(title = "Clinical Trials",
           module_ids = c("pilot", "simon", "tost", "noninferiority", "crossover", "group_sequential", "subgroup_interaction", "glmm", "tsa", "stepped_wedge")),
      list(title = "Survival Analysis",
           module_ids = c("logrank", "competing_risks", "rmst")),
      list(title = "Prediction Models",
           module_ids = c("prediction")),
      list(title = "Surveillance",
           module_ids = c("rule_of_three")),
      list(title = "Preclinical / Animal Studies",
           module_ids = c("resource_equation")),
      list(title = "Qualitative / Mixed Methods",
           module_ids = c("qualitative")),
      list(title = "Psychometrics / Scale Development",
           module_ids = c("efa_cfa")),
      list(title = "Health Economics / Value of Information",
           module_ids = c("evpi")),
      list(title = "General Statistical Tests",
           module_ids = c("correlation", "chisq", "regression", "anova_general", "logistic", "exact_tests", "rm_anova", "nonparametric", "variance", "multiplicity", "manova", "bayesian", "longitudinal", "multilevel", "meta_power"))
       )),
  list(id = "analyze", title = "Analyze", nav_id = "analyze_nav",
       groups = list(
         list(title = "From summary counts",
              module_ids = c("analyze_2x2", "analyze_dx"))
       ))
)

# Where a module lives: its workbench (list) or NULL if the title is unknown.
module_workbench_of <- function(module_title) {
  registry <- module_registry()
  ids <- vapply(registry, `[[`, character(1), "id")
  titles <- vapply(registry, `[[`, character(1), "title")
  id <- ids[match(module_title, titles)]
  if (is.na(id)) return(NULL)
  for (wb in module_workbenches) {
    for (g in wb$groups) if (id %in% g$module_ids) return(wb)
  }
  NULL
}

# Open a module from anywhere (Home hub buttons, the wizard): select its
# workbench in the top navbar, then the module inside it.
jump_to_module <- function(session, module_title) {
  wb <- module_workbench_of(module_title)
  if (is.null(wb)) stop("No workbench contains a module titled '", module_title, "'.")
  nav_select("main_nav", wb$title, session = session)
  nav_select(wb$nav_id, module_title, session = session)
  invisible(wb)
}
