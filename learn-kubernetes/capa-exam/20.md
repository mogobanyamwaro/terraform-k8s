# 20. Argo Events Fundamentals

**Domain:** Argo Events (12%)

## Concept Refresher

**Argo Events** is a Kubernetes **event-driven** automation framework. It **does not** replace GitOps CD. It **does not** run DAGs itself. It **triggers** other things — most famously **Argo Workflows**, also K8s objects, HTTP, AWS Lambda, Kafka, Slack, …

Classic line: *when X happens, start Y*.

X = webhook, S3/MinIO, Kafka, AMQP, GitHub, GitLab, calendar/cron, resource (K8s), MQTT, NATS, Redis, Azure, GCP Pub/Sub, Slack, Stripe, …

Y = Trigger (Workflow, sink, …).

**Events does not require Workflows to be installed**, but CAPA scenarios often wire them together. Calendar EventSource vs **CronWorkflow**: both can schedule; CronWorkflow is native if the only goal is “run this workflow on a cron”. Events is the answer when the trigger is **external** or **multi-source**.

## Question

**Q1.** Argo Events is for:

- A. Helm rendering
- B. Reacting to events and firing triggers
- C. Blue-green preview Services
- D. Application health Lua

**Q2.** “When an object is PUT to S3, start ETL”:

- A. Argo CD selfHeal
- B. Events (MinIO/S3) → Sensor → Workflow
- C. Rollouts setWeight
- D. AppProject

**Q3.** Events vs Workflows:

- A. Identical CRDs
- B. Events decides **when**; Workflows is **what graph runs**
- C. Workflows is the EventBus
- D. Events is the DAG engine

**Q4.** Events vs Argo CD:

- A. Events keeps Git = cluster
- B. CD reconciles Git; Events reacts to world events
- C. CD is only webhooks
- D. Events renders Kustomize

**Q5.** GitHub webhook to run a Workflow:

- A. Only ApplicationSet PR generator
- B. A typical Events EventSource + Sensor trigger
- C. Only Rollouts analysis
- D. Only Dex

**Q6.** Must Workflows be installed for Events to exist?

- A. Yes always
- B. No; Workflows is a common **trigger target**, not a required bus
- C. Yes, and Rollouts too
- D. Yes, and Argo CD too

**Q7.** Nightly report **only**, no other events:

- A. Events is the only spec-legal answer
- B. CronWorkflow is the native Workflows scheduler
- C. Must be canary
- D. Must be ApplicationSet

**Q8.** Kafka message processing pipeline kickoff:

- A. Argo CD prune
- B. Kafka EventSource + Sensor
- C. sync-wave
- D. previewService

**Q9.** Platform engineering “glue”:

- A. Events cannot call Workflows
- B. Events is the usual glue from SaaS/webhooks into Workflows
- C. Events replaces Kubernetes
- D. Events replaces Git

**Q10.** CAPA Events weight is small, so:

- A. Skip the components
- B. Still learn EventSource, EventBus, Sensor, Trigger — easy points
- C. Only memorise Helm
- D. Only memorise canary

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

Install Events + a native EventBus. Optional: webhook EventSource that triggers a hello Workflow.

## Exam tips

- **When → Events. Graph → Workflows. Git → CD. Traffic → Rollouts.**
- Events ≠ CD webhook refresh.
