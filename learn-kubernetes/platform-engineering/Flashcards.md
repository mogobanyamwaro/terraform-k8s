# Flashcards

Cover the right column.

## Meta

| Prompt | Answer |
| --- | --- |
| Duration / questions / pass | **120 min** / **60** / **75%** |
| Largest domain | **Core 36%** |
| Style | Vendor-neutral **judgement** |

## Product

| Prompt | Answer |
| --- | --- |
| Customer | **App teams** |
| Ticket for every namespace | **Anti-pattern** → self-service |
| Golden path | **Easiest default + hatch** |
| TVP | **Smallest useful path now** |
| Platform as product | Users, docs, SLO, roadmap |
| Cognitive load | Hide incidental complexity |

## Delivery

| Prompt | Answer |
| --- | --- |
| CI output | **Immutable digest** + tests |
| CD | Artifact **in an environment** |
| GitOps | Git desired; **agent reconciles** |
| Promote | **Same digest**, Git overlay |
| Rollback | **Git revert** |
| CI kubeconfig to prod | **No** |

## Obs / sec

| Prompt | Answer |
| --- | --- |
| Four signals | Metrics, logs, traces, **events** |
| OTel | **Instrumentation/export** |
| mTLS | Encrypt + **mutual auth** |
| Policy mutate | **Secure defaults** |
| PSS default | **Restricted**-like |
| Fork PRs + secrets | **Isolate** |

## APIs

| Prompt | Answer |
| --- | --- |
| Reconciliation | Actual → **desired** loop |
| CRD | **Self-service schema** |
| spec / status | Desired / **observed** |
| CAPI | **Clusters** |
| Crossplane XR | **Composed infra API** |
| Operator | Controller + **lifecycle knowledge** |

## IDP / measure

| Prompt | Answer |
| --- | --- |
| Portal | **UX**, not the whole platform |
| Catalog | **Owners, APIs, docs** |
| Template | **Scaffold golden path** |
| AI change | **PR + policy** |
| DORA 1 | **Deploy frequency** ↑ |
| DORA 2 | **Lead time** ↓ |
| DORA 3 | **Change fail %** ↓ |
| DORA 4 | **MTTR** ↓ |
| Vanity | Tool/plugin **count** |
| SPACE | Broader **DX** than DORA |
