## Submission

This is a new submission (epidemiologysuite 1.0.0).

## R CMD check results

`R CMD check --as-cran` (R 4.x, Linux, 30 Oct 2026): 0 errors. The warnings and notes seen were all caused by the machine the check ran
on, not by the package:

* "New submission" (expected).
* URLs on github.com reported as 403 Forbidden: that machine could not reach GitHub; the addresses are correct.
* "Package suggested but not available for checking: 'DescTools'" (not installed on that machine; it is only used, conditionally, in tests).
* "unable to verify current time", the locale warning (`en_US.UTF-8` not installed) and "'qpdf' is needed": machine set-up.

Timings on that machine: examples 21 s, examples with `--run-donttest` 68 s (each under 5 s after this release's changes), tests 202 s.

## Notes for the reviewers

* The package is a 'shiny' application and a set of exported calculation functions (`calc_*()`). Every exported function has a help page
  with a runnable example; the slow Monte Carlo examples are wrapped in `\donttest{}` and use a small number of simulations.
* Packages in Suggests are used only as numerical checks in the tests (each test skips when its package is missing) or for vignettes.
* Tests that start a browser (shinytest2 / chromote) are skipped on CRAN.
