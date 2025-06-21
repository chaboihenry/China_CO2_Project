# Model Reliability Assessment for China CO2 Emissions Forecast
library(tidyverse)
library(ggplot2)
library(gridExtra)

# Source the original model file to get access to the feature-engineered data
source("China_CO2_XGBoost.R")

# Use the properly feature-engineered data from the corrected model
# Get predictions on ALL historical data (not just test data)
all_historical_predictions <- predict(final_model_fit_full, new_data = all_data_final)

# Calculate residuals for ALL historical data points
all_data_with_preds <- all_data_final %>%
  mutate(
    pred = all_historical_predictions$.pred,
    residuals = co2_residual - pred,
    standardized_residuals = residuals / sd(residuals)
  )

# 1. Prediction Performance Metrics for ALL historical data
all_metrics <- all_data_with_preds %>%
  summarize(
    rmse = sqrt(mean((co2_residual - pred)^2)),
    mae = mean(abs(co2_residual - pred)),
    mape = mean(abs((co2_residual - pred) / co2_residual)) * 100,
    rsq = cor(co2_residual, pred)^2
  )

print("Prediction Performance Metrics (ALL Historical Data):")
print(all_metrics)

# 2. Standardized Residual Analysis for ALL historical data
# DIAGNOSTIC ANALYSIS: Check for correlation between residuals and fitted values
residual_fitted_correlation <- cor(all_data_with_preds$standardized_residuals, all_data_with_preds$pred)
print(paste("Correlation between standardized residuals and fitted values:", round(residual_fitted_correlation, 4)))

# Check if this correlation is statistically significant
n <- nrow(all_data_with_preds)
t_stat <- residual_fitted_correlation * sqrt((n-2)/(1-residual_fitted_correlation^2))
p_value <- 2 * pt(-abs(t_stat), df = n-2)
print(paste("P-value for correlation test:", round(p_value, 4)))

# 3. Additional Diagnostic Plots to Identify the Problem (ALL historical data)
diagnostic_plots <- list(
  # Original vs Predicted (to see if there's systematic bias)
  ggplot(all_data_with_preds, aes(x = co2_residual, y = pred)) +
    geom_point(alpha = 0.7) +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(
      title = "Actual vs Predicted Residuals (ALL Historical Data)",
      subtitle = paste("R² =", round(cor(all_data_with_preds$co2_residual, all_data_with_preds$pred)^2, 3)),
      x = "Actual Residuals",
      y = "Predicted Residuals"
    ) +
    theme_minimal(),
  
  # Residuals vs Time (to check for time-based patterns)
  ggplot(all_data_with_preds, aes(x = time_index, y = residuals)) +
    geom_point(alpha = 0.7) +
    geom_line(alpha = 0.5) +
    geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(
      title = "Residuals vs Time (ALL Historical Data)",
      x = "Time Index",
      y = "Residuals"
    ) +
    theme_minimal(),
  
  # Residuals vs Key Predictors (to identify missing variables)
  ggplot(all_data_with_preds, aes(x = gdp_growth, y = residuals)) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(
      title = "Residuals vs GDP Growth (ALL Historical Data)",
      x = "GDP Growth",
      y = "Residuals"
    ) +
    theme_minimal(),
  
  # Residuals vs Energy Growth
  ggplot(all_data_with_preds, aes(x = energy_growth, y = residuals)) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "loess", se = FALSE, color = "blue") +
    labs(
      title = "Residuals vs Energy Growth (ALL Historical Data)",
      x = "Energy Growth",
      y = "Residuals"
    ) +
    theme_minimal()
)

# Display diagnostic plots
grid.arrange(grobs = diagnostic_plots, ncol = 2)

# Create standardized residual plots (ALL historical data)
residual_plots <- list(
  # Standardized Residuals vs Fitted Values
  ggplot(all_data_with_preds, aes(x = pred, y = standardized_residuals)) +
    geom_point(alpha = 0.7) +
    geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
    geom_hline(yintercept = c(-2, 2), color = "blue", linetype = "dotted") +
    geom_smooth(method = "loess", se = FALSE, color = "green") +
    labs(
      title = "Standardized Residuals vs Fitted Values (ALL Historical Data)",
      subtitle = paste("Correlation =", round(residual_fitted_correlation, 3)),
      x = "Fitted Values (Predicted Residuals)",
      y = "Standardized Residuals"
    ) +
    theme_minimal(),
  
  # Standardized Residuals Histogram
  ggplot(all_data_with_preds, aes(x = standardized_residuals)) +
    geom_histogram(bins = 15, fill = "steelblue", alpha = 0.7) +
    geom_vline(xintercept = 0, color = "red", linetype = "dashed") +
    labs(
      title = "Distribution of Standardized Residuals (ALL Historical Data)",
      x = "Standardized Residuals",
      y = "Count"
    ) +
    theme_minimal(),
  
  # Q-Q Plot of Standardized Residuals
  ggplot(all_data_with_preds, aes(sample = standardized_residuals)) +
    stat_qq() +
    stat_qq_line(color = "red") +
    labs(
      title = "Q-Q Plot of Standardized Residuals (ALL Historical Data)",
      x = "Theoretical Quantiles",
      y = "Sample Quantiles"
    ) +
    theme_minimal(),
  
  # Standardized Residuals vs Time
  ggplot(all_data_with_preds, aes(x = time_index, y = standardized_residuals)) +
    geom_point(alpha = 0.7) +
    geom_line(alpha = 0.5) +
    geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
    geom_hline(yintercept = c(-2, 2), color = "blue", linetype = "dotted") +
    labs(
      title = "Standardized Residuals vs Time (ALL Historical Data)",
      x = "Time Index",
      y = "Standardized Residuals"
    ) +
    theme_minimal()
)

# Display all residual plots
grid.arrange(grobs = residual_plots, ncol = 2)

# 4. Additional Analysis: Residuals by Time Period
# Split data into early, middle, and late periods for analysis
all_data_with_preds <- all_data_with_preds %>%
  mutate(
    period = case_when(
      time_index <= quantile(time_index, 0.33) ~ "Early Period",
      time_index <= quantile(time_index, 0.67) ~ "Middle Period", 
      TRUE ~ "Late Period"
    )
  )

# Residual analysis by period
period_analysis <- all_data_with_preds %>%
  group_by(period) %>%
  summarize(
    n_obs = n(),
    mean_residual = mean(residuals),
    sd_residual = sd(residuals),
    rmse = sqrt(mean(residuals^2)),
    rsq = cor(co2_residual, pred)^2
  )

print("\nResidual Analysis by Time Period:")
print(period_analysis)

# 5. Residuals vs Year (actual calendar years)
residuals_vs_year <- ggplot(all_data_with_preds, aes(x = year, y = residuals)) +
  geom_point(alpha = 0.7) +
  geom_line(alpha = 0.5) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(
    title = "Residuals vs Calendar Year (ALL Historical Data)",
    x = "Year",
    y = "Residuals"
  ) +
  theme_minimal()

print(residuals_vs_year)

# Save plots
pdf("model_reliability_plots.pdf", width = 12, height = 10)
grid.arrange(grobs = diagnostic_plots, ncol = 2)
grid.arrange(grobs = residual_plots, ncol = 2)
print(residuals_vs_year)
dev.off()

# Print summary statistics for residuals (ALL historical data)
residual_summary <- all_data_with_preds %>%
  summarize(
    mean_residual = mean(residuals),
    sd_residual = sd(residuals),
    min_residual = min(residuals),
    max_residual = max(residuals),
    outliers_2sd = sum(abs(standardized_residuals) > 2),
    total_obs = n()
  )

print("\nResidual Summary Statistics (ALL Historical Data):")
print(residual_summary)

# DIAGNOSTIC CONCLUSIONS AND RECOMMENDATIONS
print("\n=== DIAGNOSTIC ANALYSIS (ALL Historical Data) ===")
if (abs(residual_fitted_correlation) > 0.3) {
  print("⚠️  HIGH CORRELATION DETECTED between residuals and fitted values")
  print("This indicates potential model problems:")
  print("1. Heteroscedasticity - variance changes with fitted values")
  print("2. Model misspecification - missing important variables")
  print("3. Non-linear relationships not captured by the model")
  print("4. Overfitting to specific patterns in the data")
  
  print("\nRECOMMENDATIONS:")
  print("1. Check for missing interaction terms or non-linear effects")
  print("2. Consider adding more features or transforming existing ones")
  print("3. Examine if the detrending process is adequate")
  print("4. Consider using different model specifications")
  print("5. Validate if the time series assumptions are met")
} else {
  print("✅ Residuals appear to be reasonably uncorrelated with fitted values")
  print("The model assumptions seem to be reasonably met.")
}

# 6. Additional Time Series Analysis
print("\n=== TIME SERIES PATTERN ANALYSIS ===")
# Check for autocorrelation in residuals
residual_acf <- acf(all_data_with_preds$residuals, plot = FALSE)
print("Autocorrelation in residuals:")
print(residual_acf$acf[1:5])

# Check for trend in residuals over time
residual_trend_model <- lm(residuals ~ time_index, data = all_data_with_preds)
residual_trend_summary <- summary(residual_trend_model)
print("\nTrend in residuals over time:")
print(residual_trend_summary$coefficients["time_index", ]) 