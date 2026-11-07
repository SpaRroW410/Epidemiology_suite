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

  wide <- Find(function(nm) {
    tokens <- strsplit(nm, "_", fixed = TRUE)[[1]]
    any(grepl("^(n|k)[0-9]*$", tokens)) && is_scalar_numeric(nm)
  }, nms)
  if (!is.null(wide)) return(wide)

  # Last resort: a count spelled as n<word> with no underscore, e.g.
  # calc_stepped_wedge_normal()'s nclusters.
  Find(function(nm) grepl("^n[A-Za-z]", nm) && is_scalar_numeric(nm), nms)
}

#' Recompute a calc_*() result's headline field across a grid of one varying argument
#'
#' @param calc_fn The calc_*() function to call.
#' @param args Named list of its *current* arguments (the values already on screen).
#' @param vary_param Name of the argument to vary.
#' @param vary_values Numeric vector of values to substitute for `vary_param`.
#' @param time_limit Seconds one point may take before it is abandoned.
#'   An exact-power search near the null can need thousands of subjects and
#'   take minutes; without a cap one such point would freeze the app. The
#'   limit is only checked where R can interrupt, so a single uninterruptible
#'   compiled call can still overrun it once.
#' @return `data.frame(x, y)` with an attribute `timeouts` (how many points
#'   were abandoned for being too slow). A value where `calc_fn()` errors
#'   (e.g. an effect size outside the formula's valid domain, or the "no
#'   effect to detect" guard when a scan range happens to include it) is
#'   simply not a row -- a sparser curve, never a fabricated point.
#' @noRd
ss_curve_points <- function(calc_fn, args, vary_param, vary_values, time_limit = Inf) {
  xs <- numeric(0)
  ys <- numeric(0)
  timeouts <- 0L
  on.exit(setTimeLimit(elapsed = Inf), add = TRUE)
  for (v in vary_values) {
    call_args <- args
    call_args[[vary_param]] <- v
    setTimeLimit(elapsed = time_limit, transient = TRUE)
    res <- tryCatch(do.call(calc_fn, call_args), error = function(e) {
      if (grepl("elapsed time limit", conditionMessage(e), fixed = TRUE)) timeouts <<- timeouts + 1L
      NULL
    })
    setTimeLimit(elapsed = Inf)
    if (is.null(res)) next
    fname <- .ss_curve_n_field(res)
    if (is.null(fname)) next
    val <- res[[fname]]
    if (!is.finite(val)) next
    xs <- c(xs, v)
    ys <- c(ys, val)
  }
  out <- data.frame(x = xs, y = ys)
  attr(out, "timeouts") <- timeouts
  out
}

# Generic scan ranges, reused across every module's curve wiring instead of
# each one inventing its own grid.

#' A scan range for a proportion-like effect parameter, bounded to (0, 1).
#' @noRd
curve_range_proportion <- function(n = 40) seq(0.02, 0.98, length.out = n)

#' A scan range for an unbounded (mean-difference-like) effect parameter,
#' centered on a reference value with a spread in the same units (typically
#' a multiple of the design's own SD). The center itself is dropped so a
#' scan never lands exactly on a design's own "no effect to detect" guard.
#' @noRd
curve_range_around <- function(center, spread, n = 40) {
  v <- seq(center - spread, center + spread, length.out = n)
  v[abs(v - center) > 1e-9]
}

#' A scan range for power -- the same (0.5, 0.99) domain every
#' `numericInput("power", ...)` in this app already restricts entry to.
#' @noRd
curve_range_power <- function(n = 40) seq(0.5, 0.99, length.out = n)

#' A scan range for a correlation-like effect parameter, bounded to
#' (-1, 1) with 0 (no effect) excluded, since every design that takes a
#' bare correlation guards against exactly zero.
#' @noRd
curve_range_correlation <- function(n = 40) {
  v <- seq(-0.95, 0.95, length.out = n)
  v[abs(v) > 1e-9]
}

#' A scan range for a ratio-like effect parameter (odds ratio, hazard
#' ratio, relative risk, ...): a fixed log-spaced grid spanning a typical
#' clinically plausible range, with 1 (no effect) excluded since every
#' such design guards against it.
#' @noRd
curve_range_ratio <- function(lower = 0.2, upper = 5, n = 40) {
  v <- exp(seq(log(lower), log(upper), length.out = n))
  v[abs(v - 1) > 1e-9]
}

#' A scan range strictly inside an explicit (lower, upper) bound, e.g. a
#' TOST/bioequivalence effect that must fall strictly within its own
#' equivalence margin or limits (not merely bounded like a proportion, but
#' bounded by another *input*, so this can't be a fixed grid). A small
#' fractional pad keeps the grid off both open-interval endpoints, which
#' every such design's own validation rejects exactly at the boundary.
#' @noRd
curve_range_within <- function(lower, upper, n = 40, margin_frac = 0.02) {
  pad <- (upper - lower) * margin_frac
  seq(lower + pad, upper - pad, length.out = n)
}

#' A log-spaced scan range around a positive center value (e.g. a
#' reference SD, a Cohen's f effect size), guaranteed to stay positive --
#' unlike curve_range_around(), which is symmetric in raw units and can go
#' negative or zero for a center not far from it. The center itself is
#' excluded, same reasoning as curve_range_around().
#' @noRd
curve_range_multiplicative <- function(center, lower_mult = 0.3, upper_mult = 3, n = 40) {
  v <- exp(seq(log(center * lower_mult), log(center * upper_mult), length.out = n))
  v[abs(v - center) > 1e-9]
}

#' Scale a vector's deviations from a reference by a multiplier `m`
#'
#' For a design whose effect is a whole vector (group means, alternative
#' proportions) rather than one scalar: `m = 1` reproduces the entered
#' values and the curve's x axis becomes "how much larger or smaller the
#' differences are", which is the one knob every such design actually has.
#' @noRd
curve_scale_about <- function(x, ref, m) ref + m * (x - ref)
