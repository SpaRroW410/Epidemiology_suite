# Bug reports for upstream packages (drafts for the owner to file)

Two packages that this app used to depend on, and still uses as checks in its tests, have bugs that were found while replacing them
(ROADMAP item 16, dependency reduction). The app computes both cases correctly (see the files named below). These are drafts; they
have **not** been posted. Re-checked on 31 Oct 2026 with the versions shown.

---

## 1. pmsampsize 1.1.3: continuous outcome, criterion 4 (precision of the intercept) stops after one step

**Where to file:** the issue tracker given by `utils::packageDescription("pmsampsize")$BugReports`, or the maintainer's e-mail
(`maintainer("pmsampsize")`).

**Title:** `type = "c"`: criterion 4 (mmoe) loop uses a negative t quantile, so the interval limits swap and n is far too small

**Body:**

> When criterion 4 (the multiplicative margin of error of the intercept, `mmoe`) is the binding criterion for a continuous outcome,
> the returned sample size is too small and the reported confidence limits are back to front.
>
> ```r
> library(pmsampsize)   # 1.1.3
> r <- pmsampsize(type = "c", parameters = 2, intercept = 1.9, sd = 0.6, rsquared = 0.2, mmoe = 1.02)
> r$sample_size   # 237
> r$int_lci       # 1.97  ("lower" limit above the intercept)
> r$int_uci       # 1.83  ("upper" limit below it)
> ```
>
> The loop for criterion 4 builds the interval with `+ qt(0.025, df)`, which is negative, so the "upper" limit is below the
> intercept. The ratio of the limits therefore drops below `mmoe` straight away and the loop stops after one step, at the
> criterion-3 size plus one (236 + 1 = 237). Using `qt(0.975, df)` (or `- qt(0.025, df)`) for the upper limit gives the intended
> result: the smallest n for which the upper confidence limit of the intercept is within 2% of it is 769 here (interval
> 1.86 to 1.94), with the other inputs as above and the default shrinkage.
>
> When criterion 4 does not bind, the results are not affected.

**In this app:** `R/calc_closed_forms_pm.R` (header comment) and `R/calc_prediction.R`; the tests check the corrected criterion
against its definition.

---

## 2. presize 0.3.11: `prec_pos_lr()` and `prec_neg_lr()` ignore `conf.level`

**Where to file:** the issue tracker given by `utils::packageDescription("presize")$BugReports`.

**Title:** `prec_pos_lr()` / `prec_neg_lr()` accept `conf.level` but always use 95%

**Body:**

> Both functions have a `conf.level` argument but do not pass it on to `prec_lr()`, so the interval is always the 95% one and the
> returned object reports `conf.level = 0.95` whatever was asked for.
>
> ```r
> library(presize)   # 0.3.11
> a <- prec_pos_lr(prev = 0.3, sens = 0.9, spec = 0.8, n = 300, conf.level = 0.95)
> b <- prec_pos_lr(prev = 0.3, sens = 0.9, spec = 0.8, n = 300, conf.level = 0.80)
> c(a$lwr, a$upr)   # 3.404 5.949
> c(b$lwr, b$upr)   # 3.404 5.949   (same as 95%)
> b$conf.level      # 0.95
> prec_lr(prev = 0.3, p1 = 0.9, p2 = 0.2, n = 300, conf.level = 0.80)[c("lwr", "upr")]   # 3.749 5.401 (the 80% interval)
> ```
>
> The body is `prec_lr(prev = prev, p1 = sens, p2 = 1 - spec, n = n, conf.width = conf.width, ...)`; adding
> `conf.level = conf.level` to that call (in both functions) fixes it. The same applies to the `conf.width` route, where the
> required n is computed for 95% instead of the requested level.

**In this app:** `R/calc_closed_forms_presize.R` (header comment); the app's likelihood-ratio design uses the requested level.
