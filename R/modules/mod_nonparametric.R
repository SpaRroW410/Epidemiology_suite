# Nonparametric Tests module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_logistic.R
# (docs/SDD.md #8) -- three distinct designs, each with its own
# calc_*() engine wrapping TrialSize:: (Chow, Shao & Wang 2003).

nonparametric_meta <- list(
  id = "nonparametric",
  nav_title = "Nonparametric Tests"
)

mod_nonparametric_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Wilcoxon rank-sum (Mann-Whitney U, two independent groups)" = "rank_sum",
          "Wilcoxon signed-rank (one sample / paired differences)" = "signed_rank",
          "Kendall's tau (nonparametric association)" = "kendall",
          "Kruskal-Wallis (k independent groups)" = "kruskal_wallis",
          "Jonckheere-Terpstra (ordered alternatives)" = "jonckheere",
          "Friedman (k related/repeated measurements)" = "friedman",
          "Kolmogorov-Smirnov (two independent samples, Monte Carlo)" = "ks",
          "Wald-Wolfowitz runs test (two independent samples, Monte Carlo)" = "runs",
          "Animal/preclinical K-sample rank test (Lehmann alternative, Monte Carlo)" = "animal_rank"
        ),
        selected = "rank_sum"
      ),
      conditionalPanel(
        condition = design_is("rank_sum"),
        numericInput(ns("k_rs"), "Allocation ratio (k = n1/n2)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("p1_rs"), "p1 = P(Y >= X)", value = 0.7, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_rs"), "p2", value = 0.8, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p3_rs"), "p3", value = 0.8, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("signed_rank"),
        numericInput(ns("p2_sr"), "p2", value = 0.3, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p3_sr"), "p3", value = 0.4, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p4_sr"), "p4", value = 0.05, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("kendall"),
        numericInput(ns("p1_k"), "p1 = concordance probability (tau = 2*p1 - 1)",
                     value = 0.6, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_k"), "p2", value = 0.7, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("kruskal_wallis"),
        selectInput(ns("k_kw"), "Number of groups (k)", choices = 3:8, selected = 3),
        numericInput(ns("f_kw"), "Cohen's f effect size", value = 0.25, min = 0.001, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("jonckheere"),
        numericInput(ns("p1_jt"), "p1 = concordance probability (tau = 2*p1 - 1)",
                     value = 0.6, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_jt"), "p2", value = 0.7, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("friedman"),
        selectInput(ns("k_fr"), "Number of repeated measurements (k)", choices = 3:8, selected = 4),
        numericInput(ns("f_fr"), "Cohen's f effect size", value = 0.25, min = 0.001, step = 0.01),
        numericInput(ns("nscor_fr"), "Nonsphericity correction (1 = sphericity assumed)",
                     value = 1, min = 0.01, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("ks"),
        numericInput(ns("effect_size_ks"), "Standardized mean shift (comparable to Cohen's d)",
                     value = 0.5, min = 0.01, step = 0.05),
        numericInput(ns("nsim_ks"), "Monte Carlo replicates per candidate n (nsim)",
                     value = 500, min = 100, max = 5000, step = 100),
        p(class = "text-muted",
          "This design searches by simulation and may take several seconds.")
      ),
      conditionalPanel(
        condition = design_is("runs"),
        numericInput(ns("effect_size_runs"), "Standardized mean shift (comparable to Cohen's d)",
                     value = 0.8, min = 0.01, step = 0.05),
        numericInput(ns("nsim_runs"), "Monte Carlo replicates per candidate n (nsim)",
                     value = 500, min = 100, max = 5000, step = 100),
        p(class = "text-muted",
          "This design searches by simulation and may take several seconds.")
      ),
      conditionalPanel(
        condition = design_is("animal_rank"),
        selectInput(ns("k_animal"), "Number of groups (k, including control)", choices = 2:6, selected = 2),
        textInput(ns("odds_ratio_animal"), "Odds ratio(s) vs. control (comma-separated; one value applies to all)",
                  value = "4"),
        radioButtons(ns("statistic_animal"), "Test statistic",
                     choices = c("Kruskal-Wallis (omnibus)" = "Kruskal-Wallis",
                                 "Jonckheere-Terpstra (ordered trend)" = "Jonckheere-Terpstra"),
                     selected = "Kruskal-Wallis"),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'Jonckheere-Terpstra'", ns("statistic_animal")),
          radioButtons(ns("alternative_animal"), "Alternative",
                       choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
                       selected = "two.sided")
        ),
        numericInput(ns("nrep_animal"), "Monte Carlo replicates per candidate n (nrep)",
                     value = 100000, min = 1000, max = 1000000, step = 1000),
        p(class = "text-muted",
          "This design searches by simulation and may take several seconds. Kruskal-Wallis allows only a two-sided alternative.")
      ),
      conditionalPanel(
        condition = paste(design_is("ks"), design_is("runs"), design_is("animal_rank"), sep = " || "),
        monte_carlo_calculate_ui(ns)
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(nonparametric_content$wilcoxon_rank_sum$title),
      render_formula_block(nonparametric_content$wilcoxon_rank_sum$formula_latex),
      shiny::markdown(nonparametric_content$wilcoxon_rank_sum$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$wilcoxon_rank_sum$worked_example),
      hr(),
      h4(nonparametric_content$wilcoxon_signed_rank$title),
      render_formula_block(nonparametric_content$wilcoxon_signed_rank$formula_latex),
      shiny::markdown(nonparametric_content$wilcoxon_signed_rank$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$wilcoxon_signed_rank$worked_example),
      hr(),
      h4(nonparametric_content$kendall_tau$title),
      render_formula_block(nonparametric_content$kendall_tau$formula_latex),
      shiny::markdown(nonparametric_content$kendall_tau$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$kendall_tau$worked_example),
      hr(),
      h4(nonparametric_content$kruskal_wallis$title),
      render_formula_block(nonparametric_content$kruskal_wallis$formula_latex),
      shiny::markdown(nonparametric_content$kruskal_wallis$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$kruskal_wallis$worked_example),
      hr(),
      h4(nonparametric_content$jonckheere_terpstra$title),
      render_formula_block(nonparametric_content$jonckheere_terpstra$formula_latex),
      shiny::markdown(nonparametric_content$jonckheere_terpstra$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$jonckheere_terpstra$worked_example),
      hr(),
      h4(nonparametric_content$friedman$title),
      render_formula_block(nonparametric_content$friedman$formula_latex),
      shiny::markdown(nonparametric_content$friedman$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$friedman$worked_example),
      hr(),
      h4(nonparametric_content$ks_two_sample$title),
      render_formula_block(nonparametric_content$ks_two_sample$formula_latex),
      shiny::markdown(nonparametric_content$ks_two_sample$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$ks_two_sample$worked_example),
      hr(),
      h4(nonparametric_content$wald_wolfowitz$title),
      render_formula_block(nonparametric_content$wald_wolfowitz$formula_latex),
      shiny::markdown(nonparametric_content$wald_wolfowitz$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$wald_wolfowitz$worked_example),
      hr(),
      h4(nonparametric_content$animal_rank_test$title),
      render_formula_block(nonparametric_content$animal_rank_test$formula_latex),
      shiny::markdown(nonparametric_content$animal_rank_test$explanation),
      h5("Worked example"),
      shiny::markdown(nonparametric_content$animal_rank_test$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(nonparametric_content$wilcoxon_rank_sum$title),
      p(strong("Citation: "), nonparametric_content$wilcoxon_rank_sum$citation),
      p(strong("Implemented via: "), code(nonparametric_content$wilcoxon_rank_sum$backend)),
      hr(),
      h4(nonparametric_content$wilcoxon_signed_rank$title),
      p(strong("Citation: "), nonparametric_content$wilcoxon_signed_rank$citation),
      p(strong("Implemented via: "), code(nonparametric_content$wilcoxon_signed_rank$backend)),
      hr(),
      h4(nonparametric_content$kendall_tau$title),
      p(strong("Citation: "), nonparametric_content$kendall_tau$citation),
      p(strong("Implemented via: "), code(nonparametric_content$kendall_tau$backend)),
      hr(),
      h4(nonparametric_content$kruskal_wallis$title),
      p(strong("Citation: "), nonparametric_content$kruskal_wallis$citation),
      p(strong("Implemented via: "), code(nonparametric_content$kruskal_wallis$backend)),
      hr(),
      h4(nonparametric_content$jonckheere_terpstra$title),
      p(strong("Citation: "), nonparametric_content$jonckheere_terpstra$citation),
      p(strong("Implemented via: "), code(nonparametric_content$jonckheere_terpstra$backend)),
      hr(),
      h4(nonparametric_content$friedman$title),
      p(strong("Citation: "), nonparametric_content$friedman$citation),
      p(strong("Implemented via: "), code(nonparametric_content$friedman$backend)),
      hr(),
      h4(nonparametric_content$ks_two_sample$title),
      p(strong("Citation: "), nonparametric_content$ks_two_sample$citation),
      p(strong("Implemented via: "), code(nonparametric_content$ks_two_sample$backend)),
      hr(),
      h4(nonparametric_content$wald_wolfowitz$title),
      p(strong("Citation: "), nonparametric_content$wald_wolfowitz$citation),
      p(strong("Implemented via: "), code(nonparametric_content$wald_wolfowitz$backend)),
      hr(),
      h4(nonparametric_content$animal_rank_test$title),
      p(strong("Citation: "), nonparametric_content$animal_rank_test$citation),
      p(strong("Implemented via: "), code(nonparametric_content$animal_rank_test$backend))
    )
  )
}

mod_nonparametric_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # ks/runs/animal_rank are Monte Carlo (ROADMAP F9/P1#7): once one of
    # them is selected, recompute only on Calculate, not on every keystroke
    # -- see monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    SLOW_DESIGNS <- c("ks", "runs", "animal_rank")

    result <- reactive({
      req(input$design)
      is_slow <- input$design %in% SLOW_DESIGNS
      if (is_slow) input$calculate

      compute <- function() {
      req(input$alpha, input$power)

      tryCatch({
        value <- if (input$design == "rank_sum") {
          req(input$k_rs, input$p1_rs, input$p2_rs, input$p3_rs)
          calc_wilcoxon_rank_sum(
            k = input$k_rs, p1 = input$p1_rs, p2 = input$p2_rs, p3 = input$p3_rs,
            alpha = input$alpha, power = input$power
          )
        } else if (input$design == "signed_rank") {
          req(input$p2_sr, input$p3_sr, input$p4_sr)
          calc_wilcoxon_signed_rank(
            p2 = input$p2_sr, p3 = input$p3_sr, p4 = input$p4_sr,
            alpha = input$alpha, power = input$power
          )
        } else if (input$design == "kendall") {
          req(input$p1_k, input$p2_k)
          calc_kendall_tau(
            p1 = input$p1_k, p2 = input$p2_k, alpha = input$alpha, power = input$power
          )
        } else if (input$design == "kruskal_wallis") {
          req(input$k_kw, input$f_kw)
          calc_kruskal_wallis(
            k = as.integer(input$k_kw), f = input$f_kw,
            alpha = input$alpha, power = input$power
          )
        } else if (input$design == "jonckheere") {
          req(input$p1_jt, input$p2_jt)
          calc_jonckheere_terpstra(
            p1 = input$p1_jt, p2 = input$p2_jt, alpha = input$alpha, power = input$power
          )
        } else if (input$design == "friedman") {
          req(input$k_fr, input$f_fr, input$nscor_fr)
          calc_friedman(
            k = as.integer(input$k_fr), f = input$f_fr, nscor = input$nscor_fr,
            alpha = input$alpha, power = input$power
          )
        } else if (input$design == "ks") {
          req(input$effect_size_ks, input$nsim_ks)
          calc_ks_two_sample(
            effect_size = input$effect_size_ks, alpha = input$alpha, power = input$power,
            nsim = input$nsim_ks
          )
        } else if (input$design == "runs") {
          req(input$effect_size_runs, input$nsim_runs)
          calc_wald_wolfowitz_runs(
            effect_size = input$effect_size_runs, alpha = input$alpha, power = input$power,
            nsim = input$nsim_runs
          )
        } else {
          req(input$k_animal, input$odds_ratio_animal, input$statistic_animal,
              input$alternative_animal, input$nrep_animal)
          odds_ratio <- suppressWarnings(as.numeric(trimws(strsplit(input$odds_ratio_animal, ",")[[1]])))
          if (anyNA(odds_ratio) || length(odds_ratio) == 0) {
            stop("Odds ratio(s) must be one or more comma-separated numbers.")
          }
          calc_animal_rank_test(
            k = as.integer(input$k_animal), odds_ratio = odds_ratio,
            alpha = input$alpha, power = input$power,
            statistic = input$statistic_animal, alternative = input$alternative_animal,
            nrep = input$nrep_animal
          )
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
      }

      if (is_slow) isolate(compute()) else compute()
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (res$design == "kendall" || res$design == "jonckheere") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Implied Kendall's tau: %.3f", v$tau))
        )
      } else if (res$design == "kruskal_wallis") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("(Equivalent one-way ANOVA would need n = %d per group)", v$n_anova_per_group))
        )
      } else if (res$design == "friedman") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("(Equivalent RM-ANOVA would need n = %d; ARE = %.4f)", v$n_rm_anova, v$are))
        )
      } else if (res$design == "ks" || res$design == "runs") {
        tagList(
          p(strong("Required sample size per group: "), v$n1),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Simulated achieved power at this n: %.3f (Monte Carlo estimate)", v$achieved_power))
        )
      } else if (res$design == "animal_rank") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total, sprintf(" (%d groups)", v$k)),
          p(sprintf("Simulated achieved power at this n: %.3f (Monte Carlo estimate)", v$achieved_power))
        )
      } else {
        p(strong("Required sample size: "), v$n)
      }
    })

    render_export_handlers(output, result, function() {
      key <- input$design
      remap <- c("rank_sum" = "wilcoxon_rank_sum", "signed_rank" = "wilcoxon_signed_rank", "kendall" = "kendall_tau", "jonckheere" = "jonckheere_terpstra", "ks" = "ks_two_sample", "runs" = "wald_wolfowitz", "animal_rank" = "animal_rank_test")
      nonparametric_content[[if (key %in% names(remap)) remap[[key]] else key]]
    })
  })
}
