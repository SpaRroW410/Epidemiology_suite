# Libraries + sourcing for all R/ files. app.R sources this before building the UI.

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(shiny, bslib, pwr, presize, epiR, clinfun, powerSurvEpi, PowerTOST)

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
       ui = mod_rule_of_three_ui, server = mod_rule_of_three_server)
)
