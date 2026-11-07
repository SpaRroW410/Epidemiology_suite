# Sample size of the two one-sided tests (TOST) procedure, transcribed from the PowerTOST package (ROADMAP Phase 6, dependency
# reduction). PowerTOST imports cubature, which has no WebAssembly build, so the three TOST designs could not run in the browser
# version; cubature is used only for a prior on both the CV and the ratio, which this app does not offer.
#
# Source: PowerTOST 1.5.7 (Labes D, Schuetz H, Lang B. PowerTOST: Power and Sample Size for (Bio)Equivalence Studies; GPL >= 2,
# https://github.com/Detlew/PowerTOST). The functions below are the parts of sampleN.TOST() and expsampleN.TOST() (prior on the CV
# only, method "exact") that this app calls, with their search rules, tolerances and numerical methods unchanged and the printing
# removed; the license allows reuse in this GPL-3 package. Exact power is computed with Owen's Q function (Owen DB. A special case
# of a bivariate non-central t-distribution. Biometrika 1965;52:437-446), expected power by integrating the power over the
# inverse-gamma distribution of the variance given the prior study (Julious SA, Owen RJ. Sample size calculations for clinical
# studies allowing for uncertainty about the variance. Pharm Stat 2006;5:29-37). tests/testthat/test-calc_closed_forms_tost.R
# compares the results with PowerTOST over grids of inputs; PowerTOST is kept as a verification oracle only.

# The designs this app uses (PowerTOST's design table): degrees of freedom as a function of the total n, the step of the sample
# size search, the design constant bk (variance of the difference = bk * sigma^2 / n) and bkni (the same per group size).
.tost_designs <- list(
  parallel = list(df = function(n) n - 2, steps = 2, bk = 4, bkni = 1),
  "2x2" = list(df = function(n) n - 2, steps = 2, bk = 2, bkni = 1 / 2),
  "2x2x4" = list(df = function(n) 3 * n - 4, steps = 2, bk = 1, bkni = 1 / 4),
  "2x3x3" = list(df = function(n) 2 * n - 3, steps = 3, bk = 1.5, bkni = 1 / 6)
)

.tost_design <- function(design) {
  d <- .tost_designs[[design]]
  if (is.null(d)) stop("Design ", design, " unknown!", call. = FALSE)
  d
}

.tost_cv2se <- function(CV) sqrt(log(1 + CV^2))

# smallest total n with at least 1 degree of freedom, rounded up to the design's step
.tost_nmin <- function(d) {
  n <- 0
  df <- 0
  while (df < 1) {
    n <- n + 1
    df <- d$df(n)
  }
  nmin <- as.integer(d$steps * trunc(n / d$steps))
  nmin + d$steps * (nmin < n)
}

# Owen's T function T(h, a), by Gauss quadrature (Patefield & Tandy's algorithm T1, as in PowerTOST's tfn()).
.tost_tfn <- function(x, fx) {
  r <- c(0.147762112357376, 0.134633359654998, 0.109543181257991, 0.0747256745752903, 0.0333356721543441)
  u <- c(0.0744371694908156, 0.216697697064624, 0.339704784149512, 0.432531683344492, 0.486953264258586)
  tp <- 1 / (2 * pi)
  tv2 <- 15
  tv3 <- 15
  tv4 <- 1e-05
  if (tv2 < abs(x)) return(0)
  xs <- -0.5 * x * x
  x2 <- fx
  fxs <- fx * fx
  if (tv3 <= log(1 + fxs) - xs * fxs) {
    x1 <- 0.5 * fx
    fxs <- 0.25 * fxs
    repeat {
      rt <- fxs + 1
      x2 <- x1 + (xs * fxs + tv3 - log(rt)) / (2 * x1 * (1 / rt - xs))
      fxs <- x2 * x2
      if (abs(x2 - x1) < tv4) break
      x1 <- x2
    }
  }
  r1 <- 1 + fxs * (0.5 + u)^2
  r2 <- 1 + fxs * (0.5 - u)^2
  rt <- sum(r * (exp(xs * r1) / r1 + exp(xs * r2) / r2))
  rt * x2 * tp
}

.tost_owens_t <- function(h, a) {
  eps <- .Machine$double.eps
  if (abs(a) < eps || !is.finite(h) || abs(1 - abs(a)) < eps || abs(h) < eps || !is.finite(abs(a))) {
    if (abs(a) < eps) return(0)
    if (!is.finite(h)) return(0)
    if (abs(1 - abs(a)) < eps) return(sign(a) * 0.5 * stats::pnorm(h) * (1 - stats::pnorm(h)))
    if (abs(h) < eps) return(atan(a) / 2 / pi)
    if (!is.finite(abs(a))) {
      tha <- if (h < 0) stats::pnorm(h) / 2 else (1 - stats::pnorm(h)) / 2
      return(sign(a) * tha)
    }
  }
  aa <- abs(a)
  if (aa <= 1) return(.tost_tfn(h, a))
  ah <- aa * h
  gh <- stats::pnorm(h)
  gah <- stats::pnorm(ah)
  tha <- 0.5 * (gh + gah) - gh * gah - .tost_tfn(ah, 1 / aa)
  if (a < 0) tha <- -tha
  tha
}

.tost_q_integrand <- function(x, nu, t, delta) {
  lnQconst <- -((nu / 2) - 1) * log(2) - lgamma(nu / 2)
  dens <- x
  x1 <- x[x != 0]
  dens[x != 0] <- sign(x1)^(nu - 1) * stats::pnorm(t * x1 / sqrt(nu) - delta) *
    exp((nu - 1) * log(abs(x1)) - 0.5 * x1^2 + lnQconst)
  dens
}

# Owen's Q function Q(nu, t, delta; 0, b) by Owen's (1965) recurrence (PowerTOST's OwensQOwen()).
.tost_owens_q_owen <- function(nu, t, delta, b) {
  if (!is.finite(b)) return(stats::pt(t, df = nu, ncp = delta))
  if (!is.finite(delta)) delta <- sign(delta) * 1e+20
  A <- t / sqrt(nu)
  B <- nu / (nu + t * t)
  upr <- nu - 2
  av <- numeric(nu)
  for (k in seq_along(av)) av[k] <- if (k == 1 || k == 2) 1 else 1 / ((k - 2) * av[k - 1])
  L <- numeric(max(upr - 1, 0))
  for (k in seq_along(L)) {
    L[k] <- if (k == 1) 0.5 * A * B * b * stats::dnorm(b) * stats::dnorm(A * b - delta) else av[k + 3] * b * L[k - 1]
  }
  ll <- max(upr + 1, 0)
  H <- numeric(ll)
  for (k in seq_along(H)) H[k] <- if (k == 1) -stats::dnorm(b) * stats::pnorm(A * b - delta) else av[k + 1] * b * H[k - 1]
  M <- numeric(ll)
  sB <- sqrt(B)
  for (k in seq_along(M)) {
    if (k == 1) M[1] <- A * sB * stats::dnorm(delta * sB) * (stats::pnorm(delta * A * sB) - stats::pnorm((delta * A * B - b) / sB))
    if (k == 2) M[2] <- B * (delta * A * M[1] + A * stats::dnorm(delta * sB) *
                               (stats::dnorm(delta * A * sB) - stats::dnorm((delta * A * B - b) / sB)))
    if (k > 2) M[k] <- ((k - 2) / (k - 1)) * B * (av[k - 1] * delta * A * M[k - 1] + M[k - 2]) - L[k - 2]
  }
  sumt <- 0
  if (2 * (nu %/% 2) != nu) {
    if (upr >= 1) {
      k <- seq(1, upr, by = 2)
      sumt <- sum(M[k + 1]) + sum(H[k + 1])
    }
    stats::pnorm(b) - 2 * .tost_owens_t(b, A - delta / b) - 2 * .tost_owens_t(delta * sB, (delta * A * B - b) / B / delta) +
      2 * .tost_owens_t(delta * sB, A) - (delta >= 0) + 2 * sumt
  } else {
    if (upr >= 0) {
      k <- seq(0, upr, by = 2)
      sumt <- sum(M[k + 1]) + sum(H[k + 1])
    }
    stats::pnorm(-delta) + sqrt(2 * pi) * sumt
  }
}

# Owen's Q function with integration limits 0 and b (PowerTOST's OwensQ()).
.tost_owens_q <- function(nu, t, delta, b) {
  if (b == 0) return(0)
  if (nu < 29 && abs(delta) > 37.62) {
    if (is.infinite(b)) {
      i_fun <- function(y) .tost_q_integrand(y / (1 - y), nu, t, delta) / (1 - y)^2
      return(stats::integrate(i_fun, lower = 0, upper = 1, subdivisions = 1000L, rel.tol = 1e-08, stop.on.error = TRUE)[[1]])
    }
    return(.tost_owens_q_owen(nu, t, delta, b))
  }
  if (is.infinite(b)) return(suppressWarnings(stats::pt(t, df = nu, ncp = delta)))
  i_fun <- function(y) .tost_q_integrand(b + y / (1 - y), nu, t, delta) / (1 - y)^2
  integral01 <- stats::integrate(i_fun, lower = 0, upper = 1, subdivisions = 1000L, rel.tol = 1e-08, stop.on.error = TRUE)
  suppressWarnings(stats::pt(t, df = nu, ncp = delta)) - integral01[[1]]
}

# Power of the TOST by the non-central t approximation (PowerTOST's .approx.power.TOST()).
.tost_power_nct <- function(alpha, ltheta1, ltheta2, diffm, sem, df) {
  tval <- stats::qt(1 - alpha, df)
  delta1 <- (diffm - ltheta1) / sem
  delta2 <- (diffm - ltheta2) / sem
  delta1[is.nan(delta1)] <- 0
  delta2[is.nan(delta2)] <- 0
  pow <- suppressWarnings(stats::pt(-tval[length(tval)], df, ncp = delta2) - stats::pt(tval[1], df, ncp = delta1))
  pow[pow < 0] <- 0
  pow
}

# Exact power of the TOST with Owen's Q (PowerTOST's .power.TOST()); vectorised over sem.
.tost_power_exact <- function(alpha, ltheta1, ltheta2, diffm, sem, df) {
  tval <- stats::qt(1 - alpha, df)
  dl <- length(tval)
  delta1 <- (diffm - ltheta1) / sem
  delta2 <- (diffm - ltheta2) / sem
  delta1[is.nan(delta1)] <- 0
  delta2[is.nan(delta2)] <- 0
  R <- (delta1 - delta2) * sqrt(df) / (tval[1] + tval[dl])
  R[is.nan(R)] <- 0
  R[R <= 0] <- Inf
  if (min(df) > 10000) {
    tval <- stats::qnorm(1 - alpha)
    pwr <- stats::pnorm(-tval[dl] - delta2) - stats::pnorm(tval[1] - delta1)
    pwr[pwr < 0] <- 0
    return(pwr)
  }
  if (min(df) >= 5000 && min(df <= 10000)) return(.tost_power_nct(alpha, ltheta1, ltheta2, diffm, sem, df))
  p1 <- numeric(length(delta1))
  p2 <- numeric(length(delta1))
  for (i in seq_along(delta1)) {
    p1[i] <- .tost_owens_q(df[1], tval[1], delta1[i], R[i])
    p2[i] <- .tost_owens_q(df[1], -tval[dl], delta2[i], R[i])
  }
  pwr <- p2 - p1
  pwr[pwr < 0] <- 0
  pwr
}

.tost_power <- function(alpha, ltheta1, ltheta2, diffm, sem, df, method = c("exact", "nct")) {
  if (match.arg(method) == "exact") .tost_power_exact(alpha, ltheta1, ltheta2, diffm, sem, df)
  else .tost_power_nct(alpha, ltheta1, ltheta2, diffm, sem, df)
}

# Start value of the sample size search (PowerTOST's .sampleN0_3()).
.tost_n0 <- function(alpha, targetpower, ltheta1, ltheta2, diffm, se, steps, bk) {
  locc <- (ltheta1 + ltheta2) / 2
  diffm <- diffm - locc
  ltheta1 <- ltheta1 - locc
  ltheta2 <- -ltheta1
  delta <- abs((ltheta2 - ltheta1) / 2)
  z1 <- stats::qnorm(1 - alpha)
  beta <- 1 - targetpower
  c <- abs(diffm / delta)
  p2 <- ifelse(c < 0.35, 1 - (1 - 0.5 * exp(-7.06 * c)) * beta, 1 - beta)
  z2 <- stats::qnorm(p2)
  dn <- ifelse(diffm < 0, diffm - ltheta1, diffm - ltheta2)
  n0 <- (bk / 2) * ((z1 + z2) * (se * sqrt(2) / dn))^2
  steps * trunc(n0 / steps)
}

# Total sample size and achieved power of the TOST (PowerTOST::sampleN.TOST(method = "exact", robust = FALSE)).
.tost_sample_size <- function(alpha = 0.05, targetpower = 0.8, logscale = TRUE, theta0, theta1, theta2, CV, design = "2x2",
                              imax = 100) {
  d <- .tost_design(design)
  nmin <- .tost_nmin(d)
  if (logscale) {
    if ((theta0 < theta1) || abs(theta0 - theta1) < 1e-08 || (theta0 > theta2) || abs(theta0 - theta1) < 1e-08) {
      stop("True ratio ", theta0, " not within margins ", theta1, " ... ", theta2, "!", call. = FALSE)
    }
    ltheta1 <- log(theta1)
    ltheta2 <- log(theta2)
    diffm <- log(theta0)
    se <- .tost_cv2se(CV)
  } else {
    if ((theta0 < theta1) || abs(theta0 - theta1) < 1e-08 || (theta0 > theta2) || abs(theta0 - theta2) < 1e-08) {
      stop("True diff. ", theta0, " not within margins ", theta1, " ... ", theta2, "!", call. = FALSE)
    }
    ltheta1 <- theta1
    ltheta2 <- theta2
    diffm <- theta0
    se <- CV
  }
  pw <- function(n) .tost_power(alpha, ltheta1, ltheta2, diffm, se * sqrt(d$bk / n), d$df(n))
  n <- .tost_n0(alpha, targetpower, ltheta1, ltheta2, diffm, se, d$steps, d$bk)
  if (n < nmin) n <- nmin
  pow <- pw(n)
  iter <- 0
  down <- FALSE
  up <- FALSE
  while (pow > targetpower) {
    if (n <= nmin) break
    down <- TRUE
    n <- n - d$steps
    iter <- iter + 1
    pow <- pw(n)
    if (iter > imax) break
  }
  while (pow < targetpower) {
    up <- TRUE
    down <- FALSE
    n <- n + d$steps
    iter <- iter + 1
    pow <- pw(n)
    if (iter > imax) break
  }
  if ((up && pow < targetpower && n < 10000) || (down && pow > targetpower && n < 10000)) n <- NA
  list(n = n, power = pow)
}

# PowerTOST's uniroot.step(): a root search over whole numbers in steps that first grow, then shrink.
.tost_uniroot_step <- function(f, interval, step = 2, step.power = 6, step.up = TRUE, pos.side = FALSE, maxiter = 100, ...) {
  lower <- min(interval)
  upper <- max(interval)
  iter <- 0
  if (lower >= upper) stop("lower < upper  is not fulfilled")
  step <- ceiling(step)
  step.power.stop <- 0
  if (step == 1) {
    step <- 2
    step.power.stop <- -1
  }
  if (step.up) {
    f.old <- f(lower, ...)
    sign <- 1
    xold <- lower
  } else {
    f.old <- f(upper, ...)
    sign <- -1
    xold <- upper
  }
  iter <- iter + 1
  ever.switched <- FALSE
  tried.extreme <- FALSE
  f.new <- f.old
  xnew <- xold
  f.switch <- NA
  xswitch <- NA
  while (step.power > step.power.stop) {
    if (f.old == 0) break
    if (iter >= maxiter) stop("reached maxiter without a solution")
    xnew <- xold + sign * step^step.power
    if ((step.up && xnew < upper) || (!step.up && xnew > lower)) {
      f.new <- f(xnew, ...)
      iter <- iter + 1
    } else {
      xnew <- xold
      f.new <- f.old
      step.power <- step.power - 1
      if (!tried.extreme) {
        if (step.up) {
          f.extreme <- f(upper, ...)
          x.extreme <- upper
        } else {
          f.extreme <- f(lower, ...)
          x.extreme <- lower
        }
        iter <- iter + 1
        tried.extreme <- TRUE
        xswitch <- x.extreme
        f.switch <- f.extreme
        if (f.extreme == 0) {
          xold <- x.extreme
          f.old <- f.extreme
          break
        }
        if (f.old * f.extreme >= 0) stop("f() at extremes not of opposite sign")
      }
    }
    if (f.old * f.new < 0) {
      sign <- sign * (-1)
      ever.switched <- TRUE
      xswitch <- xold
      f.switch <- f.old
    }
    if (ever.switched) {
      step.power <- step.power - 1
      if (step.power == step.power.stop) break
    } else {
      if (iter > 2) step.power <- step.power + 1
    }
    xold <- xnew
    f.old <- f.new
  }
  if (f.old == 0) {
    root <- xold
    f.root <- f.old
  } else if (f.new == 0) {
    root <- xnew
    f.root <- f.new
  } else if (isTRUE(f.switch == 0)) {
    root <- xswitch
    f.root <- f.switch
  } else if (pos.side) {
    root <- ifelse(f.new >= 0, xnew, xswitch)
    f.root <- ifelse(f.new >= 0, f.new, f.switch)
  } else {
    root <- ifelse(f.new < 0, xnew, xswitch)
    f.root <- ifelse(f.new < 0, f.new, f.switch)
  }
  list(iter = iter, f.root = f.root, root = root)
}

.tost_dinvgamma <- function(x, shape, scale = 1) {
  d <- exp(shape * log(scale) - lgamma(shape) - (shape + 1) * log(x) - (scale / x))
  d[x == 0] <- 0
  d
}

# Expected power over the uncertainty of the CV (prior: the CV estimated with df_m degrees of freedom).
.tost_exp_power <- function(alpha, ltheta1, ltheta2, ldiff, se, sefac_n, df_n, df_m, cp_method = "exact") {
  d_t <- function(v) .tost_dinvgamma(v, shape = df_m / 2, scale = df_m / 2 * se^2)
  p_t <- function(v) .tost_power(alpha, ltheta1, ltheta2, ldiff, sefac_n * sqrt(v), df_n, cp_method)
  i_fun <- function(x) p_t(x / (1 - x)) * d_t(x / (1 - x)) / (1 - x)^2
  stats::integrate(i_fun, 0, 1, rel.tol = 1e-05, stop.on.error = FALSE)$value
}

# Start value of the expected-power search (PowerTOST's .expsampleN0()).
.tost_exp_n0 <- function(alpha, targetpower, ltheta1, ltheta2, diffm, se, dfse, steps, bk) {
  z1 <- stats::qnorm(1 - alpha)
  if (abs(diffm) > 0.02) {
    tinv <- stats::qt(targetpower, dfse, z1)
  } else {
    tinv <- stats::qt(1 - (1 - targetpower) / 2, dfse, z1)
    diffm <- 0
  }
  n01 <- bk * (se * tinv / (ltheta1 - diffm))^2
  n02 <- bk * (se * tinv / (ltheta2 - diffm))^2
  n0 <- ceiling(max(n01, n02))
  steps * trunc(n0 / steps)
}

# Total sample size for an expected power, CV estimated in a prior study of m subjects in `prior_design`
# (PowerTOST::expsampleN.TOST(prior.type = "CV", prior.parm = list(m, design), method = "exact"), log scale).
.tost_exp_sample_size <- function(alpha = 0.05, targetpower = 0.8, theta0, theta1, theta2, CV, design = "2x2", m,
                                  prior_design = design) {
  if ((theta0 < theta1) || abs(theta0 - theta1) < 1e-08 || (theta0 > theta2) || abs(theta0 - theta1) < 1e-08) {
    stop("True ratio ", theta0, " not within margins ", theta1, " ... ", theta2, "!", call. = FALSE)
  }
  ltheta1 <- log(theta1)
  ltheta2 <- log(theta2)
  diffm <- log(theta0)
  se <- .tost_cv2se(CV)
  d <- .tost_design(design)
  dp <- .tost_design(prior_design)
  df_m <- dp$df(m)
  if (df_m <= 4) stop("Degrees of freedom need to be numeric and > 4.", call. = FALSE)
  nmin <- .tost_nmin(d)
  n0 <- .tost_exp_n0(alpha, targetpower, ltheta1, ltheta2, diffm, se, df_m, d$steps, d$bk)
  if (n0 < nmin) n0 <- nmin
  pdiff_n <- function(n, cp_method = "exact") {
    suppressWarnings(.tost_exp_power(alpha, ltheta1, ltheta2, diffm, se, sqrt(d$bk / n), d$df(n), df_m, cp_method)) - targetpower
  }
  exp_pow <- function(n, cp_method) pdiff_n(n, cp_method) + targetpower
  n <- n0
  pow <- exp_pow(n, "nct")
  if (pow <= targetpower) {
    search_int <- c(n0, 1e+07)
    step.up <- TRUE
  } else {
    search_int <- c(nmin, n0)
    step.up <- FALSE
  }
  if (search_int[1] != search_int[2]) {
    n <- tryCatch(
      .tost_uniroot_step(pdiff_n, search_int, step = d$steps, step.power = 2, step.up = step.up, pos.side = TRUE, cp_method = "nct"),
      error = function(e) {
        if (step.up && grepl("not of opposite sign", conditionMessage(e))) return("n>1e7")
        if (!step.up && grepl("not of opposite sign", conditionMessage(e))) return(nmin)
        NA
      })
    if (is.list(n)) n <- n$root
  }
  if (all(!is.na(n)) && !identical(n, "n>1e7")) {
    pow <- exp_pow(n, "exact")
    if (pow <= targetpower) {
      search_int <- c(n, 1e+07)
      step.up <- TRUE
    } else {
      search_int <- c(nmin, n)
      step.up <- FALSE
    }
    if (search_int[1] != search_int[2]) {
      n <- tryCatch(
        .tost_uniroot_step(pdiff_n, search_int, step = d$steps, step.power = 1, step.up = step.up, pos.side = TRUE, cp_method = "exact"),
        error = function(e) if (!step.up && grepl("not of opposite sign", conditionMessage(e))) nmin else NA)
      if (all(!is.na(n))) {
        if (is.list(n)) {
          pow <- n$f.root + targetpower
          n <- n$root
        } else {
          pow <- exp_pow(n, "exact")
        }
      }
    }
  }
  if (is.na(n) || identical(n, "n>1e7")) return(list(n = NA, power = NA))
  list(n = n, power = pow)
}
