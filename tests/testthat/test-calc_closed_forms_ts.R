# The TrialSize-free formulas must equal the TrialSize functions they replace, over grids of inputs. TrialSize is an oracle only.
skip_if_not_installed("TrialSize")
near <- function(a, b, info = NULL) expect_equal(unname(a), unname(b), tolerance = 1e-12, info = info)
grid <- expand.grid(alpha = c(0.01, 0.025, 0.05), beta = c(0.1, 0.2))

test_that("McNemar, crossover and pairwise ANOVA formulas equal TrialSize", {
  for (i in seq_len(nrow(grid))) {
    a <- grid$alpha[i]; b <- grid$beta[i]
    for (psai in c(1.5, 2.5, 4)) for (paid in c(0.1, 0.3))
      near(.cf_ts_mcnemar(a, b, psai, paid), TrialSize::McNemar.Test(a, b, psai, paid), paste("mcnemar", a, b, psai, paid))
    near(.cf_ts_crossover_equality(a, b, 0.4, 0.2), TrialSize::TwoSampleCrossOver.Equality(a, b, 0.4, 0.2))
    for (tau in c(1, 3, 6)) {
      near(.cf_ts_anova_pairwise(a, b, tau, 1.5, 1), TrialSize::OneWayANOVA.pairwise(a, b, tau, 1.5, 1))
      near(.cf_ts_anova_pairwise_prop(a, b, tau, 0.5, 0.35, 0.15), TrialSize::OneWayANOVA.PairwiseComparison(a, b, tau, 0.5, 0.35, 0.15))
    }
  }
})

test_that("propensity-score, trend and dose-response formulas equal TrialSize", {
  for (i in seq_len(nrow(grid))) {
    a <- grid$alpha[i]; b <- grid$beta[i]
    aa <- c(0.2, 0.3, 0.3, 0.2); bb <- c(0.3, 0.45, 0.6, 0.75)
    for (p1 in c(0.1, 0.3)) for (phi in c(1.5, 2.2)) {
      near(.cf_ts_ps_strata(a, b, 4, aa, bb, p1, phi), TrialSize::Propensity.Score.strata(a, b, 4, aa, bb, p1, phi))
      near(.cf_ts_ps_nostrata(a, b, 4, aa, bb, p1, phi), TrialSize::Propensity.Score.nostrata(a, b, 4, aa, bb, p1, phi))
    }
    for (delta in c(0, 1)) near(.cf_ts_cochran_armitage(a, b, c(0.1, 0.2, 0.3, 0.4), c(0, 1, 2, 3), c(1, 1, 1, 1), delta),
                                TrialSize::Cochran.Armitage.Trend(a, b, c(0.1, 0.2, 0.3, 0.4), c(0, 1, 2, 3), c(1, 1, 1, 1), delta))
    near(.cf_ts_dose_response_linear(a, b, 2, c(1, 1.5, 2, 2.6), c(-3, -1, 1, 3), c(1, 1, 1, 1)),
         TrialSize::Dose.Response.Linear(a, b, 2, c(1, 1.5, 2, 2.6), c(-3, -1, 1, 3), c(1, 1, 1, 1)))
  }
})

test_that("non-inferiority and nonparametric formulas equal TrialSize", {
  for (i in seq_len(nrow(grid))) {
    a <- grid$alpha[i]; b <- grid$beta[i]
    for (k in c(1, 2)) near(.cf_ts_rr_nis(a, b, 1.2, k, 0.6, 0.65, -0.3), TrialSize::RelativeRisk.NIS(a, b, 1.2, k, 0.6, 0.65, -0.3))
    near(.cf_ts_cox_nis(a, b, log(1.1), 0.5, 0.7, log(1.3)), TrialSize::Cox.NIS(a, b, log(1.1), 0.5, 0.7, log(1.3)))
    for (k in c(1, 2)) near(.cf_ts_nonpara_two(a, b, k, 0.35, 0.2, 0.18), TrialSize::Nonpara.Two.Sample(a, b, k, 0.35, 0.2, 0.18))
    near(.cf_ts_nonpara_one(a, b, 0.3, 0.2, 0.1), TrialSize::Nonpara.One.Sample(a, b, 0.3, 0.2, 0.1))
    near(.cf_ts_nonpara_indep(a, b, 0.7, 0.6), TrialSize::Nonpara.Independ(a, b, 0.7, 0.6))
  }
})

test_that("survival and matched case-control formulas equal powerSurvEpi", {
  skip_if_not_installed("powerSurvEpi")
  for (pw in c(0.8, 0.9)) for (al in c(0.025, 0.05)) {
    for (k in c(1, 2)) for (hr in c(0.5, 0.7, 1.6)) near(.cf_pse_ssize_ct(pw, k, 0.6, 0.8, hr, al), powerSurvEpi::ssizeCT.default(pw, k, 0.6, 0.8, hr, al), paste("ct", pw, al, k, hr))
    for (theta in c(1.5, 2)) for (rho2 in c(0, 0.3)) {
      near(.cf_pse_ssize_epi(pw, theta, 0.4, 0.5, rho2, al), powerSurvEpi::ssizeEpi.default(pw, theta, 0.4, 0.5, rho2, al))
      near(.cf_pse_ssize_epi_cont(pw, theta, 1.5, 0.5, rho2, al), powerSurvEpi::ssizeEpiCont.default(pw, theta, 1.5, 0.5, rho2, al))
    }
    g <- c(0.3, 0.7); P <- c(0.5, 0.4); l0 <- c(0.2, 0.35)
    near(.cf_pse_ssize_stratify(pw, 3, g, P, 0.7, l0, al), powerSurvEpi::ssize.stratify(pw, 3, g, P, 0.7, l0, al, verbose = FALSE))
    for (OR in c(1.8, 3)) for (nD in c(1, 2)) for (nH in c(1, 3)) for (R2 in c(0, 0.2)) {
      near(.cf_pse_conlogistic_bin(pw, OR, 0.3, nD, nH, R2, al), powerSurvEpi::powerConLogistic.bin(N = NULL, power = pw, OR = OR, pE = 0.3, nD = nD, nH = nH, R2 = R2, alpha = al))
      near(.cf_pse_conlogistic_con(pw, OR, 1.2, nD, nH, R2, al), powerSurvEpi::powerConLogistic.con(N = NULL, power = pw, OR = OR, sigma = 1.2, nD = nD, nH = nH, R2 = R2, alpha = al))
    }
  }
})
