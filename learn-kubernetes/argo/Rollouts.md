# Argo Rollouts (Deep Dive)

**18%.** Docs: [argo-rollouts.readthedocs.io](https://argo-rollouts.readthedocs.io/).

## Why it exists

Deployment `rollingUpdate` cannot do true **blue-green**, **weighted canary**, **analysis abort**, or **experiments**. `kind: Rollout` can.

## Blue-green

- `activeService` / `previewService`
- Promote switches users to green
- `autoPromotionEnabled` / `autoPromotionSeconds`
- `scaleDownDelaySeconds`
- pre/post promotion analysis

## Canary

Steps: `setWeight`, `pause`, `analysis`, `setCanaryScale`, `experiment`, mirror/header routes.

- `pause: {}` = wait for promote
- `pause: {duration: 5m}` = auto continue
- Mesh/Ingress = real traffic %; else replica approximation

## Analysis

| Object | Role |
| --- | --- |
| AnalysisTemplate / ClusterAnalysisTemplate | Reusable spec |
| AnalysisRun | One execution |

Providers: prometheus, job, web, datadog, kayenta, …  
`successCondition`, `interval`, `count`, `failureLimit`  
Fail → **abort**

## CLI plugin

`kubectl argo rollouts get rollout NAME --watch`  
`promote` / `abort` / `undo` / `retry`

## With Argo CD

Git holds Rollout. CD syncs. Rollouts controller executes. Optional custom health in `argocd-cm`.
