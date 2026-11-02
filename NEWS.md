# epidemiologysuite (development version)

## Effect Size tab, glossary and information tips

* **Effect Size** is a new calculator, the first group in the Plan: Sample Size list (Plan still opens on Proportions). It works out
  the number a sample-size calculator asks for from what is usually known; each result has the formula, a worked example and a source,
  and a plain reading against Cohen's conventions:
  two means (SDs **or variances**; means **or their difference**; Cohen's d, Hedges' g and an interval with the group sizes),
  d from a t statistic, d for paired measurements (from the SD of the differences, or from the two SDs and their correlation, or the
  correlation implied by all three), Cohen's f (from group means and SD, eta-squared, an F statistic or d), two proportions (give
  **one** of p1, the odds ratio, the risk ratio or the risk difference, as in OpenEpi's cohort and case-control forms; also Cohen's h and
  the number needed to treat), Cohen's w and Cramer's V (a table, a chi-square statistic, or expected proportions), a hazard ratio
  (from median survival, assuming exponential survival, or from survival or event probabilities), conversions among d, r, an odds ratio,
  R-squared and f-squared, a mean and SD from a median and IQR, and phi from a table of matched pairs.
* From R: `calc_es_two_means()`, `calc_es_from_t()`, `calc_es_paired()`, `calc_es_f()`, `calc_es_proportions()`, `calc_es_chisq_w()`,
  `calc_es_hazard_ratio()` and `calc_es_convert()`. Each is checked against a package or a defining identity (`pwr`, `cor()`,
  `t.test()`, `aov()`, `chisq.test()`, the Analyze tool's d and g), by simulation, and by round trip.
* **Sources:** Chinn 2000 (odds ratio to d, ln(OR) / 1.81 = d x pi / sqrt(3)) was read as an abstract only; Cohen 1988, Hedges 1981 and
  Hedges & Olkin 1985 were not read, and the text says so (the formulas are checked numerically). The odds-ratio conversion is marked
  approximate.
* **Information tips:** a small (i) beside a term shows its meaning on hover, on keyboard focus and on a tap (phones). The same
  definitions, about 35 terms, are on a new **Glossary** page under Find a calculator, with a filter box.
* The guide has a new route, "An effect size to enter in a calculator", and recognises phrases such as "calculate the effect size".

## Finding a calculator, dark mode, the browser version

* **Find a calculator** is now its own tab (guided questions, the list of every calculator by study design or by test, formulas).
  "Start the guide" and the new "Browse all calculators" button on Home open it at the top of the page; before, they opened a folded
  section below the visible part of the page and seemed to do nothing. On a phone the tab is "Find".
* **Browser version (GitHub Pages):** calculators are no longer loaded one by one in the background. R runs on the page's single
  thread there, so a click waited behind the queue: "Start the guide" took 80 s and a Home button 72 s on the published site; now 5 s
  and 1.5 s. A calculator loads when it is opened; the "Loading calculators" bar is not shown there.
* **Dark mode:** the guide's "describe your study" box, the formula preview and a note in the attrition calculator kept a white
  background with light text (contrast 1.3:1). They now use the theme's colours; a contrast check over every page found nothing else.
* **The guide** asks how a continuous outcome is summarised: mean and SD, or median and IQR. Both lead to the paired / unpaired
  mean-difference calculators; with a median and IQR the result explains how to estimate a mean and SD and offers the rank-based
  test. The free-text box recognises "median", "IQR" and "interquartile".

## Effect sizes from what people usually know

* **Case-control (unmatched and matched):** the effect can be given as the proportion of cases exposed (p1) instead of the odds
  ratio (`p1 =`); OR = p1 (1 - p0) / (p0 (1 - p1)), the relation the Dupont formula uses. Both are shown.
* **Matched case-control:** phi can be calculated from a table of matched pairs (both exposed, case only, control only, neither):
  `calc_matched_pairs_phi()`, the phi coefficient of the pairs table; checked against `cor()` and by simulation of Dupont's model.
* **Log-rank:** the hazard ratio can be calculated from pE and pC (proportional hazards: HR = log(1 - pE) / log(1 - pC)); an entered
  HR that differs from it by more than 10% gives a warning.
* **Rates (two groups, negative binomial):** the rate ratio can be given as the second group's rate.
* **Means:** `calc_mean_sd_from_median_iqr()` and a converter in the Means calculator estimate a mean and SD from a median and IQR
  (Wan, Wang, Liu & Tong, BMC Med Res Methodol 2014;14:135, scenario C3; read through PubMed Central; checked by simulation).

## Absolute and relative precision, non-response

* The five precision-based calculators (single proportion, single mean, cluster survey of a proportion, incidence rate, diagnostic
  accuracy) take the precision as **absolute** (+/- d on the scale of the estimate) or **relative** (+/- a fraction of it, d = epsilon x
  estimate). Single proportion, incidence rate (`epsilon =`) and diagnostic accuracy (`error = "relative"`) gain the relative form; means
  and the cluster survey already had it.
* **Refused:** a precision whose interval would pass 0 or 1 (d >= p or d >= 1 - p for a proportion, sensitivity or specificity) and a
  relative precision of 100% or more.
* **Warned, not refused:** a relative precision above 20% (a common rule of thumb; no published source checked, and the text says so); a
  proportion below 10% with d above one-fourth of it (Pourhoseingholi, Vahedi & Rahimzadeh, Gastroenterol Hepatol Bed Bench
  2013;6:14-17), applied by the app to 1 - p above 90%; for a mean, an absolute precision as large as the mean. The warnings are in the
  result's `precision_notes`.
* **Non-response / loss to follow-up** (`nonresponse =`): the number to enrol is n / (1 - r), rounded up (`n_enrolled`); for the cluster
  survey each cluster selects b / (1 - r) and the number of clusters is unchanged; for a rate the person-time to plan is divided by
  1 - r.
* Each calculator shows its precision both ways under the inputs and has a "When should I use absolute or relative precision?" panel.
  The protocol paragraph, CSV and JSON state the precision type and the inflation.
* Verified against Pourhoseingholi et al.'s Table 1 (8 of 9 cells; the ninth, p = 0.05 with d = 0.1, is now refused) and against
  `epiR::epi.sssimpleestb()` for relative and absolute precision.

# epidemiologysuite 1.0.0

First release (tag `v1.0.0`). The package was called `epidemiologicasuite` until 30 October 2026, when it followed the renaming of the
GitHub repository to `Epidemiology_suite`; the app is shown to people as **Epidemiological suite**.

## What it contains

* **Plan: Sample Size.** 50 calculator modules covering 159 study designs (proportions, means, diagnostic accuracy, agreement, case-control
  and cohort studies, clinical trials, survival, prediction models, cluster and multilevel designs, non-parametric and other tests, and
  more). Each calculator shows its formula, a worked example and a citable source, and says when a formula is derived rather than
  published or a source was not read.
* **Several measurements per patient** (eyes, lesions, patches, teeth, split-face): patients needed when treatment is given to whole
  patients (two means, two proportions) or to each patient's units (two means), units per patient needed for a fixed number of patients,
  and the floor that extra units cannot get below.
* **Analyze.** 11 summary-data tools (2 x 2 tables, rates, Mantel-Haenszel, standardization, diagnostic accuracy, vaccine efficacy and
  others), plus planning tools (randomization lists, attrition inflation), survey tools (sample selection, EPI 30 x 7 clusters, survey
  weights), outbreak and surveillance tools (attack rates, EARS and CUSUM aberration detection) and SIR / SEIR teaching models.
* **Design wizard and plain-language search.** Describe a study in words, or answer a few questions, and the app suggests calculators.
  In R, `ss_find()` does the same (also as an RStudio add-in).
* **Cite tab.** The citation in APA, Vancouver, Harvard, IEEE, MLA, Chicago, BibTeX and RIS, and a sentence for a Methods section, with
  copy and download buttons; `citation("epidemiologysuite")` and `CITATION.cff` too. Archived on Zenodo: doi:10.5281/zenodo.23794230.

## From R

* All 195 `calc_*()` functions are exported, each with a help page, every argument documented, a description of the returned
  `ss_result` object and an example that runs. `print()` and `format()` methods are registered for `ss_result`.
* `run_app()` and `epidemiologysuite_app()` start the application. Setting the environment variable `EPIDEMIOLOGYSUITE_OPEN` to a design
  key makes a deployment open on that calculator.
* Vignettes: getting started, sample size from R, analyze from R.

## Interface and accessibility

* Task-first Home page, search from every page, calculator pages with export and power-curve panels folded away, advanced options for
  the main calculators, a dark mode, and a phone layout with a bottom tab bar.
* An axe-core scan (WCAG 2.0 / 2.1 A and AA) of every calculator, light and dark, desktop and phone, finds no violations. A person's
  keyboard and screen-reader walk-through, dark-mode plots and a real-phone layout check are still to do.

## Where it runs

* In the browser (Shinylive / webR) on GitHub Pages, as a phone and server version on Posit Connect Cloud, as a Docker image, and as this
  R package. Phones and tablets are sent to the Connect version when its address is set.

## Verification

* Every formula is checked numerically against a published example, a real package (for example `pwr`, `clusterPower` and
  `powerlmm`) or a simulation; the packages used as checks are only suggested, never required at run time.
* The tests cover every calculator, the catalog and wizard, the help pages and a headless-browser smoke test of the interface.

## Known limits

* Slow Monte Carlo designs run inside the user's session and block other users on a shared server; running them in the background is
  planned.
* The browser build needs about 1 GB of memory and a large download, which is why phones are sent to the server version.
* Not yet checked: a real phone and Safari, the free-plan limits of Connect Cloud, and the package name against CRAN's rules
  (`available::available()`).
