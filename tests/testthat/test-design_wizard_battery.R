# A battery of study descriptions in plain language through the keyword parser (walk_free_text): each must end on the node
# listed. A terminal is a calculator suggestion; a question node means "the text does not settle this, ask the user", which
# is the honest outcome when a description leaves something open. Reviewed by hand when written; the point is that a change to
# the rules or the tree that sends one of these somewhere else is noticed and looked at. A wrong confident terminal (the
# case that matters) was the failure these tests exist to catch: for example a comparison of proportions routed to
# "precision of one proportion", or "intracluster correlation" routed to a correlation calculator.
wizard_battery <- list(
  list("We compared cases and controls for exposure to pesticide", "cc_matching"),
  list("Case-control study of smoking and lung cancer, unmatched, odds ratio", "term_cc_unmatched"),
  list("Individually matched case-control study 1:2 for oral contraceptive use", "term_cc_matched"),
  list("Case-control study comparing mean serum lead level between cases and controls", "cc_cont_matching"),
  list("Cases and controls, difference in mean BMI between the two groups", "cc_cont_matching"),
  list("Cases and controls, continuous exposure such as vitamin D concentration", "cc_cont_matching"),
  list("Cohort study of smokers versus non-smokers, relative risk of heart disease", "term_cohort_rr"),
  list("Prospective cohort comparing exposed and unexposed workers for incidence of asthma", "term_cohort_rr"),
  list("Cohort study, difference in mean blood pressure between exposed and unexposed", "indep_cont"),
  list("Cohort comparing mean haemoglobin between exposed and unexposed children", "indep_cont"),
  list("Retrospective cohort, time to death in exposed versus unexposed", "surv_type"),
  list("Cohort study incidence rate per person-years in exposed and unexposed", "term_count_rate"),
  list("Cross-sectional survey to estimate the prevalence of hypertension", "term_prop_precision"),
  list("Cross-sectional study comparing mean BMI between men and women", "groups_count"),
  list("Cross-sectional study comparing proportion of anaemia between urban and rural", "groups_count"),
  list("Cross-sectional association between smoking and asthma, prevalence ratio", "groups_count"),
  list("Randomized trial comparing two drugs on systolic blood pressure", "dependence_q"),
  list("Randomised controlled trial, proportion cured in treatment versus placebo", "dependence_q"),
  list("Non-inferiority trial of a new antibiotic, cure rate", "noninf_outcome"),
  list("Bioequivalence study of a generic formulation", "be_type"),
  list("Cluster randomised trial of schools, mean test score difference", "groups_count"),
  list("Cluster randomized trial in villages, proportion vaccinated", "exp_intent"),
  list("Crossover trial of two inhalers, FEV1", "term_crossover"),
  list("Stepped wedge trial across hospitals", "term_stepped_wedge"),
  list("Single arm phase II trial response rate", "term_simon"),
  list("Trial with time to recurrence as outcome, hazard ratio", "surv_type"),
  list("Compare the mean difference in weight loss between diet and exercise groups", "allocation"),
  list("Compare two means from independent groups", "allocation"),
  list("t-test for difference in means between two independent groups", "allocation"),
  list("paired t-test before and after intervention", "allocation"),
  list("Compare three groups with ANOVA", "allocation"),
  list("difference in proportion between two groups chi-square", "allocation"),
  list("Estimate the prevalence of diabetes in a district", "term_prop_precision"),
  list("Estimate the mean haemoglobin of pregnant women", "term_mean_precision"),
  list("Estimate incidence rate of dengue per 1000 person-years", "term_rate_precision"),
  list("Determine the proportion of children fully immunised", "term_prop_precision"),
  list("Estimate the sensitivity and specificity of a rapid test against a gold standard", "term_diag_precision"),
  list("Agreement between two raters, kappa", "term_kappa"),
  list("Inter-observer reliability of a scale, ICC", "term_icc"),
  list("Correlation between height and weight", "corr_type"),
  list("Linear regression to study predictors of birth weight", "reg_type"),
  list("Logistic regression with 5 predictors, events per variable", "logit_type"),
  list("Develop a prognostic model to predict mortality", "pred_type"),
  list("Qualitative study with in-depth interviews", "term_qualitative"),
  list("Systematic review and meta-analysis", "meta_type"),
  list("Survival analysis comparing two treatments, log-rank", "allocation"),
  list("Cox regression with a binary covariate", "cox_type"),
  list("sample size for diagnostic accuracy study with prevalence 10%", "diag_type"),
  list("Lot quality assurance sampling in health facilities", "survey_type"),
  list("A pilot study to assess feasibility", "term_pilot"),
  list("Hospital A and B compare the readmission rate", "allocation"),
  list("association between exposure and outcome, odds ratio from a 2x2 table I already have", "analyze_design"),
  list("case control study with continuous outcome", "cc_cont_matching"),
  list("I want to compare average age between two cohorts", "indep_cont"),
  list("Matched case-control study (1:1) comparing mean cholesterol between cases and controls", "term_two_groups_paired_cont"),
  list("Unmatched case-control study, difference in mean serum zinc between cases and controls", "indep_cont"),
  list("Frequency-matched case-control study of diet and colon cancer, odds ratio", "term_cc_freq_matched"),
  list("Nested case-control study within a cohort", "term_nested_cc"),
  list("Case-cohort design with a random sub-cohort", "term_case_cohort"),
  list("Case-crossover study of air pollution and asthma attacks", "term_case_crossover"),
  list("Self-controlled case series of vaccine safety", "term_sccs"),
  list("Ecological study of regions comparing mortality", "term_ecological"),
  list("Prospective cohort of nurses, relative risk of breast cancer in exposed vs unexposed", "term_cohort_rr"),
  list("Cohort study of exposed and unexposed children, mean difference in IQ score", "indep_cont"),
  list("Cohort study comparing mean birth weight of babies of smoking and non-smoking mothers", "indep_cont"),
  list("Retrospective cohort, hazard ratio for death by exposure status", "surv_type"),
  list("Cohort of workers, incidence rate ratio per 1000 person-years", "term_count_rate"),
  list("Cross-sectional study comparing mean haemoglobin by sex", "groups_count"),
  list("Cross-sectional survey to compare the prevalence of obesity between two districts", "groups_count"),
  list("Test of difference in mean systolic BP between two groups of patients", "allocation"),
  list("Is there a difference in average cholesterol between vegetarians and non-vegetarians?", "allocation"),
  list("difference in mean HbA1c between treatment arms in a randomised trial", "groups_count"),
  list("randomized trial of two drugs, proportion with remission", "exp_intent"),
  list("Non-inferiority margin for hazard ratio in a cancer trial", "noninf_outcome"),
  list("Equivalence trial of two blood pressure drugs", "equiv_outcome"),
  list("Group sequential trial with interim analyses", "gs_type"),
  list("Phase I dose finding 3+3", "term_dose_finding"),
  list("Bayesian adaptive trial", "bayes_type"),
  list("Cluster randomised trial, intracluster correlation 0.05, villages", "exp_intent"),
  list("Multiple primary endpoints adjusted for multiplicity", "exp_unit"),
  list("Sample size for linear regression with 8 predictors", "reg_type"),
  list("Spearman correlation between two ranks", "term_corr_spearman"),
  list("Pearson correlation expected r = 0.3", "term_corr_pearson"),
  list("Poisson regression for count outcome", "term_poisson_reg"),
  list("Reliability of a questionnaire using Cronbach alpha", "term_cronbach"),
  list("Bland-Altman limits of agreement between two devices", "term_bland_altman"),
  list("Concordance correlation coefficient between two assays", "term_ccc"),
  list("Area under the ROC curve comparison of two biomarkers", "auc_type"),
  list("Predictive value of a screening test", "term_ppv_npv"),
  list("sample size for estimating the sensitivity of a new test with 95% confidence interval", "term_diag_precision"),
  list("Randomization list for a trial with permuted blocks", "term_plan_randomization_block"),
  list("Survey weights for a household survey", "term_survey_weights_classes"),
  list("WHO EPI 30 x 7 cluster survey of immunisation coverage", "term_survey_select_epi"),
  list("SIR epidemic model with vaccination herd immunity threshold", "term_epi_model_sim"),
  list("outbreak investigation food specific attack rates", "term_analyze_outbreak_exposure"),
  list("I have summary counts and want a risk ratio with confidence interval", "analyze_design"),
  list("Calculate a Mantel-Haenszel odds ratio across strata", "analyze_mh_design"),
  list("genome wide association study", "other_purpose"),
  list("Effect of a diet on cholesterol in mice", "animal_type"),
  list("Number of studies needed for a meta-analysis", "term_meta_power"),
  list("network meta-analysis of antidepressants", "term_nma")
)

test_that("plain-language study descriptions reach the expected terminal or question", {
  got <- vapply(wizard_battery, function(x) walk_free_text(x[[1]])$node_id, "")
  want <- vapply(wizard_battery, `[[`, "", 2)
  bad <- which(got != want)
  expect_equal(unname(got[bad]), unname(want[bad]),
               info = paste(vapply(wizard_battery[bad], `[[`, "", 1), collapse = "\n"))
})

test_that("descriptions that do not settle the design stop at a question rather than guessing a calculator", {
  vague <- c("We want to know whether the exposure is associated with the outcome",
             "A study in a hospital", "sample size please", "The new programme was evaluated in some villages",
             "Time series of daily counts, interrupted time series")
  for (txt in vague) {
    r <- walk_free_text(txt)
    expect_false(isTRUE(design_nodes[[r$node_id]]$terminal), info = txt)
  }
})

test_that("a comparison of two groups is never sent to the precision calculator of a single proportion or mean", {
  comparisons <- c("Cross-sectional study comparing proportion of anaemia between urban and rural",
                   "Compare the proportion cured in two groups", "Comparing mean BMI between men and women in a survey",
                   "Cohort comparing mean haemoglobin between exposed and unexposed children",
                   "Case-control study comparing mean serum lead level between cases and controls")
  for (txt in comparisons) {
    r <- walk_free_text(txt)
    key <- design_nodes[[r$node_id]]$catalog_key
    expect_false(is.character(key) && key %in% c("proportion_single_precision", "means_single_precision"), info = txt)
  }
})
