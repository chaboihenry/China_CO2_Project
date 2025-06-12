```mermaid
%% =========  Decision tree with legend (GitHub-safe)  =========
graph TD

%% ----- colour classes -----
classDef split fill:#B4D4FF,stroke:#333,stroke-width:1px
classDef leaf  fill:#DFFFD6,stroke:#333,stroke-width:1px

%% ----- tree nodes -----
A["**co2_lag1 ≤ 9.5 Gt?**"]:::split
B["**gdp ≤ \$6 T?**"]     :::split
C["**Leaf R₁<br/>ŷ = 8.9 Gt**"]:::leaf
D["**Leaf R₂<br/>ŷ = 7.2 Gt**"]:::leaf
E["**Leaf R₃<br/>ŷ = 7.8 Gt**"]:::leaf

%% ----- edges -----
A -- "**Yes**" --> B
A -- "**No**"  --> C
B -- "**Yes**" --> D
B -- "**No**"  --> E

%% ----- legend -----
subgraph Legend
  direction LR
  L1["**Decision node<br/>(question)**"]:::split
  L2["**Leaf node<br/>(answer)**"]    :::leaf
end
```
