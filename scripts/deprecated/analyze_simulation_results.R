#!/usr/bin/env Rscript

# Purpose: Analyze simulation results (command-line version)
# Usage: Rscript scripts/analyze_simulation_results.R

# Ensure we're in the project root
if (!dir.exists("data/csv")) {
  stop("Error: 'data/csv' directory not found. Please run this script from the project root (e.g., ~/temp/random).")
}

# Source the data loader
source("scripts/load_results.R")

# 1. Load Data
cat("----------------------------------------------------------------\n")
cat("LOADING SIMULATION RESULTS\n")
cat("----------------------------------------------------------------\n")

# Use the centralized loader
all_results <- load_simulation_results(data_dir = "data/csv")

if (nrow(all_results) == 0) {
  stop("No simulation data found in data/csv/.")
}

cat(sprintf("\nSuccessfully loaded %d simulation runs across %d scenarios.\n", 
            nrow(all_results), n_distinct(all_results$scenario)))

# 2. Print Summaries per Scenario
cat("\n----------------------------------------------------------------\n")
cat("SCENARIO SUMMARIES\n")
cat("----------------------------------------------------------------\n")

scenarios <- unique(all_results$scenario)

for (scen in scenarios) {
  cat(sprintf("\n=== SCENARIO: %s ===\n", toupper(scen)))
  
  subset_data <- all_results %>% filter(scenario == scen)
  
  # Calculate key stats
  n_sims <- nrow(subset_data)
  expected_n <- mean(subset_data$n_participants)
  h2_support <- mean(subset_data$h2_supported) * 100
  
  # Effect sizes (0-10s window is key)
  mean_effect <- mean(subset_data$mean_0_10s)
  sd_effect <- sd(subset_data$mean_0_10s)
  
  cat(sprintf("  Simulations:   %d\n", n_sims))
  cat(sprintf("  Expected N:    %.1f participants\n", expected_n))
  cat(sprintf("  H2 Supported:  %.1f%%\n", h2_support))
  cat(sprintf("  Mean Effect (0-10s): %.3f (SD=%.3f)\n", mean_effect, sd_effect))
}

# 3. Create Basic Visualization (PNG)
cat("\n----------------------------------------------------------------\n")
cat("GENERATING PLOTS\n")
cat("----------------------------------------------------------------\n")

output_file <- "figures/simulation_summary_plot.png"
if (!dir.exists("figures")) dir.create("figures")

png(output_file, width = 1000, height = 600, res = 100)
par(mfrow = c(1, 2), mar = c(5, 4, 4, 1))

# Plot 1: Expected Sample Size
boxplot(n_participants ~ scenario, data = all_results,
        main = "Sample Size Distribution by Scenario",
        ylab = "Number of Participants (N)",
        col = c("#1f77b4", "#ff7f0e", "#2ca02c"),
        las = 1)
grid()

# Plot 2: Effect Size (0-10s)
boxplot(mean_0_10s ~ scenario, data = all_results,
        main = "Effect Size Distribution (0-10s)",
        ylab = "Mean Effect Size (Cohen's d)",
        col = c("#1f77b4", "#ff7f0e", "#2ca02c"),
        las = 1)
abline(h = 0, lty = 2, col = "gray")
grid()

dev.off()

cat(sprintf("Saved summary plot to: %s\n", output_file))

cat("\nAnalysis Complete!\n")
