# CAPA Lab Setup

The exam is closed-book theory. One cluster with all four projects makes “which tool” obvious.

You need Docker/Podman, `kubectl`, `kind` or `minikube`, and Git. Namespaces below match common quickstarts; adjust if you already run these tools.

```bash
kind create cluster --name capa-lab
```

## Argo Workflows

```bash
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.6.10/install.yaml
# UI (optional)
kubectl -n argo port-forward deployment/argo-server 2746:2746
```

CLI: install `argo` from [Argo Workflows releases](https://github.com/argoproj/argo-workflows/releases).

Smoke:

```bash
argo submit -n argo --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
```

## Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

CLI: `argocd`. Initial admin password is the `argocd-initial-admin-secret` in `argocd`.

## Argo Rollouts

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl argo rollouts version   # kubectl plugin
```

## Argo Events

```bash
kubectl create namespace argo-events
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
# EventBus is required before EventSource/Sensor
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
```

Events often **triggers Workflows**. You do not have to install Workflows for Events to exist, but the classic lab is webhook → Sensor → Workflow.

## One-line “which tool” checks

| You just installed | CRDs you should see |
| --- | --- |
| Workflows | `workflows.argoproj.io`, `cronworkflows`, `workflowtemplates` |
| CD | `applications.argoproj.io`, `appprojects`, `applicationsets` |
| Rollouts | `rollouts.argoproj.io`, `analysistemplates`, `analysisruns` |
| Events | `eventsources.argoproj.io`, `sensors.argoproj.io`, `eventbus.argoproj.io` |
