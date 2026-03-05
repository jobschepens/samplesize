#!/usr/bin/env Rscript

# From the simulation code
sigma_residual <- 0.35
baseline_log_duration <- 2.7

# Bin adjustments
bin_adj <- c(-0.5, 0.0, 0.7)

# Effect sizes on log scale (pilot-anchored scenarios)
# Realistic values are taken from emmeans contrasts:
# long-short = -1 * (short-long) for short/medium/long
pilot_effect_short <- 0.39168
pilot_effect_medium <- 0.01512
pilot_effect_long <- 0.00223
# Instant is excluded per current analysis plan.
pilot_effect_0_10s <- pilot_effect_short

effects <- list(
  conservative = c(pilot_effect_0_10s * 0.75, mean(c(pilot_effect_medium, pilot_effect_long)), 0.00),
  realistic = c(pilot_effect_0_10s, pilot_effect_medium, pilot_effect_long),
  optimistic = c(pilot_effect_0_10s * 1.15, pilot_effect_medium * 1.5, pilot_effect_long * 1.5)
)

# Calculate baseline durations in seconds
baseline_durations <- exp(baseline_log_duration + bin_adj)

cat('BASELINE DURATIONS (in seconds):\n')
cat('0-10s: ', round(baseline_durations[1], 1), 's\n')
cat('10-20s:', round(baseline_durations[2], 1), 's\n')
cat('20-60s:', round(baseline_durations[3], 1), 's\n')

# Effects are already specified on log scale
log_effects <- effects

# Calculate actual time differences for each scenario
cat('\n\nEFFECT SIZES IN SECONDS (LONG vs SHORT sentences):\n\n')

bin_names <- c('0-10s', '10-20s', '20-60s')

for (scenario in names(effects)) {
  cat(sprintf('%s scenario:\n', toupper(scenario)))
  
  for (i in 1:3) {
    bin <- bin_names[i]
    baseline <- baseline_durations[i]
    log_eff <- log_effects[[scenario]][i]
    
    # Effect in seconds (difference between long and short)
    time_diff <- baseline * (exp(log_eff) - 1)
    pct_change <- (exp(log_eff) - 1) * 100
    
    cat(sprintf('  %s: baseline ~%.1f s | effect ~%.2f s (~%.1f%% slower)\n', 
                bin, baseline, time_diff, pct_change))
  }
  cat('\n')
}

