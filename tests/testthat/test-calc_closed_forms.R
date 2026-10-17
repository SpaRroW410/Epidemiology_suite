# The epiR-free closed forms must reproduce the epiR (2.0.67) / rstatix functions they replace, bit for
# bit up to floating-point noise, over grids of inputs. The packages are oracles only.
skip_if_not_installed("epiR")

near <- function(a, b, info = NULL) expect_equal(unname(unlist(a)), unname(unlist(b)), tolerance = 1e-12, info = info)

test_that("one-mean precision equals epi.sssimpleestc()", {
  for (N in list(NA, 500, 5000)) for (err in c("relative", "absolute")) for (cl in c(0.9, 0.95, 0.99))
    for (cfg in list(c(50, 12, 0.1), c(10, 3, 0.05), c(120, 40, 2))) {
      eps <- if (err == "absolute") cfg[3] * cfg[1] / 10 else cfg[3]
      a <- .cf_sssimpleestc(N, cfg[1], cfg[2], eps, err, cl)
      b <- epiR::epi.sssimpleestc(N = N, xbar = cfg[1], sigma = cfg[2], epsilon = eps, error = err, nfractional = FALSE, conf.level = cl)
      near(a, b, paste(N, err, cl, paste(cfg, collapse = "/")))
    }
})

test_that("non-inferiority (means and proportions) and proportion equivalence equal epiR", {
  for (r in c(1, 2, 0.5)) for (alpha in c(0.025, 0.05)) for (pw in c(0.8, 0.9)) {
    a <- .cf_ssninfc(treat = 10, control = 10.5, sigma = 3, delta = 1.5, power = pw, r = r, alpha = alpha)
    b <- epiR::epi.ssninfc(treat = 10, control = 10.5, sigma = 3, delta = 1.5, n = NA, power = pw, r = r, nfractional = FALSE, alpha = alpha)
    near(a, b[c("n.total", "n.treat", "n.control")])
    a <- .cf_ssninfb(treat = 0.65, control = 0.7, delta = 0.1, power = pw, r = r, alpha = alpha)
    b <- epiR::epi.ssninfb(treat = 0.65, control = 0.7, delta = 0.1, n = NA, power = pw, r = r, nfractional = FALSE, alpha = alpha)
    near(a, b[c("n.total", "n.treat", "n.control")])
    a <- .cf_ssequb_equivalence(treat = 0.6, control = 0.62, delta = 0.1, power = pw, r = r, alpha = alpha)
    b <- epiR::epi.ssequb(treat = 0.6, control = 0.62, delta = 0.1, n = NA, power = pw, r = r, type = "equivalence", nfractional = FALSE, alpha = alpha)
    near(a, b[c("n.total", "n.treat", "n.control")])
  }
  expect_error(.cf_ssninfc(10, 10, 3, -1, 0.8, 1, 0.05), "greater than or equal to zero")
  expect_error(.cf_ssninfb(0.5, 0.7, 0.1, 0.8, 1, 0.05), "not reachable")
  expect_error(.cf_ssequb_equivalence(0.6, 0.6, 0, 0.8, 1, 0.05), "greater than zero")
})

test_that("case-control sample sizes (unmatched and matched) equal epi.sscc()", {
  for (OR in c(1.5, 2, 3.5, 0.5)) for (p0 in c(0.1, 0.3)) for (r in c(1, 2, 4)) for (sd in c(1, 2)) for (N in list(NA, 3000)) {
    a <- .cf_sscc_unmatched(N, OR, p0, 0.8, r, 1, sd, 0.95)
    b <- epiR::epi.sscc(N = N, OR = OR, p1 = NA, p0 = p0, n = NA, power = 0.8, r = r, phi.coef = 0, design = 1, sided.test = sd,
                        nfractional = FALSE, conf.level = 0.95, method = "unmatched", fleiss = FALSE)
    near(a, b[c("n.total", "n.case", "n.control")], paste("unmatched", OR, p0, r, sd))
  }
  for (OR in c(2, 3)) for (p0 in c(0.2, 0.4)) for (r in c(1, 2, 3)) for (phi in c(0, 0.2)) {
    a <- .cf_sscc_matched(NA, OR, p0, 0.9, r, phi, 1, 2, 0.95)
    b <- epiR::epi.sscc(N = NA, OR = OR, p1 = NA, p0 = p0, n = NA, power = 0.9, r = r, phi.coef = phi, design = 1, sided.test = 2,
                        nfractional = FALSE, conf.level = 0.95, method = "matched", fleiss = FALSE)
    near(a, b[c("n.total", "n.case", "n.control")], paste("matched", OR, p0, r, phi))
  }
})

test_that("cohort sample size equals epi.sscohortc(), with and without a finite population", {
  for (cfg in list(c(0.25, 0.1), c(0.05, 0.02), c(0.3, 0.45))) for (r in c(1, 2, 3)) for (N in list(NA, 2000)) for (sd in c(1, 2)) {
    a <- .cf_sscohortc(N, cfg[1], cfg[2], 0.8, r, 1, sd, 0.95)
    b <- epiR::epi.sscohortc(N = N, irexp1 = cfg[1], irexp0 = cfg[2], pexp = NA, n = NA, power = 0.8, r = r, design = 1, sided.test = sd,
                             finite.correction = !is.na(N), nfractional = FALSE, conf.level = 0.95)
    near(a, b[c("n.total", "n.exp1", "n.exp0", "irr")], paste(cfg, r, N, sd))
  }
})

test_that("two-stage cluster survey sizes equal epi.ssclus2estb(), constant and variable cluster size", {
  for (b in list(10, 20, c(15, 5), c(8, 8))) for (err in c("relative", "absolute")) for (rho in c(0.02, 0.2)) for (Npsu in list(NA, 400)) {
    eps <- if (err == "relative") 0.2 else 0.05
    a <- suppressWarnings(.cf_ssclus2estb(Npsu, b, 0.3, eps, err, rho, 0.95))
    f <- suppressWarnings(epiR::epi.ssclus2estb(N.psu = Npsu, b = b, Py = 0.3, epsilon = eps, error = err, rho = rho, conf.level = 0.95))
    near(a[c("n.psu", "n.ssu", "DEF")], f[c("n.psu", "n.ssu", "DEF")], paste(b, err, rho, Npsu))
  }
  expect_warning(.cf_ssclus2estb(NA, 10, 0.5, 0.5, "relative", 0.01, 0.95), "recommended")
})

test_that("detecting a case with an imperfect test equals epi.ssdetect() (hypergeometric and binomial sizes, combined Se/Sp)", {
  for (N in c(100, 1000, 20000)) for (prev in c(0.01, 0.05)) for (cl in c(0.9, 0.95)) {
    for (cfg in list(list(0.9, 1), list(c(0.9, 0.95), c(1, 0.85)))) for (int in c("series", "parallel")) {
      a <- .cf_ssdetect(N, prev, cfg[[1]], cfg[[2]], int, cl)
      b <- epiR::epi.ssdetect(N = N, prev = prev, se = cfg[[1]], sp = cfg[[2]], interpretation = int, covar = c(0, 0),
                              finite.correction = TRUE, nfractional = FALSE, conf.level = cl)
      near(a$sample.size, b$sample.size, paste(N, prev, cl, int))
      near(a$performance, b$performance)
    }
  }
})

test_that("Cochran's Q equals rstatix::cochran_qtest() on random related binary data (statistic, df and p)", {
  skip_if_not_installed("rstatix")
  set.seed(4)
  for (rep in 1:25) {
    n <- sample(10:60, 1); k <- sample(3:5, 1)
    df <- .simulate_cochran_q(n, p = sort(runif(k, 0.2, 0.8)), sigma2_subject = runif(1, 0.1, 2))
    mine <- .cf_cochran_q(df$y, df$id, df$cond)
    ref <- rstatix::cochran_qtest(df, y ~ cond | id)
    expect_equal(mine$statistic, unname(ref$statistic), tolerance = 1e-10)
    expect_equal(mine$df, unname(ref$df))
    expect_equal(mine$p, unname(ref$p), tolerance = 1e-10)
  }
  # degenerate data (all subjects identical) has no defined statistic
  expect_true(is.na(.cf_cochran_q(rep(1, 12), rep(1:4, 3), factor(rep(1:3, each = 4)))$p))
})
