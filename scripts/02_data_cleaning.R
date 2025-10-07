# This script cleans and preprocesses the GSE stock data for analysis

# Load required libraries
library(tidyverse)
library(lubridate)
library(here)
library(VIM)
library(zoo)

# Suppress variable binding warnings for dplyr operations
utils::globalVariables(c("share_code", "closing_price_vwap",
                         "total_shares_traded", "year_low", "year_high",
                         "trading_activity", "opening_price", "date"))

# Set working directory
setwd(here::here())

# Create log file
log_file <- file("logs/data_cleaning.log", open = "w")
cat("GSE Data Cleaning Started at:", Sys.time(), "\n", file = log_file)

# Load processed data
cat("Loading processed data...\n")

if (file.exists("data/processed/daily_2023_clean.rds")) {
  daily_2023 <- readRDS("data/processed/daily_2023_clean.rds")
  cat("✓ Daily 2023 data loaded\n")
} else {
  cat("⚠ Daily 2023 data not found. Run 01_data_loading.R first.\n")
  daily_2023 <- NULL
}

if (file.exists("data/processed/historical_clean.rds")) {
  historical_data <- readRDS("data/processed/historical_clean.rds")
  cat("✓ Historical data loaded\n")
} else {
  cat("⚠ Historical data not found. Run 01_data_loading.R first.\n")
  historical_data <- NULL
}

# Function to clean and standardize column names
clean_column_names <- function(data) {
  if (is.null(data)) NULL

  # Standardize column names
  colnames(data) <- colnames(data) %>%
    tolower() %>%
    stringr::str_replace_all("\\s+", "_") %>%
    stringr::str_replace_all("[^a-z0-9_]", "") %>%
    stringr::str_replace_all("_{2,}", "_") %>%
    stringr::str_remove("^_|_$")

  data
}

# Function to handle missing values
handle_missing_values <- function(data, data_name) {
  if (is.null(data)) NULL

  cat(paste("\nHandling missing values in", data_name, "...\n"))

  # Count missing values before cleaning
  missing_before <- sum(is.na(data))
  cat(paste("Missing values before cleaning:", missing_before, "\n"))

  # Handle missing values based on column type
  data_cleaned <- data %>%
    # For numeric columns, use forward fill then backward fill
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), ~ {
      if (all(is.na(.))) .
      else na.locf(na.locf(., na.rm = FALSE), fromLast = TRUE)
    })) %>%
    # For date columns, remove rows with missing dates
    filter(!is.na(date)) %>%
    # For character columns, replace NA with "Unknown"
    dplyr::mutate(dplyr::across(dplyr::where(is.character),
                                ~ ifelse(is.na(.), "Unknown", .)))

  # Count missing values after cleaning
  missing_after <- sum(is.na(data_cleaned))
  cat(paste("Missing values after cleaning:", missing_after, "\n"))
  cat(paste("Missing values removed:", missing_before - missing_after, "\n"))

  # Log missing value handling
  cat(paste("Missing values handled for", data_name, "\n"), file = log_file)
  cat(paste("Before:", missing_before, "After:", missing_after, "\n"),
      file = log_file)

  data_cleaned
}

# Function to detect and handle outliers
handle_outliers <- function(data, data_name) {
  if (is.null(data)) NULL

  cat(paste("\nDetecting outliers in", data_name, "...\n"))

  # Get numeric columns
  numeric_cols <- data %>%
    dplyr::select_if(is.numeric) %>%
    names()

  outliers_removed <- 0

  for (col in numeric_cols) {
    if (col %in% names(data)) {
      # Calculate IQR bounds
      q1 <- quantile(data[[col]], 0.25, na.rm = TRUE)
      q3 <- quantile(data[[col]], 0.75, na.rm = TRUE)
      iqr <- q3 - q1

      lower_bound <- q1 - 1.5 * iqr
      upper_bound <- q3 + 1.5 * iqr

      # Count outliers
      outliers <- sum(data[[col]] < lower_bound |
                        data[[col]] > upper_bound, na.rm = TRUE)

      if (outliers > 0) {
        cat(paste("  -", col, ":", outliers, "outliers detected\n"))

        # Cap outliers instead of removing them
        data[[col]] <- pmax(pmin(data[[col]], upper_bound), lower_bound)
        outliers_removed <- outliers_removed + outliers
      }
    }
  }

  cat(paste("Total outliers capped:", outliers_removed, "\n"))

  # Log outlier handling
  cat(paste("Outliers handled for", data_name, ":", outliers_removed, "\n"),
      file = log_file)

  data
}

# Function to create technical indicators
create_technical_indicators <- function(data, data_name) {
  if (is.null(data)) NULL

  cat(paste("\nCreating technical indicators for", data_name, "...\n"))

  # Ensure data is sorted by date
  if ("date" %in% names(data)) {
    data <- data %>%
      dplyr::arrange(date) %>%
      dplyr::group_by(share_code) %>%
      dplyr::mutate(
        # Price change
        price_change_pct = (closing_price_vwap - lag(closing_price_vwap)) /
          lag(closing_price_vwap) * 100,

        # Moving averages
        ma_5 = zoo::rollmean(closing_price_vwap, k = 5, fill = NA,
                             align = "right"),
        ma_10 = zoo::rollmean(closing_price_vwap, k = 10, fill = NA,
                              align = "right"),
        ma_20 = zoo::rollmean(closing_price_vwap, k = 20, fill = NA,
                              align = "right"),

        # Volatility (rolling standard deviation)
        volatility_5 = zoo::rollapply(closing_price_vwap, width = 5,
                                      FUN = sd, fill = NA, align = "right"),
        volatility_10 = zoo::rollapply(closing_price_vwap, width = 10,
                                       FUN = sd, fill = NA, align = "right"),

        # Volume indicators
        volume_ma_5 = zoo::rollmean(total_shares_traded, k = 5, fill = NA,
                                    align = "right"),
        volume_ma_10 = zoo::rollmean(total_shares_traded, k = 10, fill = NA,
                                     align = "right"),

        # Price position within year range
        year_high_pct = (closing_price_vwap - year_low) /
          (year_high - year_low) * 100,

        # Trading activity indicators
        trading_activity = ifelse(total_shares_traded > 0, 1, 0),
        days_since_last_trade = cumsum(trading_activity)
      ) %>%
      dplyr::ungroup()

    cat("Technical indicators created\n")
  } else {
    cat("No date column found, skipping technical indicators\n")
  }

  data
}

# Function to validate cleaned data
validate_cleaned_data <- function(data, data_name) {
  if (is.null(data)) NULL

  cat(paste("\nValidating cleaned", data_name, "...\n"))

  # Check for remaining missing values
  missing_count <- sum(is.na(data))
  cat(paste("Remaining missing values:", missing_count, "\n"))

  # Check for infinite values
  numeric_cols <- dplyr::select_if(data, is.numeric)
  infinite_count <- sum(is.infinite(as.matrix(numeric_cols)))
  cat(paste("Infinite values:", infinite_count, "\n"))

  # Check data consistency
  if ("closing_price_vwap" %in% names(data) &&
        "opening_price" %in% names(data)) {
    negative_prices <- sum(data$closing_price_vwap < 0, na.rm = TRUE) +
      sum(data$opening_price < 0, na.rm = TRUE)
    cat(paste("Negative prices:", negative_prices, "\n"))
  }

  # Check date consistency
  if ("date" %in% names(data)) {
    date_issues <- sum(is.na(data$date))
    cat(paste("Date issues:", date_issues, "\n"))
  }

  # Log validation results
  cat(paste("Validation completed for", data_name, "\n"), file = log_file)
  cat(paste("Missing values:", missing_count, "\n"), file = log_file)
  cat(paste("Infinite values:", infinite_count, "\n"), file = log_file)

  data
}

# Clean the datasets
if (!is.null(daily_2023)) {
  cat("\nCleaning Daily 2023 data...\n")
  daily_2023 <- clean_column_names(daily_2023)
  daily_2023 <- handle_missing_values(daily_2023, "Daily 2023")
  daily_2023 <- handle_outliers(daily_2023, "Daily 2023")
  daily_2023 <- create_technical_indicators(daily_2023, "Daily 2023")
  daily_2023 <- validate_cleaned_data(daily_2023, "Daily 2023")
}

if (!is.null(historical_data)) {
  cat("\nCleaning Historical data...\n")
  historical_data <- clean_column_names(historical_data)
  historical_data <- handle_missing_values(historical_data, "Historical")
  historical_data <- handle_outliers(historical_data, "Historical")
  historical_data <- create_technical_indicators(historical_data, "Historical")
  historical_data <- validate_cleaned_data(historical_data, "Historical")
}

# Save cleaned data
if (!dir.exists("data/cleaned")) {
  dir.create("data/cleaned", recursive = TRUE)
}

if (!is.null(daily_2023)) {
  saveRDS(daily_2023, "data/cleaned/daily_2023_cleaned.rds")
  write_csv(daily_2023, "data/cleaned/daily_2023_cleaned.csv")
  cat("✓ Daily 2023 cleaned data saved\n")
}

if (!is.null(historical_data)) {
  saveRDS(historical_data, "data/cleaned/historical_cleaned.rds")
  write_csv(historical_data, "data/cleaned/historical_cleaned.csv")
  cat("✓ Historical cleaned data saved\n")
}

# Create cleaning summary report
cleaning_summary <- list(
  daily_2023_rows = if (!is.null(daily_2023)) nrow(daily_2023) else 0,
  historical_rows = if (!is.null(historical_data)) nrow(historical_data) else 0,
  cleaning_time = Sys.time(),
  missing_values_handled = TRUE,
  outliers_handled = TRUE,
  technical_indicators_created = TRUE
)

saveRDS(cleaning_summary, "data/cleaned/cleaning_summary.rds")

# Close log file
cat("Data cleaning completed at:", Sys.time(), "\n", file = log_file)
close(log_file)

# Display final summary
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("GSE DATA CLEANING SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

if (!is.null(daily_2023)) {
  cat("✓ Daily 2023 Data Cleaned:", nrow(daily_2023), "rows\n")
}

if (!is.null(historical_data)) {
  cat("✓ Historical Data Cleaned:", nrow(historical_data), "rows\n")
}

cat("✓ Missing values handled\n")
cat("✓ Outliers capped\n")
cat("✓ Technical indicators created\n")
cat("✓ Cleaned data saved to: data/cleaned/\n")
cat("✓ Cleaning summary saved\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nData cleaning completed successfully!\n")
cat("Next step: Run modeling script (03_modeling.R)\n")
