# Metadata for the Stepped-Wedge CRT module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_stepped_wedge.R (SDD 4.2: "content is data, not
# hardcoded UI").

stepped_wedge_content <- list(
  normal = list(
    title = "Stepped-Wedge Cluster-Randomized Trial (Continuous Outcome)",
    formula_latex = paste0(
      "$$DEFF_c = 1 + (m-1)\\rho, \\qquad ",
      "r = \\frac{m\\,\\rho\\,\\rho_c + (1-\\rho)\\rho_s}{DEFF_c}$$",
      "$$DEFF_t = \\frac{3T(1-r)(1+Tr)}{(T^2-1)(2+Tr)}, ",
      "\\qquad VIF = DEFF_c \\times DEFF_t$$",
      "$$z = \\frac{|d|}{\\sqrt{\\dfrac{4\\sigma^2_{total}}{k\\,m\\,T} \\times VIF}}$$"
    ),
    explanation = paste(
      "A **stepped-wedge cluster-randomized trial (SW-CRT)** rolls out the",
      "intervention to all clusters over time, in a randomized order --",
      "every cluster starts in the control condition and eventually",
      "crosses over to the intervention, rather than half the clusters",
      "staying on control throughout (as in a parallel-arm cluster trial).",
      "This calculator covers the continuous-outcome, complete (no missing",
      "data), equal-step-size case.",
      "",
      "- **m (nsubjects)** - the number of individuals observed per",
      "  cluster at each time point.",
      "- **T (ntimes)** - the number of post-baseline time points/steps.",
      "- **d** - the expected (absolute) treatment effect on the outcome.",
      "- **rho (ICC)** - the intracluster correlation.",
      "- **rho_c (cluster autocorrelation)** - the correlation between two",
      "  cluster-level means from the SAME cluster at different times.",
      "  This is what lets the design effect properly decay (or not) as",
      "  clusters are followed for longer -- a plain constant-ICC parallel-",
      "  trial DEFF implicitly assumes rho_c = 1 (perfectly persistent",
      "  cluster effects), which understates the true variance whenever",
      "  cluster effects actually drift over time.",
      "- **rho_s (individual autocorrelation)** - the correlation between",
      "  two measurements on the SAME individual at different times; 0 for",
      "  a cross-sectional design (new individuals sampled at each time",
      "  point), greater than 0 for a closed-cohort design (the same",
      "  individuals followed throughout).",
      "- **Total variance** - the total outcome variance (between- plus",
      "  within-cluster).",
      "",
      "This is Hooper, Teerenstra, de Hoop & Woertman (2016)'s closed-form",
      "design effect for stepped-wedge trials -- more general than, and a",
      "documented improvement on, the widely-used but sometimes-diverging",
      "simplified restatements (e.g. Woertman et al. 2013) of the original",
      "Hussey & Hughes (2007) variance, since it explicitly allows the",
      "within-cluster correlation to decay across time lags via rho_c",
      "rather than assuming one constant correlation regardless of how far",
      "apart in time two measurements are.",
      sep = "\n"
    ),
    worked_example = paste(
      "m = 10 subjects/cluster/time point, T = 4 post-baseline time",
      "points, d = 0.25, ICC = 0.05, cluster autocorrelation rho_c = 0.5,",
      "individual autocorrelation rho_s = 0 (cross-sectional), total",
      "variance = 1, two-sided alpha = 0.05, target power = 0.80 -> this",
      "calculator finds 8 clusters switching per time point (32 clusters",
      "total, since total = nclusters x T = 8 x 4), achieving 82.1% power",
      "-- exactly matching a real",
      "`clusterPower::cpa.sw.normal()` call solving for the same unknown",
      "on the same inputs (7.5736 raw clusters before rounding up, bit-for-",
      "bit identical to this app's own raw solution). Three further",
      "scenarios (varying m, T, d, ICC, rho_c, rho_s, alpha, and power all",
      "at once) were checked the same way, all matching exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Hooper R, Teerenstra S, de Hoop E, Eldridge S. Sample size",
      "calculation for stepped wedge and other longitudinal cluster",
      "randomised trials. Stat Med. 2016;35(26):4718-4728.",
      "",
      "Baio G, Copas A, Ambler G, Hargreaves J, Beard E, Omar RZ. Sample",
      "size calculation for a stepped wedge trial. Trials. 2015;16:354.",
      "",
      "Hussey MA, Hughes JP. Design and analysis of stepped wedge cluster",
      "randomized trials. Contemp Clin Trials. 2007;28(2):182-191.",
      "",
      "Kristunas C, Morris T, Gray L. Sample size calculations for stepped",
      "wedge trials using design effects are only approximate in some",
      "circumstances. Trials. 2021;22:325 (the methodological caveat this",
      "app's checklist itself flagged before this batch, motivating the",
      "choice of Hooper et al.'s more general formula over the simpler",
      "Woertman et al. 2013 restatement).",
      "",
      "Formula extracted from, and verified bit-for-bit against, real",
      "`clusterPower::cpa.sw.normal()` calls (Moyer J, Kleinman K.",
      "clusterPower: Power Calculations for Cluster-Randomized and",
      "Cluster-Randomized Crossover Trials. R package,",
      "https://github.com/cran/clusterPower) -- installed in this sandbox",
      "via the github.com/cran mirror (`cran.r-project.org` itself is",
      "network-blocked here), used only as a verification oracle. Per this",
      "project's vendoring policy, the shipped calculator has no new",
      "runtime dependency. The binary outcome has its own section."
    ),
    backend = "closed-form reimplementation (Hooper, Teerenstra, de Hoop & Woertman 2016)"
  )
  ,
  binary = list(
    title = "Stepped-Wedge Cluster-Randomised Trial (Binary Outcome)",
    formula_latex = paste0(
      "$$V_i = \\operatorname{diag}\\!\\left(\\frac{1}{n\\,\\mu_{it}(1-\\mu_{it})}\\right) + \\tau^2 J, \\qquad ",
      "\\operatorname{logit}\\,\\mu_{it} = \\beta_0 + \\gamma_t + \\theta\\,x_{it}$$",
      "$$\\operatorname{Var}(\\hat\\theta) = \\Big[\\big(\\textstyle\\sum_i X_i^{\\top} V_i^{-1} X_i\\big)^{-1}\\Big]_{\\theta\\theta}, \\qquad ",
      "\\text{power} = \\Phi\\!\\left(\\frac{\\theta - z\\,s_0}{s_1}\\right) + 1 - \\Phi\\!\\left(\\frac{\\theta + z\\,s_0}{s_1}\\right)$$"
    ),
    explanation = paste(
      "For a **yes / no outcome** the effect is a **log odds ratio**, and the amount of information a cluster gives depends on the",
      "outcome risk in each period, so the variance has no simple design-effect form. The calculator builds each cluster's working",
      "covariance (the binomial variance of its period means on the log odds scale, plus the cluster effect with SD tau), adds up",
      "the information over the clusters, and reads the variance of the treatment effect from it -- once under no effect (s0) and",
      "once under the effect you give (s1).",
      "",
      "- **Risks on control and on the intervention** give the log odds ratio and the baseline.",
      "- **People per cluster in each period** and **number of steps**: one cluster group crosses at each step, so there are steps + 1",
      "  periods, and the first is control for everyone. Different people are measured in each period (cross-sectional).",
      "- **tau** is the SD of the cluster effect on the log odds scale. A conversion from the intracluster correlation is not built",
      "  in (I have no source for one); enter tau and try a few values.",
      "- **Change in log odds in each later period**: the same shift for every period after the first (0 means no time trend).",
      "- The result is the **clusters per step** (the smallest whole number reaching the power), and the total.",
      "",
      "Limits: equal clusters per step, equal people per cluster and period, a cluster effect that is constant over time, no",
      "closed cohort, no cluster-by-treatment effect. This is a large-sample approximation; with few clusters (say under 10 in all)",
      "the true power is usually lower, so check with a simulation (the Monte Carlo cluster trial calculator).",
      sep = "\n"
    ),
    worked_example = paste(
      "Risk 0.20 on control and 0.14 on the intervention (odds ratio 0.65), 50 people per cluster in each period, 3 steps",
      "(4 periods), tau = 0.2, no time trend, alpha = 0.05, power 0.80 -> **6 clusters per step (18 in all)**, power 0.846; with 5",
      "per step the power is 0.780. The power matches `swCRTdesign::swGlmPwr()` to 10 digits (tests).",
      sep = "\n"
    ),
    citation = paste(
      "Xia F, Hughes JP, Voldal EC, Heagerty PJ. Power and sample size calculation for stepped-wedge designs with discrete",
      "outcomes. Trials. 2021;22:598. doi:10.1186/s13063-021-05542-9 (PMC8419932). The method uses the covariance of the estimates",
      "from the Laplace approximation of Breslow NE, Clayton DG, J Am Stat Assoc 1993;88:9-25 (not read).",
      "",
      "I read the paper's description of the method; its equations did not come through in the text available to me, so the",
      "calculation is checked against the authors' own function, swCRTdesign::swGlmPwr() (R package swCRTdesign 4.2, used only to",
      "check, not at run time)."
    ),
    backend = "base R; power equals swCRTdesign::swGlmPwr() (Xia et al. 2021)"
  )

)
