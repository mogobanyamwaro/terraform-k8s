# 14. Sync Waves and Hooks

**Domain:** Argo CD (34%) — Synchronize Applications / reconciliation

## Concept Refresher

One sync can **order** resources.

**Sync waves:** annotation `argocd.argoproj.io/sync-wave: "1"` (string number). Lower waves first. Default wave `0`. Example: Namespace/CRDs wave `-1`, app wave `0`, Ingress wave `1`.

**Hooks:** Jobs (usually) annotated `argocd.argoproj.io/hook: PreSync|Sync|PostSync|SyncFail|Skip` and `hook-delete-policy`.

| Hook | When |
| --- | --- |
| PreSync | Before apply (e.g. DB migrate Job) |
| Sync | During (alongside or as part of sync) |
| PostSync | After successful sync |
| SyncFail | After failed sync |
| Skip | Don’t apply this resource as a live object (rare/special) |

Hooks that fail **fail the sync**. Wave + hook together: PreSync still before resource apply.

This is **not** Workflows DAG (different controller). It is **not** Rollouts analysis (metrics during canary).

## Question

**Q1.** Sync waves control:

- A. EventBus topics
- B. Order of resources within a sync
- C. DAG failFast
- D. Canary `setWeight` only

**Q2.** Default sync-wave is:

- A. 100
- B. 0
- C. -99 always required
- D. Only 1

**Q3.** CRDs before CRs typically:

- A. Higher wave numbers first
- B. Lower wave (e.g. `-1`) before `0`
- C. Random
- D. Only PostSync

**Q4.** A PreSync hook is commonly:

- A. An EventSource
- B. A Job that must succeed before resources apply
- C. A CronWorkflow
- D. Dex

**Q5.** PostSync runs:

- A. Before Git clone
- B. After a successful sync
- C. Only on OutOfSync forever
- D. Instead of prune

**Q6.** SyncFail hook:

- A. Runs when sync succeeds
- B. Runs when sync fails (alert/cleanup)
- C. Is selfHeal
- D. Is ApplicationSet

**Q7.** Failed PreSync Job:

- A. Sync continues anyway always
- B. Sync fails
- C. Converts to canary
- D. Deletes Git

**Q8.** Waves vs Workflows DAG:

- A. Identical CRDs
- B. Waves order **CD apply**; DAG orchestrates **workflow pods**
- C. DAG is only for Ingress
- D. Waves are EventBus

**Q9.** Annotation for wave:

- A. `rollouts.argoproj.io/weight`
- B. `argocd.argoproj.io/sync-wave`
- C. `workflows.argoproj.io/entrypoint`
- D. `events.argoproj.io/sensor`

**Q10.** DB migration then app then smoke test maps to:

- A. PreSync Job, app wave 0, PostSync Job
- B. Only EventBus
- C. Only blue-green preview
- D. Only `withParam`

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
**Q10.** A

## Hands-on

Annotate a ConfigMap `sync-wave: "-1"` and a Deployment `0`. Watch apply order on sync.

## Exam tips

- **Lower wave first.**
- **PreSync / PostSync / SyncFail** = Jobs around apply.
- Not Rollouts analysis, not Workflow DAG.
