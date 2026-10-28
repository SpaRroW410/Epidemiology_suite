# Entry point of the bundle deployed to Posit Connect Cloud (ROADMAP: three ways to use the app). Connect runs it as an
# ordinary Shiny server, so a phone only receives a web page. The bundle holds this file and the package's R/ directory, which is
# sourced exactly as the browser build does (tools/pages/make_app.R), so all three versions are the same code.
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
})
for (f in sort(list.files("R", pattern = "[.]R$", full.names = TRUE))) source(f, local = FALSE)
epidemiologicasuite_app()
