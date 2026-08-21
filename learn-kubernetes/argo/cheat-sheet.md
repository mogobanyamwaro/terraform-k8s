# Exam-Day Cheat Sheet

Last page before CAPA. Closed book. **90 minutes, 60 questions, 75% (45/60).**

## Exam Facts

| | |
| --- | --- |
| Name | Certified Argo Project Associate (CAPA) |
| Format | Multiple choice, PSI |
| Docs | **None** |
| Focus | **Which Argo tool** + CRDs for all four |

| Domain | Weight | ~Q |
| --- | ---: | ---: |
| **Workflows** | **36%** | ~22 |
| **Argo CD** | **34%** | ~20 |
| Rollouts | 18% | ~11 |
| Events | 12% | ~7 |

## Which Tool

| Job | Tool |
| --- | --- |
| Git = cluster | **CD** |
| Container DAG / ETL / CI jobs | **Workflows** |
| Canary / blue-green / analysis | **Rollouts** |
| Webhook / S3 / Kafka / GitHub event | **Events** |

## Workflows

- `entrypoint` + `templates` + `arguments`
- Definitions: container, script, resource, suspend, containerSet, http
- Invocators: **steps** (inner parallel, outer sequence), **dag** (`dependencies`, `{{tasks}}`)
- WorkflowTemplate = library; Workflow = run; CronWorkflow = schedule
- Parameters = values; artifacts = files (S3/MinIO, tar.gz)
- `retryStrategy`, `onExit`, `parallelism`, `failFast`
- `templateRef` / ClusterWorkflowTemplate

## Argo CD

- repo-server **renders**; application-controller **reconciles**; server = UI/CLI
- Application: source + destination + project + syncPolicy
- Sync ≠ Health. OutOfSync vs Degraded
- automated: **prune**, **selfHeal**. Refresh ≈ 3m + webhook
- Wave: lower first, default **0**. Hooks: PreSync, PostSync, SyncFail
- App-of-Apps = Git list of Applications. ApplicationSet = generators
- AppProject: sourceRepos, destinations
- Helm: `chart` + version or Git path + `valueFiles`. Kustomize: `path`

## Rollouts

- Rollout ≈ Deployment + `blueGreen` / `canary`
- Blue-green: **active** vs **preview**, then **promote**
- Canary: `setWeight`, `pause` (`{}` = wait), `analysis`
- AnalysisTemplate = spec; AnalysisRun = execution; fail → **abort**
- CD syncs the YAML; Rollouts moves traffic

## Events

```text
EventSource → EventBus → Sensor → Trigger
```

- Bus: JetStream / Kafka (STAN deprecated)
- Trigger is **on the Sensor** (often `argoWorkflow` submit)
- Events ≠ CD Git webhook
- Cron of a workflow only → **CronWorkflow**

## Strategy

90s/question. Flag YAML-dense items. When two tools fit, pick the one that **owns the mechanism** (traffic = Rollouts, Git drift = CD). Never leave blank.
