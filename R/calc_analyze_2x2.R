# Analyze from summary counts: the 2x2 table (ROADMAP Track B1, item 13).
#
# Unlike every other calc_*.R file this does not plan a study: it analyzes
# counts the user already has. Layout (rows = exposure, columns = outcome):
#
#                 Outcome +   Outcome -
#   Exposed          a           b
#   Unexposed        c           d
#
# The closed forms are written out here (rather than called through epiR) so
# the formulas are visible and do not depend on the shape of epi.2by2()'s
# return value, which has changed between epiR releases; epiR::epi.2by2() is
# the verification oracle in tests/testthat/test-calc_analyze_2x2.R.
#
# Sources
#   RR     Katz D et al. Biometrics 1978;34:469-474 (log-RR variance).
#   OR     Woolf B. Ann Hum Genet 1955;19:251-253 (log-OR variance).
#   RD     Wald interval for a difference of two independent proportions.
#   AF(e)  (RR - 1)/RR, or (OR - 1)/OR for case-control data; CI by
#          transforming the RR/OR limits (Rothman KJ, Greenland S, Lash TL.
#          Modern Epidemiology, 3rd ed., 2008, ch. 4 and 15).
#   PAF    Jewell NP. Statistics for Epidemiology. Chapman & Hall/CRC; 2004
#          (cohort and case-control forms, log(1 - PAF) normal approximation),
#          as implemented in epiR::epi.2by2().
#   NNT    Altman DG. BMJ 1998;317:1309-1312 (reciprocal of the risk
#          difference; interval from the reciprocal limits, undefined when the
#          RD interval includes 0).

.validate_2x2_counts <- function(a, b, c, d) {
  cells <- list(a = a, b = b, c = c, d = d)
  for (nm in names(cells)) {
    v <- cells[[nm]]
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < 0 || v != round(v)) {
      stop(sprintf("Cell %s must be a single non-negative whole number.", nm))
    }
  }
  if ((a + b) == 0 || (c + d) == 0) {
    stop("Each exposure group (row) needs at least one subject.")
  }
  if ((a + c) == 0 || (b + d) == 0) {
    stop("Each outcome category (column) needs at least one subject.")
  }
  invisible(TRUE)
}

# est +/- z*se on the log scale, back-transformed; NA when a cell is zero
# (the log of 0 is undefined and we do not silently add 0.5).
.log_ci <- function(est, se, z) {
  if (!is.finite(est) || est <= 0 || !is.finite(se)) return(c(NA_real_, NA_real_))
  exp(log(est) + c(-1, 1) * z * se)
}

#' Analyze a 2x2 table of counts
#'
#' @param a,b,c,d Cell counts: exposed with/without the outcome (a, b),
#'   unexposed with/without the outcome (c, d).
#' @param design "cohort" (risks are estimable: RR, RD, attributable fractions,
#'   number needed), "cross_sectional" (the same formulas, read as prevalences:
#'   prevalence ratio and difference) or "case_control" (only the odds ratio is
#'   estimable; the attributable fractions use the odds ratio).
#' @param conf_level Confidence level for every interval.
calc_analyze_2x2 <- function(a, b, c, d, design = c("cohort", "cross_sectional", "case_control"), conf_level = 0.95) {
  design <- match.arg(design)
  .validate_2x2_counts(a, b, c, d)
  .validate_unit_interval(conf_level, "Confidence level")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)

  n1 <- a + b; n0 <- c + d; m1 <- a + c; m0 <- b + d; n <- n1 + n0
  zero_cell <- any(c(a, b, c, d) == 0)

  # Odds ratio (both designs)
  or <- (a * d) / (b * c)
  or_ci <- .log_ci(or, sqrt(1 / a + 1 / b + 1 / c + 1 / d), z)
  if (!is.finite(or)) or <- NA_real_

  # Association tests (uncorrected Pearson chi-square; Fisher's exact)
  exp_counts <- outer(c(n1, n0), c(m1, m0)) / n
  chisq <- sum((matrix(c(a, c, b, d), 2) - exp_counts)^2 / exp_counts)
  chisq_p <- stats::pchisq(chisq, df = 1, lower.tail = FALSE)
  fisher_p <- stats::fisher.test(matrix(c(a, c, b, d), 2))$p.value

  res <- list(
    n_total = n, design = design,
    odds_ratio = or, odds_ratio_lower = or_ci[1], odds_ratio_upper = or_ci[2],
    chisq = chisq, chisq_p = chisq_p, fisher_p = fisher_p,
    min_expected_count = min(exp_counts)
  )

  if (design != "case_control") {
    r1 <- a / n1; r0 <- c / n0
    rr <- if (r0 > 0) r1 / r0 else NA_real_
    rr_ci <- .log_ci(rr, sqrt(1 / a - 1 / n1 + 1 / c - 1 / n0), z)
    rd <- r1 - r0
    rd_se <- sqrt(r1 * (1 - r1) / n1 + r0 * (1 - r0) / n0)
    rd_ci <- rd + c(-1, 1) * z * rd_se

    # Attributable fraction among the exposed: (RR - 1) / RR, limits transformed
    af <- function(x) (x - 1) / x
    af_e <- af(rr); af_ci <- af(rr_ci)

    # Population attributable fraction (Jewell 2004; as in epiR)
    paf <- (a * d - b * c) / (m1 * n0)
    paf_var <- if (c > 0) (b + paf * (a + d)) / (n * c) else NA_real_
    paf_ci <- 1 - exp(log(1 - paf) + c(1, -1) * z * sqrt(paf_var))

    # Number needed to treat / harm (Altman 1998)
    nn <- if (rd != 0) 1 / abs(rd) else NA_real_
    nn_label <- if (rd < 0) "NNT (benefit)" else if (rd > 0) "NNH (harm)" else NA_character_
    rd_ci_excludes_0 <- rd_ci[1] > 0 || rd_ci[2] < 0
    nn_ci <- if (rd_ci_excludes_0) sort(1 / abs(rd_ci)) else c(NA_real_, NA_real_)

    res <- c(res[c("n_total", "design")], list(
      risk_exposed = r1, risk_unexposed = r0,
      risk_ratio = rr, risk_ratio_lower = rr_ci[1], risk_ratio_upper = rr_ci[2],
      risk_difference = rd, risk_difference_lower = rd_ci[1], risk_difference_upper = rd_ci[2],
      attributable_fraction_exposed = af_e,
      attributable_fraction_exposed_lower = af_ci[1], attributable_fraction_exposed_upper = af_ci[2],
      population_attributable_fraction = paf,
      population_attributable_fraction_lower = paf_ci[1], population_attributable_fraction_upper = paf_ci[2],
      number_needed = nn, number_needed_label = nn_label,
      number_needed_lower = nn_ci[1], number_needed_upper = nn_ci[2]
    ), res[setdiff(names(res), c("n_total", "design"))])
  } else {
    # Case-control: (OR - 1)/OR is the exposed attributable fraction for a rare
    # outcome; the population fraction uses the exposure prevalence among cases
    # (Jewell 2004; as in epiR's case.control method).
    af <- function(x) (x - 1) / x
    paf <- (a * d - b * c) / (d * m1)
    paf_var <- if (c > 0 && d > 0) a / (c * m1) + b / (d * m0) else NA_real_
    paf_ci <- 1 - exp(log(1 - paf) + c(1, -1) * z * sqrt(paf_var))
    res <- c(res, list(
      attributable_fraction_exposed = af(or),
      attributable_fraction_exposed_lower = af(or_ci[1]), attributable_fraction_exposed_upper = af(or_ci[2]),
      population_attributable_fraction = paf,
      population_attributable_fraction_lower = paf_ci[1], population_attributable_fraction_upper = paf_ci[2]
    ))
  }

  res$zero_cell <- zero_cell
  res$inputs <- list(a = a, b = b, c = c, d = d, conf_level = conf_level)
  new_ss_result(res)
}

# Estimates as a tidy table (for display): one row per measure.
analyze_2x2_table <- function(result) {
  prev <- identical(result$design, "cross_sectional")
  pick <- function(label, base, pct = FALSE) {
    est <- result[[base]]
    if (is.null(est)) return(NULL)
    k <- if (pct) 100 else 1
    data.frame(
      measure = label, estimate = est * k,
      lower = result[[paste0(base, "_lower")]] * k, upper = result[[paste0(base, "_upper")]] * k,
      stringsAsFactors = FALSE
    )
  }
  rows <- list(
    pick(if (prev) "Prevalence ratio (PR)" else "Risk ratio (RR)", "risk_ratio"),
    pick("Odds ratio (OR)", "odds_ratio"),
    pick(if (prev) "Prevalence difference" else "Risk difference (RD)", "risk_difference"),
    pick("Attributable fraction among exposed (%)", "attributable_fraction_exposed", TRUE),
    pick("Population attributable fraction (%)", "population_attributable_fraction", TRUE)
  )
  if (!is.null(result$number_needed) && !is.na(result$number_needed)) {
    rows <- c(rows, list(data.frame(
      measure = result$number_needed_label, estimate = result$number_needed,
      lower = result$number_needed_lower, upper = result$number_needed_upper,
      stringsAsFactors = FALSE
    )))
  }
  do.call(rbind, Filter(Negate(is.null), rows))
}
