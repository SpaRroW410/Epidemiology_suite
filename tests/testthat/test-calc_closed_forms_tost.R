# The TOST sample sizes transcribed from PowerTOST (R/calc_closed_forms_tost.R) against PowerTOST itself (a verification oracle).

test_that("TOST sample size and power equal PowerTOST::sampleN.TOST() (untransformed parallel and log-scale crossovers)", {
  skip_if_not_installed("PowerTOST")
  cases <- list(
    list(FALSE, 0.05, -0.2, 0.2, 0.3, "parallel", 0.05, 0.8),
    list(FALSE, 0.3, -1, 1, 1.5, "parallel", 0.025, 0.9),
    list(FALSE, -0.1, -0.5, 0.5, 0.9, "parallel", 0.05, 0.8),
    list(TRUE, 0.95, 0.8, 1.25, 0.3, "2x2", 0.05, 0.8),
    list(TRUE, 1.05, 0.8, 1.25, 0.45, "2x2x4", 0.05, 0.9),
    list(TRUE, 0.9, 0.8, 1.25, 0.2, "2x3x3", 0.05, 0.8),
    list(TRUE, 1, 0.8, 1.25, 0.1, "2x2", 0.025, 0.8)
  )
  for (cs in cases) {
    ref <- PowerTOST::sampleN.TOST(alpha = cs[[7]], targetpower = cs[[8]], logscale = cs[[1]], theta0 = cs[[2]], theta1 = cs[[3]],
                                   theta2 = cs[[4]], CV = cs[[5]], design = cs[[6]], print = FALSE)
    me <- .tost_sample_size(cs[[7]], cs[[8]], cs[[1]], cs[[2]], cs[[3]], cs[[4]], cs[[5]], cs[[6]])
    expect_equal(me$n, ref[["Sample size"]], info = paste(cs, collapse = " "))
    expect_equal(me$power, ref[["Achieved power"]], tolerance = 1e-12, info = paste(cs, collapse = " "))
  }
})

test_that("expected-power sample size equals PowerTOST::expsampleN.TOST(prior.type = 'CV')", {
  skip_if_not_installed("PowerTOST")
  cases <- list(list(0.3, 0.95, "2x2", 30, 0.8), list(0.2, 1.05, "2x2x4", 16, 0.9), list(0.4, 0.92, "2x3x3", 24, 0.8),
                list(0.15, 1, "2x2", 12, 0.8))
  for (cs in cases) {
    ref <- suppressMessages(PowerTOST::expsampleN.TOST(alpha = 0.05, targetpower = cs[[5]], theta0 = cs[[2]], theta1 = 0.8,
                                                       theta2 = 1.25, CV = cs[[1]], design = cs[[3]], prior.type = "CV",
                                                       prior.parm = list(m = cs[[4]], design = cs[[3]]), print = FALSE))
    me <- .tost_exp_sample_size(0.05, cs[[5]], cs[[2]], 0.8, 1.25, cs[[1]], cs[[3]], cs[[4]])
    expect_equal(me$n, ref[["Sample size"]], info = paste(cs, collapse = " "))
    expect_equal(me$power, ref[["Achieved power"]], tolerance = 1e-12, info = paste(cs, collapse = " "))
  }
})

test_that("Owen's Q and T pieces agree with PowerTOST's own functions", {
  skip_if_not_installed("PowerTOST")
  for (h in c(-2, 0.3, 1.7)) for (a in c(-3, -0.4, 0.6, 2.5)) expect_equal(.tost_owens_t(h, a), PowerTOST::OwensT(h, a), tolerance = 1e-14)
  for (nu in c(3, 8, 27, 40)) for (d in c(-1, 2.5, 40)) {
    expect_equal(.tost_owens_q(nu, 1.7, d, 3), PowerTOST::OwensQ(nu, 1.7, d, 0, 3), tolerance = 1e-12, info = paste(nu, d))
  }
})
