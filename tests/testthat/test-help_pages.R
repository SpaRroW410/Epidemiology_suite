# Every exported function must have a help page that documents every argument and shows a value; the calc_*() functions also an example.
# Read from man/*.Rd and NAMESPACE directly, so it needs no installed copy of the package.

root <- function() {
  # tests run from tests/testthat (or the installed tests directory); the package sources are two levels up when they are present
  for (p in c("../..", "../../..", ".")) if (file.exists(file.path(p, "NAMESPACE")) && dir.exists(file.path(p, "man"))) return(normalizePath(p))
  NULL
}

exports <- function(r) {
  ns <- readLines(file.path(r, "NAMESPACE"), warn = FALSE)
  sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE))
}

rd_info <- function(file) {
  rd <- tools::parse_Rd(file, fragment = FALSE)
  tag <- vapply(rd, function(e) attr(e, "Rd_tag") %||% "", "")
  text <- function(e) paste(unlist(e), collapse = "")
  aliases <- vapply(rd[tag == "\\alias"], text, "")
  args <- character()
  for (blk in rd[tag == "\\arguments"]) for (it in blk) if (identical(attr(it, "Rd_tag"), "\\item")) args <- c(args, trimws(strsplit(text(it[[1]]), ",")[[1]]))
  list(aliases = aliases, args = args, has_value = any(tag == "\\value"), has_examples = any(tag == "\\examples"))
}
`%||%` <- function(a, b) if (is.null(a)) b else a

test_that("every exported function has a help page with every argument documented and a value", {
  r <- root(); skip_if(is.null(r), "package sources not available")
  ex <- exports(r); expect_gt(length(ex), 195)
  infos <- lapply(list.files(file.path(r, "man"), pattern = "[.]Rd$", full.names = TRUE), rd_info)
  by_alias <- list(); for (i in infos) for (a in i$aliases) by_alias[[a]] <- i
  ns <- asNamespace("epidemiologicasuite")
  for (f in ex) {
    info <- by_alias[[f]]
    expect_false(is.null(info), info = paste("no help page for", f))
    if (is.null(info)) next
    fm <- as.character(names(formals(get(f, ns))))
    expect_setequal(info$args, fm)
    expect_true(info$has_value, info = paste(f, "has no \\value"))
    if (startsWith(f, "calc_")) expect_true(info$has_examples, info = paste(f, "has no example"))
  }
})

test_that("all calc_*() functions are exported", {
  r <- root(); skip_if(is.null(r), "package sources not available")
  ns <- asNamespace("epidemiologicasuite")
  calc <- grep("^calc_", ls(ns), value = TRUE)
  calc <- calc[vapply(calc, function(n) is.function(get(n, ns)), TRUE)]
  expect_setequal(intersect(exports(r), calc), calc)
})

test_that("the print and format methods of a result are registered, so an installed package prints a result readably", {
  r <- root(); skip_if(is.null(r), "package sources not available")
  ns <- readLines(file.path(r, "NAMESPACE"), warn = FALSE)
  expect_true("S3method(print, ss_result)" %in% ns)
  expect_true("S3method(format, ss_result)" %in% ns)
  res <- calc_proportion_precision(p = 0.5, d = 0.05)
  expect_match(paste(capture.output(print(res)), collapse = "\n"), "n: 385")
})
