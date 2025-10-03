#'Interactive dashboard for exploring GSE stock predictions

# Load required libraries
library(shiny)
library(tidyverse)
library(plotly)
library(DT)
library(here)
library(lubridate)

utils::globalVariables(c("closing_price_vwap", "share_code", "date",
                         "total_shares_traded", "price_change_pct", "ma_5",
                         "ma_10", "volatility_5", "price", "type", "Model",
                         "MAE", "count", "n", ".", "desc", "arrange",
                         "group_by", "mutate", "select", "summarise",
                         "ungroup", "all_of", "%>%", "auto.arima",
                         "forecast", "randomForest"))

# Set working directory
setwd(here::here())

# UI Definition
ui <- fluidPage(
  titlePanel("GSE Stock Prediction Dashboard"),

  # Sidebar layout
  sidebarLayout(
    sidebarPanel(
      width = 3,
      # Stock selection
      selectInput("stock_code",
                  "Select Stock:",
                  choices = NULL,
                  selected = NULL),
      # Model selection
      selectInput("model_type",
                  "Select Model:",
                  choices = c("ARIMA", "Linear Regression", "Random Forest"),
                  selected = "ARIMA"),
      # Date range selection
      dateRangeInput("date_range",
                     "Date Range:",
                     start = Sys.Date() - 365,
                     end = Sys.Date(),
                     format = "yyyy-mm-dd"),
      # Prediction horizon
      sliderInput("prediction_days",
                  "Prediction Horizon (days):",
                  min = 1,
                  max = 30,
                  value = 7,
                  step = 1),
      # Action buttons
      actionButton("run_prediction", "Run Prediction",
                   class = "btn-primary"),
      br(), br(),
      actionButton("refresh_data", "Refresh Data",
                   class = "btn-secondary"),
      # Model performance summary
      h4("Model Performance"),
      verbatimTextOutput("model_performance")
    ),
    # Main panel
    mainPanel(
      width = 9,
      # Tab layout
      tabsetPanel(
        id = "main_tabs",
        # Overview tab
        tabPanel("Overview",
          fluidRow(
            column(12,
              h3("Stock Price Overview"),
              plotly::plotlyOutput("price_chart", height = "400px")
            )
          ),
          fluidRow(
            column(6,
              h4("Recent Performance"),
              DT::dataTableOutput("performance_table")
            ),
            column(6,
              h4("Key Statistics"),
              verbatimTextOutput("stock_stats")
            )
          )
        ),
        # Predictions tab
        tabPanel("Predictions",
          fluidRow(
            column(12,
              h3("Price Predictions"),
              plotlyOutput("prediction_chart", height = "500px")
            )
          ),
          fluidRow(
            column(12,
              h4("Prediction Details"),
              DT::dataTableOutput("prediction_table")
            )
          )
        ),

        # Model Comparison tab
        tabPanel("Model Comparison",
          fluidRow(
            column(12,
              h3("Model Performance Comparison"),
              plotlyOutput("model_comparison_chart", height = "400px")
            )
          ),
          fluidRow(
            column(12,
              h4("Model Metrics"),
              DT::dataTableOutput("model_metrics_table")
            )
          )
        ),
        # Data Explorer tab
        tabPanel("Data Explorer",
          fluidRow(
            column(12,
              h3("Historical Data Explorer"),
              DT::dataTableOutput("data_table")
            )
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {

  # Load data and models
  data_loaded <- shiny::reactive({
    # Load cleaned data
    if (file.exists("data/cleaned/daily_2023_cleaned.rds")) {
      daily_data <- readRDS("data/cleaned/daily_2023_cleaned.rds")
    } else {
      daily_data <- NULL
    }
    if (file.exists("data/cleaned/historical_cleaned.rds")) {
      historical_data <- readRDS("data/cleaned/historical_cleaned.rds")
    } else {
      historical_data <- NULL
    }

    # Load model results
    if (file.exists("models/trained/daily_models.rds")) {
      daily_models <- readRDS("models/trained/daily_models.rds")
    } else {
      daily_models <- NULL
    }

    if (file.exists("models/trained/historical_models.rds")) {
      historical_models <- readRDS("models/trained/historical_models.rds")
    } else {
      historical_models <- NULL
    }
    list(
      daily_data = daily_data,
      historical_data = historical_data,
      daily_models = daily_models,
      historical_models = historical_models
    )
  })
  # Update stock selection choices
  shiny::observe({
    data <- data_loaded()
    if (!is.null(data$daily_data)) {
      stock_choices <- unique(data$daily_data$share_code)
    } else if (!is.null(data$historical_data)) {
      stock_choices <- unique(data$historical_data$share_code)
    } else {
      stock_choices <- c("No data available")
    }
    shiny::updateSelectInput(session, "stock_code", choices = stock_choices)
  })

  # Get current data
  current_data <- shiny::reactive({
    data <- data_loaded()
    if (!is.null(data$daily_data)) {
      return(data$daily_data)
    } else if (!is.null(data$historical_data)) {
      return(data$historical_data)
    } else {
      return(NULL)
    }
  })
  # Get filtered data for selected stock
  filtered_data <- shiny::reactive({
    data <- current_data()
    if (is.null(data) || is.null(input$stock_code)) return(NULL)
    data %>%
      dplyr::filter(share_code == input$stock_code) %>%
      dplyr::filter(date >= input$date_range[1] &
                      date <= input$date_range[2]) %>%
      dplyr::arrange(date)
  })
  # Price chart
  output$price_chart <- plotly::renderPlotly({
    data <- filtered_data()
    if (is.null(data)) return(NULL)
    p <- ggplot2::ggplot(data, ggplot2::aes(x = date, y = closing_price_vwap)) +
      ggplot2::geom_line(color = "blue", size = 1) +
      ggplot2::geom_point(color = "red", size = 0.5) +
      ggplot2::labs(
        title = paste("Stock Price for", input$stock_code),
        x = "Date",
        y = "Closing Price (GHS)"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    plotly::ggplotly(p)
  })

  # Performance table
  output$performance_table <- DT::renderDataTable({
    data <- filtered_data()
    if (is.null(data)) return(NULL)

    # Calculate performance metrics
    latest_price <- tail(data$closing_price_vwap, 1)
    previous_price <- tail(data$closing_price_vwap, 2)[1]
    price_change <- latest_price - previous_price
    price_change_pct <- (price_change / previous_price) * 100

    # Calculate volatility
    returns <- diff(log(data$closing_price_vwap))
    volatility <- sd(returns, na.rm = TRUE) * sqrt(252) * 100

    # Create performance summary
    performance_summary <- data.frame(
      Metric = c("Current Price", "Price Change", "Price Change %",
                 "Volatility %"),
      Value = c(
        paste("GHS", round(latest_price, 2)),
        paste("GHS", round(price_change, 2)),
        paste(round(price_change_pct, 2), "%"),
        paste(round(volatility, 2), "%")
      )
    )

    DT::datatable(performance_summary,
                  options = list(dom = "t", pageLength = 10),
                  rownames = FALSE)
  })

  # Stock statistics
  output$stock_stats <- shiny::renderText({
    data <- filtered_data()
    if (is.null(data)) return("No data available")

    stats <- paste(
      "Data Points:", nrow(data), "\n",
      "Date Range:", min(data$date), "to", max(data$date), "\n",
      "Min Price: GHS",
      round(min(data$closing_price_vwap, na.rm = TRUE), 2), "\n",
      "Max Price: GHS",
      round(max(data$closing_price_vwap, na.rm = TRUE), 2), "\n",
      "Avg Price: GHS",
      round(mean(data$closing_price_vwap, na.rm = TRUE), 2), "\n",
      "Total Volume:", sum(data$total_shares_traded, na.rm = TRUE)
    )

    return(stats)
  })

  # Model performance
  output$model_performance <- shiny::renderText({
    data <- data_loaded()
    if (is.null(data$daily_models) && is.null(data$historical_models)) {
      return("No models available")
    }

    # Get model results for selected stock and model type
    model_key <- paste(input$stock_code, input$model_type)

    if (!is.null(data$daily_models) &&
          model_key %in% names(data$daily_models)) {
      model_result <- data$daily_models[[model_key]]
    } else if (!is.null(data$historical_models) &&
                 model_key %in% names(data$historical_models)) {
      model_result <- data$historical_models[[model_key]]
    } else {
      return("Model not found")
    }

    performance_text <- paste(
      "Model:", model_result$model_type, "\n",
      "MAE:", round(model_result$mae, 4), "\n",
      "RMSE:", round(model_result$rmse, 4), "\n",
      "MAPE:", round(model_result$mape, 2), "%\n",
      "Directional Accuracy:", round(model_result$directional_accuracy, 2), "%"
    )

    return(performance_text)
  })

  # Prediction chart
  output$prediction_chart <- plotly::renderPlotly({
    data <- filtered_data()
    if (is.null(data)) return(NULL)

    # Simple prediction using last known price and trend
    last_price <- tail(data$closing_price_vwap, 1)
    recent_trend <- mean(tail(diff(data$closing_price_vwap), 5), na.rm = TRUE)

    # Generate predictions
    future_dates <- seq(max(data$date) + 1,
                        max(data$date) + input$prediction_days,
                        by = "day")
    predictions <- last_price + (1:input$prediction_days) * recent_trend

    # Create prediction data frame
    pred_data <- data.frame(
      date = future_dates,
      predicted_price = predictions,
      type = "Prediction"
    )

    # Combine historical and prediction data
    historical_data <- data %>%
      dplyr::select(date, closing_price_vwap) %>%
      dplyr::mutate(type = "Historical")

    names(historical_data)[2] <- "price"
    names(pred_data)[2] <- "price"

    combined_data <- rbind(
      historical_data,
      pred_data
    )

    # Create plot
    p <- ggplot2::ggplot(combined_data,
                         ggplot2::aes(x = date, y = price, color = type)) +
      ggplot2::geom_line(size = 1) +
      ggplot2::geom_point(size = 0.5) +
      ggplot2::labs(
        title = paste("Price Prediction for", input$stock_code),
        x = "Date",
        y = "Price (GHS)",
        color = "Data Type"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    plotly::ggplotly(p)
  })

  # Prediction table
  output$prediction_table <- DT::renderDataTable({
    data <- filtered_data()
    if (is.null(data)) return(NULL)

    # Generate predictions
    last_price <- tail(data$closing_price_vwap, 1)
    recent_trend <- mean(tail(diff(data$closing_price_vwap), 5), na.rm = TRUE)

    future_dates <- seq(max(data$date) + 1,
                        max(data$date) + input$prediction_days,
                        by = "day")
    predictions <- last_price + (1:input$prediction_days) * recent_trend

    pred_table <- data.frame(
      Date = future_dates,
      Predicted_Price = round(predictions, 2),
      Price_Change = round(c(0, diff(predictions)), 2),
      Price_Change_Pct = round(c(0, diff(predictions)) / predictions * 100, 2)
    )

    DT::datatable(pred_table,
                  options = list(dom = "t", pageLength = 10),
                  rownames = FALSE)
  })

  # Model comparison chart
  output$model_comparison_chart <- plotly::renderPlotly({
    data <- data_loaded()
    if (is.null(data$daily_models) && is.null(data$historical_models)) {
      return(NULL)
    }

    # Get all models for selected stock
    stock_models <- list()

    if (!is.null(data$daily_models)) {
      stock_models <- c(stock_models,
                        data$daily_models[grepl(input$stock_code,
                                                names(data$daily_models))])
    }

    if (!is.null(data$historical_models)) {
      hist_models <- data$historical_models
      stock_models <- c(stock_models,
                        hist_models[grepl(input$stock_code,
                                          names(hist_models))])
    }

    if (length(stock_models) == 0) return(NULL)

    # Create comparison data
    comparison_data <- data.frame(
      Model = sapply(stock_models, function(x) x$model_type),
      MAE = sapply(stock_models, function(x) x$mae),
      RMSE = sapply(stock_models, function(x) x$rmse),
      MAPE = sapply(stock_models, function(x) x$mape),
      Directional_Accuracy = sapply(stock_models,
                                    function(x) x$directional_accuracy)
    )

    # Create comparison plot
    p <- ggplot2::ggplot(comparison_data,
                         ggplot2::aes(x = Model, y = MAE, fill = Model)) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::labs(
        title = paste("Model Performance Comparison for", input$stock_code),
        x = "Model Type",
        y = "Mean Absolute Error"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    plotly::ggplotly(p)
  })

  # Model metrics table
  output$model_metrics_table <- DT::renderDataTable({
    data <- data_loaded()
    if (is.null(data$daily_models) && is.null(data$historical_models)) {
      return(NULL)
    }

    # Get all models for selected stock
    stock_models <- list()

    if (!is.null(data$daily_models)) {
      stock_models <- c(stock_models,
                        data$daily_models[grepl(input$stock_code,
                                                names(data$daily_models))])
    }

    if (!is.null(data$historical_models)) {
      stock_models <- c(stock_models,
                        data$historical_models[grepl(input$stock_code,
                                                     names(hist_models))])
    }

    if (length(stock_models) == 0) return(NULL)

    # Metrics table
    metrics_table <- data.frame(
      Model = sapply(stock_models, function(x) x$model_type),
      MAE = round(sapply(stock_models, function(x) x$mae), 4),
      RMSE = round(sapply(stock_models, function(x) x$rmse), 4),
      MAPE = round(sapply(stock_models, function(x) x$mape), 2),
      Directional_Accuracy = round(sapply(stock_models,
                                          function(x) x$directional_accuracy), 2)
    )

    DT::datatable(metrics_table,
                  options = list(dom = "t", pageLength = 10),
                  rownames = FALSE)
  })

  # Data table
  output$data_table <- DT::renderDataTable({
    data <- filtered_data()
    if (is.null(data)) return(NULL)

    # Key columns for display
    display_data <- data %>%
      dplyr::select(date, share_code, closing_price_vwap, total_shares_traded,
                    price_change_pct, ma_5, ma_10, volatility_5) %>%
      dplyr::arrange(dplyr::desc(date))

    DT::datatable(display_data,
                  options = list(pageLength = 20, scrollX = TRUE),
                  rownames = FALSE)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
