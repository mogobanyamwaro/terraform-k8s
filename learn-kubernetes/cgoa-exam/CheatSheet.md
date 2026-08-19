# Exam-Day Cheat Sheet

Last page before you sit CGOA. Closed book. **90 minutes, 60 questions, 75% (45/60).**

## Exam Facts

| | |
| --- | --- |
| Name | Certified GitOps Associate (CGOA) |
| Format | Multiple choice, online, PSI |
| Questions | **60** |
| Duration | **90 minutes** |
| Pass | **75%** |
| Docs | **None** |
| Vendor | **Neutral** (OpenGitOps). Argo/Flux are **examples** |

| Domain | Weight | ~Q |
| --- | ---: | ---: |
| **Principles** | **30%** | ~18 |
| Terminology | 20% | ~12 |
| Patterns | 20% | ~12 |
| Related practices | 16% | ~10 |
| Tooling | 14% | ~8 |

## Strategy

1. First pass: answer what you know. Flag the rest. ~90s per question.
2. When two answers look right, pick the one that matches **OpenGitOps wording**, not a vendor slogan.
3. Read **not / except / only / always**.
4. If the question can be answered **without naming Argo or Flux**, do that.
5. No negative marking — never leave blank.

## The Four Principles (official sentences)

1. **Declarative** — Desired state expressed declaratively.
2. **Versioned and Immutable** — Store enforces immutability, versioning, **complete history**.
3. **Pulled Automatically** — **Agents pull** declarations from the source.
4. **Continuously Reconciled** — Agents **observe actual** and **attempt to apply** desired.

All four. One missing → not GitOps.

## Glossary in One Line Each

| Term | Line |
| --- | --- |
| Continuous | Regular and frequent. **Not instantaneous.** |
| Declarative description | **What**, not procedures. |
| Desired state | Enough to recreate a **behaviourally indistinguishable** system. Usually **not** DB rows. |
| Actual state | Live runtime (etcd, cloud). |
| Drift | Actual ≠ desired. |
| Reconciliation | Make actual match desired. |
| Software system | Runtime instance(s) implementing that desired state. |
| State store | Versioned, immutable, history, ACL/audit. **Git canonical, not exclusive.** |
| Feedback | Actual-state info for the **agent or humans**. |
| Rollback | **New desired state** that restores a known-good version. Then reconcile. |

## Universal Flow

```text
Declared in an immutable versioned store?
  No  → not GitOps
Agent PULL (webhook optional accelerator)?
  No  → CI/CD push, not GitOps
Loop still comparing actual vs desired?
  No  → one-shot apply, not GitOps
Description is what not how?
  No  → imperative, fails Declarative
```

## Related Practices (do not synonymise)

| Term | GitOps relation |
| --- | --- |
| CaC | Config in VCS; GitOps is CaC **plus** pull + reconcile |
| IaC | Infra declared as code; GitOps can **operate** IaC continuously |
| DevOps | Culture/flow; GitOps is a **delivery operating model** |
| DevSecOps | Policy, signed commits, no raw secrets, PR checks on config |
| CI | Build, test, produce digest; **may PR image tags into Git** |
| CD | Deploy/release; GitOps is a **pull-based CD** style |

CI `kubectl apply` to the cluster = **not** GitOps.

## Patterns

- **Deploy** = version in the cluster. **Release** = traffic/flag uses it.
- Progressive delivery = gradual exposure + **feedback** + abort. Desired weights/flags **in Git**.
- Webhook = faster pull, **not** the only mechanism.
- In-cluster vs external reconciler = **where the agent runs**, not push vs pull.
- Management cluster applying to many destinations can still be GitOps.
- Promotion = **Git PR**, not laptop kubectl to prod.

## Tooling

- Packaging: YAML, Kustomize, Helm, jsonnet/CUE. **Pin versions and image digests.**
- Stores: Git, OCI with digest. **Not** wiki, Slack, live etcd, in-place S3 clobber.
- Engines: Argo CD, Flux, others. Must **pull + reconcile**.
- Argo `selfHeal` / Flux `interval` = continuous reconciliation knobs.
- CI writes **Git**. Agent writes **cluster**. Notifications = **human feedback**.

## Rollback One-Liner

`git revert` (or new commit with old tree) → push → agent reconciles.

`kubectl rollout undo` **while Git still has the new image** → drift; self-heal **re-applies the bad version**.

## Night-Before Distractors

- Git in the repo of bash `kubectl` = **not** Declarative desired state
- `:latest` = fails **Versioned and Immutable**
- Webhook-only, no interval = fails **Pulled** / **Continuous**
- Force-push rewrite of prod as normal rollback = fails **Immutable** history
- etcd as the GitOps store = **actual**, not desired
- Argo vs Flux as “the correct GitOps” = both can be
- Continuous means “real-time” = **false**
