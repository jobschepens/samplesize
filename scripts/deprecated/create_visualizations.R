#!/usr/bin/env Rscript

# Set R library path
.libPaths(c(Sys.getenv('R_LIBS_USER'), .libPaths()))

# Load libraries
library(tidyverse)
library(ggplot2)
library(gridExtra)

setwd("c:/GitHub/temp/random")

cat("Loading data...\n")
conservative <- read.csv("simulation_results_conservative.csv")
realistic <- read.csv("simulation_results_realistic.csv")
optimistic <- read.csv("simulation_results_optimistic.csv")

# Add scenario identifier
conservative$scenario <- "Conservative"
realistic$scenario <- "Realistic"
optimistic$scenario <- "Optimistic"

# Combine all data
all_data <- bind_rows(conservative, realistic, optimistic)

cat("Data loaded. Creating visualizations...\n")

# Define color palette
colors <- c("Conservative" = "#1f77b4", "Realistic" = "#ff7f0e", "Optimistic" = "#2ca02c")

# Define ROPE boundaries (log scale: [-0.05, 0.05])
rope_lower <- -0.05
rope_upper <- 0.05

# ============================================================================
# 1. DISTRIBUTION PLOTS FOR EACH TIME WINDOW
# ============================================================================

cat("Creating density plots by time window...\n")

# 0-10s window
p1 <- ggplot(all_data, aes(x = mean_0_10s, fill = scenario)) +
  geom_density(alpha = 0.6, color = NA) +
  annotate("rect", xmin = rope_lower, xmax = rope_upper, ymin = -Inf, ymax = Inf,
           fill = "red", alpha = 0.15) +
  geom_vline(xintercept = rope_lower, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = rope_upper, linetype = "dashed", color = "red", linewidth = 1) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Effect Size Distribution: 0-10s Window",
    subtitle = "Strong effects across all scenarios (red shaded region = ROPE)",
    x = "Effect Size",
    y = "Density",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "top",
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank()
  )

# 10-20s window
p2 <- ggplot(all_data, aes(x = mean_10_20s, fill = scenario)) +
  geom_density(alpha = 0.6, color = NA) +
  annotate("rect", xmin = rope_lower, xmax = rope_upper, ymin = -Inf, ymax = Inf,
           fill = "red", alpha = 0.15) +
  geom_vline(xintercept = rope_lower, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = rope_upper, linetype = "dashed", color = "red", linewidth = 1) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Effect Size Distribution: 10-20s Window",
    subtitle = "Moderate effects with 50% reduction (red shaded region = ROPE)",
    x = "Effect Size",
    y = "Density",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "top",
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank()
  )

# 20-60s window
p3 <- ggplot(all_data, aes(x = mean_20_60s, fill = scenario)) +
  geom_density(alpha = 0.6, color = NA) +
  annotate("rect", xmin = rope_lower, xmax = rope_upper, ymin = -Inf, ymax = Inf,
           fill = "red", alpha = 0.15) +
  geom_vline(xintercept = rope_lower, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = rope_upper, linetype = "dashed", color = "red", linewidth = 1) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Effect Size Distribution: 20-60s Window",
    subtitle = "Near-zero effects with high variability (red shaded region = ROPE)",
    x = "Effect Size",
    y = "Density",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "top",
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank()
  )

ggsave("01_density_0_10s.png", p1, width = 10, height = 6, dpi = 300)
ggsave("02_density_10_20s.png", p2, width = 10, height = 6, dpi = 300)
ggsave("03_density_20_60s.png", p3, width = 10, height = 6, dpi = 300)

# ============================================================================
# 2. BOXPLOT COMPARISONS
# ============================================================================

cat("Creating boxplot comparisons...\n")

# Prepare long format data
plot_data <- all_data %>%
  pivot_longer(
    cols = c(mean_0_10s, mean_10_20s, mean_20_60s),
    names_to = "time_window",
    values_to = "effect_size"
  ) %>%
  mutate(time_window = factor(
    time_window,
    levels = c("mean_0_10s", "mean_10_20s", "mean_20_60s"),
    labels = c("0-10s", "10-20s", "20-60s")
  ),
  scenario = factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")))

# Combined boxplot
p4 <- ggplot(plot_data, aes(x = scenario, y = effect_size, fill = scenario)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = rope_lower, ymax = rope_upper,
           fill = "red", alpha = 0.15) +
  geom_hline(yintercept = rope_lower, linetype = "dashed", color = "red", linewidth = 1) +
  geom_hline(yintercept = rope_upper, linetype = "dashed", color = "red", linewidth = 1) +
  geom_boxplot(alpha = 0.7, color = "black", linewidth = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 2, color = "darkgray") +
  facet_wrap(~time_window, scales = "free_y", ncol = 3) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Effect Size Boxplots Across Time Windows",
    subtitle = "Comparison of Conservative, Realistic, and Optimistic scenarios (red region = ROPE)",
    x = "Scenario",
    y = "Effect Size",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank()
  )

ggsave("04_boxplot_all_windows.png", p4, width = 14, height = 6, dpi = 300)

# ============================================================================
# 3. VIOLIN PLOTS
# ============================================================================

cat("Creating violin plots...\n")

p5 <- ggplot(plot_data, aes(x = time_window, y = effect_size, fill = scenario)) +
  geom_violin(alpha = 0.7, position = position_dodge(width = 0.9)) +
  geom_boxplot(width = 0.1, position = position_dodge(width = 0.9), 
               fill = "white", color = "black", size = 0.4) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Distribution Shape Comparison",
    subtitle = "Violin plots with embedded boxplots",
    x = "Time Window",
    y = "Effect Size",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "top",
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank()
  )

ggsave("05_violin_plots.png", p5, width = 12, height = 7, dpi = 300)

# ============================================================================
# 4. MEAN EFFECTS WITH CONFIDENCE INTERVALS
# ============================================================================

cat("Creating mean effects plot...\n")

# Calculate statistics
stats_data <- all_data %>%
  pivot_longer(
    cols = c(mean_0_10s, mean_10_20s, mean_20_60s),
    names_to = "time_window",
    values_to = "effect_size"
  ) %>%
  mutate(time_window = factor(
    time_window,
    levels = c("mean_0_10s", "mean_10_20s", "mean_20_60s"),
    labels = c("0-10s", "10-20s", "20-60s")
  )) %>%
  group_by(scenario, time_window) %>%
  summarise(
    mean = mean(effect_size, na.rm = TRUE),
    sd = sd(effect_size, na.rm = TRUE),
    n = n(),
    se = sd / sqrt(n),
    ci_lower = mean - 1.96 * se,
    ci_upper = mean + 1.96 * se,
    .groups = "drop"
  ) %>%
  mutate(scenario = factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")))

p6 <- ggplot(stats_data, aes(x = time_window, y = mean, color = scenario, group = scenario)) +
  geom_line(size = 1.2) +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), 
                width = 0.15, size = 1, alpha = 0.7) +
  scale_color_manual(values = colors) +
  labs(
    title = "Mean Effect Trajectory Across Time Windows",
    subtitle = "With 95% confidence intervals showing temporal decay",
    x = "Time Window",
    y = "Mean Effect Size",
    color = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "top",
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.grid.minor = element_blank(),
    text = element_text(size = 11)
  )

ggsave("06_mean_trajectory.png", p6, width = 12, height = 7, dpi = 300)

# ============================================================================
# 5. HYPOTHESIS SUPPORT RATES
# ============================================================================

cat("Creating hypothesis support plot...\n")

h2_data <- all_data %>%
  group_by(scenario) %>%
  summarise(
    support_rate = mean(h2_supported, na.rm = TRUE) * 100,
    n_total = n(),
    n_supported = sum(h2_supported, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(scenario = factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")))

p7 <- ggplot(h2_data, aes(x = scenario, y = support_rate, fill = scenario)) +
  geom_col(alpha = 0.7, color = "black", size = 1) +
  geom_text(aes(label = paste0(round(support_rate, 1), "%")), 
            vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = colors) +
  ylim(0, 105) +
  labs(
    title = "H2 Hypothesis Support Rates",
    subtitle = "Percentage of simulations supporting the hypothesis",
    x = "Scenario",
    y = "Support Rate (%)",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "#f0f0f0"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 12, face = "bold")
  )

ggsave("07_h2_support_rates.png", p7, width = 10, height = 7, dpi = 300)

# ============================================================================
# 6. EFFECT SIZE COMPARISON HEATMAP
# ============================================================================

cat("Creating comparison heatmap...\n")

heatmap_data <- stats_data %>%
  select(scenario, time_window, mean) %>%
  pivot_wider(names_from = time_window, values_from = mean)

p8 <- ggplot(stats_data, aes(x = time_window, y = scenario)) +
  geom_tile(aes(fill = mean), color = "white", size = 1) +
  geom_text(aes(label = sprintf("%.3f", mean)), 
            color = "white", size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#f7fbff", high = "#08519c", name = "Mean Effect") +
  labs(
    title = "Effect Size Heatmap",
    subtitle = "Mean effects across scenarios and time windows",
    x = "Time Window",
    y = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    axis.text = element_text(size = 12, face = "bold"),
    panel.grid = element_blank()
  )

ggsave("08_effect_heatmap.png", p8, width = 10, height = 6, dpi = 300)

# ============================================================================
# 7. SAMPLE SIZE DISTRIBUTION
# ============================================================================

cat("Creating sample size distribution plot...\n")

p9 <- ggplot(all_data, aes(x = n_participants, fill = scenario)) +
  geom_histogram(alpha = 0.6, bins = 20, color = "black", size = 0.3) +
  facet_wrap(~factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")), 
             ncol = 3) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Sample Size Distribution by Scenario",
    subtitle = "Variation in number of participants across simulations",
    x = "Number of Participants",
    y = "Frequency",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.major = element_line(color = "#f0f0f0")
  )

ggsave("09_sample_size_dist.png", p9, width = 12, height = 5, dpi = 300)

# ============================================================================
# 8. SCATTER PLOT: 0-10s vs 10-20s
# ============================================================================

cat("Creating scatter plot...\n")

p10 <- ggplot(all_data, aes(x = mean_0_10s, y = mean_10_20s, color = scenario)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.1, size = 1) +
  facet_wrap(~factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")), 
             ncol = 3) +
  scale_color_manual(values = colors) +
  labs(
    title = "Relationship: 0-10s vs 10-20s Effects",
    subtitle = "Correlation between early and mid-temporal effects",
    x = "Effect Size (0-10s)",
    y = "Effect Size (10-20s)",
    color = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", color = "#333"),
    plot.subtitle = element_text(size = 11, color = "#666"),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.major = element_line(color = "#f0f0f0")
  )

ggsave("10_scatter_effects.png", p10, width = 12, height = 5, dpi = 300)

cat("\n=== VISUALIZATION SUMMARY ===\n")
cat("✓ 01_density_0_10s.png - Density distribution for 0-10s window\n")
cat("✓ 02_density_10_20s.png - Density distribution for 10-20s window\n")
cat("✓ 03_density_20_60s.png - Density distribution for 20-60s window\n")
cat("✓ 04_boxplot_all_windows.png - Boxplots across all time windows\n")
cat("✓ 05_violin_plots.png - Violin plots with distributions\n")
cat("✓ 06_mean_trajectory.png - Mean effects with CI across time\n")
cat("✓ 07_h2_support_rates.png - Hypothesis support comparison\n")
cat("✓ 08_effect_heatmap.png - Heatmap of mean effects\n")
cat("✓ 09_sample_size_dist.png - Sample size distributions\n")
cat("✓ 10_scatter_effects.png - Correlation scatter plots\n")

cat("\nAll visualizations generated successfully!\n")
