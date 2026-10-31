# Metadata for the Analyze: Aberration Detection module (ROADMAP Track B4, item 20): formula text, plain-language
# explanation, worked example and citation per design. Content is data, rendered generically by
# mod_analyze_surveillance.R.

.surv_citation <- paste(
  "Hutwagner L, Thompson W, Seeman GM, Treadwell T. The bioterrorism preparedness and response Early Aberration Reporting System",
  "(EARS). J Urban Health 2003;80(Suppl 1):i89-i96 (EARS C1, C2, C3; existence, journal, volume and pages confirmed by web search);",
  "Fricker RD Jr, Hegler BL, Dunfee DA. Comparing syndromic surveillance detection methods: EARS' versus a CUSUM-based methodology.",
  "Stat Med 2008;27:3407-3429 (the formulas as written out, and the finding that a properly set CUSUM outperformed C1-C3; confirmed);",
  "Page ES. Continuous inspection schemes. Biometrika 1954;41:100-115 (CUSUM; confirmed); Lucas JM. Counted data CUSUMs.",
  "Technometrics 1985;27:129-144 (Poisson CUSUM; confirmed); Hawkins DM, Olwell DH. Cumulative Sum Charts and Charting for Quality",
  "Improvement. Springer; 1998 (run lengths; the book exists, its pages were not read here). The EARS statistics equal",
  "surveillance::earsC() for C1 and C2 (its C3 alarm rule differs from the definition above and is not copied), and CUSUM run lengths",
  "agree with spc::xcusum.arl() by simulation; both packages are oracles in the tests only. None of the original papers could be read here."
)

analyze_surveillance_content <- list(
  ears = list(
    title = "EARS aberration detection (C1, C2, C3)",
    formula_latex = paste0(
      "$$C1_t=\\frac{x_t-\\bar x_{t-7..t-1}}{s_{t-7..t-1}},\\qquad C2_t=\\frac{x_t-\\bar x_{t-9..t-3}}{s_{t-9..t-3}},\\qquad ",
      "C3_t=\\sum_{j=0}^{2}\\max\\big(0,\\ C2_{t-j}-1\\big)$$",
      "$$\\text{signal if } C1_t>3,\\ C2_t>3,\\ \\text{or } C3_t>2$$"
    ),
    explanation = paste(
      "Paste a series of **counts in time order** (daily or weekly cases). For each day the method compares the count with the mean and standard",
      "deviation of a short **baseline** just before it (7 days by default). **C1** uses the 7 days before; **C2** leaves a **2-day gap** so an",
      "outbreak that has already begun does not raise its own baseline; **C3** adds up the recent C2 excesses over 1 SD, so it catches a",
      "slower rise that no single day makes obvious.",
      "",
      "A day **signals** when its statistic exceeds the threshold (3 for C1 and C2, 2 for C3, which you can change). The baseline",
      "standard deviation is the sample SD; if the baseline counts do not vary at all the statistic is undefined and shown as missing",
      "(set a minimum SD to avoid this). The first 7 days (9 for C2, 11 for C3) are the baseline and cannot be assessed.",
      "",
      "**Caution:** EARS has no memory of a seasonal pattern or day-of-week effect, and a threshold of 3 on a 7-day baseline gives about 1.5 false signals per hundred days for roughly normal counts (a t distribution with 6 degrees of freedom); the",
      "tool shows a signal to be looked at, not a finding. For small counts the CUSUM (Poisson) is the better choice.",
      sep = "\n"
    ),
    worked_example = "The default series is 30 days of about 5 cases a day followed by 8 days of about 12 (simulated). C1 signals on day 31, the first day of the rise, and then its own baseline absorbs the rise; C2 signals on days 31, 32, 33 and 35 because of its 2-day gap; C3 on days 31 to 37. A constant series signals nowhere.",
    citation = .surv_citation,
    backend = "closed form (EARS definitions); C1 and C2 equal surveillance::earsC(), tested; C3 checked by direct recomputation"
  ),
  cusum = list(
    title = "CUSUM for a rise in counts (normal and Poisson forms)",
    formula_latex = paste0(
      "$$\\text{normal: } C_t=\\max\\Big(0,\\ C_{t-1}+\\frac{x_t-\\mu_0}{\\sigma_0}-k\\Big),\\qquad ",
      "\\text{Poisson: } C_t=\\max\\big(0,\\ C_{t-1}+x_t-k_p\\big),\\quad k_p=\\frac{\\lambda_1-\\lambda_0}{\\ln(\\lambda_1/\\lambda_0)}$$",
      "$$\\text{signal if } C_t>h$$"
    ),
    explanation = paste(
      "Paste a series of counts. The first observations (the **baseline period**, 14 by default) set the usual level $\\mu_0$ (and, for the normal form, the standard",
      "deviation $\\sigma_0$); they are not monitored. After that the CUSUM **accumulates** how far each count is above the usual level, less an allowance:",
      "a single high day does little, a run of mildly high days builds up and crosses the threshold $h$. The statistic never goes below 0.",
      "",
      "- **Normal form**: counts are standardized; the allowance $k$ = 0.5 targets a rise of about one SD; $h$ = 4 is a common threshold. With these values,",
      "  the average number of days to a false signal is about **336** when nothing changes (one-sided), and about 8.4 days to detect a rise of one SD.",
      "- **Poisson form** (better for small counts): the allowance is $k_p$ for a rise of the mean by the factor you give (default 2); the threshold $h$ is in cases.",
      "",
      "After a signal the statistic is restarted at 0 (you can turn that off). A higher $h$ gives fewer false signals but slower detection.",
      "The baseline period must be a stretch with no outbreak in it: an outbreak in the baseline hides itself.",
      sep = "\n"
    ),
    worked_example = "The same series with a baseline of the first 14 days: the normal CUSUM signals first on day 32 (and again on 34, 35, 38 after restarts); the Poisson form with k_p = 6.18 (a doubling of the baseline mean 4.4) signals first on day 31.",
    citation = .surv_citation,
    backend = "closed form recursion; run lengths agree with spc::xcusum.arl() by simulation (tests), no runtime dependency"
  )
)
