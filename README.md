# Epidemiological suite — sample size, power and analysis tools

An R Shiny web app for sample size and power calculations in community medicine,
epidemiology and clinical research. Every calculator comes with its formula
(rendered in MathJax, with copyable LaTeX), a plain-language explanation, a worked
example, the original methodological citation, and the name of the package or
formula that implements it.

**Current state (6 November 2026):** 215 designs in 67 calculators -- sample size and power (*Plan*), analysis of counts you
already have (*Analyze*), effect-size converters, planning, survey, outbreak and surveillance tools -- each with its formula, a worked
example and a citable source, checked against a published value, a real package or a simulation. The app is called **Epidemiological
suite**; the R package is `epidemiologysuite`. There are three ways to use it (see below): the browser build on GitHub Pages, the phone /
server version on Posit Connect Cloud, and the R package, in which **every calculation is an exported function with its own help page**.
Unit tests, browser-driven UI tests, an accessibility scan (axe-core, WCAG A/AA, light and dark, desktop and phone) and
`R CMD check --as-cran` back it.

| Document | What it's for |
|---|---|
| [`docs/PENDING.md`](docs/PENDING.md) | **What is still open**, owner steps first (generated from the checklist) |
| [`docs/CHECKLIST.md`](docs/CHECKLIST.md) | Everything, done or open, by the app's groups: every design with its source and the package it is checked against |
| [`NEWS.md`](NEWS.md) | What changed, by date |
| [`docs/SDD.md`](docs/SDD.md) | The design as built: architecture, module contract, verification, decisions, how these documents are kept |
| [`docs/design_identification_algorithm.md`](docs/design_identification_algorithm.md) | The logic behind the guide ("Which calculator?") |
| [`docs/hosting.md`](docs/hosting.md) | The three versions, how each is built, Connect Cloud steps, the Zenodo DOI |
| [`docs/upstream_reports.md`](docs/upstream_reports.md) | Bug reports for upstream packages, drafted for the owner to file |
| [`docs/archive/`](docs/archive/) | The earlier roadmap, plan, to-do list and checklists, frozen on 6 November 2026 |
| **Documentation site** (pkgdown, `tools/docs/`) | One page per calculator (formula, explanation, worked example, citation, how it is computed), the vignettes, and the checklist, pending list and design documents |

---

## What's inside

The navbar has one item per **workbench**: *Home*, *Find* (search, the guide, browse lists, glossary), *Plan: Sample Size*,
*Analyze*, *Studies* (a record of calculations, downloadable as a Word file) and *Cite*. Each workbench lists its calculators under
group headers, roughly simple to advanced:

- **Plan: Sample Size** -- Effect Sizes; Descriptive & Estimation; Survey & Cross-Sectional; Observational Studies; Diagnostic &
  Screening; Agreement & Reliability; Several Measurements per Patient; Clinical Trials; Survival Analysis; Prediction Models;
  Surveillance; Preclinical / Animal Studies; Qualitative / Mixed Methods; Psychometrics / Scale Development; Health Economics / Value
  of Information; Study Planning Tools; Survey & Field Tools; Infectious Disease Models; General Statistical Tests.
- **Analyze** -- from summary counts (2x2 tables, stratified analysis, confidence intervals, rates, standardisation, diagnostic tests,
  agreement, vaccine effectiveness, test comparisons) and outbreaks and surveillance (attack rates, case fatality, EARS, CUSUM).

The full list, one line per design with its source, is [`docs/CHECKLIST.md`](docs/CHECKLIST.md) section 2. Design-level detail --
formula, backend, worked example and citation -- is in each calculator's **Formula / Help** and **Reference** tabs.

### How results are verified

A design only ships once its numbers are checked by at least one of:

1. reproducing a **published worked example** (textbook, original paper, or a
   package's own documented example);
2. matching a **real installed package** used as an oracle, often bit-for-bit;
3. a **Monte Carlo simulation** of the actual test, confirming the target power.

When a formula can't be traced to a citable source and checked numerically, the item
stays open rather than being approximated. Open and blocked items are listed, with
what would unblock them, in [`docs/PENDING.md`](docs/PENDING.md).

**Vendoring rule.** Packages discovered during development (installed from the
`github.com/cran/<pkg>` source mirror, since `cran.r-project.org` is blocked in the
development sandbox) are used **only as verification oracles**. The shipped app
reimplements the verified formula instead of adding a runtime dependency.

---

## Finding a calculator

- **Search** -- one box over every built design (its name, the question it answers and the calculator it lives in: "two means",
  "kappa", "stepped wedge", "eyes per patient"), on Home and in the navbar of every page. Choosing a result opens that calculator on
  that design.
- **Quick links and task cards** on Home -- the most-used calculators, and cards for planning a study, analysing counts, outbreaks and
  surveillance, and survey work.
- **The guide** (Find tab, "Which calculator?") -- one question at a time (aim, experimental or observational, selection, outcome,
  groups) with its reasoning, plus a free-text box that reads a one-sentence description or a research question and answers what it
  can. Every built design can be reached from it; designs not built yet say so and what would unblock them. Tests enforce both.
- **Browse** (Find tab) -- every built design by study design or by test family (G*Power-style), and a glossary.

From R, without opening the app: `ss_find("eyes per patient")` returns the matching designs, and
`run_app(calculator = "eyes per patient")` opens the app on one (a design key from `ss_find()` or a few words). An RStudio /
Positron addin, *Find a sample size calculator*, wraps both.

## Using a calculator page

- **Calculate / Formula / Help / Reference** tabs per calculator; a design selector where a module has several.
- **Advanced options** (folded; sidedness of the test, optional population size) in the most-used calculators.
- **A short result stays pinned** at the bottom of the window while the inputs above it are changed.
- **Export** (folded): a ready-to-paste justification paragraph for a protocol, CSV, JSON, and the citation of the formula's source
  (BibTeX, RIS). **Power / sensitivity curves** (folded; drawn only when opened) have a text description for screen readers.
- **Light / dark** switch in the navbar (starts from the system setting).
- **Studies:** under every result, "Add this result to [Study 1 v] Add" (also at the end of the guide, for the design choice). The
  Studies tab collects the results of each study (repeated use of one calculator becomes a table), keeps notes and the order you choose,
  lists the recent calculations, and downloads the study as a Word file: the sample-size section of a protocol, with inputs, results,
  formulas (LaTeX for Word's equation editor), justification paragraphs and references. The record is kept only in the browser tab (a reload
  keeps it, closing the tab loses it); nothing is saved on a server.
- **On a phone** (screens up to 575 px wide) the navbar becomes a bottom tab bar (Home, Find, Plan, Analyze, Studies, Cite), the long list of
  calculators becomes one drop-down, and controls get touch-sized heights. It is the same app and the same address.
- **Cite** tab: how to cite the software in APA, Vancouver, Harvard, IEEE, MLA, Chicago, BibTeX, RIS or as a sentence for a Methods
  section, with copy and download buttons.

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

## Three ways to use it

One codebase, built into three forms by CI (details and the owner's setup steps: [`docs/hosting.md`](docs/hosting.md)):

1. **In the browser, nothing to install** -- GitHub Pages, `https://sparrow410.github.io/Epidemiology_suite/app/`. The same code compiled to
   WebAssembly runs on your own device and nothing you type is sent to a server. The first visit downloads about 64 MB and needs
   about 1 GB of memory, so it suits desktop browsers. Every design is available there (since 31 Oct 2026); simulations run in the page.
2. **Phone / server version** -- the same app running on Posit Connect Cloud, so a phone only receives a web page (set up by the
   repository owner; phones are redirected to it automatically once its address is configured). What you type is sent to that server.
3. **As an R package, everything** -- works offline, with every design and the fastest simulations (below).

The browser build and the server bundle are made from the package's own `R/` directory by the `docs` and `connect-bundle` workflows,
so the three cannot drift apart. The app compares them in a table ("Three versions: which one should I use?" on Home and on the Cite tab).

## Installing and running the app

epidemiologysuite is an R package (GPL-3). Install it from GitHub and start the app:

```r
install.packages("remotes")
remotes::install_github("SpaRroW410/Epidemiology_suite")
epidemiologysuite::run_app()
```

`run_app(...)` passes its arguments on to `shiny::runApp()` (e.g.
`run_app(port = 8080, launch.browser = FALSE)`); `epidemiologysuite_app()` returns the
Shiny app object without running it.

Find a calculator without opening the app, and open the app straight on one:

```r
library(epidemiologysuite)
ss_find("eyes per patient")            # a data frame: key, design, calculator, answers
run_app(calculator = "eyes per patient")   # a design key from ss_find(), or words (the best match opens)
```

Seven vignettes show the functions at work: `vignette("getting-started")`, `"sample-size-from-r"`, `"analyze-from-r"`, and one per
topic -- `"survival-from-r"`, `"trials-from-r"`, `"diagnostic-accuracy-from-r"`, `"surveillance-from-r"`. Every calculation is also an exported function (195 `calc_*()` functions) with its own help page, every argument described and a
worked example taken from a verified test, for scripts, Quarto and R Markdown:

```r
?calc_means_paired
calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 10)   # design effect 1.45, effective n 290
```

In RStudio or Positron, *Addins > Find a sample size calculator* does the same from a search window. Setting the
environment variable `EPIDEMIOLOGYSUITE_OPEN` to a design key makes a deployment open on that calculator.

On a server, the Monte Carlo calculators run in a background R process (package `mirai`, suggested), so one user's
simulation does not hold up the others. `EPIDEMIOLOGYSUITE_WORKERS` sets the number of background processes (default 1,
0 = calculate in the session); each one is a full R process with its own memory.

From a clone (development), the root `app.R` loads the package with
`pkgload::load_all()`, so `shiny::runApp()` or `Rscript -e 'shiny::runApp()'` from
the repository root still works.

## How to cite

The app has a **Cite** tab with the citation in APA, Vancouver, Harvard, IEEE, MLA, Chicago, BibTeX and RIS, a ready-made sentence
for a Methods section, and copy and download buttons. In R: `citation("epidemiologysuite")`. GitHub's "Cite this repository" reads
`CITATION.cff`. Release v1.0.0 is archived on Zenodo, DOI [10.5281/zenodo.23794230](https://doi.org/10.5281/zenodo.23794230):

> Maheshwari, M. (2026). Epidemiological suite (Version 1.0.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.23794230

The DOI is set in three places (`docs/hosting.md`, "Adding the Zenodo DOI"): `.citation_doi` in `R/citation_info.R`,
`CITATION.cff` and `inst/CITATION`.

## Running in Docker

```sh
docker build -t epidemiologysuite .
docker run --rm -p 3838:3838 epidemiologysuite      # then open http://localhost:3838
# or:  docker compose up --build
```

The image is built from a pinned R base image, installs the dependencies listed in `DESCRIPTION` and the package itself, runs as an
unprivileged user and listens on `$PORT` (default 3838). It needs no internet access at run time. The `docker` workflow builds
it on every relevant push and drives it in headless Chrome; pushes to `main` and `v*` tags also publish it to
`ghcr.io/<owner>/epidemiologysuite`.

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

The default run skips the slowest tests (Monte Carlo simulations, ≥ 5 s
each) and takes about ten minutes with the browser tests, about a minute without them. To run everything (~13 minutes more, mostly `test-calc_glmm.R`):

```sh
S2R_SLOW_TESTS=true Rscript -e 'testthat::test_local()'
```

**UI tests** (`tests/testthat/test-ui_*.R`, split by area: `ui_smoke` opens every module, then `ui_analyze`, `ui_calculators`, `ui_planning`, `ui_studies`, `ui_wizard`, `ui_lazy`, `ui_every_design`) start the whole app
in headless Chrome with [`shinytest2`](https://rstudio.github.io/shinytest2/) and open
every module, checking that its pane shows, no output is in an error state, its
`result` output is non-empty and no JavaScript error was logged. With
`S2R_SLOW_TESTS=true` they also switch through every design of every module. They need
`shinytest2` and a Chrome/Chromium (set `CHROMOTE_CHROME` if it is not found) and skip
themselves when either is missing, or with `S2R_SKIP_UI=true`. `shinytest2` is not in
`renv.lock` (its current release needs a newer `rlang` than the lock pins); CI installs
version 0.4.1 explicitly. Locally: `remotes::install_version("shinytest2", "0.4.1")`.

Other checks that are not part of the test suite:

- `tools/ui-audit/audit.R` — every calculator at desktop and phone width: horizontal scroll, clipped controls, output and console errors.
- `tools/ui-audit/a11y.R` — axe-core (WCAG 2.0/2.1 A and AA) over every calculator; `A11Y_DARK=true` for dark mode. Needs `npm i axe-core` and `AXE_JS=/path/to/axe.min.js`.
- `R CMD build . && R CMD check --as-cran` — help pages, examples (also `--run-donttest`), code/documentation consistency, tests. In the development sandbox it ends with a warning about the missing English UTF-8 locale and a note about the unverifiable clock; both are the sandbox's.

`tests/testthat/test-help_pages.R` fails if an exported function lacks a help page, an argument description, a value or (for `calc_*`) an example.

A new Monte Carlo test should start with `skip_if_not_slow()`
(`tests/testthat/helper-slow.R`). To run one file:
`testthat::test_local(filter = "calc_proportion")`.

CI (`.github/workflows/tests.yml`) runs the fast suite on every push and pull
request, and the full suite weekly or on demand from the Actions tab.

---

## Repository structure

```
DESCRIPTION, NAMESPACE package metadata (NAMESPACE is hand-written; roxygen2 builds only the help pages, roclets = "rd")
CITATION.cff           citation for GitHub and Zenodo (carries the Zenodo DOI, see docs/hosting.md)
app.R                  development entry point: pkgload::load_all() + epidemiologysuite_app()
R/                     the package (flat, as R requires; grouped by file-name prefix):
├── run_app.R          run_app() / epidemiologysuite_app(): grouped navbar, theme, Home hub, Cite tab
├── registry.R         module_registry() + module_workbenches (groups)
├── calc_*.R           pure calculation functions, no Shiny, all exported with roxygen help (+ calc_utils.R)
├── content_*.R        per-module formula / explanation / example / citation
├── mod_*.R            Shiny UI + server per module (+ mod_shared_ui.R: export, curves, advanced options)
├── home_*.R, design_*.R   Home hub (home_hub.R search, cards), catalog, browse finder, wizard, free-text parser
├── ss_find.R          ss_find() and the RStudio / Positron addin
├── home_cite.R, citation_info.R   the Cite tab and the facts behind every citation format (author, version, DOI)
├── mod_studies.R, docx_writer.R, content_input_labels.R   Studies: Add to study, the Studies tab, the Word file (built-in writer), readable names
├── accessibility.R    names and keyboard access for generated controls, the pinned result
├── phone_shell.R      the phone layout (bottom tab bar, calculator drop-down)
└── lazy_modules.R, browser_build.R   lazy loading with progress; notice and checks for the browser build
man/                   help pages (199: every exported function)
inst/                  CITATION (what citation("epidemiologysuite") prints), rstudio/addins.dcf
tests/testthat/        unit tests, browser (shinytest2) tests, help-page, citation, phone-layout and plot-description tests
docs/                  SDD.md, CHECKLIST.md, PENDING.md (generated), the guide's algorithm, hosting.md, upstream_reports.md, archive/
.claude/               SessionStart hook that rebuilds the R environment
.github/workflows/     CI (tests.yml), documentation site and browser build (docs.yml), phone-version bundle (connect-bundle.yml), container image (docker.yml), memory and browser spikes
Dockerfile, docker-compose.yml, .dockerignore   container image (tools/docker/ holds its browser smoke test)
tools/                 docs/ (site generator, help-page tools), pages/ (browser build and phone redirect), connect/ (Posit Connect Cloud bundle), ui-audit/ (layout and accessibility scans), webr-spike/
renv.lock              locked package versions
```

## For developers

The module contract (a `calc_*()` function, a `*_content` list, a Shiny module and their registry and catalog entries), the steps
for adding a module, and the Shiny patterns that are not plain R are in [`docs/SDD.md`](docs/SDD.md) section 8. Every finished
piece of work ticks its items in [`docs/CHECKLIST.md`](docs/CHECKLIST.md), regenerates `docs/PENDING.md`
(`Rscript tools/docs/build_pending.R`) and adds a line to [`NEWS.md`](NEWS.md) (SDD section 18).

---

## License

Copyright (C) 2026 Dr. Mukul Maheshwari.

epidemiologysuite is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, version 3 — see [`LICENSE`](LICENSE). It is distributed in the hope that
it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

The project was relicensed from MIT to GPL-3 on 28 September 2026, because several
modules reimplement code read from GPL-licensed packages (decision D2 in
[`docs/SDD.md`](docs/SDD.md) section 17).
