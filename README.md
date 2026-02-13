# China CO₂ Emissions Forecasting: Hybrid XGBoost & Time Series Analysis

## Project Overview
This project focuses on modeling and forecasting China's annual CO₂ emissions—a critical indicator for global climate policy. Because emissions data is highly non-linear and influenced by complex economic factors, standard statistical models often fall short.

To address this, I developed a **Hybrid Machine Learning framework** that combines deterministic trend modeling with **XGBoost** (Extreme Gradient Boosting). By detrending the series and using XGBoost to model the residuals based on economic drivers (GDP, Energy Consumption, Population), the model achieves significantly higher accuracy than traditional ARIMA or ETS approaches.

## 🚀 Key Features
* **Hybrid Architecture**: Decomposes the time series into a quadratic trend (long-term growth) and a non-linear residual component modeled by XGBoost.
* **Advanced Feature Engineering**: Implemented dynamic features including:
    * Lagged variables and rolling window statistics.
    * Growth rates of exogenous variables (GDP, Population, Energy).
    * Polynomial expansion to capture non-linear economic relationships.
* **Recursive Forecasting**: Built a custom recursive loop to forecast 10 years into the future, dynamically updating lag features at each time step.
* **Rigorous Validation**: Used **Time Series Cross-Validation** (rolling origin) to prevent data leakage and ensure the model holds up against unseen future data.

## 📊 Results & Performance

The Hybrid XGBoost model was benchmarked against standard statistical baselines, including **ARIMAX** (Auto-Regressive Integrated Moving Average with Exogenous Regressors) and **ETS** (Error, Trend, Seasonality).

The Hybrid approach demonstrated superior performance, reducing prediction error by an order of magnitude:

| Metric | Hybrid XGBoost | ARIMAX Baseline | ETS Baseline | Improvement |
| :--- | :--- | :--- | :--- | :--- |
| **RMSE** (Root Mean Square Error) | **23.74 Mt** | N/A | 211.86 Mt | **~89% Reduction** |
| **MAE** (Mean Absolute Error) | **9.53 Mt** | 103.75 Mt | 150.02 Mt | **~90% Reduction** |
| **R²** (Explained Variance) | **> 0.99** | N/A | N/A | Near-perfect fit |

### Key Takeaways:
* **Precision:** While standard models like ARIMAX produced average errors of over **100 Million Tonnes (Mt)**, the Hybrid XGBoost model cut this down to just **~9.5 Mt**—roughly equivalent to less than **0.1%** of China's total annual emissions.
* **Stability:** The ETS model struggled with the non-linear growth trends, resulting in a high RMSE of **211.86 Mt**. The Hybrid model's decomposition strategy (Trend + Residuals) successfully stabilized the variance.
* **Outcome:** The model projects a continued rise in emissions through **2033**, reaching approximately **17,269 Mt**. However, the growth rate shows signs of stabilization compared to the exponential rise seen in the early 2000s.

## 🛠️ Tech Stack
* **Language:** R
* **Machine Learning:** `xgboost`, `tidymodels`, `parsnip`
* **Time Series:** `timetk`, `modeltime`, `zoo`, `forecast`
* **Data Manipulation:** `tidyverse` (dplyr, purrr), `janitor`
* **Visualization:** `ggplot2`, `gridExtra`

## 📂 Repository Structure

| File | Description |
| :--- | :--- |
| `China_CO2_XGBoost.R` | **Main Script.** Contains data cleaning, feature engineering, hybrid model training, and the recursive forecasting loop. |
| `model_reliability.R` | **Diagnostics.** Runs residual analysis, Q-Q plots, and autocorrelation checks to ensure statistical validity. |
| `STA457 - Final Project.pdf` | **Full Report.** The academic paper detailing the mathematical theory, literature review, and comparison of ETS vs. XGBoost. |
| `cleaned_china_data.csv` | The processed dataset containing CO₂, GDP, Population, and Energy metrics (1965–2023). |

## 🧠 Methodology Deep Dive
### Why Hybrid?
Pure regression misses complex interactions, while pure ARIMA struggles with non-linear exogenous drivers.
1.  **Step 1:** Fit a `Poly(Time, 2)` regression to capture the massive industrial growth trend of China.
2.  **Step 2:** Extract the *residuals* (the variance the trend didn't explain).
3.  **Step 3:** Train an **XGBoost** model on those residuals using features like `Energy_Growth`, `GDP_Growth`, and `Rolling_Mean_CO2`.
4.  **Step 4:** Sum the **Predicted Trend** + **Predicted Residuals** to get the final forecast.

## How to Run
This project is built in R. You will need the `tidyverse` and `tidymodels` suites.

```r
# 1. Install dependencies
install.packages(c("tidyverse", "xgboost", "tidymodels", "timetk", "zoo", "gridExtra"))

# 2. Run the main forecasting script
source("China_CO2_XGBoost.R")

# 3. Run reliability checks
source("model_reliability.R")
```

## Created by Henry Vianna as a final project for STA457 (Time Series Analysis)
