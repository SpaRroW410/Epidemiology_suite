# Absolute and relative precision for the five precision-based calculators (single proportion, single mean, cluster survey of a
# proportion, incidence rate, diagnostic accuracy): converting one to the other, the checks on the precision asked for, and the
# inflation for non-response or loss to follow-up. Pure functions, no Shiny.
#
# Absolute precision d is the half-width of the confidence interval on the scale of the estimate (p +/- d). Relative precision
# epsilon is the half-width as a fraction of the estimate, so d = epsilon x p and, for a proportion, n = z^2 (1 - p) / (epsilon^2 p).
#
# Hard stops (the calculation is refused):
#   - a relative precision of 100% or more (the interval would reach 0);
#   - for a proportion (or a sensitivity or specificity), d >= p or d >= 1 - p: the interval p +/- d would pass 0 or 1.
# Warnings (the result is still given):
#   - a relative precision above 20%. This is a common rule of thumb; no published source for it was checked, and the text says so;
#   - a proportion below 10% with d above one-fourth of it. Pourhoseingholi MA, Vahedi M, Rahimzadeh M. Sample size calculation in
#     medical studies. Gastroenterol Hepatol Bed Bench 2013;6(1):14-17 (PMID 24834239, PMC4017493; read through PubMed Central):
#     "when the assumed prevalence is too small (going to be below 10%), the precision of 5% seems to be inappropriate ... A
#     conservative choice would be one-fourth or one-fifth of prevalence as the amount of precision in the case of small P."
#     For a proportion above 90% the app applies the same rule to 1 - p; that mirror is the app's, not the paper's;
#   - for a mean, an absolute precision at least as large as the mean (the interval would include 0).
#
# Non-response / loss to follow-up: if a fraction r of those enrolled is not analyzable, enrol n / (1 - r), rounded up -- the same
# retention identity as the Attrition and Non-response calculator (calc_attrition.R), not n (1 + r).

.prec_tol <- 1e-9

.prec_fmt <- function(x, digits = 3) format(signif(x, digits), trim = TRUE, scientific = FALSE)
.prec_pct <- function(x) paste0(format(round(100 * x, 1), trim = TRUE, nsmall = 0), "%")

.validate_error_type <- function(error) {
  if (!is.character(error) || length(error) != 1 || !error %in% c("absolute", "relative")) {
    stop("error must be \"absolute\" or \"relative\".")
  }
  error
}

.validate_nonresponse <- function(x) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || x >= 1) {
    stop("nonresponse must be a single number from 0 up to (but not including) 1, e.g. 0.1 for 10% non-response or loss to follow-up.")
  }
  x
}

# Number to enrol so that n remain after a fraction r is lost: n / (1 - r), rounded up (n itself when r = 0).
.inflate_nonresponse <- function(n, r) if (r > 0) .ceil_tol(n / (1 - r)) else n

# The absolute half-width for a precision given as absolute or relative to the estimate.
.prec_absolute <- function(estimate, value, error) if (identical(error, "relative")) value * abs(estimate) else value

.prec_relative_checks <- function(value, error, estimate_label) {
  if (!identical(error, "relative")) return(character())
  if (value >= 1 - .prec_tol) {
    stop(sprintf(
      "A relative precision of 100%% or more (here %s) is not a usable target: the interval %s +/- %s would reach 0. Use a smaller relative precision (10%%-20%% is usual).",
      .prec_pct(value), estimate_label, .prec_pct(value)), call. = FALSE)
  }
  if (value > 0.2 + .prec_tol) {
    return(sprintf(
      "The relative precision is %s, above 20%%: the interval is wide compared with %s. A relative precision of at most 20%% is a common rule of thumb (no published source checked for it); 10%%-20%% is usual.",
      .prec_pct(value), estimate_label))
  }
  character()
}

# Checks for a proportion-like estimate p (prevalence, sensitivity, specificity) and its precision `value` (absolute d, or relative
# epsilon). Stops on an impossible target; returns list(d = absolute half-width, epsilon = relative half-width, notes = warnings).
.precision_checks_proportion <- function(p, value, error, p_label = "p") {
  notes <- .prec_relative_checks(value, error, p_label)
  d <- .prec_absolute(p, value, error)
  how <- if (identical(error, "relative")) sprintf(" (%s of %s)", .prec_pct(value), p_label) else ""
  if (d >= p - .prec_tol) {
    stop(sprintf(
      "The precision d = %s%s is not smaller than %s = %s, so the interval %s +/- d would reach below 0. Choose d well below %s (for a small proportion, Pourhoseingholi et al. 2013 suggest one-fourth to one-fifth of it, here %s to %s), or a relative precision.",
      .prec_fmt(d), how, p_label, .prec_fmt(p), p_label, p_label, .prec_fmt(p / 5), .prec_fmt(p / 4)), call. = FALSE)
  }
  if (d >= 1 - p - .prec_tol) {
    stop(sprintf(
      "The precision d = %s%s is not smaller than 1 - %s = %s, so the interval %s +/- d would reach above 1. Choose d well below 1 - %s.",
      .prec_fmt(d), how, p_label, .prec_fmt(1 - p), p_label, p_label), call. = FALSE)
  }
  if (p < 0.1 && d > p / 4 + .prec_tol) {
    notes <- c(notes, sprintf(
      "%s = %s is below 10%% and d = %s is more than one-fourth of it (%s). Pourhoseingholi et al. (2013) call a precision of 5%% inappropriate when the proportion is below 10%% and suggest one-fourth to one-fifth of it as a conservative choice (here %s to %s).",
      p_label, .prec_fmt(p), .prec_fmt(d), .prec_fmt(p / 4), .prec_fmt(p / 5), .prec_fmt(p / 4)))
  } else if (p > 0.9 && d > (1 - p) / 4 + .prec_tol) {
    notes <- c(notes, sprintf(
      "%s = %s is above 90%% and d = %s is more than one-fourth of 1 - %s (%s). This is the small-proportion rule of Pourhoseingholi et al. (2013), one-fourth to one-fifth of the proportion, applied by this app to 1 - %s (here %s to %s).",
      p_label, .prec_fmt(p), .prec_fmt(d), p_label, .prec_fmt((1 - p) / 4), p_label, .prec_fmt((1 - p) / 5), .prec_fmt((1 - p) / 4)))
  }
  list(d = d, epsilon = d / p, notes = notes)
}

# Checks for a mean and its precision. Returns list(d, epsilon, notes).
.precision_checks_mean <- function(mean, value, error) {
  notes <- .prec_relative_checks(value, error, "the mean")
  d <- .prec_absolute(mean, value, error)
  if (identical(error, "absolute") && d >= abs(mean) - .prec_tol) {
    notes <- c(notes, sprintf(
      "The precision %s is not smaller than the mean (%s), so the interval mean +/- %s includes 0. For a positive measurement (blood pressure, haemoglobin, weight) this is not a useful target; choose a smaller precision or a relative one.",
      .prec_fmt(d), .prec_fmt(mean), .prec_fmt(d)))
  }
  list(d = d, epsilon = d / abs(mean), notes = notes)
}

# One line stating a precision both ways and the interval it aims for, shown under the inputs. NULL if the inputs are not usable yet.
# `kind`: "proportion" (bounded 0-1, shown as percentages), "mean", or "rate" (`value` for an absolute rate precision is the FULL
# confidence-interval width, as presize uses).
precision_equivalents_text <- function(estimate, value, error, conf_level, kind = c("proportion", "mean", "rate"),
                                       label = "p") {
  kind <- match.arg(kind)
  ok <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x)
  if (!ok(estimate) || !ok(value) || !ok(conf_level) || value <= 0 || estimate == 0) return(NULL)
  if (kind == "rate" && identical(error, "absolute")) value <- value / 2   # half-width
  d <- .prec_absolute(estimate, value, error)
  eps <- d / abs(estimate)
  lev <- .prec_pct(conf_level)
  if (kind == "proportion") {
    sprintf("Absolute +/- %s (%s percentage points) = relative +/- %s of %s = %s: the %s interval aimed for is about %s to %s.",
            .prec_fmt(d), .prec_fmt(100 * d), .prec_pct(eps), label, .prec_fmt(estimate), lev,
            .prec_fmt(estimate - d), .prec_fmt(estimate + d))
  } else if (kind == "mean") {
    sprintf("Absolute +/- %s = relative +/- %s of the mean %s: the %s interval aimed for is about %s to %s.",
            .prec_fmt(d), .prec_pct(eps), .prec_fmt(estimate), lev, .prec_fmt(estimate - d), .prec_fmt(estimate + d))
  } else {
    sprintf("Interval width %s (half-width +/- %s) = relative +/- %s of the rate %s: a %s interval of about %s to %s if it were symmetric (the score and exact intervals are not quite).",
            .prec_fmt(2 * d), .prec_fmt(d), .prec_pct(eps), .prec_fmt(estimate), lev, .prec_fmt(estimate - d), .prec_fmt(estimate + d))
  }
}
