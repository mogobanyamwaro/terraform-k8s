# KCA Lab Setup

The exam is closed-book. One kind/minikube cluster plus the CLI makes Audit vs Enforce obvious.

Needs: Kubernetes (kind/minikube), Helm 3, `kubectl`, Kyverno CLI.

## Install Kyverno (Helm)

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl -n kyverno rollout status deployment/kyverno-admission-controller
```

Expect Deployments along the lines of: **admission-controller**, **background-controller**, **reports-controller**, **cleanup-controller**. Names can include a Helm release prefix.

```bash
kubectl get crds | grep kyverno
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno
```

## CLI

```bash
# example: krew
kubectl krew install kyverno
# or download from GitHub releases: kyverno/kyverno
kyverno version
```

## First ClusterPolicy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "label team is required"
        pattern:
          metadata:
            labels:
              team: "?*"
```

```bash
kubectl apply -f require-team.yaml
# CLI shift-left (no cluster needed for apply against a file):
kyverno apply require-team.yaml --resource pod.yaml
```

A Pod **without** `team` is **blocked** in Enforce. Switch to `Audit` and the Pod is created; a **PolicyReport** records the fail.

Do not spend KCA prep writing Rego. Policies are **Kubernetes YAML**.
