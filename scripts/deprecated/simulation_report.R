#!/usr/bin/env Rscript

setwd("c:/GitHub/temp/random")

# Load data
conservative <- read.csv("simulation_results_conservative.csv")
realistic <- read.csv("simulation_results_realistic.csv")
optimistic <- read.csv("simulation_results_optimistic.csv")

# Create comparison table
comparison <- data.frame(
  Scenario = c("Conservative", "Realistic", "Optimistic"),
  N_Simulations = c(nrow(conservative), nrow(realistic), nrow(optimistic)),
  
  # Mean effect 0-10s
  Mean_Effect_0_10s = c(
    mean(conservative$mean_0_10s, na.rm = TRUE),
    mean(realistic$mean_0_10s, na.rm = TRUE),
    mean(optimistic$mean_0_10s, na.rm = TRUE)
  ),
  SD_Effect_0_10s = c(
    sd(conservative$mean_0_10s, na.rm = TRUE),
    sd(realistic$mean_0_10s, na.rm = TRUE),
    sd(optimistic$mean_0_10s, na.rm = TRUE)
  ),
  
  # Mean effect 10-20s
  Mean_Effect_10_20s = c(
    mean(conservative$mean_10_20s, na.rm = TRUE),
    mean(realistic$mean_10_20s, na.rm = TRUE),
    mean(optimistic$mean_10_20s, na.rm = TRUE)
  ),
  SD_Effect_10_20s = c(
    sd(conservative$mean_10_20s, na.rm = TRUE),
    sd(realistic$mean_10_20s, na.rm = TRUE),
    sd(optimistic$mean_10_20s, na.rm = TRUE)
  ),
  
  # Mean effect 20-60s
  Mean_Effect_20_60s = c(
    mean(conservative$mean_20_60s, na.rm = TRUE),
    mean(realistic$mean_20_60s, na.rm = TRUE),
    mean(optimistic$mean_20_60s, na.rm = TRUE)
  ),
  SD_Effect_20_60s = c(
    sd(conservative$mean_20_60s, na.rm = TRUE),
    sd(realistic$mean_20_60s, na.rm = TRUE),
    sd(optimistic$mean_20_60s, na.rm = TRUE)
  ),
  
  # H2 support rate
  H2_Support_Rate = c(
    mean(conservative$h2_supported, na.rm = TRUE) * 100,
    mean(realistic$h2_supported, na.rm = TRUE) * 100,
    mean(optimistic$h2_supported, na.rm = TRUE) * 100
  )
)

cat("\n=== COMPREHENSIVE SIMULATION COMPARISON ===\n\n")
print(comparison)

write.csv(comparison, "simulation_comprehensive_summary.csv", row.names = FALSE)

cat("\n\n=== SUMMARY SAVED ===\n")
cat("File: simulation_comprehensive_summary.csv\n")
