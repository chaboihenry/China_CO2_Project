################################################################################
# China CO₂ Forecast – Recursive XGBoost (Units & Warning Fix)
#
# Adjustments:
# - Updated `across()` syntax in numerical forecast printing to resolve warning.
# - Modified y-axis label on plots to remind user to specify CO2 units.
# - Kept gridExtra arrangement with adjusted heights for plots.
################################################################################

# 1. Install xgboost if not installed, then load packages
if (!requireNamespace("xgboost", quietly = TRUE)) {
  install.packages("xgboost")
}
if (!requireNamespace("gridExtra", quietly = TRUE)) { # Ensure gridExtra is installed
  install.packages("gridExtra")
}
library(xgboost)
library(tidyverse)
library(lubridate)
library(janitor)
library(tidymodels)
library(modeltime)
library(timetk)
library(skimr)
library(zoo)
library(vip)
library(DALEXtra)
library(gridExtra) 

theme_set(theme_minimal(base_size = 12))

# 2. Load & Patch Data, Create Base Features
china_raw <- read_csv("cleaned_china_data.csv", show_col_types = FALSE) %>%
  clean_names() %>%
  mutate(year = as.integer(trimws(year))) %>%
  filter(!is.na(year)) %>%
  mutate(year = ymd(paste0(year, "-01-01")))

china_raw <- china_raw %>%
  mutate(
    urban_pct = coalesce(
      urban_population_percent_of_total_population,
      100 * urban_population / (urban_population + rural_population),
      100 * urban_population / population
    )
  )

china <- china_raw %>%
  select(
    year, co2, gdp, population, primary_energy_consumption,
    coal_consumption, oil_consumption, gas_consumption, urban_pct
  ) %>%
  arrange(year) %>%
  mutate(gdp = zoo::na.approx(gdp, na.rm = FALSE, rule = 2))

stopifnot(colSums(is.na(china)) == 0)

china_fe_base <- china %>%
  mutate(time_index = row_number())

# 3. Time-Series Split on data with time_index
splits <- initial_time_split(china_fe_base, prop = 0.80)
train_data <- training(splits)
test_data  <- testing(splits)

# 3a. Fit Simple Trend Model on Training Data & Get Residuals
trend_model <- lm(co2 ~ poly(time_index, 2, raw = TRUE), data = train_data)

train_data_processed <- train_data %>%
  mutate(
    co2_trend = predict(trend_model, newdata = .),
    co2_residual = co2 - co2_trend
  )

china_fe_full_processed <- china_fe_base %>%
  mutate(
    co2_trend = predict(trend_model, newdata = .),
    co2_residual = co2 - co2_trend
  )

china_fe_final_for_recipe <- china_fe_full_processed %>%
  mutate(
    time_index_sq = time_index^2,
    gdp_growth = (gdp / lag(gdp)) - 1,
    pop_growth = (population / lag(population)) - 1,
    energy_growth = (primary_energy_consumption / lag(primary_energy_consumption)) - 1,
    co2_lag1 = lag(co2, 1),
    co2_lag2 = lag(co2, 2),
    co2_recent = zoo::rollmean(co2, k = 3, fill = NA, align = "right")
  ) %>%
  drop_na()

train_data_final_for_recipe <- train_data_processed %>%
  select(-co2_trend) %>%
  left_join(
    china_fe_final_for_recipe %>% select(time_index, gdp_growth:co2_recent, time_index_sq), 
    by = "time_index"
  ) %>%
  drop_na()

# 4. Recipe: Predict co2_residual. Keep time_index features unnormalized.
rec <- recipe(co2_residual ~ ., data = train_data_final_for_recipe) %>%
  step_rm(co2, year, any_of("co2_trend")) %>% 
  step_zv(all_predictors()) %>%
  step_normalize(all_numeric_predictors(), -matches("time_index")) %>%
  step_naomit(all_predictors(), skip = TRUE)

# 5. Model Specification & Cross-Validation (XGBoost for residuals)
xgb_spec <- boost_tree(
  trees = 1500, tree_depth = tune(), learn_rate = tune(), min_n = tune(),
  loss_reduction = tune(), sample_size = tune(), mtry = tune(), stop_iter = 30
) %>%
  set_engine("xgboost", objective = "reg:squarederror", eval_metric = "rmse", verbosity = 0) %>%
  set_mode("regression")

set.seed(457) 
grid <- grid_space_filling(
  tree_depth(range = c(3L, 8L)), learn_rate(range = c(-3.0, -0.7)),
  min_n(range = c(2L, 20L)), loss_reduction(range = c(-2.5, 1.5)),
  sample_size = sample_prop(range = c(0.5, 0.9)),
  finalize(mtry(), train_data_final_for_recipe), size = 60
)

resamples_resid <- time_series_cv(
  train_data_final_for_recipe, initial = floor(0.60 * nrow(train_data_final_for_recipe)),
  assess = floor(0.20 * nrow(train_data_final_for_recipe)), skip = 3, cumulative = TRUE
)

wf_resid <- workflow() %>% add_recipe(rec) %>% add_model(xgb_spec)
tuned_resid <- tune_grid(wf_resid, resamples = resamples_resid, grid = grid, metrics = metric_set(rmse),
                         control = control_grid(save_pred = TRUE, verbose = TRUE))

best_params_resid <- select_best(tuned_resid, metric = "rmse")
final_wf_resid <- finalize_workflow(wf_resid, best_params_resid)

# 6. Final Fit (XGBoost on residuals using all historical data prepared for recipe)
final_fit_resid <- fit(final_wf_resid, china_fe_final_for_recipe)

xgb_train_resid_preds <- predict(final_fit_resid, new_data = china_fe_final_for_recipe)$.pred
xgb_model_residuals <- china_fe_final_for_recipe$co2_residual - xgb_train_resid_preds
resid_sd_for_ci <- sd(xgb_model_residuals, na.rm = TRUE)
z_factor <- 1.96 

# 7. Build Initial Driver Projections for 10-Year Horizon
last_hist_full_row_for_drivers <- slice_tail(china_fe_base, n = 1)
last_hist_year_date <- max(china_fe_base$year)
current_max_time_index <- max(china_fe_base$time_index)

future_skel <- tibble(
  year = seq.Date(from = last_hist_year_date + years(1),
                  to   = last_hist_year_date + years(10),
                  by   = "year"),
  time_index = seq(from = current_max_time_index + 1, length.out = 10)
) %>%
  mutate(time_index_sq = time_index^2)

future_drivers_base <- future_skel %>%
  mutate(
    gdp = last_hist_full_row_for_drivers$gdp * (1 + 0.04)^(row_number()),
    population = last_hist_full_row_for_drivers$population * (1 + 0.002)^(row_number()),
    primary_energy_consumption = last_hist_full_row_for_drivers$primary_energy_consumption * (1 + 0.03)^(row_number()),
    coal_consumption = last_hist_full_row_for_drivers$coal_consumption * (1 + 0.01)^(row_number()),
    oil_consumption = last_hist_full_row_for_drivers$oil_consumption * (1 + 0.02)^(row_number()),
    gas_consumption = last_hist_full_row_for_drivers$gas_consumption * (1 + 0.08)^(row_number()),
    urban_pct = pmin(100, last_hist_full_row_for_drivers$urban_pct + 0.8 * row_number()),
    co2 = NA_real_, 
    co2_lag1 = NA_real_, co2_lag2 = NA_real_, co2_recent = NA_real_,
    gdp_growth = NA_real_, pop_growth = NA_real_, energy_growth = NA_real_
  )

future_ready <- bind_rows(
  china_fe_base %>% select(year, time_index, co2, gdp:urban_pct),
  future_drivers_base
) %>%
  arrange(time_index) %>%
  mutate(.pred = NA_real_, co2_lower = NA_real_, co2_upper = NA_real_,
         time_index_sq = time_index^2)

last_hist_co2_values <- slice_tail(china_fe_base, n = 3)

# 8. Recursive Forecast with Detrending
forecast_indices <- which(is.na(future_ready$co2))

for (row_idx in forecast_indices) {
  current_time_index <- future_ready$time_index[row_idx]
  is_first_forecast_step <- (current_time_index == current_max_time_index + 1)
  
  current_slice_for_xgb <- future_ready[row_idx, ]
  
  if (is_first_forecast_step) {
    current_slice_for_xgb$co2_lag1 <- last_hist_co2_values %>% filter(time_index == current_max_time_index) %>% pull(co2)
    current_slice_for_xgb$co2_lag2 <- last_hist_co2_values %>% filter(time_index == current_max_time_index - 1) %>% pull(co2)
    current_slice_for_xgb$co2_recent <- mean(last_hist_co2_values$co2, na.rm = TRUE)
    
    last_hist_growth_row <- slice_tail(china_fe_final_for_recipe, n=1)
    current_slice_for_xgb$gdp_growth    <- last_hist_growth_row$gdp_growth
    current_slice_for_xgb$pop_growth    <- last_hist_growth_row$pop_growth
    current_slice_for_xgb$energy_growth <- last_hist_growth_row$energy_growth
  } else {
    prev_row_idx <- row_idx - 1
    current_slice_for_xgb$co2_lag1 <- future_ready$co2[prev_row_idx]
    if (current_time_index > current_max_time_index + 2) {
      current_slice_for_xgb$co2_lag2 <- future_ready$co2[row_idx - 2]
    } else { 
      current_slice_for_xgb$co2_lag2 <- last_hist_co2_values %>% filter(time_index == current_max_time_index) %>% pull(co2)
    }
    
    co2_for_recent_mean <- future_ready$co2[max(1, prev_row_idx-2):prev_row_idx]
    current_slice_for_xgb$co2_recent <- mean(co2_for_recent_mean, na.rm = TRUE)
    
    current_slice_for_xgb$gdp_growth    <- (future_ready$gdp[row_idx] / future_ready$gdp[prev_row_idx]) - 1
    current_slice_for_xgb$pop_growth    <- (future_ready$population[row_idx] / future_ready$population[prev_row_idx]) - 1
    current_slice_for_xgb$energy_growth <- (future_ready$primary_energy_consumption[row_idx] / future_ready$primary_energy_consumption[prev_row_idx]) - 1
  }
  
  trend_data_for_pred <- tibble(time_index = current_slice_for_xgb$time_index)
  predicted_trend <- predict(trend_model, newdata = trend_data_for_pred)
  predicted_residual <- predict(final_fit_resid, new_data = current_slice_for_xgb)$.pred
  final_co2_prediction <- predicted_trend + predicted_residual
  
  future_ready$co2[row_idx]        <- final_co2_prediction
  future_ready$.pred[row_idx]      <- final_co2_prediction
  future_ready$co2_lower[row_idx]  <- final_co2_prediction - z_factor * resid_sd_for_ci
  future_ready$co2_upper[row_idx]  <- final_co2_prediction + z_factor * resid_sd_for_ci
  
  future_ready$gdp_growth[row_idx] <- current_slice_for_xgb$gdp_growth
  future_ready$pop_growth[row_idx] <- current_slice_for_xgb$pop_growth
  future_ready$energy_growth[row_idx] <- current_slice_for_xgb$energy_growth
  future_ready$co2_lag1[row_idx] <- current_slice_for_xgb$co2_lag1
  future_ready$co2_lag2[row_idx] <- current_slice_for_xgb$co2_lag2
  future_ready$co2_recent[row_idx] <- current_slice_for_xgb$co2_recent
}

# Print Numerical Forecast Values (with updated across syntax)
numerical_forecasts <- future_ready %>%
  filter(time_index > current_max_time_index) %>% 
  select(year, co2_forecast = co2, lower_ci = co2_lower, upper_ci = co2_upper) %>%
  mutate(
    year = lubridate::year(year), 
    # Updated across() syntax:
    across(where(is.numeric), ~round(.x, 2)) 
  )

print("Numerical CO2 Emission Forecasts (China):")
print(as_tibble(numerical_forecasts)) 


# 9. Plot Historical and Forecasted Data using gridExtra with adjusted heights
y_axis_label <- "CO₂ Emissions (Check Units from Source Data)" # Modified y-axis label

future_ready_plot <- future_ready %>%
  mutate(period = ifelse(time_index > current_max_time_index, "Forecast", "Historical"))

plot_zoomed_in <- ggplot(future_ready_plot, aes(x = year, y = co2)) +
  geom_ribbon(data = . %>% filter(period == "Forecast"),
              aes(ymin = co2_lower, ymax = co2_upper), fill = "steelblue", alpha = 0.2) +
  geom_line(aes(color = period), size = 1) +
  geom_point(aes(color = period), size = 2) +
  scale_color_manual(values = c("Historical" = "black", "Forecast" = "steelblue")) +
  labs(
    title = "China CO₂ Forecast (10-Year Outlook) - Zoomed In",
    subtitle = "Detrended XGBoost: lm(co2 ~ poly(time_index,2)) + XGBoost on Residuals",
    x = "Year", y = y_axis_label, color = "Data Type" # Used modified label
  ) +
  coord_cartesian(xlim = c(last_hist_year_date - years(5), last_hist_year_date + years(10) + years(1))) +
  theme_minimal(base_size = 11) + 
  theme(legend.position = "bottom")

min_historical_year <- min(future_ready_plot$year, na.rm = TRUE)
plot_full_history <- ggplot(future_ready_plot, aes(x = year, y = co2)) +
  geom_ribbon(data = . %>% filter(period == "Forecast"),
              aes(ymin = co2_lower, ymax = co2_upper), fill = "steelblue", alpha = 0.2) +
  geom_line(aes(color = period), size = 1) +
  geom_point(data = . %>% filter(period == "Historical"), aes(color = period), size = 2) + 
  geom_point(data = . %>% filter(period == "Forecast"), aes(color = period), size = 2, alpha = 0.8) + 
  scale_color_manual(values = c("Historical" = "black", "Forecast" = "steelblue")) +
  labs(
    title = "China CO₂ Forecast - Full Historical Context",
    subtitle = "Detrended XGBoost: lm(co2 ~ poly(time_index,2)) + XGBoost on Residuals",
    x = "Year", y = y_axis_label, color = "Data Type" # Used modified label
  ) +
  coord_cartesian(xlim = c(min_historical_year, last_hist_year_date + years(10) + years(1))) +
  theme_minimal(base_size = 11) + 
  theme(legend.position = "bottom")

grid.arrange(plot_zoomed_in, plot_full_history, ncol = 1, heights = unit(c(0.8, 1.2), "null"))
