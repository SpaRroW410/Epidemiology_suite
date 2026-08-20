# Sample Size Calculator

An R Shiny web app for sample size and power calculations for community
medicine, epidemiology, and clinical research, with an explained-formula help
tab and original-source citation for every calculator. Background and full
design rationale: [`docs/project-brief.md`](docs/project-brief.md) and
[`docs/SDD.md`](docs/SDD.md).

This is Phase 1 (app shell, Home finders, Proportions module) plus the start
of Phase 2: two complete calculator modules --

- **Proportions** (`R/modules/mod_proportion.R`) -- single proportion
  (precision-based, Cochran's formula, with optional finite population
  correction), single proportion vs. known value, two independent
  proportions
- **Means** (`R/modules/mod_means.R`) -- single mean vs. known value, two
  independent means, two paired means (before-after / matched pairs)

Everything else in `docs/SDD.md` §7's catalog (case-control, cohort/RR,
diagnostic accuracy, correlation, precision-based CI-width, survival,
post-hoc power, and 3+ group comparisons for both proportions and means)
remains "coming soon" in the Home finder, per the phase plan.

## Requirements

- R (>= 4.1)
- `pacman` (installed automatically by `global.R` if missing), which in turn
  installs/loads `shiny`, `bslib`, `pwr`. `testthat` is only needed to run
  the test suite:
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
app.R                      # entry point: builds navbar, wires modules + Home finder
global.R                   # pacman::p_load(), source()s R/, defines module_registry
R/
├── modules/                # UI + server per calculator (mod_*.R)
├── calc/                   # pure calculation functions, no Shiny (calc_*.R)
├── content/                 # per-module metadata: formula, text, citation (content_*.R)
└── home/                    # Home page calculator finders (see below)
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
   - `formula_latex` — MathJax-renderable string(s), wrapped in `$$...$$`
   - `explanation` — markdown, plain-language description of each parameter
   - `worked_example` — markdown, a worked numeric example
   - `citation` — full citation of the original methodological source
   - `backend` — which package/function implements the method

   Content is data, not hardcoded UI — help/reference tabs render this list
   generically.

3. **`R/modules/mod_<name>.R`** — the Shiny module:
   - `mod_<name>_ui(id)` — a `tabsetPanel()` with **Calculate** / **Formula /
     Help** / **Reference** sub-tabs, following `mod_proportion.R`
   - `mod_<name>_server(id)` — reads inputs, calls the `calc_*` function
     inside a `reactive()` + `tryCatch()`, and renders the result or a
     validation message
   - a small metadata list (`id`, `nav_title`) for the registry

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

## Home page calculator finders

The Home tab offers two ways to find the right calculator, both driven by
the catalog in `R/home/home_catalog.R`:

- **By study design** — pick the calculator family that matches your study
  (Proportions, Means, Case-Control, ...); matches `docs/SDD.md` §7's
  catalog table.
- **By groups & data type** — pick your outcome type (proportion/mean),
  number of groups (1, 2, or 3+), and — for 2 groups — whether they're
  independent or dependent (paired/matched); for 1 group, whether you have a
  known/reference value to test against or are just estimating with a
  desired precision.

Both finders resolve to an entry in `calculator_catalog` (in
`home_catalog.R`). An entry with `built = TRUE` renders as a button that
jumps to the right nav tab and presets that module's internal design
selector; `built = FALSE` renders a "coming soon" note. **When you add a new
calculator module, also add its catalog entry/entries** (and, if it starts a
new family, an entry in `study_design_families`) — otherwise the finders
will describe it as not yet implemented even after you've built it.

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

- **`do.call()` to build `page_navbar()`'s tabs dynamically.** `app.R` builds
  the list of nav panels from `module_registry` in a loop, then calls
  `do.call(page_navbar, c(list(title = ..., theme = ...), list(home_panel),
  nav_panels))` instead of writing `page_navbar(title = ..., home_panel,
  nav_panel_1, nav_panel_2, ...)` by hand. `do.call()` is base R (not
  Shiny/JS-specific) but is worth flagging if you haven't used it before:
  it calls a function with an argument list assembled at runtime, which is
  how a variable number of calculator tabs gets passed into `...`.

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
  then switches the active tab programmatically (used by the Home finder's
  "jump to calculator" buttons) instead of the user clicking the tab
  themselves.

- **`numericInput(..., value = NA)` for an optional field.** The precision
  calculator's population size `N` is optional (no finite population
  correction if omitted). `numericInput(ns("N_precision"), ..., value =
  NA)` renders as an empty field in the browser rather than showing a
  literal `NA` — an HTML `<input type="number">` can't hold non-numeric
  text, so it just displays blank. Server-side, an untouched or
  user-cleared field comes back as `NULL` or `NA` respectively; the server
  code normalizes both to `NULL` before calling `calc_proportion_precision()`,
  which treats `N = NULL` as "no correction."

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
