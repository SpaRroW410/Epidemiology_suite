# Metadata for the Analyze: Compare Two Groups module (ROADMAP Track B1): formula text,
# plain-language explanation, worked example and citation per design. Content is data,
# rendered generically by mod_analyze_compare.R.

analyze_compare_content <- list(
  proportions = list(
    title = "Comparing two proportions: difference, ratio and odds ratio, by several methods",
    formula_latex = paste0(
      "$$\\hat\\delta=\\hat p_1-\\hat p_2,\\qquad \\text{Wald: }\\ \\hat\\delta\\pm z\\sqrt{\\tfrac{\\hat p_1\\hat q_1}{n_1}+\\tfrac{\\hat p_2\\hat q_2}{n_2}}$$",
      "$$\\text{Newcombe: }\\ \\left[\\hat\\delta-\\sqrt{(\\hat p_1-l_1)^2+(u_2-\\hat p_2)^2},\\ \\hat\\delta+\\sqrt{(u_1-\\hat p_1)^2+(\\hat p_2-l_2)^2}\\right]\\ \\ (l_i,u_i\\text{ = Wilson limits})$$",
      "$$\\text{Miettinen-Nurminen: }\\ \\{\\delta:\\ \\tfrac{(\\hat\\delta-\\delta)^2}{\\tilde v(\\delta)\\,N/(N-1)}\\le z^2\\},\\quad \\tilde v=\\tfrac{\\tilde p_1\\tilde q_1}{n_1}+\\tfrac{\\tilde p_2\\tilde q_2}{n_2}$$",
      "$$\\text{Katz: }\\ \\widehat{RR}\\,\\exp\\{\\pm z\\sqrt{\\tfrac1{x_1}-\\tfrac1{n_1}+\\tfrac1{x_2}-\\tfrac1{n_2}}\\},\\qquad \\text{Woolf: }\\ \\widehat{OR}\\,\\exp\\{\\pm z\\sqrt{\\textstyle\\sum 1/\\text{cell}}\\}$$"
    ),
    explanation = paste(
      "Enter events and sample size for **group 1** and **group 2** (two independent groups). The app reports the",
      "**risk difference**, the **risk ratio** and the **odds ratio** and, for each, confidence intervals by several",
      "methods **side by side**, because for small samples or proportions near 0 or 1 they can differ a lot. Which one to",
      "report is your decision; the notes say what each is known for.",
      "",
      "- **Difference.** The textbook **Wald** interval is known to undercover and is not recommended. The **Miettinen-Nurminen**",
      "  and **Newcombe hybrid score** intervals are among those recommended in the comparative literature (Newcombe 1998;",
      "  Fagerland et al. 2011). **Mee** is a close relative of Miettinen-Nurminen. **Agresti-Caffo** is a simple adjusted Wald",
      "  that performs well. Continuity-corrected versions are conservative (wider).",
      "- **Ratio.** The **Koopman score** interval is the recommended one; the **Katz log** interval is the textbook one and",
      "  is poor for small samples; the **adjusted log** (+1/2) interval stays defined when a count is zero.",
      "- **Odds ratio.** **Woolf** is the usual log interval; the **conditional exact** interval (Fisher) never undercovers",
      "  but is conservative, and its estimate is the conditional maximum-likelihood odds ratio, not the sample odds ratio.",
      "",
      "Intervals for the difference are cut to [-1, 1]. With a zero count the ratio and odds-ratio intervals that need a",
      "logarithm are undefined (n/a); nothing is added to the counts except where the method itself says so.",
      sep = "\n"
    ),
    worked_example = paste(
      "56 of 70 in group 1 and 48 of 80 in group 2 (the first example of the `DescTools::BinomDiffCI()` help page, after",
      "Newcombe 1998): proportions 0.800 and 0.600, difference 0.200. 95% intervals: Miettinen-Nurminen 0.053 to 0.338,",
      "Newcombe 0.052 to 0.334, Agresti-Caffo 0.052 to 0.336, Wald 0.058 to 0.343. Risk ratio 1.33: Koopman 1.08 to 1.67, Katz",
      "1.08 to 1.65. All equal `DescTools`.",
      sep = "\n"
    ),
    citation = paste(
      "Newcombe RG. Interval estimation for the difference between independent proportions: comparison of eleven methods.",
      "Stat Med 1998;17:873-890; Newcombe RG. Two-sided confidence intervals for the single proportion: comparison of seven",
      "methods. Stat Med 1998;17:857-872 (continuity-corrected Wilson limits); Miettinen O, Nurminen M. Comparative analysis",
      "of two rates. Stat Med 1985;4:213-226; Mee RW. Confidence bounds for the difference between two probabilities.",
      "Biometrics 1984;40:1175-1176; Farrington CP, Manning G. Test statistics and sample size formulae for comparative binomial",
      "trials with null hypothesis of non-zero risk difference or non-unity relative risk. Stat Med 1990;9:1447-1454;",
      "Agresti A, Caffo B. Simple and effective confidence intervals for proportions and differences of proportions result from",
      "adding two successes and two failures. Am Stat 2000;54:280-288; Koopman PAR. Confidence intervals for the ratio of two",
      "binomial proportions. Biometrics 1984;40:513-517; Katz D, et al. Biometrics 1978;34:469-474; Woolf B. Ann Hum Genet",
      "1955;19:251-253; Fagerland MW, Lydersen S, Laake P. Recommended confidence intervals for two independent binomial",
      "proportions. Stat Methods Med Res 2015;24:224-254 (online 2011). Checked against DescTools::BinomDiffCI(),",
      "DescTools::BinomRatioCI() and stats::fisher.test(). The existence and volume/pages of Newcombe 1998, Koopman 1984 and",
      "Fagerland et al. were confirmed by web search; the original papers could not be read, so formulas were verified",
      "numerically against those packages and by coverage simulation."
    ),
    backend = "closed forms and score-equation root finding; verified against DescTools::BinomDiffCI(), DescTools::BinomRatioCI(), fisher.test() and by coverage simulation"
  ),
  means = list(
    title = "Comparing two means from summary statistics: difference, variance ratio and standardized difference",
    formula_latex = paste0(
      "$$\\bar x_1-\\bar x_2\\pm t_{\\nu}\\sqrt{\\tfrac{s_1^2}{n_1}+\\tfrac{s_2^2}{n_2}},\\quad \\nu=\\frac{(s_1^2/n_1+s_2^2/n_2)^2}{\\frac{(s_1^2/n_1)^2}{n_1-1}+\\frac{(s_2^2/n_2)^2}{n_2-1}}\\ \\ \\text{(Welch)}$$",
      "$$\\bar x_1-\\bar x_2\\pm t_{n_1+n_2-2}\\,s_p\\sqrt{\\tfrac1{n_1}+\\tfrac1{n_2}},\\quad s_p^2=\\tfrac{(n_1-1)s_1^2+(n_2-1)s_2^2}{n_1+n_2-2}\\ \\ \\text{(Student, pooled)}$$",
      "$$\\frac{s_1^2}{s_2^2}\\Big/F_{1-\\alpha/2;\\,n_1-1,\\,n_2-1}\\ \\ \\text{to}\\ \\ \\frac{s_1^2}{s_2^2}\\Big/F_{\\alpha/2;\\,n_1-1,\\,n_2-1}$$",
      "$$d=\\frac{\\bar x_1-\\bar x_2}{s_p},\\qquad g=J\\,d,\\quad J=\\frac{\\Gamma(\\nu/2)}{\\sqrt{\\nu/2}\\,\\Gamma((\\nu-1)/2)},\\quad \\nu=n_1+n_2-2$$"
    ),
    explanation = paste(
      "Enter the sample size, mean and standard deviation of each group. The app gives the **difference in means** with",
      "both the **Welch** interval (does not assume equal variances; the safer default) and the **Student pooled-variance**",
      "interval (assumes equal variances), with their t-tests, so you can see whether the choice matters. It also gives the",
      "**ratio of the two variances** with an F-based interval and test (sensitive to non-normality), and the **standardized",
      "difference**: Cohen's d (difference in pooled-SD units) and Hedges' g (d with a small-sample bias correction), each",
      "with a confidence interval from the **noncentral t distribution**.",
      "",
      "All of this treats each group as an independent sample from a roughly normal distribution (or large enough for the",
      "t approximation). For paired data use the paired difference and its SD with the one-sample interval in the",
      "Confidence Intervals module.",
      sep = "\n"
    ),
    worked_example = paste(
      "Group 1: n = 25, mean 52, SD 9; group 2: n = 31, mean 47, SD 12. Difference 5.0: Welch 95% CI -0.6 to 10.6 (df about 53.8), pooled",
      "-0.8 to 10.8 (df 54); Cohen's d = 0.47, Hedges' g = 0.46. These equal `t.test()` and `var.test()` on data constructed to have",
      "exactly those summary statistics (see the unit tests).",
      sep = "\n"
    ),
    citation = paste(
      "Welch BL. The generalization of 'Student's' problem when several different population variances are involved.",
      "Biometrika 1947;34:28-35; Satterthwaite FE. An approximate distribution of estimates of variance components. Biometrics",
      "Bulletin 1946;2:110-114; Student (Gosset WS). Biometrika 1908;6:1-25; Hedges LV. Distribution theory for Glass's estimator",
      "of effect size and related estimators. J Educ Stat 1981;6:107-128 (Hedges' g and its bias correction); Cumming G, Finch S.",
      "A primer on the understanding, use, and calculation of confidence intervals that are based on central and noncentral",
      "distributions. Educ Psychol Meas 2001;61:532-574 (noncentral-t interval for d). Hedges 1981 and Cumming & Finch 2001 were",
      "confirmed to exist by web search; Welch, Satterthwaite and Student are textbook results (t.test() is the oracle).",
      "The noncentral-t limits are checked by their defining equations and a coverage simulation."
    ),
    backend = "closed forms (t, F, noncentral t); verified against t.test(), var.test() and by coverage simulation"
  )
)
