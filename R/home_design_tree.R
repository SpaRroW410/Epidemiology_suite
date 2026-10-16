# Flat-registry decision tree for the "Which calculator?" wizard
# (docs/design_identification_algorithm.md). Routes a guided Q&A session to
# either a built catalog entry (see home_catalog.R) or an honest "not yet
# built" terminal naming what is missing and why (docs/ROADMAP.md sec. 4) --
# never a silent guess and never a broken link.
#
# Node shape:
#   Question node:  id, stage, question, help (optional),
#                    options = list(list(label=, next_id=, set=(optional flag list)))
#   Terminal node:   id, terminal = TRUE, design (label shown to user),
#                    catalog_key (string, or function(flags) -> string/NULL,
#                                 for terminals whose module depends on an
#                                 earlier answer -- e.g. continuous vs binary),
#                    would_use / citation (only when not built),
#                    guidance = TRUE (only for non-calculator guidance panels,
#                                 e.g. qualitative research -- no numeric N),
#                    note (optional extra text shown regardless of built state)
#
# `next_id` may also be a function(flags) -> id, for the same "depends on an
# earlier answer" reason. `flags` accumulate as the user answers (`outcome`:
# "continuous"|"binary", `cluster`: TRUE/FALSE, `tsa_outcome`) rather than
# being threaded through as separate tree branches, to keep the node count
# from exploding combinatorially (Stage 5 in the source document makes the
# identical point about modifiers).
#
# Option order matters for nodes that have free-text rules
# (design_free_text.R refers to options by position): only ever APPEND
# options to root, est_type, allocation, selection_basis, cc_matching,
# outcome_type, groups_count and dependence_q.
#
# Coverage contract (tests/testthat/test-design_tree.R): every built entry in
# calculator_catalog, and so every module in the navbar, is reachable from
# root. The last root option ("I already know which test...") is generated
# from home_catalog.R's test_families, so home_catalog.R must be loaded
# before this file. Package files load in alphabetical (C-locale) order, which is
# why this file is named home_design_tree.R (it sorts after home_catalog.R) --
# do not rename it to something that sorts before "home_catalog.R".

# Terminal constructors -- keep the node list below readable.
.term <- function(id, design, key, note = NULL) {
  list(id = id, terminal = TRUE, design = design, catalog_key = key, note = note)
}
.term_open <- function(id, design, would_use, citation = "-", note = NULL) {
  list(id = id, terminal = TRUE, design = design, would_use = would_use,
       citation = citation, note = note)
}
.by_outcome <- function(continuous, binary) {
  force(continuous); force(binary)
  function(flags) if (identical(flags$outcome, "continuous")) continuous else binary
}

design_nodes <- list(

  root = list(
    id = "root", stage = 1,
    question = "What is the primary purpose of your study?",
    help = "If you have a hypothesis or are testing for a difference/association, choose \"Compare\". If you're just describing your own population with no comparison, choose \"Estimate\".",
    options = list(
      list(label = "Estimate a parameter with precision (prevalence, mean, rate...)", next_id = "est_type"),
      list(label = "Compare groups / test an association or hypothesis", next_id = "allocation"),
      list(label = "Build or validate a prediction/prognostic model", next_id = "pred_type"),
      list(label = "Assess the accuracy of a diagnostic test", next_id = "diag_type"),
      list(label = "Assess agreement/reliability between raters or methods", next_id = "agree_scale"),
      list(label = "Explore experiences or meanings (qualitative)", next_id = "term_qualitative"),
      list(label = "Plan a meta-analysis (number of studies, or trial sequential analysis)", next_id = "meta_type"),
      list(label = "Study the relationship between variables (correlation / regression)", next_id = "rel_type"),
      list(label = "Something else: survey sampling, scale development, rare events, animal studies, pilots, health economics, genetics", next_id = "other_purpose"),
      list(label = "Analyze counts I already have (a 2x2 table: risk ratio, odds ratio, ...)", next_id = "analyze_type"),
      list(label = "I already know which statistical test I'll use -- browse by test family", next_id = "bytest_family")
    )
  ),

  analyze_type = list(
    id = "analyze_type", stage = 1,
    question = "What do you want to analyze from counts you already have?",
    options = list(
      list(label = "An exposure-outcome association (2x2 table: risk ratio, odds ratio, ...)", next_id = "analyze_design"),
      list(label = "An association adjusted for a confounder (stratified 2x2 tables, Mantel-Haenszel)", next_id = "analyze_mh_design"),
      list(label = "Incidence rates from events and person-time (one rate, or a rate ratio of two groups)", next_id = "analyze_rate_type"),
      list(label = "Paired data, agreement between raters, or a trend across ordered groups (McNemar, kappa, chi-square for trend)", next_id = "analyze_paired_type"),
      list(label = "Rates for populations with different age structures: standardized rates or an SMR", next_id = "analyze_std_type"),
      list(label = "Compare two groups from summary figures: two proportions (difference, ratio, odds ratio) or two means", next_id = "analyze_compare_type"),
      list(label = "Vaccine efficacy or effectiveness (1 - relative risk) from a trial, cohort or case-control study", next_id = "analyze_vaccine_type"),
      list(label = "A diagnostic test (sensitivity, specificity, PPV, NPV from a test-by-disease table)", next_id = "term_analyze_dx_single"),
      list(label = "Two or more diagnostic tests used together (serial / parallel testing)", next_id = "term_analyze_dx_combined"),
      list(label = "A confidence interval for a proportion, or for a mean and standard deviation", next_id = "analyze_ci_type")
    )
  ),

  analyze_compare_type = list(
    id = "analyze_compare_type", stage = 1,
    question = "What are the two groups' summary figures?",
    options = list(
      list(label = "Events and sample sizes (two proportions)", next_id = "term_analyze_compare_proportions"),
      list(label = "Sample size, mean and standard deviation (two means)", next_id = "term_analyze_compare_means")
    )
  ),

  analyze_std_type = list(
    id = "analyze_std_type", stage = 1,
    question = "What do you have?",
    options = list(
      list(label = "Stratum-specific events and person-time for my group(s) and a standard population: direct standardization", next_id = "term_analyze_std_direct"),
      list(label = "My group's person-time by stratum and reference rates from a larger population: indirect standardization (SMR)", next_id = "term_analyze_std_indirect"),
      list(label = "Observed and expected numbers of events already: SMR with a confidence interval", next_id = "term_analyze_std_smr")
    )
  ),

  analyze_paired_type = list(
    id = "analyze_paired_type", stage = 1,
    question = "Which of these describes your counts?",
    options = list(
      list(label = "The same subjects classified twice (two tests, before/after, matched pairs): McNemar", next_id = "term_analyze_mcnemar"),
      list(label = "Two raters or tests classifying the same subjects: how well do they agree (kappa)?", next_id = "term_analyze_kappa"),
      list(label = "Proportions across ordered groups (dose levels, age bands): is there a trend?", next_id = "term_analyze_trend")
    )
  ),

  analyze_vaccine_type = list(
    id = "analyze_vaccine_type", stage = 1,
    question = "What data do you have for the vaccine comparison?",
    options = list(
      list(label = "Cases and number of participants in a vaccinated and an unvaccinated group (attack rates)", next_id = "term_analyze_vaccine_risk"),
      list(label = "Cases and person-time in each group (incidence rates)", next_id = "term_analyze_vaccine_rate"),
      list(label = "Vaccinated and unvaccinated cases and controls (case-control or test-negative design)", next_id = "term_analyze_vaccine_odds")
    )
  ),

  analyze_rate_type = list(
    id = "analyze_rate_type", stage = 1,
    question = "What do you want to do with your events and person-time?",
    options = list(
      list(label = "A confidence interval for one incidence rate", next_id = "term_analyze_rate_single"),
      list(label = "Compare two groups: rate ratio, rate difference, attributable fractions", next_id = "term_analyze_rate_ratio"),
      list(label = "Compare two groups within strata of a confounder: adjusted (Mantel-Haenszel) rate ratio and rate difference", next_id = "term_analyze_rate_stratified")
    )
  ),

  analyze_mh_design = list(
    id = "analyze_mh_design", stage = 1,
    question = "How were the subjects in your stratified tables sampled?",
    help = "Risk ratios and risk differences can only be estimated if subjects were followed from exposure to outcome (or sampled without regard to either); a case-control sample gives the odds ratio only.",
    options = list(
      list(label = "Followed from exposure to outcome, or a cross-sectional survey (cohort / trial / cross-sectional)", next_id = "term_analyze_mh_cohort"),
      list(label = "Sampled by outcome: cases and controls", next_id = "term_analyze_mh_case_control")
    )
  ),

  analyze_ci_type = list(
    id = "analyze_ci_type", stage = 1,
    question = "Which summary figures do you have?",
    options = list(
      list(label = "A proportion: x events out of n", next_id = "term_analyze_ci_proportion"),
      list(label = "A mean and standard deviation from a sample of size n", next_id = "term_analyze_ci_mean")
    )
  ),

  analyze_design = list(
    id = "analyze_design", stage = 1,
    question = "How were the subjects in your 2x2 table sampled?",
    help = "This decides which measures are valid: risks (and so risk ratio, risk difference, number needed) can only be estimated if subjects were followed from exposure to outcome or sampled without regard to either.",
    options = list(
      list(label = "Followed from exposure to outcome (cohort study or trial)", next_id = "term_analyze_2x2_cohort"),
      list(label = "Exposure and outcome measured together (cross-sectional / survey)", next_id = "term_analyze_2x2_cross_sectional"),
      list(label = "Sampled by outcome: cases and controls", next_id = "term_analyze_2x2_case_control")
    )
  ),

  other_purpose = list(
    id = "other_purpose", stage = 1,
    question = "Which of these best describes the study?",
    options = list(
      list(label = "A survey with a sampling scheme (cluster, multistage, stratified, LQAS, population size)", next_id = "survey_type"),
      list(label = "Developing or validating a scale/questionnaire (factor analysis, SEM, IRT)", next_id = "psych_type"),
      list(label = "Rare events or surveillance (no events seen, detecting at least one case)", next_id = "rare_type"),
      list(label = "An animal / preclinical experiment", next_id = "animal_type"),
      list(label = "A pilot or feasibility study (ahead of a main trial)", next_id = "term_pilot"),
      list(label = "A health-economic value-of-information analysis (EVPI / EVSI)", next_id = "voi_type"),
      list(label = "A genetic or genomic study (GWAS, gene-environment, microarray)", next_id = "gen_type")
    )
  ),

  # ---------------------------------------------------------------- sec. 1F ----
  meta_type = list(
    id = "meta_type", stage = 1,
    question = "What do you need for the meta-analysis?",
    options = list(
      list(label = "How many studies a planned pairwise meta-analysis needs (power)", next_id = "term_meta_power"),
      list(label = "Required information size for a cumulative meta-analysis of trials (trial sequential analysis)", next_id = "tsa_outcome"),
      list(label = "Network meta-analysis (several treatments compared indirectly)", next_id = "term_nma")
    )
  ),

  tsa_outcome = list(
    id = "tsa_outcome", stage = 1,
    question = "What outcome metric will the meta-analysis pool?",
    help = paste(
      "Trial sequential analysis (TSA) computes the required/optimal",
      "information size (RIS/OIS) -- the meta-analysis-level analogue of",
      "a single trial's sample size -- for a planned or",
      "cumulatively-updated meta-analysis of trials."
    ),
    options = list(
      list(label = "Risk ratio (RR)", next_id = "term_tsa", set = list(tsa_outcome = "RR")),
      list(label = "Odds ratio (OR)", next_id = "term_tsa", set = list(tsa_outcome = "OR")),
      list(label = "Risk difference (RD)", next_id = "term_tsa", set = list(tsa_outcome = "RD")),
      list(label = "Mean difference (MD)", next_id = "term_tsa", set = list(tsa_outcome = "MD"))
    )
  ),

  # ---------------------------------------------------------------- sec. 1A ----
  est_type = list(
    id = "est_type", stage = 1,
    question = "What are you estimating?",
    help = "No comparison group and no hypothesis here -- just a target precision (confidence interval width) and a confidence level.",
    options = list(
      list(label = "A proportion / prevalence", next_id = "term_prop_precision"),
      list(label = "A mean", next_id = "term_mean_precision"),
      list(label = "An incidence rate", next_id = "term_rate_precision"),
      list(label = "A ratio (risk ratio / odds ratio / rate ratio)", next_id = "ratio_type"),
      list(label = "Sensitivity or specificity of a test", next_id = "diag_type"),
      list(label = "An ICC or kappa (agreement)", next_id = "agree_scale"),
      list(label = "A standard deviation / variance", next_id = "term_sd_precision"),
      list(label = "The size of a hidden or hard-to-count population (capture-recapture)", next_id = "term_capture_recapture"),
      list(label = "A prevalence from a cluster, multistage or stratified survey", next_id = "survey_type"),
      list(label = "An upper bound on a rare event rate when no events were seen", next_id = "term_rule3_bound")
    )
  ),

  ratio_type = list(
    id = "ratio_type", stage = 1,
    question = "Which ratio?",
    options = list(
      list(label = "Risk ratio (cohort / trial)", next_id = "term_ratio_rr"),
      list(label = "Odds ratio (case-control / cross-sectional)", next_id = "term_ratio_or"),
      list(label = "Rate ratio (person-time)", next_id = "term_ratio_rate")
    )
  ),

  # ---------------------------------------------------------------- sec. 1D ----
  diag_type = list(
    id = "diag_type", stage = 1,
    question = "What do you need for the diagnostic test?",
    options = list(
      list(label = "Precision for sensitivity/specificity, no reference value", next_id = "term_diag_precision"),
      list(label = "Whether sensitivity/specificity differs from a known/reference value", next_id = "term_diag_vs_ref"),
      list(label = "Compare two tests on two independent groups of subjects", next_id = "term_diag_two_indep"),
      list(label = "Compare two tests on the same subjects (paired)", next_id = "term_diag_two_paired"),
      list(label = "Predictive values (PPV/NPV)", next_id = "term_ppv_npv"),
      list(label = "Area under the ROC curve (AUC)", next_id = "auc_type"),
      list(label = "Likelihood ratios (LR+ / LR-)", next_id = "term_diag_lr"),
      list(label = "Diagnostic odds ratio (DOR)", next_id = "term_diag_dor"),
      list(label = "Several readers read the same cases (multi-reader multi-case, MRMC)", next_id = "term_mrmc")
    )
  ),

  auc_type = list(
    id = "auc_type", stage = 1,
    question = "Which AUC question?",
    options = list(
      list(label = "One test: is its AUC better than chance (0.5)?", next_id = "term_auc_single"),
      list(label = "Two tests on the same subjects (correlated AUCs)", next_id = "term_auc_paired"),
      list(label = "Two tests on different subjects (independent AUCs)", next_id = "term_auc_unpaired")
    )
  ),

  # ---------------------------------------------------------------- sec. 1E ----
  agree_scale = list(
    id = "agree_scale", stage = 1,
    question = "What's the scale of the outcome being rated or measured?",
    options = list(
      list(label = "Categorical (e.g. present/absent, disease grade)", next_id = "term_kappa"),
      list(label = "Continuous -- reliability coefficient (ICC)", next_id = "term_icc"),
      list(label = "Continuous -- limits of agreement (Bland-Altman)", next_id = "term_bland_altman"),
      list(label = "Continuous -- concordance correlation (CCC)", next_id = "term_ccc"),
      list(label = "Scale internal consistency (Cronbach's alpha)", next_id = "term_cronbach"),
      list(label = "Method comparison by regression (Deming / Passing-Bablok)", next_id = "term_deming")
    )
  ),

  # ---------------------------------------------------------------- sec. 1C ----
  pred_type = list(
    id = "pred_type", stage = 1,
    question = "Developing a new model, or validating an existing one?",
    help = "Development sample sizes follow Riley et al.'s criteria (minimise overfitting, precise intercept/R-squared), not a single hypothesis test.",
    options = list(
      list(label = "Develop a model -- binary outcome (logistic)", next_id = "term_pred_binary"),
      list(label = "Develop a model -- continuous outcome (linear)", next_id = "term_pred_continuous"),
      list(label = "Develop a model -- time-to-event outcome (Cox / survival)", next_id = "term_pred_survival"),
      list(label = "Externally validate an existing model -- binary outcome", next_id = "term_pred_extval"),
      list(label = "Externally validate an existing model -- time-to-event outcome", next_id = "term_pred_extval_tte"),
      list(label = "Update / recalibrate a model, or a machine-learning model", next_id = "term_pred_updating")
    )
  ),

  # --------------------------------------------- relationships (sec.  Part 2) ----
  rel_type = list(
    id = "rel_type", stage = 3,
    question = "What kind of relationship?",
    options = list(
      list(label = "Correlation between two variables", next_id = "corr_type"),
      list(label = "Regression with a continuous outcome (linear regression, ANOVA/ANCOVA)", next_id = "reg_type"),
      list(label = "Regression with a binary outcome (logistic regression)", next_id = "logit_type"),
      list(label = "Regression with an ordinal outcome (proportional odds)", next_id = "term_ordinal"),
      list(label = "Regression with a count / rate outcome (Poisson regression)", next_id = "term_poisson_reg"),
      list(label = "Regression with a time-to-event outcome (Cox regression)", next_id = "cox_type")
    )
  ),

  corr_type = list(
    id = "corr_type", stage = 3,
    question = "Which correlation question?",
    options = list(
      list(label = "Pearson correlation (two continuous, roughly normal variables)", next_id = "term_corr_pearson"),
      list(label = "Spearman rank correlation", next_id = "term_corr_spearman"),
      list(label = "Kendall's tau", next_id = "term_kendall"),
      list(label = "Point-biserial (one binary, one continuous variable)", next_id = "term_corr_pb"),
      list(label = "Partial correlation (controlling for covariates)", next_id = "term_corr_partial"),
      list(label = "Compare two correlations from independent samples", next_id = "term_corr_two_indep"),
      list(label = "Compare two overlapping correlations in the same sample", next_id = "term_corr_two_dep")
    )
  ),

  reg_type = list(
    id = "reg_type", stage = 3,
    question = "Which linear-model question?",
    options = list(
      list(label = "One predictor's slope (simple linear regression)", next_id = "term_reg_slope"),
      list(label = "Overall R-squared of a multiple regression", next_id = "term_reg_r2"),
      list(label = "R-squared increase when adding predictors (hierarchical regression)", next_id = "term_reg_r2_increase"),
      list(label = "Factorial ANOVA / ANCOVA (main effects, interactions, covariates)", next_id = "term_anova_general")
    )
  ),

  logit_type = list(
    id = "logit_type", stage = 3,
    question = "What kind of predictor, and is the model adjusted for other covariates?",
    options = list(
      list(label = "Binary predictor, unadjusted", next_id = "term_logit_bin"),
      list(label = "Continuous predictor, unadjusted", next_id = "term_logit_cont"),
      list(label = "Binary predictor, adjusted for other covariates", next_id = "term_logit_bin_adj"),
      list(label = "Continuous predictor, adjusted for other covariates", next_id = "term_logit_cont_adj")
    )
  ),

  cox_type = list(
    id = "cox_type", stage = 3,
    question = "What kind of covariate is being tested in the Cox model?",
    options = list(
      list(label = "Binary covariate (e.g. treatment vs. control)", next_id = "term_cox_binary"),
      list(label = "Continuous covariate (e.g. a biomarker)", next_id = "term_cox_continuous")
    )
  ),

  # ------------------------------------------------------ specialised ----
  survey_type = list(
    id = "survey_type", stage = 1,
    question = "What is the sampling scheme?",
    options = list(
      list(label = "Simple random sampling of individuals", next_id = "term_prop_precision"),
      list(label = "Cluster / multistage sampling, equal cluster sizes (design effect)", next_id = "term_cluster_deff"),
      list(label = "Cluster / multistage sampling, unequal cluster sizes", next_id = "term_cluster_deff_var"),
      list(label = "WHO EPI-style cluster survey (e.g. 30 x 7)", next_id = "term_cluster_survey"),
      list(label = "Two-stage PPS sampling -- how many per cluster (optimal allocation)", next_id = "term_cluster_pps"),
      list(label = "Stratified sampling (allocate across strata)", next_id = "term_stratified"),
      list(label = "Lot quality assurance sampling (LQAS) -- classify areas as pass/fail", next_id = "term_lqas"),
      list(label = "Estimate a population's size (capture-recapture)", next_id = "term_capture_recapture")
    )
  ),

  psych_type = list(
    id = "psych_type", stage = 1,
    question = "Which analysis will the scale be developed or validated with?",
    options = list(
      list(label = "Exploratory / confirmatory factor analysis (EFA / CFA)", next_id = "term_efa_cfa"),
      list(label = "CFA / SEM model fit (RMSEA test of close fit)", next_id = "term_sem_rmsea"),
      list(label = "Item response theory (IRT) calibration", next_id = "term_irt"),
      list(label = "Internal consistency (Cronbach's alpha)", next_id = "term_cronbach"),
      list(label = "Test-retest reliability (ICC)", next_id = "term_icc")
    )
  ),

  rare_type = list(
    id = "rare_type", stage = 1,
    question = "What do you need?",
    options = list(
      list(label = "An upper bound on the event rate after observing zero events (rule of three)", next_id = "term_rule3_bound"),
      list(label = "How many to observe to see at least one event, with a given probability", next_id = "term_rule3_n"),
      list(label = "How many to test to detect at least one case with an imperfect test (finite population)", next_id = "term_rule3_imperfect"),
      list(label = "Exact test of one proportion against a reference value (binomial)", next_id = "term_exact_binomial"),
      list(label = "Exact test of one incidence rate against a reference rate (Poisson)", next_id = "term_exact_poisson")
    )
  ),

  animal_type = list(
    id = "animal_type", stage = 1,
    question = "How will the animal study be sized?",
    options = list(
      list(label = "Resource equation (exploratory study, effect size unknown)", next_id = "term_resource_equation"),
      list(label = "Rank-based comparison of K groups (small samples, Monte Carlo)", next_id = "term_animal_rank"),
      list(label = "A formal power calculation for a specified effect size", next_id = "exp_intent", set = list(cluster = FALSE))
    )
  ),

  voi_type = list(
    id = "voi_type", stage = 1,
    question = "Which value-of-information quantity?",
    options = list(
      list(label = "Expected value of perfect information (EVPI) -- is more research worth it at all?", next_id = "term_evpi"),
      list(label = "Expected value of sample information (EVSI) and the optimal study size (ENBS)", next_id = "term_evsi")
    )
  ),

  gen_type = list(
    id = "gen_type", stage = 1,
    question = "Which genetic / genomic design?",
    options = list(
      list(label = "Genome-wide or candidate-gene association study", next_id = "term_gwas"),
      list(label = "Gene-environment interaction", next_id = "term_gxe"),
      list(label = "Two-group gene-expression (microarray) study with FDR control", next_id = "term_microarray")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.1) ----
  allocation = list(
    id = "allocation", stage = 2,
    question = "Who determines who receives the exposure or intervention?",
    help = "If you assign it yourself, the study is experimental (a trial). If you only observe what happened naturally, it's observational.",
    options = list(
      list(label = "I (the investigator) assign it", next_id = "exp_unit"),
      list(label = "I only observe what happened naturally", next_id = "selection_basis")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.2) ----
  exp_unit = list(
    id = "exp_unit", stage = 2,
    question = "What is the unit of allocation?",
    options = list(
      list(label = "Individual subjects", next_id = "exp_intent", set = list(cluster = FALSE)),
      list(label = "Groups/clusters (villages, schools, PHCs, wards)", next_id = "exp_intent", set = list(cluster = TRUE)),
      list(label = "Same subject receives both, in sequence (crossover)", next_id = "term_crossover"),
      list(label = "Clusters cross over in sequence (stepped-wedge)", next_id = "term_stepped_wedge"),
      list(label = "Single subject, repeated periods (N-of-1)", next_id = "term_n_of_1"),
      list(label = "Groups/clusters, and I want to simulate the mixed-model analysis directly (Monte Carlo)", next_id = "glmm_outcome", set = list(cluster = TRUE))
    )
  ),

  glmm_outcome = list(
    id = "glmm_outcome", stage = 3,
    question = "Is the outcome continuous or binary?",
    options = list(
      list(label = "Continuous (linear mixed model)", next_id = "term_glmm_cont"),
      list(label = "Binary (logistic mixed model)", next_id = "term_glmm_binary")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.3) ----
  exp_intent = list(
    id = "exp_intent", stage = 2,
    question = "What is the comparison intent of the trial?",
    options = list(
      list(label = "Show one arm is better (superiority)", next_id = "outcome_type"),
      list(label = "Show it's not unacceptably worse (non-inferiority)", next_id = "noninf_outcome"),
      list(label = "Show both arms are practically equivalent (equivalence)", next_id = "equiv_outcome"),
      list(label = "Show pharmacokinetic equivalence of formulations (bioequivalence)", next_id = "be_type"),
      list(label = "Single-arm, response rate vs. a historical control (Phase II)", next_id = "term_simon"),
      list(label = "Interim analyses planned (group sequential)", next_id = "gs_type"),
      list(label = "Several primary endpoints or comparisons (multiplicity adjustment)", next_id = "mult_type"),
      list(label = "Detect whether the effect differs between subgroups (interaction)", next_id = "term_subgroup"),
      list(label = "A Bayesian design (assurance, or a Bayes-factor target)", next_id = "bayes_type"),
      list(label = "Phase I dose-finding (3+3, continual reassessment method)", next_id = "term_dose_finding"),
      list(label = "Platform / basket / umbrella trial", next_id = "term_platform")
    )
  ),

  equiv_outcome = list(
    id = "equiv_outcome", stage = 2,
    question = "Is the outcome continuous (a mean) or a proportion?",
    options = list(
      list(label = "Continuous (means)", next_id = "term_tost_means"),
      list(label = "Proportion", next_id = "term_tost_proportions")
    )
  ),

  noninf_outcome = list(
    id = "noninf_outcome", stage = 2,
    question = "Is the outcome continuous (a mean) or a proportion?",
    options = list(
      list(label = "Continuous (means)", next_id = "term_noninferiority_means"),
      list(label = "Proportion", next_id = "term_noninferiority_proportions"),
      list(label = "Binary, with the margin set as an odds ratio", next_id = "term_noninferiority_or"),
      list(label = "Time-to-event, with the margin set as a hazard ratio", next_id = "term_noninferiority_hr")
    )
  ),

  be_type = list(
    id = "be_type", stage = 2,
    question = "How should the bioequivalence study be powered?",
    options = list(
      list(label = "Power at an assumed true ratio and CV (standard)", next_id = "term_bioequivalence"),
      list(label = "Expected power averaged over uncertainty in the CV/ratio (assurance)", next_id = "term_be_assurance")
    )
  ),

  gs_type = list(
    id = "gs_type", stage = 2,
    question = "What is the outcome, and how are the interim boundaries set?",
    options = list(
      list(label = "Continuous outcome, O'Brien-Fleming / Pocock boundaries", next_id = "term_gs_normal"),
      list(label = "Binary outcome", next_id = "term_gs_binary"),
      list(label = "Time-to-event outcome", next_id = "term_gs_survival"),
      list(label = "Continuous outcome, Lan-DeMets alpha-spending function (2 looks)", next_id = "term_lan_demets")
    )
  ),

  mult_type = list(
    id = "mult_type", stage = 2,
    question = "Which comparison is repeated across the endpoints / arms?",
    options = list(
      list(label = "One proportion vs. a reference value", next_id = "term_mult_p1"),
      list(label = "Two independent proportions", next_id = "term_mult_p2"),
      list(label = "One mean vs. a reference value", next_id = "term_mult_m1"),
      list(label = "Two independent means (family-wise error, Bonferroni / Sidak)", next_id = "term_mult_m2"),
      list(label = "Two independent means (false discovery rate, Benjamini-Hochberg)", next_id = "term_mult_fdr"),
      list(label = "Several arms vs. one common control, means (Dunnett)", next_id = "term_dunnett")
    )
  ),

  bayes_type = list(
    id = "bayes_type", stage = 2,
    question = "Which Bayesian criterion?",
    options = list(
      list(label = "Assurance: probability of success averaged over a prior (two proportions, odds ratio)", next_id = "term_bayes_assurance"),
      list(label = "Bayes factor design analysis: probability the Bayes factor reaches a threshold (two means)", next_id = "term_bfda")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.4) ----
  selection_basis = list(
    id = "selection_basis", stage = 2,
    question = "On what basis were participants selected into the study?",
    help = paste(
      "This is the single most useful discriminator in the whole tree.",
      "Ask what you knew about each person BEFORE enrolling them -- not",
      "whether the data collection was prospective or retrospective",
      "(a retrospective cohort and a case-control are both",
      "\"backward-looking\" in time but differ completely in how people",
      "were selected)."
    ),
    options = list(
      list(label = "Their exposure status (outcome measured/ascertained later)", next_id = "term_cohort_rr"),
      list(label = "Their outcome/disease status (exposure ascertained backwards)", next_id = "cc_matching"),
      list(label = "Neither -- both exposure and outcome measured at the same time (cross-sectional)", next_id = "outcome_type"),
      list(label = "Cases drawn from within a defined cohort, controls sampled from it (nested case-control)", next_id = "term_nested_cc"),
      list(label = "Cases + a randomly sampled sub-cohort from a defined cohort (case-cohort)", next_id = "term_case_cohort"),
      list(label = "Each case is their own control, compared across different time windows (case-crossover)", next_id = "term_case_crossover"),
      list(label = "Repeated events within the same individuals, self-controlled (SCCS)", next_id = "term_sccs"),
      list(label = "The unit of observation is a group/area, not a person (ecological)", next_id = "term_ecological"),
      list(label = "Exposed and unexposed matched on a propensity score", next_id = "term_psm"),
      list(label = "Exposure changes over time within the same people (time-varying exposure)", next_id = "term_time_varying")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.5) ----
  cc_matching = list(
    id = "cc_matching", stage = 2,
    question = "Are cases and controls matched?",
    options = list(
      list(label = "No -- unmatched", next_id = "term_cc_unmatched"),
      list(label = "Yes -- individually matched 1:1 or 1:m", next_id = "term_cc_matched"),
      list(label = "Frequency-matched (matched at group level, analysed unmatched/stratified)", next_id = "term_cc_freq_matched")
    )
  ),

  # ---------------------------------------------------------- Stage 3 ----
  outcome_type = list(
    id = "outcome_type", stage = 3,
    question = "What type is the outcome (dependent) variable?",
    options = list(
      list(label = "Continuous (e.g. BP, Hb, BMI, a score)", next_id = "groups_count", set = list(outcome = "continuous")),
      list(label = "Binary (e.g. cured/not, positive/negative)", next_id = "groups_count", set = list(outcome = "binary")),
      list(label = "Categorical, 3+ unordered categories", next_id = "term_chisq_independence_direct"),
      list(label = "Ordinal (e.g. Likert, stage, grade)", next_id = "term_ordinal"),
      list(label = "Count / rate (e.g. episodes per person-time)", next_id = "rate_type"),
      list(label = "Time-to-event (e.g. survival, time to recurrence)", next_id = "surv_type"),
      list(label = "Repeated measurements over time on the same subjects (longitudinal)", next_id = "long_type"),
      list(label = "Several continuous outcomes analysed jointly (multivariate)", next_id = "term_manova"),
      list(label = "Continuous but clearly non-normal -- a rank-based (nonparametric) test", next_id = "np_type")
    )
  ),

  rate_type = list(
    id = "rate_type", stage = 3,
    question = "Which count / rate comparison?",
    options = list(
      list(label = "Two groups' incidence rates (Poisson)", next_id = "term_count_rate"),
      list(label = "Two groups' rates with overdispersion (negative binomial)", next_id = "term_nb_rates"),
      list(label = "One group's rate vs. a known reference rate (exact Poisson)", next_id = "term_exact_poisson"),
      list(label = "Effect of a continuous exposure on the rate (Poisson regression)", next_id = "term_poisson_reg")
    )
  ),

  surv_type = list(
    id = "surv_type", stage = 3,
    question = "Which time-to-event design?",
    options = list(
      list(label = "Log-rank test (two survival curves)", next_id = "term_logrank"),
      list(label = "Log-rank test stratified by a factor (e.g. centre)", next_id = "term_surv_stratified"),
      list(label = "Log-rank test allowing for accrual, follow-up and noncompliance", next_id = "term_surv_noncompliance"),
      list(label = "Non-proportional hazards (weighted log-rank, e.g. delayed effect)", next_id = "term_weighted_logrank"),
      list(label = "Restricted mean survival time (RMST) difference", next_id = "term_rmst"),
      list(label = "Competing risks (cause-specific hazards)", next_id = "term_competing_risks"),
      list(label = "Cox regression for a covariate's hazard ratio", next_id = "cox_type"),
      list(label = "Non-inferiority on a hazard ratio", next_id = "term_noninferiority_hr"),
      list(label = "One group's survival vs. a historical control", next_id = "term_surv_one_sample")
    )
  ),

  long_type = list(
    id = "long_type", stage = 3,
    question = "How will the repeated measurements be analysed?",
    options = list(
      list(label = "Difference in rate of change between two groups (GEE / GLS, Liu & Liang)", next_id = "term_long_slope"),
      list(label = "Difference in rate of change (Diggle et al.)", next_id = "term_long_diggle"),
      list(label = "Difference in rate of change, random-slope model (Ard & Edland)", next_id = "term_long_edland"),
      list(label = "Difference in rate of change allowing for dropout (Hu, Mackey & Thomas)", next_id = "term_long_hu"),
      list(label = "MMRM with dropout and AR(1) correlation (end-of-study difference)", next_id = "term_mmrm"),
      list(label = "Repeated-measures ANOVA: between-subjects effect", next_id = "term_rm_between"),
      list(label = "Repeated-measures ANOVA: within-subjects (time) effect", next_id = "term_rm_within"),
      list(label = "Mixed (split-plot) ANOVA: group x time interaction", next_id = "term_rm_interaction"),
      list(label = "Multilevel model, two levels (measurements within subjects)", next_id = "term_multilevel2"),
      list(label = "Multilevel model, three levels (subjects within clusters)", next_id = "term_multilevel3"),
      list(label = "Growth-curve mixed model, simulated directly (Monte Carlo)", next_id = "term_growth_curve"),
      list(label = "Binary outcome measured on k >= 3 occasions (Cochran's Q)", next_id = "term_cochran_q"),
      list(label = "Non-normal outcome measured on k >= 3 occasions (Friedman)", next_id = "term_friedman")
    )
  ),

  np_type = list(
    id = "np_type", stage = 3,
    question = "Which rank-based comparison?",
    options = list(
      list(label = "Two independent groups (Wilcoxon rank-sum / Mann-Whitney)", next_id = "term_wilcoxon_rs"),
      list(label = "Paired data or one sample vs. a value (Wilcoxon signed-rank)", next_id = "term_wilcoxon_sr"),
      list(label = "Paired data, signs only (sign test)", next_id = "term_sign_test"),
      list(label = "Three or more independent groups (Kruskal-Wallis)", next_id = "term_kruskal"),
      list(label = "Three or more ordered groups (Jonckheere-Terpstra trend)", next_id = "term_jonckheere"),
      list(label = "Three or more repeated measurements (Friedman)", next_id = "term_friedman"),
      list(label = "Two independent groups, any difference in distribution (Kolmogorov-Smirnov)", next_id = "term_ks"),
      list(label = "Two independent groups, runs test (Wald-Wolfowitz)", next_id = "term_runs")
    )
  ),

  groups_count = list(
    id = "groups_count", stage = 3,
    question = "How many groups are being compared?",
    options = list(
      list(label = "1 group vs. a known/reference value", next_id = "term_one_group_vs_ref"),
      list(label = "2 groups", next_id = "dependence_q"),
      list(label = "3 or more groups", next_id = "k_type")
    )
  ),

  k_type = list(
    id = "k_type", stage = 3,
    question = "What question about the 3+ groups?",
    options = list(
      list(label = "Is there any difference among the groups? (omnibus)", next_id = "term_k_groups"),
      list(label = "Is there a trend across ordered groups? (dose-response)", next_id = "term_k_trend"),
      list(label = "Which pairs differ? (all pairwise, post-hoc)", next_id = "term_k_pairwise"),
      list(label = "Does each group differ from one common control?", next_id = "term_k_vs_control")
    )
  ),

  dependence_q = list(
    id = "dependence_q", stage = 3,
    question = "Are the two groups independent, or the same subjects measured twice (paired)?",
    options = list(
      list(label = "Independent",
           next_id = function(flags) if (identical(flags$outcome, "continuous")) "indep_cont" else "indep_bin"),
      list(label = "Paired / dependent (before-after, matched pairs)",
           next_id = function(flags) {
             if (identical(flags$outcome, "continuous")) "term_two_groups_paired_cont" else "term_binary_paired_mcnemar"
           })
    )
  ),

  indep_cont = list(
    id = "indep_cont", stage = 3,
    question = "Anything unusual about the two groups?",
    options = list(
      list(label = "No -- equal group sizes and similar variances (t-test)", next_id = "term_two_groups_independent"),
      list(label = "Unequal group sizes (e.g. 2:1 allocation)", next_id = "term_means_unequal_n"),
      list(label = "Clearly unequal variances (Welch's t-test)", next_id = "term_means_welch")
    )
  ),

  indep_bin = list(
    id = "indep_bin", stage = 3,
    question = "Which analysis of the two proportions?",
    options = list(
      list(label = "Standard large-sample test (z / chi-square)", next_id = "term_two_groups_independent"),
      list(label = "Small samples -- Fisher's exact test", next_id = "term_exact_fisher"),
      list(label = "Small samples -- Boschloo's exact unconditional test", next_id = "term_exact_boschloo"),
      list(label = "Pooled across strata or centres (Mantel-Haenszel)", next_id = "term_mantel_haenszel")
    )
  ),

  # ================================================================== #
  # Terminal nodes -- built (route via calculator_catalog)
  # ================================================================== #

  term_prop_precision = .term("term_prop_precision", "Single proportion, precision-based", "proportion_single_precision"),
  term_mean_precision = .term("term_mean_precision", "Single mean, precision-based", "means_single_precision"),
  term_rate_precision = .term("term_rate_precision", "Incidence rate, precision-based", "incidence_rate_precision"),
  term_sd_precision = .term("term_sd_precision", "Standard deviation, precision-based", "variance_sd_precision"),
  term_capture_recapture = .term("term_capture_recapture", "Capture-recapture population size estimate", "capture_recapture"),
  term_ratio_rr = .term("term_ratio_rr", "Risk ratio, precision-based", "ratio_risk_ratio"),
  term_ratio_or = .term("term_ratio_or", "Odds ratio, precision-based", "ratio_odds_ratio"),
  term_ratio_rate = .term("term_ratio_rate", "Rate ratio, precision-based", "ratio_rate_ratio"),

  term_diag_precision = .term("term_diag_precision", "Sensitivity/specificity, precision-based", "diagnostic_precision"),
  term_diag_vs_ref = .term("term_diag_vs_ref", "Sensitivity/specificity vs. known/reference value", "diagnostic_vs_reference"),
  term_diag_two_indep = .term("term_diag_two_indep", "Two independent (unpaired) diagnostic tests", "diagnostic_two_indep"),
  term_diag_two_paired = .term("term_diag_two_paired", "Two paired diagnostic tests (same subjects)", "diagnostic_two_paired"),
  term_ppv_npv = .term("term_ppv_npv", "Predictive values (PPV/NPV)", "diagnostic_ppv_npv"),
  term_diag_lr = .term("term_diag_lr", "Likelihood ratios (LR+ / LR-), precision-based", "diagnostic_likelihood_ratio"),
  term_diag_dor = .term("term_diag_dor", "Diagnostic odds ratio (DOR)", "diagnostic_odds_ratio"),
  term_auc_single = .term("term_auc_single", "Single ROC AUC vs. chance", "roc_single_auc"),
  term_auc_paired = .term("term_auc_paired", "Two correlated (paired) ROC AUCs", "roc_compare_two_aucs"),

  term_kappa = .term("term_kappa", "Cohen's kappa (categorical agreement)", "agreement_kappa"),
  term_icc = .term("term_icc", "Intraclass correlation (ICC)", "agreement_icc"),
  term_bland_altman = .term("term_bland_altman", "Limits of agreement (Bland-Altman)", "agreement_bland_altman"),
  term_ccc = .term("term_ccc", "Concordance correlation coefficient (CCC)", "agreement_ccc"),
  term_cronbach = .term("term_cronbach", "Scale internal consistency (Cronbach's alpha)", "agreement_cronbach"),

  term_pred_binary = .term("term_pred_binary", "Prediction model development, binary outcome", "prediction_binary"),
  term_pred_continuous = .term("term_pred_continuous", "Prediction model development, continuous outcome", "prediction_continuous"),
  term_pred_survival = .term("term_pred_survival", "Prediction model development, time-to-event outcome", "prediction_survival"),
  term_pred_extval = .term("term_pred_extval", "Prediction model external validation, binary outcome", "prediction_external_validation"),

  term_meta_power = .term("term_meta_power", "Number of studies for a planned meta-analysis", "meta_power_k"),
  term_tsa = list(id = "term_tsa", terminal = TRUE,
    design = "Trial sequential analysis (required information size)",
    catalog_key = function(flags) {
      switch(if (is.null(flags$tsa_outcome)) "RR" else flags$tsa_outcome,
             RR = "tsa_rr", OR = "tsa_or", RD = "tsa_rd", MD = "tsa_md")
    }),

  term_corr_pearson = .term("term_corr_pearson", "Pearson correlation", "correlation_pearson"),
  term_corr_spearman = .term("term_corr_spearman", "Spearman rank correlation", "correlation_spearman"),
  term_kendall = .term("term_kendall", "Kendall's tau", "kendall_tau"),
  term_corr_pb = .term("term_corr_pb", "Point-biserial correlation", "correlation_point_biserial"),
  term_corr_partial = .term("term_corr_partial", "Partial correlation", "correlation_partial"),
  term_corr_two_indep = .term("term_corr_two_indep", "Two independent correlations", "correlation_two_independent"),
  term_corr_two_dep = .term("term_corr_two_dep", "Two dependent (overlapping) correlations", "correlation_two_dependent"),
  term_reg_slope = .term("term_reg_slope", "Simple linear regression slope", "correlation_regression_slope"),
  term_reg_r2 = .term("term_reg_r2", "Multiple regression, R-squared", "regression_r2"),
  term_reg_r2_increase = .term("term_reg_r2_increase", "Hierarchical regression, R-squared increase", "regression_r2_increase"),
  term_anova_general = .term("term_anova_general", "Factorial ANOVA / ANCOVA", "anova_general"),
  term_logit_bin = .term("term_logit_bin", "Logistic regression, binary predictor", "logistic_binary"),
  term_logit_cont = .term("term_logit_cont", "Logistic regression, continuous predictor", "logistic_continuous"),
  term_logit_bin_adj = .term("term_logit_bin_adj", "Multiple logistic regression, binary predictor (adjusted)", "logistic_binary_adjusted"),
  term_logit_cont_adj = .term("term_logit_cont_adj", "Multiple logistic regression, continuous predictor (adjusted)", "logistic_continuous_adjusted"),
  term_cox_binary = .term("term_cox_binary", "Cox regression, binary covariate", "cox_binary"),
  term_cox_continuous = .term("term_cox_continuous", "Cox regression, continuous covariate", "cox_continuous"),
  term_poisson_reg = .term("term_poisson_reg", "Poisson regression, continuous predictor", "poisson_regression_continuous"),

  term_cluster_deff = .term("term_cluster_deff", "Cluster / multistage sampling, design effect", "cluster_deff"),
  term_cluster_deff_var = .term("term_cluster_deff_var", "Cluster sampling, variable cluster size", "cluster_deff_variable"),
  term_cluster_survey = .term("term_cluster_survey", "WHO EPI-style cluster survey", "cluster_survey"),
  term_cluster_pps = .term("term_cluster_pps", "Two-stage PPS sampling, optimal take per cluster", "cluster_pps_optimal"),
  term_stratified = .term("term_stratified", "Stratified sampling", "stratified_sampling"),
  term_lqas = .term("term_lqas", "Lot quality assurance sampling (LQAS)", "lqas"),

  term_efa_cfa = .term("term_efa_cfa", "EFA / CFA sample size", "efa_cfa_guidance"),
  term_sem_rmsea = .term("term_sem_rmsea", "CFA / SEM test of close fit (RMSEA)", "sem_rmsea"),
  term_irt = .term("term_irt", "IRT item calibration", "irt_calibration"),

  term_rule3_bound = .term("term_rule3_bound", "Upper bound on an unseen event rate (rule of three)", "rule_of_three_bound"),
  term_rule3_n = .term("term_rule3_n", "Sample size to observe at least one event", "rule_of_three_n_required"),
  term_rule3_imperfect = .term("term_rule3_imperfect", "Detect at least one case with an imperfect test", "rule_of_three_detect_imperfect"),
  term_exact_binomial = .term("term_exact_binomial", "Exact binomial test, one proportion", "exact_binomial"),
  term_exact_poisson = .term("term_exact_poisson", "Exact Poisson test, one rate vs. reference", "exact_poisson"),

  term_resource_equation = .term("term_resource_equation", "Resource equation (animal studies)", "resource_equation"),
  term_animal_rank = .term("term_animal_rank", "Animal / preclinical K-sample rank test", "animal_rank_test"),
  term_pilot = .term("term_pilot", "Pilot / feasibility study", "pilot_feasibility"),
  term_evpi = .term("term_evpi", "Expected value of perfect information (EVPI)", "evpi"),
  term_evsi = .term("term_evsi", "Expected value of sample information (EVSI) / optimal n", "evsi_enbs"),
  term_microarray = .term("term_microarray", "Two-sample microarray study, FDR-controlled", "multiplicity_fdr_microarray",
    note = "Bioconductor tools for RNA-seq designs (RNASeqPower, PROPER, ssize) are not available here -- this is the exact Liu & Hwang FDR design for two-group expression studies."),

  term_crossover = .term("term_crossover", "Crossover trial (2x2, continuous)", "crossover_2x2"),
  term_stepped_wedge = .term("term_stepped_wedge", "Stepped-wedge cluster-randomised trial", "stepped_wedge_normal",
    note = "Continuous outcome (Hussey & Hughes). The binary-outcome version is still open -- see docs/ROADMAP.md, section 4."),
  term_glmm_cont = .term("term_glmm_cont", "Cluster-randomised trial, continuous outcome (Monte Carlo LMM)", "glmm_lmm_continuous"),
  term_glmm_binary = .term("term_glmm_binary", "Cluster-randomised trial, binary outcome (Monte Carlo GLMM)", "glmm_binary"),

  term_simon = .term("term_simon", "Simon two-stage Phase II design", "simon_two_stage"),
  term_tost_means = .term("term_tost_means", "Equivalence of two means (TOST)", "tost_means"),
  term_tost_proportions = .term("term_tost_proportions", "Equivalence of two proportions (TOST)", "tost_proportions"),
  term_bioequivalence = .term("term_bioequivalence", "Bioequivalence crossover (TOST)", "tost_bioequivalence"),
  term_be_assurance = .term("term_be_assurance", "Bioequivalence crossover, expected power (assurance)", "tost_assurance"),
  term_noninferiority_means = .term("term_noninferiority_means", "Non-inferiority trial, two means", "noninferiority_means"),
  term_noninferiority_proportions = .term("term_noninferiority_proportions", "Non-inferiority trial, two proportions", "noninferiority_proportions"),
  term_noninferiority_or = .term("term_noninferiority_or", "Non-inferiority trial, odds ratio", "noninferiority_or"),
  term_noninferiority_hr = .term("term_noninferiority_hr", "Non-inferiority trial, hazard ratio", "noninferiority_hr"),
  term_gs_normal = .term("term_gs_normal", "Group sequential design, continuous outcome", "group_sequential_normal"),
  term_gs_binary = .term("term_gs_binary", "Group sequential design, binary outcome", "group_sequential_binary"),
  term_gs_survival = .term("term_gs_survival", "Group sequential design, time-to-event outcome", "group_sequential_survival"),
  term_lan_demets = .term("term_lan_demets", "Lan-DeMets alpha-spending design", "lan_demets_normal"),
  term_mult_p1 = .term("term_mult_p1", "Multiplicity-adjusted, one proportion", "multiplicity_proportion_1s"),
  term_mult_p2 = .term("term_mult_p2", "Multiplicity-adjusted, two proportions", "multiplicity_proportion_2s"),
  term_mult_m1 = .term("term_mult_m1", "Multiplicity-adjusted, one mean", "multiplicity_means_1s"),
  term_mult_m2 = .term("term_mult_m2", "Multiplicity-adjusted, two means", "multiplicity_means_2s"),
  term_mult_fdr = .term("term_mult_fdr", "FDR-controlled, two means", "multiplicity_fdr_means_2s"),
  term_dunnett = .term("term_dunnett", "Multi-arm trial vs. a common control (Dunnett)", "multiplicity_dunnett"),
  term_subgroup = .term("term_subgroup", "Subgroup / interaction testing", "subgroup_interaction"),
  term_bayes_assurance = .term("term_bayes_assurance", "Bayesian assurance, two proportions", "bayesian_assurance_or"),
  term_bfda = .term("term_bfda", "Bayes factor design analysis, two means", "bfda_ttest"),

  term_analyze_compare_proportions = .term("term_analyze_compare_proportions", "Compare two proportions", "analyze_compare_proportions"),
  term_analyze_compare_means = .term("term_analyze_compare_means", "Compare two means from summary statistics", "analyze_compare_means"),
  term_analyze_std_direct = .term("term_analyze_std_direct", "Direct standardization", "analyze_std_direct"),
  term_analyze_std_indirect = .term("term_analyze_std_indirect", "Indirect standardization and SMR", "analyze_std_indirect"),
  term_analyze_std_smr = .term("term_analyze_std_smr", "SMR from observed and expected events", "analyze_std_smr"),
  term_analyze_mcnemar = .term("term_analyze_mcnemar", "McNemar's test and matched-pair odds ratio", "analyze_mcnemar"),
  term_analyze_kappa = .term("term_analyze_kappa", "Cohen's kappa agreement", "analyze_kappa"),
  term_analyze_trend = .term("term_analyze_trend", "Chi-square test for trend", "analyze_trend"),
  term_analyze_rate_single = .term("term_analyze_rate_single", "Confidence interval for an incidence rate", "analyze_rate_single"),
  term_analyze_rate_stratified = .term("term_analyze_rate_stratified", "Mantel-Haenszel rate ratio over strata", "analyze_rate_stratified"),
  term_analyze_vaccine_risk = .term("term_analyze_vaccine_risk", "Vaccine efficacy from attack rates", "analyze_vaccine_risk"),
  term_analyze_vaccine_rate = .term("term_analyze_vaccine_rate", "Vaccine efficacy from person-time rates", "analyze_vaccine_rate"),
  term_analyze_vaccine_odds = .term("term_analyze_vaccine_odds", "Vaccine effectiveness from a case-control study", "analyze_vaccine_odds"),
  term_analyze_rate_ratio = .term("term_analyze_rate_ratio", "Rate ratio and rate difference from person-time", "analyze_rate_ratio"),
  term_analyze_mh_cohort = .term("term_analyze_mh_cohort", "Mantel-Haenszel, cohort / trial / cross-sectional", "analyze_mh_cohort"),
  term_analyze_mh_case_control = .term("term_analyze_mh_case_control", "Mantel-Haenszel, case-control", "analyze_mh_case_control"),
  term_analyze_ci_proportion = .term("term_analyze_ci_proportion", "Confidence interval for a proportion", "analyze_ci_proportion"),
  term_analyze_ci_mean = .term("term_analyze_ci_mean", "Confidence interval for a mean and standard deviation", "analyze_ci_mean"),
  term_analyze_dx_single = .term("term_analyze_dx_single", "Diagnostic test evaluation from a 2x2 table", "analyze_dx_single"),
  term_analyze_dx_combined = .term("term_analyze_dx_combined", "Serial / parallel testing of 2-6 tests", "analyze_dx_combined"),
  term_analyze_2x2_cohort = .term("term_analyze_2x2_cohort", "2x2 table analysis, cohort / trial", "analyze_2x2_cohort"),
  term_analyze_2x2_cross_sectional = .term("term_analyze_2x2_cross_sectional", "2x2 table analysis, cross-sectional", "analyze_2x2_cross_sectional"),
  term_analyze_2x2_case_control = .term("term_analyze_2x2_case_control", "2x2 table analysis, case-control", "analyze_2x2_case_control"),

  term_cohort_rr = .term("term_cohort_rr", "Cohort study (relative risk)", "cohort_rr",
    note = paste(
      "This module assumes a binary outcome (RR). If your cohort's outcome",
      "is actually continuous (e.g. comparing a mean biomarker level",
      "between exposed and unexposed groups followed forward), you want",
      "\"Two independent means\" in the Means module instead; for an",
      "incidence rate per person-time use Incidence Rate, and for time to",
      "an event use Log-Rank / Survival.")),
  term_cc_unmatched = .term("term_cc_unmatched", "Unmatched case-control study", "case_control_unmatched"),
  term_cc_freq_matched = .term("term_cc_freq_matched", "Frequency-matched case-control study", "case_control_unmatched",
    note = "Frequency matching is analysed like an unmatched design (stratified), not the individually-matched formula -- use the unmatched calculator."),
  term_cc_matched = .term("term_cc_matched", "Individually matched case-control study", "case_control_matched"),
  term_nested_cc = .term("term_nested_cc", "Nested case-control study", "case_control_nested"),
  term_case_cohort = .term("term_case_cohort", "Case-cohort study", "case_control_case_cohort"),
  term_case_crossover = .term("term_case_crossover", "Case-crossover study", "case_crossover",
    note = paste(
      "A case-crossover study is mathematically a 1:M matched case-control",
      "design, with M control PERIODS per case instead of separately",
      "sampled control people (Maclure 1991; Mittleman et al. 1995) -- so",
      "this app's matched case-control calculator applies directly, with",
      "inputs reinterpreted as control-period exposure prevalence/",
      "correlation/count. Dharmarajan, Lee & Izem (2019), who confirm that",
      "equivalence, also show this formula can UNDERESTIMATE the true",
      "required N for case-crossover specifically -- treat the result as",
      "an optimistic planning estimate, not a precise one.")),
  term_sccs = .term("term_sccs", "Self-controlled case series (SCCS)", "sccs_samplesize"),

  term_chisq_independence_direct = .term("term_chisq_independence_direct", "Chi-square test of independence/association", "chisq_independence"),
  term_ordinal = .term("term_ordinal", "Ordinal outcome, two groups (proportional odds)", "logistic_ordinal",
    note = "For an ordinal outcome across 3+ groups, a rank-based test (Kruskal-Wallis, or Jonckheere-Terpstra for ordered groups) in Nonparametric Tests is the usual alternative."),
  term_count_rate = .term("term_count_rate", "Comparison of two incidence rates", "rate_comparison"),
  term_nb_rates = .term("term_nb_rates", "Two negative binomial rates", "negative_binomial_rates"),
  term_logrank = .term("term_logrank", "Log-rank test (two survival curves)", "logrank"),
  term_surv_stratified = .term("term_surv_stratified", "Stratified log-rank test", "survival_stratified"),
  term_surv_noncompliance = .term("term_surv_noncompliance", "Log-rank test with accrual, follow-up and noncompliance", "survival_noncompliance"),
  term_weighted_logrank = .term("term_weighted_logrank", "Weighted log-rank test (non-proportional hazards)", "weighted_logrank"),
  term_rmst = .term("term_rmst", "Restricted mean survival time comparison", "rmst_comparison"),
  term_competing_risks = .term("term_competing_risks", "Competing risks", "competing_risks_joint"),
  term_long_slope = .term("term_long_slope", "Longitudinal slope difference (Liu & Liang)", "longitudinal_slope_diff"),
  term_long_diggle = .term("term_long_diggle", "Longitudinal slope difference (Diggle et al.)", "longitudinal_diggle"),
  term_long_edland = .term("term_long_edland", "Longitudinal slope difference (Ard & Edland)", "longitudinal_edland"),
  term_long_hu = .term("term_long_hu", "Longitudinal slope difference with dropout (Hu, Mackey & Thomas)", "longitudinal_hu"),
  term_mmrm = .term("term_mmrm", "MMRM with dropout, AR(1)", "mmrm_ar1"),
  term_rm_between = .term("term_rm_between", "Repeated-measures ANOVA, between-subjects effect", "rm_anova_between"),
  term_rm_within = .term("term_rm_within", "Repeated-measures ANOVA, within-subjects effect", "rm_anova_within"),
  term_rm_interaction = .term("term_rm_interaction", "Mixed ANOVA, group x time interaction", "rm_anova_interaction"),
  term_multilevel2 = .term("term_multilevel2", "Multilevel model, two levels", "multilevel_two_level"),
  term_multilevel3 = .term("term_multilevel3", "Multilevel model, three levels", "multilevel_three_level"),
  term_growth_curve = .term("term_growth_curve", "Growth-curve mixed model (Monte Carlo)", "growth_curve_lmm"),
  term_cochran_q = .term("term_cochran_q", "Cochran's Q test", "cochran_q"),
  term_friedman = .term("term_friedman", "Friedman test", "friedman"),
  term_manova = .term("term_manova", "Two-group Hotelling's T-squared (MANOVA)", "manova_hotelling",
    note = "Two groups only; the k > 2 group global test is still open (docs/ROADMAP.md, section 4)."),
  term_wilcoxon_rs = .term("term_wilcoxon_rs", "Wilcoxon rank-sum (Mann-Whitney) test", "wilcoxon_rank_sum"),
  term_wilcoxon_sr = .term("term_wilcoxon_sr", "Wilcoxon signed-rank test", "wilcoxon_signed_rank"),
  term_sign_test = .term("term_sign_test", "Sign test", "sign_test"),
  term_kruskal = .term("term_kruskal", "Kruskal-Wallis test", "kruskal_wallis"),
  term_jonckheere = .term("term_jonckheere", "Jonckheere-Terpstra trend test", "jonckheere_terpstra"),
  term_ks = .term("term_ks", "Two-sample Kolmogorov-Smirnov test", "ks_two_sample"),
  term_runs = .term("term_runs", "Wald-Wolfowitz runs test", "wald_wolfowitz_runs"),

  term_one_group_vs_ref = .term("term_one_group_vs_ref", "One group vs. a known/reference value",
    .by_outcome("means_single", "proportion_single")),
  term_two_groups_independent = .term("term_two_groups_independent", "Two independent groups",
    .by_outcome("means_two_indep", "proportion_two_indep")),
  term_means_unequal_n = .term("term_means_unequal_n", "Two independent means, unequal group sizes", "means_two_indep_unequal_n"),
  term_means_welch = .term("term_means_welch", "Two independent means, unequal variances (Welch)", "means_welch"),
  term_exact_fisher = .term("term_exact_fisher", "Fisher's exact test, two proportions", "exact_fisher"),
  term_exact_boschloo = .term("term_exact_boschloo", "Boschloo's exact unconditional test, two proportions", "exact_boschloo"),
  term_mantel_haenszel = .term("term_mantel_haenszel", "Mantel-Haenszel test (stratified proportions)", "chisq_mantelhaenszel"),
  term_two_groups_paired_cont = .term("term_two_groups_paired_cont", "Two paired means (e.g. pre-post)", "means_two_dep"),
  term_binary_paired_mcnemar = .term("term_binary_paired_mcnemar", "Two paired/dependent proportions (McNemar)", "proportion_two_dep"),
  term_k_groups = .term("term_k_groups", "Three or more groups", .by_outcome("means_k", "proportion_k")),
  term_k_trend = .term("term_k_trend", "Trend across ordered groups",
    .by_outcome("means_planned_contrast", "chisq_cochran_armitage")),
  term_k_pairwise = .term("term_k_pairwise", "All pairwise comparisons (post-hoc)",
    .by_outcome("means_posthoc_pairwise", "proportion_posthoc_pairwise")),
  term_k_vs_control = .term("term_k_vs_control", "Each group vs. one common control",
    .by_outcome("multiplicity_dunnett", "multiplicity_proportion_2s"),
    note = paste(
      "For means this is the exact Dunnett many-to-one design. For",
      "proportions no Dunnett calculator is built, so this uses the",
      "two-proportion calculation at a Bonferroni/Sidak-adjusted alpha for",
      "the k-1 comparisons -- valid, but somewhat conservative.")),

  # ================================================================== #
  # Terminal nodes -- not yet built (honest placeholder, no catalog_key).
  # Every one of these is listed in docs/ROADMAP.md sec. 4 with what would
  # unblock it.
  # ================================================================== #

  term_n_of_1 = .term_open("term_n_of_1", "N-of-1 trial",
    would_use = "no verified formula or reachable package yet (nof1/Nof1 not on the CRAN mirror)"),
  term_auc_unpaired = .term_open("term_auc_unpaired", "Two independent (unpaired) ROC AUCs",
    would_use = "pROC::power.roc.test does not support unpaired AUCs; needs a separately verified formula",
    citation = "Hanley & McNeil (1983) Radiology 148:839-843",
    note = "For two tests on the same subjects, go back and choose the paired option."),
  term_mrmc = .term_open("term_mrmc", "Multi-reader multi-case (MRMC) study",
    would_use = "iMRMC as a verification oracle (Obuchowski-Rockette / DBM); multi-batch effort",
    citation = "Obuchowski & Rockette (1995) Commun Stat Simul Comput 24:285-308"),
  term_deming = .term_open("term_deming", "Method comparison by Deming / Passing-Bablok regression",
    would_use = "a citable simulation protocol (e.g. Linnet) -- deming, mcr and MethComp are analysis-only"),
  term_pred_extval_tte = .term_open("term_pred_extval_tte", "External validation, time-to-event outcome",
    would_use = "paused by the project owner pending paper access (Riley et al. 2022)",
    citation = "Riley et al. (2022) Stat Med 41:1280-1295"),
  term_pred_updating = .term_open("term_pred_updating", "Model updating / recalibration, or a machine-learning model",
    would_use = "paused by the project owner"),
  term_nma = .term_open("term_nma", "Network meta-analysis",
    would_use = "no verified closed form yet",
    note = "For a pairwise meta-analysis, go back and choose the number-of-studies option."),
  term_dose_finding = .term_open("term_dose_finding", "Phase I dose-finding (3+3, CRM)",
    would_use = "an operating-characteristics simulator verified against dfcrm::crmsim()",
    citation = "O'Quigley, Pepe & Fisher (1990) Biometrics 46:33-48"),
  term_platform = .term_open("term_platform", "Platform / basket / umbrella trial",
    would_use = "the same simulator framework as dose-finding, or a multi-arm group-sequential design verified against rpact",
    note = "For several arms against one shared control, the multiplicity option (Dunnett) covers the fixed-design case."),
  term_surv_one_sample = .term_open("term_surv_one_sample", "One-sample survival vs. a historical control",
    would_use = "closed form in Finkelstein et al. (2003) / Schmidt et al. (2015); sources not reachable to verify yet",
    citation = "Finkelstein, Muzikansky & Schoenfeld (2003) Stat Med 22:3035-3046"),
  term_psm = .term_open("term_psm", "Propensity-score-matched comparison",
    would_use = "a published planning heuristic with a worked example (MatchIt/Matching are analysis-only)",
    note = "A common interim approach: size the unmatched comparison with the matching calculator for your outcome, then inflate for the expected fraction of unmatched subjects."),
  term_time_varying = .term_open("term_time_varying", "Time-varying exposure",
    would_use = "OPTITXS (not on CRAN) or the Basagana & Spiegelman formulas",
    citation = "Basagana & Spiegelman (2010) Stat Med 29:2549-2562"),
  term_gwas = .term_open("term_gwas", "Genome-wide / candidate-gene association study",
    would_use = "genpwr as a verification oracle (numerical-MLE engine); multi-batch effort"),
  term_gxe = .term_open("term_gxe", "Gene-environment interaction",
    would_use = "genpwr as a verification oracle (same engine as GWAS)"),

  # ================================================================== #
  # Guidance terminals -- deliberately no numeric N
  # ================================================================== #

  term_qualitative = list(id = "term_qualitative", terminal = TRUE, guidance = TRUE,
    design = "Qualitative study -- no numeric sample size",
    catalog_key = "qualitative_guidance",
    note = paste(
      "Justify sample size with information power (Malterud, Siersma &",
      "Guassora 2016) and/or saturation evidence (Guest, Bunce & Johnson",
      "2006) instead of a formula. Emitting a numeric N here would be",
      "false precision -- this app deliberately does not compute one.")),

  term_ecological = list(id = "term_ecological", terminal = TRUE, guidance = TRUE,
    design = "Ecological study (unit of observation is a group/area)",
    catalog_key = "ecological_guidance",
    note = paste(
      "The unit of analysis here is the group (e.g. district, PHC catchment),",
      "not the individual -- none of this app's individual-level calculators",
      "apply directly, and ecological analyses carry their own inference",
      "caveats (the ecological fallacy). The guidance module linked below explains how to plan one."))
)

# "I already know which test" branch, generated from home_catalog.R's
# test_families so a new calculator added to a family appears here without
# touching this file: bytest_family -> bytest_<family id> -> term_cat_<key>.
.bytest_nodes <- function(families = test_families) {
  nodes <- list()
  fam_opts <- list()
  for (fam in families) {
    keys <- Filter(function(k) isTRUE(catalog_entry(k)$built), fam$catalog_keys)
    if (length(keys) == 0) next
    fam_node <- paste0("bytest_", fam$id)
    fam_opts[[length(fam_opts) + 1]] <- list(label = fam$label, next_id = fam_node)
    nodes[[fam_node]] <- list(
      id = fam_node, stage = 3,
      question = paste0(fam$label, ": which calculation?"),
      help = fam$hint,
      options = lapply(keys, function(k) {
        list(label = catalog_entry(k)$label, next_id = paste0("term_cat_", k))
      })
    )
    for (k in keys) {
      tid <- paste0("term_cat_", k)
      nodes[[tid]] <- .term(tid, catalog_entry(k)$label, k)
    }
  }
  nodes$bytest_family <- list(
    id = "bytest_family", stage = 3,
    question = "Which family of statistical test?",
    help = "The same grouping as the \"Browse calculators\" tab's test-family view.",
    options = fam_opts
  )
  nodes
}

design_nodes <- c(design_nodes, .bytest_nodes())

# Every catalog key some path from root can end on, trying each value a
# flag-dependent next_id/catalog_key branches on. Used by the coverage tests.
design_reachable_keys <- function(nodes = design_nodes) {
  flag_sets <- c(
    list(list(outcome = "continuous"), list(outcome = "binary")),
    lapply(c("RR", "OR", "RD", "MD"), function(t) list(tsa_outcome = t))
  )
  resolve <- function(x, flags) if (is.function(x)) x(flags) else x
  seen <- character(0)
  keys <- character(0)
  queue <- "root"
  while (length(queue)) {
    id <- queue[1]
    queue <- queue[-1]
    if (id %in% seen) next
    seen <- c(seen, id)
    node <- nodes[[id]]
    for (flags in flag_sets) {
      if (isTRUE(node$terminal)) {
        keys <- c(keys, resolve(node$catalog_key, flags))
      } else {
        for (opt in node$options) queue <- c(queue, resolve(opt$next_id, flags))
      }
    }
  }
  structure(unique(keys), nodes_reached = seen)
}
