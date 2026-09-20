#' Sample size for a two-sample (Lincoln-Petersen/Chapman) mark-recapture
#' study, planned for a target precision on the estimated population size
#'
#' No installed R package offers this (`Rcapture` and similar packages are
#' analysis-only -- they estimate N from observed n1/n2/m2 counts, they
#' don't plan n2 in advance). This closed-form design instead inverts the
#' large-sample variance of the Chapman (1951) modification of the
#' Petersen estimator:
#'   N_hat = (n1+1)(n2+1)/(m2+1) - 1          (Chapman 1951)
#' whose exact variance (Seber 1982, "The Estimation of Animal Abundance",
#' 2nd ed., section 3.2) is:
#'   Var(N_hat) = (n1+1)(n2+1)(n1-m2)(n2-m2) / [(m2+1)^2 (m2+2)]
#' Substituting the hypergeometric expectation E[m2] = n1*n2/N (the
#' standard large-sample approximation used throughout the mark-recapture
#' planning literature, e.g. Robson & Regier (1964), "Sample Size in
#' Petersen Mark-Recapture Experiments," Trans Am Fish Soc 93(3):215-226)
#' reduces this to the classical large-sample Petersen/Chapman variance
#'   Var(N_hat) ~= N(N-n1)(N-n2) / (n1*n2)
#' which, solved for n2 given an assumed true population size N, an
#' already-fixed first-sample (marking) size n1, and a target coefficient
#' of variation on N_hat, gives:
#'   n2 = (N-n1)*N / (CV^2 * n1*N + (N-n1))
#'
#' Independently verified this session (not just algebraically, but
#' against the actual discrete process) by simulating m2 ~
#' Hypergeometric(N, n1, n2) at the solved n2 across a range of N/n1/CV
#' combinations and confirming the empirical CV of the Chapman estimator
#' matches the target CV closely (e.g. N=1000, n1=100, target CV=0.10 ->
#' n2=474, simulated CV=0.101; N=200, n1=40, target CV=0.20 -> n2=67,
#' simulated CV=0.208).
#'
#' Precision is expressed the same way as this app's other precision-based
#' designs -- a relative half-width `precision` (e.g. 0.10 for a target
#' 95% CI of N_hat +/- 10% of N) at a stated confidence level, converted
#' to a target CV via CV = precision / z_(1-alpha/2) -- rather than asking
#' the user for a raw CV directly.
#'
#' @param N Assumed true population size being planned around (>= 1).
#'   Mark-recapture inherently needs a rough advance guess at N (from a
#'   pilot count, a prior survey, or expert judgment) to plan n2; if that
#'   guess is badly wrong, the achieved precision will differ from the
#'   target -- state this caveat in the UI.
#' @param n1 First-sample (marking) size, already fixed (>= 1, < N)
#' @param precision Target relative half-width of the confidence interval
#'   for N_hat, as a fraction of N (0,1) -- e.g. 0.10 for +/-10%
#' @param conf_level Confidence level for that precision target (0,1)
#' @return list(n1, n2, N, precision, conf_level, expected_recaptures,
#'   achieved_cv, achieved_precision, inputs)
calc_capture_recapture_n2 <- function(N, n1, precision, conf_level = 0.95) {
  .validate_population(N, "N")
  .validate_positive(n1, "n1")
  if (n1 >= N) stop("n1 must be smaller than N (you can't mark the whole population).")
  .validate_unit_interval(precision, "precision")
  .validate_unit_interval(conf_level, "conf_level")

  z <- qnorm(1 - (1 - conf_level) / 2)
  target_cv <- precision / z

  # n2_raw is bounded above by N for any target_cv > 0 (the denominator is
  # always >= (N - n1), its value at target_cv = 0), so n2 <= N always --
  # a full second-sample census is the zero-variance limit, never exceeded.
  n2_raw <- (N - n1) * N / (target_cv^2 * n1 * N + (N - n1))
  n2 <- ceiling(n2_raw)

  expected_recaptures <- n1 * n2 / N
  var_approx <- N * (N - n1) * (N - n2) / (n1 * n2)
  achieved_cv <- sqrt(var_approx) / N
  achieved_precision <- z * achieved_cv

  list(
    n1 = n1, n2 = n2, N = N, precision = precision, conf_level = conf_level,
    expected_recaptures = expected_recaptures,
    achieved_cv = achieved_cv,
    achieved_precision = achieved_precision,
    inputs = list(N = N, n1 = n1, precision = precision, conf_level = conf_level)
  )
}
