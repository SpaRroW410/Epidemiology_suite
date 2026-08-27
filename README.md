# Sample Size Calculator

An R Shiny web app for sample size and power calculations for community
medicine, epidemiology, and clinical research, with an explained-formula help
tab and original-source citation for every calculator. Background and full
design rationale: [`docs/project-brief.md`](docs/project-brief.md) and
[`docs/SDD.md`](docs/SDD.md). The full calculator backlog (~90 scenarios,
by study design and by statistical test, staged into a 4-phase build plan)
lives in [`docs/checklist_by_design.md`](docs/checklist_by_design.md) and
[`docs/checklist_by_test.md`](docs/checklist_by_test.md) — check those,
not the SDD, for what's built and what's next.

This is Phase 1 (app shell, Home finders, Proportions module) plus the start
of Phase 2: twenty-six complete calculator modules -- all Stage-1 CORE items
from the master checklists are now built, plus two "quick wins" batches of
further CORE items, and the start of Stage 2 (analytical depth) --

- **Proportions** (`R/modules/mod_proportion.R`) -- single proportion
  (precision-based, Cochran's formula, with optional finite population
  correction), single proportion vs. known value, two independent
  proportions
- **Means** (`R/modules/mod_means.R`) -- single mean, precision-based
  (wraps `epiR::epi.sssimpleestc()`), single mean vs. known value, two
  independent means (equal or unequal group sizes, the latter via
  `pwr::pwr.t2n.test()`), two paired means (before-after / matched pairs),
  and three or more independent groups (one-way ANOVA, wraps
  `pwr::pwr.anova.test()`, converting raw group means to Cohen's f)
- **Diagnostic Accuracy** (`R/modules/mod_diagnostic.R`) -- sensitivity &
  specificity, precision-based or vs. a known/reference value, comparing
  two diagnostic tests (unpaired or paired), all per Akoglu (2022)'s
  practical guide, plus predictive values (PPV/NPV, precision-based --
  Buderer's prevalence-adjustment logic extended to Altman & Bland 1994's
  PPV/NPV formulas) and likelihood ratios (LR+/LR-, wrapping
  `presize::prec_pos_lr()`/`prec_neg_lr()`, Simel, Samsa & Matchar 1991)
  -- see that module's own doc comments and
  `R/content/content_diagnostic.R` for the full formula set and citations
  (Buderer 1996, Casagrande & Pike 1978, Connor 1987, Obuchowski 1998,
  Altman & Bland 1994, Simel et al 1991)
- **Agreement / Reliability** (`R/modules/mod_agreement.R`) -- for when
  there's *no* gold standard at all, only two raters/methods being compared
  to each other: Cohen's kappa (categorical, wraps `presize::prec_kappa()` /
  Donner & Eliasziw 1987, Rotondi & Donner 2012), the intraclass
  correlation coefficient (continuous, wraps `presize::prec_icc()` / Bonett
  2002), Cronbach's alpha (scale internal consistency, wraps
  `presize::prec_cronb()` / Bonett & Wright 2015), Bland-Altman limits
  of agreement (wraps `presize::prec_lim_agree()` / Bland & Altman 1986),
  and Lin's concordance correlation coefficient (closed-form, Lin 1989/
  2000 -- no CRAN package implements a dedicated CCC sample-size
  function, so this reimplements the exact asymptotic variance formula
  that `epiR::epi.ccc()` itself already uses internally for its own
  confidence interval; epiR is already a project dependency)
- **Case-Control** (`R/modules/mod_case_control.R`) -- unmatched and matched
  (1:1 or 1:m) case-control studies, both wrapping `epiR::epi.sscc()`
  (Dupont 1988; Woodward 2014); nested case-control (binary or continuous
  exposure), wrapping `powerSurvEpi::powerConLogistic.bin()`/`.con()`
  (Lachin 2008 §3.1/§3.3); and case-cohort, closed-form reimplementation
  of `gap::ccsize()`'s sample-size equation (Cai & Zeng 2004) rather than
  a runtime dependency on `gap`, whose `dplyr`/`ggplot2`/`plotly`/`Rdpack`
  imports are far heavier than this one formula needs
- **Cohort / RR** (`R/modules/mod_cohort.R`) -- cohort/cross-sectional
  relative-risk studies, wrapping `epiR::epi.sscohortc()` (Kelsey,
  Thompson & Evans 1986; Woodward 2014)
- **Correlation** (`R/modules/mod_correlation.R`) -- Pearson correlation,
  wrapping `pwr::pwr.r.test()` (Cohen 1988)
- **Chi-Square Tests** (`R/modules/mod_chisq.R`) -- goodness of fit and test
  of independence/association for an R x C table (dynamic 2-5 x 2-5
  proportion-matrix UI), both wrapping `pwr::pwr.chisq.test()` +
  `pwr::ES.w1()`/`ES.w2()` (Cohen 1988); the independence design also serves
  as the Proportions module's "3+ group proportions" entry in the Home
  finder; plus McNemar's test for paired/matched proportions (the same
  subjects measured twice), wrapping `TrialSize::McNemar.Test()` (Chow,
  Shao & Wang 2003) -- `TrialSize` already a zero-dependency project
  dependency
- **Pilot / Feasibility** (`R/modules/mod_pilot.R`) -- the flat 12/arm
  rule-of-thumb (Julious 2005) plus an interactive tool showing how precise
  a pilot's estimated SD is at a given n (95% CI multipliers on the observed
  SD), from chi-square CI-for-variance theory; no formal power calculation
  since pilots aren't powered studies
- **Simon Two-Stage** (`R/modules/mod_simon.R`) -- Phase II single-arm
  designs, wrapping `clinfun::ph2simon()` (Simon 1989), reporting both the
  minimax (smallest maximum n) and optimal (smallest expected n under the
  null) designs
- **Equivalence (TOST)** (`R/modules/mod_tost.R`) -- two one-sided tests, for
  a mean difference on the raw/untransformed scale (wraps
  `PowerTOST::sampleN.TOST(logscale = FALSE, design = "parallel")`; Phillips
  1990; Diletti, Hauschke & Steinijans 1991) or for two proportions (wraps
  `epiR::epi.ssequb(type = "equivalence")` -- no lightweight package with a
  dedicated proportions-TOST function was found)
- **Log-Rank / Survival** (`R/modules/mod_logrank.R`) -- two-arm
  time-to-event studies (required N from event probabilities), wrapping
  `powerSurvEpi::ssizeCT()` (Freedman 1982; Rosner 2006); Cox
  proportional-hazards regression for a binary or continuous covariate of
  interest (optionally adjusting for a correlated covariate), wrapping
  `powerSurvEpi::ssizeEpi()`/`ssizeEpiCont()` (Latouche et al. 2004;
  Hsieh & Lavori 2000); and a stratified log-rank test under exponential
  survival (per-stratum allocation, event rates under the null, and a
  common hazard ratio), wrapping `powerSurvEpi::ssize.stratify()` (Palta
  & Amini 1985)
- **Incidence Rate** (`R/modules/mod_rate.R`) -- precision-based estimation
  of an incidence rate (number of events, then person-time, wrapping
  `presize::prec_rate()`), plus comparison of two rates via person-time
  (closed-form Demidenko 2007 Poisson-regression formula, reproducing
  WebPower's `wp.poisson()` exactly without that package's heavy
  dependency chain)
- **Multiple Regression** (`R/modules/mod_regression.R`) -- R-squared
  deviation from zero for a multiple linear regression model, wrapping
  `pwr::pwr.f2.test()` (Cohen 1988)
- **Non-Inferiority** (`R/modules/mod_noninferiority.R`) -- means or
  proportions, wrapping `epiR::epi.ssninfc()` / `epi.ssninfb()` (Chow, Shao
  & Wang 2008)
- **Rule of Three** (`R/modules/mod_rule_of_three.R`) -- the upper bound on
  an unseen adverse-event rate given zero events observed, or the sample
  size needed to have a good chance of observing at least one event of an
  assumed rate; closed-form (Hanley & Lippman-Hand 1983)
- **Exact Tests** (`R/modules/mod_exact_tests.R`) -- the binomial test
  (single proportion) and Fisher's exact test (two independent
  proportions), both more accurate than the normal-approximation designs
  elsewhere in this app for small samples. Both search upward over n
  (via `stats::binom.test()` and `Exact::power.exact.test()` respectively)
  rather than solving a closed-form equation, since exact-test power is
  genuinely non-monotonic in n (Chernick & Liu 2002) -- a stability check
  guards against recommending a fragile single-n spike
- **Prediction Model** (`R/modules/mod_prediction.R`) -- minimum sample
  size for developing a binary, continuous, or time-to-event prediction/
  prognostic model, wrapping `pmsampsize::pmsampsize()` (Riley et al. 2019
  Stat Med Parts I & II; Riley et al. 2020 BMJ 368:m441); the binary design
  additionally accepts either a Cox-Snell R² or a reported C-statistic
  (converted via Riley et al. 2021 Stat Med 40:859-864's seeded simulation)
- **ROC / AUC** (`R/modules/mod_roc.R`) -- sample size for a single ROC
  curve's AUC against the chance diagonal (0.5), wrapping
  `pROC::power.roc.test()` (Obuchowski, Lieber & Wians 2004); comparing two
  AUCs was deliberately left out of scope for now, since that case needs
  either fitted `roc` objects on real data or a full set of binormal
  parameters rather than simple summary statistics
- **Cluster / Design Effect** (`R/modules/mod_cluster.R`) -- inflates an
  already-computed simple-random-sample size for cluster/multistage
  sampling (villages, schools, health facilities), closed-form DEFF = 1 +
  (m-1)*rho (Kish 1965), no package needed
- **Stratified Sampling** (`R/modules/mod_stratified.R`) -- total sample
  size and per-stratum allocation (proportional or optimal/Neyman) for a
  population divided into strata, closed-form (Cochran 1977; Kauermann &
  Kuechenhoff 2011) rather than a runtime dependency on `samplingbook`,
  whose `Depends: pps, sampling, survey` chain is far heavier than this
  one formula needs -- verified to reproduce that package's own
  documented examples exactly
- **Crossover Trial (2x2)** (`R/modules/mod_crossover.R`) -- a 2x2
  crossover trial's sample size for a continuous outcome, testing for a
  difference (not equivalence -- see the Equivalence (TOST) module for
  that), wrapping `TrialSize::TwoSampleCrossOver.Equality()` (Chow, Shao
  & Wang 2003); `TrialSize` has zero package dependencies
- **Factorial ANOVA / ANCOVA** (`R/modules/mod_anova_general.R`) -- a
  general linear-model F-test for a factorial ANOVA main effect or
  interaction, or an ANCOVA group effect, wrapping `pwr::pwr.f2.test()`
  (Cohen 1988) -- the same engine already used by the Multiple Regression
  module, since Cohen treats ANOVA/ANCOVA and regression as one unified
  "F tests" family; effect size accepted as either Cohen's f-squared or
  partial eta-squared
- **Logistic Regression** (`R/modules/mod_logistic.R`) -- simple logistic
  regression with a binary or continuous predictor, wrapping
  `powerMediation::SSizeLogisticBin()`/`SSizeLogisticCon()` (Hsieh, Bloch
  & Larsen 1998) rather than `WebPower::wp.logistic`; `powerMediation`
  has zero package dependencies
- **Self-Controlled Case Series** (`R/modules/mod_sccs.R`) -- sample size
  for an SCCS study of a transient exposure's association with an event,
  with an optional age-effect stratification (Musonda, Farrington &
  Whitaker 2006); closed-form reimplementation of `SCCS::samplesize()`'s
  algorithm rather than a runtime dependency on `SCCS`, whose
  `Imports: survival, splines, corpcor, fda, R.methodsS3, gnm` chain is
  far heavier than this one formula needs -- verified to reproduce all
  three of that package's documented examples exactly
- **RM-ANOVA / Mixed ANOVA** (`R/modules/mod_rm_anova.R`) -- sample size
  for a between-subjects group effect, a within-subjects (repeated-
  measures) effect, or their interaction (the classic mixed/split-plot
  ANOVA test), closed-form reimplementation of
  `WebPower::wp.rmanova()`'s noncentral-F algorithm (Cohen 1988) rather
  than a runtime dependency on `WebPower`, whose `MASS`/`lme4`/`lavaan`/
  `PearsonDS` dependencies are far heavier than this one function needs
  and which that function itself never calls into; the between-effect
  design reproduces the package's own documented example exactly

Everything else in `docs/checklist_by_design.md` / `docs/checklist_by_test.md`
(advanced survival designs, post-hoc power, and the much larger Stage 2-4
backlog in those two files) remains "coming soon" in the Home hub, per
the staged build plan.

### Top navbar: grouped by study design, simple to difficult

With 24 calculator modules, one flat top-level tab per module became
unworkably crowded, so `app.R` groups them into 10 `bslib::nav_menu()`
dropdowns instead of listing them flat, ordered to match
`docs/checklist_by_design.md`'s own Part-1 study-design section numbers
(already simple -> difficult): Descriptive & Estimation, Survey &
Cross-Sectional, Observational Studies, Diagnostic & Screening, Agreement &
Reliability, Clinical Trials, Survival Analysis, Prediction Models,
Surveillance, and General Statistical Tests (the handful of modules with no
single natural study-design home -- Correlation, Chi-Square, Multiple
Regression, Factorial ANOVA/ANCOVA, Logistic Regression, Exact Tests -- kept
together here, same duality as `checklist_by_design.md` vs.
`checklist_by_test.md`). The grouping itself lives in `global.R`'s
`module_groups` list (which module ids collapse under which dropdown title,
in what order) -- `app.R` just builds one `nav_menu()` per entry; adding a
calculator to the *navbar* still only means appending to `module_registry`
plus placing its id in the right `module_groups` entry, nothing about
`app.R`'s structure changes. Total top-level nav items: Home + 10 dropdowns
= 11, down from 26 flat tabs (Home, "Which calculator?", and 24 modules).

### Home hub: welcome + three ways to find/understand a calculator

The Home tab is a short welcome, then one "Helper" area (`R/home/home_hub.R`)
bundling three tabs so none of them need their own crowding top-level nav
item:

- **"Browse calculators"** (`R/home/home_finder.R`) -- a single toggle
  ("By study design" / "By test family") over an accordion of every
  built calculator at once (collapsed by default so ~20-21 family panels
  stay scannable), rather than the old one-family-at-a-time dropdown. "By
  study design" uses `study_design_families`; "By test family" is a second,
  parallel index, `test_families` (both in `home_catalog.R`), mirroring
  G*Power/the scope-review checklist's "Part 2 -- By Statistical Test"
  groupings (t/z/F/chi-square/exact tests, correlation & regression,
  survival tests, agreement statistics, equivalence/non-inferiority forms).
  Toggling never duplicates a calculator -- both axes point at the same
  `calculator_catalog` entries and the same jump-button mechanism (below);
  it's purely a second browsing lens over one set of live modules.
- **"Which calculator? (guided wizard)"** (`R/home/design_wizard.R`) -- asks
  one question at a time (primary aim, experimental vs. observational,
  selection basis, outcome type, groups) per
  [`docs/design_identification_algorithm.md`](docs/design_identification_algorithm.md),
  shows its reasoning trace as you answer, and ends on a jump button into a
  live module -- or an honest "not yet built" note (naming the module/
  backend/citation the checklists already call for) if that branch isn't
  implemented yet. `R/home/design_tree.R` holds the question/terminal node
  registry. v1 scope is guided-tree only -- no free-text/PICO parsing yet.
- **"Formulas & LaTeX"** (`home_hub.R`'s `home_sandbox_ui()`) -- a short
  explainer of this app's `$$...$$`/MathJax formula convention, plus a live
  sandbox: type LaTeX and see it rendered instantly. See "Formula LaTeX
  source + copy button" below for the matching feature on every calculator's
  own formula display.

Both `home_finder.R` and `design_wizard.R` expose a `*_body()` UI-fragment
function (not a full page) plus their existing `*_server()`, composed
together by `home_hub.R`'s `home_panel_ui()`/`home_server()` -- same
non-module, top-level pattern as before (see "Non-idiomatic patterns"
below), just assembled from three pieces instead of mounted as separate nav
panels.

### Look & feel

`app.R`'s `bs_theme()` uses the "litera" Bootswatch preset with the
"Source Serif 4" Google Font for both body and heading text (a clean,
academic look, and a serif companion to the widely-used Source Sans family
used across scientific publishing). Google Fonts load client-side at the
browser, not server-side -- no new R package -- so this needs the end user's
browser to reach `fonts.googleapis.com`; it degrades gracefully to a system
serif font if that's blocked, same as `withMathJax()`'s formula rendering
degrading gracefully (no crash, just unstyled/untypeset content) if
`mathjax.rstudio.com` is unreachable.

## Requirements

- R (>= 4.1)
- `pacman` (installed automatically by `global.R` if missing), which in turn
  installs/loads `shiny`, `bslib`, `pwr`, `presize` (which itself pulls in
  `kappaSize`). `testthat` is only needed to run the test suite:
  ```r
  install.packages("testthat")
  ```

## Running the app

```r
shiny::runApp()
```

or from a shell:

```sh
Rscript -e 'shiny::runApp()'
```

## Running tests

```r
testthat::test_dir("tests/testthat")
```

## Repository structure

```
app.R                      # entry point: builds grouped navbar, wires modules + Home hub
global.R                   # pacman::p_load(), source()s R/, module_registry + module_groups
R/
├── modules/                # UI + server per calculator (mod_*.R), + mod_shared_ui.R
├── calc/                   # pure calculation functions, no Shiny (calc_*.R)
├── content/                 # per-module metadata: formula, text, citation (content_*.R)
└── home/                    # Home hub: finder, wizard, catalog (see below)
tests/testthat/            # unit tests on calc_*.R functions
docs/                       # project brief and software design document
www/                         # custom CSS/JS/logo, if added later
```

## Module contract

Every calculator is three files that plug into one registry entry. Nothing
outside those three files changes when you add a calculator.

1. **`R/calc/calc_<name>.R`** — pure R functions, no Shiny. Validate inputs,
   call the underlying stats package (prefer wrapping `pwr`, `presize`,
   `epiR`, `WebPower`, `pwrss`, or `TrialSize` over reimplementing formulas),
   and return a plain list of results. Because these have no Shiny
   dependency, they're directly unit-testable — see
   `tests/testthat/test-calc_proportion.R` for the pattern. Generic input
   validators (`.validate_number()`, `.validate_positive()`,
   `.validate_unit_interval()`, `.validate_population()`) live in the shared
   `R/calc/calc_utils.R` rather than being redefined per file — reuse those
   instead of writing a new one with the same check.

2. **`R/content/content_<name>.R`** — a plain R list (or one list per
   sub-design, as in `content_proportion.R`) with:
   - `title`
   - `formula_latex` — one or more MathJax display-math blocks, each wrapped
     in `$$...$$` and typically built with `paste0()` when there's more than
     one (e.g. `paste0("$$h = ...$$", "$$n = ...$$")`) — no separator needed,
     consecutive `$$...$$` blocks just render as consecutive equations. Since
     this is an R string, every LaTeX backslash has to be doubled (`\\frac`,
     `\\alpha`) — R itself treats a single `\` as an escape character. The
     in-app "Formulas & LaTeX" tab on the Home page explains this same
     convention to end users and has a live sandbox to experiment in.
   - `explanation` — markdown, plain-language description of each parameter
   - `worked_example` — markdown, a worked numeric example
   - `citation` — full citation of the original methodological source
   - `backend` — which package/function implements the method

   Content is data, not hardcoded UI — help/reference tabs render this list
   generically.

3. **`R/modules/mod_<name>.R`** — the Shiny module:
   - `mod_<name>_ui(id)` — a `tabsetPanel()` with **Calculate** / **Formula /
     Help** / **Reference** sub-tabs, following `mod_proportion.R`. On the
     Formula/Help tab, render each formula with
     `render_formula_block(<content>$formula_latex)` (from the shared
     `R/modules/mod_shared_ui.R`, sourced automatically like every other
     `mod_*.R` file) rather than a bare `withMathJax(HTML(...))` call — it
     renders the same MathJax output plus a collapsible "Show LaTeX source"
     block with a copy-to-clipboard button, so this is a drop-in replacement,
     not an alternative.
   - `mod_<name>_server(id)` — reads inputs, calls the `calc_*` function
     inside a `reactive()` + `tryCatch()`, and renders the result or a
     validation message
   - a small metadata list (`id`, `nav_title`) for the registry

   If the family has more than one design (e.g. Proportions' precision/
   known-value/two-sample split), add a `design` `radioButtons()` +
   `conditionalPanel()` per design, as in `mod_proportion.R`. A
   single-design family doesn't need one — `mod_diagnostic.R` has no
   `design` input at all, since it's one calculation with no variants to
   switch between.

### Wiring it in

Add one entry to `module_registry` in `global.R`:

```r
module_registry <- list(
  list(id = proportion_meta$id, title = proportion_meta$nav_title,
       ui = mod_proportion_ui, server = mod_proportion_server),
  list(id = means_meta$id, title = means_meta$nav_title,
       ui = mod_means_ui, server = mod_means_server)
)
```

`app.R` builds the navbar by iterating this list — it does not need to
change when you add a calculator.

## Home page calculator finder

The Home tab's "Browse calculators" section offers one toggle over two
parallel indexes, both driven by `R/home/home_catalog.R`:

- **By study design** — `study_design_families`, matching
  `docs/checklist_by_design.md`'s own sections (Proportions, Means,
  Case-Control, ...); also mirrors `docs/SDD.md` §7's catalog table.
- **By test family** — `test_families`, matching
  `docs/checklist_by_test.md`'s G*Power-style groupings (t tests, z tests, F
  tests, chi-square tests, exact tests, correlation & regression, survival
  tests, agreement statistics, equivalence/non-inferiority forms).

Both resolve to entries in `calculator_catalog` (in `home_catalog.R`) and
render as one accordion (collapsed by default) of family panels via
`.render_catalog_entry()`. An entry with `built = TRUE` renders as a button
that jumps to the right nav tab and presets that module's internal design
selector; `built = FALSE` renders a "coming soon" note. **When you add a new
calculator module, also add its catalog entry/entries** (and, if it starts a
new family, an entry in `study_design_families` and/or `test_families`) —
otherwise the finder will describe it as not yet implemented even after
you've built it.

## Non-idiomatic-for-plain-R patterns used here

A couple of things in this codebase aren't standard base-R idiom; noted here
since they're easy to miss when skimming the module code.

- **`conditionalPanel()` JS condition strings.** `mod_proportion.R` shows/hides
  input blocks with `conditionalPanel(condition = "input['proportion-design'] ==
  'single'")`. This condition is evaluated as **JavaScript in the browser**,
  not R — and because Shiny modules namespace every input id (prefixing it
  with the module id, e.g. `proportion-design` instead of `design`), the
  condition string is built with `ns("design")` rather than hardcoded, so it
  stays correct if the module is ever mounted under a different id.

- **`do.call()` to build `page_navbar()`'s (and `nav_menu()`'s) tabs
  dynamically.** `app.R` builds one `nav_menu()` per `module_groups` entry
  (each via `do.call(nav_menu, c(list(title = g$title), panels))`, since a
  group's member-module list is itself built at runtime from
  `module_groups`), then passes the whole list of `nav_menu()`s to
  `do.call(page_navbar, c(list(id = ..., title = ..., theme = ...),
  list(home_panel), group_menus))` instead of writing
  `page_navbar(title = ..., home_panel, nav_menu_1, nav_menu_2, ...)` by
  hand. `do.call()` is base R (not Shiny/JS-specific) but is worth flagging
  if you haven't used it before: it calls a function with an argument list
  assembled at runtime, which is how a variable number of dropdowns (and
  variable number of modules within each) gets passed into `...`.

- **`moduleServer()` / `NS()`.** Standard Shiny modules pattern: `NS(id)`
  namespaces UI element ids so multiple instances of a module (or multiple
  modules) never collide, and `moduleServer(id, function(input, output,
  session) {...})` gives the server function a matching, isolated input/output
  scope. Every `mod_*.R` file must use both.

- **`pacman::p_load()` instead of `library()`.** `global.R` installs
  `pacman` itself if missing (`if (!requireNamespace("pacman", quietly =
  TRUE)) install.packages("pacman")`), then calls
  `pacman::p_load(shiny, bslib, pwr)`. Unlike `library()`, `p_load()`
  installs a package automatically if it isn't already present, so a fresh
  clone of this repo doesn't need a separate "install these packages" step
  before `shiny::runApp()` works.

- **Updating a module's input from outside the module.** `home_finder.R`'s
  server logic runs at the top level (not inside `moduleServer()`), and on a
  finder button click it calls `updateRadioButtons(session,
  "proportion-design", selected = ...)` using the module's fully-namespaced
  input id directly, rather than `ns("design")`. This works because
  `update*Input()` functions address inputs by their raw, on-the-page DOM id
  — namespacing (`ns()`) is only needed *inside* a module, to build that
  same id from the bare name. Called from the root session, the
  already-namespaced string is exactly what's needed.

- **`bslib::nav_select()`.** `page_navbar(id = "main_nav", ...)` gives the
  navbar an id; `nav_select("main_nav", "Proportions", session = session)`
  then switches the active tab programmatically (used by the Home hub's
  "jump to calculator" buttons and the guided wizard) instead of the user
  clicking the tab themselves. Targets by nav title regardless of whether
  that `nav_panel` sits directly on the navbar or nested inside a
  `nav_menu()` dropdown (see "Top navbar" above) -- grouping modules into
  dropdowns didn't require any change to this jump mechanism.

- **`numericInput(..., value = NA)` for an optional field.** The precision
  calculator's population size `N` is optional (no finite population
  correction if omitted). `numericInput(ns("N_precision"), ..., value =
  NA)` renders as an empty field in the browser rather than showing a
  literal `NA` — an HTML `<input type="number">` can't hold non-numeric
  text, so it just displays blank. Server-side, an untouched or
  user-cleared field comes back as `NULL` or `NA` respectively; the server
  code normalizes both to `NULL` before calling `calc_proportion_precision()`,
  which treats `N = NULL` as "no correction."

- **`session$ns()` for dynamically created inputs.** `mod_agreement.R`'s
  kappa design needs one proportion input per category, and the number of
  categories is itself a user choice (2-5) -- so those inputs can't be
  written statically in `mod_agreement_ui()`. Instead, `mod_agreement_server()`
  builds them inside a `renderUI()` on the server side, and namespaces each
  one with `session$ns("prop_1")` rather than the `ns()` closure the static
  UI function uses. Both produce the identical namespaced id -- `ns()` is
  just `session$ns()` captured once at UI-build time and handed to the UI
  function as a convenience; server-side code reaches the same namespace
  through the session object directly, since it doesn't have that closure
  in scope.

## Adding the next module

Copy `R/calc/calc_proportion.R`, `R/content/content_proportion.R`, and
`R/modules/mod_proportion.R`, rename to the new calculator, swap the formula
and stats-package call, then:

1. Add one entry to `module_registry` in `global.R`.
2. Flip (or add) its entry/entries in `calculator_catalog` in
   `R/home/home_catalog.R` from `built = FALSE` to `built = TRUE`, with the
   right `nav_target`/`module_input_id`/`design_value`, so the Home finders
   pick it up.

See `docs/SDD.md` §7 for the full calculator catalog and phase plan (means,
case-control, cohort/RR, diagnostic accuracy, correlation, precision-based,
post-hoc power).
