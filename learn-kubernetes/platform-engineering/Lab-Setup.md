# CNPA Lab Setup

The exam is closed-book judgement. One **thinnest viable platform** makes the white paper concrete. You do not need every CNCF project.

Needs: Docker/Podman, `kubectl`, `kind` or `minikube`, Git.

```bash
kind create cluster --name cnpa-lab
```

Sketch (pick any two; do not install the universe):

| Capability | Example install |
| --- | --- |
| GitOps CD | Argo CD or Flux (see `argo/Lab-Setup.md` / `gitops/Lab-Setup.md`) |
| Policy | Kyverno or Gatekeeper ConstraintTemplate |
| Compose infra | Crossplane or a sample Operator CRD |
| Portal | Backstage local (heavy) **or** just a Git `catalog-info.yaml` + a Helm “golden path” chart |
| Observability | kube-prometheus-stack **or** just know OTel Collector sits in front of backends |

**Minimum viable exercise**

1. A Helm/Kustomize **golden path** app (Deployment + Service + NetworkPolicy).
2. GitOps Application/Kustomization that syncs it.
3. A Kyverno policy that **defaults** `runAsNonRoot` (secure by default).
4. A CRD `TeamNamespace` (or Crossplane XRD) that creates a namespace — **self-service API**.

That four-step loop *is* CNPA: productized path, GitOps, policy, platform API.
