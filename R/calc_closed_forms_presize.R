# Precision-based sample sizes that used to come from the `presize` package (ROADMAP item 16, dependency reduction, stage 2).
# Each function is the part of the presize function (0.3.11) that this app called, with the same search intervals and tolerances, so
# results equal the package's; tests/testthat/test-calc_closed_forms_presize.R compares them over grids of inputs (presize is a
# verification oracle only). Sources, as given in presize's documentation and the module content files (none of the originals was
# read here): Newcombe RG (1998) and Koopman PAR (1984) for the risk-ratio interval; Gart & Nam (1988) and Woolf (1955) for the odds
# ratio; Simel, Samsa & Matchar (1991) for likelihood ratios; Zou GY (2012) and Bonett DG (2002) for the intraclass correlation and
# Cronbach's alpha; Bland & Altman (1986) for the limits of agreement.
# Two differences from the package, both corrections:
#  * presize::prec_pos_lr() and prec_neg_lr() accept `conf.level` but do not pass it on to prec_lr(), so the confidence level was
#    silently always 95%. Here it is used (the app's likelihood-ratio design therefore changes for any level other than 95%).
#  * Cohen's kappa: the `kappaSize` package's cell probabilities are re-derived below (4 Nov 2026), so kappaSize is only a test
#    oracle now (Suggests).

.cf_cw_error <- function(conf.width, ref) if (conf.width < ref) "'conf.width' too small" else "'conf.width' too wide"

# --- one incidence rate: x events needed (or the interval width for x events) -----------------------------------------------
.cf_prec_rate <- function(r, x = NULL, conf.width = NULL, conf.level = 0.95, method = c("score", "vs", "exact", "wald")) {
  method <- match.arg(method)
  if (is.null(x) == is.null(conf.width)) stop("exactly one of 'x', and 'conf.width' must be NULL")
  alpha <- (1 - conf.level) / 2
  z <- stats::qnorm(1 - alpha); z2 <- z * z
  half <- function(x) switch(method, score = z * sqrt(r * (4 + z2 / x)) / sqrt(4 * x / r), vs = z * r * sqrt(1 / x), wald = z * r * sqrt(1 / x))
  exact_ci <- function(x) {
    t <- x / r
    lwr <- stats::qgamma(alpha, x) / t; upr <- stats::qgamma(1 - alpha, x + 1) / t
    list(lwr = lwr, upr = upr, ps = (upr - lwr) / 2)
  }
  solved <- is.null(x)
  if (solved) {
    prec <- conf.width * 0.5
    x <- tryCatch(switch(method,
      wald = (z * r / prec)^2, vs = (z * r / prec)^2,
      score = stats::uniroot(function(x) half(x) - prec, c(1, 1e+07))$root,
      exact = stats::uniroot(function(x) exact_ci(x)$ps - prec, c(1, 1e+07))$root),
      error = function(e) stop(.cf_cw_error(conf.width, r), call. = FALSE))
  }
  if (method == "exact") {
    ci <- exact_ci(x)
    radj <- r; lwr <- ci$lwr; upr <- ci$upr
    if (!solved) conf.width <- upr - lwr
  } else {
    if (!solved) prec <- half(x)
    radj <- switch(method, wald = r, score = r + z2 * r / (2 * x), vs = r * (1 + z2 / (4 * x)))
    lwr <- radj - prec; upr <- radj + prec
    conf.width <- 2 * prec
  }
  list(r = r, radj = radj, x = x, time = x / r, conf.width = conf.width, conf.level = conf.level, lwr = lwr, upr = upr)
}

# --- risk ratio (Koopman score or Katz log interval) -----------------------------------------------------------------------
.cf_prec_riskratio <- function(p1, p2, n1 = NULL, r = 1, conf.width = NULL, conf.level = 0.95, method = c("koopman", "katz")) {
  method <- match.arg(method)
  if (is.null(n1) == is.null(conf.width)) stop("exactly one of 'n1', and 'conf.width' must be NULL")
  rr <- p1 / p2
  alpha <- 1 - conf.level
  z <- stats::qnorm(1 - alpha / 2)
  if (method == "koopman") {
    fkp <- function(n1) {
      zchi <- stats::qchisq(conf.level, 1)
      n2 <- n1 * r; x1 <- n1 * p1; x2 <- n2 * p2
      midp <- min(rr)
      if (x2 == 0) { upr <- Inf; midp <- 1e+07 }
      if (x1 == 0) { lwr <- 0; midp <- 0.1 }
      kp <- function(phi) {
        A <- phi * (n1 + x2) + x1 + n2
        pp <- (A - sqrt(A^2 - 4 * phi * (n1 + n2) * (x1 + x2))) / (2 * (n1 + n2))
        (x1 - n1 * pp)^2 / (n1 * pp * (1 - pp)) * (1 + n1 * (phi - pp) / (n2 * (1 - pp)))
      }
      if (x2 > 0) upr <- stats::uniroot(function(phi) kp(phi) - zchi, c(midp, 1e+07), extendInt = "upX")$root
      if (x1 > 0) lwr <- stats::uniroot(function(phi) kp(phi) - zchi, c(0, midp), extendInt = "downX")$root
      c(lwr, upr)
    }
    if (is.null(n1)) {
      n1 <- tryCatch(stats::uniroot(function(n1) { ci <- fkp(n1); ci[2] - ci[1] - conf.width }, c(2, 1e+07))$root,
                     error = function(e) stop(.cf_cw_error(conf.width, p1), call. = FALSE))
    }
    ci <- fkp(n1); lwr <- ci[1]; upr <- ci[2]; conf.width <- upr - lwr
  } else {
    kt <- function(n1) {
      n2 <- n1 * r
      prec <- z * sqrt((1 - p1) / (n1 * p1) + (1 - p2) / (n2 * p2))
      list(upr = rr * exp(prec), lwr = rr / exp(prec), cw = rr * exp(prec) - rr / exp(prec))
    }
    if (is.null(n1)) {
      n1 <- tryCatch(stats::uniroot(function(n1) kt(n1)$cw - conf.width, c(2, 1e+07))$root,
                     error = function(e) stop(.cf_cw_error(conf.width, p1), call. = FALSE))
    }
    ci <- kt(n1); lwr <- ci$lwr; upr <- ci$upr; conf.width <- ci$cw
  }
  list(p1 = p1, p2 = p2, n1 = n1, n2 = n1 * r, ntot = n1 + n1 * r, r = r, rr = rr, lwr = lwr, upr = upr, conf.width = conf.width, conf.level = conf.level)
}

# --- odds ratio (Woolf, Gart, or independence-smoothed) --------------------------------------------------------------------
.cf_prec_or <- function(p1, p2, n1 = NULL, r = 1, conf.width = NULL, conf.level = 0.95, method = c("indip_smooth", "gart", "woolf")) {
  method <- match.arg(method)
  if (is.null(n1) == is.null(conf.width)) stop("exactly one of 'n1', and 'conf.width' must be NULL")
  or <- (p1 / (1 - p1)) / (p2 / (1 - p2))
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  cells <- function(n1) {
    n2 <- n1 * r
    x1 <- p1 * n1; x2 <- p2 * n2; y1 <- n1 - x1; y2 <- n2 - x2
    m1 <- x1 + x2; m2 <- y1 + y2; n <- n1 + n2
    add <- switch(method, woolf = c(0, 0, 0, 0), gart = rep(0.5, 4),
                  indip_smooth = c(2 * n1 * m1 / n^2, 2 * n2 * m1 / n^2, 2 * n1 * m2 / n^2, 2 * n2 * m2 / n^2))
    x1. <- x1 + add[1]; x2. <- x2 + add[2]; y1. <- y1 + add[3]; y2. <- y2 + add[4]
    theta <- (x1. * y2.) / (x2. * y1.)
    prec <- z * sqrt(1 / x1. + 1 / y1. + 1 / x2. + 1 / y2.)
    lwr <- exp(log(theta) - prec); upr <- exp(log(theta) + prec)
    list(lwr = lwr, upr = upr, cw = upr - lwr, n2 = n2)
  }
  if (is.null(n1)) {
    n1 <- tryCatch(stats::uniroot(function(n1) cells(n1)$cw - conf.width, c(1, 1e+07))$root,
                   error = function(e) stop(.cf_cw_error(conf.width, p1), call. = FALSE))
  }
  ci <- cells(n1)
  list(p1 = p1, p2 = p2, n1 = n1, n2 = ci$n2, ntot = n1 + ci$n2, r = r, or = or, lwr = ci$lwr, upr = ci$upr,
       conf.width = if (is.null(conf.width)) ci$cw else conf.width, conf.level = conf.level)
}

# --- rate ratio: n1 for a precision level (upper / lower limit ratio), or the precision level for n1 ----------------------
.cf_prec_rateratio <- function(n1 = NULL, rate1, rate2, prec.level = NULL, r = 1, conf.level = 0.95) {
  if (is.null(n1) == is.null(prec.level)) stop("exactly one of 'n1', and 'prec.level' must be NULL")
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  if (is.null(prec.level)) {
    prec.level <- exp(((2 * z) * sqrt(r * rate2 + rate1)) / sqrt(n1 * (r * rate1 * rate2)))
  } else {
    n1 <- ((4 * z^2) * (r * rate2 + rate1)) / (r * rate2 * rate1 * (log(1 / prec.level))^2)
  }
  n2 <- n1 * r
  rr <- rate1 / rate2
  sd <- sqrt(1 / (n1 * rate1) + 1 / (n2 * rate2))
  list(n1 = n1, n2 = n2, r = r, ntot = n1 + n2, rate1 = rate1, rate2 = rate2, rr = rr, lwr = exp(log(rr) - z * sd),
       upr = exp(log(rr) + z * sd), prec.level = prec.level, conf.level = conf.level)
}

# --- likelihood ratio (Simel, Samsa & Matchar 1991): n for a confidence-interval width ---------------------------------------
.cf_prec_lr <- function(prev, p1, p2, n = NULL, conf.width = NULL, conf.level = 0.95) {
  if (is.null(n) == is.null(conf.width)) stop("exactly one of 'n', and 'conf.width' must be NULL")
  ci <- function(n) {
    n1 <- n * prev; n2 <- n - n1
    lr <- p1 / p2
    se <- sqrt(((1 - p1) / (p1 * n1)) + ((1 - p2) / (p2 * n2)))
    lwr <- exp(log(lr) + stats::qnorm((1 - conf.level) / 2) * se)
    upr <- exp(log(lr) + stats::qnorm(1 - (1 - conf.level) / 2) * se)
    list(n1 = n1, n2 = n2, lr = lr, lwr = lwr, upr = upr, cw = upr - lwr)
  }
  if (is.null(n)) {
    n <- tryCatch(stats::uniroot(function(n) ci(n)$cw - conf.width, c(1, 1e+07))$root,
                  error = function(e) stop(.cf_cw_error(conf.width, p1), call. = FALSE))
  }
  v <- ci(n)
  list(prev = prev, p1 = p1, p2 = p2, n = n, n1 = v$n1, n2 = v$n2, lr = v$lr, lwr = v$lwr, upr = v$upr,
       conf.width = if (is.null(conf.width)) v$cw else conf.width, conf.level = conf.level)
}
.cf_prec_pos_lr <- function(prev, sens, spec, n = NULL, conf.width = NULL, conf.level = 0.95) .cf_prec_lr(prev, sens, 1 - spec, n, conf.width, conf.level)
.cf_prec_neg_lr <- function(prev, sens, spec, n = NULL, conf.width = NULL, conf.level = 0.95) .cf_prec_lr(prev, 1 - sens, spec, n, conf.width, conf.level)

# --- intraclass correlation (n subjects, k raters), Cronbach's alpha, limits of agreement ----------------------------------
.cf_prec_icc <- function(rho, k, n = NULL, conf.width = NULL, conf.level = 0.95) {
  if (is.null(n) == is.null(conf.width)) stop("exactly one of 'n', and 'conf.width' must be NULL")
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  if (is.null(n)) n <- 8 * z^2 * (1 - rho)^2 * (1 + (k - 1) * rho)^2 / (k * (k - 1) * conf.width^2) + 1
  n <- n + (k == 2 & rho >= 0.7) * 5 * rho
  if (is.null(conf.width)) conf.width <- sqrt(8) * z * (1 - rho) * (1 + (k - 1) * rho) / sqrt(k * (k - 1) * (n - 1))
  list(rho = rho, k = k, n = ceiling(n), conf.width = conf.width, conf.level = conf.level)
}
.cf_prec_cronb <- function(k, calpha, n = NULL, conf.level = 0.95, conf.width = NULL) {
  if (is.null(n) == is.null(conf.width)) stop("exactly one of 'n', and 'conf.width' must be NULL")
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  limits <- function(n) {
    b <- log(n / (n - 1)); s <- z * sqrt(2 * k / ((k - 1) * (n - 2)))
    c(1 - exp(log(1 - calpha) - b + s), 1 - exp(log(1 - calpha) - b - s))
  }
  if (is.null(conf.width)) {
    l <- limits(n); conf.width <- l[2] - l[1]
  } else {
    n0 <- ceiling((8 * k / (k - 1)) * (1 - calpha)^2 * (z / conf.width)^2 + 2)
    l <- limits(n0)
    n <- ceiling((n0 - 2) * ((l[2] - l[1]) / conf.width)^2 + 2)
  }
  list(calpha = calpha, k = k, n = n, conf.width = conf.width, conf.level = conf.level, lwr = l[1], upr = l[2])
}
.cf_prec_lim_agree <- function(n = NULL, conf.width = NULL, conf.level = 0.95) {
  if (is.null(n) == is.null(conf.width)) stop("exactly one of 'n', and 'conf.width' must be NULL")
  z <- stats::qnorm(1 - (1 - conf.level) / 2) * 2
  if (is.null(conf.width)) conf.width <- z * sqrt(3 / n) else n <- 3 / (conf.width / z)^2
  list(n = n, conf.width = conf.width, conf.level = conf.level)
}

# --- Cohen's kappa: n for a confidence-interval width (the kappaSize CI functions, re-derived; 4 Nov 2026) -------------------
# kappaSize::CIBinary / CI3Cats / CI4Cats / CI5Cats write out, for 2-6 raters, the cell probabilities of a goodness-of-fit approach.
# Expanded, they follow two patterns (checked against the package for every number of categories and raters):
# - two categories: every split x = (x_1, x_2) of the k raters is a cell, with the common-correlation model: with probability kappa all
#   raters give the same category, otherwise they rate independently:
#     P(x) = (1 - kappa) * binomial(x; k, p) + kappa * p_j * [all k ratings in category j];
# - three or more categories: one cell for "all k raters chose category j" (j = 1..c), with the Dirichlet-multinomial probability
#     P_j = prod_{i=0}^{k-1} (p_j + i * kappa * (1 - p_j)) / (1 + (i - 1) * kappa) [the i = 0 and i = 1 denominators are 1],
#   that is prod (alpha p_j + i) / (alpha + i) with alpha = (1 - kappa) / kappa, and one cell for everything else (1 - sum P_j).
# For two raters both patterns give the same answer.
# The sample size is the smallest n (from 11, as kappaSize) at which the chi-square distance between the cell counts expected under
# kappa0 and under each bound, n * sum((P0 - P1)^2 / P1), reaches the critical value plus 0.001 (kappaSize's own stopping rule).
# test-calc_closed_forms_presize.R checks it against kappaSize (now only a test oracle) for 2-5 categories and 2-6 raters.
.kappa_splits <- function(raters, n_cat) {
  if (n_cat == 1) return(matrix(raters, 1, 1))
  do.call(rbind, lapply(raters:0, function(x1) cbind(x1, .kappa_splits(raters - x1, n_cat - 1))))
}
.kappa_cell_probs <- function(kappa, props, splits) {
  raters <- sum(splits[1, ])
  indep <- apply(splits, 1, function(x) stats::dmultinom(x, prob = props))
  agree <- apply(splits, 1, function(x) if (max(x) == raters) props[which.max(x)] else 0)
  (1 - kappa) * indep + kappa * agree
}
# all k raters in category j, Dirichlet-multinomial with intraclass correlation kappa: prod_{i=0}^{k-1} (alpha p_j + i) / (alpha + i)
.kappa_unanimous_dm <- function(kappa, props, raters) {
  vapply(props, function(p) prod(vapply(0:(raters - 1), function(i) (p * (1 - kappa) + i * kappa) / ((1 - kappa) + i * kappa), numeric(1))), numeric(1))
}
.kappa_ci_n <- function(kappa0, kappaL, kappaU = NA, props, raters = 2, alpha = 0.05) {
  if (!raters %in% 2:6) stop("this design is for 2 to 6 raters")
  if (length(props) == 1) props <- c(props, 1 - props)
  if (abs(sum(props) - 1) >= 0.001 || any(props <= 0) || any(props >= 1)) stop("the category proportions must each lie in (0, 1) and sum to 1")
  crit <- if (is.na(kappaU)) stats::qchisq(1 - 2 * alpha, 1) else stats::qchisq(1 - alpha, 1)
  cells <- if (length(props) == 2) {
    splits <- .kappa_splits(raters, 2)
    function(k) .kappa_cell_probs(k, props, splits)
  } else {
    function(k) { u <- .kappa_unanimous_dm(k, props, raters); c(1 - sum(u), u) }
  }
  P0 <- cells(kappa0)
  dist <- function(k1) {
    P1 <- cells(k1)
    d <- (P0 - P1)^2 / P1
    sum(d[is.finite(d)])
  }
  D <- c(dist(kappaL), if (!is.na(kappaU)) dist(kappaU))
  if (any(D <= 0)) stop("'conf.width' too wide", call. = FALSE)
  n <- 11
  repeat { if (all(n * D >= crit + 0.001)) break; n <- max(n + 1, ceiling((crit + 0.001) / min(D)) - 1) }
  n
}
.cf_prec_kappa <- function(kappa, raters = 2, n_category = 2, props, conf.width, conf.level = 0.95) {
  if (n_category < 2) stop("there must be at least 2 outcome categories")
  if (n_category > 5) stop("more than 5 outcome categories is not supported")
  alpha <- 1 - conf.level
  kL <- kappa - conf.width / 2; kU <- kappa + conf.width / 2
  if (kL <= 0 || kU >= 1) stop("'conf.width' too wide", call. = FALSE)
  n <- .kappa_ci_n(kappa0 = kappa, kappaL = kL, kappaU = kU, props = props, raters = raters, alpha = alpha * 2)
  list(kappa = kappa, n = n, lwr = kL, upr = kU, conf.width = conf.width, conf.level = conf.level)
}
