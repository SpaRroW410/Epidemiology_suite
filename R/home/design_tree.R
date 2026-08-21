# Flat-registry decision tree for the "Which calculator?" wizard
# (docs/design_identification_algorithm.md). Routes a guided Q&A session to
# either a built catalog entry (see home_catalog.R) or an honest "not yet
# built" terminal naming the module/backend/citation the checklists already
# call for -- never a silent guess and never a broken link.
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
# earlier answer" reason. `flags` accumulate as the user answers (currently
# just `outcome`: "continuous"|"binary", and `cluster`: TRUE/FALSE) rather
# than being threaded through as separate tree branches, to keep the node
# count from exploding combinatorially (Stage 5 in the source document makes
# the identical point about modifiers).

design_nodes <- list(

  root = list(
    id = "root", stage = 1,
    question = "What is the primary purpose of your study?",
    help = "If you have a hypothesis or are testing for a difference/association, choose \"Compare\". If you're just describing your own population with no comparison, choose \"Estimate\".",
    options = list(
      list(label = "Estimate a parameter with precision (prevalence, mean, rate...)", next_id = "est_type"),
      list(label = "Compare groups / test an association or hypothesis", next_id = "allocation"),
      list(label = "Build or validate a prediction/prognostic model", next_id = "term_prediction"),
      list(label = "Assess the accuracy of a diagnostic test", next_id = "diag_type"),
      list(label = "Assess agreement/reliability between raters or methods", next_id = "agree_scale"),
      list(label = "Explore experiences or meanings (qualitative)", next_id = "term_qualitative")
    )
  ),

  # ---------------------------------------------------------------- §1A ----
  est_type = list(
    id = "est_type", stage = 1,
    question = "What are you estimating?",
    help = "No comparison group and no hypothesis here -- just a target precision (confidence interval width) and a confidence level.",
    options = list(
      list(label = "A proportion / prevalence", next_id = "term_prop_precision"),
      list(label = "A mean", next_id = "term_mean_precision"),
      list(label = "An incidence rate", next_id = "term_rate_precision"),
      list(label = "A ratio (risk ratio / odds ratio / rate ratio)", next_id = "term_ratio_precision"),
      list(label = "Sensitivity or specificity of a test", next_id = "diag_type"),
      list(label = "An ICC or kappa (agreement)", next_id = "agree_scale")
    )
  ),

  # ---------------------------------------------------------------- §1D ----
  diag_type = list(
    id = "diag_type", stage = 1,
    question = "What do you need for the diagnostic test?",
    options = list(
      list(label = "Precision for sensitivity/specificity, no reference value", next_id = "term_diag_precision"),
      list(label = "Whether sensitivity/specificity differs from a known/reference value", next_id = "term_diag_vs_ref"),
      list(label = "Compare two tests on two independent groups of subjects", next_id = "term_diag_two_indep"),
      list(label = "Compare two tests on the same subjects (paired)", next_id = "term_diag_two_paired"),
      list(label = "Predictive values (PPV/NPV)", next_id = "term_ppv_npv"),
      list(label = "Area under the ROC curve (AUC)", next_id = "term_auc")
    )
  ),

  # ---------------------------------------------------------------- §1E ----
  agree_scale = list(
    id = "agree_scale", stage = 1,
    question = "What's the scale of the outcome being rated or measured?",
    options = list(
      list(label = "Categorical (e.g. present/absent, disease grade)", next_id = "term_kappa"),
      list(label = "Continuous -- reliability coefficient (ICC)", next_id = "term_icc"),
      list(label = "Continuous -- limits of agreement (Bland-Altman)", next_id = "term_bland_altman"),
      list(label = "Continuous -- concordance correlation (CCC)", next_id = "term_ccc"),
      list(label = "Scale internal consistency (Cronbach's alpha)", next_id = "term_cronbach")
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
      list(label = "Single subject, repeated periods (N-of-1)", next_id = "term_n_of_1")
    )
  ),

  # ------------------------------------------------------ Stage 2 (Q2.3) ----
  exp_intent = list(
    id = "exp_intent", stage = 2,
    question = "What is the comparison intent of the trial?",
    options = list(
      list(label = "Show one arm is better (superiority)", next_id = "outcome_type"),
      list(label = "Show it's not unacceptably worse (non-inferiority)", next_id = "term_noninferiority"),
      list(label = "Show both arms are practically equivalent (equivalence)", next_id = "equiv_outcome"),
      list(label = "Show pharmacokinetic equivalence of formulations (bioequivalence)", next_id = "term_bioequivalence"),
      list(label = "Single-arm, response rate vs. a historical control (Phase II)", next_id = "term_simon"),
      list(label = "Interim analyses planned (group sequential)", next_id = "term_group_sequential")
    )
  ),

  equiv_outcome = list(
    id = "equiv_outcome", stage = 2,
    question = "Is the outcome continuous (a mean) or a proportion?",
    options = list(
      list(label = "Continuous (means)", next_id = "term_tost_means"),
      list(label = "Proportion", next_id = "term_equivalence_prop")
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
      list(label = "The unit of observation is a group/area, not a person (ecological)", next_id = "term_ecological")
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
      list(label = "Count / rate (e.g. episodes per person-time)", next_id = "term_count_rate"),
      list(label = "Time-to-event (e.g. survival, time to recurrence)", next_id = "term_logrank")
    )
  ),

  groups_count = list(
    id = "groups_count", stage = 3,
    question = "How many groups are being compared?",
    options = list(
      list(label = "1 group vs. a known/reference value", next_id = "term_one_group_vs_ref"),
      list(label = "2 groups", next_id = "dependence_q"),
      list(label = "3 or more groups", next_id = "term_k_groups")
    )
  ),

  dependence_q = list(
    id = "dependence_q", stage = 3,
    question = "Are the two groups independent, or the same subjects measured twice (paired)?",
    options = list(
      list(label = "Independent", next_id = "term_two_groups_independent"),
      list(label = "Paired / dependent (before-after, matched pairs)",
           next_id = function(flags) {
             if (identical(flags$outcome, "continuous")) "term_two_groups_paired_cont" else "term_binary_paired_mcnemar"
           })
    )
  ),

  # ================================================================== #
  # Terminal nodes -- built (route via calculator_catalog)
  # ================================================================== #

  term_prop_precision = list(id = "term_prop_precision", terminal = TRUE,
    design = "Single proportion, precision-based", catalog_key = "proportion_single_precision"),

  term_diag_precision = list(id = "term_diag_precision", terminal = TRUE,
    design = "Sensitivity/specificity, precision-based", catalog_key = "diagnostic_precision"),
  term_diag_vs_ref = list(id = "term_diag_vs_ref", terminal = TRUE,
    design = "Sensitivity/specificity vs. known/reference value", catalog_key = "diagnostic_vs_reference"),
  term_diag_two_indep = list(id = "term_diag_two_indep", terminal = TRUE,
    design = "Two independent (unpaired) diagnostic tests", catalog_key = "diagnostic_two_indep"),
  term_diag_two_paired = list(id = "term_diag_two_paired", terminal = TRUE,
    design = "Two paired diagnostic tests (same subjects)", catalog_key = "diagnostic_two_paired"),

  term_kappa = list(id = "term_kappa", terminal = TRUE,
    design = "Cohen's kappa (categorical agreement)", catalog_key = "agreement_kappa"),
  term_icc = list(id = "term_icc", terminal = TRUE,
    design = "Intraclass correlation (ICC)", catalog_key = "agreement_icc"),

  term_tost_means = list(id = "term_tost_means", terminal = TRUE,
    design = "Equivalence of two means (TOST)", catalog_key = "tost_means"),
  term_simon = list(id = "term_simon", terminal = TRUE,
    design = "Simon two-stage Phase II design", catalog_key = "simon_two_stage"),

  term_cohort_rr = list(id = "term_cohort_rr", terminal = TRUE,
    design = "Cohort study (relative risk)", catalog_key = "cohort_rr",
    note = paste(
      "This module assumes a binary outcome (RR). If your cohort's outcome",
      "is actually continuous (e.g. comparing a mean biomarker level",
      "between exposed and unexposed groups followed forward), you want",
      "\"Two independent means\" in the Means module instead.")),

  term_cc_unmatched = list(id = "term_cc_unmatched", terminal = TRUE,
    design = "Unmatched case-control study", catalog_key = "case_control_unmatched"),
  term_cc_freq_matched = list(id = "term_cc_freq_matched", terminal = TRUE,
    design = "Frequency-matched case-control study", catalog_key = "case_control_unmatched",
    note = "Frequency matching is analysed like an unmatched design (stratified), not the individually-matched formula -- use the unmatched calculator."),
  term_cc_matched = list(id = "term_cc_matched", terminal = TRUE,
    design = "Individually matched case-control study", catalog_key = "case_control_matched"),

  term_chisq_independence_direct = list(id = "term_chisq_independence_direct", terminal = TRUE,
    design = "Chi-square test of independence/association", catalog_key = "chisq_independence"),
  term_logrank = list(id = "term_logrank", terminal = TRUE,
    design = "Log-rank test (two survival curves)", catalog_key = "logrank"),

  term_one_group_vs_ref = list(id = "term_one_group_vs_ref", terminal = TRUE,
    design = "One group vs. a known/reference value",
    catalog_key = function(flags) if (identical(flags$outcome, "continuous")) "means_single" else "proportion_single"),

  term_two_groups_independent = list(id = "term_two_groups_independent", terminal = TRUE,
    design = "Two independent groups",
    catalog_key = function(flags) if (identical(flags$outcome, "continuous")) "means_two_indep" else "proportion_two_indep"),

  term_two_groups_paired_cont = list(id = "term_two_groups_paired_cont", terminal = TRUE,
    design = "Two paired means (e.g. pre-post)", catalog_key = "means_two_dep"),

  term_k_groups = list(id = "term_k_groups", terminal = TRUE,
    design = "Three or more groups",
    catalog_key = function(flags) if (identical(flags$outcome, "continuous")) "means_k" else "proportion_k"),

  # ================================================================== #
  # Terminal nodes -- not yet built (honest placeholder, no catalog_key)
  # ================================================================== #

  term_prediction = list(id = "term_prediction", terminal = TRUE,
    design = "Prediction / prognostic model (development or validation)",
    would_use = "pmsampsize (development); pmvalsampsize (external validation)",
    citation = "Riley et al. (2019) Stat Med 38:1276-1296; Riley et al. (2021) BMJ 372:m441"),

  term_ppv_npv = list(id = "term_ppv_npv", terminal = TRUE,
    design = "Predictive values (PPV/NPV)",
    would_use = "derived from a 2x2 table (no dedicated package identified yet)",
    citation = "-"),
  term_auc = list(id = "term_auc", terminal = TRUE,
    design = "Area under the ROC curve (AUC), single or two tests",
    would_use = "pROC::power.roc.test", citation = "Hanley & McNeil (1982) Radiology 143:29-36"),

  term_bland_altman = list(id = "term_bland_altman", terminal = TRUE,
    design = "Limits of agreement (Bland-Altman)",
    would_use = "presize::prec_lim_agree", citation = "Bland & Altman (1986) Lancet 327:307-310"),
  term_ccc = list(id = "term_ccc", terminal = TRUE,
    design = "Concordance correlation coefficient (CCC)",
    would_use = "no lightweight verified package identified yet", citation = "Lin (1989) Biometrics 45:255-268"),
  term_cronbach = list(id = "term_cronbach", terminal = TRUE,
    design = "Scale internal consistency (Cronbach's alpha)",
    would_use = "presize::prec_cronb", citation = "Bonett (2002) Stat Med 21:1331-1335"),

  term_mean_precision = list(id = "term_mean_precision", terminal = TRUE,
    design = "Single mean, precision-based",
    would_use = "presize::prec_mean", citation = "-"),
  term_rate_precision = list(id = "term_rate_precision", terminal = TRUE,
    design = "Incidence rate, precision-based",
    would_use = "presize::prec_rate", citation = "-"),
  term_ratio_precision = list(id = "term_ratio_precision", terminal = TRUE,
    design = "Ratio (RR/OR/rate ratio), precision-based",
    would_use = "presize::prec_riskratio and related presize functions", citation = "-"),

  term_crossover = list(id = "term_crossover", terminal = TRUE,
    design = "Crossover trial (2x2, continuous)",
    would_use = "PowerTOST; nMaster", citation = "-"),
  term_stepped_wedge = list(id = "term_stepped_wedge", terminal = TRUE,
    design = "Stepped-wedge cluster-randomised trial",
    would_use = "swCRTdesign; SWSamp; clusterPower",
    citation = "Hussey & Hughes (2007) Contemp Clin Trials 28:182-191; Hemming & Taljaard (2016) J Clin Epidemiol 69:137-146"),
  term_n_of_1 = list(id = "term_n_of_1", terminal = TRUE,
    design = "N-of-1 trial", would_use = "no lightweight verified package identified yet", citation = "-"),

  term_noninferiority = list(id = "term_noninferiority", terminal = TRUE,
    design = "Non-inferiority trial (means or proportions)",
    would_use = "SampleSize4ClinicalTrials; TrialSize", citation = "-"),
  term_equivalence_prop = list(id = "term_equivalence_prop", terminal = TRUE,
    design = "Equivalence (TOST) for proportions",
    would_use = "TOSTER; PowerTOST (no dedicated proportions-TOST function found in either yet)", citation = "-"),
  term_bioequivalence = list(id = "term_bioequivalence", terminal = TRUE,
    design = "Bioequivalence crossover (2x2 / replicate designs)",
    would_use = "PowerTOST::sampleN.TOST (crossover/replicate designs)",
    citation = "Diletti, Hauschke & Steinijans (1991); Owen's Q exact method"),
  term_group_sequential = list(id = "term_group_sequential", terminal = TRUE,
    design = "Group sequential / adaptive design",
    would_use = "gsDesign; rpact",
    citation = "Jennison & Turnbull; O'Brien-Fleming; Pocock; Lan-DeMets alpha spending"),

  term_nested_cc = list(id = "term_nested_cc", terminal = TRUE,
    design = "Nested case-control study", would_use = "no lightweight verified package identified yet", citation = "-"),
  term_case_cohort = list(id = "term_case_cohort", terminal = TRUE,
    design = "Case-cohort study", would_use = "no lightweight verified package identified yet", citation = "-"),
  term_case_crossover = list(id = "term_case_crossover", terminal = TRUE,
    design = "Case-crossover study", would_use = "no lightweight verified package identified yet", citation = "-"),
  term_sccs = list(id = "term_sccs", terminal = TRUE,
    design = "Self-controlled case series (SCCS)", would_use = "no lightweight verified package identified yet", citation = "-"),

  term_ordinal = list(id = "term_ordinal", terminal = TRUE,
    design = "Ordinal outcome (proportional odds / non-parametric)",
    would_use = "no lightweight verified package identified yet", citation = "-"),
  term_count_rate = list(id = "term_count_rate", terminal = TRUE,
    design = "Count / rate outcome comparison",
    would_use = "epiR::epi.sscompc; WebPower::wp.poisson", citation = "-"),
  term_binary_paired_mcnemar = list(id = "term_binary_paired_mcnemar", terminal = TRUE,
    design = "Two paired/dependent proportions (McNemar)",
    would_use = "no dedicated package wired in yet -- see checklist_by_design.md", citation = "-"),

  # ================================================================== #
  # Guidance terminals -- deliberately no numeric N
  # ================================================================== #

  term_qualitative = list(id = "term_qualitative", terminal = TRUE, guidance = TRUE,
    design = "Qualitative study -- no numeric sample size",
    note = paste(
      "Justify sample size with information power (Malterud, Siersma &",
      "Guassora 2016) and/or saturation evidence (Guest, Bunce & Johnson",
      "2006) instead of a formula. Emitting a numeric N here would be",
      "false precision -- this app deliberately does not compute one.")),

  term_ecological = list(id = "term_ecological", terminal = TRUE, guidance = TRUE,
    design = "Ecological study (unit of observation is a group/area)",
    note = paste(
      "The unit of analysis here is the group (e.g. district, PHC catchment),",
      "not the individual -- none of this app's individual-level calculators",
      "apply directly, and ecological analyses carry their own inference",
      "caveats (the ecological fallacy). No calculator is planned for this",
      "design yet."))
)
