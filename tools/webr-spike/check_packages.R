# Shinylive / webR feasibility spike, stage 1 (ROADMAP item 15, Track D3):
# does every runtime package of epidemiologicasuite -- and everything it needs
# -- exist as a WebAssembly build on the webR package repository, and how big
# is the download? Base R only. Run on a machine with internet access:
#   Rscript tools/webr-spike/check_packages.R [out_dir]
# It writes webr_package_check.md and webr_package_check.csv to out_dir
# (default: the working directory) and prints the same table.

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 1) args[1] else "."
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

desc <- read.dcf("DESCRIPTION", fields = "Imports")[1, 1]
imports <- trimws(sub("\\s*\\(.*$", "", strsplit(desc, ",")[[1]]))
imports <- imports[nzchar(imports)]
base_pkgs <- rownames(installed.packages(priority = "base"))
direct <- setdiff(imports, base_pkgs)

cran <- tools::CRAN_package_db()
cran <- cran[!duplicated(cran$Package), ]
rownames(cran) <- cran$Package
deps <- tools::package_dependencies(direct, db = cran, which = c("Depends", "Imports", "LinkingTo"), recursive = TRUE)
closure <- sort(unique(c(direct, unlist(deps))))
closure <- setdiff(closure, base_pkgs)
cat(sprintf("%d direct imports (non-base), %d packages in the dependency closure\n", length(direct), length(closure)))

repo_dirs <- c("4.3", "4.4", "4.5")
read_wasm_index <- function(v) {
  u <- sprintf("https://repo.r-wasm.org/bin/emscripten/contrib/%s/PACKAGES", v)
  x <- tryCatch(read.dcf(url(u)), error = function(e) NULL, warning = function(w) NULL)
  if (is.null(x)) return(NULL)
  as.data.frame(x, stringsAsFactors = FALSE)
}
idx <- setNames(lapply(repo_dirs, read_wasm_index), repo_dirs)
avail_dirs <- names(Filter(Negate(is.null), idx))
cat("webR repository indexes found for R:", paste(avail_dirs, collapse = ", "), "\n")
if (length(avail_dirs) == 0) stop("Could not read any webR package index (repo.r-wasm.org unreachable?).")

pkg_size <- function(v, p, ver) {
  u <- sprintf("https://repo.r-wasm.org/bin/emscripten/contrib/%s/%s_%s.tgz", v, p, ver)
  h <- tryCatch(curlGetHeaders(u), error = function(e) character())
  m <- grep("^content-length:", h, ignore.case = TRUE, value = TRUE)
  if (length(m)) as.numeric(sub("^[^:]*:\\s*", "", m[length(m)])) else NA_real_
}

rows <- lapply(closure, function(p) {
  r <- list(package = p, direct = p %in% direct,
            compiled = if (p %in% rownames(cran)) cran[p, "NeedsCompilation"] else NA,
            cran_version = if (p %in% rownames(cran)) cran[p, "Version"] else NA)
  for (v in avail_dirs) {
    i <- idx[[v]]
    hit <- i[i$Package == p, , drop = FALSE]
    r[[paste0("wasm_", v)]] <- if (nrow(hit)) hit$Version[1] else NA_character_
  }
  newest <- rev(avail_dirs)[1]
  ver <- r[[paste0("wasm_", newest)]]
  r$size_mb <- if (!is.na(ver)) round(pkg_size(newest, p, ver) / 1e6, 2) else NA_real_
  as.data.frame(r, stringsAsFactors = FALSE)
})
tab <- do.call(rbind, rows)
newest_col <- paste0("wasm_", rev(avail_dirs)[1])
tab$in_newest <- !is.na(tab[[newest_col]])
tab <- tab[order(tab$in_newest, !tab$direct, tab$package), ]
write.csv(tab, file.path(out_dir, "webr_package_check.csv"), row.names = FALSE)

missing <- tab[!tab$in_newest, ]
lines <- c(
  "# webR package availability",
  "",
  sprintf("Packages in the dependency closure of the %d direct imports: **%d**; present in the webR repository for R %s: **%d**; missing: **%d**.",
          length(direct), nrow(tab), rev(avail_dirs)[1], sum(tab$in_newest), nrow(missing)),
  sprintf("Total download of the packages found (sum of the .tgz sizes, before webR's own runtime): **%.1f MB**.", sum(tab$size_mb, na.rm = TRUE)),
  "",
  "## Missing from the webR repository",
  if (nrow(missing)) c("", "| package | direct import | compiled |", "|---|---|---|",
                       sprintf("| %s | %s | %s |", missing$package, ifelse(missing$direct, "yes", "no"), missing$compiled)) else "None.",
  "",
  "## Largest packages found",
  "",
  "| package | MB | compiled |", "|---|---|---|",
  { top <- head(tab[order(-tab$size_mb), ], 15); sprintf("| %s | %s | %s |", top$package, top$size_mb, top$compiled) },
  "",
  sprintf("Index availability: %s",
          paste(sprintf("R %s: %s", repo_dirs, ifelse(repo_dirs %in% avail_dirs, "found", "not found")), collapse = "; "))
)
writeLines(lines, file.path(out_dir, "webr_package_check.md"))
cat(paste(lines, collapse = "\n"), "\n")
if (nzchar(Sys.getenv("GITHUB_STEP_SUMMARY"))) cat(paste(lines, collapse = "\n"), "\n", file = Sys.getenv("GITHUB_STEP_SUMMARY"), append = TRUE)
