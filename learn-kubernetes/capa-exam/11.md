# 11. The Application CR

**Domain:** Argo CD (34%) — Use Argo CD Application

## Concept Refresher

`kind: Application` (`argoproj.io/v1alpha1`) is the unit of delivery.

```yaml
spec:
  project: default
  source:
    repoURL: https://github.com/org/app-config
    targetRevision: main
    path: overlays/prod
  destination:
    server: https://kubernetes.default.svc   # or name: in-cluster
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

| Field | Meaning |
| --- | --- |
| `source` / `sources` | Git path, Helm chart, OCI, directory, plugin |
| `destination` | Cluster + namespace |
| `project` | AppProject constraints (default `default`) |
| `ignoreDifferences` | Ignore live vs Git noise (e.g. replica counted by HPA) |
| `revisionHistoryLimit` | How many sync revisions to keep |

**Status axes (memorise)**

- **Sync:** Synced, OutOfSync, Unknown
- **Health:** Healthy, Progressing, Degraded, Suspended, Missing, Unknown

Multi-source Applications combine e.g. a Helm chart + a Git values file.

**ApplicationSet** generates many Applications (clusters, git dirs, list, matrix, …) — next files.

CLI: `argocd app create`, `get`, `sync`, `diff`, `delete`, `history`, `rollback`.

Rollback in Argo CD = sync a **previous Git revision** Argo recorded — still GitOps-shaped, not `kubectl rollout undo` as the source of truth.

## Question

**Q1.** An Application’s `source.path` is:

- A. An EventBus subject
- B. The directory in the repo to render
- C. The canary Service
- D. The workflow entrypoint

**Q2.** `destination.namespace` is:

- A. Always `argocd`
- B. Where the **app resources** are created
- C. Only Redis
- D. Only Dex

**Q3.** `destination.server: https://kubernetes.default.svc` means:

- A. A remote GKE only
- B. In-cluster Kubernetes API (same cluster as Argo CD)
- C. MinIO
- D. GitHub API

**Q4.** `project: default`:

- A. Is a WorkflowTemplate
- B. Associates the app with an AppProject (constraints)
- C. Is EventSource
- D. Is AnalysisTemplate

**Q5.** Health Degraded vs Sync OutOfSync:

- A. Identical
- B. Health is runtime; sync is Git vs live spec
- C. Both mean prune
- D. Both mean canary pause

**Q6.** `ignoreDifferences` is for:

- A. Deleting Git
- B. Fields that should not fail the diff (HPA replicas, etc.)
- C. EventBus ACL
- D. DAG failFast

**Q7.** `argocd app diff`:

- A. Runs a Workflow
- B. Shows desired vs live
- C. Shifts traffic
- D. Creates EventBus

**Q8.** Multi-source Application:

- A. Illegal
- B. Can combine e.g. Helm chart + Git values
- C. Requires Flux
- D. Requires Events

**Q9.** Argo CD rollback:

- A. Only kubectl undo while Git stays new
- B. Re-sync a previously recorded revision of desired state
- C. Deletes the project
- D. Always force-push Git

**Q10.** Application CRs usually live in:

- A. `kube-system` only
- B. The Argo CD namespace (commonly `argocd`)
- C. Every namespace randomly
- D. etcd as Git

## Answers

**Q1.** B  
**Q2.** B  
**Q3.** B  
**Q4.** B  
**Q5.** B  
**Q6.** B  
**Q7.** B  
**Q8.** B  
**Q9.** B  
**Q10.** B

## Hands-on

`argocd app create` (or YAML) pointing at a public guestbook repo. `argocd app get`. Inspect `.status.sync` and `.status.health`.

## Exam tips

- **source = where YAML comes from. destination = where it goes.**
- **Sync ≠ Health.**
- Rollback = old **desired** revision, not a secret cluster mutation.
