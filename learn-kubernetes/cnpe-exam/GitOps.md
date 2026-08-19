# GitOps on the Exam (Argo vs Flux)

You will get **one** engine per task. Copy GVK from Quick Reference.

## Flux minimum

`GitRepository` + `Kustomization` (`prune: true`, `path`, `targetNamespace`, `interval`).

```bash
flux reconcile kustomization NAME --with-source
kubectl describe kustomization NAME -n flux-system
```

Helm: `HelmRepository` + `HelmRelease`.

## Argo CD minimum

`Application` in `argocd`: `source` + `destination` + `syncPolicy.automated.{prune,selfHeal}`.

```bash
kubectl -n argocd get app
# CLI if present: argocd app sync NAME
```

Helm: `source.helm.parameters` / `valueFiles`.

## Infra

Same objects, cluster-scoped YAML in Git. Argo AppProject must allow cluster resources.

## Progressive

Rollout/Flagger YAML **in Git**, synced by the engine — or applied live if the task never mentions Git.
