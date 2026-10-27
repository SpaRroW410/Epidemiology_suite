# The pwr-free power functions must reproduce pwr's sample sizes and powers (same interval, same tolerance), over grids of
# inputs. pwr is an oracle only.
skip_if_not_installed("pwr")

near <- function(a, b, info = NULL) expect_equal(unname(a), unname(b), tolerance = 1e-12, info = info)

test_that("t tests (one-sample, two-sample, paired; all alternatives) equal pwr.t.test: n from power and power from n", {
  for (type in c("two.sample", "one.sample", "paired")) for (alt in c("two.sided", "less", "greater"))
    for (d in c(0.2, 0.5, 0.8, 1.2)) for (alpha in c(0.01, 0.05)) for (pw in c(0.8, 0.9)) {
      dd <- if (alt == "less") -d else d
      info <- paste(type, alt, d, alpha, pw)
      near(.cf_pwr_t_test(d = dd, sig.level = alpha, power = pw, type = type, alternative = alt)$n,
           pwr::pwr.t.test(d = dd, sig.level = alpha, power = pw, type = type, alternative = alt)$n, info)
      near(.cf_pwr_t_test(n = 30, d = dd, sig.level = alpha, type = type, alternative = alt)$power,
           pwr::pwr.t.test(n = 30, d = dd, sig.level = alpha, type = type, alternative = alt)$power, info)
    }
})

test_that("unequal-group t test equals pwr.t2n.test", {
  for (alt in c("two.sided", "less", "greater")) for (n1 in c(10, 40, 100)) for (d in c(0.4, 0.8)) for (pw in c(0.8, 0.9)) {
    dd <- if (alt == "less") -d else d
    a <- tryCatch(.cf_pwr_t2n_test(n1 = n1, d = dd, power = pw, alternative = alt)$n2, error = function(e) "error")
    b <- tryCatch(pwr::pwr.t2n.test(n1 = n1, d = dd, power = pw, alternative = alt)$n2, error = function(e) "error")
    if (identical(b, "error")) expect_identical(a, "error", info = paste("unreachable power", alt, n1, d, pw))   # n1 too small for this power
    else near(a, b, paste(alt, n1, d, pw))
  }
  near(.cf_pwr_t2n_test(n1 = 30, n2 = 50, d = 0.5)$power, pwr::pwr.t2n.test(n1 = 30, n2 = 50, d = 0.5)$power)
})

test_that("ANOVA, regression (f2) and chi-square power equal pwr", {
  for (k in c(2, 3, 5)) for (f in c(0.1, 0.25, 0.4)) for (pw in c(0.8, 0.9)) {
    near(.cf_pwr_anova_test(k = k, f = f, power = pw)$n, pwr::pwr.anova.test(k = k, f = f, power = pw)$n, paste("anova", k, f, pw))
  }
  near(.cf_pwr_anova_test(k = 4, n = 20, f = 0.3)$power, pwr::pwr.anova.test(k = 4, n = 20, f = 0.3)$power)
  for (u in c(1, 3, 8)) for (f2 in c(0.02, 0.15, 0.35)) for (pw in c(0.8, 0.9)) {
    near(.cf_pwr_f2_test(u = u, f2 = f2, power = pw)$v, pwr::pwr.f2.test(u = u, f2 = f2, power = pw)$v, paste("f2", u, f2, pw))
  }
  near(.cf_pwr_f2_test(u = 3, v = 60, f2 = 0.1)$power, pwr::pwr.f2.test(u = 3, v = 60, f2 = 0.1)$power)
  for (df in c(1, 2, 4, 9)) for (w in c(0.1, 0.3, 0.5)) for (pw in c(0.8, 0.9)) {
    near(.cf_pwr_chisq_test(w = w, df = df, power = pw)$N, pwr::pwr.chisq.test(w = w, df = df, power = pw)$N, paste("chisq", df, w, pw))
  }
  near(.cf_pwr_chisq_test(w = 0.3, N = 100, df = 3)$power, pwr::pwr.chisq.test(w = 0.3, N = 100, df = 3)$power)
})

test_that("correlation power equals pwr.r.test for every alternative", {
  for (alt in c("two.sided", "less", "greater")) for (r in c(0.1, 0.3, 0.5, 0.7)) for (alpha in c(0.01, 0.05)) for (pw in c(0.8, 0.9)) {
    rr <- if (alt == "less") -r else r
    near(.cf_pwr_r_test(r = rr, sig.level = alpha, power = pw, alternative = alt)$n,
         pwr::pwr.r.test(r = rr, sig.level = alpha, power = pw, alternative = alt)$n, paste(alt, r, alpha, pw))
  }
  near(.cf_pwr_r_test(n = 50, r = 0.3)$power, pwr::pwr.r.test(n = 50, r = 0.3)$power)
})

test_that("one- and two-proportion arcsine power and the effect sizes equal pwr", {
  for (alt in c("two.sided", "less", "greater")) for (h in c(0.2, 0.5, 0.8)) for (pw in c(0.8, 0.9)) {
    hh <- if (alt == "less") -h else h
    near(.cf_pwr_p_test(h = hh, power = pw, alternative = alt)$n, pwr::pwr.p.test(h = hh, power = pw, alternative = alt)$n, paste("p", alt, h, pw))
    near(.cf_pwr_2p_test(h = hh, power = pw, alternative = alt)$n, pwr::pwr.2p.test(h = hh, power = pw, alternative = alt)$n, paste("2p", alt, h, pw))
  }
  near(.cf_pwr_2p_test(h = 0.4, n = 80)$power, pwr::pwr.2p.test(h = 0.4, n = 80)$power)
  for (p1 in c(0.1, 0.35, 0.8)) for (p2 in c(0.05, 0.5)) near(.cf_es_h(p1, p2), pwr::ES.h(p1, p2))
  near(.cf_es_w1(c(0.5, 0.3, 0.2), c(0.4, 0.4, 0.2)), pwr::ES.w1(c(0.5, 0.3, 0.2), c(0.4, 0.4, 0.2)))
  P <- matrix(c(0.2, 0.1, 0.15, 0.3, 0.05, 0.2), 2, byrow = TRUE)
  near(.cf_es_w2(P), pwr::ES.w2(P))
})

test_that("misuse is refused like pwr does", {
  expect_error(.cf_pwr_t_test(d = 0.5), "exactly one")
  expect_error(.cf_pwr_t_test(n = 20, d = 0.5, power = 0.8), "exactly one")
  expect_error(.cf_pwr_t_test(d = 0.5, sig.level = 2, power = 0.8), "sig.level")
  expect_error(.cf_pwr_r_test(n = 3, r = 0.3), "at least 4")
  expect_error(.cf_pwr_anova_test(k = 1, f = 0.2, power = 0.8), "at least 2")
})

test_that("logistic and Poisson regression sizes equal powerMediation", {
  skip_if_not_installed("powerMediation")
  for (p1 in c(0.1, 0.3)) for (p2 in c(0.2, 0.45)) for (B in c(0.2, 0.5)) for (pw in c(0.8, 0.9)) for (al in c(0.01, 0.05)) {
    expect_identical(.cf_size_logistic_bin(p1, p2, B, al, pw), powerMediation::SSizeLogisticBin(p1, p2, B, al, pw))
  }
  for (p1 in c(0.05, 0.2, 0.5)) for (OR in c(0.6, 1.5, 2.5)) for (pw in c(0.8, 0.9)) {
    expect_identical(.cf_size_logistic_con(p1, OR, 0.05, pw), powerMediation::SSizeLogisticCon(p1, OR, 0.05, pw))
  }
  for (b0 in c(0.1, -1)) for (b1 in c(0.5, 0.2, -0.3)) for (mu in c(0, 1)) for (s2 in c(1, 2.5)) for (phi in c(1, 2)) {
    expect_identical(.cf_size_poisson(b0, b1, mu, s2, 1.5, phi, 0.05, 0.8), powerMediation::sizePoisson(b0, b1, mu, s2, 1.5, phi, 0.05, 0.8))
  }
  expect_equal(.cf_size_poisson(0.1, 0.5, 0, 1, 1, 1, 0.05, 0.8), 28)     # the package's documented example
})

test_that("ROC sample sizes (single curve and two correlated curves, full and partial AUC) equal pROC::power.roc.test", {
  skip_if_not_installed("pROC")
  for (auc in c(0.6, 0.73, 0.85, 0.95)) for (k in c(0.5, 1, 2)) for (pw in c(0.8, 0.9)) for (al in c(0.01, 0.05)) {
    a <- .cf_pwr_roc_auc(auc, al, pw, k); b <- pROC::power.roc.test(auc = auc, sig.level = al, power = pw, kappa = k)
    near(c(a$ncases, a$ncontrols), c(b$ncases, b$ncontrols), paste("one curve", auc, k, pw, al))
  }
  for (cfg in list(c(1.5, 0.8, 1.0, 0.9), c(0.9, 1, 1.4, 1.2))) for (rn in c(0, 0.4)) for (ra in c(0.2, 0.6)) for (k in c(1, 1.5)) {
    pl <- list(A1 = cfg[1], B1 = cfg[2], A2 = cfg[3], B2 = cfg[4], rn = rn, ra = ra, delta = 0.05)
    a <- .cf_pwr_roc_two(cfg[1], cfg[2], cfg[3], cfg[4], rn, ra, 0.05, 0.05, 0.8, k)
    b <- pROC::power.roc.test(pl, sig.level = 0.05, power = 0.8, kappa = k)
    near(c(a$ncases, a$ncontrols), c(b$ncases, b$ncontrols), paste("two curves", paste(cfg, collapse = "/"), rn, ra, k))
    pp <- c(pl, list(FPR11 = 0, FPR12 = 0.2, FPR21 = 0, FPR22 = 0.2))
    a <- .cf_pwr_roc_two(cfg[1], cfg[2], cfg[3], cfg[4], rn, ra, 0.05, 0.05, 0.8, k, 0, 0.2, 0, 0.2)
    b <- pROC::power.roc.test(pp, sig.level = 0.05, power = 0.8, kappa = k)
    near(c(a$ncases, a$ncontrols), c(b$ncases, b$ncontrols), paste("partial", paste(cfg, collapse = "/"), rn, ra, k))
  }
})
