# Helpers for working with a result from R (docs/archive/to_do_later.md C, 4 Nov 2026). The naming is: calc_*() functions compute a sample size or a
# power and return an `ss_result`; ss_*() functions work with those results (ss_find() finds a calculator, ss_text() writes the protocol
# paragraph, ss_export() writes CSV or JSON, ss_curve() varies one input). They reuse what the app's export panel and curves use.

#' A paragraph for a protocol from a result
#'
#' The same justification paragraph the app shows under every result: the design, the result, the inputs it rests on, and the source of
#' the formula.
#'
#' @param result An `ss_result`, as returned by a `calc_*()` function.
#' @param design A short name of the design, used in the sentence (for example "Single proportion, precision-based").
#' @param citation The source of the formula. Required: it is what a reviewer asks for. Each calculator's Reference tab in the app gives it.
#' @param backend Optional: how the value was computed (for example "closed form" or a package function).
#' @return A character string.
#' @examples
#' r <- calc_proportion_precision(p = 0.3, d = 0.05)
#' ss_text(r, "Single proportion, precision-based",
#'         "Cochran WG. Sampling Techniques. 3rd ed. New York: Wiley; 1977.")
#' @export
ss_text <- function(result, design, citation, backend = NULL) {
  if (!inherits(result, "ss_result")) stop("result must be an ss_result returned by a calc_*() function.", call. = FALSE)
  if (missing(design) || !is.character(design) || length(design) != 1 || !nzchar(design)) stop("design must be a short name of the design.", call. = FALSE)
  if (missing(citation) || !is.character(citation) || length(citation) != 1 || !nzchar(citation)) {
    stop("citation must name the source of the formula.", call. = FALSE)
  }
  format_justification(design, result, citation, backend)
}

#' Export a result as CSV or JSON
#'
#' One row of CSV (a header line and a data line) or a JSON object with every field of the result and its inputs, as the app's export
#' panel downloads them.
#'
#' @param result An `ss_result`, as returned by a `calc_*()` function.
#' @param format "csv" or "json".
#' @param file Optional path. When given, the text is written there and the path is returned invisibly; otherwise the text is returned.
#' @return The CSV or JSON text, or (with `file`) the path, invisibly.
#' @examples
#' r <- calc_means_1s(mu0 = 120, mu1 = 125, sd = 15)
#' cat(ss_export(r, "csv"))
#' cat(ss_export(r, "json"))
#' @export
ss_export <- function(result, format = c("csv", "json"), file = NULL) {
  if (!inherits(result, "ss_result")) stop("result must be an ss_result returned by a calc_*() function.", call. = FALSE)
  format <- match.arg(format)
  txt <- if (format == "csv") ss_result_to_csv(result) else ss_result_to_json(result)
  if (is.null(file)) return(txt)
  writeLines(txt, file)
  invisible(file)
}

#' Sample size (or power) across a range of one input
#'
#' Calls a `calc_*()` function once for each value of one argument, the others held as given, and returns the headline result for each:
#' the same calculation as the app's power / sensitivity curves. A value at which the formula has no solution is left out, not filled in.
#'
#' @param calc_fn A `calc_*()` function.
#' @param args A named list of its arguments (the values held fixed).
#' @param vary The name of the argument to vary.
#' @param values The values to give it.
#' @return A data frame with `x` (the value of `vary`) and `y` (the headline result: the sample size, or the power where that is what the
#'   function returns).
#' @examples
#' ss_curve(calc_proportion_precision, list(p = 0.3, d = 0.05), "d", c(0.03, 0.04, 0.05, 0.06))
#' @export
ss_curve <- function(calc_fn, args, vary, values) {
  if (!is.function(calc_fn)) stop("calc_fn must be a calc_*() function.", call. = FALSE)
  if (!is.list(args) || (length(args) && is.null(names(args)))) stop("args must be a named list of the function's arguments.", call. = FALSE)
  if (!is.character(vary) || length(vary) != 1 || !vary %in% names(formals(calc_fn))) {
    stop("vary must be the name of one of calc_fn's arguments.", call. = FALSE)
  }
  if (!is.numeric(values) || length(values) == 0) stop("values must be numbers.", call. = FALSE)
  out <- ss_curve_points(calc_fn, args, vary, values)
  attr(out, "timeouts") <- NULL
  out
}
