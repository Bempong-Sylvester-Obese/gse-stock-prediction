# GSE Stock Prediction - Modeling Script

# Load required libraries
library(tidyverse)
library(forecast)
library(randomForest)
library(caret)
library(lubridate)
library(here)
library(plotly)

# Suppress variable binding warnings for dplyr operations
utils::globalVariables(c("share_code", "closing_price_vwap", "price_lag_1",
                         "price_lag_2", "price_lag_3", "price_lag_5",
                         "total_shares_traded", "volume_lag_1", "count", "n",
                         ".", "desc", "arrange", "group_by", "mutate", "select",
                         "summarise", "ungroup", "all_of", "%>%", "auto.arima",
                         "forecast", "randomForest"))

# Working directory
setwd(here::here())

# Create log file
log_file <- file("logs/modeling.log", open = "w")
cat("GSE Modeling Started at:", Sys.time(), "\n", file = log_file)

# Load cleaned data
cat("Loading cleaned data...\n")

if (file.exists("data/cleaned/daily_2023_cleaned.rds")) {
  daily_data <- readRDS("data/cleaned/daily_2023_cleaned.rds")
  cat("Daily 2023 data loaded\n")
} else {
  cat("⚠ Daily 2023 cleaned data not found. Run 02_data_cleaning.R first.\n")
  daily_data <- NULL
}

if (file.exists("data/cleaned/historical_cleaned.rds")) {
  historical_data <- readRDS("data/cleaned/historical_cleaned.rds")
  cat("✓ Historical data loaded\n")
} else {
  cat("⚠ Historical cleaned data not found. Run 02_data_cleaning.R first.\n")
  historical_data <- NULL
}

# Function to prepare data for modeling
prepare_modeling_data <- function(data, target_stock = NULL) {
  if (is.null(data)) return(NULL)

  cat("Preparing data for modeling...\n")

  # Filter for specific stock if provided
  if (!is.null(target_stock)) {
    data <- data %>%
      filter(share_code == target_stock)
    cat(paste("Filtered for stock:", target_stock, "\n"))
  }

  # Ensure data is sorted by date
  data <- data %>%
    arrange(date) %>%
    filter(!is.na(closing_price_vwap)) %>%
    filter(closing_price_vwap > 0)

  # Create lagged features
  data <- data %>%
    group_by(share_code) %>%
    mutate(
      price_lag_1 = lag(closing_price_vwap, 1),
      price_lag_2 = lag(closing_price_vwap, 2),
      price_lag_3 = lag(closing_price_vwap, 3),
      price_lag_5 = lag(closing_price_vwap, 5),
      price_lag_10 = lag(closing_price_vwap, 10),

      # Price changes
      price_change_1 = closing_price_vwap - price_lag_1,
      price_change_2 = closing_price_vwap - price_lag_2,
      price_change_5 = closing_price_vwap - price_lag_5,

      # Volume features
      volume_lag_1 = lag(total_shares_traded, 1),
      volume_change = total_shares_traded - volume_lag_1,

      # Technical indicators
      rsi = calculate_rsi(closing_price_vwap, 14),
      macd = calculate_macd(closing_price_vwap),
      bollinger_upper = calculate_bollinger_upper(closing_price_vwap, 20),
      bollinger_lower = calculate_bollinger_lower(closing_price_vwap, 20)
    ) %>%
    ungroup()

  # Remove rows with missing values
  data <- data %>%
    filter(!is.na(price_lag_1)) %>%
    filter(!is.na(price_lag_2)) %>%
    filter(!is.na(price_lag_3))

  cat(paste("Prepared data:", nrow(data), "rows\n"))

  return(data)
}

# Technical indicator functions
calculate_rsi <- function(prices, period = 14) {
  if (length(prices) < period + 1) return(rep(NA, length(prices)))

  gains <- pmax(diff(prices), 0)
  losses <- pmax(-diff(prices), 0)

  avg_gain <- zoo::rollmean(gains, period, fill = NA, align = "right")
  avg_loss <- zoo::rollmean(losses, period, fill = NA, align = "right")

  rs <- avg_gain / avg_loss
  rsi <- 100 - (100 / (1 + rs))

  return(c(rep(NA, 1), rsi))
}

calculate_macd <- function(prices, fast = 12, slow = 26, signal = 9) {
  if (length(prices) < slow) return(rep(NA, length(prices)))

  ema_fast <- zoo::rollmean(prices, fast, fill = NA, align = "right")
  ema_slow <- zoo::rollmean(prices, slow, fill = NA, align = "right")

  macd_line <- ema_fast - ema_slow
  return(macd_line)
}

calculate_bollinger_upper <- function(prices, period = 20, std_dev = 2) {
  if (length(prices) < period) return(rep(NA, length(prices)))

  sma <- zoo::rollmean(prices, period, fill = NA, align = "right")
  std <- zoo::rollapply(prices, period, sd, fill = NA, align = "right")

  return(sma + (std * std_dev))
}

calculate_bollinger_lower <- function(prices, period = 20, std_dev = 2) {
  if (length(prices) < period) return(rep(NA, length(prices)))

  sma <- zoo::rollmean(prices, period, fill = NA, align = "right")
  std <- zoo::rollapply(prices, period, sd, fill = NA, align = "right")

  return(sma - (std * std_dev))
}

# ARIMA Model Function
train_arima_model <- function(data, stock_code) {
  cat(paste("Training ARIMA model for", stock_code, "...\n"))

  # Filter data for specific stock
  stock_data <- data %>%
    filter(share_code == stock_code) %>%
    arrange(date)

  if (nrow(stock_data) < 30) {
    cat(paste("⚠ Insufficient data for", stock_code, "\n"))
    return(NULL)
  }

  # Create time series
  ts_data <- ts(stock_data$closing_price_vwap, frequency = 1)

  # Split data into train and test
  train_size <- floor(0.8 * length(ts_data))
  train_data <- ts_data[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]

  tryCatch({
    # Fit ARIMA model
    arima_model <- auto.arima(train_data,
                              seasonal = FALSE,
                              stepwise = TRUE,
                              approximation = TRUE)

    # Make predictions
    forecast_result <- forecast(arima_model, h = length(test_data))

    # Calculate metrics
    predictions <- as.numeric(forecast_result$mean)
    actual <- as.numeric(test_data)

    mae <- mean(abs(predictions - actual), na.rm = TRUE)
    rmse <- sqrt(mean((predictions - actual)^2, na.rm = TRUE))
    mape <- mean(abs((actual - predictions) / actual), na.rm = TRUE) * 100

    # Directional accuracy
    actual_direction <- sign(diff(actual))
    pred_direction <- sign(diff(predictions))
    directional_accuracy <- mean(actual_direction == pred_direction,
                                 na.rm = TRUE) * 100

    model_results <- list(
      model = arima_model,
      predictions = predictions,
      actual = actual,
      mae = mae,
      rmse = rmse,
      mape = mape,
      directional_accuracy = directional_accuracy,
      stock_code = stock_code,
      model_type = "ARIMA"
    )

    cat(paste("ARIMA model trained for", stock_code, "\n"))
    cat(paste("  MAE:", round(mae, 4), "\n"))
    cat(paste("  RMSE:", round(rmse, 4), "\n"))
    cat(paste("  MAPE:", round(mape, 2), "%\n"))
    cat(paste("  Directional Accuracy:", round(directional_accuracy, 2), "%\n"))

    return(model_results)

  }, error = function(e) {
    cat(paste("✗ Error training ARIMA for", stock_code, ":", e$message, "\n"))
    NULL
  })
}

# Linear Regression Model Function
train_linear_model <- function(data, stock_code) {
  cat(paste("Training Linear Regression model for", stock_code, "...\n"))

  # Filter data for specific stock
  stock_data <- data %>%
    filter(share_code == stock_code) %>%
    arrange(date) %>%
    filter(!is.na(price_lag_1) & !is.na(price_lag_2) & !is.na(price_lag_3))

  if (nrow(stock_data) < 30) {
    cat(paste("Insufficient data for", stock_code, "\n"))
    return(NULL)
  }

  # Prepare features
  features <- c("price_lag_1", "price_lag_2",
                "price_lag_3", "price_lag_5", "price_lag_10",
                "ma_5", "ma_10", "ma_20", "volatility_5", "volatility_10",
                "volume_ma_5", "volume_ma_10", "year_high_pct")

  # Select available features
  available_features <- features[features %in% names(stock_data)]

  # Create formula
  formula_str <- paste("closing_price_vwap ~",
                       paste(available_features, collapse = " + "))
  formula <- as.formula(formula_str)

  # Split data
  train_size <- floor(0.8 * nrow(stock_data))
  train_data <- stock_data[1:train_size, ]
  test_data <- stock_data[(train_size + 1):nrow(stock_data), ]

  tryCatch({
    # Train model
    linear_model <- lm(formula, data = train_data)

    # Make predictions
    predictions <- predict(linear_model, newdata = test_data)
    actual <- test_data$closing_price_vwap

    # Calculate metrics
    mae <- mean(abs(predictions - actual), na.rm = TRUE)
    rmse <- sqrt(mean((predictions - actual)^2, na.rm = TRUE))
    mape <- mean(abs((actual - predictions) / actual), na.rm = TRUE) * 100

    # Directional accuracy
    actual_direction <- sign(diff(actual))
    pred_direction <- sign(diff(predictions))
    directional_accuracy <- mean(actual_direction == pred_direction,
                                 na.rm = TRUE) * 100

    model_results <- list(
      model = linear_model,
      predictions = predictions,
      actual = actual,
      mae = mae,
      rmse = rmse,
      mape = mape,
      directional_accuracy = directional_accuracy,
      stock_code = stock_code,
      model_type = "Linear Regression"
    )

    cat(paste("✓ Linear Regression model trained for", stock_code, "\n"))
    cat(paste("  MAE:", round(mae, 4), "\n"))
    cat(paste("  RMSE:", round(rmse, 4), "\n"))
    cat(paste("  MAPE:", round(mape, 2), "%\n"))
    cat(paste("  Directional Accuracy:", round(directional_accuracy, 2), "%\n"))

    return(model_results)

  }, error = function(e) {
    cat(paste("Error training Linear Regression for",
              stock_code, ":", e$message, "\n"))
    NULL
  })
}

# Random Forest Model Function
train_random_forest_model <- function(data, stock_code) {
  cat(paste("Training Random Forest model for", stock_code, "...\n"))

  # Filter data for specific stock
  stock_data <- data %>%
    filter(share_code == stock_code) %>%
    arrange(date) %>%
    filter(!is.na(price_lag_1) & !is.na(price_lag_2) & !is.na(price_lag_3))

  if (nrow(stock_data) < 30) {
    cat(paste("Insufficient data for", stock_code, "\n"))
    return(NULL)
  }

  # Prepare features
  features <- c("price_lag_1", "price_lag_2",
                "price_lag_3", "price_lag_5", "price_lag_10",
                "ma_5", "ma_10", "ma_20", "volatility_5", "volatility_10",
                "volume_ma_5", "volume_ma_10", "year_high_pct")

  # Select available features
  available_features <- features[features %in% names(stock_data)]

  # Prepare data for Random Forest
  rf_data <- stock_data %>%
    select(all_of(c("closing_price_vwap", available_features))) %>%
    filter(complete.cases(.))

  if (nrow(rf_data) < 20) {
    cat(paste("Insufficient complete cases for", stock_code, "\n"))
    return(NULL)
  }

  # Split data
  train_size <- floor(0.8 * nrow(rf_data))
  train_data <- rf_data[1:train_size, ]
  test_data <- rf_data[(train_size + 1):nrow(rf_data), ]

  tryCatch({
    # Train Random Forest
    rf_model <- randomForest(closing_price_vwap ~ .,
                             data = train_data,
                             ntree = 100,
                             mtry = floor(sqrt(length(available_features))),
                             importance = TRUE)

    # Make predictions
    predictions <- predict(rf_model, newdata = test_data)
    actual <- test_data$closing_price_vwap

    # Calculate metrics
    mae <- mean(abs(predictions - actual), na.rm = TRUE)
    rmse <- sqrt(mean((predictions - actual)^2, na.rm = TRUE))
    mape <- mean(abs((actual - predictions) / actual), na.rm = TRUE) * 100

    # Directional accuracy
    actual_direction <- sign(diff(actual))
    pred_direction <- sign(diff(predictions))
    directional_accuracy <- mean(actual_direction == pred_direction,
                                 na.rm = TRUE) * 100

    model_results <- list(
      model = rf_model,
      predictions = predictions,
      actual = actual,
      mae = mae,
      rmse = rmse,
      mape = mape,
      directional_accuracy = directional_accuracy,
      stock_code = stock_code,
      model_type = "Random Forest"
    )

    cat(paste("Random Forest model trained for", stock_code, "\n"))
    cat(paste("  MAE:", round(mae, 4), "\n"))
    cat(paste("  RMSE:", round(rmse, 4), "\n"))
    cat(paste("  MAPE:", round(mape, 2), "%\n"))
    cat(paste("  Directional Accuracy:", round(directional_accuracy, 2), "%\n"))

    return(model_results)

  }, error = function(e) {
    cat(paste("Error training Random Forest for",
              stock_code, ":", e$message, "\n"))
    NULL
  })
}

# Main modeling function
run_modeling_pipeline <- function(data) {
  if (is.null(data)) {
    cat("No data available for modeling\n")
    return(NULL)
  }

  # Get unique stock codes
  stock_codes <- unique(data$share_code)
  cat(paste("Found", length(stock_codes), "unique stocks\n"))

  # Prepare data for modeling
  modeling_data <- prepare_modeling_data(data)

  if (is.null(modeling_data)) {
    cat("Failed to prepare modeling data\n")
    return(NULL)
  }

  # Select top stocks by data availability
  stock_counts <- modeling_data %>%
    group_by(share_code) %>%
    summarise(count = n(), .groups = "drop") %>%
    arrange(desc(count)) %>%
    head(10)  # Top 10 stocks with most data

  cat(paste("Selected top", nrow(stock_counts), "stocks for modeling\n"))

  all_results <- list()

  # Train models for each stock
  for (i in seq_len(nrow(stock_counts))) {
    stock_code <- stock_counts$share_code[i]
    cat(paste("\nProcessing stock", i, "of", nrow(stock_counts),
              ":", stock_code, "\n"))

    # Train ARIMA model
    arima_result <- train_arima_model(modeling_data, stock_code)
    if (!is.null(arima_result)) {
      all_results[[paste(stock_code, "ARIMA")]] <- arima_result
    }

    # Train Linear Regression model
    linear_result <- train_linear_model(modeling_data, stock_code)
    if (!is.null(linear_result)) {
      all_results[[paste(stock_code, "Linear")]] <- linear_result
    }

    # Train Random Forest model
    rf_result <- train_random_forest_model(modeling_data, stock_code)
    if (!is.null(rf_result)) {
      all_results[[paste(stock_code, "RF")]] <- rf_result
    }
  }

  all_results
}

# Run the modeling pipeline
if (!is.null(daily_data)) {
  cat("\nRunning modeling pipeline on daily data...\n")
  daily_results <- run_modeling_pipeline(daily_data)
}

if (!is.null(historical_data)) {
  cat("\nRunning modeling pipeline on historical data...\n")
  historical_results <- run_modeling_pipeline(historical_data)
}

# Save model results
if (!dir.exists("models/trained")) {
  dir.create("models/trained", recursive = TRUE)
}

if (exists("daily_results") && !is.null(daily_results)) {
  saveRDS(daily_results, "models/trained/daily_models.rds")
  cat("✓ Daily models saved\n")
}

if (exists("historical_results") && !is.null(historical_results)) {
  saveRDS(historical_results, "models/trained/historical_models.rds")
  cat("✓ Historical models saved\n")
}

# Model comparison summary
create_model_summary <- function(results) {
  if (is.null(results)) return(NULL)

  summary_data <- data.frame(
    model_name = names(results),
    stock_code = sapply(results, function(x) x$stock_code),
    model_type = sapply(results, function(x) x$model_type),
    mae = sapply(results, function(x) x$mae),
    rmse = sapply(results, function(x) x$rmse),
    mape = sapply(results, function(x) x$mape),
    directional_accuracy = sapply(results, function(x) x$directional_accuracy)
  )

  summary_data
}

# Summaries
if (exists("daily_results")) {
  daily_summary <- create_model_summary(daily_results)
  if (!is.null(daily_summary)) {
    saveRDS(daily_summary, "models/trained/daily_model_summary.rds")
    write_csv(daily_summary, "models/trained/daily_model_summary.csv")
  }
}

if (exists("historical_results")) {
  historical_summary <- create_model_summary(historical_results)
  if (!is.null(historical_summary)) {
    saveRDS(historical_summary, "models/trained/historical_model_summary.rds")
    write_csv(historical_summary, "models/trained/historical_model_summary.csv")
  }
}

# Close log file
cat("Modeling completed at:", Sys.time(), "\n", file = log_file)
close(log_file)

# Final summary
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("GSE MODELING SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

if (exists("daily_results")) {
  cat("Daily models trained:", length(daily_results), "models\n")
}

if (exists("historical_results")) {
  cat("Historical models trained:", length(historical_results), "models\n")
}

cat("Models saved to: models/trained/\n")
cat("Model summaries generated\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nModeling completed successfully!\n")
cat("Next step: Run evaluation script (04_evaluation.R) or start Shiny app\n")
