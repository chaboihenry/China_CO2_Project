```mermaid
graph TD

%% colour classes
classDef decision fill:#9EC9FF,stroke:#333,stroke-width:1px
classDef leaf     fill:#B9F5C7,stroke:#333,stroke-width:1px

%% tree nodes
D["**Decision<br/>Is GDP ≤ 6 T?**"]
class D decision

L1["**Leaf<br/>ŷ = 7.2 Gt**"]
class L1 leaf

L2["**Leaf<br/>ŷ = 8.9 Gt**"]
class L2 leaf

%% edges
D -->|**Yes**| L1
D -->|**No**|  L2

%% legend
subgraph Legend
  direction LR
  K1["**Decision node<br/>(question)**"]
  class K1 decision
  K2["**Leaf node<br/>(answer)**"]
  class K2 leaf
end

```
