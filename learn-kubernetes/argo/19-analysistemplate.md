# 19. AnalysisTemplate and AnalysisRun

**Domain:** Argo Rollouts (18%) — Describe Analysis Template and AnalysisRun

## Concept Refresher

**AnalysisTemplate** (namespace) / **ClusterAnalysisTemplate**: **reusable** metric/job spec. Not an execution.

**AnalysisRun:** **one execution** created by a Rollout (or Experiment) for a step / pre-post promotion. Status: Successful, Failed, Inconclusive, Error, Running, Pending.

```yaml
kind: AnalysisTemplate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus:9090
        query: ...
```

**Providers** (recognise): prometheus, datadog, newRelic, wavefront, kayenta, web, job, cloudWatch, graphite, influxdb, skywalking, plugin.

**job** provider: run a Kubernetes Job; success of the Job is the metric.

**Args** pass Rollout metadata into queries (`{{args.service-name}}`).

Failure → Rollout **abort**. Inconclusive can be configured (`inconclusiveLimit`).

Do not confuse with WorkflowTemplate or Argo CD Application.

## Question

**Q1.** AnalysisTemplate is:

- A. A running canary
- B. A reusable analysis specification
- C. An EventBus
- D. An Application

**Q2.** AnalysisRun is:

- A. Only a Git tag
- B. A concrete execution of analysis
- C. A CronWorkflow
- D. A Dex connector

**Q3.** Prometheus provider:

- A. Shifts Istio weight itself
- B. Queries metrics for success/failure conditions
- C. Clones Git
- D. Renders Helm

**Q4.** `successCondition: result[0] >= 0.99`:

- A. A DAG when:
- B. A boolean over the provider result
- C. A sync-wave
- D. An EventSource filter only

**Q5.** `failureLimit`:

- A. Git PR limit
- B. How many failed metric measurements before the run fails
- C. AppProject destination count
- D. Workflow parallelism

**Q6.** Job provider:

- A. Always uses Prometheus
- B. Uses a Kubernetes Job as the check (e.g. integration test)
- C. Is EventBus
- D. Is repo-server

**Q7.** Who creates AnalysisRuns during a canary?

- A. Dex
- B. Rollouts controller (from templates referenced in the Rollout)
- C. Workflow controller always
- D. ApplicationSet always

**Q8.** Failed AnalysisRun typically:

- A. Prunes Git
- B. Causes the Rollout to abort
- C. Deletes Argo CD
- D. Creates EventBus

**Q9.** ClusterAnalysisTemplate:

- A. Namespace-only
- B. Cluster-scoped reusable analysis
- C. An ApplicationSet
- D. A Sensor

**Q10.** AnalysisTemplate vs WorkflowTemplate:

- A. Same CRD
- B. Analysis = Rollouts metrics/jobs; WorkflowTemplate = workflow library
- C. Both are EventSources
- D. Both are Applications

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

Attach a web or job AnalysisTemplate to a canary step. Force a fail condition and watch abort.

## Exam tips

- **Template = spec. Run = instance.**
- Failure → **abort**, not CD prune.
- Prometheus/job/web are the usual exam providers.
