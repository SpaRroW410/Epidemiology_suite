# Metadata for the Effect Size module (formula text, plain-language explanation, worked example, citation per converter).
# Content is data, rendered generically by mod_effect_size.R. The worked-example numbers were produced by the calc_es_*() functions
# (tests/testthat/test-calc_effect_size.R recomputes them). Sources are cited as read only where they were; see calc_effect_size.R.

.es_cohen_citation <- "Cohen J. Statistical Power Analysis for the Behavioral Sciences. 2nd ed. Hillsdale, NJ: Lawrence Erlbaum; 1988 (the book was not read in this session; the formulas are those of the pwr package, with which they are compared in the tests)."

effect_size_content <- list(
  two_means = list(
    title = "Two means: Cohen's d and Hedges' g",
    formula_latex = paste0(
      "$$d = \\frac{\\bar x_1 - \\bar x_2}{s_p},\\qquad s_p = \\sqrt{\\frac{(n_1-1)s_1^2 + (n_2-1)s_2^2}{n_1+n_2-2}}",
      "\\;\\; \\left(\\sqrt{\\tfrac{s_1^2+s_2^2}{2}} \\text{ if the sizes are unknown}\\right)$$",
      "$$g = J\\,d,\\quad SE(d) \\approx \\sqrt{\\frac{n_1+n_2}{n_1 n_2} + \\frac{d^2}{2(n_1+n_2)}}$$"),
    explanation = paste(
      "The difference between two group means in units of their common standard deviation: the effect size that the two-group",
      "means calculators (and the t-test power calculation) are built around. Enter the two means, or just their difference, and the",
      "standard deviation or the **variance** of each group (a variance is the SD squared; give either).",
      "",
      "- With the **group sizes** the pooled SD is weighted by degrees of freedom, and you also get **Hedges' g** (d with a small-sample",
      "  correction) and an approximate interval for d. Without them, equal group sizes are assumed.",
      "- If you know only one SD, leave the other blank: it is taken to be common to both groups.",
      "- When the two SDs differ a lot, a pooled SD describes neither group well; the means calculators also have a design for unequal",
      "  variances (Welch).",
      "",
      "Cohen's conventions (0.2 small, 0.5 medium, 0.8 large) are shown with the result; he offered them as a last resort, not as thresholds.",
      sep = "\n"),
    worked_example = paste(
      "An OpenEpi-style example: means 132.86 and 127.44 with SDs 15.34 and 18.23, 50 per group. The difference is 5.42, the pooled SD",
      "16.85, so d = 0.322 (a small effect), Hedges' g = 0.319, and the approximate 95% interval for d is -0.07 to 0.72. Giving the",
      "variances 235.32 and 332.33 instead of the SDs gives the same d. With these inputs, d = 0.32 is what you would enter in a",
      "calculator that asks for Cohen's d.", sep = "\n"),
    citation = paste(.es_cohen_citation,
                     "Hedges LV. Distribution theory for Glass's estimator of effect size and related estimators. J Educ Stat 1981;6:107-128",
                     "(the correction J for g; not read, confirmed to exist; g is checked here by simulation and equals the Compare-two-groups tool's g).",
                     "The interval is the usual large-sample one (Hedges & Olkin 1985, not read; checked against the simulated spread of d)."),
    backend = "closed forms in calc_effect_size.R; d and g equal the Analyze tool 'Compare two groups' and pwr's definition; checked by simulation"
  ),
  from_t = list(
    title = "Cohen's d from a t statistic",
    formula_latex = paste0("$$d = t\\sqrt{\\frac{1}{n_1}+\\frac{1}{n_2}}\\;\\text{(two groups)},\\qquad d_z = \\frac{t}{\\sqrt{n}}\\;\\text{(paired or one sample)}$$"),
    explanation = paste(
      "A published t statistic and the group sizes are enough to recover the standardized difference, when the paper reports no means",
      "and SDs. For two independent groups enter both sizes; for a paired or one-sample test enter the number of pairs (or subjects) as",
      "group 1 and leave group 2 blank. The sign of t is kept.",
      "",
      "These follow from the definition of the t statistic and are checked against `t.test()`.", sep = "\n"),
    worked_example = "t = 2.4 with 30 per group: d = 2.4 x sqrt(1/30 + 1/30) = 0.620 (Hedges' g 0.612, 58 degrees of freedom). A paired t of 3.1 from 25 pairs gives d_z = 3.1 / 5 = 0.62.",
    citation = paste("A mathematical identity (the t statistic of the pooled-variance t-test is d x sqrt(n1 n2 / (n1 + n2)));", .es_cohen_citation),
    backend = "closed forms; verified against stats::t.test() on simulated data"
  ),
  paired_means = list(
    title = "Paired measurements: d for the differences (d_z)",
    formula_latex = paste0("$$d_z = \\frac{\\bar d}{s_d},\\qquad s_d^2 = s_1^2 + s_2^2 - 2 r\\, s_1 s_2$$"),
    explanation = paste(
      "For before-after or matched measurements the effect size the paired t-test power calculation uses is the mean of the",
      "differences divided by the SD **of the differences**. If a paper gives the SD of the differences, enter it. If it gives only the two",
      "SDs, enter them with the correlation between the two measurements and the SD of the differences is calculated; if it gives both",
      "SDs and the SD of the differences, the correlation they imply is shown.",
      "",
      "The stronger the correlation, the smaller the SD of the differences and the larger d_z: the same mean change is easier to detect",
      "when each person's two values are alike.", sep = "\n"),
    worked_example = "Mean change 4, SDs 12 and 14, correlation 0.6: the SD of the differences is sqrt(144 + 196 - 2 x 0.6 x 12 x 14) = 11.76, so d_z = 4 / 11.76 = 0.340. With an SD of the differences of 10.3 and the same SDs, the implied correlation is 0.70.",
    citation = paste("The variance of a difference (a standard identity); d_z as in", .es_cohen_citation),
    backend = "closed form; the SD of the differences is checked on simulated correlated data"
  ),
  anova_f = list(
    title = "Several means: Cohen's f",
    formula_latex = paste0("$$f = \\frac{\\sigma_m}{\\sigma},\\quad f^2 = \\frac{\\eta^2}{1-\\eta^2} = \\frac{F\\,df_1}{df_2},\\quad f = \\frac{|d|}{2}\\;(k=2)$$"),
    explanation = paste(
      "The effect size for ANOVA, Kruskal-Wallis and repeated-measures sample-size calculations. Give the **group means** and the common",
      "SD within groups (group sizes optional: with unequal sizes the SD of the means is weighted by size); or **eta-squared**; or an",
      "**F statistic** with its degrees of freedom; or, for two groups, Cohen's d. All four routes give the same f for the same data.",
      "",
      "f squared = eta-squared / (1 - eta-squared). Cohen's conventions are 0.10 small, 0.25 medium, 0.40 large.", sep = "\n"),
    worked_example = "Group means 10, 12 and 15 with a common SD of 6: the SD of the means is 2.05, so f = 2.05 / 6 = 0.342 (a medium-to-large effect), f squared 0.117, eta-squared 0.105. Eta-squared of 0.06 gives f = 0.253.",
    citation = .es_cohen_citation,
    backend = "closed forms; f from an F statistic equals sqrt(SS_between / SS_within) from aov(); f from means equals the value the Means calculator uses"
  ),
  proportions = list(
    title = "Two proportions: odds ratio, risk ratio, risk difference, Cohen's h",
    formula_latex = paste0("$$OR = \\frac{p_1/(1-p_1)}{p_0/(1-p_0)},\\; RR = \\frac{p_1}{p_0},\\; RD = p_1 - p_0,\\; NNT = \\frac{1}{|RD|},\\; h = 2\\arcsin\\sqrt{p_1} - 2\\arcsin\\sqrt{p_0}$$"),
    explanation = paste(
      "Fill in the proportion in the reference group (p0: the unexposed, the controls, the control arm) and **one** of: the proportion in",
      "the other group (p1), the odds ratio, the risk (or prevalence) ratio, or the risk difference. The others are calculated, as in",
      "OpenEpi's forms for cohort, trial and case-control sample sizes. Cohen's h and the number needed to treat are added.",
      "",
      "**In a case-control study** read p0 as the proportion of *controls* exposed and p1 as the proportion of *cases* exposed; the odds",
      "ratio is then the odds ratio of exposure.", sep = "\n"),
    worked_example = "p0 = 5% and an odds ratio of 2: p1 = 9.52%, risk ratio 1.90, risk difference 4.52 percentage points, NNT 22, Cohen's h 0.176. (The same figures OpenEpi's cohort form shows for these inputs.)",
    citation = paste("Definitions of the effect measures; h as in", .es_cohen_citation),
    backend = "closed forms; h equals pwr::ES.h(); the others by their definitions and round trips"
  ),
  chisq_w = list(
    title = "Chi-square: Cohen's w and Cramer's V",
    formula_latex = paste0("$$w = \\sqrt{\\frac{\\chi^2}{N}} = \\sqrt{\\sum \\frac{(p_{1i}-p_{0i})^2}{p_{0i}}}$$"),
    explanation = paste(
      "The effect size for chi-square tests. Give a table of counts (rows and columns), or a chi-square statistic with N, or the cell",
      "proportions expected under the null (p0) and under your alternative (p1). For a 2 x 2 table w equals the phi coefficient;",
      "Cramer's V is shown for a table. Conventions: 0.1 small, 0.3 medium, 0.5 large.",
      "",
      "The chi-square used is the uncorrected Pearson statistic.", sep = "\n"),
    worked_example = "The table 30, 15 / 20, 35 (N = 100) has chi-square 9.09 with 1 degree of freedom, so w = 0.302 (a medium effect), equal to phi and to Cramer's V. Proportions 0.25 each under the null versus 0.40, 0.20, 0.20, 0.20 give w = 0.346.",
    citation = .es_cohen_citation,
    backend = "closed form; equals sqrt(chisq.test(correct = FALSE)$statistic / N) and pwr::ES.w1()"
  ),
  hazard_ratio = list(
    title = "Hazard ratio from median survival or survival probabilities",
    formula_latex = paste0("$$HR = \\frac{m_C}{m_E}\\;(\\text{exponential}),\\qquad HR = \\frac{\\ln S_E}{\\ln S_C} = \\frac{\\ln(1-p_E)}{\\ln(1-p_C)}$$"),
    explanation = paste(
      "The log-rank and Cox calculators ask for a hazard ratio. Often only median survival times are known. If survival is exponential",
      "(a constant hazard), the hazard is log(2) / median, so the hazard ratio of the experimental to the control arm is the *control* median",
      "divided by the *experimental* median: a longer median in the experimental arm gives HR below 1.",
      "",
      "From the survival (or event) probabilities at the same time, under proportional hazards, HR = ln S_E / ln S_C. Both routes assume",
      "the hazards are proportional (and the first, constant); if they are not, treat the result as a rough guide.", sep = "\n"),
    worked_example = "Medians of 18 months (experimental) and 12 months (control): HR = 12 / 18 = 0.667. Event probabilities of 0.3707 and 0.489 over the same follow-up: HR = ln(0.6293) / ln(0.511) = 0.690 (the log-rank calculator's own example).",
    citation = "Derived from the exponential model (hazard = log(2) / median) and the proportional-hazards relation S_E(t) = S_C(t)^HR; checked by simulation of exponential survival times. No published source is cited for this derivation.",
    backend = "closed forms; verified by simulating exponential survival times"
  ),
  correlation = list(
    title = "Convert between d, r, an odds ratio, R-squared and f-squared",
    formula_latex = paste0("$$r = \\frac{t}{\\sqrt{t^2+df}},\\; d \\approx \\frac{2r}{\\sqrt{1-r^2}},\\qquad \\ln OR \\approx \\frac{\\pi}{\\sqrt 3}\\,d,\\qquad f^2 = \\frac{R^2}{1-R^2}$$"),
    explanation = paste(
      "Give **one** of d, r, an odds ratio, R-squared or f-squared and the others are shown, so an effect size from one kind of study can",
      "be used in another kind of calculator.",
      "",
      "- **d and r** (two groups): the relation is exact for the point-biserial correlation (r = t / sqrt(t squared + df)); enter the group",
      "  sizes to use it, or leave them blank for the large-sample form for equal groups, d = 2r / sqrt(1 - r squared).",
      "- **d and the odds ratio:** ln(OR) = d x pi / sqrt(3) (Chinn 2000, who rounds the divisor to 1.81). This is an **approximation**: it holds exactly",
      "  if the outcome is a dichotomised logistic variable and approximately for a normal one.",
      "- **R-squared and f-squared:** f squared = R squared / (1 - R squared).", sep = "\n"),
    worked_example = "d = 0.5 corresponds to r = 0.243 (large-sample form), an odds ratio of about 2.48 (approximate), R-squared 0.059 and f-squared 0.0625. R-squared of 0.13 gives f-squared 0.149.",
    citation = paste("Chinn S. A simple method for converting an odds ratio to effect size for use in meta-analysis. Stat Med 2000;19:3127-31 (PMID 11113947;",
                     "only the abstract was read: 'a ln(odds ratio) can be converted to effect size by dividing by 1.81'); the d-r relation is exact and checked against cor();", .es_cohen_citation),
    backend = "closed forms; d <-> r checked against cor() and t.test(); the odds-ratio conversion is an approximation"
  ),
  median_iqr = list(
    title = "Mean and SD from a median and interquartile range",
    formula_latex = paste0("$$\\bar x \\approx \\frac{q_1 + m + q_3}{3},\\qquad s \\approx \\frac{q_3 - q_1}{2\\,\\Phi^{-1}\\!\\left(\\frac{0.75n - 0.125}{n + 0.25}\\right)}$$"),
    explanation = paste(
      "When a pilot study or paper reports a median and quartiles, estimate a mean and SD to use in the means calculators, then compute",
      "d on the first design above. For a large sample the SD is the IQR divided by 1.35. Both estimates assume roughly normal data;",
      "for a clearly skewed outcome a rank-based test (Wilcoxon / Mann-Whitney) is the alternative.", sep = "\n"),
    worked_example = "Median 45, quartiles 38 and 54, n = 60: mean 45.67, SD 12.15 (the SD is the IQR 16 divided by 1.317).",
    citation = "Wan X, Wang W, Liu J, Tong T. Estimating the sample mean and standard deviation from the sample size, median, range and/or interquartile range. BMC Med Res Methodol 2014;14:135, scenario C3 (read through PubMed Central, doi 10.1186/1471-2288-14-135).",
    backend = "closed form; checked by simulation (bias of the SD under 1% for normal data)"
  ),
  matched_pairs = list(
    title = "Matched case-control: phi from a table of matched pairs",
    formula_latex = paste0("$$\\phi = \\frac{ad - bc}{\\sqrt{(a+b)(c+d)(a+c)(b+d)}}$$"),
    explanation = paste(
      "The matched case-control calculator needs **phi**, the correlation between the exposure of a case and the exposure of its matched",
      "control. From a pilot or published table of matched pairs, count the pairs in which **both** were exposed (a), **only the case** (b),",
      "**only the control** (c) and **neither** (d). The same table gives the proportion of cases exposed, the proportion of controls exposed,",
      "the odds ratio between them and the matched-pairs (McNemar) odds ratio b / c. If no table is available, Dupont (1988) suggests 0.2.",
      sep = "\n"),
    worked_example = "30 pairs both exposed, 25 only the case, 10 only the control, 35 neither (100 pairs): phi = 0.328; 55% of cases and 40% of controls exposed (odds ratio 1.83); matched-pairs odds ratio 25 / 10 = 2.5.",
    citation = "Dupont WD. Power calculations for matched case-control studies. Biometrics 1988;44:1157-68 (the formula this app's matched case-control calculator uses); phi as the correlation of two yes/no variables.",
    backend = "closed form; equals cor() of the expanded pairs and recovers phi when pairs are simulated from Dupont's model"
  )
)
