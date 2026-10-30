# Software Design Document
## Epidemiological suite (R package `epidemiologicasuite`) — sample size, power and analysis tools for community medicine / epidemiology

| | |
|---|---|
| **Status** | v0.3 — catalog essentially complete; Analyze, planning, survey and outbreak tools built; three versions (browser, phone / server, R package); accessibility audited |
| **Date** | 29 October 2026 (v0.2: 28 September 2026; v0.1: 18 August 2026) |
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
| User accounts, saved calculation history | Still out of scope |
| Results / report export (PDF, DOCX, methods text) | Methods paragraph, CSV, JSON, BibTeX, RIS done; PDF / Word still open (ROADMAP Track B2) |
| Study-design consulting (randomization, protocol text) | Randomization lists and attrition built; protocol text partly (the justification paragraph) |
| Meta-analysis pooling | Meta-analysis *power* is built; pooling planned — ROADMAP B7 |
| Mobile app | Phone layout of the same app done (bottom tab bar, one drop-down); PWA home-screen icon and Android wrapper planned — ROADMAP Track D |
| Analysis of collected data | Summary-data *Analyze* workbench built; raw-data analysis deferred (decision D1) |

---|---|
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

The app is the R package `epidemiologicasuite` (`DESCRIPTION`, `NAMESPACE`, flat `R/`).
`R/registry.R` defines `module_registry()` (id, nav title, UI, server for each
module) and `module_workbenches` (which workbench and sidebar group each module sits in);
`R/run_app.R` builds the navbar from them (`epidemiologicasuite_app()`; `run_app()` runs it). The Home hub jumps to a module with
`bslib::nav_select()` and presets its design with `updateRadioButtons()`.

Around these layers sit three small cross-cutting pieces: `R/accessibility.R` (accessible names for generated controls, keyboard
access to scrolling results, the pinned result), `R/phone_shell.R` (the phone layout: a media query at 575 px and a script that
builds the calculator drop-down) and `R/citation_info.R` / `R/home_cite.R` (the one place for the citation facts and the Cite tab).
The public R API is the `calc_*()` functions (exported, each documented), `ss_find()`, `run_app()` and `epidemiologicasuite_app()`.

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
| UI theme/layout | `bslib::page_navbar()` + `navset_pill_list()`, Bootswatch "litera", Source Serif 4 | workbenches with grouped sidebars |
| Formula rendering | MathJax via `withMathJax()`, wrapped by `render_formula_block()` | adds a copyable LaTeX view |
| Modularity | Shiny modules (`NS()`, `moduleServer()`) | |
| Runtime stats packages | `pwr`, `presize`, `clinfun`, `powerSurvEpi`, `PowerTOST`, `Exact`, `pmsampsize`, `pROC`, `TrialSize`, `powerMediation`, `mvtnorm`, `lme4` (+ `survival`, `stats`); `epiR`, `rstatix`, `Hmisc`, `tseries` and `BayesFactor` were removed from the runtime in item 16 | 14 imports in `DESCRIPTION` incl. `shiny`/`bslib` |
| Verification-only packages | e.g. `longpower`, `powerlmm`, `RTSA`, `rpact`, `clusterPower`, `ssize.fdr`, `metapower`, `semTools`, `simr`, `voi`, `PracTools`, `WebPower` | installed from `github.com/cran/<pkg>` during development; never loaded by the app |
| Testing | `testthat` unit tests (fast/slow split), GitHub Actions CI; manual browser checks with Playwright | `shinytest2` planned (ROADMAP P1) |
| Dev environment | `.claude/hooks/session-start.sh` rebuilds R + packages on a fresh container; `renv.lock` records the versions (CI restores from it) | — |
| Version control | Git / GitHub | |
| Deployment | Installable R package (`remotes::install_github()` + `run_app()`) | hosted, package, Shinylive/PWA/APK options in ROADMAP Track D |

---

## 6. Repository Structure

```
Sample_size_all/
├── DESCRIPTION, NAMESPACE # package metadata (NAMESPACE hand-written; roxygen2 builds only the help pages)
├── CITATION.cff           # citation for GitHub / Zenodo
├── app.R                  # development entry point: pkgload::load_all() + epidemiologicasuite_app()
├── R/                     # flat (R requires it); grouped by file-name prefix
│   ├── run_app.R          # run_app(), epidemiologicasuite_app(): navbar, theme, Home hub, Cite tab
│   ├── registry.R         # module_registry(), module_workbenches
│   ├── calc_*.R           # pure functions, exported with roxygen help; calc_utils.R — validators, MC search
│   ├── content_*.R        # formula, explanation, example, citation, backend
│   ├── mod_*.R            # Shiny UI + server; mod_shared_ui.R (export, curves, advanced options)
│   ├── home_*.R, design_*.R   # home_catalog.R, home_finder.R, home_hub.R, home_cite.R,
│   │                      # home_design_tree.R, design_wizard.R, design_free_text.R
│   ├── ss_find.R, citation_info.R, accessibility.R, phone_shell.R, lazy_modules.R, browser_build.R
├── man/                   # 199 help pages (built with roxygen2, roclets = "rd")
├── vignettes/             # three package vignettes; articles/ (generated, git-ignored) holds the site's per-calculator pages
├── inst/                  # CITATION, rstudio/addins.dcf
├── tests/testthat/        # test-calc_*.R, wizard, catalog, help pages, citation, phone layout, UI smoke, ...
├── docs/
│   ├── PLAN.md            # the plan at a glance (what is done, what is next, owner decisions)
│   ├── ROADMAP.md         # forward plan with reasoning and evidence
│   ├── SDD.md             # this document
│   ├── hosting.md         # the three versions, Connect Cloud steps, adding the Zenodo DOI
│   ├── to_do_later.md     # everything still open, as a checklist
│   ├── checklist_by_design.md, checklist_by_test.md
│   ├── design_identification_algorithm.md, design-mockups/
│   └── project-brief.md   # original brief (historical)
├── tools/                 # docs/ (site and help-page tools), pages/ (browser build, phone redirect),
│                          # connect/ (Posit Connect Cloud bundle), ui-audit/ (layout and accessibility scans), webr-spike/
├── .claude/               # SessionStart hook + settings
├── .github/workflows/     # tests.yml, docs.yml (site + browser build), connect-bundle.yml, docker.yml, ...
├── renv.lock              # locked package versions
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

The table below is a snapshot of the sample-size modules as of 28 Sep 2026. Since then the app gained: the *Analyze* workbench (11 tools),
planning tools (randomization list, attrition), survey tools (sample selection, survey weights), an infectious-disease model tool
(herd immunity, SIR / SEIR, R0), outbreak and surveillance tools (attack rates, EARS / CUSUM) and the **Eyes / Lesions per Patient**
module (several correlated measurements per patient: patients needed for a between-patient comparison of two means or proportions,
a within-patient (split-face) comparison of two means, and units per patient needed for a fixed number of patients; verified against
`clusterPower`, `pwr` and simulation). The module list in `R/registry.R` is authoritative.

| Family (module) | Designs | Backend | Status |
|---|---|---|---|
| Proportions | Precision (Cochran, +FPC); vs. known value; two independent; Bonferroni post-hoc pairwise | closed form (Cochran); `pwr::pwr.p.test`, `pwr.2p.test`; `TrialSize::OneWayANOVA.PairwiseComparison()` | Live |
| Means | Precision; one-sample; two-sample (equal/unequal n); Welch; paired; one-way ANOVA; planned linear contrast; Bonferroni post-hoc pairwise | `epiR::epi.sssimpleestc()`; `pwr::pwr.t.test`, `pwr.t2n.test`, `pwr.anova.test`; closed form (Julious 2004) for Welch; `TrialSize::Dose.Response.Linear()`, `OneWayANOVA.pairwise()` | Live |
| Incidence Rate | Precision; two rates; Poisson regression (continuous predictor); two negative-binomial rates | `presize::prec_rate()`; closed form (Demidenko 2007); `powerMediation::sizePoisson()`; reimplemented `MKpower::power.nb.test()` (Zhu & Lakkis 2014) | Live |
| Ratio Estimation | Precision-based RR, OR, rate ratio | `presize::prec_riskratio()`, `prec_or()`, `prec_rateratio()` | Live |
| Stratified Sampling | Total n + proportional/Neyman allocation | closed form (Cochran 1977) | Live |
| Cluster / Design Effect | DEFF; DEFF with variable cluster size; WHO EPI cluster survey; two-stage PPS optimal allocation | closed form (Kish 1965); CV-adjusted DEFF verified vs. `clusterPower`; closed form `.cf_ssclus2estb()` (verified vs. `epiR::epi.ssclus2estb()`); Hansen-Hurwitz-Madow verified vs. `PracTools::clusOpt2()` | Live |
| LQAS | Classification decision rule | closed-form binomial search (Robertson & Valadez 2006) | Live |
| Capture-Recapture | Chapman-Petersen, precision-based | closed form (Chapman 1951; Seber 1982), Monte Carlo verified | Live |
| Case-Control | Unmatched; matched 1:m; case-crossover; nested; case-cohort | closed forms `.cf_sscc_unmatched()` / `.cf_sscc_matched()` (verified vs. `epiR::epi.sscc()`); `powerSurvEpi::powerConLogistic.bin()`/`.con()`; closed form (Cai & Zeng 2004) | Live |
| Cohort / RR | Cohort / cross-sectional RR | closed form `.cf_sscohortc()` (verified vs. `epiR::epi.sscohortc()`) | Live |
| Self-Controlled Case Series | SCCS with optional age effects | reimplemented `SCCS::samplesize()` (Musonda et al. 2006) | Live |
| Ecological Study Guidance | Guidance panel, no formula | Morgenstern 1995; Robinson 1950 | Live |
| Diagnostic Accuracy | Se/Sp precision; vs. reference; two tests unpaired/paired; PPV/NPV; LR+/LR−; DOR | closed form (Buderer; Casagrande-Pike; Connor; Altman & Bland); `presize::prec_pos_lr()`/`prec_neg_lr()` | Live |
| ROC / AUC | Single AUC vs. 0.5; two correlated AUCs | `pROC::power.roc.test()` | Live |
| Agreement / Reliability | Kappa; ICC; Cronbach's alpha; Bland-Altman; Lin's CCC | `presize::prec_kappa()`, `prec_icc()`, `prec_cronb()`, `prec_lim_agree()`; closed form (Lin 1989/2000) | Live |
| Pilot / Feasibility | 12/arm rule; precision of a pilot SD | Julious 2005; chi-square CI theory | Live |
| Simon Two-Stage | Minimax and optimal designs | `clinfun::ph2simon()` | Live |
| Equivalence (TOST) | Means; proportions; PK bioequivalence (2×2, 2×2×4, 2×3×3); expected-power bioequivalence | `PowerTOST::sampleN.TOST()`, `expsampleN.TOST()`; `epiR::epi.ssequb()` | Live |
| Non-Inferiority | Means; proportions; OR; HR | closed forms `.cf_ssninfc()`, `.cf_ssninfb()` (verified vs. `epiR::epi.ssninfc()`, `epi.ssninfb()`); `TrialSize::RelativeRisk.NIS()`, `Cox.NIS()` | Live |
| Crossover Trial (2×2) | Continuous, difference | `TrialSize::TwoSampleCrossOver.Equality()` | Live |
| Group Sequential Design | Continuous/binary/survival boundaries; Lan-DeMets spending (2 looks) + conditional power and sample-size re-estimation | `clinfun::gsdesign.*()`; spending functions verified vs. `rpact`; inverse-normal combination (Lehmacher & Wassmer 1999) | Live |
| Subgroup / Interaction Testing | "4× rule" inflation | closed form (Brookes et al. 2004) | Live |
| Monte Carlo Mixed Models | CRT continuous (LMM); CRT binary (GLMM); growth-curve slope difference | direct simulation + LRT via `lme4::lmer()`/`glmer()`; growth-curve LRT verified vs. `simr::doTest()` | Live |
| Trial Sequential Analysis | Required information size: RR, OR, RD, MD | reimplemented, verified vs. `RTSA::ris()` | Live |
| Stepped-Wedge CRT | Continuous outcome | Hooper et al. (2016) design effect, verified vs. `clusterPower::cpa.sw.normal()` | Live |
| Log-Rank / Survival | Log-rank; Cox PH (binary/continuous); stratified; accrual + noncompliance (`.cf_cpower()`, verified vs. `Hmisc::cpower()`); weighted log-rank (non-PH) | `powerSurvEpi::ssizeCT()`, `ssizeEpi()`, `ssizeEpiCont()`, `ssize.stratify()`; `Hmisc::cpower()`; simulation of `survival::survdiff(rho=)` | Live |
| Competing Risks | Joint cause-specific / any-cause hazard test | reimplemented `powerCompRisk` (Yang, Fung & Li 2017) with `mvtnorm::pmvnorm()` | Live |
| RMST Comparison | Superiority / non-inferiority | simulation reimplementing `SSRMST` + `survRM2` with `survival::survfit()` (Uno et al.) | Live |
| Prediction Model | Development (binary, continuous, survival); external validation (binary) | `pmsampsize::pmsampsize()`; reimplemented `pmvalsampsize` (Riley et al. 2021) | Live |
| Rule of Three | Upper bound; n to detect ≥ 1 event; disease freedom, imperfect test | closed form (Hanley & Lippman-Hand 1983); closed form `.cf_ssdetect()` (verified vs. `epiR::epi.ssdetect()` 2.0.67) | Live |
| Resource Equation | Recommend / check E = N − T | Mead 1988; Charan & Kantharia 2013 | Live |
| Qualitative Sample Size Guidance | Guidance panel, no formula | Guest et al. 2006; Malterud et al. 2016; Patton; Glaser & Strauss | Live |
| Psychometrics Sample Size Guidance | EFA/CFA subjects-per-item; CFA/SEM RMSEA test of close fit; IRT calibration by model | Costello & Osborne 2005 / Comrey & Lee 1992; MacCallum, Browne & Sugawara 1996 verified vs. `semTools`; Linacre 1994, Hulin et al. 1982, Reise & Yu 1990 | Live |
| Value of Information | EVPI; EVSI + ENBS-optimal n | closed-form normal VOI, verified vs. `voi::evpi()`/`evsi()` | Live |
| Correlation | Pearson; two independent r; two dependent r; point-biserial; regression slope; partial; Spearman | `pwr::pwr.r.test()`; closed form (Cohen 1988; Steiger 1980); ARE inflation for Spearman | Live |
| Chi-Square Tests | GoF; R×C independence; McNemar; Mantel-Haenszel; Cochran-Armitage; Cochran's Q | `pwr::pwr.chisq.test()`; `TrialSize::McNemar.Test()`, `Propensity.Score.strata()`, `Cochran.Armitage.Trend()`; simulation using the closed-form `.cf_cochran_q()` (verified vs. `rstatix::cochran_qtest()`) | Live |
| Multiple Regression | R² vs. zero; R² increase | `pwr::pwr.f2.test()` | Live |
| Factorial ANOVA / ANCOVA | General F-test | `pwr::pwr.f2.test()` | Live |
| Logistic Regression | Binary/continuous predictor, simple or covariate-adjusted; ordinal | `powerMediation::SSizeLogisticBin()`/`Con()`; 1/(1−R²) inflation; closed form `.cf_posamsize()` (verified vs. `Hmisc::posamsize()`) | Live |
| Exact Tests | Binomial; Fisher; Boschloo; exact Poisson; sign test | `stats::binom.test()`, `poisson.test()` searches; `Exact::power.exact.test()` | Live |
| RM-ANOVA / Mixed ANOVA | Between; within; interaction | reimplemented `WebPower::wp.rmanova()` | Live |
| Nonparametric Tests | Wilcoxon ×2; Kendall's tau; Kruskal-Wallis; Jonckheere-Terpstra; Friedman; KS; runs test (`.cf_runs_test_p()`, verified vs. `tseries::runs.test()`); animal K-sample rank test | `TrialSize::Nonpara.*()`; ARE inflation; simulation of `ks.test()`/`tseries::runs.test()`; `clinfun::power.ladesign()` | Live |
| Variance Tests | One variance; two variances; SD precision | closed form (chi-square / F) | Live |
| Multiplicity Adjustment | Bonferroni/Šidák (proportions, means); FDR (BH) means; exact microarray FDR; Dunnett | wraps this app's own formulas; FDR closed form (simulation-verified); Liu & Hwang 2007 verified vs. `ssize.fdr`; `mvtnorm::qmvt()` | Live |
| MANOVA / Hotelling's T² | Two-group Hotelling's T² | closed-form noncentral F (Rencher 2002) | Live |
| Bayesian Design Analysis | Assurance; Bayes factor design analysis | closed form `.cf_gbayes2()` (verified vs. `Hmisc::gbayes2()`); simulation of the closed-form JZS Bayes factor `.cf_ttest_bf10()` (verified vs. `BayesFactor::ttestBF()`) | Live |
| Longitudinal / MMRM | Slope difference: Liu & Liang, Diggle, Ard & Edland, Hu et al.; MMRM with dropout, AR(1) | reimplemented `longpower` functions | Live |
| Multilevel / Hierarchical Model | Two- and three-level slope difference | reimplemented `powerlmm` (no-dropout case) | Live |
| Meta-Analysis Power | Number of studies, fixed/random effects | Hedges & Pigott 2004 / Jackson & Turner 2017, verified vs. `metapower` | Live |
| Precision-based (generic CI width) | Risk difference/ratio CI width | covered across Proportions, Means, Rate, Ratio, Variance precision designs | Covered |
| MANOVA (global, k > 2 groups) | Global and special-effect tests | Vonesh & Schork (1986) — not yet implemented | Open (ROADMAP A.3) |

Open, blocked and partially covered items are listed in ROADMAP §4 — none have been
removed.

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
`calc_utils.R`, returns its result wrapped in `new_ss_result()` (`calc_result.R`,
ROADMAP P1 item 8) — a named list (inputs echoed back) with class `ss_result`
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

**Wiring** — a `module_registry()` entry and a `module_groups` placement in `R/registry.R`;
one `calculator_catalog` entry per design plus family-index keys in
`home_catalog.R`; a wizard route in `design_tree.R` (the tests require one); tests; and a
tick in both checklists. `run_app.R` never changes.

**Documentation of the calculation function** — every `calc_*()` function is exported and documented: a roxygen block with a title,
one `@param` per argument, `@return` (the components of the `ss_result`), `@examples` (a real worked example with literal values;
long-running ones inside `\donttest{}`) and `@export`; `export(calc_<name>)` in `NAMESPACE`; help pages built with
`roxygen2::roxygenise(roclets = "rd")`. Interval notation in plain-text comments is escaped (`\[0, 1)`) because roxygen reads
markdown. `tests/testthat/test-help_pages.R` enforces all of it. Internal helpers carry `@noRd`.

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
| Performance | Closed-form designs are near-instant. Monte Carlo designs take ~5–25 s, run only on a Calculate click, but still block the R process while they run; the curves are not drawn until their panel is opened; calculators load lazily (UI visible in ~27 s in the browser build instead of ~77 s) | Calculate button done; background computation (`ExtendedTask`) waits for a decision on a background-process package (ROADMAP F9) |
| Accessibility | axe-core scan (WCAG 2.0/2.1 A and AA) of every page at desktop and phone width, light and dark: 0 violations; contrast-checked theme colours; names and keyboard access for generated controls; text descriptions of plots; dark mode | Machine-checked (`tools/ui-audit/a11y.R`); a person's keyboard and screen-reader walk-through still open |
| Mobile | Phone layout of the same app: bottom tab bar, one calculator drop-down, touch-sized controls (`R/phone_shell.R`); phone / server version on Posit Connect Cloud | Checked in an emulated iPhone; not on a real phone |
| Citability | Cite tab (nine formats), `CITATION.cff`, `citation()`; every calculator cites its formula's source | Met; the Zenodo DOI is an owner step |
| Browser support | Modern evergreen browsers | Met |
| Portability | Deployable to shinyapps.io as-is. Shinylive (WebAssembly) depends on every runtime package having a webR binary — compiled packages (`lme4`, `BayesFactor`, `Hmisc`, `mvtnorm`) are the risk | Spike planned (ROADMAP D3) |
| Reproducibility | Same inputs → same output, including Monte Carlo designs (fixed seeds) | Met in code; package versions not locked (ROADMAP P0) |

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
- **Browser tests** (`shinytest2`, headless Chrome): `test-ui_smoke.R` opens every module and
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
- **Planned** (ROADMAP Track D): PWA home-screen icon, Android wrapper, r-universe and CRAN releases, desktop wrapper.

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
| 7 — suite expansion | Analyze workbench, planning and survey tools, outbreak / surveillance tools, infectious-disease models, Eyes / Lesions per Patient | **Done** (summary-data only; raw-data workbench deferred, D1) |
| 8 — dependency reduction | Shrink runtime package list where reimplementation is safe | **Done in part** — 12 packages replaced by checked reimplementations (two upstream bugs found); `PowerTOST`, `Exact`, `clinfun`, `kappaSize`, `lme4` remain |
| 9 — devices and interface | Browser build, phone / server version, phone layout, lazy loading, task-first Home, search, accessibility, dark mode | **Done** (a real-phone check is open) |
| 10 — package API | Every calculation exported with help pages, `ss_find()`, addin, Cite tab | **Done**; vignettes, r-universe and CRAN open |

Items still open, blocked, or paused by the owner are kept in ROADMAP §4 with their
unblock conditions. The two owner-paused items are external validation for
time-to-event models and model updating/recalibration.

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Formula errors silently produce wrong sample sizes | Mandatory numeric verification before shipping (§12) |
| Package updates change results | Versions locked in `renv.lock`; CI runs against them |
| Docs and navigation drift from the code | Consistency tests (ROADMAP P0); ROADMAP as the single forward-looking doc |
| Development environment lost on container reset | SessionStart hook rebuilds it; `renv.lock` records the exact versions |
| Development sandbox cannot reach CRAN or journal sites | `github.com/cran` mirror + apt for packages; web search for citations; items needing paper access stay open rather than guessed |
| Monte Carlo designs block other users on a shared server | Calculate button done; background computation (`ExtendedTask`) needs a background-process package, an owner decision (ROADMAP F9) |
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

Resolved since v0.1: `renv` — yes, `renv.lock` added. Checklist maintenance — to be
enforced by consistency tests rather than habit.

---

## Appendix: Dependencies

**Runtime** (`DESCRIPTION` `Imports`): `shiny`, `bslib` (>= 0.6.0), `clinfun`, `PowerTOST`, `Exact`, `kappaSize`, `mvtnorm`, `lme4`;
plus `survival`, `graphics`, `stats` and `utils` from base R. (Twelve earlier imports, among them `pwr`, `presize`, `epiR`,
`pROC`, `powerMediation`, `pmsampsize`, `powerSurvEpi` and `TrialSize`, were replaced by reimplementations that are tested against
the originals.)

**Testing and verification** (`Suggests`): `testthat`, `withr`, `shinytest2`, `chromote`, `jsonlite`, `htmltools`, and the packages used
as oracles by the tests (`pwr`, `epiR`, `powerMediation`, `pmsampsize`, `pROC`, `presize`, `powerSurvEpi`, `TrialSize`, `deSolve`,
`spc`, `rstatix`, `Hmisc`, `tseries`, `BayesFactor`, `DescTools`, `lmerTest`, `sampling`, `surveillance`, ...); tests that need one
skip themselves when it is not installed. `roxygen2` builds the help pages (development only).

**Verification-only (development)**: installed from `github.com/cran/<pkg>` when a
design is built, never loaded by the app — e.g. `longpower`, `powerlmm`, `RTSA`,
`rpact`, `clusterPower`, `CRTSize`, `ssize.fdr`, `metapower`, `semTools`,
`semPower`, `simr`, `voi`, `PracTools`, `WebPower`, `genpwr`, `iMRMC`, `dfcrm`.
