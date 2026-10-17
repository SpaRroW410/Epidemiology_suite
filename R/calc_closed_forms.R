# Closed-form sample-size routines that used to be borrowed from epiR and rstatix
# (ROADMAP item 16, Phase 8 dependency reduction). Each is a transcription of the branch of
# the epiR (2.0.67) / rstatix function that this app actually called, so results are identical to
# the package it replaces; tests/testthat/test-calc_closed_forms.R compares them with the real
# functions over grids of inputs (the packages are verification oracles only, not dependencies).
# The formulas are textbook ones; sources are named in the module content files and below.
# The functions are internal (leading dot) and keep epiR's argument names where that helps the
# comparison.
#
# Licence note: epiR is GPL (>= 2); these are re-expressions of published formulas, and the
# package as a whole is GPL-3 (ROADMAP finding F8).

# --- one mean, relative or absolute precision (Lwanga & Lemeshow / Levy & Lemeshow) -------------
# n = z^2 N V^2 / (z^2 V^2 + (N - 1) eps_r^2), V = sigma / mean; N infinite when NA (epiR used 1e7).
.cf_sssimpleestc <- function(N = NA, xbar, sigma, epsilon, error = "relative", conf.level = 0.95) {
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  epsilon.r <- if (identical(error, "relative")) epsilon else epsilon / xbar
  Vsq <- sigma^2 / xbar^2
  N.inf <- 1e+07
  n <- if (is.na(N)) {
    (z^2 * N.inf * Vsq) / (z^2 * Vsq + ((N.inf - 1) * epsilon.r^2))
  } else {
    (z^2 * N * Vsq) / (z^2 * Vsq + ((N - 1) * epsilon.r^2))
  }
  ceiling(n)
}

# --- non-inferiority, two means (Chow, Shao & Wang 2008, ch. 3) ----------------------------------
.cf_ssninfc <- function(treat, control, sigma, delta, power, r = 1, alpha) {
  if (delta < 0) stop("For a non-inferiority trial delta must be greater than or equal to zero.")
  z.alpha <- stats::qnorm(1 - alpha)
  z.beta <- stats::qnorm(power)
  ndelta <- -delta
  if (sign(z.alpha + z.beta) != sign(treat - control - ndelta)) {
    stop("Target power is not reachable. Check the exact specification of the hypotheses.")
  }
  n.control <- (1 + 1 / r) * (sigma * (z.alpha + z.beta) / (treat - control - ndelta))^2
  n.treat <- n.control * r
  n.control <- ceiling(n.control)    # both groups are rounded up from the unrounded values
  n.treat <- ceiling(n.treat)
  list(n.total = n.treat + n.control, n.treat = n.treat, n.control = n.control)
}

# --- non-inferiority, two proportions -----------------------------------------------------------
.cf_ssninfb <- function(treat, control, delta, power, r = 1, alpha) {
  if (delta < 0) stop("For a non-inferiority trial delta must be greater than or equal to zero.")
  z.alpha <- stats::qnorm(1 - alpha)
  z.beta <- stats::qnorm(power)
  ndelta <- -delta
  if (sign(z.alpha + z.beta) != sign(treat - control - ndelta)) {
    stop("Target power is not reachable. Check the exact specification of the hypotheses.")
  }
  n.control <- ceiling((treat * (1 - treat) / r + control * (1 - control)) * ((z.alpha + z.beta) / (treat - control - ndelta))^2)
  n.treat <- n.control * r
  list(n.total = n.treat + n.control, n.treat = n.treat, n.control = n.control)
}

# --- equivalence, two proportions (Chow, Shao & Wang 2008) -------------------------------------
.cf_ssequb_equivalence <- function(treat, control, delta, power, r = 1, alpha) {
  if (delta <= 0) stop("For an equivalence trial delta must be greater than zero.")
  z.alpha <- stats::qnorm(1 - alpha)
  z.beta <- stats::qnorm(1 - (1 - power) / 2)
  pA <- treat; pB <- control; qA <- 1 - pA; qB <- 1 - pB
  nB <- (pA * qA / r + pB * qB) * ((z.alpha + z.beta) / (abs(pA - pB) - delta))^2
  n.treat <- ceiling(nB * r)
  n.control <- ceiling(nB)
  list(n.total = n.treat + n.control, n.treat = n.treat, n.control = n.control)
}

# --- case-control, unmatched (Kelsey et al. 1996; Fleiss correction not used here) --------------
.cf_sscc_unmatched <- function(N = NA, OR, p0, power, r = 1, design = 1, sided.test = 2, conf.level = 0.95) {
  z.alpha <- stats::qnorm(1 - (1 - conf.level) / sided.test)
  z.beta <- stats::qnorm(p = 1 - power, lower.tail = FALSE)
  Pc <- (p0 / (r + 1)) * ((r * OR / (1 + (OR - 1) * p0)) + 1)
  t1 <- (r + 1) * (1 + (OR - 1) * p0)^2
  t2 <- r * p0^2 * (p0 - 1)^2 * (OR - 1)^2
  t3 <- z.alpha * sqrt((r + 1) * Pc * (1 - Pc))
  t4 <- OR * p0 * (1 - p0)
  t5 <- 1 + (OR - 1) * p0
  t6 <- t4 / (t5^2)
  t7 <- r * p0 * (1 - p0)
  t8 <- z.beta * sqrt(t6 + t7)
  n <- (t1 / t2) * (t3 + t8)^2
  n1 <- (n / (1 + r)) * design
  n0 <- r * n1
  n.total <- n0 + n1
  p1 <- n1 / n.total
  p0w <- n0 / n.total
  n.total <- if (is.na(N)) n.total else (n.total * N) / (n.total + (N - 1))
  n1 <- if (is.na(N)) n1 else p1 * n.total
  n0 <- if (is.na(N)) n0 else p0w * n.total
  n1 <- ceiling(n1); n0 <- ceiling(n0)
  list(n.total = n1 + n0, n.case = n1, n.control = n0)
}

# --- case-control, matched (Dupont 1988, as implemented in epiR) --------------------------------
.cf_sscc_matched <- function(N = NA, OR, p0, power, r = 1, phi.coef = 0, design = 1, sided.test = 2, conf.level = 0.95) {
  z.alpha <- stats::qnorm(1 - (1 - conf.level) / sided.test)
  z.beta <- stats::qnorm(1 - power, lower.tail = FALSE)
  odds0 <- p0 / (1 - p0)
  odds1 <- odds0 * OR
  p1 <- odds1 / (1 + odds1)
  psi <- OR
  pq <- p1 * (1 - p1) * p0 * (1 - p0)
  p0.p <- (p1 * p0 + phi.coef * sqrt(pq)) / p1
  p0.n <- (p0 * (1 - p1) - phi.coef * sqrt(pq)) / (1 - p1)
  tm <- ee.psi <- ee.one <- nu.psi <- nu.one <- rep(NA_real_, r)
  for (m in 1:r) {
    tm[m] <- p1 * choose(r, m - 1) * ((p0.p)^(m - 1)) * ((1 - p0.p)^(r - m + 1)) +
      (1 - p1) * choose(r, m) * ((p0.n)^m) * ((1 - p0.n))^(r - m)
    ee.psi[m] <- m * tm[m] * psi / (m * psi + r - m + 1)
    ee.one[m] <- m * tm[m] / (r + 1)
    nu.psi[m] <- m * tm[m] * psi * (r - m + 1) / ((m * psi + r - m + 1)^2)
    nu.one[m] <- m * tm[m] * (r - m + 1) / ((r + 1)^2)
  }
  ee.psi <- sum(ee.psi); ee.one <- sum(ee.one); nu.psi <- sum(nu.psi); nu.one <- sum(nu.one)
  n <- ((z.beta * sqrt(nu.psi) + z.alpha * sqrt(nu.one))^2) / ((ee.one - ee.psi)^2)
  n1 <- n * design
  n0 <- r * n1
  n.total <- n0 + n1
  p1w <- n1 / n.total
  p0w <- n0 / n.total
  n.total <- if (is.na(N)) n.total else (n.total * N) / (n.total + (N - 1))
  n1 <- if (is.na(N)) n1 else p1w * n.total
  n0 <- if (is.na(N)) n0 else p0w * n.total
  n1 <- ceiling(n1)
  n0 <- ceiling(r * n1)                                  # epiR derives the controls from the rounded cases
  list(n.total = n1 + n0, n.case = n1, n.control = n0)
}

# --- cohort, risks in the two groups (Kelsey et al. 1996 / Fleiss) ------------------------------
.cf_sscohortc <- function(N = NA, irexp1, irexp0, power, r = 1, design = 1, sided.test = 2, conf.level = 0.95) {
  z.alpha <- stats::qnorm(1 - (1 - conf.level) / sided.test)
  z.beta <- stats::qnorm(power)
  lambda <- irexp1 / irexp0
  pi <- irexp0
  pc <- (pi * ((r * lambda) + 1)) / (r + 1)
  p1 <- (r + 1) / (r * (lambda - 1)^2 * pi^2)
  p2 <- z.alpha * sqrt((r + 1) * pc * (1 - pc))
  p3 <- z.beta * sqrt((lambda * pi * (1 - (lambda * pi))) + (r * pi * (1 - pi)))
  n0 <- p1 * (p2 + p3)^2
  n0 <- n0 * design
  n <- if (is.na(N)) n0 else (n0 * N) / (n0 + (N - 1))
  n.exp1 <- ceiling(n / (r + 1)) * r
  n.exp0 <- ceiling(n / (r + 1)) * 1
  list(n.total = n.exp1 + n.exp0, n.exp1 = n.exp1, n.exp0 = n.exp0, irr = lambda)
}

# --- two-stage cluster survey for a proportion (Levy & Lemeshow; Bennett et al. 1991) -----------
.cf_ssclus2estb <- function(N.psu = NA, b, Py, epsilon, error = "relative", rho, conf.level = 0.95) {
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  epsilon.a <- if (identical(error, "absolute")) epsilon else Py * epsilon
  if (length(b) == 2) {
    bbar <- b[1]; bcv <- b[2] / b[1]
    D <- 1 + ((bcv^2 + 1) * bbar - 1) * rho
    bb <- bbar
  } else {
    D <- 1 + ((b - 1) * rho)
    bb <- b
  }
  n.ssu <- (z^2 * Py * (1 - Py)) * D / epsilon.a^2
  n.psu <- n.ssu / bb
  n.psu <- if (is.na(N.psu)) n.psu else (n.psu * N.psu) / (n.psu + (N.psu - 1))
  n.ssu <- n.psu * bb
  n.psu <- ceiling(n.psu); n.ssu <- ceiling(n.ssu)
  if (n.psu <= 25) {
    warning(paste("The calculated number of primary sampling units (n.psu) is ", n.psu,
                  ". At least 25 primary sampling units are recommended for two-stage cluster sampling designs.", sep = ""),
            call. = FALSE)
  }
  list(n.psu = n.psu, n.ssu = n.ssu, DEF = D)
}

# --- detecting at least one case with an imperfect test (MacDiarmid 1988; Cannon 2001) ----------
# One population (length(N) == 1), as the app uses it. Two tests are combined in series or in
# parallel with zero covariance (the app passes covar = c(0, 0)).
.cf_ssdetect <- function(N, prev, se, sp, interpretation = "series", conf.level = 0.95) {
  if (length(se) > 1 && interpretation == "series") {
    use <- se[1] * se[2]
    usp <- 1 - (1 - sp[1]) * (1 - sp[2])
  } else if (length(se) > 1 && interpretation == "parallel") {
    use <- 1 - (1 - se[1]) * (1 - se[2])
    usp <- sp[1] * sp[2]
  } else {
    use <- se
    usp <- sp
  }
  d <- ceiling(N * prev)
  n.h <- (N / use) * (1 - (1 - conf.level)^(1 / d))
  n.h <- if (n.h > N) NA_real_ else ceiling(n.h)
  n.b <- ceiling(log(1 - conf.level) / log(1 - prev * use))
  n.b <- n.b / (1 + (n.b / N))
  units <- ceiling(c(hypergeo = n.h, binom = n.b))
  list(performance = data.frame(se = use, sp = usp), sample.size = units)
}

# --- Cochran's Q test of equal proportions across k related binary measurements -----------------
# Q = (k - 1) [k sum_j C_j^2 - T^2] / (k T - sum_i R_i^2), df = k - 1, C_j column (condition) totals,
# R_i row (subject) totals, T the grand total (Cochran 1950, Biometrika 37:256-266). `y` holds the
# 0/1 outcomes, `id` the subject and `cond` the condition. Returns list(statistic, df, p).
.cf_cochran_q <- function(y, id, cond) {
  m <- tapply(y, list(id, cond), sum)
  if (anyNA(m)) return(list(statistic = NA_real_, df = ncol(m) - 1L, p = NA_real_))
  k <- ncol(m)
  C <- colSums(m); R <- rowSums(m); T <- sum(m)
  denom <- k * T - sum(R^2)
  if (denom == 0) return(list(statistic = NA_real_, df = k - 1L, p = NA_real_))
  q <- (k - 1) * (k * sum(C^2) - T^2) / denom
  list(statistic = q, df = k - 1L, p = stats::pchisq(q, k - 1L, lower.tail = FALSE))
}

# --- Hmisc replacements ---------------------------------------------------------------------------
# Bayesian assurance for a difference with sd `sd` of the estimate and prior density `prior`
# (Spiegelhalter, Abrams & Myles 2004; Hmisc::gbayes2): P(significant and delta > delta.w) =
# integral over delta > delta.w of [1 - Phi((delta.w - delta)/sd + z)] prior(delta) d delta.
.cf_gbayes2 <- function(sd, prior, delta.w = 0, alpha = 0.05, upper = Inf) {
  z <- stats::qnorm(1 - alpha / 2)
  prod <- function(delta) (1 - stats::pnorm((delta.w - delta) / sd + z)) * prior(delta)
  ip <- stats::integrate(prior, -Inf, upper)[["value"]]
  if (abs(ip - 1) > 0.01) {
    warning(paste("integrate failed to obtain 1.0 for integral of prior.\nDivided posterior probability by the integral it did obtain (",
                  format(ip), ").\nTry specifying upper=.", sep = ""))
  }
  stats::integrate(prod, delta.w, upper)[["value"]]
}

# Sample size for an ordinal response analysed by the proportional-odds model (Whitehead 1993):
# n = 3 (A + 1)^2 (z_alpha/2 + z_beta)^2 / (A log(OR)^2 (1 - sum p^3)), A = (1 - fraction)/fraction;
# `eff` is the efficiency of the ordinal categories relative to a continuous response (Hmisc::posamsize).
.cf_posamsize <- function(p, odds.ratio, fraction = 0.5, alpha = 0.05, power = 0.8) {
  p <- p[!is.na(p)]
  if (abs(sum(p) - 1) > 1e-05) stop("probabilities in p do not add up to 1")
  A <- (1 - fraction) / fraction
  log.or <- logb(odds.ratio)
  z.alpha <- stats::qnorm(1 - alpha / 2)
  z.beta <- stats::qnorm(power)
  ps <- 1 - sum(p^3)
  n <- 3 * ((A + 1)^2) * (z.alpha + z.beta)^2 / A / (log.or^2) / ps
  eff <- ps / (1 - 1 / n / n)
  list(n = n, eff = eff)
}

# Power of a two-arm survival comparison with uniform accrual, exponential survival and non-compliance
# (Hmisc::cpower, after Lachin & Foulkes 1986; Hmisc's own documentation cites them): the log hazard
# ratio is diluted linearly by the drop-in and non-adherence percentages. Returns the power.
.cf_cpower <- function(tref, n, mc, r, accrual, tmin, noncomp.c = 0, noncomp.i = 0, alpha = 0.05) {
  if (mc > 1) stop("mc should be a fraction")
  mi <- (1 - r / 100) * mc
  nc <- n / 2
  ni <- n / 2
  lamc <- -logb(1 - mc) / tref
  lami <- -logb(1 - mi) / tref
  tmax <- tmin + accrual
  pc <- if (accrual == 0) 1 - exp(-lamc * tmin) else 1 - 1 / accrual / lamc * (exp(-tmin * lamc) - exp(-tmax * lamc))
  pi <- if (accrual == 0) 1 - exp(-lami * tmin) else 1 - 1 / accrual / lami * (exp(-tmin * lami) - exp(-tmax * lami))
  mc <- pc * nc
  mi <- pi * ni
  delta <- logb(lami / lamc)
  if (noncomp.c + noncomp.i > 0) delta <- delta * (1 - (noncomp.c + noncomp.i) / 100)
  v <- 1 / mc + 1 / mi
  sd <- sqrt(v)
  z <- -stats::qnorm(alpha / 2)
  c(Power = 1 - (stats::pnorm(z - abs(delta) / sd) - stats::pnorm(-z - abs(delta) / sd)))
}

# --- tseries replacement: Wald-Wolfowitz runs test for a two-level factor ----------------------------
# Standard-normal approximation (Wald & Wolfowitz 1940): R runs, m = 1 + 2 n1 n2 / (n1 + n2),
# s^2 = 2 n1 n2 (2 n1 n2 - n1 - n2) / ((n1 + n2)^2 (n1 + n2 - 1)); two-sided p = 2 Phi(-|R - m| / s).
.cf_runs_test_p <- function(x) {
  n <- length(x)
  R <- 1 + sum(as.numeric(x[-1] != x[-n]))
  n1 <- sum(levels(x)[1] == x)
  n2 <- sum(levels(x)[2] == x)
  m <- 1 + 2 * n1 * n2 / (n1 + n2)
  s <- sqrt(2 * n1 * n2 * (2 * n1 * n2 - n1 - n2) / ((n1 + n2)^2 * (n1 + n2 - 1)))
  2 * stats::pnorm(-abs((R - m) / s))
}
