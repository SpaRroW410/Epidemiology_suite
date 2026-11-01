# epidemiologysuite (development version)

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
