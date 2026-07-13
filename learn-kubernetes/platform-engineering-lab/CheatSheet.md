# Cheat Sheet (skeletons)

```bash
alias k=kubectl
kn() { kubectl config set-context --current --namespace="$1"; }
export do='--dry-run=client -o yaml'
```

## Quota + LimitRange

See `04.md`. Copy ResourceQuota `hard` keys from kubernetes.io.

## Flux

GitRepository `spec.interval` + `url` + `ref.branch`.  
Kustomization `sourceRef`, `path`, `prune`, `targetNamespace`.

## Argo Application

`argoproj.io/v1alpha1` Application in `argocd`.  
`destination.server: https://kubernetes.default.svc`  
`syncOptions: [CreateNamespace=true]`

## Tekton

Task `steps[]`. Pipeline `tasks[].taskRef` + `runAfter`. PipelineRun `pipelineRef`.

## Kyverno

`validationFailureAction: Enforce`, match Pods + namespace.

## CRD

`apiextensions.k8s.io/v1`, `openAPIV3Schema`, `served/storage`, `subresources.status`.

## HPA v2

`autoscaling/v2`, `averageUtilization`.

## ServiceMonitor

`monitoring.coreos.com/v1`, labels = Prometheus selector, `endpoints.port` = Service **name**.
