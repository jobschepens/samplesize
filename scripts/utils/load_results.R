
library(tidyverse)

#' Load Simulation Results
#' 
#' Reads all simulation result CSVs from the data/csv directory 
#' and combines them into a single tibble with a 'Scenario' column.
#' 
#' @param data_dir Path to the data directory (default: "data/csv")
#' @return A tibble containing combined simulation results
load_simulation_results <- function(data_dir = "data/csv") {
  
  # Define expected file patterns and scenario names
  file_map <- c(
    "simulation_results_optimistic.csv" = "Optimistic",
    "simulation_results_realistic.csv" = "Realistic",
    "simulation_results_conservative.csv" = "Conservative"
  )
  
  all_data <- tibble()
  
  for (file_name in names(file_map)) {
    file_path <- file.path(data_dir, file_name)
    
    if (file.exists(file_path)) {
      cat(sprintf("Loading %s...\n", file_name))
      
      # Read CSV and add Scenario column
      data <- read_csv(file_path, show_col_types = FALSE) %>%
        mutate(scenario = file_map[[file_name]])
      
      all_data <- bind_rows(all_data, data)
    } else {
      cat(sprintf("WARNING: %s not found. Skipping.\n", file_path))
    }
  }
  
  # Reorder scenario factor for plotting (Conservative -> Realistic -> Optimistic)
  if (nrow(all_data) > 0) {
    all_data <- all_data %>%
      mutate(scenario = factor(scenario, levels = c("Conservative", "Realistic", "Optimistic")))
  }
  
  return(all_data)
}

# --- usage example (uncomment to test) ---
# setwd("~/temp/random")
# df <- load_simulation_results()
# print(head(df))
