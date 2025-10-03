# GSE Stock Prediction - Complete Analysis Pipeline
# This script runs the entire analysis pipeline

# Load required libraries
library(here)
library(tidyverse)

# Suppress variable binding warnings for dplyr operations
utils::globalVariables(c("%>%", "desc", "arrange", "group_by", "mutate",
                         "select", "summarise", "ungroup", "filter", "n"))

# Set working directory
setwd(here::here())

# Create log file
log_file <- file("logs/complete_analysis.log", open = "w")
cat("GSE Complete Analysis Pipeline Started at:", Sys.time(),
    "\n", file = log_file)

# Function to run script with error handling
run_script <- function(script_path, script_name) {
  cat(paste("\nRunning", script_name, "...\n"))
  cat(paste("Running", script_name, "...\n"), file = log_file)

  tryCatch({
    source(script_path)
    cat(paste("✓", script_name, "completed successfully\n"))
    cat(paste("✓", script_name, "completed successfully\n"), file = log_file)
    return(TRUE)
  }, error = function(e) {
    cat(paste("⚠", script_name, "failed:", e$message, "\n"))
    cat(paste("⚠", script_name, "failed:", e$message, "\n"), file = log_file)
    FALSE
  })
}

# Main analysis pipeline
run_complete_analysis <- function() {
  cat("GSE Stock Prediction - Complete Analysis Pipeline\n")
  cat("=" * 60 + "\n")

  # Step 1: Setup
  cat("Step 1: Project Setup\n")
  setup_success <- run_script("scripts/00_setup.R", "Project Setup")

  if (!setup_success) {
    cat("⚠ Setup failed. Cannot continue.\n")
    FALSE
  }

  # Step 2: Data Loading
  cat("\nStep 2: Data Loading\n")
  data_loading_success <- run_script("scripts/01_data_loading.R",
                                     "Data Loading")

  if (!data_loading_success) {
    cat("⚠ Data loading failed. Cannot continue.\n")
    FALSE
  }

  # Step 3: Data Cleaning
  cat("\nStep 3: Data Cleaning\n")
  data_cleaning_success <- run_script("scripts/02_data_cleaning.R",
                                      "Data Cleaning")

  if (!data_cleaning_success) {
    cat("⚠ Data cleaning failed. Cannot continue.\n")
    FALSE
  }

  # Step 4: Modeling
  cat("\nStep 4: Model Training\n")
  modeling_success <- run_script("scripts/03_modeling.R", "Model Training")

  if (!modeling_success) {
    cat("⚠ Modeling failed. Cannot continue.\n")
    FALSE
  }

  # Step 5: Testing
  cat("\nStep 5: Running Tests\n")
  test_success <- run_script("tests/test_runner.R", "Test Suite")

  if (!test_success) {
    cat("⚠ Some tests failed, but analysis completed.\n")
  }

  # Summary
  cat("\n" + "=" * 60 + "\n")
  cat("ANALYSIS PIPELINE SUMMARY\n")
  cat("=" * 60 + "\n")

  steps <- c("Setup", "Data Loading",
             "Data Cleaning", "Model Training", "Testing")
  results <- c(setup_success, data_loading_success,
               data_cleaning_success, modeling_success, test_success)

  for (i in seq_along(steps)) {
    status <- if (results[i]) "PASS" else "FAIL"
    cat(paste(steps[i], ":", status, "\n"))
  }

  successful_steps <- sum(results)
  total_steps <- length(results)

  cat(paste("\nOverall:", successful_steps, "of",
            total_steps, "steps completed successfully\n"))

  if (successful_steps >= 4) { # At least 4 out of 5 steps must succeed
    cat("Analysis pipeline completed successfully!\n")
    cat("You can now run the Shiny app with: Rscript app/run_app.R\n")
    TRUE
  } else {
    cat("Analysis pipeline failed. Please check the errors above.\n")
    FALSE
  }
}

# Function to run individual components
run_component <- function(component) {
  switch(component,
    "setup" = run_script("scripts/00_setup.R", "Project Setup"),
    "loading" = run_script("scripts/01_data_loading.R", "Data Loading"),
    "cleaning" = run_script("scripts/02_data_cleaning.R", "Data Cleaning"),
    "modeling" = run_script("scripts/03_modeling.R", "Model Training"),
    "testing" = run_script("tests/test_runner.R", "Test Suite"),
    "app" = {
      cat("Starting Shiny app...\n")
      source("app/run_app.R")
    },
    stop("Unknown component: ", component)
  )
}

# Command line interface
if (length(commandArgs(trailingOnly = TRUE)) > 0) {
  args <- commandArgs(trailingOnly = TRUE)

  if (args[1] == "all") {
    run_complete_analysis()
  } else if (args[1] %in% c("setup", "loading",
                            "cleaning", "modeling", "testing", "app")) {
    run_component(args[1])
  } else {
    cat("Usage: Rscript scripts/run_analysis.R 
                      [all|setup|loading|cleaning|modeling|testing|app]\n")
  }
} else {
  # Interactive mode
  cat("GSE Stock Prediction - Analysis Pipeline\n")
  cat("Choose an option:\n")
  cat("1. Run complete analysis pipeline\n")
  cat("2. Run individual component\n")
  cat("3. Start Shiny app\n")
  cat("4. Exit\n")

  choice <- readline("Enter your choice (1-4): ")

  switch(choice,
    "1" = run_complete_analysis(),
    "2" = {
      cat("Available components:\n")
      cat("- setup: Project setup\n")
      cat("- loading: Data loading\n")
      cat("- cleaning: Data cleaning\n")
      cat("- modeling: Model training\n")
      cat("- testing: Run tests\n")
      cat("- app: Start Shiny app\n")

      component <- readline("Enter component name: ")
      run_component(component)
    },
    "3" = run_component("app"),
    "4" = cat("Goodbye!\n"),
    cat("Invalid choice. Please run the script again.\n")
  )
}

# Close log file
cat("Complete analysis pipeline finished at:",
    Sys.time(), "\n", file = log_file)
close(log_file)
