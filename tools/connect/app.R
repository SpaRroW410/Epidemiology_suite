# Entry point of the bundle deployed to Posit Connect Cloud (ROADMAP: three ways to use the app). Connect runs it as an
# ordinary Shiny server, so a phone only receives a web page. The bundle holds this file and the package's R/ directory, which is
# sourced exactly as the browser build does (tools/pages/make_app.R), so all three versions are the same code.
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
})
files <- normalizePath(sort(list.files("R", pattern = "[.]R$", full.names = TRUE)))
# the background workers that run the Monte Carlo calculators (R/background.R) load the same files
options(epidemiologysuite.source_files = files)
for (f in files) source(f, local = FALSE)
# for the manifest's package scan: the workers need mirai, which R/background.R looks up by name (never executed)
if (FALSE) mirai::daemons
epidemiologysuite_app()
