#!/usr/bin/env Rscript

.libPaths(c(Sys.getenv('R_LIBS_USER'), .libPaths()))

library(brms)
library(tidyverse)
library(bayestestR)

set.seed(2026)

# Parameters
n_sims <- 20  # Quick estimate with 20 sims per sample size
sample_sizes <- c(80, 120, 150, 200)
n_items_per_condition <- 10

# Target effect: 1 second = 0.104 on log scale
target_effect <- 0.104
target_rope <- c(-0.03, 0.03)  # Tighter ROPE

rope_lower <- target_rope[1]
rope_upper <- target_rope[2]

sigma_residual <- 0.35
sd_participant_intercept <- 0.25
sd_item_intercept <- 0.15
sd_participant_slope <- 0.10

# Simulation function
simulate_duration_data <- function(n_participants, effect_size) {
  
  duration_bins <- c("bin_0_10s", "bin_10_20s", "bin_20_60s")
  effect_sizes <- tibble(
    duration_bin = duration_bins,
    effect_d = c(effect_size, effect_size * 0.5, 0.00)
  )
  
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
    mutate(item_id = item_id + (as.numeric(factor(duration_bin)) - 1) * n_items_per_condition * 2) %>%
    left_join(items, by = "item_id") %>%
    left_join(effect_sizes, by = "duration_bin") %>%
    mutate(
      sentence_effect = if_else(sentence_length == "long", effect_d, 0),
      baseline_log_duration = 2.7,
      bin_adjustment = case_when(
        duration_bin == "bin_0_10s" ~ -0.5,
        duration_bin == "bin_10_20s" ~ 0.0,
        duration_bin == "bin_20_60s" ~ 0.7
      ),
      individual_sentence_effect = sentence_effect + participant_slope,
      log_duration = baseline_log_duration + bin_adjustment + individual_sentence_effect +
                     participant_intercept + item_intercept + rnorm(n(), 0, sigma_residual),
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

check_rope_decision <- function(model, rope_lower, rope_upper) {
  posterior <- as_draws_df(model)
  sent_length_effect <- posterior$b_sentence_lengthlong
  
  hdi_0_10s <- hdi(sent_length_effect, ci = 0.95)
  
  if (hdi_0_10s$CI_low > rope_upper) {
    return("PRESENT")
  } else if (hdi_0_10s$CI_high < rope_lower) {
    return("ABSENT")
  } else {
    return("UNDECIDED")
  }
}

cat("\n=== Estimating sample size for 1-second effect (0.10 log scale) ===\n")
cat("ROPE: ±0.03 on log scale\n\n")

results <- tibble()

for (n_p in sample_sizes) {
  cat(sprintf("Testing N=%d... ", n_p))
  
  decisions <- character(n_sims)
  
  for (i in 1:n_sims) {
    data <- simulate_duration_data(n_p, target_effect)
    
    model <- brm(
      log_duration ~ sentence_length + (1 | participant_id) + (1 | item_id),
      data = data,
      prior = c(
        prior(normal(2.7, 1.5), class = Intercept),
        prior(normal(0, 0.5), class = b),
        prior(exponential(1), class = sd),
        prior(exponential(1), class = sigma)
      ),
      chains = 2, iter = 2000, cores = 2,
      silent = 2, refresh = 0, seed = 2026 + i
    )
    
    decisions[i] <- check_rope_decision(model, rope_lower, rope_upper)
  }
  
  detection_rate <- sum(decisions == "PRESENT") / n_sims
  undecided_rate <- sum(decisions == "UNDECIDED") / n_sims
  
  cat(sprintf("Detection rate: %.0f%% (undecided: %.0f%%)\n", detection_rate * 100, undecided_rate * 100))
  
  results <- results %>%
    bind_rows(tibble(
      n_participants = n_p,
      detection_rate = detection_rate,
      undecided_rate = undecided_rate
    ))
}

cat("\n=== SUMMARY ===\n")
print(results)

best_n <- results %>% filter(detection_rate >= 0.80) %>% slice(1) %>% pull(n_participants)
if (length(best_n) > 0) {
  cat(sprintf("\nEstimated N for ~80%% detection: %d participants\n", best_n))
  cat(sprintf("(Compared to current N=60 for 0.25 effect size)\n"))
} else {
  cat("\nNote: May need even larger sample size for reliable detection\n")
}
