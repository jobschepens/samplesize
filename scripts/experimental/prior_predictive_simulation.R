# Prior Predictive Simulation for Bayesian Sequential Design with ROPE
# Iconic Duration Effect Study
# Date: February 4, 2026

# Purpose: Estimate decision rates at N=60, 90, 120 for sequential ROPE design
# Research Question: At what sample size can we make clear ROPE decisions?

# Load required packages
library(brms)
library(tidyverse)
library(faux)  # For simulating correlated data
library(bayestestR)  # For HDI and ROPE functions

# Set seed for reproducibility
set.seed(2026)

# ============================================================================
# SIMULATION PARAMETERS
# ============================================================================

# Sample sizes to test
n_samples <- c(60, 90, 120)

# Number of participants per Latin square list
n_per_list <- 2

# Duration bins
duration_bins <- c("bin_0_10s", "bin_10_20s", "bin_20_60s")

# Number of items per condition (from collaborator baseline)
n_items_per_condition <- 10

# Number of simulation iterations
n_sims <- 100  # Start with 100, increase to 1000 for final analysis

# ROPE boundaries (on log scale)
rope_lower <- -0.05
rope_upper <- 0.05

# ============================================================================
# EFFECT SIZES (Based on H2 hypothesis)
# ============================================================================

# emmeans contrasts (from emmeans.txt):
# contrasts are (short - long), so we flip sign to encode (long - short)
# short: -0.39168, medium: -0.01512, long: -0.00223
pilot_effect_short <- 0.39168
pilot_effect_medium <- 0.01512
pilot_effect_long <- 0.00223

# Map pilot durations to 3 simulation bins
# Instant is excluded per current analysis plan.
pilot_effect_0_10s <- pilot_effect_short
pilot_effect_10_20s <- pilot_effect_medium
pilot_effect_20_60s <- pilot_effect_long

effect_sizes <- tibble(
  duration_bin = duration_bins,
  # Effect of sentence length (long - short) in each bin
  effect_d = c(
    pilot_effect_0_10s,
    pilot_effect_10_20s,
    pilot_effect_20_60s
  )
)

# Within-subjects correlation (typical for repeated measures)
within_corr <- 0.5

# Residual SD on log scale (typical for log-transformed RT/duration data)
sigma_residual <- 0.35

# Random effects SDs (on log scale)
sd_participant_intercept <- 0.25
sd_item_intercept <- 0.15
sd_participant_slope <- 0.10  # For sentence length effect

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
  
  # Generate participant IDs (balanced across 2 lists)
  participants <- tibble(
    participant_id = 1:n_participants,
    list = rep(1:2, length.out = n_participants),
    # Random intercept for each participant
    participant_intercept = rnorm(n_participants, 0, sd_participant_intercept),
    # Random slope for sentence length effect
    participant_slope = rnorm(n_participants, 0, sd_participant_slope)
  )
  
  # Generate items
  n_items_total <- n_items_per_condition * 2 * 3  # 2 sentence lengths × 3 bins
  items <- tibble(
    item_id = 1:n_items_total,
    # Random intercept for each item
    item_intercept = rnorm(n_items_total, 0, sd_item_intercept)
  )
  
  # Create full design (all participants see all items in within-subjects design)
  data <- expand_grid(
    participant_id = participants$participant_id,
    duration_bin = duration_bins,
    sentence_length = c("short", "long")
  ) %>%
    # Add item assignment (simplified - in real study would depend on Latin square)
    group_by(participant_id, duration_bin, sentence_length) %>%
    mutate(
      item_id = sample(1:n_items_total, n_items_per_condition, replace = FALSE)
    ) %>%
    ungroup() %>%
    # Expand to have one row per trial
    unnest(item_id = item_id) %>%
    # Join participant and item random effects
    left_join(participants, by = "participant_id") %>%
    left_join(items, by = "item_id") %>%
    # Join effect sizes
    left_join(effect_sizes, by = "duration_bin")
  
  # Generate log-transformed durations
  data <- data %>%
    mutate(
      # Sentence length effect (0 for short, effect_d for long)
      sentence_effect = if_else(sentence_length == "long", 
                                effect_d, 
                                0),
      
      # Base log duration (around log(15) ≈ 2.7)
      baseline_log_duration = 2.7,
      
      # Add bin-specific adjustments
      bin_adjustment = case_when(
        duration_bin == "bin_0_10s" ~ -0.5,   # ~6 seconds baseline
        duration_bin == "bin_10_20s" ~ 0.0,   # ~15 seconds baseline  
        duration_bin == "bin_20_60s" ~ 0.7    # ~30 seconds baseline
      ),
      
      # Individual-level slope adjustment
      individual_sentence_effect = sentence_effect + participant_slope,
      
      # Calculate log duration
      log_duration = baseline_log_duration + 
                     bin_adjustment +
                     individual_sentence_effect +
                     participant_intercept +
                     item_intercept +
                     rnorm(n(), 0, sigma_residual),
      
      # Convert back to seconds for realism check
      duration_seconds = exp(log_duration)
    ) %>%
    # Convert to factors for modeling
    mutate(
      participant_id = factor(participant_id),
      item_id = factor(item_id),
      sentence_length = factor(sentence_length, levels = c("short", "long")),
      duration_bin = factor(duration_bin, levels = duration_bins)
    )
  
  return(data)
}

# ============================================================================
# BAYESIAN MODEL FITTING FUNCTION
# ============================================================================

fit_bayesian_model <- function(data, chains = 2, iter = 2000, cores = 2) {
  
  # Specify priors (weakly informative)
  priors <- c(
    prior(normal(2.7, 1.5), class = Intercept),
    prior(normal(0, 0.5), class = b),
    prior(exponential(1), class = sd),
    prior(exponential(1), class = sigma),
    prior(lkj(2), class = cor)
  )
  
  # Fit model
  # Using simplified random effects structure for simulation speed
  # In actual analysis, use maximal structure: (1 + sentence_length | participant)
  model <- brm(
    log_duration ~ sentence_length * duration_bin + 
                   (1 | participant_id) + 
                   (1 | item_id),
    data = data,
    prior = priors,
    chains = chains,
    iter = iter,
    cores = cores,
    silent = 2,
    refresh = 0,
    seed = 2026,
    backend = "cmdstanr"  # Faster than rstan, remove if not available
  )
  
  return(model)
}

# ============================================================================
# ROPE DECISION FUNCTION
# ============================================================================

check_rope_decision <- function(model, rope_lower = -0.05, rope_upper = 0.05) {
  
  # Extract simple effects of sentence length within each duration bin
  # Get posterior samples
  posterior <- as_draws_df(model)
  
  # Calculate simple effects for each bin
  # Main effect of sentence length
  sent_length_effect <- posterior$b_sentence_lengthlong
  
  # Interaction terms (duration bin effects)
  int_10_20 <- posterior$`b_sentence_lengthlong:duration_binbin_10_20s`
  int_20_60 <- posterior$`b_sentence_lengthlong:duration_binbin_20_60s`
  
  # Simple effects in each bin
  # bin_0_10s is reference, so simple effect = main effect
  effect_0_10s <- sent_length_effect
  
  # bin_10_20s: add interaction
  effect_10_20s <- sent_length_effect + int_10_20
  
  # bin_20_60s: add interaction  
  effect_20_60s <- sent_length_effect + int_20_60
  
  # Calculate 95% HDI for each simple effect
  hdi_0_10s <- hdi(effect_0_10s, ci = 0.95)
  hdi_10_20s <- hdi(effect_10_20s, ci = 0.95)
  hdi_20_60s <- hdi(effect_20_60s, ci = 0.95)
  
  # Make ROPE decisions
  decision_0_10s <- case_when(
    hdi_0_10s$CI_low > rope_upper ~ "PRESENT",
    hdi_0_10s$CI_high < rope_lower ~ "ABSENT_NEGATIVE",
    hdi_0_10s$CI_low >= rope_lower & hdi_0_10s$CI_high <= rope_upper ~ "ABSENT",
    TRUE ~ "UNDECIDED"
  )
  
  decision_10_20s <- case_when(
    hdi_10_20s$CI_low > rope_upper ~ "PRESENT",
    hdi_10_20s$CI_high < rope_lower ~ "ABSENT_NEGATIVE",
    hdi_10_20s$CI_low >= rope_lower & hdi_10_20s$CI_high <= rope_upper ~ "ABSENT",
    TRUE ~ "UNDECIDED"
  )
  
  decision_20_60s <- case_when(
    hdi_20_60s$CI_low > rope_upper ~ "PRESENT",
    hdi_20_60s$CI_high < rope_lower ~ "ABSENT_NEGATIVE",
    hdi_20_60s$CI_low >= rope_lower & hdi_20_60s$CI_high <= rope_upper ~ "ABSENT",
    TRUE ~ "UNDECIDED"
  )
  
  # Check if H2 is supported (PRESENT in 0-10s AND ABSENT in 20-60s)
  h2_supported <- (decision_0_10s == "PRESENT") & 
                  (decision_20_60s %in% c("ABSENT", "ABSENT_NEGATIVE"))
  
  # Overall decision (can we stop collecting data?)
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
    # Also store HDI bounds for reporting
    hdi_0_10s_lower = hdi_0_10s$CI_low,
    hdi_0_10s_upper = hdi_0_10s$CI_high,
    hdi_10_20s_lower = hdi_10_20s$CI_low,
    hdi_10_20s_upper = hdi_10_20s$CI_high,
    hdi_20_60s_lower = hdi_20_60s$CI_low,
    hdi_20_60s_upper = hdi_20_60s$CI_high,
    # Store means too
    mean_0_10s = mean(effect_0_10s),
    mean_10_20s = mean(effect_10_20s),
    mean_20_60s = mean(effect_20_60s)
  )
  
  return(results)
}

# ============================================================================
# MAIN SIMULATION LOOP
# ============================================================================

run_simulation <- function(n_sims = 100, n_samples = c(60, 90, 120)) {
  
  cat("Starting prior predictive simulation...\n")
  cat(sprintf("Running %d simulations for sample sizes: %s\n", 
              n_sims, paste(n_samples, collapse = ", ")))
  
  # Store results
  all_results <- tibble()
  
  for (sim in 1:n_sims) {
    
    cat(sprintf("\n=== Simulation %d/%d ===\n", sim, n_sims))
    
    # Simulate data for maximum sample size
    max_n <- max(n_samples)
    data_full <- simulate_duration_data(
      n_participants = max_n,
      n_items_per_condition = n_items_per_condition,
      effect_sizes = effect_sizes,
      sigma_residual = sigma_residual,
      sd_participant_intercept = sd_participant_intercept,
      sd_item_intercept = sd_item_intercept,
      sd_participant_slope = sd_participant_slope
    )
    
    # Test each sample size sequentially
    for (n in n_samples) {
      
      cat(sprintf("  Testing N = %d...\n", n))
      
      # Subset data to current sample size
      data_subset <- data_full %>%
        filter(as.numeric(as.character(participant_id)) <= n)
      
      # Fit Bayesian model
      tryCatch({
        model <- fit_bayesian_model(data_subset, chains = 2, iter = 2000, cores = 2)
        
        # Check ROPE decisions
        decisions <- check_rope_decision(model, rope_lower, rope_upper)
        
        # Store results
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
        
        all_results <- bind_rows(all_results, result)
        
        cat(sprintf("    Decision: %s (H2: %s)\n", 
                    result$overall_decision, 
                    ifelse(result$h2_supported, "Supported", "Not Supported")))
        
        # If decided at this N, don't test larger N (mimics sequential design)
        if (result$overall_decision == "DECIDED") {
          cat("    → Clear decision reached, would stop here in sequential design\n")
          break
        }
        
      }, error = function(e) {
        cat(sprintf("    ERROR: %s\n", e$message))
      })
    }
  }
  
  return(all_results)
}

# ============================================================================
# ANALYSIS OF SIMULATION RESULTS
# ============================================================================

analyze_simulation_results <- function(results) {
  
  cat("\n\n" %>% paste0(rep("=", 70), collapse = "") %>% paste0("\n"))
  cat("SIMULATION RESULTS SUMMARY\n")
  cat(paste0(rep("=", 70), collapse = "") %>% paste0("\n\n"))
  
  # For sequential design: find the first N where decision was made for each sim
  sequential_results <- results %>%
    group_by(sim_id) %>%
    filter(overall_decision == "DECIDED") %>%
    slice_min(n_participants, n = 1, with_ties = FALSE) %>%
    ungroup()
  
  # How many sims decided at each N?
  decision_rates <- sequential_results %>%
    group_by(n_participants) %>%
    summarise(
      n_decided = n(),
      pct_decided = n() / n_distinct(results$sim_id) * 100,
      n_h2_supported = sum(h2_supported),
      pct_h2_supported = sum(h2_supported) / n() * 100
    )
  
  cat("Sequential Design Decision Rates:\n")
  cat("(% of simulations that reached clear decision at each stage)\n\n")
  print(decision_rates, n = Inf)
  
  # Expected sample size
  expected_n <- mean(sequential_results$n_participants)
  cat(sprintf("\nExpected sample size: %.1f participants\n", expected_n))
  
  # How many simulations never decided?
  never_decided <- n_distinct(results$sim_id) - nrow(sequential_results)
  pct_never_decided <- never_decided / n_distinct(results$sim_id) * 100
  cat(sprintf("Simulations undecided at N_max: %d (%.1f%%)\n", 
              never_decided, pct_never_decided))
  
  # H2 support rate (among decided simulations)
  h2_support_rate <- sum(sequential_results$h2_supported) / nrow(sequential_results) * 100
  cat(sprintf("\nH2 supported (among decided): %.1f%%\n", h2_support_rate))
  
  # Decision patterns by bin and N
  cat("\n\n" %>% paste0(rep("-", 70), collapse = "") %>% paste0("\n"))
  cat("Decision Patterns by Bin and Sample Size\n")
  cat(paste0(rep("-", 70), collapse = "") %>% paste0("\n\n"))
  
  for (n in unique(results$n_participants)) {
    cat(sprintf("\nN = %d:\n", n))
    
    n_results <- results %>% filter(n_participants == n)
    
    cat(sprintf("  0-10s bin:  PRESENT: %d (%.0f%%), ABSENT: %d (%.0f%%), UNDECIDED: %d (%.0f%%)\n",
                sum(n_results$decision_0_10s == "PRESENT"),
                mean(n_results$decision_0_10s == "PRESENT") * 100,
                sum(n_results$decision_0_10s %in% c("ABSENT", "ABSENT_NEGATIVE")),
                mean(n_results$decision_0_10s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                sum(n_results$decision_0_10s == "UNDECIDED"),
                mean(n_results$decision_0_10s == "UNDECIDED") * 100))
    
    cat(sprintf("  10-20s bin: PRESENT: %d (%.0f%%), ABSENT: %d (%.0f%%), UNDECIDED: %d (%.0f%%)\n",
                sum(n_results$decision_10_20s == "PRESENT"),
                mean(n_results$decision_10_20s == "PRESENT") * 100,
                sum(n_results$decision_10_20s %in% c("ABSENT", "ABSENT_NEGATIVE")),
                mean(n_results$decision_10_20s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                sum(n_results$decision_10_20s == "UNDECIDED"),
                mean(n_results$decision_10_20s == "UNDECIDED") * 100))
    
    cat(sprintf("  20-60s bin: PRESENT: %d (%.0f%%), ABSENT: %d (%.0f%%), UNDECIDED: %d (%.0f%%)\n",
                sum(n_results$decision_20_60s == "PRESENT"),
                mean(n_results$decision_20_60s == "PRESENT") * 100,
                sum(n_results$decision_20_60s %in% c("ABSENT", "ABSENT_NEGATIVE")),
                mean(n_results$decision_20_60s %in% c("ABSENT", "ABSENT_NEGATIVE")) * 100,
                sum(n_results$decision_20_60s == "UNDECIDED"),
                mean(n_results$decision_20_60s == "UNDECIDED") * 100))
  }
  
  # HDI width analysis
  cat("\n\n" %>% paste0(rep("-", 70), collapse = "") %>% paste0("\n"))
  cat("HDI Width (Precision) by Sample Size\n")
  cat(paste0(rep("-", 70), collapse = "") %>% paste0("\n\n"))
  
  hdi_width_summary <- results %>%
    mutate(
      hdi_width_0_10s = hdi_0_10s_upper - hdi_0_10s_lower,
      hdi_width_10_20s = hdi_10_20s_upper - hdi_10_20s_lower,
      hdi_width_20_60s = hdi_20_60s_upper - hdi_20_60s_lower
    ) %>%
    group_by(n_participants) %>%
    summarise(
      mean_width_0_10s = mean(hdi_width_0_10s),
      mean_width_10_20s = mean(hdi_width_10_20s),
      mean_width_20_60s = mean(hdi_width_20_60s)
    )
  
  cat("Mean 95% HDI width (log scale):\n")
  print(hdi_width_summary, n = Inf)
  
  cat(sprintf("\nNote: ROPE width = %.2f (from %.2f to %.2f)\n", 
              rope_upper - rope_lower, rope_lower, rope_upper))
  cat("Narrower HDI width = better precision for ROPE decisions\n")
  
  return(list(
    decision_rates = decision_rates,
    sequential_results = sequential_results,
    expected_n = expected_n,
    pct_never_decided = pct_never_decided,
    h2_support_rate = h2_support_rate
  ))
}

# ============================================================================
# VISUALIZATION FUNCTIONS
# ============================================================================

plot_simulation_results <- function(results) {
  
  # 1. Decision rates over sample sizes
  p1 <- results %>%
    group_by(n_participants, overall_decision) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(n_participants) %>%
    mutate(pct = n / sum(n) * 100) %>%
    ggplot(aes(x = factor(n_participants), y = pct, fill = overall_decision)) +
    geom_col(position = "stack") +
    scale_fill_manual(values = c("DECIDED" = "#2ECC71", "UNDECIDED" = "#E74C3C")) +
    labs(
      title = "ROPE Decision Rates by Sample Size",
      subtitle = "Percentage of simulations reaching clear decisions",
      x = "Sample Size (N participants)",
      y = "Percentage",
      fill = "Overall Decision"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "top")
  
  # 2. HDI distributions
  p2 <- results %>%
    select(sim_id, n_participants, starts_with("mean_")) %>%
    pivot_longer(cols = starts_with("mean_"), 
                 names_to = "bin", 
                 values_to = "effect") %>%
    mutate(bin = str_remove(bin, "mean_") %>% str_replace_all("_", " ")) %>%
    ggplot(aes(x = effect, fill = factor(n_participants))) +
    geom_density(alpha = 0.5) +
    geom_vline(xintercept = c(rope_lower, rope_upper), 
               linetype = "dashed", color = "red", size = 1) +
    facet_wrap(~ bin, ncol = 1) +
    labs(
      title = "Posterior Mean Distributions by Duration Bin",
      subtitle = "Red lines = ROPE boundaries",
      x = "Sentence Length Effect (log scale)",
      y = "Density",
      fill = "Sample Size"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "top")
  
  # 3. HDI width over sample size
  p3 <- results %>%
    mutate(
      hdi_width_0_10s = hdi_0_10s_upper - hdi_0_10s_lower,
      hdi_width_10_20s = hdi_10_20s_upper - hdi_10_20s_lower,
      hdi_width_20_60s = hdi_20_60s_upper - hdi_20_60s_lower
    ) %>%
    select(sim_id, n_participants, starts_with("hdi_width")) %>%
    pivot_longer(cols = starts_with("hdi_width"), 
                 names_to = "bin", 
                 values_to = "width") %>%
    mutate(bin = str_remove(bin, "hdi_width_") %>% str_replace_all("_", " ")) %>%
    ggplot(aes(x = factor(n_participants), y = width, fill = bin)) +
    geom_boxplot() +
    geom_hline(yintercept = rope_upper - rope_lower, 
               linetype = "dashed", color = "red", size = 1) +
    labs(
      title = "HDI Width (Precision) by Sample Size",
      subtitle = "Red line = ROPE width. Narrower HDI = better precision",
      x = "Sample Size (N participants)",
      y = "95% HDI Width (log scale)",
      fill = "Duration Bin"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "top")
  
  # Save plots
  ggsave("prior_pred_sim_decision_rates.png", p1, width = 8, height = 6, dpi = 300)
  ggsave("prior_pred_sim_posteriors.png", p2, width = 8, height = 10, dpi = 300)
  ggsave("prior_pred_sim_precision.png", p3, width = 8, height = 6, dpi = 300)
  
  cat("\nPlots saved:\n")
  cat("  - prior_pred_sim_decision_rates.png\n")
  cat("  - prior_pred_sim_posteriors.png\n")
  cat("  - prior_pred_sim_precision.png\n")
  
  return(list(p1 = p1, p2 = p2, p3 = p3))
}

# ============================================================================
# RUN THE SIMULATION
# ============================================================================

cat("\n")
cat(paste0(rep("=", 70), collapse = ""))
cat("\nPRIOR PREDICTIVE SIMULATION FOR BAYESIAN SEQUENTIAL DESIGN\n")
cat(paste0(rep("=", 70), collapse = ""))
cat("\n\n")

cat("Study: Iconic Duration Effect - Cut-off Point Experiment\n")
cat("Design: 2x3 within-subjects (Sentence Length x Event Duration)\n")
cat(sprintf("ROPE: [%.2f, %.2f] on log scale\n", 
            rope_lower, rope_upper))
cat(sprintf("Sequential sampling: N = %s\n", paste(n_samples, collapse = ", ")))
cat(sprintf("Simulations: %d\n", n_sims))
cat("\n")

cat("Effect sizes (Cohen's d) under H2:\n")
print(effect_sizes)
cat("\n")

cat("WARNING: This simulation can take 1-3 hours for 100 iterations.\n")
cat("Consider starting with n_sims = 10 for testing, then increase to 100-1000.\n\n")

# Uncomment to run:
# results <- run_simulation(n_sims = n_sims, n_samples = n_samples)
# 
# # Analyze results
# summary <- analyze_simulation_results(results)
# 
# # Create plots
# plots <- plot_simulation_results(results)
# 
# # Save results
# saveRDS(results, "prior_predictive_simulation_results.rds")
# write_csv(results, "prior_predictive_simulation_results.csv")
# 
# cat("\n\nSimulation complete! Results saved.\n")

cat("\n\nTo run the simulation, uncomment the code at the end of this script.\n")
cat("Recommended: Start with n_sims = 10 to test, then increase to 100+.\n")

