# Pure calculation for the Analyze workbench: pooling study results (meta-analysis) from each study's estimate and its
# confidence interval or standard error. No Shiny dependency (tests/testthat/test-calc_analyze_meta.R).
#
# Methods: inverse-variance fixed-effect pooling; Cochran's Q; the DerSimonian-Laird (method of moments) estimate of the
# between-study variance tau^2, truncated at 0; the random-effects pooled estimate with weights 1 / (v_i + tau^2); I^2 and H^2 from
# Q. These are the definitions metafor::rma(method = "FE") and rma(method = "DL") implement, and the functions here are checked
# against metafor 5.2.1 on its own example data (BCG vaccine trials) and other sets, to 6 significant figures. The review read for
# the choice of estimator: Veroniki AA et al. Methods to estimate the between-study variance and its uncertainty in meta-analysis.
# Res Synth Methods 2016;7:55-79 (PMC4950030): DerSimonian-Laird is the most used and the default of many programs, and may
# underestimate the between-study variance, giving too narrow an interval, especially with few studies or large heterogeneity.
# The original papers (DerSimonian & Laird 1986; Higgins & Thompson 2002) were not read.
# Ratio measures (odds ratio, risk ratio, hazard ratio) are pooled on the log scale; a standard error is recovered from a
# confidence interval as (upper - lower) / (2 z) on the scale of analysis.

.meta_se_from_ci <- function(lower, upper, ci_level) (upper - lower) / (2 * stats::qnorm(1 - (1 - ci_level) / 2))

#' Pool study results: fixed-effect and random-effects meta-analysis
#'
#' Pools the estimates of several studies by inverse-variance weighting: the fixed-effect estimate, the DerSimonian-Laird
#' random-effects estimate, and the heterogeneity statistics (Q, I-squared, tau-squared). Each study gives an estimate with
#' either its standard error or its confidence interval.
#'
#' @param estimate Study estimates: ratios (odds ratio, risk ratio, hazard ratio) when `measure = "ratio"`, differences (mean
#'   difference, risk difference, log ratio, any estimate with a normal sampling distribution) when `measure = "difference"`.
#' @param lower,upper Limits of each study's confidence interval (on the same scale as `estimate`); used when `se` is not given.
#' @param se Standard error of each study's estimate (for `measure = "ratio"`, of the log ratio); alternative to `lower`, `upper`.
#' @param measure `"ratio"` (pooled on the log scale and reported as a ratio) or `"difference"`.
#' @param labels Optional study labels.
#' @param ci_level Confidence level of the studies' intervals in `lower` and `upper` (default 0.95).
#' @param conf_level Confidence level of the pooled intervals (default 0.95).
#' @return A named list of class `ss_result` with the components `k` (number of studies); `fixed_estimate`, `fixed_lower`,
#'   `fixed_upper`, `fixed_se`, `fixed_p` and the same five for `random_` (estimate and limits on the scale of `estimate`, the
#'   standard error on the scale of analysis, the log scale for ratios); `Q`, `Q_df`, `Q_p`, `I2` (percent), `H2`, `tau2`; and
#'   `inputs`. The attribute `"studies"` is a data frame of the studies with their intervals and percent weights in the two models.
#' @examples
#' calc_analyze_meta(estimate = c(0.75, 0.90, 0.62, 1.05), lower = c(0.55, 0.70, 0.40, 0.80),
#'                   upper = c(1.02, 1.16, 0.96, 1.38), measure = "ratio")
#' @export
calc_analyze_meta <- function(estimate, lower = NULL, upper = NULL, se = NULL, measure = c("ratio", "difference"),
                              labels = NULL, ci_level = 0.95, conf_level = 0.95) {
  measure <- match.arg(measure)
  .validate_unit_interval(ci_level, "ci_level")
  .validate_unit_interval(conf_level, "conf_level")
  k <- length(estimate)
  if (!is.numeric(estimate) || k < 2 || anyNA(estimate)) stop("At least two studies are needed, each with a numeric estimate.")
  log_scale <- measure == "ratio"
  if (log_scale && any(estimate <= 0)) stop("A ratio (odds ratio, risk ratio, hazard ratio) must be greater than 0.")
  if (is.null(se)) {
    if (is.null(lower) || is.null(upper)) stop("Give each study's confidence interval (lower and upper) or its standard error.")
    if (length(lower) != k || length(upper) != k || anyNA(lower) || anyNA(upper)) stop("Every study needs a lower and an upper limit.")
    if (log_scale && any(lower <= 0)) stop("The lower limit of a ratio must be greater than 0.")
    if (any(upper <= lower)) stop("Each upper limit must be greater than its lower limit.")
    if (any(estimate < lower | estimate > upper)) stop("Each estimate must lie inside its confidence interval.")
    se <- if (log_scale) .meta_se_from_ci(log(lower), log(upper), ci_level) else .meta_se_from_ci(lower, upper, ci_level)
  } else {
    if (!is.numeric(se) || length(se) != k || anyNA(se) || any(se <= 0)) stop("Every study needs a standard error greater than 0.")
  }
  if (is.null(labels)) labels <- paste("Study", seq_len(k))
  if (length(labels) != k) stop("labels must have one entry per study.")
  labels <- ifelse(is.na(labels) | !nzchar(trimws(labels)), paste("Study", seq_len(k)), labels)

  y <- if (log_scale) log(estimate) else estimate
  v <- se^2
  w <- 1 / v
  fe <- sum(w * y) / sum(w)
  Q <- sum(w * (y - fe)^2)
  df <- k - 1
  tau2 <- max(0, (Q - df) / (sum(w) - sum(w^2) / sum(w)))      # DerSimonian-Laird
  wr <- 1 / (v + tau2)
  re <- sum(wr * y) / sum(wr)
  zc <- stats::qnorm(1 - (1 - conf_level) / 2)
  back <- if (log_scale) exp else identity
  pooled <- function(est, se_p, prefix) stats::setNames(
    list(back(est), back(est - zc * se_p), back(est + zc * se_p), se_p, 2 * stats::pnorm(-abs(est / se_p))),
    paste0(prefix, c("_estimate", "_lower", "_upper", "_se", "_p")))
  out <- new_ss_result(c(
    list(k = k),
    pooled(fe, sqrt(1 / sum(w)), "fixed"),
    pooled(re, sqrt(1 / sum(wr)), "random"),
    list(Q = Q, Q_df = df, Q_p = stats::pchisq(Q, df, lower.tail = FALSE),
         I2 = if (Q > 0) 100 * max(0, (Q - df) / Q) else 0,
         H2 = max(1, Q / df),
         tau2 = tau2,
         inputs = list(measure = measure, ci_level = ci_level, conf_level = conf_level))
  ))
  # the studies as analysed (intervals at conf_level, percent weights in the two models), for the table and the forest plot
  attr(out, "studies") <- data.frame(label = labels, estimate = estimate, lower = back(y - zc * se), upper = back(y + zc * se),
                                     weight_fixed = 100 * w / sum(w), weight_random = 100 * wr / sum(wr), stringsAsFactors = FALSE)
  out
}

# Reads the calculator's text box: one study per line, "label, estimate, lower, upper" or "label, estimate, SE" (the label may
# be left out; fields separated by commas, semicolons or tabs). Returns list(labels, estimate, lower, upper, se) or stops with
# the line that could not be read.
.meta_parse_studies <- function(text) {
  lines <- trimws(unlist(strsplit(if (is.null(text)) "" else text, "\n")))
  lines <- lines[nzchar(lines)]
  if (length(lines) < 2) stop("Enter at least two studies, one per line.")
  rows <- lapply(seq_along(lines), function(i) {
    f <- trimws(unlist(strsplit(lines[i], "[,;\t]")))
    num <- suppressWarnings(as.numeric(f))
    first_num <- if (is.na(num[1])) 2 else 1
    vals <- num[first_num:length(num)]
    if (anyNA(vals) || !length(vals) %in% c(2, 3)) {
      stop("Line ", i, " (\"", lines[i], "\") could not be read: write label, estimate, lower, upper -- or label, estimate, SE.")
    }
    list(label = if (first_num == 2) f[1] else NA_character_, vals = vals)
  })
  n <- unique(vapply(rows, function(r) length(r$vals), 1L))
  if (length(n) != 1) stop("Give every study the same figures: either estimate, lower, upper on every line, or estimate, SE on every line.")
  m <- do.call(rbind, lapply(rows, `[[`, "vals"))
  out <- list(labels = vapply(rows, `[[`, "", "label"), estimate = m[, 1])
  if (n == 3) { out$lower <- m[, 2]; out$upper <- m[, 3] } else out$se <- m[, 2]
  out
}
