# CNPE Lab Setup

Exam tasks run on a **provided cluster** with extra CLIs. At home, `kind` is enough. You do **not** need every featured tool installed at once.

```bash
kind create cluster --name cnpe-lab
alias k=kubectl
export do='--dry-run=client -o yaml'
```

Install only what you are practising that day. Official examples (versions float; pin when you sit):

| Tool | Typical install |
| --- | --- |
| Flux | `flux install` then GitRepository + Kustomization |
| Argo CD | `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml` |
| Argo Rollouts | official `install.yaml` + `kubectl argo rollouts` plugin |
| Tekton | Tekton Pipelines release YAML |
| Kyverno | Helm or YAML install |
| Gatekeeper | official deploy |
| Prometheus | kube-prometheus-stack **or** Prometheus Operator CRDs + one Prometheus |
| Crossplane | Helm `crossplane-stable/crossplane` + a **provider** (start with kubernetes provider, not AWS) |
| cert-manager | official YAML (operator example) |
| OpenCost | Helm in `opencost` |

CNPA `Lab-Setup.md` is theory. Here you must **apply and wait for Ready**.

**Exam desktop reminder:** work on the SSH `host`, not `base`. Docs: kubernetes.io plus the task’s Quick Reference URL.
