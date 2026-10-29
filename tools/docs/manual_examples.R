# Examples for the calc_*() functions whose test calls use helper variables (so extract_examples.R could not run them as they stand).
# Every snippet is a literal copy of a worked example from the tests, with the published value noted. Adds them to examples.json.
# Usage: Rscript tools/docs/manual_examples.R <examples.json>
suppressMessages(pkgload::load_all(".", quiet = TRUE))
path <- commandArgs(trailingOnly = TRUE)[1]
snip <- list(
  calc_analyze_exposure_table = '# per food: ill and total among the exposed, ill and total among the unexposed\nex <- rbind(c(40, 50, 4, 30), c(25, 60, 19, 20), c(10, 12, 34, 68))\ncalc_analyze_exposure_table(ex, labels = c("Salad", "Chicken", "Dessert"))',
  calc_chisq_gof = '# Cohen (1988) exercise 7.1: four equally likely categories against one larger share; N = 131\ncalc_chisq_gof(P0 = rep(0.25, 4), P1 = c(0.375, rep((1 - 0.375) / 3, 3)),\n               alpha = 0.05, power = 0.80)',
  calc_chisq_independence = '# a 2 x 2 table of joint proportions; N = 589\ncalc_chisq_independence(rbind(c(0.15, 0.35), c(0.10, 0.40)), alpha = 0.05, power = 0.80)',
  calc_longitudinal_diggle = '# Diggle et al. (2002) p. 29: 3 visits at 0, 2 and 5, one-sided; 313 per group\ncalc_longitudinal_diggle(visit_times = c(0, 2, 5), delta = 0.5, sigma2 = 100, rho = 0.2,\n                         alternative = "one.sided", power = 0.80)',
  calc_longitudinal_edland = '# the documented Alzheimer example: 208 per group\ncalc_longitudinal_edland(visit_times = seq(0, 1.5, 0.25), delta = 1.5, sigma2_slope = 24,\n                         sigma2_residual = 10, alpha = 0.05, power = 0.80)',
  calc_longitudinal_hu = '# no attrition until the last visit (p gives the share of subjects whose last visit is each one)\ncalc_longitudinal_hu(visit_times = seq(0, 1.5, 0.25), p = c(rep(0, 6), 1), delta = 1.5,\n                     sigma2_slope = 24, sigma2_residual = 10, cor_intercept_slope = 0.5,\n                     power = 0.80)',
  calc_mantelhaenszel = '# five strata (Cohen-style textbook example): stratified n = 447, naive pooled n = 1151\ncalc_mantelhaenszel(alpha = 0.05, power = 0.80, a = c(0.15, 0.15, 0.20, 0.25, 0.25),\n                    b = c(0.4, 0.4, 0.5, 0.6, 0.6), p1 = c(0.5, 0.6, 0.7, 0.8, 0.9), phi = 2)',
  calc_mmrm_ar1 = '# retention at four visits in each arm; 37 in the first arm\ncalc_mmrm_ar1(rho = 0.6, ra = c(1, 0.76, 0.63, 0.52), rb = c(1, 0.87, 0.81, 0.78), sigma = 1,\n              lambda = sqrt(1.25 / 1.75), delta = 0.9, power = 0.904)',
  calc_multiplicity_adjusted_alpha = 'calc_multiplicity_adjusted_alpha(0.05, m = 4, method = "bonferroni")   # 0.0125\ncalc_multiplicity_adjusted_alpha(0.05, m = 4, method = "sidak")        # 0.0127415',
  calc_sem_rmsea_power = 'calc_sem_rmsea_power(rmsea0 = 0.08, rmseaA = 0.03, df = 50, n = 300, alpha = 0.05, group = 2)',
  calc_survey_epi_clusters = 'set.seed(3)\nvillages <- round(runif(120, 200, 3000))   # populations of 120 villages\ncalc_survey_epi_clusters(villages, n_clusters = 30, per_cluster = 7, seed = 11,\n                         labels = paste("Village", 1:120))'
)
ex <- jsonlite::read_json(path)
for (n in names(snip)) {
  t0 <- Sys.time()
  r <- eval(parse(text = snip[[n]]), new.env(parent = asNamespace("epidemiologicasuite")))
  # the last expression's value is what is printed; take the result of the last call for the field names
  if (!is.list(r) && !is.numeric(r)) stop("unexpected result for ", n)
  ex[[n]] <- list(call = snip[[n]], seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2),
                  fields = if (is.list(r)) setdiff(names(r), "inputs") else list(), class = class(r)[1])
  cat(n, ":", class(r)[1], paste(utils::head(names(r), 6), collapse = ","), "\n")
}
jsonlite::write_json(ex, path, auto_unbox = TRUE, pretty = TRUE)
