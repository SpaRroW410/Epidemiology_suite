# Study Design Identification Algorithm
## Routing a research question → study design → statistical test → calculator module

**Purpose:** a deterministic decision algorithm that takes a user's research question
(free text, structured PICO, or answers to guided questions) and routes them to the
correct sample size calculator module in the app.

**Design philosophy:** the algorithm *suggests* with a confidence level; it never
silently decides. Design classification from natural language is genuinely ambiguous
(a "comparative cross-sectional study" in an Indian thesis protocol may be analysed as
a cohort, a case-control, or a simple two-proportion comparison depending on how
sampling actually happened). The UI must always show the inferred design, the reasoning,
and an override control.

---

## 0. Architecture overview

```
FREE TEXT / PICO INPUT
        │
        ▼
┌───────────────────────┐
│ STAGE 0: PICO parsing │  → extract P, I/E, C, O, T (time)
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ STAGE 1: PRIMARY AIM  │  → estimate / compare / predict / agree-accuracy
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ STAGE 2: DESIGN       │  → allocation, directionality, temporality, unit
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ STAGE 3: OUTCOME      │  → variable type, #groups, dependence structure
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ STAGE 4: TEST/MODULE  │  → terminal node = calculator module ID
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ STAGE 5: MODIFIERS    │  → applied ON TOP of base n (not a branch)
└───────────────────────┘
```

**Key structural insight:** Stages 1–4 form a *tree* (mutually exclusive branches).
Stage 5 modifiers are *orthogonal multipliers* applied to whatever base n emerged —
clustering, attrition, matching, multiplicity, finite population, unequal allocation.
Modelling them as tree branches causes combinatorial explosion; modelling them as a
post-hoc adjustment layer keeps the tree small and the code maintainable.

---

## STAGE 0 — PICO / question parsing

### 0.1 Slots to extract

| Slot | What it tells you | Feeds into |
|---|---|---|
| **P** — Population | Sampling frame; whether clusters exist; finite population | Stage 5 (FPC, DEFF) |
| **I/E** — Intervention or Exposure | Whether investigator *assigns* (→ experimental) or *observes* (→ observational) | Stage 2 |
| **C** — Comparator | Number of groups; presence of a comparison at all | Stage 1, Stage 3 |
| **O** — Outcome (dependent variable) | Variable type → test family | Stage 3 |
| **T** — Time / temporality | Simultaneous vs. followed-forward vs. looked-back | Stage 2 |

### 0.2 Discriminating question if C is absent

If no comparator is stated, the question is almost always **estimation**, not
comparison → Stage 1 branch A. Common in Indian community-medicine theses:
*"To estimate the prevalence of anaemia among adolescent girls in X block"* → single
proportion, not a two-group test. Detecting the absence of C early prevents the most
common misrouting.

### 0.3 Free-text keyword heuristics (for auto-suggest, low confidence)

| Signal in text | Suggests | Confidence |
|---|---|---|
| "prevalence of", "estimate the", "proportion of", "magnitude of", "assess the burden" | Estimation, single proportion | High |
| "mean level of", "average", "to determine the level" | Estimation, single mean | High |
| "compare", "difference between", "versus", "association between" | Comparative | High |
| "risk factors for", "determinants of", "predictors of" | Case-control OR cohort OR prediction model — **ambiguous, must ask** | Low |
| "effect of", "efficacy of", "impact of [intervention]" | Experimental (RCT) | Medium |
| "randomised", "allocated", "trial", "arm" | RCT | High |
| "followed up", "incidence of", "developed over" | Cohort | Medium |
| "cases and controls", "patients with X and without X" | Case-control | High |
| "validity of", "accuracy of", "sensitivity", "gold standard", "index test" | Diagnostic accuracy | High |
| "agreement", "reliability", "reproducibility", "inter-observer", "concordance" | Agreement/reliability | High |
| "develop a model", "predict", "prognostic", "risk score", "nomogram" | Prediction model | High |
| "time to", "survival", "till event", "recurrence-free" | Time-to-event | High |
| "non-inferior", "at least as good as" | Non-inferiority | High |
| "equivalent", "bioequivalence" | Equivalence/TOST | High |
| "cluster", "villages", "schools", "PHCs randomised", "anganwadi" | Cluster design → Stage 5 DEFF | High |
| "qualitative", "in-depth interview", "FGD", "thematic" | Non-formula guidance panel | High |

**Implementation note:** keyword matching alone is unreliable. A better approach for
free-text input is an LLM parsing layer that fills the PICO slots and returns a
structured JSON object, which then feeds the *deterministic* tree below. Keep the tree
deterministic — never let a language model choose the final formula, only populate the
slots. If offline/no-API operation matters, keyword heuristics degrade gracefully to
"couldn't infer, please use guided mode."

---

## STAGE 1 — Primary aim (root branch)

**Q1: What is the primary purpose of the study?**

| Answer | Branch | Goes to |
|---|---|---|
| A. Estimate a single parameter with precision (no comparison) | **ESTIMATION** | §1A |
| B. Compare groups / test an association or effect | **COMPARISON** | Stage 2 |
| C. Build or validate a prediction/prognostic model | **PREDICTION** | §1C |
| D. Assess diagnostic accuracy of a test | **DIAGNOSTIC** | §1D |
| E. Assess agreement / reliability between raters or methods | **AGREEMENT** | §1E |
| F. Explore experiences/meanings (qualitative) | **QUALITATIVE** | §1F |

> **Disambiguation rule:** if the user states a *hypothesis* (H₀/H₁), branch B.
> If they state an *objective to describe/estimate*, branch A. If both appear,
> the primary objective governs; offer to compute both and report the larger n.

### §1A — ESTIMATION branch (precision-based)

**Q1A.1: What type of parameter?**

| Parameter | Module | R backend |
|---|---|---|
| Proportion / prevalence | `mod_single_proportion` | `epiR::epi.sssimpleestb`, `presize::prec_prop` |
| Mean | `mod_single_mean` | `presize::prec_mean` |
| Incidence rate | `mod_rate_estimation` | `presize::prec_rate` |
| Ratio (RR/OR/rate ratio) | `mod_ratio_precision` | `presize::prec_riskratio` etc. |
| Sensitivity/specificity | → §1D | `presize::prec_sens` |
| ICC / kappa | → §1E | `ICC.Sample.Size`, `kappaSize` |

**Q1A.2: Precision specified as?** → absolute (±d) vs relative (±d% of p)
**Q1A.3: Population finite and enumerable?** → Stage 5 FPC modifier

> Note: a **cross-sectional study** is not a distinct calculation — it lands here
> (estimation) or in Stage 2 (if comparative). Label the design as cross-sectional in
> the output text, but route the maths to the parameter being estimated.

### §1C — PREDICTION branch

**Q1C.1: Developing a new model, or validating an existing one?**
- Development → `mod_pmsampsize_dev` (`pmsampsize`)
- External validation → `mod_pmsampsize_val` (`pmvalsampsize`)

**Q1C.2: Outcome type?** → binary / continuous / time-to-event (all supported by `pmsampsize`)

**Q1C.3: Inputs required** → number of candidate predictor *parameters* (not variables —
categorical variables with k levels contribute k−1), anticipated C-statistic or R²,
outcome prevalence or event rate, mean follow-up (time-to-event only)

> **Flag in UI:** the older EPV=10 rule of thumb is superseded by Riley et al. (2019);
> offer EPV as a legacy comparator but default to `pmsampsize`.

### §1D — DIAGNOSTIC branch

**Q1D.1: Single test vs. comparing two tests?**
**Q1D.2: Target metric?** → Se/Sp | PPV/NPV | LR | AUC
**Q1D.3: If comparing AUCs — paired (same patients, both tests) or unpaired?**

| Path | Module | Backend |
|---|---|---|
| Single Se or Sp | `mod_sens_spec` | `presize::prec_sens/spec` |
| PPV/NPV | `mod_ppv_npv` | derived 2×2 |
| Single AUC vs 0.5 | `mod_auc_single` | `pROC::power.roc.test` |
| Two AUCs paired/unpaired | `mod_auc_compare` | `pROC::power.roc.test` |

> Se/Sp calculations need **disease prevalence** to convert "n diseased needed" into
> "n to screen" — a near-universal user error. Make prevalence a required field.

### §1E — AGREEMENT branch

**Q1E.1: Outcome scale?**
- Categorical → kappa family (`mod_kappa`, `kappaSize`) → Q1E.2 #raters, #categories
- Continuous → Q1E.3

**Q1E.3: Continuous agreement target?**
- Reliability coefficient → `mod_icc` (`ICC.Sample.Size`, `presize::prec_icc`)
- Limits of agreement → `mod_bland_altman` (`presize::prec_lim_agree`)
- Concordance → `mod_ccc`
- Scale internal consistency → `mod_cronbach` (`presize::prec_cronb`)

### §1F — QUALITATIVE branch

Route to a **guidance panel, not a calculator**. Output: information power dimensions
(Malterud et al. 2016), saturation evidence (Guest et al. 2006), and a narrative
justification template. **Emit no numeric N** — false precision here is worse than
no answer.

---

## STAGE 2 — Design identification (COMPARISON branch only)

Four sequential discriminators, in this order:

### Q2.1 — Allocation: who decides exposure/intervention?

| Answer | → |
|---|---|
| Investigator assigns it | **EXPERIMENTAL** → Q2.2 |
| Investigator only observes it | **OBSERVATIONAL** → Q2.4 |

### Q2.2 — (Experimental) Unit of allocation?

| Answer | → |
|---|---|
| Individual | Individually-randomised trial → Q2.3 |
| Group/cluster (village, school, PHC, ward) | **Cluster RCT** → Stage 5 DEFF mandatory → Q2.3 |
| Same subject receives both, sequentially | **Crossover** → `mod_crossover` |
| Clusters cross over in sequence | **Stepped wedge** → `mod_stepped_wedge` |
| Single subject, repeated periods | **N-of-1** → `mod_n_of_1` |

### Q2.3 — (Experimental) Comparison intent?

| Answer | Module |
|---|---|
| Show one is better | **Superiority** → Stage 3 |
| Show not unacceptably worse | **Non-inferiority** → `mod_noninferiority` (needs margin δ, one-sided α) |
| Show both are similar within bounds | **Equivalence/TOST** → `mod_equivalence` |
| Show PK equivalence of formulations | **Bioequivalence** → `mod_bioequivalence` (CV, GMR, 0.80–1.25) |
| Single-arm, response vs historical | **Phase II** → `mod_simon_two_stage` |
| Interim analyses planned | → Stage 5 multiplicity + `mod_group_sequential` |

### Q2.4 — (Observational) Directionality — this is the crux

**Ask: on what basis were participants selected into the study?**

| Selection basis | Design | Effect measure | Module |
|---|---|---|---|
| On **exposure** status, outcome measured later | **Cohort (prospective)** | RR | `mod_cohort_rr` |
| On **exposure** status, outcome already occurred in records | **Retrospective cohort** | RR | `mod_cohort_rr` |
| On **outcome** status, exposure ascertained backwards | **Case-control** | OR | `mod_case_control` → Q2.5 |
| **Neither** — both measured at the same time | **Cross-sectional (analytic)** | PR / OR | `mod_two_proportions` |
| Cases from within a defined cohort + sampled controls | **Nested case-control** | OR | `mod_nested_cc` |
| Cases + random subcohort from a cohort | **Case-cohort** | HR | `mod_case_cohort` |
| Each case serves as own control, different time windows | **Case-crossover** | OR | `mod_case_crossover` |
| Repeated events within individuals, self-controlled | **SCCS** | IRR | `mod_sccs` |
| Unit of observation is a group, not a person | **Ecological** | — | guidance panel + caveat |

> **The single most useful discriminator in this whole algorithm** is Q2.4's phrasing.
> Asking "is it prospective or retrospective?" produces wrong answers constantly —
> a retrospective *cohort* and a *case-control* are both "retrospective" in time but
> differ fundamentally in selection basis. Always ask about **selection basis**, then
> ask about timing separately for descriptive labelling only.

### Q2.5 — (Case-control only) Matching?

| Answer | Module |
|---|---|
| Unmatched | `mod_case_control` (`epiR::epi.sscc`) |
| Individually matched 1:1 or 1:m | `mod_case_control_matched` (needs exposure correlation φ, m) |
| Frequency-matched | `mod_case_control` + note stratified analysis |

### Q2.6 — Exposure/outcome measured repeatedly over time?

If yes → **longitudinal/repeated-measures** overlay → `mod_lmm`, `mod_mmrm`,
`mod_gee` (Stage 3 still determines the outcome type).

---

## STAGE 3 — Outcome (dependent variable) characterisation

Three questions, always in this order.

### Q3.1 — What type is the dependent variable?

| Type | Examples | Test family |
|---|---|---|
| **Continuous** | BP, Hb, BMI, score | t / ANOVA / regression |
| **Binary** | cured/not, positive/negative | proportions / χ² / logistic |
| **Categorical (>2, nominal)** | blood group, diagnosis category | χ² |
| **Ordinal** | Likert, stage, grade | ordinal regression / non-parametric |
| **Count / rate** | episodes per child-year | Poisson |
| **Time-to-event** | time to shunt failure, survival | log-rank / Cox |

### Q3.2 — How many groups being compared?

1 (vs. reference value) | 2 | >2 | k with ordered trend

### Q3.3 — Are observations independent?

| Answer | Effect |
|---|---|
| Independent | standard two-sample tests |
| Paired (same subject, before/after; matched pairs) | paired tests |
| Repeated (>2 measurements per subject) | RM-ANOVA / LMM / GEE |
| Clustered (subjects nested in villages/clinics) | Stage 5 DEFF |

### Q3.4 — Parametric assumptions tenable?

If the user says the outcome is skewed / small n / ordinal → route to the
non-parametric equivalent, implemented as the parametric n inflated by an
**ARE factor** (state the assumption explicitly in the UI — this is an approximation,
not exact rank-test power).

---

## STAGE 4 — Routing table (terminal nodes)

### Continuous outcome

| Groups | Structure | Test | Module | Backend |
|---|---|---|---|---|
| 1 | — | One-sample t | `mod_t_one_sample` | `pwr::pwr.t.test` |
| 2 | Independent | Two-sample t | `mod_t_two_sample` | `pwr::pwr.t.test` |
| 2 | Independent, unequal n | Two-sample t | `mod_t_unequal_n` | `pwr::pwr.t2n.test` |
| 2 | Independent, unequal variance | Welch | `mod_welch` | `MESS::power_t_test` |
| 2 | Paired | Paired t | `mod_t_paired` | `pwr::pwr.t.test(type="paired")` |
| 2 | Independent, non-parametric | Mann-Whitney | `mod_mann_whitney` | t × ARE |
| 2 | Paired, non-parametric | Wilcoxon signed-rank | `mod_wilcoxon` | t × ARE |
| >2 | Independent | One-way ANOVA | `mod_anova_oneway` | `pwr::pwr.anova.test` |
| >2 | Independent, non-parametric | Kruskal-Wallis | `mod_kruskal` | ANOVA × ARE |
| >2 | Repeated | RM-ANOVA | `mod_rm_anova` | `WebPower::wp.rmanova` |
| >2 | Factorial | Two-way ANOVA | `mod_anova_factorial` | `WebPower` |
| >2 | With covariate adjustment | ANCOVA | `mod_ancova` | `WebPower` |
| — | Association | Pearson r | `mod_correlation` | `pwr::pwr.r.test` |
| — | Prediction | Multiple regression | `mod_regression_multiple` | `pwr::pwr.f2.test` |

### Binary outcome

| Groups | Structure | Test | Module | Backend |
|---|---|---|---|---|
| 1 | — | Single proportion | `mod_single_proportion_test` | `pwr::pwr.p.test` |
| 2 | Independent | Two proportions / χ² | `mod_two_proportions` | `pwr::pwr.2p.test` |
| 2 | Independent, small n | Fisher exact | `mod_fisher_exact` | exact |
| 2 | Paired | McNemar | `mod_mcnemar` | — |
| 2 | Cohort framing | RR | `mod_cohort_rr` | `epiR::epi.sscohortc` |
| 2 | Case-control framing | OR | `mod_case_control` | `epiR::epi.sscc` |
| >2 | Independent | χ² independence | `mod_chisq` | `pwr::pwr.chisq.test` |
| >2 | Ordered exposure | Cochran-Armitage trend | `mod_trend` | — |
| — | Multivariable | Logistic regression | `mod_logistic` | `WebPower::wp.logistic` |

### Count / rate outcome
`mod_rate_comparison` (`epiR::epi.sscompc`), `mod_poisson_regression` (`WebPower::wp.poisson`)

### Time-to-event outcome
`mod_logrank` (`powerSurvEpi`, `gsDesign::nSurv`), `mod_cox` (`powerSurvEpi`),
`mod_rmst` (`SSRMST`), `mod_competing_risks` (`powerCompRisk`)

### Ordinal outcome
`mod_ordinal_regression` (proportional odds), or non-parametric equivalents

---

## STAGE 5 — Modifier layer (applied to base n)

Applied multiplicatively/sequentially **after** the terminal module returns base n.
Each is an independent toggle in the UI, not a tree branch.

| Modifier | Trigger | Adjustment | Input needed |
|---|---|---|---|
| **Design effect (clustering)** | cluster sampling or cluster randomisation | n × DEFF, DEFF = 1 + (m−1)ρ | ICC ρ, mean cluster size m |
| **Attrition / dropout** | any longitudinal follow-up | n / (1 − d) | expected dropout d |
| **Non-response** | surveys | n / (1 − r) | expected non-response r |
| **Finite population correction** | small enumerable population | n / (1 + n/N) | population N |
| **Unequal allocation** | ratio ≠ 1:1 | inflate per allocation ratio k | k |
| **Multiplicity** | multiple primary outcomes / interim looks | α → α/m or spending function | m comparisons |
| **Interaction/subgroup** | subgroup analysis planned | ≈ n × 4 | — |
| **Missing data** | expected incomplete covariates | n / (1 − p_miss) | p_miss |
| **Continuity correction** | small-sample proportions | Fleiss correction | — |

> **Order matters.** Apply DEFF first (structural), then attrition/non-response
> (multiplicative losses), then FPC last (FPC on an already-inflated n). Document the
> order in the output so users can reproduce it by hand.

---

## Output contract

Every run of the algorithm should return:

```
1. Inferred design label       — e.g. "Unmatched case-control study"
2. Confidence                  — High / Medium / Low (+ what was ambiguous)
3. Reasoning trace             — the answers that led here, so it's auditable
4. Recommended module          — with a direct link/tab jump
5. Alternative candidates      — ranked, if confidence < High
6. Required inputs list        — before the user even opens the module
7. Override control            — "This isn't my design →" manual picker
```

**Never** collapse to a single answer at Low confidence. For "risk factors for X"
questions in particular — genuinely ambiguous between cohort, case-control, and
prediction model — present all three with a one-line explanation of when each applies
and let the user choose.

---

## R implementation sketch

Represent the tree as a flat registry of nodes rather than nested lists — flat is far
easier to test, traverse, and extend, and it lets you validate that every terminal node
points at a module that actually exists.

```r
# R/design_tree.R

design_nodes <- list(
  
  root = list(
    id       = "root",
    stage    = 1,
    question = "What is the primary purpose of your study?",
    help     = "If you have a hypothesis to test, choose 'Compare'.",
    options  = list(
      list(label = "Estimate a parameter (prevalence, mean)", next_id = "est_type"),
      list(label = "Compare groups / test association",       next_id = "allocation"),
      list(label = "Build or validate a prediction model",     next_id = "pred_type"),
      list(label = "Assess diagnostic test accuracy",          next_id = "diag_type"),
      list(label = "Assess agreement / reliability",           next_id = "agree_scale"),
      list(label = "Qualitative enquiry",                      next_id = "qual_guidance")
    )
  ),
  
  allocation = list(
    id       = "allocation",
    stage    = 2,
    question = "Who determines who receives the exposure or intervention?",
    help     = "If you assign it, the study is experimental.",
    options  = list(
      list(label = "I (the investigator) assign it", next_id = "exp_unit"),
      list(label = "I only observe what happened",   next_id = "selection_basis")
    )
  ),
  
  selection_basis = list(
    id       = "selection_basis",
    stage    = 2,
    question = "On what basis were participants selected into the study?",
    help     = paste("This is the key question separating cohort from case-control.",
                     "Ask what you knew about each person BEFORE enrolling them."),
    options  = list(
      list(label = "Their exposure status",             next_id = "cohort_outcome_type"),
      list(label = "Their outcome/disease status",      next_id = "cc_matching"),
      list(label = "Neither — both measured together",  next_id = "xsec_outcome_type")
    )
  ),
  
  # ... terminal node example ...
  cc_unmatched = list(
    id         = "cc_unmatched",
    stage      = 4,
    terminal   = TRUE,
    design     = "Unmatched case-control study",
    module     = "mod_case_control",
    backend    = "epiR::epi.sscc",
    citation   = "Schlesselman JJ (1982); Kelsey et al. (1996); Fleiss (1981)",
    inputs     = c("prop_exposed_controls", "odds_ratio",
                   "control_case_ratio", "power", "conf_level"),
    modifiers  = c("dropout", "multiplicity")
  )
)


#' Traverse the tree from a vector of answers
route_design <- function(answers, nodes = design_nodes) {
  node  <- nodes[["root"]]
  trace <- character(0)
  for (a in answers) {
    if (isTRUE(node$terminal)) break
    opt   <- node$options[[a]]
    trace <- c(trace, paste0(node$question, " → ", opt$label))
    node  <- nodes[[opt$next_id]]
  }
  list(node = node, trace = trace, complete = isTRUE(node$terminal))
}


#' Validate registry integrity — run in tests/
validate_tree <- function(nodes = design_nodes) {
  terminals <- Filter(function(n) isTRUE(n$terminal), nodes)
  ids       <- names(nodes)
  # every next_id must exist
  for (n in nodes) {
    for (o in n$options %||% list()) {
      stopifnot(o$next_id %in% ids)
    }
  }
  # every terminal must name a module that is registered in the app
  stopifnot(all(vapply(terminals, function(n) n$module %in% registered_modules(), logical(1)))) 
  invisible(TRUE)
}
```

**Testing strategy for the tree** (add to `tests/testthat/test-design_tree.R`):
- `validate_tree()` — no orphan nodes, no dangling `next_id`, every terminal maps to a
  live module
- A corpus of ~30 real research questions (pull from your department's past
  dissertations/protocols) with hand-labelled correct designs, asserted as regression
  tests. This is the only honest way to know the algorithm works — synthetic examples
  will flatter it.

---

## Known failure modes (document these in the app)

| Failure | Why it happens | Mitigation |
|---|---|---|
| "Comparative cross-sectional" misrouted | Common Indian protocol phrasing that maps to several designs | Ask selection basis explicitly; offer both cross-sectional and case-control outputs |
| Prospective/retrospective confusion | Retrospective cohort ≠ case-control, but both are "backward-looking" | Never branch on timing; branch on selection basis |
| Multiple objectives, one sample | Users enter primary objective only | Compute n for each objective, report the maximum, show the table |
| Prediction vs. aetiology conflation | "Predictors of X" is used for both | Ask: "Do you want to identify causes, or build a tool that forecasts?" |
| Clustering ignored | Users don't recognise villages/schools as clusters | Trigger DEFF prompt on P-slot keywords (village, school, PHC, ward, anganwadi, block) |
| Outcome type misread | Ordinal treated as continuous | Ask for example values, not just a type label |

---

**Document version:** 0.1 (draft)
**Companion files:** `checklist_by_design.md`, `checklist_by_test.md`, `SDD.md`
