sel <- function(r) attr(r, "selection")
frame_of <- function(r) attr(r, "frame")

test_that("SRS: exactly n distinct units in range, sorted, reproducible from the seed, caller's RNG untouched", {
  r <- calc_survey_select_srs(500, 40, seed = 3, labels = paste0("U", 1:500))
  s <- sel(r)
  expect_equal(nrow(s), 40); expect_false(anyDuplicated(s$position) > 0); expect_equal(s$position, sort(s$position))
  expect_true(all(s$position >= 1 & s$position <= 500)); expect_equal(s$unit, paste0("U", s$position))
  expect_equal(unique(s$inclusion_probability), 40 / 500); expect_equal(unique(s$design_weight), 12.5)
  expect_identical(sel(calc_survey_select_srs(500, 40, seed = 3)), sel(calc_survey_select_srs(500, 40, seed = 3))[, names(sel(calc_survey_select_srs(500, 40, seed = 3)))])
  expect_false(identical(s$position, sel(calc_survey_select_srs(500, 40, seed = 4))$position))
  set.seed(1); a <- runif(2); set.seed(1); invisible(calc_survey_select_srs(500, 40, seed = 3)); expect_identical(runif(2), a)
})

test_that("SRS: every unit has inclusion probability n/N (simulation over seeds)", {
  cnt <- tabulate(unlist(lapply(1:6000, function(s) sel(calc_survey_select_srs(30, 6, seed = s))$position)), 30)
  expect_lt(max(abs(cnt / 6000 - 6 / 30)), 0.03)
})

test_that("systematic: n units even with a fractional interval, evenly spaced, inclusion probability n/N", {
  r <- calc_survey_select_systematic(100, 10, seed = 5)
  p <- sel(r)$position
  expect_equal(length(unique(p)), 10); expect_equal(diff(p), rep(10, 9))        # whole interval: constant spacing
  expect_equal(r$interval, 10)
  r2 <- calc_survey_select_systematic(100, 12, seed = 5)
  p2 <- sel(r2)$position
  expect_equal(length(unique(p2)), 12); expect_true(all(p2 >= 1 & p2 <= 100)); expect_true(all(diff(p2) %in% c(8, 9)))   # interval 8.33
  expect_equal(p2, ceiling(r2$random_start + (0:11) * r2$interval))
  cnt <- tabulate(unlist(lapply(1:6000, function(s) sel(calc_survey_select_systematic(20, 6, seed = s))$position)), 20)
  expect_lt(max(abs(cnt / 6000 - 6 / 20)), 0.03)
  expect_identical(sel(calc_survey_select_systematic(100, 12, seed = 9)), sel(calc_survey_select_systematic(100, 12, seed = 9)))
})

test_that("PPS systematic: n units, none twice, Horvitz-Thompson total of sizes equals the frame total exactly", {
  set.seed(7)
  for (i in 1:60) {
    N <- sample(10:80, 1); x <- round(rlnorm(N, 6, 1)) + 1; n <- sample(2:min(12, N - 1), 1)
    for (ro in c(FALSE, TRUE)) {
      r <- calc_survey_select_pps(x, n, seed = i, randomize_order = ro)
      s <- sel(r)
      expect_equal(nrow(s), n); expect_false(anyDuplicated(s$position) > 0)
      expect_equal(r$ht_total_size, sum(x), tolerance = 1e-9)                  # sum of size / pi over the sample = X
      expect_true(all(frame_of(r)$inclusion_probability <= 1 + 1e-12))
      expect_equal(sum(frame_of(r)$inclusion_probability), n, tolerance = 1e-9)
    }
  }
})

test_that("PPS: certainty units are found iteratively and taken with probability 1", {
  r <- calc_survey_select_pps(c(100, 60, 10, 10, 10, 10), 3, seed = 1)       # 100 >= 200/3; then 60 >= 100/2
  f <- frame_of(r)
  expect_equal(which(f$certainty), c(1, 2)); expect_true(all(f$selected[1:2])); expect_equal(r$n_certainty, 2)
  expect_equal(sum(f$selected), 3)
  expect_equal(f$inclusion_probability[3:6], rep(0.25, 4))                   # one unit left to select among four equal ones
  # everything certain: the whole frame
  all_c <- calc_survey_select_pps(c(10, 10, 10), 3, seed = 1)
  expect_equal(nrow(sel(all_c)), 3)
  expect_error(calc_survey_select_pps(c(10, 10, 10), 4, seed = 1), "Cannot select")
})

test_that("PPS: empirical inclusion probabilities follow n * size / total (simulation over seeds)", {
  x <- c(50, 120, 30, 200, 80, 20, 150, 60, 90, 40)
  r0 <- calc_survey_select_pps(x, 4, seed = 1)
  pi <- frame_of(r0)$inclusion_probability
  cnt <- tabulate(unlist(lapply(1:8000, function(s) sel(calc_survey_select_pps(x, 4, seed = s, randomize_order = TRUE))$position)), 10)
  expect_lt(max(abs(cnt / 8000 - pi)), 0.025)
})

test_that("PPS systematic equals sampling::UPsystematic() (Madow) for the same random start", {
  skip_if_not_installed("sampling")
  set.seed(12)
  for (i in 1:60) {
    N <- sample(8:60, 1); n <- sample(2:6, 1)
    x <- round(runif(N, 20, 100))
    pik <- n * x / sum(x)
    if (any(pik >= 1)) next
    set.seed(1000 + i); u <- runif(1)
    mine <- .survey_pps_hits(x, n, u)
    set.seed(1000 + i); theirs <- sampling::UPsystematic(pik)
    expect_equal(as.numeric(mine), as.numeric(theirs), info = paste(i, N, n))
  }
})

test_that("EPI 30 x 7: 30 clusters, 210 subjects, reproducible; too few villages is an error", {
  set.seed(3); sizes <- round(runif(120, 200, 3000))
  r <- calc_survey_epi_clusters(sizes, 30, 7, seed = 11, labels = paste("Village", 1:120))
  expect_equal(r$clusters, 30); expect_equal(r$total_sample, 210); expect_equal(nrow(sel(r)), 30)
  expect_equal(r$ht_total_size, sum(sizes), tolerance = 1e-9)
  expect_identical(sel(r), sel(calc_survey_epi_clusters(sizes, 30, 7, seed = 11, labels = paste("Village", 1:120))))
  expect_error(calc_survey_epi_clusters(sizes[1:20], 30, 7, seed = 1), "Cannot select")
  expect_match(survey_selection_methods_text(r), "30 clusters selected with probability proportional to size")
})

test_that("selection input is validated", {
  expect_error(calc_survey_select_srs(100, 0, seed = 1), "whole number")
  expect_error(calc_survey_select_srs(100, 101, seed = 1), "Cannot select")
  expect_error(calc_survey_select_srs(100, 10), "seed")
  expect_error(calc_survey_select_systematic(1, 1, seed = 1), "frame size")
  expect_error(calc_survey_select_pps(c(10, -1, 5), 2, seed = 1), "positive size")
  expect_error(calc_survey_select_pps(c(10, 5), 1, seed = 1, labels = "a"), "one label per unit")
})

# ---- weights ---------------------------------------------------------------------------------------
test_that("weights: base weight N/n, adjusted weight N/r, weights sum to the population, response rates", {
  r <- calc_survey_weights(c(500, 300, 200), c(50, 50, 40), c(40, 30, 35))
  tb <- attr(r, "classes")
  expect_equal(tb$design_weight, c(10, 6, 5)); expect_equal(tb$response_rate, c(0.8, 0.6, 0.875))
  expect_equal(tb$adjusted_weight, c(500, 300, 200) / c(40, 30, 35))
  expect_equal(r$sum_of_adjusted_weights, 1000)
  expect_equal(r$unweighted_response_rate, 105 / 140); expect_equal(r$weighted_response_rate, 0.755)
  expect_equal(r$respondents_total, 105)
})

test_that("Kish effective sample size and the design effect of weighting (1 + CV^2)", {
  expect_equal(calc_survey_effective_n(c(1, 1, 2, 2))$effective_sample_size, 3.6)
  e <- calc_survey_effective_n(c(1, 1, 1, 1)); expect_equal(e$effective_sample_size, 4); expect_equal(e$design_effect_weighting, 1)
  set.seed(2); w <- runif(50, 0.5, 4); e <- calc_survey_effective_n(w)
  expect_equal(e$design_effect_weighting, e$one_plus_cv_squared, tolerance = 1e-12)
  expect_equal(e$design_effect_weighting, 50 * sum(w^2) / sum(w)^2, tolerance = 1e-12)
  # the class-based function agrees with the vector version on the expanded respondent weights
  r <- calc_survey_weights(c(500, 300, 200), c(50, 50, 40), c(40, 30, 35))
  tb <- attr(r, "classes")
  expanded <- rep(tb$adjusted_weight, tb$responded)
  ev <- calc_survey_effective_n(expanded)
  expect_equal(r$effective_sample_size, ev$effective_sample_size, tolerance = 1e-12)
  expect_equal(r$design_effect_weighting, ev$design_effect_weighting, tolerance = 1e-12)
  expect_equal(r$cv_weights, ev$cv_weights, tolerance = 1e-12)
})

test_that("weights (simulation): the adjusted-weight estimator of a total is nearly unbiased under response that differs by class", {
  set.seed(31)
  Npop <- c(4000, 2500, 1500); mu <- c(10, 20, 40); resp_p <- c(0.9, 0.6, 0.4); nsamp <- c(200, 150, 100)
  pop <- lapply(1:3, function(h) rnorm(Npop[h], mu[h], 5)); truth <- sum(vapply(pop, sum, 0))
  est <- replicate(2500, {
    tot <- 0; r <- integer(3); ys <- vector("list", 3)
    for (h in 1:3) { s <- sample.int(Npop[h], nsamp[h]); ok <- runif(nsamp[h]) < resp_p[h]; r[h] <- sum(ok); ys[[h]] <- pop[[h]][s][ok] }
    if (any(r < 1)) return(NA_real_)
    w <- calc_survey_weights(Npop, nsamp, r)
    sum(vapply(1:3, function(h) attr(w, "classes")$adjusted_weight[h] * sum(ys[[h]]), 0))
  })
  expect_lt(abs(mean(est, na.rm = TRUE) / truth - 1), 0.01)
  # ignoring nonresponse (base weights only) is clearly biased when response and outcome are related
  naive <- replicate(500, {
    sum(vapply(1:3, function(h) { s <- sample.int(Npop[h], nsamp[h]); ok <- runif(nsamp[h]) < resp_p[h]; (Npop[h] / nsamp[h]) * sum(pop[[h]][s][ok]) }, 0))
  })
  expect_gt(abs(mean(naive) / truth - 1), 0.2)
})

test_that("weights input is validated", {
  expect_error(calc_survey_weights(c(100, 50), c(10, 10), c(5, 0)), "no respondents")
  expect_error(calc_survey_weights(c(100, 50), c(10, 60), c(5, 5)), "no more than the population")
  expect_error(calc_survey_weights(c(100, 50), c(10, 10), c(11, 5)), "cannot exceed")
  expect_error(calc_survey_weights(c(100, 50), c(10), c(5, 5)), "each class")
  expect_error(calc_survey_effective_n(c(1, -2, 3)), "positive weights")
})
