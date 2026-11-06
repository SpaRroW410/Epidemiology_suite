# Software Design Document
## Epidemiological suite (R package `epidemiologysuite`) — sample size, power and analysis tools for community medicine / epidemiology

| | |
|---|---|
| **Status** | v1.0.0 — the release (R package `epidemiologysuite` 1.0.0): catalog essentially complete; Analyze, planning, survey and outbreak tools built; three versions (browser, phone / server, R package); accessibility audited |
| **Date** | 6 November 2026: project documents reorganised (v1.0: 30 October 2026; v0.3: 29 October; v0.2: 28 September; v0.1: 18 August) |
| **Author** | Mukul |
| **Type** | R Shiny web application |

This document describes the design as built and records the decisions behind it (section 17). What is done and what
is open is kept in one place, [`CHECKLIST.md`](CHECKLIST.md), with the open items generated into
[`PENDING.md`](PENDING.md); what changed when is in [`NEWS.md`](../NEWS.md). How the documents are kept: section 18.

---

## 1. Purpose & Scope

### 1.1 Purpose
Define the architecture, module design, content model, and conventions for an R Shiny
application that provides sample size and power calculations relevant to community
medicine, epidemiology, and clinical research — with an explained-formula help
system and original-source citations — so the codebase stays maintainable as
calculators are added over time by one primary developer, with possible future
contributors.

### 1.2 In scope (as built)
- Sample size / power calculators across epidemiological and clinical study designs
  (50 modules, 159 designs in all with the tools below — see §7)
- An *Analyze* workbench (11 tools) that works on counts the user already has; planning tools (randomization lists, attrition),
  survey tools (sample selection, weights) and an infectious-disease model tool
- Per-calculator help content: formula, plain-language explanation, worked example
- Per-calculator citation to the original methodological source and the implementing
  package/formula; export of a justification paragraph, CSV, JSON, BibTeX and RIS
- Ways to find a calculator: a search box (Home and navbar), quick links and task cards, browse by design, browse by test
  family, guided wizard (with free-text pre-fill); from R, `ss_find()` and `run_app(calculator = ...)`
- A phone layout (same app), a light / dark switch, text descriptions of plots, and a **Cite** tab (nine citation formats)
- Every calculation exported as a documented R function (`calc_*()`, 195 of them)
- Single-user, stateless tool (no accounts, no saved sessions); three delivery routes (§13)

### 1.3 Out of scope for the sample-size app — and where each now stands
| Item | Status |
|---|---|
| User accounts, saved calculation history | No accounts; the Studies tab keeps a record in the browser tab only (decision S1) |
| Results / report export (PDF, DOCX, methods text) | Methods paragraph, CSV, JSON, BibTeX, RIS; Word file of a study (Studies, 3 Nov 2026) |
| Study-design consulting (randomization, protocol text) | Randomization lists and attrition built; protocol text partly (the justification paragraph, Studies) |
| Meta-analysis pooling | Meta-analysis *power* is built; pooling open (CHECKLIST WB-01) |
| Mobile app | Phone layout of the same app done (bottom tab bar, one drop-down); PWA icon and Android wrapper open (CHECKLIST DIST-14) |
| Analysis of collected data | Summary-data *Analyze* workbench built; raw-data analysis deferred (decision D1, CHECKLIST WB-09) |

---

## 2. Background

Existing tools (OpenEpi, PS: Power and Sample Size, Epi Info StatCalc, G*Power, and
single-purpose R/Shiny apps such as `presize`, `rashnu`) each cover part of this
space, but none combine broad calculator coverage with an in-app, citation-backed
explanation of each formula and visible verification. This project's value is that
combination, plus long-term extensibility — not novel statistical methodology.

---

## 3. Goals & Success Criteria

| Goal | Success criterion | Status |
|---|---|---|
| Correctness | Every design matches a published worked example, a real package used as an oracle, or a Monte Carlo check of the actual test | Met for every shipped design (474 test blocks) |
| Extensibility | A new calculator is three new files plus registry/catalog entries, with no changes to other modules or `run_app.R` | Met |
| Transparency | Every result traceable to a stated formula, a cited source, and a named backend | Met |
| Usability | A student with no statistics background can get a correct result using in-app guidance alone | Yes for routing — the wizard reaches all 49 modules and all 156 designs (test-enforced) |
| Maintainability | Understandable and modifiable by one part-time developer | Met; CI and consistency tests now guard against drift |

---

## 4. System Architecture

### 4.1 High-level layers

```
┌───────────────────────────────────────────────────────────────┐
│  UI shell  (R/run_app.R — bslib::page_navbar)                  │
│  Home hub + workbenches (Plan, Analyze) + Cite tab; phone layout │
└──────────────┬──────────────────────────────┬─────────────────┘
               │                              │
┌──────────────▼───────────────┐   ┌──────────▼──────────────────┐
│  Home hub (R/home_*.R)        │   │  Calculator modules          │
│  home_catalog.R  — design     │   │  (R/mod_*.R)                 │
│    entries, two family indexes│   │  UI fn + server fn + meta    │
│  home_finder.R — Browse       │──▶│  Calculate | Formula/Help |  │
│  design_tree/_wizard.R — wizard│  │  Reference                   │
│  design_free_text.R — pre-fill│   └──────────┬──────────────────┘
└───────────────────────────────┘              │
                                    ┌──────────▼──────────────────┐
                                    │  Computation (R/calc_*.R)    │
                                    │  pure functions, no Shiny    │
                                    │  wrap a runtime package, or  │
                                    │  a verified reimplementation,│
                                    │  or a seeded Monte Carlo     │
                                    └──────────┬──────────────────┘
                                    ┌──────────▼──────────────────┐
                                    │  Content (R/content_*.R)     │
                                    │  formula LaTeX, explanation, │
                                    │  worked example, citation,   │
                                    │  backend                     │
                                    └──────────────────────────────┘
```

The app is the R package `epidemiologysuite` (`DESCRIPTION`, `NAMESPACE`, flat `R/`).
`R/registry.R` defines `module_registry()` (id, nav title, UI, server for each
module) and `module_workbenches` (which workbench and sidebar group each module sits in);
`R/run_app.R` builds the navbar from them (`epidemiologysuite_app()`; `run_app()` runs it). The Home hub jumps to a module with
`bslib::nav_select()` and presets its design with `updateRadioButtons()`.

Around these layers sit three small cross-cutting pieces: `R/accessibility.R` (accessible names for generated controls, keyboard
access to scrolling results, the pinned result), `R/phone_shell.R` (the phone layout: a media query at 575 px and a script that
builds the calculator drop-down) and `R/citation_info.R` / `R/home_cite.R` (the one place for the citation facts and the Cite tab).
The public R API is the `calc_*()` functions (exported, each documented), `ss_find()`, `run_app()` and `epidemiologysuite_app()`.

### 4.2 Design principles
- **Modules are self-contained.** A module owns its inputs, its calculation call, and
  its help/reference content. No shared mutable state between modules.
- **Computation is separated from presentation.** Each module's server calls a plain R
  function (testable without Shiny).
- **Content is data, not hardcoded UI.** Formula, explanation and citation live in a
  per-module list rendered generically.
- **Verify before shipping.** A design ships only after a numeric check against a
  published example, a package oracle, or a simulation of the real test; otherwise it
  stays open (an open item of `CHECKLIST.md`, with what would unblock it).
- **Vendoring rule.** Wrap a package when it is already a runtime dependency.
  Packages found during development are used only as verification oracles; the shipped
  app reimplements the verified formula rather than adding a runtime dependency.
  (The original "wrap, don't reimplement" preference still applies to existing
  runtime packages.)

---

## 5. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| App framework | R Shiny | |
| UI theme/layout | `bslib::page_navbar()` + `navset_pill_list()`, Bootswatch "litera", Source Serif 4 | workbenches with grouped sidebars |
| Formula rendering | MathJax via `withMathJax()`, wrapped by `render_formula_block()` | adds a copyable LaTeX view |
| Modularity | Shiny modules (`NS()`, `moduleServer()`) | |
| Runtime stats packages | `clinfun`, `mvtnorm`, `lme4`, `survival` (+ `stats`); every other calculation is written out in the app and tested against the package it reproduces (Appendix) | `Imports` in `DESCRIPTION`: these, `shiny`, `bslib`, `promises` and base R |
| Verification-only packages | e.g. `longpower`, `powerlmm`, `RTSA`, `rpact`, `clusterPower`, `ssize.fdr`, `metapower`, `semTools`, `simr`, `voi`, `PracTools`, `WebPower` | installed from `github.com/cran/<pkg>` during development; never loaded by the app |
| Testing | `testthat` unit tests (fast/slow split), `shinytest2` browser tests by area, axe-core accessibility and contrast audits (`tools/ui-audit/`), GitHub Actions CI | section 12 |
| Dev environment | `.claude/hooks/session-start.sh` rebuilds R + packages on a fresh container; `renv.lock` records the versions (CI restores from it) | — |
| Version control | Git / GitHub | |
| Deployment | Browser build, phone / server version, R package, Docker image | section 13; open steps in `CHECKLIST.md` section 7 |

---

## 6. Repository Structure

```
Epidemiology_suite/
├── DESCRIPTION, NAMESPACE # package metadata (NAMESPACE hand-written; roxygen2 builds only the help pages)
├── CITATION.cff           # citation for GitHub / Zenodo
├── app.R                  # development entry point: pkgload::load_all() + epidemiologysuite_app()
├── R/                     # flat (R requires it); grouped by file-name prefix
│   ├── run_app.R          # run_app(), epidemiologysuite_app(): navbar, theme, Home hub, Cite tab
│   ├── registry.R         # module_registry(), module_workbenches
│   ├── calc_*.R           # pure functions, exported with roxygen help; calc_utils.R — validators, MC search
│   ├── content_*.R        # formula, explanation, example, citation, backend
│   ├── mod_*.R            # Shiny UI + server; mod_shared_ui.R (export, curves, advanced options)
│   ├── home_*.R, design_*.R   # home_catalog.R, home_finder.R, home_hub.R, home_cite.R,
│   │                      # home_design_tree.R, design_wizard.R, design_free_text.R
│   ├── ss_find.R, citation_info.R, accessibility.R, phone_shell.R, lazy_modules.R, browser_build.R, memo_cache.R (result cache of the Monte Carlo calculators), background.R (background workers)
├── man/                   # 199 help pages (built with roxygen2, roclets = "rd")
├── vignettes/             # seven package vignettes; articles/ (generated, git-ignored) holds the site's per-calculator pages
├── inst/                  # CITATION, rstudio/addins.dcf
├── tests/testthat/        # test-calc_*.R, wizard, catalog, help pages, citation, phone layout, UI smoke, ...
├── docs/
│   ├── SDD.md             # this document: design as built, decisions
│   ├── CHECKLIST.md       # every item, done or open (the only place status is kept)
│   ├── PENDING.md         # the open items, generated from CHECKLIST.md (tools/docs/build_pending.R)
│   ├── design_identification_algorithm.md   # the guide's specification
│   ├── hosting.md         # the three versions, Connect Cloud steps, adding the Zenodo DOI
│   ├── upstream_reports.md   # bug-report drafts for upstream packages
│   └── archive/           # frozen 6 Nov 2026: ROADMAP, PLAN, to-do, the two first checklists, brief, mock-ups
├── tools/                 # docs/ (site and help-page tools), pages/ (browser build, phone redirect),
│                          # connect/ (Posit Connect Cloud bundle), ui-audit/ (layout and accessibility scans), webr-spike/
├── .claude/               # SessionStart hook + settings
├── .github/workflows/     # tests.yml, docs.yml (site + browser build), connect-bundle.yml, docker.yml, ...
├── renv.lock              # locked package versions
├── README.md
└── LICENSE                # GPL-3 (relicensed from MIT, decision D2)
```

---

## 7. Functional Design — Calculator Catalog

Every design of the catalog, with its source and the package it is tested against, is listed by group in
[`CHECKLIST.md`](CHECKLIST.md) section 2 (215 designs built on 6 Nov 2026), together with the designs not built yet and the open halves
of built ones, each with what would unblock it. The module list in `R/registry.R` and the catalog in `R/home_catalog.R` are
authoritative; every built design is reachable from the Find tab's browse lists, the search box and, where the decision tree has a
branch, from the guide (consistency tests: section 12). The two checklists the catalog was first built from (by study design; by
statistical test, mirroring G*Power) are in `docs/archive/`.

**Navigation (workbenches).** The top navbar has one item per workbench -- Home, *Plan:
Sample Size* (the 49 sample-size and power calculators) and *Analyze* (calculators that
work on counts the user already has) -- and each workbench shows its modules in a
sticky, scrollable `bslib::navset_pill_list()` sidebar under small group headers.
`R/registry.R`'s `module_workbenches` defines the workbenches, their groups and the order;
the Plan groups are ordered roughly simple -> advanced: Descriptive & Estimation; Survey &
Cross-Sectional; Observational Studies; Diagnostic & Screening; Agreement & Reliability;
Clinical Trials; Survival Analysis; Prediction Models; Surveillance; Preclinical / Animal
Studies; Qualitative / Mixed Methods; Psychometrics / Scale Development; Health Economics /
Value of Information; General Statistical Tests. The earlier one-dropdown-per-group navbar
(14 dropdowns, then 15) could not hold a third workbench because bslib dropdowns cannot nest.
`jump_to_module()` opens a module from the Home hub or wizard by selecting its workbench
(`input$main_nav`) and then the module in the workbench's list (`input$<nav_id>`). On phones
the sidebar stacks above the calculator with its height capped.

### 7.1 "Which calculator?" — the study design identification wizard

A guided questionnaire inside the Home hub that walks a researcher through Stages 1–5
of [`design_identification_algorithm.md`](design_identification_algorithm.md) —
primary aim, allocation/directionality, outcome type, groups/dependence — one
question at a time, showing its reasoning, and ending on a jump button into a live
module or an honest "not yet built" note. A "start over" control is always present.

Implementation: `R/home_design_tree.R` (flat node registry: question nodes with
`options`; terminals with a `catalog_key`, a function of the collected flags, or a
`would_use`/`citation` pair) and `R/design_wizard.R` (UI/server at the top
level so it can drive the navbar). `R/design_free_text.R` (`walk_free_text()`)
implements Stage 0: a keyword-heuristic parser that pre-fills answers by walking the
same registry and stops at the first question it can't infer. No LLM layer —
deliberately, to keep the app self-contained and deterministic.

**Coverage.** Root offers ten aims: estimate, compare, prediction, diagnostic
accuracy, agreement, qualitative, meta-analysis, relationships (correlation /
regression), "something else" (survey sampling, scale development, rare events,
animal studies, pilots, value of information, genetics), and "I already know which
test". The last branch is generated from `home_catalog.R`'s `test_families` at source
load time, so `home_design_tree.R` is named to load after `home_catalog.R` (package files
load alphabetically).
Terminals are built with `.term(id, design, key)` (key may be `.by_outcome(cont,
bin)`) or `.term_open(id, design, would_use, citation)`; the open ones are exactly the
not-built items of `CHECKLIST.md` section 2. Cluster-randomised paths show a design-effect note
with jump buttons to Cluster / Design Effect and Monte Carlo Mixed Models.

Enforced by tests: every node and every built catalog entry is reachable from root;
every terminal resolves to a built entry, guidance, or an open item of
`CHECKLIST.md`; `test-catalog_consistency.R` checks navbar ↔ catalog ↔ module `design`
radio values in both directions. Option order matters where free-text rules exist
(rules refer to options by position), so options are only appended there. The
RCT-internals branch still has no free-text rules.

---

## 8. Module Contract

Every calculator module follows the same three-part contract.

**Content** — a plain R list per design:
```r
proportion_content <- list(
  title = "Single Proportion vs. Known Value",
  formula_latex = "$$n = \\frac{Z_{\\alpha/2}^2 \\, p(1-p)}{d^2}$$",
  explanation = "Where p is the expected proportion, d is the precision...",
  worked_example = "...",
  citation = "Naing L, Winn T, Rusli BN. ... Arch Orofac Sci. 2006.",
  backend = "pwr::pwr.p.test"
)
```

**Calculation function** — pure R, no Shiny; validates with the shared helpers in
`calc_utils.R`, returns its result wrapped in `new_ss_result()` (`calc_result.R`,
archived ROADMAP item 8) — a named list (inputs echoed back) with class `ss_result`
added on top, so every field (`n`, `n_total`, whatever that design calls its own
headline number, `inputs`, ...) is exactly what the function would have returned
anyway; the class only adds a generic `print()`/`format()`. Monte Carlo designs use
`.mc_search_n1()` and a fixed `seed` argument for reproducibility.
```r
calc_proportion_1s <- function(p0, p1, alpha = 0.05, power = 0.8, alternative = "two.sided") {
  # validate, compute
  new_ss_result(list(n = ..., inputs = ...))
}
```

**Module** — `mod_<name>_ui(id)` (Calculate / Formula / Help / Reference tabs;
`design` radio + `conditionalPanel()` per design where there are several),
`mod_<name>_server(id)` (calls the calc function in `reactive()` + `tryCatch()`), and
`<name>_meta <- list(id, nav_title)`.

**Wiring** — a `module_registry()` entry and a group of `module_workbenches` in `R/registry.R`;
one `calculator_catalog` entry per design plus family-index keys in
`home_catalog.R`; a guide route in `home_design_tree.R` (the tests require one); tests; and a
line in `CHECKLIST.md`. `run_app.R` never changes.

**Documentation of the calculation function** — every `calc_*()` function is exported and documented: a roxygen block with a title,
one `@param` per argument, `@return` (the components of the `ss_result`), `@examples` (a real worked example with literal values;
long-running ones inside `\donttest{}`) and `@export`; `export(calc_<name>)` in `NAMESPACE`; help pages built with
`roxygen2::roxygenise(roclets = "rd")`. Interval notation in plain-text comments is escaped (`\[0, 1)`) because roxygen reads
markdown. `tests/testthat/test-help_pages.R` enforces all of it. Internal helpers carry `@noRd`.

### 8.1 Adding a module

1. Copy the three files of a similar module and adapt them.
2. Add a `module_registry()` entry and put its id in the right group of `module_workbenches`
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
5. Add `tests/testthat/test-calc_<name>.R` with a published worked example, and, where a package computes the same thing, a
   comparison with it (guarded by `skip_if_not_installed()`).
6. Document the `calc_*` function for users: a roxygen block with a title, one `@param` per argument, `@return`, `@examples`
   (a real worked example, literal values) and `@export`; add `export(calc_<name>)` to `NAMESPACE`; rebuild the help pages with
   `roxygen2::roxygenise(roclets = "rd")`. `tests/testthat/test-help_pages.R` fails if any of that is missing. Plain-text roxygen
   comments use markdown: write interval notation as `\[0, 1)`.
7. Check the new page with `tools/ui-audit/audit.R` and `tools/ui-audit/a11y.R` (no horizontal scroll, no accessibility rule violations).
8. Add the design to `docs/CHECKLIST.md` (its group, the next free ID, its source and reference package), regenerate
   `docs/PENDING.md` and add a line to `NEWS.md` (section 18).

### 8.2 Shiny patterns that are not plain R

- **`conditionalPanel()` conditions are JavaScript**, evaluated in the browser.
  Because modules namespace input ids (`proportion-design`, not `design`), the
  condition string is built with `ns("design")` so it stays correct under any
  module id.
- **`do.call()` builds the navbar.** `epidemiologysuite_app()` creates one navbar item per
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

## 9. Help / Reference Content Design
- Formula rendered by `render_formula_block(content$formula_latex)`
  (`mod_shared_ui.R`): MathJax plus a collapsible raw-LaTeX view with a copy button.
  `formula_latex` is one or more `$$...$$` blocks joined with `paste0()`; LaTeX
  backslashes are doubled in R strings.
- Explanation and worked example rendered with `shiny::markdown()`.
- Reference tab always shows the full citation and the implementing package/function
  (or "closed-form reimplementation, verified against …"), so users can check
  independently.

---

## 10. Post-hoc Power Module — Dropped

A dedicated post-hoc/achieved-power module (given n and an *observed* effect, report
the power achieved) was planned early on, then progressively deprioritized, and is
dropped as a planned deliverable — not merely deferred. Decision (2026-09-13): the
literature this project already cited (Hoenig & Heisey 2001, *"The Abuse of Power"*)
treats observed power as a deterministic, monotonic function of the p-value, so
building it would work against the Transparency goal (§3). No module was ever built.
Each calculator's own "achieved power" field (at a *pre-specified* effect size) is
standard output and unaffected.

---

## 11. Non-Functional Requirements

| Requirement | Detail | Status |
|---|---|---|
| Extensibility | New calculator = module + calc + content files + registry/catalog entries | Met |
| Input validation | Every numeric input bounded/sanity-checked; inline messages, not crashes | Met |
| Performance | Closed-form designs are near-instant. Monte Carlo designs take ~5–25 s and run in a background R process on a server (`R/background.R`, `mirai` + `ExtendedTask`), so they no longer block other users; repeats come from a cache; the curves are not drawn until their panel is opened; calculators load lazily (UI visible in ~27 s in the browser build instead of ~77 s) | Met on a server (background workers); in the browser build simulations run in the page, only on Calculate |
| Accessibility | axe-core scan (WCAG 2.0/2.1 A and AA) of every page at desktop and phone width, light and dark: 0 violations; contrast-checked theme colours; names and keyboard access for generated controls; text descriptions of plots; dark mode | Machine-checked (`tools/ui-audit/a11y.R`); a person's keyboard and screen-reader walk-through still open |
| Mobile | Phone layout of the same app: bottom tab bar, one calculator drop-down, touch-sized controls (`R/phone_shell.R`); phone / server version on Posit Connect Cloud | Checked in an emulated iPhone; not on a real phone |
| Citability | Cite tab (nine formats), `CITATION.cff`, `citation()`; every calculator cites its formula's source | Met; Zenodo DOI 10.5281/zenodo.23794230 (release v1.0.0) |
| Browser support | Modern evergreen browsers | Met |
| Portability | Three versions: browser build (Shinylive / WebAssembly), phone / server version (Posit Connect Cloud), R package | Met: every calculator runs in the browser build (3 Nov 2026) |
| Reproducibility | Same inputs → same output, including Monte Carlo designs (fixed seeds) | Met; package versions locked in `renv.lock` |

---

## 12. Testing Strategy
- **Unit tests** (`testthat`, 942 `test_that()` blocks, 89 files) on every `calc_*.R` function and on the
  wizard / free-text / content / citation logic.
- **Three verification modes** (at least one per design): published worked example;
  real package as oracle (often bit-for-bit, packages installed only for this and
  guarded by `skip_if_not_installed()`); Monte Carlo simulation of the actual test.
  Oracle comparisons are recorded in test comments and checklist notes.
- **Monte Carlo designs** additionally test type-I-error control, monotonicity (more
  effect → smaller n), and reproducibility under a fixed seed.
- **Browser tests** (`shinytest2`, headless Chrome): `test-ui_smoke.R` opens every module (the other areas are in `test-ui_*.R`, split on 4 Nov 2026) and
  checks no output errors; further tests cover the lazy loading, the wizard, Home search, the Cite tab, the phone layout, the
  plot descriptions and `run_app(calculator = ...)`. They skip themselves without Chrome or with `S2R_SKIP_UI=true`.
- **Accessibility and layout scans** (not part of the suite): `tools/ui-audit/audit.R` (layout) and `tools/ui-audit/a11y.R`
  (axe-core, light and dark).
- **Help pages**: `test-help_pages.R` (every export documented, every argument described); `R CMD check --as-cran` also runs
  every example (with `--run-donttest`) and checks code against documentation.
- **Runtime**: the default run skips the slowest tests (Monte Carlo, ≥ 5 s each; `skip_if_not_slow()`); they run with
  `S2R_SLOW_TESTS=true`.
- **CI**: `.github/workflows/tests.yml` — fast suite on every push/PR, full suite weekly or on demand, packages restored from
  `renv.lock`; `docs.yml` builds the documentation site and the browser build and boots it in headless Chrome;
  `connect-bundle.yml` builds and runs the Connect bundle; `docker.yml` builds the image.
- **Consistency tests**: `test-design_tree.R` (reachability of every node and built
  entry) and `test-catalog_consistency.R` (navbar ↔ catalog ↔ module design radios).

---

## 13. Deployment Architecture
One code base, three ways to use it (details and owner steps in [`hosting.md`](hosting.md)):
- **Browser build** (Shinylive / WebAssembly) on GitHub Pages, built by `docs.yml` from the package's own `R/`; desktop browsers.
  Phones cannot run it (about 1 GB of memory, a 64 MB download); a status panel explains the wait, and a redirect sends phones and
  tablets to the version below.
- **Phone / server version** on Posit Connect Cloud: a bundle (`app.R`, `R/`, `manifest.json`) built and run in CI and published
  to the branch `connect` on every push to `main`; Connect Cloud deploys from that branch. Same app, narrow-screen layout.
- **R package** (`remotes::install_github()`, then `run_app()`); a Docker image (`docker.yml`) for institutions.
- **Open** (`CHECKLIST.md` sections 6-7): PWA home-screen icon, Android wrapper, r-universe and CRAN releases, desktop wrapper.

---

## 14. Development Roadmap

What is open is [`PENDING.md`](PENDING.md) (generated from [`CHECKLIST.md`](CHECKLIST.md)); what was done when is
[`NEWS.md`](../NEWS.md). The build stages so far:

| Stage | Scope | Status |
|---|---|---|
| 1 -- v1 core | Proportions, means, case-control, cohort, ANOVA, correlation, chi-square, diagnostic Se/Sp, ICC, kappa, log-rank, Simon, pilot, TOST | Done |
| 2 -- analytical depth | F-family, correlation / regression suite, matched case-control, ROC, Bland-Altman / CCC / Cronbach, prediction models | Done; open halves in CHECKLIST |
| 3 -- advanced trial designs | Cluster-randomised, stepped-wedge, group-sequential, survival extensions, bioequivalence replicates, longitudinal / MMRM | Done; open halves in CHECKLIST |
| 4 -- simulation and guidance | Simulation designs, SEM, TSA, qualitative / animal guidance | Done; genetics open (GEN) |
| 5 -- the guide | Decision tree, free-text reader, research questions | Done; more phrasings wait on real questions (FIND) |
| 6 -- remaining backlog | The rest of the first checklists | Done or blocked with documented reasons |
| 7 -- suite expansion | Analyze workbench, planning and survey tools, outbreak / surveillance tools, infectious-disease models, several units per patient | Done (summary data only, decision D1) |
| 8 -- dependency reduction | Reimplement where safe, test against the original | Done: runtime is `clinfun`, `mvtnorm`, `lme4`, `survival` (two upstream bugs and one published-formula error found on the way) |
| 9 -- devices and interface | Browser build, phone / server version, phone layout, task-first Home, search, accessibility, dark mode, Studies | Done; real-phone checks open (owner) |
| 10 -- package | Exported functions with help pages, `ss_find()`, addin, vignettes, Cite tab | Done; r-universe and CRAN open (owner) |

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Formula errors silently produce wrong sample sizes | Mandatory numeric verification before shipping (§12) |
| Package updates change results | Versions locked in `renv.lock`; CI runs against them |
| Docs and navigation drift from the code | Consistency tests (section 12); status kept only in CHECKLIST.md, PENDING.md generated from it and tested |
| Development environment lost on container reset | SessionStart hook rebuilds it; `renv.lock` records the exact versions |
| Development sandbox cannot reach CRAN or journal sites | `github.com/cran` mirror + apt for packages; web search for citations; items needing paper access stay open rather than guessed |
| Monte Carlo designs block other users on a shared server | Resolved 31 Oct 2026: background workers (`mirai`); each worker is a full R process, so its memory counts against the host's limit |
| Licence of reimplementations transcribed from GPL packages | Resolved: project relicensed to GPL-3 (decision D2); module headers keep naming each source package |
| Scope creep as the project grows into a suite | Scope decision D1 (summary data only); one workbench at a time |

---

## 16. Open Questions
- **Suite decisions** — scope, licence, name, distribution target, languages, and when
  to reopen paused items: section 17 (D1–D6; D6 still open).
- **Backend reconciliation:** Proportions' precision design uses the Cochran formula
  and Diagnostic Accuracy's precision design uses Buderer's formula, where the
  checklists name `presize::prec_prop`/`epiR::epi.sssimpleestb` and
  `presize::prec_sens`/`prec_spec`. Both are verified; this is a style question.
  Revisit during Phase 8 / package API work.
- **Reference links:** link citations to DOIs where available? (Useful for the
  planned citation export.)

Resolved since v0.1: `renv` — yes, `renv.lock` added. Checklist maintenance — enforced by tests (section 18).

---

## 17. Decisions

Owner decisions, recorded 28 September 2026 unless dated (moved here from the archived ROADMAP, section 10).

| # | Question | Decision | Consequences |
|---|---|---|---|
| D1 | Scope: summary-data calculators only, or also raw-data analysis? | **Summary data only, for now**; confirmed 3 Nov 2026: raw data and line lists are too memory-heavy for the browser build and go to a later full (server) app, merged with the owner's `Easy_analysis` application | Raw-data workbench, line lists, epidemic curves and R0 / Rt wait (CHECKLIST WB-09) |
| D2 | Licence | **GPL-3** | `LICENSE` and `DESCRIPTION`; allows transcribing formulas from GPL packages |
| D3 | Name | **`epidemiologysuite`** (renamed with the repository on 30 Oct 2026; earlier `sample2result`, `epidemiologicasuite`); shown to people as "Epidemiological suite" | One package until a CRAN split is wanted |
| D4 | First distribution target | **Hosted web and the R package first**; offline / APK later | Browser build, phone / server version and package done; PWA / APK open |
| D5 | Languages | **English only** | No translation layer |
| D6 | When to reopen the two paused prediction items | *Open* | CHECKLIST OWN-04 |
| H1 | Hosting (21 Oct, 28 Oct 2026) | Browser build on GitHub Pages; the phone / server version on Posit Connect Cloud, phones redirected to it | Long-term hosting open (CHECKLIST DIST-07) |
| H2 | Background computation (31 Oct 2026) | **`mirai`** with `shiny::ExtendedTask` | Monte Carlo calculators run outside the session on a server |
| S1 | Studies: how long the record lasts (3 Nov 2026) | **This browser tab only** (`sessionStorage`) | Survives a reload; lost when the tab is closed; nothing kept on the server |
| S2 | Studies: file format | **A built-in .docx writer** | No new runtime package; `officer` only as a test reference |
| S3 | Studies: recent calculations recorded automatically | **Yes**, the last 20 | Can be added to a study later |
| S4 | Studies: how many | **Three to start, more on request** (soft limit 10) | One drop-down for the studies and Recent calculations |
| S5 | Studies: content of an entry | **Full**: inputs, result, warnings, formula (LaTeX), justification paragraph, citation | |
| W1 | Way of working (November 2026) | One branch per task, tested once at the end, one pull request, merged only on the owner's word after CI is green; branches deleted after merge | |
| W2 | Project documents (6 Nov 2026) | SDD (design, decisions), CHECKLIST (everything, with status), PENDING (generated), NEWS (history); the old files archived | Section 18 |
| F1 | Find: how the research question is read (6 Nov 2026) | **Deterministic only**: the routing tree, study state and one-question gate drafted by the owner with Gemini are built on the existing keyword reader | Nothing is sent anywhere; a language-model reader stays optional (CHECKLIST FIND-14) |
| F2 | Find: the owner's 37-design tree and the guide | **Merged into the guide**: its first question stays, the new branches go inside it | Every end point leads to a calculator or names its open item (FIND-16) |
| F3 | Find: the design cards (fallback, threats, reporting guideline, effect measure, workflow) | **The drafted text, edited**; a claim is cited where a source is found, otherwise marked with a warning sign whose hover says it is a suggestion with no confirmed source | FIND-21, SRC-06 |
| F4 | Find: search terms and codes | **Checkable sources only**: MeSH checked against NLM and published validated design filters; no Emtree / CINAHL / PsycINFO terms, no clinical codes for now | FIND-22, FIND-23; codes optional (FIND-24) |

## 18. How the project documents are kept

| File | Holds | Rule |
|---|---|---|
| `README.md` | What the suite is, the three versions, installing, running, citing | Changes rarely |
| `docs/SDD.md` | The design as built and the decisions | A new design or decision is added here |
| `docs/CHECKLIST.md` | Every item, done or open, by section, each with a stable ID (`SURV-03`); for calculators the source and the reference package | **The only place where status is kept**: tick when done, add new items with the next free ID, never reuse an ID |
| `docs/PENDING.md` | The open items, owner steps first | Generated: `Rscript tools/docs/build_pending.R`; `test-docs_pending.R` fails when it is out of date |
| `NEWS.md` | What was done, by date | One entry per finished piece of work |
| `docs/design_identification_algorithm.md`, `hosting.md`, `upstream_reports.md` | The guide's specification; the owner's hosting steps; bug-report drafts | Kept with the work they describe |
| `docs/find_routing/` | The owner's routing material for Find (drafted with Gemini, 6 Nov 2026) and its review | Source material, not edited; what is built goes into the algorithm document |
| `docs/archive/` | ROADMAP, PLAN, to-do list, the first two checklists, brief, mock-ups, frozen on 6 Nov 2026 | Not edited; code comments that cite "ROADMAP item N" refer to it |

When a piece of work is finished: tick its items in CHECKLIST (adding any new open item it leaves), run the PENDING script, add the
NEWS entry, and update this document if the design or a decision changed. The website publishes CHECKLIST, PENDING, this document and
the algorithm.

---

## Appendix: Dependencies

**Runtime** (`DESCRIPTION` `Imports`): `shiny` (>= 1.8.1), `bslib` (>= 0.7.0), `promises`, `clinfun`, `mvtnorm`, `lme4`;
plus `survival`, `graphics`, `stats` and `utils` from base R. (Fifteen earlier imports, among them `pwr`, `presize`, `epiR`,
`pROC`, `powerMediation`, `pmsampsize`, `powerSurvEpi`, `TrialSize`, `PowerTOST`, `Exact` and `kappaSize`, were replaced by reimplementations that are tested against
the originals.)

**Testing and verification** (`Suggests`): `testthat`, `withr`, `shinytest2`, `chromote`, `jsonlite`, `htmltools`, and the packages used
as oracles by the tests (`pwr`, `epiR`, `powerMediation`, `pmsampsize`, `pROC`, `presize`, `powerSurvEpi`, `TrialSize`, `deSolve`,
`spc`, `rstatix`, `Hmisc`, `tseries`, `BayesFactor`, `DescTools`, `lmerTest`, `sampling`, `surveillance`, ...); tests that need one
skip themselves when it is not installed. `roxygen2` builds the help pages (development only).

**Verification-only (development)**: installed from `github.com/cran/<pkg>` when a
design is built, never loaded by the app — e.g. `longpower`, `powerlmm`, `RTSA`,
`rpact`, `clusterPower`, `CRTSize`, `ssize.fdr`, `metapower`, `semTools`,
`semPower`, `simr`, `voi`, `PracTools`, `WebPower`, `genpwr`, `iMRMC`, `dfcrm`.
