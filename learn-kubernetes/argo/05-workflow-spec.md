# 05. Workflow Spec

**Domain:** Argo Workflows (36%) — Understand the Argo Workflow Spec

## Concept Refresher

Important `Workflow.spec` fields:

| Field | Meaning |
| --- | --- |
| `entrypoint` | Name of the starting template |
| `templates` | Template library |
| `arguments` | Workflow-level parameters/artifacts |
| `serviceAccountName` | SA for pods |
| `volumes` / `volumeClaimTemplates` | Shared storage |
| `retryStrategy` | Retries for the workflow or a template (`retryPolicy`: Always, OnFailure, OnError, OnTransientError) |
| `parallelism` | Max concurrent pods |
| `ttlStrategy` | When to GC the Workflow CR after finish |
| `podGC` | When to delete completed pods |
| `onExit` | Template always run at the end (success **or** fail) — exit handler |
| `imagePullSecrets` | Registry auth |
| `nodeSelector` / `tolerations` / `affinity` | Placement |
| `activeDeadlineSeconds` | Timeout |
| `hooks` / `template-level hooks` | Lifecycle (newer than only onExit) |

**CronWorkflow.spec** wraps a `workflowSpec` plus schedule:

| Field | Meaning |
| --- | --- |
| `schedules` | Cron expressions (v3.6+ plural; older `schedule` singular) |
| `timezone` | IANA TZ |
| `concurrencyPolicy` | Allow / Forbid / Replace |
| `startingDeadlineSeconds` | Catch-up window |
| `successfulJobsHistoryLimit` / `failedJobsHistoryLimit` | History |
| `workflowSpec` | Embedded Workflow spec |
| `suspend` | Pause the cron |

`argo submit --parameter msg=hi` maps to `spec.arguments.parameters`.

## Question

**Q1.** `spec.entrypoint` selects:

- A. The Git branch for Argo CD
- B. Which template starts the workflow
- C. The EventBus
- D. The preview Service

**Q2.** Workflow-level inputs belong in:

- A. `spec.destination`
- B. `spec.arguments`
- C. `spec.syncPolicy`
- D. `status.health`

**Q3.** `retryStrategy` on a template:

- A. Shifts traffic
- B. Re-runs a failed template according to policy/limits
- C. Prunes Git
- D. Creates an Application

**Q4.** `onExit` (exit handler):

- A. Runs only if the workflow succeeded
- B. Runs when the workflow ends, success or failure (typical notify/cleanup)
- C. Is Cron only
- D. Is Argo CD PostSync only

**Q5.** `volumeClaimTemplates` on a Workflow:

- A. Are ApplicationSets
- B. Provision PVCs for this run (data jobs)
- C. Are EventSources
- D. Are AnalysisRuns

**Q6.** CronWorkflow `concurrencyPolicy: Forbid` means:

- A. Delete Git
- B. Skip a new run if the previous is still active
- C. Always replace
- D. Always overlap

**Q7.** `spec.parallelism: 2` limits:

- A. Git clones
- B. How many workflow pods may run at once
- C. Canary weight
- D. AppProject destinations

**Q8.** `ttlStrategy` is about:

- A. Helm chart version
- B. Garbage-collecting finished Workflow objects
- C. EventBus retention only
- D. Ingress TTL

**Q9.** `activeDeadlineSeconds` :

- A. Is prune
- B. Fails the workflow if it runs too long
- C. Is selfHeal
- D. Is sync-wave

**Q10.** `argo submit -p key=value` sets:

- A. An EventSource
- B. A workflow argument parameter
- C. A Rollout pause
- D. A Dex connector

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

Add `retryStrategy: {limit: 2}` to a flaky script template. Create a CronWorkflow with `schedules: ["*/10 * * * *"]` and `timezone: UTC`.

## Exam tips

- **entrypoint + templates + arguments** = the spec core.
- **onExit** = always at the end.
- Cron = `workflowSpec` + schedule + concurrencyPolicy.
