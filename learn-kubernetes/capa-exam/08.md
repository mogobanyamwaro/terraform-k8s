# 08. Data Processing Jobs

**Domain:** Argo Workflows (36%) — Run Data Processing Jobs

## Concept Refresher

Exam “data processing” means: **map/reduce style DAGs**, artifacts or PVCs between stages, fan-out (`withParam`), retries, timeouts, exit handlers, and sometimes resource templates that create Jobs/Spark CRs.

Typical pipeline:

1. **Ingest** (HTTP/S3 artifact in)
2. **Fan-out** process partitions (`withParam` / DAG tasks)
3. **Reduce** / join
4. **Publish** artifact out or `resource` apply a ConfigMap/Job result
5. **onExit** notify Slack (or HTTP template)

Patterns to name:

| Pattern | Workflow feature |
| --- | --- |
| Partitioned process | `withParam` / DAG fan-out |
| Shared scratch | PVC / `volumeClaimTemplates` |
| Large files | Artifacts (S3) |
| Flaky workers | `retryStrategy` |
| Late cleanup | `onExit` |
| Cap cluster load | `parallelism` |
| Nightly ETL | CronWorkflow |
| Kick off from S3 put | **Argo Events** trigger, not Cron |

Workflows can **be** CI (build images) but image **deploy** to prod GitOps is still **Argo CD**. Data scientists often never touch CD.

## Question

**Q1.** A nightly Spark-on-K8s DAG belongs with:

- A. Argo Rollouts canary
- B. Argo Workflows (often CronWorkflow)
- C. Only Hubble
- D. Only Ingress

**Q2.** Processing N JSON files listed by a previous step:

- A. `withParam` fan-out
- B. `setWeight`
- C. `prune: true`
- D. AppProject `sourceRepos`

**Q3.** Intermediate parquet files between DAG tasks:

- A. Must be parameters
- B. Artifacts or a shared PVC
- C. Must be EventBus messages only
- D. Must be Application sources

**Q4.** Limit 10 worker pods at a time:

- A. `spec.parallelism`
- B. `spec.syncPolicy`
- C. `autoPromotionEnabled`
- D. `eventBus.name`

**Q5.** Notify Slack whether ETL succeeded or failed:

- A. Only a canary pause
- B. `onExit` / hooks HTTP or script
- C. Only `selfHeal`
- D. Only Dex

**Q6.** S3 object-created should start the DAG **immediately**:

- A. CronWorkflow alone is the best fit
- B. Argo Events EventSource + Sensor trigger of a Workflow
- C. Argo CD selfHeal
- D. Rollout AnalysisRun

**Q7.** `resource` template in a data job might:

- A. Shift Istio weight
- B. Apply a Kubernetes Job/CR for a compute framework
- C. Replace EventBus
- D. Replace Git

**Q8.** Retry a flaky download step:

- A. `retryStrategy` on that template
- B. `destination.server`
- C. `previewService`
- D. `sensors.triggers`

**Q9.** GitOps of the **pipeline definition** vs a **run**:

- A. Impossible
- B. CD can sync WorkflowTemplates; each execution is a Workflow CR
- C. Each run must be an Application
- D. Each run must be a Rollout

**Q10.** Workflows replacing Argo CD for prod Deployments:

- A. Recommended GitOps
- B. Mixes batch orchestration with GitOps CD; CAPA expects the split
- C. Required
- D. The only CNCF pattern

## Answers

**Q1.** B  
**Q2.** A  
**Q3.** B  
**Q4.** A  
**Q5.** B  
**Q6.** B  
**Q7.** B  
**Q8.** A  
**Q9.** B  
**Q10.** B

## Hands-on

Fan-out `withParam` over `[1,2,3]`, write each as an artifact, then a join step. Add `onExit`.

## Exam tips

- Data jobs = **DAG + artifacts + parallelism + retry + onExit**.
- Event-driven start = **Events**, scheduled = **CronWorkflow**.
- Do not use Workflows as the GitOps CD engine.
