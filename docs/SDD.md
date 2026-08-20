# Software Design Document
## Comprehensive Sample Size Calculator for Community Medicine / Epidemiology

| | |
|---|---|
| **Status** | Draft v0.1 |
| **Date** | 18 August 2026 |
| **Author** | Mukul |
| **Type** | R Shiny web application |

---

## 1. Purpose & Scope

### 1.1 Purpose
Define the architecture, module design, content model, and roadmap for an R Shiny
application that provides sample size and power calculations relevant to community
medicine, epidemiology, and clinical research — with an explained-formula help
system, original-source citations, and a post-hoc power module — so the codebase
stays maintainable as calculators are added over time by one primary developer,
with possible future contributors.

### 1.2 In scope
- Sample size / power calculators across common epidemiological and clinical
  study designs (see §7 catalog)
- Per-calculator help content: formula, plain-language explanation, worked example
- Per-calculator citation to the original methodological source
- Post-hoc / achieved power module, appropriately caveated
- Single-user, stateless, browser-based tool (no accounts, no saved sessions in v1)

### 1.3 Out of scope (v1)
- User accounts, saved calculation history, PDF report export
- Full study design consulting (randomization, blinding, analysis plans)
- Meta-analysis / systematic review sample size pooling
- Mobile-native app (responsive web only)

---

## 2. Background

Existing tools (OpenEpi, PS: Power and Sample Size, Epi Info StatCalc, and various
single-purpose R/Shiny apps such as `presize`, `rashnu`) each cover part of this
space, but none combine broad calculator coverage with an in-app, citation-backed
explanation of each formula and a properly-framed post-hoc power module. This
project's value is that combination, plus long-term extensibility — not novel
statistical methodology.

---

## 3. Goals & Success Criteria

| Goal | Success criterion |
|---|---|
| Correctness | Every calculator's output matches published worked examples and/or cross-checks against OpenEpi/PS within rounding tolerance |
| Extensibility | A new calculator can be added by creating one new module file, without touching existing modules |
| Transparency | Every result is traceable to a stated formula and a cited original source |
| Usability | A student with no statistics background can get a correct result using in-app guidance alone |
| Maintainability | Codebase understandable and modifiable by one part-time developer over months/years |

---

## 4. System Architecture

### 4.1 High-level layers

```
┌─────────────────────────────────────────────┐
│  UI Shell (bslib::page_navbar)               │
│  - Home / About                              │
│  - One nav tab per calculator family         │
│  - Post-hoc Power tab                        │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Calculator Modules (mod_*.R)                 │
│  Each = {UI fn, server fn, metadata}          │
│  Sub-tabs: Calculate | Formula/Help | Reference│
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Computation Layer                            │
│  Thin wrappers around pwr / presize / epiR /  │
│  WebPower / pwrss / TrialSize                 │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Content Layer                                │
│  Per-module metadata: formula (LaTeX string), │
│  explanation text, citation, package/function │
└─────────────────────────────────────────────┘
```

### 4.2 Design principles
- **Modules are self-contained.** A module owns its inputs, its calculation call,
  and its help/reference content. No shared mutable state between modules.
- **Computation is separated from presentation.** Each module's server function
  calls a plain R function (testable outside Shiny) that wraps the underlying
  package call — this makes unit testing possible without spinning up the app.
- **Content is data, not hardcoded UI.** Formula text, explanation, and citation
  live in a metadata list/YAML per module, rendered generically — adding a
  calculator means adding data + one calculation function, not new UI code.

---

## 5. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| App framework | R Shiny | matches existing R fluency |
| UI theme/layout | `bslib::page_navbar()` | modern Bootstrap 5 theming, tabs |
| Formula rendering | MathJax via `withMathJax()` | built into Shiny |
| Modularity | Shiny modules (`NS()`, `moduleServer()`) | standard pattern |
| Stats backends | `pwr`, `presize`, `epiR`, `WebPower`, `pwrss`, `TrialSize` | wrap, don't reimplement |
| Testing | `testthat` | unit tests on computation functions |
| Version control | Git / GitHub | |
| Deployment (v1) | shinyapps.io free tier | |
| Deployment (future option) | Shinylive (WebAssembly, static hosting) | flagged for later; see §11 |

---

## 6. Repository Structure

```
sample-size-app/
├── app.R                      # entry point: builds navbar, wires modules
├── global.R                   # library() calls, source() of R/ files
├── R/
│   ├── modules/
│   │   ├── mod_proportion.R       # UI + server + metadata
│   │   ├── mod_means.R
│   │   ├── mod_case_control.R
│   │   ├── mod_cohort.R
│   │   ├── mod_diagnostic.R
│   │   ├── mod_correlation.R
│   │   ├── mod_precision.R
│   │   └── mod_posthoc_power.R
│   ├── calc/                      # pure calculation functions (testable, no Shiny)
│   │   ├── calc_proportion.R
│   │   ├── calc_means.R
│   │   └── ...
│   └── content/                   # per-module metadata: formula, text, citation
│       ├── content_proportion.R
│       └── ...
├── tests/
│   └── testthat/
│       ├── test-calc_proportion.R
│       └── ...
├── www/                        # any custom CSS/JS, logo
├── docs/
│   ├── project-brief.md
│   └── SDD.md                  # this document
└── README.md
```

---

## 7. Functional Design — Calculator Catalog

The full, detailed calculator backlog — ~90 scenarios across both a study-design
view and a statistical-test view (mirroring and extending G*Power's catalog) —
lives in two living checklist documents, not in this table:

- **[`checklist_by_design.md`](checklist_by_design.md)** — organized the way a
  medical researcher thinks ("I'm doing a case-control study"): 17 sections
  from descriptive/estimation studies through repeated-measures/longitudinal
  designs, each item tagged **[CORE]** (v1) or **[ADV]** (later), with typical
  inputs, the suggested R package/function, and the original citation.
- **[`checklist_by_test.md`](checklist_by_test.md)** — the same catalog
  organized by statistical test family (t / z / F / χ² / Exact, plus
  non-parametric, survival, agreement, equivalence, multilevel, Bayesian, and
  simulation-based methods), explicitly cross-referenced against G*Power's own
  test families and analysis types (Faul et al. 2007, 2009).

Every calculator should be reachable from *both* files (a researcher lands via
design, a statistician via test) — the same Shiny module serves both entry
points, and both files' checkboxes are ticked with a `*(implemented: ...)*`
note as each module goes live, so either file alone shows current build
status. Both files also carry a shared 4-stage build plan (Stage 1 CORE
release through Stage 4 niche/simulation) and a set of caveats (version-
dependent vendor procedure counts, ARE-based non-parametric power, bio-
equivalence input conventions, packages with no confirmed CRAN presence,
etc.) — see those files rather than duplicating them here.

The table below is now just a snapshot of what's *actually live*, kept in
sync with the two checklists above (do not treat it as the source of truth
for what to build next):

| Family | Designs covered | Backend package/function | Status |
|---|---|---|---|
| Proportions | Precision-based (Cochran, +FPC); vs. known value; two independent | closed-form (Cochran); `pwr::pwr.p.test`, `pwr::pwr.2p.test` | Live |
| Means | One-sample, two-sample, paired t-test based | `pwr::pwr.t.test` | Live |
| Diagnostic accuracy | Precision-based (Buderer); vs. reference value; two tests, unpaired/paired | closed-form (Buderer; Casagrande-Pike; Connor), all + Yates' correction | Live |
| Agreement / reliability | Cohen's kappa; ICC | `presize::prec_kappa()` (→ `kappaSize`); `presize::prec_icc()` (Bonett 2002) | Live |
| Case-control | Unmatched; matched (1:1 or 1:m) | `epiR::epi.sscc()` | Live |
| Cohort / RR | Cohort, cross-sectional, relative risk | `epiR::epi.sscohortc()` | Live |
| Correlation | Pearson correlation | `pwr::pwr.r.test` | Not started |
| One-way ANOVA | k-group means | `pwr::pwr.anova.test` | Not started |
| Precision-based (generic) | CI-width driven (risk diff/ratio, rate) | `presize`, `precisely` | Not started |
| Survival | Log-rank, accrual/follow-up designs | `powerSurvEpi`, `gsDesign::nSurv` | Not started |
| Post-hoc / achieved power | Given n and observed effect, compute achieved power | reuse each module's engine, solve for power | Not started |

Each row above is (or will be) exactly one `mod_*.R` + `calc_*.R` +
`content_*.R` file set, following the module contract in §8.

---

## 8. Module Contract

Every calculator module follows the same three-part contract so the pattern is
copy-paste-modify for new additions.

**Metadata (content layer)** — plain R list, one per module:
```r
proportion_content <- list(
  title = "Single Proportion vs. Known Value",
  formula_latex = "n = \\frac{Z_{\\alpha/2}^2 \\, p(1-p)}{d^2}",
  explanation = "Where p is the expected proportion, d is the precision...",
  worked_example = "...",
  citation = "Naing L, Winn T, Rusli BN. Practical issues in calculating
               the sample size for prevalence studies. Arch Orofac Sci. 2006.",
  backend = "pwr::pwr.p.test"
)
```

**Calculation function (pure R, no Shiny)**:
```r
calc_proportion_ss <- function(p, d, conf_level = 0.95) {
  # validates inputs, calls pwr::pwr.p.test or closed-form formula,
  # returns a list(n = ..., inputs_echo = ...)
}
```

**Module UI/server (Shiny)**:
```r
mod_proportion_ui  <- function(id) { ... tabsetPanel(Calculate, Formula, Reference) ... }
mod_proportion_server <- function(id) { moduleServer(id, function(input, output, session) {
  # reads inputs, calls calc_proportion_ss(), renders result + validation messages
}) }
```

`app.R` wires modules into the navbar by iterating a registry list — adding a
calculator to the nav does not require editing `app.R`'s structure, only
appending to the registry.

---

## 9. Help / Reference Content Design
- Formula rendered via `withMathJax(helpText(module_content$formula_latex))`
- Explanation and worked example as plain markdown-rendered text
  (`shiny::markdown()` or `includeMarkdown()`)
- Reference sub-tab always shows: full citation, and which package/function
  implements the method, so users can verify independently

---

## 10. Post-hoc Power Module — Special Design Considerations
- Framed explicitly as **"achieved power for planning a replication study"**,
  not as a tool to explain a non-significant p-value
- Formula/Help tab must include a short methodological note (citing Hoenig &
  Heisey 2001, *"The Abuse of Power"*) on why observed power computed from a
  study's own effect size is a monotonic function of the p-value and should not
  be used to justify a null result
- Consider a soft UI nudge: after computing achieved power, surface a link back
  to the Precision-based (CI-width) module as the recommended alternative framing

---

## 11. Non-Functional Requirements

| Requirement | Detail |
|---|---|
| Extensibility | New calculator = new module + calc + content file; no changes to core app shell |
| Input validation | Every numeric input bounded/sanity-checked (e.g., proportions in [0,1]); inline error messages, not crashes |
| Performance | All calculations are closed-form/near-instant; no need for async or caching in v1 |
| Accessibility | Use `bslib` semantic components; label all inputs; sufficient color contrast |
| Browser support | Modern evergreen browsers (Chrome, Firefox, Edge); no IE support needed |
| Portability | Deployable to shinyapps.io as-is; flag any code that would block a future Shinylive port (e.g., avoid packages with compiled system dependencies not available in WebAssembly, where feasible) |

---

## 12. Testing Strategy
- **Unit tests** (`testthat`) on every `calc_*.R` function against known published
  worked examples (textbook or original-article numbers) — this is the primary
  correctness guardrail
- **Cross-validation**: for each calculator, one manual comparison run against
  OpenEpi and/or PS: Power and Sample Size with identical inputs, documented in
  the module's test file as a comment
- **Manual UI smoke test** per module before merging: invalid input handling,
  edge cases (p=0, p=1, n very small)

---

## 13. Deployment Architecture
- **v1**: shinyapps.io free tier, single app instance
- **Future option**: Shinylive export for static hosting (e.g., GitHub Pages) if
  wider distribution to other faculty/students without server costs becomes a
  priority — revisit once calculator catalog stabilizes, since some backend
  packages may need WebAssembly-compatible alternatives

---

## 14. Development Roadmap

Superseded by the 4-stage plan in `checklist_by_design.md` / `checklist_by_test.md`
("Recommendations (staged build plan)"), which is the authoritative, actively
maintained backlog. Summary:

| Stage | Scope | Status |
|---|---|---|
| 1 — v1 CORE (~25 modules) | Single proportion, single mean, two means, two proportions, unmatched case-control, cohort/RR, one-way ANOVA, correlation, chi-square, diagnostic Se/Sp, ICC, kappa, log-rank, Simon two-stage, pilot rules-of-thumb, TOST equivalence | Proportions, Means, Diagnostic Accuracy, Agreement/Reliability (kappa+ICC), Case-Control (unmatched+matched), Cohort/RR live; one-way ANOVA, correlation, chi-square, log-rank, Simon two-stage, pilot rules-of-thumb, TOST equivalence not started |
| 2 — analytical depth | F-family completeness (factorial/RM-ANOVA, ANCOVA, MANOVA), full correlation/regression suite, matched case-control, ROC comparison, Bland-Altman/CCC/Cronbach, prediction-model development (`pmsampsize`) | Not started |
| 3 — advanced trial designs | Cluster-randomized/stepped-wedge, group-sequential/adaptive, survival extensions, bioequivalence replicate designs, longitudinal/MMRM, post-hoc/achieved-power module | Not started |
| 4 — niche/simulation & non-formula | Genetic (`genpwr`), SEM (`semPower`), trial sequential analysis, `simr`-based simulation, guidance-only qualitative/animal-study panels | Not started |
| — | Deployment polish; evaluate Shinylive | Not started |

The original Phase 1-6 table (superseded) is preserved in git history for
reference; Phase 1 (app shell + Proportions template) and most of Phase 2
(Means, diagnostic accuracy) are complete under the new numbering above.

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Formula errors silently produce wrong sample sizes | Mandatory unit test against a published worked example before a module is considered done |
| Scope creep slows down v1 | Phase 1 strictly limited to one working module end-to-end |
| Post-hoc power module misused/misinterpreted by users | In-app methodological caveat is non-optional, shown on the Calculate tab itself, not buried in Help |
| Package API changes (pwr/epiR versions) break calculators | Pin package versions in a lockfile (`renv`) |

---

## 16. Open Questions
- Public GitHub repo from the start, or private until Phase 2–3 complete?
- Any interest in `renv` for dependency locking given multi-month timeline?
- Should the Reference sub-tab link out to DOIs where available, or citation text only?
- **Backend reconciliation:** three already-live calculators use a closed-form
  formula where `checklist_by_design.md`/`checklist_by_test.md` name a
  specific CRAN package instead (Proportions' precision-based design: Cochran
  formula vs. `presize::prec_prop`/`epiR::epi.sssimpleestb`; Diagnostic
  Accuracy's precision-based design: Buderer formula vs.
  `presize::prec_sens`/`prec_spec`). Both are verified correct against
  published worked examples, so this is a style question, not a correctness
  one: reconcile to the named packages for consistency with the "wrap, don't
  reimplement" principle, or leave as-is since they predate the checklist and
  already work? See `checklist_by_design.md`'s "Backend deviations" section.
- **Checklist maintenance:** `checklist_by_design.md` / `checklist_by_test.md`
  are meant to be ticked off as modules go live (per their own legend) — needs
  a habit/reminder (e.g. as a step in each new module's PR/commit) so they
  don't drift out of sync with the codebase the way this table (§7) briefly did.

---

## Appendix: Core Dependencies
`shiny`, `bslib`, `pwr`, `presize`, `precisely`, `epiR`, `WebPower`, `pwrss`,
`TrialSize`, `kappaSize`, `testthat`, `renv` (optional)
