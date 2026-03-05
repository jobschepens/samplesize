# ============================================================================
# LOCAL / HOME PC CONFIGURATION
# Sourced automatically when SIMULATION_PROFILE=local (or unset).
# Tuned for a typical 8-16 core desktop with 16-32 GB RAM.
# ============================================================================

# --- Simulation scale ---
# Keep n_sims=50 for a proper run; drop to 10 for a quick smoke-test.
n_sims              <- 50L
n_samples           <- seq(30, 120, by = 15)  # 30,45,60,75,90,105,120
n_items_per_condition <- 10L

# --- ROPE ---
rope_lower <- -0.10
rope_upper <-  0.10

# --- Parallelism ---
# 4 workers × ~2 GB = ~8 GB peak; safe on a 16 GB machine.
# Raise to 6 if you have 32 GB RAM.
max_workers_override <- 4L

# --- MCMC ---
mcmc_chains <- 2L
mcmc_iter   <- 1000L   # reduce to 500 for a quick local smoke-test

cat(sprintf("  [config] Profile  : local\n"))
cat(sprintf("  [config] n_sims   : %d\n", n_sims))
cat(sprintf("  [config] n_samples: %s\n", paste(n_samples, collapse = ",")))
cat(sprintf("  [config] ROPE     : [%.2f, %.2f]\n", rope_lower, rope_upper))
cat(sprintf("  [config] workers  : %d  |  chains: %d  |  iter: %d\n",
            max_workers_override, mcmc_chains, mcmc_iter))
