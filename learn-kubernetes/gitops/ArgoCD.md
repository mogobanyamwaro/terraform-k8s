# Argo CD (Enough for CGOA)

Not an Argo CD administrator exam. Know the **role**: a **reconciliation engine** that implements OpenGitOps for Kubernetes apps.

## What It Is

CNCF project. You declare **Applications** (and optionally ApplicationSets). Each Application points at a **Git (or Helm/OCI) source** and a **destination** cluster/namespace. Argo CD **pulls**, renders (plain YAML / Helm / Kustomize / jsonnet), **diffs** live vs desired, **syncs**.

## Pieces to recognise

| Piece | Role |
| --- | --- |
| Application CR | Desired app: source + destination + sync policy |
| ApplicationSet | Generates many Applications (clusters, Git dirs, matrices) |
| App-of-Apps | Parent Application whose YAML is more Applications |
| `spec.syncPolicy.automated` | Auto-sync when Git changes |
| `selfHeal: true` | Revert cluster drift toward Git |
| `prune: true` | Delete resources removed from Git |
| Refresh interval / webhook | Pull; webhook is accelerator |
| Destination | In-cluster or remote API (management cluster pattern) |
| Health | Runtime status (Healthy / Degraded / Missing) — **feedback** |
| SSO / RBAC / projects | Who may change Applications; **not** a replacement for Git ACL |

## GitOps mapping

| Principle | Argo CD behaviour |
| --- | --- |
| Declarative | Application + manifests |
| Versioned and Immutable | Git commit SHA / chart version; avoid `latest` |
| Pulled Automatically | Repo-server fetches Git; not CI kubectl |
| Continuously Reconciled | Status refresh + optional self-heal |

Manual **Sync** button without automation is still using a pull agent, but it is **weaker** continuous reconciliation. Exam: automated + self-heal is the GitOps-complete knob set.

## Multi-cluster

Argo CD often runs in a **management** cluster. Credentials for workload clusters live **there**, not in every app CI. Destinations are still Kubernetes runtimes of the **software system**.

## What CGOA will not require

Memorising every CLI flag, ConfigManagementPlugin syntax, or UI click-path. If a question is “where do apply credentials live?”, answer **with the engine**, not in GitHub Actions.
