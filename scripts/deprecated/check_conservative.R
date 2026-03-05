#!/usr/bin/env Rscript

.libPaths(c(Sys.getenv('R_LIBS_USER'), .libPaths()))

setwd("c:/GitHub/temp/random")

conservative <- read.csv("simulation_results_conservative.csv")
rope_lower <- -0.05
rope_upper <- 0.05

cat("Conservative 0-10s window:\n")
cat("Mean:", round(mean(conservative$mean_0_10s), 4), "\n")
cat("Median:", round(median(conservative$mean_0_10s), 4), "\n")
cat("SD:", round(sd(conservative$mean_0_10s), 4), "\n")
cat("Min:", round(min(conservative$mean_0_10s), 4), "\n")
cat("Max:", round(max(conservative$mean_0_10s), 4), "\n")
cat("\n")
cat(sprintf("ROPE bounds: [%.2f, +%.2f]\n", rope_lower, rope_upper))
cat("Are effects within ROPE?\n")
cat("All within?", all(conservative$mean_0_10s >= rope_lower & conservative$mean_0_10s <= rope_upper), "\n")
cat("Proportion within ROPE:", sum(conservative$mean_0_10s >= rope_lower & conservative$mean_0_10s <= rope_upper) / nrow(conservative), "\n")
