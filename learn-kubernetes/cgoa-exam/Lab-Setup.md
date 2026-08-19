# CGOA Lab Setup

The exam is closed-book theory. One working pull-based reconciler makes the four principles obvious.

You need Docker/Podman, `kubectl`, `kind` or `minikube`, and Git.

## Option A: Flux (GitOps Toolkit)

```bash
kind create cluster --name cgoa-lab
flux check --pre
# install Flux into the cluster (bootstrap normally needs a Git repo you own)
flux install
```

Without a real GitHub token, install the controllers only (`flux install`) and apply a `GitRepository` + `Kustomization` pointing at a public sample, for example:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/stefanprodan/podinfo
  ref:
    branch: master
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 5m
  targetNamespace: default
  sourceRef:
    kind: GitRepository
    name: podinfo
  path: ./kustomize
```

```bash
kubectl apply -f flux-podinfo.yaml
flux get kustomizations
kubectl get deploy,svc
```

Change a replica in Git (fork) or scale the Deployment in the cluster and watch Flux **revert the scale** — that is reconciliation of drift.

## Option B: Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get pods
```

Register an Application that points at a Git repo of Kubernetes YAML. Sync policy **automated** + **self-heal** is the GitOps loop.

```bash
# password (lab)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## What to notice (maps to the exam)

| You see | Principle |
| --- | --- |
| YAML/Helm in Git, not a runbook | Declarative |
| Git history of the YAML | Versioned and immutable |
| Controller fetches the repo on an interval | Pulled automatically |
| Cluster edit is overwritten | Continuously reconciled |
| `kubectl scale` then it snaps back | Drift + reconciliation |

## Teardown

```bash
kind delete cluster --name cgoa-lab
```
