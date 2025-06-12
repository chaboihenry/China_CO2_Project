# China CO₂ Forecast – Tree intuition

Below is a toy CART that splits on **co2_lag1** and **gdp** and the
corresponding rectangles in predictor space.

```mermaid
%% small CART + partition diagram
graph TD
    style A fill:#B4D4FF,stroke:#333,stroke-width:1px
    style B fill:#B4D4FF,stroke:#333,stroke-width:1px
    style C fill:#DFFFD6,stroke:#333,stroke-width:1px
    style D fill:#DFFFD6,stroke:#333,stroke-width:1px
    style E fill:#DFFFD6,stroke:#333,stroke-width:1px
    
    subgraph "Decision-Tree View"
      direction TB
      A[Root<br/>co2_lag1 ≤ 9.5 Gt?] -->|Yes| B[gdp ≤ $6 T?]
      A -->|No| C[Leaf R₁<br/>ŷ = 8.9 Gt]
      B -->|Yes| D[Leaf R₂<br/>ŷ = 7.2 Gt]
      B -->|No| E[Leaf R₃<br/>ŷ = 7.8 Gt]
    end

    %% Predictor-space partition (optional placeholder panel)
    click A " " _blank

%% CART with bold labels
graph TD
    %% --- styling (unchanged) ---
    style A fill:#B4D4FF,stroke:#333,stroke-width:1px
    style B fill:#B4D4FF,stroke:#333,stroke-width:1px
    style C fill:#DFFFD6,stroke:#333,stroke-width:1px
    style D fill:#DFFFD6,stroke:#333,stroke-width:1px
    style E fill:#DFFFD6,stroke:#333,stroke-width:1px
    
    %% --- tree panel ---
    subgraph "**Decision-Tree View**"
      direction TB
      A["**Root**<br/>**co2_lag1 ≤ 9.5 Gt?**"] -->|**Yes**| B["**gdp ≤ \$6 T?**"]
      A -->|**No**|  C["**Leaf R₁**<br/>**ŷ = 8.9 Gt**"]
      B -->|**Yes**| D["**Leaf R₂**<br/>**ŷ = 7.2 Gt**"]
      B -->|**No**|  E["**Leaf R₃**<br/>**ŷ = 7.8 Gt**"]
    end

    %% (optional predictor-space panel could go here)
