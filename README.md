# Ghana Stock Exchange (GSE) Stock Price Prediction Model

## Project Overview

This project develops machine learning models to predict stock prices for companies listed on the Ghana Stock Exchange (GSE). The analysis focuses on major Ghanaian companies and uses time series forecasting techniques to predict future stock movements.

## About the Ghana Stock Exchange

The Ghana Stock Exchange is the principal stock exchange of Ghana, located in Accra. This project analyzes stocks from major sectors including:
- Banking (GCB Bank, Ecobank Ghana, CAL Bank)
- Mining (AngloGold Ashanti, Newmont Ghana)
- Telecommunications (MTN Ghana)
- Consumer Goods (Fan Milk, Unilever Ghana)

## Features

- **Data Collection**: Automated scraping of GSE stock prices and financial indicators
- **Multiple Models**: ARIMA, Linear Regression, and Random Forest predictions
- **Interactive Visualizations**: Dashboard for exploring stock trends
- **Performance Metrics**: Model evaluation with backtesting capabilities
- **Ghana-Specific Analysis**: Incorporates local economic indicators and market holidays

## Project Structure

```
gse-stock-prediction/
├── README.md
├── .gitignore
├── gse-stock-prediction.Rproj
├── renv.lock
├── data/
├── scripts/
├── models/
├── output/
├── docs/
├── tests/
└── app/
```

## Prerequisites

### Software Requirements
- R (version 4.0 or higher)
- RStudio (recommended IDE)
- Git for version control

### R Packages
The following packages will be installed automatically:
- `tidyverse` - Data manipulation and visualization
- `quantmod` - Financial data analysis
- `forecast` - Time series forecasting
- `shiny` - Interactive web applications
- `plotly` - Interactive plots
- `rmarkdown` - Report generation
- `testthat` - Unit testing
- `renv` - Package management

## Installation

1. Clone this repository:
```bash
git clone https://github.com/Bempong-Sylvester-Obese/gse-stock-prediction.git
cd gse-stock-prediction
```

2. Open the project in RStudio by double-clicking `gse-stock-prediction.Rproj`

3. Restore the R environment:
```r
renv::restore()
```

4. Install additional dependencies:
```r
source("scripts/00_setup.R")
```

## Usage

### Quick Start
1. Run the setup script to install all dependencies
2. Execute data collection: `source("scripts/01_data_collection.R")`
3. Generate predictions: `source("scripts/03_modeling.R")`
4. View results in the Shiny app: `source("app/app.R")`

### Step-by-Step Analysis
1. **Data Collection** - Gather historical stock prices from GSE
2. **Data Cleaning** - Handle missing values and outliers
3. **Exploratory Analysis** - Visualize trends and patterns
4. **Feature Engineering** - Create technical indicators
5. **Model Training** - Build and train prediction models
6. **Model Evaluation** - Test model performance
7. **Prediction** - Generate future price forecasts

## Data Sources

- **Primary**: Ghana Stock Exchange official data
- **Secondary**: Yahoo Finance for additional historical data
- **Economic Indicators**: Bank of Ghana economic data
- **Market News**: Ghana business news sentiment analysis

## Models Included

1. **ARIMA (AutoRegressive Integrated Moving Average)**
   - Best for: Short-term predictions
   - Strengths: Handles seasonality well

2. **Linear Regression with Technical Indicators**
   - Best for: Understanding price relationships
   - Strengths: Interpretable results

3. **Random Forest**
   - Best for: Complex pattern recognition
   - Strengths: Handles non-linear relationships

## Key Files Description

- `scripts/01_data_collection.R` - Downloads and processes stock data
- `scripts/02_data_cleaning.R` - Cleans and prepares data for analysis
- `scripts/03_modeling.R` - Builds and trains prediction models
- `scripts/04_evaluation.R` - Evaluates model performance
- `app/app.R` - Interactive Shiny dashboard
- `docs/analysis_report.Rmd` - Comprehensive analysis report

## Results and Performance

Model performance will be evaluated using:
- Mean Absolute Error (MAE)
- Root Mean Square Error (RMSE)
- Mean Absolute Percentage Error (MAPE)
- Directional Accuracy (predicting price direction)

## Limitations and Disclaimers

⚠️ **Important Disclaimer**: This project is for educational and research purposes only. It should NOT be used as the sole basis for investment decisions.

- Models are based on historical data and may not predict future performance
- Ghana Stock Exchange has unique characteristics that may affect model accuracy
- External factors (political events, global market conditions) are not fully captured
- Always consult with financial professionals before making investment decisions

## Future Enhancements

- [ ] Real-time data integration
- [ ] More sophisticated deep learning models
- [ ] Integration with news sentiment analysis
- [ ] Mobile-responsive dashboard
- [ ] Email alerts for price predictions
- [ ] Portfolio optimization features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
