```mermaid
graph TD

%%─── Styles ───────────────────────────────────────────────
classDef split fill:#B4D4FF,stroke:#333,stroke-width:1px
classDef leaf  fill:#DFFFD6,stroke:#333,stroke-width:1px

%%─── Tree nodes ───────────────────────────────────────────
A["**co2_lag1 ≤ 9.5 Gt?**"]           :::split
B["**gdp ≤ 6 T?**"]                   :::split
C["**Leaf R₁\nŷ = 8.9 Gt**"]         :::leaf
D["**Leaf R₂\nŷ = 7.2 Gt**"]         :::leaf
E["**Leaf R₃\nŷ = 7.8 Gt**"]         :::leaf

A -->|**Yes**| B
A -->|**No**|  C
B -->|**Yes**| D
B -->|**No**|  E

%%─── Legend ──────────────────────────────────────────────
subgraph Legend
  direction LR
  L1["**Decision node**\n(question)"]:::split
  L2["**Leaf node**\n(answer)"]    :::leaf
end

