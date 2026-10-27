# The presize-free precision formulas must equal presize 0.3.11 over grids of inputs (the package is an oracle only), except for
# the likelihood-ratio confidence level, which presize ignores (checked separately against prec_lr()).
skip_if_not_installed("presize")
near <- function(a, b, info = NULL) expect_equal(unname(unlist(a)), unname(unlist(b)), tolerance = 1e-10, info = info)

test_that("rate precision equals prec_rate for every method, in both directions", {
  for (m in c("score", "vs", "exact", "wald")) for (r in c(0.02, 0.5, 3)) for (cl in c(0.9, 0.95)) for (cwf in c(0.5, 1.5)) {
    cw <- r * cwf
    a <- .cf_prec_rate(r, conf.width = cw, conf.level = cl, method = m)
    b <- presize::prec_rate(r, conf.width = cw, conf.level = cl, method = m)
    near(c(a$x, a$lwr, a$upr, a$conf.width, a$radj), c(b$x, b$lwr, b$upr, b$conf.width, b$radj), paste(m, r, cl, cwf))
    x <- ceiling(a$x)
    a2 <- .cf_prec_rate(r, x = x, conf.level = cl, method = m); b2 <- presize::prec_rate(r, x = x, conf.level = cl, method = m)
    near(c(a2$conf.width, a2$lwr, a2$upr), c(b2$conf.width, b2$lwr, b2$upr), paste("x", m, r, cl, cwf))
  }
  expect_error(.cf_prec_rate(1, conf.width = 1e-9, method = "wald"), NA)      # wald has a closed form: no root search to fail
})

test_that("risk ratio, odds ratio and rate ratio precision equal presize (n for a width, and the width for n)", {
  for (cfg in list(c(0.3, 0.2), c(0.1, 0.05), c(0.5, 0.4))) for (r in c(1, 2)) for (cl in c(0.9, 0.95)) for (cw in c(0.5, 1)) {
    for (m in c("koopman", "katz")) {
      a <- .cf_prec_riskratio(cfg[1], cfg[2], r = r, conf.width = cw, conf.level = cl, method = m)
      b <- presize::prec_riskratio(cfg[1], cfg[2], r = r, conf.width = cw, conf.level = cl, method = m)
      near(c(a$n1, a$n2, a$lwr, a$upr), c(b$n1, b$n2, b$lwr, b$upr), paste("rr", m, paste(cfg, collapse = "/"), r, cl, cw))
      n1 <- ceiling(a$n1)
      near(.cf_prec_riskratio(cfg[1], cfg[2], n1 = n1, r = r, conf.level = cl, method = m)$conf.width,
           presize::prec_riskratio(cfg[1], cfg[2], n1 = n1, r = r, conf.level = cl, method = m)$conf.width)
    }
    for (m in c("indip_smooth", "gart", "woolf")) {
      a <- .cf_prec_or(cfg[1], cfg[2], r = r, conf.width = cw * 2, conf.level = cl, method = m)
      b <- presize::prec_or(cfg[1], cfg[2], r = r, conf.width = cw * 2, conf.level = cl, method = m)
      near(c(a$n1, a$n2, a$lwr, a$upr), c(b$n1, b$n2, b$lwr, b$upr), paste("or", m, paste(cfg, collapse = "/"), r, cl, cw))
      n1 <- ceiling(a$n1)
      near(.cf_prec_or(cfg[1], cfg[2], n1 = n1, r = r, conf.level = cl, method = m)$conf.width,
           presize::prec_or(cfg[1], cfg[2], n1 = n1, r = r, conf.level = cl, method = m)$conf.width)
    }
  }
  for (r1 in c(0.5, 2)) for (r2 in c(1, 4)) for (r in c(1, 2)) for (pl in c(1.5, 2)) {
    a <- .cf_prec_rateratio(rate1 = r1, rate2 = r2, prec.level = pl, r = r); b <- presize::prec_rateratio(rate1 = r1, rate2 = r2, prec.level = pl, r = r)
    near(c(a$n1, a$lwr, a$upr), c(b$n1, b$lwr, b$upr))
    n1 <- ceiling(a$n1)
    near(.cf_prec_rateratio(n1 = n1, rate1 = r1, rate2 = r2, r = r)$prec.level, presize::prec_rateratio(n1 = n1, rate1 = r1, rate2 = r2, r = r)$prec.level)
  }
  expect_error(.cf_prec_riskratio(0.3, 0.2, conf.width = 1e-9), "too small")
})

test_that("likelihood-ratio precision equals prec_lr, and (unlike prec_pos_lr / prec_neg_lr) honours the confidence level", {
  for (prev in c(0.1, 0.4)) for (se in c(0.7, 0.9)) for (sp in c(0.8, 0.95)) for (cw in c(1, 3)) {
    a <- .cf_prec_pos_lr(prev, se, sp, conf.width = cw, conf.level = 0.95)
    near(c(a$n, a$n1, a$n2, a$lr, a$lwr, a$upr), { b <- presize::prec_pos_lr(prev, se, sp, conf.width = cw); c(b$n, b$n1, b$n2, b$lr, b$lwr, b$upr) }, paste("pos", prev, se, sp, cw))
    a <- .cf_prec_neg_lr(prev, se, sp, conf.width = cw / 4, conf.level = 0.95)
    near(c(a$n, a$lwr, a$upr), { b <- presize::prec_neg_lr(prev, se, sp, conf.width = cw / 4); c(b$n, b$lwr, b$upr) }, paste("neg", prev, se, sp, cw))
  }
  # a 90% interval is narrower, so fewer subjects are needed: prec_lr() (which does take conf.level) agrees, prec_pos_lr() does not
  a90 <- .cf_prec_pos_lr(0.2, 0.8, 0.9, conf.width = 1, conf.level = 0.90)$n
  near(a90, presize::prec_lr(prev = 0.2, p1 = 0.8, p2 = 0.1, conf.width = 1, conf.level = 0.90)$n)
  expect_lt(a90, .cf_prec_pos_lr(0.2, 0.8, 0.9, conf.width = 1, conf.level = 0.95)$n)
  expect_equal(presize::prec_pos_lr(0.2, 0.8, 0.9, conf.width = 1, conf.level = 0.90)$n, presize::prec_pos_lr(0.2, 0.8, 0.9, conf.width = 1)$n)   # the package ignores the level
})

test_that("ICC, Cronbach's alpha and limits-of-agreement precision equal presize", {
  for (rho in c(0.3, 0.75, 0.9)) for (k in c(2, 3, 5)) for (cw in c(0.1, 0.2)) for (cl in c(0.9, 0.95)) {
    near(.cf_prec_icc(rho, k, conf.width = cw, conf.level = cl)$n, presize::prec_icc(rho, k, conf.width = cw, conf.level = cl)$n, paste("icc", rho, k, cw, cl))
    n <- 60
    near(.cf_prec_icc(rho, k, n = n, conf.level = cl)$conf.width, presize::prec_icc(rho, k, n = n, conf.level = cl)$conf.width)
  }
  for (k in c(3, 8)) for (ca in c(0.7, 0.9)) for (cw in c(0.1, 0.2)) for (cl in c(0.9, 0.95)) {
    a <- .cf_prec_cronb(k, ca, conf.width = cw, conf.level = cl); b <- presize::prec_cronb(k, ca, conf.width = cw, conf.level = cl)
    near(c(a$n, a$lwr, a$upr), c(b$n, b$lwr, b$upr), paste("cronb", k, ca, cw, cl))
    near(.cf_prec_cronb(k, ca, n = 150, conf.level = cl)$conf.width, presize::prec_cronb(k, ca, n = 150, conf.level = cl)$conf.width)
  }
  for (cw in c(0.5, 1, 2)) for (cl in c(0.9, 0.95)) {
    near(.cf_prec_lim_agree(conf.width = cw, conf.level = cl)$n, presize::prec_lim_agree(conf.width = cw, conf.level = cl)$n)
    near(.cf_prec_lim_agree(n = 100, conf.level = cl)$conf.width, presize::prec_lim_agree(n = 100, conf.level = cl)$conf.width)
  }
})

test_that("kappa sample size equals presize::prec_kappa (kappaSize is still used underneath)", {
  skip_if_not_installed("kappaSize")
  for (nc in 2:4) for (raters in c(2, 3)) for (cw in c(0.15, 0.25)) {
    props <- switch(nc - 1, c(0.4, 0.6), c(0.3, 0.3, 0.4), c(0.2, 0.3, 0.3, 0.2))
    a <- .cf_prec_kappa(0.7, raters, nc, props, cw); b <- presize::prec_kappa(kappa = 0.7, conf.width = cw, raters = raters, n_category = nc, props = props)
    near(c(a$n, a$lwr, a$upr), c(b$n, b$lwr, b$upr), paste("kappa", nc, raters, cw))
  }
})
