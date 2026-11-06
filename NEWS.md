# epidemiologysuite (development version)

## Package release workflow (6 Nov 2026)

* **The tarball from GitHub:** a new workflow (`.github/workflows/package.yml`) builds `epidemiologysuite_<version>.tar.gz` once and
  runs `R CMD check --as-cran` on that file on Linux (R release and devel), Windows and macOS, on every pull request that touches the
  package and on demand; on a version tag it attaches the tarball to the GitHub release. An informational job installs it on Windows on
  ARM. Nothing has to be built on the owner's own computer.
* `docs/release.md`: the steps from version number to GitHub release, r-universe and CRAN, and a note on Windows on ARM.
* Bug-report drafts (`docs/upstream_reports.md`): presize takes reports as GitHub issues (no existing issue on this bug); pmsampsize
  has no tracker, so by e-mail to its maintainer; both bugs still present in the current CRAN versions.
* The name `epidemiologysuite` is confirmed free on CRAN, Bioconductor and GitHub.
* `R CMD check --as-cran` findings fixed: a stray empty file `--version` at the top of the repository (committed by accident on
  4 Nov) removed; the names mirai binds in the background workers (`lib`, `pkg`, `rng_kind`) declared for the code check; four example
  comments shortened below 100 characters; a formula in a help page that R read as a link rewritten; `digest`, `later`, `officer`
  and `xml2`, used by the tests, added to Suggests.
* **Checked against the current CRAN versions** (the new workflow installs them; the test workflow uses the older versions in
  `renv.lock`), which broke 51 tests on Windows and macOS:
  * officer 0.7 requires a `word/settings.xml` part: the Word writer now includes one (it also marks the file as current Word format,
    so Word does not open it in compatibility mode).
  * epiR 3.0.0 changed two conventions: the finite population correction (n / (1 + n/N) instead of n N / (n + N - 1)) and the rounding
    of controls in the matched case-control design; and for a single 2 x 2 table it now reports other intervals for the attributable
    fractions. The app keeps its methods (the correction epiR used before, Rothman-Greenland-Lash for the exposed fraction, Jewell 2004
    for the population fraction); the tests now compare epiR where both versions agree (unrounded, no population size, point
    estimates) and check the rest against the published formulas, so they pass with epiR 2.0.67 and 3.0.0.
  * lme4 2.1-0 (a new major version, imported by the app): the mixed-model calculators give the same results, slow Monte Carlo tests
    included.

## Find: the owner's routing material reviewed and planned (6 Nov 2026)

* The routing design the owner drafted with Gemini (a 37-design tree, guardrails, design cards, search terms) is stored in
  `docs/find_routing/` with a review. Its 46 MeSH headings were checked against the NLM vocabulary: 4 do not exist or are misnamed.
  The tree has no branch for diagnostic accuracy, agreement, prediction or estimation, reaches quasi-experiments only when the
  investigator assigns, and its ethical guardrail overwrites a stated answer.
* Decisions F1-F4 (`docs/SDD.md`): a deterministic reader; the new branches merged into the guide; design cards from the drafted text,
  cited where a source is found and otherwise marked as a suggestion; search terms only from checkable sources. The work is listed as
  FIND-16 to FIND-24, OBS-12 to OBS-15 and SRC-06.

## Project documents reorganised (6 Nov 2026)

* **One list for everything:** `docs/CHECKLIST.md` holds every item, done or open, grouped as the app groups its calculators (and
  then the guide, Studies, interface, package, hosting, engineering, sources, workbenches), each with a stable ID such as `SURV-03`;
  every calculator line names its source and the package it is checked against. It is the only place where status is kept.
* **`docs/PENDING.md`** is generated from it (`Rscript tools/docs/build_pending.R`), owner steps first; a test fails when it is out
  of date, and another when the app cites an ID that is not an open item.
* **`docs/SDD.md`** gains the decisions log (D1-D6, hosting, Studies S1-S5, way of working), a section on how the documents are kept,
  and the developer notes from the README (adding a module, Shiny patterns); its catalog table now points to the checklist.
* **README** shortened to a summary; the roadmap, plan, to-do list, the two first checklists, the brief and the mock-ups moved to
  `docs/archive/`, frozen. The website shows "What is open" and the checklist instead of the roadmap.
* Found on the way: the log-rank help still called staggered accrual and non-proportional hazards "planned" (both are built), and
  the stepped-wedge note in the guide credited Hussey & Hughes for a calculator that follows Hooper et al. 2016; both corrected.

## Matched case-control with a measured exposure; vignettes by topic (5 Nov 2026)

* **Matched sets, measured exposure:** the case-control design for matched sets (conditional logistic regression, Lachin 2008) now
  takes the effect as the mean exposure in cases and in their matched controls, as an odds ratio per SD, or per unit
  (`calc_case_control_nested_continuous(mean_diff =, OR_sd =, OR =)`), and shows cases and controls separately. The guide asks
  whether each case has one control or several: 1:1 goes to the paired comparison as before, 1:m to this design (it was sent to the
  paired test, an approximation). Lachin's examples (sec. 4.1) are reproduced: 125 cases with 2 controls each for an odds ratio of
  1.39 per SD at 85% power.
* **Correction, two or more cases per set:** the information per set is now nD nH / (nD + nH). Lachin's paper, and
  `powerSurvEpi::powerConLogistic.con()`, use nD [1 - 1/C(nD + nH, nD)], which is the same for one case per set but larger for two or
  more. Simulated matched data analysed with `survival::clogit` (1500 data sets per design, 80% planned) gave 79-82% power with the
  new factor and 51-66% with the paper's (for 2 cases and 3 controls per set, 41 sets against 28). Designs with one case per set --
  every 1:1 and 1:m matched case-control study -- are unchanged. The binary exposure already used the new factor (as
  `powerConLogistic.bin()` does).
* **Vignettes by topic:** survival, clinical trials, diagnostic accuracy and surveillance, each with the examples the tests check
  against the published answers.
* Opening a calculator from Find, the guide or the search box can now preset more than its design (`also_set` in the catalog).

## Small items cleared (4 Nov 2026)

* **Three versions** compared in a table (folded on Home, and on the Cite tab), with the one in use marked.
* **Guide:** a cohort with the exposure in ordered levels or on a scale, and a case-control with the exposure in categories or ordered
  levels, now have their own routes (trend test, logistic regression, chi-square).
* **Calculate this** for the Welch design's two SDs; **8 more glossary terms**.
* **Advanced options** (folded) for the alternative hypothesis and the simulation settings in 7 more calculators.
* **Accessibility:** the navbar's search box and dark-mode switch were inside the tab list (screen readers expect only tabs there); moved
  beside it. The group headers of the calculator lists were list items in a tab list too; now marked as presentation.
  The axe scan now covers the Find, Studies and Cite tabs, the guide's new steps and the Use this value panel: 0 violations.
* **No `kappaSize` at run time:** the kappa sample size is written out and equal to the package.
* **From R:** `ss_text()`, `ss_export()`, `ss_curve()`.
* **Fixed:** the protocol paragraph showed "N = NULL" for inputs that were not given.
* **Checked:** the detection sample size against epiR 3.0.0 (same when N x prevalence is whole; the difference is in the help).

## The guide understands research questions

* Questions phrased by topic now get an answer; before, they matched nothing. "Knowledge, attitude and practice of ...", "awareness of",
  "utilization of", "pattern of" lead to a survey estimate.
* "Determinants of smoking in youth", "factors associated with ...", "risk factors of ..." can mean several designs, so the guide shows four,
  each with a line on when it applies (a survey of a population now, case-control, cohort, prediction model), and continues from the one
  you choose.
* After the survey route, the last step also points to the sample size for the associations (two groups for one factor, multiple logistic or
  linear regression for several), and, for a population named by place (a city, district, villages, schools), to the design effect.

## Studies: a working record of calculations (phases 1 to 3)

* **Design choice from the guide:** at its last step, "Add this design choice to [Study v]" keeps the design, the calculator it leads to and
  the questions and answers; it comes first in the Studies tab and in the Word file ("How the design was chosen").
* **Notes and order:** a note on each result (a Comment line in the Word file, or a Comment column in a table) and on the whole study
  (under the title); move a result up or down within its table, and a section up or down.
* **Also under the randomization list and survey selection** (with their own methods paragraph; the list itself stays in the CSV), and
  under the Analyze tools: every page that calculates something can add its result to a study.
* **The guide** now says when nothing in a description could be matched to a design, with how to rephrase it (it showed nothing before).
* **Readable names:** inputs and results show as "Significance level (alpha)", "Sample size (n)"; names whose meaning differs between
  calculators (d, p1, r, ...) are labelled only for the calculators where the meaning is known, otherwise kept as they are.

* **Download (.docx)** for each study: title, a summary line, one section per calculator and design (a result table and an inputs table,
  or one table for repeated use), notes, the justification paragraph, each formula in LaTeX ready for Word's Insert > Equation (with a
  plain-text form where it can be made), the source, and numbered references ending with the suite's own citation. The file is written by a
  small built-in .docx writer (no new package; it also works in the browser version) and saved by the browser, so nothing is written on a server.
* **Fixed:** the DOI on the Cite tab, in `CITATION.cff` and in `R/citation_info.R` is again 10.5281/zenodo.23794230 (an old branch merged into
  main had put back a deleted Zenodo record); the ORCID is back in `CITATION.cff`.

* **Add this result to [Study v] Add** under every result (the 64 calculators with the export panel): the result is recorded as shown, with its
  inputs, warnings, formula (LaTeX), justification paragraph and citation; a short message confirms it, with Undo.
* **Studies tab:** one drop-down for Study 1, 2, 3 ("+ New study", up to 10) and Recent calculations; a name for each study; repeated use of one
  calculator and design shown as one table (the inputs that changed as columns, the others listed once); remove an entry or clear a study;
  references without duplicates.
* **Recent calculations:** the last 20 results, recorded once a result has stayed the same for 3 seconds after you changed something in that
  calculator; each can be added to a study later.
* **Kept only in this browser tab** (`sessionStorage`): a reload, or a phone waking after the server version dropped the connection, keeps it;
  closing the tab loses it. Nothing is saved on a server.

## Links from the calculators to the Effect Size converters

* **Pre-filled converters:** nine "Calculate this" links copy what the calculator already holds into the converter (group means and SD,
  eta-squared, median survival or event probabilities, the controls' exposure, the paired SDs and their correlation, Cohen's d) and open it on
  the route the calculator was using, so the same numbers are not typed twice.
* **Server version notice:** the Posit Connect version says, in a closable line at the top, that what is typed is sent to the server and is
  not saved to disk (the browser version already says that everything stays on the device).
* **Author:** ORCID added to `DESCRIPTION`, `CITATION.cff` and `citation()`.
* **Tools:** `tools/ui-audit/contrast.R` (colour-contrast crawl, dark or light mode) and `tools/ui-audit/live_timing.js` (times a published
  version as a person meets it).
* **Calculate this / Use this value:** 28 calculator inputs that ask for a number the Effect Size converters produce now have a "Calculate this"
  link: Cohen's d (from a t statistic), Cohen's f and f-squared, r (from d), the hazard ratio, the odds ratio (from proportions), the SD (from a
  median and interquartile range) and the SD of paired differences. The link opens the matching converter; once it has a result, "Use this value"
  (pinned at the bottom of the window) puts the number into the calculator's input, switches the calculator to the way of entering it that shows that
  input, and goes back. "Back without a value" leaves the input as it was. If the converter's result does not give the number, no button is offered.

## The effect, entered the way people know it (OpenEpi-style inputs)

* **Means** (two independent means, unequal group sizes, unequal variances / Welch): give both means **or their difference**, and the SD
  **or the variance** (each group's own in the Welch design, with the ratio of group sizes), as in OpenEpi's "Sample Size For Comparing Two
  Means" form; the first two designs also take **Cohen's d** directly. A line under the inputs shows the difference and the Cohen's d they
  give. OpenEpi's example inputs (means 132.86 and 127.44, SDs 15.34 and 18.23, 95% and 80%, equal groups) give 152 per group. Paired means:
  the SD of the differences, or the two SDs and their correlation.
* **Cohort / trial and two proportions:** give the exposed group's risk, or instead the **odds ratio**, the **risk ratio** or the **risk
  difference** ("fill in 1 of the following"); the others are shown. For 5% unexposed and an odds ratio of 2: 9.52%, 1.90, 4.52 points.
  Group 2 is the reference in the two-proportion design.
* **Cluster / Design Effect:** the design effect applies to **any cluster design** (a survey, a cluster-randomised trial, a quasi-experimental
  community trial), and the module now says so. A new design, **Calculate the design effect from the variance between clusters**, gives the
  design effect and the ICC from the between- and within-cluster variances, from the variance of the cluster means or proportions (with the
  overall variance or proportion), or from the variances of the estimate under the cluster design and under simple random sampling; each is
  checked by simulating clustered data. In the inflation design the design effect can be entered directly: 1.5 if nothing is known ("most
  commonly taken as 1.5 or 2"; a common planning habit, no source checked). From R: `calc_cluster_deff_variance()` and
  `calc_cluster_deff(deff =)`. The single-proportion calculator has no design-effect input; it points to this module for cluster surveys.
* **Cohen's f** (Kruskal-Wallis, Friedman, repeated-measures ANOVA): enter f, or work it out from group means and SD or from eta-squared.
  **Cohen's d** (FDR and Dunnett designs): enter d, or a difference with an SD or a variance. **Log-rank:** the hazard ratio can also be
  calculated from median survival times.
* From R: `calc_means_2s_indep()`, `calc_means_2s_unequal_n()` (`diff`, `variance`, `d`), `calc_means_welch()` (`diff`, `var1`, `var2`),
  `calc_means_paired()` (`sd1`, `sd2`, `r`), `calc_cohort()` and `calc_proportion_2s()` (`OR`, `RR`, `RD`). Existing calls are unchanged. Each route is tested to give exactly the result of the plain one.
* **Information tips** (i) on the labels of the matching terms: phi, odds ratio, ICC, design effect, sensitivity, specificity, prevalence,
  allocation ratio, rate ratio, hazard ratio, absolute and relative precision, non-response.

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
