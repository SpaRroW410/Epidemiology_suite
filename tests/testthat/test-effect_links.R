# "Calculate this" links from the calculators to the Effect Size converters, and "Use this value" back (R/mod_shared_link.R).
# The browser round trip is in test-ui_smoke.R; here every entry of the list is checked against the pages and the converters' results.

registry_ui <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      reg <- module_registry()
      cache <<- setNames(lapply(reg, function(m) as.character(m$ui(m$id))), vapply(reg, `[[`, character(1), "id"))
    }
    cache
  }
})

# a result of each converter design that a link can open, from the designs' own worked examples
es_example <- function(design) {
  switch(design,
    from_t = calc_es_from_t(2.4, 30, 30), paired_means = calc_es_paired(4, sd_diff = 11.76), anova_f = calc_es_f(eta2 = 0.06),
    hazard_ratio = calc_es_hazard_ratio(median_e = 18, median_c = 12), proportions = calc_es_proportions(0.05, OR = 2),
    correlation = calc_es_convert(d = 0.5), median_iqr = calc_mean_sd_from_median_iqr(45, 38, 54, 60),
    two_means = calc_es_two_means(mean1 = 132.86, mean2 = 127.44, sd1 = 15.34, sd2 = 18.23), stop("no example for ", design))
}

test_that("every link names a calculator input that exists, and its page shows the link", {
  ui <- registry_ui()
  for (s in .es_link_specs) {
    label <- paste(s$module, s$input)
    expect_true(s$module %in% names(ui), info = label)
    html <- ui[[s$module]]
    expect_true(grepl(sprintf('id="%s-%s"', s$module, s$input), html, fixed = TRUE), info = paste("input", label))
    expect_true(grepl(sprintf('id="%s-%s"', s$module, .es_link_id(s$input)), html, fixed = TRUE), info = paste("link", label))
  }
})

test_that("no calculator shows a link that has no entry in the list", {
  ui <- registry_ui()
  listed <- vapply(.es_link_specs, function(s) paste0(s$module, "-", .es_link_id(s$input)), character(1))
  expect_false(anyDuplicated(listed) > 0)
  shown <- unlist(lapply(names(ui), function(m) {
    # the links are action links (<a id=... class="action-button ...">); other inputs may also start with es_ (meta_power's es_type)
    found <- regmatches(ui[[m]], gregexpr(sprintf('<a id="%s-es_[A-Za-z0-9_]+"', m), ui[[m]]))[[1]]
    sub('^<a id="(.*)"$', "\\1", found)
  }))
  expect_setequal(shown, listed)
})

test_that("every link opens a converter design that gives the number it sends", {
  for (s in .es_link_specs) {
    label <- paste(s$module, s$input)
    expect_true(s$design %in% .es_designs, info = label)
    res <- list(ok = TRUE, design = s$design, value = es_example(s$design))
    v <- .es_link_value(s, res)
    expect_true(is.numeric(v) && length(v) == 1 && is.finite(v), info = label)
  }
})

test_that("the radios a link presets exist, on the converter page and on the calculator page", {
  es_html <- as.character(mod_effect_size_ui("effect_size"))
  ui <- registry_ui()
  has_choice <- function(html, ns_id, value) grepl(sprintf('name="%s" value="%s"', ns_id, value), html, fixed = TRUE)
  for (s in .es_link_specs) {
    for (n in names(s$set_es)) {
      # a preset may be a function of the calculator's input: check what it gives with nothing set and with each choice of the
      # calculator's own radios
      vals <- if (is.function(s$set_es[[n]])) {
        radios <- unique(sub('^name="[^-]+-([^"]+)" value=.*$', "\\1",
                             regmatches(ui[[s$module]], gregexpr('name="[^"]+" value="[^"]*"', ui[[s$module]]))[[1]]))
        unique(c(.es_set_value(s$set_es[[n]], list()), unlist(lapply(radios, function(r) {
          ch <- sub('^.*value="([^"]*)"$', "\\1", regmatches(ui[[s$module]], gregexpr(sprintf('name="%s-%s" value="[^"]*"', s$module, r), ui[[s$module]]))[[1]])
          vapply(ch, function(v) .es_set_value(s$set_es[[n]], setNames(list(v), r)), character(1))
        }))))
      } else s$set_es[[n]]
      for (v in vals) expect_true(has_choice(es_html, paste0("effect_size-", n), v), info = paste("converter", s$input, n, v))
    }
    for (n in names(s$set_calc)) expect_true(has_choice(ui[[s$module]], paste0(s$module, "-", n), s$set_calc[[n]]), info = paste("calculator", s$input, n))
  }
})

test_that("the converter's design radio offers every design a link opens", {
  es_html <- as.character(mod_effect_size_ui("effect_size"))
  for (d in unique(vapply(.es_link_specs, `[[`, character(1), "design")))
    expect_true(grepl(sprintf('name="effect_size-design" value="%s"', d), es_html, fixed = TRUE), info = d)
})

test_that("the value sent is the converter's number to four significant figures; none when the result lacks it", {
  spec <- .es_link_spec("nonparametric", "f_kw")
  ok <- function(v) list(ok = TRUE, value = v)
  expect_equal(.es_link_value(spec, ok(list(f = 0.342345678))), 0.3423)
  expect_null(.es_link_value(spec, ok(list(d = 0.5))))
  expect_null(.es_link_value(spec, list(ok = FALSE, message = "x")))
  expect_null(.es_link_value(spec, ok(list(f = NA_real_))))
  # the first key present wins
  two <- list(keys = c("a", "b"))
  expect_equal(.es_link_value(two, ok(list(b = 2, a = 1))), 1)
  expect_equal(.es_link_value(two, ok(list(b = 2))), 2)
})

test_that("es_link_ui refuses an input with no entry, and the panel offers the button only when there is a number", {
  expect_error(es_link_ui(NS("means"), "not_an_input"), "No Effect Size link")
  link <- list(spec = .es_link_spec("means", "d_two"), title = "Means")
  with_val <- as.character(es_link_panel(NS("effect_size"), link, list(ok = TRUE, value = list(d = 0.4999))))
  expect_match(with_val, "Use Cohen&#39;s d = 0.4999 in Means|Use Cohen's d = 0.4999 in Means")
  without <- as.character(es_link_panel(NS("effect_size"), link, list(ok = TRUE, value = list(f = 0.3))))
  expect_false(grepl("use_value", without))
  expect_match(without, "does not give")
  expect_null(es_link_panel(NS("effect_size"), NULL, list(ok = TRUE, value = list())))
})

test_that("every pre-fill copies an input the calculator has into an input the converter has", {
  es_html <- as.character(mod_effect_size_ui("effect_size"))
  ui <- registry_ui()
  n <- 0
  for (s in .es_link_specs) for (to in names(s$prefill)) {
    n <- n + 1
    expect_true(grepl(sprintf('id="effect_size-%s"', to), es_html, fixed = TRUE), info = paste("converter input", to))
    expect_true(grepl(sprintf('id="%s-%s"', s$module, s$prefill[[to]]), ui[[s$module]], fixed = TRUE), info = paste("calculator input", s$module, s$prefill[[to]]))
  }
  expect_gt(n, 15)
})

test_that("a preset given as a function follows the calculator's route", {
  hr <- .es_link_spec("logrank", "hr_logrank")$set_es$hr_from
  expect_equal(.es_set_value(hr, list(hr_as_logrank = "implied")), "p")
  expect_equal(.es_set_value(hr, list(hr_as_logrank = "medians")), "median")
  f <- .es_link_spec("nonparametric", "f_kw")$set_es$f_from
  expect_equal(.es_set_value(f, list(f_kw_as = "eta2")), "eta2")
  expect_equal(.es_set_value(f, list(f_kw_as = "f")), "means")
  expect_equal(.es_set_value("x", list()), "x")
})
