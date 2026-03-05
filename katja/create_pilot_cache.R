#!/usr/bin/env Rscript
# Create cached pilot model results from text files (for public repo)

cat("Creating pilot model cache from lmer.txt and emmeans.txt...\n")

# Parse fixed effects from lmer.txt (base R)
fixed_effects <- data.frame(
  Term = c("(Intercept)", "sentence_lengthlong", "event_durationshort",
           "event_durationmedium", "event_durationlong",
           "sentence_lengthlong:event_durationshort",
           "sentence_lengthlong:event_durationmedium",
           "sentence_lengthlong:event_durationlong"),
  Estimate = c(1.280e+00, 3.930e-01, 1.357e+00, 4.927e+00, 9.792e+00,
               -1.338e-03, -3.779e-01, -3.908e-01),
  `Std. Error` = c(6.261e-01, 1.705e-01, 8.584e-01, 8.584e-01, 8.584e-01,
                   2.412e-01, 2.412e-01, 2.412e-01),
  df = c(3.291e+01, 1.515e+03, 2.914e+01, 2.914e+01, 2.914e+01,
         1.515e+03, 1.515e+03, 1.515e+03),
  `t value` = c(2.044, 2.305, 1.581, 5.739, 11.408, -0.006, -1.567, -1.620),
  `Pr(>|t|)` = c(0.0491, 0.0213, 0.1246, 3.21e-06, 2.88e-12, 0.9956, 0.1174, 0.1054),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Parse emmeans from emmeans.txt
emmeans_summary <- data.frame(
  event_duration = c("instant", "instant", "short", "short", "medium", "medium", "long", "long"),
  sentence_length = c("short", "long", "short", "long", "short", "long", "short", "long"),
  emmean = c(1.28, 1.67, 2.64, 3.03, 6.21, 6.22, 11.07, 11.07),
  SE = rep(0.626, 8),
  df = rep(32.9, 8),
  lower.CL = c(0.00563, 0.39864, 1.36312, 1.75480, 4.93220, 4.94732, 9.79766, 9.79989),
  upper.CL = c(2.55, 2.95, 3.91, 4.30, 7.48, 7.50, 12.35, 12.35),
  stringsAsFactors = FALSE
)

# Parse contrasts from emmeans.txt
contrasts_summary <- data.frame(
  event_duration = c("instant", "short", "medium", "long"),
  contrast = rep("short - long", 4),
  estimate = c(-0.39302, -0.39168, -0.01512, -0.00223),
  SE = rep(0.171, 4),
  df = rep(1515, 4),
  t.ratio = c(-2.305, -2.297, -0.089, -0.013),
  p.value = c(0.0213, 0.0218, 0.9294, 0.9896),
  stringsAsFactors = FALSE
)

# Bundle into cache structure that mimics lmer output
pilot_model_cache <- list(
  fixed_effects = fixed_effects,
  emmeans = emmeans_summary,
  contrasts = contrasts_summary,
  note = "Cached from pilot data LMER fit. Raw data not included (private)."
)

# Save to current directory
saveRDS(pilot_model_cache, "pilot_model_cache.rds")

cat("\n✓ Cache created: pilot_model_cache.rds\n")
cat("  Contains: fixed_effects, emmeans, contrasts\n")
cat("  Move to materials/ for use in public report\n")
