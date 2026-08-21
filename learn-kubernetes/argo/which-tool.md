# Which Argo Tool?

CAPA’s first filter. Mixing tools is the most common way to lose easy points.

## One-line map

| Need | Tool | Not this |
| --- | --- | --- |
| Keep cluster = Git (GitOps CD) | **Argo CD** | Workflows `kubectl apply` in a step |
| Run a pipeline of containers on Kubernetes | **Workflows** | Argo CD Application |
| Canary / blue-green / metric abort | **Rollouts** | Deployment rollingUpdate only |
| React to webhook, S3, Kafka, cron, GitHub | **Events** | CD polling Git (that is CD refresh) |

## Typical exam stems

**“A data team needs a DAG of Spark/Python jobs with files between steps.”**  
→ Workflows + artifacts. Not CD.

**“Prod YAML lives in Git; the cluster must self-heal.”**  
→ Argo CD (`automated` + `selfHeal`). Not Events.

**“New version gets 10% traffic, Prometheus error rate must stay low, else abort.”**  
→ Rollouts canary + AnalysisTemplate. CD can *sync the Rollout object*; CD does not *do* canary by itself.

**“When a file lands in S3, start the ETL workflow.”**  
→ Events (MinIO/S3 EventSource) → Sensor trigger → Workflow. Not CD sync.

**“Every night at 02:00 run the report workflow.”**  
→ **CronWorkflow** (Workflows). Events also has a calendar EventSource; for a pure schedule of a Workflow, CronWorkflow is the native answer.

## Integration (still two tools)

```text
Git (Rollout + Service YAML)
        |
     Argo CD          <- GitOps of the Rollout object
        |
   Argo Rollouts      <- actually shifts traffic

S3 put
        |
  Argo Events         <- capture
        |
 Argo Workflows       <- ETL DAG
```

Do not say “Argo CD runs the DAG”. Do not say “Workflows is GitOps CD”.

## Related practices (exam language)

| Practice | Argo mapping |
| --- | --- |
| GitOps | Argo CD |
| CI / batch / ML pipelines | Workflows |
| Progressive delivery | Rollouts |
| Event-driven architecture | Events |
| Platform engineering | Often all four, wired as above |
