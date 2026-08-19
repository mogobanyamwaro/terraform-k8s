# Progressive Delivery (Exam)

## Argo Rollouts

`kind: Rollout` `strategy.canary` or `blueGreen`. Need extra Services.

```bash
kubectl argo rollouts get rollout NAME -n NS --watch
kubectl argo rollouts promote NAME -n NS
kubectl argo rollouts abort NAME -n NS
```

## Flagger

`kind: Canary` `targetRef` Deployment, `service.port`, `analysis.metrics`. Needs mesh or NGINX.

## Analysis

`AnalysisTemplate` + `AnalysisRun`. Fail → abort. Prometheus query in Quick Reference.
