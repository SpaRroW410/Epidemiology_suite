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
need <- c("shiny", "bslib", "lme4", "clinfun", "kappaSize", "mvtnorm", "survival", "mirai")
missing <- setdiff(need, names(m$packages))
if (length(missing)) stop("manifest.json lacks packages the app uses: ", paste(missing, collapse = ", "))
# Connect can install from CRAN or a mirror of it (what the CI runner installs from: the source reads "CRAN", "RSPM", "standard" ...);
# it cannot install from GitHub or a local copy, so refuse those
src <- vapply(m$packages, function(p) if (is.null(p$Source)) "none" else as.character(p$Source), "")
bad <- names(src)[tolower(src) %in% c("github", "gitlab", "bitbucket", "git", "local", "url", "source", "none", "unknown")]
if (length(bad)) stop("packages Connect could not install (source in brackets): ", paste0(bad, " [", src[bad], "]", collapse = ", "))
cat("package sources:", paste(names(table(vapply(m$packages, function(p) p$Source, ""))), table(vapply(m$packages, function(p) p$Source, "")), collapse = ", "), "\n")
cat(sprintf("Wrote %s/manifest.json: %d packages, %d files\n", out, length(m$packages), length(m$files)))
