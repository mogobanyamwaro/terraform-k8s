# 17. Blue-Green Strategy

**Domain:** Argo Rollouts (18%) — Progressive strategies

## Concept Refresher

**Blue-green:** two stacks. **Active** (stable/blue) serves users. **Preview** (green) is the new ReplicaSet. After tests/analysis, **promote** switches active to the new version. Old stack scales down after `scaleDownDelaySeconds`.

```yaml
strategy:
  blueGreen:
    activeService: myapp-active
    previewService: myapp-preview
    autoPromotionEnabled: false
    scaleDownDelaySeconds: 30
    prePromotionAnalysis:
      templates:
      - templateName: success-rate
```

| Field | Meaning |
| --- | --- |
| `activeService` | Service selectors updated to the live colour |
| `previewService` | Points at the new version for testing |
| `autoPromotionEnabled` | If false, wait for `promote` (or analysis success) |
| `autoPromotionSeconds` | Delay then promote |
| `prePromotionAnalysis` | Analysis before switch |
| `postPromotionAnalysis` | Analysis after switch |

Users stay on blue until promotion. Contrast **canary**: mixed traffic percentages.

Manual test URL = preview Service / Ingress.

## Question

**Q1.** Blue-green keeps users on:

- A. Mixed 10%/90% always
- B. The active colour until promotion
- C. Only preview always
- D. Only Workflow pods

**Q2.** `previewService` is for:

- A. EventBus
- B. Hitting the new version before the switch
- C. Git clone
- D. Helm repo

**Q3.** `autoPromotionEnabled: false`:

- A. Deletes the Rollout
- B. Waits for promote (or configured analysis) before switching active
- C. Always switches in 1s
- D. Disables Services

**Q4.** After successful promotion, the old ReplicaSet:

- A. Must remain forever
- B. Typically scales down after `scaleDownDelaySeconds`
- C. Becomes EventSource
- D. Becomes ApplicationSet

**Q5.** Pre-promotion analysis:

- A. Runs only on Git push in CD
- B. Evaluates metrics/jobs before switching user traffic
- C. Is a DAG entrypoint
- D. Is Dex

**Q6.** Blue-green vs canary:

- A. Identical
- B. Blue-green is all-or-nothing switch; canary is gradual weight
- C. Canary cannot use analysis
- D. Blue-green cannot use preview

**Q7.** `kubectl argo rollouts promote`:

- A. Syncs Argo CD
- B. Continues/finishes the rollout (e.g. switches blue-green)
- C. Submits a Workflow
- D. Creates EventBus

**Q8.** Two Services in blue-green:

- A. Forbidden
- B. Active vs preview selector split
- C. Only for Events
- D. Only for Workflows

**Q9.** Auto promotion after N seconds:

- A. `withSequence`
- B. `autoPromotionSeconds` (when auto promotion is used)
- C. `sync-wave`
- D. `concurrencyPolicy`

**Q10.** GitOps of blue-green:

- A. Impossible
- B. Argo CD syncs the Rollout; promotion may still be a Rollouts action/analysis
- C. Only kubectl forever
- D. Only CronWorkflow

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

Apply a blue-green example. Curl active vs preview. Promote. Watch Services.

## Exam tips

- **Active = users. Preview = new. Promote = switch.**
- Not 10% canary.
