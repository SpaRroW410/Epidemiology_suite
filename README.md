# epidemiologicasuite — Sample Size Calculator

An R Shiny web app for sample size and power calculations in community medicine,
epidemiology and clinical research. Every calculator comes with its formula
(rendered in MathJax, with copyable LaTeX), a plain-language explanation, a worked
example, the original methodological citation, and the name of the package or
formula that implements it.

**Current state:** 49 sample-size calculator modules (156 designs) plus eleven
*Analyze* tools (2x2 table analysis, stratified Mantel-Haenszel analysis, person-time rates, standardization and SMR, paired/agreement/trend tests, diagnostic test evaluation, confidence intervals, comparison of two proportions or means, vaccine efficacy, outbreak measures, aberration detection), planning, survey and infectious-disease-model tools, 600+ unit-test blocks and browser-driven
UI smoke tests. The project, app and future package are named **epidemiologicasuite**. The sample-size catalog is essentially complete; the project is now
planning its next step — growing into a wider **epidemiology suite**, an installable
**R package**, and offline/mobile distribution. See
[`docs/ROADMAP.md`](docs/ROADMAP.md).

| Document | What it's for |
|---|---|
| **Documentation site** (pkgdown, `tools/docs/`) | One page per calculator -- formula, explanation, worked example, citation, how it is computed -- plus the roadmap and design documents. Built from the package's own text on every push; published to GitHub Pages from `main` (see below) |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Priorities, review findings, suite/package/deployment plans, and every open or blocked item |
| [`docs/checklist_by_design.md`](docs/checklist_by_design.md) · [`docs/checklist_by_test.md`](docs/checklist_by_test.md) | Per-design build status and the verification evidence behind each one |
| [`docs/to_do_later.md`](docs/to_do_later.md) | Everything not finished yet, in roadmap order, as a checklist (owner decisions marked) |
| [`docs/SDD.md`](docs/SDD.md) | Architecture, module contract, conventions |
| [`docs/design_identification_algorithm.md`](docs/design_identification_algorithm.md) | The logic behind the "Which calculator?" wizard |
| [`docs/project-brief.md`](docs/project-brief.md) | The original project brief (historical) |

---

## What's inside

The top navbar has one item per **workbench** -- *Home*, *Plan: Sample Size* and *Analyze* -- and each
workbench lists its modules in a sidebar, under group headers ordered roughly simple → advanced.

| Group | Module | Designs |
|---|---|---|
| **Descriptive & Estimation** | Proportions | precision-based (Cochran, optional FPC); vs. known value; two independent; Bonferroni post-hoc pairwise |
| | Means | precision-based; vs. known value; two independent (equal/unequal n); Welch (unequal variances); paired; 3+ groups (ANOVA); planned linear contrast; Bonferroni post-hoc pairwise |
| | Incidence Rate | precision-based; two rates; Poisson regression (continuous predictor); two negative-binomial rates |
| | Ratio Estimation | precision-based risk ratio, odds ratio, rate ratio |
| **Survey & Cross-Sectional** | Stratified Sampling | total n + proportional/Neyman allocation |
| | Cluster / Design Effect | DEFF inflation; DEFF with variable cluster size; WHO EPI-style cluster survey; two-stage PPS optimal allocation (take b) |
| | LQAS | lot quality assurance sampling decision rule |
| | Capture-Recapture | two-sample Chapman-Petersen, precision-based |
| **Observational Studies** | Case-Control | unmatched; matched 1:m; case-crossover; nested case-control; case-cohort |
| | Cohort / RR | cohort / cross-sectional relative risk |
| | Self-Controlled Case Series | SCCS with optional age effects |
| | Ecological Study Guidance | guidance panel (no formula) |
| **Diagnostic & Screening** | Diagnostic Accuracy | Se/Sp precision-based; vs. reference value; two tests unpaired/paired; PPV/NPV; LR+/LR−; diagnostic odds ratio |
| | ROC / AUC | single AUC vs. 0.5; two correlated AUCs |
| **Agreement & Reliability** | Agreement / Reliability | Cohen's kappa; ICC; Cronbach's alpha; Bland-Altman limits of agreement; Lin's CCC |
| **Clinical Trials** | Pilot / Feasibility | 12/arm rule; precision of a pilot SD |
| | Simon Two-Stage | minimax and optimal phase II designs |
| | Equivalence (TOST) | two means; two proportions; PK bioequivalence (2×2, 2×2×4, 2×3×3); bioequivalence by expected power |
| | Non-Inferiority | means; proportions; odds ratio; hazard ratio |
| | Crossover Trial (2×2) | continuous outcome, difference |
| | Group Sequential Design | continuous/binary/survival boundaries; Lan-DeMets alpha spending (2 looks) with conditional power and sample-size re-estimation |
| | Subgroup / Interaction Testing | interaction-test inflation ("4× rule") |
| | Monte Carlo Mixed Models | cluster-randomized trial, continuous (LMM) or binary (GLMM); growth-curve slope difference |
| | Trial Sequential Analysis | required information size: RR, OR, RD, MD |
| | Stepped-Wedge CRT | continuous outcome (Hooper et al. 2016) |
| **Survival Analysis** | Log-Rank / Survival | log-rank; Cox PH (binary/continuous covariate); stratified log-rank; accrual + noncompliance; weighted log-rank for non-proportional hazards |
| | Competing Risks | joint cause-specific / any-cause hazard test |
| | RMST Comparison | restricted mean survival time, superiority or non-inferiority |
| **Prediction Models** | Prediction Model | development (binary, continuous, survival); external validation (binary) |
| **Study Planning Tools** | Randomization List | reproducible allocation lists from a seed: permuted blocks (fixed or random block sizes, any allocation ratio), blocks within strata, simple randomization; CSV download and a methods paragraph |
| | Attrition and Non-response | enrol n / prod(1 - loss) over several stages (not n x (1 + loss)), per-arm losses, drop-out / drop-in dilution n / (1 - R_E - R_C)^2 |
| **Survey & Field Tools** | Survey Sample Selection | reproducible selection from a list: simple random, systematic (fractional interval), PPS systematic with certainty units, and the WHO EPI 30 x 7 clusters; CSV and a methods paragraph |
| | Survey Weights and Non-response | design weights, nonresponse adjustment by weighting class, response rates, Kish effective sample size and design effect of weighting |
| **Infectious Disease Models** | Epidemic Models and Herd Immunity | herd-immunity threshold and coverage needed with an imperfect vaccine; deterministic SIR / SEIR epidemic with vaccination (final size, peak, infections averted, plotted); R0 from a growth rate or a final attack fraction |
| **Surveillance** | Rule of Three | upper bound for zero events; n to see ≥ 1 event; disease freedom with an imperfect test |
| **Preclinical / Animal Studies** | Resource Equation | Mead's E = N − T rule |
| **Qualitative / Mixed Methods** | Qualitative Sample Size Guidance | saturation, information power, purposive sampling (no formula) |
| **Psychometrics / Scale Development** | Psychometrics Sample Size Guidance | EFA/CFA subjects-per-item; CFA/SEM RMSEA test of close fit; IRT calibration by model type |
| **Health Economics** | Value of Information | EVPI; EVSI and ENBS-optimal sample size |
| **Analyze Summary Data** | 2x2 Table Analysis | analyze counts you already have: risk/prevalence ratio, odds ratio, risk/prevalence difference, attributable fractions, number needed (NNT/NNH) with confidence intervals; cohort, cross-sectional or case-control layout |
| | Diagnostic Test Evaluation | sensitivity, specificity, PPV, NPV, likelihood ratios with 95% CIs from a 2x2 table (exact or Wilson; PPV/NPV from the counts or at a stated prevalence); serial and parallel combination of 2-6 tests |
| | Confidence Intervals | proportion: Wilson, Clopper-Pearson, Agresti-Coull, Jeffreys, mid-P, Wald side by side; mean (t) and standard deviation (chi-square) from n, mean, SD |
| | Stratified Analysis (Mantel-Haenszel) | 2-8 strata of 2x2 tables: crude vs Mantel-Haenszel adjusted OR / RR / RD with CIs, Cochran-Mantel-Haenszel test, Woolf / Breslow-Day / Tarone homogeneity tests; cohort or case-control |
| | Rates and Rate Ratios | incidence rate with exact / mid-P / Byar / Wald intervals; two groups: rate ratio (exact, mid-P, Wald), rate difference, attributable fractions, exact / mid-P / score tests, from events and person-time; 2-8 strata: Mantel-Haenszel rate ratio and rate difference with homogeneity tests |
| | Paired, Agreement and Trend Tests | McNemar's test and matched-pair OR (exact/Wald), Cohen's kappa (unweighted/linear/quadratic, 2-6 categories) with CI and PABAK, Cochran-Armitage chi-square for trend |
| | Vaccine Efficacy | VE = 1 - relative risk with CIs from attack rates (Koopman / Katz / adjusted log), person-time rates (exact / mid-P / Wald) or case-control / test-negative counts (Woolf / exact) |
| | Outbreak Measures | attack rate; exposure-specific attack rates with risk ratios, risk differences and Fisher's test (the food-specific table); secondary attack rate; case fatality crude and among resolved cases, all with exact / Wilson / mid-P / other intervals |
| | Aberration Detection | CDC EARS C1, C2, C3 and a normal or Poisson CUSUM on a pasted series of counts, with a plot |
| | Compare Two Groups | difference / ratio / odds ratio of two proportions (Wald, Agresti-Caffo, Newcombe, Miettinen-Nurminen, Mee, Koopman, Katz, exact side by side) and two means (Welch, pooled, variance ratio, Cohen's d / Hedges' g) |
| | Standardization and SMR | direct standardization (Fay-Feuer gamma CI, optional two-group comparison), indirect standardization with expected events, SMR with exact and mid-P intervals |
| **General Statistical Tests** | Correlation | Pearson; two independent r; two dependent r; point-biserial; regression slope; partial; Spearman |
| | Chi-Square Tests | goodness of fit; R×C independence; McNemar; Mantel-Haenszel; Cochran-Armitage trend; Cochran's Q |
| | Multiple Regression | R² vs. zero; R² increase |
| | Factorial ANOVA / ANCOVA | general F-test |
| | Logistic Regression | binary/continuous predictor, simple or covariate-adjusted; ordinal (proportional odds) |
| | Exact Tests | binomial; Fisher; Boschloo; exact Poisson; sign test |
| | RM-ANOVA / Mixed ANOVA | between, within, group × time interaction |
| | Nonparametric Tests | Wilcoxon rank-sum and signed-rank; Kendall's tau; Kruskal-Wallis; Jonckheere-Terpstra; Friedman; Kolmogorov-Smirnov; Wald-Wolfowitz runs; animal K-sample rank test |
| | Variance Tests | one variance; two variances; SD precision |
| | Multiplicity Adjustment | Bonferroni/Šidák for proportions and means; FDR (BH) for means; exact microarray FDR (Liu & Hwang); Dunnett multi-arm vs. control |
| | MANOVA / Hotelling's T² | two-group Hotelling's T² |
| | Bayesian Design Analysis | assurance (prior-averaged power); Bayes factor design analysis |
| | Longitudinal / MMRM | slope difference (Liu & Liang, Diggle, Ard & Edland, Hu et al.); MMRM with dropout, AR(1) |
| | Multilevel / Hierarchical Model | two-level and three-level slope difference |
| | Meta-Analysis Power | number of studies for fixed/random-effects meta-analysis |

Design-level detail — formula, backend, worked example and citation — is in each
module's **Formula / Help** and **Reference** tabs, and the verification evidence is
recorded against each item in the two checklists.

### How results are verified

A design only ships once its numbers are checked by at least one of:

1. reproducing a **published worked example** (textbook, original paper, or a
   package's own documented example);
2. matching a **real installed package** used as an oracle, often bit-for-bit;
3. a **Monte Carlo simulation** of the actual test, confirming the target power.

When a formula can't be traced to a citable source and checked numerically, the item
stays open rather than being approximated. Open and blocked items are listed, with
what would unblock them, in [`docs/ROADMAP.md`](docs/ROADMAP.md) §4.

**Vendoring rule.** Packages discovered during development (installed from the
`github.com/cran/<pkg>` source mirror, since `cran.r-project.org` is blocked in the
development sandbox) are used **only as verification oracles**. The shipped app
reimplements the verified formula instead of adding a runtime dependency.

---

## Finding a calculator

The **Home** tab has three helpers:

- **Browse calculators** — one accordion of every built design, switchable between
  *by study design* and *by test family* (G*Power-style). Each entry jumps straight
  to the right module with the right design pre-selected.
- **Which calculator? (guided wizard)** — asks one question at a time (aim,
  experimental vs. observational, selection basis, outcome, groups) and shows its
  reasoning. An optional free-text box pre-fills the answers from a one-sentence
  description of the study. Every one of the 156 designs can be reached from it,
  either through the study-design questions or through its last option, "I
  already know which statistical test I'll use", which browses by test family.
  Designs that are not built yet say so, and say what would unblock them
  (`docs/ROADMAP.md` §4). Tests enforce both.
- **Formulas & LaTeX** — how formulas are written in this app, plus a live LaTeX
  sandbox.

---

## Requirements

- R ≥ 4.3
- The runtime packages are declared in `DESCRIPTION` (`Imports`) and installed with
  the package: `shiny`, `bslib`, `pwr`, `presize`, `clinfun`,
  `powerSurvEpi`, `PowerTOST`, `Exact`, `pmsampsize`, `pROC`, `TrialSize`,
  `powerMediation`, `mvtnorm`, `lme4`.
  `survival`, `stats`, `graphics` and `utils` come with R.
- `testthat` (and `withr`) to run the tests; `epiR`, `rstatix`, `Hmisc`, `tseries` and `BayesFactor` are optional (tests only: they are the
  verification oracles for the closed-form routines that used to call them).

Exact versions are recorded in [`renv.lock`](renv.lock) (R 4.3.3); CI restores
from it. To reproduce that environment: `renv::restore()`. After adding or updating
a package, re-snapshot the runtime and test packages with
`renv::snapshot(packages = c(<DESCRIPTION Imports>, "testthat", "withr", "lmerTest"))`.

In Claude Code on the web, `.claude/hooks/session-start.sh` rebuilds this
environment automatically on a fresh container (Ubuntu `r-cran-*` binaries where
available, otherwise the `github.com/cran` mirror).

## Two ways to use it

- **In the browser, nothing to install:** the app is published on GitHub Pages at `https://sparrow410.github.io/Sample_size_all/app/`
  (documentation at `https://sparrow410.github.io/Sample_size_all/`). It is the same code compiled to WebAssembly and runs
  entirely on your device; nothing you type is sent to a server. The first visit downloads about 60 MB and takes up to a minute
  to start. A few designs need compiled packages that have no WebAssembly build (TOST means, Fisher and Boschloo exact tests) and
  say so; the simulation designs are faster in the installed package.
- **As an R package, everything:** the package contains every design and works offline (below). The browser version is built from
  the package's own `R/` directory by the `docs` workflow (`tools/pages/make_app.R`), so the two cannot drift apart.

## Installing and running the app

epidemiologicasuite is an R package (GPL-3). Install it from GitHub and start the app:

```r
install.packages("remotes")
remotes::install_github("SpaRroW410/Sample_size_all")
epidemiologicasuite::run_app()
```

`run_app(...)` passes its arguments on to `shiny::runApp()` (e.g.
`run_app(port = 8080, launch.browser = FALSE)`); `epidemiologicasuite_app()` returns the
Shiny app object without running it.

From a clone (development), the root `app.R` loads the package with
`pkgload::load_all()`, so `shiny::runApp()` or `Rscript -e 'shiny::runApp()'` from
the repository root still works.

## Running in Docker

```sh
docker build -t epidemiologicasuite .
docker run --rm -p 3838:3838 epidemiologicasuite      # then open http://localhost:3838
# or:  docker compose up --build
```

The image is built from a pinned R base image, installs the dependencies listed in `DESCRIPTION` and the package itself, runs as an
unprivileged user and listens on `$PORT` (default 3838). It needs no internet access at run time. The `docker` workflow builds
it on every relevant push and drives it in headless Chrome; pushes to `main` and `v*` tags also publish it to
`ghcr.io/<owner>/epidemiologicasuite`.

## Documentation site

`tools/docs/build_site_sources.R` writes one article per calculator (from its `*_content` object), the calculator
overview and the project pages into `vignettes/` plus `_pkgdown.yml` (none of it is committed); `pkgdown::build_site()` then
builds the site into `site_out/`. The `docs` workflow does this on every push and keeps the site as a build artifact; on
`main` it also deploys to GitHub Pages. One-time setup for the repository owner: *Settings > Pages > Source: GitHub Actions*.
Locally: `Rscript tools/docs/build_site_sources.R && Rscript -e 'pkgdown::build_site()'`.

## Running tests

```r
testthat::test_local()   # loads the package from the working directory first
```

The tests call internal functions, so they must run inside the package namespace:
use `test_local()` (or `devtools::test()`), not `test_dir()` on its own.

This takes about a minute: the 27 slowest tests (Monte Carlo simulations, ≥ 5 s
each) are skipped. To run everything (~13 minutes, mostly `test-calc_glmm.R`):

```sh
S2R_SLOW_TESTS=true Rscript -e 'testthat::test_local()'
```

**UI smoke tests** (`tests/testthat/test-ui_smoke.R`, ~2 minutes) start the whole app
in headless Chrome with [`shinytest2`](https://rstudio.github.io/shinytest2/) and open
every module, checking that its pane shows, no output is in an error state, its
`result` output is non-empty and no JavaScript error was logged. With
`S2R_SLOW_TESTS=true` they also switch through every design of every module. They need
`shinytest2` and a Chrome/Chromium (set `CHROMOTE_CHROME` if it is not found) and skip
themselves when either is missing, or with `S2R_SKIP_UI=true`. `shinytest2` is not in
`renv.lock` (its current release needs a newer `rlang` than the lock pins); CI installs
version 0.4.1 explicitly. Locally: `remotes::install_version("shinytest2", "0.4.1")`.

A new Monte Carlo test should start with `skip_if_not_slow()`
(`tests/testthat/helper-slow.R`). To run one file:
`testthat::test_local(filter = "calc_proportion")`.

CI (`.github/workflows/tests.yml`) runs the fast suite on every push and pull
request, and the full suite weekly or on demand from the Actions tab.

---

## Repository structure

```
DESCRIPTION, NAMESPACE package metadata (hand-maintained; no roxygen2)
app.R                  development entry point: pkgload::load_all() + epidemiologicasuite_app()
R/                     the package (flat, as R requires; grouped by file-name prefix):
├── run_app.R          run_app() / epidemiologicasuite_app(): grouped navbar + Home hub
├── registry.R         module_registry() + module_groups
├── calc_*.R           pure calculation functions, no Shiny (+ calc_utils.R)
├── content_*.R        per-module formula / explanation / example / citation
├── mod_*.R            Shiny UI + server per module (+ mod_shared_ui.R)
└── home_*.R, design_*.R   Home hub: catalog, browse finder, wizard, free-text parser
man/                   help pages for the two exported functions
tests/testthat/        unit tests (calc_*.R functions, wizard, catalog consistency)
docs/                  roadmap, SDD, checklists, algorithm doc, original brief
.claude/               SessionStart hook that rebuilds the R environment
.github/workflows/     CI (tests.yml), documentation site (docs.yml), container image (docker.yml), browser-build spike (shinylive-spike.yml)
Dockerfile, docker-compose.yml, .dockerignore   container image (tools/docker/ holds its browser smoke test)
tools/                 docs/ (site generator), pages/ (browser build for GitHub Pages), webr-spike/ (Shinylive feasibility checks)
renv.lock              locked package versions
```

## Module contract

Every calculator is three files plus registry entries.

1. **`R/calc_<name>.R`** — pure R, no Shiny. Validate inputs with the shared
   helpers in `calc_utils.R` (`.validate_number()`, `.validate_positive()`,
   `.validate_unit_interval()`, `.validate_population()`), call a runtime package or
   a verified closed form, and return a plain list. Directly unit-testable.
   Monte Carlo designs share the search helper `.mc_search_n1()` and take a fixed
   `seed` so results are reproducible.

2. **`R/content_<name>.R`** — a list (one per design) with `title`,
   `formula_latex`, `explanation`, `worked_example`, `citation`, `backend`.
   `formula_latex` is one or more `$$...$$` blocks joined with `paste0()`; every
   LaTeX backslash is doubled because it's an R string (`\\frac`, `\\alpha`).

3. **`R/mod_<name>.R`** — `mod_<name>_ui(id)` (a `tabsetPanel()` with
   **Calculate / Formula / Help / Reference**), `mod_<name>_server(id)` (calls the
   `calc_*` function inside `reactive()` + `tryCatch()` and renders the result or the
   validation message), and `<name>_meta <- list(id =, nav_title =)`. Render
   formulas with `render_formula_block()` from `mod_shared_ui.R` (MathJax plus a
   copyable LaTeX view). Families with several designs use a `design`
   `radioButtons()` plus one `conditionalPanel()` per design.

### Adding a module

1. Copy the three files of a similar module and adapt them.
2. Add a `module_registry()` entry and put its id in the right `module_groups` entry
   (`R/registry.R`). `R/run_app.R` does not change. If the new file calls a package
   with `pkg::`, add that package to `DESCRIPTION` `Imports`.
3. Add one `calculator_catalog` entry per design in `R/home_catalog.R`
   (`built = TRUE`, `nav_target`, `module_input_id`, `design_value`) and list the
   keys in a `study_design_families` and a `test_families` entry.
4. Route to it from the wizard (`R/home_design_tree.R`): add an option and a
   `.term()` terminal where a study-design branch fits. The "browse by test" branch
   picks up new `test_families` keys automatically. `test-design_tree.R` fails if
   any built catalog entry is unreachable, and `test-catalog_consistency.R` fails if
   the catalog, the navbar and the module's `design` radio values disagree.
5. Add `tests/testthat/test-calc_<name>.R` with a published worked example.
6. Tick the item in both checklists with a short verification note.

---

## Non-idiomatic-for-plain-R patterns used here

- **`conditionalPanel()` conditions are JavaScript**, evaluated in the browser.
  Because modules namespace input ids (`proportion-design`, not `design`), the
  condition string is built with `ns("design")` so it stays correct under any
  module id.
- **`do.call()` builds the navbar.** `epidemiologicasuite_app()` creates one navbar item per
  `module_workbenches` entry (a `navset_pill_list()` sidebar of grouped modules inside it) and
  passes the variable-length list to `page_navbar()` via `do.call()`, which calls a function with
  an argument list assembled at runtime. `jump_to_module()` selects the workbench and then the module.
- **`moduleServer()` / `NS()`** give each module an isolated input/output namespace.
- **Dependencies are declared, not installed at runtime.** The app used to call
  `pacman::p_load()` from `global.R`; as a package it declares them in
  `DESCRIPTION` `Imports` and calls them with `pkg::`, which is what makes
  `remotes::install_github()` install everything it needs.
- **Load order.** Package files load alphabetically, so nothing may use another
  file's objects at load time. `module_registry()` is therefore a function, and
  `home_design_tree.R` is named to sort after `home_catalog.R`, whose
  `test_families` it reads when it loads.
- **Updating a module's input from outside it.** The Home hub runs at the top level
  and calls `updateRadioButtons(session, "proportion-design", ...)` with the
  already-namespaced id; `ns()` is only needed *inside* a module.
- **`bslib::nav_select("main_nav", <title>)`** switches tabs programmatically; it
  works whether the panel sits on the navbar or inside a nested list; use `jump_to_module()`
  (registry.R), which selects the workbench first and then the module.
- **`numericInput(..., value = NA)`** renders an empty optional field; the server
  treats `NULL`/`NA` as "not supplied".
- **`session$ns()` for inputs created in `renderUI()`** — the server-side equivalent
  of the UI's `ns()` closure (used where the number of inputs is itself a user
  choice, e.g. kappa categories).

---

## License

Copyright (C) 2026 Dr. Mukul Maheshwari.

epidemiologicasuite is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, version 3 — see [`LICENSE`](LICENSE). It is distributed in the hope that
it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

The project was relicensed from MIT to GPL-3 on 28 September 2026, because several
modules reimplement code read from GPL-licensed packages (see
[`docs/ROADMAP.md`](docs/ROADMAP.md), finding F8 and decision D2).
