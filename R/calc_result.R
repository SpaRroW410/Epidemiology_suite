# Standard result object (ROADMAP P1 item 8): every calc_*() function's
# return value is wrapped in this lightweight S3 class before being handed
# back to its caller. It changes nothing about the returned list itself --
# every existing field (n, n_total, achieved_power, inputs, ...) is kept
# exactly as before, so `res$n` etc. keeps working unchanged in every
# module's server code and every existing test. What it adds is a generic
# print()/format() method, so a calc_*() result reads sensibly on its own
# (at the R console, or later from an installed package) without a bespoke
# method per design, plus a single recognizable class for the future
# export/report/power-curve features (ROADMAP P1 items 9-10) to hook into
# instead of guessing each function's field names.
#
# Adoption is per calc_*() function, one batch at a time like every other
# incremental item in this project (see docs/ROADMAP.md #8 for progress):
# wrap the function's final `list(...)` return in `new_ss_result(list(...))`.
# Nothing else about the function changes.

#' Construct a standard sample-size result object
#'
#' @param x A named list, the calc_*() function's usual return value
#'   (whatever fields that specific design produces -- n, n_total, n1, n2,
#'   achieved_power, inputs, ... -- nothing here is renamed or removed).
#' @return `x`, unchanged, with class c("ss_result", class(x)) prepended.
new_ss_result <- function(x) {
  stopifnot(is.list(x))
  class(x) <- c("ss_result", class(x))
  x
}

# Fields printed first, if present, ahead of any other top-level field --
# every calc_*() function names its headline sample size and (if it has
# one) its achieved/simulated power differently (n, n_total, n_per_group,
# n1, n2, n_clusters, k, achieved_power, achieved_power_pooled, ...), so
# this is a match on shape (leading n/k, or containing "power"), not a
# fixed list of exact names.
.ss_result_is_headline <- function(name) {
  grepl("^(n|k)(_|$)", name) || grepl("power", name, fixed = TRUE)
}

# Shared by format.ss_result() and calc_export.R's CSV/JSON/justification-
# paragraph generators, so every rendering of a result formats the same
# value the same way.
.ss_result_fmt_value <- function(v) {
  if (is.numeric(v) && length(v) == 1 && is.finite(v) && v == round(v)) {
    as.character(as.integer(v))
  } else if (is.numeric(v)) {
    paste(format(round(v, 4), trim = TRUE), collapse = ", ")
  } else {
    paste(format(v, trim = TRUE), collapse = ", ")
  }
}

#' @method format ss_result
format.ss_result <- function(x, ...) {
  nms <- setdiff(names(x), "inputs")
  headline <- Filter(.ss_result_is_headline, nms)
  other <- setdiff(nms, headline)

  lines <- vapply(c(headline, other), function(nm) sprintf("%s: %s", nm, .ss_result_fmt_value(x[[nm]])),
                   character(1))

  if (!is.null(x$inputs) && is.list(x$inputs) && length(x$inputs) > 0) {
    input_lines <- vapply(names(x$inputs), function(nm) sprintf("  %s: %s", nm, .ss_result_fmt_value(x$inputs[[nm]])),
                           character(1))
    lines <- c(lines, "inputs:", input_lines)
  }

  lines
}

#' @method print ss_result
print.ss_result <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}
