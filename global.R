# Libraries + sourcing for all R/ files. app.R sources this before building the UI.

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(shiny, bslib, pwr, presize, epiR)

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
       ui = mod_cohort_ui, server = mod_cohort_server)
)
