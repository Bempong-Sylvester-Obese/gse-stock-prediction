# GSE Stock Prediction Project Configuration
# This file contains all project configuration settings

# Project Information
project_name <- "GSE Stock Prediction"
project_version <- "1.0.0"
project_description <- "Machine learning models 
for predicting Ghana Stock Exchange stock prices"

# Data Configuration
data_config <- list(
  # Raw data paths
  raw_data_path = "data/raw",
  daily_2023_file = "Daily Shares  ETFs 2023.csv",
  historical_file = "Updated-gse efts and shares.csv",

  # Processed data paths
  processed_data_path = "data/processed",
  cleaned_data_path = "data/cleaned",

  # Data quality thresholds
  min_data_points = 30,
  max_missing_percentage = 50,
  outlier_threshold = 3,  # Standard deviations

  # Date configuration
  date_format = "%d/%m/%Y",
  timezone = "Africa/Accra",
  currency = "GHS"
)

# Model Configuration
model_config <- list(
  # Model types
  model_types = c("ARIMA", "Linear Regression", "Random Forest"),

  # Training parameters
  train_test_split = 0.8,
  min_training_samples = 30,

  # ARIMA parameters
  arima_seasonal = FALSE,
  arima_stepwise = TRUE,
  arima_approximation = TRUE,

  # Random Forest parameters
  rf_ntree = 100,
  rf_mtry_ratio = 0.5,

  # Feature engineering
  technical_indicators = c("ma_5", "ma_10", "ma_20",
                           "volatility_5", "volatility_10"),
  lag_features = c("price_lag_1", "price_lag_2", "price_lag_3",
                   "price_lag_5", "price_lag_10"),

  # Prediction horizon
  max_prediction_days = 30,
  default_prediction_days = 7
)

# Performance Metrics
performance_metrics <- list(
  primary_metrics = c("MAE", "RMSE", "MAPE", "Directional_Accuracy"),
  metric_thresholds = list(
    MAE = 0.5,  # Maximum acceptable MAE
    RMSE = 1.0,  # Maximum acceptable RMSE
    MAPE = 10.0,  # Maximum acceptable MAPE (%)
    Directional_Accuracy = 60.0  # Minimum acceptable directional accuracy (%)
  )
)

# Shiny App Configuration
shiny_config <- list(
  app_title = "GSE Stock Prediction Dashboard",
  host = "127.0.0.1",
  port = 3838,
  max_file_size = 100 * 1024 * 1024,  # 100MB

  # Chart configuration
  chart_height = 400,
  chart_colors = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"),

  # Data table configuration
  default_page_length = 20,
  scroll_x = TRUE
)

# Logging Configuration
logging_config <- list(
  log_level = "INFO",
  log_file = "logs/application.log",
  max_log_size = 10 * 1024 * 1024,  # 10MB
  backup_count = 5
)

# Output Configuration
output_config <- list(
  # Output directories
  plots_dir = "output/plots",
  reports_dir = "output/reports",
  predictions_dir = "output/predictions",
  models_dir = "models/trained",

  # File formats
  plot_format = "png",
  plot_dpi = 300,
  report_format = "html",

  # Report configuration
  report_title = "GSE Stock Prediction Analysis Report",
  report_author = "GSE Prediction Team",
  report_date = Sys.Date()
)

# Stock Selection Configuration
stock_config <- list(
  # Priority stocks for analysis
  priority_stocks = c("GCB", "MTN", "CAL", "FML", "GOIL", "BOPP", "EGH", "ETI"),

  # Stock categories
  banking_stocks = c("GCB", "CAL", "ETI"),
  telecom_stocks = c("MTN"),
  consumer_stocks = c("FML", "BOPP"),
  energy_stocks = c("GOIL"),
  mining_stocks = c("EGH"),

  # Minimum data requirements
  min_trading_days = 100,
  min_volume_threshold = 1000
)

# API Configuration (for future enhancements)
api_config <- list(
  # External data sources
  yahoo_finance_enabled = FALSE,
  gse_api_enabled = FALSE,

  # Rate limiting
  max_requests_per_minute = 60,
  request_timeout = 30,

  # Data refresh
  auto_refresh_interval = 3600,  # 1 hour in seconds
  manual_refresh_enabled = TRUE
)

# Security Configuration
security_config <- list(
  # Data access
  require_authentication = FALSE,
  session_timeout = 3600,  # 1 hour in seconds

  # Data privacy
  anonymize_data = FALSE,
  log_user_actions = TRUE,

  # File upload security
  allowed_file_types = c("csv", "xlsx", "rds"),
  max_upload_size = 50 * 1024 * 1024  # 50MB
)

# Development Configuration
dev_config <- list(
  # Debug settings
  debug_mode = FALSE,
  verbose_logging = TRUE,

  # Testing
  run_tests_on_startup = TRUE,
  test_coverage_threshold = 80,

  # Development tools
  profiler_enabled = FALSE,
  memory_monitoring = FALSE
)

# Export all configurations
export_config <- function() {
  config_list <- list(
    PROJECT_NAME = project_name,
    PROJECT_VERSION = project_version,
    PROJECT_DESCRIPTION = project_description,
    DATA_CONFIG = data_config,
    MODEL_CONFIG = model_config,
    performance_metrics = performance_metrics,
    shiny_config = shiny_config,
    logging_config = logging_config,
    output_config = output_config,
    stock_config = stock_config,
    api_config = api_config,
    security_config = security_config,
    dev_config = dev_config
  )
  config_list
}

# Save configuration to file
save_config <- function() {
  config <- export_config()
  saveRDS(config, "config/project_config.rds")
  cat("Configuration saved to config/project_config.rds\n")
}

# Load configuration from file
load_config <- function() {
  if (file.exists("config/project_config.rds")) {
    config <- readRDS("config/project_config.rds")
    cat("Configuration loaded from config/project_config.rds\n")
    return(config)
  } else {
    cat("Configuration file not found. Using default configuration.\n")
    export_config()
  }
}

# Initialize configuration
init_config <- function() {
  # Create config directory if it doesn't exist
  if (!dir.exists("config")) {
    dir.create("config", recursive = TRUE)
  }

  # Save initial configuration
  save_config()

  cat("Project configuration initialized\n")
}

# Get specific configuration section
get_config <- function(section) {
  config <- load_config()

  if (section %in% names(config)) {
    config[[section]]
  } else {
    stop("Configuration section '", section, "' not found")
  }
}

# Update configuration
update_config <- function(section, updates) {
  config <- load_config()
  if (section %in% names(config)) {
    config[[section]] <- modifyList(config[[section]], updates)
    saveRDS(config, "config/project_config.rds")
    cat("Configuration updated for section:", section, "\n")
  } else {
    stop("Configuration section '", section, "' not found")
  }
}

# Display configuration summary
show_config_summary <- function() {
  config <- load_config()
  cat("GSE Stock Prediction Project Configuration\n")
  cat("=" * 50 + "\n")
  cat("Project Name:", config$PROJECT_NAME, "\n")
  cat("Version:", config$PROJECT_VERSION, "\n")
  cat("Description:", config$PROJECT_DESCRIPTION, "\n")
  cat("Data Path:", config$DATA_CONFIG$raw_data_path, "\n")
  cat("Models:", paste(config$MODEL_CONFIG$model_types, collapse = ", "), "\n")
  cat("Shiny App:", config$shiny_config$app_title, "\n")
  cat("=" * 50 + "\n")
}

# Initialize configuration when script is sourced
if (interactive()) {
  init_config()
  show_config_summary()
}
