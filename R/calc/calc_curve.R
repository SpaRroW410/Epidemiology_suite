# Power / sensitivity curves (ROADMAP P1 item 10): "required n vs. effect
# size" and "required n vs. power", holding every other argument at its
# current value. Pure, no Shiny -- reuses the exact same calc_*() functions
# (and their existing validation) the rest of the app already calls and
# tests, so a curve traces the same formula the point estimate on screen
# came from, never a re-derivation that could quietly drift from it.

# The sample-size-like field to plot on the y axis. Deliberately narrower
# than calc_result.R's own .ss_result_is_headline() (which also matches an
# achieved-power field -- useful for a one-line printed summary, but wrong
# here: a power curve's own x axis IS power for one of the two curves, so
# the y axis must always be the n/k field, never a second power-shaped one).
#
# Two-tier match: try the strict "starts with n/k" pattern first (this is
# what every design wired so far actually uses, so this preserves that
# exact field choice -- e.g. calc_means_welch's n1/n2 never outrank its own
# n_total this way). Only if nothing in the whole result matches does a
# second, wider pass look for n/k as a whole underscore-separated token
# anywhere in the name, which catches a design like
# calc_case_control_case_cohort()'s subcohort_n/full_cohort_n (a real
# sample size, just not spelled with an n/k *prefix*).
.ss_curve_n_field <- function(res) {
  nms <- setdiff(names(res), "inputs")
  is_scalar_numeric <- function(nm) is.numeric(res[[nm]]) && length(res[[nm]]) == 1

  strict <- Find(function(nm) grepl("^(n|k)(_|$)", nm) && is_scalar_numeric(nm), nms)
  if (!is.null(strict)) return(strict)

  Find(function(nm) {
    tokens <- strsplit(nm, "_", fixed = TRUE)[[1]]
    any(grepl("^(n|k)[0-9]*$", tokens)) && is_scalar_numeric(nm)
  }, nms)
}

#' Recompute a calc_*() result's headline field across a grid of one varying argument
#'
#' @param calc_fn The calc_*() function to call.
#' @param args Named list of its *current* arguments (the values already on screen).
#' @param vary_param Name of the argument to vary.
#' @param vary_values Numeric vector of values to substitute for `vary_param`.
#' @return `data.frame(x, y)`. A value where `calc_fn()` errors (e.g. an
#'   effect size outside the formula's valid domain, or the "no effect to
#'   detect" guard when a scan range happens to include it) is simply not a
#'   row -- a sparser curve, never a fabricated point.
ss_curve_points <- function(calc_fn, args, vary_param, vary_values) {
  xs <- numeric(0)
  ys <- numeric(0)
  for (v in vary_values) {
    call_args <- args
    call_args[[vary_param]] <- v
    res <- tryCatch(do.call(calc_fn, call_args), error = function(e) NULL)
    if (is.null(res)) next
    fname <- .ss_curve_n_field(res)
    if (is.null(fname)) next
    val <- res[[fname]]
    if (!is.finite(val)) next
    xs <- c(xs, v)
    ys <- c(ys, val)
  }
  data.frame(x = xs, y = ys)
}

# Generic scan ranges, reused across every module's curve wiring instead of
# each one inventing its own grid.

#' A scan range for a proportion-like effect parameter, bounded to (0, 1).
curve_range_proportion <- function(n = 40) seq(0.02, 0.98, length.out = n)

#' A scan range for an unbounded (mean-difference-like) effect parameter,
#' centered on a reference value with a spread in the same units (typically
#' a multiple of the design's own SD). The center itself is dropped so a
#' scan never lands exactly on a design's own "no effect to detect" guard.
curve_range_around <- function(center, spread, n = 40) {
  v <- seq(center - spread, center + spread, length.out = n)
  v[abs(v - center) > 1e-9]
}

#' A scan range for power -- the same (0.5, 0.99) domain every
#' `numericInput("power", ...)` in this app already restricts entry to.
curve_range_power <- function(n = 40) seq(0.5, 0.99, length.out = n)

#' A scan range for a correlation-like effect parameter, bounded to
#' (-1, 1) with 0 (no effect) excluded, since every design that takes a
#' bare correlation guards against exactly zero.
curve_range_correlation <- function(n = 40) {
  v <- seq(-0.95, 0.95, length.out = n)
  v[abs(v) > 1e-9]
}

#' A scan range for a ratio-like effect parameter (odds ratio, hazard
#' ratio, relative risk, ...): a fixed log-spaced grid spanning a typical
#' clinically plausible range, with 1 (no effect) excluded since every
#' such design guards against it.
curve_range_ratio <- function(lower = 0.2, upper = 5, n = 40) {
  v <- exp(seq(log(lower), log(upper), length.out = n))
  v[abs(v - 1) > 1e-9]
}
