# Background computation of the Monte Carlo calculators (R/background.R): the daemons must give exactly the session's result.

skip_if_no_background <- function() {
  skip_on_cran()
  skip_if_not_installed("mirai")
  skip_if_not(background_available(), "background computation not available here")
}

wait_for <- function(p) {
  out <- NULL
  promises::then(p, function(v) out <<- v)
  t0 <- Sys.time()
  while (is.null(out) && Sys.time() - t0 < 120) later::run_now(0.1)
  out
}

test_that("a calculation in a daemon gives exactly the result of the same call in the session", {
  skip_if_no_background()
  withr::defer(background_stop())
  expect_true(.bg_start())
  cases <- list(
    list("calc_ks_two_sample", list(effect_size = 0.8, nsim = 200, seed = 1)),
    list("calc_wald_wolfowitz_runs", list(effect_size = 0.8, nsim = 200, seed = 3)),
    list("calc_rmst_comparison", list(ac_period = 35, tot_time = 510, tau = 500, scale0 = 8500, scale1 = 8500, margin = 18,
                                      power = 0.8, nsim = 50)),
    list("calc_glmm_lmm_power", list(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.8, power = 0.8, nsim = 10, seed = 1))
  )
  for (cs in cases) {
    res <- wait_for(.bg_submit(cs[[1]], cs[[2]]))
    expect_true(isTRUE(res$ok), info = cs[[1]])
    expect_identical(res$value, suppressWarnings(do.call(cs[[1]], cs[[2]])), info = cs[[1]])
  }
})

test_that("an error in a daemon comes back as the calculator's message", {
  skip_if_no_background()
  withr::defer(background_stop())
  expect_true(.bg_start())
  res <- wait_for(.bg_submit("calc_ks_two_sample", list(effect_size = -1, nsim = 200)))
  expect_false(res$ok)
  expect_match(res$message, "effect_size")
})

test_that("with no workers the calculation runs in the session", {
  withr::local_envvar(EPIDEMIOLOGYSUITE_WORKERS = "0")
  expect_equal(background_workers(), 0L)
  expect_false(background_available())
  bg <- shiny::isolate(background_calc(session = shiny::MockShinySession$new()))
  expect_false(bg$active)
  expect_identical(bg$calc("calc_ks_two_sample", effect_size = 0.8, nsim = 200, seed = 1),
                   calc_ks_two_sample(effect_size = 0.8, nsim = 200, seed = 1))
})

test_that("the number of workers is read from the environment, then the option, else 1", {
  withr::local_envvar(EPIDEMIOLOGYSUITE_WORKERS = "")
  withr::local_options(epidemiologysuite.workers = NULL)
  expect_equal(background_workers(), 1L)
  withr::local_options(epidemiologysuite.workers = 3)
  expect_equal(background_workers(), 3L)
  withr::local_envvar(EPIDEMIOLOGYSUITE_WORKERS = "2")
  expect_equal(background_workers(), 2L)
  withr::local_envvar(EPIDEMIOLOGYSUITE_WORKERS = "many")
  expect_equal(background_workers(), 1L)
})

test_that("in the browser build a simulation runs only when Calculate is pressed, and a calculated result is reused", {
  memo_clear()
  session <- shiny::MockShinySession$new()
  bc <- .browser_calc("calculate", session)
  args <- list(effect_size = 0.8, nsim = 200, seed = 1)
  first <- shiny::isolate(do.call(bc$calc, c("calc_ks_two_sample", args)))
  expect_s3_class(first, "epidemiologysuite_pending")          # opened, nothing pressed: nothing runs
  expect_equal(memo_size(), 0L)
  session$setInputs(calculate = 1L)
  second <- shiny::isolate(do.call(bc$calc, c("calc_ks_two_sample", args)))
  expect_identical(second, do.call(calc_ks_two_sample, args))
  other <- shiny::isolate(bc$calc("calc_ks_two_sample", effect_size = 0.5, nsim = 200, seed = 1))
  expect_s3_class(other, "epidemiologysuite_pending")          # new inputs, no new press
  again <- shiny::isolate(do.call(bc$calc, c("calc_ks_two_sample", args)))
  expect_identical(again, second)                               # already calculated: shown at once
  memo_clear()
})
