# Argo Events (Deep Dive)

**12%.** Docs: [argoproj.github.io/argo-events](https://argoproj.github.io/argo-events/).

## Architecture

```text
EventSource  --publish-->  EventBus  --subscribe-->  Sensor  --fires-->  Trigger
```

Trigger is a **field on Sensor**, not a CRD.

| Component | Role |
| --- | --- |
| EventSource | Ingest (webhook, Kafka, MinIO, GitHub, calendar, K8s resource, …) → CloudEvents |
| EventBus | Transport: **JetStream**, **Kafka** (NATS Streaming deprecated) |
| Sensor | Dependencies + filters + triggers |
| Trigger | argoWorkflow, k8s, http, kafka, slack, lambda, … |

Install EventBus **first** in the namespace.

## vs lookalikes

| Need | Prefer |
| --- | --- |
| Cron of a Workflow only | CronWorkflow |
| Git change → cluster | Argo CD (+ webhook) |
| Object created / GitHub PR / Kafka | **Events** |
| The job graph | Workflows |

## Payload

Sensor maps `dataKey` from the CloudEvent into Workflow `arguments.parameters`.

## Integration picture (memorise)

S3 put → EventSource → Sensor → Workflow (ETL DAG) → maybe Git commit image → Argo CD → Rollout canary.
