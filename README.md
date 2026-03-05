# Bayesian Sample Size Simulation for Event Duration Study

[![Render Report](https://github.com/jobschepens/samplesize/actions/workflows/render-report.yml/badge.svg)](https://github.com/jobschepens/samplesize/actions/workflows/render-report.yml)

Prior predictive simulation for **sequential Bayesian sample size determination** using HDI/ROPE decisions on a mixed-effects model of event duration data. This project simulates a preregistered study on iconic duration effects in sentence interpretation, comparing four design scenarios anchored to pilot data.

**📊 [View the simulation report](https://jobschepens.github.io/samplesize/)**

## Project Overview

### Research Question
Does sentence length (short vs long) interact with event duration categories (0–10s, 10–20s, 20–60s) in reading times? **H2** predicts a present effect in short events and an absent effect in long events.

### Sequential Design
- **Sample sizes**: N = 30, 45, 60, 75, 90, 105, 120 (hard cap)
- **Decision rule**: HDI/ROPE on Bayesian mixed-effects model
  - **PRESENT**: 95% HDI entirely above ROPE (+0.10)
  - **ABSENT**: 95% HDI entirely inside ROPE (±0.10)
  - **Stop** when both 0–10s and 20–60s windows decide
- **Expected N**: 32–120 depending on scenario (optimistic → minimal)

### Scenarios
Four prior predictive scenarios explore sensitivity to pilot effect sizes:

| Scenario       | Effect 0–10s | Effect 20–60s | Description                                      |
|----------------|--------------|---------------|--------------------------------------------------|
| **Optimistic** | 0.451        | 0.003         | Strong early effect (pilot × 1.15)              |
| **Realistic**  | 0.392        | 0.002         | Pilot-anchored (emmeans contrasts)              |
| **Conservative** | 0.294      | 0.000         | Reduced early effect (pilot × 0.75)             |
| **Minimal**    | 0.200        | 0.070         | Sensitivity: half-pilot early + boundary late   |

📖 See [`scripts/simulation/run_simulation_scenarios.R`](scripts/simulation/run_simulation_scenarios.R) for detailed rationale.

## Quick Start

### Run Locally (50 sims, 4 workers)
```r
Rscript scripts/simulation/run_simulation_scenarios.R local
```

### Run on Ramses HPC (100 sims, 16 workers)
```bash
cd ~/temp/random
sbatch run_simulation.slurm
```

### Check Results
```r
library(tidyverse)
read_csv("data/csv/scenario_comparison.csv") %>% 
  select(scenario, expected_n, h2_support_rate, pct_never_decided)
```

## Repository Structure

```
samplesize/
├── data/
│   ├── csv/              # Simulation results (scenario_comparison.csv, etc.)
│   ├── rds/              # R binary outputs
│   ├── archive/          # Timestamped result backups
│   └── checkpoints/      # Per-sim checkpoint files (resume support)
├── scripts/
│   ├── simulation/       # Main simulation script (run_simulation_scenarios.R)
│   ├── utils/            # Helper functions (simulate_duration_data.R, etc.)
│   └── deprecated/       # Old analysis scripts (reference only)
├── reports/
│   └── qmd/              # Quarto report source (simulation_report.qmd)
├── config/
│   ├── params_ramses.R   # HPC config (100 sims, 16 workers)
│   └── params_local.R    # Local config (50 sims, 4 workers)
├── materials/            # Cached LMM results for report intro
├── run_simulation.slurm  # SLURM batch script for ramses
└── .github/workflows/    # Auto-render report to GitHub Pages
```

## Configuration Profiles

The simulation uses **profile-based configs** to adapt to local vs HPC environments:

| Profile  | `n_sims` | `max_workers` | `mcmc_chains` | `mcmc_iter` |
|----------|----------|---------------|---------------|-------------|
| `local`  | 50       | 4             | 2             | 1000        |
| `ramses` | 100      | 16            | 2             | 1000        |

Pass the profile as a CLI argument:
```r
Rscript scripts/simulation/run_simulation_scenarios.R ramses
```

### Ramses Deployment

1. **Upload files** (from Windows):
   ```powershell
   scp -r scripts/ config/ jschepen@ramses1.itcc.uni-koeln.de:~/temp/random/
   scp run_simulation.slurm jschepen@ramses1.itcc.uni-koeln.de:~/temp/random/
   ```

2. **Submit job**:
   ```bash
   sbatch run_simulation.slurm
   ```

3. **Monitor progress**:
   ```bash
   squeue -u jschepen
   tail -f sim_random_<JOBID>.out
   # Check per-scenario completion:
   for s in optimistic realistic conservative minimal; do
     echo -n "$s: "; ls /scratch/jschepen/<JOBID>/data/checkpoints/$s/*.rds 2>/dev/null | wc -l
   done
   ```

4. **Pull results**:
   ```powershell
   scp "jschepen@ramses1.itcc.uni-koeln.de:~/temp/random/data/csv/*.csv" "data/csv/"
   ```

## Checkpoint & Resume

Each simulation writes a checkpoint after completion:
```
data/checkpoints/<scenario>/sim_<NNNN>.rds
```

On restart (SLURM resubmit, crash recovery), completed sims are skipped automatically. To force a clean run, delete the checkpoint directory.

## Automated Report Rendering

Every push to `main` triggers a GitHub Actions workflow that:
1. Installs R 4.4.2, Quarto 1.8.27, and dependencies (via `pak` + `DESCRIPTION`)
2. Renders `reports/qmd/simulation_report.qmd` → `_site/index.html`
3. Deploys to **GitHub Pages**: https://jobschepens.github.io/samplesize/

The workflow uses reproducibility pins (R/Quarto versions, `sessionInfo()` in report).

## Key Files

| File | Purpose |
|------|---------|
| [`scripts/simulation/run_simulation_scenarios.R`](scripts/simulation/run_simulation_scenarios.R) | Main simulation loop (4 scenarios, checkpoint system, parallel execution) |
| [`scripts/utils/simulate_duration_data.R`](scripts/utils/simulate_duration_data.R) | Prior predictive data generation |
| [`scripts/utils/fit_bayesian_model.R`](scripts/utils/fit_bayesian_model.R) | brms model fitting with template-based compilation |
| [`config/params_ramses.R`](config/params_ramses.R) | HPC simulation parameters |
| [`data/csv/scenario_comparison.csv`](data/csv/scenario_comparison.csv) | Key output: expected N, H2 support rate across scenarios |
| [`reports/qmd/simulation_report.qmd`](reports/qmd/simulation_report.qmd) | Quarto report with visualizations and interpretation |
| [`run_simulation.slurm`](run_simulation.slurm) | SLURM batch script for ramses (16 CPUs, 64 GB) |

## Dependencies

**R packages** (see [`DESCRIPTION`](DESCRIPTION)):
- Core: `tidyverse`, `brms`, `bayestestR`, `lme4`, `lmerTest`, `emmeans`
- Reporting: `knitr`, `quarto`, `kableExtra`, `patchwork`, `scales`

**System requirements**:
- R ≥ 4.4.2
- cmdstanr + CmdStan 2.32+ (for brms backend)
- Quarto 1.8.27+ (for report rendering)

Install R dependencies:
```r
# Via pak (recommended):
pak::local_install_deps()

# Or via renv (reproducible lockfile):
renv::restore()
```

## Results Interpretation

After running simulations, key metrics are in [`data/csv/scenario_comparison.csv`](data/csv/scenario_comparison.csv):

- **`expected_n`**: Average sample size at which simulations decided (32 for optimistic/realistic/conservative; ~90–110 for minimal)
- **`h2_support_rate`**: % of decided simulations supporting H2 (PRESENT in 0–10s, ABSENT in 20–60s)
- **`pct_never_decided`**: % reaching hard cap (N=120) without deciding

**Key finding**: With pilot-anchored effects (0.29–0.45 for early window), the sequential design decides at N ≈ 30–32. The minimal scenario (effect = 0.20, half the pilot) pushes expected-N toward the hard cap, requiring N ≈ 90–120.

## Why Absence Detection Is Easy

**Asymmetry in HDI/ROPE decisions**:
- **PRESENT** requires `HDI_low > ROPE_upper` (+0.10) — hard when true effect is small (~0.20)
- **ABSENT** requires entire HDI inside ROPE (±0.10) — easy when true effect ≈ 0.002 (HDI width at N=30 is ~0.06)

The minimal scenario breaks this by setting the late-window effect to 0.07 (near ROPE boundary), making **both** decisions difficult simultaneously. See lines 106–119 in `run_simulation_scenarios.R` for detailed explanation.

## Citation

```
Schepens, J. (2026). Bayesian Sample Size Simulation for Event Duration Study. 
GitHub repository: https://github.com/jobschepens/samplesize
Report: https://jobschepens.github.io/samplesize/
```

## License

MIT
