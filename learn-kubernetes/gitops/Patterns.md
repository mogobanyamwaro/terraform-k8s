# GitOps Patterns (Deep Dive)

Domain weight **20%**: deploy/release, progressive delivery, pull vs event-driven, architecture.

## Deployment vs Release

**Deploy** = artifacts and manifests exist in the runtime (ReplicaSet rolled, image pulled).

**Release** = user traffic (or a flag) actually uses that version.

GitOps often **deploys** when Git changes. **Release** may wait on a flag, weight, or promotion PR.

Patterns you must name:

| Pattern | Idea |
| --- | --- |
| Recreate | Stop old, start new (downtime) |
| Rolling | Replace pods in batches (Deployment default) |
| Blue/green | Two complete stacks; flip Service/Ingress/flag |
| Canary | Small % of traffic to new, then more |
| A/B | Different versions for experiment, not only risk |
| Shadow / dark | Duplicate traffic to new, no user impact |

The GitOps part is: **the pattern’s desired state lives in Git** (weights, flags, DestinationRules, Flagger/Argo Rollouts objects). The cluster does not get a unique unpublished kubectl.

## Progressive Delivery

Automated **analysis + gradual exposure + abort**. Feedback (metrics, tests) drives the next Git-declared step or an automatic revert **in the store or CR that Git owns**.

If analysis lives only in a CI job that `kubectl`s weights, you have progressive **CI**, not GitOps, unless the agent owns the objects.

## Pull vs Event-Driven

**Pull** is the principle: the agent fetches the store.

**Events** (webhooks, image events, pub/sub) **notify** the agent to refresh **sooner**. They are not a replacement for pull, and they are not `kubectl apply` from the event source.

| | Pull (GitOps) | Push (not GitOps CD) |
| --- | --- | --- |
| Who applies | In-cluster / management agent | CI runner, laptop, bot |
| Credentials | Cluster SA / management secret | Many pipelines with kubeconfig |
| When | Interval + optional webhook | On pipeline success |
| Drift | Self-heal | Invisible until next pipeline |

## Architecture

**In-cluster reconciler:** agent runs in the target cluster (typical Flux, Argo in the same cluster).

**External / management reconciler:** agent runs elsewhere and applies to workload clusters (Argo CD destinations). Still GitOps if it **pulls** the store and **reconciles** continuously.

**State store management:** branch protection, CODEOWNERS, env overlays, app repo vs config repo, break-glass then **commit**.

**Repo patterns:** see `RepoLayout.md`.

## Promotion

Typical GitOps promotion is **not** `kubectl` to prod. It is a **PR/merge** that copies or kustomizes the same image tag from `staging/` into `prod/`, or an environment branch that is **reviewed**. Git history is the audit of who released.
