# Flashcards

Cover the right column. Full pass the night before and the morning of the exam.

## Exam Meta

| Prompt | Answer |
| --- | --- |
| Format | Closed-book **MCQ**, PSI |
| Questions / time / pass | **60** / **90 min** / **75%** |
| Vendor | **Neutral** (OpenGitOps) |
| Largest domain | **Principles 30%** |
| Terminology weight | **20%** |
| Patterns weight | **20%** |
| Related practices | **16%** |
| Tooling | **14%** |

## Four Principles (names, official order)

| Prompt | Answer |
| --- | --- |
| Principle 1 | **Declarative** |
| Principle 2 | **Versioned and Immutable** |
| Principle 3 | **Pulled Automatically** |
| Principle 4 | **Continuously Reconciled** |
| Declarative sentence | Desired state expressed **declaratively** |
| Versioned sentence | Immutability, versioning, **complete version history** |
| Pulled sentence | **Software agents automatically pull** declarations |
| Reconciled sentence | Agents **observe actual** and **attempt to apply** desired |

## Glossary

| Prompt | Answer |
| --- | --- |
| Continuous | Regular and frequent, **not instantaneous** |
| Declarative description | Desired operating state, **no procedures** |
| Desired state | Enough to recreate a **behaviourally indistinguishable** instance |
| Desired state and DB rows | Generally **not** included |
| Drift | Actual **≠** desired |
| Reconciliation | Make actual **match** desired |
| Software system | Runtime instance(s) for that desired state |
| State store | Versioned, immutable, history; **ACL/audit**; Git usual |
| Feedback | Actual-state info for **agent or humans** |
| Canonical store | **Git** |
| etcd in GitOps | **Actual** state, not the desired-state store |
| Rollback | Restore previous desired state **in the store**, then reconcile |

## Violations (prompt → which principle fails)

| Prompt | Answer |
| --- | --- |
| Makefile of kubectl as truth | **Declarative** |
| `:latest` image | **Versioned and Immutable** |
| Force-push rewrite as normal undo | **Versioned and Immutable** |
| CI kubectl apply | **Pulled Automatically** |
| Webhook-only, no poll | **Pulled** / weak continuous |
| Apply once on merge, no agent | **Continuously Reconciled** |
| Wiki as source of truth | Store + declarative |

## Related Practices

| Prompt | Answer |
| --- | --- |
| CaC vs GitOps | CaC is config in code; GitOps **adds pull + reconcile** |
| IaC vs GitOps | IaC declares infra; GitOps can **continuously operate** it |
| DevOps vs GitOps | Culture vs a **specific operating model** |
| CI’s GitOps job | Build/test; **commit digest to config Git** |
| CD that is GitOps | **Pull-based** reconcile, not CI apply |
| DevSecOps on config | PR review, CODEOWNERS, signed commits, **no raw secrets** |

## Patterns and Architecture

| Prompt | Answer |
| --- | --- |
| Deploy vs release | Cluster has version vs **traffic/flag** uses it |
| Canary | Small % traffic, then more |
| Blue/green | Two stacks, **flip** |
| Progressive delivery | Gradual + **analysis** + abort |
| Webhook role | **Accelerates** pull |
| In-cluster reconciler | Agent **in** the target cluster |
| External/management | Agent elsewhere, still **pulls** |
| App vs config repo | Code/CI vs **desired-state YAML** |
| Promotion | **PR/merge** of prod overlay, not kubectl |
| Break-glass follow-up | **Commit** (or Git will fight) |

## Tooling

| Prompt | Answer |
| --- | --- |
| Kustomize | Overlays/patches, **no Go templates** |
| Helm | Charts + values; **pin version** |
| OCI store | Versioned **digest** artifacts |
| Argo CD role | **Reconciliation engine** (Applications) |
| `selfHeal: true` | Revert **drift** toward Git |
| Flux role | **GitOps Toolkit** controllers |
| Flux Source | **Pulls** Git/OCI/Helm |
| Image automation | Writes **Git**, not kubectl |
| Notifications | **Human feedback** |
| CI interoperability | CI updates **Git**; agent updates **cluster** |

## Rollback Drills

| Prompt | Answer |
| --- | --- |
| GitOps rollback command idea | `git revert` / new commit of old tree |
| `kubectl rollout undo` + unchanged Git | **Drift**; agent may re-apply new |
| Why history enables rollback | **Versioned and Immutable** |
