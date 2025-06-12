```mermaid
graph TD

%% ---------- node style classes ----------
classDef split fill:#B4D4FF,stroke:#333,stroke-width:1px;
classDef leaf  fill:#DFFFD6,stroke:#333,stroke-width:1px;

%% ---------- decision-tree nodes ----------
A["**co2_lag1 ≤ 9.5&nbsp;Gt?**"]:::split
B["**gdp ≤ \$6&nbsp;T?**"]      :::split
C["**Leaf&nbsp;R₁<br/>ŷ = 8.9 Gt**"]:::leaf
D["**Leaf&nbsp;R₂<br/>ŷ = 7.2 Gt**"]:::leaf
E["**Leaf&nbsp;R₃<br/>ŷ = 7.8 Gt**"]:::leaf

A -- "**Yes**" --> B
A -- "**No**"  --> C
B -- "**Yes**" --> D
B -- "**No**"  --> E

%% ---------- legend ----------
subgraph Legend
  direction LR
  L1["**Decision node<br/>(question)**"]:::split
