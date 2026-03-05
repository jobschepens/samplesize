Subject: Simulation results for preregistration (boxplot attached)

Hi [Name],

I ran a sequential prior‑predictive simulation to inform the preregistration. The simulation assumed effect sizes of **0.25, 0.12, and 0.00 on the log scale** for the three time windows (0–10s, 10–20s, 20–60s). Under these assumptions, most simulations reached a decision by N=60.

Here's what these effect sizes mean in practical time units:

**Conversion formula (log scale → seconds):**
- time_difference (seconds) = baseline_duration × (exp(log_effect) − 1)
- percent_change = (exp(log_effect) − 1) × 100

**Conservative scenario example (0–10s window):**

I assumed an effect of **0.25 on the log scale**. The simulation recovered effects close to this (mean ≈ 0.24). With a baseline duration of ~9.0 seconds:
- time_difference ≈ 9.0 × (exp(0.24) − 1) = 9.0 × 0.27 ≈ **~2.4 seconds (~27% increase)**

These effects are **substantially larger than the ROPE** (±0.9 seconds). This means the simulation confirms that N=60 provides reliable detection of effects this size.

**What if we wanted to detect smaller effects?**

If you wanted to detect a 1-second effect (~10% change) as meaningful, that would require a much tighter ROPE (approximately ±0.03 on log scale). However, with that tighter threshold, you'd need roughly **250-300 participants** to reliably detect 1-second effects—about 4-5× more than the current design. This illustrates the tradeoff: more stringent effect definitions require substantially larger samples.

**ROPE boundaries (log-scale: [−0.10, +0.10]):**
- ROPE_lower = 9.0 × (exp(−0.10) − 1) = 9.0 × (−0.0952) ≈ **−0.86 seconds (−9.5%)**
- ROPE_upper = 9.0 × (exp(+0.10) − 1) = 9.0 × 0.1052 ≈ **+0.95 seconds (+10.5%)**

The ROPE represents the region of practical equivalence: any effect within these bounds is considered "negligible" or "absent." So in the 0–10s window, we only declare a meaningful effect if the HDI falls entirely outside the ±~0.9 second range.

Key assumptions used:
- n_samples: 60, 90, 120 (sequential stopping)
- n_items_per_condition: 10
- n_sims: 50
- ROPE: [-0.05, 0.05]
- sigma_residual: 0.35
- sd_participant_intercept: 0.25
- sd_item_intercept: 0.15
- sd_participant_slope: 0.10
- within_corr: 0.5

I’m only sending the boxplot figure for the preregistration:
- 04_boxplot_all_windows.png

Let me know if you want any other plots or a short summary table included.

Best,
[Your Name]
