# Metadata for the Analyze: Paired, Agreement and Trend Tests module (ROADMAP
# Track B1): formula text, plain-language explanation, worked example and citation
# per design. Content is data, rendered generically by mod_analyze_tests.R.

analyze_tests_content <- list(
  mcnemar = list(
    title = "McNemar's test and matched-pair estimates (paired binary data)",
    formula_latex = paste0(
      "$$\\chi^2_{McN}=\\frac{(b-c)^2}{b+c}\\ \\ (1\\ \\mathrm{df});\\qquad \\chi^2_{\\text{corrected}}=\\frac{(|b-c|-1)^2}{b+c}$$",
      "$$\\widehat{OR}_{\\text{matched}}=\\frac bc,\\qquad \\text{exact CI: }\\ \\frac{p}{1-p}\\ \\text{for } p\\in\\text{Clopper-Pearson}\\!\\left(\\tfrac{b}{b+c}\\right)$$",
      "$$\\hat p_1-\\hat p_2=\\frac{b-c}{N},\\qquad \\operatorname{SE}=\\frac{\\sqrt{(b+c)-(b-c)^2/N}}{N}$$"
    ),
    explanation = paste(
      "Use this when the **same subjects** are classified twice (two tests on the same people, before and after,",
      "matched pairs). Enter the 2x2 table of paired results:",
      "",
      "|  | Test 2 + | Test 2 - |",
      "|---|---|---|",
      "| **Test 1 +** | a | b |",
      "| **Test 1 -** | c | d |",
      "",
      "Only the **discordant pairs** b and c carry information about a difference between the two. The app",
      "gives McNemar's chi-square (with and without the continuity correction), the **exact test** (binomial on b",
      "out of b + c; use it when b + c is small, below about 25) and its mid-P version, the **matched-pair odds",
      "ratio** b/c with an exact and a Wald interval, and the **difference between the two positive proportions**",
      "with a Wald interval. The Wald interval for the difference is approximate and can be poor for small samples.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustration (hypothetical counts): 100 patients tested twice; both positive 30, test 1 only 12, test 2 only",
      "5, both negative 53. McNemar chi-square = 2.88 (p = 0.090), with continuity correction 2.12 (p = 0.146),",
      "exact p = 0.143; matched odds ratio 2.40; positive in 42% on test 1 and 35% on test 2. These figures equal",
      "`stats::mcnemar.test()` and `binom.test()`.",
      sep = "\n"
    ),
    citation = paste(
      "McNemar Q. Note on the sampling error of the difference between correlated proportions or percentages.",
      "Psychometrika 1947;12:153-157; Fleiss JL, Levin B, Paik MC. Statistical Methods for Rates and Proportions.",
      "3rd ed. Wiley; 2003 (matched-pair analysis, standard error of the paired difference); Clopper CJ, Pearson ES.",
      "Biometrika 1934;26:404-413 (exact interval). Checked against stats::mcnemar.test() and binom.test()."
    ),
    backend = "closed forms; verified against stats::mcnemar.test(), binom.test() and a simulation of the paired difference"
  ),
  kappa = list(
    title = "Cohen's kappa: agreement between two raters or tests",
    formula_latex = paste0(
      "$$\\hat\\kappa=\\frac{p_o-p_e}{1-p_e},\\qquad p_o=\\sum_{ij}w_{ij}p_{ij},\\quad p_e=\\sum_{ij}w_{ij}\\,p_{i\\cdot}p_{\\cdot j}$$",
      "$$\\operatorname{Var}(\\hat\\kappa)=\\frac{1}{N(1-p_e)^2}\\left\\{\\sum_{ij}p_{ij}\\left[w_{ij}-(\\bar w_{i\\cdot}+\\bar w_{\\cdot j})(1-\\hat\\kappa)\\right]^2-\\left[\\hat\\kappa-p_e(1-\\hat\\kappa)\\right]^2\\right\\}$$",
      "with $w_{ij}=1$ if $i=j$ else $0$ (unweighted), $1-|i-j|/(k-1)$ (linear) or $1-(|i-j|/(k-1))^2$ (quadratic); ",
      "$\\bar w_{i\\cdot}=\\sum_j w_{ij}p_{\\cdot j}$, $\\bar w_{\\cdot j}=\\sum_i w_{ij}p_{i\\cdot}$. ",
      "$$PABAK=\\frac{k\\,p_o-1}{k-1}$$"
    ),
    explanation = paste(
      "Enter the table of two raters' (or two tests') classifications of the same subjects: rows are rater 1,",
      "columns rater 2, 2 to 6 categories. **Kappa** is the agreement beyond chance: 0 means no better than chance,",
      "1 is perfect agreement. The confidence interval uses the large-sample standard error of Fleiss, Cohen and",
      "Everitt (1969), which does not assume kappa is 0; the test of kappa = 0 uses the standard error under that",
      "hypothesis.",
      "",
      "For **ordered categories** with more than two levels, a **weighted** kappa gives partial credit to near-misses",
      "(linear or quadratic weights). The verbal labels (slight, fair, moderate, substantial, almost perfect) are",
      "Landis and Koch's (1977) convention, not a statistical test.",
      "",
      "Kappa depends on how common the categories are: with a very rare or very common category it can be low",
      "even when raw agreement is high. **PABAK** (prevalence- and bias-adjusted kappa, for unweighted tables) is",
      "shown beside it; report observed agreement too.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustration (hypothetical counts): two raters classify 100 subjects as positive or negative; both positive 40,",
      "rater 1 only 10, rater 2 only 5, both negative 45. Observed agreement 85%, chance agreement 50%, kappa 0.70",
      "(95% CI 0.56 to 0.84), PABAK 0.70. For a 3-category table [[20, 5, 2], [4, 25, 6], [1, 5, 32]] unweighted kappa",
      "is 0.65 (0.53 to 0.78), linearly weighted 0.70 (0.58 to 0.81) and quadratically weighted 0.75 (0.63 to 0.87).",
      "These equal `DescTools::CohenKappa()`; the 2x2 kappa and PABAK also equal `epiR::epi.kappa()`.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. A coefficient of agreement for nominal scales. Educ Psychol Meas 1960;20:37-46; Cohen J. Weighted",
      "kappa. Psychol Bull 1968;70:213-220; Fleiss JL, Cohen J, Everitt BS. Large sample standard errors of kappa",
      "and weighted kappa. Psychol Bull 1969;72:323-327; Landis JR, Koch GG. The measurement of observer agreement",
      "for categorical data. Biometrics 1977;33:159-174; Byrt T, Bishop J, Carlin JB. Bias, prevalence and kappa.",
      "J Clin Epidemiol 1993;46:423-429 (PABAK). Checked against DescTools::CohenKappa() and epiR::epi.kappa()."
    ),
    backend = "closed forms (Fleiss-Cohen-Everitt variance); verified against DescTools::CohenKappa(), epiR::epi.kappa() and the explicit 1969 expression"
  ),
  trend = list(
    title = "Chi-square test for trend (Cochran-Armitage) in proportions",
    formula_latex = paste0(
      "$$\\chi^2_{trend}=\\frac{\\left\\{\\sum_i x_i\\,(r_i-n_i\\bar p)\\right\\}^2}{\\bar p(1-\\bar p)\\left[\\sum_i n_ix_i^2-\\left(\\sum_i n_ix_i\\right)^2/N\\right]}\\quad(1\\ \\mathrm{df}),\\qquad \\bar p=\\frac{\\sum r_i}{N}$$"
    ),
    explanation = paste(
      "Use this when subjects fall into **ordered groups** (dose levels, age bands, severity grades) and you want",
      "to know whether the **proportion with the outcome rises or falls steadily** across them. Enter, for each",
      "group, the number of events and the number of subjects, and optionally a numeric **score** (for example the",
      "dose). The default scores 1, 2, 3, ... treat the groups as equally spaced.",
      "",
      "The test has 1 degree of freedom and looks only for a **linear trend** on the proportion scale; a",
      "significant result does not show the relationship is linear, and a non-significant one does not rule out",
      "a non-linear pattern (such as a U shape). Reversing the group order or rescaling the scores does not change",
      "the statistic. The per-group proportions are shown with Wilson intervals.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustration (hypothetical counts): four dose groups of 100 subjects each with 10, 20, 35 and 50 events",
      "(proportions 10%, 20%, 35%, 50%). Chi-square for trend = 44.49 (1 df), p < 0.0001, increasing. The statistic",
      "equals `stats::prop.trend.test()`.",
      sep = "\n"
    ),
    citation = paste(
      "Cochran WG. Some methods for strengthening the common chi-square tests. Biometrics 1954;10:417-451;",
      "Armitage P. Tests for linear trends in proportions and frequencies. Biometrics 1955;11:375-386.",
      "Checked against stats::prop.trend.test()."
    ),
    backend = "closed form; verified against stats::prop.trend.test()"
  )
)
