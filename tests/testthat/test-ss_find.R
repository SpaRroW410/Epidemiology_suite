test_that("ss_find finds designs by the words in their name, calculator or question, best match first", {
  r <- ss_find("eyes per patient")
  expect_s3_class(r, "data.frame")
  expect_named(r, c("key", "design", "calculator", "answers"))
  expect_true(all(startsWith(r$key[1:3], "patient_units_")))
  expect_equal(ss_find("stepped wedge", n = 1)$key, "stepped_wedge_normal")
  expect_true("agreement_kappa" %in% ss_find("kappa")$key)
})

test_that("ss_find needs every word, ignores case and punctuation, and returns nothing for nonsense", {
  expect_equal(nrow(ss_find("zzzzqqq")), 0)
  expect_equal(ss_find("EYES, per Patient!")$key, ss_find("eyes per patient")$key)
  expect_lt(nrow(ss_find("eyes per patient")), nrow(ss_find("patient")))
})

test_that("ss_find with no query lists every built design once, and n limits the rows", {
  all <- ss_find(n = Inf)
  built <- Filter(function(e) isTRUE(e$built), calculator_catalog)
  expect_equal(nrow(all), length(built))
  expect_false(anyDuplicated(all$key) > 0)
  expect_equal(nrow(ss_find(n = 3)), 3)
})

test_that("a sample-size calculator is listed before an analysis tool on equal matches", {
  expect_equal(ss_find("two means", n = 1)$key, "means_two_indep")
})

test_that("ss_find rejects bad arguments", {
  expect_error(ss_find(c("a", "b")), "single string")
  expect_error(ss_find(NA_character_), "single string")
  expect_error(ss_find("x", n = 0), ">= 1")
})

test_that("run_app's calculator argument takes a design key or words, and says what it opened", {
  expect_equal(.resolve_calculator("patient_units_within_continuous"), "patient_units_within_continuous")
  expect_message(k <- .resolve_calculator("eyes per patient"), "Opening: ")
  expect_equal(k, "patient_units_between_continuous")
  expect_error(.resolve_calculator("zzzzqqq"), "No calculator matches")
  expect_error(.resolve_calculator(""), "design key")
  expect_error(epidemiologysuite_app(calculator = "zzzzqqq"), "No calculator matches")
})

test_that("the app opens on the requested calculator and design (browser test)", {
  skip_if_no_ui()
  withr::local_envvar(EPIDEMIOLOGYSUITE_OPEN = "patient_units_within_continuous")
  app <- ui_fresh_driver(background_load = FALSE, name = "open_on")
  withr::defer(app$stop())
  app$wait_for_js("Shiny.shinyapp.$inputValues['patient_units-design'] === 'within_continuous'", timeout = 60000)
  expect_equal(app$get_value(input = "main_nav"), "Plan: Sample Size")
  expect_equal(app$get_js("(document.querySelector('#plan_nav .nav-link.active')||{}).textContent"), "Eyes / Lesions per Patient")
})

test_that("the addin is registered for RStudio and Positron", {
  dcf <- read.dcf(system.file("rstudio", "addins.dcf", package = "epidemiologysuite"))
  expect_equal(unname(dcf[1, "Binding"]), "ss_find_addin")
  expect_true(is.function(ss_find_addin))
})
