# 13. Reconciliation Patterns

**Domain:** Argo CD (34%) — Identify Common Reconciliation Patterns

## Concept Refresher

Reconciliation = **compare + (optionally) apply**.

**Compare:** Git-rendered manifests vs live API objects (minus ignored fields). Result: Synced / OutOfSync.

**Health:** built-in checks (Deployment has available replicas, etc.). Custom health in `argocd-cm` Lua for CRDs (e.g. Rollout, Workflow, Crossplane).

**Patterns**

| Pattern | Meaning |
| --- | --- |
| Manual GitOps | Humans sync |
| Auto GitOps | automated + prune + selfHeal |
| App-of-Apps | Root Application whose YAML is more Applications |
| ApplicationSet | Generate apps from clusters/dirs/PRs |
| Multi-cluster | One Argo CD, many `destination.server` |
| Sync waves | Order resources during one sync |
| Hooks | Jobs around sync (migrate, smoke) |
| Progressive | Git holds a **Rollout**; Rollouts controller shifts traffic |
| Ignore / SSA | Reduce thrash (HPA, kubectl-managed labels) |

**Stuck OutOfSync:** webhook missing, repo credentials, invalid YAML, RBAC, immutable field, health never Healthy (Progressing forever).

**Missing** health: resource in Git not found live (not created yet, or wrong namespace).

Do not call Workflow controller “reconciliation of Applications”.

## Question

**Q1.** Reconciliation in Argo CD is:

- A. Only Slack
- B. Compare desired vs live and optionally sync
- C. Only DAG scheduling
- D. Only Kafka consume

**Q2.** Custom health for a CRD is typically:

- A. An EventSource
- B. Lua in Argo CD config (`argocd-cm`)
- C. A CronWorkflow
- D. Dex

**Q3.** App-of-Apps:

- A. Forbidden
- B. A parent Application that syncs child Application manifests
- C. An EventBus
- D. A canary step

**Q4.** HPA owns replicas; Git has replicas: 1:

- A. Must fight forever with no options
- B. `ignoreDifferences` (or SSA/HPA-aware pattern)
- C. Delete HPA always
- D. Use Events

**Q5.** Multi-cluster GitOps:

- A. Impossible
- B. Management Argo CD with destinations to many API servers
- C. Requires one etcd
- D. Requires Workflows

**Q6.** Resource health Missing:

- A. Synced and live always
- B. Desired object not present live
- C. EventBus down only
- D. Canary 100%

**Q7.** Auto-sync + selfHeal + prune is the pattern for:

- A. ClickOps
- B. Continuous GitOps convergence
- C. Manual-only CD
- D. Batch ETL

**Q8.** A Deployment is Synced but Degraded:

- A. Impossible
- B. Git matches spec, but runtime is unhealthy (crashloop, etc.)
- C. Git always mismatches
- D. Prune failed only

**Q9.** ApplicationSet vs App-of-Apps:

- A. Identical always
- B. ApplicationSet **generates** Applications from generators; App-of-Apps **syncs** Application YAML as child resources
- C. ApplicationSet is Rollouts
- D. App-of-Apps is Events

**Q10.** Progressive delivery with Argo CD:

- A. CD’s rollingUpdate is the only option
- B. Git declares a Rollout; CD syncs it; Rollouts executes the strategy
- C. Workflows shifts Istio weight
- D. EventBus shifts weight

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

Break a Deployment image, watch Health Degraded while Sync may still be Synced after Git has the bad image. Then revert Git.

## Exam tips

- **Synced + Degraded** is a standard combo.
- CD **syncs Rollouts**; Rollouts **does** canary.
- App-of-Apps ≠ ApplicationSet (related but not the same).
