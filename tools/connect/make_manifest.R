# Build the Posit Connect Cloud deployment bundle: tools/connect/app.R + the package's R/ directory + manifest.json.
# Usage: Rscript tools/connect/make_manifest.R [out_dir]   (default "connect_bundle")
# manifest.json lists the entry point, the files and every R package (name, version, CRAN repository) the app needs, found by
# scanning R/ for library() and pkg:: calls; Connect Cloud installs from it. Needs the `rsconnect` package and the app's
# dependencies installed (the versions installed here are the ones recorded), including packages that are only LinkingTo (RcppEigen
# for lme4): renv refuses to snapshot when one is missing.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "connect_bundle"
unlink(out, recursive = TRUE); dir.create(file.path(out, "R"), recursive = TRUE)
invisible(file.copy(list.files("R", full.names = TRUE), file.path(out, "R")))
invisible(file.copy("tools/connect/app.R", file.path(out, "app.R")))
rsconnect::writeManifest(appDir = out, appPrimaryDoc = "app.R", appMode = "shiny", dependencyResolution = "library", quiet = TRUE)
m <- jsonlite::fromJSON(file.path(out, "manifest.json"), simplifyVector = FALSE)
need <- c("shiny", "bslib", "lme4", "PowerTOST", "Exact", "clinfun", "kappaSize", "mvtnorm", "survival")
missing <- setdiff(need, names(m$packages))
if (length(missing)) stop("manifest.json lacks packages the app uses: ", paste(missing, collapse = ", "))
bad <- names(Filter(function(p) !identical(p$Source, "CRAN"), m$packages))
if (length(bad)) stop("packages not from CRAN (Connect could not install them): ", paste(bad, collapse = ", "))
cat(sprintf("Wrote %s/manifest.json: %d packages, %d files\n", out, length(m$packages), length(m$files)))
