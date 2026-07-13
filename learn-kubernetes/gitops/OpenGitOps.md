# OpenGitOps (Exam-Ready)

Vendor-neutral definition of GitOps. CGOA tests **this**, not a product UI.

Canonical: [opengitops.dev](https://opengitops.dev/) — Principles and Glossary **v1.0.0**.

## What OpenGitOps Is

A set of **principles** plus a **glossary**. Implementations (Argo CD, Flux, Config Sync, Fleet, homegrown operators) are GitOps **when they follow the principles**, not because they have “GitOps” in the marketing name.

Git is the **usual** state store. The principles talk about a **state store**, not “must be GitHub”.

## The Four Principles (memorise the sentences)

1. **Declarative** — A system managed by GitOps must have its desired state expressed declaratively.
2. **Versioned and Immutable** — Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.
3. **Pulled Automatically** — Software agents automatically pull the desired state declarations from the source.
4. **Continuously Reconciled** — Software agents continuously observe actual system state and attempt to apply the desired state.

All four must hold. A Git repo of YAML with only `kubectl apply` from Jenkins fails **Pulled Automatically** and usually **Continuously Reconciled**.

## Glossary (v1.0.0 wording, exam-ready)

| Term | Meaning |
| --- | --- |
| **Continuous** | Happening regularly and frequently. **Not** instantaneous. |
| **Declarative Description** | Configuration that describes desired operating state **without procedures** to get there. |
| **Desired State** | Complete configuration sufficient to recreate a **behaviourally indistinguishable** instance. Usually **not** database contents. |
| **Drift** | Actual state differs from desired state. |
| **Reconciliation** | Making actual match desired. |
| **Software System** | One or more runtime instances that implement the **same** desired state. |
| **State Store** | Stores desired state. Must support **versioning, immutability, complete history**; **ACL and audit** matter. Git is canonical. |
| **Feedback** | Information about actual state used by reconciliation **or** by humans (alerts, health, metrics). |

CGOA also lists **Rollback** as a terminology competency: restore a previous desired-state version in the store, then reconcile. Not a cluster-only undo that Git will fight.

## Mapping Principles → Glossary

| Principle | Glossary you will see |
| --- | --- |
| Declarative | Declarative description, desired state |
| Versioned and Immutable | State store, rollback via history |
| Pulled Automatically | Software agents, state store as source |
| Continuously Reconciled | Drift, reconciliation, continuous, feedback |

## What Is *Not* in OpenGitOps

- A requirement to use Argo CD or Flux
- A requirement that reconciliation be real-time
- A requirement that Git be the only store
- Permission to treat wiki, Slack, or live etcd as the desired-state store
- Push-only `kubectl` from CI as the delivery model

## Closed-Book Hooks

- **Four principles, official order and names.**
- Continuous ≠ instant.
- State store ≠ etcd.
- Feedback includes **human** notifications, not only controller metrics.
- Rollback = **new commit** (or equivalent immutable version) of old desired state.
