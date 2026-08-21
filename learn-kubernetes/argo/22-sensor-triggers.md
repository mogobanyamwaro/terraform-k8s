# 22. Sensor and Triggers

**Domain:** Argo Events (12%) — Components and Architecture

## Concept Refresher

**Sensor** subscribes to the EventBus, evaluates **dependencies** (which EventSource + event name, filters, `atLeast`/`any` conditions), then fires **triggers**.

```yaml
kind: Sensor
spec:
  dependencies:
  - name: webhook-dep
    eventSourceName: webhook
    eventName: example
  triggers:
  - template:
      name: start-etl
      argoWorkflow:
        operation: submit
        source:
          resource:
            apiVersion: argoproj.io/v1alpha1
            kind: Workflow
            ...
```

**Triggers** (recognise): `argoWorkflow`, `http`, `k8s` (create Job/Pod/any), `kafka`, `nats`, `awsLambda`, `slack`, `openWhisk`, `azureEventHubs`, `pulsar`, `log`, …

Parameters map event payload JSON into the Workflow (`dataKey` → dest).

Filters: data filters, expr, time. Multiple dependencies can require **all** events or combinations.

Sensor is **not** the EventBus. Sensor is **not** Argo CD application-controller.

Failed trigger retries depend on Sensor trigger policy — know retries exist; details are not the exam core.

## Question

**Q1.** A Sensor:

- A. Clones Git for Helm
- B. Consumes bus events and executes triggers when dependencies match
- C. Is the Rollout canary Service
- D. Is Dex

**Q2.** `dependencies.eventSourceName`:

- A. An AppProject
- B. Which EventSource to listen to
- C. A sync-wave
- D. A DAG task

**Q3.** The most exam-typical trigger:

- A. Maglev
- B. Submit an Argo Workflow
- C. Hubble observe
- D. Cilium BGP

**Q4.** HTTP trigger:

- A. Cannot exist
- B. Calls an external URL when the event fires
- C. Is repo-server
- D. Is previewService

**Q5.** K8s trigger:

- A. Only Argo CD sync
- B. Creates/patches a Kubernetes object
- C. Only EventBus
- D. Only AnalysisTemplate

**Q6.** Mapping S3 object key into a Workflow parameter:

- A. Impossible
- B. Sensor payload/parameter `dataKey` → workflow argument
- C. Only Helm values
- D. Only ignoreDifferences

**Q7.** Two dependencies with AND semantics:

- A. Forbidden
- B. Sensor can require multiple events before triggering
- C. Only Rollouts can AND
- D. Only CD waves AND

**Q8.** Trigger vs EventSource:

- A. Identical
- B. Source **ingests**; trigger **acts**
- C. Trigger ingests Kafka
- D. Source shifts canary

**Q9.** Slack trigger:

- A. Replaces Git
- B. Human notification as an action
- C. Is selfHeal
- D. Is prune

**Q10.** Events → Workflow → (optional) Git commit of image → Argo CD:

- A. Illegal mash-up
- B. A valid integration: Events kicks CI-like Workflow; CD still deploys from Git
- C. CD must submit the Workflow
- D. Rollouts must be the EventBus

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

Sensor with `argoWorkflow` trigger on the webhook EventSource. POST to the webhook; `argo list`.

## Exam tips

- **Sensor = if this event, then that trigger.**
- Default picture: **Workflow submit**.
- Payload mapping is how event data becomes parameters.
