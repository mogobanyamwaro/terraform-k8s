# 21. EventSource and EventBus

**Domain:** Argo Events (12%) — Components and Architecture

## Concept Refresher

Four official components: **EventSource**, **EventBus**, **Sensor**, **Trigger** (Trigger lives **on the Sensor**, not as its own CRD).

**EventSource:** watches the outside world, normalises to **CloudEvents**, **publishes** to the EventBus. Examples: `webhook`, `minio`, `kafka`, `calendar`, `resource`, `github`, `sns`, …

**EventBus:** **transport** between sources and sensors (pub/sub). Implementations: **NATS JetStream**, **Kafka**, legacy **NATS Streaming (STAN) deprecated**. Sources do not call Sensors directly.

Flow:

```text
External system → EventSource → EventBus → Sensor → Trigger
```

You typically `kubectl apply` an EventBus **before** EventSources/Sensors in a namespace.

EventSource controller creates a **deployment/pod** that actually listens (e.g. webhook Service).

## Question

**Q1.** EventSource’s job is to:

- A. Render Helm
- B. Ingest external events and publish them to the EventBus
- C. Shift canary weight
- D. Sync Applications

**Q2.** EventBus is:

- A. The Git repo
- B. The messaging fabric between EventSources and Sensors
- C. The Rollout preview Service
- D. Dex

**Q3.** Preferred EventBus implementations today:

- A. etcd only
- B. JetStream and/or Kafka (STAN deprecated)
- C. Hubble only
- D. Maglev only

**Q4.** A webhook EventSource typically:

- A. Polls Git every 3 minutes like Argo CD
- B. Exposes an HTTP endpoint that turns POSTs into CloudEvents
- C. Is a DAG template
- D. Is an AppProject

**Q5.** MinIO EventSource:

- A. Is artifactRepository for Workflows only
- B. Can notify on bucket events (object created, …)
- C. Is blue-green activeService
- D. Is Kustomize

**Q6.** EventSource talks to Sensor:

- A. Via direct HTTP always, skipping the bus
- B. Through the EventBus (decoupled pub/sub)
- C. Via Argo CD only
- D. Via Istio only

**Q7.** Calendar EventSource:

- A. Replaces Rollouts
- B. Emits events on a schedule (cron-like)
- C. Is Application health
- D. Is repo-server

**Q8.** Apply order in a namespace:

- A. Sensors before EventBus always required to fail
- B. EventBus should exist so sources/sensors can connect
- C. Applications first always
- D. Rollouts first always

**Q9.** CloudEvents in this architecture:

- A. Are Helm charts
- B. The normalised event format on the bus
- C. Are AnalysisRuns
- D. Are sync waves

**Q10.** K8s `resource` EventSource:

- A. Cannot watch API objects
- B. Can fire when a Kubernetes object changes
- C. Is only MinIO
- D. Is only Kafka

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

Apply native EventBus, then a webhook EventSource. `kubectl get eventsource,eventbus -n argo-events`.

## Exam tips

- **Source publishes. Bus transports. Sensor consumes.**
- STAN is **deprecated**. JetStream/Kafka are current.
- Trigger is **not** a fourth CRD.
