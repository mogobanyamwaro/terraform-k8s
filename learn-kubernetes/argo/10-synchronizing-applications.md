# 10. Synchronizing Applications

**Domain:** Argo CD (34%) — Synchronize Applications

## Concept Refresher

**Sync** = apply desired manifests so live matches Git.

| Mode | Behaviour |
| --- | --- |
| Manual | Human/`argocd app sync` / UI Sync |
| Automated | `syncPolicy.automated` when Git changes (and on refresh) |

Automated knobs:

```yaml
syncPolicy:
  automated:
    prune: true       # delete resources removed from Git
    selfHeal: true    # revert cluster-only changes
    allowEmpty: false
  syncOptions:
  - CreateNamespace=true
  retry:
    limit: 5
```

Without **prune**, deleted Git resources may remain in cluster. Without **selfHeal**, `kubectl` edits persist until the next sync (manual or git change).

**Refresh** = re-fetch Git and compare (does not always apply). **Hard refresh** bypasses cache.

**Sync options** (examples): `PruneLast`, `ApplyOutOfSyncOnly`, `RespectIgnoreDifferences`, `ServerSideApply=true`.

**Force** / **replace** are escape hatches for immutable fields — know they exist; not day-to-day GitOps.

Webhook speeds detection; automation still applies.

## Question

**Q1.** A sync operation:

- A. Only updates Redis
- B. Applies desired state so live matches Git
- C. Always runs a DAG
- D. Always shifts canary 10%

**Q2.** `automated.selfHeal: true`:

- A. Disables Git
- B. Reverts live drift toward Git
- C. Is EventBus
- D. Is Dex

**Q3.** `automated.prune: true`:

- A. Deletes the Git repo
- B. Deletes cluster resources that disappeared from Git
- C. Deletes Argo CD itself
- D. Deletes only Secrets always

**Q4.** Manual sync only, engineer kubectl-scales replicas:

- A. Self-heal reverts immediately always
- B. Drift remains until someone syncs (or Git changes if auto without selfHeal still may wait)
- C. Git updates automatically
- D. The Application is deleted

**Q5.** `argocd app refresh`:

- A. Always prunes
- B. Re-compares desired vs live (hard refresh skips cache)
- C. Creates a Workflow
- D. Creates an EventSource

**Q6.** `CreateNamespace=true`:

- A. A sync option to create the destination namespace
- B. A Rollout pause
- C. A DAG dependency
- D. An EventBus

**Q7.** Auto-sync without prune:

- A. Always deletes unused Ingresses
- B. May leave orphaned live resources after Git deletes them
- C. Forbids Helm
- D. Forbids Kustomize

**Q8.** Git webhook to Argo CD:

- A. Replaces Git as store
- B. Notifies Argo CD to refresh sooner than the interval
- C. Is the only legal sync
- D. Applies from GitHub Actions kubectl

**Q9.** Retry on syncPolicy:

- A. Is Workflow retryStrategy only
- B. Can retry a failed sync
- C. Is canary analysis
- D. Is CronWorkflow

**Q10.** OutOfSync with auto-sync + selfHeal on:

- A. Argo CD will attempt to converge
- B. Argo CD never applies
- C. Only Events can apply
- D. Only Rollouts can apply

## Answers

**Q1.** B  
**Q2.** B  
**Q3.** B  
**Q4.** B  
**Q5.** B  
**Q6.** A  
**Q7.** B  
**Q8.** B  
**Q9.** B  
**Q10.** A

## Hands-on

Create an Application with auto-sync off. Change a live replica count; observe OutOfSync. Sync. Enable selfHeal and repeat.

## Exam tips

- **Refresh = look. Sync = apply.**
- **selfHeal** fights kubectl. **prune** fights leftover objects.
