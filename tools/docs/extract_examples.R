# One-off documentation helper: for every calc_*() function find a real call in the test files (a worked example that is already
# checked against a published value, a package or a simulation), run it, and record the call, how long it took and the names of
# the result's components. tools/docs/write_roxygen.py uses this to complete the help pages (examples and @return).
# Usage (repository root): Rscript tools/docs/extract_examples.R <out.json>
suppressMessages(pkgload::load_all(".", quiet = TRUE))
out <- commandArgs(trailingOnly = TRUE)[1]
ns <- asNamespace("epidemiologysuite")
fns <- sort(grep("^calc_", ls(ns), value = TRUE)); fns <- fns[vapply(fns, function(n) is.function(get(n, ns)), TRUE)]
skip_wrappers <- c("expect_error", "expect_warning", "expect_message", "expect_snapshot", "expect_condition", "tryCatch", "try", "suppressWarnings")
found <- setNames(vector("list", length(fns)), fns)
walk <- function(e, in_skip = FALSE) {
  if (missing(e)) return(invisible())
  if (is.call(e)) {
    head <- e[[1]]
    nm <- if (is.name(head)) as.character(head) else NA_character_
    skip_here <- in_skip || (!is.na(nm) && nm %in% skip_wrappers)
    if (!is.na(nm) && nm %in% fns && !skip_here) found[[nm]] <<- c(found[[nm]], list(e))
    for (i in seq_along(e)) { if (identical(e[[i]], quote(expr = ))) next; walk(e[[i]], skip_here) }
  } else if (is.pairlist(e) || is.expression(e)) for (x in as.list(e)) walk(x, in_skip)
}
for (f in list.files("tests/testthat", pattern = "^test-.*[.]R$", full.names = TRUE)) {
  ex <- tryCatch(parse(f, keep.source = FALSE), error = function(e) NULL)
  for (e in ex) walk(e)
}
res <- list()
for (n in fns) {
  best <- NULL
  for (cl in found[[n]]) {
    env <- new.env(parent = ns)
    t0 <- Sys.time()
    r <- tryCatch({ setTimeLimit(elapsed = 25, transient = TRUE); eval(cl, env) }, error = function(e) NULL)
    setTimeLimit(elapsed = Inf)
    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (!is.null(r) && is.list(r)) {
      cand <- list(call = paste(deparse(cl, width.cutoff = 78L), collapse = "\n"), seconds = round(dt, 2), fields = setdiff(names(r), "inputs"))
      if (is.null(best) || (best$seconds > 1.5 && dt < best$seconds)) best <- cand
      if (dt <= 1.5) { best <- cand; break }
    }
  }
  res[[n]] <- best
}
cat("functions:", length(fns), " with an example:", sum(!vapply(res, is.null, TRUE)), " slow (> 1.5 s):", sum(vapply(res, function(x) !is.null(x) && x$seconds > 1.5, TRUE)), "\n")
jsonlite::write_json(res, out, auto_unbox = TRUE, pretty = TRUE, null = "null")
