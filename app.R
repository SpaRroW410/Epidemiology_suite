# Development entry point (shiny::runApp()): loads the package from this directory.
pkgload::load_all(".", quiet = TRUE)
epidemiologicasuite_app()
