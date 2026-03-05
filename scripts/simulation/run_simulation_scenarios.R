# Run Prior Predictive Simulations for Three Pilot Data Scenarios
# Date: February 4, 2026

cat("\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\nPRIOR PREDICTIVE SIMULATION - MULTIPLE SCENARIOS\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\n\n")

# Load required packages
suppressPackageStartupMessages({
  library(brms)
  library(tidyverse)
  library(bayestestR)
})

# Set seed
set.seed(2026)

# ============================================================================
# OUTPUT DIRECTORIES
# Script is expected to be run from the project root:
#   Rscript scripts/simulation/run_simulation_scenarios.R
# ============================================================================

dir_csv        <- file.path("data", "csv")
dir_rds        <- file.path("data", "rds")
dir_checkpoint <- file.path("data", "checkpoints")
dir_archive    <- file.path("data", "archive")
dir.create(dir_csv,        recursive = TRUE, showWarnings = FALSE)
dir.create(dir_rds,        recursive = TRUE, showWarnings = FALSE)
dir.create(dir_checkpoint, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_archive,    recursive = TRUE, showWarnings = FALSE)

# Timestamp for this run — used to archive outputs without overwriting history
run_ts <- format(Sys.time(), "%Y%m%d_%H%M%S")

cat(sprintf("CSV output        : %s\n", normalizePath(dir_csv)))
cat(sprintf("RDS output        : %s\n", normalizePath(dir_rds)))
cat(sprintf("Checkpoint output : %s\n", normalizePath(dir_checkpoint)))
cat(sprintf("Archive output    : %s\n", normalizePath(dir_archive)))
cat(sprintf("Run timestamp     : %s\n", run_ts))

# ============================================================================
# LOAD PROFILE-SPECIFIC CONFIG
# Set SIMULATION_PROFILE=ramses  in the slurm script (already done).
# Defaults to 'local' when run interactively or outside SLURM.
# ============================================================================

# Profile is passed as a command-line argument by run_simulation.slurm:
#   Rscript scripts/run_simulation_scenarios.R ramses
# This is more robust than env vars which apptainer may filter out.
# Falls back to SIMULATION_PROFILE env var, then to auto-detect via SLURM_JOB_ID.
args <- commandArgs(trailingOnly = TRUE)
sim_profile <- if (length(args) >= 1 && nchar(args[1]) > 0) {
  args[1]
} else if (nchar(Sys.getenv("SIMULATION_PROFILE")) > 0) {
  Sys.getenv("SIMULATION_PROFILE")
} else if (nchar(Sys.getenv("SLURM_JOB_ID")) > 0) {
  "ramses"
} else {
  "local"
}
config_file <- file.path("config", sprintf("params_%s.R", sim_profile))
if (!file.exists(config_file)) {
  warning(sprintf("Config file not found: %s — falling back to params_local.R", config_file))
  config_file <- file.path("config", "params_local.R")
  sim_profile <- "local"
}
cat(sprintf("\nLoading config: %s\n", config_file))
source(config_file)

# ============================================================================
# DEFINE THREE SCENARIOS BASED ON DIFFERENT PILOT DATA OUTCOMES
# ============================================================================

# emmeans contrasts (from emmeans.txt):
# contrasts are reported as (short - long), so we flip sign for (long - short)
# short: -0.39168, medium: -0.01512, long: -0.00223
pilot_effect_short <- 0.39168
pilot_effect_medium <- 0.01512
pilot_effect_long <- 0.00223

# Map pilot durations to 3 simulation bins
# Instant is excluded per current analysis plan.
pilot_effect_0_10s <- pilot_effect_short
pilot_effect_10_20s <- pilot_effect_medium
pilot_effect_20_60s <- pilot_effect_long
pilot_effect_late_avg <- mean(c(pilot_effect_10_20s, pilot_effect_20_60s))

# NOTE: The effect sizes below are HYPOTHETICAL design scenarios, not direct
# replications of the pilot. Key divergences from pilot emmeans contrasts:
#
#   Window      Pilot (emmeans)   Minimal   Conservative   Realistic   Optimistic
#   0-10s       0.392             0.200     0.294          0.392       0.451
#   10-20s      0.015             0.015     0.009          0.015       0.023
#   20-60s      0.002             0.070     0.000          0.002       0.003
#
# The 0-10s values are close to the pilot. The 10-20s and 20-60s values are
# near-zero in the pilot and remain so here; they are varied only to probe
# the sensitivity of the ROPE decision. Scenarios should NOT be read as
# "what we expect" for later windows — the pilot shows essentially no effect
# there (beta = 0.015 and 0.002 respectively, both inside the ROPE).
#
# WHY ABSENCE DETECTION IS EASY BUT PRESENCE DETECTION DRIVES SAMPLE SIZE:
# PRESENT requires HDI_low > ROPE_upper (+0.10): the effect must be large
# enough that even the lower HDI bound clears the ROPE — hard when the true
# effect is small. ABSENT requires the entire HDI to fit inside ROPE: with
# a true near-zero effect and sigma_residual = 0.35, the 95% HDI half-width
# at N = 30 is already ~0.06 (< ROPE half-width 0.10), so absence of the
# 20-60s window is decided trivially at the first checkpoint in all current
# scenarios. This asymmetry means expected-N is entirely driven by how
# quickly the 0-10s PRESENT decision can be made.
# The Minimal scenario deliberately breaks this by setting the 20-60s true
# effect to 0.07 — near the ROPE boundary — forcing the absent verdict to
# wait until the HDI narrows enough to stay below 0.10. Combined with a
# small 0-10s effect (0.20, just 2× the ROPE half-width), both decisions
# become difficult and expected-N is pushed toward the hard cap.

scenarios <- list(

  # Scenario 1: STRONG EFFECT (Optimistic)
  # Pilot showed large effect in short events, clearly absent in long
  optimistic = list(
    name = "Optimistic (Pilot-Anchored, Strong Early Effect)",
    description = "Early effect above pilot estimate, near-null in late window",
    effect_sizes = tibble(
      duration_bin = c("bin_0_10s", "bin_10_20s", "bin_20_60s"),
      effect_d = c(pilot_effect_0_10s * 1.15, pilot_effect_10_20s * 1.5, pilot_effect_20_60s * 1.5)
    )
  ),

  # Scenario 2: MODERATE EFFECT (Realistic)
  # Pilot showed medium effect, gradual decline
  realistic = list(
    name = "Realistic (emmeans-Anchored)",
    description = "Directly anchored to pilot emmeans contrasts",
    effect_sizes = tibble(
      duration_bin = c("bin_0_10s", "bin_10_20s", "bin_20_60s"),
      effect_d = c(pilot_effect_0_10s, pilot_effect_10_20s, pilot_effect_20_60s)
    )
  ),

  # Scenario 3: WEAK EFFECT (Conservative)
  # Pilot showed small effect that may be hard to detect
  conservative = list(
    name = "Conservative (Pilot-Anchored, Lower Early Effect)",
    description = "Reduced early effect, late effects inside practical-null range",
    effect_sizes = tibble(
      duration_bin = c("bin_0_10s", "bin_10_20s", "bin_20_60s"),
      effect_d = c(pilot_effect_0_10s * 0.75, pilot_effect_late_avg, 0.00)
    )
  ),

  # Scenario 4: SENSITIVITY / MINIMAL DETECTABLE EFFECT
  # Asks: what if the early effect is only half the pilot, AND the late-window
  # effect sits near the upper ROPE boundary (0.07)?  This is the worst-case
  # scenario for the sequential design:
  #   - PRESENT for 0-10s requires the HDI to clear +0.10 on a true effect of
  #     only 0.20 — needs N ≈ 60-90 before CI_low consistently exceeds 0.10.
  #   - ABSENT for 20-60s requires the HDI to stay below +0.10 on a true
  #     effect of 0.07 — also non-trivial; sampling variation regularly pushes
  #     the upper HDI bound above 0.10 at small N.
  #   Both decisions are hard simultaneously, so expected-N is pushed toward
  #   the hard cap. This scenario serves as a sensitivity analysis: if funded
  #   for N = 120, does the design still work if the pilot over-estimated the
  #   early effect by ~50%?
  minimal = list(
    name = "Minimal (Sensitivity Analysis — Half Pilot Effect)",
    description = "Early effect halved vs pilot (0.20); late effect near ROPE boundary (0.07)",
    effect_sizes = tibble(
      duration_bin = c("bin_0_10s", "bin_10_20s", "bin_20_60s"),
      effect_d = c(0.20, pilot_effect_10_20s, 0.07)
    )
  )
)

# ============================================================================
# SIMULATION PARAMETERS (SHARED ACROSS SCENARIOS)
# ============================================================================
# n_sims, n_samples, rope_lower/upper, n_items_per_condition, mcmc_chains,
# mcmc_iter, and max_workers_override are loaded from config/ above.
#
# Sequential checkpoints: start at N = 30, then every 15 participants up to the
# hard cap of N = 120.  Gives: 30, 45, 60, 75, 90, 105, 120.
# Note: fits at N = 30 and 45 should be interpreted with caution — random-slope
# covariance parameters are under-identified below N ≈ 50-60 and brms may return
# divergent transitions or low bulk-ESS at those sizes.  The first *reliable*
# stopping opportunity is therefore still N = 60; the two earlier checkpoints are
# included to observe model behaviour and may allow early stopping if evidence is
# already overwhelming (e.g. in the Optimistic scenario).
#
# ROPE = ±0.10 on the log scale.
# Rationale: ±0.10 corresponds to a ±10% multiplicative shift, roughly ±0.9 s
# on the 0–10 s baseline (exp(2.7-0.5) ≈ 9 s) and ±3 s on the 20–60 s baseline
# (exp(2.7+0.7) ≈ 30 s). Both are plausible "negligible" thresholds given that
# the effect of interest is 0.29–0.45 log units (6–9× the ROPE half-width).
# A tighter ROPE of ±0.05 is analytically infeasible: the SE at N = 120
# (~0.019) gives an HDI half-width of ~0.037, so the upper HDI bound on a
# near-zero 20–60 s effect (β ≈ 0.002) averages ~0.039 — right at the ±0.05
# boundary. Sampling variation means many runs breach 0.05, making the ABSENT
# verdict essentially unachievable before the hard cap. ±0.10 gives comfortable
# margin: at N = 60 the mean upper bound is ~0.05, yielding ~90–98% ABSENT rate.

sigma_residual <- 0.35
sd_participant_intercept <- 0.25
sd_item_intercept <- 0.15
sd_participant_slope <- 0.10
within_corr <- 0.5

# ============================================================================
# RUN METADATA
# Captures all parameters so outputs are fully self-documenting.
# Written as run_metadata.csv and embedded in scenario_comparison.csv.
# ============================================================================

run_metadata <- tibble(
  run_ts                  = run_ts,
  profile                 = sim_profile,
  n_sims                  = n_sims,
  n_samples               = paste(n_samples, collapse = ","),
  rope_lower              = rope_lower,
  rope_upper              = rope_upper,
  n_items_per_condition   = n_items_per_condition,
  sigma_residual          = sigma_residual,
  sd_participant_intercept = sd_participant_intercept,
  sd_item_intercept       = sd_item_intercept,
  sd_participant_slope    = sd_participant_slope,
  within_corr             = within_corr,
  mcmc_chains             = mcmc_chains,
  mcmc_iter               = mcmc_iter,
  max_workers             = max_workers_override,
  r_version               = paste(R.version$major, R.version$minor, sep = "."),
  brms_version            = as.character(packageVersion("brms")),
  stan_version            = paste(rstan::stan_version(), collapse = ".")
)

cat("\nRun metadata:\n")
print(t(run_metadata), quote = FALSE)
cat("\n")

# ============================================================================
# DATA SIMULATION FUNCTION
# ============================================================================

simulate_duration_data <- function(n_participants,
                                   n_items_per_condition,
                                   effect_sizes,
                                   sigma_residual,
                                   sd_participant_intercept,
                                   sd_item_intercept,
                                   sd_participant_slope) {

  duration_bins <- effect_sizes$duration_bin

  participants <- tibble(
    participant_id = 1:n_participants,
    list = rep(1:2, length.out = n_participants),
    participant_intercept = rnorm(n_participants, 0, sd_participant_intercept),
    participant_slope = rnorm(n_participants, 0, sd_participant_slope)
  )

  n_items_total <- n_items_per_condition * 2 * 3
  items <- tibble(
    item_id = 1:n_items_total,
    item_intercept = rnorm(n_items_total, 0, sd_item_intercept)
  )

  data <- expand_grid(
    participant_id = participants$participant_id,
    duration_bin = duration_bins,
    sentence_length = c("short", "long")
  ) %>%
    group_by(participant_id, duration_bin, sentence_length) %>%
    slice(rep(1:n(), n_items_per_condition)) %>%
    mutate(item_id = row_number()) %>%
    ungroup() %>%
    left_join(participants, by = "participant_id") %>%
    mutate(item_id = item_id + (as.numeric(factor(duration_bin)) - 1) *
                                 n_items_per_condition * 2) %>%
    left_join(items, by = "item_id") %>%
    left_join(effect_sizes, by = "duration_bin")

  data <- data %>%
    mutate(
      sentence_effect = if_else(sentence_length == "long", effect_d, 0),
      baseline_log_duration = 2.7,
      bin_adjustment = case_when(
        duration_bin == "bin_0_10s" ~ -0.5,
        duration_bin == "bin_10_20s" ~ 0.0,
        duration_bin == "bin_20_60s" ~ 0.7
      ),
      individual_sentence_effect = sentence_effect + participant_slope,
      log_duration = baseline_log_duration +
                     bin_adjustment +
                     individual_sentence_effect +
                     participant_intercept +
                     item_intercept +
                     rnorm(n(), 0, sigma_residual),
      duration_seconds = exp(log_duration)
    ) %>%
    mutate(
      participant_id = factor(participant_id),
      item_id = factor(item_id),
      sentence_length = factor(sentence_length, levels = c("short", "long")),
      duration_bin = factor(duration_bin, levels = duration_bins)
    )

  return(data)
}

# ============================================================================
# BAYESIAN MODEL FITTING
# ============================================================================

fit_bayesian_model <- function(data, chains = 2, iter = 1000, cores = 1, seed = 2026,
                               template_fit = NULL) {

  if (!is.null(template_fit)) {
    # Reuse the already-compiled Stan model from template_fit.
    # update() skips compilation entirely, so no sink() is called in
    # forked mclapply workers -- this is the fix for "invalid connection".
    model <- update(
      template_fit,
      newdata   = data,
      chains    = chains,
      iter      = iter,
      cores     = cores,
      silent    = 1,
      refresh   = 0,
      seed      = seed,
      recompile = FALSE
    )
  } else {
    priors <- c(
      prior(normal(2.7, 1.5), class = Intercept),
      prior(normal(0, 0.5), class = b),
      prior(exponential(1), class = sd),
      prior(exponential(1), class = sigma),
      prior(lkj(2), class = cor)  # prior for by-participant slope correlation
    )

    model <- brm(
      # Random slopes for sentence_length by participant match the DGP
      # (sd_participant_slope in simulate_duration_data). Omitting them
      # would underestimate fixed-effect uncertainty.
      log_duration ~ sentence_length * duration_bin +
                     (1 + sentence_length | participant_id) +
                     (1 | item_id),
      data   = data,
      prior  = priors,
      chains = chains,
      iter   = iter,
      cores  = cores,
      silent = 1,
      refresh = 0,
      seed   = seed
    )
  }

  return(model)
}

# ============================================================================
# PER-BIN ROPE HELPER (absolute-seconds alternative to uniform ROPE)
# ============================================================================
#
# This helper is IMPLEMENTED but NOT ACTIVE. The simulation loop calls
# check_rope_decision(model, rope_lower, rope_upper) without rope_by_bin,
# so a uniform ROPE = ±0.10 is used for all windows.
#
# What this function does: anchors "negligible" to an absolute number of
# seconds (delta_s), converting to log scale per bin:
#   rope_log_bin = log(1 + delta_s / baseline_seconds)
#
# Longer bins have a larger baseline, so the resulting log-scale ROPE is
# *tighter* for longer bins — which makes ABSENT *harder* to declare in the
# 20-60s window, NOT easier. Example with the default delta_s = 0.5 s:
#
#   0-10s : ±0.054  (≈ ±0.5 s on a ~9 s baseline)
#   10-20s: ±0.033  (≈ ±0.5 s on a ~15 s baseline)
#   20-60s: ±0.017  (≈ ±0.5 s on a ~30 s baseline)
#
# A 20-60s ROPE of ±0.017 is far tighter than even ±0.05 and would cause
# the ABSENT verdict to be unachievable within the hard cap of N = 120.
# Activating this function requires a large delta_s (≥ 3 s) to keep the
# 20-60s ROPE near ±0.10, but that would simultaneously widen the 0-10s ROPE
# to ~±0.29 — interfering with the PRESENT criterion.
#
# Recommendation: keep rope_by_bin = NULL (uniform ±0.10).
#
# Usage: pass rope_by_bin = compute_bin_ropes(delta_s) to check_rope_decision().

compute_bin_ropes <- function(delta_s = 0.5) {
  baselines <- c(
    bin_0_10s  = exp(2.7 - 0.5),  # ~9 s
    bin_10_20s = exp(2.7 + 0.0),  # ~15 s
    bin_20_60s = exp(2.7 + 0.7)   # ~30 s
  )
  bounds <- log(1 + delta_s / baselines)
  setNames(lapply(bounds, function(b) c(-b, b)), names(bounds))
}

# ============================================================================
# ROPE DECISION FUNCTION
# ============================================================================

check_rope_decision <- function(model, rope_lower = -0.05, rope_upper = 0.05,
                                rope_by_bin = NULL) {

  # Unpack per-bin bounds (fall back to uniform rope_lower/rope_upper)
  r_0_10s  <- if (!is.null(rope_by_bin)) rope_by_bin$bin_0_10s  else c(rope_lower, rope_upper)
  r_10_20s <- if (!is.null(rope_by_bin)) rope_by_bin$bin_10_20s else c(rope_lower, rope_upper)
  r_20_60s <- if (!is.null(rope_by_bin)) rope_by_bin$bin_20_60s else c(rope_lower, rope_upper)

  posterior <- as_draws_df(model)

  sent_length_effect <- posterior$b_sentence_lengthlong
  int_10_20 <- posterior$`b_sentence_lengthlong:duration_binbin_10_20s`
  int_20_60 <- posterior$`b_sentence_lengthlong:duration_binbin_20_60s`

  effect_0_10s <- sent_length_effect
  effect_10_20s <- sent_length_effect + int_10_20
  effect_20_60s <- sent_length_effect + int_20_60

  hdi_0_10s <- hdi(effect_0_10s, ci = 0.95)
  hdi_10_20s <- hdi(effect_10_20s, ci = 0.95)
  hdi_20_60s <- hdi(effect_20_60s, ci = 0.95)

  decision_0_10s <- case_when(
    hdi_0_10s$CI_low > r_0_10s[2]                                        ~ "PRESENT",
    hdi_0_10s$CI_high < r_0_10s[1]                                       ~ "ABSENT_NEGATIVE",
    hdi_0_10s$CI_low >= r_0_10s[1] & hdi_0_10s$CI_high <= r_0_10s[2]   ~ "ABSENT",
    TRUE                                                                  ~ "UNDECIDED"
  )

  decision_10_20s <- case_when(
    hdi_10_20s$CI_low > r_10_20s[2]                                          ~ "PRESENT",
    hdi_10_20s$CI_high < r_10_20s[1]                                         ~ "ABSENT_NEGATIVE",
    hdi_10_20s$CI_low >= r_10_20s[1] & hdi_10_20s$CI_high <= r_10_20s[2]   ~ "ABSENT",
    TRUE                                                                      ~ "UNDECIDED"
  )

  decision_20_60s <- case_when(
    hdi_20_60s$CI_low > r_20_60s[2]                                          ~ "PRESENT",
    hdi_20_60s$CI_high < r_20_60s[1]                                         ~ "ABSENT_NEGATIVE",
    hdi_20_60s$CI_low >= r_20_60s[1] & hdi_20_60s$CI_high <= r_20_60s[2]   ~ "ABSENT",
    TRUE                                                                      ~ "UNDECIDED"
  )

  h2_supported <- (decision_0_10s == "PRESENT") &
                  (decision_20_60s %in% c("ABSENT", "ABSENT_NEGATIVE"))

  overall_decision <- if_else(
    decision_0_10s != "UNDECIDED" & decision_20_60s != "UNDECIDED",
    "DECIDED",
    "UNDECIDED"
  )

  results <- tibble(
    decision_0_10s = decision_0_10s,
    decision_10_20s = decision_10_20s,
    decision_20_60s = decision_20_60s,
    h2_supported = h2_supported,
    overall_decision = overall_decision,
    hdi_0_10s_lower = hdi_0_10s$CI_low,
    hdi_0_10s_upper = hdi_0_10s$CI_high,
    hdi_10_20s_lower = hdi_10_20s$CI_low,
    hdi_10_20s_upper = hdi_10_20s$CI_high,
    hdi_20_60s_lower = hdi_20_60s$CI_low,
    hdi_20_60s_upper = hdi_20_60s$CI_high,
    mean_0_10s = mean(effect_0_10s),
    mean_10_20s = mean(effect_10_20s),
    mean_20_60s = mean(effect_20_60s)
  )

  return(results)
}

# ============================================================================
# SIMULATION LOOP FOR ONE SCENARIO
# ============================================================================

run_scenario_simulation <- function(scenario, n_sims, n_samples,
                                    scenario_key, dir_checkpoint) {

  cat(sprintf("\n\n%s\n", paste0(rep("=", 80), collapse = "")))
  cat(sprintf("SCENARIO: %s\n", scenario$name))
  cat(sprintf("%s\n", paste0(rep("=", 80), collapse = "")))
  cat(sprintf("Description: %s\n", scenario$description))
  cat("Effect sizes:\n")
  print(scenario$effect_sizes)
  # ------------------------------------------------------------------
  # CHECKPOINT / RESUME
  # Each completed sim writes a small RDS to ckpt_dir immediately.
  # On restart, already-completed sims are skipped automatically.
  # ------------------------------------------------------------------
  ckpt_dir <- file.path(dir_checkpoint, scenario_key)
  dir.create(ckpt_dir, recursive = TRUE, showWarnings = FALSE)

  existing_ckpts <- list.files(ckpt_dir, pattern = "^sim_\\d{4}\\.rds$")
  completed_ids  <- as.integer(sub("sim_(\\d{4})\\.rds", "\\1", existing_ckpts))
  sims_to_run    <- setdiff(seq_len(n_sims), completed_ids)

  cat(sprintf("\nRunning %d simulations...\n", n_sims))
  if (length(completed_ids) > 0) {
    cat(sprintf("  Resuming: %d already done, %d remaining.\n",
                length(completed_ids), length(sims_to_run)))
  }

  if (length(sims_to_run) == 0) {
    cat("  All simulations already completed. Loading from checkpoints.\n")
  } else {

    # Determine parallel workers
    # 1. Try SLURM_CPUS_PER_TASK first (most reliable on cluster)
    slurm_cpus <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK"))

    # 2. Fallback to detectCores() if not in SLURM
    sys_cores <- parallel::detectCores(logical = FALSE) # prefer physical cores

    if (!is.na(slurm_cpus)) {
      n_cores_available <- slurm_cpus
      cat(sprintf("Detected SLURM_CPUS_PER_TASK: %d\n", n_cores_available))
    } else {
      n_cores_available <- sys_cores
      cat(sprintf("Detected system cores: %d\n", n_cores_available))
    }

    # We run 1 core per worker (sequential chains) to maximise simulation throughput.
    # max_workers_override comes from the profile config (16 on ramses, 4 locally).
    # MAX_SIM_WORKERS env var can still override for ad-hoc tuning.
    max_workers_env <- suppressWarnings(as.integer(Sys.getenv("MAX_SIM_WORKERS")))
    max_workers <- if (!is.na(max_workers_env)) max_workers_env else max_workers_override

    n_workers <- max(1L, min(n_cores_available, max_workers, n_sims))

    cat(sprintf("Parallelizing with %d workers (1 core/worker, capped at %d for memory).\n",
                n_workers, max_workers))

    # PRE-COMPILE MODEL IN PARENT PROCESS
    # brm() calls sink() during Stan compilation (even with silent=1), which
    # breaks forked mclapply workers with "invalid connection". The fix:
    # compile once here, then pass the brmsfit object to workers so they call
    # update() instead of brm() -- update() reuses the compiled stanmodel and
    # never triggers sink().
    cat("Pre-compiling Stan model (will be reused by all workers)...\n")
    max_n <- max(n_samples)
    dummy_data <- simulate_duration_data(
      n_participants = max_n,
      n_items_per_condition = n_items_per_condition,
      effect_sizes = scenario$effect_sizes,
      sigma_residual = sigma_residual,
      sd_participant_intercept = sd_participant_intercept,
      sd_item_intercept = sd_item_intercept,
      sd_participant_slope = sd_participant_slope
    )
    dummy_model <- NULL  # NULL = workers fall back to brm() if compilation fails
    tryCatch({
      dummy_model <- fit_bayesian_model(dummy_data, chains = 1, iter = 10, cores = 1)
      cat("\u2713 Model pre-compiled. Workers will call update() -- no recompilation.\n")
    }, error = function(e) {
      cat("WARNING: Pre-compilation failed. Workers will compile individually (risk of sink errors).\n")
      cat("Error:", e$message, "\n")
    })
    rm(dummy_data); gc(verbose = FALSE)  # free data but KEEP dummy_model for workers

    # Run simulations in parallel
    results_list <- parallel::mclapply(sims_to_run, function(sim) {

      # Worker function: each worker gets its own independent RNG stream
      set.seed(2026 + sim)
      tryCatch({
        data_full <- simulate_duration_data(
          n_participants = max_n,
          n_items_per_condition = n_items_per_condition,
          effect_sizes = scenario$effect_sizes,
          sigma_residual = sigma_residual,
          sd_participant_intercept = sd_participant_intercept,
          sd_item_intercept = sd_item_intercept,
          sd_participant_slope = sd_participant_slope
        )

        sim_results <- tibble()

        n_idx <- 0L
        for (n in n_samples) {
          n_idx <- n_idx + 1L

          data_subset <- data_full %>%
            filter(as.numeric(as.character(participant_id)) <= n)

          # cores=1: we parallelise across simulations (mclapply), not chains.
          # Unique seed per sim x step keeps MCMC independent across replicates.
          # template_fit reuses the compiled Stan model -> no sink() in workers.
          model <- fit_bayesian_model(data_subset, chains = mcmc_chains, iter = mcmc_iter,
                                      cores = 1,
                                      seed = 2026L + sim * 1000L + n_idx,
                                      template_fit = dummy_model)

          decisions <- check_rope_decision(model, rope_lower, rope_upper)

          # Free the model and posterior draws immediately -- they can be 300-500 MB
          # each and are no longer needed once decisions are extracted.
          rm(model); gc(verbose = FALSE)

          result <- tibble(
            sim_id = sim,
            n_participants = n,
            decision_0_10s = decisions$decision_0_10s,
            decision_10_20s = decisions$decision_10_20s,
            decision_20_60s = decisions$decision_20_60s,
            h2_supported = decisions$h2_supported,
            overall_decision = decisions$overall_decision,
            hdi_0_10s_lower = decisions$hdi_0_10s_lower,
            hdi_0_10s_upper = decisions$hdi_0_10s_upper,
            hdi_10_20s_lower = decisions$hdi_10_20s_lower,
            hdi_10_20s_upper = decisions$hdi_10_20s_upper,
            hdi_20_60s_lower = decisions$hdi_20_60s_lower,
            hdi_20_60s_upper = decisions$hdi_20_60s_upper,
            mean_0_10s = decisions$mean_0_10s,
            mean_10_20s = decisions$mean_10_20s,
            mean_20_60s = decisions$mean_20_60s
          )

          sim_results <- bind_rows(sim_results, result)

          if (result$overall_decision == "DECIDED") {
            break  # Stop this simulation
          }
        }
        # Write checkpoint immediately — survives parent OOM kill
        saveRDS(sim_results,
                file.path(ckpt_dir, sprintf("sim_%04d.rds", sim)))
        return(sim_results)

      }, error = function(e) {
        cat(sprintf("    ERROR in sim %d: %s\n", sim, e$message))
        return(NULL)
      })

    }, mc.cores = n_workers)

    # Report failed workers before silently dropping their NULLs
    n_failed <- sum(vapply(results_list, is.null, logical(1)))
    if (n_failed > 0) {
      warning(sprintf(
        "%d of %d simulations failed (invalid connection / OOM). Checkpoint files retain any that wrote before dying.",
        n_failed, length(sims_to_run)
      ))
    }

  }  # end if (length(sims_to_run) > 0)

  # Collect ALL results from checkpoint files
  # (covers previously done sims + just-finished batch)
  ckpt_files <- list.files(ckpt_dir, pattern = "^sim_\\d{4}\\.rds$", full.names = TRUE)
  if (length(ckpt_files) == 0) {
    warning("No checkpoint files found — returning empty results.")
    return(tibble())
  }
  all_results <- bind_rows(lapply(ckpt_files, readRDS))
  cat(sprintf("  Collected %d completed simulations from checkpoints.\n",
              n_distinct(all_results$sim_id)))

  return(all_results)
}

# ============================================================================
# ANALYZE AND REPORT RESULTS
# ============================================================================

analyze_scenario_results <- function(results, scenario_name) {

  cat("\n\n")
  cat(paste0(rep("-", 80), collapse = ""))
  cat(sprintf("\nRESULTS: %s\n", scenario_name))
  cat(paste0(rep("-", 80), collapse = ""))
  cat("\n\n")

  # Sequential decision points
  sequential_results <- results %>%
    group_by(sim_id) %>%
    filter(overall_decision == "DECIDED") %>%
    slice_min(n_participants, n = 1, with_ties = FALSE) %>%
    ungroup()

  # Decision rates
  decision_summary <- sequential_results %>%
    group_by(n_participants) %>%
    summarise(
      n_decided = n(),
      pct_decided = n() / n_distinct(results$sim_id) * 100,
      n_h2_supported = sum(h2_supported),
      pct_h2_supported = sum(h2_supported) / n() * 100,
      .groups = "drop"
    )

  cat("Decision Rates at Each Sample Size:\n")
  print(decision_summary, n = Inf)

  expected_n <- mean(sequential_results$n_participants)
  never_decided <- n_distinct(results$sim_id) - nrow(sequential_results)
  pct_never_decided <- never_decided / n_distinct(results$sim_id) * 100
  h2_support_rate <- sum(sequential_results$h2_supported) / nrow(sequential_results) * 100

  cat(sprintf("\nExpected sample size: %.1f participants\n", expected_n))
  cat(sprintf("Never decided at N=120: %d (%.1f%%)\n", never_decided, pct_never_decided))
  cat(sprintf("H2 supported: %.1f%% (among decided)\n", h2_support_rate))

  # Decision patterns by bin
  cat("\n\nDecision Patterns by Bin:\n")
  for (n in unique(results$n_participants)) {
    cat(sprintf("\nN = %d:\n", n))
    n_results <- results %>% filter(n_participants == n)

    cat(sprintf("  0-10s:  PRESENT: %.0f%%, ABSENT: %.0f%%, UNDECIDED: %.0f%%\n",
                mean(n_results$decision_0_10s == "PRESENT") * 100,
                mean(n_results$decision_0_10s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                mean(n_results$decision_0_10s == "UNDECIDED") * 100))

    cat(sprintf("  10-20s: PRESENT: %.0f%%, ABSENT: %.0f%%, UNDECIDED: %.0f%%\n",
                mean(n_results$decision_10_20s == "PRESENT") * 100,
                mean(n_results$decision_10_20s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                mean(n_results$decision_10_20s == "UNDECIDED") * 100))

    cat(sprintf("  20-60s: PRESENT: %.0f%%, ABSENT: %.0f%%, UNDECIDED: %.0f%%\n",
                mean(n_results$decision_20_60s == "PRESENT") * 100,
                mean(n_results$decision_20_60s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                mean(n_results$decision_20_60s == "UNDECIDED") * 100))
  }

  # HDI width
  cat("\n\nMean HDI Width (Precision):\n")
  hdi_summary <- results %>%
    mutate(
      width_0_10s = hdi_0_10s_upper - hdi_0_10s_lower,
      width_10_20s = hdi_10_20s_upper - hdi_10_20s_lower,
      width_20_60s = hdi_20_60s_upper - hdi_20_60s_lower
    ) %>%
    group_by(n_participants) %>%
    summarise(
      width_0_10s = mean(width_0_10s),
      width_10_20s = mean(width_10_20s),
      width_20_60s = mean(width_20_60s),
      .groups = "drop"
    )
  print(hdi_summary, n = Inf)

  summary_stats <- list(
    expected_n = expected_n,
    pct_never_decided = pct_never_decided,
    h2_support_rate = h2_support_rate,
    decision_summary = decision_summary
  )

  return(summary_stats)
}

# ============================================================================
# RUN ALL SCENARIOS
# ============================================================================

cat("Starting simulations for all scenarios...\n")
cat(sprintf("Settings: %d simulations per scenario, N = %s\n",
            n_sims, paste(n_samples, collapse = ", ")))
cat(sprintf("ROPE: [%.2f, %.2f]\n", rope_lower, rope_upper))
cat(sprintf("Estimated runtime: ~45-90 minutes total\n\n"))

all_scenario_results <- list()
all_summaries <- list()

for (scenario_name in names(scenarios)) {

  start_time <- Sys.time()

  scenario <- scenarios[[scenario_name]]
  results <- run_scenario_simulation(scenario, n_sims, n_samples,
                                     scenario_key  = scenario_name,
                                     dir_checkpoint = dir_checkpoint)

  # Save scenario results
  all_scenario_results[[scenario_name]] <- results

  # Analyze
  summary <- analyze_scenario_results(results, scenario$name)
  all_summaries[[scenario_name]] <- summary

  # Save individual scenario — canonical file (read by QMD) plus timestamped archive copy
  rds_canonical <- file.path(dir_rds, sprintf("simulation_results_%s.rds", scenario_name))
  csv_canonical <- file.path(dir_csv, sprintf("simulation_results_%s.csv", scenario_name))
  saveRDS(results, rds_canonical)
  write_csv(results, csv_canonical)

  # Archive: never overwritten, one file per run
  saveRDS(results, file.path(dir_archive, sprintf("simulation_results_%s_%s.rds", scenario_name, run_ts)))
  write_csv(results, file.path(dir_archive, sprintf("simulation_results_%s_%s.csv", scenario_name, run_ts)))
  cat(sprintf("  Archived to: simulation_results_%s_%s.{csv,rds}\n", scenario_name, run_ts))

  end_time <- Sys.time()
  runtime <- difftime(end_time, start_time, units = "mins")
  cat(sprintf("\nScenario completed in %.1f minutes\n", runtime))
}

# ============================================================================
# COMPARATIVE SUMMARY ACROSS SCENARIOS
# ============================================================================

cat("\n\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\nCOMPARATIVE SUMMARY ACROSS ALL SCENARIOS\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\n\n")

comparison <- tibble(
  scenario = names(scenarios),
  effect_0_10s = map_dbl(scenarios, ~.x$effect_sizes$effect_d[1]),
  effect_10_20s = map_dbl(scenarios, ~.x$effect_sizes$effect_d[2]),
  effect_20_60s = map_dbl(scenarios, ~.x$effect_sizes$effect_d[3]),
  expected_n = map_dbl(all_summaries, ~.x$expected_n),
  pct_never_decided = map_dbl(all_summaries, ~.x$pct_never_decided),
  h2_support_rate = map_dbl(all_summaries, ~.x$h2_support_rate)
)

cat("Summary Table:\n")
print(comparison, n = Inf)

cat("\n\nInterpretation:\n")
cat("- Expected N: Average sample size needed in sequential design\n")
cat("- % Never Decided: Simulations still undecided at N=120\n")
cat("- H2 Support Rate: % of decided simulations supporting H2\n")

# Embed metadata columns into comparison so the CSV is self-documenting
comparison_with_meta <- bind_cols(comparison, run_metadata)

# Save combined results (canonical)
saveRDS(all_scenario_results, file.path(dir_rds, "all_scenarios_results.rds"))
saveRDS(all_summaries,        file.path(dir_rds, "all_scenarios_summaries.rds"))
write_csv(comparison_with_meta, file.path(dir_csv, "scenario_comparison.csv"))
write_csv(run_metadata,         file.path(dir_csv, "run_metadata.csv"))
saveRDS(run_metadata,           file.path(dir_rds, "run_metadata.rds"))

# Save combined results (timestamped archive)
saveRDS(all_scenario_results, file.path(dir_archive, sprintf("all_scenarios_results_%s.rds", run_ts)))
saveRDS(all_summaries,        file.path(dir_archive, sprintf("all_scenarios_summaries_%s.rds", run_ts)))
write_csv(comparison_with_meta, file.path(dir_archive, sprintf("scenario_comparison_%s.csv", run_ts)))
write_csv(run_metadata,         file.path(dir_archive, sprintf("run_metadata_%s.csv", run_ts)))
saveRDS(run_metadata,           file.path(dir_archive, sprintf("run_metadata_%s.rds", run_ts)))

cat("\n\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\nSIMULATION COMPLETE!\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\n\nFiles saved:\n")
cat("  - simulation_results_optimistic.csv/rds\n")
cat("  - simulation_results_realistic.csv/rds\n")
cat("  - simulation_results_conservative.csv/rds\n")
cat("  - scenario_comparison.csv  (includes metadata columns)\n")
cat("  - run_metadata.csv/rds\n")
cat("  - all_scenarios_results.rds\n")
cat("  - all_scenarios_summaries.rds\n")
cat("  - archive/ timestamped copies of all files\n")
cat("\n")
