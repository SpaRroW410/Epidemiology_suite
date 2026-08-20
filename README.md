# Sample Size Calculator

An R Shiny web app for sample size and power calculations for community
medicine, epidemiology, and clinical research, with an explained-formula help
tab and original-source citation for every calculator. Background and full
design rationale: [`docs/project-brief.md`](docs/project-brief.md) and
[`docs/SDD.md`](docs/SDD.md).

This is Phase 1: the navbar app shell plus one complete calculator module
(proportions) that serves as the template for every calculator added later.

## Requirements

- R (>= 4.1)
- Packages: `shiny`, `bslib`, `pwr`, `testthat`
  ```r
  install.packages(c("shiny", "bslib", "pwr", "testthat"))
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
app.R                      # entry point: builds navbar, wires modules
global.R                   # library() calls, source()s R/, defines module_registry
R/
├── modules/                # UI + server per calculator (mod_*.R)
├── calc/                   # pure calculation functions, no Shiny (calc_*.R)
└── content/                 # per-module metadata: formula, text, citation (content_*.R)
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
   `tests/testthat/test-calc_proportion.R` for the pattern.

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

## Adding the next module

Copy `R/calc/calc_proportion.R`, `R/content/content_proportion.R`, and
`R/modules/mod_proportion.R`, rename to the new calculator, swap the formula
and stats-package call, then add one entry to `module_registry` in
`global.R`. See `docs/SDD.md` §7 for the full calculator catalog and phase
plan (means, case-control, cohort/RR, diagnostic accuracy, correlation,
precision-based, post-hoc power).
