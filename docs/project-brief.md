# Project Brief: Comprehensive Sample Size Calculator (R Shiny)

## Context
I'm a community medicine / public health faculty member (India). I want to build an
extensive, well-documented R Shiny web app for sample size calculation, aimed at
students, faculty, and researchers in community medicine / epidemiology. This will
be a long-running project I add to over time — prioritize clean, modular,
extensible code over a quick one-shot build.

I'm comfortable in R. Basic HTML only. Please explain any non-R-idiomatic Shiny/JS
patterns you use.

## What already exists (so you understand the bar to clear)
OpenEpi, PS Power and Sample Size, Epi Info StatCalc, and a handful of single-purpose
Shiny apps (e.g. `presize`, `precisely`, `rashnu`) already cover individual formulas.
None of them combine: broad calculator coverage + an explained-formula help tab per
calculator + original article citations + a post-hoc power module, in one
maintained, extensible app. That combination is the differentiator — build with
that in mind, not just "another calculator."

## Tech stack
- R Shiny, using `bslib::page_navbar()` for a tabbed layout (one tab per calculator
  family, e.g. Proportions, Means, Case-Control/Cohort, Diagnostic Accuracy,
  Correlation, Survival, Precision-based/CI-width, Post-hoc Power)
- Shiny **modules** (`mod_*.R`, one file per calculator) from day one — do not build
  a monolithic `app.R`. Use a consistent module pattern (UI function + server
  function + a small metadata list for title/description/citation) so adding a new
  calculator later is "copy a module template, change the formula."
- MathJax (built into Shiny, `withMathJax()`) for rendering formulas in help panels
- Lean on existing, well-tested packages rather than reimplementing formulas:
  `pwr`, `presize`, `epiR`, `WebPower`, `pwrss`, `TrialSize` — wrap their functions,
  don't duplicate their math, unless a needed formula isn't covered by any package.

## Structure per calculator module
Each calculator tab should have:
1. **Calculate** sub-tab: inputs → result, with sensible defaults and input validation
   (e.g. proportions bounded [0,1], warn on implausible effect sizes)
2. **Formula/Help** sub-tab: the formula rendered in MathJax, a plain-language
   explanation of each parameter, and worked numeric example
3. **Reference** sub-tab: original source article(s) for the method (full citation),
   plus which R package/function implements it

## Phase plan
- **Phase 1 (MVP):** App skeleton with navbar + 1 fully working module (proportion-
  based sample size, single sample and two-sample) including all three sub-tabs
  above, so I have a working template to replicate.
- **Phase 2:** Add case-control, cohort/RR, mean comparison (t-test based),
  diagnostic accuracy (sensitivity/specificity), correlation modules.
- **Phase 3:** Precision-based (CI-width) module using `presize`/`precisely`.
- **Phase 4:** Post-hoc/achieved power module — frame this explicitly as
  "achieved power for planning replication studies," not as a way to explain away
  a non-significant result. Include an on-page note about why observed power from
  a study's own effect size is discouraged as a post-hoc justification tool, citing
  the relevant methodological literature (e.g. Hoenig & Heisey 2001).
- **Phase 5:** Deployment polish — I'll likely start on shinyapps.io free tier;
  flag anywhere the code would need to change for Shinylive (WebAssembly, static
  hosting) in case I want that later.

## What I want from you right now
Start with Phase 1 only:
1. Project folder structure (modules folder, global.R/app.R split, etc.)
2. A working `app.R` with `bslib` navbar shell
3. One complete module: proportion-based sample size (single proportion vs. known
   value, and two independent proportions), using the `pwr` package, with all three
   sub-tabs (Calculate / Formula / Reference) fully populated
4. A short README explaining how to add a new module following the same pattern

Ask me clarifying questions only if something above is ambiguous — otherwise scaffold
it and I'll iterate from there.
