graph TD
    %% -------------------  TREE NODES  -------------------
    A["**co2_lag1 ≤ 9.5 Gt?**"]:::split
    B["**gdp ≤ \$6 T?**"]      :::split
    C["**Leaf R₁<br/>ŷ = 8.9 Gt**"]:::leaf
    D["**Leaf R₂<br/>ŷ = 7.2 Gt**"]:::leaf
    E["**Leaf R₃<br/>ŷ = 7.8 Gt**"]:::leaf

    A -- "**Yes**" --> B
    A -- "**No**"  --> C
    B -- "**Yes**" --> D
    B -- "**No**"  --> E

    %% -------------------  LEGEND  -------------------
    subgraph "         Legend"
        direction LR
        L1["**Decision&nbsp;node**<br/>(question)"]:::split
        L2["**Leaf node**<br/>(answer)"]          :::leaf
    end

    %% -------------------  STYLES  -------------------
    classDef split fill:#B4D4FF,stroke:#333,stroke-width:1px;
    classDef leaf  fill:#DFFFD6,stroke:#333,stroke-width:1px;
