# Fast Test Script for Simulation Environment
# Run this inside your Docker container or on the HPC to verify setup.
# Usage: Rscript scripts/test_simulation_fast.R

cat("\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\nFAST ENVIRONMENT TEST\n")
cat("Checking libraries and running a minimal brms model...\n")
cat(paste0(rep("=", 80), collapse = ""))
cat("\n\n")

# 1. Load packages
tryCatch({
  cat("[1/3] Loading packages...\n")
  suppressPackageStartupMessages({
    library(brms)
    library(tidyverse)
    library(bayestestR)
  })
  cat("  -> Success: All packages loaded.\n")
}, error = function(e) {
  cat("  -> FAILED: Could not load packages.\n")
  stop(e)
})

# 2. Simulate tiny dataset
cat("\n[2/3] Simulating tiny dataset...\n")
set.seed(123)
data <- tibble(
  y = rnorm(30),
  x = rnorm(30),
  group = rep(1:3, 10)
)
cat("  -> Success: Data created.\n")

# 3. Fit minimal model
cat("\n[3/3] Fitting minimal brms model (chains=1, iter=100)...\n")
tryCatch({
  start_time <- Sys.time()
  
  model <- brm(
    y ~ x + (1|group), 
    data = data,
    chains = 1, 
    iter = 100, 
    refresh = 0,
    silent = 2,
    seed = 123,
    backend = "rstan" # Ensure rstan backend works
  )
  
  end_time <- Sys.time()
  cat(sprintf("  -> Success: Model fitted in %.1f seconds.\n", 
              difftime(end_time, start_time, units = "secs")))
  
  print(summary(model))
  
  cat("\n")
  cat(paste0(rep("=", 80), collapse = ""))
  cat("\nTEST COMPLETED SUCCESSFULLY\n")
  cat("Environment is ready for full simulation.\n")
  cat(paste0(rep("=", 80), collapse = ""))
  cat("\n")
  
}, error = function(e) {
  cat("\n  -> FAILED: Model fitting crashed.\n")
  cat("  Error message:\n")
  print(e)
  quit(status = 1)
})
