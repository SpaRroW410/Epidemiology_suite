# Sample size for developing a prediction model: Riley et al.'s criteria, written out (replaces pmsampsize, ROADMAP item 16, stage 2).
# Riley RD, Snell KIE, Ensor J, et al. Minimum sample size for developing a multivariable prediction model: Part I - continuous
# outcomes. Stat Med 2019;38:1262-1275; Part II - binary and time-to-event outcomes. Stat Med 2019;38:1276-1296; the C-statistic
# route follows Riley RD, Van Calster B, Collins GS. A note on estimating the Cox-Snell R2 from a reported C statistic (AUROC) to
# inform sample size calculations for developing a prediction model with a binary outcome. Stat Med 2021;40:859-864.
# (Citations as given in the pmsampsize package documentation; none of the papers could be read here.)
# Binary and survival outcomes, and the continuous outcome's first three criteria, transcribe the logic of pmsampsize 1.1.3 and
# equal it exactly (tests compare them over grids; the package is an oracle only).
# ONE DELIBERATE DIFFERENCE. pmsampsize 1.1.3 (the latest release) has a sign error in the continuous outcome's fourth criterion
# (precision of the intercept, `mmoe`): when that criterion is the binding one its loop uses +qt(0.025, df), a negative number, so the
# interval limits swap, the ratio falls below 1 at once and the loop stops after one step (n + 1, intervals back to front). Example:
# parameters = 2, intercept = 1.9, sd = 0.6, rsquared = 0.2, mmoe = 1.02 gives n = 237 and a "lower" limit 1.97 above the "upper"
# 1.83; the sample size that really gives an upper limit within 2% of the intercept is about 765. Here the criterion is computed
# as defined (the smallest n whose upper confidence limit for the intercept is within `mmoe` of it) and the tests check it against
# that definition; when the criterion does not bind, results equal the package's.

# Cox-Snell R2 implied by a C-statistic and the outcome prevalence, by the package's own simulation (1e6 observations, seed
# 123456): linear predictor ~ N(0, 1) for one group and N(mu, 1) for the other with mu = sqrt(2) qnorm(C), then the Cox-Snell R2 of
# the logistic regression of the group on the linear predictor. The logistic fit is done here by Newton iterations on the two
# parameters rather than glm(), which gives the same maximum-likelihood fit much faster and without building a model matrix.
.cf_cstat2rsq <- function(cstatistic, prevalence, seed = 123456) {
  n <- 1e+06
  mu <- sqrt(2) * stats::qnorm(cstatistic)
  dat <- .rand_with_seed(seed, list(a = stats::rnorm(prevalence * n, mean = 0, sd = 1),
                                    b = stats::rnorm((1 - prevalence) * n, mean = mu, sd = 1)))
  lp <- c(dat$a, dat$b)
  y <- c(rep(0, prevalence * n), rep(1, (1 - prevalence) * n))
  ll <- function(p) sum(y * log(p) + (1 - y) * log1p(-p))
  ybar <- mean(y)
  b <- c(stats::qlogis(ybar), 0)          # start at the null model
  for (it in 1:50) {
    eta <- b[1] + b[2] * lp
    p <- stats::plogis(eta)
    w <- p * (1 - p)
    g <- c(sum(y - p), sum((y - p) * lp))
    H <- matrix(c(sum(w), sum(w * lp), sum(w * lp), sum(w * lp * lp)), 2)
    step <- solve(H, g)
    b <- b + step
    if (max(abs(step)) < 1e-10) break
  }
  p <- stats::plogis(b[1] + b[2] * lp)
  null_dev <- -2 * ll(rep(ybar, length(y)))
  dev <- -2 * ll(p)
  as.numeric(1 - exp(-(null_dev - dev) / n))
}

.cf_pm_lnl_null_bin <- function(prevalence) {      # log-likelihood of the null binary model per observation, times n = 1
  prevalence * log(prevalence) + (1 - prevalence) * log(1 - prevalence)
}

# The sample size for shrinkage S: n = p / ((S - 1) log(1 - R2 / S)).
.cf_pm_n_shrink <- function(parameters, r2a, S) ceiling(parameters / ((S - 1) * log(1 - r2a / S)))

# type "b": binary outcome. Give rsquared (Cox-Snell), or cstatistic.
.cf_pmsampsize_bin <- function(parameters, prevalence, rsquared = NULL, cstatistic = NULL, shrinkage = 0.9, seed = 123456) {
  if (is.null(rsquared) == is.null(cstatistic)) stop("Give exactly one of rsquared (Cox-Snell) or cstatistic.")
  if (is.null(rsquared)) rsquared <- round(.cf_cstat2rsq(cstatistic, prevalence, seed), digits = 4)
  r2a <- rsquared
  if (shrinkage < r2a) stop("User specified shrinkage is lower than R-squared adjusted. Error in log(1 - (r2a/shrinkage)) : NaNs produced")
  n1 <- .cf_pm_n_shrink(parameters, r2a, shrinkage)
  max_r2a <- 1 - exp(2 * .cf_pm_lnl_null_bin(prevalence))
  nag_r2 <- r2a / max_r2a
  if (max_r2a < r2a) stop(sprintf("User specified R-squared adjusted is larger than the maximum possible R-squared (%s) as defined by equation 23 (Riley et al. 2018)", max_r2a))
  s2 <- r2a / (r2a + 0.05 * max_r2a)
  n2 <- .cf_pm_n_shrink(parameters, r2a, s2)
  n3 <- ceiling((1.96 / 0.05)^2 * (prevalence * (1 - prevalence)))
  nfinal <- max(n1, n2, n3)
  list(sample_size = nfinal, criteria = c(n1, n2, n3), parameters = parameters, rsquared = r2a, max_r2a = max_r2a,
       nag_r2 = nag_r2, events = nfinal * prevalence, EPP = round(nfinal * prevalence / parameters, digits = 2),
       final_shrinkage = max(s2, shrinkage))
}

# type "s": time-to-event outcome (Cox-Snell R2 given).
.cf_pmsampsize_surv <- function(parameters, rate, timepoint, meanfup, rsquared, shrinkage = 0.9) {
  r2a <- rsquared
  n <- 10000
  events <- ceiling(rate * (meanfup * n))      # same order of operations as the package: 0.05 * 1.5 * 1e4 is 750.0000000000001, 0.05 * (1.5 * 1e4) is 750
  if (shrinkage < r2a) stop("User specified shrinkage is lower than R-squared adjusted. Error in log(1 - (r2a/shrinkage)) : NaNs produced")
  n1 <- .cf_pm_n_shrink(parameters, r2a, shrinkage)
  lnL_null <- events * log(events / n) - events
  max_r2a <- 1 - exp(2 * lnL_null / n)
  nag_r2 <- r2a / max_r2a
  if (max_r2a < r2a) stop(sprintf("User specified R-squared adjusted is larger than the maximum possible R-squared (%s) as defined by equation 23 (Riley et al. 2018)", max_r2a))
  s2 <- r2a / (r2a + 0.05 * max_r2a)
  n2 <- .cf_pm_n_shrink(parameters, r2a, s2)
  n3 <- max(n1, n2)                                   # criterion 3 (precision of the overall risk) is reported at this n, as in the package
  tot <- round(meanfup * n3, digits = 1)
  uci <- 1 - exp(-(rate + 1.96 * sqrt(rate / tot)) * timepoint)
  lci <- 1 - exp(-(rate - 1.96 * sqrt(rate / tot)) * timepoint)
  nfinal <- max(n1, n2, n3)
  list(sample_size = nfinal, criteria = c(n1, n2, n3), parameters = parameters, r2a = r2a, max_r2a = max_r2a, nag_r2 = nag_r2,
       events = nfinal * rate * meanfup, EPP = round(nfinal * rate * meanfup / parameters, digits = 2),
       int_uci = round(uci, digits = 3), int_lci = round(lci, digits = 3),
       int_cuminc = round(1 - exp(-timepoint * rate), digits = 3), final_shrinkage = max(s2, shrinkage))
}

# type "c": continuous outcome.
.cf_pmsampsize_cont <- function(parameters, intercept, sd, rsquared, shrinkage = 0.9, mmoe = 1.1) {
  if (intercept == 0) stop("The intercept must not be 0: the margin of error mmoe is relative to it.")
  r2a <- rsquared
  es_at <- function(n) 1 + (parameters - 2) / (n * log(1 - (r2a * (n - parameters - 1) + parameters) / (n - 1)))
  # criterion 1: smallest n whose expected shrinkage reaches the target
  n1 <- parameters + 2
  es <- es_at(n1)
  if (!(es > shrinkage)) {
    while (is.na(es) || es < shrinkage) { n1 <- n1 + 1; es <- es_at(n1) }
  }
  n2 <- ceiling(1 + parameters * (1 - r2a) / 0.05)           # criterion 2: precision of the estimated residual variance
  n3 <- 234 + parameters                                      # criterion 3: precision of the estimated residual standard deviation
  n4 <- max(n1, n2, n3)
  # criterion 4: the upper confidence limit of the intercept within `mmoe` times the intercept
  rel_upper <- function(n) {
    df <- n - parameters - 1
    (intercept + sqrt(sd^2 * (1 - r2a) / n) * stats::qt(0.975, df)) / intercept
  }
  ok <- function(n) { v <- rel_upper(n); if (intercept > 0) v <= mmoe else v >= 2 - mmoe }   # negative intercept: the limit moves the other way
  if (!ok(n4)) {
    n_try <- max(n4, ceiling((1.96 * sqrt(sd^2 * (1 - r2a)) / ((mmoe - 1) * abs(intercept)))^2))
    n4 <- n_try
    while (!ok(n4)) n4 <- n4 + 1
    while (n4 > max(n1, n2, n3) && ok(n4 - 1)) n4 <- n4 - 1
  }
  nfinal <- max(n1, n2, n3, n4)
  df <- nfinal - parameters - 1
  half <- sqrt(sd^2 * (1 - r2a) / nfinal) * stats::qt(0.975, df)
  list(sample_size = nfinal, criteria = c(n1, n2, n3, n4), parameters = parameters, r2a = r2a,
       SPP = round(nfinal / parameters, digits = 2), int_mmoe = (intercept + half) / intercept,
       int_uci = round(intercept + half, digits = 2), int_lci = round(intercept - half, digits = 2),
       final_shrinkage = round(es_at(nfinal), digits = 3))
}
