```mermaid
flowchart TB
  A["**Init: F₀(x) = mean(y)**"] --> B["**Compute residuals<br/>r₁ = y – F₀(x)**"]
  B --> C["**Fit tree h₁(x) to r₁**"]
  C --> D["**Update: F₁(x) = F₀(x) + η·h₁(x)**"]
  D --> E["**Compute residuals<br/>r₂ = y – F₁(x)**"]
  E --> F["**Fit tree h₂(x) to r₂**"]
  F --> G["**Update: F₂(x) = F₁(x) + η·h₂(x)**"]
  G --> H["**…repeat for m = 1…M…**"]
  H --> I["**Final model: Fₘ(x)**<br/>(sum of all η·hₘ)"]
