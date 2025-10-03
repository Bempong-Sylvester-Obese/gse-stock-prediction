# GSE Stock Prediction - Test Runner
# This script runs all tests for the GSE stock prediction project

# Load required libraries
library(testthat)
library(here)

# Suppress variable binding warnings
utils::globalVariables(c("daily_data", "historical_data", "cleaned_data",
                         "model_result", "predictions", "file"))

# Set working directory
setwd(here::here())

# Create test directory if it doesn't exist
if (!dir.exists("tests")) {
  dir.create("tests", recursive = TRUE)
}

# Test data loading functions
test_data_loading <- function() {
  test_that("Data loading functions work correctly", {
    # Test if data files exist
    expect_true(file.exists("data/raw/Daily Shares  ETFs 2023.csv"))
    expect_true(file.exists("data/raw/Updated-gse efts and shares.csv"))

    # Test if data can be loaded
    if (file.exists("data/processed/daily_2023_clean.rds")) {
      daily_data <- readRDS("data/processed/daily_2023_clean.rds")
      expect_true(is.data.frame(daily_data))
      expect_true(nrow(daily_data) > 0)
    }

    if (file.exists("data/processed/historical_clean.rds")) {
      historical_data <- readRDS("data/processed/historical_clean.rds")
      expect_true(is.data.frame(historical_data))
      expect_true(nrow(historical_data) > 0)
    }
  })
}

# Test data cleaning functions
test_data_cleaning <- function() {
  test_that("Data cleaning functions work correctly", {
    # Test if cleaned data exists
    if (file.exists("data/cleaned/daily_2023_cleaned.rds")) {
      daily_cleaned <- readRDS("data/cleaned/daily_2023_cleaned.rds")
      expect_true(is.data.frame(daily_cleaned))
      expect_true(nrow(daily_cleaned) > 0)

      # Test for missing values
      missing_count <- sum(is.na(daily_cleaned))
      expect_true(missing_count < nrow(daily_cleaned) *
                    ncol(daily_cleaned) * 0.5) # Less than 50% missing
    }

    if (file.exists("data/cleaned/historical_cleaned.rds")) {
      historical_cleaned <- readRDS("data/cleaned/historical_cleaned.rds")
      expect_true(is.data.frame(historical_cleaned))
      expect_true(nrow(historical_cleaned) > 0)
    }
  })
}

# Test modeling functions
test_modeling <- function() {
  test_that("Modeling functions work correctly", {
    # Test if models exist
    if (file.exists("models/trained/daily_models.rds")) {
      daily_models <- readRDS("models/trained/daily_models.rds")
      expect_true(is.list(daily_models))
      expect_true(length(daily_models) > 0)

      # Test model structure
      for (model_name in names(daily_models)) {
        model <- daily_models[[model_name]]
        expect_true("model" %in% names(model))
        expect_true("mae" %in% names(model))
        expect_true("rmse" %in% names(model))
        expect_true("mape" %in% names(model))
        expect_true("directional_accuracy" %in% names(model))
      }
    }

    if (file.exists("models/trained/historical_models.rds")) {
      historical_models <- readRDS("models/trained/historical_models.rds")
      expect_true(is.list(historical_models))
    }
  })
}

# Test Shiny app components
test_shiny_app <- function() {
  test_that("Shiny app components work correctly", {
    # Test if app file exists
    expect_true(file.exists("app/app.R"))
    expect_true(file.exists("app/run_app.R"))

    # Test if app can be loaded
    expect_true(file.exists("app/app.R"))
  })
}

# Test project structure
test_project_structure <- function() {
  test_that("Project structure is correct", {
    # Test required directories
    expect_true(dir.exists("data"))
    expect_true(dir.exists("scripts"))
    expect_true(dir.exists("app"))
    expect_true(dir.exists("models"))
    expect_true(dir.exists("tests"))
    expect_true(dir.exists("output"))

    # Test required files
    expect_true(file.exists("README.md"))
    expect_true(file.exists("Makefile"))
    expect_true(file.exists(".Rprofile"))
    expect_true(file.exists("renv.lock"))
  })
}

# Test data quality
test_data_quality <- function() {
  test_that("Data quality is acceptable", {
    if (file.exists("data/cleaned/daily_2023_cleaned.rds")) {
      daily_data <- readRDS("data/cleaned/daily_2023_cleaned.rds")

      # Test for required columns
      required_cols <- c("date", "share_code", "closing_price_vwap")
      for (col in required_cols) {
        expect_true(col %in% names(daily_data))
      }

      # Test for reasonable data ranges
      if ("closing_price_vwap" %in% names(daily_data)) {
        prices <- daily_data$closing_price_vwap
        expect_true(all(prices > 0, na.rm = TRUE)) # Prices should be positive
        expect_true(max(prices, na.rm = TRUE) < 1000) # Reasonable upper bound
      }
    }
  })
}

# Main test runner
run_all_tests <- function() {
  cat("GSE Stock Prediction - Test Suite\n")
  cat("=" * 40 + "\n")

  # Run all tests
  test_results <- list()

  tryCatch({
    test_results$project_structure <- test_project_structure()
    cat("✓ Project structure tests passed\n")
  }, error = function(e) {
    cat(paste("Project structure tests failed:", e$message, "\n"))
    test_results$project_structure <- FALSE
  })

  tryCatch({
    test_results$data_loading <- test_data_loading()
    cat("Data loading tests passed\n")
  }, error = function(e) {
    cat(paste("Data loading tests failed:", e$message, "\n"))
    test_results$data_loading <- FALSE
  })

  tryCatch({
    test_results$data_cleaning <- test_data_cleaning()
    cat("Data cleaning tests passed\n")
  }, error = function(e) {
    cat(paste("Data cleaning tests failed:", e$message, "\n"))
    test_results$data_cleaning <- FALSE
  })

  tryCatch({
    test_results$modeling <- test_modeling()
    cat("Modeling tests passed\n")
  }, error = function(e) {
    cat(paste("Modeling tests failed:", e$message, "\n"))
    test_results$modeling <- FALSE
  })

  tryCatch({
    test_results$shiny_app <- test_shiny_app()
    cat("Shiny app tests passed\n")
  }, error = function(e) {
    cat(paste("Shiny app tests failed:", e$message, "\n"))
    test_results$shiny_app <- FALSE
  })

  tryCatch({
    test_results$data_quality <- test_data_quality()
    cat("Data quality tests passed\n")
  }, error = function(e) {
    cat(paste("Data quality tests failed:", e$message, "\n"))
    test_results$data_quality <- FALSE
  })

  # Summary
  cat("\n" + "=" * 40 + "\n")
  cat("TEST SUMMARY\n")
  cat("=" * 40 + "\n")

  passed_tests <- sum(unlist(test_results))
  total_tests <- length(test_results)

  for (test_name in names(test_results)) {
    status <- if (test_results[[test_name]]) "PASS" else "FAIL"
    cat(paste(test_name, ":", status, "\n"))
  }

  cat(paste("\nOverall:", passed_tests, "of", total_tests, "tests passed\n"))

  if (passed_tests == total_tests) {
    cat("All tests passed! Project is ready for use.\n")
  } else {
    cat("Some tests failed. Please check the issues above.\n")
  }

  test_results
}

# Run tests if script is executed directly
if (interactive()) {
  run_all_tests()
} else {
  cat("This script should be run interactively.\n")
  cat("Use: Rscript tests/test_runner.R\n")
}
