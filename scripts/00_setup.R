# GSE Stock Prediction Project Setup Script
# This script sets up the project environment and loads required packages

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Set working directory to project root
if (!require(here)) {
  install.packages("here")
  library(here)
}

# Set project root
project_root <- here::here()
setwd(project_root)

# Load required packages
required_packages <- c(
  "tidyverse",      # Data manipulation and visualization
  "quantmod",       # Financial data analysis
  "forecast",       # Time series forecasting
  "plotly",         # Interactive plots
  "DT",             # Data tables
  "lubridate",      # Date manipulation
  "zoo",            # Time series objects
  "randomForest",   # Random Forest model
  "caret",          # Machine learning
  "e1071",          # SVM and other ML algorithms
  "VIM",            # Missing data visualizations
  "corrplot",       # Correlation plots
  "gridExtra",      # Grid arrangements
  "knitr",          # Report generation
  "rmarkdown",      # Markdown reports
  "shiny",          # Web applications
  "testthat"        # Unit testing
)

# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# Install and load all required packages
cat("Setting up GSE Stock Prediction Project...\n")
cat("Loading required packages...\n")

for (pkg in required_packages) {
  cat(paste("Loading", pkg, "...\n"))
  install_and_load(pkg)
}

# Create necessary directories if they don't exist
directories <- c(
  "data/processed",
  "data/cleaned",
  "output/plots",
  "output/reports",
  "output/predictions",
  "models/trained",
  "models/saved",
  "logs"
)

for (dir in directories) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat(paste("Created directory:", dir, "\n"))
  }
}

# Set up project configuration
config <- list(
  project_name = "GSE Stock Prediction",
  version = "1.0.0",
  data_path = "data/raw",
  output_path = "output",
  models_path = "models",
  logs_path = "logs",
  date_format = "%d/%m/%Y",
  currency = "GHS",
  timezone = "Africa/Accra"
)

# Save configuration
saveRDS(config, "config/project_config.rds")

# Create log file
log_file <- file("logs/setup.log", open = "w")
cat("GSE Stock Prediction Project Setup\n", file = log_file)
cat("Setup completed at:", Sys.time(), "\n", file = log_file)
cat("R version:", R.version.string, "\n", file = log_file)
cat("Working directory:", getwd(), "\n", file = log_file)
close(log_file)

# Display project information
cat("\n")
cat(paste(rep("=", 50), collapse = ""), "\n")
cat("GSE Stock Prediction Project Setup Complete!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")
cat("Project Root:", project_root, "\n")
cat("R Version:", R.version.string, "\n")
cat("Packages Loaded:", length(required_packages), "\n")
cat("Setup Time:", Sys.time(), "\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Test data loading capability
cat("\nTesting data loading...\n")
if (file.exists("data/raw/Daily Shares  ETFs 2023.csv")) {
  cat("✓ Raw data files found\n")
} else {
  cat("⚠ Raw data files not found\n")
}

if (file.exists("data/raw/Updated-gse efts and shares.csv")) {
  cat("✓ Historical data files found\n")
} else {
  cat("⚠ Historical data files not found\n")
}

cat("\nSetup completed successfully!\n")
cat("You can now run the data collection and analysis scripts.\n")
