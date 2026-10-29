# Metadata for the "Eyes / Lesions per Patient" module (several measurements per patient): formula text, plain-language
# explanation, worked example and citation, rendered generically by mod_patient_units.R. Content is data, not hard-coded UI.

.pu_citation_common <- paste(
  "Murdoch IE, Morris SS, Cousens SN. People and eyes: statistical approaches in ophthalmology. Br J Ophthalmol. 1998;82(8):971-973",
  "(the case for using patients, not eyes, as the unit when the eyes are correlated, and for the fellow eye as control).",
  "Rosner B, Milton RC. Significance testing for correlated binary outcome data. Biometrics. 1988;44(2):505-512",
  "(ordinary tests on eyes as if independent give too many false positives; the correlation between eyes enters the test)."
)

patient_units_content <- list(
  between_continuous = list(
    title = "Several units per patient, same treatment in all of a patient's units -- comparing two means",
    formula_latex = paste0(
      "$$VIF = 1 + \\big((CV^2+1)\\,m - 1\\big)\\rho \\qquad r = \\frac{m}{VIF}$$",
      "$$\\text{power} = P\\Big(T'_{\\,2(k-1)}\\big(\\sqrt{k\\,r}\\;\\tfrac{|\\delta|}{\\sqrt{2\\sigma^2}}\\big) > t_{1-\\alpha/2,\\,2(k-1)}\\Big)$$",
      "$$k \\to \\text{smallest number of patients per arm reaching the power};\\quad k_{\\min} = k\\big|_{\\,r = 1/((CV^2+1)\\rho)}$$"
    ),
    explanation = paste(
      "Use this when each patient contributes several measurements that are *correlated* (both eyes, several lesions or patches, several",
      "teeth) and **all of a patient's units receive the same treatment** -- for example both eyes get drops A, the next patient's both",
      "eyes get drops B. The patient is the cluster and its units are the cluster members, so the patient, not the eye, is what is",
      "randomised. Counting every eye as an independent person overstates the information and gives too few patients.",
      "",
      "- **delta** - the difference between the two group means you want to detect (in the units of the measurement).",
      "- **sd** - the standard deviation of a single unit's measurement, all patients and units together.",
      "- **rho** - the correlation between two units of the same patient (the between-eye correlation). It is the proportion of the",
      "  variance that lies between patients. Typical values must come from your own pilot data or earlier studies in the same",
      "  measurement; there is no universal default. 0 means the units are as good as independent people.",
      "- **m** - the number of units per patient (2 for both eyes). If it varies (some patients have only one eye), enter the",
      "  average and the coefficient of variation CV of the number of units per patient (SD / mean); 0 if every patient has the same.",
      "- **k** - the answer: patients **per arm**. The total is twice that; the number of units is that times m.",
      "",
      "**The floor.** However many units each patient contributes, the information per patient never exceeds that of",
      "1 / ((CV^2 + 1) rho) independent units. So there is a minimum number of patients (shown as the floor) that no number of extra",
      "eyes, patches or lesions per patient can get below. Adding units helps a lot at first and then very little: the curve below",
      "the result shows it. If you have a fixed number of patients, switch the calculator to *Units per patient needed*.",
      "",
      "Method: the sample size of the same comparison with independent units, inflated by the design effect of a cluster trial",
      "(Donner & Klar 2000; Eldridge, Ashby & Kerry 2006 for unequal cluster sizes), with power from the noncentral t distribution on",
      "2(k - 1) degrees of freedom (the analysis of patient-level means, or an analysis that weights each patient by its units). The",
      "opposite tail of a two-sided test is ignored (negligible).",
      "",
      "Not covered: different numbers of units in the two arms, unequal allocation, and the analysis itself (use a model that",
      "allows for the correlation: a patient-level summary, a mixed model, or GEE).",
      sep = "\n"
    ),
    worked_example = paste(
      "Detect a difference of delta = 0.5 SD (sd = 1) between two eye drops with both eyes of a patient on the same drop (m = 2) and a",
      "between-eye correlation of rho = 0.5, at 5% significance and 80% power. VIF = 1 + (2 - 1)(0.5) = 1.5, so r = 2 / 1.5 = 1.33",
      "independent eyes per patient. The calculator gives **49 patients per arm** (exactly 48.07), 98 patients and 196 eyes in total.",
      "Treating the 196 eyes as 196 independent people would suggest 64 eyes per arm = 32 patients per arm, a third too few. The floor",
      "(infinitely many units per patient) is 33 patients per arm.",
      "",
      "Checked against `clusterPower::cpa.normal(nsubjects = 2, d = 0.5, ICC = 0.5, sigma_sq = 0.5, method = \"weighted\")`, which",
      "returns 48.07277 clusters per arm; the calculator's unrounded value agrees to the oracle's own tolerance (further cases with",
      "unequal cluster sizes in `tests/testthat/test-calc_patient_units.R`). Confirmed also by simulation: with 45 patients per arm,",
      "m = 2 and rho = 0.4 a patient-mean t-test rejected in 80.1% of 4000 simulated trials.",
      sep = "\n"
    ),
    citation = paste(
      "Donner A, Klar N. Design and Analysis of Cluster Randomization Trials in Health Research. London: Arnold; 2000 (not read; the",
      "design effect 1 + (m - 1) rho is standard and is checked numerically here).",
      "Eldridge SM, Ashby D, Kerry S. Sample size for cluster randomized trials: effect of coefficient of variation of cluster size and",
      "analysis method. Int J Epidemiol. 2006;35(5):1292-1300 (existence and topic confirmed in PubMed; the formula is checked",
      "numerically, the paper itself was not read).",
      .pu_citation_common
    ),
    backend = "closed form (design effect with noncentral t), verified against clusterPower::cpa.normal(method = 'weighted'); no package needed"
  ),

  between_binary = list(
    title = "Several units per patient, same treatment in all of a patient's units -- comparing two proportions",
    formula_latex = paste0(
      "$$VIF = 1 + \\big((CV^2+1)\\,m - 1\\big)\\rho \\qquad r = \\frac{m}{VIF}$$",
      "$$\\text{power} = P\\Big(T'_{\\,2(k-1)}\\big(\\sqrt{k\\,r}\\;\\tfrac{|p_1-p_2|}{\\sqrt{p_1(1-p_1)+p_2(1-p_2)}}\\big) > t_{1-\\alpha/2,\\,2(k-1)}\\Big)$$"
    ),
    explanation = paste(
      "The same as the continuous design, for a yes/no outcome per unit (an eye with or without the event, a patch healed or not).",
      "All of a patient's units get the same treatment.",
      "",
      "- **p1, p2** - the expected proportions of *units* with the outcome in the two groups.",
      "- **rho** - the correlation between the outcomes of two units of the same patient (as in Rosner & Milton 1988, the correlation",
      "  between eyes), **m**, **CV** and **k** as in the continuous design.",
      "",
      "The unpooled variance p1(1-p1) + p2(1-p2) is used, as in `clusterPower::cpa.binary()`. The same floor applies: patients per arm",
      "cannot go below the value reached with 1 / ((CV^2 + 1) rho) effective units per patient.",
      "",
      "Not covered: a binary outcome where each patient receives both treatments (a clustered McNemar-type comparison; its",
      "variance involves a correlation I have no checked source for).",
      sep = "\n"
    ),
    worked_example = paste(
      "Proportions of eyes with the outcome of p1 = 0.40 and p2 = 0.25, both eyes of a patient on the same treatment (m = 2), correlation",
      "between eyes rho = 0.3, 5% significance, 80% power: VIF = 1.3, r = 1.54. The calculator gives **98 patients per arm** (exactly",
      "97.90), 196 patients and 392 eyes. Treating eyes as independent would give 76 patients per arm. The floor is 46 patients per arm.",
      "",
      "Checked against `clusterPower::cpa.binary(nsubjects = 2, p1 = 0.4, p2 = 0.25, ICC = 0.3)`, which gives 97.90334 clusters per arm",
      "(identical to five decimals), and against two further cases with unequal cluster sizes in the test file.",
      sep = "\n"
    ),
    citation = paste(
      "Donner A, Klar N. Design and Analysis of Cluster Randomization Trials in Health Research. London: Arnold; 2000 (not read).",
      "Eldridge SM, Ashby D, Kerry S. Int J Epidemiol. 2006;35(5):1292-1300 (topic confirmed in PubMed; paper not read).",
      .pu_citation_common
    ),
    backend = "closed form (design effect with noncentral t), verified against clusterPower::cpa.binary(); no package needed"
  ),

  within_continuous = list(
    title = "Both treatments in every patient (split-face, split-body, one eye per arm) -- comparing two means",
    formula_latex = paste0(
      "$$\\operatorname{Var}(\\bar y_{T}-\\bar y_{C}) = \\frac{2\\sigma^2(1-\\rho)}{m}$$",
      "$$\\text{paired } t \\text{ on } N \\text{ patients:}\\quad d = \\frac{|\\delta|}{\\sigma\\sqrt{2(1-\\rho)/m}}$$"
    ),
    explanation = paste(
      "Use this when **each patient receives both treatments** -- one eye on each drug, the left and right half of the face, adjacent",
      "patches -- with m units per treatment in every patient. A patient's two arm means are subtracted and the differences are",
      "compared with a paired t-test, so the patient's own level cancels out: the higher the correlation between a patient's units,",
      "the fewer patients are needed, the opposite of the between-patient design.",
      "",
      "- **delta** - the difference between treatments to detect. **sd** - the standard deviation of one unit's measurement.",
      "- **rho** - the correlation between any two units of the same patient (assumed the same for units on the same and on",
      "  different treatments: compound symmetry).",
      "- **m** - units per treatment in each patient (1 for one eye per arm).",
      "",
      "**Derivation.** Every unit has variance sigma^2 and any two units of a patient have covariance rho sigma^2. The mean of a",
      "patient's m treated units has variance sigma^2 (1 + (m - 1) rho) / m, the same for the controls, and the two means have",
      "covariance rho sigma^2. So the variance of their difference is 2 sigma^2 (1 + (m - 1) rho) / m - 2 rho sigma^2 = 2 sigma^2 (1 - rho) / m.",
      "The number of patients is then the paired t-test sample size for the standardised difference above. This short derivation is",
      "mine, not taken from a paper; it is checked against the paired-t power function of `pwr` and by simulation (below).",
      "",
      "Limits: if the treatment effect itself varies from patient to patient (a patient-by-treatment interaction), the variance",
      "of the difference has an extra part that does not shrink with m, and more units per patient help less than this model says. This",
      "calculator does not include that part. Binary outcomes with both treatments in each patient are not covered.",
      sep = "\n"
    ),
    worked_example = paste(
      "delta = 0.5, sd = 1, rho = 0.6, m = 2 units per treatment per patient, 5% significance, 80% power: the standard deviation of a",
      "patient's difference is 1 x sqrt(2 x 0.4 / 2) = 0.632, the standardised difference is 0.5 / 0.632 = 0.79, and the paired t-test needs",
      "**15 patients** (exactly 14.59), 60 units in total. With one unit per treatment (m = 1) it needs 28 patients; giving the same two",
      "treatments to separate patients at this correlation would need 104.",
      "",
      "Checked against `pwr::pwr.t.test(d = 0.5 / 0.632, type = \"paired\", power = 0.8)` (identical n) and by simulation: with 15 patients a",
      "paired t-test rejected in 81.7% of 4000 simulated trials, against 70.5% with 12 patients.",
      sep = "\n"
    ),
    citation = paste(
      "The paired t-test power function is Cohen's (Cohen J. Statistical Power Analysis for the Behavioral Sciences, 2nd ed. Lawrence",
      "Erlbaum; 1988). The variance of the difference of arm means is a derivation (see the explanation), not a published formula.",
      .pu_citation_common
    ),
    backend = "closed form: paired t-test on the patient-level difference (internal reimplementation of pwr's paired t), verified against pwr and by simulation"
  )
)
