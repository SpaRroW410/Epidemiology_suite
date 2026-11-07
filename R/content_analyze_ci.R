# Metadata for the Analyze: Confidence Intervals module (ROADMAP Track B1):
# formula text, plain-language explanation, worked example and citation per
# design. Content is data, rendered generically by mod_analyze_ci.R.

analyze_ci_content <- list(
  proportion = list(
    title = "Confidence interval for a proportion",
    formula_latex = paste0(
      "$$\\text{Wilson: }\\ \\frac{\\hat p+\\frac{z^2}{2n}\\pm z\\sqrt{\\frac{\\hat p(1-\\hat p)}{n}+\\frac{z^2}{4n^2}}}{1+\\frac{z^2}{n}}$$",
      "$$\\text{Clopper-Pearson: }\\ \\left[B\\!\\left(\\tfrac{\\alpha}{2};x,n-x+1\\right),\\ B\\!\\left(1-\\tfrac{\\alpha}{2};x+1,n-x\\right)\\right]$$",
      "$$\\text{Agresti-Coull: }\\ \\tilde p\\pm z\\sqrt{\\frac{\\tilde p(1-\\tilde p)}{\\tilde n}},\\quad \\tilde n=n+z^2,\\ \\tilde p=\\frac{x+z^2/2}{\\tilde n}$$",
      "$$\\text{Jeffreys: }\\ \\left[B\\!\\left(\\tfrac{\\alpha}{2};x+\\tfrac12,n-x+\\tfrac12\\right),\\ B\\!\\left(1-\\tfrac{\\alpha}{2};x+\\tfrac12,n-x+\\tfrac12\\right)\\right]$$",
      "$$\\text{Wald: }\\ \\hat p\\pm z\\sqrt{\\hat p(1-\\hat p)/n}$$",
      "$B(q;a,b)$ is the $q$-quantile of the Beta$(a,b)$ distribution. The mid-P exact interval solves ",
      "$P_p(X>x)+\\tfrac12P_p(X=x)=\\alpha/2$ for the lower limit and $P_p(X<x)+\\tfrac12P_p(X=x)=\\alpha/2$ for the upper."
    ),
    explanation = paste(
      "Enter the number of **successes** (events, positives) $x$ and the **sample size** $n$. All six",
      "intervals are shown so you can see how much the choice matters.",
      "",
      "- **Wilson score** and **Agresti-Coull** are good default choices for most sample sizes.",
      "- **Clopper-Pearson (exact)** guarantees at least the nominal coverage, at the price of being",
      "  conservative (wide). Use it when a guarantee is required or when $x$ is 0 or $n$.",
      "- **Mid-P exact** is the exact interval made less conservative; it is narrower than Clopper-Pearson.",
      "- **Jeffreys** is the equal-tailed Bayesian interval under a Beta(1/2, 1/2) prior.",
      "- **Wald** is the textbook formula $\\hat p\\pm z\\,SE$. It is shown for comparison only: it can have",
      "  far less than nominal coverage and collapses to a zero-width interval at $x=0$ or $x=n$.",
      "",
      "Limits are cut to the range 0 to 1.",
      sep = "\n"
    ),
    worked_example = paste(
      "7 successes in 20 trials ($\\hat p=0.35$), 95% confidence: Wilson 0.181 to 0.567,",
      "Clopper-Pearson 0.154 to 0.592, Agresti-Coull 0.180 to 0.568, Jeffreys 0.172 to 0.568,",
      "mid-P 0.168 to 0.573, Wald 0.141 to 0.559. The first four equal `epiR::epi.conf()`.",
      sep = "\n"
    ),
    citation = paste(
      "Wilson EB. J Am Stat Assoc 1927;22:209-212; Clopper CJ, Pearson ES. Biometrika 1934;26:404-413;",
      "Agresti A, Coull BA. Am Stat 1998;52:119-126; Brown LD, Cai TT, DasGupta A. Interval estimation for a",
      "binomial proportion. Stat Sci 2001;16:101-133 (Wald, Wilson, Agresti-Coull, Jeffreys, end-point",
      "conventions); Lancaster HO. J Am Stat Assoc 1961;56:223-234 and Berry G, Armitage P. Mid-P confidence",
      "intervals: a brief review. The Statistician 1995;44:417-423 (mid-P)."
    ),
    backend = "closed forms and beta/binomial quantiles; verified against epiR::epi.conf() and binom.test()"
  ),
  mean = list(
    title = "Confidence interval for a mean and a standard deviation",
    formula_latex = paste0(
      "$$\\bar x\\pm t_{n-1,\\,1-\\alpha/2}\\,\\frac{s}{\\sqrt n}$$",
      "$$\\sqrt{\\frac{(n-1)s^2}{\\chi^2_{1-\\alpha/2,\\,n-1}}}\\ \\le\\ \\sigma\\ \\le\\ \\sqrt{\\frac{(n-1)s^2}{\\chi^2_{\\alpha/2,\\,n-1}}}$$"
    ),
    explanation = paste(
      "Enter the **sample size** $n$, the **mean** and the **standard deviation** $s$ from your summary",
      "statistics. The interval for the mean uses Student's $t$ distribution with $n-1$ degrees of freedom",
      "(the usual choice; it is exact for normally distributed data and a good approximation for a large",
      "sample). The normal-quantile version is shown too: it is appropriate only when the standard deviation",
      "is known or $n$ is large, and is narrower than the $t$ interval.",
      "",
      "The interval for the **standard deviation** uses the chi-square distribution and is exact for",
      "normally distributed data; it is not robust to non-normality, unlike the interval for the mean.",
      sep = "\n"
    ),
    worked_example = paste(
      "n = 30, mean = 10, SD = 2, 95% confidence: the mean is 10 (95% CI 9.25 to 10.75) with $t_{29}=2.045$;",
      "the standard deviation is 2 (95% CI 1.59 to 2.69). The mean interval equals `t.test()` on data",
      "constructed to have exactly that mean and SD.",
      sep = "\n"
    ),
    citation = paste(
      "Student (Gosset WS). The probable error of a mean. Biometrika 1908;6:1-25; the chi-square interval",
      "for the variance of a normal sample is standard (see e.g. Rosner B. Fundamentals of Biostatistics,",
      "one-sample inference for the variance); here it is checked by coverage simulation."
    ),
    backend = "closed forms (t, chi-square quantiles); verified against t.test() and by coverage simulation"
  )
)
