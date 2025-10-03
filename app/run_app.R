# GSE Stock Prediction - Shiny App Runner
# This script runs the Shiny dashboard application

# Load required libraries
library(shiny)
library(here)

# Suppress variable binding warnings
utils::globalVariables(c("file"))

# Set working directory to project root
setwd(here::here())

# Check if required data and models exist
check_requirements <- function() {
  required_files <- c(
    "data/cleaned/daily_2023_cleaned.rds",
    "data/cleaned/historical_cleaned.rds"
  )

  missing_files <- c()
  for (file in required_files) {
    if (!file.exists(file)) {
      missing_files <- c(missing_files, file)
    }
  }

  if (length(missing_files) > 0) {
    cat("Missing required files:\n")
    for (file in missing_files) {
      cat(paste("  -", file, "\n"))
    }
    cat("\nRun the data processing scripts first:\n")
    cat("  1. Rscript scripts/00_setup.R\n")
    cat("  2. Rscript scripts/01_data_loading.R\n")
    cat("  3. Rscript scripts/02_data_cleaning.R\n")
    cat("  4. Rscript scripts/03_modeling.R\n")
    return(FALSE)
  }

  TRUE
}

# Main function to run the app
run_gse_app <- function() {
  cat("GSE Stock Prediction Dashboard\n")
  cat("=" * 40 + "\n")

  # Check requirements
  if (!check_requirements()) {
    cat("\nRequirements not met. Please run the setup scripts first.\n")
    return(FALSE)
  }

  cat("All requirements met\n")
  cat("Starting Shiny application...\n")

  # Run the Shiny app
  tryCatch({
    shiny::runApp("app/app.R", 
                  host = "127.0.0.1", 
                  port = 3838,
                  launch.browser = TRUE)
  }, error = function(e) {
    cat(paste("Error running Shiny app:", e$message, "\n"))
    FALSE
  })
  TRUE
}

# Run the application
if (interactive()) {
  run_gse_app()
} else {
  cat("This script should be run interactively.\n")
  cat("Use: Rscript app/run_app.R\n")
}
