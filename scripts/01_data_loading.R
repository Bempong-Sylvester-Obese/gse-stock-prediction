# This script loads and validates the GSE stock data

# Load required libraries
library(tidyverse)
library(lubridate)
library(here)
library(VIM)

# Suppress variable binding warnings for dplyr operations
utils::globalVariables(c("%>%", "desc", "arrange", "group_by", "mutate",
                         "select", "summarise", "ungroup", "filter", "n"))

# Set working directory
setwd(here::here())

# Create log file
log_file <- file("logs/data_loading.log", open = "w")
cat("GSE Data Loading Started at:", Sys.time(), "\n", file = log_file)

# Function to load and validate CSV data
load_gse_data <- function(file_path, file_name) {
  cat(paste("Loading", file_name, "...\n"))

  tryCatch({
    # Read the CSV file
    data <- readr::read_csv(
      file_path,
      locale = readr::locale(date_format = "%d/%m/%Y"),
      show_col_types = FALSE
    )

    # Basic data validation
    cat(paste("✓", file_name, "loaded successfully\n"))
    cat(paste("  - Rows:", nrow(data), "\n"))
    cat(paste("  - Columns:", ncol(data), "\n"))
    cat(paste("  - Date range:",
              min(data$date, na.rm = TRUE),
              "to",
              max(data$date, na.rm = TRUE),
              "\n"))

    # Log to file
    cat(paste("Loaded", file_name, "with", nrow(data),
              "rows and", ncol(data), "columns\n"), file = log_file)

    data

  }, error = function(e) {
    cat(paste("✗ Error loading", file_name, ":",
              e$message, "\n"))
    cat(paste("Error loading", file_name, ":",
              e$message, "\n"), file = log_file)
    NULL
  })
}

# Load the main datasets
cat("Loading GSE Stock Data...\n")

# Load 2023 daily data
daily_2023 <- load_gse_data(
  "data/raw/Daily Shares  ETFs 2023.csv",
  "Daily Shares 2023"
)

# Load historical data
historical_data <- load_gse_data(
  "data/raw/Updated-gse efts and shares.csv",
  "Historical GSE Data"
)

# Data validation and cleaning function
validate_and_clean_data <- function(data, data_name) {
  if (is.null(data)) {
    NULL
  }

  cat(paste("\nValidating", data_name, "...\n"))

  # Check for missing values
  missing_summary <- data %>%
    dplyr::summarise_all(~sum(is.na(.))) %>%
    tidyr::pivot_longer(dplyr::everything(),
                        names_to = "column",
                        values_to = "missing_count")

  cat("Missing values by column:\n")
  print(missing_summary)

  # Check data types
  cat("\nData types:\n")
  print(sapply(data, class))

  # Check for duplicate rows
  duplicates <- sum(duplicated(data))
  cat(paste("Duplicate rows:", duplicates, "\n"))

  # Basic statistics for numeric columns
  numeric_cols <- data %>%
    dplyr::select_if(is.numeric) %>%
    names()

  if (length(numeric_cols) > 0) {
    cat("\nBasic statistics for numeric columns:\n")
    print(summary(data[numeric_cols]))
  }

  # Log validation results
  cat(paste("Validation completed for", data_name, "\n"), file = log_file)
  cat(paste("Missing values found in",
            sum(missing_summary$missing_count > 0),
            "columns\n"), file = log_file)
  cat(paste("Duplicate rows:", duplicates, "\n"), file = log_file)

  data
}

# Validate the loaded datasets
if (!is.null(daily_2023)) {
  daily_2023_clean <- validate_and_clean_data(daily_2023, "Daily 2023 Data")
}

if (!is.null(historical_data)) {
  historical_clean <- validate_and_clean_data(
    historical_data, "Historical Data"
  )
}

# Create combined dataset for analysis
if (!is.null(daily_2023_clean) && !is.null(historical_clean)) {
  cat("\nCreating combined dataset...\n")

  # Standardize column names if needed
  # (This would need to be adjusted based on actual column names)

  # Save processed data
  if (!dir.exists("data/processed")) {
    dir.create("data/processed", recursive = TRUE)
  }

  # Save individual datasets
  saveRDS(daily_2023_clean, "data/processed/daily_2023_clean.rds")
  saveRDS(historical_clean, "data/processed/historical_clean.rds")

  cat("Processed data saved to data/processed/\n")

  # Create summary report
  summary_report <- list(
    daily_2023_rows = nrow(daily_2023_clean),
    historical_rows = nrow(historical_clean),
    daily_2023_cols = ncol(daily_2023_clean),
    historical_cols = ncol(historical_clean),
    processing_time = Sys.time()
  )

  saveRDS(summary_report, "data/processed/data_summary.rds")

  cat("Data summary saved\n")
}

# Create data quality report
create_quality_report <- function(data, data_name) {
  if (is.null(data)) return(NULL)

  report <- list(
    dataset_name = data_name,
    total_rows = nrow(data),
    total_columns = ncol(data),
    missing_values = sum(is.na(data)),
    missing_percentage = round(
      sum(is.na(data)) / (nrow(data) * ncol(data)) * 100, 2
    ),
    duplicate_rows = sum(duplicated(data)),
    date_range = if ("date" %in% names(data)) {
      paste(min(data$date, na.rm = TRUE), "to", max(data$date, na.rm = TRUE))
    } else {
      "No date column"
    },
    numeric_columns = length(dplyr::select_if(data, is.numeric)),
    character_columns = length(dplyr::select_if(data, is.character))
  )

  report
}

# Generate quality reports
if (!is.null(daily_2023_clean)) {
  daily_report <- create_quality_report(daily_2023_clean, "Daily 2023 Data")
  saveRDS(daily_report, "data/processed/daily_2023_quality_report.rds")
}

if (!is.null(historical_clean)) {
  historical_report <- create_quality_report(
    historical_clean, "Historical Data"
  )
  saveRDS(historical_report, "data/processed/historical_quality_report.rds")
}

# Close log file
cat("Data loading completed at:", Sys.time(), "\n", file = log_file)
close(log_file)

# Display final summary
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("GSE DATA LOADING SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

if (!is.null(daily_2023_clean)) {
  cat("Daily 2023 Data:", nrow(daily_2023_clean),
      "rows,", ncol(daily_2023_clean), "columns\n")
}

if (!is.null(historical_clean)) {
  cat("Historical Data:", nrow(historical_clean),
      "rows,", ncol(historical_clean), "columns\n")
}

cat("Processed data saved to: data/processed/\n")
cat("Quality reports generated\n")
cat("Log file created: logs/data_loading.log\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nData loading completed successfully!\n")
cat("Next step: Run data cleaning script (02_data_cleaning.R)\n")
