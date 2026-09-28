# Software Design Document
## sample2result — Comprehensive Sample Size Calculator for Community Medicine / Epidemiology

| | |
|---|---|
| **Status** | v0.2 — sample-size catalog essentially complete; suite expansion planned |
| **Date** | 28 September 2026 (v0.1: 18 August 2026) |
| **Author** | Mukul |
| **Type** | R Shiny web application |

Forward planning (priorities, the epidemiology-suite expansion, R package, deployment
and every open/blocked item) lives in [`ROADMAP.md`](ROADMAP.md). This document
describes the design as built.

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
  (49 modules, ~155 designs — see §7)
- Per-calculator help content: formula, plain-language explanation, worked example
- Per-calculator citation to the original methodological source and the implementing
  package/formula
- Three ways to find a calculator: browse by design, browse by test family, guided
  wizard (with free-text pre-fill)
- Single-user, stateless, browser-based tool (no accounts, no saved sessions)

### 1.3 Out of scope for the sample-size app — and where each now stands
| Item | Status |
|---|---|
| User accounts, saved calculation history | Still out of scope |
| Results / report export (PDF, DOCX, methods text) | Planned — ROADMAP P1 |
| Study-design consulting (randomization, protocol text) | Partly planned — ROADMAP Track B2 |
| Meta-analysis pooling | Meta-analysis *power* is built; pooling planned — ROADMAP B7 |
| Mobile-native app | Planned via PWA / Android TWA — ROADMAP Track D |
| Analysis of collected data | Planned as the "Analyze" workbench — ROADMAP Track B1/B6 |

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
| Extensibility | A new calculator is three new files plus registry/catalog entries, with no changes to other modules or `app.R` | Met |
| Transparency | Every result traceable to a stated formula, a cited source, and a named backend | Met |
| Usability | A student with no statistics background can get a correct result using in-app guidance alone | Yes for routing — the wizard reaches all 49 modules and all 156 designs (test-enforced) |
| Maintainability | Understandable and modifiable by one part-time developer | Met; docs drift and no CI are the current risks (ROADMAP F3/F4) |

---

## 4. System Architecture

### 4.1 High-level layers

```
┌───────────────────────────────────────────────────────────────┐
│  UI shell  (app.R — bslib::page_navbar)                        │
│  Home hub + 14 nav_menu dropdowns built from module_groups     │
└──────────────┬──────────────────────────────┬─────────────────┘
               │                              │
┌──────────────▼───────────────┐   ┌──────────▼──────────────────┐
│  Home hub (R/home/)           │   │  Calculator modules          │
│  home_catalog.R  — 152 design │   │  (R/modules/mod_*.R)         │
│    entries, two family indexes│   │  UI fn + server fn + meta    │
│  home_finder.R — Browse       │──▶│  Calculate | Formula/Help |  │
│  design_tree/_wizard.R — wizard│  │  Reference                   │
│  design_free_text.R — pre-fill│   └──────────┬──────────────────┘
└───────────────────────────────┘              │
                                    ┌──────────▼──────────────────┐
                                    │  Computation (R/calc/)       │
                                    │  pure functions, no Shiny    │
                                    │  wrap a runtime package, or  │
                                    │  a verified reimplementation,│
                                    │  or a seeded Monte Carlo     │
                                    └──────────┬──────────────────┘
                                    ┌──────────▼──────────────────┐
                                    │  Content (R/content/)        │
                                    │  formula LaTeX, explanation, │
                                    │  worked example, citation,   │
                                    │  backend                     │
                                    └──────────────────────────────┘
```

`global.R` loads packages, sources every file under `R/`, and defines
`module_registry` (id, nav title, UI, server for each module) and `module_groups`
(which modules sit in which navbar dropdown). The Home hub jumps to a module with
`bslib::nav_select()` and presets its design with `updateRadioButtons()`.

### 4.2 Design principles
- **Modules are self-contained.** A module owns its inputs, its calculation call, and
  its help/reference content. No shared mutable state between modules.
- **Computation is separated from presentation.** Each module's server calls a plain R
  function (testable without Shiny).
- **Content is data, not hardcoded UI.** Formula, explanation and citation live in a
  per-module list rendered generically.
- **Verify before shipping.** A design ships only after a numeric check against a
  published example, a package oracle, or a simulation of the real test; otherwise it
  stays open (see ROADMAP §4).
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
| UI theme/layout | `bslib::page_navbar()` + `nav_menu()`, Bootswatch "litera", Source Serif 4 | 14 grouped dropdowns |
| Formula rendering | MathJax via `withMathJax()`, wrapped by `render_formula_block()` | adds a copyable LaTeX view |
| Modularity | Shiny modules (`NS()`, `moduleServer()`) | |
| Runtime stats packages | `pwr`, `presize`, `epiR`, `clinfun`, `powerSurvEpi`, `PowerTOST`, `Exact`, `pmsampsize`, `pROC`, `TrialSize`, `powerMediation`, `Hmisc`, `tseries`, `BayesFactor`, `mvtnorm`, `rstatix`, `lme4` (+ `survival`, `stats`) | 19 loaded by `pacman::p_load()` incl. `shiny`/`bslib` |
| Verification-only packages | e.g. `longpower`, `powerlmm`, `RTSA`, `rpact`, `clusterPower`, `ssize.fdr`, `metapower`, `semTools`, `simr`, `voi`, `PracTools`, `WebPower` | installed from `github.com/cran/<pkg>` during development; never loaded by the app |
| Testing | `testthat` unit tests; manual browser checks with Playwright | `shinytest2` + CI planned (ROADMAP P0/P1) |
| Dev environment | `.claude/hooks/session-start.sh` rebuilds R + packages on a fresh container | `renv` lockfile planned (ROADMAP P0) |
| Version control | Git / GitHub | |
| Deployment | Source + `shiny::runApp()` today | hosted, package, Shinylive/PWA/APK options in ROADMAP Track D |

---

## 6. Repository Structure

```
Sample_size_all/
├── app.R                  # builds the grouped navbar + Home hub from the registry
├── global.R               # p_load(), source() of R/, module_registry, module_groups
├── R/
│   ├── calc/              # calc_*.R — pure functions; calc_utils.R — validators, MC search
│   ├── content/           # content_*.R — formula, explanation, example, citation, backend
│   ├── modules/           # mod_*.R — Shiny UI + server; mod_shared_ui.R
│   └── home/              # home_catalog.R, home_finder.R, home_hub.R,
│                          # design_tree.R, design_wizard.R, design_free_text.R
├── tests/testthat/        # test-calc_*.R, test-design_tree.R, test-design_free_text.R,
│                          # test-catalog_consistency.R, ...
├── docs/
│   ├── ROADMAP.md         # forward plan (authoritative for "what next")
│   ├── SDD.md             # this document
│   ├── checklist_by_design.md, checklist_by_test.md
│   ├── design_identification_algorithm.md
│   └── project-brief.md   # original brief (historical)
├── .claude/               # SessionStart hook + settings
├── README.md
└── LICENSE                # GPL-3 (relicensed from MIT, ROADMAP D2)
```

---

## 7. Functional Design — Calculator Catalog

The detailed backlog lives in two checklists, which are the source of truth for build
status and verification evidence:

- **[`checklist_by_design.md`](checklist_by_design.md)** — by study design (81 of 94
  items done).
- **[`checklist_by_test.md`](checklist_by_test.md)** — by statistical test family,
  cross-referenced to G*Power (69 of 74 items done).

Every calculator should be reachable from both files, from the Home hub's Browse
catalog, and — where the decision tree has a branch — from the wizard.

The table below is a snapshot of what is live (28 Sep 2026).

| Family (module) | Designs | Backend | Status |
|---|---|---|---|
| Proportions | Precision (Cochran, +FPC); vs. known value; two independent; Bonferroni post-hoc pairwise | closed form (Cochran); `pwr::pwr.p.test`, `pwr.2p.test`; `TrialSize::OneWayANOVA.PairwiseComparison()` | Live |
| Means | Precision; one-sample; two-sample (equal/unequal n); Welch; paired; one-way ANOVA; planned linear contrast; Bonferroni post-hoc pairwise | `epiR::epi.sssimpleestc()`; `pwr::pwr.t.test`, `pwr.t2n.test`, `pwr.anova.test`; closed form (Julious 2004) for Welch; `TrialSize::Dose.Response.Linear()`, `OneWayANOVA.pairwise()` | Live |
| Incidence Rate | Precision; two rates; Poisson regression (continuous predictor); two negative-binomial rates | `presize::prec_rate()`; closed form (Demidenko 2007); `powerMediation::sizePoisson()`; reimplemented `MKpower::power.nb.test()` (Zhu & Lakkis 2014) | Live |
| Ratio Estimation | Precision-based RR, OR, rate ratio | `presize::prec_riskratio()`, `prec_or()`, `prec_rateratio()` | Live |
| Stratified Sampling | Total n + proportional/Neyman allocation | closed form (Cochran 1977) | Live |
| Cluster / Design Effect | DEFF; DEFF with variable cluster size; WHO EPI cluster survey; two-stage PPS optimal allocation | closed form (Kish 1965); CV-adjusted DEFF verified vs. `clusterPower`; `epiR::epi.ssclus2estb()`; Hansen-Hurwitz-Madow verified vs. `PracTools::clusOpt2()` | Live |
| LQAS | Classification decision rule | closed-form binomial search (Robertson & Valadez 2006) | Live |
| Capture-Recapture | Chapman-Petersen, precision-based | closed form (Chapman 1951; Seber 1982), Monte Carlo verified | Live |
| Case-Control | Unmatched; matched 1:m; case-crossover; nested; case-cohort | `epiR::epi.sscc()`; `powerSurvEpi::powerConLogistic.bin()`/`.con()`; closed form (Cai & Zeng 2004) | Live |
| Cohort / RR | Cohort / cross-sectional RR | `epiR::epi.sscohortc()` | Live |
| Self-Controlled Case Series | SCCS with optional age effects | reimplemented `SCCS::samplesize()` (Musonda et al. 2006) | Live |
| Ecological Study Guidance | Guidance panel, no formula | Morgenstern 1995; Robinson 1950 | Live |
| Diagnostic Accuracy | Se/Sp precision; vs. reference; two tests unpaired/paired; PPV/NPV; LR+/LR−; DOR | closed form (Buderer; Casagrande-Pike; Connor; Altman & Bland); `presize::prec_pos_lr()`/`prec_neg_lr()` | Live |
| ROC / AUC | Single AUC vs. 0.5; two correlated AUCs | `pROC::power.roc.test()` | Live |
| Agreement / Reliability | Kappa; ICC; Cronbach's alpha; Bland-Altman; Lin's CCC | `presize::prec_kappa()`, `prec_icc()`, `prec_cronb()`, `prec_lim_agree()`; closed form (Lin 1989/2000) | Live |
| Pilot / Feasibility | 12/arm rule; precision of a pilot SD | Julious 2005; chi-square CI theory | Live |
| Simon Two-Stage | Minimax and optimal designs | `clinfun::ph2simon()` | Live |
| Equivalence (TOST) | Means; proportions; PK bioequivalence (2×2, 2×2×4, 2×3×3); expected-power bioequivalence | `PowerTOST::sampleN.TOST()`, `expsampleN.TOST()`; `epiR::epi.ssequb()` | Live |
| Non-Inferiority | Means; proportions; OR; HR | `epiR::epi.ssninfc()`, `epi.ssninfb()`; `TrialSize::RelativeRisk.NIS()`, `Cox.NIS()` | Live |
| Crossover Trial (2×2) | Continuous, difference | `TrialSize::TwoSampleCrossOver.Equality()` | Live |
| Group Sequential Design | Continuous/binary/survival boundaries; Lan-DeMets spending (2 looks) + conditional power and sample-size re-estimation | `clinfun::gsdesign.*()`; spending functions verified vs. `rpact`; inverse-normal combination (Lehmacher & Wassmer 1999) | Live |
| Subgroup / Interaction Testing | "4× rule" inflation | closed form (Brookes et al. 2004) | Live |
| Monte Carlo Mixed Models | CRT continuous (LMM); CRT binary (GLMM); growth-curve slope difference | direct simulation + LRT via `lme4::lmer()`/`glmer()`; growth-curve LRT verified vs. `simr::doTest()` | Live |
| Trial Sequential Analysis | Required information size: RR, OR, RD, MD | reimplemented, verified vs. `RTSA::ris()` | Live |
| Stepped-Wedge CRT | Continuous outcome | Hooper et al. (2016) design effect, verified vs. `clusterPower::cpa.sw.normal()` | Live |
| Log-Rank / Survival | Log-rank; Cox PH (binary/continuous); stratified; accrual + noncompliance; weighted log-rank (non-PH) | `powerSurvEpi::ssizeCT()`, `ssizeEpi()`, `ssizeEpiCont()`, `ssize.stratify()`; `Hmisc::cpower()`; simulation of `survival::survdiff(rho=)` | Live |
| Competing Risks | Joint cause-specific / any-cause hazard test | reimplemented `powerCompRisk` (Yang, Fung & Li 2017) with `mvtnorm::pmvnorm()` | Live |
| RMST Comparison | Superiority / non-inferiority | simulation reimplementing `SSRMST` + `survRM2` with `survival::survfit()` (Uno et al.) | Live |
| Prediction Model | Development (binary, continuous, survival); external validation (binary) | `pmsampsize::pmsampsize()`; reimplemented `pmvalsampsize` (Riley et al. 2021) | Live |
| Rule of Three | Upper bound; n to detect ≥ 1 event; disease freedom, imperfect test | closed form (Hanley & Lippman-Hand 1983); `epiR::epi.ssdetect()` | Live |
| Resource Equation | Recommend / check E = N − T | Mead 1988; Charan & Kantharia 2013 | Live |
| Qualitative Sample Size Guidance | Guidance panel, no formula | Guest et al. 2006; Malterud et al. 2016; Patton; Glaser & Strauss | Live |
| Psychometrics Sample Size Guidance | EFA/CFA subjects-per-item; CFA/SEM RMSEA test of close fit; IRT calibration by model | Costello & Osborne 2005 / Comrey & Lee 1992; MacCallum, Browne & Sugawara 1996 verified vs. `semTools`; Linacre 1994, Hulin et al. 1982, Reise & Yu 1990 | Live |
| Value of Information | EVPI; EVSI + ENBS-optimal n | closed-form normal VOI, verified vs. `voi::evpi()`/`evsi()` | Live |
| Correlation | Pearson; two independent r; two dependent r; point-biserial; regression slope; partial; Spearman | `pwr::pwr.r.test()`; closed form (Cohen 1988; Steiger 1980); ARE inflation for Spearman | Live |
| Chi-Square Tests | GoF; R×C independence; McNemar; Mantel-Haenszel; Cochran-Armitage; Cochran's Q | `pwr::pwr.chisq.test()`; `TrialSize::McNemar.Test()`, `Propensity.Score.strata()`, `Cochran.Armitage.Trend()`; simulation of `rstatix::cochran_qtest()` | Live |
| Multiple Regression | R² vs. zero; R² increase | `pwr::pwr.f2.test()` | Live |
| Factorial ANOVA / ANCOVA | General F-test | `pwr::pwr.f2.test()` | Live |
| Logistic Regression | Binary/continuous predictor, simple or covariate-adjusted; ordinal | `powerMediation::SSizeLogisticBin()`/`Con()`; 1/(1−R²) inflation; `Hmisc::posamsize()` | Live |
| Exact Tests | Binomial; Fisher; Boschloo; exact Poisson; sign test | `stats::binom.test()`, `poisson.test()` searches; `Exact::power.exact.test()` | Live |
| RM-ANOVA / Mixed ANOVA | Between; within; interaction | reimplemented `WebPower::wp.rmanova()` | Live |
| Nonparametric Tests | Wilcoxon ×2; Kendall's tau; Kruskal-Wallis; Jonckheere-Terpstra; Friedman; KS; runs test; animal K-sample rank test | `TrialSize::Nonpara.*()`; ARE inflation; simulation of `ks.test()`/`tseries::runs.test()`; `clinfun::power.ladesign()` | Live |
| Variance Tests | One variance; two variances; SD precision | closed form (chi-square / F) | Live |
| Multiplicity Adjustment | Bonferroni/Šidák (proportions, means); FDR (BH) means; exact microarray FDR; Dunnett | wraps this app's own formulas; FDR closed form (simulation-verified); Liu & Hwang 2007 verified vs. `ssize.fdr`; `mvtnorm::qmvt()` | Live |
| MANOVA / Hotelling's T² | Two-group Hotelling's T² | closed-form noncentral F (Rencher 2002) | Live |
| Bayesian Design Analysis | Assurance; Bayes factor design analysis | `Hmisc::gbayes2()`; simulation of `BayesFactor::ttestBF()` | Live |
| Longitudinal / MMRM | Slope difference: Liu & Liang, Diggle, Ard & Edland, Hu et al.; MMRM with dropout, AR(1) | reimplemented `longpower` functions | Live |
| Multilevel / Hierarchical Model | Two- and three-level slope difference | reimplemented `powerlmm` (no-dropout case) | Live |
| Meta-Analysis Power | Number of studies, fixed/random effects | Hedges & Pigott 2004 / Jackson & Turner 2017, verified vs. `metapower` | Live |
| Precision-based (generic CI width) | Risk difference/ratio CI width | covered across Proportions, Means, Rate, Ratio, Variance precision designs | Covered |
| MANOVA (global, k > 2 groups) | Global and special-effect tests | Vonesh & Schork (1986) — not yet implemented | Open (ROADMAP A.3) |

Open, blocked and partially covered items are listed in ROADMAP §4 — none have been
removed.

**Top navbar.** Modules are grouped into 14 `bslib::nav_menu()` dropdowns via
`global.R`'s `module_groups`, ordered roughly simple → advanced: Descriptive &
Estimation; Survey & Cross-Sectional; Observational Studies; Diagnostic & Screening;
Agreement & Reliability; Clinical Trials; Survival Analysis; Prediction Models;
Surveillance; Preclinical / Animal Studies; Qualitative / Mixed Methods;
Psychometrics / Scale Development; Health Economics / Value of Information; General
Statistical Tests. `nav_select()` targets a module by nav title whether it sits in a
dropdown or not. The navbar is now full; the suite expansion needs a navigation
redesign (ROADMAP §5).

### 7.1 "Which calculator?" — the study design identification wizard

A guided questionnaire inside the Home hub that walks a researcher through Stages 1–5
of [`design_identification_algorithm.md`](design_identification_algorithm.md) —
primary aim, allocation/directionality, outcome type, groups/dependence — one
question at a time, showing its reasoning, and ending on a jump button into a live
module or an honest "not yet built" note. A "start over" control is always present.

Implementation: `R/home/design_tree.R` (flat node registry: question nodes with
`options`; terminals with a `catalog_key`, a function of the collected flags, or a
`would_use`/`citation` pair) and `R/home/design_wizard.R` (UI/server at the top
level so it can drive the navbar). `R/home/design_free_text.R` (`walk_free_text()`)
implements Stage 0: a keyword-heuristic parser that pre-fills answers by walking the
same registry and stops at the first question it can't infer. No LLM layer —
deliberately, to keep the app self-contained and deterministic.

**Coverage.** Root offers ten aims: estimate, compare, prediction, diagnostic
accuracy, agreement, qualitative, meta-analysis, relationships (correlation /
regression), "something else" (survey sampling, scale development, rare events,
animal studies, pilots, value of information, genetics), and "I already know which
test". The last branch is generated from `home_catalog.R`'s `test_families` at source
time, so `global.R` sources `home_catalog.R` before the rest of `R/home/`.
Terminals are built with `.term(id, design, key)` (key may be `.by_outcome(cont,
bin)`) or `.term_open(id, design, would_use, citation)`; the open ones are exactly the
not-built items in ROADMAP §4. Cluster-randomised paths show a design-effect note
with jump buttons to Cluster / Design Effect and Monte Carlo Mixed Models.

Enforced by tests: every node and every built catalog entry is reachable from root;
every terminal resolves to a built entry, guidance, or an open item listed in the
ROADMAP; `test-catalog_consistency.R` checks navbar ↔ catalog ↔ module `design`
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
`calc_utils.R`, returns a plain list (inputs echoed back). Monte Carlo designs use
`.mc_search_n1()` and a fixed `seed` argument for reproducibility.
```r
calc_proportion_1s <- function(p0, p1, alpha = 0.05, power = 0.8, alternative = "two.sided") {
  # validate, compute, return list(n = ..., inputs = ...)
}
```

**Module** — `mod_<name>_ui(id)` (Calculate / Formula / Help / Reference tabs;
`design` radio + `conditionalPanel()` per design where there are several),
`mod_<name>_server(id)` (calls the calc function in `reactive()` + `tryCatch()`), and
`<name>_meta <- list(id, nav_title)`.

**Wiring** — a `module_registry` entry and a `module_groups` placement in `global.R`;
one `calculator_catalog` entry per design plus family-index keys in
`home_catalog.R`; a wizard route in `design_tree.R` (the tests require one); tests; and a
tick in both checklists. `app.R` never changes.

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
| Performance | Closed-form designs are near-instant. Monte Carlo designs take ~5–25 s and currently recompute on input change, blocking the R process | Needs a Calculate button + async (ROADMAP F9, P1) |
| Accessibility | `bslib` semantic components; labelled inputs | Not audited (ROADMAP P3) |
| Browser support | Modern evergreen browsers | Met |
| Portability | Deployable to shinyapps.io as-is. Shinylive (WebAssembly) depends on every runtime package having a webR binary — compiled packages (`lme4`, `BayesFactor`, `Hmisc`, `mvtnorm`) are the risk | Spike planned (ROADMAP D3) |
| Reproducibility | Same inputs → same output, including Monte Carlo designs (fixed seeds) | Met in code; package versions not locked (ROADMAP P0) |

---

## 12. Testing Strategy
- **Unit tests** (`testthat`, 474 `test_that()` blocks, 54 files) on every
  `calc_*.R` function and on the wizard/free-text/content logic.
- **Three verification modes** (at least one per design): published worked example;
  real package as oracle (often bit-for-bit, packages installed only for this);
  Monte Carlo simulation of the actual test. Oracle comparisons are recorded in test
  comments and checklist notes.
- **Monte Carlo designs** additionally test type-I-error control, monotonicity (more
  effect → smaller n), and reproducibility under a fixed seed.
- **Browser checks**: each new design is exercised in the running app with Playwright
  before commit (currently ad-hoc scripts, not in the repo).
- **Runtime**: the full suite takes ~6–10 min, mostly `test-calc_glmm.R`.
- **Consistency tests**: `test-design_tree.R` (reachability of every node and built
  entry) and `test-catalog_consistency.R` (navbar ↔ catalog ↔ module design radios).
- **Planned** (ROADMAP P0/P1): fast/slow split, CI, `shinytest2` smoke tests.

---

## 13. Deployment Architecture
- **Today**: run from source (`shiny::runApp()`); shinyapps.io-compatible as-is.
- **Planned** (ROADMAP Track D): Docker image / hosted server; installable R package
  with `run_app()`; Shinylive static site → PWA → Android APK via Trusted Web
  Activity; desktop wrapper. The Shinylive spike is the go/no-go for all offline
  options.

---

## 14. Development Roadmap

The forward plan is [`ROADMAP.md`](ROADMAP.md). The build stages used so far:

| Stage | Scope | Status |
|---|---|---|
| 1 — v1 CORE | Proportions, means, case-control, cohort, ANOVA, correlation, chi-square, diagnostic Se/Sp, ICC, kappa, log-rank, Simon, pilot, TOST | **Done** |
| 1.5 — wizard, guided tree | "Which calculator?" Q&A | **Done** — full coverage since 28 Sep 2026 (ROADMAP F1) |
| 2 — analytical depth | F-family, correlation/regression suite, matched case-control, ROC, Bland-Altman/CCC/Cronbach, prediction models | **Done** (open halves in ROADMAP A.3: MANOVA k>2, non-common-index dependent r, multinomial) |
| 3 — advanced trial designs | Cluster-randomized, stepped-wedge, group-sequential/adaptive, survival extensions, bioequivalence replicates, longitudinal/MMRM | **Done** (open halves: stepped-wedge binary, Lan-DeMets 3+ looks, multilevel with dropout) |
| 4 — niche/simulation & guidance | `simr`-style simulation, SEM, TSA, qualitative/animal guidance, genetics | **Done except genetics** (GWAS / G×E open — ROADMAP A.1) |
| 5 — wizard, free-text half | Keyword parser pre-filling the wizard | **Done** (RCT-internals rules open) |
| 6 — remaining backlog | Everything else in the checklists | **Effectively complete** — 8 batches plus a closing audit; remaining items blocked with documented reasons (ROADMAP §4) |
| 8 — dependency reduction | Shrink runtime package list where reimplementation is safe | **Planned** — now ROADMAP P2 |

Items still open, blocked, or paused by the owner are kept in ROADMAP §4 with their
unblock conditions. The two owner-paused items are external validation for
time-to-event models and model updating/recalibration.

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Formula errors silently produce wrong sample sizes | Mandatory numeric verification before shipping (§12) |
| Package updates change results | Lock versions with `renv` (ROADMAP P0) |
| Docs and navigation drift from the code | Consistency tests (ROADMAP P0); ROADMAP as the single forward-looking doc |
| Development environment lost on container reset | SessionStart hook rebuilds it; `renv` will make it exact |
| Development sandbox cannot reach CRAN or journal sites | `github.com/cran` mirror + apt for packages; web search for citations; items needing paper access stay open rather than guessed |
| Monte Carlo designs block other users on a shared server | Calculate button + `ExtendedTask` before hosting widely (ROADMAP F9) |
| Licence of reimplementations transcribed from GPL packages | Resolved: project relicensed to GPL-3 (ROADMAP F8 / D2); module headers keep naming each source package |
| Scope creep as the project grows into a suite | Workbench-by-workbench milestones with exit criteria (ROADMAP §11) |

---

## 16. Open Questions
- **Suite decisions** — scope, licence, name, distribution target, languages, and when
  to reopen paused items: see ROADMAP §10 (D1–D6).
- **Backend reconciliation:** Proportions' precision design uses the Cochran formula
  and Diagnostic Accuracy's precision design uses Buderer's formula, where the
  checklists name `presize::prec_prop`/`epiR::epi.sssimpleestb` and
  `presize::prec_sens`/`prec_spec`. Both are verified; this is a style question.
  Revisit during Phase 8 / package API work.
- **Reference links:** link citations to DOIs where available? (Useful for the
  planned citation export.)

Resolved since v0.1: `renv` — yes, planned (ROADMAP P0). Checklist maintenance — to be
enforced by consistency tests rather than habit.

---

## Appendix: Dependencies

**Runtime** (loaded by `global.R`): `shiny`, `bslib`, `pwr`, `presize`, `epiR`,
`clinfun`, `powerSurvEpi`, `PowerTOST`, `Exact`, `pmsampsize`, `pROC`, `TrialSize`,
`powerMediation`, `Hmisc`, `tseries`, `BayesFactor`, `mvtnorm`, `rstatix`, `lme4`;
plus `survival` and `stats` from base R. `pacman` loads them.

**Testing**: `testthat` (and `lmerTest`, optional, for one cross-check).

**Verification-only (development)**: installed from `github.com/cran/<pkg>` when a
design is built, never loaded by the app — e.g. `longpower`, `powerlmm`, `RTSA`,
`rpact`, `clusterPower`, `CRTSize`, `ssize.fdr`, `metapower`, `semTools`,
`semPower`, `simr`, `voi`, `PracTools`, `WebPower`, `genpwr`, `iMRMC`, `dfcrm`.
