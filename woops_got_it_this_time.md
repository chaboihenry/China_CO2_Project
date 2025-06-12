```mermaid
graph TD

  %%── node styles ───────────────────────────
  classDef decision fill:#B4D4FF,stroke:#333,stroke-width:1px
  classDef leaf     fill:#DFFFD6,stroke:#333,stroke-width:1px

  %%── the tree ──────────────────────────────
  D["**Decision Node**\nIs GDP ≤ $6 T?"]:::decision
  L1["**Leaf**\nŷ = 7.2 Gt"]             :::leaf
  L2["**Leaf**\nŷ = 8.9 Gt"]             :::leaf

  D -- "**Yes**" --> L1
  D -- "**No**"  --> L2

  %%── legend ───────────────────────────────
  subgraph Legend
    direction LR
    K1["**Decision node**<br/>(question)"]:::decision
    K2["**Leaf node**<br/>(answer)"]      :::leaf
  end
