# ============================================================================
# RAMSES CLUSTER CONFIGURATION
# Sourced automatically when SIMULATION_PROFILE=ramses (set by slurm script).
# Node spec: 192 CPUs, 768 GB RAM (smp partition).
# ============================================================================

# --- Simulation scale ---
n_sims              <- 100L          # More sims = tighter Monte Carlo error
n_samples           <- seq(30, 120, by = 15)  # 30,45,60,75,90,105,120
n_items_per_condition <- 10L

# --- ROPE ---
rope_lower <- -0.10
rope_upper <-  0.10

# --- Parallelism ---
# 16 workers × ~2 GB each = ~32 GB peak; 64 GB requested gives comfortable headroom.
# Each worker runs 2 MCMC chains sequentially on 1 core.
max_workers_override <- 16L          # overrides env-var detection in run script

# --- MCMC ---
mcmc_chains <- 2L
mcmc_iter   <- 1000L   # 500 warmup + 500 samples; sufficient for ROPE decisions

cat(sprintf("  [config] Profile  : ramses\n"))
cat(sprintf("  [config] n_sims   : %d\n", n_sims))
cat(sprintf("  [config] n_samples: %s\n", paste(n_samples, collapse = ",")))
cat(sprintf("  [config] ROPE     : [%.2f, %.2f]\n", rope_lower, rope_upper))
cat(sprintf("  [config] workers  : %d  |  chains: %d  |  iter: %d\n",
            max_workers_override, mcmc_chains, mcmc_iter))
