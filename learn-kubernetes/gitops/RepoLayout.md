# Repo Layout Patterns

How teams structure the **state store**. CGOA cares that layout still obeys the four principles.

## App repo vs config repo

**Application (source) repo:** code, Dockerfile, unit tests, app CI. Produces an **immutable image digest**.

**Config (desired-state) repo:** Kubernetes YAML, Helm values, Kustomize overlays, Argo Applications, Flux Kustomizations. This is what the **agent pulls**.

Why split:

- App CI does **not** need cluster credentials
- Reviewers of prod YAML can be platform, not every app committer
- Config history is the **release audit**

A monorepo that contains both is valid if **prod paths are protected** and the agent still pulls.

## Environment layouts

| Pattern | Shape | Watch-out |
| --- | --- | --- |
| Directory overlays | `base/`, `overlays/dev`, `overlays/prod` | Prod overlay must be reviewed |
| Branches | `env/dev`, `env/prod` | Do not force-push prod; promotion is merge |
| Separate repos | `app-config-prod` | Duplication vs isolation |
| Cluster folders | `clusters/prod-1/` | One store, many runtimes |

Kustomize overlays and Helm values-per-env are the usual packaging for the same idea.

## App-of-Apps / root Kustomization

A **parent** desired state lists **children** (Argo Applications, ApplicationSets, Flux Kustomizations). The parent is also Git. Bootstrapping is still GitOps: you apply the root once (chicken-egg), then the engine pulls the rest.

Not a fifth principle. Just a **composition** pattern.

## CODEOWNERS and promotion PRs

```text
/overlays/prod/  @platform-team
```

Promotion = PR that changes prod overlay image digest. CI on the **config** repo runs `kubeconform` / policy. Merge → agent pulls.

## Secrets

Raw secrets in Git fail DevSecOps even if they are “declarative”. Prefer Sealed Secrets, SOPS, External Secrets, CSI — Git holds **encrypted blobs or references**. The desired state is still declared; the plaintext is not the reviewable store.

## Break-glass

Emergency `kubectl` is allowed **operationally**. GitOps requires a follow-up: **commit the same change** (or revert Git if the emergency was to undo). Otherwise the agent **self-heals back** or the store lies.
