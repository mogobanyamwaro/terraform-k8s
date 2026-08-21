# 18. Canary Strategy

**Domain:** Argo Rollouts (18%) — Progressive strategies

## Concept Refresher

**Canary:** shift a **percentage** of traffic (or replica weight) to the new version, pause, analyse, repeat, then 100%.

```yaml
strategy:
  canary:
    canaryService: myapp-canary
    stableService: myapp-stable
    trafficRouting:
      istio:
        virtualService:
          name: myapp
    steps:
    - setWeight: 10
    - pause: {duration: 5m}
    - analysis:
        templates:
        - templateName: success-rate
    - setWeight: 50
    - pause: {}          # wait until promote
    - setWeight: 100
```

**Steps** (know the names): `setWeight`, `pause`, `analysis`, `setCanaryScale`, `experiment`, `plugin`, `setHeaderRoute`, `setMirrorRoute`.

Without a mesh, Rollouts can canary by **replica counts** (approximate traffic). With Istio/NGINX/ALB, **true** traffic %.

**Abort** on failed analysis. **Promote** skips remaining pauses.

Header-based and mirror (shadow) routes exist for finer experiments.

## Question

**Q1.** Canary `setWeight: 20` means:

- A. 20 replicas always
- B. About 20% of traffic (or weight) to canary
- C. Wave 20
- D. 20 CronWorkflows

**Q2.** `pause: {}` with no duration:

- A. Fails the rollout
- B. Waits until promote (indefinite pause)
- C. Skips analysis always
- D. Deletes stable

**Q3.** `pause: {duration: 10m}`:

- A. Git refresh
- B. Automatic continue after 10 minutes
- C. EventBus TTL
- D. Helm timeout only

**Q4.** Analysis step in the canary list:

- A. Is Argo CD PostSync only
- B. Runs AnalysisRun(s); failure can abort
- C. Is a WorkflowTemplate
- D. Is AppProject

**Q5.** Stable vs canary Service:

- A. Blue-green names only
- B. Split traffic between old and new during canary
- C. EventSource vs Sensor
- D. repo-server vs controller

**Q6.** Without Istio, canary weight:

- A. Impossible
- B. Often approximated by pod counts (`setCanaryScale` / replica ratio)
- C. Requires Dex
- D. Requires MinIO

**Q7.** Abort on bad error rate:

- A. CD prune
- B. Failed analysis → rollout abort toward stable
- C. DAG failFast only
- D. EventBus disconnect only

**Q8.** `setMirrorRoute`:

- A. Deletes Git
- B. Shadows traffic to canary without serving users that response
- C. Is blue-green preview only
- D. Is CronWorkflow

**Q9.** Promote during a pause:

- A. Deletes the Rollout
- B. Advances remaining steps (skips waits)
- C. Creates ApplicationSet
- D. Submits CronWorkflow

**Q10.** Mixing canary YAML in Git with Argo CD auto-sync:

- A. CD performs setWeight
- B. CD updates the Rollout spec; Rollouts walks steps
- C. Workflows walks steps
- D. Events walks steps

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

Walk a 20% → pause → 50% → 100% example. Abort once to see stable restore.

## Exam tips

- **Steps are sequential:** weight, pause, analysis.
- Empty pause = **wait for promote**.
- Mesh = real %; else replica approximation.
